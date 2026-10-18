local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile
local Equipment = Profile.Equipment or {}
Profile.Equipment = Equipment

local Database = Addon.Internal.Database or {}
local Definitions = Profile.Definitions or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}
local ItemTier = Addon.Internal and Addon.Internal.ItemTier or {}

local function ensureTable(value)
    if type(value) == "table" then
        return value
    end

    return {}
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function stripSlotOrdinal(value)
    return ensureString(value):gsub("%d+$", "")
end

local function itemHasExactSlotRef(item, slotRef)
    local slotRefs = item and item.validSlotRefs or nil
    if type(slotRefs) ~= "table" or type(slotRef) ~= "string" or slotRef == "" then
        return false
    end

    for index = 1, #slotRefs do
        if tostring(slotRefs[index] or "") == slotRef then
            return true
        end
    end

    return false
end

local function getDependencies()
    return Database.Dependecies or {}
end

local function getRegistry()
    return Addon.Internal and Addon.Internal.Registry or {}
end

local function normalizeArmorWeight(value)
    local normalized = string.lower(ensureString(value))
    return normalized:gsub("^%s+", ""):gsub("%s+$", "")
end

local function isClassArmorWeightRestrictionEnabled()
    local ruleset = Addon.Internal and Addon.Internal.Ruleset or {}
    if type(ruleset.GetActiveRuleset) ~= "function" or type(ruleset.GetRulesetRuleValueByKey) ~= "function" then
        return false
    end

    return ruleset.GetRulesetRuleValueByKey(
        ruleset.GetActiveRuleset(),
        "equipment",
        "enforce_class_armor_weight_restrictions",
        true
    ) == true
end

local function bumpProfileTooltipContextRevision()
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(builder) == "table" and type(builder.BumpProfileTooltipContextRevision) == "function" then
        builder.BumpProfileTooltipContextRevision()
    end
end

local function normalizeSlotType(value)
    local normalized = string.lower(ensureString(value))
    if normalized == "mount" or normalized == "pet" then
        return normalized
    end

    return "character"
end

local function getScopeFieldName(scope)
    local normalizedScope = normalizeSlotType(scope)
    if normalizedScope == "mount" then
        return "mountEquipment"
    end
    if normalizedScope == "pet" then
        return "petEquipment"
    end

    return "equipment"
end

function Equipment.NormalizeSlotKey(slotKey)
    local normalized = string.lower(ensureString(slotKey))
    normalized = normalized:gsub("[_%-%s]", "")
    return normalized
end

function Equipment.NormalizeSlotMatchKey(slotKey)
    return stripSlotOrdinal(Equipment.NormalizeSlotKey(slotKey))
end

function Equipment.NormalizeSlotType(slotType)
    return normalizeSlotType(slotType)
end

function Equipment.PrettySlotLabel(slotKey)
    local normalized = Equipment.NormalizeSlotKey(slotKey)
    local labels = Definitions.SlotLabels or {}
    if labels[normalized] then
        return labels[normalized]
    end

    local text = normalized:gsub("(%a)([%w_]*)", function(first, rest)
        return string.upper(first) .. rest
    end)
    text = text:gsub("hand", " Hand")
    return text
end

function Equipment.GetSlotTexture(slotKey)
    local textures = Definitions.SlotTextures or {}
    local normalized = Equipment.NormalizeSlotKey(slotKey)
    return textures[normalized] or textures[Equipment.NormalizeSlotMatchKey(normalized)] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function Equipment.ResolveSlotDefinition(slotRef)
    if type(slotRef) ~= "string" or slotRef == "" then
        return nil, nil
    end

    local datasetId, slotId = nil, nil
    local dependencies = getDependencies()
    if dependencies.ParseSourceStatRef then
        datasetId, slotId = dependencies.ParseSourceStatRef(slotRef)
    end
    if not datasetId or not slotId then
        return nil, nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
    local itemSlots = dataset and dataset.itemSlots or nil
    if type(itemSlots) ~= "table" then
        return nil, dataset
    end

    for index = 1, #itemSlots do
        local itemSlot = itemSlots[index]
        if itemSlot and itemSlot.id == slotId then
            return itemSlot, dataset
        end
    end

    return nil, dataset
end

function Equipment.ResolveSlotKeyFromRef(slotRef)
    local itemSlot = Equipment.ResolveSlotDefinition(slotRef)
    if not itemSlot then
        return nil
    end

    local source = itemSlot.name
    if source == nil or source == "" then
        source = itemSlot.id
    end

    return Equipment.NormalizeSlotKey(source)
end

function Equipment.ResolveItemDefinition(itemRef)
    if type(itemRef) ~= "string" or itemRef == "" then
        return nil, nil
    end

    local datasetId, itemId = nil, nil
    local dependencies = getDependencies()
    if dependencies.ParseSourceStatRef then
        datasetId, itemId = dependencies.ParseSourceStatRef(itemRef)
    end
    if not datasetId or not itemId then
        return nil, nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
    local items = dataset and dataset.items or nil
    if type(items) ~= "table" then
        return nil, dataset
    end

    for index = 1, #items do
        local item = items[index]
        if item and item.id == itemId then
            return item, dataset
        end
    end

    return nil, dataset
end

function Equipment.CanEquipItemInScope(scope, item)
    if normalizeSlotType(scope) ~= "character" or not isClassArmorWeightRestrictionEnabled() then
        return true
    end

    if type(item) ~= "table" then
        return true
    end

    local itemType = string.lower(ensureString(item.itemType))
    if itemType ~= "armor" and itemType ~= "weapon" then
        return true
    end

    local classRef = Database.GetProfileClassRef and Database.GetProfileClassRef() or nil
    if ensureString(classRef) == "" then
        return false, "class-required"
    end

    local registry = Addon.Internal and Addon.Internal.Registry or {}
    if type(registry.ResolveClassReference) ~= "function" then
        return false, "class-unavailable"
    end

    local _, class = registry:ResolveClassReference(classRef)
    if type(class) ~= "table" then
        return false, "class-unavailable"
    end

    if itemType == "weapon" then
        local weaponTypeRef = ensureString(item.weaponTypeRef)
        for index = 1, #(class.weaponTypeRefs or {}) do
            if ensureString(class.weaponTypeRefs[index]) == weaponTypeRef then
                return true
            end
        end
        return false, "weapon-type-restricted"
    end

    local armorWeight = normalizeArmorWeight(item.armorWeight)
    if armorWeight == "cosmetic" then
        return true
    end
    if armorWeight == "" then
        return false, "armor-weight-restricted"
    end

    for index = 1, #(class.armorWeights or {}) do
        if normalizeArmorWeight(class.armorWeights[index]) == armorWeight then
            return true
        end
    end

    return false, "armor-weight-restricted"
end

function Equipment.DoesItemFitSlot(item, slotKey)
    local normalizedSlotKey = Equipment.NormalizeSlotKey(slotKey)
    local matchKey = Equipment.NormalizeSlotMatchKey(normalizedSlotKey)
    local slotRefs = item and item.validSlotRefs or nil
    if type(slotRefs) ~= "table" or #slotRefs == 0 then
        return false, nil
    end

    for index = 1, #slotRefs do
        local slotRef = slotRefs[index]
        local resolvedSlotKey = Equipment.ResolveSlotKeyFromRef(slotRef)
        if resolvedSlotKey == normalizedSlotKey or Equipment.NormalizeSlotMatchKey(resolvedSlotKey) == matchKey then
            return true, slotRef
        end
    end

    return false, nil
end

function Equipment.DoesItemFitLayoutEntry(item, layoutEntry)
    if type(layoutEntry) ~= "table" then
        return false, nil
    end

    local layoutSlotRef = ensureString(layoutEntry.slotRef)
    if layoutSlotRef ~= "" and itemHasExactSlotRef(item, layoutSlotRef) then
        return true, layoutSlotRef
    end

    local layoutSlotKey = ensureString(layoutEntry.slotKey)
    if layoutSlotKey == "" then
        return false, nil
    end

    local slotRefs = item and item.validSlotRefs or nil
    if type(slotRefs) ~= "table" or #slotRefs == 0 then
        return false, nil
    end

    local normalizedSlotKey = Equipment.NormalizeSlotKey(layoutSlotKey)
    local matchKey = Equipment.NormalizeSlotMatchKey(normalizedSlotKey)
    for index = 1, #slotRefs do
        local slotRef = slotRefs[index]
        local resolvedSlotKey = Equipment.ResolveSlotKeyFromRef(slotRef)
        if resolvedSlotKey == normalizedSlotKey then
            return true, slotRef
        end
    end

    for index = 1, #slotRefs do
        local slotRef = slotRefs[index]
        local resolvedSlotKey = Equipment.ResolveSlotKeyFromRef(slotRef)
        if Equipment.NormalizeSlotMatchKey(resolvedSlotKey) == matchKey then
            return true, slotRef
        end
    end

    return false, nil
end

function Equipment.GetProfileEquipmentMapByScope(scope)
    if Database.ListProfileEquipmentByScope then
        return ensureTable(Database.ListProfileEquipmentByScope(scope))
    end

    local profile = Database.GetOrCreateActiveProfile and Database.GetOrCreateActiveProfile() or nil
    local fieldName = getScopeFieldName(scope)
    local equipment = profile and profile[fieldName] or nil
    return ensureTable(equipment)
end

function Equipment.GetProfileEquipmentMap()
    return Equipment.GetProfileEquipmentMapByScope("character")
end

function Equipment.GetProfileMountEquipmentMap()
    return Equipment.GetProfileEquipmentMapByScope("mount")
end

function Equipment.ListEquippedSlotsByScope(scope)
    local items = {}
    local equipment = Equipment.GetProfileEquipmentMapByScope(scope)

    for slotKey, entry in pairs(equipment) do
        items[#items + 1] = {
            slotKey = Equipment.NormalizeSlotKey(slotKey),
            entry = entry,
        }
    end

    table.sort(items, function(left, right)
        return tostring(left.slotKey or "") < tostring(right.slotKey or "")
    end)

    return items
end

function Equipment.ListEquippedSlots()
    return Equipment.ListEquippedSlotsByScope("character")
end

function Equipment.ListMountEquippedSlots()
    return Equipment.ListEquippedSlotsByScope("mount")
end

local function isDatasetActivated(datasetId)
    local registry = getRegistry()
    if type(registry.IsDatasetActivated) == "function" then
        return registry:IsDatasetActivated(datasetId) == true
    end
    if type(Database.IsDatasetActivated) == "function" then
        return Database.IsDatasetActivated(datasetId) == true
    end
    return false
end

local function getEquippedItemReference(entry)
    local itemRef = ensureString(entry and entry.itemRef)
    if itemRef ~= "" then
        return itemRef
    end

    local datasetId = ensureString(entry and entry.datasetId)
    local itemId = ensureString(entry and entry.itemId)
    if datasetId == "" or itemId == "" then
        return ""
    end

    return ("%s:%s"):format(datasetId, itemId)
end

local function buildItemSetProgress(itemSetRef, setDataset, itemSet, count, itemRefs, members)
    local unlockedBonuses = {}
    local nextRequiredPieces = nil
    local maxRequiredPieces = 0

    for index = 1, #(itemSet and itemSet.bonuses or {}) do
        local bonus = itemSet.bonuses[index]
        local requiredPieces = math.floor(tonumber(bonus and bonus.requiredPieces) or 0)
        if requiredPieces > maxRequiredPieces then
            maxRequiredPieces = requiredPieces
        end
        if requiredPieces > 0 and requiredPieces <= count then
            unlockedBonuses[#unlockedBonuses + 1] = bonus
        elseif requiredPieces > count and nextRequiredPieces == nil then
            nextRequiredPieces = requiredPieces
        end
    end

    return {
        itemSetRef = itemSetRef,
        dataset = setDataset,
        itemSet = itemSet,
        count = count,
        itemRefs = itemRefs or {},
        members = members or {},
        bonuses = itemSet and itemSet.bonuses or {},
        unlockedBonuses = unlockedBonuses,
        nextRequiredPieces = nextRequiredPieces,
        maxRequiredPieces = maxRequiredPieces,
    }
end

function Equipment.ListEquippedItemSetProgress()
    local progressByRef = {}
    local seenItemRefs = {}
    local equipped = Equipment.ListEquippedSlots()

    for index = 1, #equipped do
        local slot = equipped[index]
        local entry = slot and slot.entry or nil
        local itemRef = getEquippedItemReference(entry)
        if itemRef ~= "" and not seenItemRefs[itemRef] then
            local item, itemDataset = Equipment.ResolveItemDefinition(itemRef)
            local itemDatasetId = itemDataset and ensureString(itemDataset.id) or ""
            if item and itemDatasetId ~= ""
                and isDatasetActivated(itemDatasetId)
                and type(getRegistry().ResolveItemSetForItem) == "function"
            then
                local setDataset, itemSet = getRegistry():ResolveItemSetForItem(itemDatasetId, item)
                local setDatasetId = setDataset and ensureString(setDataset.id) or ""
                local setKey = itemSet and ensureString(itemSet.key) or ""
                if itemSet and setDatasetId ~= "" and setKey ~= "" and isDatasetActivated(setDatasetId) then
                    local itemSetRef = ("%s:%s"):format(setDatasetId, setKey)
                    local progress = progressByRef[itemSetRef]
                    if not progress then
                        progress = {
                            itemSetRef = itemSetRef,
                            dataset = setDataset,
                            itemSet = itemSet,
                            count = 0,
                            itemRefs = {},
                            members = {},
                        }
                        progressByRef[itemSetRef] = progress
                    end
                    progress.count = progress.count + 1
                    progress.itemRefs[#progress.itemRefs + 1] = itemRef
                    progress.members[#progress.members + 1] = {
                        itemRef = itemRef,
                        slotKey = slot.slotKey,
                        dataset = itemDataset,
                        item = item,
                    }
                end
            end
            seenItemRefs[itemRef] = true
        end
    end

    local progress = {}
    for itemSetRef, value in pairs(progressByRef) do
        progress[#progress + 1] = buildItemSetProgress(
            itemSetRef,
            value.dataset,
            value.itemSet,
            value.count,
            value.itemRefs,
            value.members
        )
    end
    table.sort(progress, function(left, right)
        return tostring(left.itemSetRef or "") < tostring(right.itemSetRef or "")
    end)
    return progress
end

function Equipment.GetEquippedItemSetProgress(itemSetRef, owningDatasetId)
    local setDataset, itemSet
    local registry = getRegistry()
    if type(registry.ResolveItemSetReference) == "function" then
        setDataset, itemSet = registry:ResolveItemSetReference(itemSetRef, owningDatasetId)
    end
    if not setDataset or not itemSet or not isDatasetActivated(setDataset.id) then
        return nil
    end

    local canonicalRef = ("%s:%s"):format(tostring(setDataset.id), tostring(itemSet.key))
    local progress = Equipment.ListEquippedItemSetProgress()
    for index = 1, #progress do
        if progress[index].itemSetRef == canonicalRef then
            return progress[index]
        end
    end

    return buildItemSetProgress(canonicalRef, setDataset, itemSet, 0, {}, {})
end

function Equipment.GetItemSetProgressForItem(itemRef, item, owningDatasetId)
    local resolvedItem = item
    local itemDataset = nil
    local resolvedItemRef = ensureString(itemRef)
    if not resolvedItem and resolvedItemRef ~= "" then
        resolvedItem, itemDataset = Equipment.ResolveItemDefinition(resolvedItemRef)
    elseif resolvedItem and owningDatasetId then
        itemDataset = Database.GetDatasetByID and Database.GetDatasetByID(owningDatasetId) or nil
    end
    if not resolvedItem then
        return nil
    end

    local itemDatasetId = ensureString(itemDataset and itemDataset.id or owningDatasetId)
    local registry = getRegistry()
    if itemDatasetId == "" or type(registry.ResolveItemSetForItem) ~= "function" then
        return nil
    end
    local setDataset, itemSet = registry:ResolveItemSetForItem(itemDatasetId, resolvedItem)
    if not setDataset or not itemSet then
        return nil
    end

    return Equipment.GetEquippedItemSetProgress(("%s:%s"):format(setDataset.id, itemSet.key))
end

function Equipment.GetEquippedItemSetBonuses()
    local stats = {}
    local skills = {}
    local progress = Equipment.ListEquippedItemSetProgress()

    for index = 1, #progress do
        local unlocked = progress[index].unlockedBonuses or {}
        for bonusIndex = 1, #unlocked do
            local bonus = unlocked[bonusIndex]
            for statIndex = 1, #(bonus and bonus.statBonuses or {}) do
                local statBonus = bonus.statBonuses[statIndex]
                local statRef = type(statBonus) == "table" and ensureString(statBonus.statRef) or ""
                local value = type(statBonus) == "table" and tonumber(statBonus.value) or 0
                local statDataset, statDefinition
                if statRef ~= "" and type(getRegistry().ResolveStatReference) == "function" then
                    statDataset, statDefinition = getRegistry():ResolveStatReference(statRef)
                end
                if statRef ~= "" and value ~= 0
                    and statDefinition
                    and statDataset
                    and isDatasetActivated(statDataset.id)
                then
                    stats[statRef] = (stats[statRef] or 0) + value
                end
            end
            for skillIndex = 1, #(bonus and bonus.skillBonuses or {}) do
                local skillBonus = bonus.skillBonuses[skillIndex]
                local skillRef = type(skillBonus) == "table" and ensureString(skillBonus.skillRef) or ""
                local value = type(skillBonus) == "table" and tonumber(skillBonus.value) or 0
                local skillDataset, skillDefinition
                if skillRef ~= "" and type(getRegistry().ResolveSkillReference) == "function" then
                    skillDataset, skillDefinition = getRegistry():ResolveSkillReference(skillRef)
                end
                if skillRef ~= "" and value ~= 0
                    and skillDefinition
                    and skillDataset
                    and isDatasetActivated(skillDataset.id)
                then
                    skills[skillRef] = (skills[skillRef] or 0) + value
                end
            end
        end
    end

    return {
        stats = stats,
        skills = skills,
    }
end

function Equipment.ListEquippedItemSetEquipmentBonuses()
    local bonuses = {}
    local progress = Equipment.ListEquippedItemSetProgress()

    for progressIndex = 1, #progress do
        local setProgress = progress[progressIndex]
        local unlocked = setProgress and setProgress.unlockedBonuses or {}
        for bonusIndex = 1, #unlocked do
            local bonus = unlocked[bonusIndex]
            local equipmentBonuses = bonus and bonus.equipmentBonuses or {}
            for equipmentIndex = 1, #equipmentBonuses do
                local payload = equipmentBonuses[equipmentIndex]
                if type(payload) == "table" then
                    bonuses[#bonuses + 1] = {
                        itemSetRef = setProgress.itemSetRef,
                        itemSet = setProgress.itemSet,
                        dataset = setProgress.dataset,
                        requiredPieces = bonus.requiredPieces,
                        bonusIndex = bonusIndex,
                        equipmentIndex = equipmentIndex,
                        payload = payload,
                    }
                end
            end
        end
    end

    return bonuses
end

function Equipment.GetEquippedEntryByScope(scope, slotKey)
    local normalizedSlotKey = Equipment.NormalizeSlotKey(slotKey)
    local equipment = Equipment.GetProfileEquipmentMapByScope(scope)
    return equipment[normalizedSlotKey]
end

function Equipment.GetEquippedEntry(slotKey)
    return Equipment.GetEquippedEntryByScope("character", slotKey)
end

function Equipment.GetMountEquippedEntry(slotKey)
    return Equipment.GetEquippedEntryByScope("mount", slotKey)
end

function Equipment.FindBestSlotForItemInScope(item, layout, scope)
    local canEquip = Equipment.CanEquipItemInScope(scope, item)
    if not canEquip then
        return nil, nil
    end

    local orderedEntries = layout and layout.entries or {}
    local exactMatches = {}
    local fallbackMatches = {}
    local layoutByRef = {}

    for index = 1, #orderedEntries do
        local layoutEntry = orderedEntries[index]
        local slotRef = layoutEntry and ensureString(layoutEntry.slotRef) or ""
        if slotRef ~= "" then
            layoutByRef[slotRef] = layoutEntry
        end
    end

    local slotRefs = item and item.validSlotRefs or nil
    if type(slotRefs) == "table" then
        for index = 1, #slotRefs do
            local slotRef = ensureString(slotRefs[index])
            local layoutEntry = layoutByRef[slotRef]
            local slotKey = layoutEntry and layoutEntry.slotKey or nil
            if slotKey and slotRef ~= "" then
                exactMatches[#exactMatches + 1] = {
                    slotKey = slotKey,
                    slotRef = slotRef,
                    occupied = Equipment.GetEquippedEntryByScope(scope, slotKey) ~= nil,
                }
            end
        end
    end

    for index = 1, #exactMatches do
        if not exactMatches[index].occupied then
            return exactMatches[index].slotKey, exactMatches[index].slotRef
        end
    end
    if #exactMatches > 0 then
        return exactMatches[1].slotKey, exactMatches[1].slotRef
    end

    for index = 1, #orderedEntries do
        local layoutEntry = orderedEntries[index]
        local slotKey = layoutEntry and layoutEntry.slotKey or nil
        local layoutSlotRef = layoutEntry and ensureString(layoutEntry.slotRef) or ""
        local fits, slotRef = Equipment.DoesItemFitLayoutEntry(item, layoutEntry)
        if fits and slotRef and not itemHasExactSlotRef(item, layoutSlotRef) then
            fallbackMatches[#fallbackMatches + 1] = {
                slotKey = slotKey,
                slotRef = slotRef,
                occupied = Equipment.GetEquippedEntryByScope(scope, slotKey) ~= nil,
            }
        end
    end

    for index = 1, #fallbackMatches do
        if not fallbackMatches[index].occupied then
            return fallbackMatches[index].slotKey, fallbackMatches[index].slotRef
        end
    end

    local first = fallbackMatches[1]
    return first and first.slotKey or nil, first and first.slotRef or nil
end

function Equipment.FindBestSlotForItem(item, layout)
    return Equipment.FindBestSlotForItemInScope(item, layout, "character")
end

function Equipment.EquipItemInScope(scope, slotKey, itemRef, modifications, slotRef, soulbound, itemTier)
    local normalizedSlotKey = Equipment.NormalizeSlotKey(slotKey)
    if normalizedSlotKey == "" or type(itemRef) ~= "string" or itemRef == "" then
        return nil, "invalid"
    end

    local normalizedTier, tierReason
    if type(ItemTier.Validate) == "function" then
        normalizedTier, tierReason = ItemTier.Validate(itemTier)
    else
        normalizedTier = itemTier or "normal"
    end
    if not normalizedTier then
        return nil, tierReason or "invalid-item-tier"
    end

    local item, dataset = Equipment.ResolveItemDefinition(itemRef)
    if not item then
        return nil, "missing-item"
    end

    local canEquip, restrictionReason = Equipment.CanEquipItemInScope(scope, item)
    if not canEquip then
        return nil, restrictionReason or "armor-weight-restricted"
    end

    local finalSlotRef = ensureString(slotRef)
    if finalSlotRef ~= "" then
        if not itemHasExactSlotRef(item, finalSlotRef) then
            return nil, "invalid-slot"
        end
    else
        local fits, resolvedSlotRef = Equipment.DoesItemFitSlot(item, normalizedSlotKey)
        if not fits or not resolvedSlotRef then
            return nil, "invalid-slot"
        end
        finalSlotRef = resolvedSlotRef
    end

    if finalSlotRef == "" then
        return nil, "invalid-slot"
    end

    local slotDefinition = Equipment.ResolveSlotDefinition(finalSlotRef)
    if slotDefinition and normalizeSlotType(slotDefinition.slotType) ~= normalizeSlotType(scope) then
        return nil, "invalid-slot"
    end

    local normalizedScope = normalizeSlotType(scope)
    local clearsOffHand = normalizedScope == "character"
        and normalizedSlotKey == "mainhand"
        and item.isTwoHanded == true
    local function persistEquipment()
        local entry = Database.SetProfileEquipmentSlotByScope and Database.SetProfileEquipmentSlotByScope(normalizedScope, normalizedSlotKey, {
            datasetId = dataset and dataset.id or "",
            itemId = item.id,
            itemRef = itemRef,
            itemTier = normalizedTier,
            slotRef = finalSlotRef,
            modifications = ensureTable(modifications),
            soulbound = soulbound == true,
        }) or nil

        local offHandCleared = false
        if entry ~= nil and clearsOffHand and Database.ClearProfileEquipmentSlotByScope then
            offHandCleared = Database.ClearProfileEquipmentSlotByScope("character", "offhand") == true
        end

        if entry ~= nil or offHandCleared then
            bumpProfileTooltipContextRevision()
        end
        return entry
    end

    if type(Runtime) ~= "table" or type(Runtime.RunTransaction) ~= "function" then
        error("Profile equipment mutation requires the Runtime transaction module.", 2)
    end

    return Runtime:RunTransaction(
        ("profile-%s-equipment"):format(normalizedScope),
        persistEquipment
    )
end

function Equipment.EquipItem(slotKey, itemRef, modifications, slotRef, soulbound, itemTier)
    return Equipment.EquipItemInScope("character", slotKey, itemRef, modifications, slotRef, soulbound, itemTier)
end

function Equipment.EquipMountItem(slotKey, itemRef, modifications, slotRef, soulbound, itemTier)
    return Equipment.EquipItemInScope("mount", slotKey, itemRef, modifications, slotRef, soulbound, itemTier)
end

function Equipment.UnequipItemInScope(scope, slotKey)
    local normalizedSlotKey = Equipment.NormalizeSlotKey(slotKey)
    if normalizedSlotKey == "" then
        return false
    end

    local normalizedScope = normalizeSlotType(scope)
    local function clearEquipment()
        local changed = Database.ClearProfileEquipmentSlotByScope and Database.ClearProfileEquipmentSlotByScope(normalizedScope, normalizedSlotKey) or false
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    if type(Runtime) ~= "table" or type(Runtime.RunTransaction) ~= "function" then
        error("Profile equipment mutation requires the Runtime transaction module.", 2)
    end

    return Runtime:RunTransaction(
        ("profile-%s-equipment"):format(normalizedScope),
        clearEquipment
    )
end

function Equipment.UnequipItem(slotKey)
    return Equipment.UnequipItemInScope("character", slotKey)
end

function Equipment.UnequipMountItem(slotKey)
    return Equipment.UnequipItemInScope("mount", slotKey)
end

function Equipment.ListEquipableItemsForScopeSlot(scope, slotKey)
    local items = {}
    local normalizedSlotKey = Equipment.NormalizeSlotKey(slotKey)
    local datasets = Database.ListDatasets and Database.ListDatasets() or {}
    local seen = {}
    local dependencies = getDependencies()
    local expectedScope = normalizeSlotType(scope)

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetItems = dataset and dataset.items or {}
        for itemIndex = 1, #datasetItems do
            local item = datasetItems[itemIndex]
            if item and item.id then
                local itemRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, item.id) or nil
                local fits, slotRef = Equipment.DoesItemFitSlot(item, normalizedSlotKey)
                local slotDefinition = slotRef and Equipment.ResolveSlotDefinition(slotRef) or nil
                local canEquip = Equipment.CanEquipItemInScope(expectedScope, item)
                if itemRef and fits and canEquip and slotRef and slotDefinition and normalizeSlotType(slotDefinition.slotType) == expectedScope and not seen[itemRef] then
                    seen[itemRef] = true
                    items[#items + 1] = {
                        itemRef = itemRef,
                        slotRef = slotRef,
                        dataset = dataset,
                        item = item,
                    }
                end
            end
        end
    end

    table.sort(items, function(left, right)
        local leftName = string.lower(tostring(left.item and left.item.name or left.itemRef or ""))
        local rightName = string.lower(tostring(right.item and right.item.name or right.itemRef or ""))
        if leftName == rightName then
            return tostring(left.itemRef or "") < tostring(right.itemRef or "")
        end
        return leftName < rightName
    end)

    return items
end

function Equipment.ListEquipableItemsForSlot(slotKey)
    return Equipment.ListEquipableItemsForScopeSlot("character", slotKey)
end

return Equipment
