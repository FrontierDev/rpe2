local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Tasks = Addon.Internal.Tasks or {}
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local Spatial = Client.AutopilotSpatial or {}
local SpellEvaluator = Client.AutopilotSpellEvaluator or {}
local Movement = RPE and RPE.Core and RPE.Core.Movement or nil

Client.AutopilotMovementSolver = Client.AutopilotMovementSolver or {}
local Solver = Client.AutopilotMovementSolver

Solver.MELEE_RANGE_YARDS = 5
Solver.MAX_ANCHOR_TARGETS = 12
Solver.MOVEMENT_PENALTY_PER_YARD = 0.001

local EPSILON = 0.0001

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end

local function normalizeRaidMarker(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function normalizeNonNegative(value)
    return math.max(0, tonumber(value) or 0)
end

local function shouldYield(deadlineMs)
    return type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true
end

local function isUnitActive(unit)
    if type(Event) == "table" and type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end
    return type(unit) == "table" and (unit.isPlayer == true or unit.active ~= false)
end

local function getMemberUnit(member)
    if type(member) ~= "table" then
        return nil
    end
    return member.unit or member.eventUnit
end

local function getMemberCandidates(member)
    if type(member) ~= "table" then
        return {}
    end
    return type(member.actionCandidates) == "table" and member.actionCandidates
        or type(member.candidates) == "table" and member.candidates
        or {}
end

local function getCandidateUtility(candidate)
    return normalizeNonNegative(type(candidate) == "table" and (candidate.totalUtility or candidate.utility) or 0)
end

local function isCandidateUseful(candidate)
    return type(candidate) == "table"
        and (candidate.urgentHealing == true or candidate.urgentInterrupt == true or getCandidateUtility(candidate) > 0)
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
        and normalizeNonNegative(candidate.damageUtility or candidate.expectedDamage) > 0
end

local function getCandidateTargetCount(candidate)
    if type(candidate) ~= "table" then
        return 0
    end
    if type(candidate.targetUnits) == "table" and #candidate.targetUnits > 0 then
        return #candidate.targetUnits
    end
    if type(candidate.targetUnit) == "table" or type(candidate.primaryTargetUnit) == "table" then
        return 1
    end
    return 0
end

local function getCandidateTargetAt(candidate, index)
    if type(candidate) ~= "table" then
        return nil
    end
    if type(candidate.targetUnits) == "table" and #candidate.targetUnits > 0 then
        return candidate.targetUnits[index]
    end
    if index == 1 then
        return candidate.targetUnit or candidate.primaryTargetUnit
    end
    return nil
end

local function compareCandidates(left, right)
    if type(left) ~= "table" then
        return type(right) == "table" and -1 or 0
    end
    if type(right) ~= "table" then
        return 1
    end

    if type(SpellEvaluator.CompareCandidates) == "function" then
        local compared = tonumber(SpellEvaluator.CompareCandidates(left, right))
        if compared and compared ~= 0 then
            return compared > 0 and 1 or -1
        end
    end

    local leftUtility = getCandidateUtility(left)
    local rightUtility = getCandidateUtility(right)
    if leftUtility ~= rightUtility then
        return leftUtility > rightUtility and 1 or -1
    end

    local leftRef = tostring(left.spellRef or "")
    local rightRef = tostring(right.spellRef or "")
    if leftRef ~= rightRef then
        return leftRef < rightRef and 1 or -1
    end

    local leftTarget = normalizeEventId(left.targetEventId)
    local rightTarget = normalizeEventId(right.targetEventId)
    if leftTarget ~= rightTarget then
        return leftTarget < rightTarget and 1 or -1
    end
    return 0
end

local function copyPosition(position)
    if type(Spatial.CopyPosition) == "function" then
        return Spatial.CopyPosition(position)
    end
    if type(position) ~= "table" then
        return nil
    end
    return {
        x = tonumber(position.x),
        y = tonumber(position.y),
        instanceID = position.instanceID,
        available = position.available ~= false,
    }
end

local function distanceBetween(left, right)
    if type(Spatial.DistanceBetweenPositions) ~= "function" then
        return nil
    end
    return tonumber(Spatial.DistanceBetweenPositions(left, right))
end

local function getCachedPosition(runtime, eventState, unit)
    if type(Spatial.GetCachedUnitPosition) ~= "function" then
        return nil
    end
    local position = Spatial.GetCachedUnitPosition(runtime, eventState, unit)
    return type(position) == "table" and position or nil
end

local function makeCoordinateKey(position)
    if type(position) ~= "table" then
        return nil
    end
    local x = tonumber(position.x)
    local y = tonumber(position.y)
    if x == nil or y == nil or position.instanceID == nil then
        return nil
    end
    return ("%s@%.4f,%.4f"):format(tostring(position.instanceID), x, y)
end

local function parseMarkerFromActorKey(actorKey)
    local marker = tostring(actorKey or ""):match("^marker:(%d+)$")
    return normalizeRaidMarker(marker)
end

local function compareAnchorTarget(left, right)
    local leftUtility = normalizeNonNegative(left and left.relevanceUtility)
    local rightUtility = normalizeNonNegative(right and right.relevanceUtility)
    if leftUtility ~= rightUtility then
        return leftUtility > rightUtility and 1 or -1
    end

    local leftEventId = normalizeEventId(left and left.eventId)
    local rightEventId = normalizeEventId(right and right.eventId)
    if leftEventId ~= rightEventId then
        return leftEventId < rightEventId and 1 or -1
    end
    return 0
end

local function sortAnchorTargets(state)
    table.sort(state.anchorTargets, function(left, right)
        return compareAnchorTarget(left, right) > 0
    end)
end

local function insertBoundedAnchorTarget(state, unit, position, relevanceUtility)
    local eventId = normalizeEventId(unit and unit.eventID)
    if eventId <= 0 or type(position) ~= "table" then
        return false
    end

    local existing = state.anchorTargetByEventId[eventId]
    if type(existing) == "table" then
        existing.relevanceUtility = math.max(
            normalizeNonNegative(existing.relevanceUtility),
            normalizeNonNegative(relevanceUtility)
        )
        sortAnchorTargets(state)
        return true
    end

    local entry = {
        eventId = eventId,
        unit = unit,
        position = copyPosition(position),
        relevanceUtility = normalizeNonNegative(relevanceUtility),
    }
    state.anchorTargets[#state.anchorTargets + 1] = entry
    state.anchorTargetByEventId[eventId] = entry
    sortAnchorTargets(state)

    if #state.anchorTargets > Solver.MAX_ANCHOR_TARGETS then
        local removed = table.remove(state.anchorTargets)
        if removed then
            state.anchorTargetByEventId[removed.eventId] = nil
        end
    end
    return true
end

local function isAnchorReachable(state, position)
    if type(position) ~= "table" then
        return false, nil
    end
    local distance = distanceBetween(state.currentPosition, position)
    if distance == nil then
        return false, nil
    end
    return distance <= (normalizeNonNegative(state.cohortMovementAllowance) + EPSILON), distance
end

local function addAnchor(state, key, position)
    local coordinateKey = makeCoordinateKey(position)
    if not coordinateKey or state.anchorByCoordinateKey[coordinateKey] then
        return false
    end

    local reachable, distance = isAnchorReachable(state, position)
    if not reachable then
        return false
    end

    local anchor = {
        key = tostring(key or coordinateKey),
        position = copyPosition(position),
        movementDistance = normalizeNonNegative(distance),
        isCurrent = distance <= EPSILON,
    }
    state.anchorCandidates[#state.anchorCandidates + 1] = anchor
    state.anchorByCoordinateKey[coordinateKey] = anchor
    return true
end

local function failState(state, reason)
    state.result = {
        status = "failed",
        reason = tostring(reason or "movement-solve-failed"),
        actorKey = state.actorKey,
        raidMarker = state.raidMarker,
        movement = nil,
        actions = {},
        warnings = {},
    }
    state.phase = "complete"
    return true
end

function Solver.CreateState(options)
    options = type(options) == "table" and options or {}
    local eventState = options.eventState
    local runtime = options.spatialRuntime
    local actorKey = tostring(options.actorKey or "")
    local raidMarker = normalizeRaidMarker(options.raidMarker)
    if raidMarker <= 0 then
        raidMarker = parseMarkerFromActorKey(actorKey)
    end
    if actorKey == "" and raidMarker > 0 then
        actorKey = "marker:" .. tostring(raidMarker)
    end

    if type(eventState) ~= "table" or type(runtime) ~= "table" then
        return nil, "spatial-context-unavailable"
    end
    if raidMarker <= 0 or actorKey ~= ("marker:" .. tostring(raidMarker)) then
        return nil, "marked-cohort-required"
    end
    if type(options.members) ~= "table" then
        return nil, "cohort-members-unavailable"
    end

    local currentPosition = type(runtime.positionByActorKey) == "table"
        and runtime.positionByActorKey[actorKey]
        or nil
    if type(currentPosition) ~= "table"
        or type(Spatial.IsPositionAvailable) ~= "function"
        or Spatial.IsPositionAvailable(currentPosition) ~= true
        or currentPosition.instanceID == nil
    then
        return nil, "marker-position-unavailable"
    end

    local state = {
        eventState = eventState,
        spatialRuntime = runtime,
        actorKey = actorKey,
        raidMarker = raidMarker,
        members = options.members,
        currentPosition = copyPosition(currentPosition),
        activeMembers = {},
        movementByMemberEventId = {},
        pinnedMembers = {},
        cohortMovementAllowance = nil,
        phase = "resolve-movement",
        memberIndex = 1,
        collectMemberIndex = 1,
        collectCandidateIndex = 1,
        collectTargetIndex = 1,
        anchorTargets = {},
        anchorTargetByEventId = {},
        anchorCandidates = {},
        anchorByCoordinateKey = {},
        targetAnchorIndex = 1,
        centroidIndex = 1,
        centroidSumX = 0,
        centroidSumY = 0,
        centroidCount = 0,
        pairLeftIndex = 1,
        pairRightIndex = 2,
        anchorEvalIndex = 1,
        evalMemberIndex = 1,
        evalCandidateIndex = 1,
        evalTargetIndex = 1,
        evalCandidateFeasible = true,
        evalBestCandidate = nil,
        currentAnchorEvaluation = nil,
        bestAnchorEvaluation = nil,
        result = nil,
    }

    addAnchor(state, "current", state.currentPosition)
    return state
end

local function resolveMovementAllowance(state, member, unit)
    if type(Movement) ~= "table" or type(Movement.ResolveEventUnitMovementAllowance) ~= "function" then
        return nil, nil, "movement-allowance-api-unavailable"
    end

    local allowance, details = Movement:ResolveEventUnitMovementAllowance(state.eventState, unit)
    allowance = tonumber(allowance)
    if allowance == nil then
        return nil, details, "movement-allowance-unavailable"
    end
    allowance = math.max(0, allowance)

    local eventId = normalizeEventId(unit.eventID)
    state.movementByMemberEventId[eventId] = details or { effectiveValue = allowance }
    if allowance <= 0 then
        state.pinnedMembers[#state.pinnedMembers + 1] = {
            eventId = eventId,
            name = tostring(unit.name or ("NPC " .. tostring(eventId))),
            details = details,
        }
    end

    if state.cohortMovementAllowance == nil or allowance < state.cohortMovementAllowance then
        state.cohortMovementAllowance = allowance
    end
    return allowance, details
end

local function stepResolveMovement(state, deadlineMs)
    while state.memberIndex <= #(state.members or {}) do
        local member = state.members[state.memberIndex]
        local unit = getMemberUnit(member)
        if type(unit) == "table" and isUnitActive(unit) then
            if unit.isPlayer == true or normalizeRaidMarker(unit.raidMarker) ~= state.raidMarker then
                return failState(state, "cohort-member-mismatch")
            end

            local allowance, _, reason = resolveMovementAllowance(state, member, unit)
            if allowance == nil then
                return failState(state, reason)
            end
            state.activeMembers[#state.activeMembers + 1] = member
        end

        state.memberIndex = state.memberIndex + 1
        if shouldYield(deadlineMs) then
            return false
        end
    end

    if #state.activeMembers == 0 then
        return failState(state, "cohort-empty")
    end
    state.cohortMovementAllowance = normalizeNonNegative(state.cohortMovementAllowance)
    state.phase = state.cohortMovementAllowance <= 0 and "evaluate-anchors" or "collect-melee-targets"
    return false
end

local function advanceCollectCursor(state, candidate)
    local targetCount = getCandidateTargetCount(candidate)
    state.collectTargetIndex = state.collectTargetIndex + 1
    if state.collectTargetIndex > targetCount then
        state.collectTargetIndex = 1
        state.collectCandidateIndex = state.collectCandidateIndex + 1
    end
end

local function stepCollectMeleeTargets(state, deadlineMs)
    while state.collectMemberIndex <= #state.activeMembers do
        local member = state.activeMembers[state.collectMemberIndex]
        local candidates = getMemberCandidates(member)
        if state.collectCandidateIndex > #candidates then
            state.collectMemberIndex = state.collectMemberIndex + 1
            state.collectCandidateIndex = 1
            state.collectTargetIndex = 1
        else
            local candidate = candidates[state.collectCandidateIndex]
            if not isCandidateUseful(candidate) or not candidateRequiresMelee(candidate) then
                state.collectCandidateIndex = state.collectCandidateIndex + 1
                state.collectTargetIndex = 1
            else
                local targetCount = getCandidateTargetCount(candidate)
                if targetCount <= 0 then
                    state.collectCandidateIndex = state.collectCandidateIndex + 1
                    state.collectTargetIndex = 1
                else
                    local targetUnit = getCandidateTargetAt(candidate, state.collectTargetIndex)
                    local position = type(targetUnit) == "table"
                        and getCachedPosition(state.spatialRuntime, state.eventState, targetUnit)
                        or nil
                    if position then
                        insertBoundedAnchorTarget(state, targetUnit, position, getCandidateUtility(candidate))
                    end
                    advanceCollectCursor(state, candidate)
                end
            end
        end

        if shouldYield(deadlineMs) then
            return false
        end
    end

    state.phase = "generate-target-anchors"
    return false
end

local function stepGenerateTargetAnchors(state, deadlineMs)
    while state.targetAnchorIndex <= #state.anchorTargets do
        local entry = state.anchorTargets[state.targetAnchorIndex]
        addAnchor(state, "target:" .. tostring(entry.eventId), entry.position)
        state.targetAnchorIndex = state.targetAnchorIndex + 1
        if shouldYield(deadlineMs) then
            return false
        end
    end
    state.phase = "generate-centroid"
    return false
end

local function stepGenerateCentroid(state, deadlineMs)
    while state.centroidIndex <= #state.anchorTargets do
        local entry = state.anchorTargets[state.centroidIndex]
        local position = entry and entry.position or nil
        if type(position) == "table" and tonumber(position.x) ~= nil and tonumber(position.y) ~= nil then
            state.centroidSumX = state.centroidSumX + tonumber(position.x)
            state.centroidSumY = state.centroidSumY + tonumber(position.y)
            state.centroidCount = state.centroidCount + 1
        end
        state.centroidIndex = state.centroidIndex + 1
        if shouldYield(deadlineMs) then
            return false
        end
    end

    if state.centroidCount > 1 then
        addAnchor(state, "centroid", {
            available = true,
            x = state.centroidSumX / state.centroidCount,
            y = state.centroidSumY / state.centroidCount,
            instanceID = state.currentPosition.instanceID,
        })
    end
    state.phase = "generate-pairwise"
    return false
end

local function advancePairCursor(state)
    state.pairRightIndex = state.pairRightIndex + 1
    if state.pairRightIndex > #state.anchorTargets then
        state.pairLeftIndex = state.pairLeftIndex + 1
        state.pairRightIndex = state.pairLeftIndex + 1
    end
end

local function stepGeneratePairwise(state, deadlineMs)
    while state.pairLeftIndex <= #state.anchorTargets do
        local left = state.anchorTargets[state.pairLeftIndex]
        local right = state.anchorTargets[state.pairRightIndex]
        if type(left) == "table" and type(right) == "table" then
            addAnchor(state, ("mid:%d:%d"):format(left.eventId, right.eventId), {
                available = true,
                x = ((tonumber(left.position.x) or 0) + (tonumber(right.position.x) or 0)) / 2,
                y = ((tonumber(left.position.y) or 0) + (tonumber(right.position.y) or 0)) / 2,
                instanceID = state.currentPosition.instanceID,
            })
        end
        advancePairCursor(state)
        if shouldYield(deadlineMs) then
            return false
        end
    end
    state.phase = "evaluate-anchors"
    return false
end

local function resetCandidateEvaluation(state)
    state.evalTargetIndex = 1
    state.evalCandidateFeasible = true
end

local function finishCandidateEvaluation(state, candidate)
    if state.evalCandidateFeasible == true and isCandidateUseful(candidate) then
        if type(state.evalBestCandidate) ~= "table" or compareCandidates(candidate, state.evalBestCandidate) > 0 then
            state.evalBestCandidate = candidate
        end
    end
    state.evalCandidateIndex = state.evalCandidateIndex + 1
    resetCandidateEvaluation(state)
end

local function evaluateMeleeCandidateTarget(state, anchor, candidate)
    local targetCount = getCandidateTargetCount(candidate)
    if targetCount <= 0 then
        state.evalCandidateFeasible = false
        return true
    end

    local targetUnit = getCandidateTargetAt(candidate, state.evalTargetIndex)
    local targetPosition = type(targetUnit) == "table"
        and getCachedPosition(state.spatialRuntime, state.eventState, targetUnit)
        or nil
    local distance = targetPosition and distanceBetween(anchor.position, targetPosition) or nil
    if distance == nil or distance > (Solver.MELEE_RANGE_YARDS + EPSILON) then
        state.evalCandidateFeasible = false
        return true
    end

    state.evalTargetIndex = state.evalTargetIndex + 1
    return state.evalTargetIndex > targetCount
end

local function beginAnchorEvaluation(state, anchor)
    state.currentAnchorEvaluation = {
        anchor = anchor,
        selectedCandidates = {},
        aggregateUtility = 0,
        usefulCoverage = 0,
        urgentHealingCount = 0,
    }
    state.evalMemberIndex = 1
    state.evalCandidateIndex = 1
    state.evalBestCandidate = nil
    resetCandidateEvaluation(state)
end

local function finishMemberEvaluation(state)
    local evaluation = state.currentAnchorEvaluation
    local candidate = state.evalBestCandidate
    evaluation.selectedCandidates[state.evalMemberIndex] = candidate
    if type(candidate) == "table" then
        evaluation.aggregateUtility = evaluation.aggregateUtility + getCandidateUtility(candidate)
        evaluation.usefulCoverage = evaluation.usefulCoverage + 1
        if candidate.urgentHealing == true then
            evaluation.urgentHealingCount = evaluation.urgentHealingCount + 1
        end
    end

    state.evalMemberIndex = state.evalMemberIndex + 1
    state.evalCandidateIndex = 1
    state.evalBestCandidate = nil
    resetCandidateEvaluation(state)
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
    evaluation.movementPenalty = movementDistance * Solver.MOVEMENT_PENALTY_PER_YARD
    evaluation.adjustedUtility = evaluation.aggregateUtility - evaluation.movementPenalty

    if type(state.bestAnchorEvaluation) ~= "table"
        or compareAnchorEvaluations(evaluation, state.bestAnchorEvaluation) > 0
    then
        state.bestAnchorEvaluation = evaluation
    end

    state.anchorEvalIndex = state.anchorEvalIndex + 1
    state.currentAnchorEvaluation = nil
end

local function stepEvaluateAnchors(state, deadlineMs)
    while state.anchorEvalIndex <= #state.anchorCandidates do
        local anchor = state.anchorCandidates[state.anchorEvalIndex]
        if type(state.currentAnchorEvaluation) ~= "table" then
            beginAnchorEvaluation(state, anchor)
        end

        if state.evalMemberIndex > #state.activeMembers then
            finishAnchorEvaluation(state)
        else
            local member = state.activeMembers[state.evalMemberIndex]
            local candidates = getMemberCandidates(member)
            if state.evalCandidateIndex > #candidates then
                finishMemberEvaluation(state)
            else
                local candidate = candidates[state.evalCandidateIndex]
                if not isCandidateUseful(candidate) then
                    state.evalCandidateIndex = state.evalCandidateIndex + 1
                    resetCandidateEvaluation(state)
                elseif candidateRequiresMelee(candidate) then
                    local candidateComplete = evaluateMeleeCandidateTarget(state, anchor, candidate)
                    if candidateComplete then
                        finishCandidateEvaluation(state, candidate)
                    end
                else
                    finishCandidateEvaluation(state, candidate)
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

local function collectTargetEventIds(candidate)
    local ids = {}
    local seen = {}
    local targetCount = getCandidateTargetCount(candidate)
    for index = 1, targetCount do
        local targetUnit = getCandidateTargetAt(candidate, index)
        local eventId = normalizeEventId(targetUnit and targetUnit.eventID)
        if eventId > 0 and not seen[eventId] then
            seen[eventId] = true
            ids[#ids + 1] = eventId
        end
    end
    if #ids == 0 then
        local eventId = normalizeEventId(candidate and candidate.targetEventId)
        if eventId > 0 then
            ids[1] = eventId
        end
    end
    table.sort(ids)
    return ids
end

local function buildMovementActionId(state, anchor)
    return ("movement:%s:%.4f:%.4f"):format(
        tostring(state.actorKey),
        tonumber(anchor and anchor.position and anchor.position.x) or 0,
        tonumber(anchor and anchor.position and anchor.position.y) or 0
    )
end

local function buildWarning(state)
    if state.cohortMovementAllowance > 0 or #state.pinnedMembers == 0 then
        return nil
    end

    local memberIds = {}
    local names = {}
    for index = 1, #state.pinnedMembers do
        local entry = state.pinnedMembers[index]
        memberIds[#memberIds + 1] = entry.eventId
        names[#names + 1] = entry.name
    end
    table.sort(memberIds)
    table.sort(names)

    return {
        warningType = "movement-blocked",
        actorKey = state.actorKey,
        raidMarker = state.raidMarker,
        memberEventIds = memberIds,
        text = ("Marker %d cannot move because %s has no movement allowance."):format(
            state.raidMarker,
            table.concat(names, ", ")
        ),
    }
end

local function buildFinalResult(state)
    local best = state.bestAnchorEvaluation
    if type(best) ~= "table" or type(best.anchor) ~= "table" then
        return failState(state, "anchor-unavailable")
    end

    local movement = nil
    if best.anchor.isCurrent ~= true and best.anchor.movementDistance > EPSILON then
        movement = {
            actionType = "movement",
            actionId = buildMovementActionId(state, best.anchor),
            actorKey = state.actorKey,
            raidMarker = state.raidMarker,
            objectiveTargetEventIds = {},
            proposedPosition = copyPosition(best.anchor.position),
            movementAllowance = state.cohortMovementAllowance,
            movementDistance = best.anchor.movementDistance,
            status = "pending",
        }
    end

    local actions = {}
    local objectiveSeen = {}
    for index = 1, #state.activeMembers do
        local member = state.activeMembers[index]
        local unit = getMemberUnit(member)
        local candidate = best.selectedCandidates[index]
        if type(unit) == "table" and type(candidate) == "table" then
            local targetEventIds = collectTargetEventIds(candidate)
            local action = {
                actionType = "spell",
                casterEventId = normalizeEventId(unit.eventID),
                spellRef = tostring(candidate.spellRef or ""),
                targetEventId = targetEventIds[1] or normalizeEventId(candidate.targetEventId),
                targetEventIds = targetEventIds,
                totalUtility = getCandidateUtility(candidate),
                urgentHealing = candidate.urgentHealing == true,
                requiresMeleePosition = candidateRequiresMelee(candidate),
                status = "pending",
            }
            if movement and action.requiresMeleePosition then
                action.requiresMovementActionId = movement.actionId
                for targetIndex = 1, #targetEventIds do
                    local targetEventId = targetEventIds[targetIndex]
                    if not objectiveSeen[targetEventId] then
                        objectiveSeen[targetEventId] = true
                        movement.objectiveTargetEventIds[#movement.objectiveTargetEventIds + 1] = targetEventId
                    end
                end
            end
            actions[#actions + 1] = action
        end
    end

    if movement then
        table.sort(movement.objectiveTargetEventIds)
    end

    local warnings = {}
    local warning = buildWarning(state)
    if warning then
        warnings[1] = warning
    end

    state.result = {
        status = "ready",
        actorKey = state.actorKey,
        raidMarker = state.raidMarker,
        currentPosition = copyPosition(state.currentPosition),
        selectedPosition = copyPosition(best.anchor.position),
        movementAllowance = state.cohortMovementAllowance,
        movementByMemberEventId = state.movementByMemberEventId,
        aggregateUtility = best.aggregateUtility,
        adjustedUtility = best.adjustedUtility,
        usefulCoverage = best.usefulCoverage,
        movement = movement,
        actions = actions,
        warnings = warnings,
    }
    state.phase = "complete"
    return true
end

function Solver.Step(state, deadlineMs)
    if type(state) ~= "table" then
        return true
    end

    while state.phase ~= "complete" do
        if state.phase == "resolve-movement" then
            stepResolveMovement(state, deadlineMs)
        elseif state.phase == "collect-melee-targets" then
            stepCollectMeleeTargets(state, deadlineMs)
        elseif state.phase == "generate-target-anchors" then
            stepGenerateTargetAnchors(state, deadlineMs)
        elseif state.phase == "generate-centroid" then
            stepGenerateCentroid(state, deadlineMs)
        elseif state.phase == "generate-pairwise" then
            stepGeneratePairwise(state, deadlineMs)
        elseif state.phase == "evaluate-anchors" then
            stepEvaluateAnchors(state, deadlineMs)
        elseif state.phase == "finalize" then
            return buildFinalResult(state)
        else
            return failState(state, "unknown-solver-phase")
        end

        if state.phase ~= "complete" and shouldYield(deadlineMs) then
            return false
        end
    end

    return true
end

local function copyMovementDetailsByMember(source)
    local copied = {}
    for eventId, details in pairs(type(source) == "table" and source or {}) do
        if type(details) == "table" then
            copied[eventId] = {
                available = details.available == true,
                reason = details.reason,
                statRef = details.statRef,
                baseValue = details.baseValue,
                movementRangeOverride = details.movementRangeOverride,
                effectiveValue = details.effectiveValue,
            }
        end
    end
    return copied
end

function Solver.CopyResult(state)
    if type(state) ~= "table" or state.phase ~= "complete" or type(state.result) ~= "table" then
        return nil
    end

    local result = state.result
    local copiedActions = {}
    for index = 1, #(result.actions or {}) do
        local source = result.actions[index]
        local targets = {}
        for targetIndex = 1, #(source.targetEventIds or {}) do
            targets[targetIndex] = source.targetEventIds[targetIndex]
        end
        copiedActions[index] = {
            actionType = source.actionType,
            casterEventId = source.casterEventId,
            spellRef = source.spellRef,
            targetEventId = source.targetEventId,
            targetEventIds = targets,
            totalUtility = source.totalUtility,
            urgentHealing = source.urgentHealing == true,
            requiresMeleePosition = source.requiresMeleePosition == true,
            requiresMovementActionId = source.requiresMovementActionId,
            status = source.status,
        }
    end

    local copiedMovement = nil
    if type(result.movement) == "table" then
        local objectiveIds = {}
        for index = 1, #(result.movement.objectiveTargetEventIds or {}) do
            objectiveIds[index] = result.movement.objectiveTargetEventIds[index]
        end
        copiedMovement = {
            actionType = result.movement.actionType,
            actionId = result.movement.actionId,
            actorKey = result.movement.actorKey,
            raidMarker = result.movement.raidMarker,
            objectiveTargetEventIds = objectiveIds,
            proposedPosition = copyPosition(result.movement.proposedPosition),
            movementAllowance = result.movement.movementAllowance,
            movementDistance = result.movement.movementDistance,
            status = result.movement.status,
        }
    end

    local copiedWarnings = {}
    for index = 1, #(result.warnings or {}) do
        local source = result.warnings[index]
        local memberIds = {}
        for memberIndex = 1, #(source.memberEventIds or {}) do
            memberIds[memberIndex] = source.memberEventIds[memberIndex]
        end
        copiedWarnings[index] = {
            warningType = source.warningType,
            actorKey = source.actorKey,
            raidMarker = source.raidMarker,
            memberEventIds = memberIds,
            text = source.text,
        }
    end

    return {
        status = result.status,
        reason = result.reason,
        actorKey = result.actorKey,
        raidMarker = result.raidMarker,
        currentPosition = copyPosition(result.currentPosition),
        selectedPosition = copyPosition(result.selectedPosition),
        movementAllowance = result.movementAllowance,
        movementByMemberEventId = copyMovementDetailsByMember(result.movementByMemberEventId),
        aggregateUtility = result.aggregateUtility,
        adjustedUtility = result.adjustedUtility,
        usefulCoverage = result.usefulCoverage,
        movement = copiedMovement,
        actions = copiedActions,
        warnings = copiedWarnings,
    }
end

return Solver