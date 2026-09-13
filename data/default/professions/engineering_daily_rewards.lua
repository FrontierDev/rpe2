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

local function buildItemIndex()
    local itemsByRef = {}

    for datasetId, definition in pairs(type(definitions) == "table" and definitions or {}) do
        local sourceDataset = type(definition) == "table" and definition.dataset or nil
        for _, item in ipairs(type(sourceDataset) == "table" and type(sourceDataset.items) == "table" and sourceDataset.items or {}) do
            local itemId = tostring(item and item.id or "")
            if itemId ~= "" then
                itemsByRef[("%s:%s"):format(tostring(datasetId), itemId)] = item
            end
        end
    end

    return itemsByRef
end

local function isEligibleBaseMaterial(item)
    local name = tostring(item and item.name or "")
    return name:match(" Bar$") ~= nil or name:match(" Stone$") ~= nil
end

if type(dataset) == "table" then
    dataset.loot = type(dataset.loot) == "table" and dataset.loot or {}

    local recipesByOutputRef = {}
    for _, recipe in ipairs(type(dataset.recipes) == "table" and dataset.recipes or {}) do
        local outputRef = tostring(recipe and recipe.output and recipe.output.itemRef or "")
        if outputRef ~= "" then
            recipesByOutputRef[outputRef] = recipe
        end
    end

    local flattenedMaterials = {}
    local activeRefs = {}

    local function addFlattenedInput(itemRef, quantity)
        itemRef = tostring(itemRef or "")
        quantity = math.max(1, math.floor(tonumber(quantity) or 1))
        if itemRef == "" then
            return
        end

        local componentRecipe = recipesByOutputRef[itemRef]
        if componentRecipe then
            if activeRefs[itemRef] then
                error(("Engineering daily rewards found a cyclic recipe dependency at '%s'."):format(itemRef), 2)
            end

            activeRefs[itemRef] = true
            for _, input in ipairs(type(componentRecipe.inputs) == "table" and componentRecipe.inputs or {}) do
                if tostring(input and input.kind or "") == "rpe_item" then
                    addFlattenedInput(input.itemRef, quantity * math.max(1, math.floor(tonumber(input.quantity) or 1)))
                end
            end
            activeRefs[itemRef] = nil
            return
        end

        flattenedMaterials[itemRef] = (flattenedMaterials[itemRef] or 0) + quantity
    end

    for _, recipe in ipairs(type(dataset.recipes) == "table" and dataset.recipes or {}) do
        for _, input in ipairs(type(recipe.inputs) == "table" and recipe.inputs or {}) do
            if tostring(input and input.kind or "") == "rpe_item" then
                addFlattenedInput(input.itemRef, input.quantity)
            end
        end
    end

    local itemsByRef = buildItemIndex()
    local materialRefs = {}
    for itemRef in pairs(flattenedMaterials) do
        local item = itemsByRef[itemRef]
        if type(item) ~= "table" then
            error(("Engineering daily rewards could not resolve flattened material '%s'."):format(itemRef), 2)
        end

        if isEligibleBaseMaterial(item) then
            materialRefs[#materialRefs + 1] = itemRef
        end
    end

    table.sort(materialRefs, function(left, right)
        local leftItem = itemsByRef[left]
        local rightItem = itemsByRef[right]
        local leftLevel = tonumber(leftItem and leftItem.itemLevel) or 0
        local rightLevel = tonumber(rightItem and rightItem.itemLevel) or 0
        if leftLevel ~= rightLevel then
            return leftLevel < rightLevel
        end

        local leftName = tostring(leftItem and leftItem.name or left)
        local rightName = tostring(rightItem and rightItem.name or right)
        if leftName ~= rightName then
            return leftName < rightName
        end
        return left < right
    end)

    local entries = {}
    for _, itemRef in ipairs(materialRefs) do
        local item = itemsByRef[itemRef]
        local weight, minQuantity, maxQuantity = getRewardBand(item.itemLevel)
        local maxStackSize = math.max(1, math.floor(tonumber(item.maxStackSize) or maxQuantity))
        maxQuantity = math.min(maxQuantity, maxStackSize)
        minQuantity = math.min(minQuantity, maxQuantity)

        entries[#entries + 1] = {
            id = ("material_%s"):format(itemRef:gsub("[^%w]", "_")),
            maxQuantity = maxQuantity,
            minQuantity = minQuantity,
            ref = itemRef,
            type = "item",
            weight = weight,
        }
    end

    if #entries == 0 then
        error("Engineering daily rewards could not resolve any flattened metal bars or stone.", 2)
    end

    local lootId = "n6r3k8vz"
    local definition = {
        conditions = {},
        description = "Daily Engineering material cache. Rewards flattened metal bars and stone used by Engineering recipes, excluding crafted Engineering components and other material types.",
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

    engineering.version = math.max(28, math.floor(tonumber(engineering.version) or 1))
end
