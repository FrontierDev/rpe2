local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Planner = Client.AutopilotPlanner or {}
local Tasks = Addon.Internal.Tasks or {}
local Debug = Addon.Debug or {}
local Database = Addon.Internal.Database or {}
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local unpackValues = unpack or table.unpack

if type(Planner) ~= "table" or Planner._performanceSnapshotUnitsInstalled == true then
    return
end

local basePlannerStep = Planner.Step
if type(basePlannerStep) ~= "function" then
    return
end

local baseGetDatasetByID = Database.GetDatasetByID
local baseListActivatedDatasetIds = Database.ListActivatedDatasetIds
local baseGetRulesetByID = Database.GetRulesetByID
local baseGetActiveRulesetId = Database.GetActiveRulesetId
local activePlannerState = nil

local function plannerScopeActive()
    return type(activePlannerState) == "table"
end

local function getStableDatasetRoot()
    local root = Database.Datasets
    if type(root) ~= "table"
        or root ~= rawget(_G, "RPEngineDatasetDB")
        or type(root.datasets) ~= "table"
    then
        return nil
    end
    return root
end

local function getStableRulesetRoot()
    local root = Database.Rulesets
    if type(root) ~= "table"
        or root ~= rawget(_G, "RPEngineRulesetDB")
        or type(root.rulesets) ~= "table"
        or type(root.activeByChar) ~= "table"
    then
        return nil
    end
    return root
end

local function getCurrentCharacterKey()
    if type(UnitFullName) == "function" then
        local name, realm = UnitFullName("player")
        if type(name) == "string" and name ~= "" then
            realm = realm or (type(GetRealmName) == "function" and GetRealmName()) or ""
            if realm ~= "" then
                return ("%s-%s"):format(name, realm)
            end
            return name
        end
    end

    if type(UnitName) == "function" then
        local name = UnitName("player")
        if type(name) == "string" and name ~= "" then
            local realm = type(GetRealmName) == "function" and GetRealmName() or ""
            if realm ~= "" then
                return ("%s-%s"):format(name, realm)
            end
            return name
        end
    end

    return "unknown-player"
end

-- Database.GetDatasetByID normally routes through EnsureDatasets(), which
-- canonicalizes the complete dataset root and recomputes dependencies on each
-- read. Planner preparation, Aura resolution, activation, and movement perform
-- many such reads against a root that is already initialized and stable for the
-- duration of one Planner.Step slice. Bypass only that repeated normalization
-- while the planner is on-stack; every other caller retains the canonical API.
if type(baseGetDatasetByID) == "function" then
    function Database.GetDatasetByID(datasetId)
        if plannerScopeActive() and datasetId ~= nil and datasetId ~= "" then
            local root = getStableDatasetRoot()
            if root then
                return root.datasets[tostring(datasetId)]
            end
        end
        return baseGetDatasetByID(datasetId)
    end
end

if type(baseListActivatedDatasetIds) == "function" then
    function Database.ListActivatedDatasetIds()
        if plannerScopeActive() then
            local root = getStableDatasetRoot()
            if root and type(root.activatedDatasets) == "table" then
                return root.activatedDatasets
            end
        end
        return baseListActivatedDatasetIds()
    end
end

-- Ruleset reads have the same repeated-normalization path through
-- EnsureRulesets(). The fast path is used only for a stable initialized root and
-- an exact current-character active entry. Legacy unknown-player migration and
-- replaced roots deliberately fall back to the canonical database functions.
if type(baseGetRulesetByID) == "function" then
    function Database.GetRulesetByID(rulesetId)
        if plannerScopeActive() and rulesetId ~= nil and rulesetId ~= "" then
            local root = getStableRulesetRoot()
            if root then
                return root.rulesets[tostring(rulesetId)]
            end
        end
        return baseGetRulesetByID(rulesetId)
    end
end

if type(baseGetActiveRulesetId) == "function" then
    function Database.GetActiveRulesetId()
        if plannerScopeActive() then
            local root = getStableRulesetRoot()
            if root then
                local characterKey = getCurrentCharacterKey()
                local exactValue = root.activeByChar[characterKey]
                if exactValue ~= nil then
                    return exactValue
                end
                if characterKey == "unknown-player" or root.activeByChar["unknown-player"] == nil then
                    return nil
                end
            end
        end
        return baseGetActiveRulesetId()
    end
end

-- PlannerPreparationPerformance temporarily skipped the canonical initial-target
-- resolver for frozen planner proxies. That shortcut changes the condition
-- context because spell conditions are evaluated before the later candidate
-- collection pass. Preserve the canonical resolver exactly for planner proxies;
-- the prepared registry caches still remove the expensive first-use scans.
local preparedResolveSpellActivationTargetUnit = Client.ResolveSpellActivationTargetUnit
if type(preparedResolveSpellActivationTargetUnit) == "function"
    and Client._autopilotCanonicalInitialTargetRestored ~= true
then
    function Client:ResolveSpellActivationTargetUnit(activation, targetGroup)
        if rawget(self, "__autopilotPlannerProxy") == true then
            rawset(self, "__autopilotPlannerProxy", nil)
            local results = { pcall(preparedResolveSpellActivationTargetUnit, self, activation, targetGroup) }
            rawset(self, "__autopilotPlannerProxy", true)
            if results[1] ~= true then
                error(results[2], 0)
            end
            return results[2]
        end
        return preparedResolveSpellActivationTargetUnit(self, activation, targetGroup)
    end
    Client._autopilotCanonicalInitialTargetRestored = true
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

local function isUnitActive(unit)
    if type(Event) == "table" and type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end
    return type(unit) == "table" and (unit.isPlayer == true or unit.active ~= false)
end

local function createCloneState(source)
    return {
        source = source,
        result = {},
        stage = "scalars",
        scalarCursor = nil,
        resourceIndex = 1,
        statIndex = 1,
        spellIndex = 1,
        threatCursor = nil,
    }
end

local function copyShallowEntry(entry)
    if type(entry) ~= "table" then
        return entry
    end
    local copied = {}
    for key, value in pairs(entry) do
        copied[key] = value
    end
    return copied
end

local function stepCloneState(clone, deadlineMs)
    local source = clone.source
    local result = clone.result

    if clone.stage == "scalars" then
        local key, value = next(source, clone.scalarCursor)
        while key ~= nil do
            clone.scalarCursor = key
            if type(value) ~= "table" then
                result[key] = value
            end
            if shouldYield(deadlineMs) then
                return false
            end
            key, value = next(source, clone.scalarCursor)
        end
        result.resources = {}
        result.stats = {}
        result.spells = {}
        result.threatTable = {}
        clone.stage = "resources"
    end

    if clone.stage == "resources" then
        local values = source.resources or {}
        while clone.resourceIndex <= #values do
            result.resources[clone.resourceIndex] = copyShallowEntry(values[clone.resourceIndex])
            clone.resourceIndex = clone.resourceIndex + 1
            if shouldYield(deadlineMs) then return false end
        end
        clone.stage = "stats"
    end

    if clone.stage == "stats" then
        local values = source.stats or {}
        while clone.statIndex <= #values do
            result.stats[clone.statIndex] = copyShallowEntry(values[clone.statIndex])
            clone.statIndex = clone.statIndex + 1
            if shouldYield(deadlineMs) then return false end
        end
        clone.stage = "spells"
    end

    if clone.stage == "spells" then
        local values = source.spells or {}
        while clone.spellIndex <= #values do
            result.spells[clone.spellIndex] = values[clone.spellIndex]
            clone.spellIndex = clone.spellIndex + 1
            if shouldYield(deadlineMs) then return false end
        end
        clone.stage = "threat"
    end

    if clone.stage == "threat" then
        local sourceThreat = type(source.threatTable) == "table" and source.threatTable or {}
        local key, value = next(sourceThreat, clone.threatCursor)
        while key ~= nil do
            clone.threatCursor = key
            local eventId = normalizeEventId(key)
            if eventId > 0 then
                result.threatTable[eventId] = tonumber(value) or 0
            end
            if shouldYield(deadlineMs) then return false end
            key, value = next(sourceThreat, clone.threatCursor)
        end
        clone.stage = "finalize"
    end

    if clone.stage == "finalize" then
        result._networkStatMode = source._networkStatMode
        local mt = getmetatable(source)
        if mt ~= nil then setmetatable(result, mt) end
        clone.stage = "complete"
    end
    return true
end

local function ensureSnapshotState(state)
    local perf = state.performanceUnitSnapshot
    if type(perf) ~= "table" then
        perf = {
            sourceIndex = math.max(1, math.floor(tonumber(state.cursors and state.cursors.unit) or 1)),
            clone = nil,
            stage = "units",
            actorIndex = 1,
            memberIndex = 1,
        }
        state.performanceUnitSnapshot = perf
    end
    return perf
end

local function stepSnapshotUnits(state, deadlineMs)
    local perf = ensureSnapshotState(state)
    local sourceUnits = (state.sourceEventState and state.sourceEventState.units) or {}

    if perf.stage == "units" then
        while perf.sourceIndex <= #sourceUnits do
            if type(perf.clone) ~= "table" then
                perf.clone = createCloneState(sourceUnits[perf.sourceIndex])
            end
            if stepCloneState(perf.clone, deadlineMs) ~= true then
                return false
            end

            local frozenUnit = perf.clone.result
            state.snapshot.eventState.units[#state.snapshot.eventState.units + 1] = frozenUnit
            local eventId = normalizeEventId(frozenUnit.eventID)
            if eventId > 0 then
                state.snapshot.unitByEventId[eventId] = frozenUnit
            end
            perf.clone = nil
            perf.sourceIndex = perf.sourceIndex + 1
            if type(state.cursors) == "table" then
                state.cursors.unit = perf.sourceIndex
            end
            if shouldYield(deadlineMs) then return false end
        end
        perf.stage = "members"
    end

    if perf.stage == "members" then
        while perf.actorIndex <= #(state.snapshot.actors or {}) do
            local actor = state.snapshot.actors[perf.actorIndex]
            if perf.memberIndex <= #(actor.memberEventIds or {}) then
                local unit = state.snapshot.unitByEventId[normalizeEventId(actor.memberEventIds[perf.memberIndex])]
                if type(unit) == "table" and isUnitActive(unit) then
                    actor.members[#actor.members + 1] = unit
                    state.snapshot.actorMembers[#state.snapshot.actorMembers + 1] = {
                        actorKey = actor.key,
                        raidMarker = actor.raidMarker,
                        unit = unit,
                    }
                end
                perf.memberIndex = perf.memberIndex + 1
                if shouldYield(deadlineMs) then return false end
            else
                perf.actorIndex = perf.actorIndex + 1
                perf.memberIndex = 1
            end
        end
        perf.stage = "complete"
    end

    state.performanceUnitSnapshot = nil
    state.phase = "snapshot-positions"
    -- PlannerIntegration.phaseSnapshotPositions consumes cursors.unit. Reset
    -- that exact cursor; using a separate positionUnit cursor skips the entire
    -- frozen position pass and makes melee reach/movement planning impossible.
    state.cursors.unit = 1
    return true
end

local function ensureMetrics(state)
    state.metrics = type(state.metrics) == "table" and state.metrics or {}
    return state.metrics
end

local function recordSnapshotMetric(state, key, elapsed)
    local metrics = ensureMetrics(state)
    metrics[key] = math.max(tonumber(metrics[key]) or 0, math.max(0, tonumber(elapsed) or 0))
end

local function recordSlice(state, startedAt)
    local elapsed = math.max(0, nowMilliseconds() - startedAt)
    local metrics = ensureMetrics(state)
    metrics.sliceCount = (tonumber(metrics.sliceCount) or 0) + 1
    metrics.yieldCount = (tonumber(metrics.yieldCount) or 0) + 1
    metrics.maxSliceMs = math.max(tonumber(metrics.maxSliceMs) or 0, elapsed)
    metrics.snapshotMaxMs = math.max(tonumber(metrics.snapshotMaxMs) or 0, elapsed)
    recordSnapshotMetric(state, "snapshotUnitsMaxMs", elapsed)
end

local function preparationStageAtEntry(state, phase)
    local preparation = type(state.performancePreparation) == "table" and state.performancePreparation or nil
    if phase == "snapshot-auras" then
        local stage = preparation and preparation.stageA or nil
        if type(stage) ~= "table" or stage.complete ~= true then
            return "snapshotPrepareAMaxMs"
        end
    elseif phase == "snapshot-movement" then
        local stage = preparation and preparation.stageB or nil
        if type(stage) ~= "table" or stage.complete ~= true then
            return "snapshotPrepareBMaxMs"
        end
    end
    return nil
end

local SNAPSHOT_PHASE_METRIC = {
    validate = "snapshotValidateMaxMs",
    ["snapshot-positions"] = "snapshotPositionsMaxMs",
    ["snapshot-auras"] = "snapshotAurasMaxMs",
    ["snapshot-casts"] = "snapshotCastsMaxMs",
    ["snapshot-spells"] = "snapshotSpellsMaxMs",
    ["snapshot-movement"] = "snapshotMovementMaxMs",
}

local function logSnapshotBreakdown(state)
    if state._performanceSnapshotBreakdownLogged == true or type(Debug.Internal) ~= "function" then
        return
    end
    state._performanceSnapshotBreakdownLogged = true
    local m = state.metrics or {}
    Debug.Internal(
        "Autopilot snapshot phases event=%s turn=%d tick=%d validate=%.2fms units=%.2fms positions=%.2fms prepA=%.2fms auras=%.2fms casts=%.2fms spells=%.2fms prepB=%.2fms movement=%.2fms",
        tostring(state.eventId or ""),
        tonumber(state.turnNumber) or 0,
        tonumber(state.tickNumber) or 0,
        tonumber(m.snapshotValidateMaxMs) or 0,
        tonumber(m.snapshotUnitsMaxMs) or 0,
        tonumber(m.snapshotPositionsMaxMs) or 0,
        tonumber(m.snapshotPrepareAMaxMs) or 0,
        tonumber(m.snapshotAurasMaxMs) or 0,
        tonumber(m.snapshotCastsMaxMs) or 0,
        tonumber(m.snapshotSpellsMaxMs) or 0,
        tonumber(m.snapshotPrepareBMaxMs) or 0,
        tonumber(m.snapshotMovementMaxMs) or 0
    )
end

local function runPlannerStep(state, deadlineMs)
    local entryPhase = tostring(state.phase or "")
    if entryPhase == "snapshot-units" then
        local startedAt = nowMilliseconds()
        stepSnapshotUnits(state, deadlineMs)
        recordSlice(state, startedAt)
        -- Always hand back to TaskQueue after this bounded snapshot slice. If the
        -- phase completed, the next frame starts snapshot-positions cleanly.
        return false
    end

    local preparationMetric = preparationStageAtEntry(state, entryPhase)
    local startedAt = nowMilliseconds()
    local complete = basePlannerStep(state, deadlineMs)
    local elapsed = math.max(0, nowMilliseconds() - startedAt)

    local phaseMetric = preparationMetric or SNAPSHOT_PHASE_METRIC[entryPhase]
    if phaseMetric then
        recordSnapshotMetric(state, phaseMetric, elapsed)
    end

    if state.phase == "complete" then
        logSnapshotBreakdown(state)
    end
    return complete
end

function Planner.Step(state, deadlineMs)
    if type(state) ~= "table" then
        return true
    end

    local previousState = activePlannerState
    activePlannerState = state
    local results = { pcall(runPlannerStep, state, deadlineMs) }
    activePlannerState = previousState

    if results[1] ~= true then
        error(results[2], 0)
    end
    return unpackValues(results, 2, #results)
end

Planner._performanceSnapshotUnitsInstalled = true
return Planner