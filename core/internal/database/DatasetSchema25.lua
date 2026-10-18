local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Database = Addon.Internal.Database
local ItemSet = Addon.Internal.Database.Classes.ItemSet
local DATASET_SCHEMA_VERSION = 25

if type(Database) ~= "table" or Database._datasetSchema25Installed == true then
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

local function normalizeItemSetRecord(record, index)
    if type(record) ~= "table"
        or type(ItemSet) ~= "table"
        or type(ItemSet.FromTable) ~= "function"
    then
        return record
    end

    local itemSet = ItemSet.FromTable(deepCopy(record))
    local normalized = itemSet and type(itemSet.ToTable) == "function"
        and itemSet:ToTable()
        or nil
    if type(normalized) ~= "table" then
        return record
    end

    -- Preserve unknown imported fields while replacing canonical Item Set
    -- fields with the schema-25 normalization result.
    for key, value in pairs(normalized) do
        record[key] = value
    end
    if tostring(record.id or "") == "" then
        record.id = ("item_set_migrated_%s"):format(tostring(index or 1))
    end
    return record
end

local function normalizeDatasetItemSets(dataset)
    if type(dataset) ~= "table" or type(dataset.itemSets) ~= "table" then
        return dataset
    end

    for key, itemSetRecord in pairs(dataset.itemSets) do
        if type(itemSetRecord) == "table" then
            dataset.itemSets[key] = normalizeItemSetRecord(itemSetRecord, key)
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

local function normalizeExistingItemSets(root)
    if type(root) ~= "table" then
        return root
    end

    for _, dataset in pairs(type(root.datasets) == "table" and root.datasets or {}) do
        normalizeDatasetItemSets(dataset)
    end
    return advanceDatasetSchema(root)
end

local normalizedRoot = normalizeExistingItemSets(rawget(_G, "RPEngineDatasetDB"))

local baseEnsureDatasets = Database.EnsureDatasets
function Database.EnsureDatasets(...)
    local root = type(baseEnsureDatasets) == "function"
        and baseEnsureDatasets(...)
        or rawget(_G, "RPEngineDatasetDB")

    if root ~= normalizedRoot then
        normalizedRoot = normalizeExistingItemSets(root)
    else
        advanceDatasetSchema(root)
    end
    return root
end

local baseImportDataset = Database.ImportDataset
if type(baseImportDataset) == "function" then
    function Database.ImportDataset(...)
        local dataset, err = baseImportDataset(...)
        if type(dataset) ~= "table" then
            return dataset, err
        end

        normalizeDatasetItemSets(dataset)
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
Database._datasetSchema25Installed = true

if type(Database.Dependecies) == "table"
    and type(Database.Dependecies.RecomputeAllDatasetDependencies) == "function"
then
    Database.Dependecies.RecomputeAllDatasetDependencies()
end
