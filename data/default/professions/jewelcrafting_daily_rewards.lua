local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
local jewelcrafting = type(definitions) == "table" and definitions["4999dcec"] or nil
local dataset = type(jewelcrafting) == "table" and jewelcrafting.dataset or nil

if type(dataset) == "table" then
    dataset.loot = type(dataset.loot) == "table" and dataset.loot or {}

    local lootId = "j4c8m2rx"
    local definition = {
        conditions = {},
        description = "Daily Jewelcrafting material cache. Guarantees one raw gem reward, weighted toward common low-tier gems with increasingly rare high-tier gem outcomes.",
        drawCount = 1,
        entries = {
            { id = "tigerseye", maxQuantity = 7, minQuantity = 4, ref = "4999dcec:n2q67aox", type = "item", weight = 20 },
            { id = "malachite", maxQuantity = 7, minQuantity = 4, ref = "4999dcec:fcj318z0", type = "item", weight = 20 },
            { id = "shadowgem", maxQuantity = 6, minQuantity = 3, ref = "4999dcec:l3c8nzh7", type = "item", weight = 16 },
            { id = "lesser_moonstone", maxQuantity = 6, minQuantity = 3, ref = "4999dcec:w1ryslhj", type = "item", weight = 16 },
            { id = "moss_agate", maxQuantity = 6, minQuantity = 3, ref = "4999dcec:gw6wflop", type = "item", weight = 16 },
            { id = "jade", maxQuantity = 5, minQuantity = 2, ref = "4999dcec:qgjc3m5m", type = "item", weight = 12 },
            { id = "citrine", maxQuantity = 5, minQuantity = 2, ref = "4999dcec:ht59o8mx", type = "item", weight = 12 },
            { id = "aquamarine", maxQuantity = 4, minQuantity = 2, ref = "4999dcec:5nrqhg0t", type = "item", weight = 10 },
            { id = "star_ruby", maxQuantity = 3, minQuantity = 1, ref = "4999dcec:mr1cbt76", type = "item", weight = 8 },
            { id = "large_opal", maxQuantity = 2, minQuantity = 1, ref = "4999dcec:pkgfp4sl", type = "item", weight = 5 },
            { id = "blue_sapphire", maxQuantity = 2, minQuantity = 1, ref = "4999dcec:sviqeucv", type = "item", weight = 5 },
            { id = "huge_emerald", maxQuantity = 2, minQuantity = 1, ref = "4999dcec:bw8sfpgw", type = "item", weight = 5 },
            { id = "azerothian_diamond", maxQuantity = 2, minQuantity = 1, ref = "4999dcec:atpvfzht", type = "item", weight = 4 },
            { id = "arcane_crystal", maxQuantity = 1, minQuantity = 1, ref = "4999dcec:kzswtd0z", type = "item", weight = 2 },
            { id = "black_diamond", maxQuantity = 1, minQuantity = 1, ref = "4999dcec:cjo7ed11", type = "item", weight = 1 },
        },
        icon = "interface/icons/inv_misc_gem_diamond_01.blp",
        id = lootId,
        items = {},
        name = "Jewelcrafting Daily Gem Cache",
        tags = {},
    }

    local replaced = false
    for index = 1, #dataset.loot do
        local loot = dataset.loot[index]
        if type(loot) == "table" and tostring(loot.id or "") == lootId then
            dataset.loot[index] = definition
            replaced = true
            break
        end
    end

    if not replaced then
        dataset.loot[#dataset.loot + 1] = definition
    end

    jewelcrafting.version = math.max(4, math.floor(tonumber(jewelcrafting.version) or 1))
end
