local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
local blacksmithing = type(definitions) == "table" and definitions["61fdf3df"] or nil
local dataset = type(blacksmithing) == "table" and blacksmithing.dataset or nil

if type(dataset) == "table" then
    dataset.loot = type(dataset.loot) == "table" and dataset.loot or {}

    local itemRefsByName = {}
    for _, item in ipairs(type(dataset.items) == "table" and dataset.items or {}) do
        local itemId = tostring(item and item.id or "")
        local itemName = tostring(item and item.name or "")
        if itemId ~= "" and itemName ~= "" then
            itemRefsByName[itemName] = ("61fdf3df:%s"):format(itemId)
        end
    end

    local materialDefinitions = {
        { id = "bronze", name = "Bronze Bar", weight = 18, minQuantity = 6, maxQuantity = 10 },
        { id = "steel", name = "Steel Bar", weight = 16, minQuantity = 5, maxQuantity = 8 },
        { id = "mithril", name = "Mithril Bar", weight = 14, minQuantity = 4, maxQuantity = 7 },
        { id = "thorium", name = "Thorium Bar", weight = 12, minQuantity = 4, maxQuantity = 7 },
        { id = "silver", name = "Silver Bar", weight = 2, minQuantity = 1, maxQuantity = 2 },
        { id = "gold", name = "Gold Bar", weight = 1, minQuantity = 1, maxQuantity = 2 },
        { id = "truesilver", name = "Truesilver Bar", weight = 1, minQuantity = 1, maxQuantity = 1 },
    }

    local entries = {}
    for _, material in ipairs(materialDefinitions) do
        local itemRef = itemRefsByName[material.name]
        if not itemRef then
            error(("Blacksmithing daily rewards could not resolve material '%s'."):format(material.name), 2)
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

    local lootId = "d4p7k2ms"
    local replaced = false
    for index = 1, #dataset.loot do
        local loot = dataset.loot[index]
        if type(loot) == "table" and tostring(loot.id or "") == lootId then
            dataset.loot[index] = {
                conditions = {},
                description = "Daily Blacksmithing material cache. Guarantees one bar reward, weighted toward ordinary metal bars with uncommon precious bar outcomes.",
                drawCount = 1,
                entries = entries,
                icon = "interface/icons/inv_misc_stonetablet_05.blp",
                id = lootId,
                items = {},
                name = "Blacksmithing Daily Bar Cache",
                tags = {},
            }
            replaced = true
            break
        end
    end

    if not replaced then
        dataset.loot[#dataset.loot + 1] = {
            conditions = {},
            description = "Daily Blacksmithing material cache. Guarantees one bar reward, weighted toward ordinary metal bars with uncommon precious bar outcomes.",
            drawCount = 1,
            entries = entries,
            icon = "interface/icons/inv_misc_stonetablet_05.blp",
            id = lootId,
            items = {},
            name = "Blacksmithing Daily Bar Cache",
            tags = {},
        }
    end

    blacksmithing.version = math.max(9, math.floor(tonumber(blacksmithing.version) or 1))
end
