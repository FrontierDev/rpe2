local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Server = Addon.Server or {}
local Planner = Client.AutopilotPlanner or {}
local SpellEvaluator = Client.AutopilotSpellEvaluator or {}
local AuraEvaluator = Client.AutopilotAuraEvaluator or {}
local SequencePlanning = Client.AutopilotSequencePlanning or {}
local TargetSelector = Client.AutopilotTargetSelector or {}
local MovementSolver = Client.AutopilotMovementSolver or {}
local Spatial = Client.AutopilotSpatial or {}
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local Tasks = Addon.Internal.Tasks or {}
local Debug = Addon.Debug or {}

if type(Planner) ~= "table" or type(Event) ~= "table" then
    return
end

local baseResolveActiveNpcStep = Planner.ResolveActiveNpcStep
local baseBuildPlanIdentity = Planner.BuildPlanIdentity
local baseCreateState = Planner.CreateState
local baseReleaseScratch = Planner.ReleaseScratch

local function nowMilliseconds()
    if type(debugprofilestop) == "function" then
        return tonumber(debugprofilestop()) or 0
    end
    if type(GetTimePreciseSec) == "function" then
        return (tonumber(GetTimePreciseSec()) or 0) * 1000
    end
    if type(GetTime) == "function" then
        return (tonumber(GetTime()) or 0) * 1000
    end
    return 0
end

local function shouldYield(deadlineMs)
    return type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true
end

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end

local function normalizeRaidMarker(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function copyArray(values)
    local copied = {}
    for index = 1, #(values or {}) do
        copied[index] = values[index]
    end
    return copied
end

local function copyMap(values)
    local copied = {}
    for key, value in pairs(type(values) == "table" and values or {}) do
        copied[key] = value
    end
    return copied
end

local function copyPosition(position)
    if type(Spatial.CopyPosition) == "function" then
        return Spatial.CopyPosition(position)
    end
    return type(position) == "table" and copyMap(position) or nil
end

local function copyResourceEntries(entries)
    local copied = {}
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        copied[index] = type(entry) == "table" and copyMap(entry) or entry
    end
    return copied
end

local function copyStatEntries(entries)
    local copied = {}
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        copied[index] = type(entry) == "table" and copyMap(entry) or entry
    end
    return copied
end

local function copyThreatTable(values)
    local copied = {}
    for key, value in pairs(type(values) == "table" and values or {}) do
        local eventId = normalizeEventId(key)
        if eventId > 0 then
            copied[eventId] = tonumber(value) or 0
        end
    end
    return copied
end

local function copyTauntState(value)
    if type(value) ~= "table" then
        return nil
    end

    local sourceEventId = math.floor(tonumber(value.sourceEventId or value.sourceId) or 0)
    local remainingTurns = math.floor(tonumber(value.remainingTurns or value.duration) or 0)
    if sourceEventId <= 0 or remainingTurns <= 0 then
        return nil
    end

    return {
        sourceEventId = sourceEventId,
        remainingTurns = remainingTurns,
    }
end

local function buildTauntSignature(value)
    local tauntState = copyTauntState(value)
    if type(tauntState) ~= "table" then
        return "0:0"
    end
    return tostring(tauntState.sourceEventId) .. ":" .. tostring(tauntState.remainingTurns)
end

local function getHostLocalTauntState(eventState, targetEventId)
    if type(eventState) ~= "table" then
        return nil
    end

    local eventId = tostring(eventState.id or "")
    local normalizedTargetEventId = normalizeEventId(targetEventId)
    local runtimeByEventId = type(Server.EventTauntRuntimeByEventId) == "table"
        and Server.EventTauntRuntimeByEventId
        or nil
    local eventRuntime = eventId ~= "" and runtimeByEventId and runtimeByEventId[eventId] or nil
    local targetRuntime = type(eventRuntime) == "table"
        and type(eventRuntime.targets) == "table"
        and eventRuntime.targets[normalizedTargetEventId]
        or nil
    return copyTauntState(targetRuntime)
end

Planner.GetHostLocalTauntState = getHostLocalTauntState

local function buildEntryListSignature(entries, fields)
    local records = {}
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        local parts = {}
        for fieldIndex = 1, #fields do
            local value = type(entry) == "table" and entry[fields[fieldIndex]] or nil
            parts[fieldIndex] = tostring(value == nil and "" or value)
        end
        records[index] = table.concat(parts, "\30")
    end
    return table.concat(records, "\29")
end

local function buildThreatSignature(values)
    local keys = {}
    for key in pairs(type(values) == "table" and values or {}) do
        local eventId = normalizeEventId(key)
        if eventId > 0 then
            keys[#keys + 1] = eventId
        end
    end
    table.sort(keys)
    local records = {}
    for index = 1, #keys do
        local eventId = keys[index]
        records[index] = tostring(eventId) .. "=" .. tostring(tonumber(values[eventId]) or 0)
    end
    return table.concat(records, "\29")
end

local function buildUnitFrozenSignature(unit)
    return table.concat({
        tostring(normalizeEventId(unit and unit.eventID)),
        unit and unit.isPlayer == true and "1" or "0",
        tostring(unit and unit.active ~= false and 1 or 0),
        tostring(unit and unit.dead == true and 1 or 0),
        tostring(tonumber(unit and unit.team) or 0),
        tostring(normalizeRaidMarker(unit and unit.raidMarker)),
        buildEntryListSignature(unit and unit.resources, { "resourceRef", "currentValue", "maxValue" }),
        buildEntryListSignature(unit and unit.stats, { "statRef", "value", "currentValue" }),
        buildThreatSignature(unit and unit.threatTable),
        buildTauntSignature(unit and unit.tauntState),
    }, "\31")
end

local function buildPositionSignature(position)
    if type(position) ~= "table" then
        return "missing"
    end
    return table.concat({
        position.available == false and "0" or "1",
        tostring(position.x == nil and "" or position.x),
        tostring(position.y == nil and "" or position.y),
        tostring(position.instanceID == nil and "" or position.instanceID),
        tostring(position.reason or ""),
    }, "\31")
end

local function cloneEventUnit(unit)
    if type(unit) ~= "table" then
        return nil
    end

    local copy = {}
    for key, value in pairs(unit) do
        if type(value) ~= "table" then
            copy[key] = value
        end
    end

    copy.resources = copyResourceEntries(unit.resources)
    copy.stats = copyStatEntries(unit.stats)
    copy.spells = copyArray(unit.spells)
    copy.threatTable = copyThreatTable(unit.threatTable)
    copy._networkStatMode = unit._networkStatMode

    local mt = getmetatable(unit)
    if mt ~= nil then
        setmetatable(copy, mt)
    end
    return copy
end

local function cloneEventShell(eventState)
    local frozen = {}
    for key, value in pairs(type(eventState) == "table" and eventState or {}) do
        if key ~= "units" and type(value) ~= "table" then
            frozen[key] = value
        end
    end
    frozen.units = {}
    frozen.lootRefs = copyArray(eventState and eventState.lootRefs)
    frozen.eventAuras = {}
    for index = 1, #((eventState and eventState.eventAuras) or {}) do
        local entry = eventState.eventAuras[index]
        frozen.eventAuras[index] = type(entry) == "table" and {
            auraRef = entry.auraRef,
            teamIndices = copyArray(entry.teamIndices),
        } or entry
    end
    frozen.teams = {}
    for index = 1, #((eventState and eventState.teams) or {}) do
        local team = eventState.teams[index]
        frozen.teams[index] = type(team) == "table" and {
            id = team.id,
            name = team.name,
            color = type(team.color) == "table" and copyMap(team.color) or nil,
        } or team
    end
    frozen.teamColors = {}
    for index = 1, #((eventState and eventState.teamColors) or {}) do
        frozen.teamColors[index] = type(eventState.teamColors[index]) == "table"
            and copyMap(eventState.teamColors[index])
            or eventState.teamColors[index]
    end
    local mt = getmetatable(eventState)
    if mt ~= nil then
        setmetatable(frozen, mt)
    end
    return frozen
end

local function isUnitActive(unit)
    if type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end
    return type(unit) == "table" and (unit.isPlayer == true or unit.active ~= false)
end

local function findUnitByEventId(units, eventId)
    local wanted = normalizeEventId(eventId)
    if wanted <= 0 then
        return nil
    end
    for index = 1, #(units or {}) do
        local unit = units[index]
        if normalizeEventId(unit and unit.eventID) == wanted then
            return unit, index
        end
    end
    return nil
end

local function getSpellcasting()
    return Addon.Client and Addon.Client.Spellcasting or nil
end

local function getAuraEvaluator()
    return Addon.Client and Addon.Client.AutopilotAuraEvaluator or AuraEvaluator
end

local function copyDeep(value)
    local evaluator = getAuraEvaluator()
    if type(evaluator) == "table" and type(evaluator.CopyValue) == "function" then
        return evaluator.CopyValue(value)
    end
    if type(value) ~= "table" then
        return value
    end
    local copied = {}
    for key, child in pairs(value) do
        copied[key] = type(child) == "table" and copyDeep(child) or child
    end
    return copied
end

local function getMovement()
    return RPE and RPE.Core and RPE.Core.Movement or nil
end

local function getEventAuraBucket(eventId)
    local buckets = type(Client.ActiveAurasByEventId) == "table" and Client.ActiveAurasByEventId or nil
    return type(buckets) == "table" and buckets[tostring(eventId or "")] or nil
end

local function getAuraRevision(eventId)
    local bucket = type(Client.ActiveAurasByEventId) == "table"
        and Client.ActiveAurasByEventId[tostring(eventId or "")]
        or nil
    return math.max(0, math.floor(tonumber(type(bucket) == "table" and bucket.revision or 0) or 0))
end

local MAX_SNAPSHOT_GENERATION_RETRIES = 3

local function getAuraBucketRevision(bucket)
    return math.max(0, math.floor(tonumber(type(bucket) == "table" and bucket.revision or 0) or 0))
end

local function getEventCastBucket(eventId)
    local buckets = type(Client.ActiveSpellcastsByEventId) == "table" and Client.ActiveSpellcastsByEventId or nil
    return type(buckets) == "table" and buckets[tostring(eventId or "")] or nil
end

local function getEventCastRevision(eventId, bucket)
    local spellcasting = getSpellcasting()
    if type(spellcasting) == "table" and type(spellcasting.GetEventCastRevision) == "function" then
        return math.max(0, math.floor(tonumber(spellcasting.GetEventCastRevision(Client, tostring(eventId or ""))) or 0))
    end
    return math.max(0, math.floor(tonumber(type(bucket) == "table" and bucket.revision or 0) or 0))
end

local function clearArray(values)
    if type(values) ~= "table" then
        return
    end
    for index = #values, 1, -1 do
        values[index] = nil
    end
end

local function clearMap(values)
    if type(values) ~= "table" then
        return
    end
    for key in pairs(values) do
        values[key] = nil
    end
end

local function clearAuraSnapshot(state)
    clearArray(state.snapshot.activeAuraRecords)
    clearMap(state.snapshot.activeAurasByTargetEventId)
    clearMap(state.snapshot.controlStateByTargetEventId)
    clearArray(state.scratch.auraKeys)
    state.cursors.auraKeyScan = nil
    state.cursors.auraScanComplete = false
    state.cursors.auraCopyIndex = 1
end

local function clearCastSnapshot(state)
    clearArray(state.snapshot.activeCastSummaries)
    clearMap(state.snapshot.activeCastsByEventId)
    clearArray(state.scratch.castKeys)
    state.cursors.castKeyScan = nil
    state.cursors.castScanComplete = false
    state.cursors.castCopyIndex = 1
end

local function captureAuraGeneration(state)
    local bucket = getEventAuraBucket(state.eventId)
    state.scratch.auraSourceBucket = bucket
    state.scratch.auraSourceRevision = getAuraBucketRevision(bucket)
    state.scratch.auraGenerationCaptured = true
    state.snapshot.auraRevision = state.scratch.auraSourceRevision
    clearAuraSnapshot(state)
end

local function auraGenerationIsCurrent(state)
    local bucket = state.scratch.auraSourceBucket
    return bucket == getEventAuraBucket(state.eventId)
        and getAuraBucketRevision(bucket) == state.scratch.auraSourceRevision
end

local function restartAuraGeneration(state)
    local retries = (tonumber(state.scratch.auraGenerationRetries) or 0) + 1
    state.scratch.auraGenerationRetries = retries
    if retries > MAX_SNAPSHOT_GENERATION_RETRIES then
        clearAuraSnapshot(state)
        state.failureReason = "aura-snapshot-stale"
        state.phase = "finalize"
        return false
    end
    captureAuraGeneration(state)
    return false
end

local function ensureAuraGeneration(state)
    if state.scratch.auraGenerationCaptured ~= true then
        captureAuraGeneration(state)
        return true
    end
    if not auraGenerationIsCurrent(state) then
        return restartAuraGeneration(state)
    end
    return true
end

local function captureCastGeneration(state)
    local bucket = getEventCastBucket(state.eventId)
    state.scratch.castSourceBucket = bucket
    state.scratch.castSourceRevision = getEventCastRevision(state.eventId, bucket)
    state.scratch.castGenerationCaptured = true
    clearCastSnapshot(state)
end

local function castGenerationIsCurrent(state)
    local bucket = state.scratch.castSourceBucket
    return bucket == getEventCastBucket(state.eventId)
        and getEventCastRevision(state.eventId, bucket) == state.scratch.castSourceRevision
end

local function restartCastGeneration(state)
    local retries = (tonumber(state.scratch.castGenerationRetries) or 0) + 1
    state.scratch.castGenerationRetries = retries
    if retries > MAX_SNAPSHOT_GENERATION_RETRIES then
        clearCastSnapshot(state)
        state.failureReason = "cast-snapshot-stale"
        state.phase = "finalize"
        return false
    end
    captureCastGeneration(state)
    return false
end

local function ensureCastGeneration(state)
    if state.scratch.castGenerationCaptured ~= true then
        captureCastGeneration(state)
        return true
    end
    if not castGenerationIsCurrent(state) then
        return restartCastGeneration(state)
    end
    return true
end

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function buildFrozenClientProxy(frozenEventState)
    return setmetatable({
        GetEventState = function()
            return frozenEventState
        end,
    }, {
        __index = Client,
    })
end

local function copyTargetSelectionMap(targetUnits, targetGroupKey)
    local eventIds = {}
    for index = 1, #(targetUnits or {}) do
        eventIds[index] = normalizeEventId(targetUnits[index] and targetUnits[index].eventID)
    end
    local key = tostring(targetGroupKey or "")
    if key == "" then
        key = "default"
    end
    return {
        [key] = eventIds,
    }, { key }, eventIds
end

local function compareCandidates(left, right)
    if type(SpellEvaluator.CompareCandidates) == "function" then
        return SpellEvaluator.CompareCandidates(left, right)
    end
    local leftUtility = tonumber(left and left.totalUtility) or 0
    local rightUtility = tonumber(right and right.totalUtility) or 0
    if leftUtility ~= rightUtility then
        return leftUtility > rightUtility and 1 or -1
    end
    local leftRef = tostring(left and left.spellRef or "")
    local rightRef = tostring(right and right.spellRef or "")
    if leftRef ~= rightRef then
        return leftRef < rightRef and 1 or -1
    end
    return 0
end

local function candidateRequiresMelee(candidate)
    if type(candidate) ~= "table" then
        return false
    end
    return type(candidate.damageTypes) == "table"
        and candidate.damageTypes.melee == true
        and (tonumber(candidate.damageUtility) or tonumber(candidate.expectedDamage) or 0) > 0
end

local function candidateTargets(candidate)
    if type(candidate) ~= "table" then
        return {}
    end
    if type(candidate.targetUnits) == "table" then
        return candidate.targetUnits
    end
    local target = candidate.targetUnit or candidate.primaryTargetUnit
    return type(target) == "table" and { target } or {}
end

local function isCandidateFeasibleAtPosition(state, candidate, position)
    if not candidateRequiresMelee(candidate) then
        return true
    end
    if type(position) ~= "table" then
        return false
    end
    local targets = candidateTargets(candidate)
    if #targets == 0 then
        return false
    end
    local range = tonumber(MovementSolver.MELEE_RANGE_YARDS) or 5
    for index = 1, #targets do
        local targetPosition = type(Spatial.GetCachedUnitPosition) == "function"
            and select(1, Spatial.GetCachedUnitPosition(state.snapshot.spatialRuntime, state.snapshot.eventState, targets[index]))
            or nil
        local distance = targetPosition
            and type(Spatial.DistanceBetweenPositions) == "function"
            and Spatial.DistanceBetweenPositions(position, targetPosition)
            or nil
        if tonumber(distance) == nil or tonumber(distance) > range + 0.0001 then
            return false
        end
    end
    return true
end

local function getActorPosition(state, actorKey)
    local runtime = state.snapshot and state.snapshot.spatialRuntime or nil
    local position = type(runtime) == "table"
        and type(runtime.positionByActorKey) == "table"
        and runtime.positionByActorKey[actorKey]
        or nil
    if type(position) ~= "table"
        or type(Spatial.IsPositionAvailable) ~= "function"
        or Spatial.IsPositionAvailable(position) ~= true
    then
        return nil
    end
    return position
end

local function appendWarning(state, warning)
    if type(warning) ~= "table" then
        return
    end
    state.output.warnings[#state.output.warnings + 1] = warning
end

local function appendNoAction(state, actorKey, unit, reason)
    local eventId = normalizeEventId(unit and unit.eventID)
    if eventId <= 0 then
        return
    end
    state.output.noActions[#state.output.noActions + 1] = {
        actionType = "no-action",
        actionId = ("%s:noaction:%d"):format(state.planId, eventId),
        planId = state.planId,
        actorKey = tostring(actorKey or ""),
        casterEventId = eventId,
        reason = tostring(reason or "no-useful-action"),
        status = "ready",
    }
end

local function buildSpellAction(state, actorKey, unit, candidate, movementActionId, sequenceIndex, sequenceCount, actionClass, previousActionId, actionEconomyEntry)
    local eventId = normalizeEventId(unit and unit.eventID)
    if eventId <= 0 or type(candidate) ~= "table" then
        return nil
    end

    local resolvedSequenceIndex = math.max(1, math.floor(tonumber(sequenceIndex) or 1))
    local resolvedSequenceCount = math.max(resolvedSequenceIndex, math.floor(tonumber(sequenceCount) or resolvedSequenceIndex))
    local selections, selectionOrder, targetEventIds = copyTargetSelectionMap(
        candidate.targetUnits,
        candidate.targetGroupKey
    )
    if #targetEventIds == 0 and normalizeEventId(candidate.targetEventId) > 0 then
        targetEventIds[1] = normalizeEventId(candidate.targetEventId)
        selections[selectionOrder[1]][1] = targetEventIds[1]
    end

    local action = {
        actionType = "spell",
        actionId = ("%s:spell:%d:%d"):format(state.planId, eventId, resolvedSequenceIndex),
        planId = state.planId,
        eventId = state.eventId,
        turnNumber = state.turnNumber,
        tickNumber = state.tickNumber,
        actorKey = tostring(actorKey or ""),
        casterEventId = eventId,
        spellRef = tostring(candidate.spellRef or ""),
        casterSequenceIndex = resolvedSequenceIndex,
        casterSequenceCount = resolvedSequenceCount,
        actionEconomyClass = tostring(actionClass or ""),
        cooldownChannelId = actionEconomyEntry and actionEconomyEntry.cooldownChannelId or nil,
        cooldownChannelName = actionEconomyEntry and actionEconomyEntry.cooldownChannelName or nil,
        cooldownChannelTriggersGCD = actionEconomyEntry
            and actionEconomyEntry.cooldownChannelTriggersGCD == true
            or false,
        previousCasterActionId = previousActionId,
        targetSelections = selections,
        targetSelectionOrder = selectionOrder,
        targetEventIds = targetEventIds,
        targetEventId = targetEventIds[1],
        totalUtility = tonumber(candidate.totalUtility) or 0,
        damageUtility = tonumber(candidate.damageUtility) or 0,
        healingUtility = tonumber(candidate.healingUtility) or 0,
        immediateDamage = tonumber(candidate.immediateDamage) or 0,
        periodicDamage = tonumber(candidate.periodicDamage) or 0,
        immediateHealing = tonumber(candidate.immediateHealing) or 0,
        periodicHealing = tonumber(candidate.periodicHealing) or 0,
        hasPeriodicDamage = candidate.hasPeriodicDamage == true or (tonumber(candidate.periodicDamage) or 0) ~= 0,
        hasPeriodicHealing = candidate.hasPeriodicHealing == true or (tonumber(candidate.periodicHealing) or 0) ~= 0,
        urgentHealing = candidate.urgentHealing == true,
        hasControl = candidate.hasControl == true,
        movementControlUtility = tonumber(candidate.movementControlUtility) or 0,
        castingPreventionUtility = tonumber(candidate.castingPreventionUtility) or 0,
        controlUtility = tonumber(candidate.controlUtility) or 0,
        hasInterrupt = candidate.hasInterrupt == true,
        hasUsefulInterrupt = candidate.hasUsefulInterrupt == true,
        urgentInterrupt = candidate.urgentInterrupt == true,
        interruptTargetEventId = normalizeEventId(candidate.interruptTargetEventId),
        interruptRemainingTurns = candidate.interruptRemainingTurns ~= nil
            and math.max(0, math.floor(tonumber(candidate.interruptRemainingTurns) or 0))
            or nil,
        requiresMeleePosition = candidateRequiresMelee(candidate),
        status = "ready",
    }
    if movementActionId and action.requiresMeleePosition then
        action.requiresMovementActionId = movementActionId
    end
    return action
end

local function buildTacticalContext(state)
    return {
        eventState = state.snapshot.eventState,
        auraDefinitionCache = state.scratch.auraDefinitionCache,
        controlStateByTargetEventId = state.snapshot.controlStateByTargetEventId,
        activeCastsByEventId = state.snapshot.activeCastsByEventId,
    }
end

local function clonePlanTacticalLedger(state)
    local ledger = {
        projectedHealingLedger = state.scratch.projectedHealingLedger,
        projectedAuraLedger = state.scratch.projectedAuraLedger,
    }
    return type(SequencePlanning.CloneTacticalLedger) == "function"
        and SequencePlanning.CloneTacticalLedger(ledger)
        or copyDeep(ledger)
end

local function commitPlanTacticalLedger(state, ledger)
    if type(ledger) ~= "table" then
        return false
    end
    local copied = type(SequencePlanning.CloneTacticalLedger) == "function"
        and SequencePlanning.CloneTacticalLedger(ledger)
        or copyDeep(ledger)
    state.scratch.projectedHealingLedger = copied.projectedHealingLedger or { reservedByEventId = {} }
    state.scratch.projectedAuraLedger = copied.projectedAuraLedger
    return true
end

local function initializePlanTacticalLedger(state)
    if type(SequencePlanning.CreateTacticalLedger) == "function" then
        local ledger = SequencePlanning.CreateTacticalLedger(state.snapshot.activeAuraRecords)
        commitPlanTacticalLedger(state, ledger)
    elseif state.scratch.projectedAuraLedger == nil and type(AuraEvaluator.CreateProjectedAuraLedger) == "function" then
        state.scratch.projectedAuraLedger = AuraEvaluator.CreateProjectedAuraLedger(state.snapshot.activeAuraRecords)
    end
end

local function emitSequenceActions(state, actor, unit, sequence, movementActionId, noActionReason)
    local entries = type(sequence) == "table" and sequence.actions or {}
    if #entries == 0 then
        appendNoAction(state, actor.key, unit, noActionReason or "no-useful-action")
        return false
    end

    local previousActionId = nil
    local sequenceCount = #entries
    for sequenceIndex = 1, sequenceCount do
        local entry = entries[sequenceIndex]
        local candidate = type(entry) == "table" and entry.candidate or nil
        if type(candidate) == "table" then
            local action = buildSpellAction(
                state,
                actor.key,
                unit,
                candidate,
                movementActionId,
                sequenceIndex,
                sequenceCount,
                entry.actionClass,
                previousActionId,
                entry
            )
            if action then
                state.output.actions[#state.output.actions + 1] = action
                previousActionId = action.actionId
            end
        end
    end
    if previousActionId == nil then
        appendNoAction(state, actor.key, unit, noActionReason or "no-useful-action")
        return false
    end
    return true
end

local function snapshotUnitSummary(unit, spellRefs, movementSnapshot)
    return {
        eventID = normalizeEventId(unit and unit.eventID),
        name = tostring(unit and unit.name or ""),
        active = isUnitActive(unit),
        dead = unit and unit.dead == true or false,
        team = tonumber(unit and unit.team) or 0,
        raidMarker = normalizeRaidMarker(unit and unit.raidMarker),
        resources = copyResourceEntries(unit and unit.resources),
        threatTable = copyThreatTable(unit and unit.threatTable),
        tauntState = copyTauntState(unit and unit.tauntState),
        spellRefs = copyArray(spellRefs),
        movement = type(movementSnapshot) == "table" and copyMap(movementSnapshot) or nil,
    }
end

local function buildSnapshotResult(state)
    local members = {}
    for index = 1, #(state.snapshot.actorMembers or {}) do
        local entry = state.snapshot.actorMembers[index]
        local unit = entry and entry.unit
        local eventId = normalizeEventId(unit and unit.eventID)
        if eventId > 0 then
            members[#members + 1] = snapshotUnitSummary(
                unit,
                state.snapshot.spellRefsByEventId[eventId],
                state.snapshot.movementByEventId[eventId]
            )
        end
    end

    local playerPositions = {}
    for eventId, position in pairs(state.snapshot.spatialRuntime.playerPositionByEventId or {}) do
        playerPositions[eventId] = copyPosition(position)
    end
    local actorPositions = {}
    for actorKey, position in pairs(state.snapshot.spatialRuntime.positionByActorKey or {}) do
        actorPositions[actorKey] = copyPosition(position)
    end

    local activeAuraRecords = {}
    for index = 1, #(state.snapshot.activeAuraRecords or {}) do
        activeAuraRecords[index] = copyDeep(state.snapshot.activeAuraRecords[index])
    end
    local activeAurasByTargetEventId = {}
    for targetEventId, records in pairs(state.snapshot.activeAurasByTargetEventId or {}) do
        activeAurasByTargetEventId[targetEventId] = {}
        for index = 1, #(records or {}) do
            activeAurasByTargetEventId[targetEventId][index] = copyDeep(records[index])
        end
    end
    local controlStateByTargetEventId = copyDeep(state.snapshot.controlStateByTargetEventId or {})
    local activeCastSummaries = {}
    local activeCastsByEventId = {}
    for index = 1, #(state.snapshot.activeCastSummaries or {}) do
        local summary = copyDeep(state.snapshot.activeCastSummaries[index])
        activeCastSummaries[index] = summary
        if type(summary) == "table" and normalizeEventId(summary.casterEventId) > 0 then
            activeCastsByEventId[normalizeEventId(summary.casterEventId)] = copyDeep(summary)
        end
    end

    return {
        eventId = state.eventId,
        turnNumber = state.turnNumber,
        tickNumber = state.tickNumber,
        actorKey = state.actorKey,
        actorKeys = copyArray(state.actorKeys),
        scheduleRevision = state.scheduleRevision,
        members = members,
        playerPositions = playerPositions,
        actorPositions = actorPositions,
        activeAuraRecords = activeAuraRecords,
        activeAurasByTargetEventId = activeAurasByTargetEventId,
        controlStateByTargetEventId = controlStateByTargetEventId,
        auraRecords = activeAuraRecords,
        auraRecordsByTargetEventId = activeAurasByTargetEventId,
        activeCastSummaries = activeCastSummaries,
        activeCastsByEventId = activeCastsByEventId,
        activeCastByEventId = activeCastsByEventId,
    }
end

local function copyAction(action)
    if type(action) ~= "table" then
        return nil
    end
    local copy = copyMap(action)
    copy.targetEventIds = copyArray(action.targetEventIds)
    copy.targetSelectionOrder = copyArray(action.targetSelectionOrder)
    copy.targetSelections = {}
    for key, values in pairs(action.targetSelections or {}) do
        copy.targetSelections[key] = copyArray(values)
    end
    return copy
end

local function copyMovement(movement)
    if type(movement) ~= "table" then
        return nil
    end
    local copy = copyMap(movement)
    copy.objectiveTargetEventIds = copyArray(movement.objectiveTargetEventIds)
    copy.proposedPosition = copyPosition(movement.proposedPosition)
    return copy
end

local function copyWarning(warning)
    if type(warning) ~= "table" then
        return nil
    end
    local copy = copyMap(warning)
    copy.memberEventIds = copyArray(warning.memberEventIds)
    return copy
end

local function copyNoAction(record)
    return type(record) == "table" and copyMap(record) or nil
end

local function copyMetrics(metrics)
    local copied = copyMap(metrics)
    copied.movementAllowanceByActor = copyMap(type(metrics) == "table" and metrics.movementAllowanceByActor or nil)
    return copied
end

local function finishMetrics(state)
    local metrics = state.metrics
    metrics.completedAtMs = nowMilliseconds()
    metrics.totalWallMs = math.max(0, metrics.completedAtMs - (tonumber(metrics.startedAtMs) or metrics.completedAtMs))
    return metrics
end

local function logMetrics(state)
    if type(Debug.Internal) ~= "function" then
        return
    end
    local m = state.metrics or {}
    Debug.Internal(
        "Autopilot planner complete event=%s turn=%d tick=%d actor=%s slices=%d yields=%d maxSlice=%.2fms wall=%.2fms spells=%d targets=%d anchors=%d unreachable=%d",
        tostring(state.eventId or ""),
        tonumber(state.turnNumber) or 0,
        tonumber(state.tickNumber) or 0,
        tostring(state.actorKey or ""),
        tonumber(m.sliceCount) or 0,
        tonumber(m.yieldCount) or 0,
        tonumber(m.maxSliceMs) or 0,
        tonumber(m.totalWallMs) or 0,
        tonumber(m.candidateSpellCount) or 0,
        tonumber(m.candidateTargetCount) or 0,
        tonumber(m.candidateAnchorCount) or 0,
        tonumber(m.rejectedUnreachableAnchors) or 0
    )
end

local function installMovementSnapshot(unit, allowance, details)
    if type(unit) ~= "table" then
        return
    end
    unit.__autopilotMovementSnapshot = {
        effectiveValue = math.max(0, tonumber(allowance) or 0),
        available = type(details) ~= "table" or details.available ~= false,
        reason = type(details) == "table" and details.reason or nil,
        statRef = type(details) == "table" and details.statRef or nil,
        baseValue = type(details) == "table" and details.baseValue or nil,
        movementRangeOverride = type(details) == "table" and details.movementRangeOverride or nil,
        controlState = type(details) == "table" and type(details.controlState) == "table"
            and copyMap(details.controlState)
            or nil,
    }
end

local function buildActorsFromCurrentStep(state)
    local schedule = Event.BuildTurnSchedule(state.sourceEventState, state.stepCapacity)
    local step = type(schedule) == "table" and schedule[state.tickNumber] or nil
    if type(step) ~= "table" then
        return false, "step-unavailable"
    end

    state.snapshot.actors = {}
    state.snapshot.actorByKey = {}
    for index = 1, #(step.actors or {}) do
        local actor = step.actors[index]
        local kind = tostring(actor and actor.kind or "")
        if kind == "npc" or kind == "npc_marker" then
            local entry = {
                key = tostring(actor.key or ""),
                kind = kind,
                raidMarker = normalizeRaidMarker(actor.raidMarker),
                memberEventIds = copyArray(actor.unitEventIds),
                members = {},
            }
            state.snapshot.actors[#state.snapshot.actors + 1] = entry
            state.snapshot.actorByKey[entry.key] = entry
        end
    end
    if #state.snapshot.actors == 0 then
        return false, "no-npc-actor"
    end
    return true
end

local function phaseValidate(state)
    if type(state.sourceEventState) ~= "table" or state.sourceEventState.active ~= true then
        state.failureReason = "event-inactive"
        state.phase = "finalize"
        return
    end
    local ok, reason = buildActorsFromCurrentStep(state)
    if not ok then
        state.failureReason = reason
        state.phase = "finalize"
        return
    end
    state.phase = "snapshot-units"
end

local function phaseSnapshotUnits(state, deadlineMs)
    local sourceUnits = state.sourceEventState.units or {}
    while state.cursors.unit <= #sourceUnits do
        local frozenUnit = cloneEventUnit(sourceUnits[state.cursors.unit])
        if frozenUnit then
            frozenUnit.tauntState = getHostLocalTauntState(
                state.sourceEventState,
                frozenUnit.eventID
            )
            frozenUnit.__autopilotFrozenSignature = buildUnitFrozenSignature(frozenUnit)
            state.snapshot.eventState.units[#state.snapshot.eventState.units + 1] = frozenUnit
            local eventId = normalizeEventId(frozenUnit.eventID)
            if eventId > 0 then
                state.snapshot.unitByEventId[eventId] = frozenUnit
            end
        end
        state.cursors.unit = state.cursors.unit + 1
        if shouldYield(deadlineMs) then
            return false
        end
    end

    for actorIndex = 1, #state.snapshot.actors do
        local actor = state.snapshot.actors[actorIndex]
        for memberIndex = 1, #actor.memberEventIds do
            local unit = state.snapshot.unitByEventId[normalizeEventId(actor.memberEventIds[memberIndex])]
            if type(unit) == "table" and isUnitActive(unit) then
                actor.members[#actor.members + 1] = unit
                state.snapshot.actorMembers[#state.snapshot.actorMembers + 1] = {
                    actorKey = actor.key,
                    raidMarker = actor.raidMarker,
                    unit = unit,
                }
            end
        end
    end

    state.snapshot.unitsFrozen = true
    state.phase = "snapshot-positions"
    state.cursors.unit = 1
    return true
end

local function phaseSnapshotPositions(state, deadlineMs)
    if state.snapshot.spatialRuntime.instanceID == nil and type(state.runtimeRef) == "table" then
        state.snapshot.spatialRuntime.instanceID = state.runtimeRef.instanceID
    end
    local frozenUnits = state.snapshot.eventState.units or {}
    while state.cursors.unit <= #frozenUnits do
        local unit = frozenUnits[state.cursors.unit]
        local eventId = normalizeEventId(unit and unit.eventID)
        if eventId > 0 then
            if unit.isPlayer == true then
                local position = state.runtimeRef
                    and state.runtimeRef.playerPositionByEventId
                    and state.runtimeRef.playerPositionByEventId[eventId]
                    or nil
                if type(position) == "table" then
                    state.snapshot.spatialRuntime.playerPositionByEventId[eventId] = copyPosition(position)
                end
            else
                local actorKey = type(Spatial.GetNpcActorKey) == "function" and Spatial.GetNpcActorKey(unit) or nil
                if actorKey and state.snapshot.spatialRuntime.positionByActorKey[actorKey] == nil then
                    local position = state.runtimeRef
                        and state.runtimeRef.positionByActorKey
                        and state.runtimeRef.positionByActorKey[actorKey]
                        or nil
                    if type(position) == "table" then
                        state.snapshot.spatialRuntime.positionByActorKey[actorKey] = copyPosition(position)
                    end
                end
            end
        end
        state.cursors.unit = state.cursors.unit + 1
        if shouldYield(deadlineMs) then
            return false
        end
    end
    state.phase = "snapshot-auras"
    return true
end

local function appendFrozenAuraRecord(state, record)
    if type(record) ~= "table" or (tonumber(record.stacks) or 0) <= 0 then
        return
    end

    state.snapshot.activeAuraRecords[#state.snapshot.activeAuraRecords + 1] = record
    local targetEventId = normalizeEventId(record.targetEventId)
    if targetEventId > 0 then
        local byTarget = state.snapshot.activeAurasByTargetEventId[targetEventId]
        if type(byTarget) ~= "table" then
            byTarget = {}
            state.snapshot.activeAurasByTargetEventId[targetEventId] = byTarget
        end
        byTarget[#byTarget + 1] = record

        local controlState = state.snapshot.controlStateByTargetEventId[targetEventId]
        if type(controlState) ~= "table" then
            controlState = {
                cancelOnDamage = false,
                preventCasting = false,
                movementRangeOverride = nil,
                forceAutoHitAgainstTarget = false,
            }
            state.snapshot.controlStateByTargetEventId[targetEventId] = controlState
        end
        local control = record.control
        if type(control) ~= "table" and type(record.profile) == "table" then
            control = record.profile.control
        end
        if type(control) == "table" then
            controlState.cancelOnDamage = controlState.cancelOnDamage or control.cancelOnDamage == true
            controlState.preventCasting = controlState.preventCasting or control.preventCasting == true
            controlState.forceAutoHitAgainstTarget = controlState.forceAutoHitAgainstTarget
                or control.forceAutoHitAgainstTarget == true
            if control.movementRangeOverride ~= nil then
                local override = tonumber(control.movementRangeOverride)
                if override ~= nil then
                    controlState.movementRangeOverride = controlState.movementRangeOverride ~= nil
                        and math.min(controlState.movementRangeOverride, override)
                        or override
                end
            end
        end
    end
end

local function phaseSnapshotAuras(state, deadlineMs)
    if not ensureAuraGeneration(state) then
        return false
    end

    local bucket = state.scratch.auraSourceBucket
    if type(bucket) ~= "table" or type(bucket.byKey) ~= "table" then
        if not auraGenerationIsCurrent(state) then
            return restartAuraGeneration(state)
        end
        initializePlanTacticalLedger(state)
        state.phase = "snapshot-casts"
        return true
    end

    if state.cursors.auraScanComplete ~= true then
        while true do
            if not auraGenerationIsCurrent(state) then
                return restartAuraGeneration(state)
            end
            local auraKey = next(bucket.byKey, state.cursors.auraKeyScan)
            state.cursors.auraKeyScan = auraKey
            if auraKey == nil then
                if not auraGenerationIsCurrent(state) then
                    return restartAuraGeneration(state)
                end
                table.sort(state.scratch.auraKeys, function(left, right)
                    return tostring(left) < tostring(right)
                end)
                state.cursors.auraScanComplete = true
                state.cursors.auraCopyIndex = 1
                break
            end
            state.scratch.auraKeys[#state.scratch.auraKeys + 1] = auraKey
            if shouldYield(deadlineMs) then
                return false
            end
        end
    end

    local auraEvaluator = getAuraEvaluator()
    while state.cursors.auraCopyIndex <= #state.scratch.auraKeys do
        if not auraGenerationIsCurrent(state) then
            return restartAuraGeneration(state)
        end
        local auraKey = state.scratch.auraKeys[state.cursors.auraCopyIndex]
        local entry = bucket.byKey[auraKey]

        if type(entry) == "table" and type(auraEvaluator) == "table" and type(auraEvaluator.CopyAuraEntry) == "function" then
            local copied = auraEvaluator.CopyAuraEntry(entry, {
                datasetId = entry and entry.datasetId,
                auraDefinitionCache = state.scratch.auraDefinitionCache,
            }, state.scratch.auraDefinitionCache)
            appendFrozenAuraRecord(state, copied)
        elseif type(entry) == "table" then
            appendFrozenAuraRecord(state, copyDeep(entry))
        end

        state.cursors.auraCopyIndex = state.cursors.auraCopyIndex + 1
        if shouldYield(deadlineMs) then
            return false
        end
    end

    if not auraGenerationIsCurrent(state) then
        return restartAuraGeneration(state)
    end
    initializePlanTacticalLedger(state)
    state.phase = "snapshot-casts"
    state.cursors.castKeyScan = nil
    return true
end

local function copyActiveCastSummary(entry, casterEventId, turnNumber)
    if type(entry) ~= "table" then
        return nil
    end

    local turnsTotal = math.max(0, math.floor(tonumber(entry.turnsTotal) or 0))
    local turnsElapsed = math.max(0, math.floor(tonumber(entry.turnsElapsed) or 0))
    local turnsRemaining = math.max(0, math.floor(tonumber(entry.turnsRemaining) or (turnsTotal - turnsElapsed)))
    local currentTurnNumber = math.max(0, math.floor(tonumber(turnNumber) or 0))
    local completeOnTurnNumber = math.max(0, math.floor(tonumber(entry.completeOnTurnNumber) or 0))
    local copied = {
        spellRef = entry.spellRef,
        spellName = entry.spellName,
        authorityType = entry.authorityType,
        casterEventId = normalizeEventId(entry.casterEventId or casterEventId),
        turnsTotal = turnsTotal,
        turnsElapsed = turnsElapsed,
        turnsRemaining = turnsRemaining,
        remainingTurns = turnsRemaining,
        castRemainingTurns = turnsRemaining,
        startedOnTurnNumber = math.max(0, math.floor(tonumber(entry.startedOnTurnNumber) or 0)),
        completeOnTurnNumber = completeOnTurnNumber,
        lastAdvancedTurnNumber = math.max(0, math.floor(tonumber(entry.lastAdvancedTurnNumber) or 0)),
        currentTurnNumber = currentTurnNumber,
        targetEventIds = copyArray(entry.targetEventIds),
        focusedTargetEventId = normalizeEventId(entry.focusedTargetEventId),
        targetPolicy = copyDeep(entry.targetPolicy),
    }
    if type(entry.targetSelectionOrder) == "table" then
        copied.targetSelectionOrder = copyArray(entry.targetSelectionOrder)
    end
    if type(entry.targetSelections) == "table" then
        copied.targetSelections = {}
        for key, values in pairs(entry.targetSelections) do
            copied.targetSelections[key] = copyDeep(values)
        end
    end
    return copied
end

local function phaseSnapshotCasts(state, deadlineMs)
    if not ensureCastGeneration(state) then
        return false
    end

    local bucket = state.scratch.castSourceBucket
    if type(bucket) ~= "table" then
        if not castGenerationIsCurrent(state) then
            return restartCastGeneration(state)
        end
        state.phase = "snapshot-spells"
        state.cursors.member = 1
        return true
    end

    if state.cursors.castScanComplete ~= true then
        while true do
            if not castGenerationIsCurrent(state) then
                return restartCastGeneration(state)
            end
            local casterEventId = next(bucket, state.cursors.castKeyScan)
            state.cursors.castKeyScan = casterEventId
            if casterEventId == nil then
                if not castGenerationIsCurrent(state) then
                    return restartCastGeneration(state)
                end
                table.sort(state.scratch.castKeys, function(left, right)
                    return tonumber(left) and tonumber(right)
                        and tonumber(left) < tonumber(right)
                        or tostring(left) < tostring(right)
                end)
                state.cursors.castScanComplete = true
                state.cursors.castCopyIndex = 1
                break
            end
            state.scratch.castKeys[#state.scratch.castKeys + 1] = casterEventId
            if shouldYield(deadlineMs) then
                return false
            end
        end
    end

    while state.cursors.castCopyIndex <= #state.scratch.castKeys do
        if not castGenerationIsCurrent(state) then
            return restartCastGeneration(state)
        end
        local casterEventId = state.scratch.castKeys[state.cursors.castCopyIndex]
        local entry = bucket[casterEventId]

        local summary = copyActiveCastSummary(entry, casterEventId, state.turnNumber)
        if summary and summary.casterEventId > 0 then
            state.snapshot.activeCastSummaries[#state.snapshot.activeCastSummaries + 1] = summary
            state.snapshot.activeCastsByEventId[summary.casterEventId] = summary
        end

        state.cursors.castCopyIndex = state.cursors.castCopyIndex + 1
        if shouldYield(deadlineMs) then
            return false
        end
    end

    if not castGenerationIsCurrent(state) then
        return restartCastGeneration(state)
    end
    state.phase = "snapshot-spells"
    state.cursors.member = 1
    return true
end

local function phaseSnapshotSpells(state, deadlineMs)
    while state.cursors.member <= #state.snapshot.actorMembers do
        local entry = state.snapshot.actorMembers[state.cursors.member]
        local unit = entry.unit
        local eventId = normalizeEventId(unit and unit.eventID)
        local refs = type(Client.ListEventUnitResolvedSpellRefs) == "function"
            and Client:ListEventUnitResolvedSpellRefs(eventId, state.snapshot.eventState)
            or copyArray(unit and unit.spells)
        state.snapshot.spellRefsByEventId[eventId] = copyArray(refs)
        state.metrics.candidateSpellCount = state.metrics.candidateSpellCount + #refs
        state.cursors.member = state.cursors.member + 1
        if shouldYield(deadlineMs) then
            return false
        end
    end
    state.phase = "snapshot-movement"
    state.cursors.member = 1
    return true
end

local function phaseSnapshotMovement(state, deadlineMs)
    local Movement = getMovement()
    while state.cursors.member <= #state.snapshot.actorMembers do
        local entry = state.snapshot.actorMembers[state.cursors.member]
        local unit = entry.unit
        local eventId = normalizeEventId(unit and unit.eventID)
        local allowance, details = nil, nil
        if type(Movement) == "table" and type(Movement.ResolveEventUnitMovementAllowance) == "function" then
            allowance, details = Movement:ResolveEventUnitMovementAllowance(state.snapshot.eventState, unit)
        end
        allowance = math.max(0, tonumber(allowance) or 0)
        installMovementSnapshot(unit, allowance, details)
        state.snapshot.movementByEventId[eventId] = copyMap(unit.__autopilotMovementSnapshot)
        local actor = state.snapshot.actorByKey[entry.actorKey]
        if type(actor) == "table" then
            actor.movementAllowance = actor.movementAllowance == nil
                and allowance
                or math.min(actor.movementAllowance, allowance)
        end
        state.cursors.member = state.cursors.member + 1
        if shouldYield(deadlineMs) then
            return false
        end
    end
    state.phase = "activation"
    state.cursors.member = 1
    state.cursors.spell = 1
    return true
end

local function phaseActivation(state, deadlineMs)
    local Spellcasting = getSpellcasting()
    while state.cursors.member <= #state.snapshot.actorMembers do
        local entry = state.snapshot.actorMembers[state.cursors.member]
        local unit = entry.unit
        local eventId = normalizeEventId(unit and unit.eventID)
        local spellRefs = state.snapshot.spellRefsByEventId[eventId] or {}
        if state.cursors.spell > #spellRefs then
            state.cursors.member = state.cursors.member + 1
            state.cursors.spell = 1
        else
            local spellRef = tostring(spellRefs[state.cursors.spell] or "")
            local cacheKey = tostring(eventId) .. "\31" .. spellRef
            local activation = nil
            if type(Spellcasting) == "table" and type(Spellcasting.BuildSpellActivationSnapshot) == "function" then
                activation = Spellcasting.BuildSpellActivationSnapshot(
                    state.snapshot.clientProxy,
                    spellRef,
                    {
                        casterEventId = eventId,
                        includeTargetCandidates = true,
                    }
                )
            end
            state.scratch.activationByKey[cacheKey] = activation or false
            if type(activation) == "table" then
                state.scratch.activationKeys[#state.scratch.activationKeys + 1] = cacheKey
                state.metrics.candidateTargetCount = state.metrics.candidateTargetCount + #(activation.targetCandidates or {})
                state.scratch.spellDefinitionByRef[spellRef] = activation.spell
                local profile = type(SpellEvaluator.BuildSpellProfile) == "function"
                    and SpellEvaluator.BuildSpellProfile(activation, {
                        auraDefinitionCache = state.scratch.auraDefinitionCache,
                        activeAurasByTargetEventId = state.snapshot.activeAurasByTargetEventId,
                        controlStateByTargetEventId = state.snapshot.controlStateByTargetEventId,
                        activeCastsByEventId = state.snapshot.activeCastsByEventId,
                    })
                    or nil
                state.scratch.profileByKey[cacheKey] = profile or false
            end
            state.cursors.spell = state.cursors.spell + 1
            if shouldYield(deadlineMs) then
                return false
            end
        end
    end
    state.phase = "targets"
    state.cursors.member = 1
    state.cursors.spell = 1
    state.cursors.intent = 1
    return true
end

local function buildCandidateFromSelection(state, activation, profile, selection, intent)
    if type(profile) ~= "table" or type(selection) ~= "table" or selection.meetsMinTargets ~= true then
        return nil
    end

    local targets = selection.targetUnits or {}
    local isHostileTarget = type(selection.policy) == "table"
        and tostring(selection.policy.targetDisposition or "") == "enemy"
    if #targets == 0 then
        local utility = intent == "damage" and (tonumber(profile.expectedDamage) or 0) or 0
        if utility <= 0 then
            return nil
        end
        return {
            spellRef = profile.spellRef,
            casterEventId = profile.casterEventId,
            targetUnits = {},
            targetEventIds = {},
            targetGroupKey = selection.targetGroupKey,
            planningIntent = intent,
            planningProfile = profile,
            isHostileTarget = isHostileTarget,
            hasDamage = profile.hasDamage,
            hasHeal = profile.hasHeal,
            hasControl = profile.hasControl == true,
            hasInterrupt = profile.hasInterrupt == true,
            hasPeriodicDamage = profile.hasPeriodicDamage == true,
            hasPeriodicHealing = profile.hasPeriodicHealing == true,
            auraApplications = profile.auraApplications,
            appliedAuras = profile.appliedAuras,
            hasAuraApplication = profile.hasAuraApplication == true,
            damageTypes = profile.damageTypes,
            damageTypeList = profile.damageTypeList,
            immediateDamage = tonumber(profile.immediateDamage) or 0,
            periodicDamage = 0,
            immediateHealing = tonumber(profile.immediateHealing) or 0,
            periodicHealing = 0,
            expectedDamage = profile.expectedDamage,
            expectedHealing = profile.expectedHealing,
            damageUtility = utility,
            healingUtility = 0,
            movementControlUtility = 0,
            castingPreventionUtility = 0,
            controlUtility = 0,
            totalUtility = utility,
            urgentHealing = false,
            hasUsefulInterrupt = false,
            urgentInterrupt = false,
            interruptTargetEventId = 0,
            interruptRemainingTurns = nil,
            resourceBurden = profile.resourceBurden,
            cooldownCommitment = profile.cooldownCommitment,
            chargeCommitment = profile.chargeCommitment,
            activationSnapshot = activation,
        }
    end

    local damageUtility = 0
    local healingUtility = 0
    local movementControlUtility = 0
    local castingPreventionUtility = 0
    local controlUtility = 0
    local immediateDamage = 0
    local immediateHealing = 0
    local periodicDamage = 0
    local periodicHealing = 0
    local expectedDamage = 0
    local expectedHealing = 0
    local urgentHealing = false
    local hasUsefulInterrupt = false
    local urgentInterrupt = false
    local interruptTargetEventId = 0
    local interruptRemainingTurns = nil
    local targetEventIds = {}
    local evaluateInterrupt = intent == "interrupt"
    for index = 1, #targets do
        local target = targets[index]
        local evaluated = type(SpellEvaluator.EvaluateCandidate) == "function"
            and SpellEvaluator.EvaluateCandidate(activation, target, {
                projectedHealingLedger = state.scratch.projectedHealingLedger,
                projectedAuraLedger = state.scratch.projectedAuraLedger,
                auraDefinitionCache = state.scratch.auraDefinitionCache,
                controlStateByTargetEventId = state.snapshot.controlStateByTargetEventId,
                activeCastsByEventId = state.snapshot.activeCastsByEventId,
                isHostileTarget = isHostileTarget,
                profile = profile,
            })
            or nil
        if type(evaluated) == "table" then
            damageUtility = damageUtility + (tonumber(evaluated.damageUtility) or 0)
            healingUtility = healingUtility + (tonumber(evaluated.healingUtility) or 0)
            movementControlUtility = movementControlUtility + (tonumber(evaluated.movementControlUtility) or 0)
            castingPreventionUtility = castingPreventionUtility + (tonumber(evaluated.castingPreventionUtility) or 0)
            controlUtility = controlUtility + (tonumber(evaluated.controlUtility) or 0)
            immediateDamage = immediateDamage + (tonumber(evaluated.immediateDamage) or 0)
            immediateHealing = immediateHealing + (tonumber(evaluated.immediateHealing) or 0)
            periodicDamage = periodicDamage + (tonumber(evaluated.usefulPeriodicDamage) or 0)
            periodicHealing = periodicHealing + (tonumber(evaluated.usefulPeriodicHealing) or 0)
            expectedDamage = expectedDamage + (tonumber(evaluated.expectedDamage) or 0)
            expectedHealing = expectedHealing + (tonumber(evaluated.expectedHealing) or 0)
            urgentHealing = urgentHealing or evaluated.urgentHealing == true
            if evaluateInterrupt and evaluated.hasUsefulInterrupt == true and hasUsefulInterrupt ~= true then
                hasUsefulInterrupt = true
                interruptTargetEventId = normalizeEventId(evaluated.interruptTargetEventId)
                interruptRemainingTurns = evaluated.interruptRemainingTurns
            end
            urgentInterrupt = urgentInterrupt or (evaluateInterrupt and evaluated.urgentInterrupt == true)
            local targetId = normalizeEventId(target and target.eventID)
            if targetId > 0 then
                state.scratch.healthByEventId[targetId] = evaluated.targetHealth or state.scratch.healthByEventId[targetId]
            end
        end
        targetEventIds[index] = normalizeEventId(target and target.eventID)
    end

    local totalUtility = damageUtility + healingUtility + controlUtility
    if totalUtility <= 0 and urgentHealing ~= true and urgentInterrupt ~= true then
        return nil
    end

    return {
        spellRef = profile.spellRef,
        casterEventId = profile.casterEventId,
        targetUnits = copyArray(targets),
        targetEventIds = targetEventIds,
        targetUnit = targets[1],
        primaryTargetUnit = targets[1],
        targetEventId = targetEventIds[1],
        targetGroupKey = selection.targetGroupKey,
        planningIntent = intent,
        planningProfile = profile,
        isHostileTarget = isHostileTarget,
        hasDamage = profile.hasDamage,
        hasHeal = profile.hasHeal,
        hasControl = profile.hasControl == true,
        hasInterrupt = profile.hasInterrupt == true,
        hasPeriodicDamage = profile.hasPeriodicDamage == true,
        hasPeriodicHealing = profile.hasPeriodicHealing == true,
        auraApplications = profile.auraApplications,
        appliedAuras = profile.appliedAuras,
        hasAuraApplication = profile.hasAuraApplication == true,
        damageTypes = profile.damageTypes,
        damageTypeList = profile.damageTypeList,
        immediateDamage = immediateDamage,
        periodicDamage = periodicDamage,
        immediateHealing = immediateHealing,
        periodicHealing = periodicHealing,
        expectedDamage = expectedDamage,
        expectedHealing = expectedHealing,
        damageUtility = damageUtility,
        healingUtility = healingUtility,
        movementControlUtility = movementControlUtility,
        castingPreventionUtility = castingPreventionUtility,
        controlUtility = controlUtility,
        totalUtility = totalUtility,
        urgentHealing = urgentHealing,
        hasUsefulInterrupt = hasUsefulInterrupt,
        urgentInterrupt = urgentInterrupt,
        interruptTargetEventId = interruptTargetEventId,
        interruptRemainingTurns = interruptRemainingTurns,
        resourceBurden = profile.resourceBurden,
        cooldownCommitment = profile.cooldownCommitment,
        chargeCommitment = profile.chargeCommitment,
        activationSnapshot = activation,
    }
end

local function getIntentList(profile)
    local intents = {}
    if type(profile) == "table" and profile.hasHeal == true then
        intents[#intents + 1] = "healing"
    end
    if type(profile) == "table" and (profile.hasDamage == true or profile.hasControl == true) then
        intents[#intents + 1] = "hostile"
    end
    if type(profile) == "table" and profile.hasInterrupt == true then
        intents[#intents + 1] = "interrupt"
    end
    return intents
end

local function phaseTargets(state, deadlineMs)
    while state.cursors.member <= #state.snapshot.actorMembers do
        local entry = state.snapshot.actorMembers[state.cursors.member]
        local unit = entry.unit
        local eventId = normalizeEventId(unit and unit.eventID)
        local spellRefs = state.snapshot.spellRefsByEventId[eventId] or {}
        if state.cursors.spell > #spellRefs then
            state.cursors.member = state.cursors.member + 1
            state.cursors.spell = 1
            state.cursors.intent = 1
        else
            local spellRef = tostring(spellRefs[state.cursors.spell] or "")
            local cacheKey = tostring(eventId) .. "\31" .. spellRef
            local activation = state.scratch.activationByKey[cacheKey]
            local profile = state.scratch.profileByKey[cacheKey]
            if type(activation) ~= "table" or activation.canCast ~= true or type(profile) ~= "table" then
                state.cursors.spell = state.cursors.spell + 1
                state.cursors.intent = 1
            else
                local intents = getIntentList(profile)
                if state.cursors.intent > #intents then
                    state.cursors.spell = state.cursors.spell + 1
                    state.cursors.intent = 1
                else
                    local intent = intents[state.cursors.intent]
                    local selectionKey = table.concat({ eventId, spellRef, intent }, "\31")
                    local selectionState = state.scratch.targetSelectionByKey[selectionKey]
                    if type(selectionState) ~= "table" then
                        selectionState = type(TargetSelector.CreateState) == "function"
                            and select(1, TargetSelector.CreateState(activation, {
                                intent = intent,
                                spatialRuntime = state.snapshot.spatialRuntime,
                                projectedHealingLedger = state.scratch.projectedHealingLedger,
                                activeCastsByEventId = state.snapshot.activeCastsByEventId,
                            }))
                            or nil
                        state.scratch.targetSelectionByKey[selectionKey] = selectionState or false
                    end

                    if type(selectionState) ~= "table" then
                        state.cursors.intent = state.cursors.intent + 1
                    else
                        local complete = TargetSelector.Step(selectionState, deadlineMs) == true
                        if not complete then
                            return false
                        end
                        local selection = type(TargetSelector.CopyResult) == "function"
                            and TargetSelector.CopyResult(selectionState)
                            or nil
                        state.scratch.targetOrderByKey[selectionKey] = selection
                        local candidateIntent = intent == "hostile" and "damage"
                            or intent == "interrupt" and "interrupt"
                            or "heal"
                        local candidate = buildCandidateFromSelection(
                            state,
                            activation,
                            profile,
                            selection,
                            candidateIntent
                        )
                        if type(candidate) == "table" then
                            local bucket = state.scratch.actionCandidatesByEventId[eventId]
                            if type(bucket) ~= "table" then
                                bucket = {}
                                state.scratch.actionCandidatesByEventId[eventId] = bucket
                            end
                            bucket[#bucket + 1] = candidate
                            state.metrics.actionCandidateCount = state.metrics.actionCandidateCount + 1
                        end
                        state.cursors.intent = state.cursors.intent + 1
                    end
                    if shouldYield(deadlineMs) then
                        return false
                    end
                end
            end
        end
    end

    state.phase = "solve-actors"
    state.cursors.actor = 1
    return true
end

local function estimateMovementDiagnostics(solveState)
    local targetCount = #(solveState.anchorTargets or {})
    local potential = 1 + targetCount
    if targetCount > 1 then
        potential = potential + 1 + ((targetCount * (targetCount - 1)) / 2)
    end
    local accepted = #(solveState.anchorCandidates or {})
    return accepted, math.max(0, math.floor(potential - accepted))
end

local function finalizeMarkedActor(state, actor, solveState)
    local result = type(MovementSolver.CopyResult) == "function" and MovementSolver.CopyResult(solveState) or nil
    if type(result) ~= "table" or result.status ~= "ready" then
        for index = 1, #actor.members do
            appendNoAction(state, actor.key, actor.members[index], result and result.reason or "movement-solve-failed")
        end
        return
    end

    local acceptedAnchors, rejectedAnchors = estimateMovementDiagnostics(solveState)
    state.metrics.candidateAnchorCount = state.metrics.candidateAnchorCount + acceptedAnchors
    state.metrics.rejectedUnreachableAnchors = state.metrics.rejectedUnreachableAnchors + rejectedAnchors
    state.metrics.movementAllowanceByActor[actor.key] = tonumber(result.movementAllowance) or 0

    local movementActionId = nil
    if type(result.movement) == "table" then
        local movement = copyMovement(result.movement)
        movement.actionId = state.planId .. ":movement:" .. actor.key
        movement.planId = state.planId
        movement.eventId = state.eventId
        movement.turnNumber = state.turnNumber
        movement.tickNumber = state.tickNumber
        movement.status = "ready"
        movementActionId = movement.actionId
        state.output.movements[#state.output.movements + 1] = movement
    end

    for index = 1, #(result.warnings or {}) do
        appendWarning(state, result.warnings[index])
    end

    local selectedSequences = solveState.bestAnchorEvaluation and solveState.bestAnchorEvaluation.selectedSequences or {}
    for index = 1, #actor.members do
        emitSequenceActions(
            state,
            actor,
            actor.members[index],
            selectedSequences[index],
            movementActionId,
            "no-useful-action"
        )
    end
    commitPlanTacticalLedger(state, result.tacticalLedger)
end

local function createFixedSolveState(state, actor, position, allowMelee, noActionReason)
    return {
        actor = actor,
        position = position,
        allowMelee = allowMelee == true,
        noActionReason = noActionReason,
        memberIndex = 1,
        candidateIndex = 1,
        reevaluatedCandidates = {},
        sequences = {},
        tacticalLedger = clonePlanTacticalLedger(state),
        complete = false,
    }
end

local function stepFixedSolveState(state, solveState, deadlineMs)
    local actor = solveState.actor
    local context = buildTacticalContext(state)
    while solveState.memberIndex <= #(actor.members or {}) do
        local unit = actor.members[solveState.memberIndex]
        local candidates = state.scratch.actionCandidatesByEventId[normalizeEventId(unit and unit.eventID)] or {}
        if solveState.candidateIndex <= #candidates then
            local candidate = candidates[solveState.candidateIndex]
            local spatiallyFeasible = not candidateRequiresMelee(candidate)
                or (solveState.allowMelee and isCandidateFeasibleAtPosition(state, candidate, solveState.position))
            if spatiallyFeasible and type(SequencePlanning.ReevaluateCandidate) == "function" then
                local reevaluated = SequencePlanning.ReevaluateCandidate(candidate, solveState.tacticalLedger, context)
                if type(reevaluated) == "table" then
                    solveState.reevaluatedCandidates[#solveState.reevaluatedCandidates + 1] = reevaluated
                end
            end
            solveState.candidateIndex = solveState.candidateIndex + 1
        else
            local sequence = type(SequencePlanning.BuildSequence) == "function"
                and SequencePlanning.BuildSequence(solveState.reevaluatedCandidates, unit)
                or { status = "failed", actions = {} }
            solveState.sequences[solveState.memberIndex] = sequence
            local summary = type(SequencePlanning.SummarizeSequence) == "function"
                and SequencePlanning.SummarizeSequence(sequence)
                or { hasUsefulAction = false }
            if summary.hasUsefulAction == true and type(SequencePlanning.ReserveSequence) == "function" then
                solveState.tacticalLedger = SequencePlanning.ReserveSequence(
                    solveState.tacticalLedger,
                    sequence,
                    context
                )
            end
            solveState.memberIndex = solveState.memberIndex + 1
            solveState.candidateIndex = 1
            solveState.reevaluatedCandidates = {}
        end

        if shouldYield(deadlineMs) then
            return false
        end
    end
    solveState.complete = true
    return true
end

local function finalizeFixedActor(state, solveState)
    local actor = solveState.actor
    for index = 1, #(actor.members or {}) do
        emitSequenceActions(
            state,
            actor,
            actor.members[index],
            solveState.sequences[index],
            nil,
            solveState.noActionReason
        )
    end
    commitPlanTacticalLedger(state, solveState.tacticalLedger)
end

local function phaseSolveActors(state, deadlineMs)
    while state.cursors.actor <= #state.snapshot.actors do
        local actor = state.snapshot.actors[state.cursors.actor]
        if actor.kind == "npc_marker" then
            local currentPosition = getActorPosition(state, actor.key)
            if type(currentPosition) ~= "table" then
                if state.scratch.positionWarningByActorKey[actor.key] ~= true then
                    appendWarning(state, {
                        warningType = "position-unavailable",
                        actorKey = actor.key,
                        raidMarker = actor.raidMarker,
                        memberEventIds = copyArray(actor.memberEventIds),
                        text = ("Marker %d has no cached virtual position; spatial melee actions are unavailable."):format(actor.raidMarker),
                    })
                    state.scratch.positionWarningByActorKey[actor.key] = true
                end
                local fixed = state.scratch.fixedSolveByActorKey[actor.key]
                if type(fixed) ~= "table" then
                    fixed = createFixedSolveState(state, actor, nil, false, "position-unavailable")
                    state.scratch.fixedSolveByActorKey[actor.key] = fixed
                end
                if stepFixedSolveState(state, fixed, deadlineMs) ~= true then
                    return false
                end
                finalizeFixedActor(state, fixed)
                state.cursors.actor = state.cursors.actor + 1
            else
                local solveState = state.scratch.movementSolveByActorKey[actor.key]
                if type(solveState) ~= "table" then
                    local members = {}
                    for index = 1, #actor.members do
                        local unit = actor.members[index]
                        members[index] = {
                            unit = unit,
                            actionCandidates = state.scratch.actionCandidatesByEventId[normalizeEventId(unit.eventID)] or {},
                        }
                    end
                    solveState = type(MovementSolver.CreateState) == "function"
                        and select(1, MovementSolver.CreateState({
                            eventState = state.snapshot.eventState,
                            spatialRuntime = state.snapshot.spatialRuntime,
                            actorKey = actor.key,
                            raidMarker = actor.raidMarker,
                            members = members,
                            initialTacticalLedger = clonePlanTacticalLedger(state),
                            tacticalContext = buildTacticalContext(state),
                        }))
                        or nil
                    state.scratch.movementSolveByActorKey[actor.key] = solveState or false
                end

                if type(solveState) ~= "table" then
                    for index = 1, #actor.members do
                        appendNoAction(state, actor.key, actor.members[index], "movement-solve-unavailable")
                    end
                    state.cursors.actor = state.cursors.actor + 1
                else
                    local complete = MovementSolver.Step(solveState, deadlineMs) == true
                    if not complete then
                        return false
                    end
                    finalizeMarkedActor(state, actor, solveState)
                    state.cursors.actor = state.cursors.actor + 1
                end
            end
        else
            local unit = actor.members[1]
            if type(unit) == "table" then
                local spatialActorKey = type(Spatial.GetNpcActorKey) == "function" and Spatial.GetNpcActorKey(unit) or actor.key
                local position = getActorPosition(state, spatialActorKey)
                local fixed = state.scratch.fixedSolveByActorKey[actor.key]
                if type(fixed) ~= "table" then
                    fixed = createFixedSolveState(
                        state,
                        actor,
                        position,
                        type(position) == "table",
                        position and "no-useful-action" or "position-unavailable"
                    )
                    state.scratch.fixedSolveByActorKey[actor.key] = fixed
                end
                if stepFixedSolveState(state, fixed, deadlineMs) ~= true then
                    return false
                end
                finalizeFixedActor(state, fixed)
            end
            state.cursors.actor = state.cursors.actor + 1
        end

        if shouldYield(deadlineMs) then
            return false
        end
    end

    state.phase = "revalidate"
    state.cursors.revalidateUnit = 1
    state.cursors.revalidateMember = 1
    state.cursors.revalidateActivation = 1
    return true
end

local function invalidateFrozenPlan(state, reason)
    state.failureReason = tostring(reason or "snapshot-stale")
    state.output = { movements = {}, actions = {}, noActions = {}, warnings = {} }
    state.phase = "finalize"
    return true
end

local function validateLiveSpatialSnapshot(state)
    local liveRuntime = state.runtimeRef
    local frozenRuntime = state.snapshot and state.snapshot.spatialRuntime or nil
    if type(liveRuntime) ~= "table" or type(frozenRuntime) ~= "table" then
        return false
    end
    for eventId, position in pairs(frozenRuntime.playerPositionByEventId or {}) do
        local live = liveRuntime.playerPositionByEventId and liveRuntime.playerPositionByEventId[eventId] or nil
        if buildPositionSignature(live) ~= buildPositionSignature(position) then
            return false
        end
    end
    for actorKey, position in pairs(frozenRuntime.positionByActorKey or {}) do
        local live = liveRuntime.positionByActorKey and liveRuntime.positionByActorKey[actorKey] or nil
        if buildPositionSignature(live) ~= buildPositionSignature(position) then
            return false
        end
    end
    return true
end

local function phaseRevalidate(state, deadlineMs)
    -- A plan is a snapshot of one turn step. Spell completions and combat
    -- reactions can legitimately alter resources, auras, and health while it
    -- is being calculated; those changes must not cancel the step's plan.
    -- Step changes are still rejected by Client:IsAutopilotPlanStateStale.
    state.phase = "finalize"
    return true
end

local function phaseFinalize(state)
    local metrics = finishMetrics(state)
    local result = {
        planId = state.planId,
        eventId = state.eventId,
        turnNumber = state.turnNumber,
        tickNumber = state.tickNumber,
        actorKey = state.actorKey,
        actorKeys = copyArray(state.actorKeys),
        npcEventIds = copyArray(state.npcEventIds),
        scheduleRevision = state.scheduleRevision,
        snapshot = buildSnapshotResult(state),
        movements = {},
        movement = nil,
        actions = {},
        noActions = {},
        warnings = {},
        records = {},
        metrics = copyMetrics(metrics),
        status = state.failureReason and "failed" or "ready",
        reason = state.failureReason,
    }

    for index = 1, #state.output.movements do
        result.movements[index] = copyMovement(state.output.movements[index])
        result.records[#result.records + 1] = result.movements[index]
    end
    if #result.movements == 1 then
        result.movement = result.movements[1]
    end
    for index = 1, #state.output.actions do
        result.actions[index] = copyAction(state.output.actions[index])
        result.records[#result.records + 1] = result.actions[index]
    end
    for index = 1, #state.output.noActions do
        result.noActions[index] = copyNoAction(state.output.noActions[index])
        result.records[#result.records + 1] = result.noActions[index]
    end
    for index = 1, #state.output.warnings do
        result.warnings[index] = copyWarning(state.output.warnings[index])
        result.records[#result.records + 1] = result.warnings[index]
    end

    state.result = result
    state.phase = "complete"
    logMetrics(state)
    return true
end

function Planner.CreateState(eventState, descriptor, scheduleRevision, planId)
    local state = type(baseCreateState) == "function"
        and baseCreateState(eventState, descriptor, scheduleRevision, planId)
        or nil
    if type(state) ~= "table" then
        return nil
    end

    state.sourceEventState = eventState
    state.phase = "validate"
    state.snapshot = {
        eventState = cloneEventShell(eventState),
        clientProxy = nil,
        unitByEventId = {},
        actors = {},
        actorByKey = {},
        actorMembers = {},
        spellRefsByEventId = {},
        movementByEventId = {},
        activeAuraRecords = {},
        activeAurasByTargetEventId = {},
        controlStateByTargetEventId = {},
        activeCastSummaries = {},
        activeCastsByEventId = {},
        configurationRevision = getConfigurationRevision(),
        auraRevision = getAuraRevision(eventState.id),
        spatialRuntime = {
            eventId = tostring(eventState.id or ""),
            status = "ready",
            instanceID = state.runtimeRef and state.runtimeRef.instanceID or nil,
            playerPositionByEventId = {},
            positionByActorKey = {},
        },
    }
    state.snapshot.auraRecords = state.snapshot.activeAuraRecords
    state.snapshot.auraRecordsByTargetEventId = state.snapshot.activeAurasByTargetEventId
    state.snapshot.activeCastByEventId = state.snapshot.activeCastsByEventId
    state.snapshot.clientProxy = buildFrozenClientProxy(state.snapshot.eventState)
    state.scratch = {
        projectedHealingLedger = type(SpellEvaluator.CreateProjectedHealingLedger) == "function"
            and SpellEvaluator.CreateProjectedHealingLedger()
            or { reservedByEventId = {} },
        projectedAuraLedger = nil,
        spellDefinitionByRef = {},
        auraDefinitionCache = type(AuraEvaluator.CreatePlanCache) == "function"
            and AuraEvaluator.CreatePlanCache()
            or { definitionsByKey = {} },
        auraSourceBucket = nil,
        auraSourceRevision = nil,
        auraGenerationCaptured = false,
        auraGenerationRetries = 0,
        auraKeys = {},
        castKeys = {},
        castSourceBucket = nil,
        castSourceRevision = nil,
        castGenerationCaptured = false,
        castGenerationRetries = 0,
        activationByKey = {},
        activationKeys = {},
        profileByKey = {},
        healthByEventId = {},
        movementByEventId = {},
        targetSelectionByKey = {},
        targetOrderByKey = {},
        actionCandidatesByEventId = {},
        movementSolveByActorKey = {},
        fixedSolveByActorKey = {},
        positionWarningByActorKey = {},
    }
    state.cursors = {
        unit = 1,
        auraKeyScan = nil,
        auraScanComplete = false,
        auraCopyIndex = 1,
        castKeyScan = nil,
        castScanComplete = false,
        castCopyIndex = 1,
        member = 1,
        spell = 1,
        intent = 1,
        actor = 1,
        revalidateUnit = 1,
        revalidateMember = 1,
        revalidateActivation = 1,
    }
    state.output = {
        movements = {},
        actions = {},
        noActions = {},
        warnings = {},
    }
    state.metrics = {
        startedAtMs = nowMilliseconds(),
        completedAtMs = nil,
        totalWallMs = 0,
        sliceCount = 0,
        yieldCount = 0,
        maxSliceMs = 0,
        candidateSpellCount = 0,
        candidateTargetCount = 0,
        actionCandidateCount = 0,
        candidateAnchorCount = 0,
        rejectedUnreachableAnchors = 0,
        movementAllowanceByActor = {},
    }
    state.result = nil
    return state
end

local function runPlannerStep(state, deadlineMs)
    while state.phase ~= "complete" do
        if state.phase == "validate" then
            phaseValidate(state)
        elseif state.phase == "snapshot-units" then
            if phaseSnapshotUnits(state, deadlineMs) == false then return false end
        elseif state.phase == "snapshot-positions" then
            if phaseSnapshotPositions(state, deadlineMs) == false then return false end
        elseif state.phase == "snapshot-auras" then
            if phaseSnapshotAuras(state, deadlineMs) == false then return false end
        elseif state.phase == "snapshot-casts" then
            if phaseSnapshotCasts(state, deadlineMs) == false then return false end
        elseif state.phase == "snapshot-spells" then
            if phaseSnapshotSpells(state, deadlineMs) == false then return false end
        elseif state.phase == "snapshot-movement" then
            if phaseSnapshotMovement(state, deadlineMs) == false then return false end
        elseif state.phase == "activation" then
            if phaseActivation(state, deadlineMs) == false then return false end
        elseif state.phase == "targets" then
            if phaseTargets(state, deadlineMs) == false then return false end
        elseif state.phase == "solve-actors" then
            if phaseSolveActors(state, deadlineMs) == false then return false end
        elseif state.phase == "revalidate" then
            if phaseRevalidate(state, deadlineMs) == false then return false end
        elseif state.phase == "finalize" then
            return phaseFinalize(state)
        else
            state.failureReason = "unknown-planner-phase"
            state.phase = "finalize"
        end

        if state.phase ~= "complete" and shouldYield(deadlineMs) then
            return false
        end
    end
    return true
end

function Planner.Step(state, deadlineMs)
    if type(state) ~= "table" then
        return true
    end
    local startedAt = nowMilliseconds()
    state.metrics = type(state.metrics) == "table" and state.metrics or {}
    state.metrics.sliceCount = (tonumber(state.metrics.sliceCount) or 0) + 1

    local complete = runPlannerStep(state, deadlineMs) == true
    local endedAt = nowMilliseconds()
    local elapsed = math.max(0, endedAt - startedAt)
    state.metrics.maxSliceMs = math.max(tonumber(state.metrics.maxSliceMs) or 0, elapsed)
    if not complete then
        state.metrics.yieldCount = (tonumber(state.metrics.yieldCount) or 0) + 1
    else
        state.metrics.completedAtMs = endedAt
        state.metrics.totalWallMs = math.max(0, endedAt - (tonumber(state.metrics.startedAtMs) or endedAt))
        if type(state.result) == "table" then
            state.result.metrics = copyMetrics(state.metrics)
        end
    end
    return complete
end

function Planner.CopyCompletedPlan(state)
    if type(state) ~= "table" or state.phase ~= "complete" or type(state.result) ~= "table" then
        return nil
    end

    local source = state.result
    if tostring(source.status or "") ~= "ready" then
        return nil
    end
    local copied = {
        planId = tostring(source.planId or ""),
        eventId = tostring(source.eventId or ""),
        turnNumber = math.max(0, math.floor(tonumber(source.turnNumber) or 0)),
        tickNumber = math.max(0, math.floor(tonumber(source.tickNumber) or 0)),
        actorKey = tostring(source.actorKey or ""),
        actorKeys = copyArray(source.actorKeys),
        npcEventIds = copyArray(source.npcEventIds),
        scheduleRevision = tostring(source.scheduleRevision or ""),
        snapshot = copyDeep(source.snapshot),
        movements = {},
        movement = nil,
        actions = {},
        noActions = {},
        warnings = {},
        records = {},
        metrics = copyMetrics(source.metrics),
        status = tostring(source.status or "ready"),
        reason = source.reason,
    }
    for index = 1, #(source.movements or {}) do
        copied.movements[index] = copyMovement(source.movements[index])
    end
    if #copied.movements == 1 then
        copied.movement = copied.movements[1]
    end
    for index = 1, #(source.actions or {}) do
        copied.actions[index] = copyAction(source.actions[index])
    end
    for index = 1, #(source.noActions or {}) do
        copied.noActions[index] = copyNoAction(source.noActions[index])
    end
    for index = 1, #(source.warnings or {}) do
        copied.warnings[index] = copyWarning(source.warnings[index])
    end
    for index = 1, #(source.records or {}) do
        local record = source.records[index]
        if record.actionType == "spell" then
            copied.records[index] = copyAction(record)
        elseif record.actionType == "movement" then
            copied.records[index] = copyMovement(record)
        else
            copied.records[index] = copyMap(record)
        end
    end
    return copied
end

function Planner.ReleaseScratch(state)
    if type(state) ~= "table" then
        return false
    end
    state.sourceEventState = nil
    state.snapshot = nil
    state.scratch = nil
    state.cursors = nil
    state.output = nil
    if type(baseReleaseScratch) == "function" then
        local result = state.result
        baseReleaseScratch(state)
        state.result = result
    end
    state.result = nil
    return true
end

function Planner.IsFrozenSnapshotStale(state)
    if type(state) ~= "table"
        or type(state.snapshot) ~= "table"
        or type(state.snapshot.eventState) ~= "table"
    then
        return true
    end
    if state.snapshot.unitsFrozen ~= true then
        return false
    end

    local liveEventState = type(Server.EventState) == "table"
        and Server.EventState
        or state.sourceEventState
    if type(liveEventState) ~= "table" then
        return true
    end

    local frozenByEventId = {}
    for index = 1, #(state.snapshot.eventState.units or {}) do
        local frozenUnit = state.snapshot.eventState.units[index]
        local eventId = normalizeEventId(frozenUnit and frozenUnit.eventID)
        if eventId > 0 then
            frozenByEventId[eventId] = frozenUnit
        end
    end

    local liveByEventId = {}
    for index = 1, #(liveEventState.units or {}) do
        local liveUnit = liveEventState.units[index]
        local eventId = normalizeEventId(liveUnit and liveUnit.eventID)
        if eventId > 0 then
            liveByEventId[eventId] = liveUnit
        end
    end

    for eventId, frozenUnit in pairs(frozenByEventId) do
        local liveUnit = liveByEventId[eventId]
        local liveTauntState = getHostLocalTauntState(liveEventState, eventId)
        if type(liveUnit) ~= "table"
            or buildTauntSignature(frozenUnit and frozenUnit.tauntState)
                ~= buildTauntSignature(liveTauntState)
        then
            return true
        end
    end
    for eventId in pairs(liveByEventId) do
        if frozenByEventId[eventId] == nil then
            return true
        end
    end
    return false
end

local baseIsAutopilotPlanStateStale = Client.IsAutopilotPlanStateStale
if type(baseIsAutopilotPlanStateStale) == "function" then
    function Client:IsAutopilotPlanStateStale(state)
        if baseIsAutopilotPlanStateStale(self, state) == true then
            return true
        end
        return Planner.IsFrozenSnapshotStale(state) == true
    end
end

function Client:ReplanAutopilotCurrentStep(eventStateOverride)
    if type(self.ReplaceAutopilotPlanForCurrentStep) ~= "function" then
        return nil, false, "replan-api-unavailable"
    end
    return self:ReplaceAutopilotPlanForCurrentStep(eventStateOverride)
end

Planner.ResolveActiveNpcStep = baseResolveActiveNpcStep
Planner.BuildPlanIdentity = baseBuildPlanIdentity

return Planner
