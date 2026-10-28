local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function findById(entries, id)
    for index = 1, #(entries or {}) do
        if entries[index].id == id then
            return entries[index]
        end
    end

    return nil
end

local function contains(values, expected)
    for index = 1, #(values or {}) do
        if values[index] == expected then
            return true
        end
    end

    return false
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local definitions = TestSupport.LoadPackagedDefaultData(TestSupport.CreateAddon())
local paladin = assert(definitions["b0211ab3"] and definitions["b0211ab3"].dataset, "missing Paladin dataset")

local aura = assert(findById(paladin.auras, "dvtaura1"), "missing Devotion Aura definition")
assertEqual(aura.name, "Devotion Aura", "Devotion Aura has the expected name")
assertEqual(aura.duration, 0, "Devotion Aura remains active until the event ends")
assertEqual(aura.polarity, "helpful", "Devotion Aura is classified as helpful")
assertEqual(aura.effects[1].type, "stat", "Devotion Aura modifies a stat")
assertEqual(aura.effects[1].statRef, "f82db71a:pu05li08", "Devotion Aura modifies Damage Reduction")
assertEqual(aura.effects[1].baseAmount, 3, "Devotion Aura grants 3 Damage Reduction")

local trait = assert(findById(paladin.traits, "dvttrait"), "missing Devotion Aura trait")
local selfAura = assert(trait.automaticAuras and trait.automaticAuras[1], "Devotion Aura trait applies an Aura to the Paladin")
assertEqual(selfAura.auraRef, "b0211ab3:dvtaura1", "self Aura references Devotion Aura")
assertEqual(selfAura.targetScope, "self", "trait targets the Paladin")
assertEqual(selfAura.turns, 0, "trait applies Devotion Aura to the Paladin without a turn limit")

local allyAura = assert(trait.automaticAuras and trait.automaticAuras[2], "Devotion Aura trait applies an Aura to allies")
assertEqual(allyAura.auraRef, "b0211ab3:dvtaura1", "ally Aura references Devotion Aura")
assertEqual(allyAura.targetScope, "all_allies", "trait targets all allies")
assertEqual(allyAura.turns, 0, "trait applies Devotion Aura to allies without a turn limit")

local paladinClass = assert(findById(paladin.classes, "wvirv9um"), "missing Paladin class definition")
assertEqual(contains(paladinClass.talentTraitRefs, "b0211ab3:dvttrait"), true,
    "Devotion Aura is class-owned as a Paladin talent")

print("PaladinDevotionAuraTest passed")
