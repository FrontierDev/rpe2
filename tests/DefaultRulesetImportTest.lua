local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local function contains(values, expected)
    for index = 1, #values do
        if values[index] == expected then return true end
    end
    return false
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, addon)
end

local savedRulesetRoot = rawget(_G, "RPEngineRulesetDB")
local savedUnitFullName = rawget(_G, "UnitFullName")
local savedUnitName = rawget(_G, "UnitName")
local savedGetRealmName = rawget(_G, "GetRealmName")
rawset(_G, "UnitFullName", function() return "Alice", "TestRealm" end)
rawset(_G, "UnitName", nil)
rawset(_G, "GetRealmName", function() return "TestRealm" end)
local Addon = {
    Internal = {},
    Data = {},
}

loadAddonFile("core/internal/database/Database.lua", Addon)
loadAddonFile("data/default/Ruleset.lua", Addon)

local Database = Addon.Internal.Database
local DefaultRuleset = Addon.Data.DefaultRuleset
local CORE_RULESET_ID = "25076117"

local function resetRulesets()
    rawset(_G, "RPEngineRulesetDB", nil)
    Database.Rulesets = nil
end

-- This must exercise the exact packaged string through the canonical importer.
resetRulesets()
assertEqual(DefaultRuleset.export:match("format%s*=%s*\"rpe%-ruleset\".-version%s*=%s*(%d+)"), "2", "packaged envelope version")
local imported, importError = Database.ImportRuleset(DefaultRuleset.export)
assert(imported, importError)
assertEqual(imported.id, CORE_RULESET_ID, "packaged Core import ID")
assertEqual(imported.name, "Core", "packaged Core import name")
assertEqual(DefaultRuleset.packageVersion, 12, "packaged Core ruleset version")
assertEqual(imported.rules.event.event_end_justice_currency, "125", "packaged Core end-of-event Justice reward")
assertEqual(imported.rules.combat.shield_block_value_stat, "f82db71a:sblkval1", "packaged Core enables Shield Block Value")
assertTrue(contains(imported.rules.setup.allowed_class_refs, "c4a91e7d:shaman01"), "packaged Core allows Shaman setup")
assertTrue(contains(imported.rules.setup.allowed_class_refs, "e8f3b2c6:warlock1"), "packaged Core allows Warlock setup")
assertTrue(contains(imported.rules.setup.forced_dataset_ids, "c4a91e7d"), "packaged Core forces the Shaman dataset")
assertTrue(contains(imported.rules.setup.forced_dataset_ids, "e8f3b2c6"), "packaged Core forces the Warlock dataset")

-- ADDON_LOADED synchronization installs Core without touching character-scoped
-- activation. The stable-character path owns that activation decision.
resetRulesets()
assertEqual(Addon.Data.SyncDefaultRuleset(), true, "clean startup synchronizes Core")
assert(Database.GetRulesetByID(CORE_RULESET_ID), "clean startup installs Core")
assertEqual(Database.GetActiveRulesetId(), nil, "packaged sync does not activate Core early")
assertEqual(Addon.Data.ActivateDefaultRulesetForCurrentCharacter(), true, "stable startup activates Core")
assertEqual(Database.GetActiveRulesetId(), CORE_RULESET_ID, "clean startup activates Core")

-- A valid user selection must never be displaced by packaged-Core synchronization.
local userRuleset = Database.CreateRuleset("User Ruleset")
assert(userRuleset, "user ruleset is created")
assertEqual(Database.SetActiveRulesetId(userRuleset.id), userRuleset.id, "user ruleset is selected")
assertEqual(Addon.Data.SyncDefaultRuleset(), true, "sync succeeds with a user-selected ruleset")
assertEqual(Database.GetActiveRulesetId(), userRuleset.id, "sync preserves a valid user selection")

-- A package revision replaces Core via the same V2 export without changing the
-- serialization protocol version or the active user selection.
local originalExport = DefaultRuleset.export
local originalPackageVersion = DefaultRuleset.packageVersion
local updatedExport, replacements = originalExport:gsub(
    'description = ""',
    'description = "Packaged revision regression test"',
    1
)
assertEqual(replacements, 1, "test revision updates the packaged Core payload")
DefaultRuleset.export = updatedExport
DefaultRuleset.packageVersion = originalPackageVersion + 1

assertEqual(DefaultRuleset.export:match("format%s*=%s*\"rpe%-ruleset\".-version%s*=%s*(%d+)"), "2", "updated package envelope version")
assertEqual(Addon.Data.SyncDefaultRuleset(), true, "updated package synchronizes Core")
assertEqual(Database.GetRulesetByID(CORE_RULESET_ID).description, "Packaged revision regression test", "package revision replaces Core")
assertEqual(Database.GetActiveRulesetId(), userRuleset.id, "package revision preserves a valid user selection")

DefaultRuleset.export = originalExport
DefaultRuleset.packageVersion = originalPackageVersion
rawset(_G, "RPEngineRulesetDB", savedRulesetRoot)
Database.Rulesets = savedRulesetRoot
rawset(_G, "UnitFullName", savedUnitFullName)
rawset(_G, "UnitName", savedUnitName)
rawset(_G, "GetRealmName", savedGetRealmName)

print("DefaultRulesetImportTest passed")
