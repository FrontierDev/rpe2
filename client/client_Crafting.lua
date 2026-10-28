local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Crafting = Addon.Client.Crafting or {}

local Crafting = Addon.Client.Crafting
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local ItemTier = Addon.Internal and Addon.Internal.ItemTier or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Tasks = Addon.Internal and Addon.Internal.Tasks or {}
local Inventory = Addon.Client and Addon.Client.Inventory or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Debug = Addon.Debug or {}
local logCraftingInternal
local logConversionTrace
local CONVERSION_TRACE_LOGGING = false

local function captureCraftingError(errorValue)
    local message = tostring(errorValue)
    if type(debugstack) == "function" then
        return ("%s\n%s"):format(message, debugstack(2))
    end
    return message
end

local function logCraftingFailure(phase, recipeRef, errorValue, outputCommitted, completedCount)
    local message = captureCraftingError(errorValue)
    local formatted = (
        "Crafting diagnostic: recipeRef=%s phase=%s outputCommitted=%s completedCount=%d\n%s"
    ):format(
        tostring(recipeRef or ""),
        tostring(phase or "unknown"),
        outputCommitted == true and "true" or "false",
        math.max(0, math.floor(tonumber(completedCount) or 0)),
        message
    )
    if Debug and type(Debug.Error) == "function" then
        Debug.Error("%s", formatted)
    elseif Debug and type(Debug.Warn) == "function" then
        Debug.Warn("%s", formatted)
    elseif Debug and type(Debug.Internal) == "function" then
        Debug.Internal("%s", formatted)
    end
    return message
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function getTimingMilliseconds()
    if type(debugprofilestop) == "function" then
        return tonumber(debugprofilestop()) or 0
    end
    if type(GetTimePreciseSec) == "function" then
        return (tonumber(GetTimePreciseSec()) or 0) * 1000
    end
    return 0
end

local function getElapsedMilliseconds(startedAt)
    local started = tonumber(startedAt) or 0
    return math.max(0, getTimingMilliseconds() - started)
end

local function countTableKeys(values)
    local count = 0
    for _ in pairs(type(values) == "table" and values or {}) do
        count = count + 1
    end
    return count
end

local function normalizeQuantity(value, fallback)
    return math.max(0, math.floor(tonumber(value) or fallback or 0))
end

local function parseItemRef(itemRef)
    local datasetId, itemId = ensureString(itemRef):match("^([^:]+):(.+)$")
    return datasetId, itemId
end

local function resolveItemDefinition(itemRef)
    if not (Registry and Registry.ResolveItemReference) then
        return nil
    end

    local _, item = Registry:ResolveItemReference(itemRef)
    return item
end

local function resolveItemName(itemRef)
    local item = resolveItemDefinition(itemRef)
    if item and ensureString(item.name) ~= "" then
        return ensureString(item.name)
    end

    return Registry.ResolveItemName and Registry:ResolveItemName(itemRef) or ensureString(itemRef)
end

local function resolveSkillName(skillRef)
    return Registry.ResolveSkillName and Registry:ResolveSkillName(skillRef) or ensureString(skillRef)
end

local function titleCaseWords(text)
    local normalized = ensureString(text):gsub("_", " "):gsub("%s+", " ")
    return (normalized:gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end))
end

local function deriveRecipeCategoryFromItem(item)
    if type(item) ~= "table" then
        return "General"
    end

    local itemType = tostring(item.itemType or "none")
    if itemType == "armor" then
        local armorWeight = tostring(item.armorWeight or "")
        if armorWeight == "shield" then
            return "Shield"
        end
        if armorWeight ~= "" and armorWeight ~= "cosmetic" and armorWeight ~= "none" then
            return titleCaseWords(armorWeight) .. " Armor"
        end
        return "Armor"
    end
    if itemType == "weapon" then
        local weaponTypeName = Registry.ResolveWeaponTypeName and Registry:ResolveWeaponTypeName(item.weaponTypeRef) or ""
        if weaponTypeName ~= "" and weaponTypeName ~= ensureString(item.weaponTypeRef) then
            return weaponTypeName
        end
        return "Weapon"
    end
    if itemType == "modification" then
        local modificationKind = tostring(item.modificationKind or "generic")
        if modificationKind == "gem" then
            return "Gem"
        end
        if modificationKind == "enchant" then
            return "Enchantment"
        end
        return "Modification"
    end
    if itemType == "consumable" then
        local consumableType = tostring(item.consumableType or "")
        if consumableType == "elixir" then
            return "Elixir"
        end
        if consumableType ~= "" then
            return titleCaseWords(consumableType)
        end
        return "Consumable"
    end
    if itemType == "material" then
        return "Material"
    end

    return titleCaseWords(itemType ~= "" and itemType or "General")
end

local function getResolvedSkillRow(skillRef)
    return Profile.GetResolvedSkillRow and Profile.GetResolvedSkillRow(skillRef) or nil
end

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function getCurrentProfileToken()
    if type(Database.GetActiveProfile) == "function" then
        local profile = Database.GetActiveProfile()
        local characterKey = ensureString(profile and profile.characterKey)
        if characterKey ~= "" then
            return characterKey
        end
    end

    return ""
end

local function getCurrentCopperAmount()
    if Profile.GetCurrencyAmount then
        return math.max(0, tonumber(Profile.GetCurrencyAmount("copper")) or 0)
    end
    if Database.GetProfileCurrencyAmount then
        return math.max(0, tonumber(Database.GetProfileCurrencyAmount("copper")) or 0)
    end
    return 0
end

local function getSkillLevelAndCap(skillRef)
    local row = getResolvedSkillRow(skillRef)
    return math.max(0, tonumber(row and row.value) or 0), math.max(0, tonumber(row and row.maxValue) or 0), row
end

local function getRecipeSkillUpInfo(detail)
    local skillLevel = math.max(0, tonumber(detail and detail.skillLevel) or 0)
    local requiredLevel = math.max(0, tonumber(detail and detail.requiredSkillLevel) or 0)
    local skillCap = math.max(0, tonumber(detail and detail.skillCap) or 0)
    local delta = skillLevel - requiredLevel
    local chance
    local band
    local reason

    if detail and (detail.isKnown == false or detail.isSkillMet == false or delta < 0) then
        chance = 0
        band = "unavailable"
        reason = detail.isKnown == false and "unlearned" or "skill-locked"
    elseif skillCap > 0 and skillLevel >= skillCap then
        chance = 0
        band = "capped"
        reason = "capped"
    elseif delta <= 10 then
        chance = 100
        band = "orange"
    elseif delta <= 20 then
        chance = 75
        band = "yellow"
    elseif delta <= 25 then
        chance = 35
        band = "green"
    else
        chance = 0
        band = "grey"
        reason = "trivial"
    end

    local result = {
        chance = chance,
        band = band,
        reason = reason,
        skillLevel = skillLevel,
        requiredSkillLevel = requiredLevel,
        skillCap = skillCap,
        delta = delta,
    }
    logCraftingInternal(
        "Crafting skill-up calculation recipe=%s required=%d current=%d cap=%d delta=%d chance=%d band=%s reason=%s",
        tostring(detail and detail.recipeRef or ""),
        requiredLevel,
        skillLevel,
        skillCap,
        delta,
        chance,
        band,
        tostring(reason or "eligible")
    )
    return result
end

local function buildRecipeSummaryLiveContext(skillRef, options)
    local normalizedSkillRef = ensureString(skillRef)
    local values = type(options) == "table" and options or {}
    local skillRow = values.skillRow
    if type(skillRow) ~= "table" or tostring(skillRow.ref or "") ~= normalizedSkillRef then
        skillRow = getResolvedSkillRow(normalizedSkillRef)
    end

    return {
        skillRef = normalizedSkillRef,
        skillName = ensureString(skillRow and skillRow.name) ~= "" and ensureString(skillRow and skillRow.name) or resolveSkillName(normalizedSkillRef),
        skillLevel = math.max(0, tonumber(skillRow and skillRow.value) or 0),
        skillCap = math.max(0, tonumber(skillRow and skillRow.maxValue) or 0),
        copperAmount = getCurrentCopperAmount(),
        knownOnly = values.knownOnly == true,
        trainerOnly = values.trainerOnly == true,
    }
end

local function normalizeLearnMode(value)
    local mode = string.lower(ensureString(value))
    if mode == "always_learned" or mode == "trainer" or mode == "book" or mode == "unavailable" then
        return mode
    end

    return "trainer"
end

local function isRecipeKnown(recipeRef)
    return Profile.IsRecipeKnown and Profile.IsRecipeKnown(recipeRef) == true or false
end

local function calculateTrainerCostCopper(requiredSkillLevel)
    local level = math.max(0, math.floor(tonumber(requiredSkillLevel) or 0))
    return math.floor(75 + (level * 28) + (level * level * 1.6))
end

local getQualityColor

local function compareRecipeName(left, right)
    return string.lower(ensureString(left)) < string.lower(ensureString(right))
end

local function compareCraftingRecipeOrder(left, right)
    local leftCategory = string.lower(ensureString(left and left.category))
    local rightCategory = string.lower(ensureString(right and right.category))
    if leftCategory ~= rightCategory then
        return leftCategory < rightCategory
    end

    local leftLevel = tonumber(left and left.requiredSkillLevel) or 0
    local rightLevel = tonumber(right and right.requiredSkillLevel) or 0
    if leftLevel ~= rightLevel then
        return leftLevel < rightLevel
    end

    return compareRecipeName(left and left.name, right and right.name)
end

local function compareTrainerRecipeOrder(left, right)
    local leftLevel = tonumber(left and left.requiredSkillLevel) or 0
    local rightLevel = tonumber(right and right.requiredSkillLevel) or 0
    if leftLevel ~= rightLevel then
        return leftLevel < rightLevel
    end

    return compareRecipeName(left and left.name, right and right.name)
end

local function buildRecipeIndexMeta(entry)
    local recipe = entry and entry.recipe or nil
    local outputItem = resolveItemDefinition(recipe and recipe.output and recipe.output.itemRef or nil)
    local requiredSkillLevel = math.max(0, tonumber(recipe and recipe.requiredSkillLevel) or 0)
    local trainerCostCopper = calculateTrainerCostCopper(requiredSkillLevel)
    if type(recipe) == "table" then
        recipe.trainerCostCopper = trainerCostCopper
    end
    return {
        recipeRef = entry and entry.ref or "",
        category = deriveRecipeCategoryFromItem(outputItem),
        name = outputItem and ensureString(outputItem.name) ~= "" and ensureString(outputItem.name) or resolveItemName(recipe and recipe.output and recipe.output.itemRef or nil),
        requiredSkillLevel = requiredSkillLevel,
        learnMode = normalizeLearnMode(recipe and recipe.learnMode),
        skillRef = ensureString(recipe and recipe.skillRef),
        skillName = resolveSkillName(recipe and recipe.skillRef),
        trainerCostCopper = trainerCostCopper,
        trainerCostText = Common.FormatCopper and Common:FormatCopper(trainerCostCopper) or tostring(trainerCostCopper),
        outputItemRef = recipe and recipe.output and recipe.output.itemRef or nil,
        outputIcon = outputItem and ensureString(outputItem.icon) or "Interface\\Icons\\INV_Misc_QuestionMark",
        outputName = outputItem and ensureString(outputItem.name) ~= "" and ensureString(outputItem.name) or resolveItemName(recipe and recipe.output and recipe.output.itemRef or nil),
        outputMinQuantity = math.max(1, tonumber(recipe and recipe.output and recipe.output.minQuantity) or 1),
        outputMaxQuantity = math.max(1, tonumber(recipe and recipe.output and recipe.output.maxQuantity) or 1),
        outputQualityColor = getQualityColor(outputItem),
    }
end

local function buildRecipeSkillIndex(targetRevision)
    local revision = math.max(0, math.floor(tonumber(targetRevision) or getConfigurationRevision()))
    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
    local recipes = {}
    local recipeIndexByRef = {}
    local orderedBucketsBySkill = {}
    local trainerBucketsBySkill = {}
    local alwaysLearnedRefsBySkill = {}
    local skillRefByRecipeRef = {}
    local orderRankByRecipeRef = {}
    local trainerOrderRankByRecipeRef = {}
    local staticRecipeRowsByRef = {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = ensureString(dataset and dataset.id)
        for recipeIndex = 1, #(dataset and dataset.recipes or {}) do
            local recipe = dataset.recipes[recipeIndex]
            if datasetId ~= "" and recipe and recipe.id then
                local entry = {
                    ref = ("%s:%s"):format(datasetId, recipe.id),
                    dataset = dataset,
                    recipe = recipe,
                }
                recipes[#recipes + 1] = entry
                recipeIndexByRef[entry.ref] = entry

                local meta = buildRecipeIndexMeta(entry)
                skillRefByRecipeRef[entry.ref] = meta.skillRef
                staticRecipeRowsByRef[entry.ref] = meta
                if meta.skillRef ~= "" then
                    orderedBucketsBySkill[meta.skillRef] = orderedBucketsBySkill[meta.skillRef] or {}
                    orderedBucketsBySkill[meta.skillRef][#orderedBucketsBySkill[meta.skillRef] + 1] = meta

                    if meta.learnMode == "trainer" then
                        trainerBucketsBySkill[meta.skillRef] = trainerBucketsBySkill[meta.skillRef] or {}
                        trainerBucketsBySkill[meta.skillRef][#trainerBucketsBySkill[meta.skillRef] + 1] = meta
                    elseif meta.learnMode == "always_learned" then
                        alwaysLearnedRefsBySkill[meta.skillRef] = alwaysLearnedRefsBySkill[meta.skillRef] or {}
                        alwaysLearnedRefsBySkill[meta.skillRef][#alwaysLearnedRefsBySkill[meta.skillRef] + 1] = entry.ref
                    end
                end
            end
        end
    end

    local orderedRecipeRefsBySkill = {}
    for skillRef, metas in pairs(orderedBucketsBySkill) do
        table.sort(metas, compareCraftingRecipeOrder)
        orderedRecipeRefsBySkill[skillRef] = {}
        for index = 1, #metas do
            local recipeRef = metas[index].recipeRef
            orderedRecipeRefsBySkill[skillRef][index] = recipeRef
            orderRankByRecipeRef[recipeRef] = index
        end
    end

    local trainerRecipeRefsBySkill = {}
    for skillRef, metas in pairs(trainerBucketsBySkill) do
        table.sort(metas, compareTrainerRecipeOrder)
        trainerRecipeRefsBySkill[skillRef] = {}
        for index = 1, #metas do
            local recipeRef = metas[index].recipeRef
            trainerRecipeRefsBySkill[skillRef][index] = recipeRef
            trainerOrderRankByRecipeRef[recipeRef] = index
        end
    end

    return {
        revision = revision,
        recipes = recipes,
        recipeIndexByRef = recipeIndexByRef,
        orderedRecipeRefsBySkill = orderedRecipeRefsBySkill,
        trainerRecipeRefsBySkill = trainerRecipeRefsBySkill,
        alwaysLearnedRefsBySkill = alwaysLearnedRefsBySkill,
        skillRefByRecipeRef = skillRefByRecipeRef,
        orderRankByRecipeRef = orderRankByRecipeRef,
        trainerOrderRankByRecipeRef = trainerOrderRankByRecipeRef,
        staticRecipeRowsByRef = staticRecipeRowsByRef,
    }
end

getQualityColor = function(item)
    local qualityKey = type(item) == "table" and tostring(item.quality or "common") or "common"
    if type(ITEM_QUALITY_COLORS) == "table" and ITEM_QUALITY_COLORS[qualityKey] then
        local color = ITEM_QUALITY_COLORS[qualityKey]
        return { r = color.r or 1, g = color.g or 1, b = color.b or 1, a = 1 }
    end

    local lookup = {
        poor = { r = 0.62, g = 0.62, b = 0.62, a = 1 },
        common = { r = 1, g = 1, b = 1, a = 1 },
        uncommon = { r = 0.12, g = 1, b = 0, a = 1 },
        rare = { r = 0, g = 0.44, b = 0.87, a = 1 },
        epic = { r = 0.64, g = 0.21, b = 0.93, a = 1 },
        legendary = { r = 1, g = 0.5, b = 0, a = 1 },
    }
    return lookup[qualityKey] or lookup.common
end

local function normalizeRecipeItemTier(value)
    if type(ItemTier.Validate) == "function" then
        return ItemTier.Validate(value)
    end
    return value or "normal"
end

local function inventoryCountKey(itemRef, itemTier)
    return tostring(itemRef or "") .. "\0" .. tostring(normalizeRecipeItemTier(itemTier) or "normal")
end

local function countInventoryItem(itemRef, itemTier)
    local datasetId, itemId = parseItemRef(itemRef)
    if datasetId == nil or itemId == nil then
        return 0
    end

    local total = 0
    local items = Inventory.GetItems and Inventory.GetItems() or {}
    for index = 1, #items do
        local record = items[index]
        if tostring(record and record.dataset or "") == datasetId and tostring(record and record.id or "") == itemId
            and normalizeRecipeItemTier(record and record.itemTier) == normalizeRecipeItemTier(itemTier)
        then
            total = total + math.max(1, tonumber(record and record.quantity) or 1)
        end
    end

    return total
end

local function findInventorySlotForItemRef(itemRef, itemTier)
    local datasetId, itemId = parseItemRef(itemRef)
    if datasetId == nil or itemId == nil then
        return nil, nil
    end

    local items = Inventory.GetItems and Inventory.GetItems() or {}
    for index = 1, #items do
        local record = items[index]
        if tostring(record and record.dataset or "") == datasetId and tostring(record and record.id or "") == itemId
            and normalizeRecipeItemTier(record and record.itemTier) == normalizeRecipeItemTier(itemTier)
        then
            return index, record
        end
    end

    return nil, nil
end

local function removeInventoryItemCount(itemRef, quantity, itemTier)
    local remaining = math.max(1, tonumber(quantity) or 1)
    local removedTotal = 0
    while remaining > 0 do
        local slotIndex, record = findInventorySlotForItemRef(itemRef, itemTier)
        if not slotIndex or not record or not Inventory.RemoveItem then
            return false, "missing-item", removedTotal
        end

        local stackQuantity = math.max(1, tonumber(record.quantity) or 1)
        local removeQuantity = math.min(stackQuantity, remaining)
        local removed, removeError = Inventory.RemoveItem(slotIndex, removeQuantity)
        if not removed then
            return false, removeError or "remove-failed", removedTotal
        end

        local removedQuantity = type(removed) == "table" and removed.quantity or nil
        removedTotal = removedTotal + math.max(0, tonumber(removedQuantity) or removeQuantity)
        remaining = remaining - removeQuantity
    end

    return true, nil, removedTotal
end

local function getBagSlotCount(bag)
    if type(C_Container) == "table" and type(C_Container.GetContainerNumSlots) == "function" then
        return C_Container.GetContainerNumSlots(bag)
    end
    if GetContainerNumSlots then
        return GetContainerNumSlots(bag)
    end
    return 0
end

local function getContainerItemInfo(bag, slot)
    if type(C_Container) == "table" and type(C_Container.GetContainerItemInfo) == "function" then
        return C_Container.GetContainerItemInfo(bag, slot)
    end
    if GetContainerItemInfo then
        local _, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
        if not link then
            return nil
        end
        return {
            stackCount = count or 1,
            hyperlink = link,
            itemID = tonumber(link:match("item:(%d+)")),
        }
    end
    return nil
end

local function getBagItemName(info)
    if not info then
        return nil
    end
    if info.hyperlink then
        local name = info.hyperlink:match("%[(.-)%]")
        if name and name ~= "" then
            return name
        end
    end
    if info.itemID and type(C_Item) == "table" and type(C_Item.GetItemInfo) == "function" then
        local name = C_Item.GetItemInfo(info.itemID)
        if name and name ~= "" then
            return name
        end
    end
    if info.itemID and GetItemInfo then
        local name = GetItemInfo(info.itemID)
        if name and name ~= "" then
            return name
        end
    end
    return nil
end

local function scanBagItemByName(itemName)
    local targetName = ensureString(itemName)
    if targetName == "" then
        return 0, {}
    end

    local total = 0
    local matchedSlots = {}
    for bag = 0, 5 do
        local slotCount = getBagSlotCount(bag)
        for slot = 1, slotCount do
            local info = getContainerItemInfo(bag, slot)
            if info and getBagItemName(info) == targetName then
                local stackCount = math.max(1, tonumber(info.stackCount) or 1)
                total = total + stackCount
                matchedSlots[#matchedSlots + 1] = {
                    bag = bag,
                    slot = slot,
                    itemID = info.itemID,
                    itemName = targetName,
                    stackCount = stackCount,
                    hyperlink = info.hyperlink,
                }
            end
        end
    end

    return total, matchedSlots
end

local function consumeBagItemCountAtSlot(slotInfo, desiredCount)
    local cursorTypeBefore = GetCursorInfo and GetCursorInfo() or nil
    if cursorTypeBefore then
        logConversionTrace(
            "Material conversion failed before consume: cursor busy for bag=%s slot=%s",
            tostring(slotInfo and slotInfo.bag),
            tostring(slotInfo and slotInfo.slot)
        )
        return false, "cursor-busy"
    end

    local bag = tonumber(slotInfo and slotInfo.bag) or -1
    local slot = tonumber(slotInfo and slotInfo.slot) or -1
    if bag < 0 or slot < 1 then
        logConversionTrace(
            "Material conversion failed: invalid slot bag=%s slot=%s",
            tostring(slotInfo and slotInfo.bag),
            tostring(slotInfo and slotInfo.slot)
        )
        return false, "invalid-slot"
    end

    local info = getContainerItemInfo(bag, slot)
    if not info then
        logConversionTrace("Material conversion failed: missing item at bag=%d slot=%d", bag, slot)
        return false, "missing-item"
    end

    local itemName = getBagItemName(info)
    local expectedName = ensureString(slotInfo and slotInfo.itemName)
    if expectedName ~= "" and itemName ~= expectedName then
        logConversionTrace(
            "Material conversion failed: slot changed at bag=%d slot=%d expected=%s actual=%s",
            bag,
            slot,
            expectedName,
            tostring(itemName or "")
        )
        return false, "slot-changed"
    end

    local stackCount = math.max(1, tonumber(info.stackCount) or 1)
    local consumeCount = math.max(1, math.floor(tonumber(desiredCount) or 1))
    consumeCount = math.min(stackCount, consumeCount)
    logConversionTrace(
        "Material conversion consume attempt: bag=%d slot=%d item=%s stack=%d consume=%d",
        bag,
        slot,
        tostring(itemName or expectedName or ""),
        stackCount,
        consumeCount
    )
    if consumeCount < stackCount then
        if type(C_Container) == "table" and type(C_Container.SplitContainerItem) == "function" then
            logConversionTrace("Material conversion calling C_Container.SplitContainerItem(%d, %d, %d)", bag, slot, consumeCount)
            C_Container.SplitContainerItem(bag, slot, consumeCount)
        elseif SplitContainerItem then
            logConversionTrace("Material conversion calling SplitContainerItem(%d, %d, %d)", bag, slot, consumeCount)
            SplitContainerItem(bag, slot, consumeCount)
        else
            logCraftingInternal("Material conversion failed: no split function available for bag=%d slot=%d", bag, slot)
            return false, "split-unavailable"
        end
    elseif type(C_Container) == "table" and type(C_Container.PickupContainerItem) == "function" then
        logConversionTrace("Material conversion calling C_Container.PickupContainerItem(%d, %d)", bag, slot)
        C_Container.PickupContainerItem(bag, slot)
    elseif PickupContainerItem then
        logConversionTrace("Material conversion calling PickupContainerItem(%d, %d)", bag, slot)
        PickupContainerItem(bag, slot)
    else
        logCraftingInternal("Material conversion failed: no pickup function available for bag=%d slot=%d", bag, slot)
        return false, "pickup-unavailable"
    end

    local cursorType, cursorItemId = GetCursorInfo()
    logConversionTrace(
        "Material conversion post-pickup cursor: cursorType=%s cursorItemId=%s expectedItemId=%s",
        tostring(cursorType),
        tostring(cursorItemId),
        tostring(tonumber(slotInfo and slotInfo.itemID) or tonumber(info.itemID) or nil)
    )
    local expectedItemId = tonumber(slotInfo and slotInfo.itemID) or tonumber(info.itemID) or nil
    if cursorType ~= "item" or (expectedItemId and cursorItemId and tonumber(cursorItemId) ~= expectedItemId) then
        logCraftingInternal(
            "Material conversion failed after pickup: cursorType=%s cursorItemId=%s expectedItemId=%s",
            tostring(cursorType),
            tostring(cursorItemId),
            tostring(expectedItemId)
        )
        if ClearCursor then
            ClearCursor()
        end
        return false, "cursor-mismatch"
    end

    if DeleteCursorItem then
        DeleteCursorItem()

        local cursorTypeAfterDelete = GetCursorInfo and GetCursorInfo() or nil
        if cursorTypeAfterDelete then
            if ClearCursor then
                ClearCursor()
            end
            logCraftingInternal(
                "Material conversion failed after delete: cursor remained occupied for bag=%d slot=%d item=%s",
                bag,
                slot,
                tostring(itemName or expectedName or "")
            )
            return false, "cursor-not-cleared"
        end

        logConversionTrace(
            "Material conversion deleted WoW item: bag=%d slot=%d item=%s quantity=%d",
            bag,
            slot,
            tostring(itemName or expectedName or ""),
            consumeCount
        )
        return true, consumeCount
    end

    if ClearCursor then
        ClearCursor()
    end
    logCraftingInternal("Material conversion failed: DeleteCursorItem unavailable")
    return false, "delete-unavailable"
end

local function deleteBagItemCountByName(itemName, desiredCount)
    local remaining = math.max(1, math.floor(tonumber(desiredCount) or 1))
    local _, matchedSlots = scanBagItemByName(itemName)
    if not matchedSlots or #matchedSlots == 0 then
        logConversionTrace("Material conversion name scan found no slots for item=%s", tostring(itemName or ""))
        return 0, "missing-item"
    end

    local deletedCount = 0
    for index = 1, #matchedSlots do
        if remaining <= 0 then
            break
        end

        local slotInfo = matchedSlots[index]
        local stackCount = math.max(1, tonumber(slotInfo.stackCount) or 1)
        local chunkCount = math.min(stackCount, remaining)
        logConversionTrace(
            "Material conversion consuming name scan slot: item=%s bag=%d slot=%d chunk=%d stack=%d",
            tostring(itemName or ""),
            tonumber(slotInfo.bag) or -1,
            tonumber(slotInfo.slot) or -1,
            chunkCount,
            stackCount
        )
        local ok, consumedOrReason = consumeBagItemCountAtSlot(slotInfo, chunkCount)
        if not ok then
            return deletedCount, consumedOrReason or "consume-failed"
        end

        local consumedCount = math.max(1, math.floor(tonumber(consumedOrReason) or chunkCount))
        deletedCount = deletedCount + consumedCount
        remaining = remaining - consumedCount
    end

    if deletedCount <= 0 then
        return 0, "missing-item"
    end

    if remaining > 0 then
        return deletedCount, "insufficient-items"
    end

    return deletedCount
end

local function refreshVisibleProfileWindow()
    local windowController = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    if not (windowController and windowController.Get) then
        return false
    end

    local instance = windowController:Get()
    if instance and instance.RefreshVisible then
        instance:RefreshVisible()
        return true
    end
    return false
end

logCraftingInternal = function(message, ...)
    if not Debug or type(Debug.Internal) ~= "function"
        or (type(Debug.IsLevelEnabled) == "function" and not Debug.IsLevelEnabled("internal"))
    then
        return
    end
    Debug.Internal(message, ...)
end

logConversionTrace = function(message, ...)
    if CONVERSION_TRACE_LOGGING then
        logCraftingInternal(message, ...)
    end
end

local function rollQuantity(minimum, maximum)
    local minValue = math.max(1, tonumber(minimum) or 1)
    local maxValue = math.max(minValue, tonumber(maximum) or minValue)
    if minValue == maxValue then
        return minValue
    end

    return math.random(minValue, maxValue)
end

Crafting.State = Crafting.State or {
    recipes = nil,
    revision = -1,
    recipeIndexByRef = nil,
    recipesBySkill = nil,
    knownOrderedRecipeRefCache = {},
    orderedRecipeRefCache = {},
    recipeOrderKeyCache = {},
    summaryCache = {},
    detailCache = {},
    listCache = {},
    materialDefinitionCache = {},
    inventoryCountCache = {},
    inventoryCountRevision = -1,
    inventoryRevision = 0,
    pendingDetailPrimes = {},
    queue = {},
    active = nil,
    nextJobId = 0,
    queueEpoch = 0,
    queueTask = nil,
    profileKey = nil,
    status = "idle",
    listeners = {},
    nextListenerId = 0,
    lastError = "",
    lastWarning = "",
    lastOutcome = nil,
    suppressInventoryRefresh = false,
}

function Crafting:RegisterListener(listener)
    if type(listener) ~= "function" then
        return nil
    end

    local state = self.State
    state.nextListenerId = (tonumber(state.nextListenerId) or 0) + 1
    state.listeners[state.nextListenerId] = listener
    return state.nextListenerId
end

function Crafting:UnregisterListener(listenerId)
    if not tonumber(listenerId) then
        return false
    end

    self.State.listeners[tonumber(listenerId)] = nil
    return true
end

function Crafting:RecordPostCommitWarning(phase, recipeRef, errorValue, completedCount, outputCommitted)
    local warningText = outputCommitted == false
        and ("Crafting callback %s failed. See the debug log for details."):format(tostring(phase or "unknown"))
        or ("Craft completed, but %s failed. See the debug log for details."):format(tostring(phase or "ancillary work"))
    self.State.lastWarning = warningText
    logCraftingFailure(phase, recipeRef, errorValue, outputCommitted ~= false, completedCount)
    return warningText
end

function Crafting:BuildCraftOutcome(job, status)
    if type(job) ~= "table" then
        return nil
    end

    local totalCount = math.max(0, math.floor(tonumber(job.totalCount) or 0))
    local completedCount = math.max(0, math.floor(tonumber(job.completedCount) or 0))
    return {
        recipeRef = job.recipeRef,
        totalCount = totalCount,
        completedCount = completedCount,
        remainingCount = math.max(0, totalCount - completedCount),
        status = ensureString(status or "complete"),
    }
end

function Crafting:RebuildRecipeSkillIndex(targetRevision)
    Addon.Internal = Addon.Internal or {}
    local startedAt = getTimingMilliseconds()
    local built = buildRecipeSkillIndex(targetRevision)
    Addon.Internal.RecipeSkillIndex = built
    logCraftingInternal(
        "Crafting: RebuildRecipeSkillIndex revision=%d recipes=%d skills=%d trainerSkills=%d took=%.2fms",
        tonumber(built and built.revision) or 0,
        #(built and built.recipes or {}),
        countTableKeys(built and built.orderedRecipeRefsBySkill),
        countTableKeys(built and built.trainerRecipeRefsBySkill),
        getElapsedMilliseconds(startedAt)
    )
    return built
end

function Crafting:GetRecipeSkillIndex(targetRevision)
    Addon.Internal = Addon.Internal or {}
    local revision = math.max(0, math.floor(tonumber(targetRevision) or getConfigurationRevision()))
    local cached = Addon.Internal.RecipeSkillIndex
    if type(cached) == "table" and tonumber(cached.revision) == revision then
        return cached
    end

    return self:RebuildRecipeSkillIndex(revision)
end

function Crafting:NotifyChanged(reason)
    local state = self.State
    local changeReason = ensureString(reason)
    if changeReason == "inventory-change"
        or changeReason == "craft-complete"
        or changeReason == "craft-progress"
        or changeReason == "craft-blocked"
        or changeReason == "convert-complete"
    then
        state.inventoryRevision = math.max(0, tonumber(state.inventoryRevision) or 0) + 1
        state.detailCache = {}
        state.inventoryCountCache = {}
        state.inventoryCountRevision = -1
        state.pendingDetailPrimes = {}
    end
    if changeReason == "skill-gain" then
        state.summaryCache = {}
        state.detailCache = {}
        state.pendingDetailPrimes = {}
    end
    if changeReason == "trainer-learned" then
        state.knownOrderedRecipeRefCache = {}
        state.orderedRecipeRefCache = {}
        state.recipeOrderKeyCache = {}
        state.listCache = {}
        state.summaryCache = {}
        state.detailCache = {}
        state.pendingDetailPrimes = {}
    end

    local payload = self:GetState()
    payload.reason = reason or "update"
    local outcome = payload.lastOutcome
    local recipeRef = payload.active and payload.active.recipeRef or outcome and outcome.recipeRef
    local completedCount = payload.active and payload.active.completedCount or outcome and outcome.completedCount or 0
    local outputCommitted = changeReason == "skill-gain"
        or changeReason == "craft-progress"
        or changeReason == "craft-complete"
        or outcome ~= nil
    for _, listener in pairs(self.State.listeners or {}) do
        local ok, errorValue = xpcall(function()
            listener(payload)
        end, captureCraftingError)
        if not ok then
            self:RecordPostCommitWarning("crafting listener", recipeRef, errorValue, completedCount, outputCommitted)
        end
    end
    local refreshOk, refreshError = xpcall(refreshVisibleProfileWindow, captureCraftingError)
    if not refreshOk then
        self:RecordPostCommitWarning("UI refresh", recipeRef, refreshError, completedCount, outputCommitted)
    end
end

function Crafting:GetState()
    local state = self.State
    if state.profileKey ~= nil and state.profileKey ~= getCurrentProfileToken() then
        if not self:CancelCrafting("profile-changed") then
            state.profileKey = nil
        end
        state = self.State
    end

    local queue = {}
    local queuedCount = 0
    for index = 1, #(state.queue or {}) do
        local job = state.queue[index]
        local remainingCount = math.max(0, tonumber(job and job.remainingCount) or 0)
        queuedCount = queuedCount + remainingCount
        queue[#queue + 1] = {
            id = job and job.id,
            recipeRef = job and job.recipeRef,
            totalCount = job and job.totalCount,
            completedCount = job and job.completedCount,
            remainingCount = remainingCount,
        }
    end

    local active = nil
    if type(state.active) == "table" then
        active = {
            id = state.active.id,
            recipeRef = state.active.recipeRef,
            totalCount = state.active.totalCount,
            completedCount = state.active.completedCount,
            remainingCount = math.max(0, tonumber(state.active.remainingCount) or 0),
        }
    end

    return {
        active = active,
        queue = queue,
        queuedCount = queuedCount,
        isCrafting = active ~= nil or queuedCount > 0,
        status = ensureString(state.status, "idle"),
        lastError = ensureString(state.lastError),
        lastWarning = ensureString(state.lastWarning),
        lastOutcome = type(state.lastOutcome) == "table" and {
            recipeRef = state.lastOutcome.recipeRef,
            totalCount = state.lastOutcome.totalCount,
            completedCount = state.lastOutcome.completedCount,
            remainingCount = state.lastOutcome.remainingCount,
            status = state.lastOutcome.status,
        } or nil,
    }
end

function Crafting:BuildRecipeCache()
    local revision = getConfigurationRevision()
    local state = self.State
    if state.revision == revision and type(state.recipes) == "table" then
        return state.recipes
    end

    local startedAt = getTimingMilliseconds()
    local prebuilt = self:GetRecipeSkillIndex(revision)

    state.revision = revision
    state.recipes = prebuilt and prebuilt.recipes or {}
    state.recipeIndexByRef = prebuilt and prebuilt.recipeIndexByRef or {}
    state.recipesBySkill = prebuilt and prebuilt.orderedRecipeRefsBySkill or {}
    state.staticRecipeRowsByRef = prebuilt and prebuilt.staticRecipeRowsByRef or {}
    state.knownOrderedRecipeRefCache = {}
    state.orderedRecipeRefCache = {}
    state.recipeOrderKeyCache = {}
    state.summaryCache = {}
    state.detailCache = {}
    state.listCache = {}
    state.materialDefinitionCache = {}
    state.pendingDetailPrimes = {}
    logCraftingInternal(
        "Crafting: BuildRecipeCache revision=%d recipes=%d staticRows=%d took=%.2fms",
        revision,
        #(state.recipes or {}),
        (function()
            local count = 0
            for _ in pairs(state.staticRecipeRowsByRef or {}) do
                count = count + 1
            end
            return count
        end)(),
        getElapsedMilliseconds(startedAt)
    )
    return state.recipes
end

function Crafting:GetRecipeEntry(recipeRef)
    self:BuildRecipeCache()
    local index = self.State.recipeIndexByRef or {}
    return index[recipeRef]
end

function Crafting:GetMaterialConversionInfo(itemRef)
    local item = resolveItemDefinition(itemRef)
    local info = {
        itemRef = itemRef,
        item = item,
        itemName = ensureString(item and item.name),
        skillRef = item and item.wowConversionSkillRef or nil,
        skillLevel = 0,
        skillCap = 0,
        bagCount = 0,
        matchedSlots = {},
        canConvert = false,
    }

    if not item or tostring(item.itemType or "") ~= "material" or item.allowWowConversion ~= true or info.itemName == "" then
        return info
    end

    info.skillLevel, info.skillCap = getSkillLevelAndCap(info.skillRef)
    local skillReady = info.skillRef == nil or info.skillRef == "" or info.skillLevel >= 1
    info.bagCount, info.matchedSlots = scanBagItemByName(info.itemName)
    info.canConvert = skillReady and info.bagCount > 0
    return info
end

function Crafting:GetConvertibleMaterialDefinitionsForSkill(skillRef)
    local revision = getConfigurationRevision()
    local normalizedSkillRef = tostring(skillRef or "")
    local cacheKey = normalizedSkillRef
    local cacheEntry = self.State.materialDefinitionCache and self.State.materialDefinitionCache[cacheKey] or nil
    if cacheEntry and cacheEntry.revision == revision and type(cacheEntry.rows) == "table" then
        return cacheEntry.rows
    end

    local rows = {}
    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
    local seen = {}

    for index = 1, #datasets do
        local dataset = datasets[index]
        for itemIndex = 1, #(dataset and dataset.items or {}) do
            local item = dataset.items[itemIndex]
            if item and item.id and tostring(item.itemType or "") == "material" and item.allowWowConversion == true then
                local itemRef = ("%s:%s"):format(dataset.id, item.id)
                if not seen[itemRef] and tostring(item.wowConversionSkillRef or "") == tostring(skillRef or "") then
                    rows[#rows + 1] = {
                        itemRef = itemRef,
                        item = item,
                        dataset = dataset,
                        name = ensureString(item.name),
                        skillRef = item.wowConversionSkillRef,
                    }
                    seen[itemRef] = true
                end
            end
        end
    end

    table.sort(rows, function(left, right)
        local leftName = string.lower(ensureString(left and left.name))
        local rightName = string.lower(ensureString(right and right.name))
        if leftName ~= rightName then
            return leftName < rightName
        end
        return ensureString(left and left.itemRef) < ensureString(right and right.itemRef)
    end)

    self.State.materialDefinitionCache[cacheKey] = {
        revision = revision,
        rows = rows,
    }

    return rows
end

function Crafting:GetConvertibleMaterialsForSkill(skillRef)
    local definitions = self:GetConvertibleMaterialDefinitionsForSkill(skillRef)
    local rows = {}
    for index = 1, #definitions do
        local row = definitions[index]
        local conversion = self:GetMaterialConversionInfo(row.itemRef)
        rows[#rows + 1] = {
            itemRef = row.itemRef,
            item = row.item,
            dataset = row.dataset,
            name = row.name,
            skillRef = row.skillRef,
            bagCount = tonumber(conversion.bagCount) or 0,
            canConvert = conversion.canConvert == true,
        }
    end
    return rows
end

function Crafting:ValidateMaterialConversionRequest(itemRef, count)
    local conversion = self:GetMaterialConversionInfo(itemRef)
    local requestedCount = math.max(1, normalizeQuantity(count, 1))
    local availableCount = math.max(0, tonumber(conversion.bagCount) or 0)
    local validatedCount = math.min(requestedCount, availableCount)
    local isValid = conversion.canConvert == true and validatedCount == requestedCount and requestedCount > 0
    local message = nil

    if conversion.canConvert ~= true then
        message = "No matching WoW materials were found in your bags."
    elseif availableCount < requestedCount then
        message = ("Found %d item%s in your bags. Requested %d."):format(
            availableCount,
            availableCount == 1 and "" or "s",
            requestedCount
        )
    else
        message = ("Found %d item%s in your bags."):format(
            availableCount,
            availableCount == 1 and "" or "s"
        )
    end

    return {
        itemRef = itemRef,
        item = conversion.item,
        itemName = conversion.itemName,
        skillRef = conversion.skillRef,
        skillLevel = conversion.skillLevel,
        skillCap = conversion.skillCap,
        requestedCount = requestedCount,
        availableCount = availableCount,
        validatedCount = validatedCount,
        canConvert = conversion.canConvert == true,
        isValid = isValid,
        message = message,
    }
end

function Crafting:ConvertMaterialItemFromBags(itemRef, count)
    local conversion = self:GetMaterialConversionInfo(itemRef)
    local outputName = resolveItemName(itemRef)
    logConversionTrace(
        "ConvertMaterialItemFromBags called: itemRef=%s itemName=%s requested=%s bagCount=%d skillRef=%s skillLevel=%d canConvert=%s",
        tostring(itemRef or ""),
        tostring(conversion.itemName or ""),
        tostring(count),
        tonumber(conversion.bagCount) or 0,
        tostring(conversion.skillRef or ""),
        tonumber(conversion.skillLevel) or 0,
        tostring(conversion.canConvert == true)
    )
    if conversion.canConvert ~= true then
        self.State.lastError = "No matching WoW materials can be converted right now."
        logCraftingInternal("Material conversion blocked: canConvert is false for itemRef=%s", tostring(itemRef or ""))
        self:NotifyChanged("convert-blocked")
        return false
    end

    local datasetId, itemId = parseItemRef(itemRef)
    if not datasetId or not itemId or not Inventory.AddItem then
        self.State.lastError = "Invalid material conversion target."
        logCraftingInternal(
            "Material conversion blocked: invalid target itemRef=%s datasetId=%s itemId=%s addItem=%s",
            tostring(itemRef or ""),
            tostring(datasetId),
            tostring(itemId),
            tostring(Inventory.AddItem ~= nil)
        )
        self:NotifyChanged("convert-blocked")
        return false
    end

    local requestedCount = math.max(1, normalizeQuantity(count, 1))
    local convertCount = math.min(requestedCount, tonumber(conversion.bagCount) or 0)
    if convertCount <= 0 then
        self.State.lastError = "No matching WoW materials can be converted right now."
        logCraftingInternal(
            "Material conversion blocked: convertCount <= 0 itemRef=%s requested=%d bagCount=%d",
            tostring(itemRef or ""),
            requestedCount,
            tonumber(conversion.bagCount) or 0
        )
        self:NotifyChanged("convert-blocked")
        return false
    end

    local convertedCount, deleteReason = deleteBagItemCountByName(conversion.itemName, convertCount)
    convertedCount = math.max(0, math.floor(tonumber(convertedCount) or 0))
    if convertedCount < convertCount then
        logCraftingInternal(
            "Material conversion stopped after %d successful consumes for item=%s reason=%s",
            convertedCount,
            tostring(conversion.itemName or ""),
            tostring(deleteReason)
        )
    end

    if convertedCount <= 0 then
        self.State.lastError = "No matching WoW materials could be converted."
        logCraftingInternal("Material conversion produced zero successful consumes for itemRef=%s", tostring(itemRef or ""))
        self:NotifyChanged("convert-blocked")
        return false
    end

    self.State.suppressInventoryRefresh = true
    local addOk, addError = xpcall(function()
        Inventory.AddItem({
            dataset = datasetId,
            id = itemId,
            quantity = convertedCount,
        }, { source = "other-reward" })
    end, function(err)
        return tostring(err)
    end)
    self.State.suppressInventoryRefresh = false
    if not addOk then
        self.State.lastError = "Failed to grant converted material."
        logCraftingInternal("Material conversion failed while granting RPE item: %s", tostring(addError))
        self:NotifyChanged("convert-blocked")
        return false
    end
    self.State.lastError = ""
    self:NotifyChanged("convert-complete")
    return true
end

function Crafting:BuildInventoryCountCache()
    local state = self.State
    local inventoryRevision = math.max(0, tonumber(state.inventoryRevision) or 0)
    if state.inventoryCountRevision == inventoryRevision and type(state.inventoryCountCache) == "table" then
        return state.inventoryCountCache
    end

    local counts = {}
    local items = Inventory.GetItems and Inventory.GetItems() or {}
    for index = 1, #items do
        local record = items[index]
        local datasetId = tostring(record and record.dataset or "")
        local itemId = tostring(record and record.id or "")
        if datasetId ~= "" and itemId ~= "" then
            local itemRef = ("%s:%s"):format(datasetId, itemId)
            local itemTier = normalizeRecipeItemTier(record and record.itemTier)
            local key = inventoryCountKey(itemRef, itemTier)
            counts[key] = math.max(0, tonumber(counts[key]) or 0) + math.max(1, tonumber(record and record.quantity) or 1)
        end
    end

    state.inventoryCountCache = counts
    state.inventoryCountRevision = inventoryRevision
    return counts
end

function Crafting:BuildRecipeRequirementRows(recipe)
    local rows = {}
    local inventoryCounts = self:BuildInventoryCountCache()
    for index = 1, #(recipe and recipe.inputs or {}) do
        local input = recipe.inputs[index]
        local itemTier = normalizeRecipeItemTier(input and input.itemTier)
        local item = resolveItemDefinition(input.itemRef)
        local row = {
            kind = input.kind,
            itemRef = input.itemRef,
            item = item,
            name = resolveItemName(input.itemRef),
            quantity = math.max(1, tonumber(input.quantity) or 1),
            itemTier = itemTier,
            owned = math.max(0, tonumber(inventoryCounts[inventoryCountKey(input.itemRef, itemTier)]) or 0),
            qualityColor = getQualityColor(item),
        }
        row.hasEnough = row.owned >= row.quantity
        rows[#rows + 1] = row
    end
    return rows
end

function Crafting:GetConfigurationRevisionToken()
    return getConfigurationRevision()
end

function Crafting:BuildRecipeOrderKey(recipeRef)
    local summary = self:BuildRecipeSummary(recipeRef)
    if not summary then
        return nil
    end

    local revision = getConfigurationRevision()
    local state = self.State
    local cached = state.recipeOrderKeyCache and state.recipeOrderKeyCache[recipeRef] or nil
    if cached and cached.revision == revision and type(cached.meta) == "table" then
        return cached.meta
    end

    local meta = {
        recipeRef = summary.recipeRef,
        category = summary.category,
        name = summary.name,
        requiredSkillLevel = summary.requiredSkillLevel,
        isKnown = summary.isKnown == true,
        isTrainerRecipe = summary.isTrainerRecipe == true,
        isLockedByLevel = summary.isLockedByLevel == true,
    }

    state.recipeOrderKeyCache[recipeRef] = {
        revision = revision,
        meta = meta,
    }

    return meta
end

function Crafting:GetOrderedRecipeRefsForSkill(skillRef, options)
    self:BuildRecipeCache()

    local normalizedSkillRef = tostring(skillRef or "")
    local knownOnly = options and options.knownOnly == true or false
    local trainerOnly = options and options.trainerOnly == true or false
    local revision = getConfigurationRevision()
    local recipeIndex = self:GetRecipeSkillIndex(revision)

    if trainerOnly == true then
        if Profile.ListUnknownTrainerRecipeRefsForSkill then
            local refs = Profile.ListUnknownTrainerRecipeRefsForSkill(normalizedSkillRef) or {}
            logCraftingInternal(
                "Crafting: GetOrderedRecipeRefsForSkill skill=%s mode=trainer refs=%d revision=%d",
                normalizedSkillRef,
                #refs,
                revision
            )
            return refs
        end
        return recipeIndex and recipeIndex.trainerRecipeRefsBySkill and recipeIndex.trainerRecipeRefsBySkill[normalizedSkillRef] or {}
    end

    if knownOnly == true then
        if Profile.ListKnownRecipeRefsForSkill then
            local refs = Profile.ListKnownRecipeRefsForSkill(normalizedSkillRef) or {}
            logCraftingInternal(
                "Crafting: GetOrderedRecipeRefsForSkill skill=%s mode=known refs=%d revision=%d",
                normalizedSkillRef,
                #refs,
                revision
            )
            return refs
        end
    end

    local refs = recipeIndex and recipeIndex.orderedRecipeRefsBySkill and recipeIndex.orderedRecipeRefsBySkill[normalizedSkillRef] or {}
    logCraftingInternal(
        "Crafting: GetOrderedRecipeRefsForSkill skill=%s mode=all refs=%d revision=%d",
        normalizedSkillRef,
        #refs,
        revision
    )
    return refs
end

function Crafting:GetRecipeSummaryRangeForSkill(skillRef, startIndex, count, options)
    local startedAt = getTimingMilliseconds()
    local orderedRefs = self:GetOrderedRecipeRefsForSkill(skillRef, options)
    local rangeStart = math.max(1, math.floor(tonumber(startIndex) or 1))
    local rangeCount = math.max(0, math.floor(tonumber(count) or 0))
    local rangeEnd = math.min(#orderedRefs, rangeStart + rangeCount - 1)
    local rows = {}
    local liveContext = buildRecipeSummaryLiveContext(skillRef, options)

    for index = rangeStart, rangeEnd do
        local summary = self:BuildRecipeSummary(orderedRefs[index], liveContext)
        if summary then
            rows[#rows + 1] = summary
        end
    end

    logCraftingInternal(
        "Crafting: GetRecipeSummaryRangeForSkill skill=%s start=%d count=%d produced=%d total=%d mode=%s took=%.2fms",
        tostring(skillRef or ""),
        rangeStart,
        rangeCount,
        #rows,
        #orderedRefs,
        options and options.trainerOnly == true and "trainer" or (options and options.knownOnly == true and "known" or "all"),
        getElapsedMilliseconds(startedAt)
    )
    return rows, #orderedRefs
end

function Crafting:BuildRecipeSummary(recipeRef, liveContext)
    local startedAt = getTimingMilliseconds()
    local entry = self:GetRecipeEntry(recipeRef)
    if not entry then
        return nil
    end

    local revision = getConfigurationRevision()
    local state = self.State
    local useSharedCache = type(liveContext) ~= "table"
    local cached = useSharedCache and state.summaryCache and state.summaryCache[recipeRef] or nil
    if useSharedCache and cached and cached.revision == revision and type(cached.summary) == "table" then
        return cached.summary
    end

    local staticRow = state.staticRecipeRowsByRef and state.staticRecipeRowsByRef[recipeRef] or nil
    if type(staticRow) ~= "table" then
        staticRow = buildRecipeIndexMeta(entry)
        state.staticRecipeRowsByRef = state.staticRecipeRowsByRef or {}
        state.staticRecipeRowsByRef[recipeRef] = staticRow
    end

    local recipe = entry.recipe
    local effectiveLiveContext = type(liveContext) == "table" and liveContext or buildRecipeSummaryLiveContext(staticRow.skillRef)
    local skillLevel = math.max(0, tonumber(effectiveLiveContext.skillLevel) or 0)
    local skillCap = math.max(0, tonumber(effectiveLiveContext.skillCap) or 0)
    local known = effectiveLiveContext.knownOnly == true and true
        or (effectiveLiveContext.trainerOnly == true and false)
        or isRecipeKnown(entry.ref)
    local requiredSkillLevel = math.max(0, tonumber(staticRow.requiredSkillLevel) or 0)
    local trainerCostCopper = math.max(0, tonumber(staticRow.trainerCostCopper) or 0)
    local learnMode = ensureString(staticRow.learnMode)

    local isSkillMet = skillLevel >= requiredSkillLevel
    local summary = {
        recipeRef = entry.ref,
        recipe = recipe,
        dataset = entry.dataset,
        name = ensureString(staticRow.name) ~= "" and ensureString(staticRow.name) or ensureString(staticRow.outputName),
        category = ensureString(staticRow.category) ~= "" and ensureString(staticRow.category) or "General",
        skillRef = staticRow.skillRef,
        skillName = ensureString(effectiveLiveContext.skillName) ~= "" and ensureString(effectiveLiveContext.skillName) or ensureString(staticRow.skillName),
        skillLevel = skillLevel,
        skillCap = skillCap,
        requiredSkillLevel = requiredSkillLevel,
        learnMode = learnMode,
        isKnown = known,
        isTrainerRecipe = learnMode == "trainer",
        isLockedByLevel = isSkillMet ~= true,
        trainerCostCopper = trainerCostCopper,
        trainerCostText = ensureString(staticRow.trainerCostText),
        canLearnFromTrainer = learnMode == "trainer" and known ~= true and isSkillMet == true,
        canAffordTrainerCost = math.max(0, tonumber(effectiveLiveContext.copperAmount) or 0) >= trainerCostCopper,
        output = {
            itemRef = staticRow.outputItemRef,
            item = nil,
            name = ensureString(staticRow.outputName),
            icon = ensureString(staticRow.outputIcon),
            minQuantity = math.max(1, tonumber(staticRow.outputMinQuantity) or 1),
            maxQuantity = math.max(1, tonumber(staticRow.outputMaxQuantity) or 1),
            qualityColor = staticRow.outputQualityColor,
        },
        isSkillMet = isSkillMet,
    }

    if useSharedCache then
        state.summaryCache[recipeRef] = {
            revision = revision,
            summary = summary,
        }
    end

    local elapsedMs = getElapsedMilliseconds(startedAt)
    if elapsedMs >= 2 then
        logCraftingInternal(
            "Crafting: BuildRecipeSummary recipe=%s skill=%s known=%s trainer=%s took=%.2fms",
            tostring(recipeRef or ""),
            tostring(summary.skillRef or ""),
            tostring(summary.isKnown == true),
            tostring(summary.isTrainerRecipe == true),
            elapsedMs
        )
    end
    return summary
end

function Crafting:BuildRecipeDetails(recipeRef)
    local startedAt = getTimingMilliseconds()
    local summary = self:BuildRecipeSummary(recipeRef)
    if not summary then
        return nil
    end

    local configRevision = getConfigurationRevision()
    local inventoryRevision = math.max(0, tonumber(self.State.inventoryRevision) or 0)
    local cached = self.State.detailCache and self.State.detailCache[recipeRef] or nil
    if cached
        and cached.configRevision == configRevision
        and cached.inventoryRevision == inventoryRevision
        and type(cached.detail) == "table"
    then
        return cached.detail
    end

    local requirements = self:BuildRecipeRequirementRows(summary.recipe)
    local tools = {}
    local materials = {}
    local canCraft = summary.isKnown == true and summary.isSkillMet == true
    local outputItem = resolveItemDefinition(summary.output and summary.output.itemRef or nil)
    if not outputItem then
        canCraft = false
    end

    for index = 1, #requirements do
        local row = requirements[index]
        if row.kind == "tool" then
            tools[#tools + 1] = row
        else
            materials[#materials + 1] = row
        end
        if row.hasEnough ~= true then
            canCraft = false
        end
    end

    local detail = {
        recipeRef = summary.recipeRef,
        recipe = summary.recipe,
        dataset = summary.dataset,
        name = summary.name,
        category = summary.category,
        skillRef = summary.skillRef,
        skillName = summary.skillName,
        skillLevel = summary.skillLevel,
        skillCap = summary.skillCap,
        requiredSkillLevel = summary.requiredSkillLevel,
        learnMode = summary.learnMode,
        isKnown = summary.isKnown,
        isTrainerRecipe = summary.isTrainerRecipe,
        isLockedByLevel = summary.isLockedByLevel,
        trainerCostCopper = summary.trainerCostCopper,
        trainerCostText = summary.trainerCostText,
        canLearnFromTrainer = summary.canLearnFromTrainer,
        canAffordTrainerCost = summary.canAffordTrainerCost,
        output = {
            itemRef = summary.output and summary.output.itemRef or nil,
            item = outputItem,
            name = summary.output and summary.output.name or nil,
            icon = summary.output and summary.output.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
            minQuantity = math.max(1, tonumber(summary.output and summary.output.minQuantity) or 1),
            maxQuantity = math.max(1, tonumber(summary.output and summary.output.maxQuantity) or 1),
            qualityColor = summary.output and summary.output.qualityColor or getQualityColor(outputItem),
        },
        requirementRows = requirements,
        tools = tools,
        materials = materials,
        canCraft = canCraft,
        isSkillMet = summary.isSkillMet,
    }

    self.State.detailCache[recipeRef] = {
        configRevision = configRevision,
        inventoryRevision = inventoryRevision,
        detail = detail,
    }

    local elapsedMs = getElapsedMilliseconds(startedAt)
    if elapsedMs >= 2 then
        logCraftingInternal(
            "Crafting: BuildRecipeDetails recipe=%s materials=%d tools=%d canCraft=%s took=%.2fms",
            tostring(recipeRef or ""),
            #(detail.materials or {}),
            #(detail.tools or {}),
            tostring(detail.canCraft == true),
            elapsedMs
        )
    end
    return detail
end

function Crafting:GetRecipeSummariesForSkill(skillRef, options)
    local configRevision = getConfigurationRevision()
    local normalizedSkillRef = tostring(skillRef or "")
    local knownOnly = options and options.knownOnly == true or false
    local trainerOnly = options and options.trainerOnly == true or false
    local listKey = table.concat({ normalizedSkillRef, knownOnly and "known" or "all", trainerOnly and "trainer" or "mixed" }, "|")
    local cached = self.State.listCache and self.State.listCache[listKey] or nil
    if cached and cached.revision == configRevision and type(cached.rows) == "table" then
        return cached.rows
    end

    local rows = {}
    local orderedRefs = self:GetOrderedRecipeRefsForSkill(skillRef, options)
    local liveContext = buildRecipeSummaryLiveContext(skillRef, options)
    for index = 1, #orderedRefs do
        local detail = self:BuildRecipeSummary(orderedRefs[index], liveContext)
        if detail then
            rows[#rows + 1] = detail
        end
    end

    self.State.listCache[listKey] = {
        revision = configRevision,
        rows = rows,
    }

    return rows
end

function Crafting:PrimeRecipeDetails(recipeRefs)
    if type(recipeRefs) ~= "table" or #recipeRefs == 0 then
        return false
    end

    local state = self.State
    local configRevision = getConfigurationRevision()
    local inventoryRevision = math.max(0, tonumber(state.inventoryRevision) or 0)
    state.pendingDetailPrimes = state.pendingDetailPrimes or {}

    local function enqueuePrime(recipeRef)
        local normalizedRef = ensureString(recipeRef)
        if normalizedRef == "" then
            return
        end

        local cacheEntry = state.detailCache and state.detailCache[normalizedRef] or nil
        if cacheEntry
            and cacheEntry.configRevision == configRevision
            and cacheEntry.inventoryRevision == inventoryRevision
        then
            return
        end

        local pendingKey = ("%s|%d|%d"):format(normalizedRef, configRevision, inventoryRevision)
        if state.pendingDetailPrimes[pendingKey] then
            return
        end
        state.pendingDetailPrimes[pendingKey] = true

        local finalize = function()
            state.pendingDetailPrimes[pendingKey] = nil
        end

        if Tasks and type(Tasks.Enqueue) == "function" then
            Tasks:Enqueue(function(targetRecipeRef, expectedConfigRevision, expectedInventoryRevision, expectedPendingKey)
                if expectedConfigRevision ~= getConfigurationRevision() or expectedInventoryRevision ~= (math.max(0, tonumber(state.inventoryRevision) or 0)) then
                    state.pendingDetailPrimes[expectedPendingKey] = nil
                    return
                end

                self:BuildRecipeDetails(targetRecipeRef)
                state.pendingDetailPrimes[expectedPendingKey] = nil
            end, normalizedRef, configRevision, inventoryRevision, pendingKey)
        else
            self:BuildRecipeDetails(normalizedRef)
            finalize()
        end
    end

    for index = 1, #recipeRefs do
        enqueuePrime(recipeRefs[index])
    end

    return true
end

function Crafting:GetRecipesForSkill(skillRef)
    logCraftingInternal("Crafting: LEGACY GetRecipesForSkill called skill=%s", tostring(skillRef or ""))
    return self:GetRecipeSummariesForSkill(skillRef, {
        knownOnly = true,
    })
end

function Crafting:GetTrainerRecipesForSkill(skillRef)
    logCraftingInternal("Crafting: LEGACY GetTrainerRecipesForSkill called skill=%s", tostring(skillRef or ""))
    return self:GetRecipeSummariesForSkill(skillRef, {
        trainerOnly = true,
    })
end

function Crafting:GetMaxCraftableCount(recipeRef)
    local availability = self:GetCraftingAvailability(recipeRef)
    return math.max(0, tonumber(availability and availability.maxCount) or 0)
end

function Crafting:GetCraftingAvailability(recipeRef)
    local normalizedRef = ensureString(recipeRef)
    local detail = normalizedRef ~= "" and self:BuildRecipeDetails(normalizedRef) or nil
    local result = {
        recipeRef = normalizedRef,
        detail = detail,
        canCraft = false,
        maxCount = 0,
        reason = "Recipe details are still loading.",
    }
    if not detail then
        return result
    end
    if detail.isKnown ~= true then
        result.reason = "You have not learned that recipe."
        return result
    end
    if detail.isSkillMet ~= true then
        result.reason = ("Requires %s (%d)."):format(
            tostring(detail.skillName or "Skill"),
            tonumber(detail.requiredSkillLevel) or 0
        )
        return result
    end
    if not detail.output or not detail.output.item then
        result.reason = "Recipe output is unavailable."
        return result
    end

    for index = 1, #(detail.tools or {}) do
        if detail.tools[index].hasEnough ~= true then
            result.reason = ("Missing required tool: %s."):format(tostring(detail.tools[index].name or "tool"))
            return result
        end
    end
    if detail.canCraft ~= true then
        result.reason = "Insufficient materials."
        return result
    end

    local maxCount = nil
    for index = 1, #(detail.materials or {}) do
        local row = detail.materials[index]
        local craftsFromRow = math.floor((tonumber(row.owned) or 0) / math.max(1, tonumber(row.quantity) or 1))
        maxCount = maxCount == nil and craftsFromRow or math.min(maxCount, craftsFromRow)
    end

    -- Recipes without consumable materials still need a finite, safe Craft All
    -- behavior. One unit is the only count we can establish without an
    -- authored consumption limit.
    maxCount = maxCount == nil and 1 or math.max(0, maxCount)
    result.maxCount = maxCount
    result.canCraft = maxCount > 0
    if not result.canCraft then
        result.reason = "Insufficient materials."
    else
        result.reason = ""
    end
    return result
end

function Crafting:GetRecipeSkillUpChance(detail)
    return getRecipeSkillUpInfo(detail).chance
end

function Crafting:GetRecipeSkillUpInfo(detail)
    return getRecipeSkillUpInfo(detail)
end

function Crafting:ConsumeRecipeInputsOnce(detail)
    if not detail or detail.canCraft ~= true then
        return false, "recipe-not-craftable", {}
    end

    local consumedRows = {}
    for index = 1, #(detail.materials or {}) do
        local row = detail.materials[index]
        local removed, removeError, removedCount = removeInventoryItemCount(row.itemRef, row.quantity, row.itemTier)
        if (tonumber(removedCount) or 0) > 0 then
            consumedRows[#consumedRows + 1] = {
                itemRef = row.itemRef,
                itemTier = row.itemTier,
                quantity = removedCount,
                name = row.name,
            }
        end
        if not removed then
            self.State.lastError = "Failed to consume required materials."
            return false, removeError or "consume-failed", consumedRows
        end
    end

    self.State.lastError = ""
    return true, consumedRows
end

function Crafting:GrantRecipeOutputOnce(detail)
    if not detail or not detail.output or not detail.output.itemRef or not Inventory.AddItem then
        self.State.lastError = "Recipe output is invalid."
        return false
    end

    local datasetId, itemId = parseItemRef(detail.output.itemRef)
    if not datasetId or not itemId then
        self.State.lastError = "Recipe output is invalid."
        return false
    end

    local quantity = rollQuantity(detail.output.minQuantity, detail.output.maxQuantity)
    local activeJob = self.State and self.State.active or nil
    local craftEventId = activeJob and activeJob.id and ("craft:%s:%d"):format(
        tostring(activeJob.id),
        (tonumber(activeJob.completedCount) or 0) + 1
    ) or nil
    local added, addError = Inventory.AddItem({
        dataset = datasetId,
        id = itemId,
        itemTier = detail.output.itemTier,
        quantity = quantity,
    }, { source = "craft-recipe", eventId = craftEventId })
    if not added then
        self.State.lastError = "Failed to grant the crafted output: " .. tostring(addError or "unknown error")
        return false, addError or "output-grant-failed"
    end
    self.State.lastError = ""
    return true, {
        itemRef = detail.output.itemRef,
        itemTier = detail.output.itemTier,
        quantity = quantity,
    }
end

local function restoreCraftingInputs(consumedRows)
    if type(consumedRows) ~= "table" or #consumedRows == 0 then
        return true
    end
    if type(Inventory.AddItem) ~= "function" then
        return false, "inventory-add-unavailable"
    end

    for index = #consumedRows, 1, -1 do
        local row = consumedRows[index]
        local datasetId, itemId = parseItemRef(row and row.itemRef)
        if not datasetId or not itemId then
            return false, "invalid-compensation-item"
        end
        local restored, restoreError = Inventory.AddItem({
            dataset = datasetId,
            id = itemId,
            itemTier = row.itemTier,
            quantity = row.quantity,
        }, { source = "craft-compensation", suppressLootNotification = true })
        if not restored then
            return false, restoreError or "compensation-failed"
        end
    end

    return true
end

function Crafting:ExecuteCraftOnce(detail)
    if type(detail) ~= "table" or detail.canCraft ~= true then
        self.State.lastError = "Recipe is not currently craftable."
        return false
    end

    -- Recheck every material immediately before mutating inventory. The
    -- requirement rows are rebuilt from the current inventory revision, so a
    -- stale queue cannot spend inputs it no longer owns.
    for index = 1, #(detail.materials or {}) do
        local row = detail.materials[index]
        if (tonumber(row.owned) or 0) < (tonumber(row.quantity) or 1) then
            self.State.lastError = "Insufficient materials."
            return false
        end
    end

    local previousSuppressRefresh = self.State.suppressInventoryRefresh
    local consumedRows = {}
    local outputCountBefore = countInventoryItem(detail.output.itemRef, detail.output.itemTier)
    local outputCommitted = false
    local outputConfirmationWarning = nil
    self.State.suppressInventoryRefresh = true

    local transactionOk, transactionCommitted, transactionError = xpcall(function()
        local consumeCallOk, consumeSucceeded, consumeValue, consumeRows = xpcall(function()
            return self:ConsumeRecipeInputsOnce(detail)
        end, captureCraftingError)
        if not consumeCallOk then
            return false, consumeSucceeded
        end

        consumedRows = consumeSucceeded == true
            and (type(consumeValue) == "table" and consumeValue or {})
            or (type(consumeRows) == "table" and consumeRows or {})
        if consumeSucceeded ~= true then
            return false, consumeValue or "consume-failed"
        end

        local grantCallOk, grantSucceeded, grantValue = xpcall(function()
            return self:GrantRecipeOutputOnce(detail)
        end, captureCraftingError)
        local outputCountAfter = countInventoryItem(detail.output.itemRef, detail.output.itemTier)
        if grantCallOk and grantSucceeded == true then
            outputCommitted = true
            return true
        end

        if outputCountAfter > outputCountBefore then
            outputCommitted = true
            outputConfirmationWarning = grantCallOk
                and "Output grant reported failure after inventory changed."
                or "Output grant raised after inventory changed."
            return true
        end

        return false, grantCallOk and (grantValue or "output-grant-failed") or grantSucceeded
    end, captureCraftingError)
    self.State.suppressInventoryRefresh = previousSuppressRefresh

    if not transactionOk then
        outputCommitted = false
    end
    if transactionOk and transactionCommitted == true and outputCommitted == true then
        self.State.lastError = ""
        if outputConfirmationWarning then
            self:RecordPostCommitWarning("output confirmation", detail.recipeRef, outputConfirmationWarning, self.State.active and self.State.active.completedCount or 0)
        end

        local progression = Addon.Client and Addon.Client.SkillProgression or nil
        if type(progression) == "table" and type(progression.TryGain) == "function" then
            local skillUpInfo = self:GetRecipeSkillUpInfo(detail)
            local progressionOk, progressionResult = xpcall(function()
                return progression:TryGain(
                    detail.skillRef,
                    "craft-recipe",
                    skillUpInfo.chance,
                    {
                        recipeRef = detail.recipeRef,
                        onGain = function()
                            self:NotifyChanged("skill-gain")
                        end,
                    }
                )
            end, captureCraftingError)
            logCraftingInternal(
                "Crafting skill-up roll recipe=%s required=%d current=%d cap=%d chance=%d roll=%s granted=%s result=%s",
                tostring(detail.recipeRef or ""),
                skillUpInfo.requiredSkillLevel,
                skillUpInfo.skillLevel,
                skillUpInfo.skillCap,
                skillUpInfo.chance,
                tostring(progressionOk and type(progressionResult) == "table" and progressionResult.roll or "error"),
                tostring(progressionOk and type(progressionResult) == "table" and progressionResult.granted == true or false),
                tostring(progressionOk and type(progressionResult) == "table" and (progressionResult.reason or "completed") or progressionResult)
            )
            if not progressionOk then
                self:RecordPostCommitWarning("skill progression", detail.recipeRef, progressionResult, self.State.active and self.State.active.completedCount or 0)
            elseif type(progressionResult) == "table" and progressionResult.reason == "persistence-failed" then
                self:RecordPostCommitWarning("skill persistence", detail.recipeRef, progressionResult.reason, self.State.active and self.State.active.completedCount or 0)
            end
        end
        return true
    end

    local compensationOk, restored, compensationError = xpcall(function()
        return restoreCraftingInputs(consumedRows)
    end, captureCraftingError)
    if not compensationOk or restored ~= true then
        local reason = compensationOk and compensationError or restored
        self.State.lastError = "Crafting failed and required materials could not be restored."
        logCraftingFailure("input compensation", detail.recipeRef, reason or "compensation-failed", false, self.State.active and self.State.active.completedCount or 0)
    else
        self.State.lastError = transactionOk
            and ("Crafting failed: " .. tostring(transactionError or "output-grant-failed"))
            or "Crafting failed unexpectedly. See the debug log for details."
        logCraftingFailure("craft transaction", detail.recipeRef, transactionError or "craft-failed", false, self.State.active and self.State.active.completedCount or 0)
    end
    return false
end

function Crafting:ScheduleQueueStep(epoch)
    local state = self.State
    if state.queueTask ~= nil or state.active == nil then
        return false
    end

    local callback = function()
        self:ProcessQueueStep(epoch)
    end
    if type(Tasks.Enqueue) == "function" then
        state.queueTask = Tasks:Enqueue(callback)
        return true
    end
    if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
        state.queueTask = true
        C_Timer.After(0, callback)
        return true
    end

    state.lastError = "Crafting task queue is unavailable."
    state.status = "blocked"
    return false
end

function Crafting:ProcessQueueStep(epoch)
    local state = self.State
    state.queueTask = nil
    if tonumber(epoch) ~= tonumber(state.queueEpoch) or state.active == nil then
        return false
    end
    if state.profileKey ~= getCurrentProfileToken() then
        self:CancelCrafting("profile-changed")
        return false
    end

    local job = state.active
    local availability = self:GetCraftingAvailability(job.recipeRef)
    if not availability.canCraft then
        state.lastError = availability.reason
        state.status = "blocked"
        if type(job) == "table" and (tonumber(job.completedCount) or 0) > 0 then
            state.lastOutcome = self:BuildCraftOutcome(job, "blocked")
        end
        state.active = nil
        self:NotifyChanged("craft-blocked")
        if #state.queue > 0 then
            state.status = "queued"
            self:NotifyChanged("queue-progress")
            self:StartNextCraftJob()
        end
        return false
    end

    if not self:ExecuteCraftOnce(availability.detail) then
        state.status = "blocked"
        state.lastOutcome = (tonumber(job.completedCount) or 0) > 0
            and self:BuildCraftOutcome(job, "blocked")
            or nil
        state.active = nil
        self:NotifyChanged("craft-blocked")
        if #state.queue > 0 then
            state.status = "queued"
            self:NotifyChanged("queue-progress")
            self:StartNextCraftJob()
        end
        return false
    end

    job.completedCount = (tonumber(job.completedCount) or 0) + 1
    job.remainingCount = math.max(0, (tonumber(job.remainingCount) or 0) - 1)
    state.lastOutcome = self:BuildCraftOutcome(job, job.remainingCount <= 0 and "complete" or "active")
    self:NotifyChanged("craft-progress")
    if job.remainingCount <= 0 then
        state.active = nil
        state.status = #state.queue > 0 and "queued" or "complete"
        state.lastOutcome = self:BuildCraftOutcome(job, "complete")
        self:NotifyChanged("craft-complete")
        if #state.queue > 0 then
            self:StartNextCraftJob()
        end
    else
        if not self:ScheduleQueueStep(epoch) then
            state.active = nil
            state.status = "blocked"
            state.lastOutcome = self:BuildCraftOutcome(job, "blocked")
            self:NotifyChanged("craft-blocked")
        end
    end
    return true
end

function Crafting:StartNextCraftJob()
    local state = self.State
    if state.active ~= nil then
        return false
    end
    local job = table.remove(state.queue, 1)
    if not job then
        return false
    end
    state.active = job
    state.status = "active"
    state.lastOutcome = nil
    self:NotifyChanged("craft-active")
    if self:ScheduleQueueStep(state.queueEpoch) then
        return true
    end
    state.active = nil
    state.status = "blocked"
    self:NotifyChanged("craft-blocked")
    return false
end

function Crafting:QueueRecipe(recipeRef, count)
    local normalizedRef = ensureString(recipeRef)
    local state = self.State
    if state.profileKey ~= nil and state.profileKey ~= getCurrentProfileToken() then
        self:CancelCrafting("profile-changed")
        state = self.State
    end
    state.lastError = ""
    state.lastWarning = ""
    state.lastOutcome = nil
    local reject = function(message, reason)
        state.lastError = message
        if state.active == nil and #(state.queue or {}) == 0 then
            state.status = "blocked"
        end
        self:NotifyChanged(reason or "craft-blocked")
        return false
    end
    local numericCount = tonumber(count)
    if numericCount == nil or numericCount < 1 or numericCount ~= math.floor(numericCount) then
        return reject("Enter a whole number of crafts (at least 1).")
    end
    local requested = math.floor(numericCount)

    local availability = self:GetCraftingAvailability(normalizedRef)
    if not availability.canCraft then
        return reject(availability.reason)
    end
    for index = 1, #(state.queue or {}) do
        if state.queue[index].recipeRef == normalizedRef then
            return reject("That recipe is already queued.", "queue-duplicate")
        end
    end
    if state.active and state.active.recipeRef == normalizedRef then
        return reject("That recipe is already being crafted.", "queue-duplicate")
    end

    local accepted = math.min(requested, availability.maxCount)
    if accepted <= 0 then
        return reject(availability.reason)
    end
    state.nextJobId = math.max(0, tonumber(state.nextJobId) or 0) + 1
    state.profileKey = getCurrentProfileToken()
    state.queue[#state.queue + 1] = {
        id = state.nextJobId,
        recipeRef = normalizedRef,
        totalCount = accepted,
        completedCount = 0,
        remainingCount = accepted,
    }
    state.lastError = accepted < requested
        and ("Only %d craft%s available."):format(accepted, accepted == 1 and " is" or "s are")
        or ""
    state.status = "queued"
    self:NotifyChanged("queue-added")
    if state.active == nil then
        self:StartNextCraftJob()
    end
    return true
end

function Crafting:LearnRecipeFromTrainer(recipeRef)
    local detail = self:BuildRecipeDetails(recipeRef)
    if not detail then
        self.State.lastError = "Recipe not found."
        self:NotifyChanged("trainer-blocked")
        return false
    end

    if detail.isTrainerRecipe ~= true then
        self.State.lastError = "That recipe is not taught by a trainer."
        self:NotifyChanged("trainer-blocked")
        return false
    end

    if detail.isKnown == true then
        self.State.lastError = "You already know that recipe."
        self:NotifyChanged("trainer-blocked")
        return false
    end

    if detail.isLockedByLevel == true then
        self.State.lastError = ("Requires %s (%d)."):format(tostring(detail.skillName or "Skill"), tonumber(detail.requiredSkillLevel) or 0)
        self:NotifyChanged("trainer-blocked")
        return false
    end

    local spendOk = true
    if Profile.SpendCurrencyAmount then
        spendOk = select(1, Profile.SpendCurrencyAmount("copper", detail.trainerCostCopper))
    end
    if spendOk ~= true then
        self.State.lastError = "You do not have enough copper."
        self:NotifyChanged("trainer-blocked")
        return false
    end

    if not (Profile.AddKnownRecipe and Profile.AddKnownRecipe(detail.recipeRef)) then
        if Profile.AddCurrencyAmount then
            Profile.AddCurrencyAmount("copper", detail.trainerCostCopper)
        end
        self.State.lastError = "Failed to learn that recipe."
        self:NotifyChanged("trainer-blocked")
        return false
    end

    self.State.lastError = ""
    self:NotifyChanged("trainer-learned")
    return true
end

function Crafting:QueueAll(recipeRef)
    self:GetState()
    local maxCount = self:GetMaxCraftableCount(recipeRef)
    if maxCount <= 0 then
        self.State.lastError = "Nothing craftable."
        if self.State.active == nil and #(self.State.queue or {}) == 0 then
            self.State.status = "blocked"
        end
        self:NotifyChanged("queue-none")
        return false
    end

    return self:QueueRecipe(recipeRef, maxCount)
end

function Crafting:CancelCrafting(reason)
    local state = self.State
    local hadWork = state.active ~= nil or #(state.queue or {}) > 0
    if not hadWork then
        return false
    end
    state.queueEpoch = math.max(0, tonumber(state.queueEpoch) or 0) + 1
    if type(state.active) == "table" and (tonumber(state.active.completedCount) or 0) > 0 then
        state.lastOutcome = self:BuildCraftOutcome(state.active, "cancelled")
    end
    state.queueTask = nil
    state.queue = {}
    state.active = nil
    state.profileKey = nil
    state.lastError = ""
    state.status = "cancelled"
    self:NotifyChanged(reason == "profile-changed" and "profile-changed" or "craft-cancelled")
    return true
end

function Crafting:HandleProfileWindowClosed()
    return self:CancelCrafting("profile-closed")
end

function Crafting:Initialize()
    if self._initialized == true then
        return self
    end
    self._initialized = true

    if Inventory and Inventory.RegisterChangeListener then
        self._inventoryListenerId = Inventory.RegisterChangeListener(function()
            if Crafting.State and Crafting.State.suppressInventoryRefresh == true then
                return
            end
            Crafting:NotifyChanged("inventory-change")
        end)
    end
    if Profile and type(Profile.RegisterSkillChangeListener) == "function" then
        self._skillListenerId = Profile.RegisterSkillChangeListener(function()
            Crafting:NotifyChanged("skill-gain")
        end)
    end

    return self
end

Crafting:Initialize()

return Crafting
