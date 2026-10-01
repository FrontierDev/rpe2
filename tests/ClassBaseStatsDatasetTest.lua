local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local Addon = { Name = "RPEngine2", Data = {}, Internal = {}, Debug = { Internal = function() end } }
loadAddonFile("core/internal/database/Dependecies.lua", Addon)
loadAddonFile("core/internal/database/Database.lua", Addon)
loadAddonFile("data/default/Datasets.lua", Addon)
loadAddonFile("data/default/core.lua", Addon)
loadAddonFile("data/default/classes/shaman.lua", Addon)
loadAddonFile("data/default/classes/warlock.lua", Addon)

local definitions = Addon.Data.DefaultDatasets.Definitions

local function assertProgressions(class, fieldName, expected, label)
    local remaining = {}
    for ref, values in pairs(expected) do
        remaining[ref] = values
    end

    local progressions = class[fieldName]
    assertEqual(#progressions, 5, label .. " progression count")
    for index = 1, #progressions do
        local progression = progressions[index]
        local values = remaining[progression.statRef]
        assertTrue(values ~= nil, label .. " uses an expected Core stat")
        assertEqual(progression.initialValue, values[1], label .. " initial value for " .. progression.statRef)
        assertEqual(progression.perLevelValue, values[2], label .. " per-level value for " .. progression.statRef)
        remaining[progression.statRef] = nil
    end
    assertTrue(next(remaining) == nil, label .. " includes every expected stat")
end

local function assertClass(datasetId, expectedVersion, classId, name, expectedStats, expectedResources, expectedPassiveTraitCount, expectedTalentTraitCount)
    local definition = definitions[datasetId]
    assertTrue(type(definition) == "table", name .. " definition is registered")
    assertEqual(definition.version, expectedVersion, name .. " dataset version")

    local dataset = definition.dataset
    assertEqual(dataset.datasetType, "class", name .. " dataset type")
    assertEqual(dataset.name, name, name .. " dataset name")
    assertEqual(dataset.dependencies[1], "f82db71a", name .. " dependency")

    local class = dataset.classes[1]
    assertEqual(class.id, classId, name .. " class ID")
    assertEqual(class.name, name, name .. " class name")
    assertEqual(#class.passiveTraitRefs, expectedPassiveTraitCount or 0, name .. " passive trait selection")
    assertEqual(#class.talentTraitRefs, expectedTalentTraitCount or 0, name .. " talent trait selection")
    assertProgressions(class, "statProgressions", expectedStats, name)

    local remainingResources = {}
    for ref, values in pairs(expectedResources) do
        remainingResources[ref] = values
    end
    assertEqual(#class.resourceProgressions, 2, name .. " resource progression count")
    for index = 1, #class.resourceProgressions do
        local progression = class.resourceProgressions[index]
        local values = remainingResources[progression.resourceRef]
        assertTrue(values ~= nil, name .. " uses an expected Core resource")
        assertEqual(progression.initialValue, values[1], name .. " initial resource value for " .. progression.resourceRef)
        assertEqual(progression.perLevelValue, values[2], name .. " per-level resource value for " .. progression.resourceRef)
        remainingResources[progression.resourceRef] = nil
    end
    assertTrue(next(remainingResources) == nil, name .. " includes Health and Mana")
end

assertClass("c4a91e7d", 2, "shaman01", "Shaman", {
    ["f82db71a:zfqm8dxp"] = { 1, 1.08 },
    ["f82db71a:xqz0daz2"] = { 0, 0.59 },
    ["f82db71a:ygjno50i"] = { 1, 1.25 },
    ["f82db71a:75y3a8ib"] = { 1, 1.17 },
    ["f82db71a:kec9rhli"] = { 2, 1.32 },
}, {
    ["f82db71a:q2ktkztt"] = { 27, 21.24 },
    ["f82db71a:4c8mfm99"] = { 53, 24.86 },
})

assertClass("e8f3b2c6", 20, "warlock1", "Warlock", {
    ["f82db71a:zfqm8dxp"] = { 0, 0.42 },
    ["f82db71a:xqz0daz2"] = { 0, 0.51 },
    ["f82db71a:ygjno50i"] = { 1, 0.75 },
    ["f82db71a:75y3a8ib"] = { 2, 1.49 },
    ["f82db71a:kec9rhli"] = { 2, 1.58 },
}, {
    ["f82db71a:q2ktkztt"] = { 23, 23.58 },
    ["f82db71a:4c8mfm99"] = { 59, 22.27 },
}, 1, 5)

local shamanDataset = definitions["c4a91e7d"].dataset
local warlockDataset = definitions["e8f3b2c6"].dataset
local coreDataset = definitions["f82db71a"].dataset
assertEqual(definitions["c4a91e7d"].version, 2, "Shaman dataset version")
assertEqual(#shamanDataset.auras, 23, "Shaman aura count")
assertEqual(#shamanDataset.spells, 30, "Shaman spell count")
assertEqual(definitions["e8f3b2c6"].version, 20, "Warlock dataset version")
assertEqual(definitions["f82db71a"].version, 52, "Core dataset version")
assertEqual(#warlockDataset.auras, 22, "Warlock aura count")
assertEqual(#warlockDataset.spells, 40, "Warlock spell count")
assertEqual(#warlockDataset.pets, 5, "Warlock pet count")
assertEqual(#warlockDataset.traits, 6, "Warlock trait count")

local function findByName(collection, name)
    for index = 1, #collection do
        if collection[index].name == name then return collection[index] end
    end
end

local function assertIds(collection, expected, label)
    assertEqual(#collection, #expected, label .. " count")
    for index, id in ipairs(expected) do
        assertEqual(collection[index].id, id, label .. " " .. index)
    end
end

assertIds(shamanDataset.auras, {
    "shflshka", "shfrshka", "shelmsta", "shsearta", "shmagmaa", "shearthba", "shstclwa",
    "shrockba", "shstskna", "shlshlda", "shftwaua", "shsoetha", "shfbrnda", "shfbrnwa",
    "shfrresa", "shfiresa", "shnaresa", "shwndfra", "shgoaira", "shfttoma", "shhstrma",
    "shmsprga", "shtrqara",
}, "Shaman aura")
assertIds(shamanDataset.spells, {
    "shlbolt1", "sherthsk", "shflmshk", "shfrtshk", "shlavabr", "shelmast", "shseartm",
    "shfirnva", "shmagmat", "shchnltn", "shearthbd", "shstclwt", "shrockbt", "shstsknt",
    "shlshldt", "shflmtwg", "shsoetht", "shfbrnwt", "shfrrest", "shfirest", "shnarest",
    "shwndfry", "shgoairt", "shfttomt", "shhealwv", "shhstrmt", "shleshwv", "shmsprgt",
    "shchnhel", "shtrqart",
}, "Shaman spell")

local warlockClass = warlockDataset.classes[1]
assertEqual(warlockClass.passiveTraitRefs[1], "e8f3b2c6:wldemarc", "Warlock Demonic Arcana passive reference")
assertEqual(#warlockClass.talentTraitRefs, 5, "Warlock talent trait selection")
for index, traitId in ipairs({ "wlsuppr6", "wldembr15", "wldance2", "wldemtac3", "wlaftrmt" }) do
    assertEqual(warlockClass.talentTraitRefs[index], "e8f3b2c6:" .. traitId, "Warlock talent trait reference " .. index)
end
for index, traitId in ipairs({ "wldemarc", "wlsuppr6", "wldembr15", "wldance2", "wldemtac3", "wlaftrmt" }) do
    assertEqual(warlockDataset.traits[index].id, traitId, "Warlock trait " .. index)
end
local demonicArcana = findByName(warlockDataset.traits, "Demonic Arcana")
assertEqual(demonicArcana.category, "Class Passive", "Warlock Demonic Arcana category")
assertEqual(demonicArcana.icon, "interface/icons/spell_warlock_demonsoul.blp", "Warlock Demonic Arcana icon")
assertEqual(demonicArcana.statBonuses[1].statRef, "f82db71a:qh534ffl", "Warlock Demonic Arcana demon damage stat")
assertEqual(demonicArcana.statBonuses[1].value, 5, "Warlock Demonic Arcana demon damage value")
local aftermathAura = findByName(warlockDataset.auras, "Aftermath")
assertEqual(aftermathAura.id, "wlaftrma", "Warlock Aftermath aura")
assertEqual(aftermathAura.effects[1].type, "control", "Warlock Aftermath control effect")
assertEqual(findByName(warlockDataset.traits, "Suppression").icon, "interface/icons/spell_shadow_unsummonbuilding.blp", "Warlock Suppression icon")
assertEqual(findByName(warlockDataset.traits, "Demonic Embrace").icon, "interface/icons/spell_shadow_metamorphosis.blp", "Warlock Demonic Embrace icon")
local danceOfTheWicked = findByName(warlockDataset.traits, "Dance of the Wicked")
assertEqual(danceOfTheWicked.icon, "interface/icons/ability_warlock_eradication.blp", "Warlock Dance of the Wicked icon")
assertEqual(danceOfTheWicked.statBonuses[1].statRef, "f82db71a:o6113cir", "Warlock Dance of the Wicked Dodge stat")
assertEqual(danceOfTheWicked.statBonuses[1].value, 5, "Warlock Dance of the Wicked Dodge value")
assertEqual(findByName(warlockDataset.traits, "Demonic Tactics").icon, "interface/icons/spell_shadow_demonictactics.blp", "Warlock Demonic Tactics icon")
assertEqual(findByName(warlockDataset.traits, "Aftermath").icon, "interface/icons/spell_fire_fire.blp", "Warlock Aftermath icon")

for _, unitInfo in ipairs({
    { name = "Felhunter", id = "felhnt01", presetCount = 3 },
    { name = "Sayaad", id = "sayaad01", presetCount = 3 },
}) do
    local unit = findByName(coreDataset.units, unitInfo.name)
    assertTrue(unit ~= nil, "Core includes " .. unitInfo.name)
    assertEqual(unit.id, unitInfo.id, unitInfo.name .. " unit ID")
    assertEqual(#unit.presets, unitInfo.presetCount, unitInfo.name .. " preset count")
end

local sayaad = findByName(coreDataset.units, "Sayaad")
assertEqual(#sayaad.appearances, 1, "Sayaad base appearance count")
assertEqual(sayaad.appearances[1].displayId, 159, "Sayaad base display ID")
assertEqual(sayaad.appearances[1].fileDataId, 1380189, "Sayaad base FileData ID")
assertEqual(sayaad.appearances[1].cam, 0.4, "Sayaad base camera distance")
for index, expected in ipairs({
    { name = "Temptress", displays = { 159, 2834 } },
    { name = "Seductress", displays = { 4162, 20214 } },
    { name = "Tormentor", displays = { 10923, 78470 } },
}) do
    local preset = sayaad.presets[index]
    assertEqual(preset.name, expected.name, expected.name .. " preset name")
    assertEqual(#preset.appearances, 2, expected.name .. " appearance count")
    for appearanceIndex, displayId in ipairs(expected.displays) do
        local appearance = preset.appearances[appearanceIndex]
        assertEqual(appearance.displayId, displayId, expected.name .. " display ID " .. appearanceIndex)
        assertEqual(appearance.fileDataId, 1380189, expected.name .. " FileData ID " .. appearanceIndex)
        assertEqual(appearance.cam, 0.4, expected.name .. " camera distance " .. appearanceIndex)
    end
end

local voidwalker = findByName(coreDataset.units, "Voidwalker")
assertEqual(voidwalker.presets[1].name, "Corruptor", "Voidwalker Corruptor preset name")
assertEqual(#voidwalker.presets[1].spells, 2, "Voidwalker Corruptor spell count")
assertEqual(voidwalker.presets[1].spells[1], "e8f3b2c6:wlcorru1", "Voidwalker Corruptor Corruption spell reference")
assertEqual(voidwalker.presets[1].spells[2], "e8f3b2c6:wlcshads", "Voidwalker Corruptor Curse of Shadows spell reference")
assertEqual(voidwalker.presets[2].name, "Tormenter", "Voidwalker Tormenter preset name")
assertEqual(#voidwalker.presets[2].spells, 2, "Voidwalker Tormenter spell count")
assertEqual(voidwalker.presets[2].spells[1], "f82db71a:6uix049h", "Voidwalker Tormenter Pet Attack spell reference")
assertEqual(voidwalker.presets[2].spells[2], "e8f3b2c6:wltorm01", "Voidwalker Tormenter Torment spell reference")

for _, petInfo in ipairs({
    {
        name = "Summoned Felguard",
        unitRef = "f82db71a:felgrd01",
        spells = { "f82db71a:6uix049h", "7bbb4cb9:e0mooybr", "e8f3b2c6:wllgstr1" },
    },
    {
        name = "Summoned Imp",
        unitRef = "f82db71a:imp00001",
        spells = { "f82db71a:6uix049h", "d7c874c4:68dy7na1", "e8f3b2c6:wlbldp01", "e8f3b2c6:wlflmwr1" },
    },
    {
        name = "Summoned Voidwalker",
        unitRef = "f82db71a:voidw001",
        spells = { "e8f3b2c6:wlshwads", "e8f3b2c6:wltorm01", "f82db71a:6uix049h" },
    },
    {
        name = "Summoned Felhunter",
        unitRef = "f82db71a:felhnt01",
        spells = { "f82db71a:6uix049h", "e8f3b2c6:wldevmn1", "e8f3b2c6:wlspklk1" },
    },
    {
        name = "Summoned Sayaad",
        unitRef = "f82db71a:sayaad01",
        spells = { "f82db71a:6uix049h", "e8f3b2c6:wlwhipl1", "e8f3b2c6:wlcharm1" },
    },
}) do
    local pet = findByName(warlockDataset.pets, petInfo.name)
    assertTrue(pet ~= nil, "Warlock includes " .. petInfo.name)
    assertEqual(pet.unitRef, petInfo.unitRef, petInfo.name .. " unit reference")
    assertEqual(#pet.spells, #petInfo.spells, petInfo.name .. " spell count")
    for _, spellRef in ipairs(petInfo.spells) do
        local found = false
        for _, petSpellRef in ipairs(pet.spells) do
            if petSpellRef == spellRef then
                found = true
                break
            end
        end
        assertTrue(found, petInfo.name .. " includes " .. spellRef)
    end
end

for _, summonInfo in ipairs({
    { name = "Summon Felhunter", unitRef = "f82db71a:felhnt01" },
    { name = "Summon Sayaad", unitRef = "f82db71a:sayaad01" },
}) do
    local spell = findByName(warlockDataset.spells, summonInfo.name)
    local effect = spell and spell.components and spell.components[1] and spell.components[1].effect
    assertTrue(type(effect) == "table", summonInfo.name .. " has a summon effect")
    assertEqual(effect.type, "summon_pet", summonInfo.name .. " uses summon_pet")
    assertEqual(effect.unitRef, summonInfo.unitRef, summonInfo.name .. " unit reference")
end

for _, name in ipairs({
    "Shadow Bolt", "Immolate", "Searing Pain", "Rain of Fire", "Hellfire", "Soul Fire",
    "Corruption", "Life Tap", "Curse of Agony", "Curse of Weakness", "Fear", "Drain Soul",
    "Drain Life", "Drain Mana", "Chaos Bolt", "Curse of Tongues", "Curse of Elements",
    "Curse of Shadows", "Death Coil", "Howl of Terror", "Demon Skin", "Banish", "Shadow Ward",
    "Summon Felguard", "Summon Imp", "Summon Voidwalker", "Fel Fireball", "Rain of Felfire",
    "Fel Immolate", "Siphon Life", "Summon Sayaad", "Summon Felhunter", "Blood Pact", "Flame Ward",
    "Torment", "Legion Strike", "Whiplash", "Charm", "Devour Mana", "Spell Lock",
}) do
    assertTrue(findByName(warlockDataset.spells, name) ~= nil, "Warlock includes " .. name)
end
for _, name in ipairs({
    "Immolate", "Corruption", "Curse of Agony", "Curse of Weakness", "Fear",
    "Curse of Tongues", "Curse of Elements", "Curse of Shadows", "Howl of Terror",
    "Demon Skin", "Banish", "Shadow Ward", "Fel Fireball", "Fel Immolate", "Siphon Life",
    "Siphoned Life", "Blood Pact", "Flame Ward", "Legion Strike", "Charm", "Spell Lock",
}) do
    local aura = findByName(warlockDataset.auras, name)
    assertTrue(aura ~= nil, "Warlock includes " .. name .. " aura")
    assertEqual(aura.description, "", name .. " aura keeps its description generator-owned")
    assertEqual(aura.tooltipTemplate, false, name .. " aura uses generated descriptions")
    assertTrue(aura.tooltipTemplateData == nil, name .. " aura has no hand-authored tooltip payload")
end

for index = 1, #warlockDataset.spells do
    local spell = warlockDataset.spells[index]
    assertEqual(spell.description, "", spell.name .. " keeps its description generator-owned")
    assertEqual(spell.tooltipTemplate, false, spell.name .. " uses generated descriptions")
    assertTrue(spell.tooltipTemplateData == nil, spell.name .. " has no hand-authored tooltip payload")
end

local knownAuraRefs = {}
for index = 1, #warlockDataset.auras do
    local aura = warlockDataset.auras[index]
    knownAuraRefs["e8f3b2c6:" .. aura.id] = true
end
for index = 1, #warlockDataset.spells do
    local spell = warlockDataset.spells[index]
    for componentIndex = 1, #spell.components do
        local effect = spell.components[componentIndex].effect
        if effect.type == "apply_aura" then
            assertTrue(knownAuraRefs[effect.auraRef] == true, spell.name .. " references a packaged Warlock aura")
        end
    end
end

local toc = assert(io.open("RPEngine2.toc", "r"))
local tocText = toc:read("*a")
toc:close()
assertTrue(tocText:find("data/default/classes/shaman.lua", 1, true) ~= nil, "Shaman is registered in the packaged TOC")
assertTrue(tocText:find("data/default/classes/warlock.lua", 1, true) ~= nil, "Warlock is registered in the packaged TOC")

local ruleset = assert(io.open("data/default/Ruleset.lua", "r"))
local rulesetText = ruleset:read("*a")
ruleset:close()
for _, reference in ipairs({ "c4a91e7d:shaman01", "e8f3b2c6:warlock1", '"c4a91e7d"', '"e8f3b2c6"' }) do
    assertTrue(rulesetText:find(reference, 1, true) ~= nil, "Default ruleset includes " .. reference)
end

print("ClassBaseStatsDatasetTest passed")
