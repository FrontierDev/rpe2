local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Registry = Addon.Internal.Registry or {}

local Registry = Addon.Internal.Registry
local Database = Addon.Internal.Database or {}

if Registry._lootResolverInstalled == true then
    return
end

local function parseDatasetQualifiedRef(reference)
    local normalizedReference = type(reference) == "string" and reference or ""
    if normalizedReference == "" then
        return nil, nil
    end

    local separatorIndex = string.find(normalizedReference, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = string.sub(normalizedReference, 1, separatorIndex - 1)
    local lootId = string.sub(normalizedReference, separatorIndex + 1)
    if datasetId == "" or lootId == "" then
        return nil, nil
    end

    return datasetId, lootId
end

function Registry:ResolveLootReference(lootRef)
    local datasetId, lootId = parseDatasetQualifiedRef(lootRef)
    if not datasetId or not lootId then
        return nil, nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
    if not dataset then
        return nil, nil
    end

    for index = 1, #(dataset.loot or {}) do
        local loot = dataset.loot[index]
        if loot and tostring(loot.id or "") == lootId then
            return dataset, loot
        end
    end

    return dataset, nil
end

Registry._lootResolverInstalled = true
