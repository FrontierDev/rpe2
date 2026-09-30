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

local diagnostics = {}
local Addon = {
    Internal = {},
    Debug = {
        Internal = function(message, ...)
            diagnostics[#diagnostics + 1] = string.format(message, ...)
        end,
    },
    Utils = {
        Common = {
            GetNow = function() return 1 end,
            GetPlayerName = function() return currentName end,
            NormalizeName = function(name) return tostring(name or "") end,
        },
    },
}
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
    _schema = 7,
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

local function resetProfiles(profiles)
    diagnostics = {}
    rawset(_G, "RPEngineProfilesDB", {
        _schema = 7,
        profiles = profiles,
    })
    Database.Profiles = nil
    return Database.EnsureProfiles()
end

Addon.Internal.Ruleset = {
    GetActiveRuleset = function() return {} end,
    GetRulesetRuleValueByKey = function(_, _, key, fallback)
        if key == "enable_setup_wizard" then
            return true
        end
        return fallback
    end,
}
loadAddonFile("core/internal/profile/Profile.lua", Addon)
local Profile = Addon.Internal.Profile

local showSetupWizardCalls = 0
Addon.Internal.Comms = {
    Operations = {
        GetOpcode = function(_, name) return name end,
    },
}
loadAddonFile("client/client_Session.lua", Addon)
Addon.Client.ShowSetupWizardWindow = function()
    showSetupWizardCalls = showSetupWizardCalls + 1
end

local mergedRoot = resetProfiles({
    Example = {
        name = "Example",
        classRef = "legacy-class",
        skillPermanentBonuses = { ["skill:legacy"] = 3 },
        setupWizard = {
            completed = true,
            raceRef = "race:legacy",
            classRef = "class:legacy",
            primaryResourceRef = "resource:legacy",
            startingItemRefs = { "item:legacy" },
            actionBarSpellRefs = { [1] = "spell:legacy" },
        },
    },
    ["Example-Realm"] = {
        name = "Example-Realm",
        classRef = "",
        skillPermanentBonuses = {},
        setupWizard = {
            completed = false,
            raceRef = "",
            classRef = "",
            primaryResourceRef = "",
            startingItemRefs = {},
            actionBarSpellRefs = {},
        },
    },
})
local merged = mergedRoot.profiles["Example-Realm"]
assertTrue(merged.setupWizard.completed, "completed legacy setup state wins over incomplete canonical state")
assertEqual(merged.classRef, "legacy-class", "empty canonical fields receive safe legacy data")
assertEqual(merged.skillPermanentBonuses["skill:legacy"], 3, "legacy profile data is migrated when canonical data is empty")
assertEqual(merged.setupWizard.raceRef, "race:legacy", "split setup race selection survives migration")
assertEqual(merged.setupWizard.classRef, "class:legacy", "split setup class selection survives migration")
assertEqual(merged.setupWizard.primaryResourceRef, "resource:legacy", "split setup resource selection survives migration")
assertEqual(merged.setupWizard.startingItemRefs[1], "item:legacy", "split setup item selection survives migration")
assertEqual(merged.setupWizard.actionBarSpellRefs[1], "spell:legacy", "split setup action-bar selection survives migration")
assertEqual(mergedRoot.profiles.Example, nil, "duplicate legacy profile is removed after safe migration")
assertTrue(Profile.IsSetupComplete(), "profile setup completion reads the reconciled canonical profile")
assertTrue(not Profile.IsSetupRequired(), "reconciled completed profile does not require setup")
assertTrue(Addon.Client:RequireSetupCompletion("character-identity-test"), "startup setup gate accepts the reconciled profile")
assertEqual(showSetupWizardCalls, 0, "startup does not open the setup wizard for a reconciled completed profile")

local canonicalCompletedRoot = resetProfiles({
    Example = {
        name = "Example",
        setupWizard = { completed = false },
    },
    ["Example-Realm"] = {
        name = "Example-Realm",
        setupWizard = { completed = true },
    },
})
assertTrue(canonicalCompletedRoot.profiles["Example-Realm"].setupWizard.completed, "canonical completed setup state remains true")
assertEqual(canonicalCompletedRoot.profiles.Example, nil, "incomplete legacy duplicate is removed")

local conflictRoot = resetProfiles({
    Example = {
        name = "Example",
        classRef = "legacy-class",
        setupWizard = { completed = false },
    },
    ["Example-Realm"] = {
        name = "Example-Realm",
        classRef = "canonical-class",
        setupWizard = { completed = true },
    },
})
assertEqual(conflictRoot.profiles["Example-Realm"].classRef, "canonical-class", "canonical conflicting data remains authoritative")
assertEqual(conflictRoot.profiles.Example, nil, "conflicting legacy duplicate is removed after diagnosis")
assertTrue(#diagnostics > 0, "duplicate-profile conflicts emit an INTERNAL diagnostic")
assertTrue(string.find(diagnostics[1], "canonical value preserved", 1, true) ~= nil, "conflict diagnostic identifies canonical preservation")

local defaultDuplicateRoot = resetProfiles({
    Example = { name = "Example" },
    ["Example-Realm"] = {
        name = "Example-Realm",
        classRef = "canonical-class",
        setupWizard = { completed = true },
    },
})
assertEqual(defaultDuplicateRoot.profiles.Example, nil, "default duplicate bare-name profile is removed")
assertEqual(defaultDuplicateRoot.profiles["Example-Realm"].classRef, "canonical-class", "default duplicate cleanup preserves canonical data")

local canonicalOnlyRoot = resetProfiles({ ["Example-Realm"] = {} })
assertTrue(type(canonicalOnlyRoot.profiles["Example-Realm"]) == "table", "canonical-only profile remains available")
assertEqual(canonicalOnlyRoot.profiles.Example, nil, "canonical-only profile does not create a bare-name record")

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
