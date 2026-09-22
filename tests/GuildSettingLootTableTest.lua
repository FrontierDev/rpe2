local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Addon = { Internal = { Database = { Classes = {} } } }
local chunk, loadError = loadfile("core/classes/GuildSetting.lua")
assert(chunk, loadError)
chunk(nil, Addon)

local GuildSetting = Addon.Internal.Database.Classes.GuildSetting
local authored = {
    id = "guild-setting",
    requisitions = {
        {
            id = "loot-requisition",
            sourceType = "loot_table",
            itemRef = "",
            lootRef = "d6ffc4e2:a6h3r8vk",
            quantity = 1,
            costs = { { currencyRef = "justice", amount = 100 } },
            characterLimit = 0,
            roleIds = { "alchemy-role" },
        },
        {
            id = "item-requisition",
            itemRef = "f82db71a:item",
            quantity = 2,
            costs = { { currencyRef = "copper", amount = 4 } },
        },
    },
    dailyRewards = {
        { id = "loot-reward", type = "loot_table", ref = "7259f1d3:q8m2v7kc", amount = 1 },
        { id = "item-reward", type = "item", ref = "f82db71a:item", amount = 2 },
        { id = "currency-reward", type = "currency", ref = "justice", amount = 3 },
    },
}

local created = GuildSetting:New(authored)
assertEqual(created.requisitions[1].sourceType, "loot_table", "New preserves loot requisition source type")
assertEqual(created.requisitions[1].lootRef, "d6ffc4e2:a6h3r8vk", "New preserves loot requisition reference")
assertEqual(created.requisitions[1].roleIds[1], "alchemy-role", "New preserves loot requisition role restriction")
assertEqual(created.requisitions[2].sourceType, "item", "New keeps item requisitions as items")
assertEqual(created.requisitions[2].itemRef, "f82db71a:item", "New preserves item requisition reference")
assertEqual(created.dailyRewards[1].type, "loot_table", "New preserves loot-table daily reward type")
assertEqual(created.dailyRewards[1].ref, "7259f1d3:q8m2v7kc", "New preserves loot-table daily reward reference")
assertEqual(created.dailyRewards[2].type, "item", "New preserves item daily reward type")
assertEqual(created.dailyRewards[2].ref, "f82db71a:item", "New preserves item daily reward reference")
assertEqual(created.dailyRewards[3].type, "currency", "New preserves currency daily reward type")
assertEqual(created.dailyRewards[3].ref, "justice", "New preserves currency daily reward reference")

local roundTrip = GuildSetting.FromTable(authored):ToTable()
assertEqual(roundTrip.requisitions[1].sourceType, "loot_table", "round trip preserves loot requisition source type")
assertEqual(roundTrip.requisitions[1].lootRef, "d6ffc4e2:a6h3r8vk", "round trip preserves loot requisition reference")
assertEqual(roundTrip.requisitions[2].sourceType, "item", "round trip preserves item requisition source type")
assertEqual(roundTrip.requisitions[2].itemRef, "f82db71a:item", "round trip preserves item requisition reference")
assertEqual(roundTrip.dailyRewards[1].type, "loot_table", "round trip preserves loot-table daily reward type")
assertEqual(roundTrip.dailyRewards[1].ref, "7259f1d3:q8m2v7kc", "round trip preserves loot-table daily reward reference")
assertEqual(roundTrip.dailyRewards[2].type, "item", "round trip preserves item daily reward type")
assertEqual(roundTrip.dailyRewards[2].ref, "f82db71a:item", "round trip preserves item daily reward reference")
assertEqual(roundTrip.dailyRewards[3].type, "currency", "round trip preserves currency daily reward type")
assertEqual(roundTrip.dailyRewards[3].ref, "justice", "round trip preserves currency daily reward reference")

print("GuildSettingLootTableTest passed")
