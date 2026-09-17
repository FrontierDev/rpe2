local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Combat = Addon.Client.Combat or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Ruleset = Addon.Internal.Ruleset or {}
Addon.Utils = Addon.Utils or {}

local Combat = Addon.Client.Combat
local Ruleset = Addon.Internal.Ruleset or {}
local Registry = Addon.Internal.Registry or {}
local Common = Addon.Utils.Common or {}
local Dice = Addon.Utils.Dice or {}
local Lookup = Addon.Utils.Lookup or {}
local Normalization = Addon.Client.Combat.Normalization or {}
local Debug = Addon.Debug
local Database = Addon.Internal.Database or {}
local Profile = Addon.Internal.Profile or {}
local Dependencies = Database.Dependecies or {}
local UI = Addon.UI or {}
local trimText = Normalization.TrimText or function(value)
    if value == nil then
        return ""
    end
    return tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
end
local normalizeToken = Normalization.NormalizeToken or function(value)
    local token = trimText(value)
    if token == "" then
        return nil
    end
    return token
end

local function normalizeColorHex(value)
    local normalized = tostring(value or "")
    normalized = normalized:gsub("^|c", ""):gsub("|r", ""):gsub("#", "")
    normalized = normalized:gsub("[^0-9a-fA-F]", "")
    if #normalized == 6 then
        normalized = "ff" .. normalized
    end
    if #normalized ~= 8 then
        return nil
    end

    return string.lower(normalized)
end

local function wrapTextWithColor(text, colorHex)
    local normalized = normalizeColorHex(colorHex)
    if normalized == nil or tostring(text or "") == "" then
        return tostring(text or "")
    end

    return ("|c%s%s|r"):format(normalized, tostring(text))
end

local function buildDamageAmountText(amountMin, amountMax)
    local minimum = math.max(0, math.floor(tonumber(amountMin) or 0))
    local maximum = math.max(0, math.floor(tonumber(amountMax) or minimum))
    if maximum < minimum then
        minimum, maximum = maximum, minimum
    end
    if minimum == maximum then
        return tostring(minimum)
    end

    return ("%d-%d"):format(minimum, maximum)
end

local function buildAggregateDamageDetailText(aggregate)
    if type(aggregate) ~= "table" then
        return nil
    end

    local absorbedMin = tonumber(aggregate.absorbedMin)
    local absorbedMax = tonumber(aggregate.absorbedMax)
    local hasAbsorption = absorbedMin ~= nil and absorbedMax ~= nil and absorbedMax > 0
    local hasBonusDamage = type(aggregate.bonusDamageEntries) == "table" and #aggregate.bonusDamageEntries > 0
    if not hasAbsorption and not hasBonusDamage then
        return nil
    end

    local baseText = ("%s %s"):format(
        buildDamageAmountText(aggregate.amountMin, aggregate.amountMax),
        tostring(aggregate.labelText or "") ~= "" and tostring(aggregate.labelText) or "True"
    )
    if hasAbsorption then
        baseText = ("%s (absorbed %s)"):format(baseText, buildDamageAmountText(absorbedMin, absorbedMax))
    end
    baseText = wrapTextWithColor(baseText, aggregate.accentColor)

    local bonusParts = {}
    for index = 1, #aggregate.bonusDamageEntries do
        local bonusEntry = aggregate.bonusDamageEntries[index]
        local amount = math.max(0, math.floor(tonumber(bonusEntry and bonusEntry.amount) or 0))
        local absorbedAmount = math.max(0, math.floor(tonumber(bonusEntry and bonusEntry.absorbedAmount) or 0))
        if amount > 0 or absorbedAmount > 0 then
            local bonusText = "+" .. tostring(amount)
            if absorbedAmount > 0 then
                bonusText = ("%s (absorbed %d)"):format(bonusText, absorbedAmount)
            end
            bonusParts[#bonusParts + 1] = wrapTextWithColor(bonusText, bonusEntry and bonusEntry.colorHex or nil)
        end
    end

    if #bonusParts == 0 then
        return baseText
    end

    return ("%s (%s)"):format(baseText, table.concat(bonusParts, ", "))
end

local function normalizeHealthResourceRef(resourceRef)
    if type(resourceRef) ~= "string" or resourceRef == "" then
        return nil
    end

    return resourceRef
end

local function deepClone(value)
    if type(value) ~= "table" then
        return value
    end

    local clone = {}
    for key, entry in pairs(value) do
        clone[key] = deepClone(entry)
    end

    return clone
end

function Combat:CloneValue(value)
    return deepClone(value)
end

function Combat:GetRuleValue(groupKey, ruleKey, fallback)
    if type(Ruleset.GetActiveRuleset) ~= "function"
        or type(Ruleset.GetRulesetRuleDefinition) ~= "function"
        or type(Ruleset.GetRulesetRuleValue) ~= "function"
    then
        return fallback
    end

    local activeRuleset = Ruleset.GetActiveRuleset()
    local ruleDefinition = Ruleset.GetRulesetRuleDefinition(groupKey, ruleKey)
    local value = Ruleset.GetRulesetRuleValue(activeRuleset, groupKey, ruleDefinition)
    if value == nil or value == "" then
        return fallback
    end

    return value
end

function Combat:GetHealthResourceRef()
    local value = self:GetRuleValue("resources", "health_stat", "")
    if type(value) ~= "string" or value == "" then
        return nil
    end

    return value
end

function Combat:ResolveHealthResourceRef(options)
    local healthResourceRef = type(options) == "table" and normalizeHealthResourceRef(options.healthResourceRef) or nil
    if healthResourceRef then
        return healthResourceRef
    end

    local eventState = type(options) == "table" and options.eventState or nil
    healthResourceRef = normalizeHealthResourceRef(eventState and eventState.healthResourceRef)
    if healthResourceRef then
        return healthResourceRef
    end

    return normalizeHealthResourceRef(self:GetHealthResourceRef())
end

function Combat:IsHealthResource(resourceRef, options)
    local healthResourceRef = self:ResolveHealthResourceRef(options)
    return healthResourceRef ~= nil and resourceRef == healthResourceRef
end

function Combat:GetUnitHealthEntry(unit, options)
    local healthResourceRef = self:ResolveHealthResourceRef(options)
    if not healthResourceRef then
        return nil
    end

    return Lookup.GetResourceEntry and Lookup.GetResourceEntry(unit, healthResourceRef) or nil
end

function Combat:IsUnitDead(unit, options)
    local entry = self:GetUnitHealthEntry(unit, options)
    if type(entry) ~= "table" then
        return false
    end

    local currentValue = tonumber(entry.currentValue)
    if currentValue == nil then
        currentValue = tonumber(entry.maxValue) or 0
    end

    return currentValue <= 0
end

function Combat:HandleUnitDeath(options)
    local unit = type(options) == "table" and (options.targetUnit or options.unit) or nil
    local eventState = type(options) == "table" and options.eventState or nil
    local targetEventId = tonumber(type(options) == "table" and (options.targetEventId or (unit and unit.eventID)) or 0) or 0
    if type(unit) ~= "table" or type(eventState) ~= "table" or targetEventId <= 0 then
        return false, {}
    end

    local client = type(options) == "table" and options.client or Addon.Client
    local spellcasting = client and client.Spellcasting or (Addon.Client and Addon.Client.Spellcasting) or nil
    local auraManager = spellcasting and spellcasting.AuraManager or nil
    if type(auraManager) ~= "table" or type(auraManager.RemoveAllAurasForUnit) ~= "function" then
        return false, {}
    end

    local removed, removedEntries = auraManager:RemoveAllAurasForUnit(client, eventState, targetEventId, {
        context = type(options) == "table" and options.context or nil,
        queueSync = type(options) == "table" and options.queueAuraSync == true,
        sessionState = type(options) == "table" and options.sessionState or nil,
    })
    return removed, removedEntries or {}
end

function Combat:GetUnitLevel(unit, eventState)
    local function resolveLevelFromUnit(candidate)
        if type(candidate) ~= "table" then
            return nil
        end

        local level = tonumber(candidate.level)
            or tonumber(candidate.actorLevel)
            or tonumber(candidate.stats and candidate.stats.level)
            or tonumber(candidate.effectiveLevel)
        if level == nil then
            return nil
        end

        return math.max(1, math.floor(level))
    end

    local resolvedLevel = resolveLevelFromUnit(unit)
    if resolvedLevel ~= nil then
        return resolvedLevel
    end

    local resolvedUnit = type(unit) == "table" and type(unit.GetResolvedUnit) == "function" and unit:GetResolvedUnit() or nil
    resolvedLevel = resolveLevelFromUnit(resolvedUnit)
    if resolvedLevel ~= nil then
        return resolvedLevel
    end

    if type(unit) == "table" and unit.isPlayer == true and type(Profile.GetLevel) == "function" then
        local profileLevel = tonumber(Profile.GetLevel())
        if profileLevel ~= nil then
            return math.max(1, math.floor(profileLevel))
        end
    end

    local eventLevel = type(eventState) == "table" and tonumber(eventState.level) or nil
    if eventLevel ~= nil then
        return math.max(1, math.floor(eventLevel))
    end

    return 1
end

function Combat:IsLevelSystemEnabled()
    return self:GetRuleValue("character", "use_level_system", false) == true
end

function Combat:GetDamageSchoolMitigationModel()
    local rawValue = self.GetCombatRule and self:GetCombatRule("damage_school_mitigation_model", "legacy")
        or self:GetRuleValue("combat", "damage_school_mitigation_model", "legacy")
    local model = string.lower(trimText(rawValue or "legacy"))
    if model == "fixed_percent" or model == "level_scaled_percent" then
        return model
    end
    return "legacy"
end

function Combat:GetDamageSchoolMitigationReferenceLevel()
    local rawValue = self.GetCombatRule and self:GetCombatRule("damage_school_mitigation_reference_level", 60)
        or self:GetRuleValue("combat", "damage_school_mitigation_reference_level", 60)
    return math.max(1, math.floor(tonumber(rawValue) or 60))
end

function Combat:GetCriticalDamageMitigationModel(combatRules)
    local rawValue = type(combatRules) == "table" and combatRules.criticalDamageMitigationModel
        or (self.GetCombatRule and self:GetCombatRule("critical_damage_mitigation_model", "legacy"))
        or self:GetRuleValue("combat", "critical_damage_mitigation_model", "legacy")
    local model = string.lower(trimText(rawValue or "legacy"))
    if model == "fixed_percent" or model == "level_scaled_percent" then
        return model
    end
    return "legacy"
end

function Combat:GetCriticalDamageMitigationReferenceLevel(combatRules)
    local rawValue = type(combatRules) == "table" and combatRules.criticalDamageMitigationReferenceLevel
        or (self.GetCombatRule and self:GetCombatRule("critical_damage_mitigation_reference_level", 60))
        or self:GetRuleValue("combat", "critical_damage_mitigation_reference_level", 60)
    return math.max(1, math.floor(tonumber(rawValue) or 60))
end

function Combat:ResolveDamageSchoolReference(schoolRef)
    local normalizedSchoolRef = normalizeToken(schoolRef)
    if not normalizedSchoolRef
        or type(Dependencies.ParseSourceStatRef) ~= "function"
        or type(Database.GetDatasetByID) ~= "function" then
        return nil, nil
    end

    local datasetId, damageSchoolId = Dependencies.ParseSourceStatRef(normalizedSchoolRef)
    local dataset = datasetId and Database.GetDatasetByID(datasetId) or nil
    local damageSchools = type(dataset) == "table" and dataset.damageSchools or nil
    for index = 1, #(damageSchools or {}) do
        local candidate = damageSchools[index]
        if tostring(candidate and candidate.id or "") == tostring(damageSchoolId or "") then
            return dataset, candidate
        end
    end

    return dataset, nil
end

function Combat:ResolveDamageSchoolMitigation(damageSchool, statValue, unitLevel)
    if type(damageSchool) ~= "table" then
        return {
            mode = "percent",
            percent = 0,
            rawPercent = 0,
            flat = 0,
            effectiveReferenceAmount = 0,
        }
    end

    local numericStatValue = tonumber(statValue) or 0
    local model = self:GetDamageSchoolMitigationModel()
    if model == "legacy" then
        local mitigationValue = numericStatValue * (tonumber(damageSchool.mitigationCoefficient) or 1)
        if tostring(damageSchool.mitigationMode or "direct") == "percent" then
            local mitigationPercent = math.max(0, math.min(100, mitigationValue))
            return {
                mode = "percent",
                percent = mitigationPercent,
                rawPercent = mitigationValue,
                flat = 0,
                effectiveReferenceAmount = 0,
            }
        end

        return {
            mode = "direct",
            percent = nil,
            rawPercent = nil,
            flat = mitigationValue,
            effectiveReferenceAmount = 0,
        }
    end

    local referenceAmount = tonumber(damageSchool.mitigationReferenceAmount) or 0
    local referencePercent = tonumber(damageSchool.mitigationReferencePercent) or 0
    local effectiveReferenceAmount = referenceAmount
    if model == "level_scaled_percent" and self:IsLevelSystemEnabled() then
        local numericUnitLevel = math.max(1, math.floor(tonumber(unitLevel) or self:GetDamageSchoolMitigationReferenceLevel()))
        local referenceLevel = self:GetDamageSchoolMitigationReferenceLevel()
        effectiveReferenceAmount = referenceAmount * (numericUnitLevel / referenceLevel)
    end

    local rawPercent = 0
    if effectiveReferenceAmount > 0 and referencePercent ~= 0 then
        rawPercent = (numericStatValue / effectiveReferenceAmount) * referencePercent
    end
    local mitigationPercent = math.max(0, math.min(100, rawPercent))
    return {
        mode = "percent",
        percent = mitigationPercent,
        rawPercent = rawPercent,
        flat = 0,
        effectiveReferenceAmount = effectiveReferenceAmount,
    }
end

function Combat:ResolveCriticalDamageMitigation(combatRules, statValue, unitLevel)
    local numericStatValue = tonumber(statValue) or 0
    local model = self:GetCriticalDamageMitigationModel(combatRules)
    if model == "legacy" then
        local mitigationValue = numericStatValue * (tonumber(type(combatRules) == "table" and combatRules.criticalDamageMitigationCoefficient or 1) or 1)
        if tostring(type(combatRules) == "table" and combatRules.criticalDamageMitigationMode or "direct") == "percent" then
            local mitigationPercent = math.max(0, math.min(100, mitigationValue))
            return {
                mode = "percent",
                percent = mitigationPercent,
                rawPercent = mitigationValue,
                flat = 0,
                effectiveReferenceAmount = 0,
            }
        end

        return {
            mode = "direct",
            percent = nil,
            rawPercent = nil,
            flat = mitigationValue,
            effectiveReferenceAmount = 0,
        }
    end

    local referenceAmount = tonumber(type(combatRules) == "table" and combatRules.criticalDamageMitigationReferenceAmount or 0) or 0
    local referencePercent = tonumber(type(combatRules) == "table" and combatRules.criticalDamageMitigationReferencePercent or 0) or 0
    local effectiveReferenceAmount = referenceAmount
    if model == "level_scaled_percent" and self:IsLevelSystemEnabled() then
        local numericUnitLevel = math.max(1, math.floor(tonumber(unitLevel) or self:GetCriticalDamageMitigationReferenceLevel(combatRules)))
        local referenceLevel = self:GetCriticalDamageMitigationReferenceLevel(combatRules)
        effectiveReferenceAmount = referenceAmount * (numericUnitLevel / referenceLevel)
    end

    local rawPercent = 0
    if effectiveReferenceAmount > 0 and referencePercent ~= 0 then
        rawPercent = (numericStatValue / effectiveReferenceAmount) * referencePercent
    end
    local mitigationPercent = math.max(0, math.min(100, rawPercent))
    return {
        mode = "percent",
        percent = mitigationPercent,
        rawPercent = rawPercent,
        flat = 0,
        effectiveReferenceAmount = effectiveReferenceAmount,
    }
end

function Combat:ResolveDiceExpressionMax(expression, defaultCount, defaultSides)
    local count, sides = defaultCount or 1, defaultSides or 20
    if type(Dice.ParseExpression) == "function" then
        local parsedCount, parsedSides = Dice.ParseExpression(expression, defaultCount, defaultSides)
        count = parsedCount or count
        sides = parsedSides or sides
    end
    count = math.max(1, math.floor(tonumber(count) or defaultCount or 1))
    sides = math.max(1, math.floor(tonumber(sides) or defaultSides or 20))
    return count * sides, count, sides
end

function Combat:ResolveWeaponItemRef(unit, slotKey, fallbackField)
    if type(unit) ~= "table" then
        return nil
    end

    local eventRef = Normalization.NormalizeToken(unit[fallbackField])
    if eventRef then
        return eventRef
    end

    local resolvedUnit = type(unit.GetResolvedUnit) == "function" and unit:GetResolvedUnit() or nil
    local resolvedRef = Normalization.NormalizeToken(resolvedUnit and resolvedUnit[fallbackField])
    if resolvedRef then
        return resolvedRef
    end

    if unit.isPlayer == true and type(Profile.GetEquippedItem) == "function" then
        local equipped = Profile.GetEquippedItem(slotKey)
        return Normalization.NormalizeToken(equipped and equipped.itemRef)
    end

    return nil
end

function Combat:ResolveItemDefinition(itemRef)
    if not itemRef then
        return nil, nil
    end

    local equipment = Profile.Equipment or nil
    if equipment and type(equipment.ResolveItemDefinition) == "function" then
        local item, dataset = equipment.ResolveItemDefinition(itemRef)
        if item then
            return item, dataset
        end
    end

    if type(Dependencies.ParseSourceStatRef) == "function" and type(Database.GetDatasetByID) == "function" then
        local datasetId, itemId = Dependencies.ParseSourceStatRef(itemRef)
        local dataset = datasetId and Database.GetDatasetByID(datasetId) or nil
        for index = 1, #((dataset and dataset.items) or {}) do
            local candidate = dataset.items[index]
            if tostring(candidate and candidate.id or "") == tostring(itemId or "") then
                return candidate, dataset
            end
        end
    end

    return nil, nil
end

function Combat:IsWeaponBasedDamageEffect(effect)
    return type(effect) == "table" and tostring(effect.weaponDamageMode or "none") ~= "none"
end

function Combat:ResolveWeaponRefsForEffect(attackerUnit, effect, component)
    local attackType = self:ResolveHitCheckAttackType(effect, component)
    local weaponDamageMode = tostring(effect and effect.weaponDamageMode or "none")
    if weaponDamageMode == "none" then
        return {}
    end

    local primarySlotKey = attackType == "ranged" and "ranged" or "mainhand"
    local primaryField = attackType == "ranged" and "rangedWeapon" or "mainHandWeapon"
    local rows = {}

    local function appendWeapon(slotKey, fallbackField)
        local itemRef = self:ResolveWeaponItemRef(attackerUnit, slotKey, fallbackField)
        if not itemRef then
            return
        end

        local item, dataset = self:ResolveItemDefinition(itemRef)
        rows[#rows + 1] = {
            slotKey = slotKey,
            itemRef = itemRef,
            item = item,
            dataset = dataset,
            weaponTypeRef = item and item.weaponTypeRef or nil,
        }
    end

    if weaponDamageMode == "main_hand" or weaponDamageMode == "both" then
        appendWeapon(primarySlotKey, primaryField)
    end
    if weaponDamageMode == "off_hand" or weaponDamageMode == "both" then
        appendWeapon("offhand", "offHandWeapon")
    end

    return rows
end

function Combat:ResolveWeaponSkillContext(context, effect, component)
    local result = {
        isWeaponDamage = self:IsWeaponBasedDamageEffect(effect),
        contributingWeapons = {},
        expectedWeaponSkill = nil,
        resolvedWeaponSkill = nil,
        skillDeficit = 0,
        skillSurplus = 0,
        hitPenaltyPercent = 0,
        critBonusPercent = 0,
        hitPenaltyValue = 0,
        modifiersEnabled = false,
        canCrush = false,
    }

    if result.isWeaponDamage ~= true then
        return result
    end

    local attackerUnit = type(context) == "table" and (context.attackerUnit or context.casterUnit or context.caster) or nil
    local eventState = type(context) == "table" and context.eventState or nil
    result.canCrush = self:GetRuleValue("weapon_combat", "enable_crushing_blows", false) == true
    result.contributingWeapons = self:ResolveWeaponRefsForEffect(attackerUnit, effect, component)
    if #result.contributingWeapons == 0 then
        return result
    end

    if self:GetRuleValue("skills", "use_weapon_skills", true) == false
        or not self:IsLevelSystemEnabled()
        or type(eventState) ~= "table"
        or eventState.active ~= true
    then
        return result
    end

    local eventLevel = math.max(1, math.floor(tonumber(eventState.level) or 1))
    local weaponMultiplier = tonumber(self:GetRuleValue("skills", "weapon_skill_level_multiplier", 5)) or 5
    result.expectedWeaponSkill = math.max(1, math.floor(eventLevel * weaponMultiplier))

    local rowsByWeaponTypeRef = type(Profile.GetResolvedWeaponSkillRowsByWeaponType) == "function"
        and Profile.GetResolvedWeaponSkillRowsByWeaponType()
        or {}

    local resolvedValues = {}
    for index = 1, #result.contributingWeapons do
        local weapon = result.contributingWeapons[index]
        local weaponTypeRef = Normalization.NormalizeToken(weapon and weapon.weaponTypeRef)
        if weaponTypeRef then
            local bucket = rowsByWeaponTypeRef[weaponTypeRef] or {}
            if #bucket > 1 then
                if Debug and type(Debug.Warn) == "function" then
                    Debug.Warn("Weapon skill modifiers disabled: multiple weapon skills match %s.", tostring(Registry.ResolveWeaponTypeName and Registry:ResolveWeaponTypeName(weaponTypeRef) or weaponTypeRef))
                end
                return result
            end
            local row = bucket[1]
            if row then
                resolvedValues[#resolvedValues + 1] = math.max(0, math.floor(tonumber(row.resolvedValue or row.value) or 0))
            end
        end
    end

    if #resolvedValues == 0 then
        return result
    end

    table.sort(resolvedValues)
    result.resolvedWeaponSkill = resolvedValues[1]
    result.modifiersEnabled = true

    if self:GetRuleValue("weapon_combat", "skill_based_hit_chance", false) == true then
        local deficit = math.max(0, (result.expectedWeaponSkill or 0) - (result.resolvedWeaponSkill or 0))
        result.skillDeficit = deficit
        local perPoint = tonumber(self:GetRuleValue("weapon_combat", "weapon_skill_hit_modifier_per_point", 1)) or 1
        local capValue = tonumber(self:GetRuleValue("weapon_combat", "weapon_skill_hit_modifier_cap", 25)) or 25
        result.hitPenaltyPercent = math.min(capValue, deficit * perPoint)
    end

    if result.canCrush == true then
        local surplus = math.max(0, (result.resolvedWeaponSkill or 0) - (result.expectedWeaponSkill or 0))
        result.skillSurplus = surplus
        local perPoint = tonumber(self:GetRuleValue("weapon_combat", "weapon_skill_crit_modifier_per_point", 1)) or 1
        local capValue = tonumber(self:GetRuleValue("weapon_combat", "weapon_skill_crit_modifier_cap", 25)) or 25
        result.critBonusPercent = math.min(capValue, surplus * perPoint)
    end

    return result
end

function Combat:ResolveWeaponSkillHitPenaltyValue(defenceSystem, weaponSkillContext)
    local penaltyPercent = type(weaponSkillContext) == "table" and tonumber(weaponSkillContext.hitPenaltyPercent) or 0
    if penaltyPercent <= 0 then
        return 0
    end

    local rollMax = 100
    if tostring(defenceSystem or "") ~= "percent" then
        rollMax = self:ResolveDiceExpressionMax(self:GetCombatRule("attack_roll_dice", "1d20"), 1, 20)
    end

    return math.floor(((penaltyPercent * rollMax) / 100) + 0.5)
end

function Combat:ResolveAttackStatContribution(attackerUnit, defenceSystem, attackType, context)
    local statRef = self:ResolveAttackStatRef(defenceSystem, attackType)
    local statValue = 0
    if statRef then
        if type(self.GetCachedCombatStatValue) == "function" then
            statValue = self:GetCachedCombatStatValue(context, attackerUnit, statRef, 0)
        else
            statValue = Lookup.GetStatValue and Lookup.GetStatValue(attackerUnit, statRef, 0) or 0
        end
    end

    return {
        statRef = statRef,
        statValue = Common.Round(tonumber(statValue) or 0),
    }
end

function Combat:ResolveAttackModifierContext(attackerUnit, defenceSystem, attackType, weaponSkillContext, context)
    local statContribution = self:ResolveAttackStatContribution(attackerUnit, defenceSystem, attackType, context)
    local penaltyValue = type(weaponSkillContext) == "table" and tonumber(weaponSkillContext.hitPenaltyValue) or nil
    if penaltyValue == nil then
        penaltyValue = self:ResolveWeaponSkillHitPenaltyValue(defenceSystem, weaponSkillContext)
        if type(weaponSkillContext) == "table" then
            weaponSkillContext.hitPenaltyValue = penaltyValue
        end
    end

    return {
        statRef = statContribution.statRef,
        statValue = statContribution.statValue,
        weaponSkillPenaltyPercent = type(weaponSkillContext) == "table" and (tonumber(weaponSkillContext.hitPenaltyPercent) or 0) or 0,
        weaponSkillPenaltyValue = penaltyValue,
        totalModifierValue = Common.Round((tonumber(statContribution.statValue) or 0) - penaltyValue),
    }
end

function Combat:ApplyWeaponSkillHitPenalty(attackerTotal, defenceSystem, weaponSkillContext)
    local penaltyValue = type(weaponSkillContext) == "table" and tonumber(weaponSkillContext.hitPenaltyValue) or nil
    if penaltyValue == nil then
        penaltyValue = self:ResolveWeaponSkillHitPenaltyValue(defenceSystem, weaponSkillContext)
    end
    if penaltyValue <= 0 then
        return attackerTotal, 0
    end

    if type(weaponSkillContext) == "table" then
        weaponSkillContext.hitPenaltyValue = penaltyValue
    end
    return Common.Round((tonumber(attackerTotal) or 0) - penaltyValue), penaltyValue
end

function Combat:ResolveCritCategory(effect)
    local effectType = tostring(effect and effect.type or "")
    if effectType == "heal" then
        return "healing"
    end

    local damageType = string.lower(Normalization.TrimText(effect and effect.damageType or "spell"))
    if damageType == "melee" or damageType == "ranged" then
        return damageType
    end

    return "spell"
end

function Combat:ResolveCritStatRef(defenceSystem, critCategory)
    if defenceSystem == "percent" then
        return Normalization.NormalizeToken(self:GetCombatRule(("percent_%s_crit_stat"):format(critCategory), ""))
    end
    if defenceSystem == "complex" then
        return Normalization.NormalizeToken(self:GetCombatRule(("complex_%s_crit_stat"):format(critCategory), ""))
    end

    return Normalization.NormalizeToken(self:GetCombatRule(("simple_%s_crit_stat"):format(critCategory), ""))
end

function Combat:ResolveBaseCritChance(critCategory)
    return tonumber(self:GetCombatRule(("base_%s_crit_chance"):format(critCategory), 0)) or 0
end

function Combat:ResolveCritRoll(defenceSystem, context, actorUnit, critCategory, weaponSkillCritBonusPercent)
    local critContext = type(context) == "table" and context.critResolutionContext or nil
    local baseCritChance = critContext and critContext.baseCritChance or self:ResolveBaseCritChance(critCategory)
    local statRef = critContext and critContext.statRef or self:ResolveCritStatRef(defenceSystem, critCategory)
    local statValue = 0
    if statRef then
        if type(self.GetCachedCombatStatValue) == "function" then
            statValue = self:GetCachedCombatStatValue(context, actorUnit, statRef, 0)
        else
            statValue = Lookup.GetStatValue and Lookup.GetStatValue(actorUnit, statRef, 0) or 0
        end
    end
    local critBonusPercent = tonumber(weaponSkillCritBonusPercent) or 0

    if defenceSystem == "percent" then
        local chancePercent = Common.Clamp(baseCritChance + statValue + critBonusPercent, 0, 100)
        local roll = Dice.RollRandom and tonumber(Dice.RollRandom(context, 1, 100)) or 0
        return {
            success = roll <= chancePercent,
            chancePercent = chancePercent,
            roll = roll,
            statRef = statRef,
            statValue = statValue,
        }
    end

    local rollExpression = self:GetCombatRule("critical_roll_dice", "1d20")
    local rollMax = self:ResolveDiceExpressionMax(rollExpression, 1, 20)
    local roll = self:RollDiceExpression(context, rollExpression)
    local baseWindow = math.floor(((baseCritChance * rollMax) / 100) + 0.5)
    local threshold = math.max(1, rollMax - baseWindow + 1)
    local convertedBonus = math.floor(((critBonusPercent * rollMax) / 100) + 0.5)
    local total = Common.Round(roll + statValue + convertedBonus)
    return {
        success = total >= threshold,
        chancePercent = baseCritChance + critBonusPercent,
        roll = roll,
        rollMax = rollMax,
        threshold = threshold,
        total = total,
        convertedWeaponSkillBonus = convertedBonus,
        statRef = statRef,
        statValue = statValue,
    }
end

function Combat:ResolveEffectResultType(context, effect, actorUnit, defenceSystem, weaponSkillContext)
    local critCategory = self:ResolveCritCategory(effect)
    local critBonusPercent = type(weaponSkillContext) == "table" and tonumber(weaponSkillContext.critBonusPercent) or 0
    local canCrush = type(weaponSkillContext) == "table"
        and weaponSkillContext.isWeaponDamage == true
        and weaponSkillContext.canCrush == true
    if type(context) == "table" then
        context.critResolutionContext = context.critResolutionContext or {
            baseCritChance = self:ResolveBaseCritChance(critCategory),
            statRef = self:ResolveCritStatRef(defenceSystem, critCategory),
        }
    end

    if canCrush then
        local crushingRoll = self:ResolveCritRoll(defenceSystem, context, actorUnit, critCategory, critBonusPercent)
        if crushingRoll.success == true then
            return "crushing", crushingRoll
        end
    end

    local criticalRoll = self:ResolveCritRoll(defenceSystem, context, actorUnit, critCategory, critBonusPercent)
    if criticalRoll.success == true then
        return "critical", criticalRoll
    end

    return "hit", criticalRoll
end

function Combat:ApplyResourceDelta(unit, resourceRef, delta, options)
    if type(unit) ~= "table" then
        return false, nil, 0
    end

    local entry = Lookup.GetResourceEntry and Lookup.GetResourceEntry(unit, resourceRef) or nil
    if not entry then
        return false, nil, 0
    end

    local numericDelta = tonumber(delta) or 0
    if numericDelta == 0 then
        return false, entry, 0
    end

    local currentValue = tonumber(entry.currentValue)
    if currentValue == nil then
        currentValue = tonumber(entry.maxValue) or 0
    end

    local maxValue = tonumber(entry.maxValue)
    if maxValue == nil then
        maxValue = currentValue
    end

    local isHealthResource = self:IsHealthResource(resourceRef, options)
    local allowDeadHealth = type(options) == "table" and options.allowDeadHealth == true
    local nextValue = currentValue
    if not (isHealthResource and currentValue <= 0 and allowDeadHealth ~= true) then
        nextValue = currentValue + numericDelta
        if nextValue < 0 then
            nextValue = 0
        elseif maxValue ~= nil and maxValue >= 0 and nextValue > maxValue then
            nextValue = maxValue
        end
    end

    if nextValue == currentValue then
        return false, entry, 0
    end

    entry.currentValue = nextValue
    if entry.maxValue == nil then
        entry.maxValue = math.max(nextValue, maxValue or nextValue)
    end

    if isHealthResource and currentValue > 0 and nextValue <= 0 then
        local deathClient = type(options) == "table" and options.client or Addon.Client
        if deathClient and type(deathClient.RecordCombatDeath) == "function" then
            deathClient:RecordCombatDeath(
                type(options) == "table" and options.eventState or nil,
                unit,
                (type(options) == "table" and options.eventState and tostring(options.eventState.id or "") or "")
                    .. ":"
                    .. tostring(type(options) == "table" and options.eventState and options.eventState.turnNumber or "")
                    .. ":"
                    .. tostring(tonumber(unit.eventID) or 0)
            )
        end
        self:HandleUnitDeath({
            client = deathClient,
            context = options,
            eventState = type(options) == "table" and options.eventState or nil,
            queueAuraSync = type(options) == "table" and options.queueAuraSync == true,
            sessionState = type(options) == "table" and options.sessionState or nil,
            targetUnit = unit,
        })
    end

    return true, entry, nextValue - currentValue
end

function Combat:ResolveResourceEffectAmount(context, effect)
    local amount = tonumber(type(effect) == "table" and effect.amount or nil) or 0
    local amountMode = tostring(type(effect) == "table" and effect.amountMode or "flat")
    if amountMode == "flat" then
        return amount
    end

    local targetUnit = type(context) == "table" and (context.targetUnit or context.target) or nil
    local resourceRef = tostring(type(effect) == "table" and effect.resourceRef or "")
    local resourceEntry = type(targetUnit) == "table" and Lookup.GetResourceEntry and Lookup.GetResourceEntry(targetUnit, resourceRef) or nil
    local resourceValue = 0

    if amountMode == "base_percent" then
        local client = type(context) == "table" and context.client or Addon.Client
        local eventState = type(context) == "table" and context.eventState or nil
        local localUnit = type(client) == "table" and type(client.ResolveLocalEventUnit) == "function"
            and client:ResolveLocalEventUnit(eventState)
            or nil
        local targetEventId = tonumber(type(targetUnit) == "table" and targetUnit.eventID or nil)
        local localEventId = tonumber(type(localUnit) == "table" and localUnit.eventID or nil)
        local isLocalPlayer = type(targetUnit) == "table"
            and targetUnit.isPlayer == true
            and ((localUnit == targetUnit) or (targetEventId and localEventId and targetEventId == localEventId))

        if isLocalPlayer and type(Profile.GetResolvedBaseResourceValue) == "function" then
            resourceValue = tonumber(Profile.GetResolvedBaseResourceValue(resourceRef, {
                includeAuraBonuses = false,
            })) or 0
        end
    end

    if resourceValue <= 0 then
        resourceValue = tonumber(resourceEntry and resourceEntry.maxValue)
            or tonumber(resourceEntry and resourceEntry.currentValue)
            or 0
    end

    local resolvedAmount = math.ceil(resourceValue * math.abs(amount) / 100)
    return amount < 0 and -resolvedAmount or resolvedAmount
end

function Combat:PreviewResourceDelta(unit, resourceRef, delta, options)
    if type(unit) ~= "table" then
        return false, nil, 0
    end

    local entry = Lookup.GetResourceEntry and Lookup.GetResourceEntry(unit, resourceRef) or nil
    if not entry then
        return false, nil, 0
    end

    local numericDelta = tonumber(delta) or 0
    if numericDelta == 0 then
        return false, entry, 0
    end

    local currentValue = tonumber(entry.currentValue)
    if currentValue == nil then
        currentValue = tonumber(entry.maxValue) or 0
    end

    local maxValue = tonumber(entry.maxValue)
    if maxValue == nil then
        maxValue = currentValue
    end

    local allowDeadHealth = type(options) == "table" and options.allowDeadHealth == true
    local nextValue = currentValue
    if not (self:IsHealthResource(resourceRef, options) and currentValue <= 0 and allowDeadHealth ~= true) then
        nextValue = currentValue + numericDelta
        if nextValue < 0 then
            nextValue = 0
        elseif maxValue ~= nil and maxValue >= 0 and nextValue > maxValue then
            nextValue = maxValue
        end
    end

    local appliedDelta = nextValue - currentValue
    if appliedDelta == 0 then
        return false, {
            resourceRef = entry.resourceRef,
            currentValue = currentValue,
            maxValue = maxValue,
        }, 0
    end

    return true, {
        resourceRef = entry.resourceRef,
        currentValue = nextValue,
        maxValue = maxValue,
    }, appliedDelta
end

function Combat:GetOrCreateActionCombatEventState(castEntry, spell)
    if type(castEntry) ~= "table" then
        return nil
    end

    local state = castEntry.combatEventState
    local spellCasterEvents = self:CloneValue(type(spell) == "table" and spell.casterEvents or {})
    if type(state) == "table" then
        local hasPendingDamageLog = false
        if type(state.damageLogsByComponentKey) == "table" then
            hasPendingDamageLog = next(state.damageLogsByComponentKey) ~= nil
        end
        if state.pendingDamageCount == 0 and state.spellCasterEventsEmitted == true and hasPendingDamageLog ~= true then
            state.spellCasterEvents = spellCasterEvents
            state.spellCasterTargetEventIds = {}
            state.spellCasterTargetEventIdSet = {}
            state.spellCasterEventEmissions = {}
            state.spellCasterEventsEmitted = false
            state.pendingDamageCount = 0
            state.pendingDamageCountByComponentKey = {}
            state.damageLogsByComponentKey = {}
        end
        return state
    end

    state = {
        spellCasterEvents = spellCasterEvents,
        spellCasterTargetEventIds = {},
        spellCasterTargetEventIdSet = {},
        spellCasterEventEmissions = {},
        spellCasterEventsEmitted = false,
        pendingDamageCount = 0,
        pendingDamageCountByComponentKey = {},
        damageLogsByComponentKey = {},
    }
    castEntry.combatEventState = state
    return state
end

function Combat:RegisterActionDamageCombatLog(entry, damageResult)
    local context = type(entry) == "table" and entry.context or nil
    local castEntry = type(context) == "table" and context.castEntry or nil
    local spell = type(context) == "table" and context.spell or nil
    local state = self:GetOrCreateActionCombatEventState(castEntry, spell)
    local componentKey = Normalization.NormalizeToken(type(entry) == "table" and (entry.componentKey or (context and context.componentKey)) or nil)
    local amount = math.max(0, math.floor(tonumber(type(damageResult) == "table" and damageResult.amount or 0) or 0))
    if type(state) ~= "table" or not componentKey or amount < 0 then
        return false
    end

    state.damageLogsByComponentKey = state.damageLogsByComponentKey or {}
    local aggregate = state.damageLogsByComponentKey[componentKey]
    if type(aggregate) ~= "table" then
        aggregate = {
            eventId = tostring(type(entry) == "table" and ((entry.eventState and entry.eventState.id) or entry.eventId) or ""),
            entryType = "damage",
            casterDisplayName = tostring(type(entry) == "table" and entry.attackerUnit and entry.attackerUnit.name or "Unknown"),
            targetCount = 0,
            targetDisplayName = "Unknown",
            amountMin = nil,
            amountMax = nil,
            absorbedMin = nil,
            absorbedMax = nil,
            iconTexture = nil,
            spellIconTexture = type(Addon.Client) == "table" and type(Addon.Client.ResolveCombatLogSpellIcon) == "function"
                and Addon.Client:ResolveCombatLogSpellIcon(spell, type(context) == "table" and context.spellRef or nil)
                or nil,
            labelText = "",
            accentColor = nil,
            bonusDamageEntries = {},
        }
        state.damageLogsByComponentKey[componentKey] = aggregate
    end

    aggregate.targetCount = math.max(0, math.floor(tonumber(aggregate.targetCount) or 0)) + 1
    if aggregate.targetCount == 1 then
        aggregate.targetDisplayName = tostring(type(entry) == "table" and entry.defenderUnit and entry.defenderUnit.name or "Unknown")
    else
        aggregate.targetDisplayName = ("%d targets"):format(aggregate.targetCount)
    end

    if aggregate.amountMin == nil or amount < aggregate.amountMin then
        aggregate.amountMin = amount
    end
    if aggregate.amountMax == nil or amount > aggregate.amountMax then
        aggregate.amountMax = amount
    end
    local absorbedAmount = math.max(0, math.floor(tonumber(type(damageResult) == "table" and damageResult.absorbedAmount or 0) or 0))
    if aggregate.absorbedMin == nil or absorbedAmount < aggregate.absorbedMin then
        aggregate.absorbedMin = absorbedAmount
    end
    if aggregate.absorbedMax == nil or absorbedAmount > aggregate.absorbedMax then
        aggregate.absorbedMax = absorbedAmount
    end
    if tostring(type(damageResult) == "table" and damageResult.damageSchoolIcon or "") ~= "" then
        aggregate.iconTexture = tostring(damageResult.damageSchoolIcon)
    end
    if tostring(type(damageResult) == "table" and damageResult.damageSchoolName or "") ~= "" then
        aggregate.labelText = tostring(damageResult.damageSchoolName)
    end
    if aggregate.accentColor == nil then
        local effect = type(entry) == "table" and entry.effect or nil
        local schoolRef = type(effect) == "table" and effect.damageSchoolRefs and effect.damageSchoolRefs[1] or nil
        if type(Addon.Client) == "table" and type(Addon.Client.ResolveCombatLogDamageSchoolPresentation) == "function" then
            local _, resolvedLabel, resolvedColor = Addon.Client:ResolveCombatLogDamageSchoolPresentation(
                schoolRef,
                aggregate.labelText,
                aggregate.iconTexture
            )
            if tostring(aggregate.labelText or "") == "" and tostring(resolvedLabel or "") ~= "" then
                aggregate.labelText = tostring(resolvedLabel)
            end
            aggregate.accentColor = resolvedColor
        end
        if aggregate.accentColor == nil then
            local fallbackColor = UI.ResolveColor and UI.ResolveColor(nil, "accent") or nil
            if type(fallbackColor) == "table" then
                local function toByte(value, fallback)
                    local number = tonumber(value)
                    if number == nil then
                        number = fallback
                    end
                    if number <= 1 then
                        number = number * 255
                    end
                    return math.max(0, math.min(255, math.floor(number + 0.5)))
                end
                aggregate.accentColor = ("%02x%02x%02x%02x"):format(
                    toByte(fallbackColor.a, 1),
                    toByte(fallbackColor.r, 1),
                    toByte(fallbackColor.g, 1),
                    toByte(fallbackColor.b, 1)
                )
            end
        end
    end

    return true
end

function Combat:RegisterTriggeredActionBonusDamage(actionContext, targetUnit, damageResult, effect, combatEventId)
    if type(actionContext) ~= "table" or type(damageResult) ~= "table" then
        return false
    end

    local castEntry = type(actionContext) == "table" and actionContext.castEntry or nil
    local spell = type(actionContext) == "table" and actionContext.spell or nil
    local componentKey = normalizeToken(type(actionContext) == "table" and actionContext.componentKey or nil)
    local state = self:GetOrCreateActionCombatEventState(castEntry, spell)
    if type(state) ~= "table" or componentKey == nil then
        return false
    end

    local aggregate = type(state.damageLogsByComponentKey) == "table" and state.damageLogsByComponentKey[componentKey] or nil
    if type(aggregate) ~= "table" then
        return false
    end

    local amount = math.max(
        0,
        math.floor(
            tonumber(damageResult.amount)
                or math.abs(tonumber(damageResult.appliedDelta) or 0)
                or 0
        )
    )
    local absorbedAmount = math.max(0, math.floor(tonumber(damageResult.absorbedAmount) or 0))
    if amount <= 0 and absorbedAmount <= 0 then
        return false
    end

    local schoolRef = type(damageResult.damageSchoolRef) == "string" and damageResult.damageSchoolRef or nil
    if schoolRef == nil and type(effect) == "table" and type(effect.damageSchoolRefs) == "table" then
        schoolRef = effect.damageSchoolRefs[1]
    end

    local colorHex = nil
    if type(Addon.Client) == "table" and type(Addon.Client.ResolveCombatLogDamageSchoolPresentation) == "function" then
        local _, _, resolvedColor = Addon.Client:ResolveCombatLogDamageSchoolPresentation(
            schoolRef,
            damageResult.damageSchoolName,
            damageResult.damageSchoolIcon
        )
        colorHex = resolvedColor
    end

    aggregate.bonusDamageEntries = aggregate.bonusDamageEntries or {}
    aggregate.bonusDamageEntries[#aggregate.bonusDamageEntries + 1] = {
        amount = amount,
        absorbedAmount = absorbedAmount,
        colorHex = colorHex,
        targetEventId = tonumber(targetUnit and targetUnit.eventID) or 0,
        combatEventId = tostring(combatEventId or ""),
    }
    return true
end

function Combat:FlushActionDamageCombatLog(client, context, castEntry, spell, componentKey)
    local state = self:GetOrCreateActionCombatEventState(castEntry, spell)
    if type(state) ~= "table" then
        return false
    end

    componentKey = Normalization.NormalizeToken(componentKey)
    if not componentKey then
        return false
    end

    local aggregate = type(state.damageLogsByComponentKey) == "table" and state.damageLogsByComponentKey[componentKey] or nil
    if type(state.damageLogsByComponentKey) == "table" then
        state.damageLogsByComponentKey[componentKey] = nil
    end
    if type(aggregate) ~= "table" then
        return false
    end

    if type(client) ~= "table" or type(client.EmitCombatLogEntry) ~= "function" then
        return false
    end

    return client:EmitCombatLogEntry({
        eventId = aggregate.eventId,
        entryType = "damage",
        casterDisplayName = aggregate.casterDisplayName,
        targetDisplayName = aggregate.targetDisplayName,
        targetCount = aggregate.targetCount,
        amountMin = aggregate.amountMin,
        amountMax = aggregate.amountMax,
        iconTexture = aggregate.iconTexture,
        spellIconTexture = aggregate.spellIconTexture,
        labelText = tostring(aggregate.labelText or "") ~= "" and tostring(aggregate.labelText) or "True",
        detailText = buildAggregateDamageDetailText(aggregate),
        accentColor = aggregate.accentColor,
    })
end

function Combat:RegisterActionCombatEventTargets(state, targetEventIds)
    if type(state) ~= "table" or type(targetEventIds) ~= "table" then
        return false
    end

    local changed = false
    state.spellCasterTargetEventIds = state.spellCasterTargetEventIds or {}
    state.spellCasterTargetEventIdSet = state.spellCasterTargetEventIdSet or {}
    for index = 1, #targetEventIds do
        local targetEventId = math.floor(tonumber(targetEventIds[index]) or 0)
        if targetEventId > 0 and not state.spellCasterTargetEventIdSet[targetEventId] then
            state.spellCasterTargetEventIdSet[targetEventId] = true
            state.spellCasterTargetEventIds[#state.spellCasterTargetEventIds + 1] = targetEventId
            changed = true
        end
    end

    return changed
end

local function normalizeHookEventId(value)
    local text = string.lower(trimText(value or ""))
    return text ~= "" and text or nil
end

local function isOutcomeBoundHookEventId(eventId)
    return eventId == "on_auto_attack_hit"
        or eventId == "on_auto_attack_taken"
        or eventId == "on_melee_hit"
        or eventId == "on_melee_taken"
        or eventId == "on_ranged_hit"
        or eventId == "on_ranged_taken"
        or eventId == "on_spell_hit"
        or eventId == "on_spell_taken"
        or eventId == "on_heal"
        or eventId == "on_heal_taken"
        or eventId == "on_critical_hit"
        or eventId == "on_critical_hit_taken"
        or eventId == "on_critical_heal"
        or eventId == "on_critical_heal_taken"
end

local function shouldEmitHookEvent(eventId, emission)
    if not isOutcomeBoundHookEventId(eventId) then
        return true
    end

    local role = tostring(type(emission) == "table" and emission.role or "")
    local effectType = tostring(type(emission) == "table" and emission.effectType or "")
    local attackType = tostring(type(emission) == "table" and emission.attackType or "")
    local hitType = tostring(type(emission) == "table" and emission.hitType or "")
    local wasCritical = type(emission) == "table" and emission.wasCritical == true or false

    if eventId == "on_auto_attack_hit" then
        return role == "caster" and effectType == "damage" and hitType == "auto"
    end
    if eventId == "on_auto_attack_taken" then
        return role == "target" and effectType == "damage" and hitType == "auto"
    end
    if eventId == "on_heal" then
        return role == "caster" and effectType == "heal"
    end
    if eventId == "on_heal_taken" then
        return role == "target" and effectType == "heal"
    end
    if eventId == "on_critical_heal" then
        return role == "caster" and effectType == "heal" and wasCritical == true
    end
    if eventId == "on_critical_heal_taken" then
        return role == "target" and effectType == "heal" and wasCritical == true
    end
    if eventId == "on_melee_hit" then
        return role == "caster" and effectType == "damage" and attackType == "melee"
    end
    if eventId == "on_melee_taken" then
        return role == "target" and effectType == "damage" and attackType == "melee"
    end
    if eventId == "on_ranged_hit" then
        return role == "caster" and effectType == "damage" and attackType == "ranged"
    end
    if eventId == "on_ranged_taken" then
        return role == "target" and effectType == "damage" and attackType == "ranged"
    end
    if eventId == "on_spell_hit" then
        return role == "caster" and effectType == "damage" and attackType == "spell"
    end
    if eventId == "on_spell_taken" then
        return role == "target" and effectType == "damage" and attackType == "spell"
    end
    if eventId == "on_critical_hit" then
        return role == "caster" and effectType == "damage" and wasCritical == true
    end
    if eventId == "on_critical_hit_taken" then
        return role == "target" and effectType == "damage" and wasCritical == true
    end

    return true
end

function Combat:FilterHookEventIds(eventIds, emission)
    local filtered = {}
    for index = 1, #(eventIds or {}) do
        local eventId = normalizeHookEventId(eventIds[index])
        if eventId and shouldEmitHookEvent(eventId, emission) then
            filtered[#filtered + 1] = eventId
        end
    end

    return filtered
end

function Combat:GetGenericHookEventIds(eventIds)
    local filtered = {}
    for index = 1, #(eventIds or {}) do
        local eventId = normalizeHookEventId(eventIds[index])
        if eventId and not isOutcomeBoundHookEventId(eventId) then
            filtered[#filtered + 1] = eventId
        end
    end

    return filtered
end

function Combat:RegisterActionCasterEventOutcome(state, targetEventIds, emission)
    if type(state) ~= "table" or type(targetEventIds) ~= "table" or #targetEventIds == 0 or type(emission) ~= "table" then
        return false
    end

    local effectType = tostring(emission.effectType or "")
    if effectType == "" then
        return false
    end

    local attackType = tostring(emission.attackType or "")
    local hitType = tostring(emission.hitType or "")
    local wasCritical = emission.wasCritical == true
    local key = table.concat({
        effectType,
        attackType,
        hitType,
        wasCritical and "1" or "0",
    }, "|")

    state.spellCasterEventEmissions = state.spellCasterEventEmissions or {}
    local bucket = state.spellCasterEventEmissions[key]
    if type(bucket) ~= "table" then
        bucket = {
            effectType = effectType,
            attackType = attackType,
            hitType = hitType,
            wasCritical = wasCritical,
            targetEventIds = {},
            targetEventIdSet = {},
        }
        state.spellCasterEventEmissions[key] = bucket
    end

    local changed = false
    for index = 1, #targetEventIds do
        local targetEventId = math.floor(tonumber(targetEventIds[index]) or 0)
        if targetEventId > 0 and not bucket.targetEventIdSet[targetEventId] then
            bucket.targetEventIdSet[targetEventId] = true
            bucket.targetEventIds[#bucket.targetEventIds + 1] = targetEventId
            changed = true
        end
    end

    return changed
end

function Combat:RunHookList(client, context, eventIds, sourceEventId, targetEventIds)
    if type(context) ~= "table" then
        return false
    end

    local events = self.Events or nil
    if type(events) ~= "table"
        or type(events.Run) ~= "function"
        or type(eventIds) ~= "table"
        or #eventIds == 0
        or type(targetEventIds) ~= "table"
        or #targetEventIds == 0
    then
        return false
    end

    local changed = false
    local previousHookId = context.hookId
    local previousSourceEventId = context.sourceEventId
    local previousTargetEventIds = context.targetEventIds
    for index = 1, #eventIds do
        context.hookId = eventIds[index]
        context.sourceEventId = sourceEventId
        context.targetEventIds = targetEventIds
        changed = events:Run(client, context) or changed
    end

    context.hookId = previousHookId
    context.sourceEventId = previousSourceEventId
    context.targetEventIds = previousTargetEventIds
    return changed
end

function Combat:RunTargetHooks(client, context, eventIds, targetEventIds, sourceEventId)
    local resolvedSourceEventId = math.floor(tonumber(sourceEventId or (type(context) == "table" and context.casterUnit and context.casterUnit.eventID) or 0) or 0)
    if resolvedSourceEventId <= 0 then
        return false
    end

    local filteredEventIds = self:FilterHookEventIds(eventIds, {
        role = "target",
        effectType = type(context) == "table" and context.effectType or nil,
        attackType = type(context) == "table" and context.attackType or nil,
        hitType = type(context) == "table" and context.hitType or nil,
        wasCritical = type(context) == "table" and context.wasCritical == true,
    })
    if #filteredEventIds == 0 then
        return false
    end

    return self:RunHookList(client, context, filteredEventIds, resolvedSourceEventId, targetEventIds)
end

function Combat:RunCasterHooks(client, context, castEntry, spell)
    local state = self:GetOrCreateActionCombatEventState(castEntry, spell)
    if type(state) ~= "table" or state.spellCasterEventsEmitted == true then
        return false
    end

    local casterEventId = math.floor(tonumber(type(context) == "table" and context.casterUnit and context.casterUnit.eventID or 0) or 0)
    local targetEventIds = state.spellCasterTargetEventIds or {}
    if casterEventId <= 0 or type(state.spellCasterEvents) ~= "table" or #state.spellCasterEvents == 0 or #targetEventIds == 0 then
        return false
    end

    state.spellCasterEventsEmitted = true
    local changed = false
    local previousEffectType = type(context) == "table" and context.effectType or nil
    local previousAttackType = type(context) == "table" and context.attackType or nil
    local previousHitType = type(context) == "table" and context.hitType or nil
    local previousWasCritical = type(context) == "table" and context.wasCritical or nil

    local emissions = state.spellCasterEventEmissions or {}
    for _, emission in pairs(emissions) do
        local filteredEventIds = self:FilterHookEventIds(state.spellCasterEvents, {
            role = "caster",
            effectType = emission.effectType,
            attackType = emission.attackType,
            hitType = emission.hitType,
            wasCritical = emission.wasCritical,
        })
        if #filteredEventIds > 0 and #((emission and emission.targetEventIds) or {}) > 0 then
            context.effectType = emission.effectType
            context.attackType = emission.attackType
            context.hitType = emission.hitType
            context.wasCritical = emission.wasCritical == true
            changed = self:RunHookList(client, context, filteredEventIds, casterEventId, emission.targetEventIds) or changed
        end
    end

    context.effectType = previousEffectType
    context.attackType = previousAttackType
    context.hitType = previousHitType
    context.wasCritical = previousWasCritical

    local genericEventIds = self:GetGenericHookEventIds(state.spellCasterEvents)
    if #genericEventIds > 0 then
        changed = self:RunHookList(client, context, genericEventIds, casterEventId, targetEventIds) or changed
    end

    return changed
end

function Combat:BeginActionDamageResolution(castEntry, spell, componentKey)
    local state = self:GetOrCreateActionCombatEventState(castEntry, spell)
    if type(state) ~= "table" then
        return false
    end

    state.pendingDamageCount = math.max(0, math.floor(tonumber(state.pendingDamageCount) or 0)) + 1
    componentKey = Normalization.NormalizeToken(componentKey)
    if componentKey then
        state.pendingDamageCountByComponentKey = state.pendingDamageCountByComponentKey or {}
        state.pendingDamageCountByComponentKey[componentKey] = math.max(0, math.floor(tonumber(state.pendingDamageCountByComponentKey[componentKey]) or 0)) + 1
    end
    return true
end

function Combat:CompleteActionDamageResolution(client, entry, landed)
    local context = type(entry) == "table" and entry.context or nil
    local castEntry = type(context) == "table" and context.castEntry or nil
    local spell = type(context) == "table" and context.spell or nil
    local state = self:GetOrCreateActionCombatEventState(castEntry, spell)
    local componentKey = Normalization.NormalizeToken(type(entry) == "table" and (entry.componentKey or (context and context.componentKey)) or nil)
    if type(state) ~= "table" then
        return false
    end

    if landed == true then
        self:RegisterActionCombatEventTargets(state, { entry.defenderEventId })
    end

    state.pendingDamageCount = math.max(0, math.floor(tonumber(state.pendingDamageCount) or 0) - 1)
    local flushedCombatLog = false
    local shouldRunCasterHooks = landed == true and state.pendingDamageCount == 0
    if componentKey and type(state.pendingDamageCountByComponentKey) == "table" then
        local nextCount = math.max(0, math.floor(tonumber(state.pendingDamageCountByComponentKey[componentKey]) or 0) - 1)
        if nextCount > 0 then
            state.pendingDamageCountByComponentKey[componentKey] = nextCount
        else
            state.pendingDamageCountByComponentKey[componentKey] = nil
            if shouldRunCasterHooks ~= true then
                flushedCombatLog = self:FlushActionDamageCombatLog(client, context, castEntry, spell, componentKey) or flushedCombatLog
            end
        end
    end
    if shouldRunCasterHooks == true then
        local ranCasterHooks = self:RunCasterHooks(client, context, castEntry, spell) or false
        if componentKey then
            flushedCombatLog = self:FlushActionDamageCombatLog(client, context, castEntry, spell, componentKey) or flushedCombatLog
        end
        return ranCasterHooks or flushedCombatLog
    end

    return flushedCombatLog
end

function Combat:RegisterEffect(effectType, contract)
    local definition = contract
    local normalizedType = nil

    if type(effectType) == "table" and contract == nil then
        definition = effectType
        normalizedType = Normalization.NormalizeEffectType(definition.type or definition.effectType or definition.key)
    else
        normalizedType = Normalization.NormalizeEffectType(effectType)
    end

    if normalizedType == nil then
        error("Client.Combat:RegisterEffect(effectType, contract) requires a non-empty effect type.", 2)
    end

    if type(definition) ~= "table" then
        error(("Client.Combat:RegisterEffect(%q, contract) requires a contract table."):format(normalizedType), 2)
    end

    local contractType = Normalization.NormalizeEffectType(definition.type or definition.effectType or definition.key)
    if contractType ~= nil and contractType ~= normalizedType then
        error(("Client.Combat:RegisterEffect(%q, contract) received a mismatched contract type (%s)."):format(normalizedType, contractType), 2)
    end

    definition.type = normalizedType
    definition.effectType = normalizedType
    if type(definition.Normalize) ~= "function" then
        function definition:Normalize(value)
            return Normalization.NormalizeEffectData(self.type, value)
        end
    end
    if type(definition.CreateDefaults) ~= "function" and type(definition.defaults) == "table" then
        function definition:CreateDefaults()
            return Combat:CloneValue(self.defaults)
        end
    end

    Combat.Effects[normalizedType] = definition
    return definition
end

function Combat:GetEffect(effectType)
    local normalizedType = Normalization.NormalizeEffectType(effectType)
    if not normalizedType then
        return nil
    end

    return Combat.Effects and Combat.Effects[normalizedType] or nil
end

function Combat:HasEffect(effectType)
    return self:GetEffect(effectType) ~= nil
end

function Combat:GetEffectTypes()
    local effectTypes = {}

    for effectType in pairs(self.Effects or {}) do
        effectTypes[#effectTypes + 1] = effectType
    end

    table.sort(effectTypes)
    return effectTypes
end

function Combat:CreateEffectContract(definition)
    return self:RegisterEffect(definition)
end

function Combat:DispatchEffect(effectType, context, value, component)
    local contract = self:GetEffect(effectType)
    if not contract then
        return nil, nil
    end

    local normalized = contract.Normalize and contract:Normalize(value, component, context) or Normalization.NormalizeEffectData(contract.type, value)
    local handler = contract.Execute or contract.Apply or contract.Run
    if type(handler) == "function" then
        return handler(contract, context, normalized, component)
    end

    return true, normalized, contract
end

function Combat:DispatchComponentEffect(component, context)
    local normalizedComponent = Normalization.NormalizeComponent(component)
    if not normalizedComponent or not normalizedComponent.effect then
        return nil, nil, normalizedComponent
    end

    local effect = normalizedComponent.effect
    local contract = self:GetEffect(effect.type)
    if not contract then
        return nil, nil, normalizedComponent
    end

    local handler = contract.Execute or contract.Apply or contract.Run
    if type(handler) == "function" then
        return handler(contract, context, effect, normalizedComponent)
    end

    return true, effect, contract, normalizedComponent
end
