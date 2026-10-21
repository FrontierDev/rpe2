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
local warrior = assert(definitions["7bbb4cb9"] and definitions["7bbb4cb9"].dataset, "Warrior definition is registered")
local warriorClass = assert(warrior.classes[1], "Warrior class definition exists")

local function findByName(collection, name)
    for _, entry in ipairs(collection or {}) do
        if entry.name == name then
            return entry
        end
    end
end

local function assertRageCost(spellName, expectedAmount)
    local spell = assert(findByName(warrior.spells, spellName), spellName .. " is packaged")
    local costs = spell.resourceCosts or {}
    assertEqual(#costs, 1, spellName .. " has one resource cost")
    assertEqual(costs[1].resourceRef, "f82db71a:e2tfklq7", spellName .. " uses rage")
    assertEqual(costs[1].amount, expectedAmount, spellName .. " rage cost")
end

for spellName, amount in pairs({
    ["Heroic Strike"] = 10,
    ["Rend"] = 5,
    ["Intimidating Shout"] = 10,
    ["Raging Blow"] = 10,
    ["Pummel"] = 5,
    ["Sunder Armor"] = 10,
    ["Shield Slam"] = 20,
    ["Devastate"] = 10,
    ["Heroic Throw"] = 5,
    ["Demoralizing Shout"] = 5,
    ["Concussive Blow"] = 5,
}) do
    assertRageCost(spellName, amount)
end

for _, spellName in ipairs({ "Battle Shout", "Commanding Shout" }) do
    local spell = assert(findByName(warrior.spells, spellName), spellName .. " is packaged")
    assertEqual(#(spell.resourceCosts or {}), 0, spellName .. " has no rage cost")
end

local bloodrage = assert(findByName(warrior.auras, "Bloodrage"), "Bloodrage aura is packaged")
assertEqual(bloodrage.effects[1].amount, 5, "Bloodrage rage generation")
assertEqual(bloodrage.effects[1].resourceRef, "f82db71a:e2tfklq7", "Bloodrage uses rage")

local twoHanded = assert(findByName(warrior.traits, "Two-Handed Specialisation"), "Two-Handed Specialisation is packaged")
local twoHandedRef = "7bbb4cb9:" .. twoHanded.id
local referencedByClass = false
for _, traitRef in ipairs(warriorClass.talentTraitRefs or {}) do
    if traitRef == twoHandedRef then
        referencedByClass = true
        break
    end
end
assertTrue(referencedByClass, "Two-Handed Specialisation is exposed by the Warrior class")
local condition = assert(twoHanded.conditions[1], "Two-Handed Specialisation condition exists")
assertEqual(condition.type, "item_equipped", "Two-Handed Specialisation condition type")
assertEqual(condition.slotKey, "mainhand", "Two-Handed Specialisation condition slot")
assertTrue(condition.requiresTwoHanded == true, "Two-Handed Specialisation requires a two-handed weapon")
assertEqual(#condition.weaponTypeRefs, 0, "Two-Handed Specialisation accepts any two-handed weapon type")
assertEqual(twoHanded.events[1].combatEventId, "on_auto_attack_hit", "Two-Handed Specialisation hit trigger")
assertEqual(twoHanded.events[1].effects[1].amount, 10, "Two-Handed Specialisation rage generation")
assertEqual(twoHanded.events[1].effects[1].resourceRef, "f82db71a:e2tfklq7", "Two-Handed Specialisation uses rage")

local conditionAddon = TestSupport.CreateAddon()
TestSupport.LoadAddonFile("core/classes/Condition.lua", conditionAddon)
local normalized = conditionAddon.Internal.Database.Classes.Condition.Normalize(condition)
assertTrue(normalized ~= nil and normalized.requiresTwoHanded == true, "Two-handed condition survives normalization")

print("WarriorDatasetTest passed")
