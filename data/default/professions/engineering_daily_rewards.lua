local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
local engineering = type(definitions) == "table" and definitions["af503002"] or nil
local dataset = type(engineering) == "table" and engineering.dataset or nil

if type(dataset) == "table" then
    dataset.loot = type(dataset.loot) == "table" and dataset.loot or {}

    local itemRefsByName = {}
    for _, item in ipairs(type(dataset.items) == "table" and dataset.items or {}) do
        local itemId = tostring(item and item.id or "")
        local itemName = tostring(item and item.name or "")
        if itemId ~= "" and itemName ~= "" then
            itemRefsByName[itemName] = ("af503002:%s"):format(itemId)
        end
    end

    local materialDefinitions = {
        { id = "rough_blasting_powder", name = "Rough Blasting Powder", weight = 20, minQuantity = 6, maxQuantity = 10 },
        { id = "copper_bolts", name = "Handful of Copper Bolts", weight = 18, minQuantity = 6, maxQuantity = 10 },
        { id = "copper_tube", name = "Copper Tube", weight = 16, minQuantity = 5, maxQuantity = 8 },
        { id = "copper_modulator", name = "Copper Modulator", weight = 14, minQuantity = 4, maxQuantity = 7 },
        { id = "coarse_blasting_powder", name = "Coarse Blasting Powder", weight = 12, minQuantity = 4, maxQuantity = 7 },
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
        description = "Daily Engineering material cache. Guarantees one engineering-component reward, weighted toward basic components while retaining useful quantities of more involved parts.",
        drawCount = 1,
        entries = entries,
        icon = "interface/icons/inv_gizmo_03.blp",
        id = lootId,
        items = {},
        name = "Engineering Daily Component Cache",
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

    engineering.version = math.max(14, math.floor(tonumber(engineering.version) or 1))
end
