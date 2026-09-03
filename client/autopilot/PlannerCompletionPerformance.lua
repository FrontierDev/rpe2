local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Planner = Client.AutopilotPlanner or {}
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local Tasks = Addon.Internal.Tasks or {}
local Debug = Addon.Debug or {}
local unpackValues = unpack or table.unpack

if type(Planner) ~= "table" or Planner._performanceCompletionInstalled == true then
    return
end

Planner.Performance = Planner.Performance or {}
local Performance = Planner.Performance
local basePlannerStep = Planner.Step

if type(basePlannerStep) ~= "function"
    or type(Performance.StepTargets) ~= "function"
    or type(Performance.StepSolveActors) ~= "function"
then
    return
end

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

local function isUnitActive(unit)
    if type(Event) == "table" and type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end
    return type(unit) == "table" and (unit.isPlayer == true or unit.active ~= false)
end

local function ensurePerformanceMetrics(state)
    state.metrics = type(state.metrics) == "table" and state.metrics or {}
    local metrics = state.metrics
    metrics.snapshotMaxMs = tonumber(metrics.snapshotMaxMs) or 0
    metrics.activationMaxMs = tonumber(metrics.activationMaxMs) or 0
    metrics.targetsMaxMs = tonumber(metrics.targetsMaxMs) or 0
    metrics.solveMaxMs = tonumber(metrics.solveMaxMs) or 0
    metrics.finalizeMaxMs = tonumber(metrics.finalizeMaxMs) or 0
    return metrics
end

local function phaseMetricField(phase)
    phase = tostring(phase or "")
    if phase == "activation" then
        return "activationMaxMs"
    end
    if phase == "targets" then
        return "targetsMaxMs"
    end
    if phase == "solve-actors" then
        return "solveMaxMs"
    end
    if phase == "finalize" then
        return "finalizeMaxMs"
    end
    return "snapshotMaxMs"
end

local function recordPhaseElapsed(state, phase, elapsedMs)
    local metrics = ensurePerformanceMetrics(state)
    local field = phaseMetricField(phase)
    metrics[field] = math.max(tonumber(metrics[field]) or 0, math.max(0, tonumber(elapsedMs) or 0))
end

local function buildMemberSummary(state, entry)
    local unit = type(entry) == "table" and entry.unit or nil
    local eventId = normalizeEventId(unit and unit.eventID)
    if eventId <= 0 then
        return nil
    end
    -- These nested tables already belong to the frozen planner snapshot. They
    -- are immutable after planning, so completion can transfer references
    -- instead of recursively copying them a second time.
    return {
        eventID = eventId,
        name = tostring(unit and unit.name or ""),
        active = isUnitActive(unit),
        dead = unit and unit.dead == true or false,
        team = tonumber(unit and unit.team) or 0,
        raidMarker = normalizeRaidMarker(unit and unit.raidMarker),
        resources = unit and unit.resources or {},
        threatTable = unit and unit.threatTable or {},
        spellRefs = state.snapshot.spellRefsByEventId[eventId] or {},
        movement = state.snapshot.movementByEventId[eventId],
    }
end

local function createFinalizeState(state)
    local snapshot = state.snapshot or {}
    local spatialRuntime = snapshot.spatialRuntime or {}
    local output = state.output or {}
    local resultSnapshot = {
        eventId = state.eventId,
        turnNumber = state.turnNumber,
        tickNumber = state.tickNumber,
        actorKey = state.actorKey,
        actorKeys = state.actorKeys,
        scheduleRevision = state.scheduleRevision,
        members = {},
        playerPositions = spatialRuntime.playerPositionByEventId or {},
        actorPositions = spatialRuntime.positionByActorKey or {},
        activeAuraRecords = snapshot.activeAuraRecords or {},
        activeAurasByTargetEventId = snapshot.activeAurasByTargetEventId or {},
        controlStateByTargetEventId = snapshot.controlStateByTargetEventId or {},
        activeCastSummaries = snapshot.activeCastSummaries or {},
        activeCastsByEventId = snapshot.activeCastsByEventId or {},
    }
    resultSnapshot.auraRecords = resultSnapshot.activeAuraRecords
    resultSnapshot.auraRecordsByTargetEventId = resultSnapshot.activeAurasByTargetEventId
    resultSnapshot.activeCastByEventId = resultSnapshot.activeCastsByEventId

    local result = {
        planId = state.planId,
        eventId = state.eventId,
        turnNumber = state.turnNumber,
        tickNumber = state.tickNumber,
        actorKey = state.actorKey,
        actorKeys = state.actorKeys,
        npcEventIds = state.npcEventIds,
        scheduleRevision = state.scheduleRevision,
        snapshot = resultSnapshot,
        movements = output.movements or {},
        movement = nil,
        actions = output.actions or {},
        noActions = output.noActions or {},
        warnings = output.warnings or {},
        records = {},
        metrics = ensurePerformanceMetrics(state),
        status = state.failureReason and "failed" or "ready",
        reason = state.failureReason,
    }
    if #result.movements == 1 then
        result.movement = result.movements[1]
    end
    state.result = result
    return {
        stage = "members",
        index = 1,
        result = result,
    }
end

function Performance.StepFinalize(state, deadlineMs)
    local finalize = state.performanceFinalize
    if type(finalize) ~= "table" then
        finalize = createFinalizeState(state)
        state.performanceFinalize = finalize
        if shouldYield(deadlineMs) then
            return false
        end
    end

    local result = finalize.result
    if finalize.stage == "members" then
        local members = state.snapshot and state.snapshot.actorMembers or {}
        while finalize.index <= #members do
            local summary = buildMemberSummary(state, members[finalize.index])
            if summary then
                result.snapshot.members[#result.snapshot.members + 1] = summary
            end
            finalize.index = finalize.index + 1
            if shouldYield(deadlineMs) then
                return false
            end
        end
        finalize.stage = "movements"
        finalize.index = 1
    end

    local stages = {
        { name = "movements", source = result.movements },
        { name = "actions", source = result.actions },
        { name = "noActions", source = result.noActions },
        { name = "warnings", source = result.warnings },
    }
    local stageIndexByName = {
        movements = 1,
        actions = 2,
        noActions = 3,
        warnings = 4,
    }

    while finalize.stage ~= "complete" do
        local stageIndex = stageIndexByName[finalize.stage]
        if not stageIndex then
            finalize.stage = "complete"
            break
        end
        local source = stages[stageIndex].source
        if finalize.index <= #(source or {}) then
            result.records[#result.records + 1] = source[finalize.index]
            finalize.index = finalize.index + 1
            if shouldYield(deadlineMs) then
                return false
            end
        else
            if stageIndex >= #stages then
                finalize.stage = "complete"
            else
                finalize.stage = stages[stageIndex + 1].name
                finalize.index = 1
            end
        end
    end

    state.phase = "complete"
    return true
end

local function runBaseUntilPerformancePhase(state, deadlineMs)
    local originalShouldYield = Tasks.ShouldYield
    if type(originalShouldYield) ~= "function" then
        return basePlannerStep(state, deadlineMs)
    end

    Tasks.ShouldYield = function(self, deadline)
        local phase = tostring(state.phase or "")
        if phase == "targets" or phase == "solve-actors" or phase == "finalize" then
            return true
        end
        return originalShouldYield(self, deadline)
    end
    local results = { pcall(basePlannerStep, state, deadlineMs) }
    Tasks.ShouldYield = originalShouldYield
    if results[1] ~= true then
        error(results[2], 0)
    end
    return unpackValues(results, 2, #results)
end

local function logCompletion(state)
    if type(Debug.Internal) ~= "function" then
        return
    end
    local metrics = ensurePerformanceMetrics(state)
    Debug.Internal(
        "Autopilot planner complete event=%s turn=%d tick=%d actor=%s slices=%d yields=%d maxSlice=%.2fms wall=%.2fms spells=%d targets=%d anchors=%d unreachable=%d snapshotMax=%.2fms activationMax=%.2fms targetsMax=%.2fms solveMax=%.2fms finalizeMax=%.2fms",
        tostring(state.eventId or ""),
        tonumber(state.turnNumber) or 0,
        tonumber(state.tickNumber) or 0,
        tostring(state.actorKey or ""),
        tonumber(metrics.sliceCount) or 0,
        tonumber(metrics.yieldCount) or 0,
        tonumber(metrics.maxSliceMs) or 0,
        tonumber(metrics.totalWallMs) or 0,
        tonumber(metrics.candidateSpellCount) or 0,
        tonumber(metrics.candidateTargetCount) or 0,
        tonumber(metrics.candidateAnchorCount) or 0,
        tonumber(metrics.rejectedUnreachableAnchors) or 0,
        tonumber(metrics.snapshotMaxMs) or 0,
        tonumber(metrics.activationMaxMs) or 0,
        tonumber(metrics.targetsMaxMs) or 0,
        tonumber(metrics.solveMaxMs) or 0,
        tonumber(metrics.finalizeMaxMs) or 0
    )
end

function Planner.Step(state, deadlineMs)
    if type(state) ~= "table" then
        return true
    end

    local phaseAtStart = tostring(state.phase or "")
    local customStep = nil
    if phaseAtStart == "targets" then
        customStep = Performance.StepTargets
    elseif phaseAtStart == "solve-actors" then
        customStep = Performance.StepSolveActors
    elseif phaseAtStart == "finalize" then
        customStep = Performance.StepFinalize
    end

    if type(customStep) ~= "function" then
        local startedAt = nowMilliseconds()
        local completed = runBaseUntilPerformancePhase(state, deadlineMs) == true
        recordPhaseElapsed(state, phaseAtStart, nowMilliseconds() - startedAt)
        return completed
    end

    local metrics = ensurePerformanceMetrics(state)
    metrics.sliceCount = (tonumber(metrics.sliceCount) or 0) + 1
    local startedAt = nowMilliseconds()
    local completed = customStep(state, deadlineMs) == true
    local endedAt = nowMilliseconds()
    local elapsed = math.max(0, endedAt - startedAt)
    metrics.maxSliceMs = math.max(tonumber(metrics.maxSliceMs) or 0, elapsed)
    recordPhaseElapsed(state, phaseAtStart, elapsed)

    if completed then
        metrics.completedAtMs = endedAt
        metrics.totalWallMs = math.max(0, endedAt - (tonumber(metrics.startedAtMs) or endedAt))
        if type(state.result) == "table" then
            state.result.metrics = metrics
        end
        logCompletion(state)
    else
        metrics.yieldCount = (tonumber(metrics.yieldCount) or 0) + 1
    end
    return completed
end

-- Completion transfers the already-frozen result graph to the coordinator.
-- No second deep copy is made; ReleaseScratch only drops planner-owned roots.
function Planner.CopyCompletedPlan(state)
    if type(state) ~= "table"
        or state.phase ~= "complete"
        or type(state.result) ~= "table"
        or tostring(state.result.status or "") ~= "ready"
    then
        return nil
    end
    local result = state.result
    state.result = nil
    state.completedResultDetached = true
    return result
end

-- Final load-order override: cleanup only. Authorization.lua previously wrapped
-- ReleaseScratch to publish a ready plan a second time; publication is owned by
-- client_AutopilotPlanner.lua:onComplete and must happen exactly once.
function Planner.ReleaseScratch(state)
    if type(state) ~= "table" then
        return false
    end
    state.sourceEventState = nil
    state.snapshot = nil
    state.scratch = nil
    state.cursors = nil
    state.output = nil
    state.provisionalActions = nil
    state.actionCandidates = nil
    state.anchorCandidates = nil
    state.performanceFinalize = nil
    state.result = nil
    return true
end

Planner._performanceCompletionInstalled = true
return Performance
