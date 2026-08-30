local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Tasks = Addon.Internal.Tasks or {}
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

local function normalizeIntent(value)
    local intent = tostring(value or "")
    if intent == "heal" or intent == "healing" then
        return "healing"
    end
    if intent == "damage" or intent == "hostile" then
        return "hostile"
    end
    return nil
end

local function normalizePolicy(policy)
    local source = type(policy) == "table" and policy or {}
    local minTargets = normalizeCount(source.minTargets)
    local maxTargets = normalizeCount(source.maxTargets)
    if maxTargets < minTargets then
        maxTargets = minTargets
    end

    return {
        type = tostring(source.type or "single"),
        requiresTarget = source.requiresTarget == true,
        targetDisposition = tostring(source.targetDisposition or "enemy"),
        minTargets = minTargets,
        maxTargets = maxTargets,
        allowDeadTargets = source.allowDeadTargets == true,
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
    end
    return true
end

local function buildResult(state)
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
    if state.phase == "select-secondary" then
        return compareHostileSecondary(left, right)
    end
    return compareHostilePrimary(left, right)
end

local function completeSelectionPass(state)
    local bestIndex = state.bestEntryIndex
    state.selectionScanIndex = 1
    state.bestEntryIndex = nil
    if not bestIndex then
        state.result = buildResult(state)
        state.phase = "complete"
        return true
    end

    local bestEntry = state.entries[bestIndex]
    if state.kind == "healing"
        and #state.selectedEntries >= state.minTargets
        and not isOptionalHealingTargetUseful(bestEntry)
    then
        state.result = buildResult(state)
        state.phase = "complete"
        return true
    end

    markSelected(state, bestIndex)
    if #state.selectedEntries >= state.maxTargets then
        state.result = buildResult(state)
        state.phase = "complete"
        return true
    end

    if state.kind == "hostile" and #state.selectedEntries == 1 and state.maxTargets > 1 then
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

    local state = {
        activationSnapshot = activationSnapshot,
        eventState = activationSnapshot.eventState,
        casterUnit = activationSnapshot.casterUnit,
        spatialRuntime = options.spatialRuntime,
        projectedHealingLedger = options.projectedHealingLedger,
        kind = kind,
        targetGroupKey = groupKey,
        policy = policy,
        minTargets = policy.minTargets,
        maxTargets = policy.maxTargets,
        candidates = candidates,
        candidateIndex = 1,
        entries = {},
        selectedEntries = {},
        selectedByEventId = {},
        selectionScanIndex = 1,
        bestEntryIndex = nil,
        secondaryPrepareIndex = 1,
        primaryEntry = nil,
        phase = "scan",
        result = nil,
    }

    if state.maxTargets <= 0 then
        state.result = buildResult(state)
        state.phase = "complete"
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
                local entry = state.kind == "healing"
                    and buildHealingEntry(state, targetUnit)
                    or buildHostileEntry(state, targetUnit)
                if entry.eventId > 0 then
                    state.entries[#state.entries + 1] = entry
                end
                state.candidateIndex = state.candidateIndex + 1
                if shouldYield(deadlineMs) then
                    return false
                end
            end

            resetSelectionScan(state, "select")
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
        elseif state.phase == "select" or state.phase == "select-secondary" then
            while state.selectionScanIndex <= #(state.entries or {}) do
                local entryIndex = state.selectionScanIndex
                local entry = state.entries[entryIndex]
                local eventId = normalizeEventId(entry and entry.eventId)
                if eventId > 0 and state.selectedByEventId[eventId] ~= true then
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
    }
end

return Selector
