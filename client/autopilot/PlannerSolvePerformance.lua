local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Planner = Client.AutopilotPlanner or {}
local SequencePlanning = Client.AutopilotSequencePlanning or {}
local MovementSolver = Client.AutopilotMovementSolver or {}
local Spatial = Client.AutopilotSpatial or {}
local Tasks = Addon.Internal.Tasks or {}

if type(Planner) ~= "table" or Planner._performanceSolveInstalled == true then
    return
end

Planner.Performance = Planner.Performance or {}
local Performance = Planner.Performance

local function shouldYield(deadlineMs)
    return type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true
end

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
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

local function candidateRequiresMelee(candidate)
    if type(candidate) ~= "table" then
        return false
    end
    if candidate.requiresMeleePosition == true then
        return true
    end
    return type(candidate.damageTypes) == "table"
        and candidate.damageTypes.melee == true
        and math.max(0, tonumber(candidate.damageUtility or candidate.expectedDamage) or 0) > 0
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
            and select(1, Spatial.GetCachedUnitPosition(
                state.snapshot.spatialRuntime,
                state.snapshot.eventState,
                targets[index]
            ))
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
    if type(warning) == "table" then
        state.output.warnings[#state.output.warnings + 1] = warning
    end
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

local function copyTargetSelectionMap(targetUnits, targetGroupKey)
    local eventIds = {}
    for index = 1, #(targetUnits or {}) do
        eventIds[index] = normalizeEventId(targetUnits[index] and targetUnits[index].eventID)
    end
    local key = tostring(targetGroupKey or "")
    if key == "" then
        key = "default"
    end
    return { [key] = eventIds }, { key }, eventIds
end

local function buildSpellAction(state, actorKey, unit, candidate, movementActionId, sequenceIndex, sequenceCount, actionClass, previousActionId)
    local eventId = normalizeEventId(unit and unit.eventID)
    if eventId <= 0 or type(candidate) ~= "table" then
        return nil
    end
    local resolvedSequenceIndex = math.max(1, math.floor(tonumber(sequenceIndex) or 1))
    local resolvedSequenceCount = math.max(resolvedSequenceIndex, math.floor(tonumber(sequenceCount) or resolvedSequenceIndex))
    local selections, selectionOrder, targetEventIds = copyTargetSelectionMap(candidate.targetUnits, candidate.targetGroupKey)
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
                previousActionId
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

local function buildTacticalContext(state)
    return {
        eventState = state.snapshot.eventState,
        auraDefinitionCache = state.scratch.auraDefinitionCache,
        controlStateByTargetEventId = state.snapshot.controlStateByTargetEventId,
        activeCastsByEventId = state.snapshot.activeCastsByEventId,
    }
end

local function clonePlanTacticalLedger(state)
    return SequencePlanning.CloneTacticalLedger({
        projectedHealingLedger = state.scratch.projectedHealingLedger,
        projectedAuraLedger = state.scratch.projectedAuraLedger,
    })
end

local function commitPlanTacticalLedger(state, ledger)
    if type(ledger) ~= "table" then
        return false
    end
    local copied = SequencePlanning.CloneTacticalLedger(ledger)
    state.scratch.projectedHealingLedger = copied.projectedHealingLedger or { reservedByEventId = {} }
    state.scratch.projectedAuraLedger = copied.projectedAuraLedger
    return true
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
        reevaluationState = nil,
        memberStage = "candidates",
        memberSequence = nil,
        memberSummary = nil,
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

        if solveState.memberStage == "candidates" then
            if solveState.candidateIndex <= #candidates then
                local candidate = candidates[solveState.candidateIndex]
                local spatiallyFeasible = not candidateRequiresMelee(candidate)
                    or (solveState.allowMelee and isCandidateFeasibleAtPosition(state, candidate, solveState.position))
                if spatiallyFeasible then
                    if solveState.reevaluationState == nil then
                        solveState.reevaluationState = select(1, SequencePlanning.CreateCandidateReevaluationState(
                            candidate,
                            solveState.tacticalLedger,
                            context
                        )) or false
                    end
                    if type(solveState.reevaluationState) == "table" then
                        if SequencePlanning.StepCandidateReevaluation(solveState.reevaluationState, deadlineMs) ~= true then
                            return false
                        end
                        local reevaluated = SequencePlanning.CopyCandidateReevaluationResult(solveState.reevaluationState)
                        if type(reevaluated) == "table" then
                            solveState.reevaluatedCandidates[#solveState.reevaluatedCandidates + 1] = reevaluated
                        end
                    end
                end
                solveState.reevaluationState = nil
                solveState.candidateIndex = solveState.candidateIndex + 1
                if shouldYield(deadlineMs) then
                    return false
                end
            else
                solveState.memberStage = "build"
            end
        elseif solveState.memberStage == "build" then
            solveState.memberSequence = SequencePlanning.BuildSequence(solveState.reevaluatedCandidates, unit)
            solveState.sequences[solveState.memberIndex] = solveState.memberSequence
            solveState.memberStage = "summarize"
            if shouldYield(deadlineMs) then
                return false
            end
        elseif solveState.memberStage == "summarize" then
            solveState.memberSummary = SequencePlanning.SummarizeSequence(solveState.memberSequence)
            solveState.memberStage = "reserve"
            if shouldYield(deadlineMs) then
                return false
            end
        elseif solveState.memberStage == "reserve" then
            if solveState.memberSummary and solveState.memberSummary.hasUsefulAction == true then
                solveState.tacticalLedger = SequencePlanning.ReserveSequence(
                    solveState.tacticalLedger,
                    solveState.memberSequence,
                    context
                )
            end
            solveState.memberStage = "advance"
            if shouldYield(deadlineMs) then
                return false
            end
        else
            solveState.memberIndex = solveState.memberIndex + 1
            solveState.candidateIndex = 1
            solveState.reevaluatedCandidates = {}
            solveState.reevaluationState = nil
            solveState.memberSequence = nil
            solveState.memberSummary = nil
            solveState.memberStage = "candidates"
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

local function estimateMovementDiagnostics(solveState)
    local targetCount = #(solveState.anchorTargets or {})
    local potential = 1 + targetCount
    if targetCount > 1 then
        potential = potential + 1 + ((targetCount * (targetCount - 1)) / 2)
    end
    local accepted = #(solveState.anchorCandidates or {})
    return accepted, math.max(0, math.floor(potential - accepted))
end

local function copyMovement(movement)
    if type(movement) ~= "table" then
        return nil
    end
    local copied = copyMap(movement)
    copied.objectiveTargetEventIds = copyArray(movement.objectiveTargetEventIds)
    copied.proposedPosition = copyPosition(movement.proposedPosition)
    if type(movement.movementByMemberEventId) == "table" then
        copied.movementByMemberEventId = movement.movementByMemberEventId
    end
    copied.limitingMemberEventIds = copyArray(movement.limitingMemberEventIds)
    copied.plannedLimitingMemberEventIds = copyArray(movement.plannedLimitingMemberEventIds)
    return copied
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
    state.metrics.candidateAnchorCount = (tonumber(state.metrics.candidateAnchorCount) or 0) + acceptedAnchors
    state.metrics.rejectedUnreachableAnchors = (tonumber(state.metrics.rejectedUnreachableAnchors) or 0) + rejectedAnchors
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

function Performance.StepSolveActors(state, deadlineMs)
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
                    if MovementSolver.Step(solveState, deadlineMs) ~= true then
                        return false
                    end
                    finalizeMarkedActor(state, actor, solveState)
                    state.cursors.actor = state.cursors.actor + 1
                end
            end
        else
            local unit = actor.members[1]
            if type(unit) == "table" then
                local spatialActorKey = type(Spatial.GetNpcActorKey) == "function"
                    and Spatial.GetNpcActorKey(unit)
                    or actor.key
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
    return false
end

Planner._performanceSolveInstalled = true
return Performance
