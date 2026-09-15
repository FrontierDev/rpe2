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

local function normalizeDatasetLoot(dataset)
    if type(dataset) ~= "table" or type(dataset.loot) ~= "table" then
        return dataset
    end

    for key, lootRecord in pairs(dataset.loot) do
        if type(lootRecord) == "table" then
            dataset.loot[key] = normalizeLootRecord(lootRecord)
        end
    end
    return dataset
end

local function advanceDatasetSchema(root)
    if type(root) == "table" then
        root._schema = math.max(tonumber(root._schema) or 0, DATASET_SCHEMA_VERSION)
    end
    return root
end

local function normalizeExistingLoot(root)
    if type(root) ~= "table" then
        return root
    end

    for _, dataset in pairs(type(root.datasets) == "table" and root.datasets or {}) do
        normalizeDatasetLoot(dataset)
    end
    return advanceDatasetSchema(root)
end

-- Existing saved datasets were initialized before Loot.lua was loaded, so run
-- the schema-23 Loot normalization once now that the class is available.
local normalizedRoot = normalizeExistingLoot(rawget(_G, "RPEngineDatasetDB"))

local baseEnsureDatasets = Database.EnsureDatasets
function Database.EnsureDatasets(...)
    local root = type(baseEnsureDatasets) == "function"
        and baseEnsureDatasets(...)
        or rawget(_G, "RPEngineDatasetDB")

    -- A replaced SavedVariables root needs one normalization pass. Normal reads
    -- only advance the marker and do not rescan every Loot Table.
    if root ~= normalizedRoot then
        normalizedRoot = normalizeExistingLoot(root)
    else
        advanceDatasetSchema(root)
    end
    return root
end

-- Full-dataset import uses normalizeDatasetRecord rather than per-entry class
-- normalization, so normalize the imported Loot collection at this boundary.
local baseImportDataset = Database.ImportDataset
if type(baseImportDataset) == "function" then
    function Database.ImportDataset(...)
        local dataset, err = baseImportDataset(...)
        if type(dataset) ~= "table" then
            return dataset, err
        end

        normalizeDatasetLoot(dataset)
        if not (Database.IsDatasetImportTransactionActive and Database.IsDatasetImportTransactionActive())
            and type(Database.Dependecies) == "table"
            and type(Database.Dependecies.RecomputeDatasetDependencies) == "function"
        then
            Database.Dependecies.RecomputeDatasetDependencies(dataset.id)
        end
        return dataset, err
    end
end

Database.DatasetSchemaVersion = DATASET_SCHEMA_VERSION
Database._datasetSchema23Installed = true

if type(Database.Dependecies) == "table"
    and type(Database.Dependecies.RecomputeAllDatasetDependencies) == "function"
then
    Database.Dependecies.RecomputeAllDatasetDependencies()
end
