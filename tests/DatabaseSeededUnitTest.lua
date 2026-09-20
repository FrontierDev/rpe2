local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertNotSeeded(stats, statRef, message)
    for index = 1, #(stats or {}) do
        if stats[index].statRef == statRef then
            error(message .. ": unexpectedly seeded " .. statRef, 2)
        end
    end
end

local Addon = {
    Internal = { Database = { Classes = {} } },
    Data = { DefaultDatasets = {} },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("core/classes/Unit.lua")

local packagedCore
Addon.Data.DefaultDatasets.Register = function(_, definition)
    packagedCore = definition.dataset
    -- The packaged Core dataset is identified by this stable ref namespace.
    packagedCore.id = "f82db71a"
    return definition
end
loadAddonFile("data/default/core.lua")

loadAddonFile("core/internal/database/Database.lua")

local Database = Addon.Internal.Database
Database.Datasets.datasets[packagedCore.id] = packagedCore

local createdUnit = Database.CreateDatasetEntry(packagedCore.id, "units")
assert(createdUnit, "Core dataset Unit creation should succeed")

local expectedByRef = {}
local expectedOrder = {}
for index = 1, #(packagedCore.stats or {}) do
    local stat = packagedCore.stats[index]
    if stat and stat.id and stat.seedNPCStat == true then
        local statRef = packagedCore.id .. ":" .. stat.id
        expectedByRef[statRef] = tonumber(stat.baseValue) or 0
        expectedOrder[#expectedOrder + 1] = statRef
    end
end

assertEqual(#createdUnit.stats, #expectedOrder, "new Unit contains every and only Core stat marked for seeding")
local seenRefs = {}
for index = 1, #createdUnit.stats do
    local row = createdUnit.stats[index]
    assertEqual(row.statRef, expectedOrder[index], "seed order follows Core stat definitions")
    assertEqual(row.initialValue, expectedByRef[row.statRef], "seed uses the Core baseValue")
    assertEqual(row.perLevelValue, 0, "seeded Core stats start with zero per-level growth")
    assertEqual(row.value, nil, "seeded Unit stats use the canonical progression schema")
    assertEqual(seenRefs[row.statRef], nil, "seeded stat refs are unique")
    seenRefs[row.statRef] = true
end

local function findCoreStat(name)
    for index = 1, #(packagedCore.stats or {}) do
        local stat = packagedCore.stats[index]
        if stat and stat.name == name then
            return stat
        end
    end
end

local function assertSeedValue(statName, expectedValue)
    local stat = findCoreStat(statName)
    assert(stat, "Core stat definition exists: " .. statName)
    local row = nil
    for index = 1, #createdUnit.stats do
        if createdUnit.stats[index].statRef == packagedCore.id .. ":" .. stat.id then
            row = createdUnit.stats[index]
            break
        end
    end
    assert(row, "new Core Unit seeds " .. statName)
    assertEqual(row.initialValue, expectedValue, statName .. " uses expected base value")
end

assertSeedValue("Movement Speed", 30)
assertSeedValue("Shadow Resistance", 0)
assertSeedValue("Holy Resistance", 0)
assertEqual(findCoreStat("Movement Speed").id, "s1mt6jh9", "Movement Speed uses its Core stat ref")
assertEqual(findCoreStat("Shadow Resistance").id, "itpo751d", "Shadow Resistance uses its Core stat ref")
assertEqual(findCoreStat("Holy Resistance").id, "hlyrsstn", "Holy Resistance uses its Core stat ref")
assertEqual(findCoreStat("Movement Speed").seedNPCStat, true, "Movement Speed is marked for NPC seeding")
assertEqual(findCoreStat("Shadow Resistance").seedNPCStat, true, "Shadow Resistance is marked for NPC seeding")
assertEqual(findCoreStat("Holy Resistance").seedNPCStat, true, "Holy Resistance is marked for NPC seeding")
assertEqual(findCoreStat("Damage Done").seedNPCStat, false, "Damage Done stays unseeded")

local preservedSeedNames = {
    "Armor",
    "Melee Hit Chance",
    "Ranged Hit Chance",
    "Spell Hit Chance",
    "Parry Chance",
    "Dodge Chance",
    "Block Chance",
    "Magic Resistance",
    "Melee Attack Power",
    "Ranged Attack Power",
    "Spell Power",
    "Melee Crit. Chance",
    "Ranged Crit. Chance",
    "Spell Crit. Chance",
    "Healing Power",
    "Fire Resistance",
    "Frost Resistance",
    "Nature Resistance",
    "Arcane Resistance",
    "Resource Regeneration",
}
for index = 1, #preservedSeedNames do
    local stat = findCoreStat(preservedSeedNames[index])
    assert(stat, "Core stat definition exists: " .. preservedSeedNames[index])
    assertEqual(stat.seedNPCStat, true, preservedSeedNames[index] .. " remains marked for seeding")
    assert(seenRefs[packagedCore.id .. ":" .. stat.id], preservedSeedNames[index] .. " remains seeded")
end

local excludedNames = {
    "Strength",
    "Agility",
    "Intellect",
    "Spirit",
    "Stamina",
    "Dismount Resistance",
    "Damage Done",
    "Damage Reduction",
    "Healing Done",
    "Healing Received",
    "Threat Generated",
    "Defense Rating",
}
for index = 1, #excludedNames do
    local stat = findCoreStat(excludedNames[index])
    assert(stat, "Core stat definition exists: " .. excludedNames[index])
    assertNotSeeded(createdUnit.stats, packagedCore.id .. ":" .. stat.id, excludedNames[index] .. " remains absent")
end
for index = 1, #(packagedCore.stats or {}) do
    local stat = packagedCore.stats[index]
    if stat and stat.name and stat.name:match("^Damage vs%.") then
        assertNotSeeded(createdUnit.stats, packagedCore.id .. ":" .. stat.id, stat.name .. " remains absent")
    end
end

local serializedUnit = Addon.Internal.Database.Classes.Unit.FromTable(createdUnit):ToTable()
assertEqual(#serializedUnit.stats, #createdUnit.stats, "Unit serialization round trip keeps the seeded stat count")
for index = 1, #createdUnit.stats do
    local original = createdUnit.stats[index]
    local roundTrip = serializedUnit.stats[index]
    assertEqual(roundTrip.statRef, original.statRef, "Unit serialization round trip keeps stat refs")
    assertEqual(roundTrip.initialValue, original.initialValue, "Unit serialization round trip keeps initial values")
    assertEqual(roundTrip.perLevelValue, original.perLevelValue, "Unit serialization round trip keeps per-level values")
end

local emptySeedDataset = {
    id = "no-seed",
    name = "No seeded stats",
    stats = {
        { id = "manual-only", name = "Manual Only", baseValue = 12, seedNPCStat = false },
    },
    units = {},
}
Database.Datasets.datasets[emptySeedDataset.id] = emptySeedDataset
local unchangedUnit = Database.CreateDatasetEntry(emptySeedDataset.id, "units")
assert(unchangedUnit, "Unit creation in a dataset without seeded stats should succeed")
assertEqual(#unchangedUnit.stats, 0, "datasets without seeded stats still create Units with no stat rows")

print("DatabaseSeededUnitTest passed")
