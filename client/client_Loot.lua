local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Client = Addon.Client
local Common = Addon.Utils and Addon.Utils.Common or {}
local Profile = Addon.Internal.Profile or {}
local Registry = Addon.Internal.Registry or {}
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Protocol = Comms.LootProtocol or {}

local RECENT_EVENT_LIMIT = 4
local RECENT_EVENT_TTL = 900
local MAX_IDENTIFIER_LENGTH = 192

Client.LootEventAuthority = type(Client.LootEventAuthority) == "table" and Client.LootEventAuthority or {
    active = nil,
    recent = {},
}
Client.LootReceivedListeners = type(Client.LootReceivedListeners) == "table" and Client.LootReceivedListeners or {}
Client.NextLootReceivedListenerId = math.max(0, math.floor(tonumber(Client.NextLootReceivedListenerId) or 0))

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

local function deepEqual(left, right)
    if left == right then
        return true
    end
    if type(left) ~= type(right) or type(left) ~= "table" then
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

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeName(value)
    local text = trim(value)
    if text == "" then
        return ""
    end
    return type(Common.NormalizeName) == "function" and trim(Common.NormalizeName(text)) or text
end

local function getNow()
    return type(Common.GetNow) == "function" and math.max(0, math.floor(tonumber(Common.GetNow()) or 0)) or 0
end

local function positiveInteger(value)
    local numeric = tonumber(value)
    if numeric == nil
        or numeric ~= numeric
        or numeric == math.huge
        or numeric == -math.huge
        or numeric < 1
        or numeric ~= math.floor(numeric)
    then
        return nil
    end
    return math.floor(numeric)
end

local function validIdentifier(value, maximumLength)
    local text = trim(value)
    if text == "" or #text > (maximumLength or MAX_IDENTIFIER_LENGTH) then
        return nil
    end
    if text:find("[%z\1-\31\127]") then
        return nil
    end
    return text
end

local function parseDatasetReference(reference)
    local normalized = trim(reference)
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

local function normalizeInventoryRecord(record)
    if type(record) ~= "table" then
        return nil
    end
    local datasetId = trim(record.dataset)
    local itemId = trim(record.id)
    if datasetId == "" or itemId == "" then
        return nil
    end
    return {
        dataset = datasetId,
        id = itemId,
        modifications = deepCopy(type(record.modifications) == "table" and record.modifications or {}),
        soulbound = record.soulbound == true,
        quantity = math.max(1, math.floor(tonumber(record.quantity or record.count) or 1)),
    }
end

local function sameInventoryVariant(left, right)
    return type(left) == "table"
        and type(right) == "table"
        and tostring(left.dataset or "") == tostring(right.dataset or "")
        and tostring(left.id or "") == tostring(right.id or "")
        and left.soulbound == right.soulbound
        and deepEqual(left.modifications or {}, right.modifications or {})
end

local function getInventory()
    return Client.Inventory or {}
end

local function getInventoryItemVariants(inventory, datasetId, itemId)
    if type(inventory.GetItemVariants) == "function" then
        local callOk, variants = pcall(inventory.GetItemVariants, datasetId, itemId)
        if callOk and type(variants) == "table" then
            local normalized = {}
            for index = 1, #variants do
                local variant = normalizeInventoryRecord(variants[index])
                if variant then
                    normalized[#normalized + 1] = variant
                end
            end
            return normalized
        end
    end

    if type(inventory.GetItems) ~= "function" then
        return nil
    end
    local callOk, items = pcall(inventory.GetItems)
    if not callOk or type(items) ~= "table" then
        return nil
    end
    local variants = {}
    for index = 1, #items do
        local item = normalizeInventoryRecord(items[index])
        if item and item.dataset == datasetId and item.id == itemId then
            local existing = nil
            for variantIndex = 1, #variants do
                if sameInventoryVariant(variants[variantIndex], item) then
                    existing = variants[variantIndex]
                    break
                end
            end
            if existing then
                existing.quantity = existing.quantity + item.quantity
            else
                variants[#variants + 1] = item
            end
        end
    end
    return variants
end

local function getInventoryVariantQuantity(variants, variant)
    for index = 1, #(variants or {}) do
        local candidate = variants[index]
        if sameInventoryVariant(candidate, variant) then
            return math.max(0, math.floor(tonumber(candidate.quantity) or 0))
        end
    end
    return 0
end

local function compareInventoryVariants(before, after)
    for index = 1, #(before or {}) do
        local expected = before[index]
        if getInventoryVariantQuantity(after, expected) ~= getInventoryVariantQuantity(before, expected) then
            return false
        end
    end
    for index = 1, #(after or {}) do
        local actual = after[index]
        if getInventoryVariantQuantity(before, actual) ~= getInventoryVariantQuantity(after, actual) then
            return false
        end
    end
    return true
end

local function removeInventoryVariantQuantity(inventory, variant, quantity)
    local remaining = math.max(0, math.floor(tonumber(quantity) or 0))
    if remaining == 0 then
        return true
    end

    if type(inventory.RemoveVariantQuantity) == "function" then
        local callOk, removed = pcall(inventory.RemoveVariantQuantity, variant, remaining)
        if callOk then
            return removed == true
        end
    end

    if type(inventory.GetItems) ~= "function" or type(inventory.RemoveItem) ~= "function" then
        return false
    end
    local callOk, items = pcall(inventory.GetItems)
    if not callOk or type(items) ~= "table" then
        return false
    end
    for index = #items, 1, -1 do
        local item = normalizeInventoryRecord(items[index])
        if sameInventoryVariant(item, variant) then
            local removeAmount = math.min(item.quantity, remaining)
            local removedOk, removed = pcall(inventory.RemoveItem, index, removeAmount)
            if not removedOk or removed ~= true then
                return false
            end
            remaining = remaining - removeAmount
            if remaining <= 0 then
                return true
            end
        end
    end
    return false
end

local function restoreCurrencySnapshots(snapshots)
    if #(snapshots or {}) == 0 then
        return true
    end
    if type(Profile.SetCurrencyAmount) ~= "function" or type(Profile.GetCurrencyAmount) ~= "function" then
        return false
    end
    local restored = true
    for index = #(snapshots or {}), 1, -1 do
        local snapshot = snapshots[index]
        local setOk, persisted = pcall(Profile.SetCurrencyAmount, snapshot.currencyRef, snapshot.amount)
        local getOk, actual = pcall(Profile.GetCurrencyAmount, snapshot.currencyRef)
        actual = getOk and tonumber(actual) or nil
        if not setOk or persisted == nil or not getOk or actual ~= snapshot.amount then
            restored = false
        end
    end
    return restored
end

local function buildFailureResponse(deliveryId, reason)
    return {
        protocolVersion = Protocol.Version or 1,
        deliveryId = tostring(deliveryId or ""),
        success = false,
        reason = tostring(reason or "reward-application-failed"),
        rewards = {},
    }
end

local function buildRewardPlan(rewards)
    if type(rewards) ~= "table" or #rewards == 0 then
        return nil, "invalid-reward", { reason = "empty-rewards" }
    end

    local plan = {
        rewards = {},
        needsItems = false,
        needsCurrencies = false,
    }

    for index = 1, #rewards do
        local reward = rewards[index]
        if type(reward) ~= "table" then
            return nil, "invalid-reward", { rewardIndex = index, reason = "reward-not-table" }
        end
        local rewardType = string.lower(trim(reward.type))
        local rewardRef = trim(reward.ref)
        local amount = positiveInteger(reward.amount)
        if rewardType ~= "item" and rewardType ~= "currency" then
            return nil, "invalid-reward", { rewardIndex = index, field = "type" }
        end
        if rewardRef == "" or not amount then
            return nil, "invalid-reward", { rewardIndex = index, field = rewardRef == "" and "ref" or "amount" }
        end

        if rewardType == "item" then
            if type(Registry.ResolveItemReference) ~= "function" then
                return nil, "unknown-item", { rewardIndex = index, ref = rewardRef, reason = "item-api-unavailable" }
            end
            local resolveOk, dataset, item = pcall(Registry.ResolveItemReference, Registry, rewardRef)
            if not resolveOk or type(dataset) ~= "table" or type(item) ~= "table" then
                return nil, "unknown-item", { rewardIndex = index, ref = rewardRef }
            end
            local datasetId = trim(dataset.id)
            local itemId = trim(item.id)
            if datasetId == "" or itemId == "" then
                return nil, "unknown-item", { rewardIndex = index, ref = rewardRef }
            end
            plan.rewards[#plan.rewards + 1] = {
                type = "item",
                ref = ("%s:%s"):format(datasetId, itemId),
                requestedAmount = amount,
                datasetId = datasetId,
                itemId = itemId,
            }
            plan.needsItems = true
        else
            if type(Profile.NormalizeCurrencyKey) ~= "function" or type(Profile.ResolveCurrencyDefinition) ~= "function" then
                return nil, "unknown-currency", { rewardIndex = index, ref = rewardRef, reason = "currency-api-unavailable" }
            end
            local normalizeOk, currencyRef = pcall(Profile.NormalizeCurrencyKey, rewardRef)
            currencyRef = normalizeOk and trim(currencyRef) or ""
            local resolveOk, definition = pcall(Profile.ResolveCurrencyDefinition, currencyRef)
            if currencyRef == "" or not normalizeOk or not resolveOk or type(definition) ~= "table" or definition.isMissing == true then
                return nil, "unknown-currency", { rewardIndex = index, ref = rewardRef }
            end
            plan.rewards[#plan.rewards + 1] = {
                type = "currency",
                ref = currencyRef,
                currencyRef = currencyRef,
                requestedAmount = amount,
            }
            plan.needsCurrencies = true
        end
    end

    local inventory = getInventory()
    if plan.needsItems and (type(inventory.AddItem) ~= "function" or (type(inventory.GetItemVariants) ~= "function" and type(inventory.GetItems) ~= "function")) then
        return nil, "reward-application-failed", { reason = "inventory-api-unavailable" }
    end
    if plan.needsCurrencies and (type(Profile.GetCurrencyAmount) ~= "function" or type(Profile.AddCurrencyAmount) ~= "function" or type(Profile.SetCurrencyAmount) ~= "function") then
        return nil, "reward-application-failed", { reason = "currency-api-unavailable" }
    end
    return plan
end

local function captureSnapshots(plan)
    local snapshots = { items = {}, currencies = {} }
    local inventory = getInventory()
    local seenItems = {}
    local seenCurrencies = {}

    for index = 1, #(plan and plan.rewards or {}) do
        local reward = plan.rewards[index]
        if reward.type == "item" then
            if not seenItems[reward.ref] then
                local variants = getInventoryItemVariants(inventory, reward.datasetId, reward.itemId)
                if variants == nil then
                    return nil, "reward-application-failed", { rewardIndex = index, reason = "item-snapshot-failed" }
                end
                seenItems[reward.ref] = true
                snapshots.items[#snapshots.items + 1] = {
                    itemRef = reward.ref,
                    datasetId = reward.datasetId,
                    itemId = reward.itemId,
                    variants = variants,
                }
            end
        elseif not seenCurrencies[reward.currencyRef] then
            local callOk, amount = pcall(Profile.GetCurrencyAmount, reward.currencyRef)
            amount = callOk and tonumber(amount) or nil
            if not callOk or amount == nil or amount < 0 then
                return nil, "reward-application-failed", { rewardIndex = index, reason = "currency-snapshot-failed" }
            end
            seenCurrencies[reward.currencyRef] = true
            snapshots.currencies[#snapshots.currencies + 1] = {
                currencyRef = reward.currencyRef,
                amount = math.floor(amount),
            }
        end
    end
    return snapshots
end

local function rollbackTransaction(transaction)
    if type(transaction) ~= "table" then
        return false
    end
    local inventory = getInventory()
    local restored = true
    for index = #(transaction.itemAwards or {}), 1, -1 do
        local award = transaction.itemAwards[index]
        if not removeInventoryVariantQuantity(inventory, award.variant, award.amount) then
            restored = false
        end
    end
    if not restoreCurrencySnapshots(transaction.currencySnapshots) then
        restored = false
    end
    for index = 1, #(transaction.itemSnapshots or {}) do
        local snapshot = transaction.itemSnapshots[index]
        local actual = getInventoryItemVariants(inventory, snapshot.datasetId, snapshot.itemId)
        if actual == nil or not compareInventoryVariants(snapshot.variants, actual) then
            restored = false
        end
    end
    for index = 1, #(transaction.currencySnapshots or {}) do
        local snapshot = transaction.currencySnapshots[index]
        local getOk, actual = pcall(Profile.GetCurrencyAmount, snapshot.currencyRef)
        actual = getOk and tonumber(actual) or nil
        if not getOk or actual ~= snapshot.amount then
            restored = false
        end
    end
    return restored
end

local function persistReceipt(deliveryId, receipt)
    if type(Profile.SetLootReceipt) ~= "function" then
        return nil
    end
    local callOk, persisted = pcall(Profile.SetLootReceipt, deliveryId, receipt)
    if not callOk or type(persisted) ~= "table" or tostring(persisted.status or "") ~= tostring(receipt.status or "") then
        return nil
    end
    return persisted
end

local function readReceipt(deliveryId)
    if type(Profile.GetLootReceipt) ~= "function" then
        return nil
    end
    local callOk, receipt = pcall(Profile.GetLootReceipt, deliveryId)
    return callOk and type(receipt) == "table" and receipt or nil
end

local function finishFailedDelivery(payload, receipt, transaction, cause, detail)
    local rolledBack = rollbackTransaction(transaction)
    receipt.status = rolledBack and "failed" or "recovery-required"
    receipt.failedAt = getNow()
    receipt.completedAt = nil
    receipt.reason = rolledBack and cause or "recovery-required"
    receipt.failure = {
        cause = cause,
        detail = deepCopy(detail),
        rolledBack = rolledBack,
    }
    local response = buildFailureResponse(payload.deliveryId, rolledBack and cause or "recovery-required")
    receipt.result = deepCopy(response)
    local persisted = persistReceipt(payload.deliveryId, receipt)
    if not persisted and not rolledBack then
        response.reason = "recovery-required"
    elseif not persisted then
        response.reason = "receipt-persistence-failed"
    end
    return response
end

local function executeDeliveryPlan(payload, hostName, requestFingerprint, plan, snapshots)
    local receipt = {
        deliveryId = payload.deliveryId,
        protocolVersion = payload.protocolVersion,
        eventSessionId = payload.eventSessionId,
        grantId = payload.grantId,
        recipientName = payload.recipientName,
        hostName = hostName,
        requestFingerprint = requestFingerprint,
        status = "in-progress",
        startedAt = getNow(),
        snapshots = deepCopy(snapshots),
        progress = { rewards = {} },
    }
    if not persistReceipt(payload.deliveryId, receipt) then
        return buildFailureResponse(payload.deliveryId, "receipt-persistence-failed")
    end

    local expectedItemStates = {}
    for index = 1, #(snapshots.items or {}) do
        local snapshot = snapshots.items[index]
        expectedItemStates[snapshot.itemRef] = deepCopy(snapshot.variants)
    end
    local transaction = {
        itemAwards = {},
        itemSnapshots = snapshots.items or {},
        currencySnapshots = snapshots.currencies or {},
        expectedItemStates = expectedItemStates,
    }
    local inventory = getInventory()
    local resultRewards = {}

    for index = 1, #plan.rewards do
        local reward = plan.rewards[index]
        if reward.type == "item" then
            local beforeVariants = getInventoryItemVariants(inventory, reward.datasetId, reward.itemId)
            local expected = transaction.expectedItemStates[reward.ref]
            if beforeVariants == nil or expected == nil or not compareInventoryVariants(expected, beforeVariants) then
                return finishFailedDelivery(payload, receipt, transaction, "reward-application-failed", {
                    rewardIndex = index,
                    ref = reward.ref,
                    reason = "item-snapshot-drift",
                })
            end

            local addOk, addedRecord = pcall(inventory.AddItem, {
                dataset = reward.datasetId,
                id = reward.itemId,
                quantity = reward.requestedAmount,
            })
            local addedVariant = normalizeInventoryRecord(addedRecord)
            local afterVariants = getInventoryItemVariants(inventory, reward.datasetId, reward.itemId)
            local beforeAdded = addedVariant and getInventoryVariantQuantity(beforeVariants, addedVariant) or nil
            local afterAdded = addedVariant and getInventoryVariantQuantity(afterVariants, addedVariant) or nil
            local actualAdded = beforeAdded ~= nil and afterAdded ~= nil and afterAdded - beforeAdded or nil
            if actualAdded and actualAdded > 0 then
                transaction.itemAwards[#transaction.itemAwards + 1] = {
                    variant = deepCopy(addedVariant),
                    amount = actualAdded,
                }
            end
            if not addOk or not addedVariant or not beforeVariants or not afterVariants or actualAdded ~= reward.requestedAmount then
                return finishFailedDelivery(payload, receipt, transaction, "reward-application-failed", {
                    rewardIndex = index,
                    ref = reward.ref,
                    reason = "item-award-failed",
                    appliedAmount = math.max(0, tonumber(actualAdded) or 0),
                })
            end
            transaction.expectedItemStates[reward.ref] = deepCopy(afterVariants)
            resultRewards[#resultRewards + 1] = {
                type = "item",
                ref = reward.ref,
                requestedAmount = reward.requestedAmount,
                appliedAmount = actualAdded,
            }
        else
            local beforeOk, before = pcall(Profile.GetCurrencyAmount, reward.currencyRef)
            before = beforeOk and tonumber(before) or nil
            local addOk, addResult = pcall(Profile.AddCurrencyAmount, reward.currencyRef, reward.requestedAmount)
            local afterOk, after = pcall(Profile.GetCurrencyAmount, reward.currencyRef)
            after = afterOk and tonumber(after) or nil
            local actualAdded = before ~= nil and after ~= nil and after - before or nil
            if not beforeOk or not addOk or addResult == nil or not afterOk or actualAdded == nil or actualAdded < 0 or actualAdded > reward.requestedAmount then
                return finishFailedDelivery(payload, receipt, transaction, "reward-application-failed", {
                    rewardIndex = index,
                    ref = reward.ref,
                    reason = "currency-award-failed",
                    appliedAmount = math.max(0, tonumber(actualAdded) or 0),
                })
            end
            resultRewards[#resultRewards + 1] = {
                type = "currency",
                ref = reward.ref,
                requestedAmount = reward.requestedAmount,
                appliedAmount = actualAdded,
                reason = actualAdded < reward.requestedAmount and "currency-capped" or nil,
            }
        end

        receipt.progress = { rewards = deepCopy(resultRewards) }
        if not persistReceipt(payload.deliveryId, receipt) then
            return finishFailedDelivery(payload, receipt, transaction, "receipt-persistence-failed", {
                rewardIndex = index,
            })
        end
    end

    local response = {
        protocolVersion = Protocol.Version or 1,
        deliveryId = payload.deliveryId,
        success = true,
        rewards = resultRewards,
    }
    receipt.status = "complete"
    receipt.completedAt = getNow()
    receipt.failedAt = nil
    receipt.reason = nil
    receipt.result = deepCopy(response)
    receipt.progress = nil
    if not persistReceipt(payload.deliveryId, receipt) then
        return finishFailedDelivery(payload, receipt, transaction, "receipt-persistence-failed", {
            reason = "complete-receipt-write-failed",
        })
    end
    return response
end

function Client:PruneLootEventAuthority(nowOverride)
    local state = self.LootEventAuthority
    state.active = type(state.active) == "table" and state.active or nil
    state.recent = type(state.recent) == "table" and state.recent or {}
    local now = tonumber(nowOverride) or getNow()
    local kept = {}
    for index = 1, #state.recent do
        local record = state.recent[index]
        local recordedAt = tonumber(record and record.recordedAt) or 0
        if type(record) == "table"
            and trim(record.eventSessionId) ~= ""
            and trim(record.hostName) ~= ""
            and (now <= 0 or recordedAt <= 0 or (now - recordedAt) <= RECENT_EVENT_TTL)
        then
            kept[#kept + 1] = record
            if #kept >= RECENT_EVENT_LIMIT then
                break
            end
        end
    end
    state.recent = kept
    return #kept
end

function Client:RememberLootEventAuthority(eventState, isActive)
    if type(eventState) ~= "table" then
        return false
    end
    local eventSessionId = validIdentifier(eventState.id)
    local hostName = normalizeName(eventState.hostName)
    if not eventSessionId or hostName == "" then
        return false
    end
    local state = self.LootEventAuthority
    state.recent = type(state.recent) == "table" and state.recent or {}
    local record = {
        eventSessionId = eventSessionId,
        hostName = hostName,
        active = isActive == true,
        recordedAt = getNow(),
    }
    if isActive == true then
        state.active = record
        for index = #state.recent, 1, -1 do
            if tostring(state.recent[index] and state.recent[index].eventSessionId or "") == eventSessionId then
                table.remove(state.recent, index)
            end
        end
        return true
    end

    if type(state.active) == "table" and tostring(state.active.eventSessionId or "") == eventSessionId then
        state.active = nil
    end
    for index = #state.recent, 1, -1 do
        if tostring(state.recent[index] and state.recent[index].eventSessionId or "") == eventSessionId then
            table.remove(state.recent, index)
        end
    end
    table.insert(state.recent, 1, record)
    self:PruneLootEventAuthority(record.recordedAt)
    return true
end

function Client:ResolveLootEventAuthority(eventSessionId)
    local normalizedId = validIdentifier(eventSessionId)
    if not normalizedId then
        return nil, "unknown-event-session"
    end

    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
    if type(eventState) == "table"
        and tostring(eventState.id or "") == normalizedId
        and (eventState.active == true or eventState.ending == true)
    then
        local hostName = normalizeName(eventState.hostName)
        if hostName ~= "" then
            return {
                eventSessionId = normalizedId,
                hostName = hostName,
                active = eventState.active == true,
            }
        end
    end

    local state = self.LootEventAuthority
    if type(state.active) == "table" and tostring(state.active.eventSessionId or "") == normalizedId then
        return deepCopy(state.active)
    end
    self:PruneLootEventAuthority()
    for index = 1, #(state.recent or {}) do
        local record = state.recent[index]
        if tostring(record and record.eventSessionId or "") == normalizedId then
            return deepCopy(record)
        end
    end
    return nil, "unknown-event-session"
end

local function installEventAuthorityHooks()
    if Client._lootEventAuthorityHooksInstalled == true then
        return
    end

    local baseStart = Client.HandleEventStart
    if type(baseStart) == "function" then
        Client.HandleEventStart = function(self, ...)
            local previous = self.EventState
            local result = baseStart(self, ...)
            if result == true then
                if type(previous) == "table" and previous ~= self.EventState then
                    self:RememberLootEventAuthority(previous, false)
                end
                if type(self.EventState) == "table" then
                    self:RememberLootEventAuthority(self.EventState, true)
                end
            end
            return result
        end
    end

    local baseEnd = Client.HandleEventEnd
    if type(baseEnd) == "function" then
        Client.HandleEventEnd = function(self, ...)
            local endingState = self.EventState
            local result = baseEnd(self, ...)
            if result == true and type(endingState) == "table" then
                self:RememberLootEventAuthority(endingState, false)
            end
            return result
        end
    end

    local baseReset = Client.ResetEventState
    if type(baseReset) == "function" then
        Client.ResetEventState = function(self, ...)
            local resetState = self.EventState
            local result = baseReset(self, ...)
            if type(resetState) == "table" then
                self:RememberLootEventAuthority(resetState, false)
            end
            return result
        end
    end

    Client._lootEventAuthorityHooksInstalled = true
end

function Client:RegisterLootReceivedListener(callback)
    if type(callback) ~= "function" then
        return nil
    end
    self.NextLootReceivedListenerId = math.max(0, math.floor(tonumber(self.NextLootReceivedListenerId) or 0)) + 1
    self.LootReceivedListeners[self.NextLootReceivedListenerId] = callback
    return self.NextLootReceivedListenerId
end

function Client:UnregisterLootReceivedListener(listenerId)
    local id = tonumber(listenerId)
    if not id or self.LootReceivedListeners[id] == nil then
        return false
    end
    self.LootReceivedListeners[id] = nil
    return true
end

local function resolveRewardDisplayName(reward)
    if type(reward) ~= "table" then
        return "Reward"
    end
    if reward.type == "item" and type(Registry.ResolveItemReference) == "function" then
        local ok, _, item = pcall(Registry.ResolveItemReference, Registry, reward.ref)
        if ok and type(item) == "table" and trim(item.name) ~= "" then
            return trim(item.name)
        end
    elseif reward.type == "currency" and type(Profile.ResolveCurrencyDefinition) == "function" then
        local ok, definition = pcall(Profile.ResolveCurrencyDefinition, reward.ref)
        if ok and type(definition) == "table" and trim(definition.name) ~= "" then
            return trim(definition.name)
        end
    end
    return trim(reward.ref) ~= "" and trim(reward.ref) or "Reward"
end

function Client:NotifyLootReceived(response, payload)
    local notification = {
        deliveryId = payload and payload.deliveryId or response and response.deliveryId,
        eventSessionId = payload and payload.eventSessionId or nil,
        grantId = payload and payload.grantId or nil,
        rewards = deepCopy(type(response) == "table" and response.rewards or {}),
    }
    for _, listener in pairs(self.LootReceivedListeners or {}) do
        if type(listener) == "function" then
            pcall(listener, deepCopy(notification))
        end
    end

    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
        for index = 1, #notification.rewards do
            local reward = notification.rewards[index]
            local appliedAmount = math.max(0, math.floor(tonumber(reward.appliedAmount) or 0))
            local name = resolveRewardDisplayName(reward)
            DEFAULT_CHAT_FRAME:AddMessage(("|cff00ccffRPE:|r You received %d %s."):format(appliedAmount, name))
        end
    end
    return true
end

local function sendDeliveryResponse(hostName, response)
    local target = normalizeName(hostName)
    local opcode = type(Operations.GetOpcode) == "function" and Operations:GetOpcode("LOOT_DELIVERY_RESPONSE") or Protocol.ResponseOpcode
    if target == "" or not opcode or type(Protocol.BuildResponseArguments) ~= "function" or type(Comms.SendMessage) ~= "function" then
        return false
    end
    local arguments = Protocol.BuildResponseArguments(response)
    if type(arguments) ~= "table" then
        return false
    end
    return Comms:SendMessage("WHISPER", opcode, arguments, target, {
        opcode = opcode,
        scope = "client",
    }) == true
end

function Client:ExecuteLootDelivery(payload, hostName)
    if type(payload) ~= "table" then
        return buildFailureResponse("", "invalid-payload"), false
    end
    local fingerprint, fingerprintReason = nil, nil
    if type(Protocol.BuildDeliveryFingerprint) == "function" then
        fingerprint, fingerprintReason = Protocol.BuildDeliveryFingerprint(payload)
    end
    if not fingerprint then
        return buildFailureResponse(payload.deliveryId, fingerprintReason or "invalid-payload"), false
    end

    local existing = readReceipt(payload.deliveryId)
    if existing then
        if trim(existing.requestFingerprint) ~= fingerprint then
            return buildFailureResponse(payload.deliveryId, "delivery-conflict"), false
        end
        if existing.status == "complete" and type(existing.result) == "table" then
            return deepCopy(existing.result), true
        end
        if existing.status == "in-progress" then
            existing.status = "recovery-required"
            existing.failedAt = getNow()
            existing.reason = "interrupted-loot-transaction"
            persistReceipt(payload.deliveryId, existing)
            return buildFailureResponse(payload.deliveryId, "recovery-required"), true
        end
        if existing.status == "recovery-required" then
            return buildFailureResponse(payload.deliveryId, "recovery-required"), true
        end
    end

    local plan, reason, detail = buildRewardPlan(payload.rewards)
    if not plan then
        local response = buildFailureResponse(payload.deliveryId, reason or "invalid-reward")
        return response, false, detail
    end
    local snapshots = nil
    snapshots, reason, detail = captureSnapshots(plan)
    if not snapshots then
        return buildFailureResponse(payload.deliveryId, reason or "reward-application-failed"), false, detail
    end
    return executeDeliveryPlan(payload, hostName, fingerprint, plan, snapshots), false
end

function Client:HandleLootDelivery(arguments, sender)
    if type(Protocol.ParseDeliveryArguments) ~= "function" then
        return false, buildFailureResponse("", "invalid-payload")
    end
    local payload, parseReason = Protocol.ParseDeliveryArguments(arguments)
    if not payload then
        return false, buildFailureResponse("", parseReason or "invalid-payload")
    end

    local authority, authorityReason = self:ResolveLootEventAuthority(payload.eventSessionId)
    if not authority then
        return false, buildFailureResponse(payload.deliveryId, authorityReason or "unknown-event-session")
    end
    local actualSender = normalizeName(sender)
    local hostName = normalizeName(authority.hostName)
    if actualSender == "" or hostName == "" or actualSender ~= hostName then
        return false, buildFailureResponse(payload.deliveryId, "invalid-sender")
    end

    local function failAuthenticated(reason)
        local response = buildFailureResponse(payload.deliveryId, reason)
        sendDeliveryResponse(hostName, response)
        return false, response
    end

    if tonumber(payload.protocolVersion) ~= tonumber(Protocol.Version or 1) then
        return failAuthenticated("unsupported-protocol")
    end
    if not validIdentifier(payload.deliveryId) then
        return failAuthenticated("invalid-delivery-id")
    end
    if not validIdentifier(payload.eventSessionId) then
        return failAuthenticated("unknown-event-session")
    end
    if not validIdentifier(payload.grantId) then
        return failAuthenticated("invalid-grant-id")
    end

    local recipient = normalizeName(payload.recipientName)
    local localPlayer = normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or "")
    if recipient == "" or localPlayer == "" or recipient ~= localPlayer then
        return failAuthenticated("wrong-recipient")
    end

    local response, duplicate = self:ExecuteLootDelivery(payload, hostName)
    sendDeliveryResponse(hostName, response)
    if response.success == true and duplicate ~= true then
        self:NotifyLootReceived(response, payload)
    end
    return response.success == true, response
end

if type(Profile.RecoverInterruptedLootReceipts) == "function" then
    pcall(Profile.RecoverInterruptedLootReceipts)
end
installEventAuthorityHooks()
