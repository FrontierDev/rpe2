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
local setupState = "setup-state-unavailable"
local actionBarShowCalls = 0
local actionBarBuildCalls = 0
local actionBarRefreshCalls = 0
local createdFrames = {}
local savedCreateFrame = rawget(_G, "CreateFrame")

rawset(_G, "CreateFrame", function()
    local frame = {
        events = {},
        scripts = {},
    }
    function frame:RegisterEvent(event)
        self.events[event] = true
    end
    function frame:SetScript(scriptType, handler)
        self.scripts[scriptType] = handler
        self.handler = handler
    end
    createdFrames[#createdFrames + 1] = frame
    return frame
end)

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
    GetSetupAccessState = function() return setupState end,
    IsSetupComplete = function()
        if setupState == "setup-state-unavailable" then
            return nil, setupState
        end
        return setupState == "setup-complete", setupState
    end,
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
    setupState = currentProfile.setupWizard.completed == true
        and "setup-complete"
        or "setup-incomplete"
    return true
end

loadAddonFile("client/client_Session.lua", Addon)
loadAddonFile("core/internal/Runtime.lua", Addon)
loadAddonFile("client/ui/widgets/widget_ActionBar.lua", Addon)

local Client = Addon.Client
local actionBarInitializer = createdFrames[#createdFrames]
assertTrue(type(actionBarInitializer) == "table" and type(actionBarInitializer.handler) == "function", "Action Bar registers its ADDON_LOADED initializer")
local actionBar = Addon.Client.UI.ActionBarWidget
actionBar.Get = function()
    return {
        Build = function() return true end,
        Show = function() return true end,
        Refresh = function() return true end,
    }
end
local actualShowActionBarWidget = Client.ShowActionBarWidget
Client.BuildActionBarWidget = function()
    actionBarBuildCalls = actionBarBuildCalls + 1
    return true
end
Client.ShowActionBarWidget = function(self)
    actionBarShowCalls = actionBarShowCalls + 1
    return actualShowActionBarWidget(self)
end
Client.RefreshActionBarWidget = function()
    actionBarRefreshCalls = actionBarRefreshCalls + 1
    return true
end
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
    setupState = "setup-state-unavailable"
    actionBarShowCalls = 0
    actionBarBuildCalls = 0
    actionBarRefreshCalls = 0
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
    local addonLoadedAccess, addonLoadedReason = Client:CanAccessPostSetupFeatures()
    assertEqual(addonLoadedAccess, false, label .. " blocks post-setup access while setup state is unavailable")
    assertEqual(addonLoadedReason, "setup-state-unavailable", label .. " reports unavailable setup state during ADDON_LOADED")
    local addonLoadedComplete, addonLoadedCompleteReason = Addon.Internal.Profile.IsSetupComplete()
    assertEqual(addonLoadedComplete, nil, label .. " does not collapse unavailable setup into incomplete")
    assertEqual(addonLoadedCompleteReason, "setup-state-unavailable", label .. " exposes the unavailable setup reason")

    actionBarInitializer.handler(actionBarInitializer, "ADDON_LOADED", Addon.Name)
    assertEqual(actionBarShowCalls, 0, label .. " Action Bar ADDON_LOADED path does not call the gated show method")
    assertEqual(showCalls, 0, label .. " Action Bar ADDON_LOADED path does not redirect to setup")
    assertEqual(actionBarBuildCalls, 1, label .. " Action Bar is built during ADDON_LOADED")
    assertEqual(actionBarRefreshCalls, 1, label .. " Action Bar is refreshed during ADDON_LOADED")

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
    if completed then
        assertTrue(Addon.Internal.Profile.IsSetupComplete() == true, label .. " reports setup complete after character startup")
        assertTrue(Client:CanAccessPostSetupFeatures(), label .. " allows post-setup access after character startup")
        assertTrue(Client:ShowActionBarWidget(), label .. " can show the Action Bar after character startup")
        assertEqual(actionBarShowCalls, 1, label .. " shows the Action Bar only after character startup")
        assertEqual(showCalls, 0, label .. " keeps the Setup Wizard closed after character startup")
    else
        local incompleteAccess, incompleteReason = Client:CanAccessPostSetupFeatures()
        assertEqual(incompleteAccess, false, label .. " blocks incomplete post-setup access")
        assertEqual(incompleteReason, "setup-incomplete", label .. " reports authoritative setup incompletion")
    end
end

runStartup("completed character with selected ruleset", true, "custom-ruleset", "custom-ruleset", 0)
runStartup("completed character with Core fallback", true, nil, "25076117", 0)
runStartup("incomplete character with Core fallback", false, nil, "25076117", 1)

setupState = "setup-state-unavailable"
showCalls = 0
local unavailableAccess, unavailableReason = Client:RequireSetupCompletion("unresolved-ruleset")
assertEqual(unavailableAccess, false, "unresolved ruleset blocks access")
assertEqual(unavailableReason, "setup-state-unavailable", "unresolved ruleset returns setup-state-unavailable")
assertEqual(showCalls, 0, "unresolved ruleset never opens the Setup Wizard")

rawset(_G, "CreateFrame", savedCreateFrame)

print("SetupStartupOrderingTest passed")
