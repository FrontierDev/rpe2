local _, Addon = ...

local Database = Addon.Internal and Addon.Internal.Database or nil
local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil

if type(Database) == "table"
    and type(Database.SyncDefaultDatasets) == "function"
    and type(DefaultDatasets) == "table"
    and type(DefaultDatasets.Definitions) == "table"
then
    Database.SyncDefaultDatasets(DefaultDatasets.Definitions)
end
