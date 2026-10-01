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
loadAddonFile("data/default/classes/death_knight.lua", Addon)
loadAddonFile("data/default/classes/monk.lua", Addon)
loadAddonFile("data/default/classes/demon_hunter.lua", Addon)
loadAddonFile("data/default/classes/evoker.lua", Addon)

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
    local expectedResourceCount = 0
    for _ in pairs(expectedResources) do
        expectedResourceCount = expectedResourceCount + 1
    end
    assertEqual(#class.resourceProgressions, expectedResourceCount, name .. " resource progression count")
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

assertClass("c4a91e7d", 10, "shaman01", "Shaman", {
    ["f82db71a:zfqm8dxp"] = { 1, 1.08 },
    ["f82db71a:xqz0daz2"] = { 0, 0.59 },
    ["f82db71a:ygjno50i"] = { 1, 1.25 },
    ["f82db71a:75y3a8ib"] = { 1, 1.17 },
    ["f82db71a:kec9rhli"] = { 2, 1.32 },
}, {
    ["f82db71a:q2ktkztt"] = { 27, 21.24 },
    ["f82db71a:4c8mfm99"] = { 53, 24.86 },
}, 0, 14)

assertClass("e8f3b2c6", 22, "warlock1", "Warlock", {
    ["f82db71a:zfqm8dxp"] = { 0, 0.42 },
    ["f82db71a:xqz0daz2"] = { 0, 0.51 },
    ["f82db71a:ygjno50i"] = { 1, 0.75 },
    ["f82db71a:75y3a8ib"] = { 2, 1.49 },
    ["f82db71a:kec9rhli"] = { 2, 1.58 },
}, {
    ["f82db71a:q2ktkztt"] = { 23, 23.58 },
    ["f82db71a:4c8mfm99"] = { 59, 22.27 },
}, 1, 5)

assertClass("dknight1", 1, "dkclass1", "Death Knight", {
    ["f82db71a:zfqm8dxp"] = { 3, 1.64 },
    ["f82db71a:xqz0daz2"] = { 0, 1.02 },
    ["f82db71a:ygjno50i"] = { 2, 1.49 },
    ["f82db71a:75y3a8ib"] = { 0, 0.17 },
    ["f82db71a:kec9rhli"] = { 0, 0.42 },
}, {
    ["f82db71a:q2ktkztt"] = { 20, 28.29 },
}, 0, 0)

assertClass("monkdata", 1, "monk0001", "Monk", {
    ["f82db71a:zfqm8dxp"] = { 1, 0.75 },
    ["f82db71a:xqz0daz2"] = { 0, 0.68 },
    ["f82db71a:ygjno50i"] = { 0, 0.85 },
    ["f82db71a:75y3a8ib"] = { 2, 1.32 },
    ["f82db71a:kec9rhli"] = { 2, 1.49 },
}, {
    ["f82db71a:q2ktkztt"] = { 33, 24.58 },
    ["f82db71a:4c8mfm99"] = { 17, 20.8 },
}, 0, 0)

assertClass("dhunter1", 1, "dhclass1", "Demon Hunter", {
    ["f82db71a:zfqm8dxp"] = { 1, 1 },
    ["f82db71a:xqz0daz2"] = { 3, 1.81 },
    ["f82db71a:ygjno50i"] = { 1, 0.92 },
    ["f82db71a:75y3a8ib"] = { 0, 0.25 },
    ["f82db71a:kec9rhli"] = { 0, 0.51 },
}, {
    ["f82db71a:q2ktkztt"] = { 25, 25.39 },
}, 0, 0)

assertClass("evokdata", 1, "evoker01", "Evoker", {
    ["f82db71a:zfqm8dxp"] = { 0, 0.17 },
    ["f82db71a:xqz0daz2"] = { 0, 0.25 },
    ["f82db71a:ygjno50i"] = { 0, 0.42 },
    ["f82db71a:75y3a8ib"] = { 3, 1.73 },
    ["f82db71a:kec9rhli"] = { 2, 1.66 },
}, {
    ["f82db71a:q2ktkztt"] = { 31, 22.53 },
    ["f82db71a:4c8mfm99"] = { 100, 19.88 },
}, 0, 0)

local shamanDataset = definitions["c4a91e7d"].dataset
local warlockDataset = definitions["e8f3b2c6"].dataset
local coreDataset = definitions["f82db71a"].dataset
assertEqual(definitions["c4a91e7d"].version, 10, "Shaman dataset version")
assertEqual(#shamanDataset.auras, 28, "Shaman aura count")
assertEqual(#shamanDataset.spells, 32, "Shaman spell count")
assertEqual(#shamanDataset.traits, 14, "Shaman trait count")
assertEqual(#shamanDataset.items, 64, "Shaman item count")
assertEqual(definitions["e8f3b2c6"].version, 22, "Warlock dataset version")
assertEqual(definitions["f82db71a"].version, 54, "Core dataset version")
assertEqual(#warlockDataset.auras, 22, "Warlock aura count")
assertEqual(#warlockDataset.spells, 40, "Warlock spell count")
assertEqual(#warlockDataset.items, 32, "Warlock item count")
assertEqual(#warlockDataset.pets, 5, "Warlock pet count")
assertEqual(#warlockDataset.traits, 6, "Warlock trait count")

local function findByName(collection, name)
    for index = 1, #collection do
        if collection[index].name == name then return collection[index] end
    end
end

local fury = findByName(coreDataset.resources, "Fury")
assertTrue(fury ~= nil, "Core includes Fury resource")
assertEqual(fury.baseValue, 100, "Fury maximum")
assertEqual(fury.startsAtZero, true, "Fury starts at zero")
assertEqual(fury.regenMode, "manual", "Fury regen mode")
assertEqual(fury.regenPerSecond, 0, "Fury regen per turn")
assertEqual(fury.special, false, "Fury is a primary resource")
assertEqual(fury.color.r, 0.8, "Fury red channel")
assertEqual(fury.color.g, 0.32, "Fury green channel")
assertEqual(fury.color.b, 0.05, "Fury blue channel")

local runes = findByName(coreDataset.resources, "Runes")
assertTrue(runes ~= nil, "Core includes Runes resource")
assertEqual(runes.baseValue, 6, "Runes maximum")
assertEqual(runes.startsAtZero, false, "Runes start full")
assertEqual(runes.regenMode, "manual", "Runes regen mode")
assertEqual(runes.regenPerSecond, 1, "Runes regen per turn")
assertEqual(runes.special, false, "Runes are a primary resource")

local essence = findByName(coreDataset.resources, "Essence")
assertTrue(essence ~= nil, "Core includes Essence resource")
assertEqual(essence.baseValue, 5, "Essence maximum")
assertEqual(essence.startsAtZero, false, "Essence starts full")
assertEqual(essence.regenMode, "manual", "Essence regen mode")
assertEqual(essence.regenPerSecond, 1, "Essence regen per turn")
assertEqual(essence.special, true, "Essence is a special resource")

assertEqual(findByName(shamanDataset.auras, "Healing Stream").icon, "interface/icons/inv_spear_04.blp", "Healing Stream aura icon")
assertEqual(findByName(shamanDataset.spells, "Healing Stream Totem").icon, "interface/icons/inv_spear_04.blp", "Healing Stream Totem spell icon")
local riptideAura = findByName(shamanDataset.auras, "Riptide")
local riptideSpell = findByName(shamanDataset.spells, "Riptide")
assertEqual(riptideAura.duration, 3, "Riptide aura duration")
assertEqual(#riptideAura.effects, 2, "Riptide aura effect count")
assertEqual(riptideAura.effects[2].statRef, "f82db71a:ok80ohz3", "Riptide Healing Received stat")
assertEqual(riptideSpell.cooldown, 3, "Riptide cooldown")
assertEqual(#riptideSpell.components, 1, "Riptide component count")
assertEqual(riptideSpell.components[1].effect.duration, 3, "Riptide component duration")
assertEqual(#riptideSpell.tooltipTemplateData.auraSections, 1, "Riptide tooltip aura section count")
assertEqual(riptideSpell.tooltipTemplateData.auraSections[1].auraRef, "c4a91e7d:shrptdha", "Riptide tooltip aura reference")
assertEqual(riptideSpell.tooltipTemplateData.auraSections[1].tokens[2].effectIndex, 2, "Riptide tooltip Healing Received token")
assertEqual(riptideSpell.tooltipTemplateData.auraSections[1].duration, 3, "Riptide tooltip aura duration")
assertEqual(riptideSpell.tooltipTemplateData.mainText, "Apply Riptide to an ally for 3 turns.", "Riptide tooltip")
assertTrue(findByName(shamanDataset.auras, "Riptide - Healing Received") == nil, "Riptide uses one aura")

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
    "shmsprga", "shtrqara", "shrptdha", "sheashla", "sheldvau", "shflryau", "shanchea",
}, "Shaman aura")
assertIds(shamanDataset.spells, {
    "shlbolt1", "sherthsk", "shflmshk", "shfrtshk", "shlavabr", "shelmast", "shseartm",
    "shfirnva", "shmagmat", "shchnltn", "shearthbd", "shstclwt", "shrockbt", "shstsknt",
    "shlshldt", "shflmtwg", "shsoetht", "shfbrnwt", "shfrrest", "shfirest", "shnarest",
    "shwndfry", "shgoairt", "shfttomt", "shhealwv", "shhstrmt", "shleshwv", "shmsprgt",
    "shchnhel", "shtrqart", "shriptid", "sheashld",
}, "Shaman spell")

assertIds(shamanDataset.traits, {
    "shelward", "sheldevt", "shancnow", "shthstrk", "shshspec", "shantici", "shflurry",
    "shtoughn", "shwepmst", "shanchel", "shnatgui", "shhealgr", "shtidmas", "shpurify",
}, "Shaman trait")

assertIds(shamanDataset.items, {
    "s05echst",
    "s05efeet",
    "s05ehnds",
    "s05ehead",
    "s05elegs",
    "s05eshld",
    "s05ewais",
    "s05ewrst",
    "s05nchst",
    "s05nfeet",
    "s05nhnds",
    "s05nhead",
    "s05nlegs",
    "s05nshld",
    "s05nwais",
    "s05nwrst",
    "s05rchst",
    "s05rfeet",
    "s05rhnds",
    "s05rhead",
    "s05rlegs",
    "s05rshld",
    "s05rwais",
    "s05rwrst",
    "s05tchst",
    "s05tfeet",
    "s05thnds",
    "s05thead",
    "s05tlegs",
    "s05tshld",
    "s05twais",
    "s05twrst",
    "s2elchst",
    "s2elfeet",
    "s2elhnds",
    "s2elhead",
    "s2ellegs",
    "s2elshld",
    "s2elwais",
    "s2elwrst",
    "s2enchst",
    "s2enfeet",
    "s2enhnds",
    "s2enhead",
    "s2enlegs",
    "s2enshld",
    "s2enwais",
    "s2enwrst",
    "s2rhchst",
    "s2rhfeet",
    "s2rhhnds",
    "s2rhhead",
    "s2rhlegs",
    "s2rhshld",
    "s2rhwais",
    "s2rhwrst",
    "s2tnchst",
    "s2tnfeet",
    "s2tnhnds",
    "s2tnhead",
    "s2tnlegs",
    "s2tnshld",
    "s2tnwais",
    "s2tnwrst",
}, "Shaman item")

assertIds(warlockDataset.items, {
    "wl2drobe",
    "wl2dboot",
    "wl2dglov",
    "wl2dhead",
    "wl2dlegs",
    "wl2dshld",
    "wl2dbelt",
    "wl2dwrst",
    "wl2tgarb",
    "wl2ttrds",
    "wl2thand",
    "wl2tcowl",
    "wl2tpant",
    "wl2tshld",
    "wl2tcord",
    "wl2twrap",
    "w05drobe",
    "w05dsand",
    "w05dwrap",
    "w05dmask",
    "w05dlegs",
    "w05dmant",
    "w05dbelt",
    "w05dbrac",
    "w05tembr",
    "w05ttrds",
    "w05tgrsp",
    "w05thood",
    "w05tpant",
    "w05tepau",
    "w05tcord",
    "w05tbind",
}, "Warlock item")

local shamanClass = shamanDataset.classes[1]
for index, traitId in ipairs({
    "shelward", "sheldevt", "shancnow", "shthstrk", "shshspec", "shantici", "shflurry",
    "shtoughn", "shwepmst", "shanchel", "shnatgui", "shhealgr", "shtidmas", "shpurify",
}) do
    assertEqual(shamanClass.talentTraitRefs[index], "c4a91e7d:" .. traitId, "Shaman talent trait reference " .. index)
end

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
