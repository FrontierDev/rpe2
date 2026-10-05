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

local Addon = {
    Name = "RPEngine2",
    Data = {},
    Internal = {},
    Debug = { Internal = function() end },
}

loadAddonFile("data/default/Datasets.lua", Addon)
loadAddonFile("data/default/core.lua", Addon)

local definitions = Addon.Data.DefaultDatasets.Definitions
local definition = definitions.f82db71a
assertTrue(type(definition) == "table", "Core dataset registers")
assertEqual(definition.version, 64, "Core dataset version")

local dataset = definition.dataset
assertTrue(type(dataset) == "table", "Core dataset payload exists")

local function indexUnique(collection, label)
    local indexed = {}
    for index = 1, #(collection or {}) do
        local entry = collection[index]
        assertTrue(type(entry) == "table" and type(entry.id) == "string", label .. " entry " .. index .. " has an ID")
        assertTrue(indexed[entry.id] == nil, label .. " ID is unique: " .. entry.id)
        indexed[entry.id] = entry
    end
    return indexed
end

local racesById = indexUnique(dataset.races, "Core race")
local traitsById = indexUnique(dataset.traits, "Core trait")
local aurasById = indexUnique(dataset.auras, "Core aura")
local statsById = indexUnique(dataset.stats, "Core stat")
local skillsById = indexUnique(dataset.skills, "Core skill")
local damageSchoolsById = indexUnique(dataset.damageSchools, "Core damage school")

assertEqual(#dataset.races, 18, "Core race count")
assertTrue(racesById.v17z463g ~= nil, "Human remains in Core")
assertTrue(racesById.xx3padtj ~= nil, "Dwarf remains in Core")

local expectedRaces = {
    nightelf = true,
    gnome001 = true,
    orc00001 = true,
    undead01 = true,
    tauren01 = true,
    troll001 = true,
    draenei1 = true,
    bloodelf = true,
    worgen01 = true,
    goblin01 = true,
    pandaren = true,
    darkiron = true,
    mechagnm = true,
    nightbrn = true,
    vulpera1 = true,
    dracthyr = true,
}
for raceId in pairs(expectedRaces) do
    assertTrue(racesById[raceId] ~= nil, "documented race exists: " .. raceId)
end

local expectedTraits = {
    racnat10 = true,
    racarc10 = true,
    racshd10 = true,
    nequick1 = true,
    neelus05 = true,
    gnexp005 = true,
    gneng015 = true,
    racaxe05 = true,
    orchrd10 = true,
    udtouch1 = true,
    taend005 = true,
    tabrawn1 = true,
    trbeast5 = true,
    racbow05 = true,
    racthr05 = true,
    trregen5 = true,
    drhero01 = true,
    drgem005 = true,
    bearc010 = true,
    bemagic5 = true,
    worgcrit = true,
    worgaber = true,
    gobalch15 = true,
    pangrm15 = true,
    panboun5 = true,
    paninr05 = true,
    panepic5 = true,
    didung05 = true,
    diforge1 = true,
    dimass15 = true,
    difire15 = true,
    mgcombat = true,
    mgmast15 = true,
    mgfails5 = true,
    mgpinkie = true,
    nbanc15 = true,
    nbmagic1 = true,
    nbcantr5 = true,
    vulfire15 = true,
    vulnose1 = true,
    vulcamp5 = true,
    vultrik5 = true,
    drctawak = true,
    drcteye5 = true,
    drctglid = true,
    drctvis5 = true,
}
for traitId in pairs(expectedTraits) do
    assertTrue(traitsById[traitId] ~= nil, "documented racial trait exists: " .. traitId)
end
assertTrue(aurasById.drheroa1 ~= nil, "Draenei Heroic Presence aura exists")

local function fullRef(id)
    return "f82db71a:" .. id
end

local function assertRef(lookup, reference, label)
    local id = type(reference) == "string" and reference:match("^[^:]+:(.+)$") or nil
    assertTrue(id ~= nil and lookup[id] ~= nil, label .. " resolves: " .. tostring(reference))
end

for index = 1, #dataset.races do
    local race = dataset.races[index]
    for traitIndex = 1, #(race.traitRefs or {}) do
        local traitId = (race.traitRefs[traitIndex] or ""):match("^[^:]+:(.+)$")
        assertTrue(traitId ~= nil and traitsById[traitId] ~= nil,
            "race trait reference resolves: " .. tostring(race.traitRefs[traitIndex]))
    end
end

local function validateTraitReferences(value, label)
    if type(value) ~= "table" then return end
    for key, child in pairs(value) do
        if key == "statRef" then
            assertRef(statsById, child, label .. " stat reference")
        elseif key == "skillRef" then
            assertRef(skillsById, child, label .. " skill reference")
        elseif key == "auraRef" then
            assertRef(aurasById, child, label .. " aura reference")
        elseif key == "damageSchoolRef" then
            assertRef(damageSchoolsById, child, label .. " damage-school reference")
        elseif key == "damageSchoolRefs" then
            for schoolIndex = 1, #(child or {}) do
                assertRef(damageSchoolsById, child[schoolIndex], label .. " damage-school reference")
            end
        end
        validateTraitReferences(child, label .. "." .. tostring(key))
    end
end

for index = 1, #dataset.traits do
    validateTraitReferences(dataset.traits[index], "trait " .. tostring(dataset.traits[index].id))
end
for index = 1, #dataset.auras do
    validateTraitReferences(dataset.auras[index], "aura " .. tostring(dataset.auras[index].id))
end
for index = 1, #dataset.races do
    validateTraitReferences(dataset.races[index], "race " .. tostring(dataset.races[index].id))
end

local function assertTraitStat(traitId, statId, expectedValue, label)
    local trait = traitsById[traitId]
    local found = 0
    for index = 1, #(trait.statBonuses or {}) do
        local bonus = trait.statBonuses[index]
        if bonus.statRef == fullRef(statId) then
            found = found + 1
            assertEqual(bonus.value, expectedValue, label .. " value")
            assertEqual(bonus.operation, "flat", label .. " operation")
        end
    end
    assertEqual(found, 1, label .. " reference count")
end

for _, traitId in ipairs({ "bearc010", "gneng015", "dimass15", "drgem005", "gobalch15", "mgmast15", "nbanc15", "pangrm15" }) do
    local trait = traitsById[traitId]
    assertEqual(trait.skillBonuses[1].value, 15, "crafting racial bonus " .. traitId)
end
for _, traitId in ipairs({
    "didung05", "drcteye5", "drctglid", "drctvis5", "mgpinkie", "neelus05", "nbcantr5",
    "racaxe05", "panboun5", "paninr05", "panepic5", "racbow05", "racthr05", "vulcamp5", "vultrik5",
}) do
    local trait = traitsById[traitId]
    assertEqual(trait.skillBonuses[1].value, 5, "non-combat racial bonus " .. traitId)
end

assertTraitStat("racnat10", "pg0ytacb", 15, "Nature Resistance")
assertTraitStat("racarc10", "954yunb9", 15, "Arcane Resistance")
assertTraitStat("racshd10", "itpo751d", 15, "Shadow Resistance")
assertTraitStat("difire15", "0w7c7p09", 15, "Fireblood")
assertTraitStat("vulfire15", "0w7c7p09", 15, "Fire Resistance")
assertTraitStat("worgaber", "pg0ytacb", 8, "Worgen Aberration Nature")
assertTraitStat("worgaber", "itpo751d", 8, "Worgen Aberration Shadow")
assertTraitStat("bemagic5", "zs1nbz13", 1, "Blood Elf Magic Resistance")
assertEqual(#traitsById.worgaber.statBonuses, 2, "Worgen Aberration remains a split resistance")
assertEqual(#traitsById.bemagic5.statBonuses, 1, "Blood Elf Magic Resistance remains one stat")

local function assertSharedTrait(raceA, raceB, traitRef, label)
    local expected = fullRef(traitRef)
    local function hasReference(race)
        for index = 1, #(race.traitRefs or {}) do
            if race.traitRefs[index] == expected then return true end
        end
        return false
    end
    assertTrue(hasReference(racesById[raceA]), label .. " first race reference")
    assertTrue(hasReference(racesById[raceB]), label .. " second race reference")
end
assertSharedTrait("nightelf", "tauren01", "racnat10", "Nature Resistance sharing")
assertSharedTrait("gnome001", "nightbrn", "racarc10", "Arcane Resistance sharing")
assertSharedTrait("undead01", "draenei1", "racshd10", "Shadow Resistance sharing")

local function assertTraitNameUsesId(name, id)
    local count = 0
    for index = 1, #dataset.traits do
        local trait = dataset.traits[index]
        if trait.name == name then
            count = count + 1
            assertEqual(trait.id, id, name .. " uses the shared ID")
        end
    end
    assertEqual(count, 1, name .. " has no obsolete duplicate")
end
assertTraitNameUsesId("Nature Resistance", "racnat10")
assertTraitNameUsesId("Arcane Resistance", "racarc10")
assertTraitNameUsesId("Shadow Resistance", "racshd10")

-- Exercise the actual setup-wizard filtering method with the Core dataset as
-- its sole active dataset. An empty list exposes every race; a non-empty list
-- remains an exact reference filter.
local setupAddon = {
    UI = { BaseElement = {} },
    Client = {},
    Internal = { Database = {}, Registry = {}, Ruleset = {} },
}
local allowedRaceRefs = {}
setupAddon.Internal.Registry.GetActivatedDatasets = function()
    return { dataset }
end
setupAddon.Internal.Ruleset.GetActiveRuleset = function()
    return {}
end
setupAddon.Internal.Ruleset.GetRulesetRuleValueByKey = function(_, _, key, fallback)
    if key == "allowed_race_refs" then return allowedRaceRefs end
    return fallback
end
loadAddonFile("client/ui/windows/window_SetupWizard.lua", setupAddon)
local setupWizard = setupAddon.Client.UI.SetupWizard:Get()
assertEqual(#setupWizard:BuildAllowedRaceItems(), 18, "empty race allow-list exposes all Core races")
allowedRaceRefs = { fullRef("nightelf") }
local filteredRaces = setupWizard:BuildAllowedRaceItems()
assertEqual(#filteredRaces, 1, "explicit race allow-list filters Core races")
assertEqual(filteredRaces[1].value, fullRef("nightelf"), "explicit race allow-list reference")

print("CoreRaceDatasetTest passed")
