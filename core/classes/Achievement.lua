local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Achievement = {}
Achievement.__index = Achievement

local CATEGORY_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "character", label = "Character" },
    { key = "combat", label = "Combat" },
    { key = "events", label = "Events" },
    { key = "player_vs_player", label = "Player vs. Player" },
    { key = "reputation", label = "Reputation" },
    { key = "feats_of_strength", label = "Feats of Strength" },
    { key = "legacy", label = "Legacy" },
}

local VALID_CATEGORY_KEYS = {}
for index = 1, #CATEGORY_DEFINITIONS do
    VALID_CATEGORY_KEYS[CATEGORY_DEFINITIONS[index].key] = true
end

local SUPPORTED_TRIGGERS = {
    manual = true,
    currency_gain = true,
    rpe_kill = true,
    rpe_event_complete = true,
    achievement_earned = true,
    item_gain = true,
    skill_gain = true,
    rpe_boss_kill = true,
    rpe_damage = true,
    rpe_healing = true,
    rpe_event_started = true,
}

local SUPPORTED_REWARD_TYPES = {
    item = true,
    currency = true,
}

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

local function normalizeTrigger(value)
    local trigger = string.lower(trimText(value))
    if SUPPORTED_TRIGGERS[trigger] then
        return trigger
    end

    return "manual"
end

local function normalizeGoal(value)
    local numericGoal = tonumber(value)
    if not numericGoal or numericGoal ~= numericGoal or numericGoal == math.huge or numericGoal == -math.huge then
        return 1
    end

    local goal = math.floor(numericGoal)
    return math.max(1, goal)
end

local function normalizeRewardAmount(value)
    local numericAmount = tonumber(value)
    if not numericAmount
        or numericAmount ~= numericAmount
        or numericAmount == math.huge
        or numericAmount == -math.huge
    then
        return 1
    end

    return math.max(1, math.floor(numericAmount))
end

local function normalizeFilters(value)
    if type(value) ~= "table" then
        return {}
    end

    return deepCopy(value)
end

local function normalizeCriterionId(value, index, usedIds, prefix)
    local baseId = trimText(value)
    if baseId == "" then
        baseId = ("%s_%d"):format(prefix or "criterion", index)
    end

    local criterionId = baseId
    local suffix = 2
    while usedIds[criterionId] do
        criterionId = ("%s_%d"):format(baseId, suffix)
        suffix = suffix + 1
    end

    usedIds[criterionId] = true
    return criterionId
end

local function normalizeCriterion(value, index, usedIds)
    local source = type(value) == "table" and value or {}

    return {
        id = normalizeCriterionId(source.id, index, usedIds),
        description = ensureString(source.description),
        trigger = normalizeTrigger(source.trigger),
        goal = normalizeGoal(source.goal),
        filters = normalizeFilters(source.filters),
    }
end

local function normalizeCriteria(value)
    if type(value) ~= "table" then
        return {}
    end

    local criteria = {}
    local usedIds = {}
    for index = 1, #value do
        criteria[index] = normalizeCriterion(value[index], index, usedIds)
    end

    return criteria
end

local function normalizeRewardType(value)
    local rewardType = string.lower(trimText(value))
    return SUPPORTED_REWARD_TYPES[rewardType] and rewardType or nil
end

local function normalizeReward(value, index, usedIds)
    if type(value) ~= "table" then
        return deepCopy(value)
    end

    local rewardType = normalizeRewardType(value.type)
    if not rewardType then
        return deepCopy(value)
    end

    local normalized = deepCopy(value)
    normalized.id = normalizeCriterionId(value.id, index, usedIds, "reward")
    normalized.type = rewardType
    normalized.ref = trimText(value.ref)
    normalized.amount = normalizeRewardAmount(value.amount)
    return normalized
end

local function normalizeRewards(value)
    if type(value) ~= "table" then
        return {}
    end

    local rewards = deepCopy(value)
    local usedIds = {}
    for index = 1, #value do
        rewards[index] = normalizeReward(value[index], index, usedIds)
    end

    return rewards
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

local function normalizeCategory(value)
    local category = string.lower(trimText(value))
    return VALID_CATEGORY_KEYS[category] and category or "general"
end

local function normalizeSubcategory(value)
    return trimText(value)
end

function Achievement.GetCategoryDefinitions()
    return CATEGORY_DEFINITIONS
end

function Achievement.NormalizeCategory(value)
    return normalizeCategory(value)
end

function Achievement.NormalizeSubcategory(value)
    return normalizeSubcategory(value)
end

function Achievement:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = "",
        criteria = {},
        rewards = {},
        category = "general",
        subcategory = "",
        tags = {},
    }, Achievement):Merge(data)
end

function Achievement:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    self.name = ensureString(self.name)
    self.description = ensureString(self.description)
    self.icon = ensureString(self.icon)
    self.criteria = normalizeCriteria(self.criteria)
    self.rewards = normalizeRewards(self.rewards)
    self.category = normalizeCategory(self.category)
    self.subcategory = normalizeSubcategory(self.subcategory)
    self.tags = normalizeTags(self.tags)

    return self
end

function Achievement:ToTable()
    return {
        id = self.id,
        name = ensureString(self.name),
        description = ensureString(self.description),
        icon = ensureString(self.icon),
        criteria = normalizeCriteria(self.criteria),
        rewards = normalizeRewards(self.rewards),
        category = normalizeCategory(self.category),
        subcategory = normalizeSubcategory(self.subcategory),
        tags = normalizeTags(self.tags),
    }
end

function Achievement.FromTable(data)
    return Achievement:New(data)
end

Addon.Internal.Database.Classes.Achievement = Achievement
