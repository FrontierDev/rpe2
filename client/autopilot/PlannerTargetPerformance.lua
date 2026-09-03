local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Planner = Client.AutopilotPlanner or {}
local SpellEvaluator = Client.AutopilotSpellEvaluator or {}
local SequencePlanning = Client.AutopilotSequencePlanning or {}
local TargetSelector = Client.AutopilotTargetSelector or {}
local MovementSolver = Client.AutopilotMovementSolver or {}
local Spatial = Client.AutopilotSpatial or {}
local Tasks = Addon.Internal.Tasks or {}
local EPSILON = 0.0001

if type(Planner) ~= "table" or Planner._performanceTargetEvaluationInstalled == true then return end
if type(SequencePlanning.CreateCandidateReevaluationState) ~= "function" then return end

Planner.Performance = Planner.Performance or {}
local Performance = Planner.Performance

local function shouldYield(deadlineMs)
    return type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true
end
local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end
local function normalizeNonNegative(value) return math.max(0, tonumber(value) or 0) end
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
local function copyPosition(position)
    if type(Spatial.CopyPosition) == "function" then return Spatial.CopyPosition(position) end
    return type(position) == "table" and copyMap(position) or nil
end
local function getIntentList(profile)
    local intents = {}
    if type(profile) == "table" and profile.hasHeal == true then intents[#intents+1] = "healing" end
    if type(profile) == "table" and (profile.hasDamage == true or profile.hasControl == true) then intents[#intents+1] = "hostile" end
    if type(profile) == "table" and profile.hasInterrupt == true then intents[#intents+1] = "interrupt" end
    return intents
end
local function candidateTargets(candidate)
    if type(candidate) ~= "table" then return {} end
    if type(candidate.targetUnits) == "table" then return candidate.targetUnits end
    local target = candidate.targetUnit or candidate.primaryTargetUnit
    return type(target) == "table" and {target} or {}
end
local function candidateRequiresMelee(candidate)
    if type(candidate) ~= "table" then return false end
    if candidate.requiresMeleePosition == true then return true end
    return type(candidate.damageTypes) == "table" and candidate.damageTypes.melee == true
        and normalizeNonNegative(candidate.damageUtility or candidate.expectedDamage) > 0
end

local function createTargetCandidateBuildState(state, activation, profile, selection, intent)
    if type(profile) ~= "table" or type(selection) ~= "table" or selection.meetsMinTargets ~= true then
        return { complete = true, result = nil }
    end
    local targets = selection.targetUnits or {}
    local isHostileTarget = type(selection.policy) == "table"
        and tostring(selection.policy.targetDisposition or "") == "enemy"
    if #targets == 0 then
        local utility = intent == "damage" and (tonumber(profile.expectedDamage) or 0) or 0
        if utility <= 0 then
            return { complete = true, result = nil }
        end
        return {
            complete = true,
            result = {
                spellRef = profile.spellRef,
                casterEventId = profile.casterEventId,
                targetUnits = {},
                targetEventIds = {},
                targetGroupKey = selection.targetGroupKey,
                planningIntent = intent,
                planningProfile = profile,
                isHostileTarget = isHostileTarget,
                hasDamage = profile.hasDamage,
                hasHeal = profile.hasHeal,
                hasControl = profile.hasControl == true,
                hasInterrupt = profile.hasInterrupt == true,
                hasPeriodicDamage = profile.hasPeriodicDamage == true,
                hasPeriodicHealing = profile.hasPeriodicHealing == true,
                auraApplications = profile.auraApplications,
                appliedAuras = profile.appliedAuras,
                hasAuraApplication = profile.hasAuraApplication == true,
                damageTypes = profile.damageTypes,
                damageTypeList = profile.damageTypeList,
                immediateDamage = tonumber(profile.immediateDamage) or 0,
                periodicDamage = 0,
                immediateHealing = tonumber(profile.immediateHealing) or 0,
                periodicHealing = 0,
                expectedDamage = profile.expectedDamage,
                expectedHealing = profile.expectedHealing,
                damageUtility = utility,
                healingUtility = 0,
                movementControlUtility = 0,
                castingPreventionUtility = 0,
                controlUtility = 0,
                totalUtility = utility,
                urgentHealing = false,
                hasUsefulInterrupt = false,
                urgentInterrupt = false,
                interruptTargetEventId = 0,
                interruptRemainingTurns = nil,
                resourceBurden = profile.resourceBurden,
                cooldownCommitment = profile.cooldownCommitment,
                chargeCommitment = profile.chargeCommitment,
                activationSnapshot = activation,
            },
        }
    end

    return {
        activation = activation,
        profile = profile,
        selection = selection,
        intent = intent,
        targets = targets,
        targetIndex = 1,
        isHostileTarget = isHostileTarget,
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
        urgentHealing = false,
        hasUsefulInterrupt = false,
        urgentInterrupt = false,
        interruptTargetEventId = 0,
        interruptRemainingTurns = nil,
        targetEventIds = {},
        evaluateInterrupt = intent == "interrupt",
        complete = false,
        result = nil,
    }
end

local function finalizeTargetCandidate(build)
    local totalUtility = build.damageUtility + build.healingUtility + build.controlUtility
    if totalUtility <= 0 and build.urgentHealing ~= true and build.urgentInterrupt ~= true then
        build.result = nil
        build.complete = true
        return
    end
    local profile = build.profile
    local targets = build.targets
    build.result = {
        spellRef = profile.spellRef,
        casterEventId = profile.casterEventId,
        targetUnits = copyArray(targets),
        targetEventIds = build.targetEventIds,
        targetUnit = targets[1],
        primaryTargetUnit = targets[1],
        targetEventId = build.targetEventIds[1],
        targetGroupKey = build.selection.targetGroupKey,
        planningIntent = build.intent,
        planningProfile = profile,
        isHostileTarget = build.isHostileTarget,
        hasDamage = profile.hasDamage,
        hasHeal = profile.hasHeal,
        hasControl = profile.hasControl == true,
        hasInterrupt = profile.hasInterrupt == true,
        hasPeriodicDamage = profile.hasPeriodicDamage == true,
        hasPeriodicHealing = profile.hasPeriodicHealing == true,
        auraApplications = profile.auraApplications,
        appliedAuras = profile.appliedAuras,
        hasAuraApplication = profile.hasAuraApplication == true,
        damageTypes = profile.damageTypes,
        damageTypeList = profile.damageTypeList,
        immediateDamage = build.immediateDamage,
        periodicDamage = build.periodicDamage,
        immediateHealing = build.immediateHealing,
        periodicHealing = build.periodicHealing,
        expectedDamage = build.expectedDamage,
        expectedHealing = build.expectedHealing,
        damageUtility = build.damageUtility,
        healingUtility = build.healingUtility,
        movementControlUtility = build.movementControlUtility,
        castingPreventionUtility = build.castingPreventionUtility,
        controlUtility = build.controlUtility,
        totalUtility = totalUtility,
        urgentHealing = build.urgentHealing,
        hasUsefulInterrupt = build.hasUsefulInterrupt,
        urgentInterrupt = build.urgentInterrupt,
        interruptTargetEventId = build.interruptTargetEventId,
        interruptRemainingTurns = build.interruptRemainingTurns,
        resourceBurden = profile.resourceBurden,
        cooldownCommitment = profile.cooldownCommitment,
        chargeCommitment = profile.chargeCommitment,
        activationSnapshot = build.activation,
    }
    build.complete = true
end

local function stepTargetCandidateBuild(state, build, deadlineMs)
    if build.complete == true then
        return true
    end
    if shouldYield(deadlineMs) then
        return false
    end
    while build.targetIndex <= #build.targets do
        local target = build.targets[build.targetIndex]
        local evaluated = SpellEvaluator.EvaluateCandidate(build.activation, target, {
            projectedHealingLedger = state.scratch.projectedHealingLedger,
            projectedAuraLedger = state.scratch.projectedAuraLedger,
            auraDefinitionCache = state.scratch.auraDefinitionCache,
            controlStateByTargetEventId = state.snapshot.controlStateByTargetEventId,
            activeCastsByEventId = state.snapshot.activeCastsByEventId,
            isHostileTarget = build.isHostileTarget,
            profile = build.profile,
        })
        if type(evaluated) == "table" then
            build.damageUtility = build.damageUtility + (tonumber(evaluated.damageUtility) or 0)
            build.healingUtility = build.healingUtility + (tonumber(evaluated.healingUtility) or 0)
            build.movementControlUtility = build.movementControlUtility + (tonumber(evaluated.movementControlUtility) or 0)
            build.castingPreventionUtility = build.castingPreventionUtility + (tonumber(evaluated.castingPreventionUtility) or 0)
            build.controlUtility = build.controlUtility + (tonumber(evaluated.controlUtility) or 0)
            build.immediateDamage = build.immediateDamage + (tonumber(evaluated.immediateDamage) or 0)
            build.immediateHealing = build.immediateHealing + (tonumber(evaluated.immediateHealing) or 0)
            build.periodicDamage = build.periodicDamage + (tonumber(evaluated.usefulPeriodicDamage) or 0)
            build.periodicHealing = build.periodicHealing + (tonumber(evaluated.usefulPeriodicHealing) or 0)
            build.expectedDamage = build.expectedDamage + (tonumber(evaluated.expectedDamage) or 0)
            build.expectedHealing = build.expectedHealing + (tonumber(evaluated.expectedHealing) or 0)
            build.urgentHealing = build.urgentHealing or evaluated.urgentHealing == true
            if build.evaluateInterrupt and evaluated.hasUsefulInterrupt == true and build.hasUsefulInterrupt ~= true then
                build.hasUsefulInterrupt = true
                build.interruptTargetEventId = normalizeEventId(evaluated.interruptTargetEventId)
                build.interruptRemainingTurns = evaluated.interruptRemainingTurns
            end
            build.urgentInterrupt = build.urgentInterrupt or (build.evaluateInterrupt and evaluated.urgentInterrupt == true)
            local targetId = normalizeEventId(target and target.eventID)
            if targetId > 0 then
                state.scratch.healthByEventId[targetId] = evaluated.targetHealth or state.scratch.healthByEventId[targetId]
            end
        end
        build.targetEventIds[build.targetIndex] = normalizeEventId(target and target.eventID)
        build.targetIndex = build.targetIndex + 1
        if shouldYield(deadlineMs) then
            return false
        end
    end
    finalizeTargetCandidate(build)
    return true
end

local function phaseTargetsBounded(state, deadlineMs)
    while state.cursors.member <= #state.snapshot.actorMembers do
        local entry = state.snapshot.actorMembers[state.cursors.member]
        local unit = entry.unit
        local eventId = normalizeEventId(unit and unit.eventID)
        local spellRefs = state.snapshot.spellRefsByEventId[eventId] or {}
        if state.cursors.spell > #spellRefs then
            state.cursors.member = state.cursors.member + 1
            state.cursors.spell = 1
            state.cursors.intent = 1
        else
            local spellRef = tostring(spellRefs[state.cursors.spell] or "")
            local cacheKey = tostring(eventId) .. "\31" .. spellRef
            local activation = state.scratch.activationByKey[cacheKey]
            local profile = state.scratch.profileByKey[cacheKey]
            if type(activation) ~= "table" or activation.canCast ~= true or type(profile) ~= "table" then
                state.cursors.spell = state.cursors.spell + 1
                state.cursors.intent = 1
            else
                local intents = getIntentList(profile)
                if state.cursors.intent > #intents then
                    state.cursors.spell = state.cursors.spell + 1
                    state.cursors.intent = 1
                else
                    local intent = intents[state.cursors.intent]
                    local selectionKey = table.concat({ eventId, spellRef, intent }, "\31")
                    local selectionState = state.scratch.targetSelectionByKey[selectionKey]
                    if type(selectionState) ~= "table" then
                        selectionState = type(TargetSelector.CreateState) == "function"
                            and select(1, TargetSelector.CreateState(activation, {
                                intent = intent,
                                spatialRuntime = state.snapshot.spatialRuntime,
                                projectedHealingLedger = state.scratch.projectedHealingLedger,
                                activeCastsByEventId = state.snapshot.activeCastsByEventId,
                            }))
                            or nil
                        state.scratch.targetSelectionByKey[selectionKey] = selectionState or false
                    end
                    if type(selectionState) ~= "table" then
                        state.cursors.intent = state.cursors.intent + 1
                    else
                        local selection = state.scratch.targetOrderByKey[selectionKey]
                        if type(selection) ~= "table" then
                            local complete = TargetSelector.Step(selectionState, deadlineMs) == true
                            if not complete then
                                return false
                            end
                            selection = type(TargetSelector.CopyResult) == "function"
                                and TargetSelector.CopyResult(selectionState)
                                or nil
                            state.scratch.targetOrderByKey[selectionKey] = selection or false
                        end

                        local candidateIntent = intent == "hostile" and "damage"
                            or intent == "interrupt" and "interrupt"
                            or "heal"
                        local buildKey = selectionKey .. "\31candidate"
                        local build = state.scratch.performanceCandidateBuild
                        if type(build) ~= "table" or state.scratch.performanceCandidateBuildKey ~= buildKey then
                            build = createTargetCandidateBuildState(
                                state,
                                activation,
                                profile,
                                selection,
                                candidateIntent
                            )
                            state.scratch.performanceCandidateBuild = build
                            state.scratch.performanceCandidateBuildKey = buildKey
                        end
                        if stepTargetCandidateBuild(state, build, deadlineMs) ~= true then
                            return false
                        end
                        local candidate = build.result
                        if type(candidate) == "table" then
                            local bucket = state.scratch.actionCandidatesByEventId[eventId]
                            if type(bucket) ~= "table" then
                                bucket = {}
                                state.scratch.actionCandidatesByEventId[eventId] = bucket
                            end
                            bucket[#bucket + 1] = candidate
                            state.metrics.actionCandidateCount = (tonumber(state.metrics.actionCandidateCount) or 0) + 1
                        end
                        state.scratch.performanceCandidateBuild = nil
                        state.scratch.performanceCandidateBuildKey = nil
                        state.cursors.intent = state.cursors.intent + 1
                    end
                    if shouldYield(deadlineMs) then
                        return false
                    end
                end
            end
        end
    end
    state.phase = "solve-actors"
    state.cursors.actor = 1
    return false
end


Performance.StepTargets = phaseTargetsBounded
Planner._performanceTargetEvaluationInstalled = true
return Performance
