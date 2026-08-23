local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile
local Modifications = Profile.Modifications or {}
Profile.Modifications = Modifications

local Database = Addon.Internal.Database or {}
local Registry = Addon.Internal.Registry or {}

local SOCKET_TYPE_ORDER = {
    "red",
    "blue",
    "yellow",
    "orange",
    "green",
    "purple",
    "meta",
    "cogwheel",
    "prismatic",
}

local SOCKET_TYPE_FLAGS = {
    red = true,
    blue = true,
    yellow = true,
    orange = true,
    green = true,
    purple = true,
    meta = true,
    cogwheel = true,
    prismatic = true,
}

local SOCKET_COLOR_COMPONENTS = {
    red = { red = true },
    blue = { blue = true },
    yellow = { yellow = true },
    orange = { red = true, yellow = true },
    green = { blue = true, yellow = true },
    purple = { blue = true, red = true },
}

local MODIFICATION_KINDS = {
    generic = true,
    gem = true,
    enchant = true,
}

local LEGACY_ARMOR_WEIGHT_MAP = {
    light = "cloth",
    medium = "leather",
    heavy = "plate",
}

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

local function resolveCurrentTimestamp()
    if type(time) == "function" then
        return math.max(0, math.floor(tonumber(time()) or 0))
    end
    if type(GetServerTime) == "function" then
        return math.max(0, math.floor(tonumber(GetServerTime()) or 0))
    end
    return 0
end

local function buildItemRef(datasetId, itemId)
    local normalizedDatasetId = ensureString(datasetId)
    local normalizedItemId = ensureString(itemId)
    if normalizedDatasetId == "" or normalizedItemId == "" then
        return ""
    end

    return ("%s:%s"):format(normalizedDatasetId, normalizedItemId)
end

local function parseItemRef(itemRef)
    local normalizedRef = ensureString(itemRef)
    local separatorIndex = string.find(normalizedRef, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = string.sub(normalizedRef, 1, separatorIndex - 1)
    local itemId = string.sub(normalizedRef, separatorIndex + 1)
    if datasetId == "" or itemId == "" then
        return nil, nil
    end

    return datasetId, itemId
end

local function resolveItemDefinition(itemRef)
    local datasetId, itemId = parseItemRef(itemRef)
    if not datasetId or not itemId then
        return nil, nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
    if not dataset then
        return nil, nil
    end

    for index = 1, #(dataset.items or {}) do
        local item = dataset.items[index]
        if item and tostring(item.id or "") == itemId then
            return item, dataset
        end
    end

    return nil, dataset
end

local function getItemRefFromRecord(record)
    return buildItemRef(record and record.dataset, record and record.id)
end

local function isEquipmentItem(item)
    local itemType = ensureString(type(item) == "table" and item.itemType or nil)
    return itemType == "weapon" or itemType == "armor"
end

local function isModificationItem(item)
    return ensureString(type(item) == "table" and item.itemType or nil) == "modification"
end

local function hasTag(item, expectedTag)
    local normalizedExpected = string.lower(ensureString(expectedTag))
    if normalizedExpected == "" then
        return false
    end

    for index = 1, #(item and item.tags or {}) do
        if string.lower(ensureString(item.tags[index])) == normalizedExpected then
            return true
        end
    end

    return false
end

local function getModificationKind(item)
    local normalizedKind = string.lower(ensureString(type(item) == "table" and item.modificationKind or nil))
    if MODIFICATION_KINDS[normalizedKind] == true then
        return normalizedKind
    end
    if hasTag(item, "gem") then
        return "gem"
    end
    if hasTag(item, "enchant") then
        return "enchant"
    end
    return "generic"
end

local function getGemColor(item)
    local authoredColor = string.lower(ensureString(type(item) == "table" and item.gemColor or nil))
    if SOCKET_TYPE_FLAGS[authoredColor] == true then
        return authoredColor
    end

    local legacyTypes = type(item) == "table" and item.socketTypes or nil
    local legacyColor = string.lower(ensureString(type(legacyTypes) == "table" and legacyTypes[1] or nil))
    if SOCKET_TYPE_FLAGS[legacyColor] == true then
        return legacyColor
    end

    return "none"
end

local function getGenericModificationKey(item)
    return string.lower(ensureString(type(item) == "table" and item.genericModificationKey or nil)):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeArmorWeightValue(value)
    local normalized = string.lower(ensureString(value))
    return LEGACY_ARMOR_WEIGHT_MAP[normalized] or normalized
end

local function appendLegacySockets(output, color, count)
    local normalizedColor = string.lower(ensureString(color))
    if SOCKET_TYPE_FLAGS[normalizedColor] ~= true then
        return
    end

    for _ = 1, math.max(0, math.floor(tonumber(count) or 0)) do
        output[#output + 1] = {
            color = normalizedColor,
        }
    end
end

local function getItemSockets(item)
    local sockets = {}
    if type(item) == "table" and type(item.sockets) == "table" and #item.sockets > 0 then
        for index = 1, #item.sockets do
            local entry = item.sockets[index]
            local color = string.lower(ensureString(type(entry) == "table" and entry.color or entry))
            if SOCKET_TYPE_FLAGS[color] == true then
                sockets[#sockets + 1] = {
                    color = color,
                }
            end
        end
    else
        appendLegacySockets(sockets, "red", item and item.redSockets)
        appendLegacySockets(sockets, "blue", item and item.blueSockets)
        appendLegacySockets(sockets, "yellow", item and item.yellowSockets)
        appendLegacySockets(sockets, "green", item and item.greenSockets)
        appendLegacySockets(sockets, "meta", item and item.metaSockets)
        appendLegacySockets(sockets, "cogwheel", item and item.cogSockets)
        appendLegacySockets(sockets, "prismatic", item and item.prismaticSockets)
    end

    return sockets
end

local function getMaxGenericModificationCounts(item)
    local counts = {}
    local source = type(item) == "table" and (item.maxGenericModificationCounts or item.maxModificationCounts) or nil
    for key, value in pairs(type(source) == "table" and source or {}) do
        local normalizedKey = string.lower(ensureString(key))
        if normalizedKey ~= "" then
            counts[normalizedKey] = math.max(0, math.floor(tonumber(value) or 0))
        end
    end
    return counts
end

local function buildSocketRows(item)
    local sockets = getItemSockets(item)
    local rows = {}
    for index = 1, #sockets do
        rows[index] = {
            socketIndex = index,
            color = sockets[index].color,
        }
    end
    return rows
end

local function buildEffectiveSocketRows(item, modifications)
    local rows = buildSocketRows(item)
    local applied = Modifications.ListAppliedModifications(modifications)
    for index = 1, #applied do
        local modItem = applied[index] and applied[index].item or nil
        local bonusSockets = getItemSockets(modItem)
        for socketIndex = 1, #bonusSockets do
            rows[#rows + 1] = {
                socketIndex = #rows + 1,
                color = bonusSockets[socketIndex].color,
            }
        end
    end
    return rows
end

local function canGemFitSocket(gemColor, socketColor)
    local normalizedGemColor = string.lower(ensureString(gemColor))
    local normalizedSocketColor = string.lower(ensureString(socketColor))
    if SOCKET_TYPE_FLAGS[normalizedGemColor] ~= true or SOCKET_TYPE_FLAGS[normalizedSocketColor] ~= true then
        return false
    end
    if normalizedGemColor == "prismatic" then
        return true
    end
    if normalizedSocketColor == "prismatic" then
        return true
    end
    if normalizedGemColor == normalizedSocketColor then
        return true
    end
    if normalizedGemColor == "meta" or normalizedSocketColor == "meta" then
        return false
    end
    if normalizedGemColor == "cogwheel" or normalizedSocketColor == "cogwheel" then
        return false
    end

    local gemComponents = SOCKET_COLOR_COMPONENTS[normalizedGemColor]
    local socketComponents = SOCKET_COLOR_COMPONENTS[normalizedSocketColor]
    if not gemComponents or not socketComponents then
        return false
    end

    for component in pairs(socketComponents) do
        if gemComponents[component] ~= true then
            return false
        end
    end

    return true
end

local function buildGemSocketAssignments(item, modifications)
    local socketRows = buildEffectiveSocketRows(item, modifications)
    local assignments = {}
    local usedSlots = {}
    local applied = Modifications.ListAppliedModifications(modifications)

    for index = 1, #applied do
        local entry = applied[index]
        if entry and entry.modificationKind == "gem" then
            for socketIndex = 1, #socketRows do
                local socketInfo = socketRows[socketIndex]
                if not usedSlots[socketIndex] and canGemFitSocket(entry.gemColor, socketInfo and socketInfo.color) then
                    usedSlots[socketIndex] = true
                    assignments[socketIndex] = entry
                    break
                end
            end
        end
    end

    return socketRows, assignments
end

function Modifications.ComposeItemRef(datasetId, itemId)
    return buildItemRef(datasetId, itemId)
end

function Modifications.ResolveItemDefinition(itemRef)
    return resolveItemDefinition(itemRef)
end

function Modifications.GetRecordItemRef(record)
    return getItemRefFromRecord(record)
end

function Modifications.GetModificationKind(item)
    return getModificationKind(item)
end

function Modifications.GetGemColor(item)
    return getGemColor(item)
end

function Modifications.GetGenericModificationKey(item)
    return getGenericModificationKey(item)
end

function Modifications.BuildSocketRows(item)
    return buildSocketRows(item)
end

function Modifications.BuildEffectiveSocketRows(item, modifications)
    return buildEffectiveSocketRows(item, modifications)
end

function Modifications.BuildGemSocketAssignments(item, modifications)
    return buildGemSocketAssignments(item, modifications)
end

function Modifications.ListAppliedModifications(modifications)
    local rows = {}

    for modKey, modData in pairs(type(modifications) == "table" and modifications or {}) do
        local normalizedKey = ensureString(modKey)
        if string.match(normalizedKey, "^mod_") then
            local itemRef = ensureString(type(modData) == "table" and modData.itemRef or nil)
            local item, dataset = resolveItemDefinition(itemRef)
            rows[#rows + 1] = {
                modKey = normalizedKey,
                itemRef = itemRef,
                item = item,
                dataset = dataset,
                itemId = select(2, parseItemRef(itemRef)),
                appliedAt = math.max(0, math.floor(tonumber(type(modData) == "table" and modData.appliedAt or 0) or 0)),
                soulbound = type(modData) == "table" and modData.soulbound == true or false,
                modificationKind = item ~= nil and getModificationKind(item) or "generic",
                gemColor = item ~= nil and getGemColor(item) or "none",
                genericModificationKey = item ~= nil and getGenericModificationKey(item) or "",
                isGem = item ~= nil and getModificationKind(item) == "gem" or false,
                isEnchant = item ~= nil and getModificationKind(item) == "enchant" or false,
                isGeneric = item ~= nil and getModificationKind(item) == "generic" or false,
                isHidden = item ~= nil and hasTag(item, "hiddenmod") or false,
            }
        end
    end

    table.sort(rows, function(left, right)
        if left.appliedAt == right.appliedAt then
            local leftName = string.lower(ensureString(left.item and left.item.name or left.itemId or left.itemRef))
            local rightName = string.lower(ensureString(right.item and right.item.name or right.itemId or right.itemRef))
            if leftName == rightName then
                return ensureString(left.modKey) < ensureString(right.modKey)
            end
            return leftName < rightName
        end
        return left.appliedAt < right.appliedAt
    end)

    return rows
end

function Modifications.GetAggregatedBonuses(modifications)
    local bonuses = {
        stats = {},
        skills = {},
        sockets = {},
    }

    local applied = Modifications.ListAppliedModifications(modifications)
    for index = 1, #applied do
        local modItem = applied[index] and applied[index].item or nil

        for statIndex = 1, #(modItem and modItem.stats or {}) do
            local statEntry = modItem.stats[statIndex]
            local statRef = ensureString(type(statEntry) == "table" and statEntry.sourceStatRef or nil)
            local value = tonumber(type(statEntry) == "table" and statEntry.value or 0) or 0
            if statRef ~= "" and value ~= 0 then
                bonuses.stats[statRef] = (bonuses.stats[statRef] or 0) + value
            end
        end

        for skillIndex = 1, #(modItem and modItem.skillBonuses or {}) do
            local skillEntry = modItem.skillBonuses[skillIndex]
            local skillRef = ensureString(type(skillEntry) == "table" and skillEntry.skillRef or nil)
            local value = tonumber(type(skillEntry) == "table" and skillEntry.value or 0) or 0
            if skillRef ~= "" and value ~= 0 then
                bonuses.skills[skillRef] = (bonuses.skills[skillRef] or 0) + value
            end
        end
    end

    return bonuses
end

function Modifications.BuildEffectiveSocketCounts(item, modifications)
    local counts = {}
    local rows = buildEffectiveSocketRows(item, modifications)
    for index = 1, #SOCKET_TYPE_ORDER do
        counts[SOCKET_TYPE_ORDER[index]] = 0
    end
    for index = 1, #rows do
        local color = rows[index].color
        counts[color] = (counts[color] or 0) + 1
    end
    return counts
end

function Modifications.GetModificationUsageSummary(targetRecord, modificationItemRef)
    local targetItemRef = getItemRefFromRecord(targetRecord)
    local targetItem = resolveItemDefinition(targetItemRef)
    local modItem = resolveItemDefinition(modificationItemRef)
    local summary = {
        current = 0,
        max = 0,
        modificationKind = modItem ~= nil and getModificationKind(modItem) or "generic",
    }

    if not targetItem or not modItem then
        return summary
    end

    local applied = targetRecord and targetRecord.modifications or {}
    local appliedMods = Modifications.ListAppliedModifications(applied)
    local modificationKind = getModificationKind(modItem)
    summary.modificationKind = modificationKind

    if modificationKind == "enchant" then
        summary.max = 1
        for index = 1, #appliedMods do
            if appliedMods[index].modificationKind == "enchant" then
                summary.current = summary.current + 1
            end
        end
        return summary
    end

    if modificationKind == "gem" then
        local gemColor = getGemColor(modItem)
        local socketRows = buildEffectiveSocketRows(targetItem, applied)
        for index = 1, #socketRows do
            if canGemFitSocket(gemColor, socketRows[index] and socketRows[index].color) then
                summary.max = summary.max + 1
            end
        end
        for index = 1, #appliedMods do
            if appliedMods[index].itemRef == modificationItemRef then
                summary.current = summary.current + 1
            end
        end
        return summary
    end

    local genericKey = getGenericModificationKey(modItem)
    local maxCounts = getMaxGenericModificationCounts(targetItem)
    summary.max = math.max(0, math.floor(tonumber(maxCounts[genericKey]) or 0))
    for index = 1, #appliedMods do
        if appliedMods[index].modificationKind == "generic" and appliedMods[index].genericModificationKey == genericKey then
            summary.current = summary.current + 1
        end
    end
    return summary
end

function Modifications.CanApplyModificationToRecord(targetRecord, modificationRecord, slotRef)
    local targetItemRef = getItemRefFromRecord(targetRecord)
    local modificationItemRef = getItemRefFromRecord(modificationRecord)
    local targetItem = resolveItemDefinition(targetItemRef)
    local modItem = resolveItemDefinition(modificationItemRef)

    if not targetItem or not modItem then
        return false, "missing-item"
    end
    if not isEquipmentItem(targetItem) then
        return false, "invalid-target"
    end
    if not isModificationItem(modItem) then
        return false, "invalid-modification"
    end

    local applied = targetRecord and targetRecord.modifications or {}
    local appliedMods = Modifications.ListAppliedModifications(applied)
    local modificationKind = getModificationKind(modItem)

    if modificationKind ~= "gem" then
        if #(modItem.targetSlotRefs or {}) > 0 then
            local matched = false
            if type(slotRef) == "string" and slotRef ~= "" then
                for index = 1, #(modItem.targetSlotRefs or {}) do
                    if modItem.targetSlotRefs[index] == slotRef then
                        matched = true
                        break
                    end
                end
            end
            if not matched then
                for modIndex = 1, #(modItem.targetSlotRefs or {}) do
                    local targetSlotRef = modItem.targetSlotRefs[modIndex]
                    for targetIndex = 1, #(targetItem.validSlotRefs or {}) do
                        if targetItem.validSlotRefs[targetIndex] == targetSlotRef then
                            matched = true
                            break
                        end
                    end
                    if matched then
                        break
                    end
                end
            end
            if not matched then
                return false, "slot-mismatch"
            end
        end

        local targetWeaponTypeRef = ensureString(targetItem.weaponTypeRef)
        local requiredWeaponTypeRef = ensureString(modItem.targetWeaponTypeRef)
        if requiredWeaponTypeRef ~= ""
            and type(Registry.ResolveWeaponTypeReference) == "function"
            and select(2, Registry:ResolveWeaponTypeReference(requiredWeaponTypeRef)) == nil
        then
            return false, "weapon-type-mismatch"
        end
        if requiredWeaponTypeRef ~= "" and requiredWeaponTypeRef ~= targetWeaponTypeRef then
            return false, "weapon-type-mismatch"
        end
        if modItem.targetTwoHandedOnly == true and (targetItem.itemType ~= "weapon" or targetItem.isTwoHanded ~= true) then
            return false, "weapon-type-mismatch"
        end

        local targetArmorWeight = normalizeArmorWeightValue(targetItem.armorWeight)
        local requiredArmorWeight = normalizeArmorWeightValue(modItem.targetArmorWeight)
        if requiredArmorWeight ~= "" and requiredArmorWeight ~= "none" and targetArmorWeight ~= requiredArmorWeight then
            return false, "armor-weight-mismatch"
        end
    end

    if modificationKind == "enchant" then
        for index = 1, #appliedMods do
            if appliedMods[index].modificationKind == "enchant" then
                return false, "enchant-limit"
            end
        end
        return true
    end

    if modificationKind == "gem" then
        local gemColor = getGemColor(modItem)
        if gemColor == "none" then
            return false, "missing-gem-color"
        end

        local socketRows, assignments = buildGemSocketAssignments(targetItem, applied)
        local hasFreeSocket = false
        for index = 1, #socketRows do
            if assignments[index] == nil and canGemFitSocket(gemColor, socketRows[index] and socketRows[index].color) then
                hasFreeSocket = true
                break
            end
        end
        if not hasFreeSocket then
            return false, "no-matching-socket"
        end

        return true
    end

    local genericKey = getGenericModificationKey(modItem)
    if genericKey == "" then
        return false, "missing-generic-key"
    end

    local maxCounts = getMaxGenericModificationCounts(targetItem)
    local maxAllowed = math.max(0, math.floor(tonumber(maxCounts[genericKey]) or 0))
    if maxAllowed <= 0 then
        return false, "generic-key-limit"
    end

    local currentCount = 0
    for index = 1, #appliedMods do
        if appliedMods[index].modificationKind == "generic" and appliedMods[index].genericModificationKey == genericKey then
            currentCount = currentCount + 1
        end
    end
    if currentCount >= maxAllowed then
        return false, "generic-key-limit"
    end

    return true
end

function Modifications.GetCompatibleModificationChoices(targetRecord, inventoryItems, slotRef)
    local grouped = {}
    local ordered = {}

    for index = 1, #(inventoryItems or {}) do
        local candidate = inventoryItems[index]
        local ok = Modifications.CanApplyModificationToRecord(targetRecord, candidate, slotRef)
        if ok then
            local itemRef = getItemRefFromRecord(candidate)
            local item, dataset = resolveItemDefinition(itemRef)
            local quantity = math.max(1, math.floor(tonumber(candidate and candidate.quantity) or 1))
            local bucket = grouped[itemRef]
            if not bucket then
                bucket = {
                    itemRef = itemRef,
                    item = item,
                    dataset = dataset,
                    sourceIndices = {},
                    quantity = 0,
                }
                grouped[itemRef] = bucket
                ordered[#ordered + 1] = bucket
            end
            bucket.quantity = bucket.quantity + quantity
            bucket.sourceIndices[#bucket.sourceIndices + 1] = index
        end
    end

    table.sort(ordered, function(left, right)
        local leftName = string.lower(ensureString(left.item and left.item.name or left.itemRef))
        local rightName = string.lower(ensureString(right.item and right.item.name or right.itemRef))
        if leftName == rightName then
            return ensureString(left.itemRef) < ensureString(right.itemRef)
        end
        return leftName < rightName
    end)

    for index = 1, #ordered do
        local entry = ordered[index]
        entry.sourceIndex = entry.sourceIndices[1]
    end

    return ordered
end

function Modifications.AddModificationToRecord(record, modificationRecord)
    local itemRef = getItemRefFromRecord(modificationRecord)
    if itemRef == "" then
        return nil, nil
    end

    local nextRecord = deepCopy(record)
    nextRecord.modifications = type(nextRecord.modifications) == "table" and deepCopy(nextRecord.modifications) or {}

    local modIndex = 1
    local modKey = ("mod_%s_%d"):format(itemRef, modIndex)
    while nextRecord.modifications[modKey] ~= nil do
        modIndex = modIndex + 1
        modKey = ("mod_%s_%d"):format(itemRef, modIndex)
    end

    nextRecord.modifications[modKey] = {
        itemRef = itemRef,
        appliedAt = resolveCurrentTimestamp(),
        soulbound = modificationRecord and modificationRecord.soulbound == true or false,
    }

    return nextRecord, modKey
end

function Modifications.RemoveModificationFromRecord(record, modKey)
    local normalizedKey = ensureString(modKey)
    if normalizedKey == "" then
        return nil, nil
    end

    local existing = type(record) == "table" and type(record.modifications) == "table" and record.modifications[normalizedKey] or nil
    if type(existing) ~= "table" then
        return nil, nil
    end

    local nextRecord = deepCopy(record)
    nextRecord.modifications = type(nextRecord.modifications) == "table" and deepCopy(nextRecord.modifications) or {}
    nextRecord.modifications[normalizedKey] = nil

    return nextRecord, {
        modKey = normalizedKey,
        itemRef = ensureString(existing.itemRef),
        soulbound = existing.soulbound == true,
        appliedAt = math.max(0, math.floor(tonumber(existing.appliedAt) or 0)),
    }
end

return Modifications
