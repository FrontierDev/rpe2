local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
local enchanting = type(definitions) == "table" and definitions["732368d4"] or nil
local dataset = type(enchanting) == "table" and enchanting.dataset or nil

if type(dataset) == "table" then
    dataset.loot = type(dataset.loot) == "table" and dataset.loot or {}

    local itemRefsByName = {}
    for _, item in ipairs(type(dataset.items) == "table" and dataset.items or {}) do
        local itemId = tostring(item and item.id or "")
        local itemName = tostring(item and item.name or "")
        if itemId ~= "" and itemName ~= "" then
            itemRefsByName[itemName] = ("732368d4:%s"):format(itemId)
        end
    end

    local materialDefinitions = {
        -- Dusts are the most common daily result.
        { id = "strange_dust", name = "Strange Dust", weight = 20, minQuantity = 6, maxQuantity = 10 },
        { id = "soul_dust", name = "Soul Dust", weight = 18, minQuantity = 6, maxQuantity = 10 },
        { id = "vision_dust", name = "Vision Dust", weight = 16, minQuantity = 5, maxQuantity = 8 },
        { id = "dream_dust", name = "Dream Dust", weight = 14, minQuantity = 4, maxQuantity = 7 },
        { id = "illusion_dust", name = "Illusion Dust", weight = 12, minQuantity = 4, maxQuantity = 7 },

        -- Essences are less common and awarded in smaller amounts.
        { id = "magic_essence", name = "Magic Essence", weight = 6, minQuantity = 2, maxQuantity = 4 },
        { id = "astral_essence", name = "Astral Essence", weight = 5, minQuantity = 2, maxQuantity = 4 },
        { id = "mystic_essence", name = "Mystic Essence", weight = 4, minQuantity = 2, maxQuantity = 3 },
        { id = "nether_essence", name = "Nether Essence", weight = 3, minQuantity = 1, maxQuantity = 3 },
        { id = "eternal_essence", name = "Eternal Essence", weight = 2, minQuantity = 1, maxQuantity = 2 },

        -- Shards are intentionally rare daily outcomes.
        { id = "glimmering_shard", name = "Glimmering Shard", weight = 2, minQuantity = 1, maxQuantity = 1 },
        { id = "radiant_shard", name = "Radiant Shard", weight = 1, minQuantity = 1, maxQuantity = 1 },
        { id = "brilliant_shard", name = "Brilliant Shard", weight = 1, minQuantity = 1, maxQuantity = 1 },
    }

    local entries = {}
    for _, material in ipairs(materialDefinitions) do
        local itemRef = itemRefsByName[material.name]
        if not itemRef then
            error(("Enchanting daily rewards could not resolve material '%s'."):format(material.name), 2)
        end

        entries[#entries + 1] = {
            id = material.id,
            maxQuantity = material.maxQuantity,
            minQuantity = material.minQuantity,
            ref = itemRef,
            type = "item",
            weight = material.weight,
        }
    end

    local lootId = "e5n8c2qx"
    local definition = {
        conditions = {},
        description = "Daily Enchanting material cache. Guarantees one enchanting-material reward, weighted heavily toward dusts, with essences less common and shards rare.",
        drawCount = 1,
        entries = entries,
        icon = "interface/icons/inv_enchant_dustillusion.blp",
        id = lootId,
        items = {},
        name = "Enchanting Daily Material Cache",
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

    enchanting.version = math.max(3, math.floor(tonumber(enchanting.version) or 1))
end
