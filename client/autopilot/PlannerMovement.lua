local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Planner = Client.AutopilotPlanner or {}
local MovementSolver = Client.AutopilotMovementSolver or {}

local function copyOptions(options)
    local copied = {}
    for key, value in pairs(type(options) == "table" and options or {}) do
        copied[key] = value
    end
    return copied
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
