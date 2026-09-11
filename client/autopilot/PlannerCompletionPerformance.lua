local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Planner = Client.AutopilotPlanner or {}
local Spatial = Client.AutopilotSpatial or {}
local Tasks = Addon.Internal.Tasks or {}
local Debug = Addon.Debug or {}
local Event = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event or nil
local unpackValues = unpack or table.unpack

if type(Planner) ~= "table" or Planner._performanceBoundedPlannerInstalled == true then return end
local Performance = Planner.Performance or {}
if type(Performance.StepTargets) ~= "function" or type(Performance.StepSolveActors) ~= "function" then return end
local basePlannerStep = Planner.Step
if type(basePlannerStep) ~= "function" then return end

local function nowMilliseconds()
    if type(debugprofilestop) == "function" then return tonumber(debugprofilestop()) or 0 end
    if type(GetTimePreciseSec) == "function" then return (tonumber(GetTimePreciseSec()) or 0) * 1000 end
    if type(GetTime) == "function" then return (tonumber(GetTime()) or 0) * 1000 end
    return 0
end
local function shouldYield(deadlineMs)
    return type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true
end
local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end
local function normalizeRaidMarker(value) return math.max(0, math.floor(tonumber(value) or 0)) end
local function copyArray(values)
    local copied = {}
    for index = 1, #(values or {}) do copied[index] = values[index] end
    return copied
end
local function copyMap(values)
    local copied = {}
    for key, value in pairs(type(values) == "table" and values or {}) do copied[key] = value end
    return copied
end
local function copyResourceEntries(entries)
    local copied = {}
    for index = 1, #(entries or {}) do copied[index] = type(entries[index]) == "table" and copyMap(entries[index]) or entries[index] end
    return copied
end
local function copyThreatTable(values)
    local copied = {}
    for key, value in pairs(type(values) == "table" and values or {}) do
        local eventId = normalizeEventId(key)
        if eventId > 0 then copied[eventId] = tonumber(value) or 0 end
    end
    return copied
end

local function callBaseUntilInterceptPhase(baseFn, state, deadlineMs, interceptPhases)
    local originalShouldYield = Tasks.ShouldYield
    if type(originalShouldYield) ~= "function" then return baseFn(state, deadlineMs) end
    Tasks.ShouldYield = function(self, deadline)
        local phase = tostring(state.phase or "")
        if type(interceptPhases) == "table" and interceptPhases[phase] == true then return true end
        return originalShouldYield(self, deadline)
    end
    local results = { pcall(baseFn, state, deadlineMs) }
    Tasks.ShouldYield = originalShouldYield
    if results[1] ~= true then error(results[2], 0) end
    return unpackValues(results, 2, #results)
end

local function isUnitActive(unit)
    if type(Event) == "table" and type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end
    return type(unit) == "table" and (unit.isPlayer == true or unit.active ~= false)
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
        spellRefs = copyArray(spellRefs),
        movement = type(movementSnapshot) == "table" and copyMap(movementSnapshot) or nil,
    }
end

local function copyMetrics(metrics)
    local copied = copyMap(metrics)
    copied.movementAllowanceByActor = copyMap(type(metrics) == "table" and metrics.movementAllowanceByActor or nil)
    return copied
end

local function ensureFinalizeState(state)
    local finalize = state.scratch.performanceFinalize
    if type(finalize) == "table" then return finalize end
    local source = state.snapshot
    local snapshot = {
        eventId = state.eventId,
        turnNumber = state.turnNumber,
        tickNumber = state.tickNumber,
        actorKey = state.actorKey,
        actorKeys = copyArray(state.actorKeys),
        scheduleRevision = state.scheduleRevision,
        members = {},
        -- These structures are already frozen planner-owned copies. Transfer
        -- ownership instead of recursively copying them a second time.
        playerPositions = source.spatialRuntime.playerPositionByEventId,
        actorPositions = source.spatialRuntime.positionByActorKey,
        activeAuraRecords = source.activeAuraRecords,
        activeAurasByTargetEventId = source.activeAurasByTargetEventId,
        controlStateByTargetEventId = source.controlStateByTargetEventId,
        activeCastSummaries = source.activeCastSummaries,
        activeCastsByEventId = source.activeCastsByEventId,
    }
    snapshot.auraRecords = snapshot.activeAuraRecords
    snapshot.auraRecordsByTargetEventId = snapshot.activeAurasByTargetEventId
    snapshot.activeCastByEventId = snapshot.activeCastsByEventId

    local result = {
        planId = state.planId,
        eventId = state.eventId,
        turnNumber = state.turnNumber,
        tickNumber = state.tickNumber,
        actorKey = state.actorKey,
        actorKeys = copyArray(state.actorKeys),
        npcEventIds = copyArray(state.npcEventIds),
        scheduleRevision = state.scheduleRevision,
        snapshot = snapshot,
        movements = state.output.movements,
        movement = #state.output.movements == 1 and state.output.movements[1] or nil,
        actions = state.output.actions,
        noActions = state.output.noActions,
        warnings = state.output.warnings,
        records = {},
        metrics = nil,
        status = state.failureReason and "failed" or "ready",
        reason = state.failureReason,
    }
    finalize = {
        result = result,
        memberIndex = 1,
        recordGroup = 1,
        recordIndex = 1,
    }
    state.scratch.performanceFinalize = finalize
    return finalize
end

local function stepFinalizeBounded(state, deadlineMs)
    local finalize = ensureFinalizeState(state)
    local result = finalize.result
    while finalize.memberIndex <= #(state.snapshot.actorMembers or {}) do
        local entry = state.snapshot.actorMembers[finalize.memberIndex]
        local unit = entry and entry.unit
        local eventId = normalizeEventId(unit and unit.eventID)
        if eventId > 0 then
            result.snapshot.members[#result.snapshot.members + 1] = snapshotUnitSummary(
                unit,
                state.snapshot.spellRefsByEventId[eventId],
                state.snapshot.movementByEventId[eventId]
            )
        end
        finalize.memberIndex = finalize.memberIndex + 1
        if shouldYield(deadlineMs) then return false end
    end

    local groups = { result.movements, result.actions, result.noActions, result.warnings }
    while finalize.recordGroup <= #groups do
        local group = groups[finalize.recordGroup] or {}
        if finalize.recordIndex <= #group then
            result.records[#result.records + 1] = group[finalize.recordIndex]
            finalize.recordIndex = finalize.recordIndex + 1
            if shouldYield(deadlineMs) then return false end
        else
            finalize.recordGroup = finalize.recordGroup + 1
            finalize.recordIndex = 1
        end
    end

    state.result = result
    state.phase = "complete"
    return true
end

local function phaseMetricKey(phase)
    local key = tostring(phase or "")
    if key == "activation" then return "activationMaxMs" end
    if key == "targets" then return "targetsMaxMs" end
    if key == "solve-actors" then return "solveMaxMs" end
    if key == "finalize" then return "finalizeMaxMs" end
    return "snapshotMaxMs"
end

local function recordPhaseMetric(state, phase, elapsed)
    state.metrics = type(state.metrics) == "table" and state.metrics or {}
    local key = phaseMetricKey(phase)
    state.metrics[key] = math.max(tonumber(state.metrics[key]) or 0, math.max(0, tonumber(elapsed) or 0))
end

local function logMetrics(state)
    if state._performanceMetricsLogged == true or type(Debug.Internal) ~= "function" then return end
    state._performanceMetricsLogged = true
    local m = state.metrics or {}
    Debug.Internal(
        "Autopilot planner complete event=%s turn=%d tick=%d actor=%s slices=%d yields=%d maxSlice=%.2fms wall=%.2fms snapshotMax=%.2fms activationMax=%.2fms targetsMax=%.2fms solveMax=%.2fms finalizeMax=%.2fms spells=%d targets=%d anchors=%d unreachable=%d",
        tostring(state.eventId or ""),
        tonumber(state.turnNumber) or 0,
        tonumber(state.tickNumber) or 0,
        tostring(state.actorKey or ""),
        tonumber(m.sliceCount) or 0,
        tonumber(m.yieldCount) or 0,
        tonumber(m.maxSliceMs) or 0,
        tonumber(m.totalWallMs) or 0,
        tonumber(m.snapshotMaxMs) or 0,
        tonumber(m.activationMaxMs) or 0,
        tonumber(m.targetsMaxMs) or 0,
        tonumber(m.solveMaxMs) or 0,
        tonumber(m.finalizeMaxMs) or 0,
        tonumber(m.candidateSpellCount) or 0,
        tonumber(m.candidateTargetCount) or 0,
        tonumber(m.candidateAnchorCount) or 0,
        tonumber(m.rejectedUnreachableAnchors) or 0
    )
end

local function runCustomPlannerPhase(state, deadlineMs)
    if state.phase == "targets" then
        return Performance.StepTargets(state, deadlineMs)
    elseif state.phase == "solve-actors" then
        return Performance.StepSolveActors(state, deadlineMs)
    elseif state.phase == "revalidate" then
        state.phase = "finalize"
        return false
    elseif state.phase == "finalize" then
        return stepFinalizeBounded(state, deadlineMs)
    end
    return nil
end

function Planner.Step(state, deadlineMs)
    if type(state) ~= "table" then return true end
    state.metrics = type(state.metrics) == "table" and state.metrics or {}
    local entryPhase = tostring(state.phase or "")
    local isCustom = entryPhase == "targets" or entryPhase == "solve-actors"
        or entryPhase == "revalidate" or entryPhase == "finalize"
    local startedAt = nowMilliseconds()
    local complete

    if isCustom then
        state.metrics.sliceCount = (tonumber(state.metrics.sliceCount) or 0) + 1
        complete = runCustomPlannerPhase(state, deadlineMs) == true
    else
        complete = callBaseUntilInterceptPhase(basePlannerStep, state, deadlineMs, { activation = true, targets = true, finalize = true }) == true
    end

    local endedAt = nowMilliseconds()
    local elapsed = math.max(0, endedAt - startedAt)
    recordPhaseMetric(state, entryPhase, elapsed)

    if isCustom then
        state.metrics.maxSliceMs = math.max(tonumber(state.metrics.maxSliceMs) or 0, elapsed)
        if not complete then
            state.metrics.yieldCount = (tonumber(state.metrics.yieldCount) or 0) + 1
        end
    end

    if state.phase == "complete" then
        state.metrics.completedAtMs = endedAt
        state.metrics.totalWallMs = math.max(0, endedAt - (tonumber(state.metrics.startedAtMs) or endedAt))
        if type(state.result) == "table" then
            state.result.metrics = copyMetrics(state.metrics)
        end
        logMetrics(state)
        return true
    end
    return complete
end

-- The completed result is already detached/frozen by bounded finalization.
-- Retain the legacy name for the only current coordinator call site, but transfer
-- the completed object instead of deep-copying it again.
function Planner.CopyCompletedPlan(state)
    if type(state) ~= "table" or state.phase ~= "complete" or type(state.result) ~= "table" then
        return nil
    end
    if tostring(state.result.status or "") ~= "ready" then
        return nil
    end
    return state.result
end

function Planner.TakeCompletedPlan(state)
    return Planner.CopyCompletedPlan(state)
end

-- Cleanup is deliberately publication-free. The coordinator's onComplete path
-- owns the single PublishAutopilotPendingPlan call before this function runs.
function Planner.ReleaseScratch(state)
    if type(state) ~= "table" then return false end
    state.sourceEventState = nil
    state.snapshot = nil
    state.scratch = nil
    state.cursors = nil
    state.output = nil
    state.provisionalActions = nil
    state.actionCandidates = nil
    state.anchorCandidates = nil
    state.result = nil
    return true
end

Planner._performanceBoundedPlannerInstalled = true
return Planner
