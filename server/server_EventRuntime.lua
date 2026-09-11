local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Server = Addon.Server
local Client = Addon.Client
local Comms = Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local Serialization = Comms.Serialization or {}
local Operations = Comms.Operations or {}
local Common = Addon.Utils.Common or {}
local Debug = Addon.Debug or {}

local EVENT_STATE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_STATE") or nil
local EVENT_UNIT_DELTA_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_UNIT_DELTA_BATCH") or nil
local RESOURCE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE") or nil
local RESOURCE_DELTA_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE_DELTA") or nil
local RESOURCE_DELTA_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE_DELTA_BATCH") or nil
local EVENT_MUTATION_COMMIT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_MUTATION_COMMIT") or nil

local function pack(...)
    return { n = select("#", ...), ... }
end

local function logInternal(message, ...)
    if type(Debug) == "table" and type(Debug.Internal) == "function" then
        Debug.Internal(message, ...)
    end
end

local function logError(message, ...)
    if type(Debug) == "table" and type(Debug.Error) == "function" then
        Debug.Error(message, ...)
    end
end

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function buildEventAuthoritySignature(eventState)
    if type(eventState) ~= "table" or eventState.active ~= true then
        return ""
    end

    local serializedUnits = ""
    if type(eventState.SerializeUnitsForNetwork) == "function" then
        serializedUnits = eventState:SerializeUnitsForNetwork() or ""
    end

    return table.concat({
        tostring(eventState.id or ""),
        tostring(math.floor(tonumber(eventState.turnNumber) or 0)),
        tostring(math.floor(tonumber(eventState.tickNumber) or 0)),
        tostring(math.floor(tonumber(eventState.totalTicks) or 0)),
        serializedUnits,
    }, "\30")
end

local function serializeDomainArguments(arguments)
    if type(arguments) == "table" and type(Serialization.SerializeArguments) == "function" then
        return Serialization:SerializeArguments(arguments)
    end
    return tostring(arguments or "")
end

local function resolveEventChannelId(server, eventState)
    local state = type(server) == "table" and type(server.GetState) == "function" and server:GetState() or nil
    local channelId = type(state) == "table" and state.channelId or nil
    local channelName = tostring(type(eventState) == "table" and eventState.channelName or state and state.channelName or "")
    if (channelId == nil or channelId == "") and channelName ~= "" and type(Comms.ResolveChannelId) == "function" then
        channelId = Comms:ResolveChannelId(channelName)
    end
    if type(state) == "table" and channelId ~= nil and channelId ~= "" then
        state.channelId = channelId
    end
    return channelId
end

local function cloneOperation(operation)
    return {
        opcode = math.floor(tonumber(operation and operation.opcode) or 0),
        sender = tostring(operation and operation.sender or ""),
        payload = tostring(operation and operation.payload or ""),
    }
end

local function appendOperation(context, operation)
    if type(context) ~= "table" or type(operation) ~= "table" then
        return false
    end
    local opcode = math.floor(tonumber(operation.opcode) or 0)
    if opcode <= 0 then
        return false
    end
    context.operations = context.operations or {}
    context.operations[#context.operations + 1] = cloneOperation(operation)
    return true
end

Server.EventRuntime = Server.EventRuntime or nil
Server.EventMutationContext = Server.EventMutationContext or nil
Server.EventSyncApplyingMutationRequest = Server.EventSyncApplyingMutationRequest == true

function Server:InitializeEventRuntime(eventState)
    local state = eventState or self.EventState
    local eventId = tostring(type(state) == "table" and state.id or "")
    if type(state) ~= "table" or state.active ~= true or eventId == "" then
        return nil
    end

    self.EventRuntime = {
        eventId = eventId,
        revision = 0,
        auras = {},
        spellcasts = {},
        cooldowns = {},
        turnState = {
            defensiveReactions = {},
        },
        lastCommit = nil,
    }
    self.EventMutationContext = nil
    logInternal("EventSync: runtime initialized event=%s revision=0.", eventId)
    return self.EventRuntime
end

function Server:ClearEventRuntime(eventId, reason)
    local runtime = self.EventRuntime
    if type(runtime) ~= "table" then
        self.EventMutationContext = nil
        return false
    end

    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId ~= "" and tostring(runtime.eventId or "") ~= normalizedEventId then
        return false
    end

    logInternal(
        "EventSync: runtime cleared event=%s revision=%s reason=%s.",
        tostring(runtime.eventId or ""),
        tostring(runtime.revision or 0),
        tostring(reason or "event-ended")
    )
    self.EventRuntime = nil
    self.EventMutationContext = nil
    return true
end

function Server:GetEventRuntimeRevision(eventId)
    local runtime = self.EventRuntime
    if type(runtime) ~= "table" then
        return nil
    end
    local normalizedEventId = tostring(eventId or runtime.eventId or "")
    if normalizedEventId == "" or tostring(runtime.eventId or "") ~= normalizedEventId then
        return nil
    end
    return EventSync.NormalizeRevision and EventSync.NormalizeRevision(runtime.revision) or math.max(0, math.floor(tonumber(runtime.revision) or 0))
end

function Server:GetClientEventSyncProtocolVersion(clientName, state)
    local sessionState = state or (type(self.GetState) == "function" and self:GetState() or nil)
    local normalizedClientName = normalizeName(clientName)
    local clientState = type(sessionState) == "table"
        and type(sessionState.clientsByName) == "table"
        and sessionState.clientsByName[normalizedClientName]
        or nil
    return type(clientState) == "table" and tonumber(clientState.eventSyncProtocolVersion) or nil
end

function Server:IsClientEventSyncCompatible(clientName, state)
    local version = self:GetClientEventSyncProtocolVersion(clientName, state)
    return type(EventSync.IsProtocolCompatible) == "function" and EventSync.IsProtocolCompatible(version) == true
end

local nativeSendToChannel = Comms.SendToChannel

function Server:CommitEventMutation(eventId, operations, applyFn, options)
    local eventState = self.EventState
    local runtime = self.EventRuntime
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId == ""
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or tostring(eventState.id or "") ~= normalizedEventId
        or type(runtime) ~= "table"
        or tostring(runtime.eventId or "") ~= normalizedEventId
    then
        return nil, false, "event-runtime-mismatch"
    end

    local normalizedOperations, operationReason = type(EventSync.NormalizeOperations) == "function"
        and EventSync.NormalizeOperations(operations)
        or nil, nil
    if type(normalizedOperations) ~= "table" or #normalizedOperations == 0 then
        return nil, false, operationReason or "empty-commit"
    end

    if type(applyFn) == "function" then
        local appliedOk, appliedResult = pcall(applyFn)
        if not appliedOk then
            logError("EventSync: authoritative mutation apply failed for event %s: %s", normalizedEventId, tostring(appliedResult))
            return nil, false, "apply-error"
        end
        if appliedResult == false then
            return nil, false, "apply-rejected"
        end
    elseif type(options) ~= "table" or options.alreadyApplied ~= true then
        return nil, false, "missing-apply"
    end

    local previousRevision = EventSync.NormalizeRevision and EventSync.NormalizeRevision(runtime.revision) or math.max(0, math.floor(tonumber(runtime.revision) or 0))
    previousRevision = previousRevision or 0
    local revision = previousRevision + 1
    runtime.revision = revision

    local commit = {
        protocolVersion = EventSync.ProtocolVersion,
        channelName = tostring(eventState.channelName or ""),
        eventId = normalizedEventId,
        revision = revision,
        operations = normalizedOperations,
    }
    runtime.lastCommit = commit

    local payload = type(EventSync.SerializeMutationCommit) == "function" and EventSync.SerializeMutationCommit(commit) or nil
    local channelId = resolveEventChannelId(self, eventState)
    local sent = false
    if payload and channelId and EVENT_MUTATION_COMMIT_OPCODE and type(nativeSendToChannel) == "function" then
        sent = nativeSendToChannel(Comms, channelId, EVENT_MUTATION_COMMIT_OPCODE, payload, {
            opcode = EVENT_MUTATION_COMMIT_OPCODE,
            scope = "server",
        }) == true
    end

    logInternal(
        "EventSync: committed event=%s revision=%d operations=%d queued=%s.",
        normalizedEventId,
        revision,
        #normalizedOperations,
        tostring(sent)
    )
    return revision, sent, nil
end

local function beginMutationCapture(server, eventId, seedOperations)
    local existing = server.EventMutationContext
    if type(existing) == "table" then
        return existing, false
    end

    local context = {
        eventId = tostring(eventId or ""),
        operations = {},
    }
    for index = 1, #(seedOperations or {}) do
        appendOperation(context, seedOperations[index])
    end
    server.EventMutationContext = context
    return context, true
end

local function finishMutationCapture(server, context, ownsContext, changed)
    if ownsContext ~= true then
        return nil, true
    end
    if server.EventMutationContext == context then
        server.EventMutationContext = nil
    end

    if changed ~= true then
        return nil, true
    end
    if type(context.operations) ~= "table" or #context.operations == 0 then
        logError("EventSync: authoritative state changed for event %s without a captured replication operation.", tostring(context.eventId or ""))
        return nil, false
    end

    local revision, sent = server:CommitEventMutation(context.eventId, context.operations, nil, { alreadyApplied = true })
    return revision, sent
end

local foundationServerOpcodes = {
    [EVENT_STATE_OPCODE or -1] = true,
    [EVENT_UNIT_DELTA_BATCH_OPCODE or -2] = true,
}

if type(nativeSendToChannel) == "function" and Comms._eventSyncServerTransportWrapped ~= true then
    Comms._eventSyncServerTransportWrapped = true
    Comms.SendToChannel = function(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
        local opcode = tonumber(opcodeOrPayload)
        local eventState = Server.EventState
        local runtime = Server.EventRuntime
        if opcode
            and foundationServerOpcodes[opcode] == true
            and type(metadata) == "table"
            and metadata.scope == "server"
            and type(eventState) == "table"
            and eventState.active == true
            and type(runtime) == "table"
            and tostring(runtime.eventId or "") == tostring(eventState.id or "")
        then
            local operation = {
                opcode = opcode,
                sender = normalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil),
                payload = serializeDomainArguments(argumentsOrMetadata),
            }
            local context = Server.EventMutationContext
            if type(context) == "table" and tostring(context.eventId or "") == tostring(eventState.id or "") then
                appendOperation(context, operation)
                return true
            end

            local _, sent = Server:CommitEventMutation(eventState.id, { operation }, nil, { alreadyApplied = true })
            return sent == true
        end

        return nativeSendToChannel(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
    end
end

local function runWrappedMutation(server, baseMethod, options, ...)
    local eventState = server.EventState
    local runtime = server.EventRuntime
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or type(runtime) ~= "table"
        or tostring(runtime.eventId or "") ~= tostring(eventState.id or "")
        or type(server.EventMutationContext) == "table"
    then
        return baseMethod(server, ...)
    end

    local beforeSignature = buildEventAuthoritySignature(eventState)
    local context, ownsContext = beginMutationCapture(server, eventState.id)
    local results = pack(pcall(baseMethod, server, ...))
    local afterSignature = buildEventAuthoritySignature(server.EventState)
    local captured = type(context.operations) == "table" and #context.operations > 0
    local changed = beforeSignature ~= afterSignature
    if type(options) == "table" and options.commitWhenBroadcast == true and results[1] == true and results[2] == true and captured then
        changed = true
    end
    finishMutationCapture(server, context, ownsContext, changed)

    if results[1] ~= true then
        error(results[2], 0)
    end
    return unpack(results, 2, results.n)
end

local function wrapMutationMethod(methodName, options)
    local baseMethod = Server[methodName]
    if type(baseMethod) ~= "function" then
        return false
    end

    Server[methodName] = function(self, ...)
        return runWrappedMutation(self, baseMethod, options, ...)
    end
    return true
end

-- These entry points are the current active-event roots which mutate EventState
-- and/or emit EVENT_STATE/EVENT_UNIT_DELTA_BATCH after server_EventAutopilotSchedule
-- has installed its final server-side wrappers.
local mutationMethods = {
    "ReconcileClientEventSession",
    "AddEventNpcUnit",
    "SummonEventPetUnit",
    "SetEventUnitActive",
    "SetEventUnitHidden",
    "SetEventUnitBoss",
    "SetEventUnitTeam",
    "SetEventUnitRaidMarker",
    "ClearEventNpcUnits",
    "_AdvanceEventStepAfterCommit",
}

for index = 1, #mutationMethods do
    wrapMutationMethod(mutationMethods[index])
end
wrapMutationMethod("BroadcastEventDeltaBatch", { commitWhenBroadcast = true })

local baseStartEvent = Server.StartEvent
if type(baseStartEvent) == "function" then
    function Server:StartEvent(...)
        local results = pack(pcall(baseStartEvent, self, ...))
        if results[1] ~= true then
            error(results[2], 0)
        end
        local eventState = results[2]
        if type(eventState) == "table"
            and eventState.active == true
            and self.EventState == eventState
        then
            self:InitializeEventRuntime(eventState)
        end
        return unpack(results, 2, results.n)
    end
end

local baseEndEvent = Server.EndEvent
if type(baseEndEvent) == "function" then
    function Server:EndEvent(...)
        local eventId = tostring(self.EventState and self.EventState.id or self.EventRuntime and self.EventRuntime.eventId or "")
        local results = pack(pcall(baseEndEvent, self, ...))
        if results[1] ~= true then
            error(results[2], 0)
        end
        if eventId ~= "" then
            self:ClearEventRuntime(eventId, "event-ended")
        end
        return unpack(results, 2, results.n)
    end
end

local baseStopServer = Server.StopServer
if type(baseStopServer) == "function" then
    function Server:StopServer(...)
        local results = pack(pcall(baseStopServer, self, ...))
        if results[1] ~= true then
            error(results[2], 0)
        end
        self:ClearEventRuntime(nil, "server-stopped")
        return unpack(results, 2, results.n)
    end
end

local baseHandleClientConnect = Server.HandleClientConnect
if type(baseHandleClientConnect) == "function" then
    function Server:HandleClientConnect(arguments, sender, ...)
        local results = pack(pcall(baseHandleClientConnect, self, arguments, sender, ...))
        if results[1] ~= true then
            error(results[2], 0)
        end

        local state = self.State
        local clientName = normalizeName(sender)
        local clientState = type(state) == "table" and type(state.clientsByName) == "table" and state.clientsByName[clientName] or nil
        if type(clientState) == "table" then
            clientState.eventSyncProtocolVersion = EventSync.NormalizeProtocolVersion and EventSync.NormalizeProtocolVersion(arguments and arguments[5]) or tonumber(arguments and arguments[5])
            clientState.eventSyncCompatible = self:IsClientEventSyncCompatible(clientName, state)
            logInternal(
                "EventSync: CLIENT_CONNECT client=%s protocol=%s compatible=%s.",
                tostring(clientName),
                tostring(clientState.eventSyncProtocolVersion or "none"),
                tostring(clientState.eventSyncCompatible == true)
            )
        end
        return unpack(results, 2, results.n)
    end
end

local baseResourceHandlers = {
    [RESOURCE_OPCODE or -1] = Server.HandleResource,
    [RESOURCE_DELTA_OPCODE or -2] = Server.HandleResourceDelta,
    [RESOURCE_DELTA_BATCH_OPCODE or -3] = Server.HandleResourceDeltaBatch,
}

local function shouldRejectUnstampedActiveResource(server)
    local eventState = server.EventState
    local runtime = server.EventRuntime
    return server.EventSyncApplyingMutationRequest ~= true
        and type(eventState) == "table"
        and eventState.active == true
        and type(runtime) == "table"
        and tostring(runtime.eventId or "") == tostring(eventState.id or "")
end

local function wrapRawResourceHandler(methodName, opcode)
    local baseHandler = baseResourceHandlers[opcode]
    if type(baseHandler) ~= "function" then
        return
    end
    Server[methodName] = function(self, arguments, sender, ...)
        if shouldRejectUnstampedActiveResource(self) then
            logInternal(
                "EventSync: rejected unstamped %s from %s during active event.",
                tostring(methodName),
                tostring(sender or "unknown")
            )
            return false
        end
        return baseHandler(self, arguments, sender, ...)
    end
end

wrapRawResourceHandler("HandleResource", RESOURCE_OPCODE)
wrapRawResourceHandler("HandleResourceDelta", RESOURCE_DELTA_OPCODE)
wrapRawResourceHandler("HandleResourceDeltaBatch", RESOURCE_DELTA_BATCH_OPCODE)

local allowedRequestOpcodes = {
    [RESOURCE_OPCODE or -1] = true,
    [RESOURCE_DELTA_OPCODE or -2] = true,
    [RESOURCE_DELTA_BATCH_OPCODE or -3] = true,
}

function Server:HandleEventMutationRequest(payload, sender)
    local request, reason = type(EventSync.DeserializeMutationRequest) == "function" and EventSync.DeserializeMutationRequest(payload) or nil, nil
    if not request then
        logInternal("EventSync: rejected malformed mutation request from %s (%s).", tostring(sender or "unknown"), tostring(reason or "decode"))
        return false
    end
    if type(EventSync.IsProtocolCompatible) ~= "function" or EventSync.IsProtocolCompatible(request.protocolVersion) ~= true then
        return false
    end

    local state = self.State
    local eventState = self.EventState
    local runtime = self.EventRuntime
    local senderName = normalizeName(sender)
    if type(state) ~= "table"
        or state.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or type(runtime) ~= "table"
        or tostring(runtime.eventId or "") ~= tostring(eventState.id or "")
        or request.channelName ~= tostring(state.channelName or "")
        or request.eventId ~= tostring(eventState.id or "")
        or senderName == ""
        or not self:IsClientEventSyncCompatible(senderName, state)
        or allowedRequestOpcodes[request.opcode] ~= true
    then
        logInternal("EventSync: rejected mutation request sender=%s event=%s opcode=%s.", tostring(senderName), tostring(request.eventId), tostring(request.opcode))
        return false
    end

    local arguments = type(Serialization.DeserializeArguments) == "function" and Serialization:DeserializeArguments(request.payload) or {}
    if tostring(arguments[1] or "") ~= tostring(state.channelName or "")
        or normalizeName(arguments[2] or sender) ~= senderName
    then
        return false
    end

    local baseHandler = baseResourceHandlers[request.opcode]
    if type(baseHandler) ~= "function" then
        return false
    end

    local beforeSignature = buildEventAuthoritySignature(eventState)
    local context, ownsContext = beginMutationCapture(self, eventState.id, {
        {
            opcode = request.opcode,
            sender = senderName,
            payload = request.payload,
        },
    })

    self.EventSyncApplyingMutationRequest = true
    local results = pack(pcall(baseHandler, self, arguments, sender))
    self.EventSyncApplyingMutationRequest = false

    local afterSignature = buildEventAuthoritySignature(self.EventState)
    local changed = beforeSignature ~= afterSignature
    if ownsContext and self.EventMutationContext == context then
        self.EventMutationContext = nil
    end

    if results[1] ~= true then
        logError("EventSync: mutation request apply failed sender=%s opcode=%s: %s", tostring(senderName), tostring(request.opcode), tostring(results[2]))
        return false
    end
    if results[2] ~= true or changed ~= true then
        logInternal(
            "EventSync: mutation request produced no authoritative change sender=%s opcode=%s revision=%s.",
            tostring(senderName),
            tostring(request.opcode),
            tostring(runtime.revision or 0)
        )
        return true
    end

    local revision = self:CommitEventMutation(eventState.id, context.operations, nil, { alreadyApplied = true })
    return revision ~= nil
end

function Server:HandleEventSyncRequest(payload, sender)
    local request = type(EventSync.DeserializeSyncRequest) == "function" and EventSync.DeserializeSyncRequest(payload) or nil
    if not request then
        return false
    end
    local state = self.State
    local senderName = normalizeName(sender)
    local clientState = type(state) == "table" and type(state.clientsByName) == "table" and state.clientsByName[senderName] or nil
    if type(clientState) ~= "table"
        or request.channelName ~= tostring(state.channelName or "")
        or not self:IsClientEventSyncCompatible(senderName, state)
    then
        return false
    end
    clientState.eventSyncRepairRequested = true
    clientState.lastEventSyncRequestEventId = request.eventId
    clientState.lastEventSyncRequestRevision = request.appliedRevision
    clientState.lastEventSyncRequestReason = request.reason
    logInternal(
        "EventSync: repair requested client=%s event=%s revision=%s reason=%s; snapshot hydration is deferred to issue #236.",
        tostring(senderName),
        tostring(request.eventId),
        tostring(request.appliedRevision),
        tostring(request.reason)
    )
    return true
end

function Server:HandleEventSyncAck(payload, sender)
    local ack = type(EventSync.DeserializeSyncAck) == "function" and EventSync.DeserializeSyncAck(payload) or nil
    if not ack then
        return false
    end
    local state = self.State
    local senderName = normalizeName(sender)
    local clientState = type(state) == "table" and type(state.clientsByName) == "table" and state.clientsByName[senderName] or nil
    if type(clientState) ~= "table" or ack.channelName ~= tostring(state.channelName or "") then
        return false
    end
    clientState.lastAcknowledgedEventSyncId = ack.eventId
    clientState.lastAcknowledgedEventSyncRevision = ack.appliedRevision
    return true
end
