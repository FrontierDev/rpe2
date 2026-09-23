local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Guild = Addon.Client.Guild or {}

local Client = Addon.Client
local Guild = Addon.Client.Guild
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Common = Addon.Utils and Addon.Utils.Common or {}

local GUILD_ADMIN_PROTOCOL_VERSION = "2"
local GUILD_ADMIN_REQUEST_TIMEOUT = 8
local GUILD_ADMIN_QUERY_OPCODE = Operations.GetOpcode and Operations:GetOpcode("GUILD_ADMIN_QUERY") or nil
local GUILD_ADMIN_QUERY_RESPONSE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("GUILD_ADMIN_QUERY_RESPONSE") or nil
local GUILD_ADMIN_MUTATION_OPCODE = Operations.GetOpcode and Operations:GetOpcode("GUILD_ADMIN_MUTATION") or nil
local GUILD_ADMIN_MUTATION_RESPONSE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("GUILD_ADMIN_MUTATION_RESPONSE") or nil
local DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE = "reset-cycle"

Guild._guildAdminPending = Guild._guildAdminPending or {}
Guild._guildAdminRequestSequence = tonumber(Guild._guildAdminRequestSequence) or 0

local function ensureString(value)
    return value == nil and "" or tostring(value)
end

local function trimText(value)
    local text = ensureString(value)
    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    return trimmed
end

local function normalizeInteger(value, minimum, maximum)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return nil
    end
    local integer = math.floor(numeric)
    if integer ~= numeric then
        return nil
    end
    if minimum ~= nil and integer < minimum then
        return nil
    end
    if maximum ~= nil and integer > maximum then
        return nil
    end
    return integer
end

local function normalizeCharacterLimit(value)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return 1
    end
    if numeric == 0 then
        return 0
    end
    return math.max(1, math.floor(numeric))
end

local function normalizePlayerName(value)
    local name = trimText(value)
    if name == "" then
        return ""
    end
    if type(Common.NormalizeName) == "function" then
        return trimText(Common.NormalizeName(name))
    end
    return name
end

local function getLocalPlayerName()
    if type(Common.GetPlayerName) == "function" then
        return normalizePlayerName(Common.GetPlayerName())
    end
    if type(GetUnitName) == "function" then
        return normalizePlayerName(GetUnitName("player", true) or GetUnitName("player"))
    end
    if type(UnitName) == "function" then
        return normalizePlayerName(UnitName("player"))
    end
    return ""
end

local function callGlobal(name, ...)
    local handler = _G and _G[name] or nil
    if type(handler) ~= "function" then
        return false
    end
    local ok, result = pcall(handler, ...)
    return ok and result or false
end

local function getGuildIdentity()
    local inGuild = type(IsInGuild) == "function" and IsInGuild() == true or false
    local guildName, guildRankName, realmName, legacyRealmName, guildClubId = "", "", "", "", ""
    local guildRankIndex = nil

    local club = _G and _G.C_Club or nil
    if club and type(club.GetGuildClubId) == "function" then
        local ok, value = pcall(club.GetGuildClubId)
        if ok then guildClubId = trimText(value) end
    end

    if type(GetGuildInfo) == "function" then
        local ok, name, rankName, rankIndex, guildRealmName = pcall(GetGuildInfo, "player")
        if ok then
            guildName = ensureString(name)
            guildRankName = ensureString(rankName)
            guildRankIndex = tonumber(rankIndex)
            realmName = trimText(guildRealmName)
        end
    end

    if type(GetRealmName) == "function" then
        local ok, currentRealm = pcall(GetRealmName)
        if ok then legacyRealmName = trimText(currentRealm) end
    end

    return {
        inGuild = inGuild,
        guildName = guildName,
        guildRankName = guildRankName,
        guildRankIndex = guildRankIndex,
        realmName = realmName,
        legacyRealmName = legacyRealmName,
        guildClubId = guildClubId,
    }
end

local function getGuildKey(identity)
    if type(Profile.GetGuildKey) ~= "function" then
        return ""
    end
    return trimText(Profile.GetGuildKey(identity))
end

local function getDatasetLabel(dataset)
    local name = trimText(dataset and dataset.name)
    return name ~= "" and name or trimText(dataset and dataset.id)
end

local function getSettingLabel(setting)
    local name = trimText(setting and setting.name)
    return name ~= "" and name or trimText(setting and setting.id)
end

local function buildSettingMatch(dataset, setting, matchType)
    local datasetId = trimText(dataset and dataset.id)
    local settingId = trimText(setting and setting.id)
    return {
        dataset = dataset,
        setting = setting,
        datasetId = datasetId,
        settingId = settingId,
        ref = datasetId ~= "" and settingId ~= "" and (datasetId .. ":" .. settingId) or "",
        datasetName = getDatasetLabel(dataset),
        settingName = getSettingLabel(setting),
        guildName = trimText(setting and setting.guildName),
        matchType = matchType,
    }
end

local function findRole(setting, roleId)
    local wanted = trimText(roleId)
    if wanted == "" then return nil end
    local roles = type(setting and setting.roles) == "table" and setting.roles or {}
    for index = 1, #roles do
        local role = roles[index]
        if trimText(role and role.id) == wanted then
            return role, index
        end
    end
    return nil
end

local function roleMapsWowRank(role, rankIndex)
    local target = normalizeInteger(rankIndex, 0)
    if target == nil then return false end
    local mapped = type(role and role.wowGuildRankIndices) == "table" and role.wowGuildRankIndices or {}
    for index = 1, #mapped do
        if normalizeInteger(mapped[index], 0) == target then
            return true
        end
    end
    return false
end

local function getInventoryService()
    return Client.Inventory or {}
end

local function parseItemReference(itemRef)
    local datasetId, itemId = trimText(itemRef):match("^([^:]+):(.+)$")
    if not datasetId or trimText(datasetId) == "" or not itemId or trimText(itemId) == "" then
        return nil, nil
    end
    return trimText(datasetId), trimText(itemId)
end

local function findRequisition(setting, requisitionId)
    local wanted = trimText(requisitionId)
    local rows = type(setting and setting.requisitions) == "table" and setting.requisitions or {}
    for index = 1, #rows do
        local row = rows[index]
        if trimText(row and row.id) == wanted then return row end
    end
    return nil
end

local function getInventoryItemQuantity(inventory, datasetId, itemId)
    if type(inventory.GetItems) ~= "function" then return nil end
    local ok, items = pcall(inventory.GetItems)
    if not ok or type(items) ~= "table" then return nil end
    local quantity = 0
    for index = 1, #items do
        local item = items[index]
        if tostring(item and item.dataset or "") == datasetId and tostring(item and item.id or "") == itemId then
            quantity = quantity + math.max(0, math.floor(tonumber(item.quantity or item.count) or 0))
        end
    end
    return quantity
end

local function removeInventoryItemQuantity(inventory, datasetId, itemId, quantity)
    local remaining = math.max(0, math.floor(tonumber(quantity) or 0))
    if remaining == 0 then return true end
    if type(inventory.GetItems) ~= "function" or type(inventory.RemoveItem) ~= "function" then return false end
    local ok, items = pcall(inventory.GetItems)
    if not ok or type(items) ~= "table" then return false end
    for index = #items, 1, -1 do
        local item = items[index]
        if tostring(item and item.dataset or "") == datasetId and tostring(item and item.id or "") == itemId then
            local itemQuantity = math.max(1, math.floor(tonumber(item.quantity or item.count) or 1))
            local removeQuantity = math.min(itemQuantity, remaining)
            local removed, result = pcall(inventory.RemoveItem, index, removeQuantity)
            if not removed or not result then return false end
            remaining = remaining - removeQuantity
            if remaining <= 0 then return true end
        end
    end
    return false
end

local function restoreCurrencySnapshots(snapshots)
    if type(Profile.SetCurrencyAmount) ~= "function" or type(Profile.GetCurrencyAmount) ~= "function" then return false end
    local restored = true
    for index = #snapshots, 1, -1 do
        local snapshot = snapshots[index]
        local ok, result = pcall(Profile.SetCurrencyAmount, snapshot.currencyRef, snapshot.amount)
        local got, actual = pcall(Profile.GetCurrencyAmount, snapshot.currencyRef)
        actual = got and (tonumber(actual) or 0) or nil
        if not ok or result == nil or not got or actual ~= snapshot.amount then restored = false end
    end
    return restored
end

local function getCurrencyCosts(costs)
    if type(Profile.NormalizeCurrencyKey) ~= "function" or type(Profile.ResolveCurrencyDefinition) ~= "function" then
        return nil, "currency-api-unavailable"
    end
    local normalized, byCurrency = {}, {}
    local rows = type(costs) == "table" and costs or {}
    for index = 1, #rows do
        local row = rows[index]
        local currencyRef = Profile.NormalizeCurrencyKey(row and row.currencyRef)
        if currencyRef == "" then return nil, "currency-unavailable", { costIndex = index } end
        local ok, definition = pcall(Profile.ResolveCurrencyDefinition, currencyRef)
        if not ok or type(definition) ~= "table" or definition.isMissing == true then
            return nil, "currency-unavailable", { currencyRef = currencyRef, costIndex = index }
        end
        local amount = tonumber(row and row.amount)
        if not amount or amount ~= amount or amount == math.huge or amount == -math.huge or amount < 0 then
            return nil, "invalid-currency-cost", { currencyRef = currencyRef, costIndex = index }
        end
        amount = math.floor(amount)
        local entry = byCurrency[currencyRef]
        if not entry then
            entry = { currencyRef = currencyRef, amount = 0, definition = definition }
            byCurrency[currencyRef] = entry
            normalized[#normalized + 1] = entry
        end
        entry.amount = entry.amount + amount
    end
    return normalized
end

function Guild:GetLocalGuildIdentity()
    return getGuildIdentity()
end

function Guild:GetCurrentGuildName()
    return getGuildIdentity().guildName
end

function Guild:ResolveActiveGuildSetting()
    local identity = getGuildIdentity()
    local result = {
        status = nil,
        reason = nil,
        identity = identity,
        inGuild = identity.inGuild,
        guildName = identity.guildName,
        guildRankName = identity.guildRankName,
        guildRankIndex = identity.guildRankIndex,
        guildKey = getGuildKey(identity),
        setting = nil,
        dataset = nil,
        datasetId = nil,
        settingId = nil,
        ref = nil,
        match = nil,
        matches = {},
        conflict = false,
    }

    if not identity.inGuild then
        result.status, result.reason = "not-in-guild", "not-in-guild"
        return result
    end
    local guildName = trimText(identity.guildName)
    if guildName == "" then
        result.status, result.reason = "guild-loading", "guild-loading"
        return result
    end

    local exact, generic = {}, {}
    local datasets = type(Registry.GetActivatedDatasets) == "function" and Registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local settings = type(dataset and dataset.guildSettings) == "table" and dataset.guildSettings or {}
        for settingIndex = 1, #settings do
            local setting = settings[settingIndex]
            local configured = trimText(setting and setting.guildName)
            if configured == guildName then
                exact[#exact + 1] = buildSettingMatch(dataset, setting, "exact")
            elseif configured == "" then
                generic[#generic + 1] = buildSettingMatch(dataset, setting, "generic")
            end
        end
    end

    local candidates = #exact > 0 and exact or generic
    result.matches = candidates
    result.matchType = #exact > 0 and "exact" or (#generic > 0 and "generic" or nil)
    if #candidates == 0 then
        result.status, result.reason = "unavailable", "no-setting"
        return result
    end
    if #candidates > 1 then
        result.status, result.reason, result.conflict = "conflict", "conflict", true
        return result
    end

    local match = candidates[1]
    result.status, result.reason = "active", "active"
    result.setting, result.dataset = match.setting, match.dataset
    result.datasetId, result.settingId, result.ref = match.datasetId, match.settingId, match.ref
    result.match = match
    return result
end

function Guild:GetActiveGuildSetting()
    local result = self:ResolveActiveGuildSetting()
    return result.status == "active" and result.setting or nil, result
end

function Guild:GetEffectiveRoles()
    local setting, resolution = self:GetActiveGuildSetting()
    local result = {
        status = resolution and resolution.status or "unavailable",
        reason = resolution and resolution.reason or "unavailable",
        resolution = resolution,
        setting = setting,
        settingRef = resolution and resolution.ref or nil,
        guildKey = resolution and resolution.guildKey or "",
        roles = {},
        byId = {},
        manualRoleIds = {},
        mappedRoleIds = {},
    }
    if not setting or result.status ~= "active" then return result.roles, result end

    local manual = {}
    if type(Profile.GetAssignedGuildRoles) == "function" and result.guildKey ~= "" then
        local ok, assignments = pcall(Profile.GetAssignedGuildRoles, result.guildKey)
        if ok and type(assignments) == "table" then
            for _, assignment in pairs(assignments) do
                if type(assignment) == "table" and trimText(assignment.guildSettingRef) == result.settingRef then
                    local roleId = trimText(assignment.roleId)
                    if findRole(setting, roleId) then manual[roleId] = true end
                end
            end
        end
    end

    local roles = type(setting.roles) == "table" and setting.roles or {}
    for index = 1, #roles do
        local role = roles[index]
        local roleId = trimText(role and role.id)
        if roleId ~= "" then
            local isManual = manual[roleId] == true
            local isMapped = roleMapsWowRank(role, resolution.identity and resolution.identity.guildRankIndex)
            if isManual or isMapped then
                local entry = {
                    role = role,
                    roleId = roleId,
                    name = trimText(role.name) ~= "" and trimText(role.name) or roleId,
                    manual = isManual,
                    mapped = isMapped,
                    source = isManual and isMapped and "manual+mapped" or (isManual and "manual" or "mapped-from-wow-rank"),
                }
                result.roles[#result.roles + 1] = entry
                result.byId[roleId] = entry
                if isManual then result.manualRoleIds[#result.manualRoleIds + 1] = roleId end
                if isMapped then result.mappedRoleIds[#result.mappedRoleIds + 1] = roleId end
            end
        end
    end
    return result.roles, result
end

function Guild:HasEffectiveRole(roleId)
    local _, result = self:GetEffectiveRoles()
    local entry = result.byId[trimText(roleId)]
    return entry ~= nil, entry, result
end

local function buildRequisitionFailure(reason, detail)
    return false, reason, detail
end

local function validateRequisitionRoles(self, setting, requisition)
    local required = type(requisition and requisition.roleIds) == "table" and requisition.roleIds or {}
    if #required == 0 then return true, nil, { requiredRoleIds = {}, effectiveRoleIds = {} } end
    local _, effective = self:GetEffectiveRoles()
    if effective.status ~= "active" then return false, effective.reason or "setting-unavailable", effective end
    local effectiveIds = {}
    for index = 1, #effective.roles do effectiveIds[#effectiveIds + 1] = effective.roles[index].roleId end
    for index = 1, #required do
        local roleId = trimText(required[index])
        if roleId ~= "" and findRole(setting, roleId) and effective.byId[roleId] then
            return true, nil, { requiredRoleIds = required, effectiveRoleIds = effectiveIds }
        end
    end
    return false, "missing-required-role", { requiredRoleIds = required, effectiveRoleIds = effectiveIds }
end

function Guild:GetRequisitionEligibility(guildSettingRef, requisitionId)
    local setting, resolution = self:GetActiveGuildSetting()
    if not setting then return buildRequisitionFailure(resolution.reason or "setting-unavailable", resolution) end
    local requestedRef = trimText(guildSettingRef)
    if requestedRef ~= "" and requestedRef ~= resolution.ref then
        return buildRequisitionFailure("setting-mismatch", { activeSettingRef = resolution.ref, requestedSettingRef = requestedRef })
    end
    if resolution.guildKey == "" then return buildRequisitionFailure("guild-loading") end
    local general = type(setting.general) == "table" and setting.general or {}
    if general.enableRequisitions ~= true then return buildRequisitionFailure("requisitions-disabled", resolution) end

    local normalizedId = trimText(requisitionId)
    local requisition = findRequisition(setting, normalizedId)
    if not requisition then return buildRequisitionFailure("requisition-unavailable") end

    local roleOk, roleReason, roleDetail = validateRequisitionRoles(self, setting, requisition)
    if not roleOk then return buildRequisitionFailure(roleReason, roleDetail) end

    local itemRef = trimText(requisition.itemRef)
    local itemDataset, item
    if type(Registry.ResolveItemReference) == "function" then
        local ok
        ok, itemDataset, item = pcall(Registry.ResolveItemReference, Registry, itemRef)
        if not ok then itemDataset, item = nil, nil end
    end
    local datasetId, itemId = parseItemReference(itemRef)
    if type(itemDataset) ~= "table" or type(item) ~= "table" or not datasetId or not itemId then
        return buildRequisitionFailure("item-unavailable", { itemRef = itemRef })
    end

    local characterLimit = normalizeCharacterLimit(requisition.characterLimit)
    local usage = 0
    if characterLimit > 0 then
        if type(Profile.GetGuildRequisitionUsage) ~= "function" then return buildRequisitionFailure("ledger-unavailable") end
        usage = math.max(0, math.floor(tonumber(Profile.GetGuildRequisitionUsage(resolution.guildKey, resolution.ref, normalizedId)) or 0))
        if usage >= characterLimit then
            return buildRequisitionFailure("character-limit-reached", { usage = usage, characterLimit = characterLimit, requisitionId = normalizedId })
        end
    end

    local costs, costReason, costDetail = getCurrencyCosts(requisition.costs)
    if not costs then return buildRequisitionFailure(costReason, costDetail) end
    if type(Profile.GetCurrencyAmount) ~= "function" then return buildRequisitionFailure("currency-api-unavailable") end
    for index = 1, #costs do
        local cost = costs[index]
        local balance = tonumber(Profile.GetCurrencyAmount(cost.currencyRef)) or 0
        if balance < cost.amount then
            return buildRequisitionFailure("insufficient-currency", { currencyRef = cost.currencyRef, balance = balance, amount = cost.amount })
        end
    end
    if type(getInventoryService().AddItem) ~= "function" then return buildRequisitionFailure("inventory-unavailable") end

    return true, nil, {
        identity = resolution.identity,
        guildKey = resolution.guildKey,
        setting = setting,
        settingRef = resolution.ref,
        requisition = requisition,
        requisitionId = normalizedId,
        itemRef = itemRef,
        itemDataset = itemDataset,
        item = item,
        datasetId = datasetId,
        itemId = itemId,
        quantity = math.max(1, math.floor(tonumber(requisition.quantity) or 1)),
        costs = costs,
        usage = usage,
        characterLimit = characterLimit,
        isUnlimited = characterLimit == 0,
        roleDetail = roleDetail,
    }
end

function Guild:TryRequisition(guildSettingRef, requisitionId)
    local eligible, reason, detail = self:GetRequisitionEligibility(guildSettingRef, requisitionId)
    if not eligible then return false, reason, detail end

    local snapshots = {}
    for index = 1, #detail.costs do
        local cost = detail.costs[index]
        snapshots[index] = { currencyRef = cost.currencyRef, amount = tonumber(Profile.GetCurrencyAmount(cost.currencyRef)) or 0 }
    end
    local function rollbackCurrencies() return restoreCurrencySnapshots(snapshots) end
    if type(Profile.SpendCurrencyAmount) ~= "function" then return false, "currency-api-unavailable", detail end

    for index = 1, #detail.costs do
        local cost, before = detail.costs[index], snapshots[index].amount
        local expected = before - cost.amount
        local ok, spent, updated = pcall(Profile.SpendCurrencyAmount, cost.currencyRef, cost.amount)
        local got, after = pcall(Profile.GetCurrencyAmount, cost.currencyRef)
        after = got and (tonumber(after) or 0) or nil
        if not ok or spent ~= true or updated ~= expected or after ~= expected then
            local restored = rollbackCurrencies()
            return false, restored and "currency-transaction-failed" or "rollback-failed", detail
        end
    end

    local inventory = getInventoryService()
    local beforeQty = getInventoryItemQuantity(inventory, detail.datasetId, detail.itemId)
    local added, record = pcall(inventory.AddItem, { dataset = detail.datasetId, id = detail.itemId, quantity = detail.quantity })
    local afterQty = getInventoryItemQuantity(inventory, detail.datasetId, detail.itemId)
    local awarded = detail.quantity
    local measured = beforeQty ~= nil and afterQty ~= nil
    if measured then awarded = math.max(0, afterQty - beforeQty) end
    if not added or not record or (measured and awarded < detail.quantity) then
        local itemRestored = not measured or awarded <= 0 or removeInventoryItemQuantity(inventory, detail.datasetId, detail.itemId, awarded)
        local currenciesRestored = rollbackCurrencies()
        return false, (itemRestored and currenciesRestored) and "inventory-award-failed" or "rollback-failed", detail
    end

    local updatedUsage = detail.usage
    if detail.characterLimit > 0 then
        local expectedUsage = detail.usage + 1
        if type(Profile.IncrementGuildRequisitionUsage) == "function" then
            local ok, value = pcall(Profile.IncrementGuildRequisitionUsage, detail.guildKey, detail.settingRef, detail.requisitionId)
            updatedUsage = ok and value or nil
        else
            updatedUsage = nil
        end
        if updatedUsage ~= expectedUsage then
            local itemRestored = removeInventoryItemQuantity(inventory, detail.datasetId, detail.itemId, awarded)
            local ledgerRestored = false
            if itemRestored and type(Profile.SetGuildRequisitionUsage) == "function" then
                local ok, value = pcall(Profile.SetGuildRequisitionUsage, detail.guildKey, detail.settingRef, detail.requisitionId, detail.usage)
                ledgerRestored = ok and value == detail.usage
            end
            local currenciesRestored = rollbackCurrencies()
            return false, (itemRestored and ledgerRestored and currenciesRestored) and "ledger-update-failed" or "rollback-failed", detail
        end
    end

    pcall(self.RefreshWindow, self)
    return true, "ok", {
        guildSettingRef = detail.settingRef,
        requisitionId = detail.requisitionId,
        itemRef = detail.itemRef,
        quantity = detail.quantity,
        usage = updatedUsage,
        characterLimit = detail.characterLimit,
    }
end

local function buildDailyRewardPlan(setting, rewardList)
    local rewards = type(rewardList) == "table" and rewardList or type(setting and setting.dailyRewards) == "table" and setting.dailyRewards or {}
    local plan, needsItem, needsCurrency = {}, false, false
    for index = 1, #rewards do
        local reward = rewards[index]
        local rewardId = trimText(reward and reward.id)
        local rewardType = string.lower(trimText(reward and reward.type))
        local rewardRef = trimText(reward and reward.ref)
        local amount = normalizeInteger(reward and reward.amount, 1)
        if rewardId == "" or (rewardType ~= "item" and rewardType ~= "currency") or rewardRef == "" or not amount then
            return nil, "invalid-reward-definition", { rewardIndex = index, rewardId = rewardId }
        end
        if rewardType == "item" then
            if type(Registry.ResolveItemReference) ~= "function" then return nil, "item-api-unavailable" end
            local ok, dataset, item = pcall(Registry.ResolveItemReference, Registry, rewardRef)
            local datasetId, itemId = parseItemReference(rewardRef)
            if not ok or type(dataset) ~= "table" or type(item) ~= "table" or not datasetId or not itemId then
                return nil, "item-unavailable", { rewardIndex = index, rewardId = rewardId, ref = rewardRef }
            end
            plan[#plan + 1] = { id = rewardId, type = "item", ref = rewardRef, amount = amount, datasetId = datasetId, itemId = itemId }
            needsItem = true
        else
            if type(Profile.NormalizeCurrencyKey) ~= "function" or type(Profile.ResolveCurrencyDefinition) ~= "function" then return nil, "currency-api-unavailable" end
            local currencyRef = Profile.NormalizeCurrencyKey(rewardRef)
            local ok, definition = pcall(Profile.ResolveCurrencyDefinition, currencyRef)
            if currencyRef == "" or not ok or type(definition) ~= "table" or definition.isMissing == true then
                return nil, "currency-unavailable", { rewardIndex = index, rewardId = rewardId, ref = rewardRef }
            end
            plan[#plan + 1] = { id = rewardId, type = "currency", ref = rewardRef, currencyRef = currencyRef, amount = amount, definition = definition }
            needsCurrency = true
        end
    end
    return plan, nil, { needsItemAward = needsItem, needsCurrencyAward = needsCurrency }
end

function Guild:GetDailyRewardResetState()
    if type(Common.GetNow) ~= "function" or type(date) ~= "function" then return nil, "calendar-unavailable" end
    local api = _G and _G.C_DateAndTime or nil
    if not api or type(api.GetSecondsUntilDailyReset) ~= "function" then return nil, "calendar-unavailable" end
    local okNow, now = pcall(Common.GetNow)
    local okReset, remaining = pcall(api.GetSecondsUntilDailyReset)
    now, remaining = tonumber(now), tonumber(remaining)
    if not okNow or not now or not okReset or not remaining or remaining < 0 then return nil, "calendar-unavailable" end
    remaining = math.floor(remaining)
    local nextReset = now + remaining
    local okCycle, cycleKey = pcall(date, "%Y-%m-%d", nextReset)
    local okCurrent, currentDayKey = pcall(date, "%Y-%m-%d", now)
    local okPrevious, previousCycleKey = pcall(date, "%Y-%m-%d", nextReset - 86400)
    if not okCycle or not okCurrent or not okPrevious then return nil, "calendar-unavailable" end
    if not tostring(cycleKey):match("^%d%d%d%d%-%d%d%-%d%d$") then return nil, "calendar-unavailable" end
    return { secondsRemaining = remaining, cycleKey = cycleKey, currentDayKey = currentDayKey, previousCycleKey = previousCycleKey }
end

local function legacyClaimBelongsToCurrentCycle(claimDate, resetState)
    if claimDate == resetState.currentDayKey then return true end
    return resetState.cycleKey == resetState.currentDayKey and claimDate == resetState.previousCycleKey
end

function Guild:GetDailyRewardStatus()
    local setting, resolution = self:GetActiveGuildSetting()
    local result = {
        status = resolution and resolution.status or "unavailable",
        reason = resolution and resolution.reason or "unavailable",
        setting = setting,
        settingRef = resolution and resolution.ref or nil,
        guildKey = resolution and resolution.guildKey or "",
        identity = resolution and resolution.identity or getGuildIdentity(),
        rewards = {},
    }
    if not setting then return result end
    local general = type(setting.general) == "table" and setting.general or {}
    if general.enableDailyRewards ~= true then result.status, result.reason = "daily-rewards-disabled", "daily-rewards-disabled" return result end
    local resetState, resetReason = self:GetDailyRewardResetState()
    if not resetState then result.status, result.reason = resetReason, resetReason return result end
    result.resetState, result.dayKey = resetState, resetState.cycleKey
    if type(Profile.GetDailyRewardClaim) ~= "function" then result.status, result.reason = "profile-api-unavailable", "profile-api-unavailable" return result end
    local _, effective = self:GetEffectiveRoles()
    if type(effective) ~= "table" or effective.status ~= "active" then result.status, result.reason = "setting-unavailable", "setting-unavailable" return result end
    local eligible, available = {}, {}
    for index = 1, #(setting.dailyRewards or {}) do
        local reward = setting.dailyRewards[index]
        local matches = false
        for roleIndex = 1, #(reward and reward.roleIds or {}) do
            if effective.byId and effective.byId[trimText(reward.roleIds[roleIndex])] then matches = true break end
        end
        if matches then
            eligible[#eligible + 1] = reward
            local okClaim, claimDate = pcall(Profile.GetDailyRewardClaim, result.guildKey, result.settingRef, reward.id)
            if not okClaim then result.status, result.reason = "profile-api-unavailable", "profile-api-unavailable" return result end
            if claimDate ~= result.dayKey then available[#available + 1] = reward end
        end
    end
    result.rewards, result.eligibleRewards, result.availableRewards = eligible, eligible, available
    if #available == 0 then result.status, result.reason = "received-today", "received-today" return result end
    if type(Profile.GetDailyRewardTransaction) ~= "function" then result.status, result.reason = "profile-api-unavailable", "profile-api-unavailable" return result end
    local okTx, tx = pcall(Profile.GetDailyRewardTransaction, result.guildKey)
    if not okTx then result.status, result.reason = "profile-api-unavailable", "profile-api-unavailable" return result end
    if type(tx) == "table" then result.status, result.reason, result.transaction = "transaction-recovery-required", "transaction-recovery-required", tx return result end
    local plan, planReason, flags = buildDailyRewardPlan(setting, available)
    if not plan then result.status, result.reason, result.detail = planReason, planReason, flags return result end
    local inventory = getInventoryService()
    if flags.needsItemAward and type(inventory.AddItem) ~= "function" then result.status, result.reason = "inventory-api-unavailable", "inventory-api-unavailable" return result end
    if flags.needsCurrencyAward and (type(Profile.GetCurrencyAmount) ~= "function" or type(Profile.AddCurrencyAmount) ~= "function" or type(Profile.SetCurrencyAmount) ~= "function") then
        result.status, result.reason = "currency-api-unavailable", "currency-api-unavailable" return result
    end
    result.status, result.reason, result.plan = "available-today", "available-today", plan
    return result
end

local function createDailyRewardTransaction()
    local tx = { itemAwards = {}, currencySnapshots = {} }
    function tx:Rollback()
        local restored, inventory = true, getInventoryService()
        for index = #self.itemAwards, 1, -1 do
            local award = self.itemAwards[index]
            if not removeInventoryItemQuantity(inventory, award.datasetId, award.itemId, award.amount) then restored = false end
        end
        if not restoreCurrencySnapshots(self.currencySnapshots) then restored = false end
        return restored
    end
    return tx
end

local function awardDailyRewardPlan(plan)
    local tx, inventory, snapshots = createDailyRewardTransaction(), getInventoryService(), {}
    for index = 1, #plan do
        local reward = plan[index]
        if reward.type == "currency" and not snapshots[reward.currencyRef] then
            local ok, amount = pcall(Profile.GetCurrencyAmount, reward.currencyRef)
            if not ok then return false, tx:Rollback() and "currency-read-failed" or "rollback-failed", tx end
            local snapshot = { currencyRef = reward.currencyRef, amount = tonumber(amount) or 0 }
            snapshots[reward.currencyRef] = snapshot
            tx.currencySnapshots[#tx.currencySnapshots + 1] = snapshot
        end
    end
    for index = 1, #plan do
        local reward = plan[index]
        if reward.type == "item" then
            local before = getInventoryItemQuantity(inventory, reward.datasetId, reward.itemId)
            local ok, record = pcall(inventory.AddItem, { dataset = reward.datasetId, id = reward.itemId, quantity = reward.amount })
            local after = getInventoryItemQuantity(inventory, reward.datasetId, reward.itemId)
            local awarded = before ~= nil and after ~= nil and math.max(0, after - before) or reward.amount
            if awarded > 0 and (before ~= nil and after ~= nil or ok and record) then
                tx.itemAwards[#tx.itemAwards + 1] = { datasetId = reward.datasetId, itemId = reward.itemId, amount = awarded }
            end
            if not ok or not record or awarded < reward.amount then return false, tx:Rollback() and "item-award-failed" or "rollback-failed", tx end
        else
            local snapshot = snapshots[reward.currencyRef]
            local ok, added = pcall(Profile.AddCurrencyAmount, reward.currencyRef, reward.amount)
            local got, after = pcall(Profile.GetCurrencyAmount, reward.currencyRef)
            after = got and tonumber(after) or nil
            if not ok or added == nil or not got or not after or after < snapshot.amount then return false, tx:Rollback() and "currency-award-failed" or "rollback-failed", tx end
        end
    end
    return true, "ok", tx
end

local function persistDailyRewardTransactionState(context, state, reason)
    if type(Profile.SetDailyRewardTransaction) ~= "function" then return false end
    local ok, persisted = pcall(Profile.SetDailyRewardTransaction, context.guildKey, context.dayKey, context.settingRef, state, reason)
    return ok and type(persisted) == "table" and persisted.status == state and persisted.date == context.dayKey and trimText(persisted.settingRef or persisted.rankRef) == context.settingRef
end

local function clearDailyRewardTransactionState(guildKey)
    if type(Profile.ClearDailyRewardTransaction) ~= "function" then return false end
    local ok, cleared = pcall(Profile.ClearDailyRewardTransaction, guildKey)
    return ok and cleared == true
end

function Guild:ProcessDailyRewards()
    if self._dailyRewardProcessing == true then return false, "processing" end
    self._dailyRewardProcessing = true
    local context = nil
    local callOk, success, reason, result = xpcall(function()
        local status = self:GetDailyRewardStatus()
        if status.status ~= "available-today" then return false, status.status, status end
        context = { guildKey = status.guildKey, dayKey = status.dayKey, settingRef = status.settingRef }
        if not persistDailyRewardTransactionState(context, "in-progress", "award-started") then return false, "transaction-state-persistence-failed", status end
        local awarded, awardReason, transaction = awardDailyRewardPlan(status.plan or {})
        if not awarded then
            if not persistDailyRewardTransactionState(context, "failed", awardReason) then return false, "transaction-state-persistence-failed", status end
            return false, awardReason, status
        end
        if type(Profile.SetDailyRewardClaim) ~= "function" then
            pcall(transaction.Rollback, transaction)
            persistDailyRewardTransactionState(context, "failed", "claim-persistence-unavailable")
            return false, "claim-persistence-unavailable", status
        end
        for index = 1, #(status.plan or {}) do
            local reward = status.plan[index]
            local okSet, bucket = pcall(Profile.SetDailyRewardClaim, status.guildKey, status.dayKey, status.settingRef, DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE, reward.id)
            local okGet, storedDate = pcall(Profile.GetDailyRewardClaim, status.guildKey, status.settingRef, reward.id)
            if not okSet or type(bucket) ~= "table" or not okGet or storedDate ~= status.dayKey then
                pcall(transaction.Rollback, transaction)
                persistDailyRewardTransactionState(context, "failed", "claim-persistence-failed")
                return false, "claim-persistence-failed", status
            end
        end
        clearDailyRewardTransactionState(status.guildKey)
        pcall(self.RefreshWindow, self)
        return true, "claimed", { dayKey = status.dayKey, guildSettingRef = status.settingRef, rewardCount = #(status.plan or {}) }
    end, function(message) return tostring(message) end)
    self._dailyRewardProcessing = false
    if not callOk then
        if context then persistDailyRewardTransactionState(context, "failed", "processing-failed") end
        return false, "processing-failed", { error = reason }
    end
    return success, reason, result
end

function Guild:TryClaimDailyReward()
    return self:ProcessDailyRewards()
end

local function hasOfficerPermission()
    local identity = getGuildIdentity()
    if not identity.inGuild then return false end
    local info = _G and _G.C_GuildInfo or nil
    if info and type(info.IsGuildOfficer) == "function" then
        local ok, value = pcall(info.IsGuildOfficer)
        if ok then return value == true end
    end
    if type(IsGuildLeader) == "function" then
        local ok, value = pcall(IsGuildLeader)
        if ok and value == true then return true end
    end
    for _, name in ipairs({ "CanGuildRemove", "CanGuildPromote", "CanGuildDemote", "CanEditGuildInfo", "CanEditOfficerNote" }) do
        if callGlobal(name) == true then return true end
    end
    return false
end

local function hasGuildOfficerCapability(member)
    local rankIndex = normalizeInteger(member and member.rankIndex, 0)
    if rankIndex == nil then return false end
    local info = _G and _G.C_GuildInfo or nil
    local getter = info and info.GuildControlGetRankFlags or nil
    if type(getter) ~= "function" then return false end
    local ok, flags = pcall(getter, rankIndex + 1)
    return ok and type(flags) == "table" and (flags[5] == true or flags[6] == true or flags[8] == true or flags[12] == true or flags[13] == true) or false
end

function Guild:IsLocalPlayerOfficer()
    return hasOfficerPermission()
end

function Guild:RequestRosterUpdate()
    local now = type(GetTime) == "function" and GetTime() or 0
    if self._lastRosterRequest and now - self._lastRosterRequest < 2 then return false end
    local info = _G and _G.C_GuildInfo or nil
    local request = info and info.GuildRoster or _G and _G.GuildRoster or nil
    if type(request) ~= "function" then return false end
    local ok = pcall(request)
    if ok then self._lastRosterRequest = now end
    return ok
end

function Guild:GetRoster()
    if not getGuildIdentity().inGuild then return {} end
    self:RequestRosterUpdate()
    local count = type(GetNumGuildMembers) == "function" and (GetNumGuildMembers() or 0) or 0
    local roster = {}
    for index = 1, count do
        if type(GetGuildRosterInfo) == "function" then
            local ok, name, rankName, rankIndex, level, className, zone, note, _, online = pcall(GetGuildRosterInfo, index)
            if ok and name then
                roster[#roster + 1] = { name = ensureString(name), rankName = ensureString(rankName), rankIndex = tonumber(rankIndex), level = tonumber(level) or 0, className = ensureString(className), zone = ensureString(zone), note = ensureString(note), online = online == true }
            end
        end
    end
    return roster
end

local function findRosterMember(self, targetName)
    local wanted = normalizePlayerName(targetName)
    if wanted == "" then return nil end
    for _, member in ipairs(self:GetRoster() or {}) do
        if normalizePlayerName(member and member.name) == wanted then return member end
    end
    return nil
end

function Guild:IsGuildAdminTargetAvailable(targetName)
    if not getGuildIdentity().inGuild then return false, "sender-not-in-guild" end
    if self:IsLocalPlayerOfficer() ~= true then return false, "sender-not-officer" end
    local member = findRosterMember(self, targetName)
    if not member then return false, "target-not-in-guild" end
    if member.online ~= true then return false, "target-offline" end
    return true, nil, member
end

local function getArgument(arguments, index)
    return trimText(arguments and arguments[index])
end

local function successfulArgument(value)
    local normalized = string.lower(trimText(value))
    return normalized == "1" or normalized == "true" or normalized == "success"
end

local function getRequestId()
    Guild._guildAdminRequestSequence = (tonumber(Guild._guildAdminRequestSequence) or 0) + 1
    local now = type(Common.GetNow) == "function" and tonumber(Common.GetNow()) or 0
    return ("guild-admin-%d-%d"):format(math.floor(now), Guild._guildAdminRequestSequence)
end

local function sendAdminMessage(opcode, targetName, arguments)
    local target = trimText(targetName)
    if not opcode or target == "" or type(Comms.SendMessage) ~= "function" then return false end
    return Comms:SendMessage("WHISPER", opcode, arguments, target, { opcode = opcode, scope = "client" }) == true
end

local function invokeCallback(pending, response)
    if type(pending and pending.callback) == "function" then pending.callback(response) end
end

local function completePending(self, requestId, response)
    local pending = self._guildAdminPending and self._guildAdminPending[requestId] or nil
    if not pending then return false end
    self._guildAdminPending[requestId] = nil
    invokeCallback(pending, response)
    return true
end

local function registerPending(self, pending)
    self._guildAdminPending[pending.requestId] = pending
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(GUILD_ADMIN_REQUEST_TIMEOUT, function()
            if self._guildAdminPending[pending.requestId] == pending then
                completePending(self, pending.requestId, { requestId = pending.requestId, protocolVersion = GUILD_ADMIN_PROTOCOL_VERSION, success = false, reason = "no-response" })
            end
        end)
    end
end

local function sendRequest(self, opcode, targetName, arguments, pending)
    registerPending(self, pending)
    if sendAdminMessage(opcode, targetName, arguments) then return true, pending.requestId end
    self._guildAdminPending[pending.requestId] = nil
    invokeCallback(pending, { requestId = pending.requestId, protocolVersion = GUILD_ADMIN_PROTOCOL_VERSION, success = false, reason = "send-failed" })
    return false, "send-failed"
end

local function validateAdminRequest(self, arguments, sender, distribution, targetIndex)
    local requestId, version = getArgument(arguments, 1), getArgument(arguments, 2)
    if requestId == "" or version ~= GUILD_ADMIN_PROTOCOL_VERSION or distribution ~= "WHISPER" then return requestId ~= "" and requestId or nil, "incompatible-protocol", nil end
    local identity = getGuildIdentity()
    if not identity.inGuild then return requestId, "sender-not-in-guild", nil end
    local senderMember = findRosterMember(self, sender)
    if not senderMember then return requestId, "sender-not-in-guild", nil end
    if not hasGuildOfficerCapability(senderMember) then return requestId, "sender-not-officer", nil end
    local requestedTarget = normalizePlayerName(getArgument(arguments, targetIndex))
    if requestedTarget == "" or requestedTarget ~= getLocalPlayerName() then return requestId, "wrong-target", nil end
    return requestId, nil, identity
end

local function getSortedStringKeys(values, predicate)
    local keys = {}
    for key, value in pairs(type(values) == "table" and values or {}) do
        local normalized = trimText(key)
        if normalized ~= "" and (type(predicate) ~= "function" or predicate(value)) then keys[#keys + 1] = normalized end
    end
    table.sort(keys)
    return keys
end

local function appendProfileState(arguments)
    local achievementStates = {}
    if type(Profile.ListAchievementStates) == "function" then
        local ok, value = pcall(Profile.ListAchievementStates)
        if ok and type(value) == "table" then achievementStates = value end
    end
    local achievements = getSortedStringKeys(achievementStates, function(state) return type(state) == "table" and state.completedAt ~= nil end)
    arguments[#arguments + 1] = tostring(#achievements)
    for _, ref in ipairs(achievements) do arguments[#arguments + 1], arguments[#arguments + 2] = ref, achievementStates[ref].completedAt end
    local skills = {}
    if type(Profile.ListSkillLevels) == "function" then
        local ok, value = pcall(Profile.ListSkillLevels)
        if ok and type(value) == "table" then skills = value end
    end
    local skillRefs = getSortedStringKeys(skills)
    arguments[#arguments + 1] = tostring(#skillRefs)
    for _, ref in ipairs(skillRefs) do arguments[#arguments + 1], arguments[#arguments + 2] = ref, tonumber(skills[ref]) or 0 end
    return arguments
end

local function getManualRoleIds(identity, settingRef, setting)
    local ids, seen = {}, {}
    local guildKey = getGuildKey(identity)
    if guildKey == "" or type(Profile.GetAssignedGuildRoles) ~= "function" then return ids end
    local ok, assignments = pcall(Profile.GetAssignedGuildRoles, guildKey)
    if not ok or type(assignments) ~= "table" then return ids end
    for _, assignment in pairs(assignments) do
        local roleId = trimText(type(assignment) == "table" and assignment.roleId)
        if type(assignment) == "table" and trimText(assignment.guildSettingRef) == settingRef and roleId ~= "" and findRole(setting, roleId) and not seen[roleId] then
            ids[#ids + 1], seen[roleId] = roleId, true
        end
    end
    table.sort(ids)
    return ids
end

local function buildQueryResponse(self, requestId, success, reason, identity)
    local setting, resolution = self:GetActiveGuildSetting()
    local settingRef = setting and resolution.ref or ""
    local roleIds = success and setting and getManualRoleIds(identity, settingRef, setting) or {}
    local args = { requestId, GUILD_ADMIN_PROTOCOL_VERSION, success and "1" or "0", reason or (success and "ok" or "unknown-error"), settingRef, resolution and resolution.status or "unavailable", tostring(#roleIds) }
    for _, roleId in ipairs(roleIds) do args[#args + 1] = roleId end
    args[#args + 1] = identity and identity.guildRankIndex or ""
    args[#args + 1] = identity and identity.guildRankName or ""
    args[#args + 1] = identity and identity.guildName or ""
    return success and appendProfileState(args) or args
end

local function parseQueryResponse(arguments)
    local result = { manualRoleIds = {}, profileState = { achievements = {}, skills = {} } }
    local cursor = 5
    result.activeSettingRef = getArgument(arguments, cursor); cursor = cursor + 1
    result.activeSettingStatus = getArgument(arguments, cursor); cursor = cursor + 1
    local roleCount = normalizeInteger(getArgument(arguments, cursor), 0, 1000) or 0; cursor = cursor + 1
    for _ = 1, roleCount do
        local roleId = getArgument(arguments, cursor); cursor = cursor + 1
        if roleId ~= "" then result.manualRoleIds[#result.manualRoleIds + 1] = roleId end
    end
    result.guildRankIndex = tonumber(getArgument(arguments, cursor)); cursor = cursor + 1
    result.guildRankName = getArgument(arguments, cursor); cursor = cursor + 1
    result.guildName = getArgument(arguments, cursor); cursor = cursor + 1
    local achievementCount = normalizeInteger(getArgument(arguments, cursor), 0, 10000) or 0; cursor = cursor + 1
    for _ = 1, achievementCount do
        local ref, completedAt = getArgument(arguments, cursor), getArgument(arguments, cursor + 1); cursor = cursor + 2
        if ref ~= "" and completedAt ~= "" then result.profileState.achievements[ref] = { completedAt = completedAt } end
    end
    local skillCount = normalizeInteger(getArgument(arguments, cursor), 0, 10000) or 0; cursor = cursor + 1
    for _ = 1, skillCount do
        local ref, level = getArgument(arguments, cursor), normalizeInteger(getArgument(arguments, cursor + 1), 0); cursor = cursor + 2
        if ref ~= "" and level ~= nil then result.profileState.skills[ref] = level end
    end
    return result
end

local function buildMutationResponse(requestId, operation, success, reason, settingRef, roleId, effectiveAfter, detail, value)
    return { requestId, GUILD_ADMIN_PROTOCOL_VERSION, operation or "", success and "1" or "0", reason or (success and "ok" or "unknown-error"), settingRef or "", roleId or "", effectiveAfter == true and "1" or "0", detail or "", value or "" }
end

function Guild:QueryGuildAdminMember(targetName, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    if not available then invokeCallback({ callback = callback }, { success = false, reason = reason }) return false, reason end
    local requestId = getRequestId()
    return sendRequest(self, GUILD_ADMIN_QUERY_OPCODE, member.name, { requestId, GUILD_ADMIN_PROTOCOL_VERSION, member.name }, { requestId = requestId, kind = "query", targetName = member.name, callback = callback })
end

local function sendRoleMutation(self, operation, targetName, settingRef, roleId, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    settingRef, roleId = trimText(settingRef), trimText(roleId)
    if not available then invokeCallback({ callback = callback }, { success = false, operation = operation, reason = reason }) return false, reason end
    if settingRef == "" then invokeCallback({ callback = callback }, { success = false, operation = operation, reason = "setting-unavailable" }) return false, "setting-unavailable" end
    if roleId == "" then invokeCallback({ callback = callback }, { success = false, operation = operation, reason = "unknown-role" }) return false, "unknown-role" end
    local requestId = getRequestId()
    return sendRequest(self, GUILD_ADMIN_MUTATION_OPCODE, member.name, { requestId, GUILD_ADMIN_PROTOCOL_VERSION, operation, member.name, settingRef, roleId }, { requestId = requestId, kind = "mutation", operation = operation, targetName = member.name, callback = callback })
end

function Guild:AssignGuildRoleForMember(targetName, settingRef, roleId, callback)
    return sendRoleMutation(self, "assign_guild_role", targetName, settingRef, roleId, callback)
end

function Guild:RemoveGuildRoleForMember(targetName, settingRef, roleId, callback)
    return sendRoleMutation(self, "remove_guild_role", targetName, settingRef, roleId, callback)
end

local function sendSimpleMutation(self, operation, targetName, ref, value, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    if not available then invokeCallback({ callback = callback }, { success = false, operation = operation, reason = reason }) return false, reason end
    local requestId = getRequestId()
    return sendRequest(self, GUILD_ADMIN_MUTATION_OPCODE, member.name, { requestId, GUILD_ADMIN_PROTOCOL_VERSION, operation, member.name, ref or "", value or "" }, { requestId = requestId, kind = "mutation", operation = operation, targetName = member.name, callback = callback })
end

function Guild:GrantAchievementForMember(targetName, achievementRef, callback)
    local ref = trimText(achievementRef)
    if ref == "" then invokeCallback({ callback = callback }, { success = false, operation = "grant_achievement", reason = "unknown-achievement" }) return false, "unknown-achievement" end
    return sendSimpleMutation(self, "grant_achievement", targetName, ref, "", callback)
end

function Guild:AdjustSkillForMember(targetName, skillRef, delta, callback)
    local ref, normalized = trimText(skillRef), normalizeInteger(delta)
    if ref == "" then invokeCallback({ callback = callback }, { success = false, operation = "adjust_skill", reason = "unknown-skill" }) return false, "unknown-skill" end
    if not normalized or normalized == 0 then invokeCallback({ callback = callback }, { success = false, operation = "adjust_skill", reason = "invalid-delta" }) return false, "invalid-delta" end
    return sendSimpleMutation(self, "adjust_skill", targetName, ref, normalized, callback)
end

function Guild:GiveItemToMember(targetName, itemRef, quantity, callback)
    local ref, normalized = trimText(itemRef), normalizeInteger(quantity, 1)
    if ref == "" then invokeCallback({ callback = callback }, { success = false, operation = "give_item", reason = "unknown-item" }) return false, "unknown-item" end
    if not normalized then invokeCallback({ callback = callback }, { success = false, operation = "give_item", reason = "invalid-quantity" }) return false, "invalid-quantity" end
    return sendSimpleMutation(self, "give_item", targetName, ref, normalized, callback)
end

local function pendingResponse(self, arguments, sender, distribution)
    local requestId = getArgument(arguments, 1)
    local pending = self._guildAdminPending and self._guildAdminPending[requestId] or nil
    if not pending or distribution ~= "WHISPER" or normalizePlayerName(sender) ~= normalizePlayerName(pending.targetName) then return nil, nil end
    return requestId, pending
end

function Guild:HandleGuildAdminQueryResponse(arguments, sender, distribution)
    local requestId, pending = pendingResponse(self, arguments, sender, distribution)
    if not requestId or pending.kind ~= "query" then return false end
    local version = getArgument(arguments, 2)
    if version ~= GUILD_ADMIN_PROTOCOL_VERSION then return completePending(self, requestId, { requestId = requestId, protocolVersion = version, success = false, reason = "incompatible-protocol", sender = sender }) end
    local parsed = parseQueryResponse(arguments)
    local response = {
        requestId = requestId,
        protocolVersion = version,
        success = successfulArgument(getArgument(arguments, 3)),
        reason = getArgument(arguments, 4),
        activeSettingRef = parsed.activeSettingRef,
        activeSettingStatus = parsed.activeSettingStatus,
        manualRoleIds = parsed.manualRoleIds,
        guildRankIndex = parsed.guildRankIndex,
        guildRankName = parsed.guildRankName,
        guildName = parsed.guildName,
        profileState = parsed.profileState,
        achievements = parsed.profileState.achievements,
        skills = parsed.profileState.skills,
        sender = sender,
    }
    return completePending(self, requestId, response)
end

function Guild:HandleGuildAdminMutationResponse(arguments, sender, distribution)
    local requestId, pending = pendingResponse(self, arguments, sender, distribution)
    if not requestId or pending.kind ~= "mutation" then return false end
    local version, operation = getArgument(arguments, 2), getArgument(arguments, 3)
    if version ~= GUILD_ADMIN_PROTOCOL_VERSION or operation ~= pending.operation then return completePending(self, requestId, { requestId = requestId, protocolVersion = version, operation = operation, success = false, reason = "incompatible-protocol", sender = sender }) end
    return completePending(self, requestId, {
        requestId = requestId,
        protocolVersion = version,
        operation = operation,
        success = successfulArgument(getArgument(arguments, 4)),
        reason = getArgument(arguments, 5),
        activeSettingRef = getArgument(arguments, 6),
        roleId = getArgument(arguments, 7),
        effectiveAfter = successfulArgument(getArgument(arguments, 8)),
        detail = getArgument(arguments, 9),
        value = getArgument(arguments, 10),
        sender = sender,
    })
end

function Guild:HandleGuildAdminQuery(arguments, sender, distribution)
    local requestId, reason, identity = validateAdminRequest(self, arguments, sender, distribution, 3)
    if not requestId then return false end
    return sendAdminMessage(GUILD_ADMIN_QUERY_RESPONSE_OPCODE, sender, buildQueryResponse(self, requestId, reason == nil, reason or "ok", identity))
end

local function resolveAchievementReference(ref)
    if type(Registry.ResolveAchievementReference) ~= "function" then return nil, nil end
    local ok, dataset, entry = pcall(Registry.ResolveAchievementReference, Registry, ref)
    return ok and type(dataset) == "table" and type(entry) == "table" and dataset or nil, ok and type(entry) == "table" and entry or nil
end

local function resolveSkillReference(ref)
    if type(Registry.ResolveSkillReference) ~= "function" then return nil, nil end
    local ok, dataset, entry = pcall(Registry.ResolveSkillReference, Registry, ref)
    return ok and type(dataset) == "table" and type(entry) == "table" and dataset or nil, ok and type(entry) == "table" and entry or nil
end

local function resolveItemReference(ref)
    if type(Registry.ResolveItemReference) ~= "function" then return nil, nil end
    local ok, dataset, entry = pcall(Registry.ResolveItemReference, Registry, ref)
    return ok and type(dataset) == "table" and type(entry) == "table" and dataset or nil, ok and type(entry) == "table" and entry or nil
end

local function getSkillBounds(skillRef, skill)
    local minimum = string.lower(trimText(skill and skill.skillType)) == "crafting" and 1 or 0
    if type(Profile.GetResolvedSkillRow) ~= "function" then return minimum, nil, true end
    local ok, row = pcall(Profile.GetResolvedSkillRow, skillRef)
    if not ok or type(row) ~= "table" then return nil, nil, false end
    local maximum = normalizeInteger(row.maxValue, minimum)
    return minimum, maximum, true
end

function Guild:HandleGuildAdminMutation(arguments, sender, distribution)
    local operation = getArgument(arguments, 3)
    local requestId, reason, identity = validateAdminRequest(self, arguments, sender, distribution, 4)
    if not requestId then return false end
    if reason then return sendAdminMessage(GUILD_ADMIN_MUTATION_RESPONSE_OPCODE, sender, buildMutationResponse(requestId, operation, false, reason)) end

    if operation == "assign_guild_role" or operation == "remove_guild_role" then
        local requestedSettingRef, roleId = getArgument(arguments, 5), getArgument(arguments, 6)
        local setting, resolution = self:GetActiveGuildSetting()
        if not setting then reason = resolution.reason or "setting-unavailable"
        elseif requestedSettingRef ~= resolution.ref then reason = "setting-not-applicable"
        elseif not findRole(setting, roleId) then reason = "unknown-role"
        elseif operation == "assign_guild_role" then
            if type(Profile.AssignGuildRole) ~= "function" then reason = "persistence-failed"
            else
                local assignment = Profile.AssignGuildRole(resolution.guildKey, resolution.ref, roleId, { assignedAt = type(Common.GetNow) == "function" and Common.GetNow() or nil, assignedBy = tostring(sender or "") })
                if not assignment then reason = "persistence-failed"
                else
                    local effective = self:HasEffectiveRole(roleId)
                    self:RefreshWindow()
                    return sendAdminMessage(GUILD_ADMIN_MUTATION_RESPONSE_OPCODE, sender, buildMutationResponse(requestId, operation, true, "ok", resolution.ref, roleId, effective, "role-assigned", roleId))
                end
            end
        else
            if type(Profile.HasAssignedGuildRole) ~= "function" or type(Profile.RemoveGuildRole) ~= "function" then reason = "persistence-failed"
            elseif not Profile.HasAssignedGuildRole(resolution.guildKey, resolution.ref, roleId) then reason = "role-not-manually-assigned"
            else
                local removed = Profile.RemoveGuildRole(resolution.guildKey, resolution.ref, roleId)
                if not removed then reason = "persistence-failed"
                else
                    local effective = self:HasEffectiveRole(roleId)
                    self:RefreshWindow()
                    return sendAdminMessage(GUILD_ADMIN_MUTATION_RESPONSE_OPCODE, sender, buildMutationResponse(requestId, operation, true, "ok", resolution.ref, roleId, effective, "role-removed", roleId))
                end
            end
        end
        return sendAdminMessage(GUILD_ADMIN_MUTATION_RESPONSE_OPCODE, sender, buildMutationResponse(requestId, operation, false, reason, requestedSettingRef, roleId))
    end

    if operation == "grant_achievement" then
        local ref = getArgument(arguments, 5)
        local _, achievement = resolveAchievementReference(ref)
        if not achievement then reason = "unknown-achievement"
        else
            local achievements = Client.Achievements or {}
            if type(achievements.Grant) ~= "function" then reason = "achievement-api-unavailable"
            else
                local ok, granted, grantReason = pcall(achievements.Grant, achievements, ref, { source = "guild_admin", actor = tostring(sender or "") })
                if ok and granted == true then self:RefreshWindow() return sendAdminMessage(GUILD_ADMIN_MUTATION_RESPONSE_OPCODE, sender, buildMutationResponse(requestId, operation, true, "ok", "", "", false, "achievement-granted", ref)) end
                reason = ok and trimText(grantReason) or "achievement-grant-failed"
                if reason == "" then reason = "achievement-grant-failed" end
            end
        end
        return sendAdminMessage(GUILD_ADMIN_MUTATION_RESPONSE_OPCODE, sender, buildMutationResponse(requestId, operation, false, reason))
    end

    if operation == "adjust_skill" then
        local ref, delta = getArgument(arguments, 5), normalizeInteger(getArgument(arguments, 6))
        local _, skill = resolveSkillReference(ref)
        if not skill then reason = "unknown-skill"
        elseif not delta or delta == 0 then reason = "invalid-delta"
        elseif type(Profile.GetSkillLevel) ~= "function" or type(Profile.SetSkillLevel) ~= "function" then reason = "skill-api-unavailable"
        else
            local minimum, maximum = getSkillBounds(ref, skill)
            local current = normalizeInteger(Profile.GetSkillLevel(ref), 0)
            local nextLevel = current and current + delta or nil
            if minimum == nil then reason = "skill-unavailable"
            elseif not nextLevel or nextLevel < minimum or maximum and nextLevel > maximum then reason = "skill-level-out-of-range"
            else
                local ok, stored = pcall(Profile.SetSkillLevel, ref, nextLevel)
                local verified = ok and normalizeInteger(Profile.GetSkillLevel(ref), 0) or nil
                if stored == nil or verified ~= nextLevel then reason = "skill-persistence-failed"
                else self:RefreshWindow() return sendAdminMessage(GUILD_ADMIN_MUTATION_RESPONSE_OPCODE, sender, buildMutationResponse(requestId, operation, true, "ok", "", "", false, "skill-adjusted", verified)) end
            end
        end
        return sendAdminMessage(GUILD_ADMIN_MUTATION_RESPONSE_OPCODE, sender, buildMutationResponse(requestId, operation, false, reason))
    end

    if operation == "give_item" then
        local ref, quantity = getArgument(arguments, 5), normalizeInteger(getArgument(arguments, 6), 1)
        local dataset, item = resolveItemReference(ref)
        local datasetId, itemId = parseItemReference(ref)
        if not dataset or not item or not datasetId or not itemId then reason = "unknown-item"
        elseif not quantity then reason = "invalid-quantity"
        elseif type(getInventoryService().AddItem) ~= "function" then reason = "inventory-api-unavailable"
        else
            local ok, record = pcall(getInventoryService().AddItem, { dataset = datasetId, id = itemId, quantity = quantity })
            if not ok or not record then reason = "item-award-failed"
            else self:RefreshWindow() return sendAdminMessage(GUILD_ADMIN_MUTATION_RESPONSE_OPCODE, sender, buildMutationResponse(requestId, operation, true, "ok", "", "", false, "item-awarded", quantity)) end
        end
        return sendAdminMessage(GUILD_ADMIN_MUTATION_RESPONSE_OPCODE, sender, buildMutationResponse(requestId, operation, false, reason))
    end

    return sendAdminMessage(GUILD_ADMIN_MUTATION_RESPONSE_OPCODE, sender, buildMutationResponse(requestId, operation, false, "unsupported-operation"))
end

function Guild:RefreshWindow()
    local ui = Client.UI and Client.UI.Guild or nil
    local controller = ui and ui.Window or nil
    local window = controller and controller.Get and controller:Get() or nil
    if not window or not window.IsVisible or not window:IsVisible() then return nil end
    return window.Refresh and window:Refresh() or nil
end

function Guild:HandleRuntimeEvent(event)
    if event ~= "PLAYER_ENTERING_WORLD" and event ~= "PLAYER_GUILD_UPDATE" and event ~= "GUILD_ROSTER_UPDATE" then return nil end
    local _, roles = self:GetEffectiveRoles()
    self:RefreshWindow()
    return roles
end

return Guild
