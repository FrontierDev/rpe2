local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
local tailoring = type(definitions) == "table" and definitions["7259f1d3"] or nil
local dataset = type(tailoring) == "table" and tailoring.dataset or nil

if type(dataset) == "table" then
    dataset.loot = type(dataset.loot) == "table" and dataset.loot or {}

    local lootId = "q8m2v7kc"
    local exists = false
    for index = 1, #dataset.loot do
        local loot = dataset.loot[index]
        if type(loot) == "table" and tostring(loot.id or "") == lootId then
            exists = true
            break
        end
    end

    if not exists then
        dataset.loot[#dataset.loot + 1] = {
            conditions = {},
            description = "Daily Tailoring material cache. Guarantees one cloth reward, weighted toward ordinary cloth with rare Felcloth and Mooncloth outcomes.",
            drawCount = 1,
            entries = {
                {
                    id = "linen",
                    maxQuantity = 10,
                    minQuantity = 6,
                    ref = "7259f1d3:agzskvec",
                    type = "item",
                    weight = 20,
                },
                {
                    id = "wool",
                    maxQuantity = 10,
                    minQuantity = 6,
                    ref = "7259f1d3:1wssn0qp",
                    type = "item",
                    weight = 18,
                },
                {
                    id = "silk",
                    maxQuantity = 8,
                    minQuantity = 5,
                    ref = "7259f1d3:jt6ktqiu",
                    type = "item",
                    weight = 16,
                },
                {
                    id = "mageweave",
                    maxQuantity = 7,
                    minQuantity = 4,
                    ref = "7259f1d3:edth2zu1",
                    type = "item",
                    weight = 14,
                },
                {
                    id = "runecloth",
                    maxQuantity = 7,
                    minQuantity = 4,
                    ref = "7259f1d3:dx7zh3l2",
                    type = "item",
                    weight = 12,
                },
                {
                    id = "felcloth",
                    maxQuantity = 2,
                    minQuantity = 1,
                    ref = "7259f1d3:8dc72367",
                    type = "item",
                    weight = 4,
                },
                {
                    id = "mooncloth",
                    maxQuantity = 1,
                    minQuantity = 1,
                    ref = "7259f1d3:xnx0kwlv",
                    type = "item",
                    weight = 1,
                },
            },
            id = lootId,
            items = {},
            name = "Tailoring Daily Cloth Cache",
            tags = {},
        }
    end

    tailoring.version = math.max(8, math.floor(tonumber(tailoring.version) or 1))
end
