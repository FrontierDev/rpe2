local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then
        error(message, 2)
    end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local savedProfileRoot = rawget(_G, "RPEngineProfilesDB")
local savedRulesetRoot = rawget(_G, "RPEngineRulesetDB")
local savedUnitFullName = rawget(_G, "UnitFullName")
local savedUnitName = rawget(_G, "UnitName")
local savedGetRealmName = rawget(_G, "GetRealmName")

local currentName = "Example"
local fullNameRealm = "Realm"
local fallbackRealm = "Realm"
rawset(_G, "UnitFullName", function() return currentName, fullNameRealm end)
rawset(_G, "UnitName", function() return currentName end)
rawset(_G, "GetRealmName", function() return fallbackRealm end)

local Addon = { Internal = {} }
loadAddonFile("core/internal/database/Database.lua", Addon)
local Database = Addon.Internal.Database

local key, displayName, stable, bareName = Database.ResolveCurrentCharacterIdentity()
assertEqual(key, "Example-Realm", "normal identity uses the canonical Name-Realm key")
assertEqual(displayName, "Example-Realm", "normal identity display key is canonical")
assertTrue(stable, "normal identity is stable")
assertEqual(bareName, "Example", "resolver exposes the legacy bare name for migration")

fullNameRealm = ""
fallbackRealm = "Realm"
key, _, stable = Database.ResolveCurrentCharacterIdentity()
assertEqual(key, "Example-Realm", "empty UnitFullName realm uses the fallback realm")
assertTrue(stable, "fallback realm identity is stable")

fullNameRealm = nil
fallbackRealm = ""
key, _, stable = Database.ResolveCurrentCharacterIdentity()
assertEqual(key, "unknown-player", "unavailable realm uses the unstable identity")
assertTrue(not stable, "unavailable realm is not stable")
local unstableRoot = Database.EnsureProfiles()
Database.GetOrCreateActiveProfile()
assertEqual(unstableRoot.profiles["Example"], nil, "unstable identity never creates a bare-name profile")

fullNameRealm = "Realm"
fallbackRealm = "Realm"
rawset(_G, "RPEngineProfilesDB", {
    _schema = 1,
    profiles = {
        Example = {
            name = "Example",
            classRef = "legacy-class",
            setupWizard = { completed = true },
        },
    },
})
Database.Profiles = nil
local migratedRoot = Database.EnsureProfiles()
local migrated = migratedRoot.profiles["Example-Realm"]
assertTrue(type(migrated) == "table", "bare-name profile migrates to the canonical key")
assertEqual(migrated.characterKey, "Example-Realm", "migrated profile stores the canonical character key")
assertEqual(migrated.name, "Example-Realm", "migrated profile stores the canonical name")
assertEqual(migrated.classRef, "legacy-class", "migration preserves profile data")
assertTrue(migrated.setupWizard.completed, "migration preserves setup completion")
assertEqual(migratedRoot.profiles.Example, nil, "bare-name profile entry is removed after migration")

rawset(_G, "RPEngineProfilesDB", {
    _schema = 1,
    profiles = {
        Example = {
            name = "Example",
            classRef = "legacy-class",
            setupWizard = { completed = true },
        },
        ["Example-Realm"] = {
            name = "Example-Realm",
            classRef = "canonical-class",
            setupWizard = { completed = false },
        },
    },
})
Database.Profiles = nil
local authoritativeRoot = Database.EnsureProfiles()
assertEqual(authoritativeRoot.profiles["Example-Realm"].classRef, "canonical-class", "canonical profile is authoritative")
assertTrue(not authoritativeRoot.profiles["Example-Realm"].setupWizard.completed, "canonical setup state is not overwritten")
assertTrue(type(authoritativeRoot.profiles.Example) == "table", "populated bare profile is retained")

rawset(_G, "RPEngineRulesetDB", {
    _schema = 1,
    rulesets = { rules = { id = "rules", name = "Rules", rules = {} } },
    activeByChar = { Example = "rules" },
})
Database.Rulesets = nil
local activeRulesetId = Database.GetActiveRulesetId()
assertEqual(activeRulesetId, "rules", "active ruleset resolves through the canonical identity")
local activeRoot = rawget(_G, "RPEngineRulesetDB")
assertEqual(activeRoot.activeByChar["Example-Realm"], "rules", "active ruleset migrates to the canonical key")
assertEqual(activeRoot.activeByChar.Example, nil, "bare active-ruleset key is removed after migration")

rawset(_G, "RPEngineProfilesDB", savedProfileRoot)
rawset(_G, "RPEngineRulesetDB", savedRulesetRoot)
Database.Profiles = savedProfileRoot
Database.Rulesets = savedRulesetRoot
rawset(_G, "UnitFullName", savedUnitFullName)
rawset(_G, "UnitName", savedUnitName)
rawset(_G, "GetRealmName", savedGetRealmName)

print("CharacterIdentityTest passed")
