local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local GuildSetting = {}
GuildSetting.__index = GuildSetting

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimText(value)
    local text = ensureString(value)
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function isFiniteNumber(value)
    return value ~= nil
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function normalizeInteger(value, fallback, minimum)
    local numeric = tonumber(value)
    if not isFiniteNumber(numeric) then
        numeric = fallback
    end

    return math.max(minimum, math.floor(numeric))
end

local function normalizeCharacterLimit(value)
    local numeric = tonumber(value)
    if not isFiniteNumber(numeric) then
        return 1
    end

    if numeric == 0 then
        return 0
    end

    return math.max(1, math.floor(numeric))
end

local function normalizeWowGuildRankIndices(value)
    if type(value) ~= "table" then
        return {}
    end

    local normalized = {}
    local seen = {}
    for index = 1, #value do
        local numeric = tonumber(value[index])
        if isFiniteNumber(numeric) and numeric >= 0 and numeric == math.floor(numeric) then
            local rankIndex = math.floor(numeric)
            if not seen[rankIndex] then
                normalized[#normalized + 1] = rankIndex
                seen[rankIndex] = true
            end
        end
    end

    return normalized
end

local function normalizeBoolean(value)
    return value == true
end

local function normalizeReference(value)
    return trimText(value)
end

local function normalizeStableId(value, index, prefix, usedIds)
    local baseId = trimText(value)
    if baseId == "" then
        baseId = ("%s_%d"):format(prefix, index)
    end

    local id = baseId
    local suffix = 2
    while usedIds[id] do
        id = ("%s_%d"):format(baseId, suffix)
        suffix = suffix + 1
    end

    usedIds[id] = true
    return id
end

local function normalizeTags(value)
    if type(value) ~= "table" then
        return {}
    end

    local tags = {}
    for index = 1, #value do
        local tag = trimText(value[index])
        if tag ~= "" then
            tags[#tags + 1] = tag
        end
    end

    return tags
end

local function normalizeGeneral(value)
    local source = type(value) == "table" and value or {}

    return {
        enableRequisitions = normalizeBoolean(source.enableRequisitions),
        enableDailyRewards = normalizeBoolean(source.enableDailyRewards),
    }
end

local function normalizeIcon(value)
    if type(value) == "number" and isFiniteNumber(value) and value > 0 then
        return value
    end

    if type(value) == "string" then
        return trimText(value)
    end

    return ""
end

local function normalizeRole(value, index, usedIds)
    local source = type(value) == "table" and value or {}
    local wowGuildRankIndices = normalizeWowGuildRankIndices(source.wowGuildRankIndices)
    local autoGive = source.autoGive
    if autoGive == nil then
        -- Preserve the pre-autoGive behaviour for existing authored data:
        -- roles that already mapped one or more WoW ranks were automatic.
        autoGive = #wowGuildRankIndices > 0
    else
        autoGive = autoGive == true
    end

    return {
        id = normalizeStableId(source.id, index, "role", usedIds),
        name = ensureString(source.name),
        description = ensureString(source.description),
        icon = normalizeIcon(source.icon),
        autoGive = autoGive,
        wowGuildRankIndices = wowGuildRankIndices,
    }
end

local function normalizeRoles(value)
    if type(value) ~= "table" then
        return {}
    end

    local roles = {}
    local usedIds = {}
    for index = 1, #value do
        roles[index] = normalizeRole(value[index], index, usedIds)
    end

    return roles
end

local function buildLegacyRole(source)
    if type(source) ~= "table" or source.roles ~= nil or source.wowGuildRankIndices == nil then
        return nil
    end

    local roleId = trimText(source.id)
    if roleId == "" then
        roleId = "legacy_rank"
    end

    local wowGuildRankIndices = normalizeWowGuildRankIndices(source.wowGuildRankIndices)
    return {
        id = roleId,
        name = ensureString(source.name),
        description = ensureString(source.description),
        icon = normalizeIcon(source.icon),
        autoGive = #wowGuildRankIndices > 0,
        wowGuildRankIndices = wowGuildRankIndices,
    }
end

local function normalizeShopCategory(value, index, usedIds)
    local source = type(value) == "table" and value or {}

    return {
        id = normalizeStableId(source.id, index, "shop_category", usedIds),
        name = ensureString(source.name),
        order = normalizeInteger(source.order, index * 10, -2147483648),
    }
end

local function normalizeShopCategories(value)
    if type(value) ~= "table" then
        return {}
    end

    local categories = {}
    local usedIds = {}
    for index = 1, #value do
        categories[index] = normalizeShopCategory(value[index], index, usedIds)
    end

    return categories
end

local function normalizeCost(value)
    local source = type(value) == "table" and value or {}

    return {
        currencyRef = normalizeReference(source.currencyRef),
        amount = normalizeInteger(source.amount, 0, 0),
    }
end

local function normalizeCosts(value)
    if type(value) ~= "table" then
        return {}
    end

    local costs = {}
    for index = 1, #value do
        costs[index] = normalizeCost(value[index])
    end

    return costs
end

local function normalizeRoleIds(value)
    if type(value) ~= "table" then
        return {}
    end

    local roleIds = {}
    local seen = {}
    for index = 1, #value do
        local roleId = trimText(value[index])
        if roleId ~= "" and not seen[roleId] then
            roleIds[#roleIds + 1] = roleId
            seen[roleId] = true
        end
    end

    return roleIds
end

local function normalizeRequisitionSourceType(source)
    local sourceType = string.lower(trimText(source and source.sourceType))
    if sourceType == "loot" or sourceType == "table" or sourceType == "loot_table" then
        return "loot_table"
    end

    if normalizeReference(source and source.lootRef) ~= ""
        and normalizeReference(source and source.itemRef) == ""
    then
        return "loot_table"
    end

    return "item"
end

local function normalizeRequisition(value, index, usedIds, legacyRoleId)
    local source = type(value) == "table" and value or {}
    local roleIds = normalizeRoleIds(source.roleIds)
    if source.roleIds == nil and trimText(legacyRoleId) ~= "" then
        roleIds = { trimText(legacyRoleId) }
    end

    return {
        id = normalizeStableId(source.id, index, "requisition", usedIds),
        sourceType = normalizeRequisitionSourceType(source),
        itemRef = normalizeReference(source.itemRef),
        lootRef = normalizeReference(source.lootRef),
        quantity = normalizeInteger(source.quantity, 1, 1),
        costs = normalizeCosts(source.costs),
        characterLimit = normalizeCharacterLimit(source.characterLimit),
        roleIds = roleIds,
        shopCategoryId = trimText(source.shopCategoryId),
    }
end

local function normalizeRequisitions(value, legacyRoleId)
    if type(value) ~= "table" then
        return {}
    end

    local requisitions = {}
    local usedIds = {}
    for index = 1, #value do
        requisitions[index] = normalizeRequisition(value[index], index, usedIds, legacyRoleId)
    end

    return requisitions
end

local function normalizeDailyReward(value, index, usedIds)
    local source = type(value) == "table" and value or {}
    local rewardType = string.lower(trimText(source.type))
    if rewardType ~= "item" and rewardType ~= "currency" and rewardType ~= "loot_table" then
        rewardType = "item"
    end

    return {
        id = normalizeStableId(source.id, index, "daily_reward", usedIds),
        type = rewardType,
        ref = normalizeReference(source.ref),
        amount = normalizeInteger(source.amount, 1, 1),
    }
end

local function normalizeDailyRewards(value)
    if type(value) ~= "table" then
        return {}
    end

    local rewards = {}
    local usedIds = {}
    for index = 1, #value do
        rewards[index] = normalizeDailyReward(value[index], index, usedIds)
    end

    return rewards
end

function GuildSetting:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        guildName = "",
        general = {
            enableRequisitions = false,
            enableDailyRewards = false,
        },
        roles = {},
        shopCategories = {},
        requisitions = {},
        dailyRewards = {},
        tags = {},
    }, GuildSetting):Merge(data)
end

function GuildSetting:Merge(data)
    local legacyRole = buildLegacyRole(data)
    local legacyRoleId = legacyRole and trimText(legacyRole.id) or ""
    local legacyHasDailyRewards = legacyRole ~= nil
        and type(data) == "table"
        and type(data.dailyRewards) == "table"
        and #data.dailyRewards > 0

    if type(data) == "table" then
        for key, value in pairs(data) do
            self[key] = value
        end
    end

    self.name = ensureString(self.name)
    self.description = ensureString(self.description)
    self.guildName = ensureString(self.guildName)
    self.general = normalizeGeneral(self.general)
    self.roles = normalizeRoles(self.roles)
    if #self.roles == 0 and legacyRole then
        self.roles = normalizeRoles({ legacyRole })
    end
    self.shopCategories = normalizeShopCategories(self.shopCategories)
    self.requisitions = normalizeRequisitions(self.requisitions, legacyRoleId)
    self.dailyRewards = normalizeDailyRewards(self.dailyRewards)

    -- Legacy rank-scoped Daily Rewards cannot be represented safely by the
    -- GuildSetting-level reward model. Preserve the authored rewards for
    -- inspection/recovery, but leave them disabled until the author explicitly
    -- enables Daily Rewards on the migrated GuildSetting.
    if legacyHasDailyRewards then
        self.general.enableDailyRewards = false
    end

    -- Legacy fields are consumed only to build the Role-based model above.
    -- They are not retained on the live object and are never serialized.
    self.wowGuildRankIndices = nil
    self.requiredGuildRankIndex = nil
    self.progression = nil
    self.tags = normalizeTags(self.tags)

    return self
end

function GuildSetting:ToTable()
    return {
        id = self.id,
        name = ensureString(self.name),
        description = ensureString(self.description),
        guildName = ensureString(self.guildName),
        general = normalizeGeneral(self.general),
        roles = normalizeRoles(self.roles),
        shopCategories = normalizeShopCategories(self.shopCategories),
        requisitions = normalizeRequisitions(self.requisitions),
        dailyRewards = normalizeDailyRewards(self.dailyRewards),
        tags = normalizeTags(self.tags),
    }
end

function GuildSetting.FromTable(data)
    return GuildSetting:New(data)
end

Addon.Internal.Database.Classes.GuildSetting = GuildSetting
