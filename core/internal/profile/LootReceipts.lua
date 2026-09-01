local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile
local Database = Addon.Internal.Database or {}
local Common = Addon.Utils and Addon.Utils.Common or {}

local ROOT_FIELD = "lootReceiptsByChar"
local RECEIPT_LIMIT = 64
local VALID_STATUSES = {
    ["in-progress"] = true,
    ["complete"] = true,
    ["failed"] = true,
    ["recovery-required"] = true,
}

Profile.LootReceiptLimit = RECEIPT_LIMIT

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
    for key, nested in pairs(value) do
        copy[key] = deepCopy(nested, seen)
    end
    return copy
end

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function getNow()
    return type(Common.GetNow) == "function" and math.max(0, math.floor(tonumber(Common.GetNow()) or 0)) or 0
end

local function normalizeTimestamp(value)
    local number = tonumber(value)
    if number == nil or number ~= number or number == math.huge or number == -math.huge or number < 0 then
        return nil
    end
    return math.floor(number)
end

local function normalizeReceipt(receipt, deliveryId)
    if type(receipt) ~= "table" then
        return nil
    end
    local normalized = deepCopy(receipt)
    normalized.deliveryId = trim(deliveryId ~= nil and deliveryId or receipt.deliveryId)
    if normalized.deliveryId == "" then
        return nil
    end

    local status = string.lower(trim(receipt.status))
    normalized.status = VALID_STATUSES[status] and status or "failed"
    normalized.startedAt = normalizeTimestamp(receipt.startedAt)
    normalized.completedAt = normalizeTimestamp(receipt.completedAt)
    normalized.failedAt = normalizeTimestamp(receipt.failedAt)
    normalized.protocolVersion = tonumber(receipt.protocolVersion)
    normalized.eventSessionId = trim(receipt.eventSessionId)
    normalized.grantId = trim(receipt.grantId)
    normalized.recipientName = trim(receipt.recipientName)
    normalized.hostName = trim(receipt.hostName)
    normalized.requestFingerprint = trim(receipt.requestFingerprint)
    normalized.reason = receipt.reason ~= nil and tostring(receipt.reason) or nil
    normalized.snapshots = type(receipt.snapshots) == "table" and deepCopy(receipt.snapshots) or nil
    normalized.result = type(receipt.result) == "table" and deepCopy(receipt.result) or nil
    normalized.progress = type(receipt.progress) == "table" and deepCopy(receipt.progress) or nil
    normalized.failure = type(receipt.failure) == "table" and deepCopy(receipt.failure) or nil
    return normalized
end

local function resolveCharacterKey()
    if type(Database.ResolveCurrentCharacterIdentity) == "function" then
        local key, _, stable = Database.ResolveCurrentCharacterIdentity()
        key = trim(key)
        if key ~= "" then
            return key, stable == true
        end
    end
    return "unknown-player", false
end

local function ensureRoot()
    if type(Database.EnsureProfiles) ~= "function" then
        return nil
    end
    local root = Database.EnsureProfiles()
    if type(root) ~= "table" then
        return nil
    end
    root[ROOT_FIELD] = type(root[ROOT_FIELD]) == "table" and root[ROOT_FIELD] or {}
    return root
end

local function ensureBucket(create)
    local root = ensureRoot()
    if not root then
        return nil
    end

    local key, stable = resolveCharacterKey()
    local buckets = root[ROOT_FIELD]
    if stable and key ~= "unknown-player" and type(buckets["unknown-player"]) == "table" and buckets[key] == nil then
        buckets[key] = buckets["unknown-player"]
        buckets["unknown-player"] = nil
    end

    local bucket = buckets[key]
    if type(bucket) ~= "table" then
        if create ~= true then
            return nil
        end
        bucket = { receipts = {} }
        buckets[key] = bucket
    end
    bucket.receipts = type(bucket.receipts) == "table" and bucket.receipts or {}
    return bucket
end

local function retentionTimestamp(receipt)
    if type(receipt) ~= "table" then
        return 0
    end
    return tonumber(receipt.completedAt)
        or tonumber(receipt.failedAt)
        or tonumber(receipt.startedAt)
        or 0
end

function Profile.PruneLootReceipts(protectedDeliveryId)
    local bucket = ensureBucket(false)
    if not bucket then
        return 0
    end
    local receipts = bucket.receipts
    local protected = trim(protectedDeliveryId)
    local rows = {}
    local count = 0
    for deliveryId, receipt in pairs(receipts) do
        count = count + 1
        if tostring(deliveryId) ~= protected then
            rows[#rows + 1] = {
                deliveryId = tostring(deliveryId),
                timestamp = retentionTimestamp(receipt),
            }
        end
    end

    table.sort(rows, function(left, right)
        if left.timestamp ~= right.timestamp then
            return left.timestamp < right.timestamp
        end
        return left.deliveryId < right.deliveryId
    end)

    local removed = 0
    local rowIndex = 1
    while count > RECEIPT_LIMIT and rowIndex <= #rows do
        local row = rows[rowIndex]
        rowIndex = rowIndex + 1
        if receipts[row.deliveryId] ~= nil then
            receipts[row.deliveryId] = nil
            count = count - 1
            removed = removed + 1
        end
    end
    return removed
end

function Profile.GetLootReceipt(deliveryId)
    local normalizedId = trim(deliveryId)
    if normalizedId == "" then
        return nil
    end
    local bucket = ensureBucket(false)
    local receipt = bucket and bucket.receipts[normalizedId] or nil
    return normalizeReceipt(receipt, normalizedId)
end

function Profile.SetLootReceipt(deliveryId, receipt)
    local normalizedId = trim(deliveryId)
    local normalized = normalizeReceipt(receipt, normalizedId)
    if normalizedId == "" or not normalized then
        return nil
    end
    local bucket = ensureBucket(true)
    if not bucket then
        return nil
    end
    bucket.receipts[normalizedId] = deepCopy(normalized)
    Profile.PruneLootReceipts(normalizedId)
    return deepCopy(bucket.receipts[normalizedId])
end

function Profile.ClearLootReceipt(deliveryId)
    local normalizedId = trim(deliveryId)
    if normalizedId == "" then
        return false
    end
    local bucket = ensureBucket(false)
    if not bucket or bucket.receipts[normalizedId] == nil then
        return false
    end
    bucket.receipts[normalizedId] = nil
    return true
end

function Profile.ListLootReceipts()
    local bucket = ensureBucket(false)
    local result = {}
    for deliveryId, receipt in pairs(bucket and bucket.receipts or {}) do
        local normalized = normalizeReceipt(receipt, deliveryId)
        if normalized then
            result[deliveryId] = normalized
        end
    end
    return result
end

function Profile.RecoverInterruptedLootReceipts()
    local bucket = ensureBucket(false)
    if not bucket then
        return 0
    end
    local recovered = 0
    local now = getNow()
    for deliveryId, receipt in pairs(bucket.receipts) do
        local normalized = normalizeReceipt(receipt, deliveryId)
        if normalized and normalized.status == "in-progress" then
            normalized.status = "recovery-required"
            normalized.failedAt = now
            normalized.completedAt = nil
            normalized.reason = "interrupted-loot-transaction"
            bucket.receipts[deliveryId] = normalized
            recovered = recovered + 1
        elseif normalized then
            bucket.receipts[deliveryId] = normalized
        else
            bucket.receipts[deliveryId] = nil
        end
    end
    Profile.PruneLootReceipts(nil)
    return recovered
end
