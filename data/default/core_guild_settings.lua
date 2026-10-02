local _, Addon = ...

local CORE_DATASET_ID = "f82db71a"
local CORE_GUILD_SETTING_ID = "g6mh7pla"
local REAGENTS_CATEGORY_ID = "l8r4h2xn"
local DAILY_REWARDS_CATEGORY_ID = "d8y4c6vc"
local ARMOUR_CATEGORY_ID = "a6r4m2ur"

local definition = Addon.Data.DefaultDatasets.Definitions[CORE_DATASET_ID]
if not definition or not definition.dataset then
    error("Core default dataset must be registered before core_guild_settings.lua", 2)
end

if definition.version < 39 then
    definition.version = 39
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
    "dknight1", -- Death Knight
    "6e4d2a91", -- Druid
    "a93f7c12", -- Hunter
    "monkdata", -- Monk
    "c4a91e7d", -- Shaman
    "e8f3b2c6", -- Warlock
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
        roleIds = { "5jz51hqf" }, -- Alchemy
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
        roleIds = { "xzn8ikd5" }, -- Blacksmithing
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
        roleIds = { "hibfzy2h" }, -- Engineering
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
        roleIds = { "dowfaitu" }, -- Enchanting
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
        roleIds = { "csw345vc" }, -- Jewelcrafting
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
        roleIds = { "tx7n3n76" }, -- Leatherworking
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
        roleIds = { "p5btrcra" }, -- Inscription
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
        roleIds = { "7lqa25jv" }, -- Tailoring
        shopCategoryId = DAILY_REWARDS_CATEGORY_ID,
    },
}

-- Tier 0.5 / Dungeon Set 2 and Tier 2 armour sold for Justice.
-- Waist/belt pieces use the same 1,250 Justice small-slot tier as wrists.
local armourStockGroups = {
    {
        cost = 1250,
        itemRefs = {
            "b0211ab3:s05rwais",
            "b0211ab3:s05rwris",
            "b0211ab3:s05hwais",
            "b0211ab3:s05hwris",
            "b0211ab3:s05twais",
            "b0211ab3:s05twris",
            "7bbb4cb9:h05dwais",
            "7bbb4cb9:h05dwris",
            "7bbb4cb9:h05twais",
            "7bbb4cb9:h05twris",
            "1c1038a7:v05hbelt",
            "1c1038a7:v05hbrac",
            "1c1038a7:v05dcord",
            "1c1038a7:v05dwrap",
            "d7c874c4:m05dbelt",
            "d7c874c4:m05dbind",
            "d7c874c4:m05hwais",
            "d7c874c4:m05hwris",
            "23d5dce2:r05dbelt",
            "23d5dce2:r05dbrac",
            "23d5dce2:r05twais",
            "23d5dce2:r05twris",
            "a93f7c12:bm05mwst",
            "a93f7c12:bm05mbrc",
            "a93f7c12:bm05rblt",
            "a93f7c12:bm05rbnd",
            "6e4d2a91:d05bsash",
            "6e4d2a91:d05bwrap",
            "6e4d2a91:d05fgird",
            "6e4d2a91:d05fband",
            "6e4d2a91:d05twais",
            "6e4d2a91:d05twris",
            "6e4d2a91:d05rcord",
            "6e4d2a91:d05rbind",
            "e8f3b2c6:w05dbelt",
            "e8f3b2c6:w05dwrap",
            "e8f3b2c6:w05dbrac",
            "e8f3b2c6:w05tcord",
            "e8f3b2c6:w05tbind",
            "e8f3b2c6:wl2dbelt",
            "e8f3b2c6:wl2dwrst",
            "e8f3b2c6:wl2tcord",
            "e8f3b2c6:wl2twrap",
            "c4a91e7d:s05ewais",
            "c4a91e7d:s05ewrst",
            "c4a91e7d:s05nwais",
            "c4a91e7d:s05nwrst",
            "c4a91e7d:s05rwais",
            "c4a91e7d:s05rwrst",
            "c4a91e7d:s05twais",
            "c4a91e7d:s05twrst",
            "c4a91e7d:s2elwais",
            "c4a91e7d:s2elwrst",
            "c4a91e7d:s2enwais",
            "c4a91e7d:s2enwrst",
            "c4a91e7d:s2rhwais",
            "c4a91e7d:s2rhwrst",
            "c4a91e7d:s2tnwais",
            "c4a91e7d:s2tnwrst",
            "dknight1:dk05bwai",
            "dknight1:dk05bwri",
            "dknight1:dk05fbel",
            "dknight1:dk05fbra",
            "dknight1:dk05ugir",
            "dknight1:dk05uvam",
            "monkdata:mn05dbel",
            "monkdata:mn05dbnd",
            "monkdata:mn05twst",
            "monkdata:mn05twri",
            "monkdata:mn05hcor",
            "monkdata:mn05hcuf",
        },
    },
    {
        cost = 1750,
        itemRefs = {
            "b0211ab3:s05rhand",
            "b0211ab3:s05rboot",
            "b0211ab3:s05hhand",
            "b0211ab3:s05hboot",
            "b0211ab3:s05thand",
            "b0211ab3:s05tboot",
            "7bbb4cb9:h05dhnds",
            "7bbb4cb9:h05dboot",
            "7bbb4cb9:h05thnds",
            "7bbb4cb9:h05tboot",
            "1c1038a7:v05hmitt",
            "1c1038a7:v05hboot",
            "1c1038a7:v05dhnds",
            "1c1038a7:v05dslip",
            "d7c874c4:m05dgaun",
            "d7c874c4:m05dsand",
            "d7c874c4:m05hglov",
            "d7c874c4:m05hboot",
            "23d5dce2:r05dgrip",
            "23d5dce2:r05dfoot",
            "23d5dce2:r05thand",
            "23d5dce2:r05ttrea",
            "a93f7c12:bm05mgrv",
            "a93f7c12:bm05mfst",
            "a93f7c12:bm05rtrd",
            "a93f7c12:bm05rgan",
            "6e4d2a91:d05bgalo",
            "6e4d2a91:d05bhand",
            "6e4d2a91:d05fwalk",
            "6e4d2a91:d05ffist",
            "6e4d2a91:d05ttred",
            "6e4d2a91:d05tgrip",
            "6e4d2a91:d05rsand",
            "6e4d2a91:d05rgaun",
            "e8f3b2c6:w05dsand",
            "e8f3b2c6:w05ttrds",
            "e8f3b2c6:w05tgrsp",
            "e8f3b2c6:wl2dboot",
            "e8f3b2c6:wl2dglov",
            "e8f3b2c6:wl2ttrds",
            "e8f3b2c6:wl2thand",
            "c4a91e7d:s05efeet",
            "c4a91e7d:s05ehnds",
            "c4a91e7d:s05nfeet",
            "c4a91e7d:s05nhnds",
            "c4a91e7d:s05rfeet",
            "c4a91e7d:s05rhnds",
            "c4a91e7d:s05tfeet",
            "c4a91e7d:s05thnds",
            "c4a91e7d:s2elfeet",
            "c4a91e7d:s2elhnds",
            "c4a91e7d:s2enfeet",
            "c4a91e7d:s2enhnds",
            "c4a91e7d:s2rhfeet",
            "c4a91e7d:s2rhhnds",
            "c4a91e7d:s2tnfeet",
            "c4a91e7d:s2tnhnds",
            "dknight1:dk05bgri",
            "dknight1:dk05bsab",
            "dknight1:dk05fgau",
            "dknight1:dk05fboo",
            "dknight1:dk05uhan",
            "dknight1:dk05ugre",
            "monkdata:mn05dgrp",
            "monkdata:mn05dft1",
            "monkdata:mn05thnd",
            "monkdata:mn05ttrd",
            "monkdata:mn05hgau",
            "monkdata:mn05hsan",
        },
    },
    {
        cost = 2250,
        itemRefs = {
            "b0211ab3:s05rhelm",
            "b0211ab3:s05rshld",
            "b0211ab3:s05rchst",
            "b0211ab3:s05rlegs",
            "b0211ab3:s05hhelm",
            "b0211ab3:s05hshld",
            "b0211ab3:s05hchst",
            "b0211ab3:s05hlegs",
            "b0211ab3:s05thelm",
            "b0211ab3:s05tshld",
            "b0211ab3:s05tchst",
            "b0211ab3:s05tlegs",
            "7bbb4cb9:h05dhelm",
            "7bbb4cb9:h05dshld",
            "7bbb4cb9:h05dchst",
            "7bbb4cb9:h05dlegs",
            "7bbb4cb9:h05tface",
            "7bbb4cb9:h05tshld",
            "7bbb4cb9:h05tchst",
            "7bbb4cb9:h05tlegs",
            "1c1038a7:v05hcrow",
            "1c1038a7:v05hmant",
            "1c1038a7:v05hrobe",
            "1c1038a7:v05hskrt",
            "1c1038a7:v05dcowl",
            "1c1038a7:v05depau",
            "1c1038a7:v05dgown",
            "1c1038a7:v05dlegs",
            "d7c874c4:m05dcrow",
            "d7c874c4:m05dmant",
            "d7c874c4:m05drobe",
            "d7c874c4:m05dlegs",
            "d7c874c4:m05hhelm",
            "d7c874c4:m05hshld",
            "d7c874c4:m05hchst",
            "d7c874c4:m05hlegs",
            "23d5dce2:r05dcap",
            "23d5dce2:r05dspau",
            "23d5dce2:r05dtuni",
            "23d5dce2:r05dpant",
            "23d5dce2:r05tface",
            "23d5dce2:r05tpaul",
            "23d5dce2:r05tarmo",
            "23d5dce2:r05tlegs",
            "a93f7c12:bm05mchn",
            "a93f7c12:bm05mcof",
            "a93f7c12:bm05mlgg",
            "a93f7c12:bm05mpld",
            "a93f7c12:bm05rtun",
            "a93f7c12:bm05rcap",
            "a93f7c12:bm05rpnt",
            "a93f7c12:bm05rmnt",
            "6e4d2a91:d05bvest",
            "6e4d2a91:d05bcowl",
            "6e4d2a91:d05bkilt",
            "6e4d2a91:d05bspau",
            "6e4d2a91:d05ftuni",
            "6e4d2a91:d05fcap",
            "6e4d2a91:d05ftrou",
            "6e4d2a91:d05fepau",
            "6e4d2a91:d05tarmo",
            "6e4d2a91:d05tface",
            "6e4d2a91:d05tlegs",
            "6e4d2a91:d05tpaul",
            "6e4d2a91:d05rembr",
            "6e4d2a91:d05rhead",
            "6e4d2a91:d05rpant",
            "6e4d2a91:d05rmant",
            "e8f3b2c6:w05drobe",
            "e8f3b2c6:w05dmask",
            "e8f3b2c6:w05dlegs",
            "e8f3b2c6:w05dmant",
            "e8f3b2c6:w05tembr",
            "e8f3b2c6:w05thood",
            "e8f3b2c6:w05tpant",
            "e8f3b2c6:w05tepau",
            "e8f3b2c6:wl2drobe",
            "e8f3b2c6:wl2dhead",
            "e8f3b2c6:wl2dlegs",
            "e8f3b2c6:wl2dshld",
            "e8f3b2c6:wl2tgarb",
            "e8f3b2c6:wl2tcowl",
            "e8f3b2c6:wl2tpant",
            "e8f3b2c6:wl2tshld",
            "c4a91e7d:s05echst",
            "c4a91e7d:s05ehead",
            "c4a91e7d:s05elegs",
            "c4a91e7d:s05eshld",
            "c4a91e7d:s05nchst",
            "c4a91e7d:s05nhead",
            "c4a91e7d:s05nlegs",
            "c4a91e7d:s05nshld",
            "c4a91e7d:s05rchst",
            "c4a91e7d:s05rhead",
            "c4a91e7d:s05rlegs",
            "c4a91e7d:s05rshld",
            "c4a91e7d:s05tchst",
            "c4a91e7d:s05thead",
            "c4a91e7d:s05tlegs",
            "c4a91e7d:s05tshld",
            "c4a91e7d:s2elchst",
            "c4a91e7d:s2elhead",
            "c4a91e7d:s2ellegs",
            "c4a91e7d:s2elshld",
            "c4a91e7d:s2enchst",
            "c4a91e7d:s2enhead",
            "c4a91e7d:s2enlegs",
            "c4a91e7d:s2enshld",
            "c4a91e7d:s2rhchst",
            "c4a91e7d:s2rhhead",
            "c4a91e7d:s2rhlegs",
            "c4a91e7d:s2rhshld",
            "c4a91e7d:s2tnchst",
            "c4a91e7d:s2tnhead",
            "c4a91e7d:s2tnlegs",
            "c4a91e7d:s2tnshld",
            "dknight1:dk05bfac",
            "dknight1:dk05bsho",
            "dknight1:dk05bchs",
            "dknight1:dk05bleg",
            "dknight1:dk05fcro",
            "dknight1:dk05fspa",
            "dknight1:dk05fchs",
            "dknight1:dk05fleg",
            "dknight1:dk05uhel",
            "dknight1:dk05upau",
            "dknight1:dk05uchs",
            "dknight1:dk05uleg",
            "monkdata:mn05dcap",
            "monkdata:mn05dspa",
            "monkdata:mn05dtun",
            "monkdata:mn05dpnt",
            "monkdata:mn05tfac",
            "monkdata:mn05tpau",
            "monkdata:mn05tarm",
            "monkdata:mn05tleg",
            "monkdata:mn05hhea",
            "monkdata:mn05hman",
            "monkdata:mn05hemb",
            "monkdata:mn05hleg",
        },
    },
}

for _, stockGroup in ipairs(armourStockGroups) do
    for _, itemRef in ipairs(stockGroup.itemRefs) do
        requisitions[#requisitions + 1] = {
            id = "t05_" .. itemRef:gsub(":", "_"),
            itemRef = itemRef,
            quantity = 1,
            costs = {
                { currencyRef = "justice", amount = stockGroup.cost },
            },
            characterLimit = 0,
            roleIds = {},
            shopCategoryId = ARMOUR_CATEGORY_ID,
        }
    end
end

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
            id = ARMOUR_CATEGORY_ID,
            name = "Armour",
            order = 20,
        },
        {
            id = DAILY_REWARDS_CATEGORY_ID,
            name = "Loot Tables",
            order = 30,
        },
    },
    requisitions = requisitions,
    dailyRewards = {
        { id = "daily_alchemy", type = "loot_table", ref = "d6ffc4e2:a6h3r8vk", amount = 1, roleIds = { "5jz51hqf" } },
        { id = "daily_blacksmithing", type = "loot_table", ref = "61fdf3df:d4p7k2ms", amount = 1, roleIds = { "xzn8ikd5" } },
        { id = "daily_engineering", type = "loot_table", ref = "af503002:n6r3k8vz", amount = 1, roleIds = { "hibfzy2h" } },
        { id = "daily_enchanting", type = "loot_table", ref = "732368d4:e5n8c2qx", amount = 1, roleIds = { "dowfaitu" } },
        { id = "daily_jewelcrafting", type = "loot_table", ref = "4999dcec:j4c8m2rx", amount = 1, roleIds = { "csw345vc" } },
        { id = "daily_leatherworking", type = "loot_table", ref = "538a54a0:l7w4c9px", amount = 1, roleIds = { "tx7n3n76" } },
        { id = "daily_inscription", type = "loot_table", ref = "072d4851:i7n3k5qx", amount = 1, roleIds = { "p5btrcra" } },
        { id = "daily_tailoring", type = "loot_table", ref = "7259f1d3:q8m2v7kc", amount = 1, roleIds = { "7lqa25jv" } },
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
