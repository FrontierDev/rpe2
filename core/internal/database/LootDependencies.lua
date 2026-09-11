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
local trackedRecomputes = nil

local function getDatasetRoot()
    return Database.Datasets or rawget(_G or {}, "RPEngineDatasetDB")
end

local function parseQualifiedRef(reference)
    if type(Dependecies.ParseSourceStatRef) == "function" then
        return Dependecies.ParseSourceStatRef(reference)
    end

    local text = tostring(reference or "")
    local datasetId, entryId = text:match("^([^:]+):([^:]+)$")
    if not datasetId or datasetId == "" or not entryId or entryId == "" then
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

local function iterateLootEntries(dataset, callback)
    if type(dataset) ~= "table" or type(callback) ~= "function" then
        return
    end

    for _, loot in pairs(type(dataset.loot) == "table" and dataset.loot or {}) do
        if type(loot) == "table" and type(loot.entries) == "table" then
            for _, entry in pairs(loot.entries) do
                callback(entry)
            end
        end
    end
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

    iterateLootEntries(dataset, function(entry)
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
    end)

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
    iterateLootEntries(dataset, function(entry)
        if isLootReferenceEntry(entry) then
            local entryType = string.lower(tostring(entry.type or ""))
            local expectedCollection = entryType == "item" and "items" or "currencies"
            local matchesCollection = collectionKey == nil or collectionKey == expectedCollection
            local sourceDatasetId = parseQualifiedRef(entry.ref)
            local matchesDeleted = (deletedRef ~= nil and tostring(entry.ref or "") == tostring(deletedRef))
                or (deletedDatasetId ~= nil and sourceDatasetId == tostring(deletedDatasetId))

            if matchesCollection and matchesDeleted then
                -- Preserve the authored entry and its weight/quantity semantics so the
                -- editor/runtime validator can report the missing reference explicitly.
                entry.ref = nil
                mutated = true
            end
        end
    end)

    return mutated
end

local function beginTrackingRecomputes()
    local previous = trackedRecomputes
    trackedRecomputes = {}
    return previous
end

local function finishTrackingRecomputes(previous)
    local completed = trackedRecomputes or {}
    trackedRecomputes = previous
    return completed
end

local function countKeys(values)
    local count = 0
    for _ in pairs(values or {}) do
        count = count + 1
    end
    return count
end

function Dependecies.RecomputeDatasetDependencies(datasetId)
    local normalizedDatasetId = tostring(datasetId or "")
    if trackedRecomputes and normalizedDatasetId ~= "" then
        trackedRecomputes[normalizedDatasetId] = true
    end

    local dependencies = type(baseRecomputeDatasetDependencies) == "function"
        and baseRecomputeDatasetDependencies(datasetId)
        or nil
    if type(dependencies) ~= "table" then
        return dependencies
    end

    local root = getDatasetRoot()
    local dataset = type(root) == "table"
        and type(root.datasets) == "table"
        and root.datasets[normalizedDatasetId]
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
                lootMutatedDatasetIds[tostring(currentDatasetId)] = true
            end
        end
    end

    local previousTracking = beginTrackingRecomputes()
    if type(baseHandleDatasetDeleted) == "function" then
        baseHandleDatasetDeleted(datasetId)
    end

    for currentDatasetId in pairs(lootMutatedDatasetIds) do
        Dependecies.RecomputeDatasetDependencies(currentDatasetId)
    end
    local changedDatasetIds = finishTrackingRecomputes(previousTracking)

    return countKeys(changedDatasetIds)
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
                    lootMutatedDatasetIds[tostring(currentDatasetId)] = true
                end
            end
        end
    end

    local previousTracking = beginTrackingRecomputes()
    if type(baseHandleDatasetEntryDeleted) == "function" then
        baseHandleDatasetEntryDeleted(datasetId, collectionKey, entry)
    end

    for currentDatasetId in pairs(lootMutatedDatasetIds) do
        Dependecies.RecomputeDatasetDependencies(currentDatasetId)
    end
    local changedDatasetIds = finishTrackingRecomputes(previousTracking)

    return countKeys(changedDatasetIds)
end

Dependecies._lootDependencyIntegrationInstalled = true
