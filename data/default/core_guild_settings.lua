local _, Addon = ...

local CORE_DATASET_ID = "f82db71a"
local CORE_GUILD_SETTING_ID = "g6mh7pla"

local definition = Addon.Data.DefaultDatasets.Definitions[CORE_DATASET_ID]
if not definition or not definition.dataset then
    error("Core default dataset must be registered before core_guild_settings.lua", 2)
end

if definition.version < 2 then
    definition.version = 2
end

local dataset = definition.dataset

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

local guildSetting = {
    id = CORE_GUILD_SETTING_ID,
    name = "Base Guild Settings",
    description = "",
    -- Blank means this is the generic fallback Guild Setting for any guild.
    guildName = "",
    general = {
        enableRequisitions = false,
        enableDailyRewards = false,
    },
    roles = roles,
    shopCategories = {},
    requisitions = {},
    dailyRewards = {},
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
