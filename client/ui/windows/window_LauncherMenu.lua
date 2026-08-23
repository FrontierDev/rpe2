local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.LauncherMenu = Addon.Client.UI.LauncherMenu or {}

local Client = Addon.Client
local LauncherMenu = Addon.Client.UI.LauncherMenu
local UI = Addon.UI or {}

LauncherMenu.__index = LauncherMenu

local HEADER_ICON = "Interface\\AddOns\\RPEngine_Dev\\data\\textures\\ui\\rpe.png"

local WINDOW_WIDTH = 172
local WINDOW_HEIGHT = 252
local BUTTON_WIDTH = 136
local BUTTON_HEIGHT = 14
local GROUP_SPACING = 6
local BUTTON_SPACING = 2
local HEADER_HEIGHT = 10

local GROUPS = {
    {
        key = "profile",
        label = "Profile",
        entries = {
            { label = "Equipment", action = "OpenProfileLauncherDestination" },
            { label = "Spellbook", action = "OpenSpellbookLauncherDestination" },
            { label = "Skills", action = "OpenSkillsLauncherDestination" },
            { label = "Inventory", action = "OpenInventoryLauncherDestination" },
            { label = "Setup", action = "OpenSetupLauncherDestination" },
            { label = "Guild", action = "OpenGuildLauncherDestination" },
        },
    },
    {
        key = "event",
        label = "Event",
        entries = {
            { label = "Event Manager", action = "OpenEventManagerLauncherDestination" },
            { label = "Show/Hide Action Bar", action = "ToggleActionBarLauncherDestination" },
        },
    },
    {
        key = "settings",
        label = "Settings",
        entries = {
            { label = "Data Editor", action = "OpenDataEditorLauncherDestination" },
            { label = "Rules Editor", action = "OpenRulesetLauncherDestination" },
            { label = "Import Dataset", action = "OpenDatasetImportLauncherDestination" },
            { label = "Import Ruleset", action = "OpenRulesetImportLauncherDestination" },
        },
    },
}

local function createInstance()
    return setmetatable({
        window = nil,
        groupLayouts = {},
        buttons = {},
    }, LauncherMenu)
end

function LauncherMenu:Get()
    if not self._singleton then
        self._singleton = createInstance()
    end

    return self._singleton
end

function LauncherMenu:IsVisible()
    local frame = self.window and self.window.GetFrame and self.window:GetFrame() or nil
    return frame and frame.IsShown and frame:IsShown() == true or false
end

function LauncherMenu:BuildWindow()
    if self.window then
        return self.window
    end

    local window = UI.Window:New({
        name = "RPELauncherMenuWindow",
        width = WINDOW_WIDTH,
        height = WINDOW_HEIGHT,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 35,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = 10,
        contentInsetRight = 10,
        contentInsetTop = 28,
        contentInsetBottom = 10,
    })
    window:SetTitle(("|T%s:12:12:0:0|t RPE"):format(HEADER_ICON))
    window:Create()
    self.window = window

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, window:GetContentFrame(), "RPELauncherMenuRoot", {
        spacing = GROUP_SPACING,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, window:GetContentFrame(), 0, 0, 0, 0)
    self.RootLayout = root

    for groupIndex = 1, #GROUPS do
        local group = GROUPS[groupIndex]
        local groupLayout = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPELauncherMenuGroup" .. group.key, {
            spacing = BUTTON_SPACING,
            fitChildrenWidth = true,
            fitChildrenHeight = false,
            autoSize = true,
        })
        root:AddChild(groupLayout)
        self.groupLayouts[group.key] = groupLayout

        local heading = UI.CreateText(groupLayout:GetFrame(), "RPELauncherMenuHeading" .. group.key, group.label, {
            width = BUTTON_WIDTH,
            height = HEADER_HEIGHT,
            justifyH = "CENTER",
            textColor = UI.ResolveColor(nil, "text.secondary"),
        })
        groupLayout:AddChild(heading)

        for entryIndex = 1, #group.entries do
            local entry = group.entries[entryIndex]
            local button = UI.CreateButton(groupLayout:GetFrame(), "RPELauncherMenuButton" .. group.key .. entryIndex, entry.label, BUTTON_WIDTH, function()
                local action = type(Client) == "table" and Client[entry.action] or nil
                if type(action) == "function" then
                    action(Client)
                end
                self:Hide()
            end, {
                height = BUTTON_HEIGHT,
                fontSize = 7,
            })
            groupLayout:AddChild(button)
            self.buttons[entry.label] = button
        end
    end

    return window
end

function LauncherMenu:Show()
    local window = self:BuildWindow()
    if window and window.Show then
        window:Show()
    end
    return window
end

function LauncherMenu:Hide()
    if self.window and self.window.Hide then
        self.window:Hide()
    end
    return self.window
end

function LauncherMenu:Toggle()
    if self:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
    return true
end

function Client:BuildLauncherMenu()
    return LauncherMenu:Get():BuildWindow()
end

function Client:ShowLauncherMenu()
    return LauncherMenu:Get():Show()
end

function Client:HideLauncherMenu()
    return LauncherMenu:Get():Hide()
end

function Client:ToggleLauncherMenu()
    return LauncherMenu:Get():Toggle()
end

return LauncherMenu
