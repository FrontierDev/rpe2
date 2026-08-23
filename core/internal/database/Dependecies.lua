local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}

local Database = Addon.Internal.Database
Database.Dependecies = Database.Dependecies or {}

local Dependecies = Database.Dependecies
local globalEnvironment = _G or {}

local function ensureTable(value)
    if type(value) == "table" then
        return value
    end

    return {}
end

local function sortKeys(values)
    table.sort(values, function(left, right)
        return tostring(left or "") < tostring(right or "")
    end)
    return values
end

local function getDatasetRoot()
    return Database.Datasets or rawget(globalEnvironment, "RPEngineDatasetDB")
end

local function getProfilesRoot()
    return Database.Profiles or rawget(globalEnvironment, "RPEngineProfilesDB")
end

local function getDerivedSourceRefs(entry, sourcesField, legacyField, refField)
    local refs = {}

    if type(entry) ~= "table" then
        return refs
    end

    local sources = entry[sourcesField]
    if type(sources) == "table" and #sources > 0 then
        for index = 1, #sources do
            local source = sources[index]
            local sourceRef = type(source) == "table" and source[refField] or nil
            if type(sourceRef) == "string" and sourceRef ~= "" then
                refs[#refs + 1] = sourceRef
            end
        end
    elseif type(entry[legacyField]) == "string" and entry[legacyField] ~= "" then
        refs[1] = entry[legacyField]
    end

    return refs
end

local function getStatSourceRefs(stat)
    return getDerivedSourceRefs(stat, "derivedSources", "sourceStatRef", "sourceStatRef")
end

local function getResourceSourceRefs(resource)
    local refs = {}
    if type(resource) ~= "table" then
        return refs
    end

    if type(resource.sourceStatRef) == "string" and resource.sourceStatRef ~= "" then
        refs[#refs + 1] = resource.sourceStatRef
    end
    if type(resource.regenSourceStatRef) == "string" and resource.regenSourceStatRef ~= "" then
        refs[#refs + 1] = resource.regenSourceStatRef
    end

    return refs
end

local function getItemSourceRefs(item)
    local refs = {}
    if type(item) ~= "table" then
        return refs
    end

    local function appendEmbeddedTraitRefs(trait)
        if type(trait) ~= "table" then
            return
        end

        for index = 1, #(trait.statBonuses or {}) do
            local statBonus = trait.statBonuses[index]
            local statRef = type(statBonus) == "table" and statBonus.statRef or nil
            if type(statRef) == "string" and statRef ~= "" then
                refs[#refs + 1] = statRef
            end
        end

        for index = 1, #(trait.skillBonuses or {}) do
            local skillBonus = trait.skillBonuses[index]
            local skillRef = type(skillBonus) == "table" and skillBonus.skillRef or nil
            if type(skillRef) == "string" and skillRef ~= "" then
                refs[#refs + 1] = skillRef
            end
        end

        for index = 1, #(trait.automaticAuras or {}) do
            local automaticAura = trait.automaticAuras[index]
            local auraRef = type(automaticAura) == "table" and automaticAura.auraRef or nil
            if type(auraRef) == "string" and auraRef ~= "" then
                refs[#refs + 1] = auraRef
            end
        end
    end

    if type(item.damageSchoolRef) == "string" and item.damageSchoolRef ~= "" then
        refs[#refs + 1] = item.damageSchoolRef
    end

    if type(item.validSlotRefs) == "table" then
        for index = 1, #item.validSlotRefs do
            local slotRef = item.validSlotRefs[index]
            if type(slotRef) == "string" and slotRef ~= "" then
                refs[#refs + 1] = slotRef
            end
        end
    end

    if type(item.stats) == "table" then
        for index = 1, #item.stats do
            local stat = item.stats[index]
            local sourceRef = type(stat) == "table" and stat.sourceStatRef or nil
            if type(sourceRef) == "string" and sourceRef ~= "" then
                refs[#refs + 1] = sourceRef
            end
        end
    end

    if type(item.skillBonuses) == "table" then
        for index = 1, #item.skillBonuses do
            local skillBonus = item.skillBonuses[index]
            local skillRef = type(skillBonus) == "table" and skillBonus.skillRef or nil
            if type(skillRef) == "string" and skillRef ~= "" then
                refs[#refs + 1] = skillRef
            end
        end
    end

    appendEmbeddedTraitRefs(type(item.consumableTrait) == "table" and item.consumableTrait or nil)
    appendEmbeddedTraitRefs(type(item.equipmentTrait) == "table" and item.equipmentTrait or nil)

    return refs
end

local function getTraitSourceRefs(trait)
    local refs = {}
    if type(trait) ~= "table" then
        return refs
    end

    for index = 1, #(trait.statBonuses or {}) do
        local statBonus = trait.statBonuses[index]
        local statRef = type(statBonus) == "table" and statBonus.statRef or nil
        if type(statRef) == "string" and statRef ~= "" then
            refs[#refs + 1] = statRef
        end
    end

    for index = 1, #(trait.skillBonuses or {}) do
        local skillBonus = trait.skillBonuses[index]
        local skillRef = type(skillBonus) == "table" and skillBonus.skillRef or nil
        if type(skillRef) == "string" and skillRef ~= "" then
            refs[#refs + 1] = skillRef
        end
    end

    for index = 1, #(trait.automaticAuras or {}) do
        local automaticAura = trait.automaticAuras[index]
        local auraRef = type(automaticAura) == "table" and automaticAura.auraRef or nil
        if type(auraRef) == "string" and auraRef ~= "" then
            refs[#refs + 1] = auraRef
        end
    end

    return refs
end

local function getMountSourceRefs(mount)
    local refs = {}
    if type(mount) ~= "table" then
        return refs
    end

    for index = 1, #(mount.spells or {}) do
        local spellRef = mount.spells[index]
        if type(spellRef) == "string" and spellRef ~= "" then
            refs[#refs + 1] = spellRef
        end
    end

    for index = 1, #(mount.stats or {}) do
        local statBonus = mount.stats[index]
        local statRef = type(statBonus) == "table" and statBonus.statRef or nil
        if type(statRef) == "string" and statRef ~= "" then
            refs[#refs + 1] = statRef
        end
    end

    return refs
end

local function getPetSourceRefs(pet)
    local refs = {}
    if type(pet) ~= "table" then
        return refs
    end

    if type(pet.unitRef) == "string" and pet.unitRef ~= "" then
        refs[#refs + 1] = pet.unitRef
    end

    for index = 1, #(pet.spells or {}) do
        local spellRef = pet.spells[index]
        if type(spellRef) == "string" and spellRef ~= "" then
            refs[#refs + 1] = spellRef
        end
    end

    for index = 1, #(pet.equipmentSlotRefs or {}) do
        local slotRef = pet.equipmentSlotRefs[index]
        if type(slotRef) == "string" and slotRef ~= "" then
            refs[#refs + 1] = slotRef
        end
    end

    return refs
end

local function getProgressionSourceRefs(definition)
    local refs = {}
    if type(definition) ~= "table" then
        return refs
    end

    for index = 1, #(definition.statProgressions or {}) do
        local entry = definition.statProgressions[index]
        local statRef = type(entry) == "table" and entry.statRef or nil
        if type(statRef) == "string" and statRef ~= "" then
            refs[#refs + 1] = statRef
        end
    end

    for index = 1, #(definition.resourceProgressions or {}) do
        local entry = definition.resourceProgressions[index]
        local resourceRef = type(entry) == "table" and entry.resourceRef or nil
        if type(resourceRef) == "string" and resourceRef ~= "" then
            refs[#refs + 1] = resourceRef
        end
    end

    for index = 1, #(definition.traitRefs or {}) do
        local traitRef = definition.traitRefs[index]
        if type(traitRef) == "string" and traitRef ~= "" then
            refs[#refs + 1] = traitRef
        end
    end

    for index = 1, #(definition.skillBonuses or {}) do
        local skillBonus = definition.skillBonuses[index]
        local skillRef = type(skillBonus) == "table" and skillBonus.skillRef or nil
        if type(skillRef) == "string" and skillRef ~= "" then
            refs[#refs + 1] = skillRef
        end
    end

    return refs
end

local function getSkillSourceRefs(skill)
    local refs = {}
    if type(skill) ~= "table" then
        return refs
    end

    if type(skill.derivedStatRef) == "string" and skill.derivedStatRef ~= "" then
        refs[#refs + 1] = skill.derivedStatRef
    end

    return refs
end

local function getDamageSchoolSourceRefs(damageSchool)
    local refs = {}
    if type(damageSchool) ~= "table" then
        return refs
    end

    if type(damageSchool.mitigationStatRef) == "string" and damageSchool.mitigationStatRef ~= "" then
        refs[#refs + 1] = damageSchool.mitigationStatRef
    end

    return refs
end

local function getSpellSourceRefs(spell)
    local refs = {}
    if type(spell) ~= "table" then
        return refs
    end

    for index = 1, #(spell.resourceCosts or {}) do
        local resourceCost = spell.resourceCosts[index]
        local resourceRef = type(resourceCost) == "table" and resourceCost.resourceRef or nil
        if type(resourceRef) == "string" and resourceRef ~= "" then
            refs[#refs + 1] = resourceRef
        end
    end

    for index = 1, #(spell.components or {}) do
        local component = spell.components[index]
        local effect = type(component) == "table" and component.effect or nil
        local effectTable = type(effect) == "table" and effect or nil
        local effectType = type(effect) == "table" and tostring(effect.type or "") or ""

        if effectType == "damage" or effectType == "heal" then
            local statScaling = effectTable and effectTable.statScaling or {}
            for scalingIndex = 1, #statScaling do
                local scaling = statScaling[scalingIndex]
                local statRef = type(scaling) == "table" and scaling.statRef or nil
                if type(statRef) == "string" and statRef ~= "" then
                    refs[#refs + 1] = statRef
                end
            end
        end

        if effectType == "damage" then
            local damageSchoolRefs = effectTable and effectTable.damageSchoolRefs or {}
            for schoolIndex = 1, #damageSchoolRefs do
                local damageSchoolRef = damageSchoolRefs[schoolIndex]
                if type(damageSchoolRef) == "string" and damageSchoolRef ~= "" then
                    refs[#refs + 1] = damageSchoolRef
                end
            end
        end

        local auraRef = type(effect) == "table" and effect.auraRef or nil
        if type(auraRef) == "string" and auraRef ~= "" then
            refs[#refs + 1] = auraRef
        end

        local resourceRef = type(effect) == "table" and effect.resourceRef or nil
        if type(resourceRef) == "string" and resourceRef ~= "" then
            refs[#refs + 1] = resourceRef
        end
    end

    return refs
end

local function getAuraSourceRefs(aura)
    local refs = {}
    if type(aura) ~= "table" then
        return refs
    end

    for effectIndex = 1, #(aura.effects or {}) do
        local effect = aura.effects[effectIndex]
        local effectType = type(effect) == "table" and tostring(effect.type or "") or ""
        local effectTable = type(effect) == "table" and effect or nil

        if effectType == "damage" or effectType == "heal" or effectType == "stat" then
            local statScaling = effectTable and effectTable.statScaling or {}
            for scalingIndex = 1, #statScaling do
                local scaling = statScaling[scalingIndex]
                local statRef = type(scaling) == "table" and scaling.statRef or nil
                if type(statRef) == "string" and statRef ~= "" then
                    refs[#refs + 1] = statRef
                end
            end
        end

        if effectType == "damage" then
            local damageSchoolRefs = effectTable and effectTable.damageSchoolRefs or {}
            for schoolIndex = 1, #damageSchoolRefs do
                local damageSchoolRef = damageSchoolRefs[schoolIndex]
                if type(damageSchoolRef) == "string" and damageSchoolRef ~= "" then
                    refs[#refs + 1] = damageSchoolRef
                end
            end
        end

        if effectType == "stat" and type(effectTable.statRef) == "string" and effectTable.statRef ~= "" then
            refs[#refs + 1] = effectTable.statRef
        end

        if effectType == "skill" and type(effectTable.skillRef) == "string" and effectTable.skillRef ~= "" then
            refs[#refs + 1] = effectTable.skillRef
        end
    end

    return refs
end

local function getUnitSourceRefs(unit)
    local refs = {}
    if type(unit) ~= "table" then
        return refs
    end

    for index = 1, #(unit.spells or {}) do
        local spellRef = unit.spells[index]
        if type(spellRef) == "string" and spellRef ~= "" then
            refs[#refs + 1] = spellRef
        end
    end

    for index = 1, #(unit.stats or {}) do
        local stat = unit.stats[index]
        local statRef = type(stat) == "table" and stat.statRef or nil
        if type(statRef) == "string" and statRef ~= "" then
            refs[#refs + 1] = statRef
        end
    end

    for index = 1, #(unit.resources or {}) do
        local resource = unit.resources[index]
        local resourceRef = type(resource) == "table" and resource.resourceRef or nil
        if type(resourceRef) == "string" and resourceRef ~= "" then
            refs[#refs + 1] = resourceRef
        end
    end

    local equipmentRefs = {
        unit.mainHandWeapon,
        unit.offHandWeapon,
        unit.rangedWeapon,
        unit.shield,
    }
    for index = 1, #equipmentRefs do
        local equipmentRef = equipmentRefs[index]
        if type(equipmentRef) == "string" and equipmentRef ~= "" then
            refs[#refs + 1] = equipmentRef
        end
    end

    for index = 1, #(unit.resistances or {}) do
        local resistance = unit.resistances[index]
        local damageSchoolRef = type(resistance) == "table" and resistance.damageSchoolRef or nil
        if type(damageSchoolRef) == "string" and damageSchoolRef ~= "" then
            refs[#refs + 1] = damageSchoolRef
        end
    end

    return refs
end

local ACHIEVEMENT_FILTER_REFERENCE_FIELDS = {
    "currencyRef",
    "unitRef",
    "achievementRef",
}

local function getAchievementSourceRefs(achievement)
    local refs = {}
    if type(achievement) ~= "table" then
        return refs
    end

    local criteria = type(achievement.criteria) == "table" and achievement.criteria or {}
    for index = 1, #criteria do
        local criterion = criteria[index]
        local filters = type(criterion) == "table" and criterion.filters or nil
        if type(filters) == "table" then
            for fieldIndex = 1, #ACHIEVEMENT_FILTER_REFERENCE_FIELDS do
                local fieldName = ACHIEVEMENT_FILTER_REFERENCE_FIELDS[fieldIndex]
                local reference = filters[fieldName]
                if type(reference) == "string" and reference ~= "" then
                    refs[#refs + 1] = reference
                end
            end
        end
    end

    return refs
end

local function getGuildSettingSourceRefs(guildSetting)
    local refs = {}
    if type(guildSetting) ~= "table" then
        return refs
    end

    local requisitions = type(guildSetting.requisitions) == "table" and guildSetting.requisitions or {}
    for index = 1, #requisitions do
        local requisition = requisitions[index]
        if type(requisition) == "table" then
            if type(requisition.itemRef) == "string" and requisition.itemRef ~= "" then
                refs[#refs + 1] = requisition.itemRef
            end

            local costs = type(requisition.costs) == "table" and requisition.costs or {}
            for costIndex = 1, #costs do
                local cost = costs[costIndex]
                local currencyRef = type(cost) == "table" and cost.currencyRef or nil
                if type(currencyRef) == "string" and currencyRef ~= "" then
                    refs[#refs + 1] = currencyRef
                end
            end
        end
    end

    local dailyRewards = type(guildSetting.dailyRewards) == "table" and guildSetting.dailyRewards or {}
    for index = 1, #dailyRewards do
        local reward = dailyRewards[index]
        local reference = type(reward) == "table" and reward.ref or nil
        if type(reference) == "string" and reference ~= "" then
            refs[#refs + 1] = reference
        end
    end

    local progression = guildSetting.progression
    local progressionEntries = type(progression) == "table" and type(progression.entries) == "table" and progression.entries or {}
    for index = 1, #progressionEntries do
        local entry = progressionEntries[index]
        local spellRefs = type(entry) == "table" and type(entry.spellRefs) == "table" and entry.spellRefs or {}
        for spellIndex = 1, #spellRefs do
            local spellRef = spellRefs[spellIndex]
            if type(spellRef) == "string" and spellRef ~= "" then
                refs[#refs + 1] = spellRef
            end
        end
    end

    return refs
end

local function isDeletedReference(reference, deletedDatasetId, deletedRef)
    if type(reference) ~= "string" or reference == "" then
        return false
    end

    if deletedRef and reference == deletedRef then
        return true
    end

    local sourceDatasetId = Dependecies.ParseSourceStatRef(reference)
    return deletedDatasetId ~= nil and sourceDatasetId == deletedDatasetId
end

local function pruneAchievementReferences(achievements, deletedDatasetId, deletedRef, collectionKey)
    local mutated = false
    local achievementList = type(achievements) == "table" and achievements or {}
    for index = 1, #achievementList do
        local achievement = achievementList[index]
        local criteria = type(achievement) == "table" and type(achievement.criteria) == "table" and achievement.criteria or {}
        for criterionIndex = 1, #criteria do
            local criterion = criteria[criterionIndex]
            local filters = type(criterion) == "table" and criterion.filters or nil
            if type(filters) == "table" then
                for fieldIndex = 1, #ACHIEVEMENT_FILTER_REFERENCE_FIELDS do
                    local fieldName = ACHIEVEMENT_FILTER_REFERENCE_FIELDS[fieldIndex]
                    local fieldCollectionKey = fieldName == "currencyRef" and "currencies"
                        or fieldName == "unitRef" and "units"
                        or "achievements"
                    if (not collectionKey or collectionKey == fieldCollectionKey)
                        and isDeletedReference(filters[fieldName], deletedDatasetId, deletedRef)
                    then
                        filters[fieldName] = nil
                        mutated = true
                    end
                end
            end
        end
    end

    return mutated
end

local function pruneGuildSettingReferences(guildSettings, deletedDatasetId, deletedRef, collectionKey)
    local mutated = false
    local guildSettingList = type(guildSettings) == "table" and guildSettings or {}
    for index = 1, #guildSettingList do
        local guildSetting = guildSettingList[index]

        local requisitions = type(guildSetting) == "table" and type(guildSetting.requisitions) == "table" and guildSetting.requisitions or {}
        for requisitionIndex = 1, #requisitions do
            local requisition = requisitions[requisitionIndex]
            if type(requisition) == "table" then
                if (not collectionKey or collectionKey == "items")
                    and isDeletedReference(requisition.itemRef, deletedDatasetId, deletedRef)
                then
                    requisition.itemRef = nil
                    mutated = true
                end

                local costs = type(requisition.costs) == "table" and requisition.costs or {}
                for costIndex = #costs, 1, -1 do
                    local cost = costs[costIndex]
                    local currencyRef = type(cost) == "table" and cost.currencyRef or nil
                    if (not collectionKey or collectionKey == "currencies")
                        and isDeletedReference(currencyRef, deletedDatasetId, deletedRef)
                    then
                        table.remove(costs, costIndex)
                        mutated = true
                    end
                end
            end
        end

        local dailyRewards = type(guildSetting) == "table" and type(guildSetting.dailyRewards) == "table" and guildSetting.dailyRewards or {}
        for rewardIndex = 1, #dailyRewards do
            local reward = dailyRewards[rewardIndex]
            local rewardType = type(reward) == "table" and reward.type or nil
            local rewardTypeMatchesCollection = not collectionKey
                or (collectionKey == "items" and rewardType == "item")
                or (collectionKey == "currencies" and rewardType == "currency")
            if type(reward) == "table"
                and rewardTypeMatchesCollection
                and isDeletedReference(reward.ref, deletedDatasetId, deletedRef)
            then
                reward.ref = nil
                mutated = true
            end
        end

        local progression = type(guildSetting) == "table" and guildSetting.progression or nil
        local entries = type(progression) == "table" and type(progression.entries) == "table" and progression.entries or {}
        for entryIndex = 1, #entries do
            local entry = entries[entryIndex]
            local spellRefs = type(entry) == "table" and type(entry.spellRefs) == "table" and entry.spellRefs or {}
            for spellIndex = #spellRefs, 1, -1 do
                if (not collectionKey or collectionKey == "spells")
                    and isDeletedReference(spellRefs[spellIndex], deletedDatasetId, deletedRef)
                then
                    table.remove(spellRefs, spellIndex)
                    mutated = true
                end
            end
        end
    end

    return mutated
end

local function pruneDeletedDerivedSources(entry, deletedDatasetId, legacyField, refField)
    local mutated = false
    local keptSources = {}
    local sources = type(entry) == "table" and entry.derivedSources or nil

    if type(sources) == "table" and #sources > 0 then
        for sourceIndex = 1, #sources do
            local source = sources[sourceIndex]
            local sourceDatasetId = type(source) == "table" and Dependecies.ParseSourceStatRef(source[refField]) or nil
            if sourceDatasetId ~= deletedDatasetId then
                keptSources[#keptSources + 1] = source
            else
                mutated = true
            end
        end

        if mutated then
            entry.derivedSources = keptSources
            if #keptSources == 0 and entry.valueMode == "derived" then
                entry.valueMode = "manual"
            end
        end
    else
        local sourceDatasetId = entry and Dependecies.ParseSourceStatRef(entry[legacyField]) or nil
        if sourceDatasetId == deletedDatasetId then
            entry[legacyField] = nil
            if entry.valueMode == "derived" then
                entry.valueMode = "manual"
            end
            mutated = true
        end
    end

    return mutated
end

function Dependecies.ParseSourceStatRef(sourceStatRef)
    local text = tostring(sourceStatRef or "")
    local datasetId, statId = text:match("^([^:]+):([^:]+)$")
    if not datasetId or datasetId == "" or not statId or statId == "" then
        return nil, nil
    end

    return datasetId, statId
end

function Dependecies.ComposeSourceStatRef(datasetId, statId)
    local left = tostring(datasetId or "")
    local right = tostring(statId or "")
    if left == "" or right == "" then
        return nil
    end

    return ("%s:%s"):format(left, right)
end

function Dependecies.RecomputeDatasetDependencies(datasetId)
    local root = getDatasetRoot()
    local datasets = type(root) == "table" and root.datasets or nil
    local dataset = datasets and datasets[tostring(datasetId or "")] or nil
    if not dataset then
        return nil
    end

    local seen = {}
    local dependencies = {}
    local stats = ensureTable(dataset.stats)
    local resources = ensureTable(dataset.resources)
    local units = ensureTable(dataset.units)
    local mounts = ensureTable(dataset.mounts)
    local pets = ensureTable(dataset.pets)
    local items = ensureTable(dataset.items)
    local damageSchools = ensureTable(dataset.damageSchools)
    local spells = ensureTable(dataset.spells)
    local traits = ensureTable(dataset.traits)
    local skills = ensureTable(dataset.skills)
    local races = ensureTable(dataset.races)
    local classes = ensureTable(dataset.classes)
    local auras = ensureTable(dataset.auras)
    local achievements = ensureTable(dataset.achievements)
    local guildSettings = ensureTable(dataset.guildSettings)

    for index = 1, #units do
        local unit = units[index]
        local sourceRefs = getUnitSourceRefs(unit)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #mounts do
        local mount = mounts[index]
        local sourceRefs = getMountSourceRefs(mount)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #pets do
        local pet = pets[index]
        local sourceRefs = getPetSourceRefs(pet)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #stats do
        local stat = stats[index]
        local sourceRefs = getStatSourceRefs(stat)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #resources do
        local resource = resources[index]
        local sourceRefs = getResourceSourceRefs(resource)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #items do
        local item = items[index]
        local sourceRefs = getItemSourceRefs(item)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #spells do
        local spell = spells[index]
        local sourceRefs = getSpellSourceRefs(spell)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #traits do
        local trait = traits[index]
        local sourceRefs = getTraitSourceRefs(trait)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #skills do
        local skill = skills[index]
        local sourceRefs = getSkillSourceRefs(skill)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #races do
        local race = races[index]
        local sourceRefs = getProgressionSourceRefs(race)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #classes do
        local class = classes[index]
        local sourceRefs = getProgressionSourceRefs(class)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #auras do
        local aura = auras[index]
        local sourceRefs = getAuraSourceRefs(aura)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #achievements do
        local achievement = achievements[index]
        local sourceRefs = getAchievementSourceRefs(achievement)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #guildSettings do
        local guildSetting = guildSettings[index]
        local sourceRefs = getGuildSettingSourceRefs(guildSetting)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    for index = 1, #damageSchools do
        local damageSchool = damageSchools[index]
        local sourceRefs = getDamageSchoolSourceRefs(damageSchool)

        for refIndex = 1, #sourceRefs do
            local sourceDatasetId = Dependecies.ParseSourceStatRef(sourceRefs[refIndex])
            if sourceDatasetId and sourceDatasetId ~= dataset.id and not seen[sourceDatasetId] then
                dependencies[#dependencies + 1] = sourceDatasetId
                seen[sourceDatasetId] = true
            end
        end
    end

    dataset.dependencies = sortKeys(dependencies)
    return dataset.dependencies
end

function Dependecies.RecomputeAllDatasetDependencies()
    local root = getDatasetRoot()
    if type(root) ~= "table" then
        return 0
    end
    local count = 0

    for datasetId in pairs(root.datasets or {}) do
        Dependecies.RecomputeDatasetDependencies(datasetId)
        count = count + 1
    end

    return count
end

function Dependecies.HandleDatasetDeleted(datasetId)
    local root = getDatasetRoot()
    if type(root) ~= "table" then
        return 0
    end
    local changed = 0

    for currentDatasetId, dataset in pairs(root.datasets or {}) do
        if currentDatasetId ~= datasetId then
            local mutated = false
            local stats = ensureTable(dataset.stats)
            local resources = ensureTable(dataset.resources)
            local units = ensureTable(dataset.units)
            local items = ensureTable(dataset.items)
            local damageSchools = ensureTable(dataset.damageSchools)
            local spells = ensureTable(dataset.spells)
            local mounts = ensureTable(dataset.mounts)
            local pets = ensureTable(dataset.pets)
            local traits = ensureTable(dataset.traits)
            local skills = ensureTable(dataset.skills)
            local races = ensureTable(dataset.races)
            local classes = ensureTable(dataset.classes)
            local auras = ensureTable(dataset.auras)
            local achievements = ensureTable(dataset.achievements)
            local guildSettings = ensureTable(dataset.guildSettings)

            for index = 1, #units do
                local unit = units[index]
                local unitMutated = false

                local keptSpells = {}
                for spellIndex = 1, #(unit and unit.spells or {}) do
                    local spellRef = unit.spells[spellIndex]
                    local sourceDatasetId = Dependecies.ParseSourceStatRef(spellRef)
                    if sourceDatasetId == datasetId then
                        unitMutated = true
                    else
                        keptSpells[#keptSpells + 1] = spellRef
                    end
                end
                if unitMutated then
                    unit.spells = keptSpells
                end

                local keptStats = {}
                local statsMutated = false
                for statIndex = 1, #(unit and unit.stats or {}) do
                    local stat = unit.stats[statIndex]
                    local sourceDatasetId = type(stat) == "table" and Dependecies.ParseSourceStatRef(stat.statRef) or nil
                    if sourceDatasetId == datasetId then
                        statsMutated = true
                    else
                        keptStats[#keptStats + 1] = stat
                    end
                end
                if statsMutated then
                    unit.stats = keptStats
                    unitMutated = true
                end

                local keptResources = {}
                local resourcesMutated = false
                for resourceIndex = 1, #(unit and unit.resources or {}) do
                    local resource = unit.resources[resourceIndex]
                    local sourceDatasetId = type(resource) == "table" and Dependecies.ParseSourceStatRef(resource.resourceRef) or nil
                    if sourceDatasetId == datasetId then
                        resourcesMutated = true
                    else
                        keptResources[#keptResources + 1] = resource
                    end
                end
                if resourcesMutated then
                    unit.resources = keptResources
                    unitMutated = true
                end

                local equipmentKeys = { "mainHandWeapon", "offHandWeapon", "rangedWeapon", "shield" }
                for equipmentIndex = 1, #equipmentKeys do
                    local key = equipmentKeys[equipmentIndex]
                    local equipmentRef = unit and unit[key] or nil
                    local sourceDatasetId = type(equipmentRef) == "string" and Dependecies.ParseSourceStatRef(equipmentRef) or nil
                    if sourceDatasetId == datasetId then
                        unit[key] = nil
                        unitMutated = true
                    end
                end

                local keptResistances = {}
                local resistancesMutated = false
                for resistanceIndex = 1, #(unit and unit.resistances or {}) do
                    local resistance = unit.resistances[resistanceIndex]
                    local sourceDatasetId = type(resistance) == "table" and Dependecies.ParseSourceStatRef(resistance.damageSchoolRef) or nil
                    if sourceDatasetId == datasetId then
                        resistancesMutated = true
                    else
                        keptResistances[#keptResistances + 1] = resistance
                    end
                end
                if resistancesMutated then
                    unit.resistances = keptResistances
                    unitMutated = true
                end

                if unitMutated then
                    mutated = true
                end
            end

            for index = 1, #stats do
                if pruneDeletedDerivedSources(stats[index], datasetId, "sourceStatRef", "sourceStatRef") then
                    mutated = true
                end
            end

            for index = 1, #resources do
                local resource = resources[index]
                local resourceMutated = false

                local sourceDatasetId = resource and Dependecies.ParseSourceStatRef(resource.sourceStatRef) or nil
                if sourceDatasetId == datasetId then
                    resource.sourceStatRef = nil
                    if resource.valueMode == "derived" then
                        resource.valueMode = "manual"
                    end
                    resourceMutated = true
                end

                local regenSourceDatasetId = resource and Dependecies.ParseSourceStatRef(resource.regenSourceStatRef) or nil
                if regenSourceDatasetId == datasetId then
                    resource.regenSourceStatRef = nil
                    if resource.regenMode == "derived" then
                        resource.regenMode = "manual"
                    end
                    resourceMutated = true
                end

                if resourceMutated then
                    mutated = true
                end
            end

            for index = 1, #items do
                local item = items[index]
                local itemStats = type(item) == "table" and ensureTable(item.stats) or {}
                local keptStats = {}
                local itemMutated = false

                for statIndex = 1, #itemStats do
                    local stat = itemStats[statIndex]
                    local sourceDatasetId = type(stat) == "table" and Dependecies.ParseSourceStatRef(stat.sourceStatRef) or nil
                    if sourceDatasetId == datasetId then
                        itemMutated = true
                    else
                        keptStats[#keptStats + 1] = stat
                    end
                end

                if itemMutated then
                    item.stats = keptStats
                    mutated = true
                end

                local keptSkillBonuses = {}
                local skillBonusesMutated = false
                for bonusIndex = 1, #(item and item.skillBonuses or {}) do
                    local skillBonus = item.skillBonuses[bonusIndex]
                    local sourceDatasetId = type(skillBonus) == "table" and Dependecies.ParseSourceStatRef(skillBonus.skillRef) or nil
                    if sourceDatasetId == datasetId then
                        skillBonusesMutated = true
                    else
                        keptSkillBonuses[#keptSkillBonuses + 1] = skillBonus
                    end
                end
                if skillBonusesMutated then
                    item.skillBonuses = keptSkillBonuses
                    mutated = true
                end

                local slotRefs = {}
                local slotMutated = false
                for refIndex = 1, #(item.validSlotRefs or {}) do
                    local slotRef = item.validSlotRefs[refIndex]
                    local sourceDatasetId = Dependecies.ParseSourceStatRef(slotRef)
                    if sourceDatasetId == datasetId then
                        slotMutated = true
                    else
                        slotRefs[#slotRefs + 1] = slotRef
                    end
                end
                if slotMutated then
                    item.validSlotRefs = slotRefs
                    mutated = true
                end

                local damageSchoolDatasetId = item and Dependecies.ParseSourceStatRef(item.damageSchoolRef) or nil
                if damageSchoolDatasetId == datasetId then
                    item.damageSchoolRef = nil
                    mutated = true
                end

                local embeddedTraits = {
                    type(item) == "table" and type(item.consumableTrait) == "table" and item.consumableTrait or nil,
                    type(item) == "table" and type(item.equipmentTrait) == "table" and item.equipmentTrait or nil,
                }
                for traitIndex = 1, #embeddedTraits do
                    local consumableTrait = embeddedTraits[traitIndex]
                    if consumableTrait then
                        local keptTraitStats = {}
                        local traitStatsMutated = false
                        for statIndex = 1, #(consumableTrait.statBonuses or {}) do
                            local statBonus = consumableTrait.statBonuses[statIndex]
                            local sourceDatasetId = type(statBonus) == "table" and Dependecies.ParseSourceStatRef(statBonus.statRef) or nil
                            if sourceDatasetId == datasetId then
                                traitStatsMutated = true
                            else
                                keptTraitStats[#keptTraitStats + 1] = statBonus
                            end
                        end
                        if traitStatsMutated then
                            consumableTrait.statBonuses = keptTraitStats
                            mutated = true
                        end

                        local keptTraitSkillBonuses = {}
                        local traitSkillMutated = false
                        for skillIndex = 1, #(consumableTrait.skillBonuses or {}) do
                            local skillBonus = consumableTrait.skillBonuses[skillIndex]
                            local sourceDatasetId = type(skillBonus) == "table" and Dependecies.ParseSourceStatRef(skillBonus.skillRef) or nil
                            if sourceDatasetId == datasetId then
                                traitSkillMutated = true
                            else
                                keptTraitSkillBonuses[#keptTraitSkillBonuses + 1] = skillBonus
                            end
                        end
                        if traitSkillMutated then
                            consumableTrait.skillBonuses = keptTraitSkillBonuses
                            mutated = true
                        end

                        local keptAutomaticAuras = {}
                        local automaticAurasMutated = false
                        for auraIndex = 1, #(consumableTrait.automaticAuras or {}) do
                            local automaticAura = consumableTrait.automaticAuras[auraIndex]
                            local sourceDatasetId = type(automaticAura) == "table" and Dependecies.ParseSourceStatRef(automaticAura.auraRef) or nil
                            if sourceDatasetId == datasetId then
                                automaticAurasMutated = true
                            else
                                keptAutomaticAuras[#keptAutomaticAuras + 1] = automaticAura
                            end
                        end
                        if automaticAurasMutated then
                            consumableTrait.automaticAuras = keptAutomaticAuras
                            mutated = true
                        end
                    end
                end
            end

            for index = 1, #spells do
                local spell = spells[index]
                local spellMutated = false

                local keptResourceCosts = {}
                for costIndex = 1, #(spell and spell.resourceCosts or {}) do
                    local resourceCost = spell.resourceCosts[costIndex]
                    local sourceDatasetId = type(resourceCost) == "table" and Dependecies.ParseSourceStatRef(resourceCost.resourceRef) or nil
                    if sourceDatasetId == datasetId then
                        spellMutated = true
                    else
                        keptResourceCosts[#keptResourceCosts + 1] = resourceCost
                    end
                end
                if spellMutated then
                    spell.resourceCosts = keptResourceCosts
                end

                for componentIndex = 1, #(spell and spell.components or {}) do
                    local component = spell.components[componentIndex]
                    local effect = type(component) == "table" and component.effect or nil
                    local effectTable = type(effect) == "table" and effect or nil
                    local effectType = type(effect) == "table" and tostring(effect.type or "") or ""

                    if effectTable and (effectType == "damage" or effectType == "heal") then
                        local keptScaling = {}
                        local scalingMutated = false
                        local statScaling = effectTable.statScaling or {}
                        for scalingIndex = 1, #statScaling do
                            local scaling = statScaling[scalingIndex]
                            local sourceDatasetId = type(scaling) == "table" and Dependecies.ParseSourceStatRef(scaling.statRef) or nil
                            if sourceDatasetId == datasetId then
                                scalingMutated = true
                            else
                                keptScaling[#keptScaling + 1] = scaling
                            end
                        end
                        if scalingMutated then
                            effectTable.statScaling = keptScaling
                            spellMutated = true
                        end
                    end

                    if effectTable and effectType == "damage" then
                        local keptDamageSchools = {}
                        local schoolMutated = false
                        local damageSchoolRefs = effectTable.damageSchoolRefs or {}
                        for schoolIndex = 1, #damageSchoolRefs do
                            local damageSchoolRef = damageSchoolRefs[schoolIndex]
                            local sourceDatasetId = Dependecies.ParseSourceStatRef(damageSchoolRef)
                            if sourceDatasetId == datasetId then
                                schoolMutated = true
                            else
                                keptDamageSchools[#keptDamageSchools + 1] = damageSchoolRef
                            end
                        end
                        if schoolMutated then
                            effectTable.damageSchoolRefs = keptDamageSchools
                            spellMutated = true
                        end
                    end

                    local auraDatasetId = effectTable and Dependecies.ParseSourceStatRef(effectTable.auraRef) or nil
                    if effectTable and auraDatasetId == datasetId then
                        effectTable.auraRef = nil
                        if effectTable.applyAura ~= nil then
                            effectTable.applyAura = false
                        end
                        spellMutated = true
                    end

                    local resourceDatasetId = effectTable and Dependecies.ParseSourceStatRef(effectTable.resourceRef) or nil
                    if effectTable and resourceDatasetId == datasetId then
                        effectTable.resourceRef = nil
                        spellMutated = true
                    end
                end

                if spellMutated then
                    mutated = true
                end
            end

            for index = 1, #traits do
                local trait = traits[index]
                local traitMutated = false

                local keptTraitStats = {}
                for statIndex = 1, #(trait and trait.statBonuses or {}) do
                    local statBonus = trait.statBonuses[statIndex]
                    local sourceDatasetId = type(statBonus) == "table" and Dependecies.ParseSourceStatRef(statBonus.statRef) or nil
                    if sourceDatasetId == datasetId then
                        traitMutated = true
                    else
                        keptTraitStats[#keptTraitStats + 1] = statBonus
                    end
                end
                if traitMutated then
                    trait.statBonuses = keptTraitStats
                end

                local keptAutomaticAuras = {}
                local automaticAurasMutated = false
                for auraIndex = 1, #(trait and trait.automaticAuras or {}) do
                    local automaticAura = trait.automaticAuras[auraIndex]
                    local sourceDatasetId = type(automaticAura) == "table" and Dependecies.ParseSourceStatRef(automaticAura.auraRef) or nil
                    if sourceDatasetId == datasetId then
                        automaticAurasMutated = true
                    else
                        keptAutomaticAuras[#keptAutomaticAuras + 1] = automaticAura
                    end
                end
                if automaticAurasMutated then
                    trait.automaticAuras = keptAutomaticAuras
                    traitMutated = true
                end

                local keptSkillBonuses = {}
                local skillBonusesMutated = false
                for skillIndex = 1, #(trait and trait.skillBonuses or {}) do
                    local skillBonus = trait.skillBonuses[skillIndex]
                    local sourceDatasetId = type(skillBonus) == "table" and Dependecies.ParseSourceStatRef(skillBonus.skillRef) or nil
                    if sourceDatasetId == datasetId then
                        skillBonusesMutated = true
                    else
                        keptSkillBonuses[#keptSkillBonuses + 1] = skillBonus
                    end
                end
                if skillBonusesMutated then
                    trait.skillBonuses = keptSkillBonuses
                    traitMutated = true
                end

                if traitMutated then
                    mutated = true
                end
            end

            for index = 1, #skills do
                local skill = skills[index]
                local skillDatasetId = skill and Dependecies.ParseSourceStatRef(skill.derivedStatRef) or nil
                if skillDatasetId == datasetId then
                    skill.derivedStatRef = nil
                    mutated = true
                end
            end

            for index = 1, #races do
                local race = races[index]
                local raceMutated = false
                local keptStatProgressions = {}
                for progressionIndex = 1, #(race and race.statProgressions or {}) do
                    local progression = race.statProgressions[progressionIndex]
                    local sourceDatasetId = type(progression) == "table" and Dependecies.ParseSourceStatRef(progression.statRef) or nil
                    if sourceDatasetId == datasetId then
                        raceMutated = true
                    else
                        keptStatProgressions[#keptStatProgressions + 1] = progression
                    end
                end
                if raceMutated then
                    race.statProgressions = keptStatProgressions
                end

                local keptResourceProgressions = {}
                local resourceMutated = false
                for progressionIndex = 1, #(race and race.resourceProgressions or {}) do
                    local progression = race.resourceProgressions[progressionIndex]
                    local sourceDatasetId = type(progression) == "table" and Dependecies.ParseSourceStatRef(progression.resourceRef) or nil
                    if sourceDatasetId == datasetId then
                        resourceMutated = true
                    else
                        keptResourceProgressions[#keptResourceProgressions + 1] = progression
                    end
                end
                if resourceMutated then
                    race.resourceProgressions = keptResourceProgressions
                    raceMutated = true
                end

                local keptTraitRefs = {}
                local traitRefsMutated = false
                for traitIndex = 1, #(race and race.traitRefs or {}) do
                    local traitRef = race.traitRefs[traitIndex]
                    local sourceDatasetId = Dependecies.ParseSourceStatRef(traitRef)
                    if sourceDatasetId == datasetId then
                        traitRefsMutated = true
                    else
                        keptTraitRefs[#keptTraitRefs + 1] = traitRef
                    end
                end
                if traitRefsMutated then
                    race.traitRefs = keptTraitRefs
                    raceMutated = true
                end

                local keptSkillBonuses = {}
                local skillBonusesMutated = false
                for skillIndex = 1, #(race and race.skillBonuses or {}) do
                    local skillBonus = race.skillBonuses[skillIndex]
                    local sourceDatasetId = type(skillBonus) == "table" and Dependecies.ParseSourceStatRef(skillBonus.skillRef) or nil
                    if sourceDatasetId == datasetId then
                        skillBonusesMutated = true
                    else
                        keptSkillBonuses[#keptSkillBonuses + 1] = skillBonus
                    end
                end
                if skillBonusesMutated then
                    race.skillBonuses = keptSkillBonuses
                    raceMutated = true
                end

                if raceMutated then
                    mutated = true
                end
            end

            for index = 1, #classes do
                local class = classes[index]
                local classMutated = false
                local keptStatProgressions = {}
                for progressionIndex = 1, #(class and class.statProgressions or {}) do
                    local progression = class.statProgressions[progressionIndex]
                    local sourceDatasetId = type(progression) == "table" and Dependecies.ParseSourceStatRef(progression.statRef) or nil
                    if sourceDatasetId == datasetId then
                        classMutated = true
                    else
                        keptStatProgressions[#keptStatProgressions + 1] = progression
                    end
                end
                if classMutated then
                    class.statProgressions = keptStatProgressions
                end

                local keptResourceProgressions = {}
                local resourceMutated = false
                for progressionIndex = 1, #(class and class.resourceProgressions or {}) do
                    local progression = class.resourceProgressions[progressionIndex]
                    local sourceDatasetId = type(progression) == "table" and Dependecies.ParseSourceStatRef(progression.resourceRef) or nil
                    if sourceDatasetId == datasetId then
                        resourceMutated = true
                    else
                        keptResourceProgressions[#keptResourceProgressions + 1] = progression
                    end
                end
                if resourceMutated then
                    class.resourceProgressions = keptResourceProgressions
                    classMutated = true
                end

                local keptTraitRefs = {}
                local traitRefsMutated = false
                for traitIndex = 1, #(class and class.traitRefs or {}) do
                    local traitRef = class.traitRefs[traitIndex]
                    local sourceDatasetId = Dependecies.ParseSourceStatRef(traitRef)
                    if sourceDatasetId == datasetId then
                        traitRefsMutated = true
                    else
                        keptTraitRefs[#keptTraitRefs + 1] = traitRef
                    end
                end
                if traitRefsMutated then
                    class.traitRefs = keptTraitRefs
                    classMutated = true
                end

                local keptSkillBonuses = {}
                local skillBonusesMutated = false
                for skillIndex = 1, #(class and class.skillBonuses or {}) do
                    local skillBonus = class.skillBonuses[skillIndex]
                    local sourceDatasetId = type(skillBonus) == "table" and Dependecies.ParseSourceStatRef(skillBonus.skillRef) or nil
                    if sourceDatasetId == datasetId then
                        skillBonusesMutated = true
                    else
                        keptSkillBonuses[#keptSkillBonuses + 1] = skillBonus
                    end
                end
                if skillBonusesMutated then
                    class.skillBonuses = keptSkillBonuses
                    classMutated = true
                end

                if classMutated then
                    mutated = true
                end
            end

            for index = 1, #mounts do
                local mount = mounts[index]
                local mountMutated = false
                local keptSpellRefs = {}
                local keptStats = {}

                for spellIndex = 1, #(mount and mount.spells or {}) do
                    local spellRef = mount.spells[spellIndex]
                    local sourceDatasetId = Dependecies.ParseSourceStatRef(spellRef)
                    if sourceDatasetId == datasetId then
                        mountMutated = true
                    else
                        keptSpellRefs[#keptSpellRefs + 1] = spellRef
                    end
                end

                for statIndex = 1, #(mount and mount.stats or {}) do
                    local statBonus = mount.stats[statIndex]
                    local sourceDatasetId = type(statBonus) == "table" and Dependecies.ParseSourceStatRef(statBonus.statRef) or nil
                    if sourceDatasetId == datasetId then
                        mountMutated = true
                    else
                        keptStats[#keptStats + 1] = statBonus
                    end
                end

                if mountMutated then
                    mount.spells = keptSpellRefs
                    mount.stats = keptStats
                    mutated = true
                end
            end

            for index = 1, #pets do
                local pet = pets[index]
                local petMutated = false
                local keptSpellRefs = {}
                local keptSlotRefs = {}

                local unitDatasetId = pet and Dependecies.ParseSourceStatRef(pet.unitRef) or nil
                if unitDatasetId == datasetId then
                    pet.unitRef = nil
                    petMutated = true
                end

                for spellIndex = 1, #(pet and pet.spells or {}) do
                    local spellRef = pet.spells[spellIndex]
                    local sourceDatasetId = Dependecies.ParseSourceStatRef(spellRef)
                    if sourceDatasetId == datasetId then
                        petMutated = true
                    else
                        keptSpellRefs[#keptSpellRefs + 1] = spellRef
                    end
                end

                for slotIndex = 1, #(pet and pet.equipmentSlotRefs or {}) do
                    local slotRef = pet.equipmentSlotRefs[slotIndex]
                    local sourceDatasetId = Dependecies.ParseSourceStatRef(slotRef)
                    if sourceDatasetId == datasetId then
                        petMutated = true
                    else
                        keptSlotRefs[#keptSlotRefs + 1] = slotRef
                    end
                end

                if petMutated then
                    pet.spells = keptSpellRefs
                    pet.equipmentSlotRefs = keptSlotRefs
                    mutated = true
                end
            end

            for index = 1, #auras do
                local aura = auras[index]
                local auraMutated = false

                for effectIndex = 1, #(aura and aura.effects or {}) do
                    local effect = aura.effects[effectIndex]
                    local effectTable = type(effect) == "table" and effect or nil
                    local effectType = type(effect) == "table" and tostring(effect.type or "") or ""

                    if effectTable and (effectType == "damage" or effectType == "heal" or effectType == "stat") then
                        local keptScaling = {}
                        local scalingMutated = false
                        local statScaling = effectTable.statScaling or {}
                        for scalingIndex = 1, #statScaling do
                            local scaling = statScaling[scalingIndex]
                            local sourceDatasetId = type(scaling) == "table" and Dependecies.ParseSourceStatRef(scaling.statRef) or nil
                            if sourceDatasetId == datasetId then
                                scalingMutated = true
                            else
                                keptScaling[#keptScaling + 1] = scaling
                            end
                        end
                        if scalingMutated then
                            effectTable.statScaling = keptScaling
                            auraMutated = true
                        end
                    end

                    if effectType == "damage" then
                        local keptDamageSchools = {}
                        local schoolMutated = false
                        local damageSchoolRefs = effectTable and effectTable.damageSchoolRefs or {}
                        for schoolIndex = 1, #damageSchoolRefs do
                            local damageSchoolRef = damageSchoolRefs[schoolIndex]
                            local sourceDatasetId = Dependecies.ParseSourceStatRef(damageSchoolRef)
                            if sourceDatasetId == datasetId then
                                schoolMutated = true
                            else
                                keptDamageSchools[#keptDamageSchools + 1] = damageSchoolRef
                            end
                        end
                        if schoolMutated then
                            effectTable.damageSchoolRefs = keptDamageSchools
                            auraMutated = true
                        end
                    end

                    if effectType == "stat" then
                        local statDatasetId = effectTable and Dependecies.ParseSourceStatRef(effectTable.statRef) or nil
                        if statDatasetId == datasetId then
                            effectTable.statRef = nil
                            auraMutated = true
                        end
                    end

                    if effectType == "skill" then
                        local skillDatasetId = effectTable and Dependecies.ParseSourceStatRef(effectTable.skillRef) or nil
                        if skillDatasetId == datasetId then
                            effectTable.skillRef = nil
                            auraMutated = true
                        end
                    end
                end

                if auraMutated then
                    mutated = true
                end
            end

            if pruneAchievementReferences(achievements, datasetId, nil) then
                mutated = true
            end

            if pruneGuildSettingReferences(guildSettings, datasetId, nil) then
                mutated = true
            end

            for index = 1, #damageSchools do
                local damageSchool = damageSchools[index]
                local mitigationDatasetId = damageSchool and Dependecies.ParseSourceStatRef(damageSchool.mitigationStatRef) or nil
                if mitigationDatasetId == datasetId then
                    damageSchool.mitigationStatRef = nil
                    mutated = true
                end
            end

            local dependencies = ensureTable(dataset.dependencies)
            for index = #dependencies, 1, -1 do
                if dependencies[index] == datasetId then
                    table.remove(dependencies, index)
                    mutated = true
                end
            end

            if mutated then
                Dependecies.RecomputeDatasetDependencies(currentDatasetId)
                changed = changed + 1
            end
        end
    end

    local profilesRoot = getProfilesRoot()
    local profiles = type(profilesRoot) == "table" and profilesRoot.profiles or nil
    if type(profiles) == "table" then
        for _, profile in pairs(profiles) do
            if type(profile) == "table" and type(profile.skillLevels) == "table" then
                for skillRef in pairs(profile.skillLevels) do
                    local sourceDatasetId = Dependecies.ParseSourceStatRef(skillRef)
                    if sourceDatasetId == datasetId then
                        profile.skillLevels[skillRef] = nil
                    end
                end
            end
            if type(profile) == "table" and type(profile.skillActionBar) == "table" then
                for slotIndex, skillRef in pairs(profile.skillActionBar) do
                    local sourceDatasetId = Dependecies.ParseSourceStatRef(skillRef)
                    if sourceDatasetId == datasetId then
                        profile.skillActionBar[slotIndex] = nil
                    end
                end
            end
            if type(profile) == "table" and type(profile.recipebook) == "table" then
                for index = #profile.recipebook, 1, -1 do
                    local sourceDatasetId = Dependecies.ParseSourceStatRef(profile.recipebook[index])
                    if sourceDatasetId == datasetId then
                        table.remove(profile.recipebook, index)
                    end
                end
            end
            if type(profile) == "table" then
                profile.recipeKnowledge = {}
            end
            if type(profile) == "table" and type(profile.mountedActionBar) == "table" then
                for slotIndex, spellRef in pairs(profile.mountedActionBar) do
                    local sourceDatasetId = Dependecies.ParseSourceStatRef(spellRef)
                    if sourceDatasetId == datasetId then
                        profile.mountedActionBar[slotIndex] = nil
                    end
                end
            end
            if type(profile) == "table" and type(profile.mountEquipment) == "table" then
                for slotKey, entry in pairs(profile.mountEquipment) do
                    local itemRef = type(entry) == "table" and entry.itemRef or nil
                    local slotRef = type(entry) == "table" and entry.slotRef or nil
                    local itemDatasetId = Dependecies.ParseSourceStatRef(itemRef)
                    local slotDatasetId = Dependecies.ParseSourceStatRef(slotRef)
                    if itemDatasetId == datasetId or slotDatasetId == datasetId then
                        profile.mountEquipment[slotKey] = nil
                    end
                end
            end
            if type(profile) == "table" and type(profile.petEquipment) == "table" then
                for petRef, equipmentMap in pairs(profile.petEquipment) do
                    local petDatasetId = Dependecies.ParseSourceStatRef(petRef)
                    if petDatasetId == datasetId then
                        profile.petEquipment[petRef] = nil
                    elseif type(equipmentMap) == "table" then
                        for slotKey, entry in pairs(equipmentMap) do
                            local itemRef = type(entry) == "table" and entry.itemRef or nil
                            local slotRef = type(entry) == "table" and entry.slotRef or nil
                            local itemDatasetId = Dependecies.ParseSourceStatRef(itemRef)
                            local slotDatasetId = Dependecies.ParseSourceStatRef(slotRef)
                            if itemDatasetId == datasetId or slotDatasetId == datasetId then
                                equipmentMap[slotKey] = nil
                            end
                        end
                    end
                end
            end
            if type(profile) == "table" and type(profile.equipment) == "table" then
                for slotKey, entry in pairs(profile.equipment) do
                    local itemRef = type(entry) == "table" and entry.itemRef or nil
                    local slotRef = type(entry) == "table" and entry.slotRef or nil
                    local itemDatasetId = Dependecies.ParseSourceStatRef(itemRef)
                    local slotDatasetId = Dependecies.ParseSourceStatRef(slotRef)
                    if itemDatasetId == datasetId or slotDatasetId == datasetId then
                        profile.equipment[slotKey] = nil
                    end
                end
            end
            if type(profile) == "table" then
                local mountDatasetId = Dependecies.ParseSourceStatRef(profile.mountRef)
                if mountDatasetId == datasetId then
                    profile.mountRef = nil
                    profile.mounted = false
                end

                local petDatasetId = Dependecies.ParseSourceStatRef(profile.petRef)
                if petDatasetId == datasetId then
                    profile.petRef = nil
                end
            end
        end
    end

    return changed
end

function Dependecies.HandleDatasetEntryDeleted(datasetId, collectionKey, entry)
    local deletedEntryId = type(entry) == "table" and tostring(entry.id or "") or ""
    if deletedEntryId == "" then
        return 0
    end

    local deletedRef = Dependecies.ComposeSourceStatRef(datasetId, deletedEntryId)
    if not deletedRef then
        return 0
    end

    local root = getDatasetRoot()
    if type(root) ~= "table" then
        return 0
    end

    local changed = 0

    for currentDatasetId, dataset in pairs(root.datasets or {}) do
        local mutated = false

        if collectionKey == "skills" then
            for index = 1, #(dataset.items or {}) do
                local item = dataset.items[index]
                local keptBonuses = {}
                local itemMutated = false
                for bonusIndex = 1, #(item and item.skillBonuses or {}) do
                    local skillBonus = item.skillBonuses[bonusIndex]
                    if type(skillBonus) == "table" and tostring(skillBonus.skillRef or "") == deletedRef then
                        itemMutated = true
                    else
                        keptBonuses[#keptBonuses + 1] = skillBonus
                    end
                end
                if itemMutated then
                    item.skillBonuses = keptBonuses
                    mutated = true
                end
            end

            for index = 1, #(dataset.traits or {}) do
                local trait = dataset.traits[index]
                local keptBonuses = {}
                local traitMutated = false
                for bonusIndex = 1, #(trait and trait.skillBonuses or {}) do
                    local skillBonus = trait.skillBonuses[bonusIndex]
                    if type(skillBonus) == "table" and tostring(skillBonus.skillRef or "") == deletedRef then
                        traitMutated = true
                    else
                        keptBonuses[#keptBonuses + 1] = skillBonus
                    end
                end
                if traitMutated then
                    trait.skillBonuses = keptBonuses
                    mutated = true
                end
            end

            local function pruneDefinitionSkillBonuses(definitions)
                for index = 1, #(definitions or {}) do
                    local definition = definitions[index]
                    local keptBonuses = {}
                    local definitionMutated = false
                    for bonusIndex = 1, #(definition and definition.skillBonuses or {}) do
                        local skillBonus = definition.skillBonuses[bonusIndex]
                        if type(skillBonus) == "table" and tostring(skillBonus.skillRef or "") == deletedRef then
                            definitionMutated = true
                        else
                            keptBonuses[#keptBonuses + 1] = skillBonus
                        end
                    end
                    if definitionMutated then
                        definition.skillBonuses = keptBonuses
                        mutated = true
                    end
                end
            end

            pruneDefinitionSkillBonuses(dataset.races)
            pruneDefinitionSkillBonuses(dataset.classes)

            for index = 1, #(dataset.auras or {}) do
                local aura = dataset.auras[index]
                for effectIndex = 1, #(aura and aura.effects or {}) do
                    local effect = aura.effects[effectIndex]
                    if type(effect) == "table" and tostring(effect.type or "") == "skill" and tostring(effect.skillRef or "") == deletedRef then
                        effect.skillRef = nil
                        mutated = true
                    end
                end
            end
        elseif collectionKey == "stats" then
            for index = 1, #(dataset.skills or {}) do
                local skill = dataset.skills[index]
                if type(skill) == "table" and tostring(skill.derivedStatRef or "") == deletedRef then
                    skill.derivedStatRef = nil
                    mutated = true
                end
            end

            for index = 1, #(dataset.mounts or {}) do
                local mount = dataset.mounts[index]
                local keptStats = {}
                local mountMutated = false
                for statIndex = 1, #(mount and mount.stats or {}) do
                    local statBonus = mount.stats[statIndex]
                    if type(statBonus) == "table" and tostring(statBonus.statRef or "") == deletedRef then
                        mountMutated = true
                    else
                        keptStats[#keptStats + 1] = statBonus
                    end
                end
                if mountMutated then
                    mount.stats = keptStats
                    mutated = true
                end
            end
        elseif collectionKey == "units" then
            for index = 1, #(dataset.pets or {}) do
                local pet = dataset.pets[index]
                if type(pet) == "table" and tostring(pet.unitRef or "") == deletedRef then
                    pet.unitRef = nil
                    mutated = true
                end
            end
        elseif collectionKey == "itemSlots" then
            for index = 1, #(dataset.items or {}) do
                local item = dataset.items[index]
                local keptSlotRefs = {}
                local itemMutated = false
                for slotIndex = 1, #(item and item.validSlotRefs or {}) do
                    local slotRef = item.validSlotRefs[slotIndex]
                    if tostring(slotRef or "") == deletedRef then
                        itemMutated = true
                    else
                        keptSlotRefs[#keptSlotRefs + 1] = slotRef
                    end
                end
                if itemMutated then
                    item.validSlotRefs = keptSlotRefs
                    mutated = true
                end
            end

            for index = 1, #(dataset.pets or {}) do
                local pet = dataset.pets[index]
                local keptSlotRefs = {}
                local petMutated = false
                for slotIndex = 1, #(pet and pet.equipmentSlotRefs or {}) do
                    local slotRef = pet.equipmentSlotRefs[slotIndex]
                    if tostring(slotRef or "") == deletedRef then
                        petMutated = true
                    else
                        keptSlotRefs[#keptSlotRefs + 1] = slotRef
                    end
                end
                if petMutated then
                    pet.equipmentSlotRefs = keptSlotRefs
                    mutated = true
                end
            end
        elseif collectionKey == "spells" then
            for index = 1, #(dataset.mounts or {}) do
                local mount = dataset.mounts[index]
                local keptSpellRefs = {}
                local mountMutated = false
                for spellIndex = 1, #(mount and mount.spells or {}) do
                    local spellRef = mount.spells[spellIndex]
                    if tostring(spellRef or "") == deletedRef then
                        mountMutated = true
                    else
                        keptSpellRefs[#keptSpellRefs + 1] = spellRef
                    end
                end
                if mountMutated then
                    mount.spells = keptSpellRefs
                    mutated = true
                end
            end

            for index = 1, #(dataset.pets or {}) do
                local pet = dataset.pets[index]
                local keptSpellRefs = {}
                local petMutated = false
                for spellIndex = 1, #(pet and pet.spells or {}) do
                    local spellRef = pet.spells[spellIndex]
                    if tostring(spellRef or "") == deletedRef then
                        petMutated = true
                    else
                        keptSpellRefs[#keptSpellRefs + 1] = spellRef
                    end
                end
                if petMutated then
                    pet.spells = keptSpellRefs
                    mutated = true
                end
            end
        end

        if collectionKey == "units" or collectionKey == "currencies" or collectionKey == "achievements" then
            if pruneAchievementReferences(dataset.achievements, nil, deletedRef, collectionKey) then
                mutated = true
            end
        end

        if collectionKey == "items" or collectionKey == "currencies" or collectionKey == "spells" then
            if pruneGuildSettingReferences(dataset.guildSettings, nil, deletedRef, collectionKey) then
                mutated = true
            end
        end

        if mutated then
            Dependecies.RecomputeDatasetDependencies(currentDatasetId)
            changed = changed + 1
        end
    end

    if collectionKey == "skills" then
        local profilesRoot = getProfilesRoot()
        local profiles = type(profilesRoot) == "table" and profilesRoot.profiles or nil
        if type(profiles) == "table" then
            for _, profile in pairs(profiles) do
                if type(profile) == "table" and type(profile.skillLevels) == "table" then
                    profile.skillLevels[deletedRef] = nil
                end
                if type(profile) == "table" and type(profile.skillActionBar) == "table" then
                    for slotIndex, skillRef in pairs(profile.skillActionBar) do
                        if tostring(skillRef or "") == deletedRef then
                            profile.skillActionBar[slotIndex] = nil
                        end
                    end
                end
                if type(profile) == "table" then
                    profile.recipeKnowledge = {}
                end
            end
        end
    elseif collectionKey == "recipes" or collectionKey == "spells" or collectionKey == "mounts" or collectionKey == "pets" or collectionKey == "itemSlots" then
        local profilesRoot = getProfilesRoot()
        local profiles = type(profilesRoot) == "table" and profilesRoot.profiles or nil
        if type(profiles) == "table" then
            for _, profile in pairs(profiles) do
                if collectionKey == "recipes" and type(profile) == "table" then
                    if type(profile.recipebook) == "table" then
                        for index = #profile.recipebook, 1, -1 do
                            if tostring(profile.recipebook[index] or "") == deletedRef then
                                table.remove(profile.recipebook, index)
                            end
                        end
                    end
                    profile.recipeKnowledge = {}
                elseif collectionKey == "spells" and type(profile) == "table" and type(profile.mountedActionBar) == "table" then
                    for slotIndex, spellRef in pairs(profile.mountedActionBar) do
                        if tostring(spellRef or "") == deletedRef then
                            profile.mountedActionBar[slotIndex] = nil
                        end
                    end
                elseif collectionKey == "mounts" and type(profile) == "table" and tostring(profile.mountRef or "") == deletedRef then
                    profile.mountRef = nil
                    profile.mounted = false
                elseif collectionKey == "pets" and type(profile) == "table" then
                    if tostring(profile.petRef or "") == deletedRef then
                        profile.petRef = nil
                    end
                    if type(profile.petEquipment) == "table" then
                        profile.petEquipment[deletedRef] = nil
                    end
                elseif collectionKey == "itemSlots" and type(profile) == "table" then
                    for _, fieldName in ipairs({ "equipment", "mountEquipment" }) do
                        if type(profile[fieldName]) == "table" then
                            for slotKey, entry in pairs(profile[fieldName]) do
                                local slotRef = type(entry) == "table" and tostring(entry.slotRef or "") or ""
                                if slotRef == deletedRef then
                                    profile[fieldName][slotKey] = nil
                                end
                            end
                        end
                    end
                    if type(profile.petEquipment) == "table" then
                        for _, equipmentMap in pairs(profile.petEquipment) do
                            if type(equipmentMap) == "table" then
                                for slotKey, entry in pairs(equipmentMap) do
                                    local slotRef = type(entry) == "table" and tostring(entry.slotRef or "") or ""
                                    if slotRef == deletedRef then
                                        equipmentMap[slotKey] = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return changed
end
