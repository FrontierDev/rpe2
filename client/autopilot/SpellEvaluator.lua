local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Common = Addon.Utils.Common or {}
local Lookup = Addon.Utils.Lookup or {}

Client.AutopilotSpellEvaluator = Client.AutopilotSpellEvaluator or {}
local Evaluator = Client.AutopilotSpellEvaluator

Evaluator.URGENT_HEALTH_FRACTION = 0.50

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
        damageTypes = {},
        damageTypeList = {},
        damageComponentCount = 0,
        healComponentCount = 0,
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

function Evaluator.BuildSpellProfile(activationSnapshot)
    if type(activationSnapshot) ~= "table" or activationSnapshot.canCast ~= true then
        return nil
    end

    local spell = activationSnapshot.spell
    local casterUnit = activationSnapshot.casterUnit
    if type(spell) ~= "table" or type(casterUnit) ~= "table" then
        return nil
    end

    local classification = Evaluator.ClassifySpell(spell)
    local expectedDamage = 0
    local expectedHealing = 0

    for index = 1, #(spell.components or {}) do
        local component = spell.components[index]
        local effect = type(component) == "table" and component.effect or nil
        local effectType = tostring(type(effect) == "table" and effect.type or "")
        if effectType == "damage" then
            expectedDamage = expectedDamage + Evaluator.ResolveExpectedDamage(casterUnit, effect)
        elseif effectType == "heal" then
            expectedHealing = expectedHealing + Evaluator.ResolveExpectedHealing(casterUnit, effect)
        end
    end

    return {
        spellRef = tostring(activationSnapshot.spellRef or ""),
        spell = spell,
        casterUnit = casterUnit,
        casterEventId = tonumber(casterUnit.eventID) or 0,
        eventState = activationSnapshot.eventState,
        hasDamage = classification.hasDamage,
        hasHeal = classification.hasHeal,
        damageTypes = classification.damageTypes,
        damageTypeList = classification.damageTypeList,
        damageComponentCount = classification.damageComponentCount,
        healComponentCount = classification.healComponentCount,
        expectedDamage = expectedDamage,
        expectedHealing = expectedHealing,
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

function Evaluator.EvaluateCandidate(activationSnapshot, targetUnit, options)
    options = type(options) == "table" and options or {}
    local profile = Evaluator.BuildSpellProfile(activationSnapshot)
    if type(profile) ~= "table" then
        return nil
    end

    local health = type(targetUnit) == "table"
        and Evaluator.ResolveProjectedHealth(targetUnit, profile.eventState, options.projectedHealingLedger)
        or nil
    local effectiveHealing = 0
    if profile.hasHeal and type(health) == "table" and health.isLiving == true then
        effectiveHealing = math.min(profile.expectedHealing, health.projectedMissingHealth)
    end

    local urgentHealing = profile.hasHeal
        and type(health) == "table"
        and health.isLiving == true
        and health.healthFraction <= Evaluator.URGENT_HEALTH_FRACTION
        and effectiveHealing > 0

    local damageUtility = profile.hasDamage and profile.expectedDamage or 0
    local healingUtility = effectiveHealing
    local totalUtility = damageUtility + healingUtility
    local preferredIntent = nil
    if urgentHealing then
        preferredIntent = "heal"
    elseif healingUtility > damageUtility then
        preferredIntent = "heal"
    elseif damageUtility > 0 then
        preferredIntent = "damage"
    elseif healingUtility > 0 then
        preferredIntent = "heal"
    end

    return {
        spellRef = profile.spellRef,
        casterEventId = profile.casterEventId,
        targetEventId = math.floor(tonumber(targetUnit and targetUnit.eventID) or 0),
        hasDamage = profile.hasDamage,
        hasHeal = profile.hasHeal,
        damageTypes = profile.damageTypes,
        damageTypeList = profile.damageTypeList,
        expectedDamage = profile.expectedDamage,
        expectedHealing = profile.expectedHealing,
        effectiveHealing = effectiveHealing,
        damageUtility = damageUtility,
        healingUtility = healingUtility,
        totalUtility = totalUtility,
        urgentHealing = urgentHealing == true,
        preferredIntent = preferredIntent,
        resourceBurden = profile.resourceBurden,
        cooldownCommitment = profile.cooldownCommitment,
        chargeCommitment = profile.chargeCommitment,
        targetHealth = health,
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
