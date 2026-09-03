local _, Addon = ...

Addon.Data = Addon.Data or {}

local DefaultDatasets = {}
Addon.Data.DefaultDatasets = DefaultDatasets

DefaultDatasets.Definitions = {}

local PACKAGED_VERSIONS = {
    ["f82db71a"] = 1, -- _Core

    ["d7c874c4"] = 1, -- Mage
    ["b0211ab3"] = 1, -- Paladin
    ["1c1038a7"] = 1, -- Priest
    ["23d5dce2"] = 1, -- Rogue
    ["7bbb4cb9"] = 1, -- Warrior

    ["d6ffc4e2"] = 1, -- Alchemy
    ["61fdf3df"] = 1, -- Blacksmithing
    ["732368d4"] = 1, -- Enchanting
    ["072d4851"] = 1, -- Inscription
    ["4999dcec"] = 1, -- Jewelcrafting
    ["538a54a0"] = 1, -- Leatherworking
    ["3eb7e9bb"] = 1, -- Misc
    ["7259f1d3"] = 1, -- Tailoring
}

local packagedDatasetCount = 0
for _ in pairs(PACKAGED_VERSIONS) do
    packagedDatasetCount = packagedDatasetCount + 1
end

local registeredPackagedCount = 0

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

-- The checked-in dataset payloads were exported as `RPE_DATASET_V1 { ... }`.
-- That is valid Lua call syntax once the package loader supplies this function.
-- The outer payload version remains the clipboard serialization version; the
-- packaged content version used by the installer is kept separately above.
function RPE_DATASET_V1(payload)
    if type(payload) ~= "table" or type(payload.dataset) ~= "table" then
        error("Packaged RPE_DATASET_V1 payload must contain a dataset table.", 2)
    end

    local datasetId = payload.dataset.id
    local packagedVersion = PACKAGED_VERSIONS[datasetId]
    if packagedVersion == nil then
        error(("Default dataset '%s' has no packaged version."):format(tostring(datasetId)), 2)
    end

    local definition = DefaultDatasets:Register({
        version = packagedVersion,
        dataset = payload.dataset,
    })

    registeredPackagedCount = registeredPackagedCount + 1
    if registeredPackagedCount == packagedDatasetCount then
        RPE_DATASET_V1 = nil
    end

    return definition
end
