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

local leatherPath = "data/default/professions/leatherworking.lua"
local tocPath = "RPEngine_Dev.toc"
local recipePaths = {
    "data/default/professions/leatherworking_200_210.lua",
    "data/default/professions/leatherworking_210_225.lua",
    "data/default/professions/leatherworking_230_250.lua",
    "data/default/professions/leatherworking_250_270.lua",
    "data/default/professions/leatherworking_270_295.lua",
    "data/default/professions/leatherworking_300_recipes.lua",
}

local canonicalProfessionPaths = {
    "data/default/professions/alchemy.lua",
    "data/default/professions/blacksmithing.lua",
    "data/default/professions/enchanting.lua",
    "data/default/professions/inscription.lua",
    "data/default/professions/jewelcrafting.lua",
    "data/default/professions/misc.lua",
    "data/default/professions/tailoring.lua",
}

-- Reproduce the current effective recipe state in the same order in which the
-- current TOC applies the recipe extensions. This is the source of truth for
-- the migration; no recipe is reconstructed by hand.
local sourceAddon = makeAddon()
loadAddonFile("data/default/professions/alchemy.lua", sourceAddon)
loadAddonFile("data/default/professions/blacksmithing.lua", sourceAddon)
loadAddonFile("data/default/professions/enchanting.lua", sourceAddon)
loadAddonFile("data/default/professions/inscription.lua", sourceAddon)
loadAddonFile("data/default/professions/jewelcrafting.lua", sourceAddon)
loadAddonFile(leatherPath, sourceAddon)

local working = assert(sourceAddon.Data.DefaultDatasets.Definitions["538a54a0"], "Leatherworking definition missing")
assert(tonumber(working.version) == 11, "Issue #189 expected Leatherworking packaged version 11 before migration")
local baseItems = deepCopy(working.dataset.items or {})
local baseRecipes = deepCopy(working.dataset.recipes or {})

for index = 1, 5 do
    loadAddonFile(recipePaths[index], sourceAddon)
end
loadAddonFile("data/default/professions/misc.lua", sourceAddon)
loadAddonFile("data/default/professions/tailoring.lua", sourceAddon)
loadAddonFile(recipePaths[6], sourceAddon)

local expectedItems = deepCopy(working.dataset.items or {})
local expectedRecipes = deepCopy(working.dataset.recipes or {})
assert(serialize(expectedItems) == serialize(baseItems), "recipe extensions unexpectedly changed canonical Leatherworking items")
assert(#expectedRecipes >= #baseRecipes, "recipe extension replay unexpectedly removed recipes")

local function assertUniqueRecipes(recipes, label)
    local ids, names = {}, {}
    for _, recipe in ipairs(recipes or {}) do
        local id = tostring(recipe.id or "")
        local name = tostring(recipe.name or "")
        assert(id ~= "", label .. " recipe without id: " .. name)
        assert(name ~= "", label .. " recipe without name: " .. id)
        assert(not ids[id], label .. " duplicate recipe id: " .. id)
        assert(not names[name], label .. " duplicate recipe name: " .. name)
        ids[id] = true
        names[name] = true
    end
    return ids, names
end

local expectedIds, expectedNames = assertUniqueRecipes(expectedRecipes, "effective Leatherworking")

local function findRecipe(recipes, name)
    for _, recipe in ipairs(recipes or {}) do
        if recipe.name == name then
            return recipe
        end
    end
    return nil
end

local function inputQuantity(recipe, itemRef)
    for _, input in ipairs(recipe and recipe.inputs or {}) do
        if input.itemRef == itemRef then
            return tonumber(input.quantity) or 0
        end
    end
    return 0
end

local skill300Count = 0
local skill300BookCount = 0
local skill300TrainerCount = 0
for _, recipe in ipairs(expectedRecipes) do
    if tonumber(recipe.requiredSkillLevel) == 300 then
        skill300Count = skill300Count + 1
        assert(recipe.skillRef == "f82db71a:x9qez6bu", "skill-300 recipe has wrong Leatherworking skill ref: " .. tostring(recipe.name))
        assert(not tostring(recipe.name):find("Knothide"), "Knothide skill-300 recipe introduced: " .. tostring(recipe.name))
        if recipe.learnMode == "book" then
            skill300BookCount = skill300BookCount + 1
        elseif recipe.learnMode == "trainer" then
            skill300TrainerCount = skill300TrainerCount + 1
        else
            error("unexpected skill-300 learn mode for " .. tostring(recipe.name) .. ": " .. tostring(recipe.learnMode))
        end
    end
end
assert(skill300Count == 52, "expected 52 skill-300 recipes, got " .. tostring(skill300Count))
assert(skill300BookCount == 51, "expected 51 book skill-300 recipes, got " .. tostring(skill300BookCount))
assert(skill300TrainerCount == 1, "expected 1 trainer skill-300 recipe, got " .. tostring(skill300TrainerCount))
assert(findRecipe(expectedRecipes, "Blue Dragonscale Leggings").learnMode == "trainer", "Blue Dragonscale Leggings must remain trainer-sourced")

-- Targeted normalization checks guard the authored skill-300 decisions called
-- out by #189 while the full structural comparison below guards every field.
assert(inputQuantity(findRecipe(expectedRecipes, "Wicked Leather Armor"), "7259f1d3:8dc72367") == 2, "Wicked Leather Armor must retain 2 Felcloth")
assert(inputQuantity(findRecipe(expectedRecipes, "Black Dragonscale Shoulders"), "538a54a0:4gnkyr9f") == 93, "Cured Rugged Hide normalization changed for Black Dragonscale Shoulders")
assert(inputQuantity(findRecipe(expectedRecipes, "Molten Helm"), "538a54a0:4gnkyr9f") == 75, "Core Leather normalization changed for Molten Helm")
assert(inputQuantity(findRecipe(expectedRecipes, "Core Armor Kit"), "538a54a0:4gnkyr9f") == 15, "Core Armor Kit Rugged Leather normalization changed")
assert(inputQuantity(findRecipe(expectedRecipes, "Shifting Cloak"), "538a54a0:4gnkyr9f") == 46, "Shifting Cloak Rugged Leather normalization changed")

-- Move the exact effective recipe array into the canonical definition and bump
-- the packaged version monotonically so existing SavedVariables are replaced
-- by Database.SyncDefaultDatasets without depending on extension mutation.
working.version = 12
working.dataset.items = deepCopy(baseItems)
working.dataset.recipes = deepCopy(expectedRecipes)
writeFile(leatherPath, "local _, Addon = ...\n\nAddon.Data.DefaultDatasets:Register(" .. serialize(working, 0) .. ")\n")

-- Reload the serialized canonical file alone and prove it is structurally the
-- same result that the old extension chain produced.
local checkAddon = makeAddon()
loadAddonFile(leatherPath, checkAddon)
local checkedLeather = assert(checkAddon.Data.DefaultDatasets.Definitions["538a54a0"], "serialized Leatherworking definition missing")
assert(tonumber(checkedLeather.version) == 12, "Leatherworking packaged version must be 12")
assert(serialize(checkedLeather.dataset.items or {}) == serialize(baseItems), "canonical item array changed during recipe consolidation")
assert(serialize(checkedLeather.dataset.recipes or {}) == serialize(expectedRecipes), "canonical recipe array differs from pre-refactor effective state")
local checkedIds, checkedNames = assertUniqueRecipes(checkedLeather.dataset.recipes, "canonical Leatherworking")
for id in pairs(expectedIds) do
    assert(checkedIds[id], "canonical Leatherworking lost recipe id: " .. id)
end
for name in pairs(expectedNames) do
    assert(checkedNames[name], "canonical Leatherworking lost recipe: " .. name)
end

local canonicalText = readFile(leatherPath)
local _, registerCount = canonicalText:gsub("DefaultDatasets:Register", "")
assert(registerCount == 1, "Leatherworking canonical file must register exactly once")
assert(not canonicalText:find("DefaultDatasets%.Definitions%[%\"538a54a0%\"%]"), "canonical Leatherworking must not mutate an already-registered definition")

-- Load all canonical packaged item datasets and validate every retained recipe
-- item reference. This catches stale output IDs and stale cross-dataset inputs.
local packagedAddon = makeAddon()
loadAddonFile("data/default/core.lua", packagedAddon)
for _, path in ipairs(canonicalProfessionPaths) do
    loadAddonFile(path, packagedAddon)
end
loadAddonFile(leatherPath, packagedAddon)

local packagedItems = {}
local itemNamesByRef = {}
for datasetId, definition in pairs(packagedAddon.Data.DefaultDatasets.Definitions) do
    for _, item in ipairs(definition.dataset.items or {}) do
        local ref = datasetId .. ":" .. tostring(item.id or "")
        packagedItems[ref] = true
        itemNamesByRef[ref] = item.name
    end
end

local lowerSkillCount = 0
local canonicalSkill300Count = 0
for _, recipe in ipairs(checkedLeather.dataset.recipes or {}) do
    local outputRef = recipe.output and recipe.output.itemRef or ""
    assert(packagedItems[outputRef], "unresolved recipe output ref for " .. tostring(recipe.name) .. ": " .. tostring(outputRef))

    for _, input in ipairs(recipe.inputs or {}) do
        if input.itemRef and input.itemRef ~= "" then
            assert(packagedItems[input.itemRef], "unresolved recipe input ref for " .. tostring(recipe.name) .. ": " .. tostring(input.itemRef))
        end
    end

    if tonumber(recipe.requiredSkillLevel) == 300 then
        canonicalSkill300Count = canonicalSkill300Count + 1
        local outputDatasetId = outputRef:match("^([^:]+):")
        assert(outputDatasetId == "538a54a0", "skill-300 output is not a Leatherworking item: " .. tostring(recipe.name))
        assert(not tostring(itemNamesByRef[outputRef] or ""):find("Knothide"), "Knothide skill-300 output introduced: " .. tostring(recipe.name))
    elseif tonumber(recipe.requiredSkillLevel) and tonumber(recipe.requiredSkillLevel) < 300 then
        lowerSkillCount = lowerSkillCount + 1
    end
end
assert(canonicalSkill300Count == 52, "canonical skill-300 recipe count changed")
assert(lowerSkillCount > 0, "lower-skill Leatherworking recipes were lost")

-- Verify the Enchanting material names explicitly required by #189 still back
-- the refs used by the skill-300 recipes.
local enchanting = assert(packagedAddon.Data.DefaultDatasets.Definitions["732368d4"], "Enchanting packaged dataset missing")
local enchantingRefByName = {}
for _, item in ipairs(enchanting.dataset.items or {}) do
    enchantingRefByName[item.name] = "732368d4:" .. tostring(item.id)
end
local essenceAirRef = assert(enchantingRefByName["Essence of Air"], "Essence of Air missing from packaged Enchanting")
local essenceWaterRef = assert(enchantingRefByName["Essence of Water"], "Essence of Water missing from packaged Enchanting")
assert(inputQuantity(findRecipe(expectedRecipes, "Mongoose Boots"), essenceAirRef) == 6, "Mongoose Boots Essence of Air reference/quantity changed")
assert(inputQuantity(findRecipe(expectedRecipes, "Hide of the Wild"), essenceWaterRef) == 10, "Hide of the Wild Essence of Water reference/quantity changed")

local jewelcrafting = assert(packagedAddon.Data.DefaultDatasets.Definitions["4999dcec"], "Jewelcrafting packaged dataset missing")
local blackDiamondRef
for _, item in ipairs(jewelcrafting.dataset.items or {}) do
    if item.name == "Black Diamond" then
        blackDiamondRef = "4999dcec:" .. tostring(item.id)
        break
    end
end
assert(blackDiamondRef, "Black Diamond missing from packaged Jewelcrafting")
assert(inputQuantity(findRecipe(expectedRecipes, "Mongoose Boots"), blackDiamondRef) == 4, "Mongoose Boots Black Diamond reference/quantity changed")
assert(inputQuantity(findRecipe(expectedRecipes, "Shifting Cloak"), "3eb7e9bb:hq608hly") == 8, "Shifting Cloak Guardian Stone reference/quantity changed")

-- Two independent fresh registrations must yield the same count; with the
-- extension files removed below there is no reload-time append path left.
local reloadAddon = makeAddon()
loadAddonFile(leatherPath, reloadAddon)
local reloadLeather = assert(reloadAddon.Data.DefaultDatasets.Definitions["538a54a0"])
assert(#(reloadLeather.dataset.recipes or {}) == #(checkedLeather.dataset.recipes or {}), "fresh reload recipe count differs")
assert(serialize(reloadLeather.dataset.recipes or {}) == serialize(checkedLeather.dataset.recipes or {}), "fresh reload recipe state differs")

-- Remove all obsolete recipe extension entries/files only after the canonical
-- data and all reference validations have passed.
local toc = readFile(tocPath)
for _, path in ipairs(recipePaths) do
    local escaped = path:gsub("([^%w])", "%%%1")
    local nextToc, removed = toc:gsub(escaped .. "\r?\n", "", 1)
    assert(removed == 1, "TOC entry missing for obsolete recipe extension: " .. path)
    toc = nextToc
end
for _, path in ipairs(recipePaths) do
    assert(not toc:find(path, 1, true), "obsolete recipe extension remains in TOC: " .. path)
end
writeFile(tocPath, toc)

for _, path in ipairs(recipePaths) do
    assert(os.remove(path), "failed to remove obsolete recipe extension: " .. path)
end

print(string.format(
    "Issue #189 consolidation passed: %d base recipes -> %d canonical recipes; %d lower-skill; %d skill-300 (%d book, %d trainer)",
    #baseRecipes,
    #expectedRecipes,
    lowerSkillCount,
    skill300Count,
    skill300BookCount,
    skill300TrainerCount
))
