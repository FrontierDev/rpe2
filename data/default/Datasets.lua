local _, Addon = ...

Addon.Data = Addon.Data or {}

local DefaultDatasets = {}
Addon.Data.DefaultDatasets = DefaultDatasets

DefaultDatasets.Definitions = {}

local function isPositiveInteger(value)
    return type(value) == "number"
        and value > 0
        and value == math.floor(value)
end

function DefaultDatasets:Register(definition)
    if type(definition) ~= "table" then
        error("Default dataset definition must be a table.", 2)
    end

    local dataset = definition.dataset
    if type(dataset) ~= "table" then
        error("Default dataset definition must contain a dataset table.", 2)
    end

    local datasetId = dataset.id
    if type(datasetId) ~= "string" or datasetId == "" then
        error("Default dataset must have a non-empty string id.", 2)
    end

    if not isPositiveInteger(definition.version) then
        error(("Default dataset '%s' must have a positive integer packaged version."):format(datasetId), 2)
    end

    if self.Definitions[datasetId] ~= nil then
        error(("Default dataset '%s' is already registered."):format(datasetId), 2)
    end

    self.Definitions[datasetId] = definition
    return definition
end
