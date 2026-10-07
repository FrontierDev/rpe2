local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local Addon = TestSupport.CreateAddon()
local definitions = TestSupport.LoadPackagedDefaultData(Addon)
local coreDefinition = definitions["f82db71a"]
assertTrue(type(coreDefinition) == "table", "Core dataset is registered")

local coreEntries = TestSupport.IndexDatasetEntries({ ["f82db71a"] = coreDefinition }, {
    "resources",
    "stats",
})
local allEntries = TestSupport.IndexDatasetEntries(definitions, { "traits" })

local function hasValue(values, expected)
    for index = 1, #(values or {}) do
        if values[index] == expected then return true end
    end
    return false
end

local function validateProgressions(class, className, collectionName, referenceField)
    local seen = {}
    local progressions = class[collectionName] or {}
    assertTrue(#progressions > 0, className .. " has " .. collectionName)
    for index = 1, #progressions do
        local progression = progressions[index]
        local reference = progression[referenceField]
        assertTrue(type(reference) == "string" and coreEntries[reference] ~= nil,
            className .. " " .. collectionName .. " reference resolves: " .. tostring(reference))
        assertTrue(not seen[reference], className .. " does not duplicate " .. referenceField .. ": " .. reference)
        seen[reference] = true
        assertTrue(type(progression.initialValue) == "number", className .. " initial progression value is numeric")
        assertTrue(type(progression.perLevelValue) == "number", className .. " per-level progression value is numeric")
    end
end

for datasetId, definition in pairs(definitions) do
    local dataset = definition.dataset
    if dataset.datasetType == "class" then
        assertEqual(dataset.id, datasetId, "class dataset registration key matches its payload")
        assertTrue(hasValue(dataset.dependencies, "f82db71a"), dataset.name .. " depends on Core")
        assertEqual(#(dataset.classes or {}), 1, dataset.name .. " has one class definition")

        local class = dataset.classes[1]
        assertTrue(type(class.id) == "string" and class.id ~= "", dataset.name .. " class has an ID")
        assertTrue(type(class.name) == "string" and class.name ~= "", dataset.name .. " class has a name")
        validateProgressions(class, class.name, "statProgressions", "statRef")
        validateProgressions(class, class.name, "resourceProgressions", "resourceRef")

        for _, field in ipairs({ "passiveTraitRefs", "talentTraitRefs" }) do
            local seen = {}
            for index = 1, #(class[field] or {}) do
                local reference = class[field][index]
                assertTrue(allEntries[reference] ~= nil,
                    class.name .. " " .. field .. " resolves: " .. tostring(reference))
                assertTrue(reference:sub(1, #datasetId + 1) == datasetId .. ":",
                    class.name .. " " .. field .. " belongs to its dataset: " .. tostring(reference))
                assertTrue(not seen[reference], class.name .. " does not duplicate " .. field .. ": " .. reference)
                seen[reference] = true
            end
        end
    end
end

-- This is a deliberately focused balance regression. The structure above is
-- content-agnostic; numeric values stay only where this exact coefficient is
-- the compatibility contract being protected.
local deathKnight = definitions.dknight1.dataset
local runeStrike
for _, spell in ipairs(deathKnight.spells or {}) do
    if spell.name == "Rune Strike" then runeStrike = spell; break end
end
assertTrue(runeStrike ~= nil, "Death Knight includes Rune Strike")
assertEqual(runeStrike.components[1].effect.baseDamage, 135, "Rune Strike base damage")
assertEqual(runeStrike.components[1].effect.weaponDamageCoefficient, 1.8, "Rune Strike weapon coefficient")

print("ClassBaseStatsDatasetTest passed")
