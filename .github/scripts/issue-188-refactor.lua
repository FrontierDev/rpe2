local function readFile(path)
    local handle = assert(io.open(path, "rb"))
    local content = handle:read("*a")
    handle:close()
    return content
end

local function writeFile(path, content)
    local handle = assert(io.open(path, "wb"))
    handle:write(content)
    handle:close()
end

local function deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, nested in pairs(value) do
        result[deepCopy(key, seen)] = deepCopy(nested, seen)
    end
    return result
end

local function isIdentifier(value)
    return type(value) == "string" and value:match("^[%a_][%w_]*$") ~= nil
end

local function compareKeys(left, right)
    local leftType, rightType = type(left), type(right)
    if leftType == rightType then
        if leftType == "number" then
            return left < right
        end
        return tostring(left) < tostring(right)
    end
    return leftType < rightType
end

local function serialize(value, indent)
    indent = indent or 0
    local valueType = type(value)
    if valueType == "nil" then
        return "nil"
    elseif valueType == "boolean" then
        return value and "true" or "false"
    elseif valueType == "number" then
        return tostring(value)
    elseif valueType == "string" then
        return string.format("%q", value)
    elseif valueType ~= "table" then
        error("Cannot serialize value of type " .. valueType)
    end

    local arrayLength = #value
    local extraKeys = {}
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key > arrayLength or key ~= math.floor(key) then
            extraKeys[#extraKeys + 1] = key
        end
    end
    table.sort(extraKeys, compareKeys)

    if arrayLength == 0 and #extraKeys == 0 then
        return "{}"
    end

    local childIndent = indent + 4
    local pad = string.rep(" ", indent)
    local childPad = string.rep(" ", childIndent)
    local parts = { "{" }

    for index = 1, arrayLength do
        parts[#parts + 1] = childPad .. serialize(value[index], childIndent) .. ","
    end

    for _, key in ipairs(extraKeys) do
        local keyText
        if isIdentifier(key) then
            keyText = tostring(key)
        else
            keyText = "[" .. serialize(key, childIndent) .. "]"
        end
        parts[#parts + 1] = childPad .. keyText .. " = " .. serialize(value[key], childIndent) .. ","
    end

    parts[#parts + 1] = pad .. "}"
    return table.concat(parts, "\n")
end

local function makeAddon()
    local Addon = {
        Data = {
            DefaultDatasets = {
                Definitions = {},
            },
        },
    }
    function Addon.Data.DefaultDatasets:Register(definition)
        assert(type(definition) == "table" and type(definition.dataset) == "table", "invalid dataset definition")
        local id = definition.dataset.id
        assert(type(id) == "string" and id ~= "", "dataset id required")
        assert(self.Definitions[id] == nil, "duplicate dataset registration: " .. id)
        self.Definitions[id] = definition
        return definition
    end
    return Addon
end

local function loadAddonFile(path, Addon)
    local chunk, err = loadfile(path)
    assert(chunk, err)
    return chunk("RPEngine_Dev", Addon)
end

local function recipeMap(recipes)
    local map = {}
    for _, recipe in ipairs(recipes or {}) do
        local key = tostring(recipe.id or "")
        if key == "" then
            key = "name:" .. tostring(recipe.name or "")
        end
        map[key] = recipe
    end
    return map
end

local function recipeDelta(before, after)
    local prior = recipeMap(before)
    local updates = {}
    for _, recipe in ipairs(after or {}) do
        local key = tostring(recipe.id or "")
        if key == "" then
            key = "name:" .. tostring(recipe.name or "")
        end
        local old = prior[key]
        if old == nil or serialize(old) ~= serialize(recipe) then
            updates[#updates + 1] = deepCopy(recipe)
        end
    end
    return updates
end

local function writeRecipeExtension(path, updates)
    local body = [=[local _, Addon = ...

local definitions = Addon.Data and Addon.Data.DefaultDatasets and Addon.Data.DefaultDatasets.Definitions or nil
local definition = definitions and definitions["538a54a0"] or nil
if type(definition) ~= "table" or type(definition.dataset) ~= "table" then
    error("Leatherworking default dataset must be registered before loading this recipe extension.")
end

local dataset = definition.dataset
dataset.recipes = dataset.recipes or {}

local recipeUpdates = ]=] .. serialize(updates, 0) .. [=[

local function matches(existing, update)
    local updateId = tostring(update and update.id or "")
    local existingId = tostring(existing and existing.id or "")
    if updateId ~= "" and existingId == updateId then
        return true
    end
    local updateName = tostring(update and update.name or "")
    return updateName ~= "" and tostring(existing and existing.name or "") == updateName
end

for updateIndex = 1, #recipeUpdates do
    local update = recipeUpdates[updateIndex]
    local replaced = false
    for recipeIndex = 1, #dataset.recipes do
        if matches(dataset.recipes[recipeIndex], update) then
            dataset.recipes[recipeIndex] = update
            replaced = true
            break
        end
    end
    if not replaced then
        dataset.recipes[#dataset.recipes + 1] = update
    end
end
]=]
    writeFile(path, body)
end

local leatherPath = "data/default/professions/leatherworking.lua"
local rangePaths = {
    "data/default/professions/leatherworking_200_210.lua",
    "data/default/professions/leatherworking_210_225.lua",
    "data/default/professions/leatherworking_230_250.lua",
    "data/default/professions/leatherworking_250_270.lua",
    "data/default/professions/leatherworking_270_295.lua",
}
local item300Path = "data/default/professions/leatherworking_300.lua"
local recipe300Path = "data/default/professions/leatherworking_300_recipes.lua"
local tailoringPath = "data/default/professions/tailoring.lua"
local felclothPath = "data/default/professions/tailoring_felcloth.lua"

-- Reproduce the current Leatherworking item state by executing the existing files
-- in TOC order. Recipe deltas are captured separately so #188 does not move
-- recipes into the canonical dataset; #189 remains responsible for that work.
local sourceAddon = makeAddon()
for _, dependencyPath in ipairs({
    "data/default/professions/blacksmithing.lua",
    "data/default/professions/enchanting.lua",
    "data/default/professions/jewelcrafting.lua",
    "data/default/professions/tailoring.lua",
    "data/default/professions/misc.lua",
}) do
    loadAddonFile(dependencyPath, sourceAddon)
end
loadAddonFile(leatherPath, sourceAddon)
local working = assert(sourceAddon.Data.DefaultDatasets.Definitions["538a54a0"])
local baseRecipes = deepCopy(working.dataset.recipes or {})
local expectedRecipeState = deepCopy(baseRecipes)

for _, path in ipairs(rangePaths) do
    local before = deepCopy(working.dataset.recipes or {})
    loadAddonFile(path, sourceAddon)
    local updates = recipeDelta(before, working.dataset.recipes or {})
    writeRecipeExtension(path, updates)
    expectedRecipeState = deepCopy(working.dataset.recipes or {})
end

loadAddonFile(item300Path, sourceAddon)
working.version = 10
local expectedItems = deepCopy(working.dataset.items or {})
working.dataset.recipes = deepCopy(baseRecipes)
writeFile(leatherPath, "local _, Addon = ...\n\nAddon.Data.DefaultDatasets:Register(" .. serialize(working, 0) .. ")\n")

-- Consolidate Felcloth into the canonical Tailoring dataset.
local tailoringAddon = makeAddon()
loadAddonFile(tailoringPath, tailoringAddon)
loadAddonFile(felclothPath, tailoringAddon)
local tailoringDefinition = assert(tailoringAddon.Data.DefaultDatasets.Definitions["7259f1d3"])
tailoringDefinition.version = 2
local expectedTailoringItems = deepCopy(tailoringDefinition.dataset.items or {})
writeFile(tailoringPath, "local _, Addon = ...\n\nAddon.Data.DefaultDatasets:Register(" .. serialize(tailoringDefinition, 0) .. ")\n")

local function assertUniqueItems(items, label)
    local ids, names = {}, {}
    for _, item in ipairs(items or {}) do
        local id, name = tostring(item.id or ""), tostring(item.name or "")
        assert(id ~= "", label .. " item without id")
        assert(name ~= "", label .. " item without name")
        assert(not ids[id], label .. " duplicate item id: " .. id)
        assert(not names[name], label .. " duplicate item name: " .. name)
        ids[id], names[name] = true, true
    end
    return ids, names
end

-- Validate canonical Leatherworking serialization.
local checkAddon = makeAddon()
loadAddonFile(leatherPath, checkAddon)
local checkedLeather = assert(checkAddon.Data.DefaultDatasets.Definitions["538a54a0"])
assert(checkedLeather.version == 10, "Leatherworking canonical version must be 10")
assert(serialize(checkedLeather.dataset.items or {}) == serialize(expectedItems), "Leatherworking canonical items differ from extension-chain result")
assert(serialize(checkedLeather.dataset.recipes or {}) == serialize(baseRecipes), "#188 must not migrate extension recipes into leatherworking.lua")
local leatherIds, leatherNames = assertUniqueItems(checkedLeather.dataset.items, "Leatherworking")
assert(not leatherNames["Knothide Leather"], "Knothide Leather must not be introduced")
assert(leatherNames["Core Armor Kit"], "Core Armor Kit missing from canonical Leatherworking")
assert(leatherNames["Red Dragonscale Breastplate"], "skill-300 Leatherworking items missing")
assert(leatherIds["62656npm"] and leatherNames["Wicked Leather Armor"], "Wicked Leather Armor stable id lost")
assert(leatherIds["1xyj0rh1"] and leatherNames["Wicked Leather Belt"], "Wicked Leather Belt stable id lost")

-- Validate canonical Tailoring serialization and Felcloth identity.
local checkTailoringAddon = makeAddon()
loadAddonFile(tailoringPath, checkTailoringAddon)
local checkedTailoring = assert(checkTailoringAddon.Data.DefaultDatasets.Definitions["7259f1d3"])
assert(checkedTailoring.version == 2, "Tailoring canonical version must be 2")
assert(serialize(checkedTailoring.dataset.items or {}) == serialize(expectedTailoringItems), "Tailoring canonical items differ from extension result")
local _, tailoringNames = assertUniqueItems(checkedTailoring.dataset.items, "Tailoring")
assert(tailoringNames["Felcloth"], "Felcloth missing from canonical Tailoring")
local felclothCount = 0
for _, item in ipairs(checkedTailoring.dataset.items or {}) do
    if item.name == "Felcloth" then
        felclothCount = felclothCount + 1
        assert(item.id == "8dc72367", "Felcloth stable id changed")
        assert(item.icon == "interface/icons/inv_fabric_felrag.blp", "Felcloth icon changed")
    end
end
assert(felclothCount == 1, "Felcloth must exist exactly once")

-- Recipe-only range files must reproduce exactly the recipe state produced by
-- the original mixed extensions while leaving canonical items untouched.
local replayAddon = makeAddon()
loadAddonFile(leatherPath, replayAddon)
for _, path in ipairs(rangePaths) do
    local text = readFile(path)
    assert(not text:find("dataset%.items"), path .. " still mutates items")
    assert(not text:find("itemType%s*="), path .. " still contains item definitions")
    loadAddonFile(path, replayAddon)
end
local replayLeather = assert(replayAddon.Data.DefaultDatasets.Definitions["538a54a0"])
assert(serialize(replayLeather.dataset.recipes or {}) == serialize(expectedRecipeState), "recipe-only range files do not reproduce previous recipe state")
assert(serialize(replayLeather.dataset.items or {}) == serialize(expectedItems), "recipe-only range files changed canonical items")

-- Verify the skill-300 recipe extension resolves against canonical items,
-- including the newly canonical Tailoring Felcloth material.
local fullAddon = makeAddon()
loadAddonFile(tailoringPath, fullAddon)
loadAddonFile("data/default/professions/enchanting.lua", fullAddon)
loadAddonFile("data/default/professions/jewelcrafting.lua", fullAddon)
loadAddonFile("data/default/professions/misc.lua", fullAddon)
loadAddonFile(leatherPath, fullAddon)
for _, path in ipairs(rangePaths) do
    loadAddonFile(path, fullAddon)
end
loadAddonFile(recipe300Path, fullAddon)
local fullLeather = assert(fullAddon.Data.DefaultDatasets.Definitions["538a54a0"])
local itemById = {}
for _, item in ipairs(fullLeather.dataset.items or {}) do
    itemById[item.id] = item
end
local skill300Count = 0
local wickedFelcloth = false
for _, recipe in ipairs(fullLeather.dataset.recipes or {}) do
    local outputRef = recipe.output and recipe.output.itemRef or ""
    local datasetId, itemId = outputRef:match("^([^:]+):(.+)$")
    if datasetId == "538a54a0" then
        assert(itemById[itemId], "recipe output does not resolve: " .. tostring(recipe.name))
    end
    if tonumber(recipe.requiredSkillLevel) == 300 then
        skill300Count = skill300Count + 1
        assert(not tostring(recipe.name):find("Knothide"), "Knothide skill-300 recipe introduced")
        local outputItem = itemById[itemId]
        assert(outputItem and not tostring(outputItem.name):find("Knothide"), "Knothide skill-300 output introduced")
    end
    if recipe.name == "Wicked Leather Armor" then
        for _, input in ipairs(recipe.inputs or {}) do
            if input.itemRef == "7259f1d3:8dc72367" and input.quantity == 2 then
                wickedFelcloth = true
            end
        end
    end
end
assert(skill300Count == 52, "expected 52 skill-300 Leatherworking recipes, got " .. tostring(skill300Count))
assert(wickedFelcloth, "Wicked Leather Armor must retain 2 Felcloth")

-- Remove the now-obsolete item-only extension entries/files.
local tocPath = "RPEngine_Dev.toc"
local toc = readFile(tocPath)
local removedTailoring, removedLeather
local nextToc
nextToc, removedTailoring = toc:gsub("data/default/professions/tailoring_felcloth%.lua\r?\n", "", 1)
nextToc, removedLeather = nextToc:gsub("data/default/professions/leatherworking_300%.lua\r?\n", "", 1)
assert(removedTailoring == 1, "tailoring_felcloth.lua TOC entry missing")
assert(removedLeather == 1, "leatherworking_300.lua TOC entry missing")
writeFile(tocPath, nextToc)
assert(os.remove(item300Path), "failed to remove leatherworking_300.lua")
assert(os.remove(felclothPath), "failed to remove tailoring_felcloth.lua")

print("Issue #188 consolidation and deterministic validation passed")
