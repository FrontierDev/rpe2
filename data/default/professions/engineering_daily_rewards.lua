local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
local engineering = type(definitions) == "table" and definitions["af503002"] or nil
local dataset = type(engineering) == "table" and engineering.dataset or nil

local function getRewardBand(itemLevel)
    itemLevel = math.max(0, math.floor(tonumber(itemLevel) or 0))

    if itemLevel <= 10 then
        return 20, 6, 10
    elseif itemLevel <= 20 then
        return 18, 6, 10
    elseif itemLevel <= 30 then
        return 16, 5, 8
    elseif itemLevel <= 40 then
        return 14, 4, 7
    elseif itemLevel <= 50 then
        return 10, 3, 5
    elseif itemLevel <= 60 then
        return 6, 2, 4
    end

    return 3, 1, 2
end

if type(dataset) == "table" then
    dataset.loot = type(dataset.loot) == "table" and dataset.loot or {}

    local materials = {}
    for _, item in ipairs(type(dataset.items) == "table" and dataset.items or {}) do
        local itemId = tostring(item and item.id or "")
        local itemName = tostring(item and item.name or "")
        if itemId ~= "" and itemName ~= "" and tostring(item.itemType or "") == "material" then
            materials[#materials + 1] = item
        end
    end

    table.sort(materials, function(left, right)
        local leftLevel = tonumber(left and left.itemLevel) or 0
        local rightLevel = tonumber(right and right.itemLevel) or 0
        if leftLevel ~= rightLevel then
            return leftLevel < rightLevel
        end
        return tostring(left and left.name or "") < tostring(right and right.name or "")
    end)

    local entries = {}
    for _, item in ipairs(materials) do
        local weight, minQuantity, maxQuantity = getRewardBand(item.itemLevel)
        local maxStackSize = math.max(1, math.floor(tonumber(item.maxStackSize) or maxQuantity))
        maxQuantity = math.min(maxQuantity, maxStackSize)
        minQuantity = math.min(minQuantity, maxQuantity)

        entries[#entries + 1] = {
            id = tostring(item.id),
            maxQuantity = maxQuantity,
            minQuantity = minQuantity,
            ref = ("af503002:%s"):format(tostring(item.id)),
            type = "item",
            weight = weight,
        }
    end

    if #entries == 0 then
        error("Engineering daily rewards could not resolve any Engineering material items.", 2)
    end

    local lootId = "n6r3k8vz"
    local definition = {
        conditions = {},
        description = "Daily Engineering material cache. Guarantees one Engineering material reward from the full Engineering material pool, with lower-tier components more common and higher-tier components progressively rarer.",
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
