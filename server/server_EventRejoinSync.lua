local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Server = Addon.Server
local Comms = Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local CombatState = Comms.EventCombatState or {}
local Serialization = Comms.Serialization or {}
local ResourceSync = Comms.ResourceSync or {}
local Operations = Comms.Operations or {}
local Common = Addon.Utils.Common or {}
local Debug = Addon.Debug or {}

local EVENT_START_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_START") or nil
local EVENT_UNITS_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_UNITS") or nil
local EVENT_STATE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_STATE") or nil
local EVENT_SYNC_SNAPSHOT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_SYNC_SNAPSHOT") or nil

local LEGACY_REJOIN_OPCODES = {
    [EVENT_START_OPCODE or -1] = true,
    [EVENT_UNITS_OPCODE or -2] = true,
    [EVENT_STATE_OPCODE or -3] = true,
}

local function logInternal(message, ...)
    if type(Debug.Internal) == "function" then
        Debug.Internal(message, ...)
    end
end

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function findPlayerUnit(eventState, playerName)
    local expected = normalizeName(playerName)
    if expected == "" then
        return nil
    end
    for index = 1, #(type(eventState) == "table" and eventState.units or {}) do
        local unit = eventState.units[index]
        if unit and unit.isPlayer == true then
            local candidate = normalizeName(unit.ownerID or unit.controllerID or unit.name)
            if candidate == expected then
                return unit
            end
        end
    end
    return nil
end

local function hasResourceRef(resources, resourceRef)
    local expected = tostring(resourceRef or "")
    if expected == "" then
        return true
    end
    for index = 1, #(resources or {}) do
        if tostring(resources[index] and resources[index].resourceRef or "") == expected then
            return true
        end
    end
    return false
end

local function cloneCanonicalRuntime(runtime)
    if type(runtime) ~= "table" or type(CombatState.CloneRuntimeState) ~= "function" then
        return nil
    end
    return CombatState.CloneRuntimeState({
        auras = runtime.auras or {},
        spellcasts = runtime.spellcasts or {},
        cooldowns = runtime.cooldowns or {},
        defensiveReactions = runtime.turnState and runtime.turnState.defensiveReactions or {},
    })
end

local function buildSnapshotSections(server, eventState, reason)
    if type(eventState) ~= "table" or eventState.active ~= true then
        return nil, "event-inactive"
    end
    if type(eventState.ToStartArguments) ~= "function"
        or type(eventState.ToStateArguments) ~= "function"
        or type(eventState.SerializeUnitsForNetwork) ~= "function"
        or type(Serialization.SerializeArguments) ~= "function"
        or type(CombatState.SerializeRuntimeState) ~= "function"
    then
        return nil, "snapshot-api-unavailable"
    end

    local runtimeState = cloneCanonicalRuntime(server.EventRuntime)
    if type(runtimeState) ~= "table" then
        return nil, "runtime-unavailable"
    end

    local hashes = type(server.GetExpectedClientHashes) == "function" and server:GetExpectedClientHashes() or {}
    local startPayload = Serialization:SerializeArguments(eventState:ToStartArguments(false))
    local statePayload = Serialization:SerializeArguments(eventState:ToStateArguments())
    local unitsPayload = eventState:SerializeUnitsForNetwork()
    local runtimePayload = CombatState.SerializeRuntimeState(runtimeState)
    if type(startPayload) ~= "string" or type(statePayload) ~= "string"
        or type(unitsPayload) ~= "string" or type(runtimePayload) ~= "string"
    then
        return nil, "snapshot-section-serialize-failed"
    end

    return {
        start = startPayload,
        state = statePayload,
        units = unitsPayload,
        runtime = runtimePayload,
        datasetHash = tostring(hashes.datasetHash or ""),
        rulesetHash = tostring(hashes.rulesetHash or ""),
        reason = tostring(reason or "rejoin"),
    }, nil
end

function Server:BuildEventSyncSnapshot(reason)
    local state = self.State
    local eventState = self.EventState
    local runtime = self.EventRuntime
    if type(state) ~= "table" or state.active ~= true
        or type(eventState) ~= "table" or eventState.active ~= true
        or type(runtime) ~= "table"
        or tostring(runtime.eventId or "") ~= tostring(eventState.id or "")
    then
        return nil, "event-runtime-inactive"
    end

    local revisionBefore = type(self.GetEventRuntimeRevision) == "function"
        and self:GetEventRuntimeRevision(eventState.id)
        or tonumber(runtime.revision)
    revisionBefore = type(EventSync.NormalizeRevision) == "function"
        and EventSync.NormalizeRevision(revisionBefore)
        or math.max(0, math.floor(tonumber(revisionBefore) or 0))
    if revisionBefore == nil then
        return nil, "invalid-runtime-revision"
    end

    local sections, sectionReason = buildSnapshotSections(self, eventState, reason)
    if not sections then
        return nil, sectionReason
    end

    local revisionAfter = type(self.GetEventRuntimeRevision) == "function"
        and self:GetEventRuntimeRevision(eventState.id)
        or tonumber(runtime.revision)
    revisionAfter = type(EventSync.NormalizeRevision) == "function"
        and EventSync.NormalizeRevision(revisionAfter)
        or math.max(0, math.floor(tonumber(revisionAfter) or 0))
    if revisionAfter ~= revisionBefore then
        return nil, "snapshot-revision-changed"
    end

    local payload = type(EventSync.SerializeSnapshotEnvelope) == "function"
        and EventSync.SerializeSnapshotEnvelope({
            protocolVersion = EventSync.ProtocolVersion,
            channelName = tostring(state.channelName or ""),
            eventId = tostring(eventState.id or ""),
            revision = revisionBefore,
            sections = sections,
        })
        or nil
    if type(payload) ~= "string" then
        return nil, "snapshot-envelope-serialize-failed"
    end

    return {
        eventId = tostring(eventState.id or ""),
        revision = revisionBefore,
        payload = payload,
        sectionCount = 7,
        byteCount = #payload,
    }, nil
end

function Server:SendEventSyncSnapshotToClient(clientName, reason)
    local normalizedClientName = normalizeName(clientName)
    local state = self.State
    local eventState = self.EventState
    local clientState = type(state) == "table" and type(state.clientsByName) == "table"
        and state.clientsByName[normalizedClientName] or nil
    if normalizedClientName == "" or type(clientState) ~= "table"
        or type(eventState) ~= "table" or eventState.active ~= true
        or EVENT_SYNC_SNAPSHOT_OPCODE == nil
        or type(self.IsClientEventSyncCompatible) ~= "function"
        or self:IsClientEventSyncCompatible(normalizedClientName, state) ~= true
    then
        return false
    end
    if type(self.ClientHashesMatch) == "function" and self:ClientHashesMatch(normalizedClientName, state) ~= true then
        return false
    end

    local snapshot, buildReason = self:BuildEventSyncSnapshot(reason)
    if not snapshot then
        logInternal("EventSync: snapshot build failed client=%s reason=%s.", normalizedClientName, tostring(buildReason))
        return false
    end

    clientState.eventSyncSynchronized = false
    clientState.eventSyncSnapshotSentEventId = snapshot.eventId
    clientState.eventSyncSnapshotSentRevision = snapshot.revision
    clientState.eventSyncSnapshotSentReason = tostring(reason or "rejoin")

    local sent = Comms:SendMessage("WHISPER", EVENT_SYNC_SNAPSHOT_OPCODE, snapshot.payload, normalizedClientName, {
        opcode = EVENT_SYNC_SNAPSHOT_OPCODE,
        scope = "server",
        priority = "CRITICAL",
    }) == true
    logInternal(
        "EventSync: snapshot client=%s event=%s revision=%d bytes=%d reason=%s queued=%s.",
        normalizedClientName,
        snapshot.eventId,
        snapshot.revision,
        snapshot.byteCount,
        tostring(reason or "rejoin"),
        tostring(sent)
    )
    return sent
end

-- Suppress only the old active-event recovery triplet for the exact reconnecting
-- target. Fresh event startup is outside this narrow guard and remains unchanged.
do
    local baseSendMessage = Comms.SendMessage
    if type(baseSendMessage) == "function" then
        Comms.SendMessage = function(self, distribution, opcodeOrPayload, argumentsOrMetadata, target, metadata)
            local suppressedTarget = Server.EventRejoinSuppressLegacySnapshotTarget
            if type(suppressedTarget) == "string" and suppressedTarget ~= ""
                and distribution == "WHISPER"
                and normalizeName(target) == suppressedTarget
                and LEGACY_REJOIN_OPCODES[tonumber(opcodeOrPayload) or -1] == true
            then
                logInternal("EventSync: suppressed legacy active-event rejoin opcode=%s target=%s.", tostring(opcodeOrPayload), suppressedTarget)
                return true
            end
            return baseSendMessage(self, distribution, opcodeOrPayload, argumentsOrMetadata, target, metadata)
        end
    end
end

-- Expose protocol/resource data while server_Session's CLIENT_CONNECT handler is
-- synchronously inside ReconcileClientEventSession.
do
    local baseHandleClientConnect = Server.HandleClientConnect
    if type(baseHandleClientConnect) == "function" then
        function Server:HandleClientConnect(arguments, sender, ...)
            local previousContext = self.EventRejoinConnectContext
            local resourcePresent = type(arguments) == "table" and arguments[6] ~= nil
            self.EventRejoinConnectContext = {
                clientName = normalizeName(sender),
                protocolVersion = type(EventSync.NormalizeProtocolVersion) == "function"
                    and EventSync.NormalizeProtocolVersion(arguments and arguments[5])
                    or tonumber(arguments and arguments[5]),
                resourceSnapshotPresent = resourcePresent,
                resources = resourcePresent and type(ResourceSync.NormalizeResources) == "function"
                    and ResourceSync.NormalizeResources(arguments[6]) or {},
            }
            local results = { pcall(baseHandleClientConnect, self, arguments, sender, ...) }
            self.EventRejoinConnectContext = previousContext
            if results[1] ~= true then
                error(results[2], 0)
            end
            return unpack(results, 2)
        end
    end
end

-- Reconcile through the existing #234 mutation wrapper, suppress the old three
-- recovery messages, then capture the full snapshot after any roster insertion
-- has committed and allocated its revision.
do
    local baseReconcileClientEventSession = Server.ReconcileClientEventSession
    if type(baseReconcileClientEventSession) == "function" then
        function Server:ReconcileClientEventSession(clientName, ...)
            local normalizedClientName = normalizeName(clientName)
            local state = self.State
            local eventState = self.EventState
            local clientState = type(state) == "table" and type(state.clientsByName) == "table"
                and state.clientsByName[normalizedClientName] or nil
            if type(state) ~= "table" or state.active ~= true or normalizedClientName == "" or type(clientState) ~= "table" then
                return false
            end
            if type(eventState) ~= "table" or eventState.active ~= true then
                return baseReconcileClientEventSession(self, clientName, ...)
            end

            local connectContext = self.EventRejoinConnectContext
            if type(connectContext) == "table" and connectContext.clientName == normalizedClientName then
                clientState.eventSyncProtocolVersion = connectContext.protocolVersion
                clientState.eventSyncCompatible = type(EventSync.IsProtocolCompatible) == "function"
                    and EventSync.IsProtocolCompatible(connectContext.protocolVersion) == true
            end
            if clientState.eventSyncCompatible ~= true then
                clientState.eventSyncSynchronized = false
                logInternal("EventSync: active-event reconcile rejected incompatible client=%s protocol=%s.", normalizedClientName, tostring(clientState.eventSyncProtocolVersion or "none"))
                return false
            end
            if type(self.ClientHashesMatch) == "function" and self:ClientHashesMatch(normalizedClientName, state) ~= true then
                clientState.eventSyncSynchronized = false
                return false
            end

            -- Host reload recovery is intentionally unsupported. Avoid turning an
            -- ordinary host CLIENT_CONNECT refresh into a destructive self-rejoin.
            local localHostName = normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or nil)
            if localHostName ~= ""
                and normalizedClientName == localHostName
                and normalizeName(eventState.hostName) == localHostName
            then
                clientState.eventSyncSynchronized = true
                return true
            end

            local existingBefore = findPlayerUnit(eventState, normalizedClientName)
            if not existingBefore then
                if type(connectContext) ~= "table"
                    or connectContext.clientName ~= normalizedClientName
                    or connectContext.resourceSnapshotPresent ~= true
                then
                    clientState.eventSyncSynchronized = false
                    logInternal("EventSync: late join rejected without connect resource snapshot client=%s.", normalizedClientName)
                    return false
                end
                local healthResourceRef = tostring(eventState.healthResourceRef or "")
                if healthResourceRef ~= "" and not hasResourceRef(connectContext.resources, healthResourceRef) then
                    clientState.eventSyncSynchronized = false
                    logInternal("EventSync: late join rejected incomplete resources client=%s missing=%s.", normalizedClientName, healthResourceRef)
                    return false
                end
                clientState.resources = type(ResourceSync.CloneResources) == "function"
                    and ResourceSync.CloneResources(connectContext.resources or {})
                    or (connectContext.resources or {})
            end

            clientState.eventSyncSynchronized = false
            local previousSuppressedTarget = self.EventRejoinSuppressLegacySnapshotTarget
            self.EventRejoinSuppressLegacySnapshotTarget = normalizedClientName
            local results = { pcall(baseReconcileClientEventSession, self, clientName, ...) }
            self.EventRejoinSuppressLegacySnapshotTarget = previousSuppressedTarget
            if results[1] ~= true then
                error(results[2], 0)
            end
            if results[2] ~= true then
                return results[2]
            end

            local currentEventState = self.EventState
            local authoritativeUnit = findPlayerUnit(currentEventState, normalizedClientName)
            if authoritativeUnit and type(authoritativeUnit.resources) == "table" then
                clientState.resources = type(ResourceSync.CloneResources) == "function"
                    and ResourceSync.CloneResources(authoritativeUnit.resources)
                    or authoritativeUnit.resources
            end

            local snapshotReason = existingBefore and "reconnect" or "late-join"
            return self:SendEventSyncSnapshotToClient(normalizedClientName, snapshotReason)
        end
    end
end

function Server:HandleEventSyncRequest(payload, sender)
    local request = type(EventSync.DeserializeSyncRequest) == "function" and EventSync.DeserializeSyncRequest(payload) or nil
    local state = self.State
    local eventState = self.EventState
    local runtime = self.EventRuntime
    local senderName = normalizeName(sender)
    local clientState = type(state) == "table" and type(state.clientsByName) == "table" and state.clientsByName[senderName] or nil
    if type(request) ~= "table"
        or type(state) ~= "table" or state.active ~= true
        or type(eventState) ~= "table" or eventState.active ~= true
        or type(runtime) ~= "table"
        or type(clientState) ~= "table"
        or request.channelName ~= tostring(state.channelName or "")
        or (request.eventId ~= "" and request.eventId ~= tostring(eventState.id or ""))
        or type(EventSync.IsProtocolCompatible) ~= "function"
        or EventSync.IsProtocolCompatible(request.protocolVersion) ~= true
        or type(self.IsClientEventSyncCompatible) ~= "function"
        or self:IsClientEventSyncCompatible(senderName, state) ~= true
        or (type(self.ClientHashesMatch) == "function" and self:ClientHashesMatch(senderName, state) ~= true)
    then
        return false
    end

    clientState.eventSyncSynchronized = false
    clientState.eventSyncRepairRequested = true
    clientState.lastEventSyncRequestEventId = request.eventId
    clientState.lastEventSyncRequestRevision = request.appliedRevision
    clientState.lastEventSyncRequestReason = request.reason
    return self:SendEventSyncSnapshotToClient(senderName, request.reason ~= "" and request.reason or "repair")
end

function Server:HandleEventSyncAck(payload, sender)
    local ack = type(EventSync.DeserializeSyncAck) == "function" and EventSync.DeserializeSyncAck(payload) or nil
    local state = self.State
    local eventState = self.EventState
    local runtime = self.EventRuntime
    local senderName = normalizeName(sender)
    local clientState = type(state) == "table" and type(state.clientsByName) == "table" and state.clientsByName[senderName] or nil
    if type(ack) ~= "table" or type(clientState) ~= "table"
        or type(eventState) ~= "table" or eventState.active ~= true
        or type(runtime) ~= "table"
        or ack.channelName ~= tostring(state and state.channelName or "")
        or ack.eventId ~= tostring(eventState.id or "")
        or type(EventSync.IsProtocolCompatible) ~= "function"
        or EventSync.IsProtocolCompatible(ack.protocolVersion) ~= true
        or type(self.IsClientEventSyncCompatible) ~= "function"
        or self:IsClientEventSyncCompatible(senderName, state) ~= true
        or tonumber(ack.appliedRevision) > tonumber(runtime.revision or 0)
    then
        return false
    end

    clientState.lastAcknowledgedEventSyncId = ack.eventId
    clientState.lastAcknowledgedEventSyncRevision = ack.appliedRevision
    clientState.eventSyncRepairRequested = false
    clientState.eventSyncSynchronized = true
    logInternal("EventSync: snapshot acknowledged client=%s event=%s revision=%d current=%d.", senderName, ack.eventId, ack.appliedRevision, tonumber(runtime.revision) or 0)
    return true
end

logInternal("EventSync: host rejoin snapshot integration loaded.")

return Server
