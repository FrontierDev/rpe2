local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Database = Addon.Internal.Database
local Loot = Addon.Internal.Database.Classes.Loot
local DATASET_SCHEMA_VERSION = 23

if type(Database) ~= "table" or Database._datasetSchema23Installed == true then
    return
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end
    return copy
end

local function normalizeLootRecord(record)
    if type(record) ~= "table"
        or type(Loot) ~= "table"
        or type(Loot.FromTable) ~= "function"
        or type(Loot.ToTable) ~= "function"
    then
        return record
    end

    local normalized = Loot.ToTable(Loot.FromTable(deepCopy(record)))
    if type(normalized) ~= "table" then
        return record
    end

    -- Preserve unknown imported fields while replacing canonical Loot fields with
    -- the schema-23 normalization result.
    for key, value in pairs(normalized) do
        record[key] = value
    end
    return record
end

local function normalizeLootCollections(root)
    if type(root) ~= "table" then
        return root
    end

    for _, dataset in pairs(type(root.datasets) == "table" and root.datasets or {}) do
        if type(dataset) == "table" and type(dataset.loot) == "table" then
            for index = 1, #dataset.loot do
                if type(dataset.loot[index]) == "table" then
                    normalizeLootRecord(dataset.loot[index])
                end
            end
        end
    end

    root._schema = math.max(tonumber(root._schema) or 0, DATASET_SCHEMA_VERSION)
    return root
end

normalizeLootCollections(rawget(_G, "RPEngineDatasetDB"))

local baseEnsureDatasets = Database.EnsureDatasets
function Database.EnsureDatasets(...)
    local root = type(baseEnsureDatasets) == "function"
        and baseEnsureDatasets(...)
        or rawget(_G, "RPEngineDatasetDB")
    return normalizeLootCollections(root)
end

Database.DatasetSchemaVersion = DATASET_SCHEMA_VERSION
Database._datasetSchema23Installed = true

if type(Database.Dependecies) == "table"
    and type(Database.Dependecies.RecomputeAllDatasetDependencies) == "function"
then
    Database.Dependecies.RecomputeAllDatasetDependencies()
end
