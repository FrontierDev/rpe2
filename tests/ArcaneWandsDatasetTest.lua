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
local enchanting = assert(definitions["732368d4"] and definitions["732368d4"].dataset, "Enchanting definition is registered")

local function findItem(items, name)
    for _, item in ipairs(items or {}) do
        if item.name == name then
            return item
        end
    end
end

local function assertWand(item, expected)
    assertTrue(item ~= nil, expected.name .. " is packaged")
    assertEqual(item.id, expected.id, expected.name .. " ID")
    assertEqual(item.bindingFlag, expected.bindingFlag, expected.name .. " binding")
    assertEqual(item.itemLevel, expected.itemLevel, expected.name .. " item level")
    assertEqual(item.itemType, "weapon", expected.name .. " item type")
    assertEqual(item.damageMode, "range", expected.name .. " damage mode")
    assertEqual(item.minDamagePerTurn, expected.minDamagePerTurn, expected.name .. " minimum Arcane damage")
    assertEqual(item.maxDamagePerTurn, expected.maxDamagePerTurn, expected.name .. " maximum Arcane damage")
    assertEqual(item.damageSchoolRef, "f82db71a:dtxhglqg", expected.name .. " damage school")
    assertEqual(item.weaponTypeRef, "f82db71a:s4q9t5f3", expected.name .. " weapon type")
    assertEqual(item.validSlotRefs[1], "f82db71a:q8ve6n6t", expected.name .. " valid slot")
    assertEqual(item.isTwoHanded, false, expected.name .. " is one-handed")
    assertEqual(item.canDisenchant, false, expected.name .. " cannot be disenchanted")
    assertEqual(item.conditions[1].type, "level", expected.name .. " level condition type")
    assertEqual(item.conditions[1].minimumValue, expected.requiredLevel, expected.name .. " required level")
end

local wornArcaneWand = findItem(core.items, "Worn Arcane Wand")
assertWand(wornArcaneWand, {
    name = "Worn Arcane Wand",
    id = "wrnarca1",
    bindingFlag = "none",
    itemLevel = 1,
    minDamagePerTurn = 1,
    maxDamagePerTurn = 3,
    requiredLevel = 1,
})
assertEqual(wornArcaneWand.quality, "poor", "Worn Arcane Wand quality")
assertEqual(wornArcaneWand.tags[1], "starter", "Worn Arcane Wand starter tag")

for _, expected in ipairs({
    { name = "Lesser Magic Wand", id = "enlmag01", itemLevel = 15, minDamagePerTurn = 12, maxDamagePerTurn = 22, requiredLevel = 5 },
    { name = "Greater Magic Wand", id = "engmag01", itemLevel = 23, minDamagePerTurn = 22, maxDamagePerTurn = 41, requiredLevel = 13 },
    { name = "Lesser Mystic Wand", id = "enlmys01", itemLevel = 31, minDamagePerTurn = 23, maxDamagePerTurn = 43, requiredLevel = 26 },
    { name = "Greater Mystic Wand", id = "engmys01", itemLevel = 35, minDamagePerTurn = 40, maxDamagePerTurn = 76, requiredLevel = 30 },
}) do
    assertWand(findItem(enchanting.items, expected.name), {
        name = expected.name,
        id = expected.id,
        bindingFlag = "bind_on_equip",
        itemLevel = expected.itemLevel,
        minDamagePerTurn = expected.minDamagePerTurn,
        maxDamagePerTurn = expected.maxDamagePerTurn,
        requiredLevel = expected.requiredLevel,
    })
end

print("ArcaneWandsDatasetTest passed")
