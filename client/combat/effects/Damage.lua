local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Combat = Addon.Client.Combat or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Combat = Addon.Client.Combat
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Registry = Addon.Internal.Registry or {}
local Database = Addon.Internal.Database or {}
local Dependencies = Database.Dependecies or {}
local Common = Addon.Utils.Common or {}
local Dice = Addon.Utils.Dice or {}
local Lookup = Addon.Utils.Lookup or {}
local Normalization = Addon.Client.Combat.Normalization or {}
local Debug = Addon.Debug
local function getAuraManager()
    return Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraManager or nil
end

local function getProfile()
    return Addon.Internal and Addon.Internal.Profile or {}
end

local DEFAULT_ATTACK_ROLL_DICE = "1d20"
local DEFAULT_DEFENCE_ROLL_DICE = "1d20"
local RESULT_PASS = "pass"
local RESULT_FAIL = "fail"
local HIT_CHECK_REQUEST_OPCODE = Operations.GetOpcode and Operations:GetOpcode("COMBAT_HIT_CHECK_REQUEST") or nil
local trimText = Normalization.TrimText
local normalizeToken = Normalization.NormalizeToken
local normalizeResultToken = Normalization.NormalizeResultToken
local splitList = Normalization.SplitList

local function getPercentModifierStatValue(unit, statRef)
    local normalizedStatRef = normalizeToken(statRef)
    if not normalizedStatRef then
        return 0
    end

    return tonumber(Lookup.GetStatValue and Lookup.GetStatValue(unit, normalizedStatRef, 0) or 0) or 0
end

local function applyPercentModifier(amount, percentValue, invert)
    local numericAmount = tonumber(amount) or 0
    local numericPercent = tonumber(percentValue) or 0
    local factor = invert and (1 - (numericPercent / 100)) or (1 + (numericPercent / 100))
    return numericAmount * factor
end

local function buildThreatUpdatePayload(targetUnit, sourceUnit, amount)
    local targetEventId = math.floor(tonumber(targetUnit and targetUnit.eventID) or 0)
    local sourceEventId = math.floor(tonumber(sourceUnit and sourceUnit.eventID) or 0)
    if targetEventId <= 0 or sourceEventId <= 0 then
        return nil
    end

    return {
        targetEventId = targetEventId,
        sourceEventId = sourceEventId,
        amount = math.max(0, Common.Round(amount or 0)),
    }
end

local function applyThreatToUnit(targetUnit, sourceEventId, threatAmount)
    local numericSourceEventId = math.floor(tonumber(sourceEventId) or 0)
    local numericThreatAmount = math.max(0, Common.Round(threatAmount or 0))
    if type(targetUnit) ~= "table" or numericSourceEventId <= 0 or numericThreatAmount <= 0 then
        return false, numericThreatAmount, 0
    end

    targetUnit.threatTable = type(targetUnit.threatTable) == "table" and targetUnit.threatTable or {}
    local previousThreat = tonumber(targetUnit.threatTable[numericSourceEventId]) or 0
    targetUnit.threatTable[numericSourceEventId] = previousThreat + numericThreatAmount
    return true, numericThreatAmount, targetUnit.threatTable[numericSourceEventId]
end

local function buildCombatResult(entry, resultToken, resultType)
    return {
        effectType = "damage",
        resultType = resultType or resultToken or "invalid",
        hitCheckResult = resultToken,
        landed = resultToken == RESULT_PASS,
        pending = resultToken == nil,
        amount = 0,
        checkId = entry and entry.checkId or nil,
        eventId = entry and entry.eventId or nil,
        spellRef = entry and entry.spellRef or nil,
        componentKey = entry and entry.componentKey or nil,
    }
end

function Combat:GetCombatRule(ruleKey, fallback)
    return self:GetRuleValue("combat", ruleKey, fallback)
end

function Combat:RollDiceExpression(context, expression)
    return Dice.RollExpression and Dice.RollExpression(context, expression, 1, 20) or 0
end

function Combat:ResolveHitCheckAttackType(effect, component)
    local rawValue = type(effect) == "table" and effect.damageType or nil
    if rawValue == nil and type(component) == "table" and type(component.effect) == "table" then
        rawValue = component.effect.damageType
    end
    if rawValue == nil and type(component) == "table" then
        rawValue = component.damageType
    end

    local attackType = string.lower(trimText(rawValue or "spell"))
    if attackType ~= "melee" and attackType ~= "ranged" then
        attackType = "spell"
    end

    return attackType
end

function Combat:ResolveDefenceSystem()
    local defenceSystem = string.lower(trimText(self:GetCombatRule("defence_system", "ac") or "ac"))
    if defenceSystem == "ac" or defenceSystem == "simple" or defenceSystem == "complex" or defenceSystem == "percent" then
        return defenceSystem
    end

    return nil
end

function Combat:ResolveComplexDefenceStats(attackType)
    return splitList(self:GetCombatRule(("complex_defence_stats_%s"):format(attackType or "spell"), {}))
end

function Combat:ResolveAttackStatRef(defenceSystem, attackType)
    if defenceSystem == "percent" then
        return normalizeToken(self:GetCombatRule(("percent_%s_hit_stat"):format(attackType or "spell"), ""))
    end

    return normalizeToken(self:GetCombatRule("simple_attack_stat", ""))
end

function Combat:ResolveDefenceStatRef(defenceSystem, attackType)
    if defenceSystem == "ac" then
        return normalizeToken(self:GetCombatRule("armor_class_stat", ""))
    end
    if defenceSystem == "simple" then
        return normalizeToken(self:GetCombatRule("simple_defence_stat", ""))
    end
    if defenceSystem == "percent" then
        return normalizeToken(self:GetCombatRule(("percent_%s_resistance_stat"):format(attackType or "spell"), ""))
    end

    return nil
end

function Combat:ResolvePercentResistanceStatRefs(attackType)
    return splitList(self:GetCombatRule(("percent_%s_resistance_stat"):format(attackType or "spell"), {}))
end

function Combat:SumStatValues(unit, statRefs)
    local total = 0
    for index = 1, #(statRefs or {}) do
        local statRef = normalizeToken(statRefs[index])
        if statRef then
            total = total + (Lookup.GetStatValue and Lookup.GetStatValue(unit, statRef, 0) or 0)
        end
    end

    return total
end

function Combat:ResolveSpellComponent(spellRef, componentKey)
    if type(Registry.ResolveSpellReference) ~= "function" then
        return nil, nil, nil
    end

    local dataset, spell = Registry:ResolveSpellReference(spellRef)
    if not dataset or not spell then
        return nil, nil, nil
    end

    local normalizedComponentKey = normalizeToken(componentKey)
    if not normalizedComponentKey then
        return dataset, spell, nil
    end

    for index = 1, #(spell.components or {}) do
        local component = spell.components[index]
        if normalizeToken(component and component.key) == normalizedComponentKey then
            return dataset, spell, component
        end
    end

    return dataset, spell, nil
end

function Combat:ResolveDamageAmount(context, effect)
    local attackerUnit = type(context) == "table" and (context.attackerUnit or context.casterUnit or context.caster) or nil
    local baseDamage = tonumber(effect and effect.baseDamage) or 0
    local statScaling = 0
    local weaponDamage = 0
    local weaponDamageCoefficient = tonumber(effect and effect.weaponDamageCoefficient) or 1

    local function resolveWeaponRefForSlot(unit, slotKey, fallbackField)
        if type(unit) ~= "table" then
            return nil
        end

        local eventRef = normalizeToken(unit[fallbackField])
        if eventRef then
            return eventRef
        end

        local resolvedUnit = type(unit.GetResolvedUnit) == "function" and unit:GetResolvedUnit() or nil
        local resolvedRef = normalizeToken(resolvedUnit and resolvedUnit[fallbackField])
        if resolvedRef then
            return resolvedRef
        end

        local profile = getProfile()
        if unit.isPlayer == true and type(profile.GetEquippedItem) == "function" then
            local equipped = profile.GetEquippedItem(slotKey)
            local itemRef = equipped and equipped.itemRef or nil
            return normalizeToken(itemRef)
        end

        return nil
    end

    local function resolveWeaponDefinition(itemRef)
        if not itemRef then
            return nil
        end

        local profile = getProfile()
        local equipment = profile.Equipment or nil
        if equipment and type(equipment.ResolveItemDefinition) == "function" then
            local item = equipment.ResolveItemDefinition(itemRef)
            if item then
                return item
            end
        end

        if type(Dependencies.ParseSourceStatRef) == "function" and type(Database.GetDatasetByID) == "function" then
            local datasetId, itemId = Dependencies.ParseSourceStatRef(itemRef)
            local dataset = datasetId and Database.GetDatasetByID(datasetId) or nil
            for index = 1, #((dataset and dataset.items) or {}) do
                local candidate = dataset.items[index]
                if tostring(candidate and candidate.id or "") == tostring(itemId or "") then
                    return candidate
                end
            end
        end

        return nil
    end

    local function resolveWeaponDamageValue(itemRef)
        local item = resolveWeaponDefinition(itemRef)
        if type(item) ~= "table" then
            return 0
        end

        local damageMode = tostring(item.damageMode or "fixed")
        if damageMode == "range" then
            local minDamage = math.floor(tonumber(item.minDamagePerTurn) or 0)
            local maxDamage = math.floor(tonumber(item.maxDamagePerTurn) or 0)
            if maxDamage < minDamage then
                maxDamage = minDamage
            end
            return math.max(0, tonumber(Dice.RollRandom and Dice.RollRandom(context, minDamage, maxDamage) or minDamage) or 0)
        end

        return math.max(0, tonumber(item.damagePerTurn) or 0)
    end

    local function appendWeaponDamage(ref)
        if ref then
            weaponDamage = weaponDamage + resolveWeaponDamageValue(ref)
        end
    end

    local attackType = self:ResolveHitCheckAttackType(effect)
    local weaponDamageMode = tostring(effect and effect.weaponDamageMode or "none")
    if weaponDamageMode ~= "none" then
        local primarySlotKey = attackType == "ranged" and "ranged" or "mainhand"
        local primaryField = attackType == "ranged" and "rangedWeapon" or "mainHandWeapon"
        if weaponDamageMode == "main_hand" or weaponDamageMode == "both" then
            appendWeaponDamage(resolveWeaponRefForSlot(attackerUnit, primarySlotKey, primaryField))
        end
        if weaponDamageMode == "off_hand" or weaponDamageMode == "both" then
            appendWeaponDamage(resolveWeaponRefForSlot(attackerUnit, "offhand", "offHandWeapon"))
        end
    end

    for index = 1, #(effect and effect.statScaling or {}) do
        local entry = effect.statScaling[index]
        if type(entry) == "table" then
            local statRef = normalizeToken(entry.statRef)
            if statRef then
                local statValue = Lookup.GetStatValue and Lookup.GetStatValue(attackerUnit, statRef, 0) or 0
                local coefficient = tonumber(entry.coefficient) or 0
                statScaling = statScaling + (statValue * coefficient)
            end
        end
    end

    local variance = Dice.RollVariance and Dice.RollVariance(context) or 1
    return math.max(0, Common.Round((baseDamage + (weaponDamage * weaponDamageCoefficient) + statScaling) * variance))
end

local function buildResolvedDamageResult(self, entry)
    if type(entry) ~= "table" or type(entry.defenderUnit) ~= "table" then
        return false, nil
    end

    local rawDamage = math.max(0, tonumber(entry.rawDamage) or 0)
    local resultType = normalizeToken(entry.resultType) or "hit"
    local result = {
        resultType = resultType,
        wasCritical = resultType == "critical" or resultType == "crushing",
        rawDamage = rawDamage,
        amount = 0,
        mitigated = 0,
        applied = false,
        resourceEntry = nil,
        healthResourceRef = nil,
        hitType = nil,
        appliedDelta = 0,
        resourceDeltas = {},
        damageSchoolName = "",
        damageSchoolIcon = nil,
        threatGenerated = 0,
        threatApplied = false,
        threatSourceEventId = 0,
        threatTargetEventId = 0,
        threatTotal = 0,
        threatUpdate = nil,
    }
    if rawDamage <= 0 then
        return false, result
    end

    local effect = type(entry.effect) == "table" and entry.effect or nil
    local component = type(entry.component) == "table" and entry.component or nil
    if type(effect) ~= "table" or type(component) ~= "table" then
        local _, _, resolvedComponent = self:ResolveSpellComponent(entry.spellRef, entry.componentKey)
        component = resolvedComponent
        effect = type(component) == "table" and component.effect or nil
    end
    if type(effect) ~= "table" then
        return false, result
    end
    result.hitType = normalizeToken(effect.hitType) or "ability"

    local scaledRawDamage = rawDamage
    if resultType == "crushing" then
        scaledRawDamage = scaledRawDamage * (tonumber(self:GetCombatRule("crushing_blow_damage_multiplier", 1.5)) or 1.5)
    elseif resultType == "critical" then
        scaledRawDamage = scaledRawDamage * (tonumber(self:GetCombatRule("critical_damage_multiplier", 2.0)) or 2.0)
    end
    local finalDamage = scaledRawDamage
    local schoolNames = {}
    local damageSchoolRefs = effect.damageSchoolRefs or {}
    for schoolIndex = 1, #damageSchoolRefs do
        local schoolRef = normalizeToken(damageSchoolRefs[schoolIndex])
        if schoolRef then
            local _, damageSchool = self:ResolveDamageSchoolReference(schoolRef)
            if damageSchool then
                local name = tostring(damageSchool.name or "")
                if name ~= "" then
                    schoolNames[#schoolNames + 1] = name
                end
                if result.damageSchoolIcon == nil and tostring(damageSchool.icon or "") ~= "" then
                    result.damageSchoolIcon = tostring(damageSchool.icon)
                end

                local mitigationStatRef = normalizeToken(damageSchool.mitigationStatRef)
                local mitigationStatValue = mitigationStatRef and (Lookup.GetStatValue and Lookup.GetStatValue(entry.defenderUnit, mitigationStatRef, 0) or 0) or 0
                local mitigation = self:ResolveDamageSchoolMitigation(
                    damageSchool,
                    mitigationStatValue,
                    self:GetUnitLevel(entry.defenderUnit, entry.eventState)
                )
                if mitigation.mode == "direct" then
                    finalDamage = finalDamage - (tonumber(mitigation.flat) or 0)
                else
                    finalDamage = finalDamage * (1 - ((tonumber(mitigation.percent) or 0) / 100))
                end
            end
        end
    end

    finalDamage = applyPercentModifier(
        finalDamage,
        getPercentModifierStatValue(entry.attackerUnit, self:GetCombatRule("damage_dealt_stat", "")),
        false
    )

    local reductionStatRef = normalizeToken(self:GetCombatRule("damage_reduction_stat", ""))
    if reductionStatRef then
        local reductionValue = Lookup.GetStatValue and Lookup.GetStatValue(entry.defenderUnit, reductionStatRef, 0) or 0
        finalDamage = applyPercentModifier(finalDamage, reductionValue, true)
    end

    finalDamage = math.max(0, Common.Round(finalDamage))
    scaledRawDamage = math.max(0, Common.Round(scaledRawDamage))
    result.amount = finalDamage
    result.mitigated = math.max(0, scaledRawDamage - finalDamage)
    result.mitigationPercent = scaledRawDamage > 0 and ((result.mitigated / scaledRawDamage) * 100) or 0
    result.damageSchoolName = table.concat(schoolNames, ", ")
    if result.damageSchoolName == "" then
        result.damageSchoolName = "True"
    end

    if entry.defenderUnit.isPlayer ~= true and tonumber(result.amount) > 0 then
        local attackerEventId = math.floor(tonumber(entry.attackerEventId or (entry.attackerUnit and entry.attackerUnit.eventID)) or 0)
        local defenderEventId = math.floor(tonumber(entry.defenderEventId or (entry.defenderUnit and entry.defenderUnit.eventID)) or 0)
        local threatCoefficient = tonumber(effect.threatCoefficient) or 1
        local threatAmount = math.max(0, Common.Round(tonumber(result.amount) * threatCoefficient))
        threatAmount = math.max(0, Common.Round(applyPercentModifier(
            threatAmount,
            getPercentModifierStatValue(entry.attackerUnit, self:GetCombatRule("threat_generated_stat", "")),
            false
        )))
        local threatApplied, generatedThreat, totalThreat = applyThreatToUnit(
            entry.defenderUnit,
            attackerEventId,
            threatAmount
        )
        result.threatGenerated = generatedThreat
        result.threatApplied = threatApplied
        result.threatSourceEventId = attackerEventId
        result.threatTargetEventId = defenderEventId
        result.threatTotal = totalThreat
        result.threatUpdate = buildThreatUpdatePayload(entry.defenderUnit, entry.attackerUnit, generatedThreat)
    end

    return true, result
end

function Combat:BuildDamagePreview(entry)
    if type(entry) ~= "table" then
        return nil
    end
    if type(entry.damagePreview) == "table" then
        return entry.damagePreview
    end

    local _, result = buildResolvedDamageResult(self, entry)
    if type(result) == "table" then
        entry.damagePreview = result
    end
    return result
end

function Combat:ApplyResolvedDamage(entry, previewOnly)
    local computed, result = buildResolvedDamageResult(self, entry)
    if not computed or type(result) ~= "table" then
        return false, result
    end
    local finalDamage = tonumber(result.amount) or 0

    local healthResourceRef = type(entry.context) == "table" and normalizeToken(entry.context.healthResourceRef) or nil
    if not healthResourceRef then
        healthResourceRef = normalizeToken(entry.eventState and entry.eventState.healthResourceRef)
    end
    if not healthResourceRef then
        healthResourceRef = normalizeToken(self:GetHealthResourceRef())
    end
    result.healthResourceRef = healthResourceRef
    if not healthResourceRef or finalDamage <= 0 then
        return false, result
    end

    if not (Lookup.GetResourceEntry and Lookup.GetResourceEntry(entry.defenderUnit, healthResourceRef)) then
        local sourceEntry = nil
        local resolvedUnit = entry.defenderUnit.GetResolvedUnit and entry.defenderUnit:GetResolvedUnit() or nil
        local resolvedResources = type(resolvedUnit) == "table" and resolvedUnit.resources or nil
        for index = 1, #(resolvedResources or {}) do
            local candidate = resolvedResources[index]
            if normalizeToken(candidate and candidate.resourceRef) == healthResourceRef then
                sourceEntry = candidate
                break
            end
        end
        if not sourceEntry and type(Dependencies.ParseSourceStatRef) == "function" and type(Database.GetDatasetByID) == "function" then
            local datasetId, resourceId = Dependencies.ParseSourceStatRef(healthResourceRef)
            local dataset = datasetId and Database.GetDatasetByID(datasetId) or nil
            local resources = type(dataset) == "table" and dataset.resources or nil
            for index = 1, #(resources or {}) do
                local candidate = resources[index]
                if tostring(candidate and candidate.id or "") == tostring(resourceId or "") then
                    sourceEntry = candidate
                    break
                end
            end
        end
        if sourceEntry then
            local playerCount = 0
            for index = 1, #(entry.eventState and entry.eventState.units or {}) do
                if entry.eventState.units[index] and entry.eventState.units[index].isPlayer == true then
                    playerCount = playerCount + 1
                end
            end

            local currentValue = sourceEntry.currentValue
            local maxValue = sourceEntry.maxValue
            if currentValue == nil and maxValue == nil then
                if sourceEntry.value ~= nil or sourceEntry.perPlayer ~= nil then
                    local scaledValue = (tonumber(sourceEntry.value) or 0) + ((tonumber(sourceEntry.perPlayer) or 0) * playerCount)
                    currentValue = scaledValue
                    maxValue = scaledValue
                else
                    local baseValue = tonumber(sourceEntry.baseValue) or 0
                    local derivedValue = 0
                    if tostring(sourceEntry.valueMode or "manual") == "derived" and sourceEntry.sourceStatRef then
                        derivedValue = (Lookup.GetStatValue and Lookup.GetStatValue(entry.defenderUnit, sourceEntry.sourceStatRef, 0) or 0) * (tonumber(sourceEntry.multiplier) or 0)
                    end
                    local resolvedValue = baseValue + derivedValue
                    currentValue = sourceEntry.startsAtZero == true and 0 or resolvedValue
                    maxValue = resolvedValue
                end
            end

            entry.defenderUnit.resources = entry.defenderUnit.resources or {}
            entry.defenderUnit.resources[#entry.defenderUnit.resources + 1] = {
                resourceRef = healthResourceRef,
                currentValue = tonumber(currentValue ~= nil and currentValue or maxValue) or 0,
                maxValue = tonumber(maxValue ~= nil and maxValue or currentValue) or 0,
            }
        end
    end

    -- Damage results are always previewed locally and become authoritative only once
    -- the corresponding RESOURCE_DELTA message is handled back through the client.
    local applied, resourceEntry, appliedDelta = self:PreviewResourceDelta(entry.defenderUnit, healthResourceRef, -finalDamage)
    result.applied = applied
    result.resourceEntry = resourceEntry
    result.appliedDelta = appliedDelta
    if applied and resourceEntry then
        result.resourceDeltas = {
            {
                resourceRef = healthResourceRef,
                delta = appliedDelta,
                maxValue = tonumber(resourceEntry.maxValue) or 0,
                currentValue = tonumber(resourceEntry.currentValue) or 0,
            },
        }
    end
    if not applied then
        return false, result
    end

    return true, result
end

function Combat:BuildAttackerTotal(context, attackerUnit, defenceSystem, attackType)
    local statContribution = self:ResolveAttackStatContribution(attackerUnit, defenceSystem, attackType)
    if defenceSystem == "percent" then
        local roll = Dice.RollRandom and tonumber(Dice.RollRandom(context, 1, 100)) or 0
        local total = Common.Round(roll + (tonumber(statContribution.statValue) or 0))
        return total, {
            roll = roll,
            statRef = statContribution.statRef,
            statValue = statContribution.statValue,
            baseTotal = total,
        }
    end

    local roll = self:RollDiceExpression(context, self:GetCombatRule("attack_roll_dice", DEFAULT_ATTACK_ROLL_DICE))
    local total = Common.Round(roll + (tonumber(statContribution.statValue) or 0))
    return total, {
        roll = roll,
        statRef = statContribution.statRef,
        statValue = statContribution.statValue,
        baseTotal = total,
    }
end

function Combat:ResolveHitCheckOutcome(entry, action)
    if type(entry) ~= "table" then
        return nil, nil
    end

    local actionId = type(action) == "table" and action.id or action
    if normalizeResultToken(actionId) == RESULT_PASS then
        return RESULT_PASS, {
            attackerTotal = tonumber(entry.attackerTotal) or 0,
            defenceSystem = RESULT_PASS,
        }
    end

    local resolvedSystem = type(action) == "table" and tostring(action.resolutionSystem or entry.defenceSystem or "") or tostring(entry.defenceSystem or "")
    if resolvedSystem ~= "ac" and resolvedSystem ~= "simple" and resolvedSystem ~= "complex" and resolvedSystem ~= "percent" then
        resolvedSystem = tostring(entry.defenceSystem or "")
    end

    local attackerTotal = tonumber(entry.attackerTotal) or 0
    if resolvedSystem == "ac" then
        local armorClassStat = self:ResolveDefenceStatRef("ac", entry.attackType)
        local armorClass = armorClassStat and (Lookup.GetStatValue and Lookup.GetStatValue(entry.defenderUnit, armorClassStat, 0) or 0) or 0
        return attackerTotal > armorClass and RESULT_PASS or RESULT_FAIL, {
            attackerTotal = attackerTotal,
            defenderTotal = armorClass,
            defenceStatRef = armorClassStat,
            defenceSystem = "ac",
        }
    end

    if resolvedSystem == "simple" then
        local defenceStatRef = self:ResolveDefenceStatRef("simple", entry.attackType)
        local roll = self:RollDiceExpression(entry.context, self:GetCombatRule("defence_roll_dice", DEFAULT_DEFENCE_ROLL_DICE))
        local defenceValue = defenceStatRef and (Lookup.GetStatValue and Lookup.GetStatValue(entry.defenderUnit, defenceStatRef, 0) or 0) or 0
        local defenderTotal = roll + defenceValue
        return attackerTotal > defenderTotal and RESULT_PASS or RESULT_FAIL, {
            attackerTotal = attackerTotal,
            defenderTotal = defenderTotal,
            defenceStatRef = defenceStatRef,
            defenceSystem = "simple",
        }
    end

    if resolvedSystem == "complex" then
        local defenceStatRef = normalizeToken(type(action) == "table" and action.statRef or actionId)
        local roll = self:RollDiceExpression(entry.context, self:GetCombatRule("defence_roll_dice", DEFAULT_DEFENCE_ROLL_DICE))
        local defenceValue = defenceStatRef and (Lookup.GetStatValue and Lookup.GetStatValue(entry.defenderUnit, defenceStatRef, 0) or 0) or 0
        local defenderTotal = roll + defenceValue
        return attackerTotal > defenderTotal and RESULT_PASS or RESULT_FAIL, {
            attackerTotal = attackerTotal,
            defenderTotal = defenderTotal,
            defenceStatRef = defenceStatRef,
            defenceSystem = "complex",
        }
    end

    if resolvedSystem == "percent" then
        local chosenResistanceStats = nil
        local chosenDefenceStatRef = type(action) == "table" and normalizeToken(action.statRef) or nil
        if chosenDefenceStatRef then
            chosenResistanceStats = { chosenDefenceStatRef }
        else
            chosenResistanceStats = self:ResolvePercentResistanceStatRefs(entry.attackType)
        end

        local resistanceValue = self:SumStatValues(entry.defenderUnit, chosenResistanceStats)
        local basePenalty = tonumber(self:GetCombatRule("percent_base_penalty", 0)) or 0
        local defenderThreshold = Common.Round(basePenalty + resistanceValue)
        return attackerTotal > defenderThreshold and RESULT_PASS or RESULT_FAIL, {
            attackerTotal = attackerTotal,
            defenderTotal = defenderThreshold,
            resistanceTotal = resistanceValue,
            basePenalty = basePenalty,
            defenceStatRef = chosenDefenceStatRef,
            defenceSystem = "percent",
        }
    end

    return nil, nil
end

function Combat:BuildHitCheckEntry(context, effect, component)
    local eventState = type(context) == "table" and context.eventState or nil
    if type(eventState) ~= "table" or eventState.active ~= true then
        eventState = Client.GetEventState and Client:GetEventState() or nil
    end

    local sessionState = type(context) == "table" and context.sessionState or nil
    if type(sessionState) ~= "table" or sessionState.active ~= true then
        sessionState = Client.GetState and Client:GetState() or nil
    end

    local attackerUnit = type(context) == "table" and (context.attackerUnit or context.casterUnit or context.caster) or nil
    local defenderUnit = type(context) == "table" and (context.defenderUnit or context.targetUnit or context.target) or nil
    local spellRef = type(context) == "table" and normalizeToken(context.spellRef) or nil
    local componentKey = normalizeToken(component and component.key or type(context) == "table" and context.componentKey or nil)
    local defenceSystem = self:ResolveDefenceSystem()
    local attackType = self:ResolveHitCheckAttackType(effect, component)
    local eventId = type(context) == "table" and normalizeToken(context.eventId) or nil
    if not eventId then
        eventId = normalizeToken(eventState and eventState.id)
    end

    if type(attackerUnit) ~= "table" or type(defenderUnit) ~= "table" or not spellRef or not componentKey or not defenceSystem or not eventId then
        return nil
    end

    self.PendingHitCheckCounter = (self.PendingHitCheckCounter or 0) + 1

    local weaponSkillContext = self:ResolveWeaponSkillContext({
        attackerUnit = attackerUnit,
        casterUnit = attackerUnit,
        eventState = eventState,
    }, effect, component)
    local attackerTotal, attackerRollContext = self:BuildAttackerTotal(context, attackerUnit, defenceSystem, attackType)
    local prePenaltyAttackerTotal = attackerTotal
    local attackModifierContext = self:ResolveAttackModifierContext(attackerUnit, defenceSystem, attackType, weaponSkillContext)
    attackerTotal, attackModifierContext.weaponSkillPenaltyValue = self:ApplyWeaponSkillHitPenalty(attackerTotal, defenceSystem, weaponSkillContext)
    attackModifierContext.baseTotal = prePenaltyAttackerTotal
    attackModifierContext.finalTotal = attackerTotal
    attackModifierContext.roll = type(attackerRollContext) == "table" and attackerRollContext.roll or nil
    if type(attackerRollContext) == "table" then
        attackerRollContext.weaponSkillPenaltyValue = attackModifierContext.weaponSkillPenaltyValue
        attackerRollContext.finalTotal = attackerTotal
        attackerRollContext.totalModifierValue = attackModifierContext.totalModifierValue
    end
    local resultType = self:ResolveEffectResultType(context, effect, attackerUnit, defenceSystem, weaponSkillContext)

    local entry = {
        checkId = ("%s:%d"):format(eventId, self.PendingHitCheckCounter),
        eventId = eventId,
        spellRef = spellRef,
        componentKey = componentKey,
        attackType = attackType,
        defenceSystem = defenceSystem,
        attackerUnit = attackerUnit,
        defenderUnit = defenderUnit,
        attackerEventId = tonumber(attackerUnit.eventID) or 0,
        defenderEventId = tonumber(defenderUnit.eventID) or 0,
        attackerTotal = attackerTotal,
        rawDamage = self:ResolveDamageAmount(context, effect),
        resultType = resultType,
        effect = effect,
        component = component,
        weaponSkillContext = weaponSkillContext,
        attackerRollContext = attackerRollContext,
        attackModifierContext = attackModifierContext,
        targetEvents = Combat:CloneValue(effect and effect.targetEvents or {}),
        context = context or {},
        sessionState = sessionState,
        eventState = eventState,
    }

    local _, preview = buildResolvedDamageResult(self, entry)
    if type(preview) == "table" then
        entry.damagePreview = preview
    end

    return entry
end

function Combat:BeginHitCheck(context, effect, component)
    local entry = self:BuildHitCheckEntry(context, effect, component)
    if not entry or entry.attackerEventId <= 0 or entry.defenderEventId <= 0 then
        return false, buildCombatResult(entry, nil, "invalid")
    end

    local auraManager = getAuraManager()
    if auraManager
        and type(auraManager.ShouldForceAutoHitAgainstTarget) == "function"
        and auraManager:ShouldForceAutoHitAgainstTarget(entry.eventState, entry.defenderEventId) == true
    then
        local completed, result = Combat:CompleteHitCheck(entry, RESULT_PASS, "forced-hit")
        if completed and type(Combat.ApplyResolvedDamage) == "function" then
            local _, damageResult = self:ApplyResolvedDamage(entry)
            entry.lastDamageResult = damageResult
            if type(self.FinalizeLocalDamageResult) == "function" then
                self:FinalizeLocalDamageResult(entry, damageResult)
            end
        end
        return completed, result
    end

    Client:SetPendingCombatHitCheck(entry)

    if entry.defenderUnit.isPlayer ~= true then
        local actionId = Combat.ChooseAutomaticReactionAction and Combat:ChooseAutomaticReactionAction(entry) or RESULT_PASS
        local resultToken, resolution = self:ResolveHitCheckOutcome(entry, actionId)
        entry.lastResolution = resolution
        if type(Combat.LogDefenceAttempt) == "function" then
            Combat:LogDefenceAttempt(entry, resultToken, resolution)
        end
        local completed, result = false, nil
        if type(Combat.CompleteHitCheck) == "function" then
            completed, result = Combat:CompleteHitCheck(entry, resultToken, "npc-local")
        end
        if completed and resultToken == RESULT_PASS then
            local _, damageResult = self:ApplyResolvedDamage(entry)
            entry.lastDamageResult = damageResult
            if type(self.FinalizeLocalDamageResult) == "function" then
                self:FinalizeLocalDamageResult(entry, damageResult)
            end
        elseif completed and resultToken == RESULT_FAIL then
            if type(Combat.CompleteActionDamageResolution) == "function" then
                Combat:CompleteActionDamageResolution(Client, entry, false)
            end
            if type(self.ShowMissCombatText) == "function" then
                self:ShowMissCombatText(entry)
            end
        end
        return completed, result
    end

    local localEventUnit = Client.ResolveLocalEventUnit and Client:ResolveLocalEventUnit(entry.eventState) or nil
    if tonumber(localEventUnit and localEventUnit.eventID) == entry.defenderEventId then
        entry.localOnly = true
        if Client.ShowCombatReaction then
            Client:ShowCombatReaction(entry)
        end
        local pendingResult = buildCombatResult(entry, nil, "pending")
        pendingResult.resultType = entry.resultType or pendingResult.resultType
        return true, pendingResult
    end

    local defenderName = Combat.ResolveSenderForUnit and Combat:ResolveSenderForUnit(entry.eventState, entry.defenderUnit) or ""
    if defenderName == "" or not Combat.SendCombatWhisper or not Combat:SendCombatWhisper(defenderName, HIT_CHECK_REQUEST_OPCODE, {
        entry.checkId,
        entry.eventId,
        entry.attackerEventId,
        entry.defenderEventId,
        entry.spellRef,
        entry.componentKey,
        entry.attackerTotal,
        entry.rawDamage,
        entry.resultType,
    }) then
        if Client.ClearPendingCombatHitCheck then
            Client:ClearPendingCombatHitCheck(entry.checkId)
        end
        return false, buildCombatResult(entry, nil, "send_failed")
    end

    local pendingResult = buildCombatResult(entry, nil, "pending")
    pendingResult.resultType = entry.resultType or pendingResult.resultType
    return true, pendingResult
end

function Combat:ExecuteDamageEffect(context, effect, component)
    return self:BeginHitCheck(context, effect, component)
end

local DamageEffect = Combat:CreateEffectContract({
    type = "damage",
    label = "Damage",
    description = "Deals damage to a target.",
    defaults = {
        type = "damage",
        baseDamage = 0,
        threatCoefficient = 1,
        weaponDamageMode = "none",
        weaponDamageCoefficient = 1,
        statScaling = {},
        damageSchoolRefs = {},
        hitType = "ability",
        damageType = "spell",
        alwaysHits = false,
        usesProjectile = false,
        projectilePath = "",
        projectileSpeed = 0,
        applyAura = false,
        auraRef = nil,
        auraStacks = 1,
        targetEvents = {},
    },
    fields = {
        "baseDamage",
        "threatCoefficient",
        "weaponDamageMode",
        "weaponDamageCoefficient",
        "statScaling",
        "damageSchoolRefs",
        "hitType",
        "damageType",
        "alwaysHits",
        "usesProjectile",
        "projectilePath",
        "projectileSpeed",
        "applyAura",
        "auraRef",
        "auraStacks",
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteDamageEffect(context, effect or self.defaults, component)
    end,
})

return DamageEffect
