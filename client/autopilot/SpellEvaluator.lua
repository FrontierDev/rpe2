local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Common = Addon.Utils.Common or {}
local Lookup = Addon.Utils.Lookup or {}

Client.AutopilotSpellEvaluator = Client.AutopilotSpellEvaluator or {}
local Evaluator = Client.AutopilotSpellEvaluator

Evaluator.URGENT_HEALTH_FRACTION = 0.50
Evaluator.MOVEMENT_CONTROL_UTILITY_CAP = 10
Evaluator.FRAGILE_CONTROL_MULTIPLIER = 0.5
Evaluator.CASTING_PREVENTION_UTILITY = 8

local function normalizeNonNegative(value)
    return math.max(0, tonumber(value) or 0)
end

local function roundNonNegative(value)
    local numericValue = normalizeNonNegative(value)
    if type(Common.Round) == "function" then
        return math.max(0, tonumber(Common.Round(numericValue)) or 0)
    end
    return math.max(0, math.floor(numericValue + 0.5))
end

local function normalizeDamageType(value)
    local damageType = tostring(value or "spell")
    if damageType == "melee" or damageType == "ranged" then
        return damageType
    end
    return "spell"
end

local function getCombat()
    return Addon.Client and Addon.Client.Combat or nil
end

local function getSpellcasting()
    return Addon.Client and Addon.Client.Spellcasting or nil
end

local function getAuraEvaluator()
    return Addon.Client and Addon.Client.AutopilotAuraEvaluator or nil
end

local function getStatValue(unit, statRef)
    if type(unit) ~= "table" or type(statRef) ~= "string" or statRef == "" then
        return 0
    end
    return tonumber(Lookup.GetStatValue and Lookup.GetStatValue(unit, statRef, 0) or 0) or 0
end

local function resolveStatScaling(unit, effect)
    local total = 0
    for index = 1, #(effect and effect.statScaling or {}) do
        local entry = effect.statScaling[index]
        if type(entry) == "table" and type(entry.statRef) == "string" and entry.statRef ~= "" then
            total = total + (getStatValue(unit, entry.statRef) * (tonumber(entry.coefficient) or 0))
        end
    end
    return total
end

local function resolveItemAverageDamage(item)
    if type(item) ~= "table" then
        return 0
    end

    if tostring(item.damageMode or "fixed") == "range" then
        local minimum = math.floor(tonumber(item.minDamagePerTurn) or 0)
        local maximum = math.floor(tonumber(item.maxDamagePerTurn) or 0)
        if maximum < minimum then
            maximum = minimum
        end
        return math.max(0, (minimum + maximum) / 2)
    end

    return math.max(0, tonumber(item.damagePerTurn) or 0)
end

local function resolveWeaponAverageDamage(casterUnit, effect)
    local weaponDamageMode = tostring(effect and effect.weaponDamageMode or "none")
    if weaponDamageMode == "none" or type(casterUnit) ~= "table" then
        return 0
    end

    local combat = getCombat()
    if type(combat) ~= "table" then
        return 0
    end

    local attackType = normalizeDamageType(effect and effect.damageType)
    if type(combat.ResolveHitCheckAttackType) == "function" then
        attackType = tostring(combat:ResolveHitCheckAttackType(effect) or attackType)
    end

    local total = 0
    local function appendSlot(slotKey, fallbackField)
        local itemRef = type(combat.ResolveWeaponItemRef) == "function"
            and combat:ResolveWeaponItemRef(casterUnit, slotKey, fallbackField)
            or casterUnit[fallbackField]
        if type(itemRef) ~= "string" or itemRef == "" then
            return
        end

        local item = type(combat.ResolveItemDefinition) == "function"
            and select(1, combat:ResolveItemDefinition(itemRef))
            or nil
        total = total + resolveItemAverageDamage(item)
    end

    local primarySlotKey = attackType == "ranged" and "ranged" or "mainhand"
    local primaryField = attackType == "ranged" and "rangedWeapon" or "mainHandWeapon"
    if weaponDamageMode == "main_hand" or weaponDamageMode == "both" then
        appendSlot(primarySlotKey, primaryField)
    end
    if weaponDamageMode == "off_hand" or weaponDamageMode == "both" then
        appendSlot("offhand", "offHandWeapon")
    end

    return math.max(0, total)
end

function Evaluator.ResolveExpectedDamage(casterUnit, effect)
    if type(effect) ~= "table" or tostring(effect.type or "") ~= "damage" then
        return 0
    end

    local baseDamage = tonumber(effect.baseDamage) or 0
    local weaponDamage = resolveWeaponAverageDamage(casterUnit, effect)
    local weaponCoefficient = tonumber(effect.weaponDamageCoefficient) or 1
    local statScaling = resolveStatScaling(casterUnit, effect)
    return roundNonNegative(baseDamage + (weaponDamage * weaponCoefficient) + statScaling)
end

function Evaluator.ResolveExpectedHealing(casterUnit, effect)
    if type(effect) ~= "table" or tostring(effect.type or "") ~= "heal" then
        return 0
    end

    local baseHealing = tonumber(effect.baseHealing) or 0
    local statScaling = resolveStatScaling(casterUnit, effect)
    return roundNonNegative(baseHealing + statScaling)
end

function Evaluator.ClassifySpell(spell)
    local result = {
        hasDamage = false,
        hasHeal = false,
        hasInterrupt = false,
        damageTypes = {},
        damageTypeList = {},
        damageComponentCount = 0,
        healComponentCount = 0,
        interruptComponentCount = 0,
    }

    for index = 1, #(spell and spell.components or {}) do
        local component = spell.components[index]
        local effect = type(component) == "table" and component.effect or nil
        local effectType = tostring(type(effect) == "table" and effect.type or "")
        if effectType == "damage" then
            result.hasDamage = true
            result.damageComponentCount = result.damageComponentCount + 1
            result.damageTypes[normalizeDamageType(effect.damageType)] = true
        elseif effectType == "heal" then
            result.hasHeal = true
            result.healComponentCount = result.healComponentCount + 1
        elseif effectType == "interrupt" then
            result.hasInterrupt = true
            result.interruptComponentCount = result.interruptComponentCount + 1
        end
    end

    local stableDamageTypeOrder = { "melee", "ranged", "spell" }
    for index = 1, #stableDamageTypeOrder do
        local damageType = stableDamageTypeOrder[index]
        if result.damageTypes[damageType] == true then
            result.damageTypeList[#result.damageTypeList + 1] = damageType
        end
    end

    return result
end

local function resolveResourceBurden(casterUnit, spell, eventState)
    local spellcasting = getSpellcasting()
    local total = 0

    for index = 1, #(spell and spell.resourceCosts or {}) do
        local cost = spell.resourceCosts[index]
        local amount = nil
        if type(spellcasting) == "table" and type(spellcasting.ResolveSpellResourceCostAmount) == "function" then
            amount = spellcasting.ResolveSpellResourceCostAmount(casterUnit, cost, {
                eventState = eventState,
            })
        end
        total = total + normalizeNonNegative(amount ~= nil and amount or (cost and cost.amount))
    end

    return total
end

local function resolveCooldownCommitment(spell)
    return normalizeNonNegative(spell and spell.cooldown)
end

local function resolveChargeCommitment(snapshot, spell)
    if type(spell) ~= "table" or spell.useCooldownCharges ~= true then
        return 0
    end

    local currentCharges = tonumber(snapshot and snapshot.currentCharges)
    local maxCharges = tonumber(snapshot and snapshot.maxCharges) or tonumber(spell.charges)
    if currentCharges and currentCharges > 0 then
        return 1 / currentCharges
    end
    if maxCharges and maxCharges > 0 then
        return 1 / maxCharges
    end
    return 1
end

local function buildDamageTypeList(damageTypes)
    local list = {}
    local stableDamageTypeOrder = { "melee", "ranged", "spell" }
    for index = 1, #stableDamageTypeOrder do
        local damageType = stableDamageTypeOrder[index]
        if type(damageTypes) == "table" and damageTypes[damageType] == true then
            list[#list + 1] = damageType
        end
    end
    return list
end

local function isSupportedControl(control)
    return type(control) == "table"
        and (control.movementRangeOverride ~= nil or control.preventCasting == true)
end

function Evaluator.BuildSpellProfile(activationSnapshot, options)
    if type(activationSnapshot) ~= "table" or activationSnapshot.canCast ~= true then
        return nil
    end

    options = type(options) == "table" and options or {}

    local spell = activationSnapshot.spell
    local casterUnit = activationSnapshot.casterUnit
    if type(spell) ~= "table" or type(casterUnit) ~= "table" then
        return nil
    end

    local classification = Evaluator.ClassifySpell(spell)
    local immediateDamage = 0
    local immediateHealing = 0

    for index = 1, #(spell.components or {}) do
        local component = spell.components[index]
        local effect = type(component) == "table" and component.effect or nil
        local effectType = tostring(type(effect) == "table" and effect.type or "")
        if effectType == "damage" then
            immediateDamage = immediateDamage + Evaluator.ResolveExpectedDamage(casterUnit, effect)
        elseif effectType == "heal" then
            immediateHealing = immediateHealing + Evaluator.ResolveExpectedHealing(casterUnit, effect)
        end
    end

    local auraApplications = {}
    local auraEvaluator = getAuraEvaluator()
    if type(auraEvaluator) == "table" and type(auraEvaluator.CollectSpellAuraApplications) == "function" then
        auraApplications = auraEvaluator.CollectSpellAuraApplications(spell, {
            dataset = activationSnapshot.dataset,
            datasetId = activationSnapshot.datasetId
                or (activationSnapshot.dataset and activationSnapshot.dataset.id)
                or activationSnapshot.spellDatasetId,
            spellDatasetId = activationSnapshot.spellDatasetId
                or (activationSnapshot.dataset and activationSnapshot.dataset.id),
        }, options.auraDefinitionCache)
    end

    local hasPeriodicDamage = false
    local hasPeriodicHealing = false
    local hasControl = false
    local controlApplications = {}
    for index = 1, #auraApplications do
        local application = auraApplications[index]
        local auraProfile = application and application.profile or nil
        hasPeriodicDamage = hasPeriodicDamage or (type(auraProfile) == "table" and auraProfile.hasPeriodicDamage == true)
        hasPeriodicHealing = hasPeriodicHealing or (type(auraProfile) == "table" and auraProfile.hasPeriodicHealing == true)
        local control = type(auraProfile) == "table" and auraProfile.control or nil
        if isSupportedControl(control) then
            hasControl = true
            controlApplications[#controlApplications + 1] = application
        end
    end

    local damageTypes = {}
    for key, value in pairs(classification.damageTypes or {}) do
        damageTypes[key] = value
    end
    if hasPeriodicDamage then
        -- Periodic Aura damage is not a melee movement requirement. Treating it
        -- as spell damage allows pure DoTs to use the existing hostile intent.
        damageTypes.spell = true
    end

    return {
        spellRef = tostring(activationSnapshot.spellRef or ""),
        spell = spell,
        casterUnit = casterUnit,
        casterEventId = tonumber(casterUnit.eventID) or 0,
        eventState = activationSnapshot.eventState,
        hasDamage = classification.hasDamage or hasPeriodicDamage,
        hasHeal = classification.hasHeal or hasPeriodicHealing,
        hasInterrupt = classification.hasInterrupt == true,
        hasControl = hasControl,
        hasImmediateDamage = classification.hasDamage,
        hasImmediateHeal = classification.hasHeal,
        hasPeriodicDamage = hasPeriodicDamage,
        hasPeriodicHealing = hasPeriodicHealing,
        damageTypes = damageTypes,
        damageTypeList = buildDamageTypeList(damageTypes),
        damageComponentCount = classification.damageComponentCount,
        healComponentCount = classification.healComponentCount,
        interruptComponentCount = classification.interruptComponentCount,
        immediateDamage = immediateDamage,
        immediateHealing = immediateHealing,
        periodicDamage = 0,
        periodicHealing = 0,
        -- Profile-level compatibility fields remain immediate-only because
        -- periodic value is target- and existing-Aura-state-dependent.
        expectedDamage = immediateDamage,
        expectedHealing = immediateHealing,
        auraApplications = auraApplications,
        appliedAuras = auraApplications,
        hasAuraApplication = #auraApplications > 0,
        controlApplications = controlApplications,
        activeAurasByTargetEventId = options.activeAurasByTargetEventId,
        controlStateByTargetEventId = options.controlStateByTargetEventId,
        activeCastsByEventId = options.activeCastsByEventId,
        resourceBurden = resolveResourceBurden(casterUnit, spell, activationSnapshot.eventState),
        cooldownCommitment = resolveCooldownCommitment(spell),
        chargeCommitment = resolveChargeCommitment(activationSnapshot, spell),
    }
end

function Evaluator.CreateProjectedHealingLedger()
    return {
        reservedByEventId = {},
    }
end

local function getHealthEntry(targetUnit, eventState)
    local combat = getCombat()
    if type(combat) == "table" and type(combat.GetUnitHealthEntry) == "function" then
        local entry = combat:GetUnitHealthEntry(targetUnit, { eventState = eventState })
        if type(entry) == "table" then
            return entry
        end
    end

    local healthResourceRef = type(eventState) == "table" and eventState.healthResourceRef or nil
    if type(healthResourceRef) == "string" and healthResourceRef ~= "" and type(Lookup.GetResourceEntry) == "function" then
        return Lookup.GetResourceEntry(targetUnit, healthResourceRef)
    end

    return nil
end

function Evaluator.ResolveProjectedHealth(targetUnit, eventState, ledger)
    local entry = getHealthEntry(targetUnit, eventState)
    if type(entry) ~= "table" then
        return nil
    end

    local currentValue = tonumber(entry.currentValue)
    local maxValue = tonumber(entry.maxValue)
    if currentValue == nil then
        currentValue = maxValue
    end
    if maxValue == nil then
        maxValue = currentValue
    end
    currentValue = tonumber(currentValue)
    maxValue = tonumber(maxValue)
    if currentValue == nil or maxValue == nil or maxValue <= 0 then
        return nil
    end

    currentValue = math.max(0, math.min(maxValue, currentValue))
    local targetEventId = math.floor(tonumber(targetUnit and targetUnit.eventID) or 0)
    local reserved = 0
    if targetEventId > 0 and type(ledger) == "table" and type(ledger.reservedByEventId) == "table" then
        reserved = normalizeNonNegative(ledger.reservedByEventId[targetEventId])
    end

    local projectedCurrent = math.min(maxValue, currentValue + reserved)
    return {
        targetEventId = targetEventId,
        currentValue = currentValue,
        maxValue = maxValue,
        healthFraction = currentValue / maxValue,
        missingHealth = math.max(0, maxValue - currentValue),
        reservedHealing = reserved,
        projectedCurrentValue = projectedCurrent,
        projectedHealthFraction = projectedCurrent / maxValue,
        projectedMissingHealth = math.max(0, maxValue - projectedCurrent),
        isLiving = currentValue > 0,
    }
end

function Evaluator.ReserveProjectedHealing(ledger, targetUnit, eventState, expectedHealing)
    if type(ledger) ~= "table" then
        return 0
    end
    ledger.reservedByEventId = type(ledger.reservedByEventId) == "table" and ledger.reservedByEventId or {}

    local health = Evaluator.ResolveProjectedHealth(targetUnit, eventState, ledger)
    if type(health) ~= "table" or health.isLiving ~= true or health.targetEventId <= 0 then
        return 0
    end

    local effectiveHealing = math.min(normalizeNonNegative(expectedHealing), health.projectedMissingHealth)
    if effectiveHealing <= 0 then
        return 0
    end

    ledger.reservedByEventId[health.targetEventId] = health.reservedHealing + effectiveHealing
    return effectiveHealing
end

local function resolvePeriodicApplicationUtility(profile, targetUnit, options)
    local auraEvaluator = getAuraEvaluator()
    if type(auraEvaluator) ~= "table"
        or type(auraEvaluator.CreateProjectedAuraLedger) ~= "function"
        or type(auraEvaluator.EvaluateProjectedAuraApplication) ~= "function"
    then
        return 0, 0, nil
    end

    local targetEventId = math.floor(tonumber(targetUnit and targetUnit.eventID) or 0)
    local recordsByTarget = options.activeAurasByTargetEventId
        or profile.activeAurasByTargetEventId
        or {}
    local activeAuraRecords = targetEventId > 0 and recordsByTarget[targetEventId] or nil
    if type(options.activeAuraRecords) == "table" then
        activeAuraRecords = options.activeAuraRecords
    end

    local ledger = type(options.projectedAuraLedger) == "table"
        and auraEvaluator.CloneProjectedAuraLedger(options.projectedAuraLedger)
        or auraEvaluator.CreateProjectedAuraLedger(activeAuraRecords)
    local periodicDamage = 0
    local periodicHealing = 0

    for index = 1, #(profile.auraApplications or {}) do
        local application = profile.auraApplications[index]
        local projection = auraEvaluator.EvaluateProjectedAuraApplication(
            ledger,
            application,
            profile.casterUnit,
            targetUnit,
            {
                datasetId = application and application.datasetId,
                auraDefinitionCache = options.auraDefinitionCache,
            },
            options.auraDefinitionCache
        )
        if type(projection) == "table" then
            periodicDamage = periodicDamage + (tonumber(projection.periodicDamage) or 0)
            periodicHealing = periodicHealing + (tonumber(projection.periodicHealing) or 0)
            if type(projection.ledger) == "table" then
                ledger = projection.ledger
            end
        end
    end

    return periodicDamage, periodicHealing, ledger
end

function Evaluator.ResolveMovementControlSeverity(override)
    if override == nil then
        return 0
    end
    local numericOverride = tonumber(override)
    if numericOverride == nil then
        return 0
    end
    if numericOverride <= 0 then
        return 1
    end
    return 1 / (1 + numericOverride)
end

local function copyControlState(state)
    return {
        cancelOnDamage = type(state) == "table" and state.cancelOnDamage == true or false,
        preventCasting = type(state) == "table" and state.preventCasting == true or false,
        movementRangeOverride = type(state) == "table" and tonumber(state.movementRangeOverride) or nil,
        forceAutoHitAgainstTarget = type(state) == "table" and state.forceAutoHitAgainstTarget == true or false,
    }
end

local function getTargetMapEntry(options, profile, fieldName, targetEventId)
    local source = type(options) == "table" and options[fieldName] or nil
    if type(source) ~= "table" and type(profile) == "table" then
        source = profile[fieldName]
    end
    return type(source) == "table" and source[targetEventId] or nil
end

function Evaluator.ResolveControlUtility(profile, targetUnit, options)
    options = type(options) == "table" and options or {}
    local result = {
        movementControlUtility = 0,
        castingPreventionUtility = 0,
        controlUtility = 0,
    }
    if type(profile) ~= "table" or profile.hasControl ~= true or options.isHostileTarget ~= true then
        return result
    end

    local targetEventId = math.floor(tonumber(targetUnit and targetUnit.eventID) or 0)
    if targetEventId <= 0 then
        return result
    end

    local projectedControl = copyControlState(getTargetMapEntry(
        options,
        profile,
        "controlStateByTargetEventId",
        targetEventId
    ))
    local activeCast = getTargetMapEntry(options, profile, "activeCastsByEventId", targetEventId)

    for index = 1, #(profile.controlApplications or {}) do
        local application = profile.controlApplications[index]
        local auraProfile = type(application) == "table" and application.profile or nil
        local proposedControl = type(auraProfile) == "table" and auraProfile.control or nil
        if isSupportedControl(proposedControl) then
            local movementUtility = 0
            local proposedOverride = tonumber(proposedControl.movementRangeOverride)
            if proposedOverride ~= nil then
                local existingOverride = projectedControl.movementRangeOverride
                local effectiveOverride = existingOverride ~= nil
                    and math.min(existingOverride, proposedOverride)
                    or proposedOverride
                local increment = math.max(
                    0,
                    Evaluator.ResolveMovementControlSeverity(effectiveOverride)
                        - Evaluator.ResolveMovementControlSeverity(existingOverride)
                )
                movementUtility = Evaluator.MOVEMENT_CONTROL_UTILITY_CAP * increment
                projectedControl.movementRangeOverride = effectiveOverride
            end

            local castingUtility = 0
            if proposedControl.preventCasting == true
                and type(activeCast) == "table"
                and projectedControl.preventCasting ~= true
            then
                castingUtility = Evaluator.CASTING_PREVENTION_UTILITY
                projectedControl.preventCasting = true
            end

            if proposedControl.cancelOnDamage == true then
                movementUtility = movementUtility * Evaluator.FRAGILE_CONTROL_MULTIPLIER
                castingUtility = castingUtility * Evaluator.FRAGILE_CONTROL_MULTIPLIER
            end

            result.movementControlUtility = result.movementControlUtility + movementUtility
            result.castingPreventionUtility = result.castingPreventionUtility + castingUtility
        end
    end

    result.controlUtility = result.movementControlUtility + result.castingPreventionUtility
    return result
end

local function resolveCastRemainingTurns(activeCast)
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

function Evaluator.ResolveInterruptUtility(profile, targetUnit, options)
    options = type(options) == "table" and options or {}
    local targetEventId = math.floor(tonumber(targetUnit and targetUnit.eventID) or 0)
    local result = {
        hasUsefulInterrupt = false,
        urgentInterrupt = false,
        interruptTargetEventId = 0,
        interruptRemainingTurns = nil,
    }
    if type(profile) ~= "table"
        or profile.hasInterrupt ~= true
        or options.isHostileTarget ~= true
        or targetEventId <= 0
    then
        return result
    end

    local activeCast = getTargetMapEntry(options, profile, "activeCastsByEventId", targetEventId)
    if type(activeCast) ~= "table" then
        return result
    end

    result.hasUsefulInterrupt = true
    result.urgentInterrupt = true
    result.interruptTargetEventId = targetEventId
    result.interruptRemainingTurns = resolveCastRemainingTurns(activeCast)
    return result
end

function Evaluator.EvaluateCandidate(activationSnapshot, targetUnit, options)
    options = type(options) == "table" and options or {}
    local profile = type(options.profile) == "table"
        and options.profile
        or Evaluator.BuildSpellProfile(activationSnapshot, options)
    if type(profile) ~= "table" then
        return nil
    end

    local health = type(targetUnit) == "table"
        and Evaluator.ResolveProjectedHealth(targetUnit, profile.eventState, options.projectedHealingLedger)
        or nil

    local immediateDamage = normalizeNonNegative(profile.immediateDamage ~= nil and profile.immediateDamage or profile.expectedDamage)
    local immediateHealing = normalizeNonNegative(profile.immediateHealing ~= nil and profile.immediateHealing or profile.expectedHealing)
    local immediateEffectiveHealing = 0
    if profile.hasImmediateHeal and type(health) == "table" and health.isLiving == true then
        immediateEffectiveHealing = math.min(immediateHealing, health.projectedMissingHealth)
    end

    local periodicDamage, periodicHealing, projectedAuraLedger = resolvePeriodicApplicationUtility(profile, targetUnit, options)
    local usefulPeriodicDamage = periodicDamage <= 0 and periodicDamage or 0
    if periodicDamage > 0 and type(health) == "table" then
        usefulPeriodicDamage = math.min(
            periodicDamage,
            math.max(0, tonumber(health.projectedCurrentValue) or tonumber(health.currentValue) or 0)
        )
    end

    local usefulPeriodicHealing = periodicHealing <= 0 and periodicHealing or 0
    if periodicHealing > 0 and type(health) == "table" then
        local remainingMissingHealth = math.max(0, health.projectedMissingHealth - immediateEffectiveHealing)
        usefulPeriodicHealing = math.min(periodicHealing, remainingMissingHealth)
    end

    local control = Evaluator.ResolveControlUtility(profile, targetUnit, options)
    local interrupt = Evaluator.ResolveInterruptUtility(profile, targetUnit, options)
    local damageUtility = immediateDamage + usefulPeriodicDamage
    local healingUtility = math.max(0, immediateEffectiveHealing + usefulPeriodicHealing)
    local controlUtility = tonumber(control.controlUtility) or 0
    local totalUtility = damageUtility + healingUtility + controlUtility
    local urgentHealing = profile.hasHeal
        and type(health) == "table"
        and health.isLiving == true
        and health.projectedHealthFraction <= Evaluator.URGENT_HEALTH_FRACTION
        and healingUtility > 0

    local preferredIntent = nil
    if urgentHealing then
        preferredIntent = "heal"
    elseif interrupt.urgentInterrupt == true then
        preferredIntent = "interrupt"
    elseif healingUtility > damageUtility + controlUtility then
        preferredIntent = "heal"
    elseif damageUtility > 0 then
        preferredIntent = "damage"
    elseif controlUtility > 0 then
        preferredIntent = "control"
    elseif healingUtility > 0 then
        preferredIntent = "heal"
    end

    return {
        spellRef = profile.spellRef,
        casterEventId = profile.casterEventId,
        targetEventId = math.floor(tonumber(targetUnit and targetUnit.eventID) or 0),
        hasDamage = profile.hasDamage,
        hasHeal = profile.hasHeal,
        hasControl = profile.hasControl == true,
        hasInterrupt = profile.hasInterrupt == true,
        hasImmediateDamage = profile.hasImmediateDamage == true,
        hasImmediateHeal = profile.hasImmediateHeal == true,
        hasPeriodicDamage = profile.hasPeriodicDamage == true,
        hasPeriodicHealing = profile.hasPeriodicHealing == true,
        damageTypes = profile.damageTypes,
        damageTypeList = profile.damageTypeList,
        immediateDamage = immediateDamage,
        immediateHealing = immediateHealing,
        periodicDamage = periodicDamage,
        periodicHealing = periodicHealing,
        usefulPeriodicDamage = usefulPeriodicDamage,
        usefulPeriodicHealing = usefulPeriodicHealing,
        expectedDamage = immediateDamage + usefulPeriodicDamage,
        expectedHealing = immediateHealing + usefulPeriodicHealing,
        auraApplications = profile.auraApplications,
        appliedAuras = profile.appliedAuras,
        hasAuraApplication = profile.hasAuraApplication == true,
        effectiveHealing = healingUtility,
        damageUtility = damageUtility,
        healingUtility = healingUtility,
        movementControlUtility = tonumber(control.movementControlUtility) or 0,
        castingPreventionUtility = tonumber(control.castingPreventionUtility) or 0,
        controlUtility = controlUtility,
        totalUtility = totalUtility,
        urgentHealing = urgentHealing == true,
        hasUsefulInterrupt = interrupt.hasUsefulInterrupt == true,
        urgentInterrupt = interrupt.urgentInterrupt == true,
        interruptTargetEventId = math.floor(tonumber(interrupt.interruptTargetEventId) or 0),
        interruptRemainingTurns = interrupt.interruptRemainingTurns,
        preferredIntent = preferredIntent,
        resourceBurden = profile.resourceBurden,
        cooldownCommitment = profile.cooldownCommitment,
        chargeCommitment = profile.chargeCommitment,
        targetHealth = health,
        projectedAuraLedger = projectedAuraLedger,
        activationSnapshot = activationSnapshot,
    }
end

function Evaluator.CompareCandidates(left, right)
    if type(left) ~= "table" then
        return type(right) == "table" and -1 or 0
    end
    if type(right) ~= "table" then
        return 1
    end

    if left.urgentHealing ~= right.urgentHealing then
        return left.urgentHealing == true and 1 or -1
    end

    if left.urgentInterrupt ~= right.urgentInterrupt then
        return left.urgentInterrupt == true and 1 or -1
    end

    local leftUtility = normalizeNonNegative(left.totalUtility)
    local rightUtility = normalizeNonNegative(right.totalUtility)
    if leftUtility ~= rightUtility then
        return leftUtility > rightUtility and 1 or -1
    end

    local leftResource = normalizeNonNegative(left.resourceBurden)
    local rightResource = normalizeNonNegative(right.resourceBurden)
    if leftResource ~= rightResource then
        return leftResource < rightResource and 1 or -1
    end

    local leftCooldown = normalizeNonNegative(left.cooldownCommitment)
    local rightCooldown = normalizeNonNegative(right.cooldownCommitment)
    if leftCooldown ~= rightCooldown then
        return leftCooldown < rightCooldown and 1 or -1
    end

    local leftCharge = normalizeNonNegative(left.chargeCommitment)
    local rightCharge = normalizeNonNegative(right.chargeCommitment)
    if leftCharge ~= rightCharge then
        return leftCharge < rightCharge and 1 or -1
    end

    local leftRef = tostring(left.spellRef or "")
    local rightRef = tostring(right.spellRef or "")
    if leftRef ~= rightRef then
        return leftRef < rightRef and 1 or -1
    end

    local leftTarget = math.floor(tonumber(left.targetEventId) or 0)
    local rightTarget = math.floor(tonumber(right.targetEventId) or 0)
    if leftTarget ~= rightTarget then
        return leftTarget < rightTarget and 1 or -1
    end

    return 0
end

function Evaluator.SelectBestCandidate(candidates)
    local best = nil
    for index = 1, #(candidates or {}) do
        local candidate = candidates[index]
        if type(candidate) == "table" and (best == nil or Evaluator.CompareCandidates(candidate, best) > 0) then
            best = candidate
        end
    end
    return best
end

return Evaluator