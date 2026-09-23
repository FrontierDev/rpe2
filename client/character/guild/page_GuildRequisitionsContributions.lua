local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local Page = Addon.Client.UI.Guild.RequisitionsPage
local Guild = Addon.Client.Guild
if not Page or not Guild then return end

local OldPartitionRequisitions = Page.PartitionRequisitions

function Page:PartitionRequisitions()
    local shopRows, limitedRows = OldPartitionRequisitions(self)
    if type(Guild.GetGuildShopContributionRows) ~= "function" then
        return shopRows, limitedRows
    end

    local ok, contributed = pcall(Guild.GetGuildShopContributionRows, Guild)
    if not ok or type(contributed) ~= "table" then
        return shopRows, limitedRows
    end

    for index = 1, #contributed do
        local row = contributed[index]
        if type(row) == "table" and type(row.requisition) == "table" then
            shopRows[#shopRows + 1] = row.requisition
        end
    end

    return shopRows, limitedRows
end

-- Guild requisitions, Guild Shop entries, and Daily Rewards can also resolve
-- Loot Tables. Item requisitions retain the existing path unchanged.
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Loot = Addon.Internal and Addon.Internal.Loot or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local DEFAULT_LOOT_ICON = "Interface\\Icons\\INV_Misc_Chest_04"
local unpackValues = table.unpack or unpack

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function positiveInteger(value, fallback)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then numeric = fallback or 1 end
    return math.max(1, math.floor(numeric))
end

local function normalizeCharacterLimit(value)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then return 1 end
    if numeric == 0 then return 0 end
    return math.max(1, math.floor(numeric))
end

local function requisitionSourceType(requisition)
    local sourceType = string.lower(trim(requisition and requisition.sourceType))
    if sourceType == "loot" or sourceType == "table" or sourceType == "loot_table" then return "loot_table" end
    if trim(requisition and requisition.lootRef) ~= "" and trim(requisition and requisition.itemRef) == "" then return "loot_table" end
    return "item"
end

local function isLootDailyReward(reward)
    local rewardType = string.lower(trim(reward and reward.type))
    return rewardType == "loot" or rewardType == "table" or rewardType == "loot_table"
end

local function findRequisition(setting, requisitionId)
    local wanted = trim(requisitionId)
    for index = 1, #(setting and setting.requisitions or {}) do
        local requisition = setting.requisitions[index]
        if trim(requisition and requisition.id) == wanted then return requisition end
    end
    return nil
end

local function resolveRequestedRequisition(self, requisitionId)
    if type(self.ResolveGuildShopContributionRequisition) == "function" then
        local contribution = self:ResolveGuildShopContributionRequisition(requisitionId)
        if contribution and type(contribution.requisition) == "table" then return contribution.requisition, contribution end
    end
    local setting, resolution = self:GetActiveGuildSetting()
    return findRequisition(setting, requisitionId), nil, setting, resolution
end

local function normalizeCurrencyCosts(costs)
    if type(Profile.NormalizeCurrencyKey) ~= "function" or type(Profile.ResolveCurrencyDefinition) ~= "function" then
        return nil, "currency-api-unavailable"
    end
    local result, byCurrency = {}, {}
    for index = 1, #(costs or {}) do
        local row = costs[index]
        local currencyRef = trim(Profile.NormalizeCurrencyKey(row and row.currencyRef))
        local amount = tonumber(row and row.amount)
        if currencyRef == "" then return nil, "currency-unavailable", { costIndex = index } end
        if not amount or amount ~= amount or amount == math.huge or amount == -math.huge or amount < 0 then
            return nil, "invalid-currency-cost", { currencyRef = currencyRef, costIndex = index }
        end
        local ok, definition = pcall(Profile.ResolveCurrencyDefinition, currencyRef)
        if not ok or type(definition) ~= "table" or definition.isMissing == true then
            return nil, "currency-unavailable", { currencyRef = currencyRef, costIndex = index }
        end
        amount = math.floor(amount)
        local entry = byCurrency[currencyRef]
        if not entry then
            entry = { currencyRef = currencyRef, amount = 0, definition = definition }
            byCurrency[currencyRef] = entry
            result[#result + 1] = entry
        end
        entry.amount = entry.amount + amount
    end
    return result
end

local function inventoryService()
    return Addon.Client and Addon.Client.Inventory or {}
end

local function parseItemRef(reference)
    local datasetId, itemId = trim(reference):match("^([^:]+):(.+)$")
    if not datasetId or not itemId then return nil, nil end
    return trim(datasetId), trim(itemId)
end

local function inventoryQuantity(inventory, datasetId, itemId)
    if type(inventory.GetItems) ~= "function" then return nil end
    local ok, items = pcall(inventory.GetItems)
    if not ok or type(items) ~= "table" then return nil end
    local total = 0
    for index = 1, #items do
        local item = items[index]
        if tostring(item and item.dataset or "") == datasetId and tostring(item and item.id or "") == itemId then
            total = total + math.max(0, math.floor(tonumber(item.quantity or item.count) or 0))
        end
    end
    return total
end

local function removeInventoryQuantity(inventory, datasetId, itemId, amount)
    local remaining = math.max(0, math.floor(tonumber(amount) or 0))
    if remaining == 0 then return true end
    if type(inventory.GetItems) ~= "function" or type(inventory.RemoveItem) ~= "function" then return false end
    local ok, items = pcall(inventory.GetItems)
    if not ok or type(items) ~= "table" then return false end
    for index = #items, 1, -1 do
        local item = items[index]
        if tostring(item and item.dataset or "") == datasetId and tostring(item and item.id or "") == itemId then
            local available = math.max(1, math.floor(tonumber(item.quantity or item.count) or 1))
            local take = math.min(available, remaining)
            local removed, result = pcall(inventory.RemoveItem, index, take)
            if not removed or not result then return false end
            remaining = remaining - take
            if remaining <= 0 then return true end
        end
    end
    return false
end

local function restoreCurrencies(snapshots)
    if #(snapshots or {}) == 0 then return true end
    if type(Profile.SetCurrencyAmount) ~= "function" or type(Profile.GetCurrencyAmount) ~= "function" then return false end
    local restored = true
    for index = #snapshots, 1, -1 do
        local snapshot = snapshots[index]
        local ok = pcall(Profile.SetCurrencyAmount, snapshot.currencyRef, snapshot.amount)
        local got, actual = pcall(Profile.GetCurrencyAmount, snapshot.currencyRef)
        if not ok or not got or tonumber(actual) ~= snapshot.amount then restored = false end
    end
    return restored
end

local function newRewardTransaction()
    local transaction = { itemAwards = {}, currencySnapshots = {} }
    function transaction:Rollback()
        local restored = true
        local inventory = inventoryService()
        for index = #self.itemAwards, 1, -1 do
            local award = self.itemAwards[index]
            if not removeInventoryQuantity(inventory, award.datasetId, award.itemId, award.amount) then restored = false end
        end
        if not restoreCurrencies(self.currencySnapshots) then restored = false end
        return restored
    end
    return transaction
end

local function awardConcreteRewards(rewards)
    local inventory = inventoryService()
    local transaction = newRewardTransaction()
    local currencySnapshots = {}
    for index = 1, #(rewards or {}) do
        local reward = rewards[index]
        if reward.type == "currency" and not currencySnapshots[reward.ref] then
            if type(Profile.GetCurrencyAmount) ~= "function" then return false, "currency-api-unavailable", transaction end
            local ok, amount = pcall(Profile.GetCurrencyAmount, reward.ref)
            if not ok then return false, "currency-read-failed", transaction end
            local snapshot = { currencyRef = reward.ref, amount = tonumber(amount) or 0 }
            currencySnapshots[reward.ref] = snapshot
            transaction.currencySnapshots[#transaction.currencySnapshots + 1] = snapshot
        end
    end

    for index = 1, #(rewards or {}) do
        local reward = rewards[index]
        if reward.type == "item" then
            local datasetId, itemId = parseItemRef(reward.ref)
            if not datasetId or not itemId or type(inventory.AddItem) ~= "function" then
                return false, transaction:Rollback() and "inventory-api-unavailable" or "rollback-failed", transaction
            end
            local before = inventoryQuantity(inventory, datasetId, itemId)
            local ok, record = pcall(inventory.AddItem, { dataset = datasetId, id = itemId, quantity = reward.amount })
            local after = inventoryQuantity(inventory, datasetId, itemId)
            local measured = before ~= nil and after ~= nil
            local awarded = measured and math.max(0, after - before) or reward.amount
            if awarded > 0 and ((ok and record) or measured) then
                transaction.itemAwards[#transaction.itemAwards + 1] = { datasetId = datasetId, itemId = itemId, amount = awarded }
            end
            if not ok or not record or (measured and awarded < reward.amount) then
                return false, transaction:Rollback() and "item-award-failed" or "rollback-failed", transaction
            end
        elseif reward.type == "currency" then
            if type(Profile.AddCurrencyAmount) ~= "function" or type(Profile.GetCurrencyAmount) ~= "function" then
                return false, transaction:Rollback() and "currency-api-unavailable" or "rollback-failed", transaction
            end
            local snapshot = currencySnapshots[reward.ref]
            local ok = pcall(Profile.AddCurrencyAmount, reward.ref, reward.amount)
            local got, after = pcall(Profile.GetCurrencyAmount, reward.ref)
            if not ok or not got or tonumber(after) ~= snapshot.amount + reward.amount then
                return false, transaction:Rollback() and "currency-award-failed" or "rollback-failed", transaction
            end
        end
    end
    return true, "ok", transaction
end

local function resolveLootRolls(validatedLoot, count)
    if type(Loot.ResolveValidatedLootTable) ~= "function" or type(Loot.MergeConcreteRewards) ~= "function" then
        return nil, "loot-api-unavailable"
    end
    local rewards = {}
    for rollIndex = 1, positiveInteger(count, 1) do
        local resolved, reason, detail = Loot.ResolveValidatedLootTable(validatedLoot)
        if not resolved then
            detail = type(detail) == "table" and detail or {}
            detail.rollIndex = rollIndex
            return nil, reason, detail
        end
        for index = 1, #resolved do rewards[#rewards + 1] = resolved[index] end
    end
    return Loot.MergeConcreteRewards(rewards)
end

local function validateLootRewardCapabilities(validatedLoot)
    local needsItem, needsCurrency = false, false
    for index = 1, #(validatedLoot and validatedLoot.entries or {}) do
        local entry = validatedLoot.entries[index]
        if entry.type == "item" then needsItem = true end
        if entry.type == "currency" then needsCurrency = true end
    end
    if needsItem and type(inventoryService().AddItem) ~= "function" then return false, "inventory-unavailable" end
    if needsCurrency and (type(Profile.GetCurrencyAmount) ~= "function" or type(Profile.AddCurrencyAmount) ~= "function" or type(Profile.SetCurrencyAmount) ~= "function") then
        return false, "currency-api-unavailable"
    end
    return true
end

local function validateRequisitionRoles(self, requisition)
    local required = type(requisition and requisition.roleIds) == "table" and requisition.roleIds or {}
    if #required == 0 then return true, nil, { requiredRoleIds = {}, effectiveRoleIds = {} } end
    local _, effective = self:GetEffectiveRoles()
    if type(effective) ~= "table" or effective.status ~= "active" then
        return false, effective and effective.reason or "setting-unavailable", effective
    end
    local effectiveIds = {}
    for index = 1, #(effective.roles or {}) do effectiveIds[#effectiveIds + 1] = effective.roles[index].roleId end
    for index = 1, #required do
        local roleId = trim(required[index])
        if roleId ~= "" and effective.byId and effective.byId[roleId] then
            return true, nil, { requiredRoleIds = required, effectiveRoleIds = effectiveIds }
        end
    end
    return false, "missing-required-role", { requiredRoleIds = required, effectiveRoleIds = effectiveIds }
end

local BaseGetRequisitionEligibility = Guild.GetRequisitionEligibility
local BaseTryRequisition = Guild.TryRequisition

function Guild:GetRequisitionEligibility(guildSettingRef, requisitionId)
    local requisition, contribution = resolveRequestedRequisition(self, requisitionId)
    if not requisition or requisitionSourceType(requisition) ~= "loot_table" then
        return BaseGetRequisitionEligibility(self, guildSettingRef, requisitionId)
    end

    local setting, resolution = self:GetActiveGuildSetting()
    if not setting or not resolution or resolution.status ~= "active" then
        return false, resolution and resolution.reason or "setting-unavailable", resolution
    end
    if trim(guildSettingRef) ~= "" and trim(guildSettingRef) ~= trim(resolution.ref) then
        return false, "setting-mismatch", { activeSettingRef = resolution.ref, requestedSettingRef = guildSettingRef }
    end
    if type(setting.general) ~= "table" or setting.general.enableRequisitions ~= true then
        return false, "requisitions-disabled", resolution
    end

    local roleOk, roleReason, roleDetail = validateRequisitionRoles(self, requisition)
    if not roleOk then return false, roleReason, roleDetail end

    if type(Loot.ResolveLootReference) ~= "function" then return false, "loot-api-unavailable", { lootRef = trim(requisition.lootRef) } end
    local lootRef = trim(requisition.lootRef)
    local validatedLoot, lootReason, lootDetail = Loot.ResolveLootReference(lootRef)
    if not validatedLoot then return false, lootReason or "loot-table-unavailable", lootDetail or { lootRef = lootRef } end
    local capabilitiesOk, capabilityReason = validateLootRewardCapabilities(validatedLoot)
    if not capabilitiesOk then return false, capabilityReason, { lootRef = lootRef } end

    local limit = normalizeCharacterLimit(requisition.characterLimit)
    local usage = 0
    if limit > 0 then
        if type(Profile.GetGuildRequisitionUsage) ~= "function" then return false, "ledger-unavailable" end
        usage = math.max(0, math.floor(tonumber(Profile.GetGuildRequisitionUsage(resolution.guildKey, resolution.ref, requisition.id)) or 0))
        if usage >= limit then
            return false, "character-limit-reached", { usage = usage, characterLimit = limit, requisitionId = requisition.id }
        end
    end

    local costs, costReason, costDetail = normalizeCurrencyCosts(requisition.costs)
    if not costs then return false, costReason, costDetail end
    if type(Profile.GetCurrencyAmount) ~= "function" then return false, "currency-api-unavailable" end
    for index = 1, #costs do
        local cost = costs[index]
        local balance = tonumber(Profile.GetCurrencyAmount(cost.currencyRef)) or 0
        if balance < cost.amount then
            return false, "insufficient-currency", { currencyRef = cost.currencyRef, balance = balance, amount = cost.amount }
        end
    end

    return true, nil, {
        guildKey = resolution.guildKey,
        setting = setting,
        settingRef = resolution.ref,
        requisition = requisition,
        requisitionId = trim(requisition.id),
        sourceType = "loot_table",
        lootRef = lootRef,
        lootTable = validatedLoot,
        rollCount = positiveInteger(requisition.quantity, 1),
        costs = costs,
        usage = usage,
        characterLimit = limit,
        isUnlimited = limit == 0,
        roleDetail = roleDetail,
        shopContribution = contribution,
    }
end

local function spendCosts(costs)
    local snapshots = {}
    if #(costs or {}) == 0 then return true, snapshots end
    if type(Profile.GetCurrencyAmount) ~= "function" or type(Profile.SpendCurrencyAmount) ~= "function" then
        return false, snapshots, "currency-api-unavailable"
    end
    for index = 1, #costs do
        local cost = costs[index]
        snapshots[index] = { currencyRef = cost.currencyRef, amount = tonumber(Profile.GetCurrencyAmount(cost.currencyRef)) or 0 }
    end
    for index = 1, #costs do
        local cost = costs[index]
        local expected = snapshots[index].amount - cost.amount
        local ok, spent, updated = pcall(Profile.SpendCurrencyAmount, cost.currencyRef, cost.amount)
        local got, after = pcall(Profile.GetCurrencyAmount, cost.currencyRef)
        after = got and tonumber(after) or nil
        if not ok or spent ~= true or updated ~= expected or after ~= expected then
            return false, snapshots, restoreCurrencies(snapshots) and "currency-transaction-failed" or "rollback-failed"
        end
    end
    return true, snapshots
end

function Guild:TryRequisition(guildSettingRef, requisitionId)
    local requisition = select(1, resolveRequestedRequisition(self, requisitionId))
    if not requisition or requisitionSourceType(requisition) ~= "loot_table" then
        return BaseTryRequisition(self, guildSettingRef, requisitionId)
    end

    local eligible, reason, detail = self:GetRequisitionEligibility(guildSettingRef, requisitionId)
    if not eligible then return false, reason, detail end
    local rewards, resolveReason, resolveDetail = resolveLootRolls(detail.lootTable, detail.rollCount)
    if not rewards then return false, resolveReason or "loot-resolution-failed", resolveDetail end
    local spent, costSnapshots, spendReason = spendCosts(detail.costs)
    if not spent then return false, spendReason, detail end
    local awarded, awardReason, rewardTransaction = awardConcreteRewards(rewards)
    if not awarded then
        local costsRestored = restoreCurrencies(costSnapshots)
        return false, costsRestored and awardReason or "rollback-failed", detail
    end

    local updatedUsage = detail.usage
    if detail.characterLimit > 0 then
        local expectedUsage = detail.usage + 1
        local incrementOk, incrementValue = false, nil
        if type(Profile.IncrementGuildRequisitionUsage) == "function" then
            incrementOk, incrementValue = pcall(Profile.IncrementGuildRequisitionUsage, detail.guildKey, detail.settingRef, detail.requisitionId)
        end
        updatedUsage = incrementOk and incrementValue or nil
        if updatedUsage ~= expectedUsage then
            local rewardsRestored = rewardTransaction:Rollback()
            local ledgerRestored = false
            if rewardsRestored and type(Profile.SetGuildRequisitionUsage) == "function" then
                local setOk, setValue = pcall(Profile.SetGuildRequisitionUsage, detail.guildKey, detail.settingRef, detail.requisitionId, detail.usage)
                ledgerRestored = setOk and setValue == detail.usage
            end
            local costsRestored = restoreCurrencies(costSnapshots)
            return false, (rewardsRestored and ledgerRestored and costsRestored) and "ledger-update-failed" or "rollback-failed", detail
        end
    end

    pcall(self.RefreshWindow, self)
    return true, "ok", {
        guildSettingRef = detail.settingRef,
        requisitionId = detail.requisitionId,
        lootRef = detail.lootRef,
        rollCount = detail.rollCount,
        rewards = rewards,
        usage = updatedUsage,
        characterLimit = detail.characterLimit,
    }
end

local BaseGetDailyRewardStatus = Guild.GetDailyRewardStatus
local BaseProcessDailyRewards = Guild.ProcessDailyRewards

local function hasLootTableDailyRewards(setting)
    for index = 1, #(setting and setting.dailyRewards or {}) do
        if isLootDailyReward(setting.dailyRewards[index]) then return true end
    end
    return false
end

local function validateDailyLootTables(setting)
    if type(Loot.ResolveLootReference) ~= "function" then return nil, "loot-api-unavailable" end
    local validated = {}
    for index = 1, #(setting and setting.dailyRewards or {}) do
        local reward = setting.dailyRewards[index]
        if isLootDailyReward(reward) then
            local lootRef = trim(reward.ref)
            local lootTable, reason, detail = Loot.ResolveLootReference(lootRef)
            if not lootTable then
                detail = type(detail) == "table" and detail or {}
                detail.rewardIndex = index
                detail.rewardId = trim(reward.id)
                return nil, reason, detail
            end
            local capabilitiesOk, capabilityReason = validateLootRewardCapabilities(lootTable)
            if not capabilitiesOk then
                return nil, capabilityReason, { rewardIndex = index, rewardId = trim(reward.id), ref = lootRef }
            end
            validated[index] = lootTable
        end
    end
    return validated
end

local function withTemporaryDailyRewards(setting, rewards, callback)
    local original = setting.dailyRewards
    setting.dailyRewards = rewards
    local results = { xpcall(callback, function(message) return tostring(message) end) }
    setting.dailyRewards = original
    return unpackValues(results)
end

function Guild:GetDailyRewardStatus()
    local setting = select(1, self:GetActiveGuildSetting())
    if not hasLootTableDailyRewards(setting) then return BaseGetDailyRewardStatus(self) end

    local authoredRewards = setting.dailyRewards
    local surrogateRewards = {}
    for index = 1, #authoredRewards do
        local reward = authoredRewards[index]
        if isLootDailyReward(reward) then
            surrogateRewards[index] = { id = reward.id, type = "currency", ref = "copper", amount = 1, roleIds = reward.roleIds }
        else
            surrogateRewards[index] = reward
        end
    end

    local callOk, status = withTemporaryDailyRewards(setting, surrogateRewards, function()
        return BaseGetDailyRewardStatus(self)
    end)
    if not callOk or type(status) ~= "table" then
        return { status = "processing-failed", reason = "processing-failed", rewards = authoredRewards }
    end
    local eligibleById = {}
    for index = 1, #(status.rewards or {}) do eligibleById[tostring(status.rewards[index] and status.rewards[index].id or "")] = true end
    status.rewards = {}
    for index = 1, #authoredRewards do
        local reward = authoredRewards[index]
        if eligibleById[tostring(reward and reward.id or "")] then status.rewards[#status.rewards + 1] = reward end
    end
    if status.status ~= "available-today" then return status end

    local validated, reason, detail = validateDailyLootTables(setting)
    if not validated then
        status.status = reason or "loot-table-unavailable"
        status.reason = status.status
        status.detail = detail
        status.plan = nil
        return status
    end
    status.lootTables = validated
    return status
end

local function resolveDailyRewards(setting, selectedRewards)
    local validated, reason, detail = validateDailyLootTables(setting)
    if not validated then return nil, reason, detail end
    if type(Loot.ValidateConcreteReward) ~= "function" or type(Loot.MergeConcreteRewards) ~= "function" then
        return nil, "loot-api-unavailable"
    end
    local concreteRewards = {}
    local selectedById = {}
    for index = 1, #(selectedRewards or {}) do selectedById[tostring(selectedRewards[index] and selectedRewards[index].id or "")] = true end
    for index = 1, #(setting and setting.dailyRewards or {}) do
        local reward = setting.dailyRewards[index]
        if selectedById[tostring(reward and reward.id or "")] then
        if isLootDailyReward(reward) then
            local rolled, rollReason, rollDetail = resolveLootRolls(validated[index], positiveInteger(reward.amount, 1))
            if not rolled then return nil, rollReason, rollDetail end
            for rewardIndex = 1, #rolled do concreteRewards[#concreteRewards + 1] = rolled[rewardIndex] end
        else
            local concrete, concreteReason, concreteDetail = Loot.ValidateConcreteReward({ type = reward.type, ref = reward.ref, amount = reward.amount })
            if not concrete then
                concreteDetail = type(concreteDetail) == "table" and concreteDetail or {}
                concreteDetail.rewardIndex = index
                return nil, concreteReason, concreteDetail
            end
            concreteRewards[#concreteRewards + 1] = concrete
        end
        end
    end
    return Loot.MergeConcreteRewards(concreteRewards)
end

function Guild:ProcessDailyRewards()
    local setting = select(1, self:GetActiveGuildSetting())
    if not hasLootTableDailyRewards(setting) then return BaseProcessDailyRewards(self) end

    local status = self:GetDailyRewardStatus()
    if type(status) ~= "table" or status.status ~= "available-today" then
        return false, status and status.status or "unavailable", status
    end
    local concreteRewards, reason, detail = resolveDailyRewards(setting, status.availableRewards or status.rewards)
    if not concreteRewards then return false, reason or "loot-resolution-failed", detail end

    local temporary = {}
    local eligibleRoleIds, eligibleRoleSeen = {}, {}
    for index = 1, #(status.availableRewards or {}) do
        for roleIndex = 1, #(status.availableRewards[index].roleIds or {}) do
            local roleId = status.availableRewards[index].roleIds[roleIndex]
            if not eligibleRoleSeen[roleId] then eligibleRoleSeen[roleId] = true; eligibleRoleIds[#eligibleRoleIds + 1] = roleId end
        end
    end
    for index = 1, #concreteRewards do
        local reward = concreteRewards[index]
        temporary[index] = {
            id = ("resolved_daily_reward_%d"):format(index),
            type = reward.type,
            ref = reward.ref,
            amount = reward.amount,
            roleIds = eligibleRoleIds,
        }
    end

    local callOk, success, processReason, result = withTemporaryDailyRewards(setting, temporary, function()
        return BaseProcessDailyRewards(self)
    end)
    if not callOk then return false, "processing-failed", { error = success } end
    if success then
        for index = 1, #(status.plan or {}) do
            local reward = status.plan[index]
            local stored = type(Profile.SetDailyRewardClaim) == "function"
                and Profile.SetDailyRewardClaim(status.guildKey, status.dayKey, status.settingRef, Profile.DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE, reward.id)
            if type(stored) ~= "table" then return false, "claim-persistence-failed", result end
        end
    end
    if success and type(result) == "table" then result.resolvedRewards = concreteRewards end
    return success, processReason, result
end

local function resolveLootDisplay(requisition)
    local reference = trim(requisition and requisition.lootRef)
    local display = {
        ref = reference,
        name = reference ~= "" and "Missing Loot Table" or "Unassigned Loot Table",
        description = "",
        drawCount = nil,
        icon = DEFAULT_LOOT_ICON,
    }
    if type(Registry.ResolveLootReference) ~= "function" or reference == "" then return display end
    local ok, _, lootTable = pcall(Registry.ResolveLootReference, Registry, reference)
    if ok and type(lootTable) == "table" then
        display.name = trim(lootTable.name) ~= "" and trim(lootTable.name) or "Loot Table"
        display.description = trim(lootTable.description)
        display.drawCount = positiveInteger(lootTable.drawCount, 1)
        display.icon = trim(lootTable.icon) ~= "" and lootTable.icon or display.icon
        display.lootTable = lootTable
    end
    return display
end

local function buildLootTooltip(display, requisition)
    local builder = Addon.Client and Addon.Client.UI and Addon.Client.UI.Tooltips and Addon.Client.UI.Tooltips.Loot or nil
    if builder and type(builder.Build) == "function" then
        local tooltip = builder:Build({
            lootRef = display and display.ref,
            lootTable = display and display.lootTable,
        })
        if tooltip then return tooltip end
    end

    return {
        type = "custom",
        title = display and display.name or "Loot Table",
        lines = {
            { left = display and display.description or "", colorToken = "text.secondary" },
            { left = ("Rolls: %d"):format(positiveInteger(requisition and requisition.quantity, 1)), colorToken = "text.secondary" },
        },
    }
end

local function roleName(setting, roleId)
    local wanted = trim(roleId)
    for index = 1, #(setting and setting.roles or {}) do
        local role = setting.roles[index]
        if trim(role and role.id) == wanted then
            local name = trim(role.name)
            return name ~= "" and name or "Role"
        end
    end
    return "Missing Role"
end

local BaseBindShopEntry = Page.BindShopEntry
local BaseBuildResolvedShopRows = Page.BuildResolvedShopRows
local BaseBuildDailyRewardTooltip = Page.BuildDailyRewardTooltip
local BaseHideShopEntry = Page.HideShopEntry

function Page:BindShopEntry(entry, requisition)
    if requisitionSourceType(requisition) ~= "loot_table" then
        entry.resolvedLootDisplay = nil
        return BaseBindShopEntry(self, entry, requisition)
    end

    local display = resolveLootDisplay(requisition)
    local eligible, reason, detail = self:GetShopEligibility(requisition)
    local costText = self:FormatCompactCost(requisition and requisition.costs)
    entry:SetOption("keepMouseEnabled", true)
    entry.resolvedRequisition = requisition
    entry.resolvedItem = nil
    entry.resolvedItemRef = nil
    entry.resolvedItemDisplay = nil
    entry.resolvedItemName = display.name
    entry.resolvedLootDisplay = display
    entry.resolvedCostText = costText
    entry.resolvedEligibility = eligible
    entry.resolvedEligibilityReason = reason
    entry.resolvedEligibilityDetail = detail
    entry:SetIcon(display.icon)
    entry:SetItemName(display.name)
    entry:SetCostText(costText)
    entry:SetCostColor(reason == "insufficient-currency" and "danger" or "text.secondary")
    entry:SetEnabled(eligible)
    entry:SetTooltip(function()
        local tooltip = buildLootTooltip(display, requisition)
        local lines = tooltip.lines or {}
        if reason == "missing-required-role" then
            local names = {}
            for index = 1, #(requisition.roleIds or {}) do names[#names + 1] = roleName(self.ActiveGuildSetting, requisition.roleIds[index]) end
            lines[#lines + 1] = { text = " ", wrap = false }
            lines[#lines + 1] = {
                text = #names == 1 and ("Requires Role: %s"):format(names[1]) or ("Requires one of: %s"):format(table.concat(names, ", ")),
                r = 0.95,
                g = 0.35,
                b = 0.35,
                wrap = true,
            }
        end
        return tooltip
    end)
    entry:Show()
end

function Page:BuildResolvedShopRows(requisitions)
    local rows = BaseBuildResolvedShopRows(self, requisitions)
    for index = 1, #rows do
        local row = rows[index]
        if requisitionSourceType(row.requisition) == "loot_table" then
            local display = resolveLootDisplay(row.requisition)
            row.name = display.name
            row.searchName = string.lower(display.name)
        end
    end
    return rows
end

function Page:HideShopEntry(entry)
    if entry then entry.resolvedLootDisplay = nil end
    return BaseHideShopEntry(self, entry)
end

local function dailyRewardDisplay(reward)
    local rewardType = string.lower(trim(reward and reward.type))
    local reference = trim(reward and reward.ref)
    local amount = positiveInteger(reward and reward.amount, 1)
    if isLootDailyReward(reward) then
        local display = resolveLootDisplay({ lootRef = reference })
        return display.name, display.icon, ("x%d roll%s"):format(amount, amount == 1 and "" or "s")
    end
    if rewardType == "currency" then
        local currencyKey = type(Profile.NormalizeCurrencyKey) == "function" and trim(Profile.NormalizeCurrencyKey(reference)) or reference
        local name, icon = reference, nil
        if type(Profile.ResolveCurrencyDefinition) == "function" then
            local ok, definition = pcall(Profile.ResolveCurrencyDefinition, currencyKey)
            if ok and type(definition) == "table" and definition.isMissing ~= true then
                name = trim(definition.name) ~= "" and trim(definition.name) or reference
                icon = definition.icon
            end
        end
        local right = currencyKey == "copper" and Common:FormatCopper(amount) or ("x%d"):format(amount)
        return name, icon, right
    end
    local name, icon = reference, nil
    if type(Registry.ResolveItemReference) == "function" then
        local ok, _, item = pcall(Registry.ResolveItemReference, Registry, reference)
        if ok and type(item) == "table" then
            name = trim(item.name) ~= "" and trim(item.name) or reference
            icon = item.icon
        end
    end
    return name, icon, ("x%d"):format(amount)
end

function Page:BuildDailyRewardTooltip()
    local rewards = self.DailyRewardStatus and self.DailyRewardStatus.rewards or nil
    local hasLoot = false
    for index = 1, #(rewards or {}) do
        if isLootDailyReward(rewards[index]) then hasLoot = true break end
    end
    if not hasLoot then return BaseBuildDailyRewardTooltip(self) end

    local spec = { type = "custom", title = "Daily Rewards", lines = {} }
    for index = 1, #(rewards or {}) do
        local name, icon, right = dailyRewardDisplay(rewards[index])
        local line = { left = name, right = right, colorToken = "text.secondary", rightColorToken = "text.primary" }
        if type(icon) == "number" then line.left = ("|T%d:16:16|t %s"):format(icon, name)
        elseif trim(icon) ~= "" then line.icon = icon end
        spec.lines[#spec.lines + 1] = line
    end
    return spec
end

return Page
