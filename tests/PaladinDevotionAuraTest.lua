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

local shadowAura = assert(findById(paladin.auras, "shdres60"), "missing Shadow Resistance Aura definition")
assertEqual(shadowAura.duration, 0, "Shadow Resistance Aura remains active until the event ends")
assertEqual(shadowAura.effects[1].statRef, "f82db71a:itpo751d", "Shadow Resistance Aura modifies Shadow Resistance")
assertEqual(shadowAura.effects[1].baseAmount, 60, "Shadow Resistance Aura grants 60 Shadow Resistance")

local shadowTrait = assert(findById(paladin.traits, "shdraura1"), "missing Shadow Resistance Aura trait")
assertEqual(shadowTrait.automaticAuras[1].auraRef, "b0211ab3:shdres60", "Shadow Resistance trait references its Aura")
assertEqual(shadowTrait.automaticAuras[1].targetScope, "self", "Shadow Resistance trait targets the Paladin")
assertEqual(shadowTrait.automaticAuras[1].turns, 0, "Shadow Resistance trait applies to the Paladin indefinitely")
assertEqual(shadowTrait.automaticAuras[2].targetScope, "all_allies", "Shadow Resistance trait targets all allies")
assertEqual(shadowTrait.automaticAuras[2].turns, 0, "Shadow Resistance trait applies to allies indefinitely")

local shieldSpecialisation = assert(findById(paladin.traits, "shldspec1"), "missing Shield Specialisation trait")
assertEqual(shieldSpecialisation.statBonuses[1].statRef, "f82db71a:sblkval1", "Shield Specialisation modifies Shield Block Value")
assertEqual(shieldSpecialisation.statBonuses[1].operation, "percent", "Shield Specialisation uses percentage scaling")
assertEqual(shieldSpecialisation.statBonuses[1].value, 30, "Shield Specialisation grants 30% Shield Block Value")

local paladinClass = assert(findById(paladin.classes, "wvirv9um"), "missing Paladin class definition")
assertEqual(contains(paladinClass.talentTraitRefs, "b0211ab3:dvttrait"), true,
    "Devotion Aura is class-owned as a Paladin talent")
assertEqual(contains(paladinClass.talentTraitRefs, "b0211ab3:shdraura1"), true,
    "Shadow Resistance Aura is class-owned as a Paladin talent")
assertEqual(contains(paladinClass.talentTraitRefs, "b0211ab3:shldspec1"), true,
    "Shield Specialisation is class-owned as a Paladin talent")

local sanctuaryAura = assert(findById(paladin.auras, "3ugbrrk0"), "missing Blessing of Sanctuary Aura")
assertEqual(sanctuaryAura.effects[1].statRef, "f82db71a:sblkval1", "Blessing of Sanctuary modifies Shield Block Value")
assertEqual(sanctuaryAura.effects[1].operation, "percent", "Blessing of Sanctuary scales Shield Block Value by percentage")
assertEqual(sanctuaryAura.effects[1].baseAmount, 20, "Blessing of Sanctuary grants 20% Shield Block Value")
assertEqual(sanctuaryAura.effects[2].statRef, "f82db71a:p8syz5ba", "Blessing of Sanctuary modifies Block Chance")
assertEqual(sanctuaryAura.effects[2].baseAmount, 5, "Blessing of Sanctuary grants 5% Block Chance")

local sanctuarySpell = findById(paladin.spells, "zg4n0a1f")
assert(sanctuarySpell, "missing Blessing of Sanctuary spell")
assertEqual(sanctuarySpell.tooltipTemplateData.auraSections[1].descriptionText,
    "Increases Shield Block Value by 20%. Increases Block Chance by 5%.",
    "Blessing of Sanctuary spell tooltip describes updated effects")

print("PaladinDevotionAuraTest passed")
