local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile
local Equipment = Profile.Equipment or {}
Profile.Equipment = Equipment

local Database = Addon.Internal.Database or {}
local Definitions = Profile.Definitions or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}

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
        false
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

    if type(item) ~= "table" or string.lower(ensureString(item.itemType)) ~= "armor" then
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

    local armorWeight = normalizeArmorWeight(item.armorWeight)
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

function Equipment.EquipItemInScope(scope, slotKey, itemRef, modifications, slotRef, soulbound)
    local normalizedSlotKey = Equipment.NormalizeSlotKey(slotKey)
    if normalizedSlotKey == "" or type(itemRef) ~= "string" or itemRef == "" then
        return nil, "invalid"
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
    local function persistEquipment()
        local entry = Database.SetProfileEquipmentSlotByScope and Database.SetProfileEquipmentSlotByScope(normalizedScope, normalizedSlotKey, {
            datasetId = dataset and dataset.id or "",
            itemId = item.id,
            itemRef = itemRef,
            slotRef = finalSlotRef,
            modifications = ensureTable(modifications),
            soulbound = soulbound == true,
        }) or nil

        if entry ~= nil then
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

function Equipment.EquipItem(slotKey, itemRef, modifications, slotRef, soulbound)
    return Equipment.EquipItemInScope("character", slotKey, itemRef, modifications, slotRef, soulbound)
end

function Equipment.EquipMountItem(slotKey, itemRef, modifications, slotRef, soulbound)
    return Equipment.EquipItemInScope("mount", slotKey, itemRef, modifications, slotRef, soulbound)
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
