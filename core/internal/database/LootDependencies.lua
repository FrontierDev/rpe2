local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}

local Database = Addon.Internal.Database
Database.Dependecies = Database.Dependecies or {}

local Dependecies = Database.Dependecies

if Dependecies._lootDependencyIntegrationInstalled == true then
    return
end

local baseRecomputeDatasetDependencies = Dependecies.RecomputeDatasetDependencies
local baseHandleDatasetDeleted = Dependecies.HandleDatasetDeleted
local baseHandleDatasetEntryDeleted = Dependecies.HandleDatasetEntryDeleted

local function getDatasetRoot()
    return Database.Datasets or rawget(_G or {}, "RPEngineDatasetDB")
end

local function parseQualifiedRef(reference)
    if type(Dependecies.ParseSourceStatRef) == "function" then
        return Dependecies.ParseSourceStatRef(reference)
    end

    local text = tostring(reference or "")
    local datasetId, entryId = text:match("^([^:]+):([^:]+)$")
    if datasetId == "" or entryId == "" then
        return nil, nil
    end
    return datasetId, entryId
end

local function isLootReferenceEntry(entry)
    if type(entry) ~= "table" then
        return false
    end

    local entryType = string.lower(tostring(entry.type or ""))
    return entryType == "item" or entryType == "currency"
end

local function appendLootDependencies(dataset, dependencies)
    if type(dataset) ~= "table" or type(dependencies) ~= "table" then
        return dependencies
    end

    local seen = {}
    for index = 1, #dependencies do
        local dependencyId = tostring(dependencies[index] or "")
        if dependencyId ~= "" then
            seen[dependencyId] = true
        end
    end

    for lootIndex = 1, #(dataset.loot or {}) do
        local loot = dataset.loot[lootIndex]
        for entryIndex = 1, #(type(loot) == "table" and loot.entries or {}) do
            local entry = loot.entries[entryIndex]
            if isLootReferenceEntry(entry) then
                local sourceDatasetId = parseQualifiedRef(entry.ref)
                if sourceDatasetId
                    and sourceDatasetId ~= tostring(dataset.id or "")
                    and not seen[sourceDatasetId]
                then
                    dependencies[#dependencies + 1] = sourceDatasetId
                    seen[sourceDatasetId] = true
                end
            end
        end
    end

    table.sort(dependencies, function(left, right)
        return tostring(left or "") < tostring(right or "")
    end)
    return dependencies
end

local function pruneLootReferences(dataset, deletedDatasetId, deletedRef, collectionKey)
    if type(dataset) ~= "table" then
        return false
    end

    local mutated = false
    for lootIndex = 1, #(dataset.loot or {}) do
        local loot = dataset.loot[lootIndex]
        for entryIndex = 1, #(type(loot) == "table" and loot.entries or {}) do
            local entry = loot.entries[entryIndex]
            if isLootReferenceEntry(entry) then
                local entryType = string.lower(tostring(entry.type or ""))
                local expectedCollection = entryType == "item" and "items" or "currencies"
                local matchesCollection = collectionKey == nil or collectionKey == expectedCollection
                local sourceDatasetId = parseQualifiedRef(entry.ref)
                local matchesDeleted = deletedRef ~= nil
                    and tostring(entry.ref or "") == tostring(deletedRef)
                    or (deletedDatasetId ~= nil and sourceDatasetId == tostring(deletedDatasetId))

                if matchesCollection and matchesDeleted then
                    -- Preserve the authored entry and its weight/quantity semantics so the
                    -- editor/runtime validator can report the missing reference explicitly.
                    entry.ref = nil
                    mutated = true
                end
            end
        end
    end

    return mutated
end

function Dependecies.RecomputeDatasetDependencies(datasetId)
    local dependencies = type(baseRecomputeDatasetDependencies) == "function"
        and baseRecomputeDatasetDependencies(datasetId)
        or nil
    if type(dependencies) ~= "table" then
        return dependencies
    end

    local root = getDatasetRoot()
    local dataset = type(root) == "table"
        and type(root.datasets) == "table"
        and root.datasets[tostring(datasetId or "")]
        or nil
    if not dataset then
        return dependencies
    end

    appendLootDependencies(dataset, dependencies)
    dataset.dependencies = dependencies
    return dataset.dependencies
end

function Dependecies.HandleDatasetDeleted(datasetId)
    local root = getDatasetRoot()
    local lootMutatedDatasetIds = {}

    if type(root) == "table" and type(root.datasets) == "table" then
        for currentDatasetId, dataset in pairs(root.datasets) do
            if tostring(currentDatasetId) ~= tostring(datasetId)
                and pruneLootReferences(dataset, tostring(datasetId), nil, nil)
            then
                lootMutatedDatasetIds[#lootMutatedDatasetIds + 1] = tostring(currentDatasetId)
            end
        end
    end

    local changed = type(baseHandleDatasetDeleted) == "function"
        and baseHandleDatasetDeleted(datasetId)
        or 0

    for index = 1, #lootMutatedDatasetIds do
        Dependecies.RecomputeDatasetDependencies(lootMutatedDatasetIds[index])
    end

    return math.max(tonumber(changed) or 0, #lootMutatedDatasetIds)
end

function Dependecies.HandleDatasetEntryDeleted(datasetId, collectionKey, entry)
    local deletedEntryId = type(entry) == "table" and tostring(entry.id or "") or ""
    local deletedRef = nil
    if deletedEntryId ~= "" and type(Dependecies.ComposeSourceStatRef) == "function" then
        deletedRef = Dependecies.ComposeSourceStatRef(datasetId, deletedEntryId)
    elseif deletedEntryId ~= "" then
        deletedRef = ("%s:%s"):format(tostring(datasetId or ""), deletedEntryId)
    end

    local lootMutatedDatasetIds = {}
    if deletedRef and (collectionKey == "items" or collectionKey == "currencies") then
        local root = getDatasetRoot()
        if type(root) == "table" and type(root.datasets) == "table" then
            for currentDatasetId, dataset in pairs(root.datasets) do
                if pruneLootReferences(dataset, nil, deletedRef, collectionKey) then
                    lootMutatedDatasetIds[#lootMutatedDatasetIds + 1] = tostring(currentDatasetId)
                end
            end
        end
    end

    local changed = type(baseHandleDatasetEntryDeleted) == "function"
        and baseHandleDatasetEntryDeleted(datasetId, collectionKey, entry)
        or 0

    for index = 1, #lootMutatedDatasetIds do
        Dependecies.RecomputeDatasetDependencies(lootMutatedDatasetIds[index])
    end

    return math.max(tonumber(changed) or 0, #lootMutatedDatasetIds)
end

Dependecies._lootDependencyIntegrationInstalled = true
