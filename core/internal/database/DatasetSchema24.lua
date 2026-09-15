local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Database = Addon.Internal.Database
local Item = Addon.Internal.Database.Classes.Item
local DATASET_SCHEMA_VERSION = 24

if type(Database) ~= "table" or Database._datasetSchema24Installed == true then
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

local function normalizeItemRecord(record)
    if type(record) ~= "table"
        or type(Item) ~= "table"
        or type(Item.FromTable) ~= "function"
    then
        return record
    end

    local normalizedItem = Item.FromTable(deepCopy(record))
    local normalized = normalizedItem and type(normalizedItem.ToTable) == "function"
        and normalizedItem:ToTable()
        or nil
    if type(normalized) ~= "table" then
        return record
    end

    -- Preserve unknown imported fields while replacing canonical Item fields with
    -- the schema-24 normalization result. Explicitly assign useSpellRef so stale
    -- references on unsupported item types are removed when normalization returns nil.
    for key, value in pairs(normalized) do
        record[key] = value
    end
    record.useSpellRef = normalized.useSpellRef
    return record
end

local function normalizeDatasetItems(dataset)
    if type(dataset) ~= "table" or type(dataset.items) ~= "table" then
        return dataset
    end

    for key, itemRecord in pairs(dataset.items) do
        if type(itemRecord) == "table" then
            dataset.items[key] = normalizeItemRecord(itemRecord)
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

local function normalizeExistingItems(root)
    if type(root) ~= "table" then
        return root
    end

    for _, dataset in pairs(type(root.datasets) == "table" and root.datasets or {}) do
        normalizeDatasetItems(dataset)
    end
    return advanceDatasetSchema(root)
end

-- Existing saved datasets were initialized before Item.lua exposed useSpellRef,
-- so run schema-24 Item normalization once now that the class is available.
local normalizedRoot = normalizeExistingItems(rawget(_G, "RPEngineDatasetDB"))

local baseEnsureDatasets = Database.EnsureDatasets
function Database.EnsureDatasets(...)
    local root = type(baseEnsureDatasets) == "function"
        and baseEnsureDatasets(...)
        or rawget(_G, "RPEngineDatasetDB")

    -- A replaced SavedVariables root needs one normalization pass. Normal reads
    -- only advance the marker and do not rescan every Item.
    if root ~= normalizedRoot then
        normalizedRoot = normalizeExistingItems(root)
    else
        advanceDatasetSchema(root)
    end
    return root
end

-- Full-dataset import uses the generic dataset-record normalization path rather
-- than per-entry Item class normalization, so normalize Items at this boundary.
local baseImportDataset = Database.ImportDataset
if type(baseImportDataset) == "function" then
    function Database.ImportDataset(...)
        local dataset, err = baseImportDataset(...)
        if type(dataset) ~= "table" then
            return dataset, err
        end

        normalizeDatasetItems(dataset)
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
Database._datasetSchema24Installed = true

if type(Database.Dependecies) == "table"
    and type(Database.Dependecies.RecomputeAllDatasetDependencies) == "function"
then
    Database.Dependecies.RecomputeAllDatasetDependencies()
end
