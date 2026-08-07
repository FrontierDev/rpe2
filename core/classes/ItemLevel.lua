local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local ItemLevel = {}

local QUALITY_TRANSFORMS = {
    uncommon = { offset = 9.8, scale = 1.21 },
    rare = { offset = 4.2, scale = 1.42 },
    epic = { offset = -11.2, scale = 1.64 },
    legendary = { offset = -21.7, scale = 1.86 },
}

local RARITY_FALLBACK_BONUSES = {
    poor = 0,
    common = 0,
    uncommon = 5,
    rare = 10,
    epic = 20,
    legendary = 30,
}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function getAverageDamagePerTurn(item)
    local damageMode = ensureString(item and item.damageMode)
    if damageMode == "range" then
        local minimum = math.max(0, tonumber(item and item.minDamagePerTurn) or 0)
        local maximum = math.max(minimum, tonumber(item and item.maxDamagePerTurn) or 0)
        return (minimum + maximum) * 0.5
    end

    local fixedDamage = math.max(0, tonumber(item and item.damagePerTurn) or 0)
    if fixedDamage > 0 then
        return fixedDamage
    end

    local minimum = math.max(0, tonumber(item and item.minDamagePerTurn) or 0)
    local maximum = math.max(minimum, tonumber(item and item.maxDamagePerTurn) or 0)
    if maximum > 0 then
        return (minimum + maximum) * 0.5
    end

    return 0
end

local function parseSourceStatRef(reference)
    local dependencies = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Dependecies or {}
    if type(dependencies.ParseSourceStatRef) == "function" then
        return dependencies.ParseSourceStatRef(reference)
    end

    local datasetId, statId = tostring(reference or ""):match("^([^:]+):(.+)$")
    return datasetId, statId
end

local function resolveStatDefinition(sourceStatRef)
    if type(sourceStatRef) ~= "string" or sourceStatRef == "" then
        return nil
    end

    local datasetId, statId = parseSourceStatRef(sourceStatRef)
    if not datasetId or not statId then
        return nil
    end

    local database = Addon.Internal and Addon.Internal.Database or {}
    local dataset = type(database.GetDatasetByID) == "function" and database.GetDatasetByID(datasetId) or nil
    local stats = dataset and dataset.stats or nil
    if type(stats) ~= "table" then
        return nil
    end

    for index = 1, #stats do
        local stat = stats[index]
        if type(stat) == "table" and tostring(stat.id or "") == statId then
            return stat
        end
    end

    return nil
end

local function calculateWeightedItemLevel(item)
    local totalPow = 0

    for index = 1, #((item and item.stats) or {}) do
        local entry = item.stats[index]
        local amount = math.max(0, tonumber(entry and entry.value) or 0)
        local stat = resolveStatDefinition(entry and entry.sourceStatRef)
        local weight = tonumber(stat and stat.itemLevelWeight) or 0
        if amount > 0 and weight ~= 0 then
            totalPow = totalPow + (math.abs(amount * weight) ^ 1.5)
        end
    end

    local itemValue = totalPow > 0 and (totalPow ^ (2 / 3)) or 0
    if itemValue <= 0 then
        return 0
    end

    local quality = string.lower(ensureString(item and item.quality))
    local transform = QUALITY_TRANSFORMS[quality]
    local ilvlFloat = itemValue
    if transform then
        ilvlFloat = (itemValue + transform.offset) / transform.scale
    end

    return math.max(0, math.floor(ilvlFloat + 0.5))
end

local function calculateFallbackItemLevel(item)
    local level = 1 + (RARITY_FALLBACK_BONUSES[string.lower(ensureString(item and item.quality))] or 0)
    if ensureString(item and item.itemType) == "weapon" then
        level = level + math.floor(getAverageDamagePerTurn(item) * 0.5)
    end

    return math.max(1, math.floor(level + 0.5))
end

function ItemLevel.CalculateForItem(item)
    if type(item) ~= "table" then
        return 0
    end

    local itemType = ensureString(item.itemType)
    if itemType ~= "weapon" and itemType ~= "armor" then
        return 0
    end

    local weighted = calculateWeightedItemLevel(item)
    if weighted > 0 then
        return weighted
    end

    return calculateFallbackItemLevel(item)
end

Addon.Internal.Database.Classes.ItemLevel = ItemLevel

return ItemLevel
