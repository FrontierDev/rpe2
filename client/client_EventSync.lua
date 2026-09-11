local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Comms = Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local Serialization = Comms.Serialization or {}
local Operations = Comms.Operations or {}
local ResourceSync = Comms.ResourceSync or {}
local Common = Addon.Utils.Common or {}
local Debug = Addon.Debug or {}
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil

local CLIENT_CONNECT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("CLIENT_CONNECT") or nil
local EVENT_STATE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_STATE") or nil
local EVENT_UNIT_DELTA_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_UNIT_DELTA_BATCH") or nil
local RESOURCE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE") or nil
local RESOURCE_DELTA_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE_DELTA") or nil
local RESOURCE_DELTA_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE_DELTA_BATCH") or nil
local EVENT_SYNC_REQUEST_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_SYNC_REQUEST") or nil
local EVENT_MUTATION_REQUEST_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_MUTATION_REQUEST") or nil

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

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, nested in pairs(value) do
        copy[key] = deepCopy(nested)
    end
    return copy
end

local function cloneResources(resources)
    if type(ResourceSync.CloneResources) == "function" then
        return ResourceSync.CloneResources(resources or {})
    end
    return deepCopy(resources or {})
end

Client.EventSyncState = Client.EventSyncState or {
    status = "idle",
    eventId = nil,
    reason = nil,
    appliedRevision = 0,
    bufferedCommits = {},
    repairRequested = false,
    pipelineActive = false,
}
Client.EventSyncApplyingCommittedMutation = Client.EventSyncApplyingCommittedMutation == true

function Client:GetEventSyncState(createIfMissing)
    if type(self.EventSyncState) ~= "table" and createIfMissing ~= false then
        self.EventSyncState = {
            status = "idle",
            eventId = nil,
            reason = nil,
            appliedRevision = 0,
            bufferedCommits = {},
            repairRequested = false,
            pipelineActive = false,
        }
    end
    return self.EventSyncState
end

function Client:InitializeEventSyncForEvent(eventId, appliedRevision)
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId == "" then
        return nil
    end

    local state = self:GetEventSyncState(true)
    if tostring(state.eventId or "") == normalizedEventId and state.pipelineActive == true then
        return state
    end

    state.status = "idle"
    state.eventId = normalizedEventId
    state.reason = nil
    state.appliedRevision = type(EventSync.NormalizeRevision) == "function" and (EventSync.NormalizeRevision(appliedRevision) or 0) or math.max(0, math.floor(tonumber(appliedRevision) or 0))
    state.bufferedCommits = {}
    state.repairRequested = false
    state.pipelineActive = true
    logInternal("EventSync: client pipeline initialized event=%s revision=%d.", normalizedEventId, state.appliedRevision)
    return state
end

function Client:ResetEventSyncState(eventId, reason)
    local state = self:GetEventSyncState(false)
    if type(state) ~= "table" then
        return false
    end
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId ~= "" and tostring(state.eventId or "") ~= normalizedEventId then
        return false
    end

    state.status = "idle"
    state.eventId = nil
    state.reason = tostring(reason or "reset")
    state.appliedRevision = 0
    state.bufferedCommits = {}
    state.repairRequested = false
    state.pipelineActive = false
    return true
end

function Client:SetEventSyncAppliedRevision(eventId, revision, options)
    local normalizedEventId = tostring(eventId or "")
    local normalizedRevision = type(EventSync.NormalizeRevision) == "function" and EventSync.NormalizeRevision(revision) or nil
    if normalizedEventId == "" or normalizedRevision == nil then
        return false
    end
    local state = self:InitializeEventSyncForEvent(normalizedEventId, normalizedRevision)
    if not state then
        return false
    end
    state.appliedRevision = normalizedRevision
    state.bufferedCommits = {}
    state.repairRequested = false
    if type(options) ~= "table" or options.keepSyncing ~= true then
        state.status = "idle"
        state.reason = nil
    end
    return true
end

local function resolveSessionChannelId(sessionState)
    if type(sessionState) ~= "table" then
        return nil
    end
    local channelId = sessionState.channelId
    if (channelId == nil or channelId == "")
        and type(sessionState.channelName) == "string"
        and sessionState.channelName ~= ""
        and type(Comms.ResolveChannelId) == "function"
    then
        channelId = Comms:ResolveChannelId(sessionState.channelName)
        if channelId ~= nil and channelId ~= "" then
            sessionState.channelId = channelId
        end
    end
    return channelId
end

function Client:RequestEventSyncRepair(reason)
    local syncState = self:GetEventSyncState(false)
    local sessionState = type(self.GetState) == "function" and self:GetState() or self.State
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
    if type(syncState) ~= "table"
        or type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or EVENT_SYNC_REQUEST_OPCODE == nil
        or type(EventSync.SerializeSyncRequest) ~= "function"
    then
        return false
    end
    if syncState.repairRequested == true then
        return true
    end

    local channelId = resolveSessionChannelId(sessionState)
    if not channelId then
        return false
    end

    local payload = EventSync.SerializeSyncRequest({
        protocolVersion = EventSync.ProtocolVersion,
        channelName = sessionState.channelName,
        eventId = eventState.id,
        appliedRevision = syncState.appliedRevision or 0,
        reason = reason or syncState.reason or "revision-gap",
    })
    if not payload then
        return false
    end

    syncState.repairRequested = true
    local sent = Comms:SendToChannel(channelId, EVENT_SYNC_REQUEST_OPCODE, payload, {
        opcode = EVENT_SYNC_REQUEST_OPCODE,
        scope = "client",
    }) == true
    if not sent then
        syncState.repairRequested = false
    end
    logInternal(
        "EventSync: repair request event=%s revision=%s reason=%s queued=%s.",
        tostring(eventState.id or ""),
        tostring(syncState.appliedRevision or 0),
        tostring(reason or syncState.reason or "revision-gap"),
        tostring(sent)
    )
    return sent
end

local function captureRollbackState(client)
    local eventState = type(client.GetEventState) == "function" and client:GetEventState() or client.EventState
    local sessionState = type(client.GetState) == "function" and client:GetState() or client.State
    local rollback = {
        eventState = eventState,
        turnNumber = type(eventState) == "table" and eventState.turnNumber or nil,
        tickNumber = type(eventState) == "table" and eventState.tickNumber or nil,
        totalTicks = type(eventState) == "table" and eventState.totalTicks or nil,
        unitsPayload = nil,
        memberResources = {},
        memberNames = {},
    }

    if type(eventState) == "table" and type(eventState.SerializeUnitsForNetwork) == "function" then
        rollback.unitsPayload = eventState:SerializeUnitsForNetwork()
    end
    if type(sessionState) == "table" and type(sessionState.membersByName) == "table" then
        for memberName, member in pairs(sessionState.membersByName) do
            rollback.memberNames[memberName] = true
            if type(member) == "table" and member.resources ~= nil then
                rollback.memberResources[memberName] = cloneResources(member.resources)
            end
        end
    end
    return rollback
end

local function restoreRollbackState(client, rollback)
    if type(rollback) ~= "table" then
        return false
    end
    local eventState = rollback.eventState
    if type(eventState) == "table" then
        eventState.turnNumber = rollback.turnNumber
        eventState.tickNumber = rollback.tickNumber
        eventState.totalTicks = rollback.totalTicks
        if type(rollback.unitsPayload) == "string"
            and type(Event) == "table"
            and type(Event.DeserializeUnitsFromNetwork) == "function"
        then
            eventState.units = Event.DeserializeUnitsFromNetwork(rollback.unitsPayload)
        end
    end

    local sessionState = type(client.GetState) == "function" and client:GetState() or client.State
    if type(sessionState) == "table" and type(sessionState.membersByName) == "table" then
        for memberName in pairs(sessionState.membersByName) do
            if rollback.memberNames[memberName] ~= true then
                sessionState.membersByName[memberName] = nil
            end
        end
        for memberName in pairs(rollback.memberNames) do
            local member = sessionState.membersByName[memberName]
            if type(member) == "table" then
                if rollback.memberResources[memberName] ~= nil then
                    member.resources = cloneResources(rollback.memberResources[memberName])
                else
                    member.resources = nil
                end
            end
        end
    end
    return true
end

local committedHandlers = {
    [EVENT_STATE_OPCODE or -1] = "HandleEventState",
    [EVENT_UNIT_DELTA_BATCH_OPCODE or -2] = "HandleEventUnitDeltaBatch",
    [RESOURCE_OPCODE or -3] = "HandleResource",
    [RESOURCE_DELTA_OPCODE or -4] = "HandleResourceDelta",
    [RESOURCE_DELTA_BATCH_OPCODE or -5] = "HandleResourceDeltaBatch",
}

local function validateCommittedOperations(commit, eventState)
    for index = 1, #(commit.operations or {}) do
        local operation = commit.operations[index]
        local handlerName = committedHandlers[tonumber(operation and operation.opcode) or 0]
        if not handlerName or type(Client[handlerName]) ~= "function" then
            return false, "unsupported-operation:" .. tostring(operation and operation.opcode or "nil")
        end

        local arguments = type(Serialization.DeserializeArguments) == "function"
            and Serialization:DeserializeArguments(operation.payload or "")
            or {}
        if tostring(arguments[1] or "") ~= tostring(commit.channelName or "") then
            return false, "operation-channel-mismatch"
        end
        if tostring(arguments[2] or "") ~= tostring(eventState.id or "")
            and operation.opcode ~= RESOURCE_OPCODE
            and operation.opcode ~= RESOURCE_DELTA_OPCODE
            and operation.opcode ~= RESOURCE_DELTA_BATCH_OPCODE
        then
            return false, "operation-event-mismatch"
        end
    end
    return true, nil
end

local function applyCommittedOperations(client, commit)
    local eventState = type(client.GetEventState) == "function" and client:GetEventState() or client.EventState
    local valid, reason = validateCommittedOperations(commit, eventState)
    if not valid then
        return false, reason
    end

    local rollback = captureRollbackState(client)
    client.EventSyncApplyingCommittedMutation = true
    for index = 1, #(commit.operations or {}) do
        local operation = commit.operations[index]
        local handlerName = committedHandlers[operation.opcode]
        local arguments = Serialization:DeserializeArguments(operation.payload or "")
        local handler = client[handlerName]
        local ok, handlerResult = pcall(
            handler,
            client,
            arguments,
            operation.sender,
            "EVENT_SYNC",
            nil,
            {
                opcode = operation.opcode,
                argumentsText = operation.payload,
                arguments = arguments,
                sender = operation.sender,
                eventSyncCommit = true,
                eventSyncRevision = commit.revision,
            }
        )
        if not ok then
            client.EventSyncApplyingCommittedMutation = false
            restoreRollbackState(client, rollback)
            return false, tostring(handlerResult or "handler-error")
        end
        -- Existing domain handlers intentionally return false for some
        -- idempotent/no-change inputs (for example an already-present unit
        -- upsert).  The host commit is still authoritative; successful Lua
        -- execution is the failure boundary here.
    end
    client.EventSyncApplyingCommittedMutation = false
    return true, nil
end

function Client:HandleCommittedEventMutation(payload, sender)
    local commit, reason = type(EventSync.DeserializeMutationCommit) == "function" and EventSync.DeserializeMutationCommit(payload) or nil, nil
    if not commit then
        logInternal("EventSync: rejected malformed mutation commit (%s).", tostring(reason or "decode"))
        return false
    end
    if type(EventSync.IsProtocolCompatible) ~= "function" or EventSync.IsProtocolCompatible(commit.protocolVersion) ~= true then
        return false
    end

    local sessionState = type(self.GetState) == "function" and self:GetState() or self.State
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or commit.channelName ~= tostring(sessionState.channelName or "")
        or commit.eventId ~= tostring(eventState.id or "")
    then
        return false
    end

    local expectedHost = normalizeName(eventState.hostName)
    local normalizedSender = normalizeName(sender)
    if expectedHost ~= "" and normalizedSender ~= expectedHost then
        logInternal("EventSync: rejected commit from non-host sender=%s expected=%s.", tostring(normalizedSender), tostring(expectedHost))
        return false
    end

    local syncState = self:GetEventSyncState(true)
    if tostring(syncState.eventId or "") ~= commit.eventId or syncState.pipelineActive ~= true then
        syncState = self:InitializeEventSyncForEvent(commit.eventId, 0)
    end

    local appliedRevision = type(EventSync.NormalizeRevision) == "function" and (EventSync.NormalizeRevision(syncState.appliedRevision) or 0) or math.max(0, math.floor(tonumber(syncState.appliedRevision) or 0))
    if commit.revision <= appliedRevision then
        logInternal(
            "EventSync: discarded stale commit event=%s revision=%d applied=%d.",
            commit.eventId,
            commit.revision,
            appliedRevision
        )
        return true
    end

    syncState.bufferedCommits = syncState.bufferedCommits or {}
    if syncState.status == "syncing" then
        syncState.bufferedCommits[commit.revision] = commit
        logInternal("EventSync: buffered commit while syncing event=%s revision=%d.", commit.eventId, commit.revision)
        self:RequestEventSyncRepair(syncState.reason or "revision-gap")
        return true
    end

    if commit.revision > appliedRevision + 1 then
        syncState.bufferedCommits[commit.revision] = commit
        syncState.status = "syncing"
        syncState.reason = "revision-gap"
        syncState.repairRequested = false
        logInternal(
            "EventSync: revision gap event=%s applied=%d incoming=%d; gameplay locked pending repair.",
            commit.eventId,
            appliedRevision,
            commit.revision
        )
        self:RequestEventSyncRepair("revision-gap")
        return true
    end

    local applied, applyReason = applyCommittedOperations(self, commit)
    if not applied then
        syncState.bufferedCommits[commit.revision] = commit
        syncState.status = "syncing"
        syncState.reason = "commit-apply-failed"
        syncState.repairRequested = false
        logError(
            "EventSync: commit apply failed event=%s revision=%d reason=%s; gameplay locked pending repair.",
            commit.eventId,
            commit.revision,
            tostring(applyReason or "unknown")
        )
        self:RequestEventSyncRepair("commit-apply-failed")
        return false
    end

    syncState.appliedRevision = commit.revision
    logInternal(
        "EventSync: applied commit event=%s revision=%d operations=%d.",
        commit.eventId,
        commit.revision,
        #(commit.operations or {})
    )
    return true
end

function Client:HandleEventSyncSnapshot(payload, sender)
    -- Opcode/codec seam only.  Snapshot hydration is Issue #236.
    logInternal(
        "EventSync: snapshot received from %s but hydration is not enabled until issue #236 (bytes=%d).",
        tostring(sender or "unknown"),
        #(tostring(payload or ""))
    )
    return false
end

local foundationClientOpcodes = {
    [RESOURCE_OPCODE or -1] = true,
    [RESOURCE_DELTA_OPCODE or -2] = true,
    [RESOURCE_DELTA_BATCH_OPCODE or -3] = true,
}

local nativeSendToChannel = Comms.SendToChannel
if type(nativeSendToChannel) == "function" and Comms._eventSyncClientTransportWrapped ~= true then
    Comms._eventSyncClientTransportWrapped = true
    Comms.SendToChannel = function(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
        local opcode = tonumber(opcodeOrPayload)

        if opcode == CLIENT_CONNECT_OPCODE and type(argumentsOrMetadata) == "table" then
            local arguments = {}
            for index = 1, #argumentsOrMetadata do
                arguments[index] = argumentsOrMetadata[index]
            end
            arguments[5] = EventSync.ProtocolVersion
            return nativeSendToChannel(self, channelId, opcode, arguments, metadata)
        end

        local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
        local syncState = Client:GetEventSyncState(false)
        if opcode
            and foundationClientOpcodes[opcode] == true
            and type(metadata) == "table"
            and metadata.scope == "client"
            and type(eventState) == "table"
            and eventState.active == true
            and type(syncState) == "table"
            and syncState.pipelineActive == true
            and tostring(syncState.eventId or "") == tostring(eventState.id or "")
        then
            if Client.EventSyncApplyingCommittedMutation == true then
                logInternal("EventSync: suppressed nested foundation mutation send while applying host commit opcode=%s.", tostring(opcode))
                return false
            end
            if EVENT_MUTATION_REQUEST_OPCODE == nil or type(EventSync.SerializeMutationRequest) ~= "function" then
                return false
            end

            local domainPayload = type(argumentsOrMetadata) == "table" and Serialization:SerializeArguments(argumentsOrMetadata) or tostring(argumentsOrMetadata or "")
            local requestPayload = EventSync.SerializeMutationRequest({
                protocolVersion = EventSync.ProtocolVersion,
                channelName = tostring(eventState.channelName or ""),
                eventId = tostring(eventState.id or ""),
                opcode = opcode,
                payload = domainPayload,
            })
            if not requestPayload then
                return false
            end

            local requestMetadata = {}
            for key, value in pairs(metadata or {}) do
                requestMetadata[key] = value
            end
            requestMetadata.opcode = EVENT_MUTATION_REQUEST_OPCODE
            requestMetadata.scope = "client"
            requestMetadata.eventSyncDomainOpcode = opcode
            return nativeSendToChannel(self, channelId, EVENT_MUTATION_REQUEST_OPCODE, requestPayload, requestMetadata)
        end

        return nativeSendToChannel(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
    end
end

local function shouldRejectRawFoundationResource(client)
    if client.EventSyncApplyingCommittedMutation == true then
        return false
    end
    local eventState = type(client.GetEventState) == "function" and client:GetEventState() or client.EventState
    local syncState = client:GetEventSyncState(false)
    return type(eventState) == "table"
        and eventState.active == true
        and type(syncState) == "table"
        and syncState.pipelineActive == true
        and tostring(syncState.eventId or "") == tostring(eventState.id or "")
end

local function wrapRawResourceHandler(methodName)
    local baseHandler = Client[methodName]
    if type(baseHandler) ~= "function" then
        return
    end
    Client[methodName] = function(self, arguments, sender, ...)
        if shouldRejectRawFoundationResource(self) then
            logInternal("EventSync: discarded unstamped %s from %s during active event.", tostring(methodName), tostring(sender or "unknown"))
            return false
        end
        return baseHandler(self, arguments, sender, ...)
    end
end

wrapRawResourceHandler("HandleResource")
wrapRawResourceHandler("HandleResourceDelta")
wrapRawResourceHandler("HandleResourceDeltaBatch")

local baseHandleEventStart = Client.HandleEventStart
if type(baseHandleEventStart) == "function" then
    function Client:HandleEventStart(arguments, sender, ...)
        local previousEventId = tostring(self.EventState and self.EventState.id or "")
        local previousSyncEventId = tostring(self.EventSyncState and self.EventSyncState.eventId or "")
        local result = baseHandleEventStart(self, arguments, sender, ...)
        local eventState = self.EventState
        if result == true and type(eventState) == "table" and eventState.active == true then
            local eventId = tostring(eventState.id or "")
            if eventId ~= "" and not (previousEventId == eventId and previousSyncEventId == eventId) then
                self:InitializeEventSyncForEvent(eventId, 0)
            elseif eventId ~= "" and type(self.EventSyncState) == "table" then
                self.EventSyncState.pipelineActive = true
            end
        end
        return result
    end
end

local baseHandleEventEnd = Client.HandleEventEnd
if type(baseHandleEventEnd) == "function" then
    function Client:HandleEventEnd(arguments, ...)
        local eventId = tostring(self.EventState and self.EventState.id or arguments and arguments[2] or "")
        local result = baseHandleEventEnd(self, arguments, ...)
        if result == true and type(self.EventSyncState) == "table" and tostring(self.EventSyncState.eventId or "") == eventId then
            self.EventSyncState.pipelineActive = false
            self.EventSyncState.status = "idle"
            self.EventSyncState.reason = "event-ending"
            self.EventSyncState.bufferedCommits = {}
            self.EventSyncState.repairRequested = false
        end
        return result
    end
end

local baseCanPerformEventAction = Client.CanPerformEventAction
if type(baseCanPerformEventAction) == "function" then
    function Client:CanPerformEventAction(eventState, actionKind)
        local state = eventState or (type(self.GetEventState) == "function" and self:GetEventState() or self.EventState)
        local syncState = self:GetEventSyncState(false)
        if type(state) == "table"
            and state.active == true
            and type(syncState) == "table"
            and syncState.status == "syncing"
            and tostring(syncState.eventId or "") == tostring(state.id or "")
        then
            return false, "event-syncing"
        end
        return baseCanPerformEventAction(self, eventState, actionKind)
    end
end
