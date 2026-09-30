local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Planner = Client.AutopilotPlanner or {}
local MovementSolver = Client.AutopilotMovementSolver or {}

local EPSILON = 0.0001

local function copyOptions(options)
    local copied = {}
    for key, value in pairs(type(options) == "table" and options or {}) do
        copied[key] = value
    end
    return copied
end

local function copyArray(values)
    local copied = {}
    for index = 1, #(values or {}) do
        copied[index] = values[index]
    end
    return copied
end

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end

local function copyMovementDetailsByMember(source)
    local copied = {}
    for eventId, details in pairs(type(source) == "table" and source or {}) do
        if type(details) == "table" then
            local reason = tostring(details.reason or "")
            local statRef = tostring(details.statRef or "")
            local baseStatFound = details.baseStatFound
            if baseStatFound == nil then
                baseStatFound = statRef ~= "" and reason ~= "movement-range-stat-missing"
            end
            local usedMissingStatFallback = details.usedMissingStatFallback == true
                or (baseStatFound ~= true and details.movementRangeOverride == nil)
            copied[eventId] = {
                available = details.available ~= false,
                reason = details.reason,
                statRef = details.statRef,
                baseStatFound = baseStatFound == true,
                baseValue = details.baseValue,
                movementRangeOverride = details.movementRangeOverride,
                usedMissingStatFallback = usedMissingStatFallback,
                missingStatFallbackValue = details.missingStatFallbackValue or (usedMissingStatFallback and 30 or nil),
                effectiveValue = details.effectiveValue,
            }
        end
    end
    return copied
end

local function getMemberNameByEventId(state, eventId)
    local wanted = normalizeEventId(eventId)
    for index = 1, #(type(state) == "table" and state.members or {}) do
        local member = state.members[index]
        local unit = type(member) == "table" and (member.unit or member.eventUnit) or nil
        if normalizeEventId(unit and unit.eventID) == wanted then
            local name = tostring(unit and unit.name or "")
            return name ~= "" and name or ("NPC " .. tostring(wanted))
        end
    end
    return wanted > 0 and ("NPC " .. tostring(wanted)) or "Unknown NPC"
end

local function findLimitingMemberEventIds(movementByMemberEventId, movementAllowance)
    local minimum = math.max(0, tonumber(movementAllowance) or 0)
    local ids = {}
    for eventId, details in pairs(type(movementByMemberEventId) == "table" and movementByMemberEventId or {}) do
        local normalizedId = normalizeEventId(eventId)
        local effectiveValue = type(details) == "table" and tonumber(details.effectiveValue) or nil
        if normalizedId > 0 and effectiveValue ~= nil and math.abs(math.max(0, effectiveValue) - minimum) <= EPSILON then
            ids[#ids + 1] = normalizedId
        end
    end
    table.sort(ids)
    return ids
end

local function appendDiagnosticWarning(result, reason, memberEventIds, text)
    if type(result) ~= "table" or #(memberEventIds or {}) == 0 then
        return
    end
    result.warnings = type(result.warnings) == "table" and result.warnings or {}
    result.warnings[#result.warnings + 1] = {
        warningType = tostring(reason or "movement-diagnostic"),
        reason = tostring(reason or "movement-diagnostic"),
        actorKey = tostring(result.actorKey or ""),
        raidMarker = math.max(0, math.floor(tonumber(result.raidMarker) or 0)),
        memberEventIds = copyArray(memberEventIds),
        text = tostring(text or "Movement configuration warning."),
    }
end

local function appendMovementConfigurationWarnings(result, state)
    local unconfiguredIds = {}
    local unconfiguredNames = {}
    local missingIds = {}
    local missingNames = {}
    local missingStatRef = ""

    for eventId, details in pairs(type(result.movementByMemberEventId) == "table" and result.movementByMemberEventId or {}) do
        local normalizedId = normalizeEventId(eventId)
        local reason = type(details) == "table" and tostring(details.reason or "") or ""
        if normalizedId > 0 and reason == "movement-range-unconfigured" then
            unconfiguredIds[#unconfiguredIds + 1] = normalizedId
            unconfiguredNames[#unconfiguredNames + 1] = getMemberNameByEventId(state, normalizedId)
        elseif normalizedId > 0 and reason == "movement-range-stat-missing" then
            missingIds[#missingIds + 1] = normalizedId
            missingNames[#missingNames + 1] = getMemberNameByEventId(state, normalizedId)
            if missingStatRef == "" then
                missingStatRef = tostring(details.statRef or "")
            end
        end
    end

    table.sort(unconfiguredIds)
    table.sort(unconfiguredNames)
    table.sort(missingIds)
    table.sort(missingNames)

    if #unconfiguredIds > 0 then
        appendDiagnosticWarning(
            result,
            "movement-range-unconfigured",
            unconfiguredIds,
            ("Marker %d has no Movement Range Stat configured; affected NPCs: %s."):format(
                math.max(0, math.floor(tonumber(result.raidMarker) or 0)),
                table.concat(unconfiguredNames, ", ")
            )
        )
    end

    if #missingIds > 0 then
        local statText = missingStatRef ~= "" and (" " .. missingStatRef) or ""
        appendDiagnosticWarning(
            result,
            "movement-range-stat-missing",
            missingIds,
            ("Marker %d NPCs are missing the configured Movement Range Stat%s: %s."):format(
                math.max(0, math.floor(tonumber(result.raidMarker) or 0)),
                statText,
                table.concat(missingNames, ", ")
            )
        )
    end
end

local baseCopyMovementSolveResult = MovementSolver.CopyResult
if type(baseCopyMovementSolveResult) == "function" then
    function MovementSolver.CopyResult(state)
        local result = baseCopyMovementSolveResult(state)
        if type(result) ~= "table" then
            return result
        end

        result.movementByMemberEventId = copyMovementDetailsByMember(result.movementByMemberEventId)
        local limitingMemberEventIds = findLimitingMemberEventIds(
            result.movementByMemberEventId,
            result.movementAllowance
        )

        if type(result.movement) == "table" then
            result.movement.plannedMovementAllowance = math.max(
                0,
                tonumber(result.movement.movementAllowance) or tonumber(result.movementAllowance) or 0
            )
            result.movement.plannedMovementDistance = math.max(
                0,
                tonumber(result.movement.movementDistance) or 0
            )
            result.movement.movementByMemberEventId = copyMovementDetailsByMember(result.movementByMemberEventId)
            result.movement.limitingMemberEventIds = copyArray(limitingMemberEventIds)
            result.movement.plannedLimitingMemberEventIds = copyArray(limitingMemberEventIds)
        end

        appendMovementConfigurationWarnings(result, state)
        return result
    end
end

local function ensureMovementSolveScratch(state)
    if type(state) ~= "table" then
        return nil
    end
    state.scratch = type(state.scratch) == "table" and state.scratch or {}
    state.scratch.movementSolveByKey = type(state.scratch.movementSolveByKey) == "table"
        and state.scratch.movementSolveByKey
        or {}
    return state.scratch
end

function Planner.CreateMovementSolveState(state, solveKey, options)
    if type(MovementSolver.CreateState) ~= "function" then
        return nil, "movement-solver-unavailable"
    end

    local key = tostring(solveKey or "")
    if key == "" then
        return nil, "movement-solve-key-unavailable"
    end

    local scratch = ensureMovementSolveScratch(state)
    if type(scratch) ~= "table" then
        return nil, "planner-state-unavailable"
    end

    local resolvedOptions = copyOptions(options)
    if resolvedOptions.spatialRuntime == nil then
        resolvedOptions.spatialRuntime = state.runtimeRef
    end

    local solveState, reason = MovementSolver.CreateState(resolvedOptions)
    if type(solveState) ~= "table" then
        return nil, reason or "movement-solve-unavailable"
    end

    scratch.movementSolveByKey[key] = solveState
    return solveState
end

function Planner.StepMovementSolve(state, solveKey, deadlineMs)
    if type(MovementSolver.Step) ~= "function" then
        return false, nil, "movement-solver-unavailable"
    end

    local key = tostring(solveKey or "")
    local scratch = ensureMovementSolveScratch(state)
    local solveState = type(scratch) == "table" and scratch.movementSolveByKey[key] or nil
    if type(solveState) ~= "table" then
        return false, nil, "movement-solve-unavailable"
    end

    local complete = MovementSolver.Step(solveState, deadlineMs) == true
    if not complete then
        return false, nil
    end

    local result = type(MovementSolver.CopyResult) == "function"
        and MovementSolver.CopyResult(solveState)
        or nil
    return true, result
end

function Planner.GetMovementSolveResult(state, solveKey)
    local key = tostring(solveKey or "")
    local scratch = type(state) == "table" and state.scratch or nil
    local solveState = type(scratch) == "table"
        and type(scratch.movementSolveByKey) == "table"
        and scratch.movementSolveByKey[key]
        or nil
    if type(solveState) ~= "table" or type(MovementSolver.CopyResult) ~= "function" then
        return nil
    end
    return MovementSolver.CopyResult(solveState)
end

return Planner
