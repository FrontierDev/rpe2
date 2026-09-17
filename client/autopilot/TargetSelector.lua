local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Tasks = Addon.Internal.Tasks or {}
local Debug = Addon.Debug or {}
local Spatial = Client.AutopilotSpatial or {}
local SpellEvaluator = Client.AutopilotSpellEvaluator or {}

Client.AutopilotTargetSelector = Client.AutopilotTargetSelector or {}
local Selector = Client.AutopilotTargetSelector

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

local function normalizeCount(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function normalizeRaidMarker(value)
    local marker = math.floor(tonumber(value) or 0)
    return marker >= 1 and marker <= 8 and marker or 0
end

local function normalizeIntent(value)
    local intent = tostring(value or "")
    if intent == "heal" or intent == "healing" then
        return "healing"
    end
    if intent == "damage" or intent == "hostile" then
        return "hostile"
    end
    if intent == "interrupt" then
        return "interrupt"
    end
    return nil
end

local function normalizePolicy(policy)
    local source = type(policy) == "table" and policy or {}
    local targetType = tostring(source.type or "single")
    local minTargets = normalizeCount(source.minTargets)
    local maxTargets = normalizeCount(source.maxTargets)
    if targetType ~= "all_allies" and maxTargets < minTargets then
        maxTargets = minTargets
    end

    return {
        type = targetType,
        requiresTarget = source.requiresTarget == true,
        targetDisposition = tostring(source.targetDisposition or "enemy"),
        minTargets = minTargets,
        maxTargets = maxTargets,
        allowDeadTargets = source.allowDeadTargets == true,
        allowHiddenTargets = source.allowHiddenTargets == true,
        disableSelfCast = source.disableSelfCast == true,
    }
end

local function findTargetGroup(groups, groupKey)
    local normalizedKey = tostring(groupKey or "")
    if normalizedKey == "" then
        return type(groups) == "table" and groups[1] or nil
    end

    for index = 1, #(groups or {}) do
        local group = groups[index]
        if tostring(group and group.key or "") == normalizedKey then
            return group
        end
    end
    return nil
end

local function resolveCanonicalGroup(snapshot, groupKey)
    local groups = type(snapshot) == "table" and snapshot.targetGroups or nil
    if type(groups) == "table" and #groups > 0 then
        local group = findTargetGroup(groups, groupKey)
        if type(group) ~= "table" then
            return nil, nil, nil, "target-group-unavailable"
        end

        local key = tostring(group.key or "")
        local candidates = type(snapshot.targetCandidatesByGroup) == "table"
            and snapshot.targetCandidatesByGroup[key]
            or nil
        if type(candidates) ~= "table" and group == groups[1] then
            candidates = snapshot.targetCandidates
        end
        return key, normalizePolicy(group.policy), type(candidates) == "table" and candidates or {}, nil
    end

    if groupKey ~= nil and tostring(groupKey) ~= "" then
        return nil, nil, nil, "target-group-unavailable"
    end
    return nil, normalizePolicy(snapshot and snapshot.policy), type(snapshot and snapshot.targetCandidates) == "table" and snapshot.targetCandidates or {}, nil
end

local function getThreat(casterUnit, targetUnit)
    local targetEventId = normalizeEventId(targetUnit and targetUnit.eventID)
    if targetEventId <= 0 or type(casterUnit) ~= "table" then
        return 0
    end
    local threatTable = type(casterUnit.threatTable) == "table" and casterUnit.threatTable or nil
    return math.max(0, tonumber(threatTable and threatTable[targetEventId]) or 0)
end

local function resolveTauntOverride(casterUnit, candidates)
    local tauntState = type(casterUnit) == "table" and casterUnit.tauntState or nil
    if type(tauntState) ~= "table" then
        return 0, 0
    end

    local sourceEventId = normalizeEventId(tauntState.sourceEventId or tauntState.sourceId)
    local remainingTurns = math.max(0, math.floor(tonumber(tauntState.remainingTurns or tauntState.duration) or 0))
    if sourceEventId <= 0 or remainingTurns <= 0 then
        return 0, 0
    end

    -- Candidate membership is the legality check. The selector deliberately
    -- does not duplicate disposition, active, dead, or hidden-target rules.
    for index = 1, #(candidates or {}) do
        if normalizeEventId(candidates[index] and candidates[index].eventID) == sourceEventId then
            return sourceEventId, remainingTurns
        end
    end
    return 0, 0
end

local function getCachedDistance(runtime, eventState, leftUnit, rightUnit)
    if type(Spatial.DistanceBetweenCachedUnits) ~= "function" then
        return nil
    end
    local distance = Spatial.DistanceBetweenCachedUnits(runtime, eventState, leftUnit, rightUnit)
    return tonumber(distance)
end

local function buildHostileEntry(state, targetUnit)
    return {
        unit = targetUnit,
        eventId = normalizeEventId(targetUnit and targetUnit.eventID),
        threat = getThreat(state.casterUnit, targetUnit),
        casterDistance = getCachedDistance(state.spatialRuntime, state.eventState, state.casterUnit, targetUnit),
        primaryDistance = nil,
    }
end

local function buildHealingEntry(state, targetUnit)
    local health = type(SpellEvaluator.ResolveProjectedHealth) == "function"
        and SpellEvaluator.ResolveProjectedHealth(targetUnit, state.eventState, state.projectedHealingLedger)
        or nil
    return {
        unit = targetUnit,
        eventId = normalizeEventId(targetUnit and targetUnit.eventID),
        health = health,
    }
end

local function resolveInterruptRemainingTurns(activeCast)
    if type(activeCast) ~= "table" then
        return nil
    end
    local remaining = activeCast.turnsRemaining
    if remaining == nil then
        remaining = activeCast.remainingTurns
    end
    if remaining == nil then
        remaining = activeCast.castRemainingTurns
    end
    if tonumber(remaining) == nil then
        return nil
    end
    return math.max(0, math.floor(tonumber(remaining) or 0))
end

local function buildInterruptEntry(state, targetUnit)
    if tostring(state.policy and state.policy.targetDisposition or "") ~= "enemy" then
        return nil
    end
    local eventId = normalizeEventId(targetUnit and targetUnit.eventID)
    local activeCast = eventId > 0
        and type(state.activeCastsByEventId) == "table"
        and state.activeCastsByEventId[eventId]
        or nil
    if type(activeCast) ~= "table" then
        return nil
    end
    return {
        unit = targetUnit,
        eventId = eventId,
        threat = getThreat(state.casterUnit, targetUnit),
        activeCast = activeCast,
        interruptRemainingTurns = resolveInterruptRemainingTurns(activeCast),
    }
end

local function compareKnownDistance(leftDistance, rightDistance)
    local leftKnown = tonumber(leftDistance) ~= nil
    local rightKnown = tonumber(rightDistance) ~= nil
    if leftKnown ~= rightKnown then
        return leftKnown and 1 or -1
    end
    if leftKnown and leftDistance ~= rightDistance then
        return leftDistance < rightDistance and 1 or -1
    end
    return 0
end

local function compareHostilePrimary(left, right)
    local leftThreat = math.max(0, tonumber(left and left.threat) or 0)
    local rightThreat = math.max(0, tonumber(right and right.threat) or 0)
    if leftThreat ~= rightThreat then
        return leftThreat > rightThreat and 1 or -1
    end

    local distanceOrder = compareKnownDistance(left and left.casterDistance, right and right.casterDistance)
    if distanceOrder ~= 0 then
        return distanceOrder
    end

    local leftEventId = normalizeEventId(left and left.eventId)
    local rightEventId = normalizeEventId(right and right.eventId)
    if leftEventId ~= rightEventId then
        return leftEventId < rightEventId and 1 or -1
    end
    return 0
end

local function compareHostilePrimaryWithTaunt(state, left, right)
    local tauntSourceEventId = normalizeEventId(state and state.tauntSourceEventId)
    if tauntSourceEventId > 0 then
        local leftIsTaunt = normalizeEventId(left and left.eventId) == tauntSourceEventId
        local rightIsTaunt = normalizeEventId(right and right.eventId) == tauntSourceEventId
        if leftIsTaunt ~= rightIsTaunt then
            return leftIsTaunt and 1 or -1
        end
    end
    return compareHostilePrimary(left, right)
end

local function resolveHostileSelectionReason(state, selectedEntry)
    if type(selectedEntry) ~= "table" then
        return "none"
    end
    if state.tauntSourceEventId > 0
        and normalizeEventId(selectedEntry.eventId) == state.tauntSourceEventId
    then
        return "taunt"
    end

    local selectedThreat = math.max(0, tonumber(selectedEntry.threat) or 0)
    local hasLowerThreat = false
    local hasEqualThreat = false
    for index = 1, #(state.entries or {}) do
        local other = state.entries[index]
        if other ~= selectedEntry then
            local otherThreat = math.max(0, tonumber(other and other.threat) or 0)
            if otherThreat < selectedThreat then
                hasLowerThreat = true
            elseif otherThreat == selectedThreat then
                hasEqualThreat = true
            end
        end
    end
    if hasLowerThreat then
        return "threat"
    end
    if hasEqualThreat then
        local selectedDistance = tonumber(selectedEntry.casterDistance)
        for index = 1, #(state.entries or {}) do
            local other = state.entries[index]
            if other ~= selectedEntry
                and math.max(0, tonumber(other and other.threat) or 0) == selectedThreat
                and compareKnownDistance(selectedDistance, tonumber(other.casterDistance)) ~= 0
            then
                return "distance"
            end
        end
        return "eventID"
    end
    return "threat"
end

local function compareHostileSecondary(left, right)
    local distanceOrder = compareKnownDistance(left and left.primaryDistance, right and right.primaryDistance)
    if distanceOrder ~= 0 then
        return distanceOrder
    end

    local leftHasDistance = tonumber(left and left.primaryDistance) ~= nil
    local rightHasDistance = tonumber(right and right.primaryDistance) ~= nil
    if leftHasDistance ~= true and rightHasDistance ~= true then
        local leftThreat = math.max(0, tonumber(left and left.threat) or 0)
        local rightThreat = math.max(0, tonumber(right and right.threat) or 0)
        if leftThreat ~= rightThreat then
            return leftThreat > rightThreat and 1 or -1
        end
    end

    local leftEventId = normalizeEventId(left and left.eventId)
    local rightEventId = normalizeEventId(right and right.eventId)
    if leftEventId ~= rightEventId then
        return leftEventId < rightEventId and 1 or -1
    end
    return 0
end

local function compareHealing(left, right)
    local leftHealth = type(left) == "table" and left.health or nil
    local rightHealth = type(right) == "table" and right.health or nil
    local leftKnown = type(leftHealth) == "table"
    local rightKnown = type(rightHealth) == "table"
    if leftKnown ~= rightKnown then
        return leftKnown and 1 or -1
    end

    if leftKnown then
        local leftFraction = tonumber(leftHealth.projectedHealthFraction)
            or tonumber(leftHealth.healthFraction)
            or 1
        local rightFraction = tonumber(rightHealth.projectedHealthFraction)
            or tonumber(rightHealth.healthFraction)
            or 1
        if leftFraction ~= rightFraction then
            return leftFraction < rightFraction and 1 or -1
        end

        local leftMissing = math.max(0, tonumber(leftHealth.projectedMissingHealth) or tonumber(leftHealth.missingHealth) or 0)
        local rightMissing = math.max(0, tonumber(rightHealth.projectedMissingHealth) or tonumber(rightHealth.missingHealth) or 0)
        if leftMissing ~= rightMissing then
            return leftMissing > rightMissing and 1 or -1
        end
    end

    local leftEventId = normalizeEventId(left and left.eventId)
    local rightEventId = normalizeEventId(right and right.eventId)
    if leftEventId ~= rightEventId then
        return leftEventId < rightEventId and 1 or -1
    end
    return 0
end

local function compareInterrupt(left, right)
    local leftRemaining = tonumber(left and left.interruptRemainingTurns)
    local rightRemaining = tonumber(right and right.interruptRemainingTurns)
    if leftRemaining ~= nil and rightRemaining ~= nil and leftRemaining ~= rightRemaining then
        return leftRemaining < rightRemaining and 1 or -1
    end

    local leftThreat = math.max(0, tonumber(left and left.threat) or 0)
    local rightThreat = math.max(0, tonumber(right and right.threat) or 0)
    if leftThreat ~= rightThreat then
        return leftThreat > rightThreat and 1 or -1
    end

    local leftEventId = normalizeEventId(left and left.eventId)
    local rightEventId = normalizeEventId(right and right.eventId)
    if leftEventId ~= rightEventId then
        return leftEventId < rightEventId and 1 or -1
    end
    return 0
end

local function isOptionalHealingTargetUseful(entry)
    local health = type(entry) == "table" and entry.health or nil
    if type(health) ~= "table" then
        return false
    end
    return math.max(0, tonumber(health.projectedMissingHealth) or tonumber(health.missingHealth) or 0) > 0
end

local function markSelected(state, entryIndex)
    local entry = state.entries[entryIndex]
    if type(entry) ~= "table" then
        return false
    end

    local eventId = normalizeEventId(entry.eventId)
    if eventId <= 0 or state.selectedByEventId[eventId] == true then
        return false
    end

    state.selectedEntries[#state.selectedEntries + 1] = entry
    state.selectedByEventId[eventId] = true
    if state.kind == "hostile" and state.primaryEntry == nil then
        state.primaryEntry = entry
        state.primarySelectionReason = resolveHostileSelectionReason(state, entry)
    end
    return true
end

local buildResult

local function finishSelection(state)
    state.result = buildResult(state)
    if type(Debug.Internal) == "function" and state.kind == "hostile" then
        local casterEventId = normalizeEventId(state.casterUnit and state.casterUnit.eventID)
        local selectedEventId = normalizeEventId(state.result.primaryTargetEventId)
        local reason = tostring(state.result.selectionReason or "none")
        local suffix = reason == "taunt"
            and (" remaining=" .. tostring(normalizeCount(state.result.tauntRemainingTurns)))
            or ""
        Debug.Internal(
            "Autopilot target: npc=%d selected=%d reason=%s%s",
            casterEventId,
            selectedEventId,
            reason,
            suffix
        )
    end
    state.phase = "complete"
end

buildResult = function(state)
    local targetUnits = {}
    local targetEventIds = {}
    for index = 1, #(state.selectedEntries or {}) do
        local entry = state.selectedEntries[index]
        if type(entry) == "table" and type(entry.unit) == "table" then
            targetUnits[#targetUnits + 1] = entry.unit
            targetEventIds[#targetEventIds + 1] = normalizeEventId(entry.eventId)
        end
    end

    return {
        status = "ready",
        kind = state.kind,
        targetGroupKey = state.targetGroupKey,
        policy = state.policy,
        minTargets = state.minTargets,
        maxTargets = state.maxTargets,
        selectedCount = #targetUnits,
        meetsMinTargets = #targetUnits >= state.minTargets,
        targetUnits = targetUnits,
        targetEventIds = targetEventIds,
        primaryTargetUnit = targetUnits[1],
        primaryTargetEventId = targetEventIds[1],
        selectionReason = tostring(state.primarySelectionReason or "none"),
        tauntSourceEventId = normalizeEventId(state.tauntSourceEventId),
        tauntRemainingTurns = normalizeCount(state.tauntRemainingTurns),
    }
end

local function shouldYield(deadlineMs)
    return type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true
end

local function resetSelectionScan(state, phase)
    state.phase = phase
    state.selectionScanIndex = 1
    state.bestEntryIndex = nil
end

local function compareForPhase(state, left, right)
    if state.kind == "healing" then
        return compareHealing(left, right)
    end
    if state.kind == "interrupt" then
        return compareInterrupt(left, right)
    end
    if state.phase == "select-secondary" then
        return compareHostileSecondary(left, right)
    end
    return compareHostilePrimaryWithTaunt(state, left, right)
end

local function completeSelectionPass(state)
    local bestIndex = state.bestEntryIndex
    state.selectionScanIndex = 1
    state.bestEntryIndex = nil
    if not bestIndex then
        finishSelection(state)
        return true
    end

    local bestEntry = state.entries[bestIndex]
    if state.targetType ~= "raid_marker"
        and state.kind == "healing"
        and #state.selectedEntries >= state.minTargets
        and not isOptionalHealingTargetUseful(bestEntry)
    then
        finishSelection(state)
        return true
    end

    markSelected(state, bestIndex)
    if #state.selectedEntries >= state.maxTargets then
        finishSelection(state)
        return true
    end

    if state.targetType == "raid_marker" then
        if state.phase == "select" then
            state.anchorRaidMarker = normalizeRaidMarker(bestEntry.unit and bestEntry.unit.raidMarker)
            if state.anchorRaidMarker <= 0 then
                finishSelection(state)
                return true
            end
        end
        resetSelectionScan(state, "select-raid-marker")
        return false
    end

    if state.targetType ~= "raid_marker"
        and state.kind == "hostile"
        and #state.selectedEntries == 1
        and state.maxTargets > 1
    then
        state.phase = "prepare-secondary"
        state.secondaryPrepareIndex = 1
        return false
    end

    resetSelectionScan(state, state.kind == "hostile" and "select-secondary" or "select")
    return false
end

function Selector.CreateState(activationSnapshot, options)
    options = type(options) == "table" and options or {}
    if type(activationSnapshot) ~= "table" or activationSnapshot.canCast ~= true then
        return nil, "illegal-activation"
    end
    if type(activationSnapshot.casterUnit) ~= "table" or type(activationSnapshot.eventState) ~= "table" then
        return nil, "activation-context-unavailable"
    end

    local kind = normalizeIntent(options.intent)
    if not kind then
        return nil, "intent-unavailable"
    end

    local groupKey, policy, candidates, groupReason = resolveCanonicalGroup(activationSnapshot, options.targetGroupKey)
    if groupReason then
        return nil, groupReason
    end

    local targetType = tostring(policy.type or "single")
    if targetType == "raid_marker" then
        local markedCandidates = {}
        for index = 1, #candidates do
            if normalizeRaidMarker(candidates[index] and candidates[index].raidMarker) > 0 then
                markedCandidates[#markedCandidates + 1] = candidates[index]
            end
        end
        candidates = markedCandidates
    end

    local tauntSourceEventId, tauntRemainingTurns = 0, 0
    if kind == "hostile" then
        tauntSourceEventId, tauntRemainingTurns = resolveTauntOverride(
            activationSnapshot.casterUnit,
            candidates
        )
    end

    local state = {
        activationSnapshot = activationSnapshot,
        eventState = activationSnapshot.eventState,
        casterUnit = activationSnapshot.casterUnit,
        spatialRuntime = options.spatialRuntime,
        projectedHealingLedger = options.projectedHealingLedger,
        activeCastsByEventId = options.activeCastsByEventId,
        kind = kind,
        targetGroupKey = groupKey,
        policy = policy,
        targetType = targetType,
        minTargets = policy.minTargets,
        maxTargets = policy.maxTargets,
        candidates = candidates,
        candidateIndex = 1,
        entries = {},
        selectedEntries = {},
        selectedByEventId = {},
        tauntSourceEventId = tauntSourceEventId,
        tauntRemainingTurns = tauntRemainingTurns,
        primarySelectionReason = nil,
        selectionScanIndex = 1,
        bestEntryIndex = nil,
        secondaryPrepareIndex = 1,
        primaryEntry = nil,
        phase = "scan",
        result = nil,
    }

    if state.maxTargets <= 0 and state.targetType ~= "all_allies" then
        finishSelection(state)
    elseif state.targetType == "all_allies" and #state.candidates == 0 then
        finishSelection(state)
    end
    return state
end

function Selector.Step(state, deadlineMs)
    if type(state) ~= "table" then
        return true
    end

    while state.phase ~= "complete" do
        if state.phase == "scan" then
            while state.candidateIndex <= #(state.candidates or {}) do
                local targetUnit = state.candidates[state.candidateIndex]
                local entry = nil
                if state.kind == "healing" then
                    entry = buildHealingEntry(state, targetUnit)
                elseif state.kind == "interrupt" then
                    entry = buildInterruptEntry(state, targetUnit)
                else
                    entry = buildHostileEntry(state, targetUnit)
                end
                if type(entry) == "table" and entry.eventId > 0 then
                    state.entries[#state.entries + 1] = entry
                end
                state.candidateIndex = state.candidateIndex + 1
                if shouldYield(deadlineMs) then
                    return false
                end
            end

            if state.targetType == "all_allies" then
                for entryIndex = 1, #state.entries do
                    if state.maxTargets > 0 and #state.selectedEntries >= state.maxTargets then
                        break
                    end
                    markSelected(state, entryIndex)
                end
                finishSelection(state)
            else
                resetSelectionScan(state, "select")
            end
            if shouldYield(deadlineMs) then
                return false
            end
        elseif state.phase == "prepare-secondary" then
            while state.secondaryPrepareIndex <= #(state.entries or {}) do
                local entry = state.entries[state.secondaryPrepareIndex]
                if type(entry) == "table" and entry ~= state.primaryEntry then
                    entry.primaryDistance = getCachedDistance(
                        state.spatialRuntime,
                        state.eventState,
                        state.primaryEntry and state.primaryEntry.unit,
                        entry.unit
                    )
                end
                state.secondaryPrepareIndex = state.secondaryPrepareIndex + 1
                if shouldYield(deadlineMs) then
                    return false
                end
            end

            resetSelectionScan(state, "select-secondary")
            if shouldYield(deadlineMs) then
                return false
            end
        elseif state.phase == "select"
            or state.phase == "select-secondary"
            or state.phase == "select-raid-marker"
        then
            while state.selectionScanIndex <= #(state.entries or {}) do
                local entryIndex = state.selectionScanIndex
                local entry = state.entries[entryIndex]
                local eventId = normalizeEventId(entry and entry.eventId)
                local entryMarker = normalizeRaidMarker(entry and entry.unit and entry.unit.raidMarker)
                local markerMatches = state.phase ~= "select-raid-marker"
                    or entryMarker == state.anchorRaidMarker
                if eventId > 0 and state.selectedByEventId[eventId] ~= true and markerMatches then
                    local best = state.bestEntryIndex and state.entries[state.bestEntryIndex] or nil
                    if type(best) ~= "table" or compareForPhase(state, entry, best) > 0 then
                        state.bestEntryIndex = entryIndex
                    end
                end
                state.selectionScanIndex = state.selectionScanIndex + 1
                if shouldYield(deadlineMs) then
                    return false
                end
            end

            completeSelectionPass(state)
            if state.phase ~= "complete" and shouldYield(deadlineMs) then
                return false
            end
        else
            state.result = buildResult(state)
            state.phase = "complete"
        end
    end

    return true
end

function Selector.CopyResult(state)
    if type(state) ~= "table" or state.phase ~= "complete" or type(state.result) ~= "table" then
        return nil
    end

    local source = state.result
    return {
        status = tostring(source.status or "ready"),
        kind = tostring(source.kind or ""),
        targetGroupKey = source.targetGroupKey,
        policy = source.policy,
        minTargets = normalizeCount(source.minTargets),
        maxTargets = normalizeCount(source.maxTargets),
        selectedCount = normalizeCount(source.selectedCount),
        meetsMinTargets = source.meetsMinTargets == true,
        targetUnits = copyArray(source.targetUnits),
        targetEventIds = copyArray(source.targetEventIds),
        primaryTargetUnit = source.primaryTargetUnit,
        primaryTargetEventId = normalizeEventId(source.primaryTargetEventId),
        selectionReason = tostring(source.selectionReason or "none"),
        tauntSourceEventId = normalizeEventId(source.tauntSourceEventId),
        tauntRemainingTurns = normalizeCount(source.tauntRemainingTurns),
    }
end

return Selector
