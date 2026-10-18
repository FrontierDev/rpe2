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

local pendingTargeting = {
    spellRef = "test:targeted-spell",
    groups = {
        {
            key = "default",
            focusedTargetEventId = 42,
            selectedTargetEventIds = {
                [42] = true,
                [7] = true,
            },
        },
    },
}

local Addon = {
    Client = {
        UI = {},
    },
    Internal = {
        Profile = {
            GetActionBarMode = function() return "spells" end,
            GetActionBarLayoutMode = function() return "complex" end,
            ShouldUseMountedActionBar = function() return false end,
        },
    },
}

local Client = Addon.Client
function Client:CanAccessPostSetupFeatures()
    return true
end
function Client:GetPendingSpellTargeting()
    return pendingTargeting
end
function Client:GetEventState()
    return nil
end

loadAddonFile("client/ui/widgets/widget_ActionBar.lua", Addon)

local widget = Addon.Client.UI.ActionBarWidget:Get()
widget.Build = function() end
widget.Show = function() end
widget.GetActionBarRows = function() return {} end
widget.GetContentInset = function() return 0 end
widget.IsUnlocked = function() return false end
widget.rootPanel = {
    GetFrame = function()
        return {}
    end,
}

local plan = widget:BuildIncrementalRefreshPlan("target-selection")
assertTrue(type(plan) == "table", "Action Bar refresh plan builds with selected target lookup tables")
assertTrue(type(plan.refreshSignature) == "string", "Action Bar refresh signature is generated")
assertTrue(plan.refreshSignature:find("7,42", 1, true) ~= nil, "Action Bar refresh signature serializes selected target IDs")

print("ActionBarTargetingSignatureTest passed")
