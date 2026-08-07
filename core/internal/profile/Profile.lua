local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile

local Database = Addon.Internal.Database or {}
local TraitClass = Database.Classes and Database.Classes.Trait or {}
local Equipment = Profile.Equipment or {}
local Resolver = Profile.Resolver or {}

local function getItemClass()
    return Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Item or nil
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function getInventory()
    return Addon.Client and Addon.Client.Inventory or {}
end

local function getDependencies()
    return Database.Dependecies or {}
end

local function getRegistry()
    return Addon.Internal and Addon.Internal.Registry or {}
end

local function findActivatedDatasetById(datasetId)
    local normalizedId = ensureString(datasetId)
    if normalizedId == "" then
        return nil
    end

    local registry = getRegistry()
    local datasets = registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}
    for index = 1, #datasets do
        local dataset = datasets[index]
        if tostring(dataset and dataset.id or "") == normalizedId then
            return dataset
        end
    end

    return type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(normalizedId) or nil
end

local function getRuleset()
    return Addon.Internal and Addon.Internal.Ruleset or {}
end

local function getConditions()
    return Addon.Client and Addon.Client.Conditions or {}
end

local function bumpProfileTooltipContextRevision()
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(builder) == "table" and type(builder.BumpProfileTooltipContextRevision) == "function" then
        builder.BumpProfileTooltipContextRevision()
    end
end

local function trimString(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function getSpellStatusText(spell)
    if not spell then
        return ""
    end

    if (tonumber(spell.castTime) or 0) > 0 then
        return ("Cast %.1fs"):format(tonumber(spell.castTime) or 0)
    end

    return "Instant"
end

local function getSpellSummaryText(spell)
    if not spell then
        return "This spell definition is missing from its dataset."
    end

    if spell.description and spell.description ~= "" then
        return spell.description
    end

    local componentCount = #(spell.components or {})
    local resourceCostCount = #(spell.resourceCosts or {})
    return ("%d component%s, %d cost%s"):format(
        componentCount,
        componentCount == 1 and "" or "s",
        resourceCostCount,
        resourceCostCount == 1 and "" or "s"
    )
end

local function getSpellCooldownText(spell)
    local cooldown = tonumber(spell and spell.cooldown) or 0
    if cooldown <= 0 then
        return "No Cooldown"
    end

    return ("Cooldown %.1fs"):format(cooldown)
end

local function normalizeTraitPayload(payload)
    if type(TraitClass) == "table" and type(TraitClass.NormalizeRuntimePayload) == "function" then
        return TraitClass.NormalizeRuntimePayload(payload)
    end

    return type(payload) == "table" and payload or {}
end

local function formatSummaryCount(count, singular)
    local numericCount = math.max(0, math.floor(tonumber(count) or 0))
    return ("%d %s%s"):format(numericCount, singular, numericCount == 1 and "" or "s")
end

local function getTraitSummaryText(payload, missingText)
    local normalizedPayload = normalizeTraitPayload(payload)
    if type(payload) ~= "table" then
        return missingText or "This trait definition is missing from its dataset."
    end

    local parts = {}
    local statBonusCount = #(normalizedPayload.statBonuses or {})
    local skillBonusCount = #(normalizedPayload.skillBonuses or {})
    local automaticAuraCount = #(normalizedPayload.automaticAuras or {})
    local eventCount = #(normalizedPayload.events or {})

    if statBonusCount > 0 then
        parts[#parts + 1] = formatSummaryCount(statBonusCount, "stat bonus")
    end
    if skillBonusCount > 0 then
        parts[#parts + 1] = formatSummaryCount(skillBonusCount, "skill bonus")
    end
    if automaticAuraCount > 0 then
        parts[#parts + 1] = formatSummaryCount(automaticAuraCount, "aura")
    end
    if eventCount > 0 then
        parts[#parts + 1] = formatSummaryCount(eventCount, "event")
    end

    if #parts == 0 then
        return missingText or "No effects"
    end

    return table.concat(parts, ", ")
end

local function evaluateDetailConditions(ownerType, owner, options)
    local conditions = getConditions()
    if type(conditions) ~= "table" or type(conditions.EvaluateList) ~= "function" or type(owner) ~= "table" then
        return {
            passed = true,
            failureText = "",
        }
    end

    local values = type(options) == "table" and options or {}
    local context = conditions:BuildContext(ownerType, owner, values)
    return conditions:EvaluateList(owner.conditions, context)
end

local function getActionBarSizeFromRuleset()
    local rulesetLogic = getRuleset()
    local ruleset = rulesetLogic.GetActiveRuleset and rulesetLogic.GetActiveRuleset() or nil
    local ruleDefinition = rulesetLogic.GetRulesetRuleDefinition and rulesetLogic.GetRulesetRuleDefinition("interface", "action_bar_size") or nil
    local rawValue = 5
    if rulesetLogic.GetRulesetRuleValue then
        local value = rulesetLogic.GetRulesetRuleValue(ruleset, "interface", ruleDefinition)
        if value ~= nil then
            rawValue = value
        end
    end
    local size = math.floor(tonumber(rawValue) or 5)
    if size < 0 then
        return 0
    end

    return size
end

local function buildKnownSpellRefs()
    local refs = {}
    local seen = {}

    local manualSpellbook = Database.ListProfileSpellbook and Database.ListProfileSpellbook() or {}
    for index = 1, #manualSpellbook do
        local spellRef = ensureString(manualSpellbook[index])
        if spellRef ~= "" and not seen[spellRef] then
            seen[spellRef] = true
            refs[#refs + 1] = spellRef
        end
    end

    local registry = getRegistry()
    local datasets = registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = ensureString(dataset and dataset.id)
        if datasetId ~= "" then
            for spellIndex = 1, #(dataset and dataset.spells or {}) do
                local spell = dataset.spells[spellIndex]
                if spell and spell.id and tostring(spell.learnMode or "trainer") == "always_learned" then
                    local spellRef = ("%s:%s"):format(datasetId, tostring(spell.id))
                    if not seen[spellRef] then
                        seen[spellRef] = true
                        refs[#refs + 1] = spellRef
                    end
                end
            end
        end
    end

    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local mount = selectedMount and selectedMount.mount or nil
    for index = 1, #(mount and mount.spells or {}) do
        local spellRef = ensureString(mount.spells[index])
        if spellRef ~= "" and not seen[spellRef] then
            seen[spellRef] = true
            refs[#refs + 1] = spellRef
        end
    end

    return refs
end

local function isSpellProvidedBySelectedMount(spellRef)
    local normalizedRef = ensureString(spellRef)
    if normalizedRef == "" then
        return false
    end

    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local mount = selectedMount and selectedMount.mount or nil
    for index = 1, #(mount and mount.spells or {}) do
        if ensureString(mount.spells[index]) == normalizedRef then
            return true
        end
    end

    return false
end

local DEFAULT_TALENT_TRAIT_CATEGORY = "General"

local function getRulesetValue(categoryKey, ruleKey, fallback)
    local rulesetLogic = getRuleset()
    local ruleset = rulesetLogic.GetActiveRuleset and rulesetLogic.GetActiveRuleset() or nil
    local ruleDefinition = rulesetLogic.GetRulesetRuleDefinition and rulesetLogic.GetRulesetRuleDefinition(categoryKey, ruleKey) or nil
    local value = nil
    if rulesetLogic.GetRulesetRuleValue then
        value = rulesetLogic.GetRulesetRuleValue(ruleset, categoryKey, ruleDefinition)
    end
    if value == nil then
        return fallback
    end

    return value
end

local function getTraitRuleValue(ruleKey, fallback)
    return getRulesetValue("traits", ruleKey, fallback)
end

local function getMountRuleValue(ruleKey, fallback)
    return getRulesetValue("mounts", ruleKey, fallback)
end

local function getInterfaceRuleValue(ruleKey, fallback)
    return getRulesetValue("interface", ruleKey, fallback)
end

local function refreshVisibleProfileWindow()
    local profileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    if not (profileWindow and profileWindow.Get) then
        return false
    end

    local instance = profileWindow:Get()
    local window = instance and instance.window or nil
    local frame = window and window.GetFrame and window:GetFrame() or nil
    if not (frame and frame.IsShown and frame:IsShown() == true) then
        return false
    end

    if instance and instance.Refresh then
        instance:Refresh()
        return true
    end

    return false
end

local function refreshMountedUi(reason)
    local client = Addon.Client or nil
    if type(client) == "table" and type(client.RefreshActionBarWidget) == "function" then
        client:RefreshActionBarWidget(reason or "profile-mount")
    end

    refreshVisibleProfileWindow()
    return true
end

local function getTraitSourceCategory(trait)
    if type(trait) ~= "table" then
        return "talent"
    end

    if trait.isClass == true then
        return "class"
    end
    if trait.isRacial == true then
        return "race"
    end

    return "talent"
end

local function getTraitCategoryFromDefinition(trait)
    if type(trait) ~= "table" then
        return DEFAULT_TALENT_TRAIT_CATEGORY
    end

    local category = trimString(trait.category)
    if category ~= "" then
        return category
    end

    return DEFAULT_TALENT_TRAIT_CATEGORY
end

local function getTraitDisplayCategory(origin, typeCategory, trait)
    if origin == "class" then
        if typeCategory == "talent" then
            return "class_talents"
        end
        return "class_passives"
    end
    if origin == "race" then
        return "race_passives"
    end

    return getTraitCategoryFromDefinition(trait)
end

local function getTraitUnlockLevel(trait)
    if type(trait) ~= "table" then
        return 1
    end

    return math.max(1, math.floor(tonumber(trait.unlockLevel) or 1))
end

local function appendUniqueRef(target, seen, reference)
    local normalizedRef = ensureString(reference)
    if normalizedRef == "" or seen[normalizedRef] then
        return false
    end

    seen[normalizedRef] = true
    target[#target + 1] = normalizedRef
    return true
end

local function buildManualKnownTraitRefs()
    local refs = {}
    local seen = {}
    local manualTraits = Database.ListProfileTraits and Database.ListProfileTraits() or {}

    for index = 1, #manualTraits do
        appendUniqueRef(refs, seen, manualTraits[index])
    end

    return refs
end

local function buildManualActiveTraitRefs()
    local refs = {}
    local seen = {}
    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil
    local hasPersistedActiveTraits = type(profile) == "table" and profile.activeTraits ~= nil
    local activeTraits = Database.ListProfileActiveTraits and Database.ListProfileActiveTraits() or {}
    if not hasPersistedActiveTraits then
        activeTraits = Database.ListProfileTraits and Database.ListProfileTraits() or {}
    end

    for index = 1, #activeTraits do
        appendUniqueRef(refs, seen, activeTraits[index])
    end

    return refs
end

local function buildInactiveTraitRefs()
    local refs = {}
    local seen = {}
    local inactiveTraits = Database.ListProfileInactiveTraits and Database.ListProfileInactiveTraits() or {}

    for index = 1, #inactiveTraits do
        appendUniqueRef(refs, seen, inactiveTraits[index])
    end

    return refs
end

local function resolveProfileDefinition(reference, collectionKey)
    local normalizedRef = ensureString(reference)
    if normalizedRef == "" then
        return nil, nil
    end

    local dependencies = getDependencies()
    local datasetId, entryId = nil, nil
    if type(dependencies.ParseSourceStatRef) == "function" then
        datasetId, entryId = dependencies.ParseSourceStatRef(normalizedRef)
    else
        datasetId, entryId = normalizedRef:match("^([^:]+):(.+)$")
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
        if entry and tostring(entry.id or "") == tostring(entryId) then
            return dataset, entry
        end
    end

    return dataset, nil
end

local function buildSelectedOriginTraitRefs(kind)
    local refs = {}
    local seen = {}

    if kind == "race" then
        if getTraitRuleValue("allow_race_traits", true) == false then
            return refs
        end
        local profileRaceRef = Database.GetProfileRaceRef and Database.GetProfileRaceRef() or nil
        local _, race = resolveProfileDefinition(profileRaceRef, "races")
        local raceTraitRefs = type(race) == "table" and race.traitRefs or nil
        for index = 1, #(raceTraitRefs or {}) do
            appendUniqueRef(refs, seen, raceTraitRefs[index])
        end
        return refs
    end

    if getTraitRuleValue("allow_class_traits", true) == false then
        return refs
    end
    local profileClassRef = Database.GetProfileClassRef and Database.GetProfileClassRef() or nil
    local _, class = resolveProfileDefinition(profileClassRef, "classes")
    local classTraitRefs = type(class) == "table" and class.traitRefs or nil
    for index = 1, #(classTraitRefs or {}) do
        appendUniqueRef(refs, seen, classTraitRefs[index])
    end

    return refs
end

local function buildAutoGrantedTraitRefs(kind)
    local refs = {}
    local seen = {}
    local selectedRefs = buildSelectedOriginTraitRefs(kind)

    if kind == "race" and getTraitRuleValue("auto_enable_race_traits", true) == false then
        return refs
    end
    if kind == "class" and getTraitRuleValue("auto_enable_class_traits", true) == false then
        return refs
    end

    for index = 1, #selectedRefs do
        appendUniqueRef(refs, seen, selectedRefs[index])
    end

    return refs
end

local function getKnownTraitOrigin(traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return nil
    end

    local raceRefs = buildSelectedOriginTraitRefs("race")
    for index = 1, #raceRefs do
        if raceRefs[index] == normalizedRef then
            return "race"
        end
    end

    local classRefs = buildSelectedOriginTraitRefs("class")
    for index = 1, #classRefs do
        if classRefs[index] == normalizedRef then
            return "class"
        end
    end

    local manualRefs = buildManualKnownTraitRefs()
    for index = 1, #manualRefs do
        if manualRefs[index] == normalizedRef then
            return "manual"
        end
    end

    return nil
end

local function buildEffectiveKnownTraitRefs()
    local refs = {}
    local seen = {}
    local manualRefs = buildManualKnownTraitRefs()
    local raceRefs = buildSelectedOriginTraitRefs("race")
    local classRefs = buildSelectedOriginTraitRefs("class")

    for index = 1, #manualRefs do
        appendUniqueRef(refs, seen, manualRefs[index])
    end
    for index = 1, #raceRefs do
        appendUniqueRef(refs, seen, raceRefs[index])
    end
    for index = 1, #classRefs do
        appendUniqueRef(refs, seen, classRefs[index])
    end

    return refs
end

local function pruneSelectedOriginTraitRef(kind, traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return false
    end

    local profileDefinitionRef = nil
    local collectionKey = nil
    if kind == "race" then
        profileDefinitionRef = Database.GetProfileRaceRef and Database.GetProfileRaceRef() or nil
        collectionKey = "races"
    elseif kind == "class" then
        profileDefinitionRef = Database.GetProfileClassRef and Database.GetProfileClassRef() or nil
        collectionKey = "classes"
    else
        return false
    end

    local dataset, definition = resolveProfileDefinition(profileDefinitionRef, collectionKey)
    if type(definition) ~= "table" then
        return false
    end

    local keptTraitRefs = {}
    local removed = false
    for index = 1, #(definition.traitRefs or {}) do
        local currentRef = ensureString(definition.traitRefs[index])
        if currentRef == normalizedRef then
            removed = true
        elseif currentRef ~= "" then
            keptTraitRefs[#keptTraitRefs + 1] = currentRef
        end
    end

    if not removed then
        return false
    end

    definition.traitRefs = keptTraitRefs
    if Database.RemoveProfileActiveTrait then
        Database.RemoveProfileActiveTrait(normalizedRef)
    end
    if Database.RemoveProfileInactiveTrait then
        Database.RemoveProfileInactiveTrait(normalizedRef)
    end
    if Database.NotifyDatasetEntryChanged and dataset and dataset.id then
        Database.NotifyDatasetEntryChanged(dataset.id, collectionKey)
    end

    return true
end

local function buildEffectiveActiveTraitRefs()
    local refs = {}
    local seen = {}
    local manualRefs = buildManualActiveTraitRefs()
    local inactiveRefs = buildInactiveTraitRefs()
    local raceRefs = buildAutoGrantedTraitRefs("race")
    local classRefs = buildAutoGrantedTraitRefs("class")
    local inactiveLookup = {}

    for index = 1, #inactiveRefs do
        inactiveLookup[inactiveRefs[index]] = true
    end

    for index = 1, #manualRefs do
        appendUniqueRef(refs, seen, manualRefs[index])
    end
    for index = 1, #raceRefs do
        appendUniqueRef(refs, seen, raceRefs[index])
    end
    for index = 1, #classRefs do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(classRefs[index]) or nil
        if detail and detail.origin == "class" and detail.typeCategory == "talent" then
            if inactiveLookup[classRefs[index]] ~= true then
                appendUniqueRef(refs, seen, classRefs[index])
            end
        else
            appendUniqueRef(refs, seen, classRefs[index])
        end
    end

    return refs
end

local function getProfileLevel()
    return math.max(1, math.floor(tonumber(Database.GetProfileLevel and Database.GetProfileLevel() or 1) or 1))
end

local function isTraitDetailVisibleToProfile(detail)
    if type(detail) ~= "table" then
        return false
    end

    if detail.isMissing == true then
        return true
    end

    if detail.typeCategory == "race" and detail.origin ~= "race" then
        return false
    end
    if detail.typeCategory == "class" and detail.origin ~= "class" then
        return false
    end

    return (tonumber(detail.unlockLevel) or 1) <= getProfileLevel()
end

local function buildTraitCountSummary()
    local manualRefs = buildManualKnownTraitRefs()
    local effectiveKnownRefs = {}
    local raceRefs = {}
    local classRefs = {}
    local countedTotalRefs = {}
    local countedSeen = {}
    local manualCount = 0
    local manualTalentCount = 0

    for index = 1, #manualRefs do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(manualRefs[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            manualCount = manualCount + 1
            if detail.typeCategory == "talent" then
                manualTalentCount = manualTalentCount + 1
            end
            appendUniqueRef(countedTotalRefs, countedSeen, detail.traitRef)
        end
    end

    local effectiveKnownCandidates = buildEffectiveKnownTraitRefs()
    for index = 1, #effectiveKnownCandidates do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(effectiveKnownCandidates[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            effectiveKnownRefs[#effectiveKnownRefs + 1] = effectiveKnownCandidates[index]
        end
    end

    local raceCandidates = buildAutoGrantedTraitRefs("race")
    for index = 1, #raceCandidates do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(raceCandidates[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            raceRefs[#raceRefs + 1] = raceCandidates[index]
        end
    end

    local classCandidates = buildAutoGrantedTraitRefs("class")
    for index = 1, #classCandidates do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(classCandidates[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            classRefs[#classRefs + 1] = classCandidates[index]
        end
    end

    local level = getProfileLevel()
    local baseTalentTraits = math.max(0, math.floor(tonumber(getTraitRuleValue("base_talent_traits", 0)) or 0))
    local talentTraitsPerLevel = math.max(0, tonumber(getTraitRuleValue("talent_traits_per_level", 0)) or 0)
    local maxTotalTraits = math.max(0, math.floor(tonumber(getTraitRuleValue("max_total_traits", 0)) or 0))
    local maxTalentTraits = math.max(0, math.floor(baseTalentTraits + ((level - 1) * talentTraitsPerLevel)))
    local countRaceTowardTotal = getTraitRuleValue("count_race_traits_toward_total", false) == true
    local countClassTowardTotal = getTraitRuleValue("count_class_traits_toward_total", false) == true
    if countRaceTowardTotal then
        for index = 1, #raceRefs do
            appendUniqueRef(countedTotalRefs, countedSeen, raceRefs[index])
        end
    end
    if countClassTowardTotal then
        for index = 1, #classRefs do
            appendUniqueRef(countedTotalRefs, countedSeen, classRefs[index])
        end
    end

    return {
        level = level,
        manualCount = manualCount,
        manualTalentCount = manualTalentCount,
        maxTotalTraits = maxTotalTraits,
        maxTalentTraits = maxTalentTraits,
        effectiveTotalCount = #countedTotalRefs,
        effectiveKnownCount = #effectiveKnownRefs,
        autoRaceCount = #raceRefs,
        autoClassCount = #classRefs,
        countRaceTowardTotal = countRaceTowardTotal,
        countClassTowardTotal = countClassTowardTotal,
    }
end

local PROFILE_STAT_CATEGORY_ORDER = {
    "Primary",
    "Secondary",
    "Melee",
    "Ranged",
    "Spell",
    "Defense",
    "Resistances",
    "Utility",
    "Mounted",
    "Special",
}

local function buildProfileStatCategoryOrderLookup()
    local lookup = {}
    for index = 1, #PROFILE_STAT_CATEGORY_ORDER do
        lookup[PROFILE_STAT_CATEGORY_ORDER[index]] = index
    end
    return lookup
end

local PROFILE_STAT_CATEGORY_ORDER_LOOKUP = buildProfileStatCategoryOrderLookup()

local function appendSortedSlotEntries(entries, bucket)
    table.sort(bucket, function(left, right)
        local leftPriority = tonumber(left.priority) or 0
        local rightPriority = tonumber(right.priority) or 0
        if leftPriority == rightPriority then
            local leftName = string.lower(tostring(left.name or left.slotKey or ""))
            local rightName = string.lower(tostring(right.name or right.slotKey or ""))
            if leftName == rightName then
                return tostring(left.slotKey or "") < tostring(right.slotKey or "")
            end
            return leftName < rightName
        end
        return leftPriority < rightPriority
    end)

    local values = {}
    for index = 1, #bucket do
        values[#values + 1] = bucket[index].slotKey
        entries[#entries + 1] = bucket[index]
    end

    return values
end

local function buildSlotLayoutFromRefs(slotRefs)
    local groups = {
        left = {},
        right = {},
        bottom = {},
    }
    local ordered = {}
    local seen = {}

    for index = 1, #(slotRefs or {}) do
        local slotRef = ensureString(slotRefs[index])
        local itemSlot, dataset = nil, nil
        if Equipment.ResolveSlotDefinition then
            itemSlot, dataset = Equipment.ResolveSlotDefinition(slotRef)
        end
        if itemSlot and dataset then
            local slotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(itemSlot.name ~= "" and itemSlot.name or itemSlot.id) or tostring(itemSlot.id)
            if slotKey ~= "" and not seen[slotKey] then
                local panelSide = tostring(itemSlot.panelSide or "left")
                if panelSide ~= "right" and panelSide ~= "bottom" then
                    panelSide = "left"
                end

                seen[slotKey] = true
                groups[panelSide][#groups[panelSide] + 1] = {
                    slotKey = slotKey,
                    slotRef = slotRef,
                    slotId = itemSlot.id,
                    datasetId = dataset.id,
                    name = itemSlot.name,
                    priority = tonumber(itemSlot.priority) or 0,
                }
            end
        end
    end

    for _, key in ipairs({ "left", "right", "bottom" }) do
        groups[key] = appendSortedSlotEntries(ordered, groups[key])
    end

    return {
        left = groups.left,
        right = groups.right,
        bottom = groups.bottom,
        ordered = (function()
            local values = {}
            for index = 1, #ordered do
                values[#values + 1] = ordered[index].slotKey
            end
            return values
        end)(),
        entries = ordered,
    }
end

local function buildSlotLayoutForScope(scope)
    local normalizedScope = Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(scope) or tostring(scope or "character")
    local groups = {
        left = {},
        right = {},
        bottom = {},
    }
    local ordered = {}
    local seen = {}
    local registry = getRegistry()
    local datasets = registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local itemSlots = dataset and dataset.itemSlots or {}
        for slotIndex = 1, #itemSlots do
            local itemSlot = itemSlots[slotIndex]
            if itemSlot and itemSlot.id and (Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(itemSlot.slotType) or "character") == normalizedScope then
                local slotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(itemSlot.name ~= "" and itemSlot.name or itemSlot.id) or tostring(itemSlot.id)
                local dependencies = getDependencies()
                local slotRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, itemSlot.id) or nil
                if slotKey ~= "" and not seen[slotKey] then
                    local panelSide = tostring(itemSlot.panelSide or "left")
                    if panelSide ~= "right" and panelSide ~= "bottom" then
                        panelSide = "left"
                    end

                    seen[slotKey] = true
                    groups[panelSide][#groups[panelSide] + 1] = {
                        slotKey = slotKey,
                        slotRef = slotRef,
                        slotId = itemSlot.id,
                        datasetId = dataset.id,
                        name = itemSlot.name,
                        priority = tonumber(itemSlot.priority) or 0,
                    }
                end
            end
        end
    end

    for _, key in ipairs({ "left", "right", "bottom" }) do
        groups[key] = appendSortedSlotEntries(ordered, groups[key])
    end

    return {
        left = groups.left,
        right = groups.right,
        bottom = groups.bottom,
        ordered = (function()
            local values = {}
            for index = 1, #ordered do
                values[#values + 1] = ordered[index].slotKey
            end
            return values
        end)(),
        entries = ordered,
    }
end

function Profile.GetActiveProfile()
    if Database.GetActiveProfile then
        return Database.GetActiveProfile()
    end

    return nil
end

function Profile.GetEquipmentLayoutByScope(scope)
    local normalizedScope = Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(scope) or tostring(scope or "character")
    if normalizedScope == "pet" then
        return Profile.GetPetLayout and Profile.GetPetLayout() or buildSlotLayoutFromRefs({})
    end

    return buildSlotLayoutForScope(scope)
end

function Profile.GetEquipmentLayout()
    return Profile.GetEquipmentLayoutByScope("character")
end

function Profile.ListMounts()
    local rows = {}
    local registry = getRegistry()
    local dependencies = getDependencies()
    local datasets = registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        for mountIndex = 1, #(dataset and dataset.mounts or {}) do
            local mount = dataset.mounts[mountIndex]
            if mount and mount.id then
                local mountRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, mount.id) or nil
                if mountRef then
                    rows[#rows + 1] = {
                        ref = mountRef,
                        dataset = dataset,
                        datasetId = dataset.id,
                        mount = mount,
                        name = trimString(mount.name) ~= "" and trimString(mount.name) or tostring(mount.id),
                        icon = ensureString(mount.icon),
                        description = ensureString(mount.description),
                    }
                end
            end
        end
    end

    table.sort(rows, function(left, right)
        local leftName = string.lower(ensureString(left and left.name))
        local rightName = string.lower(ensureString(right and right.name))
        if leftName == rightName then
            return ensureString(left and left.ref) < ensureString(right and right.ref)
        end
        return leftName < rightName
    end)

    return rows
end

function Profile.ListPets()
    local rows = {}
    local registry = getRegistry()
    local dependencies = getDependencies()
    local datasets = registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        for petIndex = 1, #(dataset and dataset.pets or {}) do
            local pet = dataset.pets[petIndex]
            if pet and pet.id then
                local petRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, pet.id) or nil
                if petRef then
                    local unitDataset, unit = resolveProfileDefinition(pet.unitRef, "units")
                    local unitName = trimString(unit and unit.name)
                    local petName = trimString(pet.name)
                    rows[#rows + 1] = {
                        ref = petRef,
                        dataset = dataset,
                        datasetId = dataset.id,
                        pet = pet,
                        unit = unit,
                        unitDataset = unitDataset,
                        name = petName ~= "" and petName or (unitName ~= "" and unitName or tostring(pet.id)),
                        description = ensureString(unit and unit.description),
                        unitRef = ensureString(pet.unitRef),
                    }
                end
            end
        end
    end

    table.sort(rows, function(left, right)
        local leftName = string.lower(ensureString(left and left.name))
        local rightName = string.lower(ensureString(right and right.name))
        if leftName == rightName then
            return ensureString(left and left.ref) < ensureString(right and right.ref)
        end
        return leftName < rightName
    end)

    return rows
end

function Profile.GetSelectedMount()
    local mountRef = Database.GetProfileMountRef and Database.GetProfileMountRef() or nil
    local normalizedRef = ensureString(mountRef)
    if normalizedRef == "" then
        return nil
    end

    local dataset, mount = resolveProfileDefinition(normalizedRef, "mounts")
    if not mount then
        return nil
    end

    return {
        ref = normalizedRef,
        dataset = dataset,
        datasetId = dataset and dataset.id or nil,
        mount = mount,
        name = trimString(mount.name) ~= "" and trimString(mount.name) or tostring(mount.id or normalizedRef),
        description = ensureString(mount.description),
        icon = ensureString(mount.icon),
        isActive = dataset and Database.IsDatasetActivated and Database.IsDatasetActivated(dataset.id) or false,
    }
end

function Profile.GetSelectedPet()
    local petRef = Database.GetProfilePetRef and Database.GetProfilePetRef() or nil
    local normalizedRef = ensureString(petRef)
    if normalizedRef == "" then
        return nil
    end

    local dataset, pet = resolveProfileDefinition(normalizedRef, "pets")
    if not pet then
        return nil
    end

    local unitDataset, unit = resolveProfileDefinition(pet.unitRef, "units")
    local petName = trimString(pet.name)
    local unitName = trimString(unit and unit.name)
    return {
        ref = normalizedRef,
        dataset = dataset,
        datasetId = dataset and dataset.id or nil,
        pet = pet,
        unit = unit,
        unitDataset = unitDataset,
        unitRef = ensureString(pet.unitRef),
        name = petName ~= "" and petName or (unitName ~= "" and unitName or tostring(pet.id or normalizedRef)),
        description = ensureString(unit and unit.description),
        isActive = dataset and Database.IsDatasetActivated and Database.IsDatasetActivated(dataset.id) or false,
        hasUnit = unit ~= nil,
    }
end

function Profile.GetMountLayout()
    return Profile.GetEquipmentLayoutByScope("mount")
end

function Profile.GetPetLayout()
    local selectedPet = Profile.GetSelectedPet and Profile.GetSelectedPet() or nil
    local pet = selectedPet and selectedPet.pet or nil
    return buildSlotLayoutFromRefs(pet and pet.equipmentSlotRefs or {})
end

function Profile.GetMountRef()
    return Database.GetProfileMountRef and Database.GetProfileMountRef() or nil
end

function Profile.GetPetRef()
    return Database.GetProfilePetRef and Database.GetProfilePetRef() or nil
end

function Profile.SetMountRef(mountRef)
    local result = Database.SetProfileMountRef and Database.SetProfileMountRef(mountRef) or nil
    refreshMountedUi("profile-mount-ref")
    return result
end

function Profile.SetPetRef(petRef)
    local result = Database.SetProfilePetRef and Database.SetProfilePetRef(petRef) or nil
    refreshVisibleProfileWindow()
    return result
end

function Profile.IsPetSelectionValid()
    local selectedPet = Profile.GetSelectedPet()
    return type(selectedPet) == "table" and selectedPet.isActive == true and selectedPet.hasUnit == true
end

function Profile.GetSelectedPetSpellRefs()
    local selectedPet = Profile.GetSelectedPet and Profile.GetSelectedPet() or nil
    local pet = selectedPet and selectedPet.pet or nil
    local spellRefs = {}

    for index = 1, #(pet and pet.spells or {}) do
        local spellRef = ensureString(pet.spells[index])
        if spellRef ~= "" then
            spellRefs[#spellRefs + 1] = spellRef
        end
    end

    return spellRefs
end

function Profile.BuildSelectedPetRuntimeStats()
    local selectedPet = Profile.GetSelectedPet and Profile.GetSelectedPet() or nil
    if type(selectedPet) ~= "table" or selectedPet.isActive ~= true or selectedPet.hasUnit ~= true then
        return {}
    end

    local resolver = Profile.Resolver or nil
    if type(resolver) ~= "table" or type(resolver.BuildUnitRuntimeStatRows) ~= "function" then
        return {}
    end

    local unit = selectedPet.unit or nil
    local equipped = Profile.ListEquippedSlotsByScope and Profile.ListEquippedSlotsByScope("pet") or {}
    return resolver.BuildUnitRuntimeStatRows(unit and unit.stats or {}, equipped)
end

function Profile.IsMounted()
    return Database.GetProfileMounted and Database.GetProfileMounted() == true or false
end

function Profile.SetMounted(mounted)
    local desiredMounted = mounted == true
    local result = false
    if Database.SetProfileMounted then
        Database.SetProfileMounted(desiredMounted)
        local currentMounted = Database.GetProfileMounted and Database.GetProfileMounted() == true or false
        result = currentMounted == desiredMounted
    end
    refreshMountedUi("profile-mounted")
    return result
end

function Profile.IsMountSelectionValid()
    local selectedMount = Profile.GetSelectedMount()
    return type(selectedMount) == "table" and selectedMount.isActive == true
end

function Profile.CanMount()
    local selectedMount = Profile.GetSelectedMount()
    if not selectedMount or selectedMount.isActive ~= true then
        return false, "no-mount"
    end

    local client = Addon.Client or nil
    local eventState = type(client) == "table" and type(client.GetEventState) == "function" and client:GetEventState() or nil
    local localEventUnit = type(client) == "table" and type(client.ResolveLocalEventUnit) == "function" and client:ResolveLocalEventUnit(eventState) or nil
    if eventState and eventState.active == true and localEventUnit and getMountRuleValue("allow_mount_in_combat", false) ~= true then
        return false, "combat-blocked"
    end

    return true
end

function Profile.ToggleMounted()
    if Profile.IsMounted() then
        local changed = Profile.SetMounted(false)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed, "dismounted"
    end

    local allowed, reason = Profile.CanMount()
    if not allowed then
        return false, reason or "blocked"
    end

    local changed = Profile.SetMounted(true)
    if changed then
        bumpProfileTooltipContextRevision()
    end
    return changed, "mounted"
end

function Profile.ListEquippedSlots()
    return Equipment.ListEquippedSlots and Equipment.ListEquippedSlots() or {}
end

function Profile.ListEquippedSlotsByScope(scope)
    return Equipment.ListEquippedSlotsByScope and Equipment.ListEquippedSlotsByScope(scope) or {}
end

function Profile.GetEquippedItemByScope(scope, slotKey)
    local entry = Equipment.GetEquippedEntryByScope and Equipment.GetEquippedEntryByScope(scope, slotKey) or nil
    if not entry then
        return nil
    end

    local item, dataset = nil, nil
    local slotDefinition, slotDataset = nil, nil
    if Equipment.ResolveItemDefinition then
        item, dataset = Equipment.ResolveItemDefinition(entry.itemRef)
    end
    if Equipment.ResolveSlotDefinition then
        slotDefinition, slotDataset = Equipment.ResolveSlotDefinition(entry.slotRef)
    end

    return {
        slotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(slotKey) or slotKey,
        datasetId = entry.datasetId,
        itemId = entry.itemId,
        itemRef = entry.itemRef,
        slotRef = entry.slotRef,
        modifications = entry.modifications,
        soulbound = entry.soulbound == true,
        item = item,
        dataset = dataset,
        slotDefinition = slotDefinition,
        slotDataset = slotDataset,
        isMissing = item == nil,
        isActive = dataset and Database.IsDatasetActivated and Database.IsDatasetActivated(dataset.id) or false,
    }
end

function Profile.GetEquippedItem(slotKey)
    return Profile.GetEquippedItemByScope("character", slotKey)
end

function Profile.EquipItem(slotKey, itemRef, modifications, slotRef, soulbound)
    return Equipment.EquipItem and Equipment.EquipItem(slotKey, itemRef, modifications, slotRef, soulbound) or nil
end

local function getActiveEquipmentScope()
    local profileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    local activeProfileWindow = profileWindow and profileWindow.Get and profileWindow:Get() or nil
    local equipmentPage = activeProfileWindow and activeProfileWindow.equipmentStatsPage or nil
    if equipmentPage and equipmentPage.GetActiveEquipmentScope then
        return equipmentPage:GetActiveEquipmentScope()
    end

    return "character"
end

local function isVisibleEquipmentTabActive(profileWindow)
    if not profileWindow or not profileWindow.IsVisible or profileWindow:IsVisible() ~= true then
        return false
    end

    local activeTabKey = profileWindow.GetActiveTabKey and profileWindow:GetActiveTabKey() or ""
    return activeTabKey == "equipment"
end

local function getPreferredInventoryEquipScope(options, activeProfileWindow)
    local normalizedOptions = type(options) == "table" and options or nil
    local optionScope = normalizedOptions and ensureString(normalizedOptions.scope) or ""
    local optionTabKey = normalizedOptions and ensureString(normalizedOptions.activeTabKey) or ""
    if optionScope ~= "" and optionTabKey == "equipment" then
        return Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(optionScope) or optionScope
    end

    if isVisibleEquipmentTabActive(activeProfileWindow) then
        return getActiveEquipmentScope()
    end

    return nil
end

local function appendInventoryEquipScopeCandidate(candidates, seen, scope)
    local normalizedScope = Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(scope) or tostring(scope or "character")
    if normalizedScope == "" or seen[normalizedScope] then
        return
    end

    seen[normalizedScope] = true
    candidates[#candidates + 1] = normalizedScope
end

local function buildInventoryEquipScopeCandidates(item, preferredScope)
    local candidates = {}
    local seen = {}
    appendInventoryEquipScopeCandidate(candidates, seen, preferredScope)

    local slotRefs = item and item.validSlotRefs or nil
    for index = 1, #(slotRefs or {}) do
        local slotDefinition = Equipment.ResolveSlotDefinition and Equipment.ResolveSlotDefinition(slotRefs[index]) or nil
        local scope = slotDefinition and slotDefinition.slotType or nil
        appendInventoryEquipScopeCandidate(candidates, seen, scope)
    end

    if #candidates == 0 then
        appendInventoryEquipScopeCandidate(candidates, seen, "character")
    end

    return candidates
end

local function resolveInventoryEquipTarget(item, scope, preferredSlotKey)
    local activeLayout = Profile.GetEquipmentLayoutByScope and Profile.GetEquipmentLayoutByScope(scope) or Profile.GetEquipmentLayout()
    if preferredSlotKey and Equipment.DoesItemFitLayoutEntry then
        for layoutIndex = 1, #(activeLayout and activeLayout.entries or {}) do
            local layoutEntry = activeLayout.entries[layoutIndex]
            if layoutEntry and layoutEntry.slotKey == preferredSlotKey then
                local fits, resolvedSlotRef = Equipment.DoesItemFitLayoutEntry(item, layoutEntry)
                if fits and resolvedSlotRef then
                    return preferredSlotKey, resolvedSlotRef
                end
                break
            end
        end
    end

    if Equipment.FindBestSlotForItemInScope then
        return Equipment.FindBestSlotForItemInScope(item, activeLayout, scope)
    end

    return nil, nil
end

function Profile.EquipInventoryItem(slotIndex, record, options)
    local Inventory = getInventory()
    local profileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    local inventoryRecord = record or (Inventory.GetItem and Inventory.GetItem(slotIndex)) or nil
    local equipOptions = type(options) == "table" and options or nil
    if type(inventoryRecord) ~= "table" then
        return nil, "missing-item"
    end

    local itemRef = inventoryRecord.dataset and inventoryRecord.id and ("%s:%s"):format(tostring(inventoryRecord.dataset), tostring(inventoryRecord.id)) or nil
    if not itemRef then
        return nil, "invalid"
    end

    local item = Equipment.ResolveItemDefinition and Equipment.ResolveItemDefinition(itemRef) or nil
    if not item then
        return nil, "missing-item"
    end

    local activeProfileWindow = profileWindow and profileWindow.Get and profileWindow:Get() or nil
    local preferredScope = getPreferredInventoryEquipScope(equipOptions, activeProfileWindow)
    local preferredSlotKey = equipOptions and equipOptions.slotKey or nil
    if not preferredSlotKey and isVisibleEquipmentTabActive(activeProfileWindow) then
        preferredSlotKey = activeProfileWindow.SelectedSlotKey
    end

    local equipmentScope = nil
    local slotKey, slotRef = nil, nil
    local scopeCandidates = buildInventoryEquipScopeCandidates(item, preferredScope)
    for index = 1, #scopeCandidates do
        local candidateScope = scopeCandidates[index]
        slotKey, slotRef = resolveInventoryEquipTarget(item, candidateScope, preferredSlotKey)
        if slotKey and slotRef then
            equipmentScope = candidateScope
            break
        end
    end

    if not equipmentScope or not slotKey or not slotRef then
        return nil, "invalid-slot"
    end

    local previousEntry = Equipment.GetEquippedEntryByScope and Equipment.GetEquippedEntryByScope(equipmentScope, slotKey) or nil
    if previousEntry and Inventory.AddItem then
        Inventory.AddItem({
            dataset = previousEntry.datasetId,
            id = previousEntry.itemId,
            modifications = previousEntry.modifications,
            soulbound = previousEntry.soulbound == true,
        })
    end

    local itemClass = getItemClass()
    local equippedSoulbound = inventoryRecord.soulbound == true
        or (itemClass and itemClass.IsBindOnEquip and itemClass.IsBindOnEquip(item) or false)
    local equipped = Equipment.EquipItemInScope and Equipment.EquipItemInScope(equipmentScope, slotKey, itemRef, inventoryRecord.modifications, slotRef, equippedSoulbound) or nil
    if not equipped then
        return nil, "equip-failed"
    end

    if Inventory.RemoveItem then
        Inventory.RemoveItem(slotIndex)
    end

    return equipped, slotKey
end

function Profile.UnequipItem(slotKey)
    return Equipment.UnequipItem and Equipment.UnequipItem(slotKey) or false
end

function Profile.UnequipSlotToInventoryByScope(scope, slotKey)
    local Inventory = getInventory()
    local equippedEntry = Equipment.GetEquippedEntryByScope and Equipment.GetEquippedEntryByScope(scope, slotKey) or nil
    if not equippedEntry then
        return false
    end

    if Inventory.AddItem then
        Inventory.AddItem({
            dataset = equippedEntry.datasetId,
            id = equippedEntry.itemId,
            modifications = equippedEntry.modifications,
            soulbound = equippedEntry.soulbound == true,
        })
    end

    return Equipment.UnequipItemInScope and Equipment.UnequipItemInScope(scope, slotKey) or false
end

function Profile.UnequipSlotToInventory(slotKey)
    return Profile.UnequipSlotToInventoryByScope("character", slotKey)
end

function Profile.ListResolvedStats(options)
    return Resolver.ListResolvedStats and Resolver.ListResolvedStats(options) or {}
end

function Profile.GetResolvedStatRow(statRef, options)
    local normalizedRef = ensureString(statRef)
    if normalizedRef == "" then
        return nil
    end

    if Resolver.GetResolvedStatRowsByRefs then
        local rows = Resolver.GetResolvedStatRowsByRefs({ normalizedRef }, options)
        return rows[1]
    end

    local rows = Profile.ListResolvedStats(options)
    for index = 1, #rows do
        local row = rows[index]
        if type(row) == "table" and row.ref == normalizedRef then
            return row
        end
    end

    return nil
end

function Profile.GetResolvedStatValue(statRef, fallback, options)
    local row = Profile.GetResolvedStatRow(statRef, options)
    local value = row and tonumber(row.value) or nil
    if value ~= nil then
        return value, true, row
    end

    if fallback ~= nil then
        return fallback, false, nil
    end

    return nil, false, nil
end

function Profile.ListResolvedResources(options)
    return Resolver.ListResolvedResources and Resolver.ListResolvedResources(options) or {}
end

function Profile.GetResolvedResourceRow(resourceRef, options)
    local normalizedRef = ensureString(resourceRef)
    if normalizedRef == "" then
        return nil
    end

    if Resolver.GetResolvedResourceRowsByRefs then
        local rows = Resolver.GetResolvedResourceRowsByRefs({ normalizedRef }, options)
        return rows[1]
    end

    local resources = Profile.ListResolvedResources(options)
    for index = 1, #resources do
        local resourceRow = resources[index]
        if resourceRow and resourceRow.ref == normalizedRef then
            return resourceRow
        end
    end

    return nil
end

function Profile.GetResolvedStatRowsByRefs(statRefs, options)
    if Resolver.GetResolvedStatRowsByRefs then
        return Resolver.GetResolvedStatRowsByRefs(statRefs, options)
    end

    local rows = {}
    for index = 1, #(statRefs or {}) do
        local row = Profile.GetResolvedStatRow(statRefs[index], options)
        if row then
            rows[#rows + 1] = row
        end
    end
    return rows
end

function Profile.GetResolvedResourceRowsByRefs(resourceRefs, options)
    if Resolver.GetResolvedResourceRowsByRefs then
        return Resolver.GetResolvedResourceRowsByRefs(resourceRefs, options)
    end

    local rows = {}
    for index = 1, #(resourceRefs or {}) do
        local row = Profile.GetResolvedResourceRow(resourceRefs[index], options)
        if row then
            rows[#rows + 1] = row
        end
    end
    return rows
end

function Profile.ListResolvedSkills(options)
    return Resolver.ListResolvedSkills and Resolver.ListResolvedSkills(options) or {}
end

function Profile.GetResolvedSkillRow(skillRef, options)
    local normalizedRef = ensureString(skillRef)
    if normalizedRef == "" then
        return nil
    end

    local rows = Profile.ListResolvedSkills(options)
    for index = 1, #rows do
        local row = rows[index]
        if row and row.ref == normalizedRef then
            return row
        end
    end

    return nil
end

function Profile.ListKnownSpells()
    local spellbook = buildKnownSpellRefs()
    local rows = {}

    for index = 1, #spellbook do
        local detail = Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellbook[index]) or nil
        if detail then
            rows[#rows + 1] = {
                rowIndex = index,
                spellRef = detail.spellRef,
                name = detail.name,
                statusText = detail.statusText,
                detailText = detail.summaryText,
                isMissing = detail.isMissing,
                dataset = detail.dataset,
                spell = detail.spell,
                spellbookCategory = detail.spellbookCategory,
            }
        end
    end

    return rows
end

function Profile.GetTraitCategory(trait)
    return getTraitCategoryFromDefinition(trait)
end

function Profile.GetTraitCountSummary()
    return buildTraitCountSummary()
end

function Profile.ListKnownTraits()
    local traitbook = buildEffectiveKnownTraitRefs()
    local activeTraitRefs = buildEffectiveActiveTraitRefs()
    local activeRefs = {}
    local rows = {}

    for index = 1, #activeTraitRefs do
        activeRefs[activeTraitRefs[index]] = true
    end

    for index = 1, #traitbook do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(traitbook[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            detail.isActive = activeRefs[detail.traitRef] == true
            rows[#rows + 1] = detail
        end
    end

    return rows
end

function Profile.ListActiveTraits()
    local traitbook = buildEffectiveActiveTraitRefs()
    local rows = {}

    for index = 1, #traitbook do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(traitbook[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            detail.isActive = true
            rows[#rows + 1] = detail
        end
    end

    return rows
end

function Profile.ListEquippedItemTraits()
    local rows = {}
    local equipped = Equipment.ListEquippedSlots and Equipment.ListEquippedSlots() or {}

    for index = 1, #equipped do
        local slotEntry = equipped[index]
        local entry = slotEntry and slotEntry.entry or nil
        local item, dataset = nil, nil
        if entry and Equipment.ResolveItemDefinition then
            item, dataset = Equipment.ResolveItemDefinition(entry.itemRef)
        end

        local equipmentTrait = item and item.equipmentTrait or nil
        if item and type(equipmentTrait) == "table" then
            local payload = normalizeTraitPayload(equipmentTrait)
            local itemName = trimString(item.name)
            local authoredDescriptionText = trimString(payload.description)
            local summaryText = getTraitSummaryText(payload, "No effects")
            local itemConditionState = evaluateDetailConditions("item", item, {
                itemRef = entry and entry.itemRef or nil,
                item = item,
            })
            local payloadConditionState = evaluateDetailConditions("trait", payload, {
                itemRef = entry and entry.itemRef or nil,
                item = item,
            })
            rows[#rows + 1] = {
                sourceType = "equipment",
                category = "equipment",
                slotKey = slotEntry and slotEntry.slotKey or nil,
                item = item,
                itemRef = entry and entry.itemRef or nil,
                itemName = itemName,
                name = itemName ~= "" and itemName or "Equipment Trait",
                payload = payload,
                summaryText = summaryText,
                authoredDescriptionText = authoredDescriptionText,
                descriptionText = authoredDescriptionText ~= "" and authoredDescriptionText or summaryText,
                descriptionSource = authoredDescriptionText ~= "" and "authored" or "summary",
                icon = ensureString(item.icon),
                dataset = dataset,
                datasetId = dataset and dataset.id or nil,
                equipmentTrait = equipmentTrait,
                isMissing = false,
                conditionFailureText = itemConditionState.passed ~= true and itemConditionState.failureText or (payloadConditionState.passed ~= true and payloadConditionState.failureText or ""),
            }
        end
    end

    if Profile.IsMounted() and Equipment.ListMountEquippedSlots then
        local mountedEquipped = Equipment.ListMountEquippedSlots()
        for index = 1, #mountedEquipped do
            local slotEntry = mountedEquipped[index]
            local entry = slotEntry and slotEntry.entry or nil
            local item, dataset = nil, nil
            if entry and Equipment.ResolveItemDefinition then
                item, dataset = Equipment.ResolveItemDefinition(entry.itemRef)
            end

            local equipmentTrait = item and item.equipmentTrait or nil
            if item and type(equipmentTrait) == "table" then
                local payload = normalizeTraitPayload(equipmentTrait)
                local itemName = trimString(item.name)
                local authoredDescriptionText = trimString(payload.description)
                local summaryText = getTraitSummaryText(payload, "No effects")
                local itemConditionState = evaluateDetailConditions("item", item, {
                    itemRef = entry and entry.itemRef or nil,
                    item = item,
                    equipmentScope = "mount",
                })
                local payloadConditionState = evaluateDetailConditions("trait", payload, {
                    itemRef = entry and entry.itemRef or nil,
                    item = item,
                    equipmentScope = "mount",
                })
                rows[#rows + 1] = {
                    sourceType = "mount_equipment",
                    category = "equipment",
                    slotKey = slotEntry and slotEntry.slotKey or nil,
                    item = item,
                    itemRef = entry and entry.itemRef or nil,
                    itemName = itemName,
                    name = itemName ~= "" and itemName or "Mount Equipment Trait",
                    payload = payload,
                    summaryText = summaryText,
                    authoredDescriptionText = authoredDescriptionText,
                    descriptionText = authoredDescriptionText ~= "" and authoredDescriptionText or summaryText,
                    descriptionSource = authoredDescriptionText ~= "" and "authored" or "summary",
                    icon = ensureString(item.icon),
                    dataset = dataset,
                    datasetId = dataset and dataset.id or nil,
                    equipmentTrait = equipmentTrait,
                    isMissing = false,
                    conditionFailureText = itemConditionState.passed ~= true and itemConditionState.failureText or (payloadConditionState.passed ~= true and payloadConditionState.failureText or ""),
                }
            end
        end
    end

    table.sort(rows, function(left, right)
        local leftName = string.lower(ensureString(left and left.name))
        local rightName = string.lower(ensureString(right and right.name))
        if leftName == rightName then
            return ensureString(left and left.itemRef) < ensureString(right and right.itemRef)
        end
        return leftName < rightName
    end)

    return rows
end

function Profile.GetKnownTraitDetails(traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return nil
    end

    local registry = getRegistry()
    local dataset, trait = nil, nil
    if registry.ResolveTraitReference then
        dataset, trait = registry:ResolveTraitReference(normalizedRef)
    end

    local traitName = registry.ResolveTraitName and registry:ResolveTraitName(normalizedRef) or normalizedRef
    local datasetName = dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or "Unknown Dataset"
    local traitPayload = trait and normalizeTraitPayload(trait) or nil
    local authoredDescriptionText = traitPayload and trimString(traitPayload.description) or ""
    local summaryText = getTraitSummaryText(traitPayload, trait and "No effects" or "This trait definition is missing from its dataset.")
    local descriptionText = authoredDescriptionText
    local typeCategory = getTraitSourceCategory(trait)
    local unlockLevel = getTraitUnlockLevel(trait)
    local descriptionSource = authoredDescriptionText ~= "" and "authored" or "summary"
    local origin = getKnownTraitOrigin(normalizedRef) or "manual"
    local category = getTraitDisplayCategory(origin, typeCategory, trait)
    local isVisibleToProfile = false
    local isUnlockedForProfile = false
    local conditionState = evaluateDetailConditions("trait", traitPayload, {
        traitRef = normalizedRef,
    })

    if descriptionText == "" then
        descriptionText = summaryText
    end

    isUnlockedForProfile = unlockLevel <= getProfileLevel()

    local detail = {
        traitRef = normalizedRef,
        name = traitName,
        dataset = dataset,
        trait = trait,
        traitPayload = traitPayload,
        datasetName = datasetName,
        summaryText = summaryText,
        authoredDescriptionText = authoredDescriptionText,
        descriptionText = descriptionText,
        descriptionSource = descriptionSource,
        category = category,
        typeCategory = typeCategory,
        unlockLevel = unlockLevel,
        origin = origin,
        isAutoGranted = origin == "race" or origin == "class",
        isManual = origin == "manual",
        isToggleable = (origin == "manual" and typeCategory == "talent")
            or (origin == "class" and typeCategory == "talent"),
        isRemovable = origin == "manual"
            or (trait == nil and (origin == "race" or origin == "class")),
        icon = trait and trait.icon or "",
        isEnvironmental = trait and trait.isEnvironmental == true or false,
        isMissing = trait == nil,
        conditionFailureText = conditionState.passed ~= true and conditionState.failureText or "",
    }
    detail.isUnlockedForProfile = isUnlockedForProfile
    detail.isVisibleToProfile = isTraitDetailVisibleToProfile(detail)
    return detail
end

function Profile.ListAvailableConsumableTraits()
    local Inventory = getInventory()
    local displayItems = Inventory.GetDisplayItems and Inventory.GetDisplayItems() or {}
    local rows = {}
    local rowsByItemRef = {}
    local preferredConsumables = Database.ListProfilePreferredConsumables and Database.ListProfilePreferredConsumables() or {}
    local preferredLookup = {}

    for index = 1, #preferredConsumables do
        local itemRef = ensureString(preferredConsumables[index])
        if itemRef ~= "" then
            preferredLookup[itemRef] = true
        end
    end

    for index = 1, #displayItems do
        local resolved = displayItems[index]
        local item = resolved and resolved.item or nil
        local consumableTrait = item and item.consumableTrait or nil
        if resolved and resolved.isMissing ~= true and type(consumableTrait) == "table" then
            local itemRef = resolved.datasetId and resolved.itemId and ("%s:%s"):format(tostring(resolved.datasetId), tostring(resolved.itemId)) or ensureString(item and item.name)
            local itemName = trimString(item and item.name)
            local dataset = resolved.datasetId and findActivatedDatasetById(resolved.datasetId) or nil
            local datasetName = dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or "Unknown Dataset"
            local payload = normalizeTraitPayload(consumableTrait)
            local authoredDescriptionText = trimString(payload.description)
            local itemDescriptionText = trimString(item and item.description)
            local summaryText = itemDescriptionText ~= "" and itemDescriptionText or getTraitSummaryText(payload, "No effects")
            local descriptionText = authoredDescriptionText ~= "" and authoredDescriptionText or summaryText
            local descriptionSource = authoredDescriptionText ~= "" and "authored" or "summary"
            local itemIcon = ensureString(item and item.icon)
            local itemConditionState = evaluateDetailConditions("item", item, {
                itemRef = itemRef,
                item = item,
            })
            local payloadConditionState = evaluateDetailConditions("trait", payload, {
                itemRef = itemRef,
                item = item,
            })
            local row = rowsByItemRef[itemRef]
            if not row then
                row = {
                    itemRef = itemRef,
                    sourceIndex = resolved.sourceIndex,
                    sourceIndices = {},
                    resolvedItem = resolved,
                    item = item,
                    category = "consumable",
                    name = itemName ~= "" and itemName or "Consumable Trait",
                    itemName = itemName,
                    traitName = "",
                    dataset = dataset,
                    datasetId = resolved.datasetId,
                    datasetName = datasetName,
                    payload = payload,
                    summaryText = summaryText,
                    authoredDescriptionText = authoredDescriptionText,
                    descriptionText = descriptionText,
                    descriptionSource = descriptionSource,
                    icon = itemIcon,
                    phase = consumableTrait.phase,
                    consumableTrait = consumableTrait,
                    count = 0,
                    isToggleable = true,
                    isActive = preferredLookup[itemRef] == true,
                    conditionFailureText = itemConditionState.passed ~= true and itemConditionState.failureText or (payloadConditionState.passed ~= true and payloadConditionState.failureText or ""),
                }
                rowsByItemRef[itemRef] = row
                rows[#rows + 1] = row
            end

            row.count = (tonumber(row.count) or 0) + math.max(1, math.floor(tonumber(resolved.quantity) or 1))
            row.sourceIndices[#row.sourceIndices + 1] = resolved.sourceIndex
        end
    end

    table.sort(rows, function(left, right)
        local leftName = string.lower(ensureString(left and left.name))
        local rightName = string.lower(ensureString(right and right.name))
        if leftName == rightName then
            return ensureString(left and left.itemRef) < ensureString(right and right.itemRef)
        end
        return leftName < rightName
    end)

    return rows
end

function Profile.ListPreferredConsumableItemRefs()
    return Database.ListProfilePreferredConsumables and Database.ListProfilePreferredConsumables() or {}
end

function Profile.IsConsumableTraitPreferred(itemRef)
    local normalizedRef = ensureString(itemRef)
    if normalizedRef == "" then
        return false
    end

    local preferredConsumables = Profile.ListPreferredConsumableItemRefs and Profile.ListPreferredConsumableItemRefs() or {}
    for index = 1, #preferredConsumables do
        if ensureString(preferredConsumables[index]) == normalizedRef then
            return true
        end
    end

    return false
end

local function findAvailableConsumableTrait(itemRef)
    local normalizedRef = ensureString(itemRef)
    if normalizedRef == "" then
        return nil
    end

    local rows = Profile.ListAvailableConsumableTraits and Profile.ListAvailableConsumableTraits() or {}
    for index = 1, #rows do
        local row = rows[index]
        if ensureString(row and row.itemRef) == normalizedRef then
            return row
        end
    end

    return nil
end

function Profile.ActivateConsumableTrait(itemRef)
    local normalizedRef = ensureString(itemRef)
    if normalizedRef == "" then
        return false
    end

    local selectedRow = findAvailableConsumableTrait(normalizedRef)
    if not selectedRow then
        return false
    end

    if Database.AddProfilePreferredConsumable then
        return Database.AddProfilePreferredConsumable(normalizedRef)
    end

    return false
end

function Profile.DeactivateConsumableTrait(itemRef)
    local normalizedRef = ensureString(itemRef)
    if normalizedRef == "" then
        return false
    end

    if Database.RemoveProfilePreferredConsumable then
        return Database.RemoveProfilePreferredConsumable(normalizedRef)
    end

    return false
end

function Profile.ToggleConsumableTraitActivation(itemRef)
    local normalizedRef = ensureString(itemRef)
    if normalizedRef == "" then
        return nil
    end

    if Profile.IsConsumableTraitPreferred(normalizedRef) then
        return Profile.DeactivateConsumableTrait(normalizedRef) and "deactivated" or nil
    end

    return Profile.ActivateConsumableTrait(normalizedRef) and "activated" or nil
end

function Profile.AddKnownTrait(traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return false
    end

    local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(normalizedRef) or nil
    if detail and detail.typeCategory ~= "talent" then
        return false
    end
    if detail and detail.isAutoGranted == true then
        return false
    end
    if detail and detail.isVisibleToProfile ~= true then
        return false
    end

    local summary = buildTraitCountSummary()
    if detail and detail.isEnvironmental ~= true then
        if summary.maxTotalTraits > 0 and summary.manualCount >= summary.maxTotalTraits then
            return false
        end
        if detail.typeCategory == "talent" and summary.maxTalentTraits > 0 and summary.manualTalentCount >= summary.maxTalentTraits then
            return false
        end
    end

    if Database.AddProfileTrait then
        local added = Database.AddProfileTrait(normalizedRef)
        if added and Database.AddProfileActiveTrait then
            Database.AddProfileActiveTrait(normalizedRef)
        end
        return added
    end

    return false
end

function Profile.RemoveKnownTrait(traitRef)
    local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(traitRef) or nil
    if detail and detail.isMissing == true and detail.origin == "race" then
        return pruneSelectedOriginTraitRef("race", detail.traitRef)
    end
    if detail and detail.isMissing == true and detail.origin == "class" then
        return pruneSelectedOriginTraitRef("class", detail.traitRef)
    end

    if Database.RemoveProfileTrait then
        return Database.RemoveProfileTrait(traitRef)
    end

    return false
end

function Profile.IsTraitActive(traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return false
    end

    local activeTraits = Profile.ListActiveTraits and Profile.ListActiveTraits() or {}
    for index = 1, #activeTraits do
        if ensureString(activeTraits[index] and activeTraits[index].traitRef) == normalizedRef then
            return true
        end
    end

    return false
end

function Profile.ActivateTrait(traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return false
    end

    local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(normalizedRef) or nil
    if detail and detail.isToggleable ~= true then
        return false
    end
    if detail and detail.isVisibleToProfile ~= true then
        return false
    end
    if detail and detail.origin == "manual" then
        local knownTraits = Database.ListProfileTraits and Database.ListProfileTraits() or {}
        local isKnown = false
        for index = 1, #knownTraits do
            if ensureString(knownTraits[index]) == normalizedRef then
                isKnown = true
                break
            end
        end
        if not isKnown then
            return false
        end
    end
    if Profile.IsTraitActive(normalizedRef) then
        return false
    end

    if detail and detail.origin == "class" and detail.typeCategory == "talent" then
        if Database.RemoveProfileInactiveTrait then
            Database.RemoveProfileInactiveTrait(normalizedRef)
        end
        return true
    end

    if Database.AddProfileActiveTrait then
        return Database.AddProfileActiveTrait(normalizedRef)
    end

    return false
end

function Profile.DeactivateTrait(traitRef)
    local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(traitRef) or nil
    if detail and detail.isToggleable ~= true then
        return false
    end

    if detail and detail.origin == "class" and detail.typeCategory == "talent" then
        if Profile.IsTraitActive(traitRef) and Database.AddProfileInactiveTrait then
            Database.AddProfileInactiveTrait(traitRef)
            return true
        end
        return false
    end

    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil
    local hasPersistedActiveTraits = type(profile) == "table" and profile.activeTraits ~= nil
    if not hasPersistedActiveTraits then
        local knownTraits = Database.ListProfileTraits and Database.ListProfileTraits() or {}
        if #knownTraits > 0 and Database.AddProfileActiveTrait then
            for index = 1, #knownTraits do
                Database.AddProfileActiveTrait(knownTraits[index])
            end
        end
    end

    if Database.RemoveProfileActiveTrait then
        return Database.RemoveProfileActiveTrait(traitRef)
    end

    return false
end

function Profile.ToggleTraitActivation(traitRef)
    local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(traitRef) or nil
    if detail and detail.isToggleable ~= true then
        return nil
    end

    if Profile.IsTraitActive(traitRef) then
        return Profile.DeactivateTrait(traitRef) and "deactivated" or nil
    end

    if Profile.ActivateTrait(traitRef) then
        return "activated"
    end

    return nil
end

function Profile.RemoveKnownTraitAt(index)
    if Database.RemoveProfileTraitAt then
        return Database.RemoveProfileTraitAt(index)
    end

    return false
end

function Profile.GetKnownSpellDetails(spellRef)
    local normalizedRef = ensureString(spellRef)
    if normalizedRef == "" then
        return nil
    end

    local registry = getRegistry()
    local dataset, spell = nil, nil
    if registry.ResolveSpellReference then
        dataset, spell = registry:ResolveSpellReference(normalizedRef)
    end

    local spellName = registry.ResolveSpellName and registry:ResolveSpellName(normalizedRef) or normalizedRef
    local datasetName = dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or "Unknown Dataset"
    local summaryText = getSpellSummaryText(spell)
    local authoredDescriptionText = spell and trimString(spell.description) or ""
    local descriptionText = authoredDescriptionText
    local descriptionSource = authoredDescriptionText ~= "" and "authored" or "summary"
    local learnMode = spell and tostring(spell.learnMode or "trainer") or "unavailable"
    local conditionState = evaluateDetailConditions("spell", spell, {
        spellRef = normalizedRef,
    })

    if descriptionText == "" then
        descriptionText = summaryText
        descriptionSource = "summary"
    end

    return {
        spellRef = normalizedRef,
        name = spellName,
        dataset = dataset,
        spell = spell,
        datasetName = datasetName,
        statusText = getSpellStatusText(spell),
        cooldownText = getSpellCooldownText(spell),
        summaryText = summaryText,
        authoredDescriptionText = authoredDescriptionText,
        descriptionText = descriptionText,
        descriptionSource = descriptionSource,
        learnMode = learnMode,
        spellbookCategory = isSpellProvidedBySelectedMount(normalizedRef) and "Mounted" or (spell and trimString(spell.spellbookCategory) or ""),
        mountedCombatOnly = spell and spell.mountedCombatOnly == true or false,
        isMissing = spell == nil,
        conditionFailureText = conditionState.passed ~= true and conditionState.failureText or "",
    }
end

function Profile.AddKnownSpell(spellRef)
    if Database.AddProfileSpellbookSpell then
        local changed = Database.AddProfileSpellbookSpell(spellRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.RemoveKnownSpell(spellRef)
    if Database.RemoveProfileSpellbookSpell then
        local changed = Database.RemoveProfileSpellbookSpell(spellRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.RemoveKnownSpellAt(index)
    if Database.RemoveProfileSpellbookSpellAt then
        local changed = Database.RemoveProfileSpellbookSpellAt(index)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.GetActionBarSize()
    return getActionBarSizeFromRuleset()
end

function Profile.GetActionBarMode()
    if Database.GetProfileActionBarMode then
        return Database.GetProfileActionBarMode()
    end

    return "spells"
end

local function hasSelectedMountActionBarSpells()
    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local mount = selectedMount and selectedMount.mount or nil
    local spellRefs = mount and mount.spells or nil
    if type(spellRefs) ~= "table" then
        return false
    end

    for index = 1, #spellRefs do
        local spellRef = ensureString(spellRefs[index])
        if spellRef ~= "" then
            if not Profile.IsMountedActionBarRestricted or not Profile.IsMountedActionBarRestricted() then
                return true
            end
            if Profile.IsMountedCombatSpell and Profile.IsMountedCombatSpell(spellRef) then
                return true
            end
        end
    end

    return false
end

function Profile.ShouldUseMountedActionBar()
    return Profile.IsMounted()
        and (
            getInterfaceRuleValue("mounted_action_bar", false) == true
            or hasSelectedMountActionBarSpells()
        )
end

function Profile.IsMountedActionBarRestricted()
    return getInterfaceRuleValue("mounted_action_bar_only_mounted_combat_spells", false) == true
end

function Profile.AreWidgetsUnlocked()
    if Database.GetProfileWidgetsUnlocked then
        return Database.GetProfileWidgetsUnlocked()
    end

    return false
end

function Profile.SetWidgetsUnlocked(unlocked)
    if Database.SetProfileWidgetsUnlocked then
        return Database.SetProfileWidgetsUnlocked(unlocked)
    end

    return false
end

function Profile.SetActionBarMode(mode)
    if Database.SetProfileActionBarMode then
        return Database.SetProfileActionBarMode(mode)
    end

    return "spells"
end

function Profile.ToggleActionBarMode()
    local currentMode = Profile.GetActionBarMode()
    if currentMode == "skills" then
        return Profile.SetActionBarMode("spells")
    end

    return Profile.SetActionBarMode("skills")
end

function Profile.GetActionBarAnchor()
    if Database.GetProfileActionBarAnchor then
        return Database.GetProfileActionBarAnchor()
    end

    return nil
end

function Profile.GetPrimaryResourceRef()
    if Database.GetProfilePrimaryResourceRef then
        return Database.GetProfilePrimaryResourceRef()
    end

    return nil
end

function Profile.SetPrimaryResourceRef(resourceRef)
    if Database.SetProfilePrimaryResourceRef then
        return Database.SetProfilePrimaryResourceRef(resourceRef)
    end

    return nil
end

function Profile.GetSpecialResourceRef()
    if Database.GetProfileSpecialResourceRef then
        return Database.GetProfileSpecialResourceRef()
    end

    return nil
end

function Profile.SetSpecialResourceRef(resourceRef)
    if Database.SetProfileSpecialResourceRef then
        return Database.SetProfileSpecialResourceRef(resourceRef)
    end

    return nil
end

function Profile.GetLevel()
    if Database.GetProfileLevel then
        return Database.GetProfileLevel()
    end

    return 1
end

function Profile.SetLevel(level)
    if Database.SetProfileLevel then
        return Database.SetProfileLevel(level)
    end

    return 1
end

function Profile.GetRaceRef()
    if Database.GetProfileRaceRef then
        return Database.GetProfileRaceRef()
    end

    return nil
end

function Profile.SetRaceRef(raceRef)
    if Database.SetProfileRaceRef then
        return Database.SetProfileRaceRef(raceRef)
    end

    return nil
end

function Profile.GetClassRef()
    if Database.GetProfileClassRef then
        return Database.GetProfileClassRef()
    end

    return nil
end

function Profile.SetClassRef(classRef)
    if Database.SetProfileClassRef then
        return Database.SetProfileClassRef(classRef)
    end

    return nil
end

function Profile.GetSetupWizardState()
    if Database.GetProfileSetupWizardState then
        return Database.GetProfileSetupWizardState()
    end

    return nil
end

function Profile.SetSetupWizardState(state)
    if Database.SetProfileSetupWizardState then
        return Database.SetProfileSetupWizardState(state)
    end

    return nil
end

function Profile.GetResolvedBaseResourceValue(resourceRef, options)
    local row = Profile.GetResolvedResourceRow(resourceRef, options)
    return tonumber(row and row.baseResourceValue) or 0, row
end

function Profile.SetActionBarAnchor(anchor)
    if Database.SetProfileActionBarAnchor then
        return Database.SetProfileActionBarAnchor(anchor)
    end

    return nil
end

function Profile.ListActionBarBindings()
    return Database.ListProfileActionBar and Database.ListProfileActionBar() or {}
end

function Profile.ListSkillActionBarBindings()
    return Database.ListProfileSkillActionBar and Database.ListProfileSkillActionBar() or {}
end

function Profile.ListMountedActionBarBindings()
    return {}
end

function Profile.FindActionBarSlotBySpell(spellRef)
    if Database.FindProfileActionBarSlotBySpell then
        return Database.FindProfileActionBarSlotBySpell(spellRef)
    end

    return nil
end

function Profile.FindActionBarSlotBySkill(skillRef)
    if Database.FindProfileActionBarSlotBySkill then
        return Database.FindProfileActionBarSlotBySkill(skillRef)
    end

    return nil
end

function Profile.FindMountedActionBarSlotBySpell(spellRef)
    local normalizedRef = ensureString(spellRef)
    if normalizedRef == "" then
        return nil
    end

    local rows = Profile.ListMountedActionBarSlots and Profile.ListMountedActionBarSlots() or {}
    for slotIndex = 1, #rows do
        if ensureString(rows[slotIndex] and rows[slotIndex].spellRef) == normalizedRef then
            return slotIndex
        end
    end

    return nil
end

function Profile.BindSpellToActionBarSlot(slotIndex, spellRef)
    if Database.BindProfileActionBarSpell then
        local changed = Database.BindProfileActionBarSpell(slotIndex, spellRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return nil
end

function Profile.IsMountedCombatSpell(spellRef)
    local detail = Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellRef) or nil
    return detail and detail.mountedCombatOnly == true or false
end

function Profile.CanBindSpellToMountedActionBar(spellRef)
    return false
end

function Profile.BindSpellToMountedActionBarSlot(slotIndex, spellRef)
    return nil
end

local function isBindableSkillRow(row)
    return type(row) == "table"
        and tostring(row.skillType or "") == "noncombat"
        and row.rollable == true
end

function Profile.BindSkillToActionBarSlot(slotIndex, skillRef)
    local row = Profile.GetResolvedSkillRow and Profile.GetResolvedSkillRow(skillRef) or nil
    if not isBindableSkillRow(row) then
        return nil
    end

    if Database.BindProfileActionBarSkill then
        local changed = Database.BindProfileActionBarSkill(slotIndex, skillRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return nil
end

function Profile.UnbindSpellFromActionBar(spellRef)
    if Database.UnbindProfileActionBarSpell then
        local changed = Database.UnbindProfileActionBarSpell(spellRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.UnbindSkillFromActionBar(skillRef)
    if Database.UnbindProfileActionBarSkill then
        local changed = Database.UnbindProfileActionBarSkill(skillRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.UnbindSpellFromMountedActionBar(spellRef)
    return false
end

function Profile.ClearActionBarSlot(slotIndex)
    if Database.ClearProfileActionBarSlot then
        return Database.ClearProfileActionBarSlot(slotIndex)
    end

    return false
end

function Profile.ClearSkillActionBarSlot(slotIndex)
    if Database.ClearProfileSkillActionBarSlot then
        return Database.ClearProfileSkillActionBarSlot(slotIndex)
    end

    return false
end

function Profile.ClearMountedActionBarSlot(slotIndex)
    return false
end

function Profile.BindSpellToFirstAvailableActionBarSlot(spellRef)
    local bindings = Profile.ListActionBarBindings()
    local size = Profile.GetActionBarSize()

    for slotIndex = 1, size do
        if bindings[slotIndex] == nil or bindings[slotIndex] == "" then
            return Profile.BindSpellToActionBarSlot(slotIndex, spellRef)
        end
    end

    return nil
end

function Profile.BindSpellToFirstAvailableMountedActionBarSlot(spellRef)
    return nil
end

function Profile.BindSkillToFirstAvailableActionBarSlot(skillRef)
    local row = Profile.GetResolvedSkillRow and Profile.GetResolvedSkillRow(skillRef) or nil
    if not isBindableSkillRow(row) then
        return nil
    end

    local bindings = Profile.ListSkillActionBarBindings()
    local size = Profile.GetActionBarSize()

    for slotIndex = 1, size do
        if bindings[slotIndex] == nil or bindings[slotIndex] == "" then
            return Profile.BindSkillToActionBarSlot(slotIndex, skillRef)
        end
    end

    return nil
end

function Profile.ToggleSpellActionBarBinding(spellRef)
    local boundSlot = Profile.FindActionBarSlotBySpell(spellRef)
    if boundSlot then
        return Profile.UnbindSpellFromActionBar(spellRef) and "unbound" or nil, boundSlot
    end

    local slotIndex = Profile.BindSpellToFirstAvailableActionBarSlot(spellRef)
    if slotIndex then
        return "bound", slotIndex
    end

    return nil, nil
end

function Profile.ToggleSkillActionBarBinding(skillRef)
    local boundSlot = Profile.FindActionBarSlotBySkill(skillRef)
    if boundSlot then
        return Profile.UnbindSkillFromActionBar(skillRef) and "unbound" or nil, boundSlot
    end

    local slotIndex = Profile.BindSkillToFirstAvailableActionBarSlot(skillRef)
    if slotIndex then
        return "bound", slotIndex
    end

    return nil, nil
end

function Profile.ToggleMountedSpellActionBarBinding(spellRef)
    return nil, nil
end

local function getMountedActionBarSpellRefs()
    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local mount = selectedMount and selectedMount.mount or nil
    local spellRefs = mount and mount.spells or nil
    if type(spellRefs) ~= "table" then
        return {}
    end

    local filtered = {}
    for index = 1, #spellRefs do
        local spellRef = ensureString(spellRefs[index])
        if spellRef ~= "" then
            if not Profile.IsMountedActionBarRestricted() or Profile.IsMountedCombatSpell(spellRef) then
                filtered[#filtered + 1] = spellRef
            end
        end
    end

    return filtered
end

function Profile.GetActionBarSlotDetails(slotIndex)
    local spellRef = Database.GetProfileActionBarSpell and Database.GetProfileActionBarSpell(slotIndex) or nil
    if not spellRef then
        return nil
    end

    local detail = Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellRef) or nil
    if not detail then
        return nil
    end

    detail.slotIndex = math.floor(tonumber(slotIndex) or 0)
    detail.actionBarKind = "spell"
    return detail
end

function Profile.GetSkillActionBarSlotDetails(slotIndex)
    local skillRef = Database.GetProfileActionBarSkill and Database.GetProfileActionBarSkill(slotIndex) or nil
    if not skillRef then
        return nil
    end

    local row = Profile.GetResolvedSkillRow and Profile.GetResolvedSkillRow(skillRef) or nil
    if not isBindableSkillRow(row) then
        return nil
    end

    local detail = {}
    for key, value in pairs(row) do
        detail[key] = value
    end
    detail.slotIndex = math.floor(tonumber(slotIndex) or 0)
    detail.actionBarKind = "skill"
    return detail
end

function Profile.GetMountedActionBarSlotDetails(slotIndex)
    local mountedSpellRefs = getMountedActionBarSpellRefs()
    local spellRef = mountedSpellRefs[math.floor(tonumber(slotIndex) or 0)]
    if not spellRef then
        return nil
    end

    local detail = Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellRef) or nil
    if not detail then
        return nil
    end

    detail.slotIndex = math.floor(tonumber(slotIndex) or 0)
    detail.actionBarKind = "mounted-spell"
    return detail
end

function Profile.ListActionBarSlots()
    local size = Profile.GetActionBarSize()
    local rows = {}

    for slotIndex = 1, size do
        rows[slotIndex] = Profile.GetActionBarSlotDetails(slotIndex)
    end

    return rows
end

function Profile.ListSkillActionBarSlots()
    local size = Profile.GetActionBarSize()
    local rows = {}

    for slotIndex = 1, size do
        rows[slotIndex] = Profile.GetSkillActionBarSlotDetails(slotIndex)
    end

    return rows
end

function Profile.ListMountedActionBarSlots()
    local size = Profile.GetActionBarSize()
    local rows = {}

    for slotIndex = 1, size do
        rows[slotIndex] = Profile.GetMountedActionBarSlotDetails(slotIndex)
    end

    return rows
end

function Profile.GetStatBonus(statRef)
    if Database.GetProfileStatBonus then
        return Database.GetProfileStatBonus(statRef)
    end

    return 0
end

function Profile.SetStatBonus(statRef, value)
    if Database.SetProfileStatBonus then
        return Database.SetProfileStatBonus(statRef, value)
    end

    return nil
end

function Profile.ClearStatBonus(statRef)
    if Database.ClearProfileStatBonus then
        return Database.ClearProfileStatBonus(statRef)
    end

    return false
end

function Profile.ListSkillLevels()
    if Database.ListProfileSkillLevels then
        return Database.ListProfileSkillLevels()
    end

    return {}
end

function Profile.GetSkillLevel(skillRef)
    if Database.GetProfileSkillLevel then
        return Database.GetProfileSkillLevel(skillRef)
    end

    return 0
end

function Profile.SetSkillLevel(skillRef, value)
    if Database.SetProfileSkillLevel then
        return Database.SetProfileSkillLevel(skillRef, value)
    end

    return nil
end

function Profile.ClearSkillLevel(skillRef)
    if Database.ClearProfileSkillLevel then
        return Database.ClearProfileSkillLevel(skillRef)
    end

    return false
end

function Profile.ListProfileStatRows(options)
    local resolvedStats = Profile.ListResolvedStats(options)
    local grouped = {}
    local rows = {}
    local movementRangeStatRef = Profile.GetMovementRangeStatRef and ensureString(Profile.GetMovementRangeStatRef()) or ""

    for index = 1, #resolvedStats do
        local statRow = resolvedStats[index]
        local stat = statRow and statRow.stat or nil
        if stat and stat.visibility == true and ensureString(statRow and statRow.ref) ~= movementRangeStatRef then
            local categoryName = trimString(stat.category)
            if categoryName ~= "" then
                local bucket = grouped[categoryName]
                if not bucket then
                    bucket = {}
                    grouped[categoryName] = bucket
                end

                bucket[#bucket + 1] = statRow
            end
        end
    end

    local categoryOrder = {}
    for categoryName in pairs(grouped) do
        categoryOrder[#categoryOrder + 1] = categoryName
    end

    table.sort(categoryOrder, function(left, right)
        local leftFallback = string.byte(string.lower(tostring(left)), 1) or 0
        local rightFallback = string.byte(string.lower(tostring(right)), 1) or 0
        local leftOrder = PROFILE_STAT_CATEGORY_ORDER_LOOKUP[left] or (1000 + leftFallback)
        local rightOrder = PROFILE_STAT_CATEGORY_ORDER_LOOKUP[right] or (1000 + rightFallback)
        if leftOrder == rightOrder then
            return string.lower(tostring(left)) < string.lower(tostring(right))
        end
        return leftOrder < rightOrder
    end)

    for index = 1, #categoryOrder do
        local categoryName = categoryOrder[index]
        local bucket = grouped[categoryName] or {}
        if #bucket > 0 then
            rows[#rows + 1] = {
                rowType = "header",
                category = categoryName,
            }

            for statIndex = 1, #bucket do
                local statRow = bucket[statIndex]
                rows[#rows + 1] = {
                    rowType = "stat",
                    category = categoryName,
                    statRow = statRow,
                }
            end
        end
    end

    return rows
end

function Profile.ListEquipableItemsForSlot(slotKey)
    return Equipment.ListEquipableItemsForSlot and Equipment.ListEquipableItemsForSlot(slotKey) or {}
end

function Profile.ListEquipableItemsForScopeSlot(scope, slotKey)
    local rows = Equipment.ListEquipableItemsForScopeSlot and Equipment.ListEquipableItemsForScopeSlot(scope, slotKey) or {}
    local normalizedScope = Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(scope) or tostring(scope or "character")
    if normalizedScope ~= "pet" then
        return rows
    end

    local filtered = {}
    local layout = Profile.GetPetLayout and Profile.GetPetLayout() or nil
    local slotEntries = layout and layout.entries or {}
    local allowedSlotRefs = {}
    local normalizedSlotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(slotKey) or ensureString(slotKey)

    for index = 1, #slotEntries do
        local entry = slotEntries[index]
        if entry and entry.slotKey == normalizedSlotKey then
            allowedSlotRefs[ensureString(entry.slotRef)] = true
        end
    end

    for index = 1, #rows do
        local row = rows[index]
        if allowedSlotRefs[ensureString(row and row.slotRef)] == true then
            filtered[#filtered + 1] = row
        end
    end

    return filtered
end

function Profile.ListMountEquippedSlots()
    return Profile.ListEquippedSlotsByScope("mount")
end

function Profile.GetEquippedMountItem(slotKey)
    return Profile.GetEquippedItemByScope("mount", slotKey)
end

function Profile.EquipMountItem(slotKey, itemRef, modifications, slotRef, soulbound)
    local layout = Profile.GetEquipmentLayoutByScope and Profile.GetEquipmentLayoutByScope("mount") or Profile.GetMountLayout()
    local normalizedSlotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(slotKey) or ensureString(slotKey)
    local allowed = false
    for index = 1, #(layout.entries or {}) do
        local entry = layout.entries[index]
        if entry and entry.slotKey == normalizedSlotKey then
            allowed = true
            if ensureString(slotRef) == "" then
                slotRef = entry.slotRef
            end
            break
        end
    end
    if not allowed then
        return nil, "invalid-slot"
    end

    return Equipment.EquipItemInScope and Equipment.EquipItemInScope("mount", slotKey, itemRef, modifications, slotRef, soulbound) or nil
end

function Profile.UnequipMountItem(slotKey)
    return Equipment.UnequipItemInScope and Equipment.UnequipItemInScope("mount", slotKey) or false
end

function Profile.ListEquipableMountItemsForSlot(slotKey)
    return Profile.ListEquipableItemsForScopeSlot("mount", slotKey)
end

function Profile.ListPetEquippedSlots()
    return Profile.ListEquippedSlotsByScope("pet")
end

function Profile.GetEquippedPetItem(slotKey)
    return Profile.GetEquippedItemByScope("pet", slotKey)
end

function Profile.EquipPetItem(slotKey, itemRef, modifications, slotRef, soulbound)
    local layout = Profile.GetPetLayout and Profile.GetPetLayout() or buildSlotLayoutFromRefs({})
    local normalizedSlotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(slotKey) or ensureString(slotKey)
    local allowed = false
    for index = 1, #(layout.entries or {}) do
        local entry = layout.entries[index]
        if entry and entry.slotKey == normalizedSlotKey then
            allowed = true
            if ensureString(slotRef) == "" then
                slotRef = entry.slotRef
            end
            break
        end
    end
    if not allowed then
        return nil, "invalid-slot"
    end

    return Equipment.EquipItemInScope and Equipment.EquipItemInScope("pet", slotKey, itemRef, modifications, slotRef, soulbound) or nil
end

function Profile.UnequipPetItem(slotKey)
    return Equipment.UnequipItemInScope and Equipment.UnequipItemInScope("pet", slotKey) or false
end

function Profile.ListEquipablePetItemsForSlot(slotKey)
    return Profile.ListEquipableItemsForScopeSlot("pet", slotKey)
end

function Profile.GetMovementRangeStatRef()
    local value = getMountRuleValue("movement_range_stat", "")
    return type(value) == "string" and value or ""
end

function Profile.GetMovementRangeValue()
    local statRef = Profile.GetMovementRangeStatRef()
    local baseValue = nil
    if statRef ~= "" then
        baseValue = Profile.GetResolvedStatValue and Profile.GetResolvedStatValue(statRef, 0) or 0
    end

    local auraManager = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraManager or nil
    if auraManager and type(auraManager.GetLocalPlayerMovementRangeOverride) == "function" then
        local overrideValue = auraManager:GetLocalPlayerMovementRangeOverride()
        if overrideValue ~= nil then
            return overrideValue
        end
    end

    return baseValue
end

function Profile.GetMaximumHealthRow(options)
    local rulesetLogic = getRuleset()
    local ruleset = rulesetLogic.GetActiveRuleset and rulesetLogic.GetActiveRuleset() or nil
    local ruleDefinition = rulesetLogic.GetRulesetRuleDefinition and rulesetLogic.GetRulesetRuleDefinition("resources", "health_stat") or nil
    local healthResourceRef = rulesetLogic.GetRulesetRuleValue and rulesetLogic.GetRulesetRuleValue(ruleset, "resources", ruleDefinition) or nil
    if type(healthResourceRef) ~= "string" or healthResourceRef == "" then
        return nil
    end

    local resources = Profile.ListResolvedResources(options)
    for index = 1, #resources do
        local resourceRow = resources[index]
        if resourceRow and resourceRow.ref == healthResourceRef then
            return resourceRow
        end
    end

    return nil
end

function Profile.GetHealthResourceRef(options)
    local healthRow = Profile.GetMaximumHealthRow(options)
    return healthRow and healthRow.ref or nil
end

function Profile.GetSlotLabel(slotKey)
    if Equipment.PrettySlotLabel then
        return Equipment.PrettySlotLabel(slotKey)
    end

    local label = ensureString(slotKey)
    if label == "" then
        return "Slot"
    end

    return label
end

function Profile.GetSlotTexture(slotKey)
    return Equipment.GetSlotTexture and Equipment.GetSlotTexture(slotKey) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

return Profile
