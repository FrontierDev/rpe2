local _, Addon = ...

local CORE_DATASET_ID = "f82db71a"
local CORE_GUILD_SETTING_ID = "g6mh7pla"
local REAGENTS_CATEGORY_ID = "l8r4h2xn"

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

-- Reagent requisitions reference the packaged Miscellaneous Items dataset.
-- Keep that relationship explicit for dependency activation/validation.
dataset.dependencies = dataset.dependencies or {}
local hasMiscDependency = false
for _, dependencyId in ipairs(dataset.dependencies) do
    if tostring(dependencyId or "") == "3eb7e9bb" then
        hasMiscDependency = true
        break
    end
end
if not hasMiscDependency then
    dataset.dependencies[#dataset.dependencies + 1] = "3eb7e9bb"
end

local hasTailoringDependency = false
for _, dependencyId in ipairs(dataset.dependencies) do
    if tostring(dependencyId or "") == "7259f1d3" then
        hasTailoringDependency = true
        break
    end
end
if not hasTailoringDependency then
    dataset.dependencies[#dataset.dependencies + 1] = "7259f1d3"
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

-- These unlimited Guild Shop entries are intentionally limited to exceptional
-- legacy/special reagents. Normal gathering and crafting materials remain part
-- of the ordinary acquisition economy rather than the Guild Shop.
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
