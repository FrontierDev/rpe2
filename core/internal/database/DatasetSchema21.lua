local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}

local Database = Addon.Internal.Database
local DATASET_SCHEMA_VERSION = 22

if type(Database) ~= "table" or Database._datasetSchema21Installed == true then
    return
end

local function advanceDatasetSchema(root)
    if type(root) == "table" then
        root._schema = math.max(tonumber(root._schema) or 0, DATASET_SCHEMA_VERSION)
    end
    return root
end

-- This loaded Dataset schema extension now advances through schema 22. Schema
-- 21 added Preset spell/equipment persistence; schema 22 removes canonical
-- Unit Resource.perPlayer data through Unit normalization.
advanceDatasetSchema(rawget(_G, "RPEngineDatasetDB"))

local baseEnsureDatasets = Database.EnsureDatasets
function Database.EnsureDatasets(...)
    local root = type(baseEnsureDatasets) == "function" and baseEnsureDatasets(...) or rawget(_G, "RPEngineDatasetDB")
    return advanceDatasetSchema(root)
end

Database.DatasetSchemaVersion = DATASET_SCHEMA_VERSION
Database._datasetSchema21Installed = true
