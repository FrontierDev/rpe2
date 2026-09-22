local function assertEqual(actual, expected, message)
    if actual ~= expected then error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2) end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, nested in pairs(value) do copy[key] = deepCopy(nested) end
    return copy
end

local function deepEqual(left, right)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    for key, value in pairs(left) do if not deepEqual(value, right[key]) then return false end end
    for key, value in pairs(right) do if not deepEqual(value, left[key]) then return false end end
    return true
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local savedDatasets = rawget(_G, "RPEngineDatasetDB")
local savedRulesets = rawget(_G, "RPEngineRulesetDB")
local Addon = { Internal = {}, Data = {} }

loadAddonFile("core/internal/database/Dependecies.lua", Addon)
loadAddonFile("core/internal/database/Database.lua", Addon)
loadAddonFile("core/internal/ruleset/Rules.lua", Addon)
loadAddonFile("core/internal/ruleset/Ruleset.lua", Addon)
for _, path in ipairs({
    "core/classes/Condition.lua", "core/classes/Unit.lua", "core/classes/Mount.lua",
    "core/classes/Pet.lua", "core/classes/Spell.lua", "core/classes/Trait.lua",
    "core/classes/Skill.lua", "core/classes/Item.lua", "core/classes/Stat.lua",
    "core/classes/Resource.lua", "core/classes/Race.lua", "core/classes/Class.lua",
    "core/classes/ItemSlot.lua", "core/classes/WeaponType.lua", "core/classes/DamageSchool.lua",
    "core/classes/Loot.lua", "core/classes/Recipe.lua", "core/classes/Aura.lua",
    "core/classes/Interaction.lua", "core/classes/Achievement.lua", "core/classes/GuildSetting.lua",
    "core/classes/Currency.lua",
}) do loadAddonFile(path, Addon) end
loadAddonFile("core/internal/Registry.lua", Addon)

local Database = Addon.Internal.Database
local Registry = Addon.Internal.Registry

local function datasetFixture()
    return {
        id = "compat", name = "Compatibility", dependencies = { "foo", "core", "foo" },
        units = { { id = "unit", name = "Unit", resources = { { resourceRef = "compat:health", initialValue = 10, perPlayer = true } } } },
        items = { { id = "item", name = "Item", itemType = "material", useSpellRef = "compat:spell", staleItemField = "old" } },
        spells = { { id = "spell", name = "Spell", cooldown = 1, unknownSpellField = true } },
        loot = { { id = "loot", name = "Loot", entries = { { id = "entry", type = "item", ref = "compat:item" } }, items = { "legacy-a" } } },
    }
end

local function datasetExport(dataset)
    rawset(_G, "RPEngineDatasetDB", { datasets = { compat = dataset }, activeByChar = {}, activatedDatasets = {} })
    Database.Datasets = nil
    return assert(Database.ExportDatasetForCompatibilityHash("compat"))
end

local first = datasetFixture()
local second = datasetFixture()
second.oldMigrationFlag = "different"
second.units[1].resources[1].perPlayer = false
second.items[1].staleItemField = "different"
second.items[1].useSpellRef = "compat:other-spell"
second.spells[1].unknownSpellField = "different"
second.loot[1].items = { "legacy-b" }
second.dependencies = { "core", "foo" }
assertEqual(datasetExport(first), datasetExport(second), "historical dataset fields do not affect compatibility export")

local changed = datasetFixture()
changed.spells[1].cooldown = 2
assertTrue(datasetExport(first) ~= datasetExport(changed), "current Spell fields affect compatibility export")
changed = datasetFixture()
changed.loot[1].entries[1].ref = "compat:other-item"
assertTrue(datasetExport(first) ~= datasetExport(changed), "current Loot entries affect compatibility export")

local ordered = datasetFixture()
ordered.items[2] = { id = "item-z", name = "Z" }
local reversed = datasetFixture()
reversed.items = { { id = "item-z", name = "Z" }, reversed.items[1] }
assertEqual(datasetExport(ordered), datasetExport(reversed), "dataset entry order is irrelevant")

local legacyAuthor = datasetFixture()
local legacySnapshot = deepCopy(legacyAuthor)
local savedUnitFullName = rawget(_G, "UnitFullName")
rawset(_G, "UnitFullName", function() return "First", "Realm" end)
local firstLegacyCanonical = Database.BuildDatasetCompatibilityRecord(legacyAuthor)
rawset(_G, "UnitFullName", function() return "Second", "Realm" end)
local secondLegacyCanonical = Database.BuildDatasetCompatibilityRecord(legacySnapshot)
rawset(_G, "UnitFullName", savedUnitFullName)
assertTrue(deepEqual(firstLegacyCanonical, secondLegacyCanonical), "missing dataset author is deterministic")
assertTrue(deepEqual(legacyAuthor, legacySnapshot), "dataset compatibility projection is pure")

local function rulesetExport(ruleset)
    rawset(_G, "RPEngineRulesetDB", { rulesets = { rules = ruleset }, activeByChar = { ["unknown-player"] = "rules" } })
    Database.Rulesets = nil
    return assert(Database.ExportRulesetForCompatibilityHash("rules"))
end

local rulesA = { id = "rules", name = "Rules", rules = {} }
local rulesB = { id = "rules", name = "Rules", oldMigrationFlag = true, rules = {
    legacy_category = { old_rule = 123 }, character = { old_removed_rule = true },
} }
assertEqual(rulesetExport(rulesA), rulesetExport(rulesB), "unknown ruleset fields and rules are ignored")

local explicitDefaults = { id = "rules", name = "Rules", rules = { character = { use_level_system = false } } }
assertEqual(rulesetExport(rulesA), rulesetExport(explicitDefaults), "missing rules equal explicit defaults")
local changedRules = { id = "rules", name = "Rules", rules = { character = { use_level_system = true } } }
assertTrue(rulesetExport(rulesA) ~= rulesetExport(changedRules), "current rules affect compatibility export")
local rulesSnapshot = deepCopy(rulesA)
rawset(_G, "UnitFullName", function() return "First", "Realm" end)
local firstRulesCanonical = Database.BuildRulesetCompatibilityRecord(rulesA)
rawset(_G, "UnitFullName", function() return "Second", "Realm" end)
local secondRulesCanonical = Database.BuildRulesetCompatibilityRecord(rulesSnapshot)
rawset(_G, "UnitFullName", savedUnitFullName)
assertTrue(deepEqual(firstRulesCanonical, secondRulesCanonical), "missing ruleset author is deterministic")
assertTrue(deepEqual(rulesA, rulesSnapshot), "ruleset compatibility projection is pure")

-- Exercise Registry's production entry points, including its dedicated
-- ruleset compatibility exporter.
rawset(_G, "RPEngineDatasetDB", { datasets = { compat = datasetFixture() }, activeByChar = {}, activatedDatasets = { "compat" } })
rawset(_G, "RPEngineRulesetDB", { rulesets = { rules = rulesA }, activeByChar = { ["unknown-player"] = "rules" } })
Database.Datasets, Database.Rulesets = nil, nil
Addon.Internal.ConfigurationRevision = (Addon.Internal.ConfigurationRevision or 0) + 1
assertTrue(type(Registry:GenerateActivatedDatasetsHash()) == "string", "Registry hashes canonical datasets")
assertTrue(type(Registry:GenerateActiveRulesetHash()) == "string", "Registry hashes canonical rulesets")

rawset(_G, "RPEngineDatasetDB", savedDatasets)
rawset(_G, "RPEngineRulesetDB", savedRulesets)
Database.Datasets, Database.Rulesets = savedDatasets, savedRulesets
print("CompatibilityHashCanonicalizationTest passed")
