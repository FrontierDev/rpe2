local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
local alchemy = type(definitions) == "table" and definitions["d6ffc4e2"] or nil
local dataset = type(alchemy) == "table" and alchemy.dataset or nil

if type(dataset) == "table" then
    dataset.loot = type(dataset.loot) == "table" and dataset.loot or {}

    local itemRefsByName = {}
    for _, item in ipairs(type(dataset.items) == "table" and dataset.items or {}) do
        local itemId = tostring(item and item.id or "")
        local itemName = tostring(item and item.name or "")
        if itemId ~= "" and itemName ~= "" then
            itemRefsByName[itemName] = ("d6ffc4e2:%s"):format(itemId)
        end
    end

    local materialDefinitions = {
        -- Low-level herbs.
        { id = "peacebloom", name = "Peacebloom", weight = 10, minQuantity = 6, maxQuantity = 10 },
        { id = "silverleaf", name = "Silverleaf", weight = 10, minQuantity = 6, maxQuantity = 10 },
        { id = "earthroot", name = "Earthroot", weight = 10, minQuantity = 6, maxQuantity = 10 },
        { id = "mageroyal", name = "Mageroyal", weight = 10, minQuantity = 6, maxQuantity = 10 },
        { id = "briarthorn", name = "Briarthorn", weight = 10, minQuantity = 6, maxQuantity = 10 },
        { id = "swiftthistle", name = "Swiftthistle", weight = 10, minQuantity = 6, maxQuantity = 10 },

        -- Mid-level herbs.
        { id = "stranglekelp", name = "Stranglekelp", weight = 8, minQuantity = 5, maxQuantity = 8 },
        { id = "bruiseweed", name = "Bruiseweed", weight = 8, minQuantity = 5, maxQuantity = 8 },
        { id = "wild_steelbloom", name = "Wild Steelbloom", weight = 8, minQuantity = 5, maxQuantity = 8 },
        { id = "grave_moss", name = "Grave Moss", weight = 8, minQuantity = 5, maxQuantity = 8 },
        { id = "kingsblood", name = "Kingsblood", weight = 8, minQuantity = 5, maxQuantity = 8 },
        { id = "liferoot", name = "Liferoot", weight = 8, minQuantity = 5, maxQuantity = 8 },

        -- Upper-mid-level herbs.
        { id = "fadeleaf", name = "Fadeleaf", weight = 6, minQuantity = 4, maxQuantity = 7 },
        { id = "goldthorn", name = "Goldthorn", weight = 6, minQuantity = 4, maxQuantity = 7 },
        { id = "khadgars_whisker", name = "Khadgar's Whisker", weight = 6, minQuantity = 4, maxQuantity = 7 },
        { id = "wintersbite", name = "Wintersbite", weight = 6, minQuantity = 4, maxQuantity = 7 },

        -- High-level herbs.
        { id = "firebloom", name = "Firebloom", weight = 4, minQuantity = 3, maxQuantity = 5 },
        { id = "purple_lotus", name = "Purple Lotus", weight = 4, minQuantity = 3, maxQuantity = 5 },
        { id = "arthas_tears", name = "Arthas' Tears", weight = 4, minQuantity = 3, maxQuantity = 5 },
        { id = "sungrass", name = "Sungrass", weight = 4, minQuantity = 3, maxQuantity = 5 },
        { id = "blindweed", name = "Blindweed", weight = 4, minQuantity = 3, maxQuantity = 5 },
        { id = "ghost_mushroom", name = "Ghost Mushroom", weight = 4, minQuantity = 3, maxQuantity = 5 },

        -- Endgame gathering herbs. Black Lotus and Bloodvine are intentionally excluded.
        { id = "gromsblood", name = "Gromsblood", weight = 2, minQuantity = 2, maxQuantity = 4 },
        { id = "golden_sansam", name = "Golden Sansam", weight = 2, minQuantity = 2, maxQuantity = 4 },
        { id = "dreamfoil", name = "Dreamfoil", weight = 2, minQuantity = 2, maxQuantity = 4 },
        { id = "mountain_silversage", name = "Mountain Silversage", weight = 2, minQuantity = 2, maxQuantity = 4 },
        { id = "plaguebloom", name = "Plaguebloom", weight = 2, minQuantity = 2, maxQuantity = 4 },
        { id = "icecap", name = "Icecap", weight = 2, minQuantity = 2, maxQuantity = 4 },
    }

    local entries = {}
    for _, material in ipairs(materialDefinitions) do
        local itemRef = itemRefsByName[material.name]
        if not itemRef then
            error(("Alchemy daily rewards could not resolve herb '%s'."):format(material.name), 2)
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

    local lootId = "a6h3r8vk"
    local definition = {
        conditions = {},
        description = "Daily Alchemy herb cache. Guarantees one herb reward, weighted toward lower-tier gathering herbs with smaller quantities and lower odds for endgame herbs. Black Lotus and Bloodvine are excluded.",
        drawCount = 1,
        entries = entries,
        icon = "interface/icons/inv_misc_herb_dreamfoil.blp",
        id = lootId,
        items = {},
        name = "Alchemy Daily Herb Cache",
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

    alchemy.version = math.max(28, math.floor(tonumber(alchemy.version) or 1))
end
