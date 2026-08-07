local addonName, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Inventory = Addon.Client.Inventory or {}

local Inventory = Addon.Client.Inventory
local Database = Addon.Internal and Addon.Internal.Database or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local ModificationService = Profile and Profile.Modifications or {}

local function getItemClass()
    return Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Item or nil
end

local SCHEMA_VERSION = 1
local DEFAULT_ROOT_NAME = "RPEngineInventoryDB"

Inventory._changeListeners = Inventory._changeListeners or {}
Inventory._nextChangeListenerId = Inventory._nextChangeListenerId or 0

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

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end

    return copy
end

local function deepEqual(left, right)
    if left == right then
        return true
    end
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return false
    end

    for key, value in pairs(left) do
        if not deepEqual(value, right[key]) then
            return false
        end
    end
    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end

    return true
end

local function getCharacterKey()
    if UnitFullName then
        local name, realm = UnitFullName("player")
        if name and name ~= "" then
            realm = realm or (GetRealmName and GetRealmName()) or ""
            if realm ~= "" then
                return ("%s-%s"):format(name, realm)
            end

            return name
        end
    end

    if UnitName then
        local name = UnitName("player")
        if name and name ~= "" then
            local realm = (GetRealmName and GetRealmName()) or ""
            if realm ~= "" then
                return ("%s-%s"):format(name, realm)
            end

            return name
        end
    end

    return "unknown-player"
end

local function notifyChangeListeners(changeType, detail)
    local listeners = Inventory._changeListeners or {}
    local inventory = Inventory.GetCharacterInventory()
    local payload = {
        changeType = tostring(changeType or "set"),
        characterKey = getCharacterKey(),
        itemCount = #(inventory and inventory.items or {}),
        detail = type(detail) == "table" and deepCopy(detail) or nil,
    }

    for _, listener in pairs(listeners) do
        if type(listener) == "function" then
            pcall(listener, payload)
        end
    end
end

function Inventory.EnsureRoot()
    local root = ensureTable(_G[DEFAULT_ROOT_NAME])
    _G[DEFAULT_ROOT_NAME] = root

    root._schema = root._schema or SCHEMA_VERSION
    root.inventoriesByChar = ensureTable(root.inventoriesByChar)

    Inventory.Root = root
    return root
end

function Inventory.NormalizeInventoryItem(record)
    if type(record) ~= "table" then
        return nil
    end

    local datasetId = ensureString(record.dataset)
    local itemId = ensureString(record.id)
    if datasetId == "" or itemId == "" then
        return nil
    end

    return {
        dataset = datasetId,
        id = itemId,
        modifications = deepCopy(ensureTable(record.modifications)),
        soulbound = record.soulbound == true,
        quantity = math.max(1, math.floor(tonumber(record.quantity or record.count) or 1)),
    }
end

local function findDatasetItem(dataset, itemId)
    local items = dataset and dataset.items or nil
    if type(items) ~= "table" then
        return nil
    end

    for index = 1, #items do
        local item = items[index]
        if type(item) == "table" and tostring(item.id or "") == itemId then
            return item, index
        end
    end

    return nil
end

local function resolveItemDefinition(itemRecord)
    local normalized = Inventory.NormalizeInventoryItem(itemRecord)
    if not normalized then
        return nil, nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(normalized.dataset) or nil
    local item = findDatasetItem(dataset, normalized.id)
    return dataset, item
end

local function canStackRecord(itemRecord)
    local _, item = resolveItemDefinition(itemRecord)
    if type(item) ~= "table" or item.canStack ~= true then
        return false, 1
    end

    return true, math.max(1, math.floor(tonumber(item.maxStackSize) or 1))
end

local function canMergeInventoryRecords(left, right)
    local normalizedLeft = Inventory.NormalizeInventoryItem(left)
    local normalizedRight = Inventory.NormalizeInventoryItem(right)
    if not normalizedLeft or not normalizedRight then
        return false
    end

    return normalizedLeft.dataset == normalizedRight.dataset
        and normalizedLeft.id == normalizedRight.id
        and deepEqual(normalizedLeft.modifications, normalizedRight.modifications)
        and normalizedLeft.soulbound == normalizedRight.soulbound
end

local function parseItemRef(itemRef)
    local normalized = ensureString(itemRef)
    local separatorIndex = string.find(normalized, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = string.sub(normalized, 1, separatorIndex - 1)
    local itemId = string.sub(normalized, separatorIndex + 1)
    if datasetId == "" or itemId == "" then
        return nil, nil
    end

    return datasetId, itemId
end

local function addNormalizedRecordToItems(items, record)
    local normalized = Inventory.NormalizeInventoryItem(record)
    if not normalized then
        return nil
    end

    local canStack, maxStackSize = canStackRecord(normalized)
    local remaining = math.max(1, math.floor(tonumber(normalized.quantity) or 1))
    normalized.quantity = 1

    if canStack then
        for index = 1, #items do
            local existing = Inventory.NormalizeInventoryItem(items[index])
            local existingQuantity = math.max(1, math.floor(tonumber(existing and existing.quantity) or 1))
            if existing and canMergeInventoryRecords(existing, normalized) and existingQuantity < maxStackSize then
                local addAmount = math.min(maxStackSize - existingQuantity, remaining)
                existing.quantity = existingQuantity + addAmount
                items[index] = existing
                remaining = remaining - addAmount
                if remaining <= 0 then
                    break
                end
            end
        end
    end

    while remaining > 0 do
        local nextRecord = deepCopy(normalized)
        nextRecord.quantity = canStack and math.min(maxStackSize, remaining) or 1
        items[#items + 1] = nextRecord
        remaining = remaining - nextRecord.quantity
    end

    return normalized
end

local function splitRecordForMutation(items, recordIndex, relatedIndex)
    local index = tonumber(recordIndex)
    local otherIndex = tonumber(relatedIndex)
    if not index or index < 1 or index > #items then
        return nil, otherIndex
    end

    local record = Inventory.NormalizeInventoryItem(items[index])
    local quantity = math.max(1, math.floor(tonumber(record and record.quantity) or 1))
    if not record or quantity <= 1 then
        return index, otherIndex
    end

    items[index].quantity = quantity - 1

    local splitRecord = deepCopy(record)
    splitRecord.quantity = 1
    table.insert(items, index + 1, splitRecord)

    if otherIndex and otherIndex > index then
        otherIndex = otherIndex + 1
    end

    return index + 1, otherIndex
end

function Inventory.GetCharacterInventory()
    local root = Inventory.EnsureRoot()
    local characterKey = getCharacterKey()
    local inventory = ensureTable(root.inventoriesByChar[characterKey])

    inventory.items = ensureTable(inventory.items)
    root.inventoriesByChar[characterKey] = inventory
    return inventory
end

function Inventory.RegisterChangeListener(listener)
    if type(listener) ~= "function" then
        return nil
    end

    Inventory._nextChangeListenerId = (tonumber(Inventory._nextChangeListenerId) or 0) + 1
    local listenerId = Inventory._nextChangeListenerId
    Inventory._changeListeners[listenerId] = listener
    return listenerId
end

function Inventory.UnregisterChangeListener(listenerId)
    local normalizedId = tonumber(listenerId)
    if not normalizedId then
        return false
    end

    if Inventory._changeListeners[normalizedId] == nil then
        return false
    end

    Inventory._changeListeners[normalizedId] = nil
    return true
end

function Inventory.GetItems()
    local inventory = Inventory.GetCharacterInventory()
    local items = {}

    for index = 1, #(inventory.items or {}) do
        local normalized = Inventory.NormalizeInventoryItem(inventory.items[index])
        if normalized then
            items[#items + 1] = normalized
        end
    end

    inventory.items = items
    return items
end

function Inventory.SetItems(items, changeType, detail)
    local inventory = Inventory.GetCharacterInventory()
    local normalizedItems = {}

    for index = 1, #(items or {}) do
        local normalized = Inventory.NormalizeInventoryItem(items[index])
        if normalized then
            normalizedItems[#normalizedItems + 1] = normalized
        end
    end

    inventory.items = normalizedItems
    notifyChangeListeners(changeType or "set", detail)
    return inventory.items
end

function Inventory.AddItem(itemRecord)
    local normalized = Inventory.NormalizeInventoryItem(itemRecord)
    if not normalized then
        return nil
    end

    local _, itemDefinition = resolveItemDefinition(normalized)
    local itemClass = getItemClass()
    if itemClass and itemClass.IsBindOnPickup and itemClass.IsBindOnPickup(itemDefinition) then
        normalized.soulbound = true
    end

    local items = Inventory.GetItems()
    local canStack, maxStackSize = canStackRecord(normalized)
    local remaining = math.max(1, math.floor(tonumber(normalized.quantity) or 1))
    normalized.quantity = 1

    if canStack then
        for index = 1, #items do
            local existing = Inventory.NormalizeInventoryItem(items[index])
            local existingQuantity = math.max(1, math.floor(tonumber(existing and existing.quantity) or 1))
            if existing and canMergeInventoryRecords(existing, normalized) and existingQuantity < maxStackSize then
                local spaceRemaining = maxStackSize - existingQuantity
                local addAmount = math.min(spaceRemaining, remaining)
                existing.quantity = existingQuantity + addAmount
                items[index] = existing
                remaining = remaining - addAmount
                if remaining <= 0 then
                    break
                end
            end
        end
    end

    while remaining > 0 do
        local nextRecord = deepCopy(normalized)
        nextRecord.quantity = canStack and math.min(maxStackSize, remaining) or 1
        items[#items + 1] = nextRecord
        remaining = remaining - nextRecord.quantity
    end

    Inventory.SetItems(items, "add", {
        dataset = normalized.dataset,
        itemId = normalized.id,
        quantity = math.max(1, math.floor(tonumber(itemRecord and itemRecord.quantity) or tonumber(itemRecord and itemRecord.count) or 1)),
    })
    return normalized, #items
end

function Inventory.AddResolvedRecord(resolved)
    if type(resolved) ~= "table" then
        return nil
    end

    return Inventory.AddItem({
        dataset = resolved.datasetId or (resolved.record and resolved.record.dataset) or "",
        id = resolved.itemId or (resolved.record and resolved.record.id) or "",
        modifications = deepCopy(resolved.modifications or (resolved.record and resolved.record.modifications) or {}),
        soulbound = resolved.soulbound == true or (resolved.record and resolved.record.soulbound == true),
    })
end

function Inventory.SetItemSoulbound(slotIndex, soulbound, quantity)
    local items = Inventory.GetItems()
    local index = tonumber(slotIndex)
    if not index or index < 1 or index > #items then
        return nil
    end

    local desiredSoulbound = soulbound == true
    local normalized = Inventory.NormalizeInventoryItem(items[index])
    if not normalized then
        return nil
    end

    local existingQuantity = math.max(1, math.floor(tonumber(normalized.quantity) or 1))
    local bindQuantity = math.max(1, math.floor(tonumber(quantity) or existingQuantity))
    bindQuantity = math.min(existingQuantity, bindQuantity)

    if normalized.soulbound == desiredSoulbound and bindQuantity >= existingQuantity then
        return normalized, index
    end

    if bindQuantity >= existingQuantity then
        items[index].soulbound = desiredSoulbound
        Inventory.SetItems(items, desiredSoulbound and "bind" or "unbind", {
            slotIndex = index,
            quantity = bindQuantity,
        })
        return Inventory.GetItem(index), index
    end

    items[index].quantity = existingQuantity - bindQuantity

    local splitRecord = deepCopy(normalized)
    splitRecord.quantity = bindQuantity
    splitRecord.soulbound = desiredSoulbound
    table.insert(items, index + 1, splitRecord)

    Inventory.SetItems(items, desiredSoulbound and "bind" or "unbind", {
        slotIndex = index,
        quantity = bindQuantity,
    })
    return Inventory.GetItem(index + 1), index + 1
end

function Inventory.BindItem(slotIndex, quantity)
    return Inventory.SetItemSoulbound(slotIndex, true, quantity)
end

function Inventory.RemoveItem(slotIndex, quantity)
    local items = Inventory.GetItems()
    local index = tonumber(slotIndex)
    if not index or index < 1 or index > #items then
        return nil
    end

    local removeQuantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local removed = Inventory.NormalizeInventoryItem(items[index])
    local existingQuantity = math.max(1, math.floor(tonumber(removed and removed.quantity) or 1))
    if not removed then
        return nil
    end

    if existingQuantity > removeQuantity then
        items[index].quantity = existingQuantity - removeQuantity
        removed.quantity = removeQuantity
    else
        table.remove(items, index)
    end

    Inventory.SetItems(items, "remove", {
        slotIndex = index,
        quantity = removeQuantity,
    })
    return removed
end

function Inventory.DeleteItem(slotIndex)
    local record = Inventory.GetItem(slotIndex)
    local quantity = math.max(1, math.floor(tonumber(record and record.quantity) or 1))
    return Inventory.RemoveItem(slotIndex, quantity)
end

function Inventory.GetItem(slotIndex)
    local items = Inventory.GetItems()
    local index = tonumber(slotIndex)
    if not index or index < 1 or index > #items then
        return nil
    end

    return items[index]
end

function Inventory.EquipItem(slotIndex, options)
    local index = tonumber(slotIndex)
    local record = Inventory.GetItem(index)
    if not record then
        return nil, "missing-item"
    end

    local profile = Addon.Internal and Addon.Internal.Profile or {}
    if not profile.EquipInventoryItem then
        return nil, "profile-unavailable"
    end

    local equipped, slotKey = profile.EquipInventoryItem(index, record, options)
    if not equipped then
        return nil, slotKey
    end

    return equipped, slotKey
end

function Inventory.GetCompatibleModificationChoices(targetSlotIndex)
    local index = tonumber(targetSlotIndex)
    local targetRecord = index and Inventory.GetItem(index) or nil
    if not targetRecord or type(ModificationService.GetCompatibleModificationChoices) ~= "function" then
        return {}
    end

    return ModificationService.GetCompatibleModificationChoices(targetRecord, Inventory.GetItems())
end

function Inventory.ApplyModification(targetSlotIndex, modificationSlotIndex)
    local targetIndex = tonumber(targetSlotIndex)
    local sourceIndex = tonumber(modificationSlotIndex)
    local items = Inventory.GetItems()
    if not targetIndex or not sourceIndex then
        return nil, "invalid-slot"
    end
    if targetIndex < 1 or targetIndex > #items or sourceIndex < 1 or sourceIndex > #items then
        return nil, "invalid-slot"
    end

    targetIndex, sourceIndex = splitRecordForMutation(items, targetIndex, sourceIndex)

    local targetRecord = Inventory.NormalizeInventoryItem(items[targetIndex])
    local sourceRecord = Inventory.NormalizeInventoryItem(items[sourceIndex])
    if not targetRecord or not sourceRecord then
        return nil, "missing-item"
    end

    if type(ModificationService.CanApplyModificationToRecord) ~= "function" then
        return nil, "modification-unavailable"
    end

    local canApply, reason = ModificationService.CanApplyModificationToRecord(targetRecord, sourceRecord)
    if not canApply then
        return nil, reason or "incompatible"
    end

    local nextRecord, modKey = nil, nil
    if type(ModificationService.AddModificationToRecord) == "function" then
        nextRecord, modKey = ModificationService.AddModificationToRecord(targetRecord, sourceRecord)
    end
    if not nextRecord or not modKey then
        return nil, "apply-failed"
    end

    items[targetIndex] = nextRecord

    local sourceQuantity = math.max(1, math.floor(tonumber(sourceRecord.quantity) or 1))
    if sourceQuantity > 1 then
        items[sourceIndex].quantity = sourceQuantity - 1
    else
        table.remove(items, sourceIndex)
        if sourceIndex < targetIndex then
            targetIndex = targetIndex - 1
        end
    end

    Inventory.SetItems(items, "modify-apply", {
        targetSlotIndex = targetIndex,
        modificationSlotIndex = tonumber(modificationSlotIndex),
        modKey = modKey,
        itemRef = type(ModificationService.GetRecordItemRef) == "function" and ModificationService.GetRecordItemRef(sourceRecord) or nil,
    })

    return Inventory.GetItem(targetIndex), modKey, targetIndex
end

function Inventory.RemoveAppliedModification(targetSlotIndex, modKey)
    local targetIndex = tonumber(targetSlotIndex)
    local items = Inventory.GetItems()
    if not targetIndex or targetIndex < 1 or targetIndex > #items then
        return nil, "invalid-slot"
    end

    local targetRecord = Inventory.NormalizeInventoryItem(items[targetIndex])
    if not targetRecord or type(ModificationService.RemoveModificationFromRecord) ~= "function" then
        return nil, "missing-item"
    end

    local nextRecord, removed = ModificationService.RemoveModificationFromRecord(targetRecord, modKey)
    if not nextRecord or not removed then
        return nil, "missing-modification"
    end

    items[targetIndex] = nextRecord

    Inventory.SetItems(items, "modify-remove", {
        targetSlotIndex = targetIndex,
        modKey = removed.modKey,
        itemRef = removed.itemRef,
    })

    return Inventory.GetItem(targetIndex), removed, targetIndex
end

function Inventory.ResolveItem(itemRecord)
    local normalized = Inventory.NormalizeInventoryItem(itemRecord)
    if not normalized then
        return nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(normalized.dataset) or nil
    local item = findDatasetItem(dataset, normalized.id)
    local datasetActive = dataset ~= nil and Database.IsDatasetActivated and Database.IsDatasetActivated(dataset.id) or false

    return {
        record = normalized,
        datasetId = normalized.dataset,
        itemId = normalized.id,
        dataset = dataset,
        item = item,
        modifications = deepCopy(normalized.modifications),
        soulbound = normalized.soulbound == true,
        quantity = math.max(1, math.floor(tonumber(normalized.quantity) or 1)),
        isActive = datasetActive == true,
        isMissing = dataset == nil or item == nil,
    }
end

function Inventory.GetDisplayItems(maxItems)
    local items = Inventory.GetItems()
    local active = {}
    local inactive = {}

    for index = 1, #items do
        local resolved = Inventory.ResolveItem(items[index])
        if resolved then
            resolved.sourceIndex = index
            if resolved.isActive and not resolved.isMissing then
                active[#active + 1] = resolved
            else
                inactive[#inactive + 1] = resolved
            end
        end
    end

    local ordered = {}
    for index = 1, #active do
        ordered[#ordered + 1] = active[index]
    end
    for index = 1, #inactive do
        ordered[#ordered + 1] = inactive[index]
    end

    if maxItems and maxItems > 0 and #ordered > maxItems then
        local limited = {}
        for index = 1, maxItems do
            limited[index] = ordered[index]
        end
        return limited
    end

    return ordered
end

function Inventory.Initialize()
    return Inventory.EnsureRoot()
end

Inventory.Initialize()

local initializer = CreateFrame and CreateFrame("Frame")
if initializer then
    initializer:RegisterEvent("ADDON_LOADED")
    initializer:SetScript("OnEvent", function(_, event, loadedAddonName)
        if event ~= "ADDON_LOADED" or loadedAddonName ~= addonName then
            return
        end

        Inventory.Initialize()
    end)
end

return Inventory
