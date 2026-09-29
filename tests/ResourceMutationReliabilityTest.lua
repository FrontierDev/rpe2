local Harness = dofile("tests/support/IsolationHarness.lua")

local function assertEqual(expected, actual, message)
    assert(expected == actual, (message or "values differ")
        .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function assertTrue(value, message)
    assert(value == true, message or "expected true")
end

local function clone(value)
    return Harness.Clone(value)
end

local function resources(healthValue, healthMax)
    return {
        {
            resourceRef = "health",
            currentValue = healthValue,
            maxValue = healthMax or 100,
        },
    }
end

local function resourceByRef(values, resourceRef)
    for index = 1, #(values or {}) do
        if values[index] and values[index].resourceRef == resourceRef then
            return values[index]
        end
    end
    return nil
end

local function health(unit)
    local resource = resourceByRef(unit and unit.resources, "health")
    return tonumber(resource and resource.currentValue) or 0
end

local function threat(unit, sourceEventId)
    return tonumber(unit and unit.threatTable and unit.threatTable[sourceEventId]) or 0
end

local function findUnit(eventState, eventId)
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == tonumber(eventId) then
            return unit
        end
    end
    return nil
end

local function cloneResources(value)
    local result = {}
    for index = 1, #(value or {}) do
        result[index] = clone(value[index])
    end
    return result
end

local function resourcesEqual(left, right)
    if type(left) ~= "table" or type(right) ~= "table" or #left ~= #right then
        return false
    end
    for index = 1, #left do
        local a = left[index]
        local b = right[index]
        if not a or not b
            or a.resourceRef ~= b.resourceRef
            or tonumber(a.currentValue) ~= tonumber(b.currentValue)
            or tonumber(a.maxValue) ~= tonumber(b.maxValue)
        then
            return false
        end
    end
    return true
end

local function normalizeDeltas(value)
    local result = {}
    for index = 1, #(value or {}) do
        local entry = value[index]
        if type(entry) == "table" and tostring(entry.resourceRef or "") ~= "" then
            result[#result + 1] = {
                resourceRef = tostring(entry.resourceRef),
                delta = tonumber(entry.delta) or 0,
                maxValue = entry.maxValue,
                currentValue = entry.currentValue,
            }
        end
    end
    return result
end

local function coalesceDeltas(value)
    local result = {}
    local byRef = {}
    for _, entry in ipairs(normalizeDeltas(value)) do
        local current = byRef[entry.resourceRef]
        if not current then
            current = {
                resourceRef = entry.resourceRef,
                delta = 0,
                maxValue = entry.maxValue,
                currentValue = entry.currentValue,
            }
            byRef[entry.resourceRef] = current
            result[#result + 1] = current
        end
        current.delta = current.delta + (tonumber(entry.delta) or 0)
        current.maxValue = entry.maxValue or current.maxValue
        current.currentValue = entry.currentValue or current.currentValue
    end
    return result
end

local function coalesceTargetedDeltas(value)
    local result = {}
    local byKey = {}
    for index = 1, #(value or {}) do
        local entry = value[index]
        local targetEventId = tonumber(entry and entry.targetEventId) or 0
        if targetEventId > 0 then
            local key = tostring(targetEventId) .. "\31" .. tostring(entry.resourceRef or "")
            local current = byKey[key]
            if not current then
                current = {
                    targetEventId = targetEventId,
                    resourceRef = tostring(entry.resourceRef or ""),
                    delta = 0,
                    maxValue = entry.maxValue,
                    currentValue = entry.currentValue,
                }
                byKey[key] = current
                result[#result + 1] = current
            end
            current.delta = current.delta + (tonumber(entry.delta) or 0)
            current.maxValue = entry.maxValue or current.maxValue
            current.currentValue = entry.currentValue or current.currentValue
        end
    end
    return result
end

local function applyDeltas(resourceList, deltaList)
    local changed = false
    local applied = {}
    for _, delta in ipairs(deltaList or {}) do
        local resource = resourceByRef(resourceList, delta.resourceRef)
        if resource then
            local before = tonumber(resource.currentValue) or 0
            local maximum = tonumber(delta.maxValue or resource.maxValue) or before
            local nextValue = math.max(0, math.min(maximum, before + (tonumber(delta.delta) or 0)))
            resource.currentValue = nextValue
            changed = changed or nextValue ~= before
            applied[#applied + 1] = {
                resourceRef = delta.resourceRef,
                delta = nextValue - before,
                maxValue = maximum,
                currentValue = nextValue,
            }
        end
    end
    return changed, applied
end

local function installResourceSync(node)
    local sync = node.Addon.Internal.Comms.ResourceSync or {}
    node.Addon.Internal.Comms.ResourceSync = sync
    sync.CloneResources = cloneResources
    sync.NormalizeResources = function(value)
        return type(value) == "table" and cloneResources(value) or {}
    end
    sync.ResourcesEqual = resourcesEqual
    sync.CoalesceResourceDeltas = function(value, additional)
        local combined = {}
        for _, entry in ipairs(value or {}) do combined[#combined + 1] = entry end
        for _, entry in ipairs(additional or {}) do combined[#combined + 1] = entry end
        return coalesceDeltas(combined)
    end
    sync.CoalesceTargetedResourceDeltas = function(value, additional)
        local combined = {}
        for _, entry in ipairs(value or {}) do combined[#combined + 1] = entry end
        for _, entry in ipairs(additional or {}) do combined[#combined + 1] = entry end
        return coalesceTargetedDeltas(combined)
    end
    sync.ApplyResourceDeltasToResources = applyDeltas
    sync.ApplyResourceDeltasToEventUnitByEventID = function(units, eventId, deltas)
        local unit
        for index = 1, #(units or {}) do
            if tonumber(units[index] and units[index].eventID) == tonumber(eventId) then
                unit = units[index]
                break
            end
        end
        if not unit then
            return false, nil, {}
        end
        local changed, applied = applyDeltas(unit.resources, deltas)
        return changed, unit, applied
    end
    sync.ApplyResourcesToEventUnitByEventID = function(units, eventId, incoming)
        local unit = findUnit({ units = units }, eventId)
        if not unit then
            return false
        end
        local nextResources = cloneResources(incoming)
        if resourcesEqual(unit.resources, nextResources) then
            return false
        end
        unit.resources = nextResources
        return true
    end
    sync.ApplyResourcesToEventUnits = function(units, playerName, incoming)
        local changed = false
        for index = 1, #(units or {}) do
            local unit = units[index]
            if unit and unit.isPlayer == true and tostring(unit.ownerID or unit.name or "") == tostring(playerName) then
                changed = sync.ApplyResourcesToEventUnitByEventID(units, unit.eventID, incoming) or changed
            end
        end
        return changed
    end
    sync.UpdateEventReadiness = function() return true end
    sync.BuildPlayerTurnRegenResourceDeltas = function()
        return { { resourceRef = "health", delta = 4, maxValue = 100 } }
    end
    sync.SerializeResources = function() return "bootstrap" end
    sync.BuildProfileResourceSnapshot = function() return resources(100, 100) end
end

local function installProjection(node)
    local eventClass = {
        IsBoss = function(unit) return unit and unit.boss == true end,
        SerializeUnitDeltaBatchForNetwork = function(entries)
            local serialized = {}
            for index = 1, #(entries or {}) do
                local entry = entries[index]
                local unit = entry and entry.unit or {}
                serialized[#serialized + 1] = table.concat({
                    tostring(entry and entry.eventID or 0),
                    tostring(health(unit)),
                    tostring(threat(unit, 2)),
                }, ",")
            end
            return table.concat(serialized, ";")
        end,
    }
    node.Addon.Internal.Database = { Classes = { Event = eventClass, EventUnit = eventClass } }
    node.Addon.Client.GetState = function() return node.SessionState end
    node.Addon.Client.QueueEventWidgetRefresh = function() return true end
    node.Addon.Client.QueueTargetingWidgetRefresh = function() return true end
    node.Addon.Client.ResolveLocalEventUnit = function(_, eventState)
        for index = 1, #((eventState and eventState.units) or {}) do
            local unit = eventState.units[index]
            if unit and unit.isPlayer == true and tostring(unit.ownerID or "") == node.Name then
                return unit
            end
        end
        return nil
    end
    node.Addon.Client.HandleEventUnitDeltaBatch = function(_, arguments)
        local serialized = tostring(arguments and arguments[3] or "")
        for record in string.gmatch(serialized, "[^;]+") do
            local eventId, nextHealth, nextThreat = string.match(record, "([^,]+),([^,]+),([^,]+)")
            local unit = findUnit(node.EventState, tonumber(eventId))
            if unit then
                local resource = resourceByRef(unit.resources, "health")
                if resource then
                    resource.currentValue = tonumber(nextHealth) or resource.currentValue
                end
                unit.threatTable = unit.threatTable or {}
                unit.threatTable[2] = tonumber(nextThreat) or 0
            end
        end
        node.EventState.liveUnitRevision = tonumber(arguments and arguments[4]) or node.EventState.liveUnitRevision
        return true
    end
    node.Addon.Client.HandleEventTransactionProjection = function(_, envelope)
        return node.Addon.Client:HandleEventResourceTransactionProjection(envelope)
    end
end

local function setup(options)
    options = options or {}
    local world = Harness.New()
    local host = world:AddHost("Host")
    local playerA = world:AddClient("PlayerA")
    local playerB = world:AddClient("PlayerB")
    local nodes = { host, playerA, playerB }
    local stats = {
        broadcasts = 0,
        valor = { Host = 0, PlayerA = 0, PlayerB = 0 },
        kills = { Host = 0, PlayerA = 0, PlayerB = 0 },
        damage = { Host = 0, PlayerA = 0, PlayerB = 0 },
        healing = { Host = 0, PlayerA = 0, PlayerB = 0 },
        presentations = { Host = 0, PlayerA = 0, PlayerB = 0 },
    }
    local fixture = {
        id = options.eventId or "event-a",
        active = true,
        hostName = "Host",
        channelName = options.channelName or "RPE-RESOURCE",
        channelId = options.channelId or 19,
        turnNumber = 2,
        tickNumber = 3,
        liveUnitRevision = 0,
        healthResourceRef = "health",
        units = {
            { eventID = 1, name = "Boss", active = true, isPlayer = false, boss = true, resources = resources(options.bossHealth or 100), threatTable = {} },
            { eventID = 2, name = "PlayerA", active = true, isPlayer = true, ownerID = "PlayerA", resources = resources(options.playerAHealth or 100), threatTable = {} },
            { eventID = 3, name = "PlayerB", active = true, isPlayer = true, ownerID = "PlayerB", resources = resources(options.playerBHealth or 100), threatTable = {} },
        },
    }

    for _, node in ipairs(nodes) do
        installResourceSync(node)
        installProjection(node)
        node:LoadFile("client/client_Resources.lua")
        local terminalPresentation = node.Addon.Client.HandleEventResourceTransactionTerminal
        node.Addon.Client.HandleEventResourceTransactionTerminal = function(client, envelope)
            if envelope and envelope.state == "committed" then
                stats.presentations[node.Name] = stats.presentations[node.Name] + 1
            end
            return terminalPresentation(client, envelope)
        end
        local peerPresentation = node.Addon.Client.HandleEventResourceTransactionProjection
        node.Addon.Client.HandleEventResourceTransactionProjection = function(client, envelope)
            if envelope and envelope.state == "committed" then
                stats.presentations[node.Name] = stats.presentations[node.Name] + 1
            end
            return peerPresentation(client, envelope)
        end
        node.Addon.Client.GrantConfiguredEventCurrency = function()
            stats.valor[node.Name] = stats.valor[node.Name] + 1
            return true
        end
        node.Addon.Client.Achievements = {
            HandleRPEKill = function() stats.kills[node.Name] = stats.kills[node.Name] + 1 end,
            HandleRPEDamage = function(_, context) stats.damage[node.Name] = stats.damage[node.Name] + (tonumber(context.amount) or 0) end,
            HandleRPEHealing = function(_, context) stats.healing[node.Name] = stats.healing[node.Name] + (tonumber(context.amount) or 0) end,
        }
        node.Addon.Client.Spellcasting = {
            ShowInboundResourceDeltaCombatText = function() return true end,
        }
    end
    host:LoadFile("server/server_Session.lua")
    assertTrue(type(host.Addon.Server.EventTransactions.handlers["event-resource-delta"]) == "function",
        "live delta transaction handler registered")
    assertTrue(type(host.Addon.Server.EventTransactions.handlers["event-resource-batch"]) == "function",
        "live batch transaction handler registered")
    assertTrue(type(host.Addon.Server.EventTransactions.handlers["event-resource-replace"]) == "function",
        "live replace transaction handler registered")
    world:StartEvent(fixture)

    for _, node in ipairs(nodes) do
        node.SessionState.membersByName = {
            Host = { name = "Host" },
            PlayerA = { name = "PlayerA" },
            PlayerB = { name = "PlayerB" },
        }
    end
    local server = host.Addon.Server
    server.State = {
        active = true,
        channelName = fixture.channelName,
        channelId = fixture.channelId,
        clientsByName = {
            Host = { name = "Host" },
            PlayerA = { name = "PlayerA" },
            PlayerB = { name = "PlayerB" },
        },
        clientOrder = { "Host", "PlayerA", "PlayerB" },
    }
    server.EventState = host.ServerEventState
    server.EventDraftState = clone(host.ServerEventState)
    server.BroadcastEventDeltaBatch = function(self, entries)
        stats.broadcasts = stats.broadcasts + 1
        self.EventState.liveUnitRevision = (tonumber(self.EventState.liveUnitRevision) or 0) + 1
        local eventClass = host.Addon.Internal.Database.Classes.Event
        local serialized = eventClass.SerializeUnitDeltaBatchForNetwork(entries)
        local opcode = host.Addon.Internal.Comms.Operations:GetOpcode("EVENT_UNIT_DELTA_BATCH")
        return host.Comms:SendToChannel(self.EventState.channelId, opcode, {
            self.EventState.channelName,
            self.EventState.id,
            serialized,
            self.EventState.liveUnitRevision,
        }, { opcode = opcode, scope = "server" })
    end
    host.Addon.Server.EventTransactions:StartEvent(fixture.id)
    return world, host, playerA, playerB, stats
end

local function sendDelta(player, reason, targetEventId, delta, options)
    return player.Addon.Client:SendClientResourceDeltas(
        player.SessionState,
        reason,
        player.Name,
        { { resourceRef = "health", delta = delta, maxValue = 100 } },
        targetEventId,
        options
    )
end

-- Normal resource mutation: one shared transaction and one revisioned broadcast.
do
    local world, host, playerA, playerB, stats = setup()
    local sent, transactionId = sendDelta(playerA, "damage", 1, -30)
    assertTrue(sent, "normal resource transaction submitted")
    world:DeliverAll()
    assertEqual(1, stats.broadcasts, "normal resource broadcast")
    assertEqual(70, health(findUnit(host.EventState, 1)), "normal host health")
    assertEqual(70, health(findUnit(playerA.EventState, 1)), "normal origin health")
    assertEqual(70, health(findUnit(playerB.EventState, 1)), "normal peer health")
    assertEqual(1, stats.presentations.PlayerA, "normal origin presentation")
    assertEqual(1, stats.presentations.PlayerB, "normal peer presentation")
    assertEqual("committed", playerA.Addon.Client.EventTransactions.TerminalTransactions["event-a"][transactionId].state,
        "normal resource terminal")
end

-- Dropping the request exercises the shared retry state machine.
do
    local world, host, playerA, _, stats = setup()
    local requestOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_REQUEST
    world:DropNext("PlayerA", "Host", requestOpcode)
    local sent, transactionId = sendDelta(playerA, "dropped-request", 1, -10)
    assertTrue(sent and transactionId ~= nil, "dropped request was accepted locally")
    world:DeliverAll()
    assertEqual(0, stats.broadcasts, "dropped request did not execute early")
    world:AdvanceTime(1500)
    world:DeliverAll()
    assertEqual(1, stats.broadcasts, "request retry executed once")
    assertTrue(playerA.Addon.Client.EventTransactions.TerminalTransactions["event-a"][transactionId] ~= nil,
        "request retry settled the same transaction")
end

-- Duplicate request replay is served by the shared server terminal record.
do
    local world, host, playerA, playerB, stats = setup()
    local _, transactionId = sendDelta(playerA, "duplicate-request", 1, -10)
    world:DeliverAll()
    assertEqual(1, stats.broadcasts, "duplicate baseline broadcast")
    assertTrue(playerA.Addon.Client.EventTransactions:Replay(transactionId, "event-a"), "duplicate request replay sent")
    world:DeliverAll()
    assertEqual(1, stats.broadcasts, "duplicate request did not rebroadcast the unit")
end

-- A dropped commit is recovered through the same transaction; the server
-- terminal record prevents a second resource application.
do
    local world, host, playerA, _, stats = setup()
    local commitOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_COMMIT
    world:DropNext("Host", "PlayerA", commitOpcode)
    local _, transactionId = sendDelta(playerA, "dropped-commit", 1, -10)
    world:DeliverAll()
    assertEqual(1, stats.broadcasts, "commit drop executed mutation once")
    world:AdvanceTime(1500)
    world:DeliverAll()
    assertEqual(1, stats.broadcasts, "commit retry did not execute mutation twice")
    assertEqual(1, stats.presentations.PlayerA, "commit retry presented once")
    assertTrue(playerA.Addon.Client.EventTransactions.TerminalTransactions["event-a"][transactionId] ~= nil,
        "commit retry settled the origin")
    assertTrue(playerA.Addon.Client.EventTransactions:Replay(transactionId, "event-a"), "duplicate commit replay sent")
    world:DeliverAll()
    assertEqual(1, stats.presentations.PlayerA, "duplicate commit did not repeat origin presentation")
    assertEqual(1, stats.presentations.PlayerB, "duplicate commit did not repeat peer presentation")
end

-- A batch is one authoritative transaction and one EventUnit delta broadcast.
do
    local world, host, playerA, playerB, stats = setup()
    local sent = playerA.Addon.Client:SendClientResourceDeltaBatch(
        playerA.SessionState,
        "batch-damage",
        playerA.Name,
        {
            { targetEventId = 1, resourceRef = "health", delta = -5, maxValue = 100 },
            { targetEventId = 3, resourceRef = "health", delta = -7, maxValue = 100 },
        },
        {
            threatUpdates = { { targetEventId = 1, sourceEventId = 2, amount = 5 } },
            scope = "reaction",
        }
    )
    assertTrue(sent, "resource batch submitted")
    world:DeliverAll()
    assertEqual(1, stats.broadcasts, "resource batch broadcast once")
    assertEqual(95, health(findUnit(host.EventState, 1)), "batch host target one")
    assertEqual(93, health(findUnit(playerB.EventState, 3)), "batch peer target two")
    assertEqual(5, threat(findUnit(host.EventState, 1), 2), "batch threat committed with resources")
end

-- Replacing a live unit (the Event Manager resurrection path) uses the shared
-- terminal and revisioned projection.
do
    local world, host, playerA, playerB, stats = setup({ playerAHealth = 0 })
    local requestOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_REQUEST
    world:DropNext("PlayerA", "Host", requestOpcode)
    local sent = playerA.Addon.Client:SendClientResources(
        playerA.SessionState,
        "resurrect",
        playerA.Name,
        resources(100),
        2
    )
    assertTrue(sent, "live resource replace submitted")
    world:DeliverAll()
    assertEqual(0, stats.broadcasts, "dropped replace did not execute early")
    world:AdvanceTime(1500)
    world:DeliverAll()
    assertEqual(1, stats.broadcasts, "replace broadcast once")
    assertEqual(100, health(findUnit(host.EventState, 2)), "replace host health")
    assertEqual(100, health(findUnit(playerB.EventState, 2)), "replace peer health")
end

-- Boss kill, damage progress, and healing progress are terminal presentation
-- effects, not local resource echoes.
do
    local world, host, playerA, playerB, stats = setup({ bossHealth = 20 })
    local sent = sendDelta(playerA, "boss-kill", 1, -20)
    assertTrue(sent, "boss kill submitted")
    world:DeliverAll()
    assertEqual(1, stats.valor.PlayerA, "boss kill awards Valor once")
    assertEqual(1, stats.kills.PlayerA, "boss kill achievement once")
    assertEqual(20, stats.damage.PlayerA, "damage progress uses actual damage")

    sent = sendDelta(playerA, "heal", 1, 5)
    assertTrue(sent, "healing submitted")
    world:DeliverAll()
    assertEqual(5, stats.healing.PlayerA, "healing progress uses actual healing")
end

-- The queued spell-cost caller still flushes into the shared batch.
do
    local world, host, playerA, playerB, stats = setup({ playerAHealth = 90 })
    assertTrue(playerA.Addon.Client:QueueClientResourceDeltas(
        playerA.SessionState,
        "spell-cost",
        { { resourceRef = "health", delta = -3, maxValue = 100 } },
        2,
        { scope = "reaction", immediate = true }
    ), "queued spell cost accepted")
    world:DeliverAll()
    assertEqual(1, stats.broadcasts, "queued spell cost uses one transaction")
    assertEqual(87, health(findUnit(host.EventState, 2)), "queued spell cost committed authoritatively")

    local activeUnit = findUnit(playerA.EventState, 2)
    playerA.Addon.Client.DeferTurnDeltaSync = false
    playerA.Addon.Client.ResolveActiveSpellcasterUnit = function(_, eventState)
        return findUnit(eventState, 2), nil, { isControlled = true }
    end
    assertTrue(playerA.Addon.Client:ApplyLocalTurnStartResourceRegeneration(
        playerA.SessionState,
        playerA.EventState
    ), "turn regeneration queued")
    world:DeliverAll()
    assertEqual(2, stats.broadcasts, "turn regeneration uses one shared transaction")
    assertEqual(91, health(activeUnit), "turn regeneration committed authoritatively")
end

-- A stale Event-A envelope cannot mutate Event-B.
do
    local world, host, playerA, playerB, stats = setup()
    local record = playerA.Addon.Client.EventTransactions:Create({
        operation = "event-resource-delta",
        targetEventIds = { 1 },
        input = { targetEventId = 1, resourceDeltas = { { resourceRef = "health", delta = -10 } } },
    })
    assertTrue(record ~= nil, "stale resource transaction created")
    world:StartEvent({
        id = "event-b",
        active = true,
        hostName = "Host",
        channelName = "RPE-RESOURCE-B",
        channelId = 20,
        liveUnitRevision = 0,
        healthResourceRef = "health",
        units = clone(host.EventState.units),
    })
    local eventBHealth = health(findUnit(playerA.EventState, 1))
    host.Addon.Server.State.channelName = "RPE-RESOURCE-B"
    host.Addon.Server.State.channelId = 20
    local accepted = host.Addon.Server.EventTransactions:ReceiveRequest(record.envelope, "PlayerA")
    assertTrue(accepted == false, "stale resource transaction rejected")
    assertEqual(0, stats.broadcasts, "stale resource transaction did not broadcast")
    assertEqual(eventBHealth, health(findUnit(playerA.EventState, 1)), "stale resource transaction did not mutate Event-B")
end

print("ResourceMutationReliabilityTest passed")
