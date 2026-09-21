local _, Addon = ...

local CORE_DATASET_ID = "f82db71a"
local CORE_GUILD_SETTING_ID = "g6mh7pla"
local REAGENTS_CATEGORY_ID = "l8r4h2xn"
local DAILY_REWARDS_CATEGORY_ID = "d8y4c6vc"

local definition = Addon.Data.DefaultDatasets.Definitions[CORE_DATASET_ID]
if not definition or not definition.dataset then
    error("Core default dataset must be registered before core_guild_settings.lua", 2)
end

if definition.version < 5 then
    definition.version = 5
end

local dataset = definition.dataset

-- Copper and Justice are built-in currencies and should be referenced directly
-- by requisition costs. Remove the obsolete authored Spark of Inspiration
-- currency from Core.
dataset.currencies = dataset.currencies or {}
for index = #dataset.currencies, 1, -1 do
    local currency = dataset.currencies[index]
    if type(currency) == "table"
        and (tostring(currency.id or "") == "k3aulg3o"
            or tostring(currency.name or "") == "Spark of Inspiration") then
        table.remove(dataset.currencies, index)
    end
end

-- Guild requisitions and daily rewards reference these packaged datasets.
-- Keep those relationships explicit for dependency activation/validation.
dataset.dependencies = dataset.dependencies or {}
local guildSettingDependencyIds = {
    "3eb7e9bb", -- Miscellaneous Items
    "d6ffc4e2", -- Alchemy
    "61fdf3df", -- Blacksmithing
    "af503002", -- Engineering
    "732368d4", -- Enchanting
    "4999dcec", -- Jewelcrafting
    "538a54a0", -- Leatherworking
    "072d4851", -- Inscription
    "7259f1d3", -- Tailoring
}
for _, requiredDependencyId in ipairs(guildSettingDependencyIds) do
    local hasDependency = false
    for _, dependencyId in ipairs(dataset.dependencies) do
        if tostring(dependencyId or "") == requiredDependencyId then
            hasDependency = true
            break
        end
    end
    if not hasDependency then
        dataset.dependencies[#dataset.dependencies + 1] = requiredDependencyId
    end
end

-- Role IDs are stable implementation details. The Data Editor presents Role
-- names and does not expose these identifiers to authors.
local professionRoleIdsBySkillId = {
    ["6hydytdf"] = "xzn8ikd5", -- Blacksmithing
    ["pdyzyudy"] = "5jz51hqf", -- Alchemy
    ["x9qez6bu"] = "tx7n3n76", -- Leatherworking
    ["fxp3vo4o"] = "csw345vc", -- Jewelcrafting
    ["goqp0alw"] = "7lqa25jv", -- Tailoring
    ["4keh3nf1"] = "dowfaitu", -- Enchanting
    ["ahx59weu"] = "j6zdsq7e", -- Fishing
    ["l9sc8rji"] = "b9ng9b03", -- Cooking
    ["xprqs3y1"] = "hibfzy2h", -- Engineering
    ["8gf2axb6"] = "p5btrcra", -- Inscription
}

local professionRoles = {}
for _, skill in ipairs(dataset.skills or {}) do
    if type(skill) == "table" and tostring(skill.skillType or "") == "crafting" then
        local skillId = tostring(skill.id or "")
        if skillId ~= "" then
            professionRoles[#professionRoles + 1] = {
                id = professionRoleIdsBySkillId[skillId] or ("profession_" .. skillId),
                name = tostring(skill.name or "Crafting Profession"),
                description = "",
                icon = skill.icon or "",
                autoGive = false,
                wowGuildRankIndices = {},
            }
        end
    end
end

table.sort(professionRoles, function(left, right)
    return string.lower(tostring(left.name or "")) < string.lower(tostring(right.name or ""))
end)

local roles = {
    {
        id = "gmoxy0vd",
        name = "Base",
        description = "",
        icon = "",
        autoGive = true,
        -- WoW guild rank indices are zero-based and guilds support up to ten ranks.
        wowGuildRankIndices = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    },
}

for _, role in ipairs(professionRoles) do
    roles[#roles + 1] = role
end

-- Guild Shop stock includes exceptional legacy reagents and profession daily
-- reward caches.
local requisitions = {
    {
        id = "w1v4r3ag",
        itemRef = "3eb7e9bb:2hbdmyj4", -- Wildvine
        quantity = 1,
        costs = {
            { currencyRef = "copper", amount = 400 }, -- 4s
        },
        characterLimit = 0,
        roleIds = { "xzn8ikd5", "tx7n3n76", "7lqa25jv" },
        shopCategoryId = REAGENTS_CATEGORY_ID,
    },
    {
        id = "h7w2r9kt",
        itemRef = "3eb7e9bb:w2plwren", -- Heart of the Wild
        quantity = 1,
        costs = {
            { currencyRef = "copper", amount = 400 }, -- 4s
        },
        characterLimit = 0,
        roleIds = { "5jz51hqf", "7lqa25jv" },
        shopCategoryId = REAGENTS_CATEGORY_ID,
    },
    {
        id = "d6m4r8un",
        itemRef = "3eb7e9bb:qivy73u4", -- Demonic Rune
        quantity = 1,
        costs = {
            { currencyRef = "copper", amount = 600 }, -- 6s
        },
        characterLimit = 0,
        roleIds = { "xzn8ikd5", "7lqa25jv" },
        shopCategoryId = REAGENTS_CATEGORY_ID,
    },
    {
        id = "d4r7r2un",
        itemRef = "3eb7e9bb:c1i4aecn", -- Dark Rune
        quantity = 1,
        costs = {
            { currencyRef = "copper", amount = 2000 }, -- 20s
        },
        characterLimit = 0,
        roleIds = { "xzn8ikd5", "7lqa25jv" },
        shopCategoryId = REAGENTS_CATEGORY_ID,
    },
    {
        id = "g8a3r5dn",
        itemRef = "3eb7e9bb:hq608hly", -- Guardian Stone
        quantity = 1,
        costs = {
            { currencyRef = "copper", amount = 10000 }, -- 1g
        },
        characterLimit = 0,
        roleIds = { "xzn8ikd5", "tx7n3n76", "7lqa25jv" },
        shopCategoryId = REAGENTS_CATEGORY_ID,
    },
    {
        id = "b9v2r6ne",
        itemRef = "3eb7e9bb:8eummju4", -- Bloodvine
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 75 },
        },
        characterLimit = 0,
        roleIds = { "xzn8ikd5", "tx7n3n76", "7lqa25jv" },
        shopCategoryId = REAGENTS_CATEGORY_ID,
    },
    {
        id = "f3c8r1re",
        itemRef = "3eb7e9bb:e0tarf0p", -- Fiery Core
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 110 },
        },
        characterLimit = 0,
        roleIds = { "xzn8ikd5", "tx7n3n76", "7lqa25jv" },
        shopCategoryId = REAGENTS_CATEGORY_ID,
    },
    {
        id = "l4c7r2re",
        itemRef = "3eb7e9bb:g3ytywfw", -- Lava Core
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 110 },
        },
        characterLimit = 0,
        roleIds = { "xzn8ikd5", "tx7n3n76", "7lqa25jv" },
        shopCategoryId = REAGENTS_CATEGORY_ID,
    },
    {
        id = "f9r5r0ne",
        itemRef = "3eb7e9bb:06vxv3hh", -- Frozen Rune
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 200 },
        },
        characterLimit = 0,
        roleIds = { "xzn8ikd5", "tx7n3n76", "7lqa25jv" },
        shopCategoryId = REAGENTS_CATEGORY_ID,
    },
    {
        id = "p2k8m4qz",
        itemRef = "",
        sourceType = "loot_table",
        lootRef = "d6ffc4e2:a6h3r8vk", -- Alchemy Daily Herb Cache
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 100 },
        },
        characterLimit = 0,
        shopCategoryId = DAILY_REWARDS_CATEGORY_ID,
    },
    {
        id = "b7r1w6ce",
        itemRef = "",
        sourceType = "loot_table",
        lootRef = "61fdf3df:d4p7k2ms", -- Blacksmithing Daily Bar Cache
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 100 },
        },
        characterLimit = 0,
        shopCategoryId = DAILY_REWARDS_CATEGORY_ID,
    },
    {
        id = "e3n9c5vx",
        itemRef = "",
        sourceType = "loot_table",
        lootRef = "af503002:n6r3k8vz", -- Engineering Daily Material Cache
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 100 },
        },
        characterLimit = 0,
        shopCategoryId = DAILY_REWARDS_CATEGORY_ID,
    },
    {
        id = "j6t2h8ra",
        itemRef = "",
        sourceType = "loot_table",
        lootRef = "732368d4:e5n8c2qx", -- Enchanting Daily Material Cache
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 100 },
        },
        characterLimit = 0,
        shopCategoryId = DAILY_REWARDS_CATEGORY_ID,
    },
    {
        id = "l4f7p1ny",
        itemRef = "",
        sourceType = "loot_table",
        lootRef = "4999dcec:j4c8m2rx", -- Jewelcrafting Daily Gem Cache
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 100 },
        },
        characterLimit = 0,
        shopCategoryId = DAILY_REWARDS_CATEGORY_ID,
    },
    {
        id = "i9c3d6qa",
        itemRef = "",
        sourceType = "loot_table",
        lootRef = "538a54a0:l7w4c9px", -- Leatherworking Daily Leather Cache
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 100 },
        },
        characterLimit = 0,
        shopCategoryId = DAILY_REWARDS_CATEGORY_ID,
    },
    {
        id = "t8m5v2rk",
        itemRef = "",
        sourceType = "loot_table",
        lootRef = "072d4851:i7n3k5qx", -- Inscription Daily Ink Cache
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 100 },
        },
        characterLimit = 0,
        shopCategoryId = DAILY_REWARDS_CATEGORY_ID,
    },
    {
        id = "g1x4b7we",
        itemRef = "",
        sourceType = "loot_table",
        lootRef = "7259f1d3:q8m2v7kc", -- Tailoring Daily Cloth Cache
        quantity = 1,
        costs = {
            { currencyRef = "justice", amount = 100 },
        },
        characterLimit = 0,
        shopCategoryId = DAILY_REWARDS_CATEGORY_ID,
    },
}

local guildSetting = {
    id = CORE_GUILD_SETTING_ID,
    name = "Base Guild Settings",
    description = "",
    -- Blank means this is the generic fallback Guild Setting for any guild.
    guildName = "",
    general = {
        enableRequisitions = true,
        enableDailyRewards = true,
    },
    roles = roles,
    shopCategories = {
        {
            id = REAGENTS_CATEGORY_ID,
            name = "Reagents",
            order = 10,
        },
        {
            id = DAILY_REWARDS_CATEGORY_ID,
            name = "Daily Rewards",
            order = 20,
        },
    },
    requisitions = requisitions,
    dailyRewards = {
        {
            id = "q8m2v7kc",
            type = "loot_table",
            ref = "7259f1d3:q8m2v7kc",
            amount = 1,
        },
    },
    tags = {},
}

dataset.guildSettings = dataset.guildSettings or {}
local replaced = false
for index, existing in ipairs(dataset.guildSettings) do
    if type(existing) == "table" and tostring(existing.id or "") == CORE_GUILD_SETTING_ID then
        dataset.guildSettings[index] = guildSetting
        replaced = true
        break
    end
end

if not replaced then
    dataset.guildSettings[#dataset.guildSettings + 1] = guildSetting
end
