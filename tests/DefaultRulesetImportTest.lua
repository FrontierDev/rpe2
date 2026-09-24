local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, addon)
end

local savedRulesetRoot = rawget(_G, "RPEngineRulesetDB")
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

-- Clean startup installs and activates Core for the current character.
resetRulesets()
assertEqual(Addon.Data.SyncDefaultRuleset(), true, "clean startup synchronizes Core")
assert(Database.GetRulesetByID(CORE_RULESET_ID), "clean startup installs Core")
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

print("DefaultRulesetImportTest passed")
