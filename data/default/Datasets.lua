local _, Addon = ...

Addon.Data = Addon.Data or {}

local DefaultDatasets = {}
Addon.Data.DefaultDatasets = DefaultDatasets

DefaultDatasets.Definitions = {}

-- Ownership migrated from the legacy built-ins. Keeping this explicit makes a
-- future content edit fail validation instead of silently turning one of these
-- race/class traits back into an unowned manual trait.
local REQUIRED_TRAIT_OWNERSHIP = {
    { datasetId = "f82db71a", collection = "races", ownerId = "v17z463g", field = "traitRefs", traitRef = "f82db71a:dm2h660e" },
    { datasetId = "23d5dce2", collection = "classes", ownerId = "ta9uh9xw", field = "passiveTraitRefs", traitRef = "23d5dce2:z9yfqvhy" },
    { datasetId = "23d5dce2", collection = "classes", ownerId = "ta9uh9xw", field = "passiveTraitRefs", traitRef = "23d5dce2:58pob6kr" },
    { datasetId = "7bbb4cb9", collection = "classes", ownerId = "wvirv9um", field = "talentTraitRefs", traitRef = "7bbb4cb9:duukevtq" },
    { datasetId = "7bbb4cb9", collection = "classes", ownerId = "wvirv9um", field = "talentTraitRefs", traitRef = "7bbb4cb9:r73vv899" },
    { datasetId = "7bbb4cb9", collection = "classes", ownerId = "wvirv9um", field = "talentTraitRefs", traitRef = "7bbb4cb9:0ncx0gfs" },
    { datasetId = "7bbb4cb9", collection = "classes", ownerId = "wvirv9um", field = "talentTraitRefs", traitRef = "7bbb4cb9:a8x4ee34" },
}

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

function DefaultDatasets:ValidateTraitOwnership()
    local traitsByRef = {}
    for datasetId, definition in pairs(self.Definitions) do
        local dataset = definition and definition.dataset or {}
        for index = 1, #(dataset.traits or {}) do
            local trait = dataset.traits[index]
            if trait and trait.id then
                traitsByRef[tostring(datasetId) .. ":" .. tostring(trait.id)] = trait
            end
        end
    end

    local function requireTrait(reference, owner)
        if type(reference) ~= "string" or reference == "" or not traitsByRef[reference] then
            return nil, ("%s references missing trait '%s'."):format(owner, tostring(reference))
        end
        return true
    end

    for datasetId, definition in pairs(self.Definitions) do
        local dataset = definition and definition.dataset or {}
        for index = 1, #(dataset.races or {}) do
            local race = dataset.races[index]
            for traitIndex = 1, #(race and race.traitRefs or {}) do
                local ok, message = requireTrait(race.traitRefs[traitIndex], ("Race %s"):format(tostring(race.id or index)))
                if not ok then return false, message end
            end
        end
        for index = 1, #(dataset.classes or {}) do
            local class = dataset.classes[index]
            if type(class and class.traitRefs) == "table" then
                return false, ("Class %s still uses legacy traitRefs."):format(tostring(class.id or index))
            end
            local passiveRefs, talentRefs = class and class.passiveTraitRefs or {}, class and class.talentTraitRefs or {}
            local passiveLookup = {}
            for traitIndex = 1, #passiveRefs do
                local reference = passiveRefs[traitIndex]
                local ok, message = requireTrait(reference, ("Class %s passive"):format(tostring(class.id or index)))
                if not ok then return false, message end
                if passiveLookup[reference] then return false, ("Class %s duplicates passive trait '%s'."):format(tostring(class.id or index), reference) end
                passiveLookup[reference] = true
            end
            for traitIndex = 1, #talentRefs do
                local reference = talentRefs[traitIndex]
                local ok, message = requireTrait(reference, ("Class %s talent"):format(tostring(class.id or index)))
                if not ok then return false, message end
                if passiveLookup[reference] then return false, ("Class %s assigns '%s' as both passive and talent."):format(tostring(class.id or index), reference) end
            end
        end
        for index = 1, #(dataset.traits or {}) do
            local trait = dataset.traits[index]
            if trait and (trait.isClass ~= nil or trait.isRacial ~= nil or trait.isTalent ~= nil) then
                return false, ("Trait %s retains deprecated ownership flags."):format(tostring(trait.id or index))
            end
        end
    end

    for index = 1, #REQUIRED_TRAIT_OWNERSHIP do
        local requirement = REQUIRED_TRAIT_OWNERSHIP[index]
        local dataset = self.Definitions[requirement.datasetId] and self.Definitions[requirement.datasetId].dataset or nil
        local owner = nil
        for ownerIndex = 1, #(dataset and dataset[requirement.collection] or {}) do
            local candidate = dataset[requirement.collection][ownerIndex]
            if candidate and candidate.id == requirement.ownerId then owner = candidate; break end
        end
        local found = false
        for refIndex = 1, #(owner and owner[requirement.field] or {}) do
            if owner[requirement.field][refIndex] == requirement.traitRef then found = true; break end
        end
        if not found then
            return false, ("Required ownership is missing: %s on %s %s."):format(requirement.traitRef, requirement.collection, requirement.ownerId)
        end
    end
    return true
end
