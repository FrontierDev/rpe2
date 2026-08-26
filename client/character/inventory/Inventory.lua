local addonName, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Inventory = Addon.Client.Inventory or {}

local Inventory = Addon.Client.Inventory
local Database = Addon.Internal and Addon.Internal.Database or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local ModificationService = Profile and Profile.Modifications or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}

local function startTiming(label, thresholdMs, context)
    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Start) == "function" then
        if type(timings.IsEnabled) == "function" and not timings:IsEnabled() then
            return nil
        end
        return timings:Start(label, {
            thresholdMs = thresholdMs,
            context = context,
        })
    end
    return nil
end

local function stopTiming(timer, cardinality)
    if not timer then
        return
    end

    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Stop) == "function" then
        timings:Stop(timer, { cardinality = cardinality })
    end
end

local function getItemClass()
    return Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Item or nil
end

local SCHEMA_VERSION = 1
local DEFAULT_ROOT_NAME = "RPEngineInventoryDB"
local CANONICAL_ADD_NOTIFICATION = {}

Inventory._changeListeners = Inventory._changeListeners or {}
Inventory._nextChangeListenerId = Inventory._nextChangeListenerId or 0
Inventory.RuntimeByCharacter = Inventory.RuntimeByCharacter or {}
Inventory._fallbackRevision = tonumber(Inventory._fallbackRevision) or 0

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

local function deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue, seen)
    end

    return copy
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

local function getItemRef(datasetId, itemId)
    local normalizedDatasetId = ensureString(datasetId)
    local normalizedItemId = ensureString(itemId)
    if normalizedDatasetId == "" or normalizedItemId == "" then
        return ""
    end

    return ("%s:%s"):format(normalizedDatasetId, normalizedItemId)
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

-- Stable serialization is used only at canonicalization and mutation
-- boundaries. Sorting keys makes equivalent modification maps produce the
-- same identity regardless of Lua's table iteration order.
local function sortedTableKeys(source)
    local keys = {}
    for key in pairs(source or {}) do
        keys[#keys + 1] = key
    end

    local typeOrder = {
        ["nil"] = 1,
        boolean = 2,
        number = 3,
        string = 4,
        table = 5,
        ["function"] = 6,
        thread = 7,
        userdata = 8,
    }
    table.sort(keys, function(left, right)
        local leftType = type(left)
        local rightType = type(right)
        if leftType ~= rightType then
            return (typeOrder[leftType] or 99) < (typeOrder[rightType] or 99)
        end
        if leftType == "number" then
            return left < right
        end

        return tostring(left) < tostring(right)
    end)

    return keys
end

local function stableSerialize(value, seen, nextId)
    local valueType = type(value)
    if valueType == "nil" then
        return "nil"
    end
    if valueType == "boolean" then
        return value and "boolean:true" or "boolean:false"
    end
    if valueType == "number" then
        if value ~= value then
            return "number:nan"
        end
        if value == math.huge then
            return "number:infinity"
        end
        if value == -math.huge then
            return "number:-infinity"
        end
        return "number:" .. tostring(value)
    end
    if valueType == "string" then
        return "string:" .. string.format("%q", value)
    end
    if valueType ~= "table" then
        return valueType .. ":" .. tostring(value)
    end

    seen = seen or {}
    nextId = nextId or { value = 0 }
    if seen[value] then
        return "table-ref:" .. tostring(seen[value])
    end

    nextId.value = nextId.value + 1
    seen[value] = nextId.value
    local parts = {}
    local keys = sortedTableKeys(value)
    for index = 1, #keys do
        local key = keys[index]
        parts[#parts + 1] = stableSerialize(key, seen, nextId)
            .. "="
            .. stableSerialize(value[key], seen, nextId)
    end

    return "table:{" .. table.concat(parts, ";") .. "}"
end

local function getModificationSignature(record)
    return stableSerialize(record and record.modifications or {})
end

local function getStackIdentity(record, modificationSignature)
    local signature = modificationSignature or getModificationSignature(record)
    return table.concat({
        getItemRef(record and record.dataset, record and record.id),
        record and record.soulbound == true and "true" or "false",
        signature,
    }, "|")
end

local function copyCanonicalRecord(record)
    if type(record) ~= "table" then
        return nil
    end

    return {
        dataset = record.dataset,
        id = record.id,
        modifications = deepCopy(record.modifications or {}),
        soulbound = record.soulbound == true,
        quantity = math.max(1, math.floor(tonumber(record.quantity) or 1)),
    }
end

local function getRawCharacterInventory()
    local root = Inventory.EnsureRoot()
    local characterKey = getCharacterKey()
    local inventory = root.inventoriesByChar[characterKey]
    if type(inventory) ~= "table" then
        inventory = {}
        root.inventoriesByChar[characterKey] = inventory
    end
    if type(inventory.items) ~= "table" then
        inventory.items = {}
    end

    return inventory, characterKey
end

local function getRuntimeState(characterKey)
    local state = Inventory.RuntimeByCharacter[characterKey]
    if type(state) ~= "table" then
        state = {}
        Inventory.RuntimeByCharacter[characterKey] = state
    end

    state.stackIndex = state.stackIndex or {}
    state.variantIndex = state.variantIndex or {}
    state.indexByRecord = state.indexByRecord or {}
    return state
end

local invalidateDisplaySnapshot

local function removeRecordFromIndex(state, record)
    local entry = state and state.indexByRecord and state.indexByRecord[record] or nil
    if not entry then
        return false
    end

    local bucket = state.stackIndex[entry.stackKey]
    if type(bucket) == "table" then
        local position = tonumber(entry.bucketPosition) or 0
        if position >= 1 and bucket[position] == record then
            table.remove(bucket, position)
            for index = position, #bucket do
                local shifted = state.indexByRecord[bucket[index]]
                if shifted then
                    shifted.bucketPosition = index
                end
            end
        else
            for index = #bucket, 1, -1 do
                if bucket[index] == record then
                    table.remove(bucket, index)
                    for shiftedIndex = index, #bucket do
                        local shifted = state.indexByRecord[bucket[shiftedIndex]]
                        if shifted then
                            shifted.bucketPosition = shiftedIndex
                        end
                    end
                    break
                end
            end
        end

        if #bucket == 0 then
            state.stackIndex[entry.stackKey] = nil
            local variants = state.variantIndex[entry.itemRef]
            if variants and variants[entry.stackKey] == bucket then
                variants[entry.stackKey] = nil
                if next(variants) == nil then
                    state.variantIndex[entry.itemRef] = nil
                end
            end
        end
    end

    state.indexByRecord[record] = nil
    return true
end

local function addRecordToIndex(state, record, index, stackKey, modificationSignature)
    if type(record) ~= "table" then
        return nil
    end

    local resolvedStackKey = stackKey or getStackIdentity(record)
    local itemRef = getItemRef(record.dataset, record.id)
    local bucket = state.stackIndex[resolvedStackKey]
    if type(bucket) ~= "table" then
        bucket = {}
        state.stackIndex[resolvedStackKey] = bucket
    end

    bucket[#bucket + 1] = record
    state.indexByRecord[record] = {
        index = index,
        stackKey = resolvedStackKey,
        itemRef = itemRef,
        signature = modificationSignature or getModificationSignature(record),
        bucketPosition = #bucket,
    }

    state.variantIndex[itemRef] = state.variantIndex[itemRef] or {}
    state.variantIndex[itemRef][resolvedStackKey] = bucket
    return state.indexByRecord[record]
end

local function rebuildIndexes(state, items)
    state.stackIndex = {}
    state.variantIndex = {}
    state.indexByRecord = {}
    for index = 1, #(items or {}) do
        addRecordToIndex(state, items[index], index)
    end
end

local function reindexFrom(state, items, startIndex)
    local firstIndex = math.max(1, math.floor(tonumber(startIndex) or 1))
    for index = firstIndex, #(items or {}) do
        local record = items[index]
        local entry = state.indexByRecord[record]
        if entry then
            entry.index = index
        else
            addRecordToIndex(state, record, index)
        end
    end
end

local function insertIndexedRecord(state, items, index, record, stackKey)
    table.insert(items, index, record)
    addRecordToIndex(state, record, index, stackKey)
    reindexFrom(state, items, index + 1)
end

local function replaceIndexedRecord(state, items, index, record, stackKey)
    local previous = items[index]
    if previous == record then
        return
    end

    removeRecordFromIndex(state, previous)
    items[index] = record
    addRecordToIndex(state, record, index, stackKey)
end

local function removeIndexedRecord(state, items, index)
    local record = items[index]
    if not record then
        return nil
    end

    removeRecordFromIndex(state, record)
    table.remove(items, index)
    reindexFrom(state, items, index)
    return record
end

local function canonicalizeInventory(inventory, state)
    local source = ensureTable(inventory.items)
    local canonicalItems = {}
    for index = 1, #source do
        local normalized = Inventory.NormalizeInventoryItem(source[index])
        if normalized then
            canonicalItems[#canonicalItems + 1] = normalized
        end
    end

    inventory.items = canonicalItems
    state.canonicalized = true
    state.items = canonicalItems
    state.itemCount = #canonicalItems
    rebuildIndexes(state, canonicalItems)
    invalidateDisplaySnapshot(state)
    return canonicalItems
end

local function ensureRuntimeState(inventory, characterKey, force)
    local state = getRuntimeState(characterKey)
    local items = ensureTable(inventory.items)
    if inventory.items ~= items then
        inventory.items = items
    end

    if force
        or state.canonicalized ~= true
        or state.items ~= items
        or tonumber(state.itemCount) ~= #items
    then
        canonicalizeInventory(inventory, state)
    end

    return state
end

function Inventory.GetCharacterInventory()
    local inventory, characterKey = getRawCharacterInventory()
    ensureRuntimeState(inventory, characterKey)
    return inventory
end

function Inventory.InvalidateRuntimeState()
    local characterKey = getCharacterKey()
    local state = Inventory.RuntimeByCharacter[characterKey]
    if type(state) == "table" then
        state.canonicalized = false
        state.items = nil
        state.itemCount = nil
        invalidateDisplaySnapshot(state)
    end
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

local function resolveCanonicalItemDefinition(itemRecord)
    if type(itemRecord) ~= "table" then
        return nil, nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(itemRecord.dataset) or nil
    local item = findDatasetItem(dataset, itemRecord.id)
    return dataset, item
end

local function resolveItemDefinition(itemRecord)
    local normalized = Inventory.NormalizeInventoryItem(itemRecord)
    if not normalized then
        return nil, nil, nil
    end

    local dataset, item = resolveCanonicalItemDefinition(normalized)
    return dataset, item, normalized
end

local function getStackMetadata(itemDefinition)
    if type(itemDefinition) ~= "table" or itemDefinition.canStack ~= true then
        return false, 1
    end

    return true, math.max(1, math.floor(tonumber(itemDefinition.maxStackSize) or 1))
end

local function getStackCandidates(state, stackKey)
    local bucket = state.stackIndex[stackKey]
    if type(bucket) ~= "table" or #bucket == 0 then
        return {}
    end

    local candidates = {}
    for index = 1, #bucket do
        candidates[index] = bucket[index]
    end
    table.sort(candidates, function(left, right)
        local leftEntry = state.indexByRecord[left]
        local rightEntry = state.indexByRecord[right]
        return (leftEntry and leftEntry.index or 0) < (rightEntry and rightEntry.index or 0)
    end)
    return candidates
end

local function getRuntimeRevision(domain)
    if type(Runtime) == "table" and type(Runtime.GetRevision) == "function" then
        return math.max(0, math.floor(tonumber(Runtime:GetRevision(domain)) or 0))
    end

    if domain == "InventoryRevision" then
        return math.max(0, math.floor(tonumber(Inventory._fallbackRevision) or 0))
    end

    return 0
end

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function getCurrentTransaction()
    if type(Runtime) == "table" and type(Runtime.GetCurrentTransaction) == "function" then
        return Runtime:GetCurrentTransaction()
    end

    return nil
end

local function getPendingGainBucket(stackKey, create)
    local transaction = getCurrentTransaction()
    if type(transaction) ~= "table" or type(stackKey) ~= "string" or stackKey == "" then
        return nil
    end

    transaction.inventoryPendingGains = transaction.inventoryPendingGains or {}
    local bucket = transaction.inventoryPendingGains[stackKey]
    if not bucket and create then
        bucket = {}
        transaction.inventoryPendingGains[stackKey] = bucket
    end
    return bucket
end

local function settlePendingGains(mutation)
    if type(mutation) ~= "table" then
        return
    end

    local stackKey = mutation.stackKey
    local bucket = getPendingGainBucket(stackKey, false)
    if type(bucket) ~= "table" then
        return
    end

    local remaining = math.max(0, math.floor(tonumber(mutation.removedQuantity) or 0))
    if remaining <= 0 then
        return
    end

    -- Removal/rollback walks the newest matching stacks first. Mirror that
    -- ownership order when netting multiple pending gains for one variant.
    for index = #bucket, 1, -1 do
        if remaining <= 0 then
            break
        end

        local pending = bucket[index]
        local available = math.max(0, math.floor(tonumber(pending.remaining) or 0))
        local settled = math.min(available, remaining)
        if settled > 0 then
            pending.remaining = available - settled
            pending.payload.settledQuantity = pending.remaining
            remaining = remaining - settled
        end

        if pending.remaining <= 0 then
            table.remove(bucket, index)
        end
    end
end

local function queuePendingGain(mutation)
    local requestedQuantity = mutation.actualAddedQuantity or mutation.quantity
    local quantity = math.max(0, math.floor(tonumber(requestedQuantity) or 0))
    if quantity <= 0 then
        return
    end

    local payload = mutation
    payload.settledQuantity = quantity
    local bucket = getPendingGainBucket(payload.stackKey, true)
    if bucket then
        bucket[#bucket + 1] = {
            payload = payload,
            remaining = quantity,
        }
    end

    Runtime:EmitMutationEvent("item_gain", payload)
end

local function appendSearchValue(buffer, value)
    local text = ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
    if text ~= "" then
        buffer[#buffer + 1] = string.lower(text)
    end
end

local function appendSearchValues(buffer, values)
    for index = 1, #(values or {}) do
        appendSearchValue(buffer, values[index])
    end
end

local QUALITY_LABELS = {
    poor = "Poor",
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    epic = "Epic",
    legendary = "Legendary",
}

local ITEM_TYPE_LABELS = {
    weapon = "Weapon",
    armor = "Armor",
    tool = "Tool",
    consumable = "Consumable",
    material = "Material",
    modification = "Modification",
    none = "Item",
}

local function getQualityLabel(quality)
    local key = tostring(quality or "common")
    return QUALITY_LABELS[key] or tostring(quality or "Common")
end

local function getItemTypeLabel(itemType)
    local key = tostring(itemType or "none")
    return ITEM_TYPE_LABELS[key] or tostring(itemType or "Item")
end

local function buildNormalizedSearchText(dataset, item, record)
    local values = {}
    appendSearchValue(values, item and item.name)
    appendSearchValue(values, record and record.id)
    appendSearchValue(values, dataset and dataset.id or record and record.dataset)
    appendSearchValue(values, dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or nil)
    appendSearchValue(values, item and getItemTypeLabel(item.itemType) or nil)
    appendSearchValue(values, item and getQualityLabel(item.quality) or nil)
    appendSearchValues(values, item and item.tags or nil)
    return table.concat(values, "\n")
end

local function getActiveDatasetSet()
    if type(Database.ListActivatedDatasetIds) ~= "function" then
        return nil
    end

    local active = {}
    local activated = Database.ListActivatedDatasetIds() or {}
    for index = 1, #activated do
        active[tostring(activated[index] or "")] = true
    end
    return active
end

local function buildDisplayEntry(record, sourceIndex, stackIdentity, knownDataset, knownItem, activeDatasets)
    local dataset, item = knownDataset, knownItem
    if dataset == nil and item == nil then
        dataset, item = resolveCanonicalItemDefinition(record)
    end
    local isMissing = dataset == nil or item == nil
    local isActive
    if activeDatasets then
        isActive = dataset ~= nil and activeDatasets[tostring(dataset.id or "")] == true
    else
        isActive = dataset ~= nil
            and Database.IsDatasetActivated
            and Database.IsDatasetActivated(dataset.id) == true
            or false
    end
    local quality = item and tostring(item.quality or "common") or "common"
    local itemType = item and tostring(item.itemType or "none") or "none"

    return {
        sourceIndex = sourceIndex,
        stackIdentity = stackIdentity,
        record = record,
        datasetId = record.dataset,
        itemId = record.id,
        dataset = dataset,
        item = item,
        isActive = isActive,
        isMissing = isMissing,
        quantity = math.max(1, math.floor(tonumber(record.quantity) or 1)),
        soulbound = record.soulbound == true,
        modifications = record.modifications,
        quality = quality,
        itemType = itemType,
        tags = item and type(item.tags) == "table" and item.tags or {},
        normalizedSearchText = buildNormalizedSearchText(dataset, item, record),
    }
end

invalidateDisplaySnapshot = function(state)
    if type(state) ~= "table" then
        return
    end

    state.displaySnapshot = nil
    state.displaySnapshotInventoryRevision = -1
    state.displaySnapshotConfigurationRevision = -1
end

local function buildDisplaySnapshot(inventory, state, inventoryRevision, configurationRevision)
    local active = {}
    local inactive = {}
    local items = inventory.items or {}
    local activeDatasets = getActiveDatasetSet()

    for index = 1, #items do
        local record = items[index]
        local indexEntry = state.indexByRecord[record]
        local resolved = buildDisplayEntry(
            record,
            index,
            indexEntry and indexEntry.stackKey or nil,
            nil,
            nil,
            activeDatasets
        )
        if resolved.isActive and not resolved.isMissing then
            active[#active + 1] = resolved
        else
            inactive[#inactive + 1] = resolved
        end
    end

    local snapshot = {}
    for index = 1, #active do
        snapshot[#snapshot + 1] = active[index]
    end
    for index = 1, #inactive do
        snapshot[#snapshot + 1] = inactive[index]
    end

    -- Assign only after every entry is complete so callers never observe a
    -- partially-built presentation snapshot.
    state.displaySnapshot = snapshot
    state.displaySnapshotInventoryRevision = inventoryRevision
    state.displaySnapshotConfigurationRevision = configurationRevision
    return snapshot, #active, #inactive
end

function Inventory.GetDisplaySnapshot()
    local timer = startTiming("Inventory.GetDisplaySnapshot", 4, "display-snapshot")
    local inventory = Inventory.GetCharacterInventory()
    local characterKey = getCharacterKey()
    local state = getRuntimeState(characterKey)
    local inventoryRevision = getRuntimeRevision("InventoryRevision")
    local configurationRevision = getConfigurationRevision()

    if state.displaySnapshot
        and state.displaySnapshotInventoryRevision == inventoryRevision
        and state.displaySnapshotConfigurationRevision == configurationRevision
    then
        if timer then
            stopTiming(timer, {
                inventoryStacks = #inventory.items,
                resolvedItems = #state.displaySnapshot,
                cached = true,
            })
        end
        return state.displaySnapshot
    end

    -- An old snapshot is the only presentation state that is safe to expose
    -- while an authoritative transaction is still open. The post-commit
    -- listener invalidates it after the revision is published.
    if getCurrentTransaction() ~= nil and state.displaySnapshot then
        if timer then
            stopTiming(timer, {
                inventoryStacks = #inventory.items,
                resolvedItems = #state.displaySnapshot,
                deferred = true,
            })
        end
        return state.displaySnapshot
    end

    local snapshot, activeCount, inactiveCount = buildDisplaySnapshot(
        inventory,
        state,
        inventoryRevision,
        configurationRevision
    )
    if timer then
        stopTiming(timer, {
            inventoryStacks = #inventory.items,
            resolvedItems = #snapshot,
            activeItems = activeCount,
            inactiveItems = inactiveCount,
            cached = false,
        })
    end
    return snapshot
end

local dispatchInventoryPayload

local function buildInventoryMutationDetail(changeType, detail, notificationToken)
    local result = type(detail) == "table" and deepCopy(detail) or {}
    result.changeType = tostring(changeType or result.changeType or "set")
    result.characterKey = getCharacterKey()
    result.isCanonicalAdd = notificationToken == CANONICAL_ADD_NOTIFICATION
    return result
end

local function markInventoryMutation(changeType, detail, notificationToken)
    local mutation = buildInventoryMutationDetail(changeType, detail, notificationToken)
    if type(Runtime) == "table" and type(Runtime.MarkChanged) == "function" then
        if mutation.changeType == "remove" or mutation.changeType == "remove-variant"
            or mutation.changeType == "modify-apply"
        then
            settlePendingGains(mutation)
        end
        Runtime:MarkChanged("inventory", mutation)
        if mutation.isCanonicalAdd == true
            and type(Runtime.EmitMutationEvent) == "function"
        then
            -- Achievement item gains are authoritative dependent work. Queue
            -- a transaction-local pending payload so same-transaction rollback
            -- can settle it before the before-commit processor runs.
            queuePendingGain(mutation)
        end
        return mutation
    end

    Inventory._fallbackRevision = math.max(0, tonumber(Inventory._fallbackRevision) or 0) + 1
    local characterKey = getCharacterKey()
    local state = Inventory.RuntimeByCharacter[characterKey]
    invalidateDisplaySnapshot(state)
    dispatchInventoryPayload({
        inventory = {
            changed = true,
            mutations = { mutation },
            mutationCount = 1,
            revisions = { InventoryRevision = Inventory._fallbackRevision },
        },
    }, nil)
    return mutation
end

local function runMutation(reason, callback)
    if type(Runtime) == "table" and type(Runtime.RunTransaction) == "function" then
        return Runtime:RunTransaction(reason, callback)
    end

    return callback()
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
    -- The canonical list is owned by the Inventory runtime. Normal reads do
    -- not allocate replacement records or rewrite SavedVariables.
    return inventory.items
end

function Inventory.SetItems(items, changeType, detail, notificationToken)
    local timer = startTiming("Inventory.SetItems", 4, changeType or "set")
    local result = runMutation("inventory:" .. tostring(changeType or "set"), function()
        local inventory = Inventory.GetCharacterInventory()
        local source = type(items) == "table" and items or {}
        local normalizedItems = {}

        for index = 1, #source do
            local normalized = Inventory.NormalizeInventoryItem(source[index])
            if normalized then
                normalizedItems[#normalizedItems + 1] = normalized
            end
        end

        inventory.items = normalizedItems
        local characterKey = getCharacterKey()
        local state = getRuntimeState(characterKey)
        -- The replacement list was normalized above. Publish it directly to
        -- the session state and rebuild the non-persisted indexes once.
        state.canonicalized = true
        state.items = normalizedItems
        state.itemCount = #normalizedItems
        rebuildIndexes(state, normalizedItems)

        local mutation = type(detail) == "table" and deepCopy(detail) or {}
        mutation.structural = true
        mutation.fullRefresh = true
        mutation.bulk = true
        mutation.slots = mutation.slots or {}
        mutation.changeType = changeType or "set"
        markInventoryMutation(changeType or "set", mutation, notificationToken)
        return inventory.items
    end)
    if timer then
        stopTiming(timer, {
            inventoryStacks = #(result or {}),
            resolvedItems = #(result or {}),
            mutationCount = 1,
        })
    end
    return result
end

local function addItemInternal(normalized, itemDefinition)
    local timer = startTiming("Inventory.AddItem", 4, "inventory-add")
    local inventory = Inventory.GetCharacterInventory()
    local characterKey = getCharacterKey()
    local state = getRuntimeState(characterKey)
    local items = inventory.items
    local canStack, maxStackSize = getStackMetadata(itemDefinition)
    local remaining = math.max(1, math.floor(tonumber(normalized.quantity) or 1))
    local actualAddedQuantity = remaining
    local addedStackCount = 0
    local affectedSlots = {}

    normalized.quantity = 1
    local modificationSignature = getModificationSignature(normalized)
    local stackKey = getStackIdentity(normalized, modificationSignature)
    if canStack then
        local candidates = getStackCandidates(state, stackKey)
        for index = 1, #candidates do
            local existing = candidates[index]
            local entry = state.indexByRecord[existing]
            local existingIndex = entry and entry.index or nil
            local existingQuantity = math.max(1, math.floor(tonumber(existing and existing.quantity) or 1))
            if existingIndex and existingQuantity < maxStackSize then
                local addAmount = math.min(maxStackSize - existingQuantity, remaining)
                existing.quantity = existingQuantity + addAmount
                affectedSlots[#affectedSlots + 1] = existingIndex
                remaining = remaining - addAmount
                if remaining <= 0 then
                    break
                end
            end
        end
    end

    while remaining > 0 do
        local nextRecord = copyCanonicalRecord(normalized)
        nextRecord.quantity = canStack and math.min(maxStackSize, remaining) or 1
        items[#items + 1] = nextRecord
        addRecordToIndex(state, nextRecord, #items, stackKey, modificationSignature)
        affectedSlots[#affectedSlots + 1] = #items
        addedStackCount = addedStackCount + 1
        remaining = remaining - nextRecord.quantity
    end

    state.itemCount = #items
    markInventoryMutation("add", {
        dataset = normalized.dataset,
        itemId = normalized.id,
        itemRef = getItemRef(normalized.dataset, normalized.id),
        stackKey = stackKey,
        quantity = actualAddedQuantity,
        actualAddedQuantity = actualAddedQuantity,
        addedRefs = { getItemRef(normalized.dataset, normalized.id) },
        slots = affectedSlots,
        addedStackCount = addedStackCount,
        source = "inventory-add",
    }, CANONICAL_ADD_NOTIFICATION)

    if timer then
        stopTiming(timer, {
            inventoryStacks = #items,
            affectedStacks = #affectedSlots,
            addedStacks = addedStackCount,
            actualAddedQuantity = actualAddedQuantity,
        })
    end
    return normalized, #items
end

function Inventory.AddItem(itemRecord)
    local normalized = Inventory.NormalizeInventoryItem(itemRecord)
    if not normalized then
        return nil
    end

    local _, itemDefinition = resolveCanonicalItemDefinition(normalized)
    local itemClass = getItemClass()
    if itemClass and itemClass.IsBindOnPickup and itemClass.IsBindOnPickup(itemDefinition) then
        normalized.soulbound = true
    end

    return runMutation("inventory:add", function()
        return addItemInternal(normalized, itemDefinition)
    end)
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
        quantity = resolved.quantity,
    })
end

local function setItemSoulboundInternal(slotIndex, soulbound, quantity)
    local inventory = Inventory.GetCharacterInventory()
    local characterKey = getCharacterKey()
    local state = getRuntimeState(characterKey)
    local items = inventory.items
    local index = tonumber(slotIndex)
    if not index or index < 1 or index > #items then
        return nil
    end

    local record = items[index]
    local desiredSoulbound = soulbound == true
    local existingQuantity = math.max(1, math.floor(tonumber(record.quantity) or 1))
    local bindQuantity = math.max(1, math.floor(tonumber(quantity) or existingQuantity))
    bindQuantity = math.min(existingQuantity, bindQuantity)

    if record.soulbound == desiredSoulbound and bindQuantity >= existingQuantity then
        return record, index
    end

    local affectedSlots = { index }
    if bindQuantity >= existingQuantity then
        removeRecordFromIndex(state, record)
        record.soulbound = desiredSoulbound
        addRecordToIndex(state, record, index)
    else
        record.quantity = existingQuantity - bindQuantity
        local splitRecord = copyCanonicalRecord(record)
        splitRecord.quantity = bindQuantity
        splitRecord.soulbound = desiredSoulbound
        insertIndexedRecord(state, items, index + 1, splitRecord)
        affectedSlots[#affectedSlots + 1] = index + 1
        index = index + 1
    end

    state.itemCount = #items
    markInventoryMutation(desiredSoulbound and "bind" or "unbind", {
        slotIndex = tonumber(slotIndex),
        quantity = bindQuantity,
        itemRef = getItemRef(record.dataset, record.id),
        slots = affectedSlots,
        structural = bindQuantity < existingQuantity,
    })
    return items[index], index
end

function Inventory.SetItemSoulbound(slotIndex, soulbound, quantity)
    return runMutation("inventory:" .. (soulbound == true and "bind" or "unbind"), function()
        return setItemSoulboundInternal(slotIndex, soulbound, quantity)
    end)
end

function Inventory.BindItem(slotIndex, quantity)
    return Inventory.SetItemSoulbound(slotIndex, true, quantity)
end

local function removeItemInternal(slotIndex, quantity)
    local inventory = Inventory.GetCharacterInventory()
    local characterKey = getCharacterKey()
    local state = getRuntimeState(characterKey)
    local items = inventory.items
    local index = tonumber(slotIndex)
    if not index or index < 1 or index > #items then
        return nil
    end

    local requestedQuantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local record = items[index]
    local recordIndexEntry = state.indexByRecord[record]
    local stackKey = recordIndexEntry and recordIndexEntry.stackKey or getStackIdentity(record)
    local existingQuantity = math.max(1, math.floor(tonumber(record.quantity) or 1))
    local removed = copyCanonicalRecord(record)
    local actualRemovedQuantity = math.min(existingQuantity, requestedQuantity)
    removed.quantity = actualRemovedQuantity

    if existingQuantity > requestedQuantity then
        record.quantity = existingQuantity - requestedQuantity
    else
        removeIndexedRecord(state, items, index)
    end

    state.itemCount = #items
    markInventoryMutation("remove", {
        slotIndex = index,
        stackKey = stackKey,
        quantity = requestedQuantity,
        removedQuantity = actualRemovedQuantity,
        removedRefs = { getItemRef(record.dataset, record.id) },
        slots = { index },
        structural = existingQuantity <= requestedQuantity,
    })
    return removed
end

function Inventory.RemoveItem(slotIndex, quantity)
    return runMutation("inventory:remove", function()
        return removeItemInternal(slotIndex, quantity)
    end)
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

local function applyModificationInternal(targetSlotIndex, modificationSlotIndex)
    local inventory = Inventory.GetCharacterInventory()
    local characterKey = getCharacterKey()
    local state = getRuntimeState(characterKey)
    local items = inventory.items
    local originalTargetIndex = tonumber(targetSlotIndex)
    local originalSourceIndex = tonumber(modificationSlotIndex)
    if not originalTargetIndex or not originalSourceIndex then
        return nil, "invalid-slot"
    end
    if originalTargetIndex < 1 or originalTargetIndex > #items
        or originalSourceIndex < 1 or originalSourceIndex > #items
    then
        return nil, "invalid-slot"
    end

    local targetRecord = items[originalTargetIndex]
    local sourceRecord = items[originalSourceIndex]
    local sourceIndexEntry = state.indexByRecord[sourceRecord]
    local sourceStackKey = sourceIndexEntry and sourceIndexEntry.stackKey or getStackIdentity(sourceRecord)
    local targetWorking = copyCanonicalRecord(targetRecord)
    local sourceWorking = copyCanonicalRecord(sourceRecord)
    local targetWasSplit = targetWorking.quantity > 1
    if targetWasSplit then
        targetWorking.quantity = 1
        if originalSourceIndex == originalTargetIndex then
            sourceWorking.quantity = math.max(1, targetRecord.quantity - 1)
        end
    end

    if type(ModificationService.CanApplyModificationToRecord) ~= "function" then
        return nil, "modification-unavailable"
    end

    local canApply, reason = ModificationService.CanApplyModificationToRecord(targetWorking, sourceWorking)
    if not canApply then
        return nil, reason or "incompatible"
    end

    local nextRecord, modKey = nil, nil
    if type(ModificationService.AddModificationToRecord) == "function" then
        nextRecord, modKey = ModificationService.AddModificationToRecord(targetWorking, sourceWorking)
    end
    nextRecord = Inventory.NormalizeInventoryItem(nextRecord)
    if not nextRecord or not modKey then
        return nil, "apply-failed"
    end

    local targetIndex = originalTargetIndex
    local sourceIndex = originalSourceIndex
    if targetWasSplit then
        targetRecord.quantity = math.max(1, targetRecord.quantity - 1)
        targetIndex = originalTargetIndex + 1
        if sourceIndex > originalTargetIndex then
            sourceIndex = sourceIndex + 1
        end
        insertIndexedRecord(state, items, targetIndex, nextRecord)
    else
        replaceIndexedRecord(state, items, targetIndex, nextRecord)
    end

    local sourceQuantity = math.max(1, math.floor(tonumber(sourceWorking.quantity) or 1))
    local sourceRemoved = false
    if sourceQuantity > 1 then
        items[sourceIndex].quantity = sourceQuantity - 1
    else
        removeIndexedRecord(state, items, sourceIndex)
        sourceRemoved = true
        if sourceIndex < targetIndex then
            targetIndex = targetIndex - 1
        end
    end

    state.itemCount = #items
    markInventoryMutation("modify-apply", {
        targetSlotIndex = targetIndex,
        modificationSlotIndex = originalSourceIndex,
        modKey = modKey,
        itemRef = type(ModificationService.GetRecordItemRef) == "function"
            and ModificationService.GetRecordItemRef(sourceRecord)
            or getItemRef(sourceRecord.dataset, sourceRecord.id),
        stackKey = sourceStackKey,
        removedQuantity = 1,
        slots = { originalTargetIndex, originalSourceIndex, targetIndex },
        structural = targetWasSplit or sourceRemoved,
    })

    return Inventory.GetItem(targetIndex), modKey, targetIndex
end

function Inventory.ApplyModification(targetSlotIndex, modificationSlotIndex)
    return runMutation("inventory:modify-apply", function()
        return applyModificationInternal(targetSlotIndex, modificationSlotIndex)
    end)
end

local function removeAppliedModificationInternal(targetSlotIndex, modKey)
    local inventory = Inventory.GetCharacterInventory()
    local characterKey = getCharacterKey()
    local state = getRuntimeState(characterKey)
    local items = inventory.items
    local targetIndex = tonumber(targetSlotIndex)
    if not targetIndex or targetIndex < 1 or targetIndex > #items then
        return nil, "invalid-slot"
    end

    local targetRecord = items[targetIndex]
    if type(ModificationService.RemoveModificationFromRecord) ~= "function" then
        return nil, "missing-item"
    end

    local nextRecord, removed = ModificationService.RemoveModificationFromRecord(targetRecord, modKey)
    nextRecord = Inventory.NormalizeInventoryItem(nextRecord)
    if not nextRecord or not removed then
        return nil, "missing-modification"
    end

    replaceIndexedRecord(state, items, targetIndex, nextRecord)
    state.itemCount = #items
    markInventoryMutation("modify-remove", {
        targetSlotIndex = targetIndex,
        modKey = removed.modKey,
        itemRef = removed.itemRef,
        slots = { targetIndex },
    })

    return Inventory.GetItem(targetIndex), removed, targetIndex
end

function Inventory.RemoveAppliedModification(targetSlotIndex, modKey)
    return runMutation("inventory:modify-remove", function()
        return removeAppliedModificationInternal(targetSlotIndex, modKey)
    end)
end

function Inventory.ResolveItem(itemRecord)
    local dataset, item, normalized = resolveItemDefinition(itemRecord)
    if not normalized then
        return nil
    end

    -- Resolve the external record once at this ownership boundary; snapshots
    -- use the canonical-record path above and never normalize on read.
    return buildDisplayEntry(normalized, nil, nil, dataset, item)
end

function Inventory.GetDisplayItems(maxItems)
    local snapshot = Inventory.GetDisplaySnapshot()
    if maxItems and maxItems > 0 and #snapshot > maxItems then
        local limited = {}
        for index = 1, maxItems do
            limited[index] = snapshot[index]
        end
        return limited
    end

    return snapshot
end

local function getVariantBucket(state, recordOrKey)
    local stackKey
    if type(recordOrKey) == "string" then
        if state.stackIndex[recordOrKey] then
            stackKey = recordOrKey
        else
            local datasetId, itemId = parseItemRef(recordOrKey)
            if datasetId and itemId then
                stackKey = getStackIdentity({
                    dataset = datasetId,
                    id = itemId,
                    modifications = {},
                    soulbound = false,
                })
            end
        end
    elseif type(recordOrKey) == "table" then
        local normalized = Inventory.NormalizeInventoryItem(recordOrKey)
        if normalized then
            stackKey = getStackIdentity(normalized)
        end
    end

    return stackKey, stackKey and state.stackIndex[stackKey] or nil
end

function Inventory.GetVariantQuantity(recordOrKey)
    Inventory.GetCharacterInventory()
    local characterKey = getCharacterKey()
    local state = getRuntimeState(characterKey)
    local _, bucket = getVariantBucket(state, recordOrKey)
    if type(bucket) ~= "table" then
        return 0
    end

    local total = 0
    for index = 1, #bucket do
        total = total + math.max(1, math.floor(tonumber(bucket[index].quantity) or 1))
    end
    return total
end

function Inventory.GetItemVariants(datasetId, itemId)
    if itemId == nil then
        datasetId, itemId = parseItemRef(datasetId)
    end
    datasetId = ensureString(datasetId)
    itemId = ensureString(itemId)
    if datasetId == "" or itemId == "" then
        return {}
    end

    Inventory.GetCharacterInventory()
    local characterKey = getCharacterKey()
    local state = getRuntimeState(characterKey)
    local variants = state.variantIndex[getItemRef(datasetId, itemId)] or {}
    local buckets = {}
    for stackKey, bucket in pairs(variants) do
        local first = bucket and bucket[1]
        local entry = first and state.indexByRecord[first] or nil
        buckets[#buckets + 1] = {
            stackKey = stackKey,
            bucket = bucket,
            index = entry and entry.index or math.huge,
        }
    end
    table.sort(buckets, function(left, right)
        if left.index == right.index then
            return left.stackKey < right.stackKey
        end
        return left.index < right.index
    end)

    local result = {}
    for index = 1, #buckets do
        local bucket = buckets[index].bucket
        local first = bucket and bucket[1]
        if first then
            local variant = copyCanonicalRecord(first)
            variant.quantity = 0
            for bucketIndex = 1, #bucket do
                variant.quantity = variant.quantity
                    + math.max(1, math.floor(tonumber(bucket[bucketIndex].quantity) or 1))
            end
            result[#result + 1] = variant
        end
    end
    return result
end

local function removeVariantQuantityInternal(recordOrKey, quantity)
    local inventory = Inventory.GetCharacterInventory()
    local characterKey = getCharacterKey()
    local state = getRuntimeState(characterKey)
    local items = inventory.items
    local requestedQuantity = math.max(0, math.floor(tonumber(quantity) or 0))
    if requestedQuantity == 0 then
        return true
    end

    local stackKey, bucket = getVariantBucket(state, recordOrKey)
    if not stackKey or type(bucket) ~= "table" then
        return false
    end

    local candidates = {}
    for index = 1, #bucket do
        candidates[index] = bucket[index]
    end
    table.sort(candidates, function(left, right)
        local leftEntry = state.indexByRecord[left]
        local rightEntry = state.indexByRecord[right]
        return (leftEntry and leftEntry.index or 0) > (rightEntry and rightEntry.index or 0)
    end)

    local remaining = requestedQuantity
    local removedQuantity = 0
    local structuralChange = false
    local affectedSlots = {}
    local itemRef = ""
    for index = 1, #candidates do
        if remaining <= 0 then
            break
        end

        local record = candidates[index]
        local entry = state.indexByRecord[record]
        local slotIndex = entry and entry.index or nil
        if slotIndex and items[slotIndex] == record then
            itemRef = getItemRef(record.dataset, record.id)
            local available = math.max(1, math.floor(tonumber(record.quantity) or 1))
            local removeQuantity = math.min(available, remaining)
            affectedSlots[#affectedSlots + 1] = slotIndex
            if removeQuantity >= available then
                removeIndexedRecord(state, items, slotIndex)
                structuralChange = true
            else
                record.quantity = available - removeQuantity
            end
            remaining = remaining - removeQuantity
            removedQuantity = removedQuantity + removeQuantity
        end
    end

    if removedQuantity > 0 then
        state.itemCount = #items
        markInventoryMutation("remove-variant", {
            itemRef = itemRef,
            stackKey = stackKey,
            quantity = requestedQuantity,
            removedQuantity = removedQuantity,
            removedRefs = { itemRef },
            slots = affectedSlots,
            structural = structuralChange,
        })
    end
    return remaining <= 0
end

function Inventory.RemoveVariantQuantity(recordOrKey, quantity)
    return runMutation("inventory:remove-variant", function()
        return removeVariantQuantityInternal(recordOrKey, quantity)
    end)
end

dispatchInventoryPayload = function(changeSet, summary)
    local inventoryChange = type(changeSet) == "table" and changeSet.inventory or nil
    if type(inventoryChange) ~= "table" then
        return
    end

    local inventory = Inventory.GetCharacterInventory()
    local mutations = type(inventoryChange.mutations) == "table" and inventoryChange.mutations or {}
    local addedItems = {}
    local addedQuantities = {}
    local firstChangeType = nil
    local changeTypeCount = 0
    local allCanonicalAdds = #mutations > 0

    for index = 1, #mutations do
        local mutation = mutations[index]
        local mutationType = mutation and mutation.changeType or nil
        if mutationType ~= nil then
            if firstChangeType == nil then
                firstChangeType = tostring(mutationType)
            elseif firstChangeType ~= tostring(mutationType) then
                changeTypeCount = 2
            end
            if changeTypeCount == 0 then
                changeTypeCount = 1
            end
        end

        if not mutation or mutation.changeType ~= "add" or mutation.isCanonicalAdd ~= true then
            allCanonicalAdds = false
        else
            local datasetId = ensureString(mutation.dataset or mutation.datasetId)
            local itemId = ensureString(mutation.itemId or mutation.id)
            local amount = math.max(0, math.floor(tonumber(mutation.actualAddedQuantity or mutation.quantity) or 0))
            if datasetId ~= "" and itemId ~= "" and amount > 0 then
                local itemRef = mutation.itemRef or getItemRef(datasetId, itemId)
                addedItems[#addedItems + 1] = {
                    dataset = datasetId,
                    datasetId = datasetId,
                    id = itemId,
                    itemId = itemId,
                    itemRef = itemRef,
                    quantity = amount,
                    actualAddedQuantity = amount,
                }
                addedQuantities[itemRef] = (tonumber(addedQuantities[itemRef]) or 0) + amount
            end
        end
    end

    local payloadChangeType = firstChangeType or "set"
    if changeTypeCount > 1 then
        payloadChangeType = "transaction"
    end
    local detail
    if #mutations == 1 then
        detail = deepCopy(mutations[1])
    else
        detail = {
            mutations = deepCopy(mutations),
            addedItems = deepCopy(addedItems),
            addedQuantities = deepCopy(addedQuantities),
        }
    end

    local payload = {
        changeType = payloadChangeType,
        characterKey = getCharacterKey(),
        itemCount = #(inventory.items or {}),
        detail = detail,
        changes = deepCopy(mutations),
        addedItems = addedItems,
        addedQuantities = addedQuantities,
        addedRefs = deepCopy(inventoryChange.addedRefs or {}),
        removedRefs = deepCopy(inventoryChange.removedRefs or {}),
        structural = inventoryChange.structural == true,
        fullRefresh = inventoryChange.fullRefresh == true,
        isCanonicalAdd = allCanonicalAdds,
        revision = getRuntimeRevision("InventoryRevision"),
        summary = summary,
    }

    local listeners = Inventory._changeListeners or {}
    for _, listener in pairs(listeners) do
        if type(listener) == "function" then
            -- A listener must not be able to abort the remaining consumers.
            pcall(listener, payload)
        end
    end
end

if type(Runtime) == "table" and type(Runtime.RegisterPostCommitListener) == "function"
    and Inventory._runtimePostCommitListenerId == nil
then
    Inventory._runtimePostCommitListenerId = Runtime:RegisterPostCommitListener(function(changeSet, summary)
        if type(changeSet) ~= "table" or type(changeSet.inventory) ~= "table" then
            return
        end

        local characterKey = getCharacterKey()
        local state = Inventory.RuntimeByCharacter[characterKey]
        invalidateDisplaySnapshot(state)
        dispatchInventoryPayload(changeSet, summary)
    end)
end

function Inventory.Initialize()
    Inventory.GetCharacterInventory()
    return Inventory.Root
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
