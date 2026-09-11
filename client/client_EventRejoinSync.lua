local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Server = Addon.Server or {}
local Comms = Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local CombatState = Comms.EventCombatState or {}
local Serialization = Comms.Serialization or {}
local ResourceSync = Comms.ResourceSync or {}
local Operations = Comms.Operations or {}
local Registry = Addon.Internal.Registry or {}
local Event = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Event or nil
local Common = Addon.Utils.Common or {}
local Debug = Addon.Debug or {}
local Tasks = Addon.Internal.Tasks or {}
local Spellcasting = Client.Spellcasting or {}
local AuraManager = Spellcasting.AuraManager or (Addon.Internal and Addon.Internal.AuraManager) or nil
local Combat = Client.Combat or {}

local CLIENT_CONNECT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("CLIENT_CONNECT") or nil
local EVENT_SYNC_REQUEST_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_SYNC_REQUEST") or nil
local EVENT_SYNC_ACK_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_SYNC_ACK") or nil

local REQUIRED_SECTIONS = {
    "start",
    "state",
    "units",
    "runtime",
    "datasetHash",
    "rulesetHash",
}

local function logInternal(message, ...)
    if type(Debug.Internal) == "function" then
        Debug.Internal(message, ...)
    end
end

local function logError(message, ...)
    if type(Debug.Error) == "function" then
        Debug.Error(message, ...)
    end
end

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function cloneResources(resources)
    return type(ResourceSync.CloneResources) == "function" and ResourceSync.CloneResources(resources or {}) or resources or {}
end

local function resolveChannelId(state)
    if type(state) ~= "table" then
        return nil
    end
    local channelId = state.channelId
    if (channelId == nil or channelId == "") and type(Comms.ResolveChannelId) == "function" then
        channelId = Comms:ResolveChannelId(state.channelName)
    end
    if channelId ~= nil and channelId ~= "" then
        state.channelId = channelId
    end
    return channelId
end

local function setSyncLocked(client, eventId, reason)
    local syncState = type(client.GetEventSyncState) == "function" and client:GetEventSyncState(true) or client.EventSyncState
    if type(syncState) ~= "table" then
        syncState = {
            status = "syncing",
            eventId = tostring(eventId or ""),
            reason = tostring(reason or "snapshot-invalid"),
            appliedRevision = 0,
            bufferedCommits = {},
            repairRequested = false,
            pipelineActive = true,
        }
        client.EventSyncState = syncState
    end
    if tostring(eventId or "") ~= "" then
        syncState.eventId = tostring(eventId)
    end
    syncState.status = "syncing"
    syncState.reason = tostring(reason or "snapshot-invalid")
    syncState.pipelineActive = true
    syncState.bufferedCommits = syncState.bufferedCommits or {}
    return syncState
end

-- CLIENT_CONNECT now carries the current local resource snapshot. The host uses
-- it only when the player is genuinely absent from the active roster; returning
-- units keep their host-authoritative current resources.
do
    local baseSendToChannel = Comms.SendToChannel
    if type(baseSendToChannel) == "function" then
        Comms.SendToChannel = function(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
            local opcode = tonumber(opcodeOrPayload)
            if opcode == CLIENT_CONNECT_OPCODE and type(argumentsOrMetadata) == "table" then
                local arguments = {}
                for index = 1, math.max(#argumentsOrMetadata, 6) do
                    arguments[index] = argumentsOrMetadata[index]
                end
                arguments[5] = EventSync.ProtocolVersion
                local resources = type(ResourceSync.BuildProfileResourceSnapshot) == "function"
                    and ResourceSync.BuildProfileResourceSnapshot()
                    or {}
                arguments[6] = type(ResourceSync.SerializeResources) == "function"
                    and ResourceSync.SerializeResources(resources or {})
                    or ""
                return baseSendToChannel(self, channelId, opcodeOrPayload, arguments, metadata)
            end
            return baseSendToChannel(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
        end
    end
end

function Client:AbortPendingEventWork(eventId, reason)
    local normalizedEventId = tostring(eventId or "")
    local abortReason = tostring(reason or "event-sync")
    if normalizedEventId == "" then
        return false
    end

    if type(self.CancelPendingTurnCommit) == "function" then
        self:CancelPendingTurnCommit(abortReason, normalizedEventId)
    end
    if type(self.ResetEventResourceDeltas) == "function" then
        self:ResetEventResourceDeltas(normalizedEventId)
    end
    if type(AuraManager) == "table" and type(AuraManager.DiscardPendingOutboundAuraOperations) == "function" then
        AuraManager:DiscardPendingOutboundAuraOperations(self, "turn", normalizedEventId)
        AuraManager:DiscardPendingOutboundAuraOperations(self, "reaction", normalizedEventId)
    end
    if type(self.CancelSpellTargeting) == "function" then
        self:CancelSpellTargeting(abortReason)
    end
    if type(Tasks.CancelScope) == "function" then
        Tasks:CancelScope("event:" .. normalizedEventId, abortReason)
        Tasks:CancelScope("event-turn-commit:" .. normalizedEventId, abortReason)
        Tasks:CancelScope("autopilot:" .. normalizedEventId, abortReason)
    end

    self.PendingDefensiveReactionUses = {}
    self.PendingRPEKillAchievements = {}
    self.PendingRPEHealthAchievements = {}
    self.TurnEndPending = false
    self.PendingTurnCommit = nil
    self.PendingResourceDeltaFlushQueued = false
    self.PendingResourceDeltaFlushQueuedByScope = {}
    self.PendingEventWidgetRefreshReason = nil
    self.PendingStartupActionBarRefresh = false
    self.PendingStartupActionBarRefreshReason = nil
    return true
end

function Client:RequestEventSyncRepair(reason)
    local sessionState = type(self.GetState) == "function" and self:GetState() or self.State
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
    local syncState = type(self.GetEventSyncState) == "function" and self:GetEventSyncState(true) or self.EventSyncState
    if type(sessionState) ~= "table" or sessionState.active ~= true or type(syncState) ~= "table"
        or EVENT_SYNC_REQUEST_OPCODE == nil or type(EventSync.SerializeSyncRequest) ~= "function"
    then
        return false
    end

    if syncState.repairRequested == true then
        return true
    end
    local channelId = resolveChannelId(sessionState)
    if channelId == nil or channelId == "" then
        return false
    end

    local eventId = tostring(syncState.eventId or (eventState and eventState.id) or "")
    local payload = EventSync.SerializeSyncRequest({
        protocolVersion = EventSync.ProtocolVersion,
        channelName = sessionState.channelName,
        eventId = eventId,
        appliedRevision = syncState.appliedRevision or 0,
        reason = reason or syncState.reason or "repair",
    })
    if type(payload) ~= "string" then
        return false
    end

    syncState.status = "syncing"
    syncState.reason = tostring(reason or syncState.reason or "repair")
    syncState.pipelineActive = true
    syncState.repairRequested = true
    syncState.repairRequestedAt = type(Common.GetNow) == "function" and Common.GetNow() or 0
    local sent = Comms:SendToChannel(channelId, EVENT_SYNC_REQUEST_OPCODE, payload, {
        opcode = EVENT_SYNC_REQUEST_OPCODE,
        scope = "client",
        priority = "CRITICAL",
    }) == true
    if not sent then
        syncState.repairRequested = false
    end
    return sent
end

local function validateSectionSet(snapshot)
    if type(snapshot) ~= "table" or type(snapshot.sections) ~= "table" then
        return false, "missing-sections"
    end
    for index = 1, #REQUIRED_SECTIONS do
        local name = REQUIRED_SECTIONS[index]
        if type(snapshot.sections[name]) ~= "string" then
            return false, "missing-section:" .. name
        end
    end
    return true
end

local function validateSnapshotHashes(sections)
    local datasetHash = type(Registry.GenerateActivatedDatasetsHash) == "function"
        and tostring(Registry:GenerateActivatedDatasetsHash() or "") or ""
    local rulesetHash = type(Registry.GenerateActiveRulesetHash) == "function"
        and tostring(Registry:GenerateActiveRulesetHash() or "") or ""
    return tostring(sections.datasetHash or "") == datasetHash
        and tostring(sections.rulesetHash or "") == rulesetHash
end

local function validateUniqueUnits(units)
    local seen = {}
    for index = 1, #(units or {}) do
        local unit = units[index]
        local eventId = math.floor(tonumber(unit and unit.eventID) or 0)
        if eventId <= 0 or seen[eventId] then
            return false
        end
        seen[eventId] = true
    end
    return true, seen
end

local function validateRuntimeReferences(runtimeState, unitIds, eventId, turnNumber)
    for index = 1, #(runtimeState.auras or {}) do
        local aura = runtimeState.auras[index]
        if not unitIds[tonumber(aura and aura.casterEventId) or 0]
            or not unitIds[tonumber(aura and aura.targetEventId) or 0]
        then
            return false, "aura-unit-missing"
        end
    end
    for casterEventId in pairs(runtimeState.spellcasts or {}) do
        if not unitIds[tonumber(casterEventId) or 0] then
            return false, "cast-unit-missing"
        end
    end
    for unitEventId in pairs(runtimeState.cooldowns or {}) do
        if not unitIds[tonumber(unitEventId) or 0] then
            return false, "cooldown-unit-missing"
        end
    end
    local defensive = runtimeState.defensiveReactions or {}
    if tostring(defensive.eventId or "") ~= "" and tostring(defensive.eventId or "") ~= tostring(eventId or "") then
        return false, "defensive-event-mismatch"
    end
    if tonumber(defensive.turnNumber) ~= nil
        and tonumber(defensive.turnNumber) > 0
        and tonumber(defensive.turnNumber) ~= tonumber(turnNumber)
    then
        return false, "defensive-turn-mismatch"
    end
    return true
end

local function decodeSnapshot(snapshot, sender)
    local validSections, sectionReason = validateSectionSet(snapshot)
    if not validSections then
        return nil, sectionReason
    end
    if not validateSnapshotHashes(snapshot.sections) then
        return nil, "configuration-hash-mismatch"
    end
    if type(Event) ~= "table" or type(Event.FromStartArguments) ~= "function"
        or type(Event.DeserializeUnitsFromNetwork) ~= "function"
        or type(Serialization.DeserializeArguments) ~= "function"
        or type(CombatState.DeserializeRuntimeState) ~= "function"
    then
        return nil, "snapshot-api-unavailable"
    end

    local startArguments = Serialization:DeserializeArguments(snapshot.sections.start)
    local stateArguments = Serialization:DeserializeArguments(snapshot.sections.state)
    local units = Event.DeserializeUnitsFromNetwork(snapshot.sections.units)
    local runtimeState, runtimeReason = CombatState.DeserializeRuntimeState(snapshot.sections.runtime)
    if type(startArguments) ~= "table" or type(stateArguments) ~= "table"
        or type(units) ~= "table" or type(runtimeState) ~= "table"
    then
        return nil, runtimeReason or "snapshot-section-decode-failed"
    end
    if tostring(startArguments[1] or "") ~= snapshot.channelName
        or tostring(startArguments[2] or "") ~= snapshot.eventId
        or tostring(stateArguments[1] or "") ~= snapshot.channelName
        or tostring(stateArguments[2] or "") ~= snapshot.eventId
    then
        return nil, "snapshot-identity-mismatch"
    end

    local nextState = Event.FromStartArguments(startArguments)
    if type(nextState) ~= "table" then
        return nil, "event-start-decode-failed"
    end
    nextState.hostName = normalizeName(nextState.hostName ~= "" and nextState.hostName or sender)
    nextState.channelName = snapshot.channelName
    nextState.id = snapshot.eventId
    nextState.active = true
    nextState.ending = false
    nextState.endedAt = 0
    nextState.turnNumber = math.max(1, math.floor(tonumber(stateArguments[3]) or tonumber(nextState.turnNumber) or 1))
    nextState.tickNumber = math.max(1, math.floor(tonumber(stateArguments[4]) or tonumber(nextState.tickNumber) or 1))
    nextState.totalTicks = math.max(1, math.floor(tonumber(stateArguments[5]) or tonumber(nextState.totalTicks) or 1))
    nextState.units = units
    nextState.rosterReady = true
    nextState.unitsChunkExpected = 0
    nextState.unitsChunkReceived = 0
    nextState.startupReady = false
    nextState.startupPhase = "syncing"
    nextState.transitionPhase = nil

    local unique, unitIds = validateUniqueUnits(units)
    if not unique then
        return nil, "invalid-unit-roster"
    end
    local runtimeValid, runtimeValidationReason = validateRuntimeReferences(
        runtimeState,
        unitIds,
        snapshot.eventId,
        nextState.turnNumber
    )
    if not runtimeValid then
        return nil, runtimeValidationReason
    end
    if type(ResourceSync.UpdateEventReadiness) == "function" then
        ResourceSync.UpdateEventReadiness(nextState)
    end
    if nextState.unitsReady ~= true or nextState.resourcesReady ~= true then
        return nil, "snapshot-resources-incomplete"
    end

    return {
        eventState = nextState,
        runtimeState = runtimeState,
    }, nil
end

local function exportCurrentRuntime(client, eventState)
    if type(eventState) ~= "table" then
        return nil
    end
    return {
        auras = type(AuraManager) == "table" and type(AuraManager.ExportEventAuraState) == "function"
            and AuraManager:ExportEventAuraState(client, eventState.id) or {},
        spellcasts = type(Spellcasting.ExportEventCastState) == "function"
            and Spellcasting.ExportEventCastState(client, eventState.id) or {},
        cooldowns = type(Spellcasting.ExportEventCooldownState) == "function"
            and Spellcasting.ExportEventCooldownState(client, eventState.id) or {},
        defensiveReactions = type(Combat.ExportDefensiveReactionUseLedger) == "function"
            and Combat:ExportDefensiveReactionUseLedger(eventState.id, eventState.turnNumber)
            or { eventId = tostring(eventState.id or ""), turnNumber = tonumber(eventState.turnNumber) or 0, uses = {} },
    }
end

local function replaceRuntime(client, eventState, runtimeState)
    if type(AuraManager) ~= "table" or type(AuraManager.ReplaceEventAuraState) ~= "function"
        or type(Spellcasting.ReplaceEventCastState) ~= "function"
        or type(Spellcasting.ReplaceEventCooldownState) ~= "function"
        or type(Combat.ReplaceDefensiveReactionUseLedger) ~= "function"
    then
        return false
    end
    if AuraManager:ReplaceEventAuraState(client, eventState, runtimeState.auras or {}, { refresh = false }) ~= true then
        return false
    end
    if Spellcasting.ReplaceEventCastState(client, eventState.id, runtimeState.spellcasts or {}, { refresh = false }) ~= true then
        return false
    end
    if Spellcasting.ReplaceEventCooldownState(client, eventState.id, runtimeState.cooldowns or {}, { refresh = false }) ~= true then
        return false
    end
    if Combat:ReplaceDefensiveReactionUseLedger(runtimeState.defensiveReactions or {}) ~= true then
        return false
    end
    return true
end

local function updateSessionResourceCaches(sessionState, eventState)
    if type(sessionState) ~= "table" or type(eventState) ~= "table" then
        return false
    end
    sessionState.membersByName = sessionState.membersByName or {}
    sessionState.memberOrder = sessionState.memberOrder or {}
    local localPlayer = normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or nil)
    local changed = false
    for index = 1, #(eventState.units or {}) do
        local unit = eventState.units[index]
        if unit and unit.isPlayer == true then
            local owner = normalizeName(unit.ownerID or unit.controllerID or unit.name)
            local member = owner ~= "" and sessionState.membersByName[owner] or nil
            if owner == localPlayer and type(member) ~= "table" then
                member = { name = owner, joinedAt = type(Common.GetNow) == "function" and Common.GetNow() or 0 }
                sessionState.membersByName[owner] = member
                sessionState.memberOrder[#sessionState.memberOrder + 1] = owner
            end
            if type(member) == "table" then
                member.resources = cloneResources(unit.resources)
                changed = true
            end
        end
    end
    sessionState.lastResourceSyncEventId = eventState.id
    return changed
end

local function restorePreviousRuntime(client, previousState, previousRuntime)
    if type(previousState) ~= "table" or type(previousRuntime) ~= "table" then
        return
    end
    client.EventState = previousState
    replaceRuntime(client, previousState, previousRuntime)
end

local function installSnapshot(client, sessionState, decoded, revision)
    local nextState = decoded.eventState
    local runtimeState = decoded.runtimeState
    local previousState = client.EventState
    local previousRuntime = exportCurrentRuntime(client, previousState)
    local previousControlledEventUnitId = client.ControlledEventUnitId

    if type(previousState) == "table" then
        client:AbortPendingEventWork(previousState.id, "event-sync-snapshot")
    end
    if type(previousState) ~= "table" or tostring(previousState.id or "") ~= tostring(nextState.id or "") then
        client:AbortPendingEventWork(nextState.id, "event-sync-snapshot")
    end

    if type(previousState) == "table" and tostring(previousState.id or "") ~= tostring(nextState.id or "") then
        if type(client.ResetSpellcastingState) == "function" then
            client:ResetSpellcastingState(previousState.id)
        end
        if type(client.ResetTraitRuntime) == "function" then
            client:ResetTraitRuntime(previousState.id)
        end
        if type(client.ClearEventWidgetCombatLog) == "function" then
            client:ClearEventWidgetCombatLog("event-sync-replaced")
        end
    end

    client.EventState = nextState
    local ok, replaced = pcall(replaceRuntime, client, nextState, runtimeState)
    if not ok or replaced ~= true then
        restorePreviousRuntime(client, previousState, previousRuntime)
        client.ControlledEventUnitId = previousControlledEventUnitId
        return false, ok and "runtime-replace-failed" or tostring(replaced)
    end

    updateSessionResourceCaches(sessionState, nextState)
    client.EventUnitInteractionMarkers = {}
    client.LastLocalInteractionMarker = nil
    client.TurnEndPending = false
    client.LastAppliedTurnRegenKey = nil
    if type(client.ResolveControlledEventUnit) == "function" then
        client:ResolveControlledEventUnit(nextState)
    end

    local syncState = type(client.GetEventSyncState) == "function" and client:GetEventSyncState(true) or client.EventSyncState
    syncState.eventId = tostring(nextState.id or "")
    syncState.pipelineActive = true
    syncState.status = "syncing"
    syncState.reason = "snapshot-install"
    syncState.appliedRevision = revision
    syncState.repairRequested = false
    syncState.bufferedCommits = syncState.bufferedCommits or {}
    for bufferedRevision, commit in pairs(syncState.bufferedCommits) do
        if tonumber(bufferedRevision) <= tonumber(revision)
            or type(commit) ~= "table"
            or tostring(commit.eventId or "") ~= tostring(nextState.id or "")
        then
            syncState.bufferedCommits[bufferedRevision] = nil
        end
    end
    return true, nil
end

local baseHandleCommittedEventMutation = Client.HandleCommittedEventMutation

local function drainBufferedCommits(client, syncState, hostName)
    if type(baseHandleCommittedEventMutation) ~= "function" then
        return false, "commit-handler-unavailable"
    end
    while true do
        local nextRevision = (tonumber(syncState.appliedRevision) or 0) + 1
        local commit = syncState.bufferedCommits and syncState.bufferedCommits[nextRevision] or nil
        if type(commit) ~= "table" then
            break
        end
        syncState.bufferedCommits[nextRevision] = nil
        local payload = type(EventSync.SerializeMutationCommit) == "function" and EventSync.SerializeMutationCommit(commit) or nil
        if type(payload) ~= "string" then
            syncState.bufferedCommits[nextRevision] = commit
            return false, "buffered-commit-serialize-failed"
        end
        syncState.status = "idle"
        local ok = baseHandleCommittedEventMutation(client, payload, hostName) == true
        syncState = type(client.GetEventSyncState) == "function" and client:GetEventSyncState(true) or client.EventSyncState
        if not ok or tonumber(syncState.appliedRevision) ~= nextRevision then
            syncState.bufferedCommits[nextRevision] = commit
            return false, "buffered-commit-apply-failed"
        end
        syncState.status = "syncing"
    end

    local appliedRevision = tonumber(syncState.appliedRevision) or 0
    local lowestBuffered = nil
    for revision in pairs(syncState.bufferedCommits or {}) do
        local numericRevision = tonumber(revision)
        if numericRevision and numericRevision > appliedRevision
            and (lowestBuffered == nil or numericRevision < lowestBuffered)
        then
            lowestBuffered = numericRevision
        end
    end
    if lowestBuffered ~= nil and lowestBuffered > appliedRevision + 1 then
        return false, "post-snapshot-revision-gap"
    end
    return true, nil
end

local function rebuildDerivedAndVisualState(client, eventState)
    if type(client.RefreshTraitRuntimeEntries) == "function" then
        client:RefreshTraitRuntimeEntries(eventState)
    end
    if type(AuraManager) == "table" and type(AuraManager.RefreshLocalPlayerDerivedState) == "function" then
        AuraManager:RefreshLocalPlayerDerivedState(eventState, {
            suppressProfileRefresh = true,
        })
    end
    if type(client.InvalidatePendingSpellTargetingDisplayState) == "function" then
        client:InvalidatePendingSpellTargetingDisplayState()
    end
    if type(client.QueueEventWidgetRefresh) == "function" then
        client:QueueEventWidgetRefresh("event-sync-ready")
    end
    if type(client.QueueActionBarRefresh) == "function" then
        client:QueueActionBarRefresh("event-sync-ready")
    end
    if type(client.QueueActionBarCompanionBarsRefresh) == "function" then
        client:QueueActionBarCompanionBarsRefresh("event-sync-ready", { immediate = true })
    end
    if type(client.QueueTargetingWidgetRefresh) == "function" then
        client:QueueTargetingWidgetRefresh("event-sync-ready")
    end
end

local function sendSyncAck(client, sessionState, eventState, revision)
    local channelId = resolveChannelId(sessionState)
    if channelId == nil or channelId == "" or EVENT_SYNC_ACK_OPCODE == nil
        or type(EventSync.SerializeSyncAck) ~= "function"
    then
        return false
    end
    local payload = EventSync.SerializeSyncAck({
        protocolVersion = EventSync.ProtocolVersion,
        channelName = sessionState.channelName,
        eventId = eventState.id,
        appliedRevision = revision,
    })
    if type(payload) ~= "string" then
        return false
    end
    return Comms:SendToChannel(channelId, EVENT_SYNC_ACK_OPCODE, payload, {
        opcode = EVENT_SYNC_ACK_OPCODE,
        scope = "client",
        priority = "CRITICAL",
    }) == true
end

function Client:HandleEventSyncSnapshot(payload, sender)
    local snapshot, decodeReason = type(EventSync.DeserializeSnapshotEnvelope) == "function"
        and EventSync.DeserializeSnapshotEnvelope(payload) or nil, "codec-unavailable"
    local sessionState = type(self.GetState) == "function" and self:GetState() or self.State
    if type(snapshot) ~= "table" then
        local syncState = setSyncLocked(self, nil, decodeReason or "snapshot-decode-failed")
        syncState.repairRequested = false
        self:RequestEventSyncRepair(syncState.reason)
        return false
    end

    local syncState = setSyncLocked(self, snapshot.eventId, "snapshot-received")
    syncState.repairRequested = false
    if type(sessionState) ~= "table" or sessionState.active ~= true
        or snapshot.channelName ~= tostring(sessionState.channelName or "")
        or normalizeName(sender) == ""
        or normalizeName(sender) ~= normalizeName(sessionState.hostName)
        or type(EventSync.IsProtocolCompatible) ~= "function"
        or EventSync.IsProtocolCompatible(snapshot.protocolVersion) ~= true
    then
        syncState.reason = "snapshot-sender-or-session-invalid"
        self:RequestEventSyncRepair(syncState.reason)
        return false
    end

    local appliedRevision = tonumber(syncState.appliedRevision) or 0
    local currentEventState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
    if type(currentEventState) == "table"
        and tostring(currentEventState.id or "") == tostring(snapshot.eventId or "")
        and snapshot.revision < appliedRevision
    then
        syncState.status = "idle"
        syncState.reason = nil
        syncState.repairRequested = false
        return true
    end
    if type(currentEventState) == "table"
        and tostring(currentEventState.id or "") == tostring(snapshot.eventId or "")
        and snapshot.revision == appliedRevision
        and syncState.status ~= "syncing"
    then
        sendSyncAck(self, sessionState, currentEventState, appliedRevision)
        return true
    end

    local decoded, validationReason = decodeSnapshot(snapshot, sender)
    if not decoded then
        syncState.status = "syncing"
        syncState.reason = validationReason or "snapshot-invalid"
        syncState.repairRequested = false
        if syncState.reason ~= "configuration-hash-mismatch" then
            self:RequestEventSyncRepair(syncState.reason)
        else
            syncState.repairRequested = true
            logError("EventSync snapshot rejected: local dataset/ruleset hashes differ from host.")
        end
        return false
    end

    local installed, installReason = installSnapshot(self, sessionState, decoded, snapshot.revision)
    syncState = type(self.GetEventSyncState) == "function" and self:GetEventSyncState(true) or self.EventSyncState
    if installed ~= true then
        syncState.status = "syncing"
        syncState.reason = installReason or "snapshot-install-failed"
        syncState.repairRequested = false
        self:RequestEventSyncRepair(syncState.reason)
        return false
    end

    local drained, drainReason = drainBufferedCommits(self, syncState, normalizeName(sessionState.hostName))
    syncState = type(self.GetEventSyncState) == "function" and self:GetEventSyncState(true) or self.EventSyncState
    if drained ~= true then
        syncState.status = "syncing"
        syncState.reason = drainReason or "post-snapshot-gap"
        syncState.repairRequested = false
        decoded.eventState.startupReady = false
        decoded.eventState.startupPhase = "syncing"
        self:RequestEventSyncRepair(syncState.reason)
        if type(self.QueueEventWidgetRefresh) == "function" then
            self:QueueEventWidgetRefresh("event-sync-gap")
        end
        return true
    end

    local finalState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
    if type(finalState) ~= "table" or finalState.active ~= true or tostring(finalState.id or "") ~= tostring(snapshot.eventId or "") then
        syncState.status = "syncing"
        syncState.reason = "post-snapshot-event-invalid"
        syncState.repairRequested = false
        self:RequestEventSyncRepair(syncState.reason)
        return false
    end

    rebuildDerivedAndVisualState(self, finalState)
    finalState.startupReady = true
    finalState.startupPhase = "ready"
    finalState.transitionPhase = nil
    syncState.status = "idle"
    syncState.reason = nil
    syncState.repairRequested = false
    syncState.pipelineActive = true
    local finalRevision = tonumber(syncState.appliedRevision) or snapshot.revision
    local acknowledged = sendSyncAck(self, sessionState, finalState, finalRevision)
    logInternal(
        "EventSync: snapshot hydrated event=%s snapshotRevision=%d appliedRevision=%d buffered=%d ack=%s.",
        tostring(finalState.id or ""),
        tonumber(snapshot.revision) or 0,
        finalRevision,
        (function() local count=0 for _ in pairs(syncState.bufferedCommits or {}) do count=count+1 end return count end)(),
        tostring(acknowledged)
    )
    return true
end

logInternal("EventSync: client rejoin snapshot integration loaded.")

return Client
