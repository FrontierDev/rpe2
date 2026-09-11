local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local SequencePlanning = Client.AutopilotSequencePlanning or {}
local MovementSolver = Client.AutopilotMovementSolver or {}
local Spatial = Client.AutopilotSpatial or {}
local Tasks = Addon.Internal.Tasks or {}
local unpackValues = unpack or table.unpack
local EPSILON = 0.0001

if type(MovementSolver) ~= "table" or MovementSolver._performanceBoundedEvaluationInstalled == true then
    return
end
local baseMovementStep = MovementSolver.Step
if type(baseMovementStep) ~= "function" then return end

local function shouldYield(deadlineMs)
    return type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true
end

local function normalizeNonNegative(value)
    return math.max(0, tonumber(value) or 0)
end

local function candidateTargets(candidate)
    if type(candidate) ~= "table" then return {} end
    if type(candidate.targetUnits) == "table" then return candidate.targetUnits end
    local target = candidate.targetUnit or candidate.primaryTargetUnit
    return type(target) == "table" and { target } or {}
end

local function candidateRequiresMelee(candidate)
    if type(candidate) ~= "table" then return false end
    if candidate.requiresMeleePosition == true then return true end
    return type(candidate.damageTypes) == "table"
        and candidate.damageTypes.melee == true
        and normalizeNonNegative(candidate.damageUtility or candidate.expectedDamage) > 0
end

local function isCandidateUseful(candidate)
    return type(candidate) == "table"
        and (candidate.urgentHealing == true
            or candidate.urgentInterrupt == true
            or normalizeNonNegative(candidate.totalUtility or candidate.utility) > 0)
end

local function getMemberUnit(member)
    return type(member) == "table" and (member.unit or member.eventUnit) or nil
end

local function getMemberCandidates(member)
    return type(member) == "table" and (member.actionCandidates or member.candidates) or {}
end

local function getCandidateTargetCount(candidate)
    local targets = candidateTargets(candidate)
    return #targets
end

local function getCandidateTargetAt(candidate, index)
    return candidateTargets(candidate)[index]
end

local function getCachedPosition(runtime, eventState, unit)
    if type(Spatial.GetCachedUnitPosition) ~= "function" then
        return nil
    end
    local position = Spatial.GetCachedUnitPosition(runtime, eventState, unit)
    return type(position) == "table" and position or nil
end

local function distanceBetween(left, right)
    if type(Spatial.DistanceBetweenPositions) ~= "function" then
        return nil
    end
    return tonumber(Spatial.DistanceBetweenPositions(left, right))
end

local function resetMovementCandidateEvaluation(state)
    state.evalTargetIndex = 1
    state.evalCandidateFeasible = true
    state.performanceReevaluationState = nil
end

local function beginAnchorEvaluation(state, anchor)
    state.currentAnchorEvaluation = {
        anchor = anchor,
        selectedSequences = {},
        tacticalLedger = SequencePlanning.CloneTacticalLedger(state.initialTacticalLedger),
        aggregateUtility = 0,
        usefulCoverage = 0,
        urgentHealingCount = 0,
        urgentInterruptCount = 0,
    }
    state.evalMemberIndex = 1
    state.evalCandidateIndex = 1
    state.evalCandidates = {}
    state.performanceMemberStage = nil
    resetMovementCandidateEvaluation(state)
end

local function compareAnchorEvaluations(left, right)
    if type(left) ~= "table" then
        return type(right) == "table" and -1 or 0
    end
    if type(right) ~= "table" then
        return 1
    end
    local leftUtility = tonumber(left.aggregateUtility) or 0
    local rightUtility = tonumber(right.aggregateUtility) or 0
    if math.abs(leftUtility - rightUtility) > EPSILON then
        return leftUtility > rightUtility and 1 or -1
    end
    if left.usefulCoverage ~= right.usefulCoverage then
        return left.usefulCoverage > right.usefulCoverage and 1 or -1
    end
    local leftCurrent = left.anchor and left.anchor.isCurrent == true
    local rightCurrent = right.anchor and right.anchor.isCurrent == true
    if leftCurrent ~= rightCurrent then
        return leftCurrent and 1 or -1
    end
    local leftScore = tonumber(left.adjustedUtility) or leftUtility
    local rightScore = tonumber(right.adjustedUtility) or rightUtility
    if math.abs(leftScore - rightScore) > EPSILON then
        return leftScore > rightScore and 1 or -1
    end
    local leftDistance = normalizeNonNegative(left.anchor and left.anchor.movementDistance)
    local rightDistance = normalizeNonNegative(right.anchor and right.anchor.movementDistance)
    if math.abs(leftDistance - rightDistance) > EPSILON then
        return leftDistance < rightDistance and 1 or -1
    end
    local leftX = tonumber(left.anchor and left.anchor.position and left.anchor.position.x) or 0
    local rightX = tonumber(right.anchor and right.anchor.position and right.anchor.position.x) or 0
    if math.abs(leftX - rightX) > EPSILON then
        return leftX < rightX and 1 or -1
    end
    local leftY = tonumber(left.anchor and left.anchor.position and left.anchor.position.y) or 0
    local rightY = tonumber(right.anchor and right.anchor.position and right.anchor.position.y) or 0
    if math.abs(leftY - rightY) > EPSILON then
        return leftY < rightY and 1 or -1
    end
    local leftKey = tostring(left.anchor and left.anchor.key or "")
    local rightKey = tostring(right.anchor and right.anchor.key or "")
    if leftKey ~= rightKey then
        return leftKey < rightKey and 1 or -1
    end
    return 0
end

local function finishAnchorEvaluation(state)
    local evaluation = state.currentAnchorEvaluation
    local movementDistance = normalizeNonNegative(evaluation.anchor and evaluation.anchor.movementDistance)
    evaluation.movementPenalty = movementDistance * (tonumber(MovementSolver.MOVEMENT_PENALTY_PER_YARD) or 0.001)
    evaluation.adjustedUtility = evaluation.aggregateUtility - evaluation.movementPenalty
    if type(state.bestAnchorEvaluation) ~= "table"
        or compareAnchorEvaluations(evaluation, state.bestAnchorEvaluation) > 0
    then
        state.bestAnchorEvaluation = evaluation
    end
    state.anchorEvalIndex = state.anchorEvalIndex + 1
    state.currentAnchorEvaluation = nil
end

local function stepMovementMemberFinish(state, deadlineMs)
    local evaluation = state.currentAnchorEvaluation
    local member = state.activeMembers[state.evalMemberIndex]
    local unit = getMemberUnit(member)
    local stage = state.performanceMemberStage or "build"

    if stage == "build" then
        state.performanceMemberSequence = SequencePlanning.BuildSequence(state.evalCandidates, unit)
        state.performanceMemberStage = "summarize"
        if shouldYield(deadlineMs) then return false end
        stage = "summarize"
    end
    if stage == "summarize" then
        state.performanceMemberSummary = SequencePlanning.SummarizeSequence(state.performanceMemberSequence)
        state.performanceMemberStage = "reserve"
        if shouldYield(deadlineMs) then return false end
        stage = "reserve"
    end
    if stage == "reserve" then
        local summary = state.performanceMemberSummary or { hasUsefulAction = false }
        evaluation.selectedSequences[state.evalMemberIndex] = state.performanceMemberSequence
        if summary.hasUsefulAction == true then
            evaluation.aggregateUtility = evaluation.aggregateUtility + normalizeNonNegative(summary.sequenceUtility)
            evaluation.usefulCoverage = evaluation.usefulCoverage + 1
            evaluation.urgentHealingCount = evaluation.urgentHealingCount + math.max(0, tonumber(summary.urgentHealingCount) or 0)
            evaluation.urgentInterruptCount = evaluation.urgentInterruptCount + math.max(0, tonumber(summary.urgentInterruptCount) or 0)
            evaluation.tacticalLedger = SequencePlanning.ReserveSequence(
                evaluation.tacticalLedger,
                state.performanceMemberSequence,
                state.tacticalContext
            )
        end
        state.performanceMemberStage = "advance"
        if shouldYield(deadlineMs) then return false end
    end

    state.evalMemberIndex = state.evalMemberIndex + 1
    state.evalCandidateIndex = 1
    state.evalCandidates = {}
    state.performanceMemberStage = nil
    state.performanceMemberSequence = nil
    state.performanceMemberSummary = nil
    resetMovementCandidateEvaluation(state)
    return true
end

local function stepMovementCandidateReevaluation(state, candidate, deadlineMs)
    if state.performanceReevaluationState == nil then
        state.performanceReevaluationState = select(1, SequencePlanning.CreateCandidateReevaluationState(
            candidate,
            state.currentAnchorEvaluation.tacticalLedger,
            state.tacticalContext
        )) or false
    end
    local reevaluation = state.performanceReevaluationState
    if type(reevaluation) == "table" then
        if SequencePlanning.StepCandidateReevaluation(reevaluation, deadlineMs) ~= true then
            return false
        end
        local result = SequencePlanning.CopyCandidateReevaluationResult(reevaluation)
        if isCandidateUseful(result) then
            state.evalCandidates[#state.evalCandidates + 1] = result
        end
    end
    state.evalCandidateIndex = state.evalCandidateIndex + 1
    resetMovementCandidateEvaluation(state)
    return true
end

local function stepEvaluateAnchorsBounded(state, deadlineMs)
    while state.anchorEvalIndex <= #(state.anchorCandidates or {}) do
        local anchor = state.anchorCandidates[state.anchorEvalIndex]
        if type(state.currentAnchorEvaluation) ~= "table" then
            beginAnchorEvaluation(state, anchor)
        end

        if state.evalMemberIndex > #(state.activeMembers or {}) then
            finishAnchorEvaluation(state)
        else
            local member = state.activeMembers[state.evalMemberIndex]
            local candidates = getMemberCandidates(member)
            if state.evalCandidateIndex > #candidates then
                if stepMovementMemberFinish(state, deadlineMs) ~= true then
                    return false
                end
            else
                local candidate = candidates[state.evalCandidateIndex]
                if not isCandidateUseful(candidate) then
                    state.evalCandidateIndex = state.evalCandidateIndex + 1
                    resetMovementCandidateEvaluation(state)
                elseif candidateRequiresMelee(candidate) then
                    local targetCount = getCandidateTargetCount(candidate)
                    if targetCount <= 0 then
                        state.evalCandidateFeasible = false
                    elseif state.evalTargetIndex <= targetCount then
                        local targetUnit = getCandidateTargetAt(candidate, state.evalTargetIndex)
                        local targetPosition = type(targetUnit) == "table"
                            and getCachedPosition(state.spatialRuntime, state.eventState, targetUnit)
                            or nil
                        local distance = targetPosition and distanceBetween(anchor.position, targetPosition) or nil
                        if distance == nil or distance > ((tonumber(MovementSolver.MELEE_RANGE_YARDS) or 5) + EPSILON) then
                            state.evalCandidateFeasible = false
                            state.evalTargetIndex = targetCount + 1
                        else
                            state.evalTargetIndex = state.evalTargetIndex + 1
                        end
                    end
                    if state.evalTargetIndex > targetCount then
                        if state.evalCandidateFeasible == true then
                            if stepMovementCandidateReevaluation(state, candidate, deadlineMs) ~= true then
                                return false
                            end
                        else
                            state.evalCandidateIndex = state.evalCandidateIndex + 1
                            resetMovementCandidateEvaluation(state)
                        end
                    end
                else
                    if stepMovementCandidateReevaluation(state, candidate, deadlineMs) ~= true then
                        return false
                    end
                end
            end
        end

        if shouldYield(deadlineMs) then
            return false
        end
    end
    state.phase = "finalize"
    return false
end

local function callBaseUntilInterceptPhase(baseFn, state, deadlineMs, interceptPhases)
    local originalShouldYield = Tasks.ShouldYield
    if type(originalShouldYield) ~= "function" then
        return baseFn(state, deadlineMs)
    end

    Tasks.ShouldYield = function(self, deadline)
        local phase = tostring(state.phase or "")
        if type(interceptPhases) == "table" and interceptPhases[phase] == true then
            return true
        end
        return originalShouldYield(self, deadline)
    end
    local results = { pcall(baseFn, state, deadlineMs) }
    Tasks.ShouldYield = originalShouldYield
    if results[1] ~= true then
        error(results[2], 0)
    end
    return unpackValues(results, 2, #results)
end

function MovementSolver.Step(state, deadlineMs)
    if type(state) ~= "table" then
        return true
    end
    if state.phase == "evaluate-anchors" then
        return stepEvaluateAnchorsBounded(state, deadlineMs)
    end
    return callBaseUntilInterceptPhase(baseMovementStep, state, deadlineMs, { ["evaluate-anchors"] = true })
end

MovementSolver._performanceBoundedEvaluationInstalled = true
return MovementSolver
