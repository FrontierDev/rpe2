local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
local engineering = type(definitions) == "table" and definitions["af503002"] or nil
local dataset = type(engineering) == "table" and engineering.dataset or nil

if type(dataset) == "table" then
    dataset.loot = type(dataset.loot) == "table" and dataset.loot or {}

    local itemRefsByName = {}
    for datasetId, definition in pairs(type(definitions) == "table" and definitions or {}) do
        local sourceDataset = type(definition) == "table" and definition.dataset or nil
        for _, item in ipairs(type(sourceDataset) == "table" and type(sourceDataset.items) == "table" and sourceDataset.items or {}) do
            local itemId = tostring(item and item.id or "")
            local itemName = tostring(item and item.name or "")
            if itemId ~= "" and itemName ~= "" then
                itemRefsByName[itemName] = ("%s:%s"):format(tostring(datasetId), itemId)
            end
        end
    end

    local materialDefinitions = {
        { id = "copper_bar", name = "Copper Bar", weight = 20, minQuantity = 6, maxQuantity = 10 },
        { id = "rough_stone", name = "Rough Stone", weight = 20, minQuantity = 6, maxQuantity = 10 },
        { id = "bronze_bar", name = "Bronze Bar", weight = 18, minQuantity = 6, maxQuantity = 10 },
        { id = "coarse_stone", name = "Coarse Stone", weight = 18, minQuantity = 6, maxQuantity = 10 },
        { id = "iron_bar", name = "Iron Bar", weight = 16, minQuantity = 5, maxQuantity = 8 },
        { id = "heavy_stone", name = "Heavy Stone", weight = 16, minQuantity = 5, maxQuantity = 8 },
        { id = "steel_bar", name = "Steel Bar", weight = 14, minQuantity = 4, maxQuantity = 7 },
        { id = "solid_stone", name = "Solid Stone", weight = 14, minQuantity = 4, maxQuantity = 7 },
        { id = "mithril_bar", name = "Mithril Bar", weight = 12, minQuantity = 4, maxQuantity = 7 },
        { id = "dense_stone", name = "Dense Stone", weight = 12, minQuantity = 4, maxQuantity = 7 },
        { id = "thorium_bar", name = "Thorium Bar", weight = 10, minQuantity = 3, maxQuantity = 5 },
        { id = "silver_bar", name = "Silver Bar", weight = 4, minQuantity = 1, maxQuantity = 2 },
        { id = "gold_bar", name = "Gold Bar", weight = 3, minQuantity = 1, maxQuantity = 2 },
        { id = "truesilver_bar", name = "Truesilver Bar", weight = 2, minQuantity = 1, maxQuantity = 2 },
        { id = "dark_iron_bar", name = "Dark Iron Bar", weight = 1, minQuantity = 1, maxQuantity = 2 },
        { id = "arcanite_bar", name = "Arcanite Bar", weight = 1, minQuantity = 1, maxQuantity = 1 },
    }

    local entries = {}
    for _, material in ipairs(materialDefinitions) do
        local itemRef = itemRefsByName[material.name]
        if not itemRef then
            error(("Engineering daily rewards could not resolve material '%s'."):format(material.name), 2)
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

    local lootId = "n6r3k8vz"
    local definition = {
        conditions = {},
        description = "Daily Engineering material cache. Guarantees one explicitly weighted metal bar or mining stone reward, with common low-tier materials more frequent and valuable high-tier bars progressively rarer.",
        drawCount = 1,
        entries = entries,
        icon = "interface/icons/inv_gizmo_03.blp",
        id = lootId,
        items = {},
        name = "Engineering Daily Material Cache",
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

    engineering.version = math.max(29, math.floor(tonumber(engineering.version) or 1))
end
