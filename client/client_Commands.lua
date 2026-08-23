local addonName, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Commands = Addon.Client.Commands or {}

local ClientCommands = Addon.Client.Commands
local Commands = Addon.Commands or {}
local Client = Addon.Client
local Profile = Addon.Internal and Addon.Internal.Profile or {}

local function isActionBarVisible()
    local actionBarWidget = Addon.Client and Addon.Client.UI and Addon.Client.UI.ActionBarWidget or nil
    local widget = actionBarWidget and actionBarWidget.Get and actionBarWidget:Get() or nil
    local rootPanel = widget and widget.rootPanel or nil
    local frame = rootPanel and rootPanel.GetFrame and rootPanel:GetFrame() or nil
    return frame and frame.IsShown and frame:IsShown() == true or false
end

local function joinArgs(args, startIndex)
    local values = {}
    for index = startIndex or 1, #(args or {}) do
        values[#values + 1] = tostring(args[index] or "")
    end
    return table.concat(values, " ")
end

local function register(path, handler, description)
    if Commands and Commands.RegisterCommand then
        Commands:RegisterCommand(path, handler, {
            description = description,
        })
    end
end

function ClientCommands:RegisterSlashCommands()
    register({ "data" }, function(context)
        if not Client.OpenDataEditorLauncherDestination then
            context.router:Print("Data editor UI is not available.", "warn")
            return false
        end

        Client:OpenDataEditorLauncherDestination()
        context.router:Print("Data editor window shown.")
        return true
    end, "Show the data editor window.")

    register({ "rulesets" }, function(context)
        if not Client.OpenRulesetLauncherDestination then
            context.router:Print("Ruleset UI is not available.", "warn")
            return false
        end

        Client:OpenRulesetLauncherDestination()
        context.router:Print("Ruleset window shown.")
        return true
    end, "Show the ruleset window.")

    register({ "inventory" }, function(context)
        if not Client.OpenInventoryLauncherDestination then
            context.router:Print("Inventory UI is not available.", "warn")
            return false
        end

        Client:OpenInventoryLauncherDestination()
        context.router:Print("Inventory window shown.")
        return true
    end, "Show the inventory window.")

    register({ "profile" }, function(context)
        if not Client.OpenProfileLauncherDestination then
            context.router:Print("Profile UI is not available.", "warn")
            return false
        end

        Client:OpenProfileLauncherDestination()
        context.router:Print("Profile window shown.")
        return true
    end, "Show the profile window.")

    register({ "guild" }, function(context)
        if not Client.OpenGuildLauncherDestination then
            context.router:Print("Guild UI is not available.", "warn")
            return false
        end

        Client:OpenGuildLauncherDestination()
        context.router:Print("Guild window shown.")
        return true
    end, "Show the guild window.")

    register({ "unlock" }, function(context)
        if not Profile or not Profile.SetWidgetsUnlocked then
            context.router:Print("Widget unlock mode is not available.", "warn")
            return false
        end

        Profile.SetWidgetsUnlocked(true)
        context.router:Print("Movable widgets unlocked.")
        return true
    end, "Unlock movable widgets for repositioning.")

    register({ "lock" }, function(context)
        if not Profile or not Profile.SetWidgetsUnlocked then
            context.router:Print("Widget lock mode is not available.", "warn")
            return false
        end

        Profile.SetWidgetsUnlocked(false)
        context.router:Print("Movable widgets locked.")
        return true
    end, "Lock movable widgets in place.")

    register({ "client", "reset" }, function(context)
        if not Client.Reset then
            context.router:Print("Client reset is not available.", "warn")
            return false
        end

        Client:Reset("slash-command")
        context.router:Print("Client reset.")
        return true
    end, "Reset the client channel state.")

    register({ "client", "status" }, function(context)
        local state = Client.GetState and Client:GetState() or nil
        if not state then
            context.router:Print("Client is inactive.")
            return true
        end

        context.router:Print(
            "Client active: joinedAt=%s channelId=%s",
            nil,
            tostring(state.joinedAt or 0),
            tostring(state.channelId or 0)
        )
        return true
    end, "Show client status.")

end

function Client:OpenProfileLauncherDestination()
    if not self.ShowProfileWindowTab then
        return nil
    end

    return self:ShowProfileWindowTab("equipment")
end

function Client:OpenGuildLauncherDestination()
    if not self.ShowGuildWindow then
        return nil
    end

    return self:ShowGuildWindow()
end

function Client:OpenSpellbookLauncherDestination()
    if not self.ShowProfileWindowTab then
        return nil
    end

    return self:ShowProfileWindowTab("spellbook")
end

function Client:OpenSkillsLauncherDestination()
    if not self.ShowProfileWindowTab then
        return nil
    end

    return self:ShowProfileWindowTab("skills")
end

function Client:OpenInventoryLauncherDestination()
    if not self.ShowInventoryWindow then
        return nil
    end

    return self:ShowInventoryWindow()
end

function Client:OpenSetupLauncherDestination()
    if not self.ShowSetupWizardWindow then
        return nil
    end

    return self:ShowSetupWizardWindow()
end

function Client:OpenEventManagerLauncherDestination()
    local server = Addon.Server or nil
    if type(server) ~= "table" or type(server.ShowEventManageWindow) ~= "function" then
        return nil
    end

    return server:ShowEventManageWindow()
end

function Client:ToggleActionBarLauncherDestination()
    if isActionBarVisible() then
        if self.HideActionBarWidget then
            return self:HideActionBarWidget()
        end
        return nil
    end

    if self.ShowActionBarWidget then
        self:ShowActionBarWidget()
    end
    if self.RefreshActionBarWidget then
        self:RefreshActionBarWidget("launcher-toggle")
    end
    return true
end

function Client:OpenDataEditorLauncherDestination()
    if not self.ShowDataEditorWindow then
        return nil
    end

    return self:ShowDataEditorWindow()
end

function Client:OpenRulesetLauncherDestination()
    if not self.ShowRulesetWindow then
        return nil
    end

    return self:ShowRulesetWindow()
end

function Client:OpenDatasetImportLauncherDestination()
    local window = self:OpenDataEditorLauncherDestination()
    local dataEditor = Addon.Client and Addon.Client.UI and Addon.Client.UI.Editor or nil
    if dataEditor and dataEditor.ShowDatasetImportWindow then
        dataEditor:ShowDatasetImportWindow()
    end
    return window
end

function Client:OpenRulesetImportLauncherDestination()
    local window = self:OpenRulesetLauncherDestination()
    local rulesetWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Ruleset or nil
    if rulesetWindow and rulesetWindow.ShowRulesetImportWindow then
        rulesetWindow:ShowRulesetImportWindow()
    end
    return window
end

function Client:IsLauncherMenuVisible()
    local launcherMenu = Addon.Client and Addon.Client.UI and Addon.Client.UI.LauncherMenu or nil
    local menu = launcherMenu and launcherMenu.Get and launcherMenu:Get() or nil
    return menu and menu.IsVisible and menu:IsVisible() or false
end

ClientCommands:RegisterSlashCommands()
