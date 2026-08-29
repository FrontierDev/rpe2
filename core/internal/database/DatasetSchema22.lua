local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}

local Database = Addon.Internal.Database
local DATASET_SCHEMA_VERSION = 22

if type(Database) ~= "table" or Database._datasetSchema22Installed == true then
    return
end

local function advanceDatasetSchema(root)
    if type(root) == "table" then
        root._schema = math.max(tonumber(root._schema) or 0, DATASET_SCHEMA_VERSION)
    end
    return root
end

-- Unit normalization now drops the legacy Resource.perPlayer field. Advance the
-- persisted Dataset marker so rewritten/exported Units use the schema-22 shape.
advanceDatasetSchema(rawget(_G, "RPEngineDatasetDB"))

local baseEnsureDatasets = Database.EnsureDatasets
function Database.EnsureDatasets(...)
    local root = type(baseEnsureDatasets) == "function" and baseEnsureDatasets(...) or rawget(_G, "RPEngineDatasetDB")
    return advanceDatasetSchema(root)
end

Database.DatasetSchemaVersion = DATASET_SCHEMA_VERSION
Database._datasetSchema22Installed = true
