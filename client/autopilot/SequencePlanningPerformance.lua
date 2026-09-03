local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local SpellEvaluator = Client.AutopilotSpellEvaluator or {}
local SequencePlanning = Client.AutopilotSequencePlanning or {}
local Tasks = Addon.Internal.Tasks or {}

if type(SequencePlanning) ~= "table" or SequencePlanning._performanceReevaluationInstalled == true then
    return
end

local function shouldYield(deadlineMs)
    return type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true
end

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end

local function normalizeNonNegative(value)
    return math.max(0, tonumber(value) or 0)
end

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

local function candidateTargets(candidate)
    if type(candidate) ~= "table" then return {} end
    if type(candidate.targetUnits) == "table" then return candidate.targetUnits end
    local target = candidate.targetUnit or candidate.primaryTargetUnit
    return type(target) == "table" and { target } or {}
end

local function cloneCandidate(candidate)
    if type(candidate) ~= "table" then
        return nil
    end
    local copied = copyMap(candidate)
    copied.targetUnits = copyArray(candidate.targetUnits)
    copied.targetEventIds = copyArray(candidate.targetEventIds)
    copied.damageTypeList = copyArray(candidate.damageTypeList)
    return copied
end

function SequencePlanning.CreateCandidateReevaluationState(candidate, tacticalLedger, context)
    if type(candidate) ~= "table" then
        return nil, "candidate-unavailable"
    end
    local targets = candidateTargets(candidate)
    if #targets == 0 then
        return {
            candidate = candidate,
            complete = true,
            result = cloneCandidate(candidate),
        }
    end
    if type(SpellEvaluator.EvaluateCandidate) ~= "function"
        or type(candidate.activationSnapshot) ~= "table"
        or type(candidate.planningProfile) ~= "table"
    then
        return nil, "candidate-evaluator-unavailable"
    end

    return {
        candidate = candidate,
        tacticalLedger = type(tacticalLedger) == "table" and tacticalLedger or {},
        context = type(context) == "table" and context or {},
        targets = targets,
        targetIndex = 1,
        damageUtility = 0,
        healingUtility = 0,
        movementControlUtility = 0,
        castingPreventionUtility = 0,
        controlUtility = 0,
        immediateDamage = 0,
        immediateHealing = 0,
        periodicDamage = 0,
        periodicHealing = 0,
        expectedDamage = 0,
        expectedHealing = 0,
        projectedHealingByTargetEventId = {},
        urgentHealing = false,
        hasUsefulInterrupt = false,
        urgentInterrupt = false,
        interruptTargetEventId = 0,
        interruptRemainingTurns = nil,
        evaluateInterrupt = tostring(candidate.planningIntent or "") == "interrupt",
        complete = false,
        result = nil,
    }
end

local function accumulateReevaluationTarget(state, target, evaluated)
    if type(evaluated) ~= "table" then
        return
    end
    state.damageUtility = state.damageUtility + (tonumber(evaluated.damageUtility) or 0)
    state.healingUtility = state.healingUtility + (tonumber(evaluated.healingUtility) or 0)
    state.movementControlUtility = state.movementControlUtility + (tonumber(evaluated.movementControlUtility) or 0)
    state.castingPreventionUtility = state.castingPreventionUtility + (tonumber(evaluated.castingPreventionUtility) or 0)
    state.controlUtility = state.controlUtility + (tonumber(evaluated.controlUtility) or 0)
    state.immediateDamage = state.immediateDamage + (tonumber(evaluated.immediateDamage) or 0)
    state.immediateHealing = state.immediateHealing + (tonumber(evaluated.immediateHealing) or 0)
    state.periodicDamage = state.periodicDamage + (tonumber(evaluated.usefulPeriodicDamage) or 0)
    state.periodicHealing = state.periodicHealing + (tonumber(evaluated.usefulPeriodicHealing) or 0)
    state.expectedDamage = state.expectedDamage + (tonumber(evaluated.expectedDamage) or 0)
    state.expectedHealing = state.expectedHealing + (tonumber(evaluated.expectedHealing) or 0)
    local targetEventId = normalizeEventId(target and target.eventID)
    if targetEventId > 0 then
        state.projectedHealingByTargetEventId[targetEventId] = normalizeNonNegative(evaluated.healingUtility)
    end
    state.urgentHealing = state.urgentHealing or evaluated.urgentHealing == true
    if state.evaluateInterrupt and evaluated.hasUsefulInterrupt == true and state.hasUsefulInterrupt ~= true then
        state.hasUsefulInterrupt = true
        state.interruptTargetEventId = normalizeEventId(evaluated.interruptTargetEventId)
        state.interruptRemainingTurns = evaluated.interruptRemainingTurns
    end
    state.urgentInterrupt = state.urgentInterrupt or (state.evaluateInterrupt and evaluated.urgentInterrupt == true)
end

local function finalizeReevaluation(state)
    local totalUtility = state.damageUtility + state.healingUtility + state.controlUtility
    if totalUtility <= 0 and state.urgentHealing ~= true and state.urgentInterrupt ~= true then
        state.result = nil
        state.complete = true
        return
    end
    local result = cloneCandidate(state.candidate)
    result.damageUtility = state.damageUtility
    result.healingUtility = state.healingUtility
    result.movementControlUtility = state.movementControlUtility
    result.castingPreventionUtility = state.castingPreventionUtility
    result.controlUtility = state.controlUtility
    result.totalUtility = totalUtility
    result.immediateDamage = state.immediateDamage
    result.immediateHealing = state.immediateHealing
    result.periodicDamage = state.periodicDamage
    result.periodicHealing = state.periodicHealing
    result.expectedDamage = state.expectedDamage
    result.expectedHealing = state.expectedHealing
    result.projectedHealingByTargetEventId = state.projectedHealingByTargetEventId
    result.urgentHealing = state.urgentHealing
    result.hasUsefulInterrupt = state.hasUsefulInterrupt
    result.urgentInterrupt = state.urgentInterrupt
    result.interruptTargetEventId = state.interruptTargetEventId
    result.interruptRemainingTurns = state.interruptRemainingTurns
    state.result = result
    state.complete = true
end

function SequencePlanning.StepCandidateReevaluation(state, deadlineMs)
    if type(state) ~= "table" then
        return true
    end
    if state.complete == true then
        return true
    end
    if shouldYield(deadlineMs) then
        return false
    end

    local candidate = state.candidate
    local ledger = state.tacticalLedger or {}
    local context = state.context or {}
    while state.targetIndex <= #(state.targets or {}) do
        local target = state.targets[state.targetIndex]
        local evaluated = SpellEvaluator.EvaluateCandidate(candidate.activationSnapshot, target, {
            projectedHealingLedger = ledger.projectedHealingLedger,
            projectedAuraLedger = ledger.projectedAuraLedger,
            auraDefinitionCache = context.auraDefinitionCache,
            controlStateByTargetEventId = context.controlStateByTargetEventId,
            activeCastsByEventId = context.activeCastsByEventId,
            isHostileTarget = candidate.isHostileTarget == true,
            profile = candidate.planningProfile,
        })
        accumulateReevaluationTarget(state, target, evaluated)
        state.targetIndex = state.targetIndex + 1
        if shouldYield(deadlineMs) then
            return false
        end
    end

    finalizeReevaluation(state)
    return true
end

function SequencePlanning.CopyCandidateReevaluationResult(state)
    return type(state) == "table" and state.complete == true and state.result or nil
end

function SequencePlanning.ReevaluateCandidate(candidate, tacticalLedger, context)
    local state = SequencePlanning.CreateCandidateReevaluationState(candidate, tacticalLedger, context)
    if type(state) ~= "table" then
        return nil
    end
    while SequencePlanning.StepCandidateReevaluation(state, nil) ~= true do
        -- nil deadline is intentionally synchronous for non-planner callers.
    end
    return state.result
end

SequencePlanning._performanceReevaluationInstalled = true
return SequencePlanning
