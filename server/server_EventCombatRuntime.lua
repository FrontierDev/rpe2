local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Server = Addon.Server
local Client = Addon.Client
local Comms = Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local CombatState = Comms.EventCombatState or {}
local Serialization = Comms.Serialization or {}
local Operations = Comms.Operations or {}
local Common = Addon.Utils.Common or {}
local Registry = Addon.Internal.Registry or {}
local Debug = Addon.Debug or {}
local Event = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Event or nil
local Spellcasting = Client.Spellcasting or {}
local AuraManager = Spellcasting.AuraManager or (Addon.Internal and Addon.Internal.AuraManager) or nil
local Combat = Client.Combat or {}

local EVENT_STATE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_STATE") or nil
local EVENT_UNIT_DELTA_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_UNIT_DELTA_BATCH") or nil
local RESOURCE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE") or nil
local RESOURCE_DELTA_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE_DELTA") or nil
local RESOURCE_DELTA_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE_DELTA_BATCH") or nil
local AURA_APPLY_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_APPLY") or nil
local AURA_DISPEL_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_DISPEL") or nil
local AURA_APPLY_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_APPLY_BATCH") or nil
local AURA_DISPEL_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_DISPEL_BATCH") or nil
local SPELLCAST_START_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_START") or nil
local SPELLCAST_COMPLETE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_COMPLETE") or nil
local SPELLCAST_INTERRUPT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_INTERRUPT") or nil
local EVENT_MUTATION_REQUEST_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_MUTATION_REQUEST") or nil
local EVENT_RUNTIME_STATE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_RUNTIME_STATE") or nil
local EVENT_DEFENSIVE_USE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_DEFENSIVE_USE") or nil

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

local function localPlayerName()
    return normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or nil)
end

local function findEventUnit(eventState, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end
    for index = 1, #(type(eventState) == "table" and eventState.units or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end
    return nil
end

local function eventUnitExists(eventState, eventId)
    return findEventUnit(eventState, eventId) ~= nil
end

local function resolveControllerName(eventState, unit)
    if type(unit) ~= "table" then
        return ""
    end
    if unit.isPlayer == true then
        return normalizeName(unit.ownerID or unit.controllerID or unit.name)
    end
    local controllerId = tonumber(unit.controllerID) or 0
    if controllerId > 0 then
        local controller = findEventUnit(eventState, controllerId)
        return normalizeName(controller and (controller.ownerID or controller.controllerID or controller.name) or nil)
    end
    return normalizeName(unit.controllerID or unit.ownerID)
end

local function resolveChannelId(sessionState)
    if type(sessionState) ~= "table" then
        return nil
    end
    local channelId = sessionState.channelId
    if (channelId == nil or channelId == "") and type(Comms.ResolveChannelId) == "function" then
        channelId = Comms:ResolveChannelId(sessionState.channelName)
    end
    if channelId ~= nil and channelId ~= "" then
        sessionState.channelId = channelId
    end
    return channelId
end

local function cloneResourcesByMember(sessionState)
    local cloned = {}
    for name, member in pairs(type(sessionState) == "table" and sessionState.membersByName or {}) do
        cloned[name] = type(CombatState.CloneValue) == "function" and CombatState.CloneValue(member and member.resources) or nil
    end
    return cloned
end

-- -------------------------------------------------------------------------
-- Pure export/replacement seams.  These deliberately manipulate current
-- runtime records rather than replaying gameplay messages.
-- -------------------------------------------------------------------------

if type(AuraManager) == "table" then
    function AuraManager:ExportEventAuraState(client, eventId)
        local bucket = self.GetEventAuraBucket and self:GetEventAuraBucket(client, eventId, false) or nil
        local records = {}
        for _, entry in pairs(type(bucket) == "table" and bucket.byKey or {}) do
            local record = type(CombatState.CloneAuraRecord) == "function" and CombatState.CloneAuraRecord(entry) or nil
            if record and record.stacks > 0 then
                records[#records + 1] = record
            end
        end
        return type(CombatState.CloneAuraRecords) == "function" and CombatState.CloneAuraRecords(records) or records
    end

    function AuraManager:ReplaceEventAuraState(client, eventState, records, options)
        local eventId = tostring(type(eventState) == "table" and eventState.id or "")
        if type(client) ~= "table" or type(eventState) ~= "table" or eventId == "" then
            return false
        end
        if type(self.ClearEventAuraBucket) == "function" then
            self:ClearEventAuraBucket(client, eventId)
        elseif type(client.ActiveAurasByEventId) == "table" then
            client.ActiveAurasByEventId[eventId] = nil
        end

        local normalized = type(CombatState.CloneAuraRecords) == "function" and CombatState.CloneAuraRecords(records or {}) or records or {}
        for index = 1, #normalized do
            local record = normalized[index]
            local applied, entry = self:UpsertAura(client, {
                eventState = eventState,
                auraRef = record.auraRef,
                datasetId = record.datasetId ~= "" and record.datasetId or nil,
                casterEventId = record.casterEventId,
                targetEventId = record.targetEventId,
                stacks = record.stacks,
                turns = math.max(1, record.turnsRemaining),
                powerLevel = record.powerLevel,
                fullState = true,
            })
            if applied ~= true or type(entry) ~= "table" then
                return false
            end
            entry.turnsRemaining = record.turnsRemaining
            entry.stacks = record.stacks
            entry.stackBehavior = record.stackBehavior
            entry.maxStacks = record.maxStacks
            entry.lastAdvancedOwnerTurnNumber = record.lastAdvancedOwnerTurnNumber
            entry.pendingAdvancedOwnerTurnNumber = nil
            entry.stackTurns = type(CombatState.CloneValue) == "function" and CombatState.CloneValue(record.stackTurns) or record.stackTurns
        end

        local resolvedOptions = type(options) == "table" and options or {}
        if resolvedOptions.refresh == true then
            if type(self.QueueLocalPlayerDerivedStateRefresh) == "function" then
                self:QueueLocalPlayerDerivedStateRefresh(eventState, { reason = "event-runtime-replace" })
            end
            if type(client.QueueActionBarRefresh) == "function" then
                client:QueueActionBarRefresh("event-runtime-aura-replace")
            end
        end
        return true
    end
end

function Spellcasting.ExportEventCastState(client, eventId)
    local bucket = type(Spellcasting.GetEventCastBucket) == "function" and Spellcasting.GetEventCastBucket(client, eventId, false) or nil
    return type(CombatState.CloneCastBucket) == "function" and CombatState.CloneCastBucket(bucket or {}) or {}
end

function Spellcasting.ReplaceEventCastState(client, eventId, records, options)
    local normalizedEventId = tostring(eventId or "")
    if type(client) ~= "table" or normalizedEventId == "" then
        return false
    end
    if type(Spellcasting.ClearEventCastBucket) == "function" then
        Spellcasting.ClearEventCastBucket(client, normalizedEventId)
    else
        client.ActiveSpellcastsByEventId = client.ActiveSpellcastsByEventId or {}
        client.ActiveSpellcastsByEventId[normalizedEventId] = nil
    end
    local normalized = type(CombatState.CloneCastBucket) == "function" and CombatState.CloneCastBucket(records or {}) or records or {}
    for casterEventId, entry in pairs(normalized) do
        if type(Spellcasting.SetCastEntry) == "function" then
            Spellcasting.SetCastEntry(client, normalizedEventId, casterEventId, entry)
        end
    end
    if type(Spellcasting.BumpEventCastRevision) == "function" then
        Spellcasting.BumpEventCastRevision(client, normalizedEventId)
    end
    if type(options) == "table" and options.refresh == true and type(client.QueueActionBarRefresh) == "function" then
        client:QueueActionBarRefresh("event-runtime-cast-replace")
    end
    return true
end

function Spellcasting.ExportEventCooldownState(client, eventId)
    local bucket = type(Spellcasting.GetEventCooldownBucket) == "function" and Spellcasting.GetEventCooldownBucket(client, eventId, false) or nil
    return type(CombatState.CloneCooldownBucket) == "function" and CombatState.CloneCooldownBucket(bucket or {}) or {}
end

function Spellcasting.ReplaceEventCooldownState(client, eventId, records, options)
    local normalizedEventId = tostring(eventId or "")
    if type(client) ~= "table" or normalizedEventId == "" then
        return false
    end
    client.CooldownsByEventId = client.CooldownsByEventId or {}
    client.CooldownsByEventId[normalizedEventId] = type(CombatState.CloneCooldownBucket) == "function" and CombatState.CloneCooldownBucket(records or {}) or records or {}
    client._cachedCooldownSpellMetadata = nil
    client._cachedPetCooldownSpellMetadata = nil
    if type(options) == "table" and options.refresh == true and type(client.QueueActionBarRefresh) == "function" then
        client:QueueActionBarRefresh("event-runtime-cooldown-replace")
    end
    return true
end

function Combat:ExportDefensiveReactionUseLedger(eventId, turnNumber)
    local ledger = self.DefensiveReactionUseLedger
    if type(ledger) ~= "table"
        or (eventId ~= nil and tostring(ledger.eventId or "") ~= tostring(eventId or ""))
        or (turnNumber ~= nil and tonumber(ledger.turnNumber) ~= tonumber(turnNumber))
    then
        return {
            eventId = tostring(eventId or ""),
            turnNumber = math.max(0, math.floor(tonumber(turnNumber) or 0)),
            uses = {},
        }
    end
    return type(CombatState.CloneDefensiveState) == "function" and CombatState.CloneDefensiveState(ledger) or ledger
end

function Combat:ReplaceDefensiveReactionUseLedger(value)
    local state = type(CombatState.CloneDefensiveState) == "function" and CombatState.CloneDefensiveState(value or {}) or value or {}
    if state.eventId == "" or state.turnNumber <= 0 then
        self.DefensiveReactionUseLedger = nil
        return true
    end
    self.DefensiveReactionUseLedger = state
    return true
end

local function exportClientRuntime(eventState)
    local eventId = tostring(type(eventState) == "table" and eventState.id or "")
    local turnNumber = math.max(0, math.floor(tonumber(type(eventState) == "table" and eventState.turnNumber) or 0))
    return {
        auras = type(AuraManager) == "table" and type(AuraManager.ExportEventAuraState) == "function"
            and AuraManager:ExportEventAuraState(Client, eventId) or {},
        spellcasts = type(Spellcasting.ExportEventCastState) == "function"
            and Spellcasting.ExportEventCastState(Client, eventId) or {},
        cooldowns = type(Spellcasting.ExportEventCooldownState) == "function"
            and Spellcasting.ExportEventCooldownState(Client, eventId) or {},
        defensiveReactions = type(Combat.ExportDefensiveReactionUseLedger) == "function"
            and Combat:ExportDefensiveReactionUseLedger(eventId, turnNumber) or { eventId = eventId, turnNumber = turnNumber, uses = {} },
    }
end

local function mergeServerCastState(eventId, clientBucket)
    local merged = type(CombatState.CloneCastBucket) == "function" and CombatState.CloneCastBucket(clientBucket or {}) or clientBucket or {}
    local serverBucket = type(Server.ActiveSpellcastsByEventId) == "table" and Server.ActiveSpellcastsByEventId[eventId] or nil
    for casterEventId, entry in pairs(type(serverBucket) == "table" and serverBucket or {}) do
        local numericCasterEventId = tonumber(casterEventId) or tonumber(entry and entry.casterEventId) or 0
        if numericCasterEventId > 0 and merged[numericCasterEventId] == nil then
            local normalized = {
                spellRef = entry.spellRef,
                spellName = entry.spellName,
                authorityType = entry.authorityType,
                casterEventId = numericCasterEventId,
                turnsTotal = entry.turnsTotal,
                turnsElapsed = entry.turnsElapsed or 0,
                turnsRemaining = math.max(0, (tonumber(entry.turnsTotal) or 1) - (tonumber(entry.turnsElapsed) or 0)),
                startedOnTurnNumber = entry.startedOnTurnNumber or (Server.EventState and Server.EventState.turnNumber) or 1,
                completeOnTurnNumber = entry.completeOnTurnNumber,
                lastAdvancedTurnNumber = entry.lastAdvancedTurnNumber or entry.startedOnTurnNumber or (Server.EventState and Server.EventState.turnNumber) or 1,
                targetSelections = entry.targetSelections,
                targetSelectionOrder = entry.targetSelectionOrder,
                targetEventIds = entry.targetEventIds,
                focusedTargetEventId = entry.focusedTargetEventId,
                targetPolicy = entry.targetPolicy,
                resolvedStartCostAmounts = entry.resolvedStartCostAmounts,
            }
            local cloned = type(CombatState.CloneCastEntry) == "function" and CombatState.CloneCastEntry(normalized) or normalized
            if cloned then
                merged[numericCasterEventId] = cloned
            end
        end
    end
    return merged
end

function Server:SyncEventCombatRuntimeFromLocalClient()
    local eventState = self.EventState
    local runtime = self.EventRuntime
    if type(eventState) ~= "table" or eventState.active ~= true
        or type(runtime) ~= "table" or tostring(runtime.eventId or "") ~= tostring(eventState.id or "")
    then
        return false
    end
    local exported = exportClientRuntime(eventState)
    runtime.auras = type(CombatState.CloneAuraRecords) == "function" and CombatState.CloneAuraRecords(exported.auras) or exported.auras
    runtime.spellcasts = mergeServerCastState(eventState.id, exported.spellcasts)
    runtime.cooldowns = type(CombatState.CloneCooldownBucket) == "function" and CombatState.CloneCooldownBucket(exported.cooldowns) or exported.cooldowns
    runtime.turnState = runtime.turnState or {}
    runtime.turnState.defensiveReactions = type(CombatState.CloneDefensiveState) == "function"
        and CombatState.CloneDefensiveState(exported.defensiveReactions) or exported.defensiveReactions
    return true
end

function Server:ExportEventCombatRuntime()
    local eventState = self.EventState
    local runtime = self.EventRuntime
    if type(eventState) ~= "table" or eventState.active ~= true or type(runtime) ~= "table" then
        return nil
    end
    return type(CombatState.CloneRuntimeState) == "function" and CombatState.CloneRuntimeState({
        auras = runtime.auras or {},
        spellcasts = runtime.spellcasts or {},
        cooldowns = runtime.cooldowns or {},
        defensiveReactions = runtime.turnState and runtime.turnState.defensiveReactions or {},
    }) or nil
end

local function buildRuntimeStateOperation(server)
    local eventState = server.EventState
    local runtimeState = server:ExportEventCombatRuntime()
    if type(eventState) ~= "table" or type(runtimeState) ~= "table" or EVENT_RUNTIME_STATE_OPCODE == nil then
        return nil
    end
    local runtimePayload = type(CombatState.SerializeRuntimeState) == "function" and CombatState.SerializeRuntimeState(runtimeState) or nil
    if not runtimePayload then
        return nil
    end
    local arguments = {
        tostring(eventState.channelName or ""),
        tostring(eventState.id or ""),
        runtimePayload,
    }
    return {
        opcode = EVENT_RUNTIME_STATE_OPCODE,
        sender = localPlayerName(),
        payload = Serialization:SerializeArguments(arguments),
    }
end

local function appendOperation(context, operation)
    if type(context) ~= "table" or type(operation) ~= "table" or tonumber(operation.opcode) == nil then
        return false
    end
    context.operations = context.operations or {}
    context.operations[#context.operations + 1] = operation
    return true
end

local function appendRuntimeStateOperation(server, context)
    local operation = buildRuntimeStateOperation(server)
    return operation and appendOperation(context, operation) or false
end

-- -------------------------------------------------------------------------
-- Client full-state committed operation.
-- -------------------------------------------------------------------------

function Client:HandleEventRuntimeState(arguments, sender)
    if self.EventSyncApplyingCommittedMutation ~= true then
        return false
    end
    local sessionState = type(self.GetState) == "function" and self:GetState() or self.State
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
    if type(sessionState) ~= "table" or sessionState.active ~= true
        or type(eventState) ~= "table" or eventState.active ~= true
        or tostring(arguments and arguments[1] or "") ~= tostring(sessionState.channelName or "")
        or tostring(arguments and arguments[2] or "") ~= tostring(eventState.id or "")
    then
        return false
    end
    local expectedHost = normalizeName(eventState.hostName)
    if expectedHost ~= "" and normalizeName(sender) ~= expectedHost then
        return false
    end
    local runtimeState, reason = type(CombatState.DeserializeRuntimeState) == "function"
        and CombatState.DeserializeRuntimeState(arguments and arguments[3] or "") or nil, "codec-unavailable"
    if type(runtimeState) ~= "table" then
        logError("Event combat runtime replacement rejected: %s", tostring(reason or "decode"))
        return false
    end

    if type(AuraManager) == "table" and type(AuraManager.ReplaceEventAuraState) == "function"
        and AuraManager:ReplaceEventAuraState(self, eventState, runtimeState.auras, { refresh = false }) ~= true
    then
        return false
    end
    if type(Spellcasting.ReplaceEventCastState) == "function"
        and Spellcasting.ReplaceEventCastState(self, eventState.id, runtimeState.spellcasts, { refresh = false }) ~= true
    then
        return false
    end
    if type(Spellcasting.ReplaceEventCooldownState) == "function"
        and Spellcasting.ReplaceEventCooldownState(self, eventState.id, runtimeState.cooldowns, { refresh = false }) ~= true
    then
        return false
    end
    if type(Combat.ReplaceDefensiveReactionUseLedger) == "function" then
        Combat:ReplaceDefensiveReactionUseLedger(runtimeState.defensiveReactions)
    end

    self.PendingDefensiveReactionUses = self.PendingDefensiveReactionUses or {}
    local committedUses = runtimeState.defensiveReactions and runtimeState.defensiveReactions.uses or {}
    for identity in pairs(self.PendingDefensiveReactionUses) do
        if committedUses[identity] ~= nil then
            self.PendingDefensiveReactionUses[identity] = nil
        end
    end

    if type(self.QueueActionBarRefresh) == "function" then
        self:QueueActionBarRefresh("event-runtime-state")
    end
    if type(AuraManager) == "table" and type(AuraManager.QueueLocalPlayerDerivedStateRefresh) == "function" then
        AuraManager:QueueLocalPlayerDerivedStateRefresh(eventState, { reason = "event-runtime-state" })
    end
    logInternal(
        "Event combat runtime installed event=%s auras=%d casts=%d cooldownUnits=%d defensiveUses=%d.",
        tostring(eventState.id or ""),
        #(runtimeState.auras or {}),
        (function() local n=0 for _ in pairs(runtimeState.spellcasts or {}) do n=n+1 end return n end)(),
        (function() local n=0 for _ in pairs(runtimeState.cooldowns or {}) do n=n+1 end return n end)(),
        (function() local n=0 for _ in pairs(committedUses) do n=n+1 end return n end)()
    )
    return true
end

-- -------------------------------------------------------------------------
-- Revisioned commit application extension.  #234 remains the fast path for
-- commits containing only its foundation operations.
-- -------------------------------------------------------------------------

local baseHandleCommittedEventMutation = Client.HandleCommittedEventMutation
local combatCommittedHandlers = {
    [EVENT_STATE_OPCODE or -1] = "HandleEventState",
    [EVENT_UNIT_DELTA_BATCH_OPCODE or -2] = "HandleEventUnitDeltaBatch",
    [RESOURCE_OPCODE or -3] = "HandleResource",
    [RESOURCE_DELTA_OPCODE or -4] = "HandleResourceDelta",
    [RESOURCE_DELTA_BATCH_OPCODE or -5] = "HandleResourceDeltaBatch",
    [AURA_APPLY_OPCODE or -6] = "HandleAuraApply",
    [AURA_DISPEL_OPCODE or -7] = "HandleAuraDispel",
    [AURA_APPLY_BATCH_OPCODE or -8] = "HandleAuraApplyBatch",
    [AURA_DISPEL_BATCH_OPCODE or -9] = "HandleAuraDispelBatch",
    [SPELLCAST_START_OPCODE or -10] = "HandleSpellcastStart",
    [SPELLCAST_COMPLETE_OPCODE or -11] = "HandleSpellcastComplete",
    [SPELLCAST_INTERRUPT_OPCODE or -12] = "HandleSpellcastInterrupt",
    [EVENT_RUNTIME_STATE_OPCODE or -13] = "HandleEventRuntimeState",
}

local function commitHasCombatState(commit)
    for index = 1, #(commit and commit.operations or {}) do
        local opcode = tonumber(commit.operations[index] and commit.operations[index].opcode) or 0
        if opcode == EVENT_RUNTIME_STATE_OPCODE
            or opcode == AURA_APPLY_OPCODE or opcode == AURA_DISPEL_OPCODE
            or opcode == AURA_APPLY_BATCH_OPCODE or opcode == AURA_DISPEL_BATCH_OPCODE
            or opcode == SPELLCAST_START_OPCODE or opcode == SPELLCAST_COMPLETE_OPCODE or opcode == SPELLCAST_INTERRUPT_OPCODE
        then
            return true
        end
    end
    return false
end

local function captureCommitRollback(client, eventState, sessionState)
    local rollback = {
        turnNumber = eventState.turnNumber,
        tickNumber = eventState.tickNumber,
        totalTicks = eventState.totalTicks,
        unitsPayload = type(eventState.SerializeUnitsForNetwork) == "function" and eventState:SerializeUnitsForNetwork() or nil,
        members = cloneResourcesByMember(sessionState),
        runtime = exportClientRuntime(eventState),
    }
    return rollback
end

local function restoreCommitRollback(client, eventState, sessionState, rollback)
    if type(rollback) ~= "table" then
        return
    end
    eventState.turnNumber = rollback.turnNumber
    eventState.tickNumber = rollback.tickNumber
    eventState.totalTicks = rollback.totalTicks
    if type(rollback.unitsPayload) == "string" and type(Event) == "table" and type(Event.DeserializeUnitsFromNetwork) == "function" then
        eventState.units = Event.DeserializeUnitsFromNetwork(rollback.unitsPayload)
    end
    for name, resources in pairs(rollback.members or {}) do
        local member = type(sessionState.membersByName) == "table" and sessionState.membersByName[name] or nil
        if type(member) == "table" then
            member.resources = type(CombatState.CloneValue) == "function" and CombatState.CloneValue(resources) or resources
        end
    end
    if type(AuraManager) == "table" and type(AuraManager.ReplaceEventAuraState) == "function" then
        AuraManager:ReplaceEventAuraState(client, eventState, rollback.runtime.auras, { refresh = false })
    end
    if type(Spellcasting.ReplaceEventCastState) == "function" then
        Spellcasting.ReplaceEventCastState(client, eventState.id, rollback.runtime.spellcasts, { refresh = false })
    end
    if type(Spellcasting.ReplaceEventCooldownState) == "function" then
        Spellcasting.ReplaceEventCooldownState(client, eventState.id, rollback.runtime.cooldowns, { refresh = false })
    end
    if type(Combat.ReplaceDefensiveReactionUseLedger) == "function" then
        Combat:ReplaceDefensiveReactionUseLedger(rollback.runtime.defensiveReactions)
    end
end

function Client:HandleCommittedEventMutation(payload, sender)
    local commit = type(EventSync.DeserializeMutationCommit) == "function" and EventSync.DeserializeMutationCommit(payload) or nil
    if type(commit) ~= "table" or not commitHasCombatState(commit) then
        return type(baseHandleCommittedEventMutation) == "function" and baseHandleCommittedEventMutation(self, payload, sender) or false
    end
    if type(EventSync.IsProtocolCompatible) ~= "function" or EventSync.IsProtocolCompatible(commit.protocolVersion) ~= true then
        return false
    end
    local sessionState = type(self.GetState) == "function" and self:GetState() or self.State
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
    if type(sessionState) ~= "table" or sessionState.active ~= true
        or type(eventState) ~= "table" or eventState.active ~= true
        or commit.channelName ~= tostring(sessionState.channelName or "")
        or commit.eventId ~= tostring(eventState.id or "")
        or (normalizeName(eventState.hostName) ~= "" and normalizeName(sender) ~= normalizeName(eventState.hostName))
    then
        return false
    end

    local syncState = type(self.GetEventSyncState) == "function" and self:GetEventSyncState(true) or self.EventSyncState
    if type(syncState) ~= "table" then
        return false
    end
    if tostring(syncState.eventId or "") ~= commit.eventId or syncState.pipelineActive ~= true then
        syncState = self:InitializeEventSyncForEvent(commit.eventId, 0)
    end
    local appliedRevision = type(EventSync.NormalizeRevision) == "function" and (EventSync.NormalizeRevision(syncState.appliedRevision) or 0) or 0
    if commit.revision <= appliedRevision then
        return true
    end
    syncState.bufferedCommits = syncState.bufferedCommits or {}
    if syncState.status == "syncing" or commit.revision > appliedRevision + 1 then
        syncState.bufferedCommits[commit.revision] = commit
        syncState.status = "syncing"
        syncState.reason = syncState.reason or "revision-gap"
        syncState.repairRequested = false
        if type(self.RequestEventSyncRepair) == "function" then
            self:RequestEventSyncRepair(syncState.reason)
        end
        return true
    end

    for index = 1, #(commit.operations or {}) do
        local operation = commit.operations[index]
        if type(combatCommittedHandlers[tonumber(operation and operation.opcode) or 0]) ~= "string" then
            syncState.status = "syncing"
            syncState.reason = "unsupported-combat-commit-operation"
            syncState.bufferedCommits[commit.revision] = commit
            if type(self.RequestEventSyncRepair) == "function" then
                self:RequestEventSyncRepair(syncState.reason)
            end
            return false
        end
    end

    local rollback = captureCommitRollback(self, eventState, sessionState)
    self.EventSyncApplyingCommittedMutation = true
    local success = true
    local failureReason = nil
    for index = 1, #(commit.operations or {}) do
        local operation = commit.operations[index]
        local handlerName = combatCommittedHandlers[operation.opcode]
        local handler = self[handlerName]
        local arguments = Serialization:DeserializeArguments(operation.payload or "")
        local ok, result = pcall(handler, self, arguments, operation.sender, "EVENT_SYNC", nil, {
            opcode = operation.opcode,
            argumentsText = operation.payload,
            arguments = arguments,
            eventSyncCommit = true,
            eventSyncRevision = commit.revision,
        })
        if not ok or result == false and operation.opcode == EVENT_RUNTIME_STATE_OPCODE then
            success = false
            failureReason = ok and (handlerName .. "-rejected") or tostring(result)
            break
        end
    end
    self.EventSyncApplyingCommittedMutation = false

    if not success then
        restoreCommitRollback(self, eventState, sessionState, rollback)
        syncState.bufferedCommits[commit.revision] = commit
        syncState.status = "syncing"
        syncState.reason = "combat-commit-apply-failed"
        syncState.repairRequested = false
        logError("Event combat commit apply failed event=%s revision=%s reason=%s", commit.eventId, tostring(commit.revision), tostring(failureReason))
        if type(self.RequestEventSyncRepair) == "function" then
            self:RequestEventSyncRepair(syncState.reason)
        end
        return false
    end

    syncState.appliedRevision = commit.revision
    logInternal("Event combat commit applied event=%s revision=%d operations=%d.", commit.eventId, commit.revision, #(commit.operations or {}))
    return true
end

-- -------------------------------------------------------------------------
-- Proposal routing and host validation.
-- -------------------------------------------------------------------------

local combatProposalOpcodes = {
    [AURA_APPLY_OPCODE or -1] = true,
    [AURA_DISPEL_OPCODE or -2] = true,
    [AURA_APPLY_BATCH_OPCODE or -3] = true,
    [AURA_DISPEL_BATCH_OPCODE or -4] = true,
    [SPELLCAST_START_OPCODE or -5] = true,
    [SPELLCAST_COMPLETE_OPCODE or -6] = true,
    [SPELLCAST_INTERRUPT_OPCODE or -7] = true,
    [EVENT_DEFENSIVE_USE_OPCODE or -8] = true,
}

local auraProposalOpcodes = {
    [AURA_APPLY_OPCODE or -1] = "HandleAuraApply",
    [AURA_DISPEL_OPCODE or -2] = "HandleAuraDispel",
    [AURA_APPLY_BATCH_OPCODE or -3] = "HandleAuraApplyBatch",
    [AURA_DISPEL_BATCH_OPCODE or -4] = "HandleAuraDispelBatch",
}

local rawServerSpellHandlers = {
    [SPELLCAST_START_OPCODE or -1] = Server.HandleSpellcastStart,
    [SPELLCAST_COMPLETE_OPCODE or -2] = Server.HandleSpellcastComplete,
    [SPELLCAST_INTERRUPT_OPCODE or -3] = Server.HandleSpellcastInterrupt,
}
local clientSpellHandlers = {
    [SPELLCAST_START_OPCODE or -1] = "HandleSpellcastStart",
    [SPELLCAST_COMPLETE_OPCODE or -2] = "HandleSpellcastComplete",
    [SPELLCAST_INTERRUPT_OPCODE or -3] = "HandleSpellcastInterrupt",
}

local function validateCommonProposal(server, request, sender)
    local state = server.State
    local eventState = server.EventState
    local runtime = server.EventRuntime
    local senderName = normalizeName(sender)
    if type(state) ~= "table" or state.active ~= true
        or type(eventState) ~= "table" or eventState.active ~= true
        or type(runtime) ~= "table" or tostring(runtime.eventId or "") ~= tostring(eventState.id or "")
        or request.channelName ~= tostring(state.channelName or "")
        or request.eventId ~= tostring(eventState.id or "")
        or senderName == ""
        or type(EventSync.IsProtocolCompatible) ~= "function" or EventSync.IsProtocolCompatible(request.protocolVersion) ~= true
    then
        return nil
    end
    if senderName ~= localPlayerName()
        and type(server.IsClientEventSyncCompatible) == "function"
        and server:IsClientEventSyncCompatible(senderName, state) ~= true
    then
        return nil
    end
    return senderName
end

local function sanitizeCastMetadata(eventState, trusted, candidate)
    if type(trusted) ~= "table" then
        return nil
    end
    local record = type(CombatState.CloneCastEntry) == "function" and CombatState.CloneCastEntry({
        spellRef = trusted.spellRef,
        spellName = trusted.spellName,
        authorityType = trusted.authorityType,
        casterEventId = trusted.casterEventId,
        turnsTotal = trusted.turnsTotal,
        turnsElapsed = 0,
        turnsRemaining = trusted.turnsTotal,
        startedOnTurnNumber = trusted.startedOnTurnNumber or (eventState and eventState.turnNumber) or 1,
        completeOnTurnNumber = trusted.completeOnTurnNumber,
        lastAdvancedTurnNumber = trusted.lastAdvancedTurnNumber or trusted.startedOnTurnNumber or (eventState and eventState.turnNumber) or 1,
        targetSelections = type(candidate) == "table" and candidate.targetSelections or nil,
        targetSelectionOrder = type(candidate) == "table" and candidate.targetSelectionOrder or nil,
        targetEventIds = type(candidate) == "table" and candidate.targetEventIds or nil,
        focusedTargetEventId = type(candidate) == "table" and candidate.focusedTargetEventId or nil,
        targetPolicy = type(candidate) == "table" and candidate.targetPolicy or nil,
        resolvedStartCostAmounts = type(candidate) == "table" and candidate.resolvedStartCostAmounts or nil,
    }) or nil
    if not record then
        return nil
    end
    local validTargets = {}
    for index = 1, #(record.targetEventIds or {}) do
        if eventUnitExists(eventState, record.targetEventIds[index]) then
            validTargets[#validTargets + 1] = record.targetEventIds[index]
        end
    end
    record.targetEventIds = validTargets
    if record.focusedTargetEventId > 0 and not eventUnitExists(eventState, record.focusedTargetEventId) then
        record.focusedTargetEventId = 0
    end
    return record
end

local function installCooldownCandidateForCaster(candidateRuntime, eventId, casterEventId)
    local candidate = type(candidateRuntime) == "table" and candidateRuntime.cooldowns or nil
    local unitState = type(candidate) == "table" and candidate[tonumber(casterEventId) or 0] or nil
    local normalized = type(CombatState.CloneCooldownUnitState) == "function" and CombatState.CloneCooldownUnitState(unitState) or nil
    if not normalized then
        return false
    end
    Client.CooldownsByEventId = Client.CooldownsByEventId or {}
    Client.CooldownsByEventId[eventId] = Client.CooldownsByEventId[eventId] or {}
    Client.CooldownsByEventId[eventId][tonumber(casterEventId)] = normalized
    return true
end

local function buildDefensiveIdentity(eventId, turnNumber, defenderEventId, resolutionSystem, statRef)
    local normalizedEventId = string.lower(tostring(eventId or ""))
    local normalizedResolution = string.lower(tostring(resolutionSystem or ""))
    local normalizedStatRef = string.lower(tostring(statRef or ""))
    if normalizedEventId == "" or normalizedResolution == "" or normalizedStatRef == "" then
        return nil
    end
    return table.concat({ normalizedEventId, tostring(math.floor(tonumber(turnNumber) or 0)), tostring(math.floor(tonumber(defenderEventId) or 0)), normalizedResolution, normalizedStatRef }, "\31")
end

local rawConsumeDefensiveReactionUse = Combat.ConsumeDefensiveReactionUse
local rawCanUseDefensiveReaction = Combat.CanUseDefensiveReaction

local function applyDefensiveProposal(server, arguments, senderName)
    local eventState = server.EventState
    local eventId = tostring(arguments and arguments[2] or "")
    local turnNumber = math.floor(tonumber(arguments and arguments[3]) or 0)
    local defenderEventId = math.floor(tonumber(arguments and arguments[4]) or 0)
    local resolutionSystem = tostring(arguments and arguments[5] or "")
    local statRef = tostring(arguments and arguments[6] or "")
    if eventId ~= tostring(eventState.id or "") or turnNumber ~= math.floor(tonumber(eventState.turnNumber) or 0) then
        return false
    end
    local defender = findEventUnit(eventState, defenderEventId)
    if not defender or resolveControllerName(eventState, defender) ~= senderName then
        return false
    end

    local runtimeDefensive = server.EventRuntime.turnState and server.EventRuntime.turnState.defensiveReactions or nil
    if type(Combat.ReplaceDefensiveReactionUseLedger) == "function" then
        Combat:ReplaceDefensiveReactionUseLedger(runtimeDefensive or { eventId = eventId, turnNumber = turnNumber, uses = {} })
    end
    local entry = {
        eventState = eventState,
        eventId = eventId,
        turnNumber = turnNumber,
        defenderEventId = defenderEventId,
        defenderUnit = defender,
        defenceSystem = resolutionSystem,
    }
    local action = {
        enabled = true,
        resolutionSystem = resolutionSystem,
        statRef = statRef,
    }
    if type(rawCanUseDefensiveReaction) == "function" then
        local available = rawCanUseDefensiveReaction(Combat, entry, action)
        if available ~= true then
            logInternal("Event defensive use rejected duplicate/invalid event=%s turn=%d defender=%d stat=%s.", eventId, turnNumber, defenderEventId, statRef)
            return false
        end
    end
    if type(rawConsumeDefensiveReactionUse) ~= "function" then
        return false
    end
    local consumed = rawConsumeDefensiveReactionUse(Combat, entry, action)
    return consumed == true
end

local function applyCombatProposal(server, request, proposal, senderName)
    local arguments = Serialization:DeserializeArguments(proposal.domainPayload or "")
    local eventState = server.EventState
    local context = server.EventMutationContext
    local ownsContext = type(context) ~= "table"
    if ownsContext then
        context = { eventId = tostring(eventState.id or ""), operations = {} }
        server.EventMutationContext = context
    end

    server.EventCombatApplyingMutationRequest = true
    Client.EventCombatApplyingHostProposal = true
    local ok = false
    local candidateRuntime = proposal.runtimeState
    if auraProposalOpcodes[request.opcode] then
        local handler = Client[auraProposalOpcodes[request.opcode]]
        ok = type(handler) == "function" and handler(Client, arguments, senderName) == true
    elseif clientSpellHandlers[request.opcode] then
        local rawServerHandler = rawServerSpellHandlers[request.opcode]
        local serverAccepted = type(rawServerHandler) == "function" and rawServerHandler(server, arguments, senderName) == true
        local clientHandler = Client[clientSpellHandlers[request.opcode]]
        local clientAccepted = type(clientHandler) == "function" and clientHandler(Client, arguments, senderName) == true
        ok = serverAccepted and clientAccepted
        local casterEventId = tonumber(arguments[3]) or 0
        if ok and request.opcode == SPELLCAST_START_OPCODE then
            local serverEntry = server.GetSpellcastEntry and server:GetSpellcastEntry(eventState.id, casterEventId) or nil
            local candidate = type(candidateRuntime) == "table" and candidateRuntime.spellcasts and candidateRuntime.spellcasts[casterEventId] or nil
            local canonical = sanitizeCastMetadata(eventState, serverEntry, candidate)
            if canonical then
                server.ActiveSpellcastsByEventId[eventState.id] = server.ActiveSpellcastsByEventId[eventState.id] or {}
                server.ActiveSpellcastsByEventId[eventState.id][casterEventId] = canonical
                if type(Spellcasting.SetCastEntry) == "function" then
                    Spellcasting.SetCastEntry(Client, eventState.id, casterEventId, canonical)
                end
            end
            installCooldownCandidateForCaster(candidateRuntime, eventState.id, casterEventId)
        elseif ok and request.opcode == SPELLCAST_COMPLETE_OPCODE then
            installCooldownCandidateForCaster(candidateRuntime, eventState.id, casterEventId)
        end
    elseif request.opcode == EVENT_DEFENSIVE_USE_OPCODE then
        ok = applyDefensiveProposal(server, arguments, senderName)
    end
    Client.EventCombatApplyingHostProposal = false
    server.EventCombatApplyingMutationRequest = false

    if ok then
        server:SyncEventCombatRuntimeFromLocalClient()
        appendOperation(context, {
            opcode = request.opcode,
            sender = senderName,
            payload = proposal.domainPayload,
        })
        appendRuntimeStateOperation(server, context)
    end

    if ownsContext and server.EventMutationContext == context then
        server.EventMutationContext = nil
    end
    if not ok then
        return false
    end
    if not ownsContext then
        return true
    end
    local revision = server:CommitEventMutation(eventState.id, context.operations, nil, { alreadyApplied = true })
    return revision ~= nil
end

local baseHandleEventMutationRequest = Server.HandleEventMutationRequest
function Server:HandleEventMutationRequest(payload, sender)
    local request = type(EventSync.DeserializeMutationRequest) == "function" and EventSync.DeserializeMutationRequest(payload) or nil
    if type(request) ~= "table" or combatProposalOpcodes[request.opcode] ~= true then
        return type(baseHandleEventMutationRequest) == "function" and baseHandleEventMutationRequest(self, payload, sender) or false
    end
    local senderName = validateCommonProposal(self, request, sender)
    if not senderName then
        return false
    end
    local proposal, reason = type(CombatState.DeserializeDomainProposal) == "function" and CombatState.DeserializeDomainProposal(request.payload) or nil, "codec-unavailable"
    if not proposal then
        logInternal("Event combat proposal rejected sender=%s opcode=%s reason=%s.", tostring(senderName), tostring(request.opcode), tostring(reason))
        return false
    end
    local arguments = Serialization:DeserializeArguments(proposal.domainPayload or "")
    if tostring(arguments[1] or "") ~= tostring(self.State and self.State.channelName or "")
        or tostring(arguments[2] or "") ~= tostring(self.EventState and self.EventState.id or "")
    then
        return false
    end
    local applied = applyCombatProposal(self, request, proposal, senderName)
    logInternal("Event combat proposal sender=%s opcode=%s accepted=%s revision=%s.", senderName, tostring(request.opcode), tostring(applied), tostring(self.EventRuntime and self.EventRuntime.revision or 0))
    return applied
end

-- Reject legacy unstamped active-event combat runtime messages.  Host proposal
-- application and revisioned commit application are the two explicit bypasses.
local function shouldRejectUnstampedCombatClient(client)
    if client.EventSyncApplyingCommittedMutation == true or client.EventCombatApplyingHostProposal == true then
        return false
    end
    local eventState = type(client.GetEventState) == "function" and client:GetEventState() or client.EventState
    local syncState = type(client.GetEventSyncState) == "function" and client:GetEventSyncState(false) or client.EventSyncState
    return type(eventState) == "table" and eventState.active == true
        and type(syncState) == "table" and syncState.pipelineActive == true
        and tostring(syncState.eventId or "") == tostring(eventState.id or "")
end

for _, handlerName in ipairs({
    "HandleAuraApply", "HandleAuraDispel", "HandleAuraApplyBatch", "HandleAuraDispelBatch",
    "HandleSpellcastStart", "HandleSpellcastComplete", "HandleSpellcastInterrupt",
}) do
    local baseHandler = Client[handlerName]
    if type(baseHandler) == "function" then
        Client[handlerName] = function(self, arguments, sender, ...)
            if shouldRejectUnstampedCombatClient(self) then
                logInternal("Event combat discarded unstamped %s from %s.", handlerName, tostring(sender or "unknown"))
                return false
            end
            return baseHandler(self, arguments, sender, ...)
        end
    end
end

for opcode, rawHandler in pairs(rawServerSpellHandlers) do
    if type(rawHandler) == "function" then
        local handlerName = opcode == SPELLCAST_START_OPCODE and "HandleSpellcastStart"
            or opcode == SPELLCAST_COMPLETE_OPCODE and "HandleSpellcastComplete"
            or "HandleSpellcastInterrupt"
        Server[handlerName] = function(self, arguments, sender, ...)
            if type(self.EventRuntime) == "table" and self.EventCombatApplyingMutationRequest ~= true then
                return false
            end
            return rawHandler(self, arguments, sender, ...)
        end
    end
end

local function buildProposalRuntimeState()
    local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
    return type(eventState) == "table" and exportClientRuntime(eventState) or nil
end

local function sendCombatMutationRequest(channelId, opcode, arguments, metadata)
    local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
    local sessionState = type(Client.GetState) == "function" and Client:GetState() or Client.State
    if type(eventState) ~= "table" or eventState.active ~= true or type(sessionState) ~= "table" or sessionState.active ~= true then
        return false
    end
    local domainPayload = Serialization:SerializeArguments(arguments or {})
    local proposalPayload = CombatState.SerializeDomainProposal(domainPayload, buildProposalRuntimeState())
    local requestPayload = EventSync.SerializeMutationRequest({
        protocolVersion = EventSync.ProtocolVersion,
        channelName = sessionState.channelName,
        eventId = eventState.id,
        opcode = opcode,
        payload = proposalPayload,
    })
    if not requestPayload then
        return false
    end

    if type(Server.EventRuntime) == "table" and Client.EventSyncApplyingCommittedMutation ~= true then
        return Server:HandleEventMutationRequest(requestPayload, localPlayerName()) == true
    end

    local requestMetadata = {}
    for key, value in pairs(metadata or {}) do
        requestMetadata[key] = value
    end
    requestMetadata.opcode = EVENT_MUTATION_REQUEST_OPCODE
    requestMetadata.scope = "client"
    requestMetadata.eventCombatDomainOpcode = opcode
    return Comms._eventCombatBaseSendToChannel(
        Comms,
        channelId,
        EVENT_MUTATION_REQUEST_OPCODE,
        requestPayload,
        requestMetadata
    )
end

local function commitHostServerDomainOperation(opcode, arguments)
    local eventState = Server.EventState
    if type(eventState) ~= "table" or eventState.active ~= true or type(Server.EventRuntime) ~= "table" then
        return false
    end
    Server:SyncEventCombatRuntimeFromLocalClient()
    local context = Server.EventMutationContext
    local ownsContext = type(context) ~= "table"
    if ownsContext then
        context = { eventId = tostring(eventState.id or ""), operations = {} }
    end
    appendOperation(context, {
        opcode = opcode,
        sender = localPlayerName(),
        payload = Serialization:SerializeArguments(arguments or {}),
    })
    appendRuntimeStateOperation(Server, context)
    if not ownsContext then
        return true
    end
    local revision = Server:CommitEventMutation(eventState.id, context.operations, nil, { alreadyApplied = true })
    return revision ~= nil
end

local baseSendToChannel = Comms.SendToChannel
Comms._eventCombatBaseSendToChannel = baseSendToChannel
if type(baseSendToChannel) == "function" then
    Comms.SendToChannel = function(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
        local opcode = tonumber(opcodeOrPayload)
        if combatProposalOpcodes[opcode] == true and type(metadata) == "table" and metadata.scope == "client" then
            local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
            local syncState = type(Client.GetEventSyncState) == "function" and Client:GetEventSyncState(false) or Client.EventSyncState
            if type(eventState) == "table" and eventState.active == true
                and type(syncState) == "table" and syncState.pipelineActive == true
            then
                return sendCombatMutationRequest(channelId, opcode, argumentsOrMetadata, metadata)
            end
        end
        if (opcode == SPELLCAST_START_OPCODE or opcode == SPELLCAST_COMPLETE_OPCODE or opcode == SPELLCAST_INTERRUPT_OPCODE)
            and type(metadata) == "table" and metadata.scope == "server"
            and type(Server.EventRuntime) == "table"
        then
            return commitHostServerDomainOperation(opcode, argumentsOrMetadata)
        end
        return baseSendToChannel(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
    end
end

-- -------------------------------------------------------------------------
-- Defensive reaction proposals.  The existing synchronous check remains the
-- immediate UX guard; the use is tentative until the host commit replaces the
-- ledger.  This avoids treating client-only ledger destruction as authority.
-- -------------------------------------------------------------------------

local function normalizeDefensiveToken(value)
    local text = string.lower(tostring(value or ""))
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function defensiveIdentityFromEntry(entry, action)
    local eventState = type(entry) == "table" and entry.eventState or nil
    local eventId = tostring(type(entry) == "table" and (entry.eventId or (eventState and eventState.id)) or "")
    local turnNumber = math.floor(tonumber(type(entry) == "table" and (entry.turnNumber or (eventState and eventState.turnNumber)) or 0) or 0)
    local defenderEventId = math.floor(tonumber(type(entry) == "table" and (entry.defenderEventId or (entry.defenderUnit and entry.defenderUnit.eventID)) or 0) or 0)
    local resolutionSystem = normalizeDefensiveToken(type(action) == "table" and (action.resolutionSystem or action.id) or action)
    local statRef = normalizeDefensiveToken(type(action) == "table" and action.statRef or nil)
    return buildDefensiveIdentity(eventId, turnNumber, defenderEventId, resolutionSystem, statRef), eventId, turnNumber, defenderEventId, resolutionSystem, statRef
end

if type(rawCanUseDefensiveReaction) == "function" then
    function Combat:CanUseDefensiveReaction(entry, action)
        local allowed, reason = rawCanUseDefensiveReaction(self, entry, action)
        if allowed ~= true then
            return allowed, reason
        end
        local identity, _, turnNumber = defensiveIdentityFromEntry(entry, action)
        local pending = type(Client.PendingDefensiveReactionUses) == "table" and Client.PendingDefensiveReactionUses[identity] or nil
        if type(pending) == "table" and tonumber(pending.turnNumber) == tonumber(turnNumber) then
            return false, "used-this-turn"
        end
        return true
    end
end

if type(rawConsumeDefensiveReactionUse) == "function" then
    function Combat:ConsumeDefensiveReactionUse(entry, action)
        local eventState = type(entry) == "table" and entry.eventState or nil
        local syncState = type(Client.GetEventSyncState) == "function" and Client:GetEventSyncState(false) or Client.EventSyncState
        if type(eventState) ~= "table" or eventState.active ~= true
            or type(syncState) ~= "table" or syncState.pipelineActive ~= true
            or Client.EventCombatApplyingHostProposal == true
            or Client.EventSyncApplyingCommittedMutation == true
        then
            return rawConsumeDefensiveReactionUse(self, entry, action)
        end

        local previous = type(CombatState.CloneDefensiveState) == "function"
            and CombatState.CloneDefensiveState(self.DefensiveReactionUseLedger or {}) or self.DefensiveReactionUseLedger
        local consumed, reason = rawConsumeDefensiveReactionUse(self, entry, action)
        if consumed ~= true then
            return consumed, reason
        end
        local identity, eventId, turnNumber, defenderEventId, resolutionSystem, statRef = defensiveIdentityFromEntry(entry, action)
        if not identity then
            return true
        end
        local after = self.DefensiveReactionUseLedger
        local wasRestrictedUse = type(after) == "table" and type(after.uses) == "table" and after.uses[identity] == true
            and not (type(previous) == "table" and type(previous.uses) == "table" and previous.uses[identity] == true)
        if not wasRestrictedUse then
            return true
        end

        self:ReplaceDefensiveReactionUseLedger(previous)
        Client.PendingDefensiveReactionUses = Client.PendingDefensiveReactionUses or {}
        Client.PendingDefensiveReactionUses[identity] = { turnNumber = turnNumber }

        local sessionState = type(Client.GetState) == "function" and Client:GetState() or Client.State
        local channelId = resolveChannelId(sessionState)
        if not channelId then
            Client.PendingDefensiveReactionUses[identity] = nil
            return false, "channel-unavailable"
        end
        local sent = sendCombatMutationRequest(channelId, EVENT_DEFENSIVE_USE_OPCODE, {
            sessionState.channelName,
            eventId,
            turnNumber,
            defenderEventId,
            resolutionSystem,
            statRef,
        }, {
            opcode = EVENT_DEFENSIVE_USE_OPCODE,
            scope = "client",
        })
        if not sent then
            Client.PendingDefensiveReactionUses[identity] = nil
            return false, "defensive-use-send-failed"
        end
        return true
    end
end

-- -------------------------------------------------------------------------
-- Turn progression.  Cast/cooldown legality and prior-turn defensive use are
-- deterministic and are stamped in the same revision as EVENT_STATE.  Aura
-- duration progression remains owner-executed through the existing
-- AdvanceAuraEntry path; its full-state apply is now host-stamped immediately
-- when that owner progression completes, preserving tick side effects.
-- -------------------------------------------------------------------------

local function advanceHostDeterministicRuntime(server, previousTurnNumber)
    local eventState = server.EventState
    local runtime = server.EventRuntime
    if type(eventState) ~= "table" or type(runtime) ~= "table" then
        return false
    end
    local isCasterDue = function(unitEventId)
        return type(Spellcasting.IsCasterTurnOnTick) ~= "function"
            or Spellcasting.IsCasterTurnOnTick(eventState, unitEventId) == true
    end
    local castChanged, completed = type(CombatState.AdvanceCastBucket) == "function"
        and CombatState.AdvanceCastBucket(runtime.spellcasts or {}, eventState.turnNumber, isCasterDue)
        or false, {}
    for index = 1, #(completed or {}) do
        runtime.spellcasts[completed[index]] = nil
    end
    local cooldownChanged = type(CombatState.AdvanceCooldownBucket) == "function"
        and CombatState.AdvanceCooldownBucket(runtime.cooldowns or {}, eventState.turnNumber, isCasterDue)
        or false
    local defensiveChanged = false
    if tonumber(previousTurnNumber) ~= tonumber(eventState.turnNumber) then
        runtime.turnState = runtime.turnState or {}
        runtime.turnState.defensiveReactions = {
            eventId = tostring(eventState.id or ""),
            turnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1)),
            uses = {},
        }
        defensiveChanged = true
    end
    return castChanged == true or cooldownChanged == true or defensiveChanged == true
end

local baseAdvanceEventStepAfterCommit = Server._AdvanceEventStepAfterCommit
if type(baseAdvanceEventStepAfterCommit) == "function" then
    function Server:_AdvanceEventStepAfterCommit(commit, completed, ...)
        local eventState = self.EventState
        if type(eventState) ~= "table" or eventState.active ~= true or type(self.EventRuntime) ~= "table" then
            return baseAdvanceEventStepAfterCommit(self, commit, completed, ...)
        end
        if type(self.EventMutationContext) == "table" then
            local previousTurn = tonumber(eventState.turnNumber)
            local result = baseAdvanceEventStepAfterCommit(self, commit, completed, ...)
            if result == true then
                advanceHostDeterministicRuntime(self, previousTurn)
                appendRuntimeStateOperation(self, self.EventMutationContext)
            end
            return result
        end

        local previousTurn = tonumber(eventState.turnNumber)
        local context = { eventId = tostring(eventState.id or ""), operations = {} }
        self.EventMutationContext = context
        local ok, result = pcall(baseAdvanceEventStepAfterCommit, self, commit, completed, ...)
        if not ok then
            self.EventMutationContext = nil
            error(result, 0)
        end
        if result == true then
            advanceHostDeterministicRuntime(self, previousTurn)
            appendRuntimeStateOperation(self, context)
        end
        if self.EventMutationContext == context then
            self.EventMutationContext = nil
        end
        if result == true and #context.operations > 0 then
            self:CommitEventMutation(eventState.id, context.operations, nil, { alreadyApplied = true })
        end
        return result
    end
end

local baseStartEvent = Server.StartEvent
if type(baseStartEvent) == "function" then
    function Server:StartEvent(...)
        local result = baseStartEvent(self, ...)
        if type(result) == "table" and result.active == true and type(self.EventRuntime) == "table" then
            self:SyncEventCombatRuntimeFromLocalClient()
            self.EventRuntime.turnState = self.EventRuntime.turnState or {}
            self.EventRuntime.turnState.defensiveReactions = {
                eventId = tostring(result.id or ""),
                turnNumber = math.max(1, math.floor(tonumber(result.turnNumber) or 1)),
                uses = {},
            }
        end
        return result
    end
end

logInternal("Event combat authority integration loaded (runtime opcode=%s defensive opcode=%s).", tostring(EVENT_RUNTIME_STATE_OPCODE), tostring(EVENT_DEFENSIVE_USE_OPCODE))

return Server
