local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local definitions = TestSupport.LoadPackagedDefaultData(TestSupport.CreateAddon())
local core = assert(definitions["f82db71a"] and definitions["f82db71a"].dataset, "Core definition is registered")
local mage = assert(definitions["d7c874c4"] and definitions["d7c874c4"].dataset, "Mage definition is registered")

local function findById(entries, id)
    for _, entry in ipairs(entries or {}) do
        if entry.id == id then return entry end
    end
end

local waterElemental = findById(core.units, "watere01")
assertTrue(type(waterElemental) == "table", "Water Elemental unit is packaged in Core")
assertEqual(waterElemental.name, "Water Elemental", "Water Elemental name")
assertEqual(waterElemental.creatureType, "elemental", "Water Elemental creature type")
assertEqual(waterElemental.creatureSize, "medium", "Water Elemental creature size")
assertEqual(waterElemental.challengeLevel, "normal", "Water Elemental challenge level")
assertEqual(#waterElemental.appearances, 0, "Water Elemental has no assumed appearance")
assertEqual(#waterElemental.presets, 0, "Water Elemental has no presets")
assertEqual(waterElemental.tags[1], "water", "Water Elemental tag")

assertEqual(#waterElemental.resources, 2, "Water Elemental resource row count")
assertEqual(waterElemental.resources[1].initialValue, 180, "Water Elemental health initial value")
assertEqual(waterElemental.resources[1].perLevelValue, 44.40678, "Water Elemental health scaling")
assertEqual(waterElemental.resources[2].initialValue, 150, "Water Elemental mana initial value")
assertEqual(waterElemental.resources[2].perLevelValue, 34.745763, "Water Elemental mana scaling")

local expectedStats = {
    { 50, 17.79661, "f82db71a:v42albuv" },
    { 0, 0, "f82db71a:wbj4zuf3" },
    { 0, 0, "f82db71a:dd88li4c" },
    { 5, 0, "f82db71a:v2g0tw0o" },
    { 0, 0, "f82db71a:tcn0s8kx" },
    { 0, 0, "f82db71a:o6113cir" },
    { 0, 0, "f82db71a:p8syz5ba" },
    { 0, 0, "f82db71a:zs1nbz13" },
    { 35, 4.491525, "f82db71a:u7b49vs9" },
    { 0, 0, "f82db71a:v2rs9cpy" },
    { 20, 4.745763, "f82db71a:7t7xgzcx" },
    { 5, 0, "f82db71a:jslmczbi" },
    { 0, 0, "f82db71a:fercjhm5" },
    { 5, 0, "f82db71a:69hfqhne" },
    { 0, 0, "f82db71a:0w7c7p09" },
    { 0, 0, "f82db71a:hj6d4kvy" },
    { 2, 2, "f82db71a:jjn0my8k" },
    { 0, 0, "f82db71a:pg0ytacb" },
    { 0, 0, "f82db71a:954yunb9" },
    { 0, 0, "f82db71a:itpo751d" },
    { 0, 0, "f82db71a:hlyrsstn" },
    { 0, 0, "f82db71a:rgnrtg01" },
    { 30, 0, "f82db71a:s1mt6jh9" },
}
assertEqual(#waterElemental.stats, #expectedStats, "Water Elemental stat row count")
for index, expected in ipairs(expectedStats) do
    local actual = waterElemental.stats[index]
    assertEqual(actual.initialValue, expected[1], "Water Elemental stat " .. index .. " initial value")
    assertEqual(actual.perLevelValue, expected[2], "Water Elemental stat " .. index .. " scaling")
    assertEqual(actual.statRef, expected[3], "Water Elemental stat " .. index .. " reference")
end

assertEqual(#waterElemental.spells, 4, "Water Elemental spell count")
for index, expected in ipairs({
    "f82db71a:natatk01",
    "d7c874c4:lywroiqu",
    "d7c874c4:7ha8pdoy",
    "d7c874c4:icearm01",
}) do
    assertEqual(waterElemental.spells[index], expected, "Water Elemental spell " .. index)
end

local waterPet = findById(mage.pets, "smnwatel")
assertTrue(type(waterPet) == "table", "Mage Water Elemental pet is packaged")
assertEqual(waterPet.name, "Summoned Water Elemental", "Mage Water Elemental pet name")
assertEqual(waterPet.unitRef, "f82db71a:watere01", "Mage Water Elemental pet unit reference")
assertEqual(#waterPet.equipmentSlotRefs, 0, "Mage Water Elemental pet equipment slots")
assertEqual(#waterPet.spells, 4, "Mage Water Elemental pet spell count")
for index, expected in ipairs(waterElemental.spells) do
    assertEqual(waterPet.spells[index], expected, "Mage Water Elemental pet spell " .. index)
end

local summonWaterElemental = findById(mage.spells, "mgsmwatl")
assertTrue(type(summonWaterElemental) == "table", "Summon Water Elemental spell is packaged")
assertEqual(summonWaterElemental.name, "Summon Water Elemental", "Summon Water Elemental name")
assertEqual(summonWaterElemental.spellbookCategory, "Frost", "Summon Water Elemental category")
assertEqual(summonWaterElemental.icon, "interface/icons/spell_frost_summonwaterelemental.blp", "Summon Water Elemental icon")
assertEqual(#summonWaterElemental.components, 1, "Summon Water Elemental component count")
assertEqual(summonWaterElemental.components[1].effect.type, "summon_pet", "Summon Water Elemental effect type")
assertEqual(summonWaterElemental.components[1].effect.unitRef, "f82db71a:watere01", "Summon Water Elemental unit reference")
assertEqual(summonWaterElemental.components[1].target.type, "caster", "Summon Water Elemental target type")
assertEqual(summonWaterElemental.components[1].target.targetDisposition, "ally", "Summon Water Elemental target disposition")
assertEqual(#summonWaterElemental.resourceCosts, 0, "Summon Water Elemental has no resource cost")

print("WaterElementalDatasetTest passed")
