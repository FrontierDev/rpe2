local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Traits = Addon.Client.Traits or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Traits = Addon.Client.Traits or {}
local Spellcasting = Addon.Client.Spellcasting or {}
local Combat = Addon.Client and Addon.Client.Combat or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local TraitClass = Database and Database.Classes and Database.Classes.Trait or {}
local Dependencies = Database and Database.Dependecies or {}
local ResourceSync = Addon.Internal and Addon.Internal.Comms and Addon.Internal.Comms.ResourceSync or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local UI = Addon.UI or {}
local AuraDescriptionBuilder = Spellcasting.AuraDescriptionBuilder or {}
local SpellDescriptionBuilder = Spellcasting.DescriptionBuilder or {}

local TraitDescriptionBuilder = Traits.DescriptionBuilder or {}
Traits.DescriptionBuilder = TraitDescriptionBuilder

local MIN_VARIANCE = 0.9
local MAX_VARIANCE = 1.1

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function enqueueDescriptionWork(fn, ...)
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        tasks:Enqueue(fn, ...)
        return true
    end

    return false
end

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

local CONSUMABLE_ELIXIR_PREFIXES = {
    battle = "Battle Elixir.",
    guardian = "Guardian Elixir.",
}

local function buildConsumableTagLookup(item)
    local lookup = {}
    for index = 1, #((item and item.tags) or {}) do
        local tag = string.lower(ensureString(item.tags[index]))
        if tag ~= "" then
            lookup[tag] = true
        end
    end
    return lookup
end

local function resolveConsumableElixirType(detail)
    local item = type(detail) == "table" and detail.item or nil
    local consumableType = string.lower(ensureString(item and item.consumableType or type(detail) == "table" and detail.consumableType or ""))
    if consumableType ~= "elixir" then
        return nil
    end

    local explicitType = string.lower(ensureString(item and item.consumableElixirType or type(detail) == "table" and detail.consumableElixirType or ""))
    if explicitType == "battle" or explicitType == "guardian" then
        return explicitType
    end

    local tags = buildConsumableTagLookup(item)
    if tags.battle == true and tags.guardian ~= true then
        return "battle"
    end
    if tags.guardian == true and tags.battle ~= true then
        return "guardian"
    end

    return nil
end

local function decorateConsumableDescriptionText(detail, descriptionText)
    local text = trimText(descriptionText or "")
    local elixirType = resolveConsumableElixirType(detail)
    local prefix = elixirType and CONSUMABLE_ELIXIR_PREFIXES[elixirType] or nil
    if prefix == nil or prefix == "" then
        return text
    end
    if text == "" then
        return prefix
    end
    if string.sub(text, 1, string.len(prefix)) == prefix then
        return text
    end

    return ("%s %s"):format(prefix, text)
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

local function formatValueRange(minimum, maximum)
    local minValue = math.max(0, tonumber(minimum) or 0)
    local maxValue = math.max(0, tonumber(maximum) or 0)
    if minValue > maxValue then
        minValue, maxValue = maxValue, minValue
    end

    if minValue == maxValue then
        return tostring(minValue)
    end

    return ("%d to %d"):format(minValue, maxValue)
end

local function buildDeterministicRandom(mode)
    return function(_, minimum, maximum)
        if minimum ~= nil and maximum ~= nil then
            if mode == "min" then
                return minimum
            end

            return maximum
        end

        if mode == "min" then
            return 0
        end

        return 1
    end
end

local function buildValueContext(casterUnit, variance, randomMode)
    return {
        casterUnit = casterUnit,
        attackerUnit = casterUnit,
        caster = casterUnit,
        variance = variance,
        random = buildDeterministicRandom(randomMode),
    }
end

local function resolveCasterUnit(detail)
    if type(SpellDescriptionBuilder) == "table" and type(SpellDescriptionBuilder.ResolveCasterUnit) == "function" then
        return SpellDescriptionBuilder.ResolveCasterUnit(detail)
    end
    if type(SpellDescriptionBuilder) == "table" and type(SpellDescriptionBuilder.BuildPseudoCasterUnit) == "function" then
        return SpellDescriptionBuilder.BuildPseudoCasterUnit()
    end

    return {
        isPlayer = true,
        name = "Player",
        stats = {},
        resources = {},
    }
end

local function buildGeneratedDescriptionCacheKey(detail, casterUnit)
    if type(SpellDescriptionBuilder) == "table" and type(SpellDescriptionBuilder.ResolveGeneratedTooltipCacheKey) == "function" then
        return SpellDescriptionBuilder.ResolveGeneratedTooltipCacheKey(detail, casterUnit)
    end

    return table.concat({
        tostring(type(detail) == "table" and detail.traitRef or ""),
        tostring(type(detail) == "table" and detail.detailName or ""),
    }, "\31")
end

local function applySummaryFallback(detail)
    local summaryText = trimText(type(detail) == "table" and detail.summaryText or "")
    summaryText = decorateConsumableDescriptionText(detail, summaryText)
    if type(detail) == "table" then
        detail.descriptionText = summaryText
        detail.descriptionSource = "summary"
    end

    return summaryText, "summary"
end

local function ensurePendingDescriptionState(detail)
    if type(detail) ~= "table" then
        return nil, nil
    end

    detail.generatedDescriptionPendingByKey = detail.generatedDescriptionPendingByKey or {}
    detail.generatedDescriptionPendingOwnersByKey = detail.generatedDescriptionPendingOwnersByKey or {}
    return detail.generatedDescriptionPendingByKey, detail.generatedDescriptionPendingOwnersByKey
end

local function addPendingDescriptionOwner(detail, cacheKey, owner)
    if type(detail) ~= "table" or type(cacheKey) ~= "string" or cacheKey == "" or owner == nil then
        return
    end

    local _, ownersByKey = ensurePendingDescriptionState(detail)
    if type(ownersByKey) ~= "table" then
        return
    end

    local owners = ownersByKey[cacheKey]
    if type(owners) ~= "table" then
        owners = {}
        ownersByKey[cacheKey] = owners
    end

    for index = 1, #owners do
        if owners[index] == owner then
            return
        end
    end

    owners[#owners + 1] = owner
end

local function takePendingDescriptionOwners(detail, cacheKey)
    if type(detail) ~= "table" or type(cacheKey) ~= "string" or cacheKey == "" then
        return nil
    end

    local pendingByKey, ownersByKey = ensurePendingDescriptionState(detail)
    local owners = type(ownersByKey) == "table" and ownersByKey[cacheKey] or nil
    if type(pendingByKey) == "table" then
        pendingByKey[cacheKey] = nil
    end
    if type(ownersByKey) == "table" then
        ownersByKey[cacheKey] = nil
    end

    return owners
end

local function refreshTooltipOwners(owners)
    if type(owners) ~= "table" or type(UI.Tooltip) ~= "table" or type(UI.Tooltip.RefreshForElement) ~= "function" then
        return
    end

    for index = 1, #owners do
        UI.Tooltip:RefreshForElement(owners[index])
    end
end

local function storeGeneratedDescription(detail, generatedDescriptionText, cacheKey)
    if type(detail) ~= "table" then
        return
    end

    local normalizedGeneratedDescriptionText = trimText(generatedDescriptionText or "")
    detail.generatedDescriptionText = normalizedGeneratedDescriptionText
    detail.generatedDescriptionCacheKey = cacheKey

    if normalizedGeneratedDescriptionText ~= "" then
        detail.descriptionText = normalizedGeneratedDescriptionText
        detail.descriptionSource = "generated"
        return
    end

    applySummaryFallback(detail)
end

local function storeGeneratedTooltipPayload(detail, generatedDescriptionText, generatedAuraSections, cacheKey)
    if type(detail) ~= "table" then
        return
    end

    storeGeneratedDescription(detail, generatedDescriptionText, cacheKey)
    detail.generatedAuraSections = type(generatedAuraSections) == "table" and generatedAuraSections or {}
    detail.generatedAuraSectionsCacheKey = cacheKey
end

local function resolveDatasetId(detail)
    if type(detail) ~= "table" then
        return nil
    end

    if type(detail.datasetId) == "string" and detail.datasetId ~= "" then
        return detail.datasetId
    end

    local dataset = detail.dataset
    if type(dataset) == "table" and type(dataset.id) == "string" and dataset.id ~= "" then
        return dataset.id
    end

    local traitRef = type(detail.traitRef) == "string" and detail.traitRef or ""
    local datasetId = traitRef:match("^([^:]+):.+$")
    if datasetId and datasetId ~= "" then
        return datasetId
    end

    local resolvedItem = detail.resolvedItem
    if type(resolvedItem) == "table" and type(resolvedItem.datasetId) == "string" and resolvedItem.datasetId ~= "" then
        return resolvedItem.datasetId
    end

    return nil
end

local function resolveTraitPayload(detail)
    local payload = nil
    if type(detail) == "table" then
        payload = detail.traitPayload or detail.payload or detail.consumableTrait or detail.trait
    end

    if type(TraitClass) == "table" and type(TraitClass.NormalizeRuntimePayload) == "function" then
        return TraitClass.NormalizeRuntimePayload(payload)
    end

    return type(payload) == "table" and payload or {}
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

local function resolveAuraMetadata(detail, auraRef)
    local defaultName = "an aura"
    if type(auraRef) ~= "string" or auraRef == "" then
        return {
            name = defaultName,
            duration = nil,
        }
    end

    local auraManager = Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.ResolveAuraDefinition) == "function" then
        local _, auraDefinition = auraManager:ResolveAuraDefinition(auraRef, {
            datasetId = resolveDatasetId(detail),
            dataset = type(detail) == "table" and detail.dataset or nil,
            spellDatasetId = resolveDatasetId(detail),
            sourceDatasetId = resolveDatasetId(detail),
        })
        if type(auraDefinition) == "table" then
            local auraName = trimText(auraDefinition.name)
            return {
                name = auraName ~= "" and auraName or defaultName,
                duration = tonumber(auraDefinition.duration) or nil,
            }
        end
    end

    local _, auraId = nil, nil
    if type(Dependencies.ParseSourceStatRef) == "function" then
        _, auraId = Dependencies.ParseSourceStatRef(auraRef)
    end

    return {
        name = ensureString(auraId or auraRef, defaultName),
        duration = nil,
    }
end

local function buildOwnerTargetContext()
    return {
        subject = "you",
        object = "yourself",
        possessive = "your",
        reflexive = "yourself",
    }
end

local function buildGenericTargetContext(subject, object, possessive)
    return {
        subject = subject,
        object = object,
        possessive = possessive,
        reflexive = "itself",
    }
end

local function resolveAutomaticAuraTargetPhrase(targetScope)
    local scope = tostring(targetScope or "self")
    if scope == "all_allies" then
        return "all allies"
    end
    if scope == "all_enemies" then
        return "all enemies"
    end

    return "yourself"
end

local function resolveAutomaticAuraTargetContext(targetScope)
    local scope = tostring(targetScope or "self")
    if scope == "all_allies" then
        return buildGenericTargetContext("the affected ally", "the affected ally", "the affected ally's")
    end
    if scope == "all_enemies" then
        return buildGenericTargetContext("the affected enemy", "the affected enemy", "the affected enemy's")
    end

    return buildOwnerTargetContext()
end

local function resolveTriggeredTargetContext(combatEventId, triggerTarget)
    local eventId = tostring(combatEventId or "")
    local targetKey = tostring(triggerTarget or "event_other")
    if targetKey == "event_source" then
        if eventId == "on_auto_attack_hit"
            or eventId == "on_auto_attack_taken"
            or eventId == "on_melee_hit"
            or eventId == "on_melee_taken"
            or eventId == "on_ranged_hit"
            or eventId == "on_ranged_taken"
        then
            return buildGenericTargetContext("the attacker", "the attacker", "the attacker's")
        end
        if eventId == "on_critical_hit" or eventId == "on_critical_hit_taken" then
            return buildGenericTargetContext("the attacker", "the attacker", "the attacker's")
        end
        if eventId == "on_spell_hit" or eventId == "on_spell_taken" then
            return buildGenericTargetContext("the caster", "the caster", "the caster's")
        end
        if eventId == "on_heal" or eventId == "on_heal_taken" then
            return buildGenericTargetContext("the healer", "the healer", "the healer's")
        end
        if eventId == "on_critical_heal" or eventId == "on_critical_heal_taken" then
            return buildGenericTargetContext("the healer", "the healer", "the healer's")
        end

        return buildGenericTargetContext("the source", "the source", "the source's")
    end
    if targetKey == "aura_caster" or targetKey == "aura_target" then
        return buildOwnerTargetContext()
    end
    if eventId == "on_auto_attack_hit"
        or eventId == "on_melee_hit"
        or eventId == "on_ranged_hit"
        or eventId == "on_spell_hit"
        or eventId == "on_heal"
        or eventId == "on_critical_hit"
        or eventId == "on_critical_heal"
    then
        return buildGenericTargetContext("the target", "the target", "the target's")
    end
    if eventId == "on_auto_attack_taken"
        or eventId == "on_melee_taken"
        or eventId == "on_ranged_taken"
        or eventId == "on_spell_taken"
        or eventId == "on_heal_taken"
        or eventId == "on_critical_hit_taken"
        or eventId == "on_critical_heal_taken"
    then
        return buildOwnerTargetContext()
    end

    return buildGenericTargetContext("the other unit", "the other unit", "the other unit's")
end

local function resolveCombatTriggerLabel(combatEventId)
    local eventId = tostring(combatEventId or "")
    if eventId == "on_auto_attack_hit" then
        return "When you hit with a basic attack"
    end
    if eventId == "on_auto_attack_taken" then
        return "When you are victim of a basic attack"
    end
    if eventId == "on_melee_hit" then
        return "When you hit with a melee attack"
    end
    if eventId == "on_melee_taken" then
        return "When you are hit by a melee attack"
    end
    if eventId == "on_ranged_hit" then
        return "When you hit with a ranged attack"
    end
    if eventId == "on_ranged_taken" then
        return "When you are hit by a ranged attack"
    end
    if eventId == "on_spell_hit" then
        return "When you hit with a spell"
    end
    if eventId == "on_spell_taken" then
        return "When you are hit by a spell"
    end
    if eventId == "on_heal" then
        return "When you heal"
    end
    if eventId == "on_heal_taken" then
        return "When you are healed"
    end
    if eventId == "on_critical_hit" then
        return "When you critically hit"
    end
    if eventId == "on_critical_hit_taken" then
        return "When you are critically hit"
    end
    if eventId == "on_critical_heal" then
        return "When you critically heal"
    end
    if eventId == "on_critical_heal_taken" then
        return "When you receive a critical heal"
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

local function buildStatBonusSentence(entry)
    local amount = tonumber(entry and entry.value) or 0
    if amount == 0 then
        return nil
    end

    local statName = resolveStatName(entry and entry.statRef or nil)
    local amountText = tostring(math.abs(amount))
    if tostring(entry and entry.operation or "flat") == "percent" or isPercentDisplayStat(entry and entry.statRef or nil) then
        amountText = amountText .. "%"
    end
    if amount > 0 then
        return ("Increase %s by %s."):format(statName, amountText)
    end

    return ("Reduce %s by %s."):format(statName, amountText)
end

local function formatEventAmountText(amount, amountMode, suffix)
    local normalizedMode = tostring(amountMode or "flat")
    local normalizedSuffix = suffix and (" " .. suffix) or ""
    if normalizedMode == "base_percent" then
        return ("%g%% of Base%s"):format(math.abs(tonumber(amount) or 0), normalizedSuffix)
    end
    if normalizedMode == "max_percent" then
        return ("%g%% of Max%s"):format(math.abs(tonumber(amount) or 0), normalizedSuffix)
    end

    return tostring(math.abs(tonumber(amount) or 0)) .. normalizedSuffix
end

local function buildSkillBonusSentence(entry)
    local amount = tonumber(entry and entry.value) or 0
    if amount == 0 then
        return nil
    end

    local skillName = resolveSkillName(entry and entry.skillRef or nil)
    local amountText = tostring(math.abs(amount))
    if amount > 0 then
        return ("Increases your skill in %s by %s."):format(skillName, amountText)
    end

    return ("Reduces your skill in %s by %s."):format(skillName, amountText)
end

local function buildAutomaticAuraSentence(detail, auraEntry)
    local metadata = resolveAuraMetadata(detail, auraEntry and auraEntry.auraRef or nil)
    local targetPhrase = resolveAutomaticAuraTargetPhrase(auraEntry and auraEntry.targetScope or nil)
    local sentence = ("Apply %s to %s"):format(metadata.name, targetPhrase)
    local stacks = math.max(1, math.floor(tonumber(auraEntry and auraEntry.stacks) or 1))
    local duration = tonumber(auraEntry and auraEntry.turns) or metadata.duration
    if stacks > 1 then
        sentence = ("%s with %d stacks"):format(sentence, stacks)
    end
    if duration and duration > 0 then
        sentence = ("%s for %s"):format(sentence, formatTurnLabel(duration))
    end

    return sentence .. "."
end

local function buildEventDamageClause(casterUnit, effect, targetContext)
    if type(Combat.ResolveDamageAmount) ~= "function" then
        return nil
    end

    local schoolLabel = resolveDamageSchoolLabel(effect)
    local amountMode = tostring(effect and effect.amountMode or "flat")
    if amountMode == "flat" then
        local minimum = Combat:ResolveDamageAmount(buildValueContext(casterUnit, MIN_VARIANCE, "min"), effect)
        local maximum = Combat:ResolveDamageAmount(buildValueContext(casterUnit, MAX_VARIANCE, "max"), effect)
        return ("deal %s %s damage to %s"):format(formatValueRange(minimum, maximum), schoolLabel, targetContext.object)
    end

    return ("deal %s %s damage to %s"):format(
        formatEventAmountText(effect and effect.baseDamage, amountMode),
        schoolLabel,
        targetContext.object
    )
end

local function buildEventHealClause(casterUnit, effect, targetContext)
    if type(Combat.ResolveHealingAmount) ~= "function" then
        return nil
    end

    local amountMode = tostring(effect and effect.amountMode or "flat")
    if amountMode == "flat" then
        local minimum = Combat:ResolveHealingAmount(buildValueContext(casterUnit, MIN_VARIANCE, "min"), effect)
        local maximum = Combat:ResolveHealingAmount(buildValueContext(casterUnit, MAX_VARIANCE, "max"), effect)
        return ("heal %s for %s health"):format(targetContext.object, formatValueRange(minimum, maximum))
    end

    return ("heal %s for %s health"):format(
        targetContext.object,
        formatEventAmountText(effect and effect.baseHealing, amountMode)
    )
end

local function buildEventResourceClause(effect, targetContext)
    local amount = tonumber(effect and effect.amount) or 0
    if amount == 0 then
        return nil
    end

    local resourceName = resolveResourceName(effect and effect.resourceRef or nil)
    local amountMode = tostring(effect and effect.amountMode or "flat")
    local restoreText = formatEventAmountText(amount, amountMode, resourceName)
    local lossText = formatEventAmountText(amount, amountMode)
    if amount > 0 then
        return ("restore %s to %s"):format(restoreText, targetContext.object)
    end

    if targetContext.object == "yourself" then
        return ("lose %s"):format(lossText)
    end

    return ("reduce %s %s by %s"):format(targetContext.possessive, resourceName, lossText)
end

local function buildEventApplyAuraClause(detail, effect, targetContext)
    local metadata = resolveAuraMetadata(detail, effect and effect.auraRef or nil)
    local clause = ("apply %s to %s"):format(metadata.name, targetContext.object)
    local stacks = math.max(1, math.floor(tonumber(effect and effect.stacks) or tonumber(effect and effect.auraStacks) or 1))
    local duration = tonumber(effect and effect.duration) or metadata.duration
    if stacks > 1 then
        clause = ("%s with %d stacks"):format(clause, stacks)
    end
    if duration and duration > 0 then
        clause = ("%s for %s"):format(clause, formatTurnLabel(duration))
    end

    return clause
end

local function buildEventRemoveAuraClause(detail, effect, targetContext)
    local stacks = math.max(1, math.floor(tonumber(effect and effect.stacks) or 1))
    local auraMetadata = resolveAuraMetadata(detail, effect and effect.auraRef or nil)
    local clause = ("remove %d stack%s"):format(stacks, stacks == 1 and "" or "s")
    if auraMetadata.name ~= "an aura" then
        clause = ("%s of %s"):format(clause, auraMetadata.name)
    end
    if targetContext.object ~= "yourself" then
        clause = ("%s from %s"):format(clause, targetContext.object)
    end

    return clause
end

local function buildEventEffectClause(detail, casterUnit, eventEntry, effect)
    local targetContext = resolveTriggeredTargetContext(eventEntry and eventEntry.combatEventId or nil, eventEntry and eventEntry.triggerTarget or nil)
    local effectType = tostring(effect and effect.type or "")
    if effectType == "damage" then
        return buildEventDamageClause(casterUnit, effect, targetContext)
    end
    if effectType == "heal" then
        return buildEventHealClause(casterUnit, effect, targetContext)
    end
    if effectType == "resource" then
        return buildEventResourceClause(effect, targetContext)
    end
    if effectType == "apply_aura" then
        return buildEventApplyAuraClause(detail, effect, targetContext)
    end
    if effectType == "remove_aura" then
        return buildEventRemoveAuraClause(detail, effect, targetContext)
    end

    return nil
end

function TraitDescriptionBuilder:BuildGeneratedDescription(detail, casterUnit)
    local payload = resolveTraitPayload(detail)
    casterUnit = casterUnit or resolveCasterUnit(detail)
    local sentences = {}

    for index = 1, #(payload.statBonuses or {}) do
        local sentence = buildStatBonusSentence(payload.statBonuses[index])
        if sentence and sentence ~= "" then
            sentences[#sentences + 1] = sentence
        end
    end

    for index = 1, #(payload.skillBonuses or {}) do
        local sentence = buildSkillBonusSentence(payload.skillBonuses[index])
        if sentence and sentence ~= "" then
            sentences[#sentences + 1] = sentence
        end
    end

    for index = 1, #(payload.automaticAuras or {}) do
        local sentence = buildAutomaticAuraSentence(detail, payload.automaticAuras[index])
        if sentence and sentence ~= "" then
            sentences[#sentences + 1] = sentence
        end
    end

    for index = 1, #(payload.events or {}) do
        local eventEntry = payload.events[index]
        local clauses = {}
        for effectIndex = 1, #(eventEntry and eventEntry.effects or {}) do
            local clause = buildEventEffectClause(detail, casterUnit, eventEntry, eventEntry.effects[effectIndex])
            if clause and clause ~= "" then
                clauses[#clauses + 1] = clause
            end
        end

        if #clauses > 0 then
            local prefix = resolveCombatTriggerLabel(eventEntry and eventEntry.combatEventId or nil)
            local chance = normalizeChancePercent(eventEntry and eventEntry.chance)
            if chance < 100 then
                prefix = ("%s (%g%% chance)"):format(prefix, chance)
            end
            sentences[#sentences + 1] = prefix .. ", " .. joinClauses(clauses) .. "."
        end
    end

    return table.concat(sentences, " ")
end

function TraitDescriptionBuilder:BuildGeneratedAuraSections(detail, casterUnit)
    local payload = resolveTraitPayload(detail)
    if type(AuraDescriptionBuilder) ~= "table" or type(AuraDescriptionBuilder.BuildTooltipSection) ~= "function" then
        return {}
    end

    casterUnit = casterUnit or resolveCasterUnit(detail)
    local datasetId = resolveDatasetId(detail)
    local sections = {}
    local seen = {}

    local function addAuraSection(auraRef, stacks, duration, powerLevel, targetContext)
        if type(auraRef) ~= "string" or auraRef == "" then
            return
        end

        local sectionKey = table.concat({
            auraRef,
            tostring(stacks or ""),
            tostring(duration or ""),
            tostring(powerLevel or ""),
            tostring(targetContext and targetContext.subject or ""),
        }, "\31")
        if seen[sectionKey] then
            return
        end
        seen[sectionKey] = true

        local section = AuraDescriptionBuilder:BuildTooltipSection(auraRef, {
            dataset = type(detail) == "table" and detail.dataset or nil,
            datasetId = datasetId,
            spellDatasetId = datasetId,
            casterUnit = casterUnit,
            powerLevel = powerLevel,
            stacks = stacks,
            duration = duration,
            targetContext = targetContext,
        })
        if type(section) == "table" and trimText(section.descriptionText or "") ~= "" then
            sections[#sections + 1] = section
        end
    end

    for index = 1, #(payload.automaticAuras or {}) do
        local automaticAura = payload.automaticAuras[index]
        addAuraSection(
            automaticAura and automaticAura.auraRef or nil,
            math.max(1, math.floor(tonumber(automaticAura and automaticAura.stacks) or 1)),
            tonumber(automaticAura and automaticAura.turns) or nil,
            tonumber(automaticAura and automaticAura.powerLevel) or 0,
            resolveAutomaticAuraTargetContext(automaticAura and automaticAura.targetScope or nil)
        )
    end

    for index = 1, #(payload.events or {}) do
        local eventEntry = payload.events[index]
        local targetContext = resolveTriggeredTargetContext(eventEntry and eventEntry.combatEventId or nil, eventEntry and eventEntry.triggerTarget or nil)
        for effectIndex = 1, #(eventEntry and eventEntry.effects or {}) do
            local effect = eventEntry.effects[effectIndex]
            if tostring(effect and effect.type or "") == "apply_aura" then
                addAuraSection(
                    effect.auraRef,
                    math.max(1, math.floor(tonumber(effect.stacks) or tonumber(effect.auraStacks) or 1)),
                    tonumber(effect.duration) or nil,
                    tonumber(effect.basePower) or 0,
                    targetContext
                )
            end
        end
    end

    return sections
end

function TraitDescriptionBuilder:BuildGeneratedTooltipPayload(detail, casterUnit)
    casterUnit = casterUnit or resolveCasterUnit(detail)
    return self:BuildGeneratedDescription(detail, casterUnit), self:BuildGeneratedAuraSections(detail, casterUnit)
end

local function collectPendingDescriptionOwners(detail, requestedCacheKey, currentCacheKey)
    local owners = {}
    local keys = {
        requestedCacheKey,
    }
    if type(currentCacheKey) == "string" and currentCacheKey ~= "" and currentCacheKey ~= requestedCacheKey then
        keys[#keys + 1] = currentCacheKey
    end

    for keyIndex = 1, #keys do
        local pendingOwners = takePendingDescriptionOwners(detail, keys[keyIndex])
        for ownerIndex = 1, #(pendingOwners or {}) do
            owners[#owners + 1] = pendingOwners[ownerIndex]
        end
    end

    return owners
end

local function runQueuedDescriptionBuildResolve(state)
    if type(state) ~= "table" or type(state.detail) ~= "table" then
        return false
    end

    state.casterUnit = resolveCasterUnit(state.detail)
    return true
end

local function runQueuedDescriptionBuildDescription(state)
    if type(state) ~= "table" or type(state.builder) ~= "table" then
        return false
    end

    state.generatedDescriptionText = state.builder:BuildGeneratedDescription(state.detail, state.casterUnit)
    return true
end

local function runQueuedDescriptionBuildAuras(state)
    if type(state) ~= "table" or type(state.builder) ~= "table" then
        return false
    end

    state.generatedAuraSections = state.builder:BuildGeneratedAuraSections(state.detail, state.casterUnit)
    return true
end

local function finalizeQueuedDescriptionBuild(state)
    if type(state) ~= "table" or type(state.builder) ~= "table" or type(state.detail) ~= "table" then
        return false
    end

    local casterUnit = resolveCasterUnit(state.detail)
    local currentCacheKey = buildGeneratedDescriptionCacheKey(state.detail, casterUnit)
    local generatedDescriptionText = state.generatedDescriptionText
    local generatedAuraSections = state.generatedAuraSections
    if currentCacheKey ~= state.requestedCacheKey then
        generatedDescriptionText, generatedAuraSections = state.builder:BuildGeneratedTooltipPayload(state.detail, casterUnit)
    end

    storeGeneratedTooltipPayload(state.detail, generatedDescriptionText, generatedAuraSections, currentCacheKey)
    refreshTooltipOwners(collectPendingDescriptionOwners(state.detail, state.requestedCacheKey, currentCacheKey))
    return true
end

local function enqueueQueuedDescriptionBuildPhase(nextPhase, state)
    if enqueueDescriptionWork(nextPhase, state) then
        return true
    end

    nextPhase(state)
    return false
end

local runQueuedDescriptionBuildPhaseDescription
local runQueuedDescriptionBuildPhaseAuras
local runQueuedDescriptionBuildPhaseFinalize

local function runQueuedDescriptionBuildPhaseResolve(state)
    if not runQueuedDescriptionBuildResolve(state) then
        return
    end

    enqueueQueuedDescriptionBuildPhase(runQueuedDescriptionBuildPhaseDescription, state)
end

runQueuedDescriptionBuildPhaseDescription = function(state)
    if not runQueuedDescriptionBuildDescription(state) then
        return
    end

    enqueueQueuedDescriptionBuildPhase(runQueuedDescriptionBuildPhaseAuras, state)
end

runQueuedDescriptionBuildPhaseAuras = function(state)
    if not runQueuedDescriptionBuildAuras(state) then
        return
    end

    enqueueQueuedDescriptionBuildPhase(runQueuedDescriptionBuildPhaseFinalize, state)
end

runQueuedDescriptionBuildPhaseFinalize = function(state)
    finalizeQueuedDescriptionBuild(state)
end

function TraitDescriptionBuilder:QueueDescriptionBuild(detail, cacheKey, owner)
    if type(detail) ~= "table" or type(cacheKey) ~= "string" or cacheKey == "" then
        return false
    end

    local pendingByKey = ensurePendingDescriptionState(detail)
    if type(pendingByKey) ~= "table" then
        return false
    end

    addPendingDescriptionOwner(detail, cacheKey, owner)
    if pendingByKey[cacheKey] then
        return true
    end

    pendingByKey[cacheKey] = true
    local state = {
        builder = self,
        detail = detail,
        requestedCacheKey = cacheKey,
        casterUnit = nil,
        generatedDescriptionText = nil,
        generatedAuraSections = nil,
    }

    local enqueued = enqueueDescriptionWork(runQueuedDescriptionBuildPhaseResolve, state)
    if enqueued then
        return true
    end

    local casterUnit = resolveCasterUnit(detail)
    local currentCacheKey = buildGeneratedDescriptionCacheKey(detail, casterUnit)
    local generatedDescriptionText, generatedAuraSections = self:BuildGeneratedTooltipPayload(detail, casterUnit)
    storeGeneratedTooltipPayload(detail, generatedDescriptionText, generatedAuraSections, currentCacheKey)
    refreshTooltipOwners(collectPendingDescriptionOwners(detail, cacheKey, currentCacheKey))
    return false
end

function TraitDescriptionBuilder:BuildTooltipData(detail, options)
    local authoredDescriptionText = trimText(
        type(detail) == "table" and detail.authoredDescriptionText
            or type(detail) == "table" and resolveTraitPayload(detail).description
            or ""
    )
    local cacheKey = buildGeneratedDescriptionCacheKey(detail, nil)
    local hasCachedGeneratedDescription = type(detail) == "table"
        and tostring(detail.generatedDescriptionCacheKey or "") == cacheKey
        and detail.generatedDescriptionText ~= nil
    local hasCachedAuraSections = type(detail) == "table"
        and tostring(detail.generatedAuraSectionsCacheKey or "") == cacheKey
        and type(detail.generatedAuraSections) == "table"

    local allowDeferredBuild = not (type(options) == "table" and options.deferGeneration == false)
    local tooltipOwner = type(options) == "table" and options.tooltipOwner or nil
    if (not hasCachedGeneratedDescription or not hasCachedAuraSections)
        and allowDeferredBuild
        and self:QueueDescriptionBuild(detail, cacheKey, tooltipOwner)
    then
        local fallbackDescriptionText = authoredDescriptionText
        local fallbackSource = "authored"
        if fallbackDescriptionText ~= "" then
            fallbackDescriptionText = decorateConsumableDescriptionText(detail, fallbackDescriptionText)
            detail.descriptionText = fallbackDescriptionText
            detail.descriptionSource = fallbackSource
        elseif hasCachedGeneratedDescription and trimText(detail.generatedDescriptionText or "") ~= "" then
            fallbackDescriptionText = decorateConsumableDescriptionText(detail, trimText(detail.generatedDescriptionText or ""))
            fallbackSource = "generated"
            detail.descriptionText = fallbackDescriptionText
            detail.descriptionSource = fallbackSource
        else
            fallbackDescriptionText, fallbackSource = applySummaryFallback(detail)
        end

        return {
            descriptionText = fallbackDescriptionText,
            descriptionSource = fallbackSource,
            auraSections = {},
        }
    end

    if not hasCachedGeneratedDescription or not hasCachedAuraSections then
        local casterUnit = resolveCasterUnit(detail)
        local generatedDescriptionText, generatedAuraSections = self:BuildGeneratedTooltipPayload(detail, casterUnit)
        storeGeneratedTooltipPayload(detail, generatedDescriptionText, generatedAuraSections, cacheKey)
        hasCachedGeneratedDescription = true
        hasCachedAuraSections = true
    end

    local descriptionText = authoredDescriptionText
    local descriptionSource = "authored"
    if descriptionText == "" then
        local generatedDescriptionText = hasCachedGeneratedDescription and trimText(detail.generatedDescriptionText or "") or ""
        if generatedDescriptionText ~= "" then
            descriptionText = decorateConsumableDescriptionText(detail, generatedDescriptionText)
            descriptionSource = "generated"
            detail.descriptionText = descriptionText
            detail.descriptionSource = descriptionSource
        else
            descriptionText, descriptionSource = applySummaryFallback(detail)
        end
    else
        descriptionText = decorateConsumableDescriptionText(detail, descriptionText)
        detail.descriptionText = descriptionText
        detail.descriptionSource = descriptionSource
    end

    return {
        descriptionText = descriptionText,
        descriptionSource = descriptionSource,
        auraSections = hasCachedAuraSections and detail.generatedAuraSections or {},
    }
end

function TraitDescriptionBuilder:BuildDescription(detail, options)
    local tooltipData = self:BuildTooltipData(detail, options)
    return trimText(type(tooltipData) == "table" and tooltipData.descriptionText or ""), type(tooltipData) == "table" and tooltipData.descriptionSource or "summary"
end

function TraitDescriptionBuilder.ResolveCasterUnit(detail)
    return resolveCasterUnit(detail)
end

return TraitDescriptionBuilder
