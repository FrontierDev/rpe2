local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Planner = Client.AutopilotPlanner or {}
local Tasks = Addon.Internal.Tasks or {}
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil

if type(Planner) ~= "table" or Planner._performanceSnapshotUnitsInstalled == true then
    return
end

local basePlannerStep = Planner.Step
if type(basePlannerStep) ~= "function" then
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
    state.cursors.positionUnit = 1
    return true
end

local function recordSlice(state, startedAt)
    local elapsed = math.max(0, nowMilliseconds() - startedAt)
    state.metrics = type(state.metrics) == "table" and state.metrics or {}
    local metrics = state.metrics
    metrics.sliceCount = (tonumber(metrics.sliceCount) or 0) + 1
    metrics.yieldCount = (tonumber(metrics.yieldCount) or 0) + 1
    metrics.maxSliceMs = math.max(tonumber(metrics.maxSliceMs) or 0, elapsed)
    metrics.snapshotMaxMs = math.max(tonumber(metrics.snapshotMaxMs) or 0, elapsed)
end

function Planner.Step(state, deadlineMs)
    if type(state) ~= "table" then
        return true
    end
    if tostring(state.phase or "") ~= "snapshot-units" then
        return basePlannerStep(state, deadlineMs)
    end

    local startedAt = nowMilliseconds()
    stepSnapshotUnits(state, deadlineMs)
    recordSlice(state, startedAt)
    -- Always hand back to TaskQueue after this bounded snapshot slice. If the
    -- phase completed, the next frame starts snapshot-positions cleanly.
    return false
end

Planner._performanceSnapshotUnitsInstalled = true
return Planner
