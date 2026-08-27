local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}
Addon.Utils = Addon.Utils or {}

local Profile = Addon.Internal.Profile
local Resolver = Profile.Resolver or {}
Profile.Resolver = Resolver

local Common = Addon.Utils.Common or {}
local Database = Addon.Internal.Database or {}
local Dependencies = Database.Dependecies or {}
local Equipment = Profile.Equipment or {}
local Modifications = Profile.Modifications or {}

local function getRulesetLogic()
    return Addon.Internal and Addon.Internal.Ruleset or {}
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function cloneColor(value)
    if type(value) ~= "table" then
        return { r = 1, g = 1, b = 1, a = 1 }
    end

    return {
        r = tonumber(value.r) or 1,
        g = tonumber(value.g) or 1,
        b = tonumber(value.b) or 1,
        a = tonumber(value.a) or 1,
    }
end

local function collectActivatedStats()
    local datasets = Addon.Internal.Registry and Addon.Internal.Registry.GetActivatedDatasets and Addon.Internal.Registry:GetActivatedDatasets() or {}
    local entries = {}
    local byRef = {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local stats = dataset and dataset.stats or {}
        for statIndex = 1, #stats do
            local stat = stats[statIndex]
            if stat and stat.id then
                local ref = Dependencies.ComposeSourceStatRef and Dependencies.ComposeSourceStatRef(dataset.id, stat.id) or nil
                if ref then
                    local entry = {
                        ref = ref,
                        dataset = dataset,
                        stat = stat,
                    }
                    entries[#entries + 1] = entry
                    byRef[ref] = entry
                end
            end
        end
    end

    return entries, byRef
end

local function collectActivatedResources()
    local datasets = Addon.Internal.Registry and Addon.Internal.Registry.GetActivatedDatasets and Addon.Internal.Registry:GetActivatedDatasets() or {}
    local entries = {}
    local byRef = {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local resources = dataset and dataset.resources or {}
        for resourceIndex = 1, #resources do
            local resource = resources[resourceIndex]
            if resource and resource.id then
                local ref = Dependencies.ComposeSourceStatRef and Dependencies.ComposeSourceStatRef(dataset.id, resource.id) or nil
                if ref then
                    local entry = {
                        ref = ref,
                        dataset = dataset,
                        resource = resource,
                    }
                    entries[#entries + 1] = entry
                    byRef[ref] = entry
                end
            end
        end
    end

    return entries, byRef
end

local function collectActivatedSkills()
    local datasets = Addon.Internal.Registry and Addon.Internal.Registry.GetActivatedDatasets and Addon.Internal.Registry:GetActivatedDatasets() or {}
    local entries = {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local skills = dataset and dataset.skills or {}
        for skillIndex = 1, #skills do
            local skill = skills[skillIndex]
            if skill and skill.id then
                local ref = Dependencies.ComposeSourceStatRef and Dependencies.ComposeSourceStatRef(dataset.id, skill.id) or nil
                if ref then
                    entries[#entries + 1] = {
                        ref = ref,
                        dataset = dataset,
                        skill = skill,
                    }
                end
            end
        end
    end

    return entries
end

local function buildProfileStatBonusMap()
    local bonuses = {}
    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil
    local storedBonuses = profile and profile.statBonuses or nil

    for statRef, bonus in pairs(type(storedBonuses) == "table" and storedBonuses or {}) do
        local normalizedStatRef = ensureString(statRef)
        if normalizedStatRef ~= "" then
            bonuses[normalizedStatRef] = tonumber(bonus) or 0
        end
    end

    return bonuses
end

local function buildProfileSkillLevelMap()
    local levels = {}
    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil
    local storedLevels = profile and profile.skillLevels or nil

    for skillRef, value in pairs(type(storedLevels) == "table" and storedLevels or {}) do
        local normalizedSkillRef = ensureString(skillRef)
        if normalizedSkillRef ~= "" then
            levels[normalizedSkillRef] = math.max(0, math.floor(tonumber(value) or 0))
        end
    end

    return levels
end

local function getRulesetRuleValue(categoryKey, ruleKey, fallback)
    local rulesetLogic = getRulesetLogic()
    local ruleset = rulesetLogic.GetActiveRuleset and rulesetLogic.GetActiveRuleset() or nil
    local value = nil
    if rulesetLogic.GetRulesetRuleDefinition and rulesetLogic.GetRulesetRuleValue then
        local ruleDefinition = rulesetLogic.GetRulesetRuleDefinition(categoryKey, ruleKey)
        value = rulesetLogic.GetRulesetRuleValue(ruleset, categoryKey, ruleDefinition)
    end
    if value == nil then
        return fallback
    end

    return value
end

local function getConditions()
    return Addon.Client and Addon.Client.Conditions or {}
end

local function isTraitCategoryAllowed(category)
    local normalizedCategory = ensureString(category)
    if normalizedCategory == "class" or normalizedCategory == "class_passives" or normalizedCategory == "class_talents" then
        return getRulesetRuleValue("traits", "allow_class_traits", true) ~= false
    end
    if normalizedCategory == "race" or normalizedCategory == "race_passives" then
        return getRulesetRuleValue("traits", "allow_race_traits", true) ~= false
    end
    if normalizedCategory == "consumable" then
        return getRulesetRuleValue("consumables", "allow_consumable_traits", true) ~= false
    end

    return true
end

local function accumulateTraitStatBonuses(flatBonuses, percentBonuses, payload)
    for index = 1, #(payload and payload.statBonuses or {}) do
        local statBonus = payload.statBonuses[index]
        local statRef = type(statBonus) == "table" and ensureString(statBonus.statRef) or ""
        if statRef ~= "" then
            if tostring(type(statBonus) == "table" and statBonus.operation or "flat") == "percent" then
                percentBonuses[statRef] = (percentBonuses[statRef] or 0) + (tonumber(statBonus.value) or 0)
            else
                flatBonuses[statRef] = (flatBonuses[statRef] or 0) + (tonumber(statBonus.value) or 0)
            end
        end
    end
end

local function evaluateProfileConditions(ownerType, owner, options)
    local conditions = getConditions()
    if type(conditions) ~= "table" or type(conditions.EvaluateList) ~= "function" then
        return true
    end

    local values = type(options) == "table" and options or {}
    local context = conditions:BuildContext(ownerType, owner, values)
    local result = conditions:EvaluateList(type(owner) == "table" and owner.conditions or nil, context)
    return result.passed == true
end

local function accumulateTraitSkillBonuses(bonuses, payload)
    for index = 1, #(payload and payload.skillBonuses or {}) do
        local skillBonus = payload.skillBonuses[index]
        local skillRef = type(skillBonus) == "table" and ensureString(skillBonus.skillRef) or ""
        if skillRef ~= "" then
            bonuses[skillRef] = (bonuses[skillRef] or 0) + (tonumber(skillBonus.value) or 0)
        end
    end
end

local function buildTraitStatBonusMap()
    local bonuses = {}
    local percentBonuses = {}
    local activeTraits = type(Profile.ListActiveTraits) == "function" and Profile.ListActiveTraits() or type(Profile.ListKnownTraits) == "function" and Profile.ListKnownTraits() or {}

    for index = 1, #activeTraits do
        local row = activeTraits[index]
        local trait = row and row.trait or nil
        local category = row and row.category or nil
        if trait
            and row.isMissing ~= true
            and trait.isEnvironmental ~= true
            and isTraitCategoryAllowed(category)
            and evaluateProfileConditions("trait", trait, {
                traitRef = row and row.traitRef,
            })
        then
            accumulateTraitStatBonuses(bonuses, percentBonuses, trait)
        end
    end

    local equippedItemTraits = type(Profile.ListEquippedItemTraits) == "function" and Profile.ListEquippedItemTraits() or {}
    for index = 1, #equippedItemTraits do
        local row = equippedItemTraits[index]
        if row
            and row.isMissing ~= true
            and evaluateProfileConditions("item", row.item, {
                itemRef = row.itemRef,
                item = row.item,
                equipmentScope = row.sourceType == "mount_equipment" and "mount" or nil,
            })
            and evaluateProfileConditions("trait", row.payload or row.equipmentTrait, {
                itemRef = row.itemRef,
                item = row.item,
                equipmentScope = row.sourceType == "mount_equipment" and "mount" or nil,
            })
        then
            accumulateTraitStatBonuses(bonuses, percentBonuses, row.payload or row.equipmentTrait)
        end
    end

    local client = Addon.Client or nil
    local eventState = type(client) == "table" and type(client.GetEventState) == "function" and client:GetEventState() or nil
    if type(client) == "table" and type(eventState) == "table" and eventState.active == true and type(client.GetAppliedConsumableTraitsForEvent) == "function" then
        local appliedConsumables = client:GetAppliedConsumableTraitsForEvent(eventState) or {}
        for index = 1, #appliedConsumables do
            local entry = appliedConsumables[index]
            if isTraitCategoryAllowed("consumable")
                and evaluateProfileConditions("trait", entry and entry.payload or nil, {
                    eventState = eventState,
                    item = entry and entry.item,
                    itemRef = entry and entry.itemRef,
                })
            then
                accumulateTraitStatBonuses(bonuses, percentBonuses, entry and entry.payload or nil)
            end
        end
    end

    bonuses.__percentBonuses = percentBonuses
    return bonuses
end

local function buildTraitSkillBonusMap()
    local bonuses = {}
    local activeTraits = type(Profile.ListActiveTraits) == "function" and Profile.ListActiveTraits() or type(Profile.ListKnownTraits) == "function" and Profile.ListKnownTraits() or {}

    for index = 1, #activeTraits do
        local row = activeTraits[index]
        local trait = row and row.trait or nil
        local category = row and row.category or nil
        if trait
            and row.isMissing ~= true
            and trait.isEnvironmental ~= true
            and isTraitCategoryAllowed(category)
            and evaluateProfileConditions("trait", trait, {
                traitRef = row and row.traitRef,
            })
        then
            accumulateTraitSkillBonuses(bonuses, trait)
        end
    end

    local equippedItemTraits = type(Profile.ListEquippedItemTraits) == "function" and Profile.ListEquippedItemTraits() or {}
    for index = 1, #equippedItemTraits do
        local row = equippedItemTraits[index]
        if row
            and row.isMissing ~= true
            and evaluateProfileConditions("item", row.item, {
                itemRef = row.itemRef,
                item = row.item,
                equipmentScope = row.sourceType == "mount_equipment" and "mount" or nil,
            })
            and evaluateProfileConditions("trait", row.payload or row.equipmentTrait, {
                itemRef = row.itemRef,
                item = row.item,
                equipmentScope = row.sourceType == "mount_equipment" and "mount" or nil,
            })
        then
            accumulateTraitSkillBonuses(bonuses, row.payload or row.equipmentTrait)
        end
    end

    local client = Addon.Client or nil
    local eventState = type(client) == "table" and type(client.GetEventState) == "function" and client:GetEventState() or nil
    if type(client) == "table" and type(eventState) == "table" and eventState.active == true and type(client.GetAppliedConsumableTraitsForEvent) == "function" then
        local appliedConsumables = client:GetAppliedConsumableTraitsForEvent(eventState) or {}
        for index = 1, #appliedConsumables do
            local entry = appliedConsumables[index]
            if isTraitCategoryAllowed("consumable")
                and evaluateProfileConditions("trait", entry and entry.payload or nil, {
                    eventState = eventState,
                    item = entry and entry.item,
                    itemRef = entry and entry.itemRef,
                })
            then
                accumulateTraitSkillBonuses(bonuses, entry and entry.payload or nil)
            end
        end
    end

    return bonuses
end

local function buildEmptyResolvedComponents()
    return {
        definitionBaseValue = 0,
        raceBaseValue = 0,
        classBaseValue = 0,
        profileBonusBaseValue = 0,
        traitBonusBaseValue = 0,
        traitPercentBonus = 0,
        baseValue = 0,
        derivedContribution = 0,
        equipmentBonus = 0,
        auraFlatBonus = 0,
        auraPercentBonus = 0,
        value = 0,
    }
end

local function clampNumber(value, minimum, maximum)
    local numericValue = tonumber(value) or 0
    if minimum ~= nil and numericValue < minimum then
        numericValue = minimum
    end
    if maximum ~= nil and numericValue > maximum then
        numericValue = maximum
    end
    return numericValue
end

local function getProfileLevel()
    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil
    return math.max(1, math.floor(tonumber(profile and profile.level) or 1))
end

local function resolveProfileDefinition(reference, collectionKey)
    local normalizedRef = ensureString(reference)
    if normalizedRef == "" then
        return nil, nil
    end

    local datasetId, entryId = nil, nil
    if Dependencies.ParseSourceStatRef then
        datasetId, entryId = Dependencies.ParseSourceStatRef(normalizedRef)
    end
    if not datasetId or not entryId then
        return nil, nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
    if not dataset then
        return nil, nil
    end

    for index = 1, #(dataset[collectionKey] or {}) do
        local entry = dataset[collectionKey][index]
        if entry and tostring(entry.id or "") == entryId then
            return dataset, entry
        end
    end

    return dataset, nil
end

local function buildProgressionValueMap(progressions, refKey, level)
    local values = {}

    for index = 1, #(progressions or {}) do
        local entry = progressions[index]
        local reference = type(entry) == "table" and ensureString(entry[refKey]) or ""
        if reference ~= "" then
            values[reference] = (values[reference] or 0)
                + (tonumber(entry.initialValue) or 0)
                + ((math.max(1, level) - 1) * (tonumber(entry.perLevelValue) or 0))
        end
    end

    return values
end

local function buildProfileProgressionContext()
    local useRaces = getRulesetRuleValue("character", "use_races", false) == true
    local useClasses = getRulesetRuleValue("character", "use_classes", false) == true
    local useFallback = getRulesetRuleValue("resources", "use_base_resource_fallback", true) ~= false
    local fallbackFraction = clampNumber(getRulesetRuleValue("resources", "base_resource_fallback", 1), 0, 1)
    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil
    local level = getProfileLevel()
    local race = nil
    local class = nil

    if useRaces then
        _, race = resolveProfileDefinition(profile and profile.raceRef, "races")
    end
    if useClasses then
        _, class = resolveProfileDefinition(profile and profile.classRef, "classes")
    end

    return {
        level = level,
        useFallback = useFallback,
        fallbackFraction = fallbackFraction,
        raceStatValues = buildProgressionValueMap(race and race.statProgressions, "statRef", level),
        classStatValues = buildProgressionValueMap(class and class.statProgressions, "statRef", level),
        raceResourceValues = buildProgressionValueMap(race and race.resourceProgressions, "resourceRef", level),
        classResourceValues = buildProgressionValueMap(class and class.resourceProgressions, "resourceRef", level),
    }
end

local function shouldIncludeAuraBonuses(options)
    if type(options) ~= "table" or options.includeAuraBonuses == nil then
        return true
    end

    return options.includeAuraBonuses == true
end

local function resolveLocalAuraContext(options)
    if not shouldIncludeAuraBonuses(options) then
        return nil
    end

    local client = Addon.Client or nil
    local eventState = type(client) == "table"
        and ((type(client.GetEventState) == "function" and client:GetEventState()) or client.EventState)
        or nil
    if type(eventState) ~= "table" or eventState.active ~= true then
        return nil
    end

    local localUnit = type(client) == "table" and type(client.ResolveLocalEventUnit) == "function"
        and client:ResolveLocalEventUnit(eventState)
        or nil
    local unitEventId = tonumber(localUnit and localUnit.eventID) or 0
    if unitEventId <= 0 then
        return nil
    end

    local auraManager = type(client) == "table" and client.Spellcasting and client.Spellcasting.AuraManager or nil
    if type(auraManager) ~= "table"
        or type(auraManager.BuildStatModifierTotals) ~= "function"
        or type(auraManager.CreateStatModifierTotalsContinuation) ~= "function"
    then
        return nil
    end

    return {
        client = client,
        auraManager = auraManager,
        eventState = eventState,
        unitEventId = unitEventId,
    }
end

local function resolveAuraBonusesForStat(auraContext, statRef)
    if type(auraContext) ~= "table" or type(statRef) ~= "string" or statRef == "" then
        return 0, 0
    end

    local ok, flatBonus, percentBonus = pcall(
        auraContext.auraManager.BuildStatModifierTotals,
        auraContext.auraManager,
        auraContext.eventState,
        auraContext.unitEventId,
        statRef
    )
    if not ok then
        return 0, 0
    end

    return tonumber(flatBonus) or 0, tonumber(percentBonus) or 0
end

local function resolveAuraBonusForSkill(auraContext, skillRef)
    if type(auraContext) ~= "table" or type(skillRef) ~= "string" or skillRef == "" then
        return 0
    end

    if type(auraContext.auraManager.BuildSkillModifierTotal) ~= "function" then
        return 0
    end

    local ok, flatBonus = pcall(
        auraContext.auraManager.BuildSkillModifierTotal,
        auraContext.auraManager,
        auraContext.eventState,
        auraContext.unitEventId,
        skillRef
    )
    if not ok then
        return 0
    end

    return tonumber(flatBonus) or 0
end

local function roundResolvedValue(value)
    if type(Common.Round) == "function" then
        return Common.Round(value)
    end

    return math.floor((tonumber(value) or 0) + 0.5)
end

local function resolveStatComponents(entry, byRef, cache, activeRefs, profileBonuses, equipmentBonuses, auraContext, progressionContext)
    if not entry or not entry.ref then
        return buildEmptyResolvedComponents()
    end

    if cache[entry.ref] ~= nil then
        return cache[entry.ref]
    end

    if activeRefs[entry.ref] then
        return buildEmptyResolvedComponents()
    end
    activeRefs[entry.ref] = true

    local stat = entry.stat or {}
    local valueMode = tostring(stat.valueMode or "manual")
    local definitionBaseValue = tonumber(stat.baseValue) or 0
    local raceBaseValue = tonumber(progressionContext and progressionContext.raceStatValues and progressionContext.raceStatValues[entry.ref]) or 0
    local classBaseValue = tonumber(progressionContext and progressionContext.classStatValues and progressionContext.classStatValues[entry.ref]) or 0
    local profileBonusBaseValue = tonumber(profileBonuses[entry.ref]) or 0
    local traitBonusBaseValue = tonumber(equipmentBonuses.__traitBonuses and equipmentBonuses.__traitBonuses[entry.ref]) or 0
    local traitPercentBonus = tonumber(
        equipmentBonuses.__traitPercentBonuses
            and equipmentBonuses.__traitPercentBonuses[entry.ref]
    ) or 0
    local baseValue = definitionBaseValue + raceBaseValue + classBaseValue + profileBonusBaseValue + traitBonusBaseValue
    local derivedContribution = 0
    local equipmentBonus = tonumber(equipmentBonuses[entry.ref]) or 0

    if valueMode == "derived" and type(stat.derivedSources) == "table" and #stat.derivedSources > 0 then
        for index = 1, #stat.derivedSources do
            local source = stat.derivedSources[index]
            local sourceRef = type(source) == "table" and source.sourceStatRef or nil
            local coefficient = type(source) == "table" and tonumber(source.coefficient) or 1
            local sourceEntry = sourceRef and byRef[sourceRef] or nil
            if sourceEntry then
                local sourceComponents = resolveStatComponents(sourceEntry, byRef, cache, activeRefs, profileBonuses, equipmentBonuses, auraContext, progressionContext)
                derivedContribution = derivedContribution + ((sourceComponents and sourceComponents.value or 0) * coefficient)
            end
        end
    end

    local auraFlatBonus, auraPercentBonus = resolveAuraBonusesForStat(auraContext, entry.ref)
    local value = baseValue + derivedContribution + equipmentBonus + auraFlatBonus
    local totalPercentBonus = traitPercentBonus + auraPercentBonus
    if totalPercentBonus ~= 0 then
        value = value * (1 + (totalPercentBonus / 100))
    end
    if auraFlatBonus ~= 0 or totalPercentBonus ~= 0 then
        value = roundResolvedValue(value)
    end

    local resolved = {
        definitionBaseValue = definitionBaseValue,
        raceBaseValue = raceBaseValue,
        classBaseValue = classBaseValue,
        profileBonusBaseValue = profileBonusBaseValue,
        traitBonusBaseValue = traitBonusBaseValue,
        traitPercentBonus = traitPercentBonus,
        baseValue = baseValue,
        derivedContribution = derivedContribution,
        equipmentBonus = equipmentBonus,
        auraFlatBonus = auraFlatBonus,
        auraPercentBonus = auraPercentBonus,
        value = value,
    }

    activeRefs[entry.ref] = nil
    cache[entry.ref] = resolved
    return resolved
end

local function accumulateEquipmentStatBonuses(bonuses, equippedRows, equipmentScope)
    for index = 1, #(equippedRows or {}) do
        local entry = equippedRows[index]
        local equippedEntry = entry and entry.entry or nil
        local item = equippedEntry and Equipment.ResolveItemDefinition and Equipment.ResolveItemDefinition(equippedEntry.itemRef) or nil
        if item and not evaluateProfileConditions("item", item, {
            itemRef = equippedEntry and equippedEntry.itemRef,
            item = item,
            equipmentScope = equipmentScope,
        }) then
            item = nil
        end
        local stats = item and item.stats or nil
        if type(stats) == "table" then
            for statIndex = 1, #stats do
                local statEntry = stats[statIndex]
                local statRef = type(statEntry) == "table" and statEntry.sourceStatRef or nil
                local bonus = type(statEntry) == "table" and tonumber(statEntry.value) or 0
                if statRef and bonus ~= 0 then
                    bonuses[statRef] = (bonuses[statRef] or 0) + bonus
                end
            end
        end

        local modificationBonuses = equippedEntry and Modifications.GetAggregatedBonuses and Modifications.GetAggregatedBonuses(equippedEntry.modifications) or nil
        for statRef, bonus in pairs(modificationBonuses and modificationBonuses.stats or {}) do
            if statRef and bonus ~= 0 then
                bonuses[statRef] = (bonuses[statRef] or 0) + bonus
            end
        end
    end
end

local function accumulateEquipmentSkillBonuses(bonuses, equippedRows, equipmentScope)
    for index = 1, #(equippedRows or {}) do
        local entry = equippedRows[index]
        local equippedEntry = entry and entry.entry or nil
        local item = equippedEntry and Equipment.ResolveItemDefinition and Equipment.ResolveItemDefinition(equippedEntry.itemRef) or nil
        if item and not evaluateProfileConditions("item", item, {
            itemRef = equippedEntry and equippedEntry.itemRef,
            item = item,
            equipmentScope = equipmentScope,
        }) then
            item = nil
        end

        for bonusIndex = 1, #(item and item.skillBonuses or {}) do
            local skillBonus = item.skillBonuses[bonusIndex]
            local skillRef = type(skillBonus) == "table" and ensureString(skillBonus.skillRef) or ""
            local bonusValue = type(skillBonus) == "table" and tonumber(skillBonus.value) or 0
            if skillRef ~= "" and bonusValue ~= 0 then
                bonuses[skillRef] = (bonuses[skillRef] or 0) + bonusValue
            end
        end

        local modificationBonuses = equippedEntry and Modifications.GetAggregatedBonuses and Modifications.GetAggregatedBonuses(equippedEntry.modifications) or nil
        for skillRef, bonusValue in pairs(modificationBonuses and modificationBonuses.skills or {}) do
            if ensureString(skillRef) ~= "" and bonusValue ~= 0 then
                bonuses[skillRef] = (bonuses[skillRef] or 0) + bonusValue
            end
        end
    end
end

local function appendRuntimeStatValue(rows, valuesByRef, order, statRef, value)
    local normalizedStatRef = ensureString(statRef)
    local numericValue = tonumber(value) or 0
    if normalizedStatRef == "" or numericValue == 0 then
        return
    end

    if valuesByRef[normalizedStatRef] == nil then
        order[#order + 1] = normalizedStatRef
        valuesByRef[normalizedStatRef] = 0
    end

    valuesByRef[normalizedStatRef] = (valuesByRef[normalizedStatRef] or 0) + numericValue
end

local function buildRuntimeStatRows(baseEntries, equippedRows, extraEntries)
    local valuesByRef = {}
    local order = {}
    local equipmentBonuses = {}
    local rows = {}

    for index = 1, #(baseEntries or {}) do
        local entry = baseEntries[index]
        appendRuntimeStatValue(rows, valuesByRef, order, entry and entry.statRef, entry and entry.value)
    end

    accumulateEquipmentStatBonuses(equipmentBonuses, equippedRows, nil)
    for statRef, value in pairs(equipmentBonuses) do
        appendRuntimeStatValue(rows, valuesByRef, order, statRef, value)
    end

    for index = 1, #(extraEntries or {}) do
        local entry = extraEntries[index]
        appendRuntimeStatValue(rows, valuesByRef, order, entry and entry.statRef, entry and entry.value)
    end

    for index = 1, #order do
        local statRef = order[index]
        local value = tonumber(valuesByRef[statRef]) or 0
        rows[#rows + 1] = {
            statRef = statRef,
            value = value,
            currentValue = value,
        }
    end

    return rows
end

local function buildItemStatBonusMap()
    local bonuses = {}
    local equipped = Equipment.ListEquippedSlots and Equipment.ListEquippedSlots() or {}
    accumulateEquipmentStatBonuses(bonuses, equipped, nil)

    if type(Profile.IsMounted) == "function" and Profile.IsMounted() then
        local selectedMount = type(Profile.GetSelectedMount) == "function" and Profile.GetSelectedMount() or nil
        local mount = selectedMount and selectedMount.mount or nil
        for index = 1, #(mount and mount.stats or {}) do
            local entry = mount.stats[index]
            local statRef = type(entry) == "table" and ensureString(entry.statRef) or ""
            local bonus = type(entry) == "table" and tonumber(entry.value) or 0
            if statRef ~= "" and bonus ~= 0 then
                bonuses[statRef] = (bonuses[statRef] or 0) + bonus
            end
        end

        local mountedEquipped = Profile.ListEquippedSlotsByScope and Profile.ListEquippedSlotsByScope("mount") or {}
        accumulateEquipmentStatBonuses(bonuses, mountedEquipped, "mount")
    end

    return bonuses
end

local function buildItemSkillBonusMap()
    local bonuses = {}
    local equipped = Equipment.ListEquippedSlots and Equipment.ListEquippedSlots() or {}
    accumulateEquipmentSkillBonuses(bonuses, equipped, nil)

    if type(Profile.IsMounted) == "function" and Profile.IsMounted() then
        local mountedEquipped = Profile.ListEquippedSlotsByScope and Profile.ListEquippedSlotsByScope("mount") or {}
        accumulateEquipmentSkillBonuses(bonuses, mountedEquipped, "mount")
    end

    return bonuses
end

local function buildOriginSkillBonusMap(collectionKey)
    local bonuses = {}
    if collectionKey == "races" and getRulesetRuleValue("character", "use_races", false) ~= true then
        return bonuses
    end
    if collectionKey == "classes" and getRulesetRuleValue("character", "use_classes", false) ~= true then
        return bonuses
    end

    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil
    local reference = profile and profile[(collectionKey == "races" and "raceRef" or "classRef")] or nil
    local _, definition = resolveProfileDefinition(reference, collectionKey)

    for index = 1, #(definition and definition.skillBonuses or {}) do
        local skillBonus = definition.skillBonuses[index]
        local skillRef = type(skillBonus) == "table" and ensureString(skillBonus.skillRef) or ""
        local bonusValue = type(skillBonus) == "table" and tonumber(skillBonus.value) or 0
        if skillRef ~= "" and bonusValue ~= 0 then
            bonuses[skillRef] = (bonuses[skillRef] or 0) + bonusValue
        end
    end

    return bonuses
end

local function buildStatResolutionContext(options)
    local entries, byRef = collectActivatedStats()
    local profileBonuses = buildProfileStatBonusMap()
    local bonuses = buildItemStatBonusMap()
    local traitBonuses = buildTraitStatBonusMap()
    bonuses.__traitBonuses = traitBonuses
    bonuses.__traitPercentBonuses = traitBonuses.__percentBonuses or {}

    return {
        entries = entries,
        byRef = byRef,
        cache = {},
        profileBonuses = profileBonuses,
        bonuses = bonuses,
        auraContext = resolveLocalAuraContext(options),
        progressionContext = buildProfileProgressionContext(),
    }
end

local function buildResolvedStatRowFromComponents(entry, resolved)
    if type(entry) ~= "table" or type(resolved) ~= "table" then
        return nil
    end

    local stat = entry.stat or {}
    local statName = ensureString(stat.name)
    if statName == "" then
        statName = ensureString(stat.id)
    end
    if statName == "" then
        statName = "Unnamed Stat"
    end

    return {
        ref = entry.ref,
        datasetId = entry.dataset and entry.dataset.id or nil,
        statId = stat.id,
        name = statName,
        icon = ensureString(stat.icon),
        priority = math.floor(tonumber(stat.priority) or 0),
        color = cloneColor(stat.color),
        displayMode = tostring(stat.displayMode or "signed_value"),
        definitionBaseValue = resolved.definitionBaseValue,
        raceBaseValue = resolved.raceBaseValue,
        classBaseValue = resolved.classBaseValue,
        profileBonusBaseValue = resolved.profileBonusBaseValue,
        traitBonusBaseValue = resolved.traitBonusBaseValue,
        baseValue = resolved.baseValue,
        derivedContribution = resolved.derivedContribution,
        equipmentBonus = resolved.equipmentBonus,
        auraFlatBonus = resolved.auraFlatBonus,
        auraPercentBonus = resolved.auraPercentBonus,
        value = resolved.value,
        stat = stat,
    }
end

local function buildResolvedStatRow(entry, context)
    if type(entry) ~= "table" or type(context) ~= "table" then
        return nil
    end

    local resolved = resolveStatComponents(
        entry,
        context.byRef,
        context.cache,
        {},
        context.profileBonuses,
        context.bonuses,
        context.auraContext,
        context.progressionContext
    )
    return buildResolvedStatRowFromComponents(entry, resolved)
end

local function createResolvedStatFrame(entry, context, activeRefs)
    if type(entry) ~= "table" or not entry.ref then
        return {
            resolved = buildEmptyResolvedComponents(),
        }
    end

    if context.cache[entry.ref] ~= nil then
        return {
            resolved = context.cache[entry.ref],
        }
    end

    if activeRefs[entry.ref] then
        return {
            resolved = buildEmptyResolvedComponents(),
        }
    end

    activeRefs[entry.ref] = true
    local stat = entry.stat or {}
    local valueMode = tostring(stat.valueMode or "manual")
    local definitionBaseValue = tonumber(stat.baseValue) or 0
    local progressionContext = context.progressionContext or {}
    local profileBonuses = context.profileBonuses or {}
    local bonuses = context.bonuses or {}
    local traitBonuses = bonuses.__traitBonuses or {}
    local traitPercentBonuses = bonuses.__traitPercentBonuses or {}

    return {
        entry = entry,
        valueMode = valueMode,
        sourceIndex = 1,
        derivedContribution = 0,
        definitionBaseValue = definitionBaseValue,
        raceBaseValue = tonumber(progressionContext.raceStatValues and progressionContext.raceStatValues[entry.ref]) or 0,
        classBaseValue = tonumber(progressionContext.classStatValues and progressionContext.classStatValues[entry.ref]) or 0,
        profileBonusBaseValue = tonumber(profileBonuses[entry.ref]) or 0,
        traitBonusBaseValue = tonumber(traitBonuses[entry.ref]) or 0,
        traitPercentBonus = tonumber(traitPercentBonuses[entry.ref]) or 0,
        equipmentBonus = tonumber(bonuses[entry.ref]) or 0,
    }
end

local function completeResolvedStatFrame(frame, context)
    local entry = frame.entry
    local baseValue = frame.definitionBaseValue
        + frame.raceBaseValue
        + frame.classBaseValue
        + frame.profileBonusBaseValue
        + frame.traitBonusBaseValue
    local auraTotals = type(context.auraModifiersByStat) == "table"
        and context.auraModifiersByStat[entry.ref]
        or nil
    local auraFlatBonus = tonumber(auraTotals and auraTotals.flat) or 0
    local auraPercentBonus = tonumber(auraTotals and auraTotals.percent) or 0
    local value = baseValue + frame.derivedContribution + frame.equipmentBonus + auraFlatBonus
    local totalPercentBonus = frame.traitPercentBonus + auraPercentBonus
    if totalPercentBonus ~= 0 then
        value = value * (1 + (totalPercentBonus / 100))
    end
    if auraFlatBonus ~= 0 or totalPercentBonus ~= 0 then
        value = roundResolvedValue(value)
    end

    return {
        definitionBaseValue = frame.definitionBaseValue,
        raceBaseValue = frame.raceBaseValue,
        classBaseValue = frame.classBaseValue,
        profileBonusBaseValue = frame.profileBonusBaseValue,
        traitBonusBaseValue = frame.traitBonusBaseValue,
        traitPercentBonus = frame.traitPercentBonus,
        baseValue = baseValue,
        derivedContribution = frame.derivedContribution,
        equipmentBonus = frame.equipmentBonus,
        auraFlatBonus = auraFlatBonus,
        auraPercentBonus = auraPercentBonus,
        value = value,
    }
end

local shouldYieldResolvedStateContinuation

local function stepResolvedStatComponents(continuation, context, entry, deadlineMs)
    local state = continuation.statResolution
    if type(state) ~= "table" then
        state = {
            stack = {},
            activeRefs = {},
            depth = 0,
        }
        continuation.statResolution = state
        local rootFrame = createResolvedStatFrame(entry, context, state.activeRefs)
        if rootFrame.resolved ~= nil then
            state.resolved = rootFrame.resolved
            state.depth = 0
        else
            state.depth = 1
            state.stack[1] = rootFrame
        end
    end

    if state.resolved ~= nil then
        return true
    end

    while state.depth > 0 do
        local frame = state.stack[state.depth]
        local stat = frame.entry and frame.entry.stat or nil
        local sources = frame.valueMode == "derived" and stat and stat.derivedSources or nil
        if type(sources) == "table" and frame.sourceIndex <= #sources then
            local source = sources[frame.sourceIndex]
            frame.sourceIndex = frame.sourceIndex + 1
            local sourceRef = type(source) == "table" and source.sourceStatRef or nil
            local coefficient = type(source) == "table" and tonumber(source.coefficient) or 1
            local sourceEntry = sourceRef and context.byRef[sourceRef] or nil
            if sourceEntry then
                local sourceComponents = context.cache[sourceRef]
                if sourceComponents ~= nil then
                    frame.derivedContribution = frame.derivedContribution
                        + ((sourceComponents.value or 0) * coefficient)
                elseif state.activeRefs[sourceRef] then
                    -- Match resolveStatComponents: a cycle contributes an empty component set.
                else
                    local childFrame = createResolvedStatFrame(sourceEntry, context, state.activeRefs)
                    childFrame.parentCoefficient = coefficient
                    state.depth = state.depth + 1
                    state.stack[state.depth] = childFrame
                end
            end
        else
            local resolved = completeResolvedStatFrame(frame, context)
            context.cache[frame.entry.ref] = resolved
            state.activeRefs[frame.entry.ref] = nil
            state.stack[state.depth] = nil
            state.depth = state.depth - 1
            if state.depth <= 0 then
                state.resolved = resolved
            else
                local parentFrame = state.stack[state.depth]
                parentFrame.derivedContribution = parentFrame.derivedContribution
                    + ((resolved.value or 0) * (frame.parentCoefficient or 1))
            end
        end

        if shouldYieldResolvedStateContinuation(deadlineMs) then
            return false
        end
    end

    return true
end

local function buildResolvedStatsByRef(statRefs, options)
    local requestedRefs = type(statRefs) == "table" and statRefs or {}
    local context = buildStatResolutionContext(options)
    local rowsByRef = {}

    for index = 1, #requestedRefs do
        local statRef = ensureString(requestedRefs[index])
        local entry = context.byRef and context.byRef[statRef] or nil
        if statRef ~= "" and entry then
            rowsByRef[statRef] = buildResolvedStatRow(entry, context)
        end
    end

    return rowsByRef
end

local function buildResolvedResourceRow(entry, resolvedStatsByRef, progressionContext)
    if type(entry) ~= "table" then
        return nil
    end

    local resource = entry.resource or {}
    local resourceName = ensureString(resource.name)
    local definitionBaseValue = tonumber(resource.baseValue) or 0
    local derivedContribution = 0
    local intrinsicDerivedContribution = 0
    local raceBaseValue = tonumber(progressionContext.raceResourceValues and progressionContext.raceResourceValues[entry.ref]) or 0
    local classBaseValue = tonumber(progressionContext.classResourceValues and progressionContext.classResourceValues[entry.ref]) or 0
    local resolvedBaseValue = definitionBaseValue + raceBaseValue + classBaseValue

    if tostring(resource.valueMode or "manual") == "derived" then
        local sourceRow = type(resource.sourceStatRef) == "string" and resolvedStatsByRef[resource.sourceStatRef] or nil
        local multiplier = tonumber(resource.multiplier) or 0
        local sourceValue = sourceRow and tonumber(sourceRow.value) or 0
        local sourceIntrinsicValue = sourceRow and ((tonumber(sourceRow.baseValue) or 0) + (tonumber(sourceRow.derivedContribution) or 0)) or 0
        derivedContribution = sourceValue * multiplier
        intrinsicDerivedContribution = sourceIntrinsicValue * multiplier
    end

    if resourceName == "" then
        resourceName = ensureString(resource.id)
    end
    if resourceName == "" then
        resourceName = "Unnamed Resource"
    end

    return {
        ref = entry.ref,
        datasetId = entry.dataset and entry.dataset.id or nil,
        resourceId = resource.id,
        name = resourceName,
        icon = ensureString(resource.icon),
        color = cloneColor(resource.color),
        definitionBaseValue = definitionBaseValue,
        baseValue = resolvedBaseValue,
        derivedContribution = derivedContribution,
        raceBaseValue = raceBaseValue,
        classBaseValue = classBaseValue,
        fallbackBaseValue = 0,
        baseResourceValue = 0,
        intrinsicBaseResourceValue = resolvedBaseValue + intrinsicDerivedContribution,
        value = resolvedBaseValue + derivedContribution,
        isSpecial = resource.special == true,
        resource = resource,
    }
end

local function finalizeResolvedResourceRows(rows, progressionContext)
    for index = 1, #rows do
        local row = rows[index]
        local computedBaseResource = tonumber(row.intrinsicBaseResourceValue) or 0
        local fallbackBaseValue = 0
        if computedBaseResource <= 0 and progressionContext.useFallback == true then
            fallbackBaseValue = (tonumber(row.value) or 0) * progressionContext.fallbackFraction
            computedBaseResource = fallbackBaseValue
        end
        row.fallbackBaseValue = fallbackBaseValue
        row.baseResourceValue = computedBaseResource
    end
end

shouldYieldResolvedStateContinuation = function(deadlineMs)
    local tasks = Addon.Internal and Addon.Internal.Tasks or nil
    return type(tasks) == "table"
        and type(tasks.ShouldYield) == "function"
        and tasks:ShouldYield(deadlineMs) == true
end

local function compareResolvedStatRows(left, right)
    if left.priority == right.priority then
        local leftName = string.lower(tostring(left.name or ""))
        local rightName = string.lower(tostring(right.name or ""))
        if leftName == rightName then
            return tostring(left.statId or "") < tostring(right.statId or "")
        end
        return leftName < rightName
    end

    return left.priority > right.priority
end

local function compareResolvedResourceRows(left, right)
    local leftName = string.lower(tostring(left.name or ""))
    local rightName = string.lower(tostring(right.name or ""))
    if leftName == rightName then
        return tostring(left.resourceId or "") < tostring(right.resourceId or "")
    end

    return leftName < rightName
end

local function stepInsertionSort(continuation, rows, prefix, compare)
    local indexKey = prefix .. "SortIndex"
    local currentKey = prefix .. "SortCurrent"
    local compareKey = prefix .. "SortCompareIndex"
    local sortIndex = continuation[indexKey] or 2

    if sortIndex > #rows then
        continuation[indexKey] = nil
        continuation[currentKey] = nil
        continuation[compareKey] = nil
        return true
    end

    local current = continuation[currentKey]
    local compareIndex = continuation[compareKey]
    if current == nil then
        current = rows[sortIndex]
        compareIndex = sortIndex - 1
        continuation[currentKey] = current
        continuation[compareKey] = compareIndex
    end

    if compareIndex >= 1 and compare(current, rows[compareIndex]) then
        rows[compareIndex + 1] = rows[compareIndex]
        continuation[compareKey] = compareIndex - 1
        return false
    end

    rows[compareIndex + 1] = current
    continuation[indexKey] = sortIndex + 1
    continuation[currentKey] = nil
    continuation[compareKey] = nil
    return false
end

local function getRuntimeTraitEntries()
    local client = Addon.Client or nil
    local eventState = type(client) == "table" and type(client.GetEventState) == "function"
        and client:GetEventState()
        or nil
    local state = type(client) == "table"
        and type(client.GetTraitRuntimeState) == "function"
        and client:GetTraitRuntimeState(eventState and eventState.id or nil, false)
        or nil
    return type(state) == "table" and type(state.activeEntries) == "table" and state.activeEntries or {}
end

local function parseResolvedItemReference(itemRef)
    if type(Dependencies.ParseSourceStatRef) ~= "function" then
        return nil, nil
    end

    local datasetId, itemId = Dependencies.ParseSourceStatRef(itemRef)
    if not datasetId or not itemId then
        return nil, nil
    end
    return tostring(datasetId), tostring(itemId)
end

local function buildResolvedItemIndexKey(datasetId, itemId)
    if not datasetId or not itemId then
        return ""
    end
    return tostring(datasetId) .. ":" .. tostring(itemId)
end

local function createProgressionPreparation()
    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil
    local raceDatasetId, raceEntryId = nil, nil
    local classDatasetId, classEntryId = nil, nil
    if type(Dependencies.ParseSourceStatRef) == "function" then
        raceDatasetId, raceEntryId = Dependencies.ParseSourceStatRef(profile and profile.raceRef)
        classDatasetId, classEntryId = Dependencies.ParseSourceStatRef(profile and profile.classRef)
    end

    return {
        phase = "race-definition",
        entryIndex = 1,
        raceDatasetId = raceDatasetId,
        raceEntryId = raceEntryId,
        classDatasetId = classDatasetId,
        classEntryId = classEntryId,
        race = nil,
        class = nil,
        raceStatValues = {},
        classStatValues = {},
        raceResourceValues = {},
        classResourceValues = {},
        level = getProfileLevel(),
        useRaces = getRulesetRuleValue("character", "use_races", false) == true,
        useClasses = getRulesetRuleValue("character", "use_classes", false) == true,
        useFallback = getRulesetRuleValue("resources", "use_base_resource_fallback", true) ~= false,
        fallbackFraction = clampNumber(getRulesetRuleValue("resources", "base_resource_fallback", 1), 0, 1),
    }
end

local function advanceProgressionPreparation(continuation)
    local preparation = continuation.progressionPreparation
    local context = continuation.context.progressionContext
    if type(preparation) ~= "table" or type(context) ~= "table" then
        return true
    end

    if preparation.phase == "race-definition" then
        if not preparation.useRaces or not preparation.raceDatasetId or not preparation.raceEntryId then
            preparation.phase = "class-definition"
            preparation.entryIndex = 1
        else
            local dataset = Database.GetDatasetByID and Database.GetDatasetByID(preparation.raceDatasetId) or nil
            local entries = dataset and dataset.races or nil
            local entryCount = type(entries) == "table" and #entries or 0
            if preparation.entryIndex > entryCount then
                preparation.phase = "class-definition"
                preparation.entryIndex = 1
            else
                local entry = entries[preparation.entryIndex]
                if entry and tostring(entry.id or "") == tostring(preparation.raceEntryId) then
                    preparation.race = entry
                    preparation.phase = "class-definition"
                    preparation.entryIndex = 1
                else
                    preparation.entryIndex = preparation.entryIndex + 1
                end
            end
        end
    elseif preparation.phase == "class-definition" then
        if not preparation.useClasses or not preparation.classDatasetId or not preparation.classEntryId then
            preparation.phase = "race-stats"
            preparation.entryIndex = 1
        else
            local dataset = Database.GetDatasetByID and Database.GetDatasetByID(preparation.classDatasetId) or nil
            local entries = dataset and dataset.classes or nil
            local entryCount = type(entries) == "table" and #entries or 0
            if preparation.entryIndex > entryCount then
                preparation.phase = "race-stats"
                preparation.entryIndex = 1
            else
                local entry = entries[preparation.entryIndex]
                if entry and tostring(entry.id or "") == tostring(preparation.classEntryId) then
                    preparation.class = entry
                    preparation.phase = "race-stats"
                    preparation.entryIndex = 1
                else
                    preparation.entryIndex = preparation.entryIndex + 1
                end
            end
        end
    else
        local list, refKey, target = nil, nil, nil
        if preparation.phase == "race-stats" then
            list, refKey, target = preparation.race and preparation.race.statProgressions, "statRef", preparation.raceStatValues
        elseif preparation.phase == "class-stats" then
            list, refKey, target = preparation.class and preparation.class.statProgressions, "statRef", preparation.classStatValues
        elseif preparation.phase == "race-resources" then
            list, refKey, target = preparation.race and preparation.race.resourceProgressions, "resourceRef", preparation.raceResourceValues
        elseif preparation.phase == "class-resources" then
            list, refKey, target = preparation.class and preparation.class.resourceProgressions, "resourceRef", preparation.classResourceValues
        else
            context.level = preparation.level
            context.useFallback = preparation.useFallback
            context.fallbackFraction = preparation.fallbackFraction
            context.raceStatValues = preparation.raceStatValues
            context.classStatValues = preparation.classStatValues
            context.raceResourceValues = preparation.raceResourceValues
            context.classResourceValues = preparation.classResourceValues
            continuation.progressionPreparation = nil
            return true
        end

        local entryCount = type(list) == "table" and #list or 0
        if preparation.entryIndex > entryCount then
            if preparation.phase == "race-stats" then
                preparation.phase = "class-stats"
            elseif preparation.phase == "class-stats" then
                preparation.phase = "race-resources"
            elseif preparation.phase == "race-resources" then
                preparation.phase = "class-resources"
            else
                preparation.phase = "complete"
            end
            preparation.entryIndex = 1
        else
            local entry = list[preparation.entryIndex]
            local reference = type(entry) == "table" and ensureString(entry[refKey]) or ""
            if reference ~= "" then
                target[reference] = (target[reference] or 0)
                    + (tonumber(entry.initialValue) or 0)
                    + ((math.max(1, preparation.level) - 1) * (tonumber(entry.perLevelValue) or 0))
            end
            preparation.entryIndex = preparation.entryIndex + 1
        end
    end

    return false
end

local function stepResolvedItemIndex(continuation)
    local datasetId = continuation.datasetIds[continuation.itemDatasetIndex]
    if datasetId == nil then
        continuation.itemDataset = nil
        continuation.itemEntryLimit = nil
        continuation.itemDatasetIndex = nil
        continuation.itemEntryIndex = nil
        return true
    end

    if continuation.itemDataset == nil then
        continuation.itemDataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or false
        continuation.itemEntryIndex = 1
        local items = continuation.itemDataset and continuation.itemDataset.items or nil
        continuation.itemEntryLimit = type(items) == "table" and #items or 0
    end

    local items = continuation.itemDataset and continuation.itemDataset.items or nil
    if continuation.itemEntryIndex > (continuation.itemEntryLimit or 0) then
        continuation.itemDatasetScanned[tostring(datasetId)] = true
        continuation.itemDataset = nil
        continuation.itemEntryLimit = nil
        continuation.itemDatasetIndex = continuation.itemDatasetIndex + 1
        continuation.itemEntryIndex = 1
        return false
    end

    local item = items[continuation.itemEntryIndex]
    if item == nil then
        continuation.itemEntryIndex = continuation.itemEntryIndex + 1
        return false
    end

    if item.id ~= nil then
        local key = buildResolvedItemIndexKey(datasetId, item.id)
        if key ~= "" then
            continuation.itemDefinitionIndex[key] = {
                item = item,
                dataset = continuation.itemDataset,
            }
        end
    end
    continuation.itemEntryIndex = continuation.itemEntryIndex + 1
    return false
end

local function beginResolvedItemLookup(continuation, datasetId, itemId)
    if not datasetId or not itemId then
        return false
    end

    local normalizedDatasetId = tostring(datasetId)
    if continuation.itemDatasetScanned[normalizedDatasetId] then
        return false
    end

    continuation.itemLookup = {
        datasetId = normalizedDatasetId,
        dataset = Database.GetDatasetByID and Database.GetDatasetByID(normalizedDatasetId) or nil,
        entryIndex = 1,
        entryLimit = nil,
    }
    local items = continuation.itemLookup.dataset and continuation.itemLookup.dataset.items or nil
    continuation.itemLookup.entryLimit = type(items) == "table" and #items or 0
    return true
end

local function stepResolvedItemLookup(continuation)
    local lookup = continuation.itemLookup
    if type(lookup) ~= "table" then
        return true
    end

    local items = lookup.dataset and lookup.dataset.items or nil
    if lookup.entryIndex > (lookup.entryLimit or 0) then
        continuation.itemDatasetScanned[lookup.datasetId] = true
        continuation.itemLookup = nil
        return true
    end

    local item = items[lookup.entryIndex]
    if item == nil then
        lookup.entryIndex = lookup.entryIndex + 1
        return false
    end

    if item.id ~= nil then
        local key = buildResolvedItemIndexKey(lookup.datasetId, item.id)
        if key ~= "" then
            continuation.itemDefinitionIndex[key] = {
                item = item,
                dataset = lookup.dataset,
            }
        end
    end
    lookup.entryIndex = lookup.entryIndex + 1
    return false
end

local function addResolvedEquipmentStatBonus(bonuses, statEntry)
    local statRef = type(statEntry) == "table" and statEntry.sourceStatRef or nil
    local value = type(statEntry) == "table" and tonumber(statEntry.value) or 0
    if statRef and value ~= 0 then
        bonuses[statRef] = (bonuses[statRef] or 0) + value
    end
end

local function addResolvedModificationStatBonus(bonuses, statEntry)
    local statRef = type(statEntry) == "table" and ensureString(statEntry.sourceStatRef) or ""
    local value = type(statEntry) == "table" and tonumber(statEntry.value) or 0
    if statRef ~= "" and value ~= 0 then
        bonuses[statRef] = (bonuses[statRef] or 0) + value
    end
end

local function addResolvedMountStatBonus(bonuses, statEntry)
    local statRef = type(statEntry) == "table" and ensureString(statEntry.statRef) or ""
    local value = type(statEntry) == "table" and tonumber(statEntry.value) or 0
    if statRef ~= "" and value ~= 0 then
        bonuses[statRef] = (bonuses[statRef] or 0) + value
    end
end

local function createResolvedEquipmentPreparation()
    return {
        phase = "character-init",
        rowIndex = 1,
        rows = nil,
        current = nil,
        mountStats = nil,
        mountStatIndex = 1,
    }
end

local function startResolvedEquipmentRow(continuation, preparation, scope)
    local row = preparation.rows[preparation.rowIndex]
    if row == nil then
        return false
    end

    local equippedEntry = row.entry
    local datasetId, itemId = parseResolvedItemReference(equippedEntry and equippedEntry.itemRef)
    local indexed = continuation.itemDefinitionIndex[buildResolvedItemIndexKey(datasetId, itemId)]
    if not indexed and beginResolvedItemLookup(continuation, datasetId, itemId) then
        return false, true
    end
    local item = indexed and indexed.item or nil
    if item and not evaluateProfileConditions("item", item, {
        itemRef = equippedEntry and equippedEntry.itemRef,
        item = item,
        equipmentScope = scope,
    }) then
        item = nil
    end

    preparation.current = {
        equippedEntry = equippedEntry,
        item = item,
        phase = "item-stats",
        statIndex = 1,
        modKey = nil,
        modItem = nil,
        modStatIndex = 1,
    }
    return true
end

local function stepResolvedEquipmentPreparation(continuation)
    local preparation = continuation.equipmentPreparation
    local bonuses = continuation.context.bonuses
    if type(preparation) ~= "table" then
        return true
    end

    if continuation.itemLookup ~= nil then
        stepResolvedItemLookup(continuation)
        return false
    end

    if preparation.phase == "character-init" then
        preparation.rows = Equipment.ListEquippedSlots and Equipment.ListEquippedSlots() or {}
        preparation.rowIndex = 1
        preparation.phase = "character"
        return false
    elseif preparation.phase == "mount-stats-init" then
        local selectedMount = type(Profile.IsMounted) == "function" and Profile.IsMounted()
            and type(Profile.GetSelectedMount) == "function" and Profile.GetSelectedMount()
            or nil
        preparation.mountStats = selectedMount and selectedMount.mount and selectedMount.mount.stats or {}
        preparation.mountStatIndex = 1
        preparation.phase = "mount-stats"
        return false
    elseif preparation.phase == "mount-equipment-init" then
        preparation.rows = Profile.ListEquippedSlotsByScope and Profile.ListEquippedSlotsByScope("mount") or {}
        preparation.rowIndex = 1
        preparation.phase = "mount-equipment"
        return false
    elseif preparation.phase == "mount-stats" then
        local statEntry = preparation.mountStats[preparation.mountStatIndex]
        if statEntry == nil then
            preparation.phase = "mount-equipment-init"
        else
            addResolvedMountStatBonus(bonuses, statEntry)
            preparation.mountStatIndex = preparation.mountStatIndex + 1
        end
        return false
    elseif preparation.phase == "complete" then
        continuation.equipmentPreparation = nil
        return true
    end

    if preparation.current == nil then
        local started, pendingLookup = startResolvedEquipmentRow(
            continuation,
            preparation,
            preparation.phase == "mount-equipment" and "mount" or nil
        )
        if pendingLookup then
            return false
        end
        if not started then
            if preparation.phase == "character" then
                if type(Profile.IsMounted) == "function" and Profile.IsMounted() then
                    preparation.phase = "mount-stats-init"
                else
                    preparation.phase = "complete"
                end
            else
                preparation.phase = "complete"
            end
            return false
        end
    end

    local current = preparation.current
    if current.phase == "item-stats" then
        local statEntry = current.item and current.item.stats and current.item.stats[current.statIndex] or nil
        if statEntry == nil then
            current.phase = "modifications"
        else
            addResolvedEquipmentStatBonus(bonuses, statEntry)
            current.statIndex = current.statIndex + 1
        end
    elseif current.phase == "modifications" then
        local modKey, modData = next(current.equippedEntry and current.equippedEntry.modifications or {}, current.modKey)
        current.modKey = modKey
        if modKey == nil then
            preparation.current = nil
            preparation.rowIndex = preparation.rowIndex + 1
        elseif string.match(tostring(modKey), "^mod_") then
            local datasetId, itemId = parseResolvedItemReference(modData and modData.itemRef)
            local indexed = continuation.itemDefinitionIndex[buildResolvedItemIndexKey(datasetId, itemId)]
            if not indexed and beginResolvedItemLookup(continuation, datasetId, itemId) then
                current.lookupDatasetId = datasetId
                current.lookupItemId = itemId
                current.phase = "modification-lookup"
                return false
            end
            current.modItem = indexed and indexed.item or nil
            current.modStatIndex = 1
            current.phase = "modification-stats"
        end
    elseif current.phase == "modification-lookup" then
        local indexed = continuation.itemDefinitionIndex[buildResolvedItemIndexKey(
            current.lookupDatasetId,
            current.lookupItemId
        )]
        current.modItem = indexed and indexed.item or nil
        current.lookupDatasetId = nil
        current.lookupItemId = nil
        current.modStatIndex = 1
        current.phase = "modification-stats"
    else
        local statEntry = current.modItem
            and current.modItem.stats
            and current.modItem.stats[current.modStatIndex]
            or nil
        if statEntry == nil then
            current.modItem = nil
            current.phase = "modifications"
        else
            addResolvedModificationStatBonus(bonuses, statEntry)
            current.modStatIndex = current.modStatIndex + 1
        end
    end
    return false
end

function Resolver.CreateResolvedStateContinuation(options)
    local registry = Addon.Internal and Addon.Internal.Registry or nil
    local datasetIds = type(registry) == "table" and type(registry.ListActivatedDatasetIds) == "function"
        and registry:ListActivatedDatasetIds()
        or {}
    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil
    local storedBonuses = type(profile) == "table" and profile.statBonuses or nil
    local traitBonuses = {}
    local traitPercentBonuses = {}
    local equipmentBonuses = {}
    equipmentBonuses.__traitBonuses = traitBonuses
    equipmentBonuses.__traitPercentBonuses = traitPercentBonuses

    return {
        options = options,
        phase = "profile-bonuses",
        datasetIds = datasetIds,
        datasetIndex = 1,
        entryIndex = 1,
        profileBonusSource = type(storedBonuses) == "table" and storedBonuses or {},
        profileBonusKey = nil,
        traitEntries = getRuntimeTraitEntries(),
        traitIndex = 1,
        traitBonusIndex = 1,
        progressionPreparation = createProgressionPreparation(),
        itemDatasetIndex = 1,
        itemEntryIndex = 1,
        itemDataset = nil,
        itemEntryLimit = nil,
        itemDatasetScanned = {},
        itemDefinitionIndex = {},
        itemLookup = nil,
        equipmentPreparation = createResolvedEquipmentPreparation(),
        context = {
            entries = {},
            byRef = {},
            cache = {},
            profileBonuses = {},
            bonuses = equipmentBonuses,
            auraContext = nil,
            auraModifiersByStat = {},
            progressionContext = {
                level = 1,
                useFallback = true,
                fallbackFraction = 1,
                raceStatValues = {},
                classStatValues = {},
                raceResourceValues = {},
                classResourceValues = {},
            },
        },
        statRows = {},
        statRowsByRef = {},
        resourceEntries = {},
        resourceRows = {},
        resourceRowsByRef = {},
    }
end

function Resolver.StepResolvedStateContinuation(continuation, deadlineMs)
    if type(continuation) ~= "table" then
        return true
    end

    local context = continuation.context
    if type(context) ~= "table" then
        return true
    end

    while true do
        if continuation.phase == "profile-bonuses" then
            local statRef, bonus = next(continuation.profileBonusSource, continuation.profileBonusKey)
            continuation.profileBonusKey = statRef
            if statRef == nil then
                continuation.phase = "trait-bonuses"
            else
                local normalizedStatRef = ensureString(statRef)
                if normalizedStatRef ~= "" then
                    context.profileBonuses[normalizedStatRef] = tonumber(bonus) or 0
                end
            end
        elseif continuation.phase == "trait-bonuses" then
            local sourceEntry = continuation.traitEntries[continuation.traitIndex]
            if sourceEntry == nil then
                continuation.phase = "prepare-aura"
                continuation.datasetIndex = 1
                continuation.entryIndex = 1
            else
                local payload = type(sourceEntry) == "table" and sourceEntry.payload or nil
                local statBonus = type(payload) == "table"
                    and type(payload.statBonuses) == "table"
                    and payload.statBonuses[continuation.traitBonusIndex]
                    or nil
                if statBonus == nil then
                    continuation.traitIndex = continuation.traitIndex + 1
                    continuation.traitBonusIndex = 1
                else
                    local statRef = type(statBonus) == "table" and ensureString(statBonus.statRef) or ""
                    if statRef ~= "" then
                        if tostring(statBonus.operation or "flat") == "percent" then
                            context.bonuses.__traitPercentBonuses[statRef] = (context.bonuses.__traitPercentBonuses[statRef] or 0)
                                + (tonumber(statBonus.value) or 0)
                        else
                            context.bonuses.__traitBonuses[statRef] = (context.bonuses.__traitBonuses[statRef] or 0)
                                + (tonumber(statBonus.value) or 0)
                        end
                    end
                    continuation.traitBonusIndex = continuation.traitBonusIndex + 1
                end
            end
        elseif continuation.phase == "prepare-aura" then
            continuation.context.auraContext = resolveLocalAuraContext(continuation.options)
            continuation.context.auraModifiersByStat = {}
            if continuation.context.auraContext == nil then
                continuation.phase = "prepare-progression"
            else
                local auraContext = continuation.context.auraContext
                continuation.auraModifierContinuation = auraContext.auraManager:CreateStatModifierTotalsContinuation(
                    auraContext.client,
                    auraContext.eventState,
                    auraContext.unitEventId
                )
                if type(continuation.auraModifierContinuation) ~= "table" then
                    error("Resolved-state aura modifier continuation is unavailable.")
                end
                continuation.phase = "prepare-aura-modifiers"
            end
        elseif continuation.phase == "prepare-aura-modifiers" then
            local auraContext = continuation.context.auraContext
            local auraContinuation = continuation.auraModifierContinuation
            local completed, reason = auraContext.auraManager:StepStatModifierTotalsContinuation(
                auraContinuation,
                deadlineMs
            )
            if completed == nil then
                return nil, reason or "aura-stale"
            end
            if completed ~= true then
                return false
            end
            continuation.context.auraModifiersByStat = auraContinuation.modifiersByStat or {}
            continuation.auraModifierContinuation = nil
            continuation.phase = "prepare-progression"
        elseif continuation.phase == "prepare-progression" then
            if advanceProgressionPreparation(continuation) then
                continuation.phase = "prepare-items"
            end
        elseif continuation.phase == "prepare-items" then
            if stepResolvedItemIndex(continuation) then
                continuation.phase = "prepare-equipment"
            end
        elseif continuation.phase == "prepare-equipment" then
            if stepResolvedEquipmentPreparation(continuation) then
                continuation.phase = "collect-stats"
                continuation.datasetIndex = 1
                continuation.entryIndex = 1
            end
        elseif continuation.phase == "collect-stats" then
            local datasetId = continuation.datasetIds[continuation.datasetIndex]
            if datasetId == nil then
                continuation.phase = "build-stats"
                continuation.entryIndex = 1
            else
                local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
                local stat = type(dataset) == "table" and type(dataset.stats) == "table"
                    and dataset.stats[continuation.entryIndex]
                    or nil
                if stat == nil then
                    continuation.datasetIndex = continuation.datasetIndex + 1
                    continuation.entryIndex = 1
                elseif stat.id then
                    local ref = Dependencies.ComposeSourceStatRef and Dependencies.ComposeSourceStatRef(dataset.id, stat.id) or nil
                    if ref then
                        local entry = {
                            ref = ref,
                            dataset = dataset,
                            stat = stat,
                        }
                        context.entries[#context.entries + 1] = entry
                        context.byRef[ref] = entry
                    end
                    continuation.entryIndex = continuation.entryIndex + 1
                else
                    continuation.entryIndex = continuation.entryIndex + 1
                end
            end
        elseif continuation.phase == "build-stats" then
            local entry = context.entries[continuation.entryIndex]
            if entry == nil then
                continuation.phase = "sort-stats"
            else
                continuation.statEntry = continuation.statEntry or entry
                local completed = stepResolvedStatComponents(
                    continuation,
                    context,
                    continuation.statEntry,
                    deadlineMs
                )
                if not completed then
                    return false
                end
                local row = buildResolvedStatRowFromComponents(
                    continuation.statEntry,
                    continuation.statResolution.resolved
                )
                if row then
                    continuation.statRows[#continuation.statRows + 1] = row
                    continuation.statRowsByRef[row.ref] = row
                end
                continuation.statResolution = nil
                continuation.statEntry = nil
                continuation.entryIndex = continuation.entryIndex + 1
            end
        elseif continuation.phase == "sort-stats" then
            if stepInsertionSort(continuation, continuation.statRows, "stat", compareResolvedStatRows) then
                continuation.phase = "collect-resources"
                continuation.datasetIndex = 1
                continuation.entryIndex = 1
            end
        elseif continuation.phase == "collect-resources" then
            local datasetId = continuation.datasetIds[continuation.datasetIndex]
            if datasetId == nil then
                continuation.phase = "build-resources"
                continuation.entryIndex = 1
            else
                local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
                local resource = type(dataset) == "table" and type(dataset.resources) == "table"
                    and dataset.resources[continuation.entryIndex]
                    or nil
                if resource == nil then
                    continuation.datasetIndex = continuation.datasetIndex + 1
                    continuation.entryIndex = 1
                elseif resource.id then
                    local ref = Dependencies.ComposeSourceStatRef and Dependencies.ComposeSourceStatRef(dataset.id, resource.id) or nil
                    if ref then
                        continuation.resourceEntries[#continuation.resourceEntries + 1] = {
                            ref = ref,
                            dataset = dataset,
                            resource = resource,
                        }
                    end
                    continuation.entryIndex = continuation.entryIndex + 1
                else
                    continuation.entryIndex = continuation.entryIndex + 1
                end
            end
        elseif continuation.phase == "build-resources" then
            local entry = continuation.resourceEntries[continuation.entryIndex]
            if entry == nil then
                continuation.phase = "finalize-resources"
                continuation.entryIndex = 1
            else
                local row = buildResolvedResourceRow(entry, continuation.statRowsByRef, context.progressionContext)
                if row then
                    continuation.resourceRows[#continuation.resourceRows + 1] = row
                    continuation.resourceRowsByRef[row.ref] = row
                end
                continuation.entryIndex = continuation.entryIndex + 1
            end
        elseif continuation.phase == "finalize-resources" then
            local row = continuation.resourceRows[continuation.entryIndex]
            if row == nil then
                continuation.phase = "sort-resources"
            else
                local computedBaseResource = tonumber(row.intrinsicBaseResourceValue) or 0
                local fallbackBaseValue = 0
                if computedBaseResource <= 0 and context.progressionContext.useFallback == true then
                    fallbackBaseValue = (tonumber(row.value) or 0) * context.progressionContext.fallbackFraction
                    computedBaseResource = fallbackBaseValue
                end
                row.fallbackBaseValue = fallbackBaseValue
                row.baseResourceValue = computedBaseResource
                continuation.entryIndex = continuation.entryIndex + 1
            end
        elseif continuation.phase == "sort-resources" then
            if stepInsertionSort(continuation, continuation.resourceRows, "resource", compareResolvedResourceRows) then
                continuation.phase = "complete"
            end
        else
            continuation.context = nil
            continuation.datasetIds = nil
            continuation.traitEntries = nil
            continuation.resourceEntries = nil
            continuation.progressionPreparation = nil
            continuation.itemDatasetScanned = nil
            continuation.itemEntryLimit = nil
            continuation.itemDefinitionIndex = nil
            continuation.itemLookup = nil
            continuation.equipmentPreparation = nil
            continuation.statResolution = nil
            continuation.statEntry = nil
            return true
        end

        if shouldYieldResolvedStateContinuation(deadlineMs) then
            return false
        end
    end
end

function Resolver.ListResolvedStats(options)
    local context = buildStatResolutionContext(options)
    local rows = {}

    for index = 1, #context.entries do
        local row = buildResolvedStatRow(context.entries[index], context)
        if row then
            rows[#rows + 1] = row
        end
    end

    table.sort(rows, function(left, right)
        if left.priority == right.priority then
            local leftName = string.lower(tostring(left.name or ""))
            local rightName = string.lower(tostring(right.name or ""))
            if leftName == rightName then
                return tostring(left.statId or "") < tostring(right.statId or "")
            end
            return leftName < rightName
        end
        return left.priority > right.priority
    end)

    return rows
end

function Resolver.GetResolvedStatRowsByRefs(statRefs, options)
    local rowsByRef = buildResolvedStatsByRef(statRefs, options)
    local rows = {}

    for index = 1, #(statRefs or {}) do
        local statRef = ensureString(statRefs[index])
        local row = rowsByRef[statRef]
        if row then
            rows[#rows + 1] = row
        end
    end

    return rows
end

function Resolver.ListResolvedResources(options, resolvedStatRows)
    local entries = collectActivatedResources()
    local statRows = type(resolvedStatRows) == "table"
        and resolvedStatRows
        or Resolver.ListResolvedStats(options)
    local progressionContext = buildProfileProgressionContext()
    local resolvedStatsByRef = {}
    local rows = {}

    for index = 1, #statRows do
        local statRow = statRows[index]
        if statRow and statRow.ref then
            resolvedStatsByRef[statRow.ref] = statRow
        end
    end

    for index = 1, #entries do
        local row = buildResolvedResourceRow(entries[index], resolvedStatsByRef, progressionContext)
        if row then
            rows[#rows + 1] = row
        end
    end

    finalizeResolvedResourceRows(rows, progressionContext)

    table.sort(rows, function(left, right)
        local leftName = string.lower(tostring(left.name or ""))
        local rightName = string.lower(tostring(right.name or ""))
        if leftName == rightName then
            return tostring(left.resourceId or "") < tostring(right.resourceId or "")
        end
        return leftName < rightName
    end)

    return rows
end

function Resolver.GetResolvedResourceRowsByRefs(resourceRefs, options)
    local entries, entriesByRef = collectActivatedResources()
    local progressionContext = buildProfileProgressionContext()
    local requestedStatRefs = {}
    local seenStatRefs = {}
    local resolvedStatsByRef = {}
    local rows = {}

    for index = 1, #(resourceRefs or {}) do
        local resourceRef = ensureString(resourceRefs[index])
        local entry = entriesByRef and entriesByRef[resourceRef] or nil
        local resource = entry and entry.resource or nil
        local sourceStatRef = type(resource) == "table" and ensureString(resource.sourceStatRef) or ""
        if sourceStatRef ~= "" and not seenStatRefs[sourceStatRef] then
            seenStatRefs[sourceStatRef] = true
            requestedStatRefs[#requestedStatRefs + 1] = sourceStatRef
        end
    end

    local statRows = buildResolvedStatsByRef(requestedStatRefs, options)
    for statRef, row in pairs(statRows) do
        resolvedStatsByRef[statRef] = row
    end

    for index = 1, #(resourceRefs or {}) do
        local resourceRef = ensureString(resourceRefs[index])
        local entry = entriesByRef and entriesByRef[resourceRef] or nil
        local row = entry and buildResolvedResourceRow(entry, resolvedStatsByRef, progressionContext) or nil
        if row then
            rows[#rows + 1] = row
        end
    end

    finalizeResolvedResourceRows(rows, progressionContext)
    return rows
end

local SKILL_TYPE_ORDER = {
    weapon = 1,
    noncombat = 2,
    crafting = 3,
    language = 4,
}

local function isSkillTypeEnabled(skillType)
    local normalizedType = ensureString(skillType)
    if normalizedType == "weapon" then
        return getRulesetRuleValue("skills", "use_weapon_skills", true) ~= false
    end
    if normalizedType == "crafting" then
        return getRulesetRuleValue("skills", "use_crafting_skills", true) ~= false
    end
    if normalizedType == "language" then
        return getRulesetRuleValue("skills", "use_language_skills", true) ~= false
    end

    return getRulesetRuleValue("skills", "use_noncombat_skills", true) ~= false
end

local function getFixedSkillCap(skillType)
    if skillType == "crafting" then
        return math.max(1, math.floor(tonumber(getRulesetRuleValue("skills", "crafting_skill_max_level", 100)) or 100))
    end
    if skillType == "language" then
        return math.max(0, math.floor(tonumber(getRulesetRuleValue("skills", "language_skill_max_level", 100)) or 100))
    end

    return math.max(0, math.floor(tonumber(getRulesetRuleValue("skills", "noncombat_skill_max_level", 100)) or 100))
end

local function buildResolvedSkillRow(entry, resolvedStatsByRef, storedLevels, itemBonuses, traitBonuses, raceBonuses, classBonuses, auraContext, level, weaponMultiplier)
    local skill = entry and entry.skill or {}
    local skillType = ensureString(skill.skillType)
    if not isSkillTypeEnabled(skillType) then
        return nil
    end

    local maxValue = 0
    local storedValue = math.max(0, math.floor(tonumber(storedLevels and storedLevels[entry.ref]) or 0))
    local baseValue = 0
    local derivedValue = 0
    local hasDerivedStat = type(skill.derivedStatRef) == "string" and skill.derivedStatRef ~= ""

    if skillType == "weapon" then
        maxValue = math.max(0, math.floor((tonumber(level) or 0) * (tonumber(weaponMultiplier) or 0)))
        baseValue = clampNumber(storedValue, 0, maxValue)
    elseif skillType == "crafting" or skillType == "language" then
        maxValue = getFixedSkillCap(skillType)
        if skillType == "crafting" then
            baseValue = clampNumber(math.max(1, storedValue), 1, maxValue)
        else
            baseValue = storedValue
        end
    else
        maxValue = getFixedSkillCap(skillType)
        if hasDerivedStat then
            local statRow = resolvedStatsByRef and resolvedStatsByRef[skill.derivedStatRef] or nil
            local statValue = tonumber(statRow and statRow.value) or 0
            derivedValue = roundResolvedValue(statValue * (tonumber(skill.derivedMultiplier) or 0))
            baseValue = storedValue + derivedValue
        else
            baseValue = storedValue
        end
    end

    local name = ensureString(skill.name)
    if name == "" then
        name = ensureString(skill.id)
    end
    if name == "" then
        name = "Unnamed Skill"
    end

    local itemBonus = tonumber(itemBonuses and itemBonuses[entry.ref]) or 0
    local traitBonus = tonumber(traitBonuses and traitBonuses[entry.ref]) or 0
    local raceBonus = tonumber(raceBonuses and raceBonuses[entry.ref]) or 0
    local classBonus = tonumber(classBonuses and classBonuses[entry.ref]) or 0
    local auraBonus = resolveAuraBonusForSkill(auraContext, entry.ref)
    local bonusValue = itemBonus + traitBonus + raceBonus + classBonus + auraBonus
    local resolvedValue = math.max(0, baseValue + bonusValue)
    if skillType == "crafting" then
        resolvedValue = clampNumber(math.max(1, resolvedValue), 1, maxValue)
    end

    return {
        ref = entry.ref,
        datasetId = entry.dataset and entry.dataset.id or nil,
        skillId = skill.id,
        name = name,
        icon = ensureString(skill.icon),
        description = ensureString(skill.description),
        skillType = skillType ~= "" and skillType or "noncombat",
        weaponTypeRef = skillType == "weapon" and ensureString(skill.weaponTypeRef) or nil,
        learnMode = ensureString(skill.learnMode) ~= "" and ensureString(skill.learnMode) or "always_available",
        rollable = skill.rollable == true,
        derivedStatRef = skill.derivedStatRef,
        derivedMultiplier = tonumber(skill.derivedMultiplier) or 0,
        storedValue = storedValue,
        baseValue = baseValue,
        derivedValue = hasDerivedStat and derivedValue or nil,
        maxValue = maxValue,
        itemBonus = itemBonus,
        traitBonus = traitBonus,
        raceBonus = raceBonus,
        classBonus = classBonus,
        auraBonus = auraBonus,
        bonusValue = bonusValue,
        value = resolvedValue,
        resolvedValue = resolvedValue,
        progressValue = math.min(resolvedValue, maxValue),
        isDerived = hasDerivedStat,
        skill = skill,
    }
end

local function buildResolvedStatsByRef(statRows)
    local resolvedStatsByRef = {}

    for index = 1, #(type(statRows) == "table" and statRows or {}) do
        local statRow = statRows[index]
        if statRow and statRow.ref then
            resolvedStatsByRef[statRow.ref] = statRow
        end
    end

    return resolvedStatsByRef
end

local function requestedSkillEntries(skillRefs)
    local requestedRefs = type(skillRefs) == "table" and skillRefs or {}
    local requestedSet = {}
    local requestedEntries = {}
    local needsResolvedStats = false
    local entries = collectActivatedSkills()

    for index = 1, #requestedRefs do
        local skillRef = ensureString(requestedRefs[index])
        if skillRef ~= "" then
            requestedSet[skillRef] = true
        end
    end

    for index = 1, #entries do
        local entry = entries[index]
        local entryRef = ensureString(entry and entry.ref)
        if requestedSet[entryRef] then
            requestedEntries[#requestedEntries + 1] = entry
            local skill = entry and entry.skill or nil
            local skillType = ensureString(skill and skill.skillType)
            local derivedStatRef = ensureString(skill and skill.derivedStatRef)
            if skillType ~= "weapon" and skillType ~= "crafting" and skillType ~= "language" and derivedStatRef ~= "" then
                needsResolvedStats = true
            end
        end
    end

    return requestedEntries, needsResolvedStats
end

function Resolver.ListResolvedSkills(options)
    local entries = collectActivatedSkills()
    local resolvedStatsByRef = buildResolvedStatsByRef(Resolver.ListResolvedStats(options))
    local storedLevels = buildProfileSkillLevelMap()
    local itemBonuses = buildItemSkillBonusMap()
    local traitBonuses = buildTraitSkillBonusMap()
    local raceBonuses = buildOriginSkillBonusMap("races")
    local classBonuses = buildOriginSkillBonusMap("classes")
    local auraContext = resolveLocalAuraContext(options)
    local level = getProfileLevel()
    local weaponMultiplier = tonumber(getRulesetRuleValue("skills", "weapon_skill_level_multiplier", 5)) or 5
    local rows = {}

    for index = 1, #entries do
        local entry = entries[index]
        local row = buildResolvedSkillRow(entry, resolvedStatsByRef, storedLevels, itemBonuses, traitBonuses, raceBonuses, classBonuses, auraContext, level, weaponMultiplier)
        if row then
            rows[#rows + 1] = row
        end
    end

    table.sort(rows, function(left, right)
        local leftOrder = SKILL_TYPE_ORDER[left.skillType] or 999
        local rightOrder = SKILL_TYPE_ORDER[right.skillType] or 999
        if leftOrder == rightOrder then
            local leftName = string.lower(tostring(left.name or ""))
            local rightName = string.lower(tostring(right.name or ""))
            if leftName == rightName then
                return tostring(left.skillId or "") < tostring(right.skillId or "")
            end
            return leftName < rightName
        end
        return leftOrder < rightOrder
    end)

    return rows
end

function Resolver.GetResolvedSkillRowsByRefs(skillRefs, options)
    local requestedRefs = type(skillRefs) == "table" and skillRefs or {}
    local entries, needsResolvedStats = requestedSkillEntries(requestedRefs)
    local resolvedStatsByRef = needsResolvedStats and buildResolvedStatsByRef(Resolver.ListResolvedStats(options)) or {}
    local storedLevels = buildProfileSkillLevelMap()
    local itemBonuses = buildItemSkillBonusMap()
    local traitBonuses = buildTraitSkillBonusMap()
    local raceBonuses = buildOriginSkillBonusMap("races")
    local classBonuses = buildOriginSkillBonusMap("classes")
    local auraContext = resolveLocalAuraContext(options)
    local level = getProfileLevel()
    local weaponMultiplier = tonumber(getRulesetRuleValue("skills", "weapon_skill_level_multiplier", 5)) or 5
    local rowsByRef = {}

    for index = 1, #entries do
        local entry = entries[index]
        local row = buildResolvedSkillRow(entry, resolvedStatsByRef, storedLevels, itemBonuses, traitBonuses, raceBonuses, classBonuses, auraContext, level, weaponMultiplier)
        if row then
            rowsByRef[row.ref] = row
        end
    end

    local resolved = {}
    for index = 1, #requestedRefs do
        local skillRef = ensureString(requestedRefs[index])
        local row = rowsByRef[skillRef]
        if row then
            resolved[#resolved + 1] = row
        end
    end

    return resolved
end

Resolver.BuildUnitRuntimeStatRows = buildRuntimeStatRows

return Resolver
