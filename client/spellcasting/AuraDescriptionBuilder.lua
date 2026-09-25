local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Spellcasting = Addon.Client.Spellcasting or {}
local Combat = Addon.Client and Addon.Client.Combat or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Dependencies = Database and Database.Dependecies or {}
local ResourceSync = Addon.Internal and Addon.Internal.Comms and Addon.Internal.Comms.ResourceSync or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local TooltipTemplate = Spellcasting.TooltipTemplate or {}

local AuraDescriptionBuilder = Spellcasting.AuraDescriptionBuilder or {}
Spellcasting.AuraDescriptionBuilder = AuraDescriptionBuilder

local function trimText(value)
    local text = tostring(value or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function ensureString(value, fallback)
    local text = trimText(value)
    if text == "" then
        return fallback or ""
    end

    return text
end

local function sortedNumericKeys(values)
    local keys = {}
    for key in pairs(values or {}) do
        local numericKey = tonumber(key)
        if numericKey and numericKey > 0 and math.floor(numericKey) == numericKey then
            keys[#keys + 1] = {
                sortKey = numericKey,
                key = key,
            }
        end
    end

    table.sort(keys, function(left, right)
        return left.sortKey < right.sortKey
    end)
    return keys
end

local function joinClauses(clauses)
    local count = #(clauses or {})
    if count == 0 then
        return ""
    end
    if count == 1 then
        return clauses[1]
    end
    if count == 2 then
        return ("%s and %s"):format(clauses[1], clauses[2])
    end

    return table.concat(clauses, ", ", 1, count - 1) .. ", and " .. clauses[count]
end

local function formatTurnLabel(turns)
    local numericTurns = math.max(1, math.floor(tonumber(turns) or 1))
    if numericTurns == 1 then
        return "1 turn"
    end

    return ("%d turns"):format(numericTurns)
end

local function buildStackingDescription(auraDefinition, options)
    if type(auraDefinition) ~= "table" then
        return ""
    end

    local clauses = {}
    local appliedStacks = math.max(1, math.floor(tonumber(type(options) == "table" and options.stacks) or 1))
    local maxStacks = math.max(1, math.floor(tonumber(auraDefinition.maxStacks) or 1))

    if appliedStacks > 1 then
        clauses[#clauses + 1] = ("Applies %d stacks."):format(appliedStacks)
    end
    if maxStacks > 1 then
        clauses[#clauses + 1] = ("Stacks up to %d times."):format(maxStacks)
    end

    return table.concat(clauses, " ")
end

local function resolveAuraDefinition(auraRef, options)
    local normalizedAuraRef = trimText(auraRef)
    local optionDataset = type(options) == "table" and options.dataset or nil
    local optionDatasetId = type(options) == "table" and (
        options.datasetId
        or (type(optionDataset) == "table" and optionDataset.id)
        or options.sourceDatasetId
        or options.spellDatasetId
    ) or nil

    if normalizedAuraRef ~= "" and type(optionDataset) == "table" then
        local explicitDatasetId, explicitAuraId = nil, nil
        if type(Dependencies.ParseSourceStatRef) == "function" then
            explicitDatasetId, explicitAuraId = Dependencies.ParseSourceStatRef(normalizedAuraRef)
        end
        if explicitDatasetId == nil or explicitDatasetId == "" then
            explicitDatasetId = optionDatasetId
            explicitAuraId = normalizedAuraRef
        end

        if type(explicitDatasetId) == "string" and explicitDatasetId ~= ""
            and type(explicitAuraId) == "string" and explicitAuraId ~= ""
            and tostring(optionDataset.id or "") == explicitDatasetId
        then
            for index = 1, #((optionDataset and optionDataset.auras) or {}) do
                local aura = optionDataset.auras[index]
                if type(aura) == "table" and tostring(aura.id or "") == explicitAuraId then
                    return optionDataset, aura, ("%s:%s"):format(explicitDatasetId, explicitAuraId)
                end
            end
        end
    end

    local auraManager = Spellcasting.AuraManager or nil
    if type(auraManager) ~= "table" or type(auraManager.ResolveAuraDefinition) ~= "function" then
        return nil, nil, nil
    end

    return auraManager:ResolveAuraDefinition(auraRef, {
        datasetId = type(options) == "table" and options.datasetId or nil,
        dataset = type(options) == "table" and options.dataset or nil,
        sourceDatasetId = type(options) == "table" and options.sourceDatasetId or nil,
        spellDatasetId = type(options) == "table" and options.spellDatasetId or nil,
    })
end

local function resolveDamageSchoolName(schoolRef)
    if type(schoolRef) ~= "string" or schoolRef == "" then
        return nil
    end

    local datasetId, schoolId = nil, nil
    if type(Dependencies.ParseSourceStatRef) == "function" then
        datasetId, schoolId = Dependencies.ParseSourceStatRef(schoolRef)
    end

    if not datasetId or not schoolId then
        return schoolRef
    end

    local dataset = type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(datasetId) or nil
    for index = 1, #((dataset and dataset.damageSchools) or {}) do
        local damageSchool = dataset.damageSchools[index]
        if tostring(damageSchool and damageSchool.id or "") == tostring(schoolId) then
            local name = trimText(damageSchool and damageSchool.name or "")
            if name ~= "" then
                return name
            end
            break
        end
    end

    return schoolId
end

local function resolveDamageSchoolLabel(effect)
    local names = {}
    for index = 1, #(effect and effect.damageSchoolRefs or {}) do
        local name = resolveDamageSchoolName(effect.damageSchoolRefs[index])
        if name and name ~= "" then
            names[#names + 1] = name
        end
    end

    if #names == 0 then
        return "True"
    end

    return table.concat(names, "/")
end

local function resolveResourceName(resourceRef)
    local resolvedRow = type(Profile.GetResolvedResourceRow) == "function" and Profile.GetResolvedResourceRow(resourceRef) or nil
    local resolvedName = resolvedRow and resolvedRow.name or nil
    if type(resolvedName) == "string" and resolvedName ~= "" then
        return resolvedName
    end

    if type(ResourceSync.ResolveResourceName) == "function" then
        local syncName = tostring(ResourceSync.ResolveResourceName(resourceRef) or "")
        if syncName ~= "" then
            return syncName
        end
    end

    local resourceId = nil
    if type(Dependencies.ParseSourceStatRef) == "function" then
        _, resourceId = Dependencies.ParseSourceStatRef(resourceRef)
    end

    return ensureString(resourceId or resourceRef, "Resource")
end

local function resolveStatName(statRef)
    local resolvedRow = type(Profile.GetResolvedStatRow) == "function" and Profile.GetResolvedStatRow(statRef) or nil
    local resolvedName = resolvedRow and resolvedRow.name or nil
    if type(resolvedName) == "string" and resolvedName ~= "" then
        return resolvedName
    end

    local datasetId, statId = nil, nil
    if type(Dependencies.ParseSourceStatRef) == "function" then
        datasetId, statId = Dependencies.ParseSourceStatRef(statRef)
    end

    if datasetId and statId and type(Registry.ResolveStatReference) == "function" then
        local _, stat = Registry:ResolveStatReference(statRef)
        local name = trimText(stat and stat.name or "")
        if name ~= "" then
            return name
        end
    end

    return ensureString(statId or statRef, "a stat")
end

local function resolveDefenceLabel(statRef)
    local normalizedRef = ensureString(statRef)
    if normalizedRef == "" then
        return nil
    end

    if type(Registry.ResolveStatReference) == "function" then
        local _, stat = Registry:ResolveStatReference(normalizedRef)
        local defenceLabel = trimText(stat and stat.defenceLabel or "")
        if defenceLabel ~= "" then
            return defenceLabel
        end
    end

    return resolveStatName(normalizedRef)
end

local function resolveSkillName(skillRef)
    local resolvedRow = type(Profile.GetResolvedSkillRow) == "function" and Profile.GetResolvedSkillRow(skillRef) or nil
    local resolvedName = resolvedRow and resolvedRow.name or nil
    if type(resolvedName) == "string" and resolvedName ~= "" then
        return resolvedName
    end

    local skillName = type(Registry.ResolveSkillName) == "function" and Registry:ResolveSkillName(skillRef) or nil
    if type(skillName) == "string" and skillName ~= "" then
        return skillName
    end

    local _, skillId = ensureString(skillRef):match("^([^:]+):(.+)$")
    return ensureString(skillId or skillRef, "a skill")
end

local function isPercentDisplayStat(statRef)
    local resolvedRow = type(Profile.GetResolvedStatRow) == "function" and Profile.GetResolvedStatRow(statRef) or nil
    local resolvedDisplayMode = type(resolvedRow) == "table" and tostring(resolvedRow.displayMode or "") or ""
    if resolvedDisplayMode == "signed_percent" or resolvedDisplayMode == "equip_percent" then
        return true
    end

    local datasetId, statId = nil, nil
    if type(Dependencies.ParseSourceStatRef) == "function" then
        datasetId, statId = Dependencies.ParseSourceStatRef(statRef)
    end

    if datasetId and statId and type(Registry.ResolveStatReference) == "function" then
        local _, stat = Registry:ResolveStatReference(statRef)
        local displayMode = tostring(stat and stat.displayMode or "")
        return displayMode == "signed_percent" or displayMode == "equip_percent"
    end

    return false
end

local function resolveTargetContext(options)
    local targetContext = type(options) == "table" and options.targetContext or nil
    if type(targetContext) ~= "table" then
        return {
            subject = "the affected unit",
            object = "the affected unit",
            possessive = "the affected unit's",
            reflexive = "itself",
        }
    end

    return {
        subject = ensureString(targetContext.subject, "the affected unit"),
        object = ensureString(targetContext.object, "the affected unit"),
        possessive = ensureString(targetContext.possessive, "the affected unit's"),
        reflexive = ensureString(targetContext.reflexive, "itself"),
    }
end

local function buildAuraEffectContext(options)
    return {
        aura = {
            powerLevel = tonumber(type(options) == "table" and options.powerLevel) or 0,
            rankMultiplier = tonumber(type(options) == "table" and options.rankMultiplier) or 1,
            stacks = math.max(1, math.floor(tonumber(type(options) == "table" and options.stacks) or 1)),
        },
        casterUnit = type(options) == "table" and options.casterUnit or nil,
        targetUnit = type(options) == "table" and options.targetUnit or nil,
    }
end

local function resolveAmount(options, effect, baseField)
    local auraManager = Spellcasting.AuraManager or nil
    if type(auraManager) ~= "table" or type(auraManager.ResolveEffectAmount) ~= "function" then
        return 0
    end

    local amount = auraManager:ResolveEffectAmount(buildAuraEffectContext(options), effect, baseField)
    if type(Common.Round) == "function" then
        return Common.Round(amount)
    end

    return math.floor((tonumber(amount) or 0) + 0.5)
end

local function resolveAuraThreatDescription(auraDefinition)
    local hasHighThreat = false
    local hasModerateThreat = false
    local hasLowThreat = false

    for index = 1, #((type(auraDefinition) == "table" and auraDefinition.effects) or {}) do
        local effect = auraDefinition.effects[index]
        if type(effect) == "table" and tostring(effect.type or "") == "damage" and effect.threatCoefficient ~= nil then
            local threatCoefficient = tonumber(effect.threatCoefficient)
            if threatCoefficient and threatCoefficient > 1.8 then
                hasHighThreat = true
            elseif threatCoefficient and threatCoefficient > 1.2 then
                hasModerateThreat = true
            elseif threatCoefficient and threatCoefficient < 0.5 then
                hasLowThreat = true
            end
        end
    end

    if hasHighThreat then
        return "Generates a high amount of threat."
    end
    if hasModerateThreat then
        return "Generates a moderate amount of threat."
    end
    if hasLowThreat then
        return "Generates a low amount of threat."
    end
    return ""
end

local function appendAuraThreatDescription(auraDefinition, descriptionText)
    local description = trimText(descriptionText)
    local threatDescription = resolveAuraThreatDescription(auraDefinition)
    if threatDescription == "" then
        return description
    end
    if description == "" then
        return threatDescription
    end
    if description:sub(-#threatDescription) == threatDescription then
        return description
    end
    return description .. " " .. threatDescription
end

local function buildPassiveDamageSentence(effect, targetContext, options)
    local amount = math.max(0, resolveAmount(options, effect, "baseDamage"))
    local amountMode = tostring(effect and effect.amountMode or "flat")
    local schoolLabel = resolveDamageSchoolLabel(effect)
    local amountText = ""
    
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base"):format(amount)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max"):format(amount)
    else
        amountText = tostring(math.floor(amount))
    end
    
    return ("Deals %s %s damage each turn."):format(amountText, schoolLabel)
end

local function buildPassiveAbsorbSentence(effect, targetContext, options)
    local amountMode = tostring(effect and effect.amountMode or "flat")
    local amountText = nil
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base"):format(tonumber(effect and effect.baseAbsorption) or 0)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max"):format(tonumber(effect and effect.baseAbsorption) or 0)
    else
        amountText = tostring(math.max(0, resolveAmount(options, effect, "baseAbsorption")))
    end

    local schoolLabel = #((effect and effect.damageSchoolRefs) or {}) > 0
        and (resolveDamageSchoolLabel(effect) .. " damage")
        or "damage"
    return ("Absorbs %s %s."):format(amountText, schoolLabel)
end

local function buildPassiveHealSentence(effect, targetContext, options)
    local amount = math.max(0, resolveAmount(options, effect, "baseHealing"))
    local amountMode = tostring(effect and effect.amountMode or "flat")
    local amountText = ""
    
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base"):format(amount)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max"):format(amount)
    else
        amountText = tostring(math.floor(amount))
    end
    
    return ("Heals for %s health each turn."):format(amountText)
end

local function buildPassiveApplyAuraSentence(effect, targetContext, options)
    local _, auraDefinition = resolveAuraDefinition(effect and effect.auraRef or nil, options)
    local auraName = ensureString(auraDefinition and auraDefinition.name, "an aura")
    local targetObject = targetContext and targetContext.object or "the affected unit"
    local sentence = targetObject == "you"
        and ("Applies %s to you"):format(auraName)
        or ("Applies %s to %s"):format(auraName, targetObject)
    local stacks = math.max(1, math.floor(tonumber(effect and effect.stacks) or 1))
    local duration = math.max(0, math.floor(tonumber(effect and effect.duration) or 0))
    if stacks > 1 then
        sentence = ("%s with %d stacks"):format(sentence, stacks)
    end
    if duration > 0 then
        sentence = ("%s for %s"):format(sentence, formatTurnLabel(duration))
    end

    return sentence .. "."
end

local function buildPassiveResourceSentence(effect, targetContext)
    local amount = tonumber(effect and effect.amount) or 0
    local amountMode = tostring(effect and effect.amountMode or "flat")
    local resourceName = resolveResourceName(effect and effect.resourceRef or nil)
    local amountText = ""
    
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base %s"):format(amount, resourceName)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max %s"):format(amount, resourceName)
    else
        amountText = ("%d %s"):format(math.floor(amount), resourceName)
    end
    
    if amount >= 0 then
        return ("Restores %s each turn."):format(amountText)
    end

    local reduceAmountText = ""
    if amountMode == "base_percent" then
        reduceAmountText = ("%g%% of Base"):format(amount)
    elseif amountMode == "max_percent" then
        reduceAmountText = ("%g%% of Max"):format(amount)
    else
        reduceAmountText = tostring(math.floor(math.abs(amount)))
    end
    
    return ("Reduces %s by %s each turn."):format(resourceName, reduceAmountText)
end

local function buildPassiveStatSentence(effect, targetContext, options)
    local amount = resolveAmount(options, effect, "baseAmount")
    local statName = resolveStatName(effect and effect.statRef or nil)
    local numericAmount = math.abs(amount)
    local amountText = tostring(numericAmount)
    if tostring(effect and effect.operation or "flat") == "percent" or isPercentDisplayStat(effect and effect.statRef or nil) then
        amountText = amountText .. "%"
    end

    local verb = amount >= 0 and "Increases" or "Reduces"
    return ("%s %s by %s."):format(verb, statName, amountText)
end

local function buildPassiveSkillSentence(effect, targetContext, options)
    local amount = resolveAmount(options, effect, "baseAmount")
    local skillName = resolveSkillName(effect and effect.skillRef or nil)
    local numericAmount = math.abs(amount)
    local amountText = tostring(numericAmount)
    local possessive = targetContext and targetContext.possessive or "your"
    if amount >= 0 then
        return ("Increases %s skill in %s by %s."):format(possessive, skillName, amountText)
    end

    return ("Reduces %s skill in %s by %s."):format(possessive, skillName, amountText)
end

local function buildPassiveControlSentence(effect, targetContext, options)
    local sentences = {}
    local targetObject = targetContext and targetContext.object or "the affected unit"
    if effect and effect.cancelOnDamage == true then
        sentences[#sentences + 1] = ("Breaks when %s takes damage."):format(targetObject)
    end
    if effect and effect.preventCasting == true then
        if targetObject == "you" then
            sentences[#sentences + 1] = "Prevents you from casting spells."
        else
            sentences[#sentences + 1] = ("Prevents %s from casting spells."):format(targetObject)
        end
    end
    if tonumber(effect and effect.movementRangeOverride) == 0 then
        if targetObject == "you" then
            sentences[#sentences + 1] = "Sets your movement range to 0."
        else
            sentences[#sentences + 1] = ("Sets %s movement range to 0."):format(targetContext and targetContext.possessive or "the affected unit's")
        end
    end
    if effect and effect.forceAutoHitAgainstTarget == true then
        if targetObject == "you" then
            sentences[#sentences + 1] = "Causes all attacks against you to automatically hit."
        else
            sentences[#sentences + 1] = ("Causes all attacks against %s to automatically hit."):format(targetObject)
        end
    end

    if #sentences == 0 then
        return nil
    end

    return table.concat(sentences, " ")
end

local function resolveCombatTriggerLabel(combatEventId, targetContext, defenceStatRef, damageSchoolRef)
    local eventId = tostring(combatEventId or "")
    if eventId == "on_taunt" then
        if targetContext.subject == "you" then
            return "When you taunt an enemy"
        end
        return ("When %s taunts an enemy"):format(targetContext.subject)
    end
    if eventId == "on_taunted" then
        if targetContext.subject == "you" then
            return "When you are taunted"
        end
        return ("When %s is taunted"):format(targetContext.subject)
    end
    if eventId == "on_defence" then
        local defenceLabel = resolveDefenceLabel(defenceStatRef)
        if defenceLabel then
            defenceLabel = string.lower(defenceLabel)
            if targetContext.subject == "you" then
                return ("When you successfully %s an attack"):format(defenceLabel)
            end
            return ("When %s successfully %s an attack"):format(targetContext.subject, defenceLabel)
        end
        if targetContext.subject == "you" then
            return "When you successfully defend against an attack"
        end
        return ("When %s successfully defends against an attack"):format(targetContext.subject)
    end
    if eventId == "on_damage_type" then
        local damageSchoolLabel = resolveDamageSchoolName(damageSchoolRef)
        if damageSchoolLabel then
            if targetContext.subject == "you" then
                return ("When you deal %s damage"):format(damageSchoolLabel)
            end
            return ("When %s deals %s damage"):format(targetContext.subject, damageSchoolLabel)
        end
        if targetContext.subject == "you" then
            return "When you deal damage"
        end
        return ("When %s deals damage"):format(targetContext.subject)
    end
    if eventId == "on_auto_attack_hit" then
        if targetContext.subject == "you" then
            return "When you hit with a basic attack"
        end
        return ("When %s hits with a basic attack"):format(targetContext.subject)
    end
    if eventId == "on_auto_attack_taken" then
        if targetContext.subject == "you" then
            return "When you are victim of a basic attack"
        end
        return ("When %s is victim of a basic attack"):format(targetContext.subject)
    end
    if eventId == "on_melee_hit" then
        if targetContext.subject == "you" then
            return "When you hit with a melee attack"
        end
        return ("When %s hits with a melee attack"):format(targetContext.subject)
    end
    if eventId == "on_melee_taken" then
        if targetContext.subject == "you" then
            return "When you are hit by a melee attack"
        end
        return ("When %s is hit by a melee attack"):format(targetContext.subject)
    end
    if eventId == "on_ranged_hit" then
        if targetContext.subject == "you" then
            return "When you hit with a ranged attack"
        end
        return ("When %s hits with a ranged attack"):format(targetContext.subject)
    end
    if eventId == "on_ranged_taken" then
        if targetContext.subject == "you" then
            return "When you are hit by a ranged attack"
        end
        return ("When %s is hit by a ranged attack"):format(targetContext.subject)
    end
    if eventId == "on_spell_hit" then
        if targetContext.subject == "you" then
            return "When you hit with a spell"
        end
        return ("When %s hits with a spell"):format(targetContext.subject)
    end
    if eventId == "on_spell_taken" then
        if targetContext.subject == "you" then
            return "When you are hit by a spell"
        end
        return ("When %s is hit by a spell"):format(targetContext.subject)
    end
    if eventId == "on_heal" then
        if targetContext.subject == "you" then
            return "When you heal"
        end
        return ("When %s heals"):format(targetContext.subject)
    end
    if eventId == "on_heal_taken" then
        if targetContext.subject == "you" then
            return "When you are healed"
        end
        return ("When %s is healed"):format(targetContext.subject)
    end
    if eventId == "on_critical_hit" then
        if targetContext.subject == "you" then
            return "When you critically hit"
        end
        return ("When %s critically hits"):format(targetContext.subject)
    end
    if eventId == "on_critical_hit_taken" then
        if targetContext.subject == "you" then
            return "When you are critically hit"
        end
        return ("When %s is critically hit"):format(targetContext.subject)
    end
    if eventId == "on_critical_heal" then
        if targetContext.subject == "you" then
            return "When you critically heal"
        end
        return ("When %s critically heals"):format(targetContext.subject)
    end
    if eventId == "on_critical_heal_taken" then
        if targetContext.subject == "you" then
            return "When you receive a critical heal"
        end
        return ("When %s receives a critical heal"):format(targetContext.subject)
    end

    local events = Combat and Combat.Events or nil
    local definition = type(events) == "table" and type(events.GetDefinition) == "function" and events:GetDefinition(eventId) or nil
    if type(definition) == "table" and definition.label then
        return ("On %s"):format(tostring(definition.label))
    end

    return "When triggered"
end

local function normalizeChancePercent(value)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return 100
    end

    return math.max(0, math.min(100, numericValue))
end

local function resolveTriggeredTargetContext(combatEventId, triggerTarget, auraTargetContext)
    local eventId = tostring(combatEventId or "")
    local targetKey = tostring(triggerTarget or "event_other")
    if targetKey == "aura_caster" then
        return {
            subject = "you",
            object = "you",
            possessive = "your",
            reflexive = "yourself",
        }
    end
    if targetKey == "aura_target" then
        return auraTargetContext
    end
    if eventId == "on_damage_type" and targetKey == "event_source" then
        return {
            subject = "the damage dealer",
            object = "the damage dealer",
            possessive = "the damage dealer's",
            reflexive = "itself",
        }
    end
    if eventId == "on_damage_type" and targetKey == "event_other" then
        return {
            subject = "the damaged unit",
            object = "the damaged unit",
            possessive = "the damaged unit's",
            reflexive = "itself",
        }
    end
    if targetKey == "event_source" then
        if eventId == "on_heal" or eventId == "on_heal_taken" then
            return {
                subject = "the healer",
                object = "the healer",
                possessive = "the healer's",
                reflexive = "itself",
            }
        end
        if eventId == "on_critical_heal" or eventId == "on_critical_heal_taken" then
            return {
                subject = "the healer",
                object = "the healer",
                possessive = "the healer's",
                reflexive = "itself",
            }
        end
        if eventId == "on_spell_hit" or eventId == "on_spell_taken" then
            return {
                subject = "the caster",
                object = "the caster",
                possessive = "the caster's",
                reflexive = "itself",
            }
        end
        if eventId == "on_critical_hit" or eventId == "on_critical_hit_taken" then
            return {
                subject = "the attacker",
                object = "the attacker",
                possessive = "the attacker's",
                reflexive = "itself",
            }
        end
        return {
            subject = "the attacker",
            object = "the attacker",
            possessive = "the attacker's",
            reflexive = "itself",
        }
    end
    if eventId == "on_auto_attack_hit"
        or eventId == "on_melee_hit"
        or eventId == "on_ranged_hit"
        or eventId == "on_spell_hit"
        or eventId == "on_heal"
        or eventId == "on_critical_hit"
        or eventId == "on_critical_heal"
    then
        return {
            subject = "the target",
            object = "the target",
            possessive = "the target's",
            reflexive = "itself",
        }
    end
    if eventId == "on_auto_attack_taken"
        or eventId == "on_melee_taken"
        or eventId == "on_ranged_taken"
        or eventId == "on_spell_taken"
        or eventId == "on_heal_taken"
        or eventId == "on_critical_hit_taken"
        or eventId == "on_critical_heal_taken"
    then
        return auraTargetContext
    end
    if eventId == "on_taunt" then
        return {
            subject = "the taunted target",
            object = "the taunted target",
            possessive = "the taunted target's",
            reflexive = "itself",
        }
    end
    if eventId == "on_taunted" then
        return {
            subject = "the taunter",
            object = "the taunter",
            possessive = "the taunter's",
            reflexive = "itself",
        }
    end

    return auraTargetContext
end

local function buildEventDamageClause(effect, targetContext, options)
    local amount = math.max(0, resolveAmount(options, effect, "baseDamage"))
    local amountMode = tostring(effect and effect.amountMode or "flat")
    local schoolLabel = resolveDamageSchoolLabel(effect)
    local amountText = ""
    
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base"):format(amount)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max"):format(amount)
    else
        amountText = tostring(math.floor(amount))
    end
    
    if targetContext.subject == "you" then
        return ("you take %s %s damage"):format(amountText, schoolLabel)
    end

    return ("%s takes %s %s damage"):format(targetContext.subject, amountText, schoolLabel)
end

local function buildEventHealClause(effect, targetContext, options)
    local amount = math.max(0, resolveAmount(options, effect, "baseHealing"))
    local amountMode = tostring(effect and effect.amountMode or "flat")
    local amountText = ""
    
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base"):format(amount)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max"):format(amount)
    else
        amountText = tostring(math.floor(amount))
    end
    
    if targetContext.object == "you" then
        return ("heal yourself for %s health"):format(amountText)
    end

    return ("heal %s for %s health"):format(targetContext.object, amountText)
end

local function buildEventResourceClause(effect, targetContext)
    local amount = tonumber(effect and effect.amount) or 0
    local amountMode = tostring(effect and effect.amountMode or "flat")
    local resourceName = resolveResourceName(effect and effect.resourceRef or nil)
    
    local amountText = ""
    local lossAmountText = ""
    
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base %s"):format(amount, resourceName)
        lossAmountText = ("%g%% of Base"):format(amount)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max %s"):format(amount, resourceName)
        lossAmountText = ("%g%% of Max"):format(amount)
    else
        amountText = ("%d %s"):format(math.floor(amount), resourceName)
        lossAmountText = tostring(math.floor(math.abs(amount)))
    end
    
    if amount > 0 then
        if targetContext.object == "you" then
            return ("restore %s"):format(amountText)
        end
        return ("restore %s to %s"):format(amountText, targetContext.object)
    end

    if targetContext.object == "you" then
        return ("lose %s"):format(lossAmountText)
    end
    return ("reduce %s %s by %s"):format(targetContext.possessive, resourceName, lossAmountText)
end

local function buildEventApplyAuraClause(effect, targetContext, options)
    local _, auraDefinition = resolveAuraDefinition(effect and effect.auraRef or nil, options)
    local auraName = ensureString(auraDefinition and auraDefinition.name, "an aura")
    local clause = targetContext.object == "you"
        and ("apply %s to yourself"):format(auraName)
        or ("apply %s to %s"):format(auraName, targetContext.object)
    local stacks = math.max(1, math.floor(tonumber(effect and effect.stacks) or tonumber(effect and effect.auraStacks) or 1))
    local duration = math.max(0, math.floor(tonumber(effect and effect.duration) or 0))
    if stacks > 1 then
        clause = ("%s with %d stacks"):format(clause, stacks)
    end
    if duration > 0 then
        clause = ("%s for %s"):format(clause, formatTurnLabel(duration))
    end

    return clause
end

local function buildEventRemoveAuraClause(currentAuraName, currentAuraRef, effect, targetContext, options)
    local stacks = math.max(1, math.floor(tonumber(effect and effect.stacks) or 1))
    local authoredAuraRef = type(effect) == "table" and effect.auraRef or nil
    local clause = ("remove %d stack%s"):format(stacks, stacks == 1 and "" or "s")

    if type(authoredAuraRef) == "string" and authoredAuraRef ~= "" and authoredAuraRef ~= currentAuraRef then
        local _, auraDefinition = resolveAuraDefinition(authoredAuraRef, options)
        local auraName = ensureString(auraDefinition and auraDefinition.name, "an aura")
        clause = ("%s of %s"):format(clause, auraName)
        if targetContext.object ~= "you" then
            clause = ("%s from %s"):format(clause, targetContext.object)
        end
        return clause
    end

    if currentAuraName ~= "" then
        return clause
    end

    if targetContext.object ~= "you" then
        return ("%s from %s"):format(clause, targetContext.object)
    end

    return clause
end

local function buildEventInterruptClause(targetContext)
    if targetContext.object == "you" then
        return "interrupt yourself"
    end

    return ("interrupt %s"):format(targetContext.object)
end

local function buildEventRemoveHiddenClause(targetContext)
    if targetContext.object == "you" then
        return "reveal yourself"
    end

    return ("reveal %s"):format(targetContext.object)
end

local function buildEventRevertClause(targetContext)
    if targetContext.object == "you" then
        return "revert the last reversible spell received by you this turn"
    end

    return ("revert the last reversible spell received by %s this turn"):format(targetContext.object)
end

local function buildEventEffectClause(currentAuraName, currentAuraRef, combatEventId, triggerTarget, targetContext, effect, options)
    local effectType = tostring(effect and effect.type or "")
    local resolvedTargetContext = resolveTriggeredTargetContext(combatEventId, triggerTarget, targetContext)
    if effectType == "damage" then
        return buildEventDamageClause(effect, resolvedTargetContext, options)
    end
    if effectType == "heal" then
        return buildEventHealClause(effect, resolvedTargetContext, options)
    end
    if effectType == "resource" then
        return buildEventResourceClause(effect, resolvedTargetContext)
    end
    if effectType == "apply_aura" then
        return buildEventApplyAuraClause(effect, resolvedTargetContext, options)
    end
    if effectType == "remove_hidden" then
        return buildEventRemoveHiddenClause(resolvedTargetContext)
    end
    if effectType == "remove_aura" then
        return buildEventRemoveAuraClause(currentAuraName, currentAuraRef, effect, resolvedTargetContext, options)
    end
    if effectType == "interrupt" then
        return buildEventInterruptClause(resolvedTargetContext)
    end
    if effectType == "revert" then
        return buildEventRevertClause(resolvedTargetContext)
    end

    return nil
end

function AuraDescriptionBuilder:BuildGeneratedDescription(auraDefinition, options)
    if type(auraDefinition) ~= "table" then
        return ""
    end

    local targetContext = resolveTargetContext(options)
    local auraName = ensureString(auraDefinition.name, "")
    local currentAuraRef = type(options) == "table" and options.auraRef or nil
    local sentences = {}

    local passiveEffectKeys = sortedNumericKeys(auraDefinition.effects)
    for index = 1, #passiveEffectKeys do
        local effect = auraDefinition.effects[passiveEffectKeys[index].key]
        local effectType = tostring(effect and effect.type or "")
        local sentence = nil
        if effectType == "damage" then
            sentence = buildPassiveDamageSentence(effect, targetContext, options)
        elseif effectType == "absorb" then
            sentence = buildPassiveAbsorbSentence(effect, targetContext, options)
        elseif effectType == "heal" then
            sentence = buildPassiveHealSentence(effect, targetContext, options)
        elseif effectType == "resource" then
            sentence = buildPassiveResourceSentence(effect, targetContext)
        elseif effectType == "apply_aura" then
            sentence = buildPassiveApplyAuraSentence(effect, targetContext, options)
        elseif effectType == "stat" then
            sentence = buildPassiveStatSentence(effect, targetContext, options)
        elseif effectType == "skill" then
            sentence = buildPassiveSkillSentence(effect, targetContext, options)
        elseif effectType == "control" then
            sentence = buildPassiveControlSentence(effect, targetContext, options)
        end

        if sentence and sentence ~= "" then
            sentences[#sentences + 1] = sentence
        end
    end

    local eventKeys = sortedNumericKeys(auraDefinition.events)
    for index = 1, #eventKeys do
        local auraEvent = auraDefinition.events[eventKeys[index].key]
        local clauses = {}
        local effectKeys = sortedNumericKeys(auraEvent and auraEvent.effects)
        for effectIndex = 1, #effectKeys do
            local effect = auraEvent.effects[effectKeys[effectIndex].key]
            local clause = buildEventEffectClause(
                auraName,
                currentAuraRef,
                auraEvent and auraEvent.combatEventId or nil,
                auraEvent and auraEvent.triggerTarget or nil,
                targetContext,
                effect,
                options
            )
            if clause and clause ~= "" then
                clauses[#clauses + 1] = clause
            end
        end

        if #clauses > 0 then
            local prefix = resolveCombatTriggerLabel(
                auraEvent and auraEvent.combatEventId or nil,
                targetContext,
                auraEvent and auraEvent.defenceStatRef or nil,
                auraEvent and auraEvent.damageSchoolRef or nil
            )
            local chance = normalizeChancePercent(auraEvent and auraEvent.chance)
            if chance < 100 then
                prefix = ("%s (%g%% chance)"):format(prefix, chance)
            end
            sentences[#sentences + 1] = prefix .. ", " .. joinClauses(clauses) .. "."
        end
    end

    return appendAuraThreatDescription(auraDefinition, table.concat(sentences, " "))
end

local function buildStackingTemplate(auraDefinition)
    if type(auraDefinition) ~= "table" or type(TooltipTemplate.CreateBuildState) ~= "function" then
        return "", {}
    end

    local state = TooltipTemplate.CreateBuildState()
    local clauses = {}
    local maxStacks = math.max(1, math.floor(tonumber(auraDefinition.maxStacks) or 1))
    if maxStacks > 1 then
        local appliedToken = TooltipTemplate.AddToken(state, "AURA_APPLIED_STACKS", "aura_stacks", {
            applyMode = "applied_stacks",
        })
        clauses[#clauses + 1] = ("Applies %s stacks."):format(appliedToken)
        local maxToken = TooltipTemplate.AddToken(state, "AURA_MAX_STACKS", "aura_stacks", {
            applyMode = "max_stacks",
        })
        clauses[#clauses + 1] = ("Stacks up to %s times."):format(maxToken)
    end

    return table.concat(clauses, " "), state.tokens
end

local function buildAuraTemplateError(auraRef)
    local normalizedRef = trimText(auraRef)
    if normalizedRef == "" then
        normalizedRef = "unknown"
    end

    return ("Tooltip template error: could not resolve aura template '%s'."):format(normalizedRef)
end

local function buildAuraAmountToken(state, baseKey, metadata)
    if type(TooltipTemplate.AddToken) ~= "function" then
        return ""
    end

    return TooltipTemplate.AddToken(state, baseKey, "aura_amount", metadata)
end

local function buildPassiveDamageSentenceTemplate(effect, effectIndex, state)
    local schoolLabel = resolveDamageSchoolLabel(effect)
    local amountMode = tostring(effect and effect.amountMode or "flat")
    if amountMode == "base_percent" then
        return ("Deals %g%% of Base %s damage each turn."):format(tonumber(effect and effect.baseDamage) or 0, schoolLabel)
    end
    if amountMode == "max_percent" then
        return ("Deals %g%% of Max %s damage each turn."):format(tonumber(effect and effect.baseDamage) or 0, schoolLabel)
    end
    local amountToken = buildAuraAmountToken(state, "AURA_DAMAGE", {
        effectIndex = effectIndex,
        baseField = "baseDamage",
        applyMode = "damage_amount",
    })
    return ("Deals %s %s damage each turn."):format(amountToken, schoolLabel)
end

local function buildPassiveAbsorbSentenceTemplate(effect, effectIndex, state)
    local amountMode = tostring(effect and effect.amountMode or "flat")
    local amountText = nil
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base"):format(tonumber(effect and effect.baseAbsorption) or 0)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max"):format(tonumber(effect and effect.baseAbsorption) or 0)
    else
        amountText = buildAuraAmountToken(state, "AURA_ABSORB", {
            effectIndex = effectIndex,
            baseField = "baseAbsorption",
            applyMode = "absorb_amount",
        })
    end

    local schoolLabel = #((effect and effect.damageSchoolRefs) or {}) > 0
        and (resolveDamageSchoolLabel(effect) .. " damage")
        or "damage"
    return ("Absorbs %s %s."):format(amountText, schoolLabel)
end

local function buildPassiveHealSentenceTemplate(effect, effectIndex, state)
    local amountMode = tostring(effect and effect.amountMode or "flat")
    if amountMode == "base_percent" then
        return ("Heals for %g%% of Base health each turn."):format(tonumber(effect and effect.baseHealing) or 0)
    end
    if amountMode == "max_percent" then
        return ("Heals for %g%% of Max health each turn."):format(tonumber(effect and effect.baseHealing) or 0)
    end
    local amountToken = buildAuraAmountToken(state, "AURA_HEAL", {
        effectIndex = effectIndex,
        baseField = "baseHealing",
        applyMode = "heal_amount",
    })
    return ("Heals for %s health each turn."):format(amountToken)
end

local function buildPassiveApplyAuraSentenceTemplate(effect, targetContext, options)
    local _, auraDefinition = resolveAuraDefinition(effect and effect.auraRef or nil, options)
    local auraName = ensureString(auraDefinition and auraDefinition.name, "an aura")
    local targetObject = targetContext and targetContext.object or "the affected unit"
    local sentence = targetObject == "you"
        and ("Applies %s to you"):format(auraName)
        or ("Applies %s to %s"):format(auraName, targetObject)
    local stacks = math.max(1, math.floor(tonumber(effect and effect.stacks) or 1))
    local duration = math.max(0, math.floor(tonumber(effect and effect.duration) or 0))
    if stacks > 1 then
        sentence = ("%s with %d stacks"):format(sentence, stacks)
    end
    if duration > 0 then
        sentence = ("%s for %s"):format(sentence, formatTurnLabel(duration))
    end

    return sentence .. "."
end

local function buildPassiveResourceSentenceTemplate(effect, effectIndex, state)
    local amount = tonumber(effect and effect.amount) or 0
    local resourceName = resolveResourceName(effect and effect.resourceRef or nil)
    local amountMode = tostring(effect and effect.amountMode or "flat")
    if amount >= 0 then
        if amountMode == "base_percent" then
            return ("Restores %g%% of Base %s each turn."):format(amount, resourceName)
        end
        if amountMode == "max_percent" then
            return ("Restores %g%% of Max %s each turn."):format(amount, resourceName)
        end
        local amountToken = buildAuraAmountToken(state, "AURA_RESOURCE_GAIN", {
            effectIndex = effectIndex,
            applyMode = "resource_gain_amount",
        })
        return ("Restores %s each turn."):format(amountToken)
    end

    if amountMode == "base_percent" then
        return ("Reduces %s by %g%% of Base each turn."):format(resourceName, math.abs(amount))
    end
    if amountMode == "max_percent" then
        return ("Reduces %s by %g%% of Max each turn."):format(resourceName, math.abs(amount))
    end
    local amountToken = buildAuraAmountToken(state, "AURA_RESOURCE_LOSS", {
        effectIndex = effectIndex,
        applyMode = "resource_loss_amount",
    })
    return ("Reduces %s by %s each turn."):format(resourceName, amountToken)
end

local function buildPassiveStatSentenceTemplate(effect, effectIndex, state)
    local statName = resolveStatName(effect and effect.statRef or nil)
    local verb = (tonumber(effect and effect.baseAmount) or 0) >= 0 and "Increases" or "Reduces"
    local amountToken = buildAuraAmountToken(state, "AURA_STAT", {
        effectIndex = effectIndex,
        baseField = "baseAmount",
        applyMode = "stat_amount",
    })
    local percentSuffix = (
        tostring(effect and effect.operation or "flat") == "percent"
        or isPercentDisplayStat(effect and effect.statRef or nil)
    ) and "%" or ""
    return ("%s %s by %s%s."):format(verb, statName, amountToken, percentSuffix)
end

local function buildPassiveSkillSentenceTemplate(effect, effectIndex, targetContext, state)
    local skillName = resolveSkillName(effect and effect.skillRef or nil)
    local possessive = targetContext and targetContext.possessive or "your"
    local amountToken = buildAuraAmountToken(state, "AURA_SKILL", {
        effectIndex = effectIndex,
        baseField = "baseAmount",
        applyMode = "skill_amount",
    })
    if (tonumber(effect and effect.baseAmount) or 0) >= 0 then
        return ("Increases %s skill in %s by %s."):format(possessive, skillName, amountToken)
    end

    return ("Reduces %s skill in %s by %s."):format(possessive, skillName, amountToken)
end

local function buildEventDamageClauseTemplate(effect, eventIndex, effectIndex, targetContext, state)
    local schoolLabel = resolveDamageSchoolLabel(effect)
    local amountMode = tostring(effect and effect.amountMode or "flat")
    local amountText = nil
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base"):format(tonumber(effect and effect.baseDamage) or 0)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max"):format(tonumber(effect and effect.baseDamage) or 0)
    end
    if amountText then
        if targetContext.subject == "you" then
            return ("you take %s %s damage"):format(amountText, schoolLabel)
        end
        return ("%s takes %s %s damage"):format(targetContext.subject, amountText, schoolLabel)
    end
    local amountToken = buildAuraAmountToken(state, "AURA_EVENT_DAMAGE", {
        eventIndex = eventIndex,
        effectIndex = effectIndex,
        baseField = "baseDamage",
        applyMode = "damage_amount",
    })
    if targetContext.subject == "you" then
        return ("you take %s %s damage"):format(amountToken, schoolLabel)
    end

    return ("%s takes %s %s damage"):format(targetContext.subject, amountToken, schoolLabel)
end

local function buildEventHealClauseTemplate(effect, eventIndex, effectIndex, targetContext, state)
    local amountMode = tostring(effect and effect.amountMode or "flat")
    local amountText = nil
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base"):format(tonumber(effect and effect.baseHealing) or 0)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max"):format(tonumber(effect and effect.baseHealing) or 0)
    end
    if amountText then
        if targetContext.object == "you" then
            return ("heal yourself for %s health"):format(amountText)
        end
        return ("heal %s for %s health"):format(targetContext.object, amountText)
    end
    local amountToken = buildAuraAmountToken(state, "AURA_EVENT_HEAL", {
        eventIndex = eventIndex,
        effectIndex = effectIndex,
        baseField = "baseHealing",
        applyMode = "heal_amount",
    })
    if targetContext.object == "you" then
        return ("heal yourself for %s health"):format(amountToken)
    end

    return ("heal %s for %s health"):format(targetContext.object, amountToken)
end

local function buildEventResourceClauseTemplate(effect, eventIndex, effectIndex, targetContext, state)
    local amount = tonumber(effect and effect.amount) or 0
    local resourceName = resolveResourceName(effect and effect.resourceRef or nil)
    local amountMode = tostring(effect and effect.amountMode or "flat")
    if amount > 0 then
        if amountMode == "base_percent" then
            if targetContext.object == "you" then
                return ("restore %g%% of Base %s"):format(amount, resourceName)
            end
            return ("restore %g%% of Base %s to %s"):format(amount, resourceName, targetContext.object)
        end
        if amountMode == "max_percent" then
            if targetContext.object == "you" then
                return ("restore %g%% of Max %s"):format(amount, resourceName)
            end
            return ("restore %g%% of Max %s to %s"):format(amount, resourceName, targetContext.object)
        end
        local amountToken = buildAuraAmountToken(state, "AURA_EVENT_RESOURCE_GAIN", {
            eventIndex = eventIndex,
            effectIndex = effectIndex,
            applyMode = "resource_gain_amount",
        })
        if targetContext.object == "you" then
            return ("restore %s"):format(amountToken)
        end
        return ("restore %s to %s"):format(amountToken, targetContext.object)
    end

    if amountMode == "base_percent" then
        if targetContext.object == "you" then
            return ("lose %g%% of Base"):format(math.abs(amount))
        end
        return ("reduce %s %s by %g%% of Base"):format(targetContext.possessive, resourceName, math.abs(amount))
    end
    if amountMode == "max_percent" then
        if targetContext.object == "you" then
            return ("lose %g%% of Max"):format(math.abs(amount))
        end
        return ("reduce %s %s by %g%% of Max"):format(targetContext.possessive, resourceName, math.abs(amount))
    end
    local amountToken = buildAuraAmountToken(state, "AURA_EVENT_RESOURCE_LOSS", {
        eventIndex = eventIndex,
        effectIndex = effectIndex,
        applyMode = "resource_loss_amount",
    })
    if targetContext.object == "you" then
        return ("lose %s"):format(amountToken)
    end
    return ("reduce %s %s by %s"):format(targetContext.possessive, resourceName, amountToken)
end

local function buildEventEffectClauseTemplate(currentAuraName, currentAuraRef, combatEventId, triggerTarget, targetContext, effect, eventIndex, effectIndex, options, state)
    local effectType = tostring(effect and effect.type or "")
    local resolvedTargetContext = resolveTriggeredTargetContext(combatEventId, triggerTarget, targetContext)
    if effectType == "damage" then
        return buildEventDamageClauseTemplate(effect, eventIndex, effectIndex, resolvedTargetContext, state)
    end
    if effectType == "heal" then
        return buildEventHealClauseTemplate(effect, eventIndex, effectIndex, resolvedTargetContext, state)
    end
    if effectType == "resource" then
        return buildEventResourceClauseTemplate(effect, eventIndex, effectIndex, resolvedTargetContext, state)
    end
    if effectType == "apply_aura" then
        return buildEventApplyAuraClause(effect, resolvedTargetContext, options)
    end
    if effectType == "remove_hidden" then
        return buildEventRemoveHiddenClause(resolvedTargetContext)
    end
    if effectType == "remove_aura" then
        return buildEventRemoveAuraClause(currentAuraName, currentAuraRef, effect, resolvedTargetContext, options)
    end
    if effectType == "interrupt" then
        return buildEventInterruptClause(resolvedTargetContext)
    end
    if effectType == "revert" then
        return buildEventRevertClause(resolvedTargetContext)
    end

    return nil
end

local function resolveAuraTemplateEffect(auraDefinition, token)
    if type(auraDefinition) ~= "table" or type(token) ~= "table" then
        return nil
    end

    local eventIndex = tonumber(token.eventIndex)
    local effectIndex = tonumber(token.effectIndex)
    if effectIndex == nil then
        return nil
    end
    effectIndex = math.floor(effectIndex)
    if effectIndex <= 0 then
        return nil
    end

    if eventIndex ~= nil then
        eventIndex = math.floor(eventIndex)
        local auraEvent = (auraDefinition.events or {})[eventIndex]
        return type(auraEvent) == "table" and (auraEvent.effects or {})[effectIndex] or nil
    end

    return (auraDefinition.effects or {})[effectIndex]
end

local function resolveAuraTemplateToken(auraDefinition, token, options)
    local applyMode = tostring(token and token.applyMode or "")
    if applyMode == "applied_stacks" then
        return tostring(math.max(1, math.floor(tonumber(type(options) == "table" and options.stacks) or 1)))
    end
    if applyMode == "max_stacks" then
        return tostring(math.max(1, math.floor(tonumber(auraDefinition and auraDefinition.maxStacks) or 1)))
    end

    local effect = resolveAuraTemplateEffect(auraDefinition, token)
    if type(effect) ~= "table" then
        return nil
    end

    if applyMode == "damage_amount" or applyMode == "heal_amount" or applyMode == "absorb_amount" or applyMode == "stat_amount" or applyMode == "skill_amount" then
        local amount = resolveAmount(options, effect, tostring(token.baseField or "baseAmount"))
        local numericAmount = math.abs(amount)
        if applyMode == "damage_amount" or applyMode == "heal_amount" or applyMode == "absorb_amount" then
            local amountMode = tostring(effect.amountMode or "flat")
            if amountMode == "base_percent" then
                return ("%g%% of Base"):format(math.abs(tonumber(effect[token.baseField or "baseAmount"]) or 0))
            end
            if amountMode == "max_percent" then
                return ("%g%% of Max"):format(math.abs(tonumber(effect[token.baseField or "baseAmount"]) or 0))
            end
            return tostring(math.floor(numericAmount))
        end
        local amountText = tostring(
            (applyMode == "stat_amount" and (tostring(effect.operation or "flat") == "percent" or isPercentDisplayStat(effect.statRef)))
                and math.abs(tonumber(effect[token.baseField or "baseAmount"]) or 0)
                or numericAmount
        )
        -- Percentage-valued stat tokens are rendered as the numeric value only.
        -- Authored tooltip templates own their punctuation (for example, the
        -- common `{AURA_STAT_1}%` form), while generated sentences append the
        -- suffix themselves. Keeping the token value punctuation-free avoids
        -- duplicated percent signs when a template includes the suffix.
        return amountText
    end

    if applyMode == "resource_gain_amount" or applyMode == "resource_loss_amount" then
        local amount = tonumber(effect.amount) or 0
        local amountMode = tostring(effect.amountMode or "flat")
        local resourceName = resolveResourceName(effect.resourceRef)
        if applyMode == "resource_gain_amount" then
            if amountMode == "base_percent" then
                return ("%g%% of Base %s"):format(math.abs(tonumber(effect.amount) or 0), resourceName)
            end
            if amountMode == "max_percent" then
                return ("%g%% of Max %s"):format(math.abs(tonumber(effect.amount) or 0), resourceName)
            end
            return ("%d %s"):format(math.floor(amount), resourceName)
        end

        local lossAmount = math.abs(amount)
        if amountMode == "base_percent" then
            return ("%g%% of Base"):format(lossAmount)
        end
        if amountMode == "max_percent" then
            return ("%g%% of Max"):format(lossAmount)
        end
        return tostring(math.floor(lossAmount))
    end

    return nil
end

function AuraDescriptionBuilder:BuildTooltipTemplatePayload(auraDefinition, options)
    if type(auraDefinition) ~= "table" or type(TooltipTemplate.CreateBuildState) ~= "function" then
        return nil
    end

    local targetContext = resolveTargetContext(options)
    local auraName = ensureString(auraDefinition.name, "")
    local currentAuraRef = type(options) == "table" and options.auraRef or nil
    local authoredDescriptionText = trimText(auraDefinition.description)
    local bodyState = TooltipTemplate.CreateBuildState()
    local bodySentences = {}

    local passiveEffectKeys = sortedNumericKeys(auraDefinition.effects)
    for index = 1, #passiveEffectKeys do
        local effectIndex = tonumber(passiveEffectKeys[index].key)
        local effect = auraDefinition.effects[passiveEffectKeys[index].key]
        local effectType = tostring(effect and effect.type or "")
        local sentence = nil
        if effectType == "damage" then
            sentence = buildPassiveDamageSentenceTemplate(effect, effectIndex, bodyState)
        elseif effectType == "absorb" then
            sentence = buildPassiveAbsorbSentenceTemplate(effect, effectIndex, bodyState)
        elseif effectType == "heal" then
            sentence = buildPassiveHealSentenceTemplate(effect, effectIndex, bodyState)
        elseif effectType == "resource" then
            sentence = buildPassiveResourceSentenceTemplate(effect, effectIndex, bodyState)
        elseif effectType == "apply_aura" then
            sentence = buildPassiveApplyAuraSentenceTemplate(effect, targetContext, options)
        elseif effectType == "stat" then
            sentence = buildPassiveStatSentenceTemplate(effect, effectIndex, bodyState)
        elseif effectType == "skill" then
            sentence = buildPassiveSkillSentenceTemplate(effect, effectIndex, targetContext, bodyState)
        elseif effectType == "control" then
            sentence = buildPassiveControlSentence(effect, targetContext, options)
        end
        if sentence and sentence ~= "" then
            bodySentences[#bodySentences + 1] = sentence
        end
    end

    local eventKeys = sortedNumericKeys(auraDefinition.events)
    for index = 1, #eventKeys do
        local eventIndex = tonumber(eventKeys[index].key)
        local auraEvent = auraDefinition.events[eventKeys[index].key]
        local clauses = {}
        local effectKeys = sortedNumericKeys(auraEvent and auraEvent.effects)
        for effectPosition = 1, #effectKeys do
            local effectIndex = tonumber(effectKeys[effectPosition].key)
            local effect = auraEvent.effects[effectKeys[effectPosition].key]
            local clause = buildEventEffectClauseTemplate(
                auraName,
                currentAuraRef,
                auraEvent and auraEvent.combatEventId or nil,
                auraEvent and auraEvent.triggerTarget or nil,
                targetContext,
                effect,
                eventIndex,
                effectIndex,
                options,
                bodyState
            )
            if clause and clause ~= "" then
                clauses[#clauses + 1] = clause
            end
        end

        if #clauses > 0 then
            local prefix = resolveCombatTriggerLabel(
                auraEvent and auraEvent.combatEventId or nil,
                targetContext,
                auraEvent and auraEvent.defenceStatRef or nil,
                auraEvent and auraEvent.damageSchoolRef or nil
            )
            local chance = normalizeChancePercent(auraEvent and auraEvent.chance)
            if chance < 100 then
                prefix = ("%s (%g%% chance)"):format(prefix, chance)
            end
            bodySentences[#bodySentences + 1] = prefix .. ", " .. joinClauses(clauses) .. "."
        end
    end

    local stackingText, stackingTokens = buildStackingTemplate(auraDefinition)
    local bodyText = #bodySentences > 0 and table.concat(bodySentences, " ") or authoredDescriptionText
    bodyText = appendAuraThreatDescription(auraDefinition, bodyText)
    return TooltipTemplate.NormalizeAuraPayload({
        bodyText = bodyText,
        bodyTokens = bodyState.tokens,
        stackingText = stackingText,
        stackingTokens = stackingTokens,
    })
end

function AuraDescriptionBuilder:ResolveTooltipTemplatePayload(auraDefinition, payload, options)
    local normalizedPayload = type(TooltipTemplate.NormalizeAuraPayload) == "function"
        and TooltipTemplate.NormalizeAuraPayload(payload)
        or nil
    if type(auraDefinition) ~= "table" or type(normalizedPayload) ~= "table" then
        return nil, buildAuraTemplateError(type(options) == "table" and options.auraRef or nil)
    end

    local function resolveToken(token)
        return resolveAuraTemplateToken(auraDefinition, token, options)
    end

    local bodyText = normalizedPayload.bodyText
    if bodyText ~= "" then
        local renderedBody, renderError = TooltipTemplate.ResolveText(bodyText, normalizedPayload.bodyTokens, resolveToken)
        if renderedBody == nil then
            return nil, renderError
        end
        bodyText = renderedBody
    end

    local stackingText = normalizedPayload.stackingText
    if stackingText ~= "" then
        local renderedStacking, renderError = TooltipTemplate.ResolveText(stackingText, normalizedPayload.stackingTokens, resolveToken)
        if renderedStacking == nil then
            return nil, renderError
        end
        stackingText = renderedStacking
    end

    return TooltipTemplate.CombineText(bodyText, stackingText), nil
end

function AuraDescriptionBuilder:BuildTooltipSectionTemplate(auraRef, options)
    local dataset, auraDefinition, qualifiedAuraRef = resolveAuraDefinition(auraRef, options)
    if type(auraDefinition) ~= "table" then
        return nil, buildAuraTemplateError(auraRef)
    end

    local resolvedOptions = {
        auraRef = qualifiedAuraRef or auraRef,
        datasetId = dataset and dataset.id or (type(options) == "table" and options.datasetId or nil),
        dataset = dataset or (type(options) == "table" and options.dataset or nil),
        spellDatasetId = type(options) == "table" and options.spellDatasetId or nil,
        casterUnit = type(options) == "table" and options.casterUnit or nil,
        targetUnit = type(options) == "table" and options.targetUnit or nil,
        powerLevel = type(options) == "table" and options.powerLevel or nil,
        rankMultiplier = type(options) == "table" and options.rankMultiplier or nil,
        stacks = type(options) == "table" and options.stacks or nil,
        duration = type(options) == "table" and options.duration or nil,
        targetContext = type(options) == "table" and options.targetContext or nil,
    }
    local payload = type(TooltipTemplate.NormalizeAuraPayload) == "function"
        and TooltipTemplate.NormalizeAuraPayload(auraDefinition.tooltipTemplateData)
        or nil
    if type(payload) ~= "table" then
        payload = self:BuildTooltipTemplatePayload(auraDefinition, {
            auraRef = resolvedOptions.auraRef,
            datasetId = resolvedOptions.datasetId,
            dataset = resolvedOptions.dataset,
            spellDatasetId = resolvedOptions.spellDatasetId,
            casterUnit = resolvedOptions.casterUnit,
            targetUnit = resolvedOptions.targetUnit,
            powerLevel = resolvedOptions.powerLevel,
            rankMultiplier = resolvedOptions.rankMultiplier,
            stacks = resolvedOptions.stacks,
            duration = resolvedOptions.duration,
            targetContext = resolvedOptions.targetContext,
        })
    end
    if type(payload) == "table" then
        return {
            auraRef = qualifiedAuraRef or auraRef,
            datasetId = dataset and dataset.id or (type(options) == "table" and options.datasetId or nil),
            spellDatasetId = type(options) == "table" and options.spellDatasetId or nil,
            nameText = ensureString(auraDefinition.name, ensureString(qualifiedAuraRef or auraRef, "Aura")),
            icon = ensureString(auraDefinition.icon, "Interface\\Icons\\INV_Misc_QuestionMark"),
            descriptionText = TooltipTemplate.CombineText(payload.bodyText, payload.stackingText),
            tokens = TooltipTemplate.MergeTokens(payload.bodyTokens, payload.stackingTokens),
            powerLevel = type(options) == "table" and options.powerLevel or nil,
            rankMultiplier = type(options) == "table" and options.rankMultiplier or nil,
            stacks = type(options) == "table" and options.stacks or nil,
            duration = type(options) == "table" and options.duration or nil,
            targetContext = type(options) == "table" and options.targetContext or nil,
        }, nil
    end

    local generatedDescriptionText = self:BuildGeneratedDescription(auraDefinition, resolvedOptions)
    local stackingDescriptionText = buildStackingDescription(auraDefinition, resolvedOptions)
    local descriptionText = trimText(table.concat({
        trimText(generatedDescriptionText),
        trimText(auraDefinition.description),
        trimText(stackingDescriptionText),
    }, " "))
    if descriptionText == "" then
        return nil, buildAuraTemplateError(auraRef)
    end

    return {
        auraRef = qualifiedAuraRef or auraRef,
        datasetId = resolvedOptions.datasetId,
        spellDatasetId = resolvedOptions.spellDatasetId,
        nameText = ensureString(auraDefinition.name, ensureString(qualifiedAuraRef or auraRef, "Aura")),
        icon = ensureString(auraDefinition.icon, "Interface\\Icons\\INV_Misc_QuestionMark"),
        descriptionText = descriptionText,
        tokens = {},
        powerLevel = resolvedOptions.powerLevel,
        rankMultiplier = resolvedOptions.rankMultiplier,
        stacks = resolvedOptions.stacks,
        duration = resolvedOptions.duration,
        targetContext = resolvedOptions.targetContext,
    }, nil
end

function AuraDescriptionBuilder:ResolveTooltipSectionTemplate(section, options)
    if type(section) ~= "table" then
        return nil, buildAuraTemplateError(nil)
    end

    local dataset, auraDefinition, qualifiedAuraRef = resolveAuraDefinition(section.auraRef, {
        dataset = type(options) == "table" and options.dataset or nil,
        datasetId = type(options) == "table" and options.datasetId or section.datasetId,
        spellDatasetId = type(options) == "table" and options.spellDatasetId or section.spellDatasetId,
    })
    if type(auraDefinition) ~= "table" then
        return nil, buildAuraTemplateError(section.auraRef)
    end

    local function resolveToken(token)
        return resolveAuraTemplateToken(auraDefinition, token, {
            auraRef = qualifiedAuraRef or section.auraRef,
            datasetId = dataset and dataset.id or section.datasetId,
            dataset = dataset,
            spellDatasetId = section.spellDatasetId,
            casterUnit = type(options) == "table" and options.casterUnit or nil,
            targetUnit = type(options) == "table" and options.targetUnit or nil,
            powerLevel = tonumber(section.powerLevel) or 0,
            rankMultiplier = tonumber(type(options) == "table" and options.rankMultiplier)
                or tonumber(section.rankMultiplier)
                or 1,
            stacks = tonumber(section.stacks) or 1,
            duration = section.duration,
            targetContext = section.targetContext,
        })
    end

    return TooltipTemplate.ResolveText(section.descriptionText or "", section.tokens or {}, resolveToken)
end

function AuraDescriptionBuilder:BuildTooltipSection(auraRef, options)
    local dataset, auraDefinition, qualifiedAuraRef = resolveAuraDefinition(auraRef, options)
    if type(auraDefinition) ~= "table" then
        return nil
    end

    if auraDefinition.tooltipTemplate == true then
        local resolvedOptions = {
            auraRef = qualifiedAuraRef or auraRef,
            datasetId = dataset and dataset.id or (type(options) == "table" and options.datasetId or nil),
            dataset = dataset or (type(options) == "table" and options.dataset or nil),
            spellDatasetId = type(options) == "table" and options.spellDatasetId or nil,
            casterUnit = type(options) == "table" and options.casterUnit or nil,
            targetUnit = type(options) == "table" and options.targetUnit or nil,
            powerLevel = type(options) == "table" and options.powerLevel or nil,
            rankMultiplier = type(options) == "table" and options.rankMultiplier or nil,
            stacks = type(options) == "table" and options.stacks or nil,
            duration = type(options) == "table" and options.duration or nil,
            targetContext = type(options) == "table" and options.targetContext or nil,
        }
        local payload = type(TooltipTemplate.NormalizeAuraPayload) == "function"
            and TooltipTemplate.NormalizeAuraPayload(auraDefinition.tooltipTemplateData)
            or nil
        if type(payload) ~= "table" then
            payload = self:BuildTooltipTemplatePayload(auraDefinition, resolvedOptions)
        end
        local resolvedDescriptionText, resolveError = self:ResolveTooltipTemplatePayload(auraDefinition, payload, resolvedOptions)
        local descriptionText = trimText(resolvedDescriptionText)
        if descriptionText == "" then
            return {
                auraRef = qualifiedAuraRef or auraRef,
                name = ensureString(auraDefinition.name, ensureString(qualifiedAuraRef or auraRef, "Aura")),
                icon = ensureString(auraDefinition.icon, "Interface\\Icons\\INV_Misc_QuestionMark"),
                descriptionText = trimText(resolveError or ""),
                descriptionSource = "error",
            }
        end
        return {
            auraRef = qualifiedAuraRef or auraRef,
            name = ensureString(auraDefinition.name, ensureString(qualifiedAuraRef or auraRef, "Aura")),
            icon = ensureString(auraDefinition.icon, "Interface\\Icons\\INV_Misc_QuestionMark"),
            descriptionText = descriptionText,
            descriptionSource = "template",
        }
    end

    local authoredDescriptionText = trimText(auraDefinition.description)
    local generatedDescriptionText = self:BuildGeneratedDescription(auraDefinition, {
        auraRef = qualifiedAuraRef or auraRef,
        datasetId = dataset and dataset.id or (type(options) == "table" and options.datasetId or nil),
        dataset = dataset or (type(options) == "table" and options.dataset or nil),
        spellDatasetId = type(options) == "table" and options.spellDatasetId or nil,
        casterUnit = type(options) == "table" and options.casterUnit or nil,
        powerLevel = type(options) == "table" and options.powerLevel or nil,
        rankMultiplier = type(options) == "table" and options.rankMultiplier or nil,
        stacks = type(options) == "table" and options.stacks or nil,
        targetContext = type(options) == "table" and options.targetContext or nil,
    })
    local baseDescriptionText = trimText(generatedDescriptionText)
    local descriptionSource = "generated"
    if baseDescriptionText == "" then
        baseDescriptionText = authoredDescriptionText
        descriptionSource = "authored"
    end

    local stackingDescriptionText = buildStackingDescription(auraDefinition, options)
    local descriptionText = trimText(table.concat({
        trimText(baseDescriptionText),
        trimText(stackingDescriptionText),
    }, " "))
    if descriptionText == "" then
        return nil
    end

    return {
        auraRef = qualifiedAuraRef or auraRef,
        name = ensureString(auraDefinition.name, ensureString(qualifiedAuraRef or auraRef, "Aura")),
        icon = ensureString(auraDefinition.icon, "Interface\\Icons\\INV_Misc_QuestionMark"),
        descriptionText = descriptionText,
        descriptionSource = descriptionSource,
    }
end

return AuraDescriptionBuilder
