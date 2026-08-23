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

local function normalizeOptionalRankIndex(value)
    local numeric = tonumber(value)
    if not isFiniteNumber(numeric) or numeric < 0 then
        return nil
    end

    return math.floor(numeric)
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
        enableProgression = normalizeBoolean(source.enableProgression),
    }
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

local function normalizeRequisition(value, index, usedIds)
    local source = type(value) == "table" and value or {}

    return {
        id = normalizeStableId(source.id, index, "requisition", usedIds),
        itemRef = normalizeReference(source.itemRef),
        quantity = normalizeInteger(source.quantity, 1, 1),
        costs = normalizeCosts(source.costs),
        requiredGuildRankIndex = normalizeOptionalRankIndex(source.requiredGuildRankIndex),
        characterLimit = normalizeInteger(source.characterLimit, 1, 1),
    }
end

local function normalizeRequisitions(value)
    if type(value) ~= "table" then
        return {}
    end

    local requisitions = {}
    local usedIds = {}
    for index = 1, #value do
        requisitions[index] = normalizeRequisition(value[index], index, usedIds)
    end

    return requisitions
end

local function normalizeDailyReward(value, index, usedIds)
    local source = type(value) == "table" and value or {}
    local rewardType = string.lower(trimText(source.type))
    if rewardType ~= "item" and rewardType ~= "currency" then
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

local function normalizeSpellRefs(value)
    if type(value) ~= "table" then
        return {}
    end

    local spellRefs = {}
    local seen = {}
    for index = 1, #value do
        local spellRef = normalizeReference(value[index])
        if spellRef ~= "" and not seen[spellRef] then
            spellRefs[#spellRefs + 1] = spellRef
            seen[spellRef] = true
        end
    end

    return spellRefs
end

local function normalizeProgressionEntry(value, index, usedIds)
    local source = type(value) == "table" and value or {}

    return {
        id = normalizeStableId(source.id, index, "progression_entry", usedIds),
        name = ensureString(source.name),
        description = ensureString(source.description),
        icon = ensureString(source.icon),
        lockedText = ensureString(source.lockedText),
        spellRefs = normalizeSpellRefs(source.spellRefs),
    }
end

local function normalizeProgressionEntries(value)
    if type(value) ~= "table" then
        return {}
    end

    local entries = {}
    local usedIds = {}
    for index = 1, #value do
        entries[index] = normalizeProgressionEntry(value[index], index, usedIds)
    end

    return entries
end

local function normalizeProgression(value)
    local source = type(value) == "table" and value or {}

    return {
        slotCount = normalizeInteger(source.slotCount, 3, 1),
        entries = normalizeProgressionEntries(source.entries),
    }
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
            enableProgression = false,
        },
        requisitions = {},
        dailyRewards = {},
        progression = {
            slotCount = 3,
            entries = {},
        },
        tags = {},
    }, GuildSetting):Merge(data)
end

function GuildSetting:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    self.name = ensureString(self.name)
    self.description = ensureString(self.description)
    self.guildName = ensureString(self.guildName)
    self.general = normalizeGeneral(self.general)
    self.requisitions = normalizeRequisitions(self.requisitions)
    self.dailyRewards = normalizeDailyRewards(self.dailyRewards)
    self.progression = normalizeProgression(self.progression)
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
        requisitions = normalizeRequisitions(self.requisitions),
        dailyRewards = normalizeDailyRewards(self.dailyRewards),
        progression = normalizeProgression(self.progression),
        tags = normalizeTags(self.tags),
    }
end

function GuildSetting.FromTable(data)
    return GuildSetting:New(data)
end

Addon.Internal.Database.Classes.GuildSetting = GuildSetting
