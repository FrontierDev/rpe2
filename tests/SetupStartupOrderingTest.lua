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

local identityStable = false
local syncCalls = 0
local activateCalls = 0
local refreshCalls = 0
local showCalls = 0
local showWasStable = false
local activeRulesetId = nil
local currentProfile = nil

local Addon = {
    Name = "RPEngine2",
    Data = {},
    Client = {},
    Internal = {},
    Utils = {},
}

local Common = {
    GetNow = function() return 1 end,
    GetPlayerName = function() return "Alice" end,
    NormalizeName = function(name) return tostring(name or "") end,
    GetGroupType = function() return nil end,
}
local Operations = {
    GetOpcode = function(_, name) return name end,
}
Addon.Utils.Common = Common
Addon.Internal.Comms = { Operations = Operations }
Addon.Internal.Database = {
    IsCurrentCharacterIdentityStable = function() return identityStable end,
}
Addon.Internal.Profile = {
    IsSetupComplete = function() return currentProfile.setupWizard.completed == true end,
}
Addon.Data.SyncDefaultRuleset = function()
    syncCalls = syncCalls + 1
    -- Model the configuration notification emitted by packaged ruleset import
    -- so the test covers the real ADDON_LOADED suppression boundary.
    Addon.Client:HandleLocalConfigurationChanged("active-ruleset")
    return true
end
Addon.Data.ActivateDefaultRulesetForCurrentCharacter = function()
    activateCalls = activateCalls + 1
    if not identityStable then
        return false
    end
    if activeRulesetId == nil then
        activeRulesetId = "25076117"
    end
    return true
end

loadAddonFile("client/client_Session.lua", Addon)
loadAddonFile("core/internal/Runtime.lua", Addon)

local Client = Addon.Client
Client.QueueLocalConfigurationRefresh = function(_, reason)
    refreshCalls = refreshCalls + 1
    return reason ~= nil
end
Client.ShowSetupWizardWindow = function()
    showCalls = showCalls + 1
    showWasStable = identityStable
    return true
end

local function runStartup(label, completed, initialRulesetId, expectedRulesetId, expectedShowCalls)
    identityStable = false
    syncCalls = 0
    activateCalls = 0
    refreshCalls = 0
    showCalls = 0
    showWasStable = false
    activeRulesetId = initialRulesetId
    currentProfile = {
        setupWizard = { completed = completed },
        skillPermanentBonuses = { weapon = 7 },
    }
    local originalBonus = currentProfile.skillPermanentBonuses.weapon

    Addon.Internal.DispatchEvent("ADDON_LOADED", Addon.Name)
    assertEqual(syncCalls, 1, label .. " installs packaged rules during ADDON_LOADED")
    assertEqual(activateCalls, 0, label .. " does not activate a character ruleset during ADDON_LOADED")
    assertEqual(showCalls, 0, label .. " does not open setup during ADDON_LOADED")
    assertEqual(activeRulesetId, initialRulesetId, label .. " preserves the pre-login active ruleset during ADDON_LOADED")

    identityStable = true
    Addon.Internal.DispatchEvent("PLAYER_ENTERING_WORLD")
    assertEqual(syncCalls, 2, label .. " synchronizes packaged rules after identity is stable")
    assertEqual(activateCalls, 1, label .. " activates character rules after identity is stable")
    assertEqual(activeRulesetId, expectedRulesetId, label .. " resolves the expected active ruleset")
    assertEqual(showCalls, expectedShowCalls, label .. " opens setup the expected number of times")
    if expectedShowCalls > 0 then
        assertTrue(showWasStable, label .. " opens setup only after identity is stable")
    end
    assertEqual(currentProfile.setupWizard.completed, completed, label .. " preserves setup completion")
    assertEqual(currentProfile.skillPermanentBonuses.weapon, originalBonus, label .. " preserves permanent skill bonuses")
    assertTrue(refreshCalls > 0, label .. " queues the normal post-login configuration refresh")
end

runStartup("completed character with selected ruleset", true, "custom-ruleset", "custom-ruleset", 0)
runStartup("completed character with Core fallback", true, nil, "25076117", 0)
runStartup("incomplete character with Core fallback", false, nil, "25076117", 1)

print("SetupStartupOrderingTest passed")
