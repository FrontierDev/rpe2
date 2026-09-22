local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client

Client.AutopilotSequencePlanning = Client.AutopilotSequencePlanning or {}
local SequencePlanning = Client.AutopilotSequencePlanning

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end

local function normalizeNonNegative(value)
    return math.max(0, tonumber(value) or 0)
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

local function getSpellEvaluator()
    return Client.AutopilotSpellEvaluator or {}
end

local function getAuraEvaluator()
    return Client.AutopilotAuraEvaluator or {}
end

local function getActionEconomy()
    return Client.AutopilotActionEconomy or {}
end

local function getSpellcasting()
    return Client.Spellcasting or {}
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

local function cloneHealingLedger(ledger)
    local copied = { reservedByEventId = {} }
    for eventId, amount in pairs(type(ledger) == "table" and ledger.reservedByEventId or {}) do
        local numericEventId = normalizeEventId(eventId)
        if numericEventId > 0 then
            copied.reservedByEventId[numericEventId] = normalizeNonNegative(amount)
        end
    end
    return copied
end

function SequencePlanning.CreateTacticalLedger(activeAuraRecords)
    local SpellEvaluator = getSpellEvaluator()
    local AuraEvaluator = getAuraEvaluator()
    return {
        projectedHealingLedger = type(SpellEvaluator.CreateProjectedHealingLedger) == "function"
            and SpellEvaluator.CreateProjectedHealingLedger()
            or { reservedByEventId = {} },
        projectedAuraLedger = type(AuraEvaluator.CreateProjectedAuraLedger) == "function"
            and AuraEvaluator.CreateProjectedAuraLedger(activeAuraRecords)
            or { byAuraRef = {} },
    }
end

function SequencePlanning.CloneTacticalLedger(ledger)
    local AuraEvaluator = getAuraEvaluator()
    local source = type(ledger) == "table" and ledger or {}
    return {
        projectedHealingLedger = cloneHealingLedger(source.projectedHealingLedger),
        projectedAuraLedger = type(AuraEvaluator.CloneProjectedAuraLedger) == "function"
            and AuraEvaluator.CloneProjectedAuraLedger(source.projectedAuraLedger)
            or copyMap(source.projectedAuraLedger),
    }
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

function SequencePlanning.ReevaluateCandidate(candidate, tacticalLedger, context)
    if type(candidate) ~= "table" then
        return nil
    end

    context = type(context) == "table" and context or {}
    local targets = candidateTargets(candidate)
    if #targets == 0 then
        return cloneCandidate(candidate)
    end

    local SpellEvaluator = getSpellEvaluator()
    if type(SpellEvaluator.EvaluateCandidate) ~= "function" then
        return nil
    end

    local activation = candidate.activationSnapshot
    local profile = candidate.planningProfile
    if type(activation) ~= "table" or type(profile) ~= "table" then
        return nil
    end

    local ledger = type(tacticalLedger) == "table" and tacticalLedger or {}
    local damageUtility = 0
    local healingUtility = 0
    local movementControlUtility = 0
    local castingPreventionUtility = 0
    local controlUtility = 0
    local immediateDamage = 0
    local immediateHealing = 0
    local periodicDamage = 0
    local periodicHealing = 0
    local expectedDamage = 0
    local expectedHealing = 0
    local projectedHealingByTargetEventId = {}
    local urgentHealing = false
    local hasUsefulInterrupt = false
    local urgentInterrupt = false
    local interruptTargetEventId = 0
    local interruptRemainingTurns = nil
    local evaluateInterrupt = tostring(candidate.planningIntent or "") == "interrupt"

    for index = 1, #targets do
        local evaluated = SpellEvaluator.EvaluateCandidate(activation, targets[index], {
            projectedHealingLedger = ledger.projectedHealingLedger,
            projectedAuraLedger = ledger.projectedAuraLedger,
            auraDefinitionCache = context.auraDefinitionCache,
            controlStateByTargetEventId = context.controlStateByTargetEventId,
            activeCastsByEventId = context.activeCastsByEventId,
            isHostileTarget = candidate.isHostileTarget == true,
            profile = profile,
        })
        if type(evaluated) == "table" then
            damageUtility = damageUtility + (tonumber(evaluated.damageUtility) or 0)
            healingUtility = healingUtility + (tonumber(evaluated.healingUtility) or 0)
            movementControlUtility = movementControlUtility + (tonumber(evaluated.movementControlUtility) or 0)
            castingPreventionUtility = castingPreventionUtility + (tonumber(evaluated.castingPreventionUtility) or 0)
            controlUtility = controlUtility + (tonumber(evaluated.controlUtility) or 0)
            immediateDamage = immediateDamage + (tonumber(evaluated.immediateDamage) or 0)
            immediateHealing = immediateHealing + (tonumber(evaluated.immediateHealing) or 0)
            periodicDamage = periodicDamage + (tonumber(evaluated.usefulPeriodicDamage) or 0)
            periodicHealing = periodicHealing + (tonumber(evaluated.usefulPeriodicHealing) or 0)
            expectedDamage = expectedDamage + (tonumber(evaluated.expectedDamage) or 0)
            expectedHealing = expectedHealing + (tonumber(evaluated.expectedHealing) or 0)
            local targetEventId = normalizeEventId(targets[index] and targets[index].eventID)
            if targetEventId > 0 then
                projectedHealingByTargetEventId[targetEventId] = normalizeNonNegative(evaluated.healingUtility)
            end
            urgentHealing = urgentHealing or evaluated.urgentHealing == true
            if evaluateInterrupt and evaluated.hasUsefulInterrupt == true and hasUsefulInterrupt ~= true then
                hasUsefulInterrupt = true
                interruptTargetEventId = normalizeEventId(evaluated.interruptTargetEventId)
                interruptRemainingTurns = evaluated.interruptRemainingTurns
            end
            urgentInterrupt = urgentInterrupt or (evaluateInterrupt and evaluated.urgentInterrupt == true)
        end
    end

    local totalUtility = damageUtility + healingUtility + controlUtility
    if totalUtility <= 0 and urgentHealing ~= true and urgentInterrupt ~= true then
        return nil
    end

    local result = cloneCandidate(candidate)
    result.damageUtility = damageUtility
    result.healingUtility = healingUtility
    result.movementControlUtility = movementControlUtility
    result.castingPreventionUtility = castingPreventionUtility
    result.controlUtility = controlUtility
    result.totalUtility = totalUtility
    result.immediateDamage = immediateDamage
    result.immediateHealing = immediateHealing
    result.periodicDamage = periodicDamage
    result.periodicHealing = periodicHealing
    result.expectedDamage = expectedDamage
    result.expectedHealing = expectedHealing
    result.projectedHealingByTargetEventId = projectedHealingByTargetEventId
    result.urgentHealing = urgentHealing
    result.hasUsefulInterrupt = hasUsefulInterrupt
    result.urgentInterrupt = urgentInterrupt
    result.interruptTargetEventId = interruptTargetEventId
    result.interruptRemainingTurns = interruptRemainingTurns
    return result
end

local function buildAvailableResources(unit)
    local available = {}
    for index = 1, #(type(unit) == "table" and unit.resources or {}) do
        local entry = unit.resources[index]
        local resourceRef = type(entry) == "table" and tostring(entry.resourceRef or "") or ""
        if resourceRef ~= "" then
            local current = tonumber(entry.currentValue)
            if current == nil then
                current = tonumber(entry.maxValue) or 0
            end
            available[resourceRef] = normalizeNonNegative(current)
        end
    end
    return available
end

local function appendResolvedCosts(target, costs, result)
    local Spellcasting = getSpellcasting()
    if type(Spellcasting.ResolveSpellResourceCostAmount) ~= "function" then
        return
    end
    for index = 1, #(costs or {}) do
        local cost = costs[index]
        local resourceRef = type(cost) == "table" and tostring(cost.resourceRef or "") or ""
        local amount = Spellcasting.ResolveSpellResourceCostAmount(target, cost)
        if resourceRef ~= "" and normalizeNonNegative(amount) > 0 then
            result[resourceRef] = normalizeNonNegative(result[resourceRef]) + normalizeNonNegative(amount)
        end
    end
end

local function buildResourceCommitments(candidate, protectsFutureActivation)
    local activation = type(candidate) == "table" and candidate.activationSnapshot or nil
    local casterUnit = type(activation) == "table" and activation.casterUnit or nil
    if type(casterUnit) ~= "table" then
        return {}
    end

    local startCommitments = {}
    local endCommitments = {}
    appendResolvedCosts(casterUnit, activation.startCosts or {}, startCommitments)
    appendResolvedCosts(casterUnit, activation.endCosts or {}, endCommitments)

    local result = copyMap(startCommitments)
    for resourceRef, amount in pairs(endCommitments) do
        if protectsFutureActivation == true then
            -- Canonical activation checks start/end affordability separately.
            -- A later channel-triggering or terminal action only needs the
            -- larger phase requirement preserved for live activation;
            -- summing both phases would be stricter than the canonical
            -- BuildSpellActivationSnapshot check.
            result[resourceRef] = math.max(normalizeNonNegative(result[resourceRef]), normalizeNonNegative(amount))
        else
            -- A non-GCD-channel action resolves before the next sequence
            -- action, so both phases are actual prior consumption and must
            -- be reserved.
            result[resourceRef] = normalizeNonNegative(result[resourceRef]) + normalizeNonNegative(amount)
        end
    end
    return result
end

local function buildActionEconomyInput(candidate)
    local ActionEconomy = getActionEconomy()
    local Spellcasting = getSpellcasting()
    local activation = type(candidate) == "table" and candidate.activationSnapshot or nil
    local spell = type(activation) == "table" and activation.spell or nil
    if type(ActionEconomy.CreateInput) ~= "function" or type(activation) ~= "table" or type(spell) ~= "table" then
        return nil
    end

    if type(Spellcasting.ResolvePersistentCastTurns) ~= "function"
        or type(Spellcasting.ResolveSpellCooldownChannel) ~= "function"
        or type(Spellcasting.NormalizeTurnCount) ~= "function"
    then
        return nil
    end

    local persistentCastTurns = Spellcasting.ResolvePersistentCastTurns(spell)
    local cooldownChannelId, cooldownChannel, _, cooldownChannelReason = Spellcasting.ResolveSpellCooldownChannel(spell)
    local cooldownChannelConfigured = type(cooldownChannel) == "table" and cooldownChannel.enabled == true
    local cooldownChannelTriggersGCD = type(cooldownChannel) == "table"
        and cooldownChannel.triggersGCD == true
        or nil
    local cooldownChannelCanUseOffTurn = type(cooldownChannel) == "table"
        and cooldownChannel.enabled == true
        and cooldownChannel.canUseOffTurn == true
        or false
    local cooldownTurns = type(Spellcasting.GetEffectivePersonalCooldownTurns) == "function"
        and Spellcasting.GetEffectivePersonalCooldownTurns(spell)
        or Spellcasting.NormalizeTurnCount(spell.cooldown)
    local cooldownGroup = nil
    if cooldownTurns ~= nil then
        local group = tostring(spell.cooldownGroup or "")
        cooldownGroup = group ~= "" and group or nil
    end

    return ActionEconomy.CreateInput(candidate, {
        activationSnapshot = activation,
        spellRef = candidate.spellRef,
        canCast = activation.canCast == true,
        persistentCastTurns = persistentCastTurns,
        cooldownChannelId = cooldownChannelId,
        cooldownChannelName = type(cooldownChannel) == "table" and cooldownChannel.name or nil,
        cooldownChannelTriggersGCD = cooldownChannelTriggersGCD,
        cooldownChannelCanUseOffTurn = cooldownChannelCanUseOffTurn,
        cooldownChannelConfigured = cooldownChannelConfigured,
        cooldownChannelReason = cooldownChannelConfigured
            and ""
            or tostring(cooldownChannelReason or "invalid-cooldown-channel"),
        cooldownGroup = cooldownGroup,
        resourceCommitments = buildResourceCommitments(
            candidate,
            persistentCastTurns ~= nil or cooldownChannelTriggersGCD == true
        ),
    })
end

function SequencePlanning.BuildSequence(candidates, unit)
    local ActionEconomy = getActionEconomy()
    local SpellEvaluator = getSpellEvaluator()
    if type(ActionEconomy.BuildSequence) ~= "function" then
        return { status = "failed", reason = "action-economy-unavailable", actions = {} }
    end

    local inputs = {}
    for index = 1, #(candidates or {}) do
        local input = buildActionEconomyInput(candidates[index])
        if type(input) == "table" then
            inputs[#inputs + 1] = input
        end
    end

    return ActionEconomy.BuildSequence(inputs, {
        availableResources = buildAvailableResources(unit),
        compareCandidates = SpellEvaluator.CompareCandidates,
    })
end

local function reserveCandidateHealing(ledger, candidate, context)
    local SpellEvaluator = getSpellEvaluator()
    if type(SpellEvaluator.ReserveProjectedHealing) ~= "function" then
        return
    end
    local targets = candidateTargets(candidate)
    local byTarget = type(candidate) == "table" and candidate.projectedHealingByTargetEventId or nil
    local fallbackTotal = normalizeNonNegative(candidate and candidate.healingUtility)
    local fallbackPerTarget = fallbackTotal / math.max(1, #targets)
    for index = 1, #targets do
        local targetEventId = normalizeEventId(targets[index] and targets[index].eventID)
        local amount = type(byTarget) == "table" and normalizeNonNegative(byTarget[targetEventId]) or fallbackPerTarget
        if amount > 0 then
            SpellEvaluator.ReserveProjectedHealing(
                ledger.projectedHealingLedger,
                targets[index],
                context.eventState,
                amount
            )
        end
    end
end

local function reserveCandidateAuras(ledger, candidate, context)
    local AuraEvaluator = getAuraEvaluator()
    if type(AuraEvaluator.ReserveProjectedAura) ~= "function" then
        return
    end
    local casterEventId = normalizeEventId(candidate and candidate.casterEventId)
    if casterEventId <= 0 then
        return
    end
    local nextAuraLedger = ledger.projectedAuraLedger
    local targets = candidateTargets(candidate)
    for applicationIndex = 1, #(candidate and candidate.auraApplications or {}) do
        local application = candidate.auraApplications[applicationIndex]
        for targetIndex = 1, #targets do
            local targetEventId = normalizeEventId(targets[targetIndex] and targets[targetIndex].eventID)
            if targetEventId > 0 then
                local nextLedger = AuraEvaluator.ReserveProjectedAura(
                    nextAuraLedger,
                    application,
                    casterEventId,
                    targetEventId,
                    {
                        datasetId = application and application.datasetId,
                        auraDefinitionCache = context.auraDefinitionCache,
                    },
                    context.auraDefinitionCache
                )
                if type(nextLedger) == "table" then
                    nextAuraLedger = nextLedger
                end
            end
        end
    end
    ledger.projectedAuraLedger = nextAuraLedger
end

function SequencePlanning.ReserveSequence(tacticalLedger, sequence, context)
    context = type(context) == "table" and context or {}
    local ledger = SequencePlanning.CloneTacticalLedger(tacticalLedger)
    for index = 1, #(type(sequence) == "table" and sequence.actions or {}) do
        local entry = sequence.actions[index]
        local candidate = type(entry) == "table" and entry.candidate or nil
        if type(candidate) == "table" then
            reserveCandidateHealing(ledger, candidate, context)
            reserveCandidateAuras(ledger, candidate, context)
        end
    end
    return ledger
end

function SequencePlanning.SummarizeSequence(sequence)
    local summary = {
        sequenceUtility = 0,
        hasUsefulAction = false,
        urgentHealingCount = 0,
        urgentInterruptCount = 0,
    }
    for index = 1, #(type(sequence) == "table" and sequence.actions or {}) do
        local entry = sequence.actions[index]
        local candidate = type(entry) == "table" and entry.candidate or nil
        if type(candidate) == "table" then
            summary.hasUsefulAction = true
            summary.sequenceUtility = summary.sequenceUtility + normalizeNonNegative(candidate.totalUtility)
            if candidate.urgentHealing == true then
                summary.urgentHealingCount = summary.urgentHealingCount + 1
            end
            if candidate.urgentInterrupt == true then
                summary.urgentInterruptCount = summary.urgentInterruptCount + 1
            end
        end
    end
    summary.urgentHealing = summary.urgentHealingCount > 0
    summary.urgentInterrupt = summary.urgentInterruptCount > 0
    return summary
end

return SequencePlanning
