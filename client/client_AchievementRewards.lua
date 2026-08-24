local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Profile = Addon.Internal.Profile or {}
local Registry = Addon.Internal.Registry or {}
local Common = Addon.Utils and Addon.Utils.Common or {}

local Achievements = Client.Achievements or {}
Client.Achievements = Achievements

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

local function trimText(value)
    local text = tostring(value or "")
    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function getNow()
    if type(Common.GetNow) == "function" then
        return tonumber(Common.GetNow()) or 0
    end

    return 0
end

local function isFinitePositiveInteger(value)
    local numeric = tonumber(value)
    if not numeric
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

local function parseDatasetReference(reference)
    local normalized = trimText(reference)
    local separatorIndex = string.find(normalized, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = string.sub(normalized, 1, separatorIndex - 1)
    local entryId = string.sub(normalized, separatorIndex + 1)
    if datasetId == "" or entryId == "" then
        return nil, nil
    end

    return datasetId, entryId
end

local function getInventoryService()
    return Client.Inventory or {}
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

local function normalizeInventoryRecord(record)
    if type(record) ~= "table" then
        return nil
    end

    local datasetId = tostring(record.dataset or "")
    local itemId = tostring(record.id or "")
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

local function getInventoryItemVariants(inventory, datasetId, itemId)
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
        if item
            and item.dataset == datasetId
            and item.id == itemId
        then
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
            local itemQuantity = item.quantity
            local removeQuantity = math.min(itemQuantity, remaining)
            local removedCallOk, removed = pcall(inventory.RemoveItem, index, removeQuantity)
            if not removedCallOk or not removed then
                return false
            end

            remaining = remaining - removeQuantity
            if remaining <= 0 then
                return true
            end
        end
    end

    return false
end

local function restoreCurrencySnapshots(snapshots)
    if type(Profile.SetCurrencyAmount) ~= "function"
        or type(Profile.GetCurrencyAmount) ~= "function"
    then
        return false
    end

    local restored = true
    for index = #(snapshots or {}), 1, -1 do
        local snapshot = snapshots[index]
        local setCallOk, setResult = pcall(
            Profile.SetCurrencyAmount,
            snapshot.currencyRef,
            snapshot.amount
        )
        local getCallOk, actual = pcall(Profile.GetCurrencyAmount, snapshot.currencyRef)
        actual = getCallOk and (tonumber(actual) or 0) or nil
        if not setCallOk
            or setResult == nil
            or not getCallOk
            or actual ~= snapshot.amount
        then
            restored = false
        end
    end

    return restored
end

local function readRewardState(achievementRef)
    if type(Profile.GetAchievementRewardState) ~= "function" then
        return nil, "reward-state-api-unavailable"
    end

    local callOk, state = pcall(Profile.GetAchievementRewardState, achievementRef)
    if not callOk then
        return nil, "reward-state-read-failed"
    end

    return type(state) == "table" and state or nil
end

local function persistRewardState(achievementRef, state)
    if type(Profile.SetAchievementRewardState) ~= "function" then
        return false, "reward-state-api-unavailable"
    end

    local callOk, persisted = pcall(Profile.SetAchievementRewardState, achievementRef, state)
    if not callOk or type(persisted) ~= "table" then
        return false, "reward-state-persistence-failed"
    end

    if persisted.status ~= state.status then
        return false, "reward-state-verification-failed"
    end

    return true, persisted
end

local function buildRewardEntryId(reward, index, usedIds)
    local baseId = type(reward) == "table" and trimText(reward.id) or ""
    if baseId == "" then
        baseId = ("reward_%d"):format(index)
    end

    local rewardId = baseId
    local suffix = 2
    while usedIds[rewardId] do
        rewardId = ("%s_%d"):format(baseId, suffix)
        suffix = suffix + 1
    end

    usedIds[rewardId] = true
    return rewardId
end

local function buildAchievementRewardPlan(achievement)
    local plan = {
        supported = {},
        unsupported = {},
        needsItems = false,
        needsCurrencies = false,
    }
    local rewards = type(achievement and achievement.rewards) == "table"
        and achievement.rewards
        or {}
    local usedIds = {}

    for index = 1, #rewards do
        local reward = rewards[index]
        local rewardId = buildRewardEntryId(reward, index, usedIds)
        local rewardType = type(reward) == "table"
            and string.lower(trimText(reward.type))
            or ""
        local rewardRef = type(reward) == "table" and trimText(reward.ref) or ""

        if rewardType ~= "item" and rewardType ~= "currency" then
            plan.unsupported[#plan.unsupported + 1] = {
                id = rewardId,
                index = index,
                type = rewardType ~= "" and rewardType or "unsupported",
                ref = rewardRef,
                status = "unsupported",
            }
        else
            local amount = isFinitePositiveInteger(type(reward) == "table" and reward.amount or nil)
            if rewardRef == "" or not amount then
                return nil, "invalid-reward-definition", {
                    rewardId = rewardId,
                    rewardIndex = index,
                    rewardType = rewardType,
                }
            end

            if rewardType == "item" then
                if type(Registry.ResolveItemReference) ~= "function" then
                    return nil, "item-api-unavailable", {
                        rewardId = rewardId,
                        rewardIndex = index,
                        ref = rewardRef,
                    }
                end

                local resolveCallOk, dataset, item = pcall(
                    Registry.ResolveItemReference,
                    Registry,
                    rewardRef
                )
                local datasetId, itemId = parseDatasetReference(rewardRef)
                if not resolveCallOk
                    or type(dataset) ~= "table"
                    or type(item) ~= "table"
                    or not datasetId
                    or not itemId
                then
                    return nil, "item-unavailable", {
                        rewardId = rewardId,
                        rewardIndex = index,
                        ref = rewardRef,
                    }
                end

                plan.supported[#plan.supported + 1] = {
                    id = rewardId,
                    type = rewardType,
                    ref = rewardRef,
                    amount = amount,
                    datasetId = datasetId,
                    itemId = itemId,
                }
                plan.needsItems = true
            else
                if type(Profile.NormalizeCurrencyKey) ~= "function"
                    or type(Profile.ResolveCurrencyDefinition) ~= "function"
                then
                    return nil, "currency-api-unavailable", {
                        rewardId = rewardId,
                        rewardIndex = index,
                        ref = rewardRef,
                    }
                end

                local normalizeCallOk, currencyRef = pcall(
                    Profile.NormalizeCurrencyKey,
                    rewardRef
                )
                currencyRef = normalizeCallOk and trimText(currencyRef) or ""
                local resolveCallOk, definition = pcall(
                    Profile.ResolveCurrencyDefinition,
                    currencyRef
                )
                if currencyRef == ""
                    or not normalizeCallOk
                    or not resolveCallOk
                    or type(definition) ~= "table"
                    or definition.isMissing == true
                then
                    return nil, "currency-unavailable", {
                        rewardId = rewardId,
                        rewardIndex = index,
                        ref = rewardRef,
                    }
                end

                plan.supported[#plan.supported + 1] = {
                    id = rewardId,
                    type = rewardType,
                    ref = rewardRef,
                    currencyRef = currencyRef,
                    amount = amount,
                    definition = definition,
                }
                plan.needsCurrencies = true
            end
        end
    end

    local inventory = getInventoryService()
    if plan.needsItems
        and (type(inventory.AddItem) ~= "function"
            or type(inventory.GetItems) ~= "function"
            or type(inventory.RemoveItem) ~= "function")
    then
        return nil, "inventory-api-unavailable", {
            rewardType = "item",
        }
    end

    if plan.needsCurrencies
        and (type(Profile.GetCurrencyAmount) ~= "function"
            or type(Profile.AddCurrencyAmount) ~= "function"
            or type(Profile.SetCurrencyAmount) ~= "function")
    then
        return nil, "currency-api-unavailable", {
            rewardType = "currency",
        }
    end

    return plan
end

local function captureTransactionSnapshots(plan)
    local snapshots = {
        items = {},
        currencies = {},
    }
    local inventory = getInventoryService()
    local seenItems = {}
    local seenCurrencies = {}

    for index = 1, #(plan and plan.supported or {}) do
        local reward = plan.supported[index]
        if reward.type == "item" then
            if not seenItems[reward.ref] then
                local variants = getInventoryItemVariants(
                    inventory,
                    reward.datasetId,
                    reward.itemId
                )
                if variants == nil then
                    return nil, "item-snapshot-failed", {
                        rewardId = reward.id,
                        ref = reward.ref,
                    }
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
                return nil, "currency-snapshot-failed", {
                    rewardId = reward.id,
                    currencyRef = reward.currencyRef,
                }
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

local function createRewardState(existingState, plan, snapshots)
    local state = type(existingState) == "table" and deepCopy(existingState) or {}
    local entries = type(state.entries) == "table" and state.entries or {}

    state.status = "in-progress"
    state.startedAt = getNow()
    state.completedAt = nil
    state.failedAt = nil
    state.reason = nil
    state.snapshots = deepCopy(snapshots or {
        items = {},
        currencies = {},
    })

    for index = 1, #(plan and plan.unsupported or {}) do
        local reward = plan.unsupported[index]
        local entry = type(entries[reward.id]) == "table" and entries[reward.id] or {}
        entry.status = "unsupported"
        entry.type = reward.type
        entry.ref = reward.ref
        entry.reason = "unsupported-reward-type"
        entries[reward.id] = entry
    end

    for index = 1, #(plan and plan.supported or {}) do
        local reward = plan.supported[index]
        local entry = type(entries[reward.id]) == "table" and entries[reward.id] or {}
        entry.status = "pending"
        entry.type = reward.type
        entry.ref = reward.ref
        entry.amount = reward.amount
        entry.appliedAmount = nil
        entry.failedAt = nil
        entry.reason = nil
        entries[reward.id] = entry
    end

    state.entries = entries
    return state
end

local function createFailureState(existingState, reason, detail)
    local state = type(existingState) == "table" and deepCopy(existingState) or {}
    state.status = "failed"
    state.failedAt = getNow()
    state.completedAt = nil
    state.reason = reason
    if detail ~= nil then
        state.failure = deepCopy(detail)
    end
    state.entries = type(state.entries) == "table" and state.entries or {}
    return state
end

local function markEntryFailure(state, rewardId, reason, rolledBack)
    local entries = type(state.entries) == "table" and state.entries or {}
    for entryId, entry in pairs(entries) do
        if type(entry) == "table" then
            if entryId == rewardId then
                entry.status = "failed"
                entry.reason = reason
            elseif entry.status == "applied" then
                if rolledBack then
                    entry.status = "rolled-back"
                end
            elseif entry.status == "pending" then
                entry.status = "not-applied"
            end
        end
    end
    state.entries = entries
end

local function rollbackTransaction(transaction)
    if type(transaction) ~= "table" then
        return false
    end

    local inventory = getInventoryService()
    local restored = true
    for index = #(transaction.itemAwards or {}), 1, -1 do
        local award = transaction.itemAwards[index]
        if not removeInventoryVariantQuantity(
            inventory,
            award.variant,
            award.amount
        ) then
            restored = false
        end
    end

    if not restoreCurrencySnapshots(transaction.currencySnapshots) then
        restored = false
    end

    for index = 1, #(transaction.itemSnapshots or {}) do
        local snapshot = transaction.itemSnapshots[index]
        local actual = getInventoryItemVariants(
            inventory,
            snapshot.datasetId,
            snapshot.itemId
        )
        if actual == nil or not compareInventoryVariants(snapshot.variants, actual) then
            restored = false
        end
    end

    for index = 1, #(transaction.currencySnapshots or {}) do
        local snapshot = transaction.currencySnapshots[index]
        local callOk, actual = pcall(Profile.GetCurrencyAmount, snapshot.currencyRef)
        actual = callOk and (tonumber(actual) or 0) or nil
        if not callOk or actual ~= snapshot.amount then
            restored = false
        end
    end

    return restored
end

local function finishFailedTransaction(achievementRef, state, transaction, rewardId, reason)
    local rolledBack = rollbackTransaction(transaction)
    markEntryFailure(state, rewardId, reason, rolledBack)
    state.status = rolledBack and "failed" or "recovery-required"
    state.failedAt = getNow()
    state.completedAt = nil
    state.reason = reason

    local persisted = persistRewardState(achievementRef, state)
    if not persisted then
        state.status = "recovery-required"
        state.reason = reason .. ":reward-state-persistence-failed"
        persistRewardState(achievementRef, state)
    end

    return false, state.status, state
end

local function finishSuccessfulTransaction(achievementRef, state, plan)
    state.status = "complete"
    state.completedAt = getNow()
    state.failedAt = nil
    state.reason = #(plan and plan.unsupported or {}) > 0
        and "unsupported-reward-record"
        or nil

    local persisted, persistedReason = persistRewardState(achievementRef, state)
    if persisted then
        return true, "complete", state
    end

    return false, persistedReason or "reward-state-persistence-failed", state
end

local function executeRewardPlan(achievementRef, state, plan)
    local inventory = getInventoryService()
    local itemSnapshots = state.snapshots and state.snapshots.items or {}
    local expectedItemStates = {}
    for index = 1, #itemSnapshots do
        local snapshot = itemSnapshots[index]
        if snapshot.itemRef ~= nil then
            expectedItemStates[snapshot.itemRef] = deepCopy(snapshot.variants)
        end
    end

    local transaction = {
        itemAwards = {},
        itemSnapshots = itemSnapshots,
        expectedItemStates = expectedItemStates,
        currencySnapshots = state.snapshots and state.snapshots.currencies or {},
    }

    for index = 1, #(plan.supported or {}) do
        local reward = plan.supported[index]
        local entry = state.entries[reward.id]
        if reward.type == "item" then
            local expectedVariants = transaction.expectedItemStates[reward.ref]
            local beforeVariants = getInventoryItemVariants(
                inventory,
                reward.datasetId,
                reward.itemId
            )
            if expectedVariants == nil
                or beforeVariants == nil
                or not compareInventoryVariants(expectedVariants, beforeVariants)
            then
                return finishFailedTransaction(
                    achievementRef,
                    state,
                    transaction,
                    reward.id,
                    "item-snapshot-drift"
                )
            end

            local addCallOk, addedRecord = pcall(inventory.AddItem, {
                dataset = reward.datasetId,
                id = reward.itemId,
                quantity = reward.amount,
            })
            local addedVariant = normalizeInventoryRecord(addedRecord)
            local afterVariants = getInventoryItemVariants(
                inventory,
                reward.datasetId,
                reward.itemId
            )
            local beforeAdded = addedVariant
                and getInventoryVariantQuantity(beforeVariants, addedVariant)
                or nil
            local afterAdded = addedVariant
                and getInventoryVariantQuantity(afterVariants, addedVariant)
                or nil
            local actualAdded = beforeAdded ~= nil
                and afterAdded ~= nil
                and afterAdded - beforeAdded
                or nil
            if actualAdded and actualAdded > 0 then
                transaction.itemAwards[#transaction.itemAwards + 1] = {
                    variant = deepCopy(addedVariant),
                    amount = actualAdded,
                }
            end

            if not addCallOk
                or addedVariant == nil
                or beforeVariants == nil
                or afterVariants == nil
                or actualAdded ~= reward.amount
            then
                entry.appliedAmount = math.max(0, tonumber(actualAdded) or 0)
                return finishFailedTransaction(
                    achievementRef,
                    state,
                    transaction,
                    reward.id,
                    "item-award-failed"
                )
            end

            entry.status = "applied"
            entry.appliedAmount = actualAdded
            entry.appliedAt = getNow()
            transaction.expectedItemStates[reward.ref] = deepCopy(afterVariants)
        else
            local beforeCallOk, before = pcall(Profile.GetCurrencyAmount, reward.currencyRef)
            before = beforeCallOk and tonumber(before) or nil
            local addCallOk, addedAmount = pcall(
                Profile.AddCurrencyAmount,
                reward.currencyRef,
                reward.amount
            )
            local afterCallOk, after = pcall(Profile.GetCurrencyAmount, reward.currencyRef)
            after = afterCallOk and tonumber(after) or nil
            local actualAdded = before ~= nil and after ~= nil and after - before or nil

            if not addCallOk
                or addedAmount == nil
                or before == nil
                or not afterCallOk
                or actualAdded == nil
                or actualAdded < 0
                or actualAdded > reward.amount
            then
                entry.appliedAmount = math.max(0, tonumber(actualAdded) or 0)
                return finishFailedTransaction(
                    achievementRef,
                    state,
                    transaction,
                    reward.id,
                    "currency-award-failed"
                )
            end

            entry.status = "applied"
            entry.appliedAmount = actualAdded
            entry.appliedAt = getNow()
            if actualAdded < reward.amount then
                entry.reason = "currency-capped"
            else
                entry.reason = nil
            end
        end

        local persisted, persistReason = persistRewardState(achievementRef, state)
        if not persisted then
            return finishFailedTransaction(
                achievementRef,
                state,
                transaction,
                reward.id,
                persistReason or "reward-state-persistence-failed"
            )
        end
    end

    local success, reason, result = finishSuccessfulTransaction(achievementRef, state, plan)
    if success then
        return success, reason, result
    end

    return finishFailedTransaction(
        achievementRef,
        state,
        transaction,
        nil,
        reason or "reward-state-persistence-failed"
    )
end

local function markRecoveryRequired(achievementRef, rewardState, reason)
    local state = deepCopy(rewardState or {})
    state.status = "recovery-required"
    state.failedAt = getNow()
    state.reason = reason or "interrupted-reward-transaction"
    local persisted = persistRewardState(achievementRef, state)
    return persisted, state
end

local function getRewardDeliveryQueue(achievements)
    local queue = achievements._rewardDeliveryQueue
    if type(queue) ~= "table" then
        queue = {
            items = {},
            queued = {},
        }
        achievements._rewardDeliveryQueue = queue
    end

    queue.items = type(queue.items) == "table" and queue.items or {}
    queue.queued = type(queue.queued) == "table" and queue.queued or {}
    return queue
end

local function enqueueRewardDelivery(achievements, achievementRef, achievement, options)
    local activeRefs = achievements._rewardDeliveryActiveRefs or {}
    if activeRefs[achievementRef] then
        return false, "reward-delivery-active"
    end

    local queue = getRewardDeliveryQueue(achievements)
    if queue.queued[achievementRef] then
        return true, "already-queued"
    end

    local deliveryOptions = type(options) == "table" and options or {}
    queue.queued[achievementRef] = true
    queue.items[#queue.items + 1] = {
        achievementRef = achievementRef,
        achievement = achievement,
        options = {
            newlyCompleted = deliveryOptions.newlyCompleted == true,
            retry = deliveryOptions.retry == true,
        },
    }
    return true, "queued"
end

local function drainRewardDeliveryQueue(achievements)
    if achievements._rewardDeliveryDraining == true
        or (tonumber(achievements._rewardDeliveryDepth) or 0) > 0
    then
        return
    end

    local queue = getRewardDeliveryQueue(achievements)
    if #queue.items == 0 then
        return
    end

    achievements._rewardDeliveryDraining = true
    while #queue.items > 0 do
        local request = table.remove(queue.items, 1)
        queue.queued[request.achievementRef] = nil

        local callOk = pcall(
            achievements.DeliverRewards,
            achievements,
            request.achievementRef,
            request.achievement,
            request.options
        )
        if not callOk then
            local rewardState = readRewardState(request.achievementRef)
            if type(rewardState) == "table" and rewardState.status == "in-progress" then
                markRecoveryRequired(
                    request.achievementRef,
                    rewardState,
                    "queued-reward-delivery-error"
                )
            end
        end
    end

    achievements._rewardDeliveryDraining = nil
end

function Achievements:RecoverInProgressRewards()
    if self._rewardRecoveryChecked == true then
        return 0
    end

    if type(Profile.ListAchievementStates) ~= "function" then
        return 0
    end

    local callOk, states = pcall(Profile.ListAchievementStates)
    if not callOk or type(states) ~= "table" then
        return 0
    end

    local recovered = 0
    local allPersisted = true
    for achievementRef, achievementState in pairs(states) do
        local rewardState = type(achievementState) == "table"
            and achievementState.rewardState
            or nil
        if type(rewardState) == "table" and rewardState.status == "in-progress" then
            local persisted = markRecoveryRequired(
                achievementRef,
                rewardState,
                "interrupted-reward-transaction"
            )
            if persisted then
                recovered = recovered + 1
            else
                allPersisted = false
            end
        end
    end

    self._rewardRecoveryChecked = allPersisted
    return recovered
end

function Achievements:DeliverRewards(achievementRef, achievement, options)
    local normalizedRef = trimText(achievementRef)
    if normalizedRef == "" or type(achievement) ~= "table" then
        return false, "achievement-unavailable"
    end

    if (tonumber(self._rewardDeliveryDepth) or 0) > 0 then
        local queued, queueReason = enqueueRewardDelivery(
            self,
            normalizedRef,
            achievement,
            options
        )
        return queued, queueReason
    end

    local isRetry = type(options) == "table" and options.retry == true
    local isNewlyCompleted = type(options) == "table" and options.newlyCompleted == true
    local existingState, stateReason = readRewardState(normalizedRef)
    if stateReason then
        return false, stateReason
    end

    local existingStatus = type(existingState) == "table" and existingState.status or nil
    if existingStatus == "complete" or existingStatus == "legacy-skipped" then
        return false, existingStatus
    end
    if existingStatus == "recovery-required" then
        return false, "recovery-required"
    end
    if existingStatus == "in-progress" then
        markRecoveryRequired(normalizedRef, existingState)
        return false, "recovery-required"
    end

    if existingStatus == "failed" and not isRetry then
        return false, "retry-required"
    end
    if existingStatus ~= nil
        and existingStatus ~= "failed"
        and existingStatus ~= "pending"
    then
        return false, "reward-state-not-ready"
    end

    if not isRetry and not isNewlyCompleted then
        return false, "new-completion-required"
    end

    if type(Profile.GetAchievementState) ~= "function" then
        return false, "achievement-state-api-unavailable"
    end
    local achievementStateCallOk, achievementState = pcall(
        Profile.GetAchievementState,
        normalizedRef
    )
    if not achievementStateCallOk
        or type(achievementState) ~= "table"
        or tonumber(achievementState.completedAt) == nil
    then
        return false, "achievement-incomplete"
    end

    local plan, planReason, planDetail = buildAchievementRewardPlan(achievement)
    if not plan then
        local failedState = createFailureState(existingState, planReason, planDetail)
        persistRewardState(normalizedRef, failedState)
        return false, planReason, failedState
    end

    if #plan.supported == 0 then
        local completedState = createRewardState(existingState, plan, {
            items = {},
            currencies = {},
        })
        completedState.status = "complete"
        completedState.completedAt = getNow()
        completedState.failedAt = nil
        completedState.reason = #plan.unsupported > 0
            and "unsupported-reward-record"
            or "no-rewards"
        local persisted, persistedReason = persistRewardState(normalizedRef, completedState)
        if not persisted then
            return false, persistedReason, completedState
        end
        return true, "complete", completedState
    end

    local snapshots, snapshotReason, snapshotDetail = captureTransactionSnapshots(plan)
    if not snapshots then
        local failedState = createFailureState(existingState, snapshotReason, snapshotDetail)
        persistRewardState(normalizedRef, failedState)
        return false, snapshotReason, failedState
    end

    local state = createRewardState(existingState, plan, snapshots)
    local persisted, persistedReason = persistRewardState(normalizedRef, state)
    if not persisted then
        return false, persistedReason, state
    end

    self._rewardDeliveryDepth = (tonumber(self._rewardDeliveryDepth) or 0) + 1
    self._rewardDeliveryActiveRefs = self._rewardDeliveryActiveRefs or {}
    self._rewardDeliveryActiveRefs[normalizedRef] = true

    local callOk, success, reason, result = pcall(
        executeRewardPlan,
        normalizedRef,
        state,
        plan
    )

    self._rewardDeliveryActiveRefs[normalizedRef] = nil
    self._rewardDeliveryDepth = math.max(0, (tonumber(self._rewardDeliveryDepth) or 1) - 1)

    if not callOk then
        local persistedRecovery, recoveryState = markRecoveryRequired(
            normalizedRef,
            state,
            "reward-delivery-error"
        )
        success = false
        reason = persistedRecovery and "recovery-required"
            or "reward-state-persistence-failed"
        result = recoveryState
    end

    if (tonumber(self._rewardDeliveryDepth) or 0) == 0 then
        drainRewardDeliveryQueue(self)
    end

    return success, reason, result
end

function Achievements:RetryRewards(achievementRef)
    local normalizedRef = trimText(achievementRef)
    if normalizedRef == "" then
        return false, "achievement-unavailable"
    end

    if type(Profile.GetAchievementState) ~= "function"
        or type(Registry.ResolveAchievementReference) ~= "function"
    then
        return false, "achievement-api-unavailable"
    end

    local stateCallOk, achievementState = pcall(Profile.GetAchievementState, normalizedRef)
    if not stateCallOk or type(achievementState) ~= "table" then
        return false, "achievement-state-unavailable"
    end
    if tonumber(achievementState.completedAt) == nil then
        return false, "achievement-incomplete"
    end

    local rewardState, rewardStateReason = readRewardState(normalizedRef)
    if rewardStateReason then
        return false, rewardStateReason
    end
    if type(rewardState) ~= "table" then
        return false, "no-reward-transaction"
    end
    if rewardState.status == "in-progress" then
        markRecoveryRequired(normalizedRef, rewardState)
        return false, "recovery-required"
    end
    if rewardState.status ~= "failed" then
        return false, rewardState.status or "reward-state-not-retryable"
    end

    local resolveCallOk, _, achievement = pcall(
        Registry.ResolveAchievementReference,
        Registry,
        normalizedRef
    )
    if not resolveCallOk or type(achievement) ~= "table" then
        return false, "achievement-unavailable"
    end

    return self:DeliverRewards(normalizedRef, achievement, { retry = true })
end

return Achievements
