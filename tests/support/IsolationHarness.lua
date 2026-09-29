-- Deterministic, in-memory runtimes for Lua integration tests.
--
-- This intentionally stops at transport and runtime isolation.  It does not
-- model event authority, combat resolution, or any other production policy.

local Harness = {}
local unpackValues = unpack

local function clone(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[clone(key, seen)] = clone(child, seen)
    end
    return copy
end

local function normalizeName(name)
    return type(name) == "string" and name or tostring(name or "")
end

local function matches(rule, packet)
    return (rule.sender == nil or rule.sender == packet.sender)
        and (rule.recipient == nil or rule.recipient == packet.recipient)
        and (rule.opcode == nil or tostring(rule.opcode) == tostring(packet.opcode))
end

local Router = {}
Router.__index = Router

function Router.new(world)
    return setmetatable({
        world = world,
        nodes = {},
        channels = {},
        pending = {},
        held = {},
        dropNextRules = {},
        dropAllRules = {},
        holdNextRules = {},
        duplicateNextRules = {},
        packetSequence = 0,
        logicalSendCount = 0,
        deliveryCount = 0,
        sendHistory = {},
        packetHistory = {},
        deliveryHistory = {},
    }, Router)
end

function Router:AddNode(node)
    self.nodes[#self.nodes + 1] = node
    self.channels[node.Name] = self.channels[node.Name] or {}
end

function Router:JoinChannel(node, channelId, channelName)
    if node.ChannelId ~= nil then
        local oldId = tostring(node.ChannelId)
        if self.channels[oldId] then
            self.channels[oldId][node.Name] = nil
        end
    end
    if node.ChannelName ~= nil then
        local oldName = tostring(node.ChannelName)
        if self.channels[oldName] then
            self.channels[oldName][node.Name] = nil
        end
    end
    node.ChannelId = channelId
    node.ChannelName = channelName
    local keys = { tostring(channelId or ""), tostring(channelName or "") }
    for _, key in ipairs(keys) do
        if key ~= "" then
            self.channels[key] = self.channels[key] or {}
            self.channels[key][node.Name] = true
        end
    end
end

function Router:_recipients(sender, distribution, target, metadata)
    local result = {}
    local includeSender = not (type(metadata) == "table" and metadata.includeSender == false)
    local normalizedDistribution = string.upper(tostring(distribution or ""))

    if normalizedDistribution == "WHISPER" then
        for _, node in ipairs(self.nodes) do
            if node.Name == normalizeName(target) then
                result[#result + 1] = node
                break
            end
        end
        return result
    end

    if normalizedDistribution == "CHANNEL" then
        local members = self.channels[tostring(target or "")] or {}
        for _, node in ipairs(self.nodes) do
            if members[node.Name] and (includeSender or node.Name ~= sender) then
                result[#result + 1] = node
            end
        end
        return result
    end

    -- PARTY, RAID, GUILD, and similar broadcast distributions are represented
    -- as the test world's connected peers.  Tests can narrow this with a
    -- recipient-specific rule or exclude the sender with includeSender=false.
    for _, node in ipairs(self.nodes) do
        if includeSender or node.Name ~= sender then
            result[#result + 1] = node
        end
    end
    return result
end

function Router:_consume(rules, packet)
    for index, rule in ipairs(rules) do
        if matches(rule, packet) then
            table.remove(rules, index)
            return true
        end
    end
    return false
end

function Router:_persistentMatch(rules, packet)
    for _, rule in ipairs(rules) do
        if matches(rule, packet) then
            return true
        end
    end
    return false
end

function Router:_enqueue(packet)
    self.pending[#self.pending + 1] = packet
end

function Router:Send(sender, distribution, opcode, arguments, target, metadata)
    self.packetSequence = self.packetSequence + 1
    self.logicalSendCount = self.logicalSendCount + 1

    local send = {
        id = self.logicalSendCount,
        sender = sender,
        distribution = string.upper(tostring(distribution or "")),
        target = target,
        opcode = opcode,
        arguments = clone(arguments or {}),
        metadata = metadata or {},
    }
    self.sendHistory[#self.sendHistory + 1] = send

    local recipients = self:_recipients(sender, send.distribution, target, metadata)
    for _, node in ipairs(recipients) do
        self.packetSequence = self.packetSequence + 1
        local packet = {
            id = self.packetSequence,
            logicalId = send.id,
            sender = sender,
            recipient = node.Name,
            distribution = send.distribution,
            target = target,
            opcode = opcode,
            arguments = clone(arguments or {}),
            metadata = metadata or {},
            duplicate = false,
            status = "pending",
        }
        self.packetHistory[#self.packetHistory + 1] = packet

        if self:_persistentMatch(self.dropAllRules, packet)
            or self:_consume(self.dropNextRules, packet)
        then
            packet.status = "dropped"
        elseif self:_consume(self.holdNextRules, packet) then
            packet.status = "held"
            self.held[#self.held + 1] = packet
        else
            self:_enqueue(packet)
            if self:_consume(self.duplicateNextRules, packet) then
                self.packetSequence = self.packetSequence + 1
                local duplicate = clone(packet)
                duplicate.id = self.packetSequence
                duplicate.duplicate = true
                duplicate.status = "pending"
                self.packetHistory[#self.packetHistory + 1] = duplicate
                self:_enqueue(duplicate)
            end
        end
    end

    return true
end

function Router:_deliver(packet)
    packet.status = "delivered"
    self.deliveryCount = self.deliveryCount + 1
    self.deliveryHistory[#self.deliveryHistory + 1] = packet

    local recipient
    for _, node in ipairs(self.nodes) do
        if node.Name == packet.recipient then
            recipient = node
            break
        end
    end
    if recipient then
        recipient.Comms:ReceiveMessage(packet.prefix or "RPE", packet,
            packet.distribution, packet.sender, packet.target)
    end

    if not packet.duplicate and type(packet.metadata) == "table"
        and type(packet.metadata.onDelivered) == "function"
    then
        packet.metadata.onDelivered(packet, true)
    end
end

function Router:DeliverAll()
    local delivered = 0
    while #self.pending > 0 do
        local packet = table.remove(self.pending, 1)
        self:_deliver(packet)
        delivered = delivered + 1
    end
    return delivered
end

function Router:ReleaseHeld(sender, recipient, opcode)
    local released = {}
    local remaining = {}
    for _, packet in ipairs(self.held) do
        if (sender == nil or packet.sender == sender)
            and (recipient == nil or packet.recipient == recipient)
            and (opcode == nil or tostring(packet.opcode) == tostring(opcode))
        then
            packet.status = "pending"
            released[#released + 1] = packet
        else
            remaining[#remaining + 1] = packet
        end
    end
    self.held = remaining
    for _, packet in ipairs(released) do
        self:_enqueue(packet)
    end
    return #released
end

function Router:DeliverOutOfOrder(sender, recipient, opcode)
    local selected = {}
    local remaining = {}
    for _, packet in ipairs(self.held) do
        if (sender == nil or packet.sender == sender)
            and (recipient == nil or packet.recipient == recipient)
            and (opcode == nil or tostring(packet.opcode) == tostring(opcode))
        then
            packet.status = "pending"
            selected[#selected + 1] = packet
        else
            remaining[#remaining + 1] = packet
        end
    end
    self.held = remaining
    for index = #selected, 1, -1 do
        self:_enqueue(selected[index])
    end
    return #selected
end

function Router:DropNext(sender, recipient, opcode)
    self.dropNextRules[#self.dropNextRules + 1] = {
        sender = sender, recipient = recipient, opcode = opcode,
    }
end

function Router:DropAll(sender, recipient, opcode)
    self.dropAllRules[#self.dropAllRules + 1] = {
        sender = sender, recipient = recipient, opcode = opcode,
    }
end

function Router:HoldNext(sender, recipient, opcode)
    self.holdNextRules[#self.holdNextRules + 1] = {
        sender = sender, recipient = recipient, opcode = opcode,
    }
end

function Router:DuplicateNext(sender, recipient, opcode)
    self.duplicateNextRules[#self.duplicateNextRules + 1] = {
        sender = sender, recipient = recipient, opcode = opcode,
    }
end

local Runtime = {}
Runtime.__index = Runtime

function Runtime:LoadFile(path)
    local chunk, errorMessage = loadfile(path)
    assert(chunk, errorMessage)
    if setfenv then
        setfenv(chunk, self.env)
    end
    return chunk("RPEngine2", self.Addon)
end

function Runtime:RegisterOperation(opcode, handler, name)
    return self.Addon.Internal.Comms.Operations:Register(opcode, handler, name)
end

function Runtime:Schedule(delayMs, callback)
    return self.World:_schedule(delayMs, callback, self)
end

local function makeRuntime(world, name, isHost)
    local node = setmetatable({
        World = world,
        Name = normalizeName(name),
        IsHost = isHost == true,
        EventState = nil,
        ServerEventState = nil,
        SessionState = {},
    }, Runtime)

    local addon = {
        Internal = { Comms = {}, Tasks = {} },
        Utils = { Common = {} },
        Debug = {},
        Client = {},
        Server = nil,
    }
    node.Addon = addon
    node.env = setmetatable({}, { __index = _G })
    node.env.GetServerTime = function() return world.nowMs / 1000 end
    node.env.GetTime = function() return world.nowMs / 1000 end
    node.env.GetTimePreciseSec = function() return world.nowMs / 1000 end
    node.env.GetUnitName = function() return node.Name end
    node.env.Ambiguate = function(value) return value end
    node.env.UnitName = function() return node.Name end
    node.env.C_Timer = {
        After = function(delay, callback) return node:Schedule((tonumber(delay) or 0) * 1000, callback) end,
        NewTimer = function(delay, callback) return node:Schedule((tonumber(delay) or 0) * 1000, callback) end,
    }

    addon.Client.Name = node.Name
    addon.Client.EventState = nil
    addon.Client.SessionState = node.SessionState
    addon.Client.State = node.SessionState
    addon.Client.GetEventState = function() return node.EventState end

    if node.IsHost then
        addon.Server = {
            Name = node.Name,
            GetEventState = function() return node.ServerEventState end,
            GetState = function() return node.ServerEventState end,
        }
    end

    addon.Internal.Tasks.Enqueue = function(_, callback, ...)
        local arguments = { ... }
        return node:Schedule(0, function()
            callback(unpackValues(arguments))
        end)
    end
    addon.Internal.Tasks.Schedule = function(_, delayMs, callback)
        return node:Schedule(delayMs or 0, callback)
    end

    local comms = addon.Internal.Comms
    comms.Prefix = "RPE"
    comms.Node = node
    comms.Router = world.Router
    node.Comms = comms

    function comms:BuildOutboundMessage(opcodeOrPayload, argumentsOrTarget, targetOrMetadata, metadata)
        if type(opcodeOrPayload) == "number" then
            return opcodeOrPayload, argumentsOrTarget, targetOrMetadata, metadata or {}
        end

        local details = type(targetOrMetadata) == "table" and targetOrMetadata or {}
        return tonumber(details.opcode), opcodeOrPayload, argumentsOrTarget, details
    end

    function comms:SendMessage(distribution, opcodeOrPayload, argumentsOrTarget, targetOrMetadata, metadata)
        local opcode, arguments, target, details = self:BuildOutboundMessage(
            opcodeOrPayload, argumentsOrTarget, targetOrMetadata, metadata)
        if not opcode then
            return false
        end

        if type(arguments) ~= "table" then
            arguments = self.Node.Addon.Internal.Comms.Serialization:DeserializeArguments(arguments or "")
        end
        return self.Router:Send(self.Node.Name, distribution, opcode, arguments, target, details)
    end

    function comms:SendToChannel(channelId, opcode, arguments, metadata)
        return self:SendMessage("CHANNEL", opcode, arguments, channelId, metadata)
    end

    function comms:ReceiveMessage(prefix, packetOrMessage, distribution, sender, target)
        local packet = packetOrMessage
        if type(packetOrMessage) ~= "table" then
            local decoded = self.Node.Addon.Internal.Comms.Serialization:DeserializePacket(packetOrMessage)
            if not decoded then
                return false
            end
            packet = decoded
            packet.arguments = self.Node.Addon.Internal.Comms.Serialization:DeserializeArguments(decoded.argumentsText)
        end

        if prefix ~= nil and prefix ~= "" and prefix ~= self.Prefix then
            return false
        end
        return self.Node.Addon.Internal.Comms.Operations:Dispatch(
            packet.opcode, packet.arguments or {}, sender, distribution, target, packet)
    end

    function comms:JoinChannel(channelId, channelName)
        self.Router:JoinChannel(self.Node, channelId, channelName)
        return true
    end

    node:LoadFile("utils/Common.lua")
    node:LoadFile("core/internal/comms/Serialization.lua")
    node:LoadFile("core/internal/comms/Operations.lua")
    node:LoadFile("core/internal/comms/EventTransactions.lua")
    return node
end

function Runtime:StartEventState(eventState, serverState)
    self.EventState = eventState
    self.Addon.Client.EventState = eventState
    self.Addon.Client.SessionState = self.SessionState
    if self.IsHost then
        self.ServerEventState = serverState
        self.Addon.Server.EventState = serverState
    end
end

local World = {}
World.__index = World

function World.New()
    local world = setmetatable({
        nowMs = 0,
        nodes = {},
        host = nil,
        timers = {},
        timerSequence = 0,
    }, World)
    world.Router = Router.new(world)
    world.router = world.Router
    return world
end

function World:_addNode(name, isHost)
    assert(type(name) == "string" and name ~= "", "runtime name is required")
    for _, existing in ipairs(self.nodes) do
        assert(existing.Name ~= name, "runtime names must be unique")
    end
    if isHost then
        assert(not self.host, "a world can have only one host")
    end

    local node = makeRuntime(self, name, isHost)
    self.nodes[#self.nodes + 1] = node
    self.Router:AddNode(node)
    if isHost then
        self.host = node
    end
    return node
end

function World:AddHost(name)
    return self:_addNode(name, true)
end

function World:AddClient(name)
    return self:_addNode(name, false)
end

function World:_schedule(delayMs, callback, owner)
    assert(type(callback) == "function", "scheduled work requires a callback")
    self.timerSequence = self.timerSequence + 1
    local timer = {
        dueMs = self.nowMs + math.max(0, tonumber(delayMs) or 0),
        sequence = self.timerSequence,
        callback = callback,
        owner = owner,
        cancelled = false,
    }
    self.timers[#self.timers + 1] = timer
    local handle = {}
    function handle:Cancel() timer.cancelled = true end
    function handle:IsCancelled() return timer.cancelled end
    return handle
end

function World:_runDueWork()
    while true do
        local selectedIndex
        local selected
        for index, timer in ipairs(self.timers) do
            if timer.cancelled then
                selectedIndex = index
                selected = timer
                break
            end
            if timer.dueMs <= self.nowMs
                and (not selected or timer.dueMs < selected.dueMs
                    or (timer.dueMs == selected.dueMs and timer.sequence < selected.sequence))
            then
                selectedIndex = index
                selected = timer
            end
        end
        if not selected then
            return
        end
        table.remove(self.timers, selectedIndex)
        if not selected.cancelled then
            selected.callback()
        end
    end
end

function World:SetTime(milliseconds)
    self.nowMs = tonumber(milliseconds) or 0
    self:_runDueWork()
end

function World:AdvanceTime(milliseconds)
    local delta = tonumber(milliseconds) or 0
    assert(delta >= 0, "fake time cannot move backwards")
    self.nowMs = self.nowMs + delta
    self:_runDueWork()
end

function World:GetScheduledWork()
    local result = {}
    for _, timer in ipairs(self.timers) do
        if not timer.cancelled then
            result[#result + 1] = {
                dueMs = timer.dueMs,
                remainingMs = math.max(0, timer.dueMs - self.nowMs),
                owner = timer.owner and timer.owner.Name or nil,
            }
        end
    end
    return result
end

function World:StartEvent(fixture)
    fixture = fixture or {}
    local eventId = fixture.id or fixture.eventID or "test-event"
    local channelName = fixture.channelName or ("RPE-" .. tostring(eventId))
    local channelId = fixture.channelId or channelName

    for _, node in ipairs(self.nodes) do
        local state = clone(fixture)
        state.id = state.id or eventId
        state.active = state.active ~= false
        state.channelName = channelName
        state.channelId = channelId
        state.hostName = state.hostName or (self.host and self.host.Name or "")
        node:StartEventState(state, node.IsHost and clone(fixture) or nil)
        node.SessionState.active = true
        node.SessionState.channelName = channelName
        node.SessionState.channelId = channelId
        node.Comms:JoinChannel(channelId, channelName)
    end
    if self.host and self.host.ServerEventState then
        self.host.ServerEventState.id = self.host.ServerEventState.id or eventId
        self.host.ServerEventState.active = self.host.ServerEventState.active ~= false
        self.host.ServerEventState.channelName = channelName
        self.host.ServerEventState.channelId = channelId
        self.host.ServerEventState.hostName = self.host.ServerEventState.hostName
            or (self.host and self.host.Name or "")
    end
    for _, node in ipairs(self.nodes) do
        local transactions = node.Addon.Client and node.Addon.Client.EventTransactions
        if transactions then
            transactions:StartEvent(node.EventState and node.EventState.id)
        end
        if node.IsHost and node.Addon.Server and node.Addon.Server.EventTransactions then
            node.Addon.Server.EventTransactions:StartEvent(node.ServerEventState and node.ServerEventState.id)
        end
    end
end

function World:EndEvent(reason)
    local eventId = self.host and self.host.EventState and self.host.EventState.id or nil
    for _, node in ipairs(self.nodes) do
        if node.Addon.Client and node.Addon.Client.EventTransactions and eventId then
            node.Addon.Client.EventTransactions:EndEvent(eventId, reason or "ended")
        end
        if node.IsHost and node.Addon.Server and node.Addon.Server.EventTransactions and eventId then
            node.Addon.Server.EventTransactions:EndEvent(eventId, reason or "ended")
        end
        if node.EventState then
            node.EventState.active = false
        end
        if node.ServerEventState then
            node.ServerEventState.active = false
        end
    end
end

function World:DropNext(sender, recipient, opcode)
    return self.Router:DropNext(sender, recipient, opcode)
end

function World:DropAll(sender, recipient, opcode)
    return self.Router:DropAll(sender, recipient, opcode)
end

function World:HoldNext(sender, recipient, opcode)
    return self.Router:HoldNext(sender, recipient, opcode)
end

function World:ReleaseHeld(sender, recipient, opcode)
    return self.Router:ReleaseHeld(sender, recipient, opcode)
end

function World:DuplicateNext(sender, recipient, opcode)
    return self.Router:DuplicateNext(sender, recipient, opcode)
end

function World:DeliverOutOfOrder(sender, recipient, opcode)
    return self.Router:DeliverOutOfOrder(sender, recipient, opcode)
end

function World:DeliverAll()
    return self.Router:DeliverAll()
end

Harness.Router = Router
Harness.Runtime = Runtime
Harness.World = World
Harness.New = World.New
Harness.Clone = clone

return Harness
