local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Recipe = {}
Recipe.__index = Recipe

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function normalizeReference(value)
    local reference = ensureString(value)
    if reference == "" then
        return nil
    end

    return reference
end

local function normalizeQuantity(value, fallback)
    return math.max(0, math.floor(tonumber(value) or fallback or 0))
end

local function normalizeLearnMode(value)
    local mode = string.lower(ensureString(value))
    if mode == "always_learned" or mode == "trainer" or mode == "book" or mode == "unavailable" then
        return mode
    end

    return "trainer"
end

local function normalizeOutput(value)
    local source = type(value) == "table" and value or {}
    local minQuantity = normalizeQuantity(source.minQuantity or source.quantity, 1)
    local maxQuantity = math.max(minQuantity, normalizeQuantity(source.maxQuantity or source.quantity, minQuantity))

    return {
        itemRef = normalizeReference(source.itemRef),
        minQuantity = math.max(1, minQuantity),
        maxQuantity = math.max(1, maxQuantity),
    }
end

local function normalizeInput(value)
    if type(value) ~= "table" then
        return nil
    end

    local kind = string.lower(ensureString(value.kind))
    if kind ~= "rpe_item" and kind ~= "tool" then
        return nil
    end

    local normalized = {
        kind = kind,
        quantity = math.max(1, normalizeQuantity(value.quantity, 1)),
    }

    normalized.itemRef = normalizeReference(value.itemRef)
    if not normalized.itemRef then
        return nil
    end

    return normalized
end

local function normalizeInputs(values)
    local normalized = {}
    for index = 1, #(values or {}) do
        local entry = normalizeInput(values[index])
        if entry then
            normalized[#normalized + 1] = entry
        end
    end
    return normalized
end

local function migrateLegacyInputs(recipe)
    local migrated = {}

    for index = 1, #(recipe and recipe.reagents or {}) do
        local reagent = recipe.reagents[index]
        local itemRef = normalizeReference(type(reagent) == "table" and (reagent.itemRef or reagent.ref) or nil)
        if itemRef then
            migrated[#migrated + 1] = {
                kind = "rpe_item",
                itemRef = itemRef,
                quantity = math.max(1, normalizeQuantity(type(reagent) == "table" and reagent.quantity or nil, 1)),
            }
        end
    end

    return migrated
end

local function migrateLegacyOutput(recipe)
    local result = type(recipe) == "table" and recipe.results and recipe.results[1] or nil
    return normalizeOutput({
        itemRef = type(result) == "table" and (result.itemRef or result.ref) or nil,
        minQuantity = type(result) == "table" and (result.minQuantity or result.quantity) or 1,
        maxQuantity = type(result) == "table" and (result.maxQuantity or result.quantity) or 1,
    })
end

function Recipe:New(data)
    return setmetatable({
        id = nil,
        name = nil,
        description = "",
        category = "",
        learnMode = "trainer",
        skillRef = nil,
        requiredSkillLevel = 0,
        trainerCostCopper = 0,
        output = {
            itemRef = nil,
            minQuantity = 1,
            maxQuantity = 1,
        },
        inputs = {},
        reagents = {},
        results = {},
        tags = {},
    }, Recipe):Merge(data)
end

function Recipe:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    local hasOutput = data.output ~= nil
    local hasInputs = data.inputs ~= nil
    local incomingOutput = hasOutput and data.output or nil
    local incomingInputs = hasInputs and data.inputs or nil

    for key, value in pairs(data) do
        if key ~= "output" and key ~= "inputs" then
            self[key] = value
        end
    end

    if self.name ~= nil then
        self.name = ensureString(self.name)
    end
    self.description = ""
    self.category = ""
    self.learnMode = normalizeLearnMode(self.learnMode)
    self.skillRef = normalizeReference(self.skillRef)
    self.requiredSkillLevel = math.max(0, normalizeQuantity(self.requiredSkillLevel, 0))
    self.trainerCostCopper = math.max(0, normalizeQuantity(self.trainerCostCopper, 0))
    self.output = normalizeOutput(hasOutput and incomingOutput or (self.output and self.output.itemRef and self.output or migrateLegacyOutput(self)))
    self.inputs = normalizeInputs(hasInputs and incomingInputs or (#(self.inputs or {}) > 0 and self.inputs or migrateLegacyInputs(self)))

    return self
end

function Recipe:ToTable()
    return {
        id = self.id,
        name = ensureString(self.name),
        description = "",
        category = "",
        learnMode = self.learnMode,
        skillRef = self.skillRef,
        requiredSkillLevel = self.requiredSkillLevel,
        trainerCostCopper = self.trainerCostCopper,
        output = normalizeOutput(self.output),
        inputs = normalizeInputs(self.inputs),
        reagents = self.reagents,
        results = self.results,
        tags = self.tags,
    }
end

function Recipe.FromTable(data)
    return Recipe:New(data)
end

Addon.Internal.Database.Classes.Recipe = Recipe
