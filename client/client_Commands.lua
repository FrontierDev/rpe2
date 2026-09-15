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

local function parseDebugCurrencyAmount(value)
    local numericAmount = tonumber(value)
    if not numericAmount
        or numericAmount ~= numericAmount
        or numericAmount == math.huge
        or numericAmount == -math.huge
    then
        return nil
    end

    local amount = math.floor(numericAmount)
    if amount <= 0 then
        return nil
    end

    return amount
end

function ClientCommands:RegisterSlashCommands()
    register({ "debug", "currency", "add" }, function(context)
        if Client:RequireSetupCompletion("debug-currency") ~= true then
            return false
        end

        local args = context and context.args or {}
        local currencyRef = tostring(args[1] or "")
        local amount = parseDebugCurrencyAmount(args[2])
        local internalProfile = Addon.Internal and Addon.Internal.Profile or nil

        if currencyRef == "" or not amount then
            context.router:Print(
                "Usage: /rpe debug currency add <currency> <amount> (amount must be a positive whole number).",
                "warn"
            )
            return false
        end

        if type(internalProfile) ~= "table"
            or type(internalProfile.AddCurrencyAmount) ~= "function"
            or type(internalProfile.GetCurrencyAmount) ~= "function"
        then
            context.router:Print("Currency debug command is not available.", "warn")
            return false
        end

        local normalizedCurrencyRef = currencyRef
        if type(internalProfile.NormalizeCurrencyKey) == "function" then
            normalizedCurrencyRef = internalProfile.NormalizeCurrencyKey(currencyRef)
        end
        if normalizedCurrencyRef == "" then
            context.router:Print("A currency key or reference is required.", "warn")
            return false
        end

        local previousBalance = internalProfile.GetCurrencyAmount(normalizedCurrencyRef)
        local persistedAmount = internalProfile.AddCurrencyAmount(normalizedCurrencyRef, amount)
        if persistedAmount == nil then
            context.router:Print("Currency grant failed for %s.", "warn", normalizedCurrencyRef)
            return false
        end

        local resultingBalance = internalProfile.GetCurrencyAmount(normalizedCurrencyRef)
        context.router:Print(
            "Debug currency grant: %s +%d; balance %d (was %d).",
            nil,
            normalizedCurrencyRef,
            amount,
            tonumber(resultingBalance) or 0,
            tonumber(previousBalance) or 0
        )
        return true
    end, "Development test utility: grant currency through Profile.AddCurrencyAmount.")

    register({ "data" }, function(context)
        if not Client.OpenDataEditorLauncherDestination then
            context.router:Print("Data editor UI is not available.", "warn")
            return false
        end

        if not Client:OpenDataEditorLauncherDestination() then
            return false
        end
        context.router:Print("Data editor window shown.")
        return true
    end, "Show the data editor window.")

    register({ "rulesets" }, function(context)
        if not Client.OpenRulesetLauncherDestination then
            context.router:Print("Ruleset UI is not available.", "warn")
            return false
        end

        if not Client:OpenRulesetLauncherDestination() then
            return false
        end
        context.router:Print("Ruleset window shown.")
        return true
    end, "Show the ruleset window.")

    register({ "inventory" }, function(context)
        if not Client.OpenInventoryLauncherDestination then
            context.router:Print("Inventory UI is not available.", "warn")
            return false
        end

        if not Client:OpenInventoryLauncherDestination() then
            return false
        end
        context.router:Print("Inventory window shown.")
        return true
    end, "Show the inventory window.")

    register({ "profile" }, function(context)
        if not Client.OpenProfileLauncherDestination then
            context.router:Print("Profile UI is not available.", "warn")
            return false
        end

        if not Client:OpenProfileLauncherDestination() then
            return false
        end
        context.router:Print("Profile window shown.")
        return true
    end, "Show the profile window.")

    register({ "guild" }, function(context)
        if not Client.OpenGuildLauncherDestination then
            context.router:Print("Guild UI is not available.", "warn")
            return false
        end

        if not Client:OpenGuildLauncherDestination() then
            return false
        end
        context.router:Print("Guild window shown.")
        return true
    end, "Show the guild window.")

    register({ "unlock" }, function(context)
        if Client:RequireSetupCompletion("widget-unlock") ~= true then
            return false
        end

        if not Profile or not Profile.SetWidgetsUnlocked then
            context.router:Print("Widget unlock mode is not available.", "warn")
            return false
        end

        Profile.SetWidgetsUnlocked(true)
        context.router:Print("Movable widgets unlocked.")
        return true
    end, "Unlock movable widgets for repositioning.")

    register({ "lock" }, function(context)
        if Client:RequireSetupCompletion("widget-lock") ~= true then
            return false
        end

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
    if self:RequireSetupCompletion("event-manager-destination") ~= true then
        return nil
    end

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

    local shown = self.ShowActionBarWidget and self:ShowActionBarWidget() or nil
    if not shown then
        return false
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
    if not window then
        return nil
    end

    local dataEditor = Addon.Client and Addon.Client.UI and Addon.Client.UI.Editor or nil
    if dataEditor and dataEditor.ShowDatasetImportWindow then
        dataEditor:ShowDatasetImportWindow()
    end
    return window
end

function Client:OpenRulesetImportLauncherDestination()
    local window = self:OpenRulesetLauncherDestination()
    if not window then
        return nil
    end

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
