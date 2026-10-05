local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local Addon = {
    Name = "RPEngine2",
    Data = {},
    Internal = {},
    Debug = { Internal = function() end },
}

local function loadAddonFile(path)
    TestSupport.LoadAddonFile(path, Addon, "RPEngine2")
end

loadAddonFile("core/internal/database/Dependecies.lua")
loadAddonFile("core/internal/database/Database.lua")
loadAddonFile("data/default/Datasets.lua")
loadAddonFile("data/default/core.lua")
for _, classFile in ipairs({
    "shaman.lua", "warlock.lua", "death_knight.lua", "monk.lua",
    "demon_hunter.lua", "evoker.lua", "paladin.lua",
}) do
    loadAddonFile("data/default/classes/" .. classFile)
end

local definitions = Addon.Data.DefaultDatasets.Definitions
local core = definitions["f82db71a"] and definitions["f82db71a"].dataset
assertTrue(type(core) == "table", "Core dataset is registered")

local function findByName(collection, name)
    for index = 1, #(collection or {}) do
        if collection[index].name == name then return collection[index] end
    end
end

local function hasValue(collection, key, value)
    for index = 1, #(collection or {}) do
        if key == nil and collection[index] == value then return true end
        if key ~= nil and collection[index][key] == value then return true end
    end
    return false
end

local knownStats, knownResources, knownAuras = {}, {}, {}
for _, stat in ipairs(core.stats or {}) do knownStats["f82db71a:" .. stat.id] = true end
for _, resource in ipairs(core.resources or {}) do knownResources["f82db71a:" .. resource.id] = true end
for datasetId, definition in pairs(definitions) do
    for _, aura in ipairs(definition.dataset.auras or {}) do
        knownAuras[datasetId .. ":" .. aura.id] = true
    end
end

local expectedClassDatasets = {
    c4a91e7d = "Shaman",
    e8f3b2c6 = "Warlock",
    dknight1 = "Death Knight",
    monkdata = "Monk",
    dhunter1 = "Demon Hunter",
    evokdata = "Evoker",
    b0211ab3 = "Paladin",
}

for datasetId, className in pairs(expectedClassDatasets) do
    local definition = definitions[datasetId]
    assertTrue(type(definition) == "table", className .. " definition is registered")
    assertTrue(type(definition.version) == "number" and definition.version > 0, className .. " has a positive dataset version")
    local dataset = definition.dataset
    assertEqual(dataset.datasetType, "class", className .. " dataset type")
    assertEqual(dataset.name, className, className .. " dataset name")
    assertTrue(hasValue(dataset.dependencies, nil, "f82db71a"), className .. " depends on Core")
    assertEqual(#(dataset.classes or {}), 1, className .. " has one class definition")

    local class = dataset.classes[1]
    assertTrue(type(class.id) == "string" and class.id ~= "", className .. " class has an ID")
    assertEqual(class.name, className, className .. " class name")

    local statRefs = {}
    assertEqual(#(class.statProgressions or {}), 5, className .. " has five base stat progressions")
    for index = 1, #class.statProgressions do
        local progression = class.statProgressions[index]
        assertTrue(not statRefs[progression.statRef], className .. " stat refs are unique")
        statRefs[progression.statRef] = true
        assertTrue(knownStats[progression.statRef], className .. " stat ref resolves: " .. tostring(progression.statRef))
        assertTrue(type(progression.initialValue) == "number", className .. " stat initial value is numeric")
        assertTrue(type(progression.perLevelValue) == "number", className .. " stat level value is numeric")
    end

    local resourceRefs = {}
    assertTrue(#(class.resourceProgressions or {}) > 0, className .. " has resource progressions")
    for index = 1, #class.resourceProgressions do
        local progression = class.resourceProgressions[index]
        assertTrue(not resourceRefs[progression.resourceRef], className .. " resource refs are unique")
        resourceRefs[progression.resourceRef] = true
        assertTrue(knownResources[progression.resourceRef], className .. " resource ref resolves: " .. tostring(progression.resourceRef))
        assertTrue(type(progression.initialValue) == "number", className .. " resource initial value is numeric")
        assertTrue(type(progression.perLevelValue) == "number", className .. " resource level value is numeric")
    end

    local entryIds = {}
    for _, collectionName in ipairs({ "auras", "spells", "traits", "items" }) do
        for index = 1, #(dataset[collectionName] or {}) do
            local entry = dataset[collectionName][index]
            assertTrue(type(entry.id) == "string" and entry.id ~= "", className .. " " .. collectionName .. " entry has an ID")
            assertTrue(not entryIds[collectionName .. ":" .. entry.id], className .. " " .. collectionName .. " IDs are unique")
            entryIds[collectionName .. ":" .. entry.id] = true
        end
    end

    for index = 1, #(dataset.spells or {}) do
        local spell = dataset.spells[index]
        assertEqual(spell.description, "", spell.name .. " keeps its description generator-owned")
        for componentIndex = 1, #(spell.components or {}) do
            local effect = spell.components[componentIndex].effect
            if effect and effect.type == "apply_aura" then
                assertTrue(knownAuras[effect.auraRef] == true, spell.name .. " references a packaged aura")
            end
        end
    end
end

local deathKnight = definitions.dknight1.dataset
local runeStrike = findByName(deathKnight.spells, "Rune Strike")
assertTrue(runeStrike ~= nil, "Death Knight includes Rune Strike")
assertEqual(runeStrike.components[1].effect.baseDamage, 135, "Rune Strike base damage")
assertEqual(runeStrike.components[1].effect.weaponDamageCoefficient, 1.8, "Rune Strike weapon coefficient")

local paladin = definitions.b0211ab3.dataset
local holyShield = findByName(paladin.auras, "Holy Shield")
assertTrue(holyShield ~= nil, "Paladin includes Holy Shield")
assertEqual(holyShield.tooltipTemplate, false, "Holy Shield uses generated aura tooltip text")
assertEqual(holyShield.tooltipTemplateData, nil, "Holy Shield has no hand-authored tooltip payload")

local sealOfTheCrusader = findByName(paladin.auras, "Seal of the Crusader")
assertTrue(sealOfTheCrusader ~= nil, "Paladin includes Seal of the Crusader")
local hitBonusFound = false
for index = 1, #(sealOfTheCrusader.effects or {}) do
    local effect = sealOfTheCrusader.effects[index]
    if effect.statRef == "f82db71a:wbj4zuf3" and effect.baseAmount == 3 then
        hitBonusFound = true
    end
end
assertTrue(hitBonusFound, "Seal of the Crusader grants 3% melee hit")

local fury = findByName(core.resources, "Fury")
assertTrue(fury ~= nil, "Core includes Fury resource")
assertEqual(fury.baseValue, 100, "Fury maximum")
assertEqual(fury.startsAtZero, true, "Fury starts at zero")
local runes = findByName(core.resources, "Runes")
assertTrue(runes ~= nil, "Core includes Runes resource")
assertEqual(runes.baseValue, 6, "Runes maximum")
local essence = findByName(core.resources, "Essence")
assertTrue(essence ~= nil, "Core includes Essence resource")
assertEqual(essence.baseValue, 5, "Essence maximum")

local toc = assert(io.open("RPEngine2.toc", "r"))
local tocText = toc:read("*a")
toc:close()
for _, reference in ipairs({ "data/default/classes/shaman.lua", "data/default/classes/warlock.lua" }) do
    assertTrue(tocText:find(reference, 1, true) ~= nil, "Packaged TOC includes " .. reference)
end

print("ClassBaseStatsDatasetTest passed")
