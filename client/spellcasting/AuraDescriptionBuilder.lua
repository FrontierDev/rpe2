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
    if type(resolvedRow) == "table" and tostring(resolvedRow.displayMode or "") == "signed_percent" then
        return true
    end

    local datasetId, statId = nil, nil
    if type(Dependencies.ParseSourceStatRef) == "function" then
        datasetId, statId = Dependencies.ParseSourceStatRef(statRef)
    end

    if datasetId and statId and type(Registry.ResolveStatReference) == "function" then
        local _, stat = Registry:ResolveStatReference(statRef)
        return tostring(stat and stat.displayMode or "") == "signed_percent"
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
            stacks = math.max(1, math.floor(tonumber(type(options) == "table" and options.stacks) or 1)),
        },
        casterUnit = type(options) == "table" and options.casterUnit or nil,
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

local function buildPassiveDamageSentence(effect, targetContext, options)
    local amount = math.max(0, resolveAmount(options, effect, "baseDamage"))
    local schoolLabel = resolveDamageSchoolLabel(effect)
    return ("Deals %d %s damage each turn."):format(amount, schoolLabel)
end

local function buildPassiveHealSentence(effect, targetContext, options)
    local amount = math.max(0, resolveAmount(options, effect, "baseHealing"))
    return ("Heals for %d health each turn."):format(amount)
end

local function buildPassiveResourceSentence(effect, targetContext)
    local amount = tonumber(effect and effect.amount) or 0
    local resourceName = resolveResourceName(effect and effect.resourceRef or nil)
    if amount >= 0 then
        return ("Restores %d %s each turn."):format(amount, resourceName)
    end

    return ("Reduces %s by %d each turn."):format(resourceName, math.abs(amount))
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

local function resolveCombatTriggerLabel(combatEventId, targetContext)
    local eventId = tostring(combatEventId or "")
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

    return auraTargetContext
end

local function buildEventDamageClause(effect, targetContext, options)
    local amount = math.max(0, resolveAmount(options, effect, "baseDamage"))
    local schoolLabel = resolveDamageSchoolLabel(effect)
    if targetContext.subject == "you" then
        return ("you take %d %s damage"):format(amount, schoolLabel)
    end

    return ("%s takes %d %s damage"):format(targetContext.subject, amount, schoolLabel)
end

local function buildEventHealClause(effect, targetContext, options)
    local amount = math.max(0, resolveAmount(options, effect, "baseHealing"))
    if targetContext.object == "you" then
        return ("heal yourself for %d health"):format(amount)
    end

    return ("heal %s for %d health"):format(targetContext.object, amount)
end

local function buildEventResourceClause(effect, targetContext)
    local amount = tonumber(effect and effect.amount) or 0
    local resourceName = resolveResourceName(effect and effect.resourceRef or nil)
    if amount > 0 then
        if targetContext.object == "you" then
            return ("restore %d %s"):format(amount, resourceName)
        end
        return ("restore %d %s to %s"):format(amount, resourceName, targetContext.object)
    end

    if targetContext.object == "you" then
        return ("lose %d %s"):format(math.abs(amount), resourceName)
    end
    return ("reduce %s %s by %d"):format(targetContext.possessive, resourceName, math.abs(amount))
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

local function buildEventRevertClause(targetContext)
    if targetContext.object == "you" then
        return "revert the last spell that affected you"
    end

    return ("revert the last spell that affected %s"):format(targetContext.object)
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
        elseif effectType == "heal" then
            sentence = buildPassiveHealSentence(effect, targetContext, options)
        elseif effectType == "resource" then
            sentence = buildPassiveResourceSentence(effect, targetContext)
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
            sentences[#sentences + 1] = resolveCombatTriggerLabel(auraEvent and auraEvent.combatEventId or nil, targetContext) .. ", " .. joinClauses(clauses) .. "."
        end
    end

    return table.concat(sentences, " ")
end

function AuraDescriptionBuilder:BuildTooltipSection(auraRef, options)
    local dataset, auraDefinition, qualifiedAuraRef = resolveAuraDefinition(auraRef, options)
    if type(auraDefinition) ~= "table" then
        return nil
    end

    local authoredDescriptionText = trimText(auraDefinition.description)
    local generatedDescriptionText = self:BuildGeneratedDescription(auraDefinition, {
        auraRef = qualifiedAuraRef or auraRef,
        datasetId = dataset and dataset.id or (type(options) == "table" and options.datasetId or nil),
        dataset = dataset or (type(options) == "table" and options.dataset or nil),
        spellDatasetId = type(options) == "table" and options.spellDatasetId or nil,
        casterUnit = type(options) == "table" and options.casterUnit or nil,
        powerLevel = type(options) == "table" and options.powerLevel or nil,
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
