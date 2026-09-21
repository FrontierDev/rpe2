local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
local leatherworking = type(definitions) == "table" and definitions["538a54a0"] or nil
local dataset = type(leatherworking) == "table" and leatherworking.dataset or nil

if type(dataset) == "table" then
    dataset.loot = type(dataset.loot) == "table" and dataset.loot or {}

    local itemRefsByName = {}
    for _, item in ipairs(type(dataset.items) == "table" and dataset.items or {}) do
        local itemId = tostring(item and item.id or "")
        local itemName = tostring(item and item.name or "")
        if itemId ~= "" and itemName ~= "" then
            itemRefsByName[itemName] = ("538a54a0:%s"):format(itemId)
        end
    end

    local materialDefinitions = {
        { id = "light", name = "Light Leather", weight = 20, minQuantity = 6, maxQuantity = 10 },
        { id = "medium", name = "Medium Leather", weight = 18, minQuantity = 6, maxQuantity = 10 },
        { id = "heavy", name = "Heavy Leather", weight = 16, minQuantity = 5, maxQuantity = 8 },
        { id = "thick", name = "Thick Leather", weight = 14, minQuantity = 4, maxQuantity = 7 },
        { id = "rugged", name = "Rugged Leather", weight = 12, minQuantity = 4, maxQuantity = 7 },
    }

    local entries = {}
    for _, material in ipairs(materialDefinitions) do
        local itemRef = itemRefsByName[material.name]
        if not itemRef then
            error(("Leatherworking daily rewards could not resolve material '%s'."):format(material.name), 2)
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

    local lootId = "l7w4c9px"
    local definition = {
        conditions = {},
        description = "Daily Leatherworking material cache. Guarantees one leather reward, weighted toward lower-tier ordinary leathers while retaining useful amounts of higher-tier leather.",
        drawCount = 1,
        entries = entries,
        icon = "interface/icons/inv_misc_leatherscrap_02.blp",
        id = lootId,
        items = {},
        name = "Leatherworking Daily Leather Cache",
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

    leatherworking.version = math.max(17, math.floor(tonumber(leatherworking.version) or 1))
end
