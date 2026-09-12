local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.LauncherMenu = Addon.Client.UI.LauncherMenu or {}
Addon.Client.UI.MinimapButton = Addon.Client.UI.MinimapButton or {}

local Client = Addon.Client
local LauncherMenu = Addon.Client.UI.LauncherMenu
local MinimapButton = Addon.Client.UI.MinimapButton
local UI = Addon.UI or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Help = Addon.Client and Addon.Client.Help or {}

LauncherMenu.__index = LauncherMenu
MinimapButton.__index = MinimapButton

local HEADER_ICON = "Interface\\AddOns\\RPEngine_Dev\\data\\textures\\ui\\rpe.png"

local WINDOW_WIDTH = 172
local BUTTON_WIDTH = 136
local BUTTON_HEIGHT = 14
local GROUP_SPACING = 6
local BUTTON_SPACING = 2
local HEADER_HEIGHT = 10
local CONTENT_INSET_LEFT = 10
local CONTENT_INSET_RIGHT = 10
local CONTENT_INSET_TOP = 28
local CONTENT_INSET_BOTTOM = 10

local MINIMAP_SETTING_KEY = "minimapButton"
local MINIMAP_HELP_ID = "minimap.open-menu"
local MINIMAP_DEFAULT_ANGLE = 220
local MINIMAP_BUTTON_SIZE = 32
local MINIMAP_RADIUS_OFFSET = 2

local LAUNCHER_HELP_SEQUENCE = {
    "launcher.profile",
    "launcher.event",
    "launcher.content",
}

local LAUNCHER_HELP = {
    ["launcher.profile"] = {
        groupKey = "profile",
        anchorLabel = "Equipment",
        text = "Character tools are here. View your equipment, spells, skills, inventory, setup and guild features.",
    },
    ["launcher.event"] = {
        groupKey = "event",
        anchorLabel = "Event Manager",
        text = "Event tools are here. Event hosts can configure and manage RPE events, and you can show or hide your Action Bar.",
    },
    ["launcher.content"] = {
        groupKey = "settings",
        anchorLabel = "Data Editor",
        text = "Create or import RPE data and rules here. These tools are mainly for campaign and ruleset authors.",
    },
}

local LAUNCHER_HELP_BY_GROUP = {
    profile = "launcher.profile",
    event = "launcher.event",
    settings = "launcher.content",
}

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

local function calculateWindowHeight()
    local contentHeight = 0

    for groupIndex = 1, #GROUPS do
        local group = GROUPS[groupIndex]
        local entryCount = #(group.entries or {})

        contentHeight = contentHeight + HEADER_HEIGHT
        contentHeight = contentHeight + (entryCount * BUTTON_HEIGHT)
        contentHeight = contentHeight + (entryCount * BUTTON_SPACING)
    end

    if #GROUPS > 1 then
        contentHeight = contentHeight + ((#GROUPS - 1) * GROUP_SPACING)
    end

    return CONTENT_INSET_TOP + contentHeight + CONTENT_INSET_BOTTOM
end

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

function LauncherMenu:RegisterHelpTips()
    if type(Help.Register) ~= "function" then
        return false
    end

    for index = 1, #LAUNCHER_HELP_SEQUENCE do
        local tipId = LAUNCHER_HELP_SEQUENCE[index]
        local definition = LAUNCHER_HELP[tipId]
        local tipText = definition and definition.text or nil
        Help:Register(tipId, {
            text = tipText,
            onAcknowledgeCallback = function()
                if self:IsVisible() then
                    self:ShowNextHelpTip()
                end
            end,
        })
    end

    return true
end

function LauncherMenu:GetHelpAnchor(tipId)
    local definition = LAUNCHER_HELP[tipId]
    if not definition then
        return nil
    end
    return self.buttons[definition.anchorLabel]
end

function LauncherMenu:ShowNextHelpTip()
    if not self:IsVisible() or type(Help.IsAcknowledged) ~= "function" or type(Help.Show) ~= "function" then
        return false
    end

    self:RegisterHelpTips()

    for index = 1, #LAUNCHER_HELP_SEQUENCE do
        local tipId = LAUNCHER_HELP_SEQUENCE[index]
        if not Help:IsAcknowledged(tipId) then
            local anchor = self:GetHelpAnchor(tipId)
            if anchor == nil then
                return false
            end
            return Help:Show(tipId, anchor)
        end
    end

    return false
end

function LauncherMenu:HideHelpTip()
    local activeTipId = Help.ActiveTipId
    if type(activeTipId) ~= "string" or not LAUNCHER_HELP[activeTipId] or type(Help.Hide) ~= "function" then
        return false
    end
    return Help:Hide(activeTipId)
end

function LauncherMenu:AcknowledgeGroupHelp(groupKey)
    local tipId = LAUNCHER_HELP_BY_GROUP[groupKey]
    if not tipId or type(Help.Acknowledge) ~= "function" then
        return false
    end
    return Help:Acknowledge(tipId)
end

function LauncherMenu:BuildWindow()
    if self.window then
        return self.window
    end

    local window = UI.Window:New({
        name = "RPELauncherMenuWindow",
        width = WINDOW_WIDTH,
        height = calculateWindowHeight(),
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 35,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = CONTENT_INSET_LEFT,
        contentInsetRight = CONTENT_INSET_RIGHT,
        contentInsetTop = CONTENT_INSET_TOP,
        contentInsetBottom = CONTENT_INSET_BOTTOM,
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
                    self:AcknowledgeGroupHelp(group.key)
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

    self:RegisterHelpTips()
    return window
end

function LauncherMenu:Show()
    local window = self:BuildWindow()
    if window and window.Show then
        window:Show()
    end
    self:ShowNextHelpTip()
    return window
end

function LauncherMenu:Hide()
    self:HideHelpTip()
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

local function normalizeMinimapState(value)
    local state = type(value) == "table" and value or {}
    local angle = tonumber(state.angle)
    if angle == nil then
        angle = MINIMAP_DEFAULT_ANGLE
    end
    angle = angle % 360

    return {
        angle = angle,
        hidden = state.hidden == true,
    }
end

local function loadMinimapState()
    if type(Database.GetGlobalSetting) ~= "function" then
        return normalizeMinimapState(nil)
    end
    return normalizeMinimapState(Database.GetGlobalSetting(MINIMAP_SETTING_KEY, nil))
end

local function saveMinimapState(state)
    local normalized = normalizeMinimapState(state)
    if type(Database.SetGlobalSetting) == "function" then
        Database.SetGlobalSetting(MINIMAP_SETTING_KEY, normalized)
    end
    return normalized
end

local function atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi * 0.5
    elseif x == 0 and y < 0 then
        return -math.pi * 0.5
    end
    return 0
end

local function getMinimapRadius()
    local width = Minimap and Minimap.GetWidth and Minimap:GetWidth() or 140
    local height = Minimap and Minimap.GetHeight and Minimap:GetHeight() or width
    return (math.min(width, height) * 0.5) + MINIMAP_RADIUS_OFFSET
end

function MinimapButton:ApplyPosition(angle)
    if not self.frame or not Minimap then
        return false
    end

    local normalizedAngle = (tonumber(angle) or MINIMAP_DEFAULT_ANGLE) % 360
    local radians = math.rad(normalizedAngle)
    local radius = getMinimapRadius()
    local x = math.cos(radians) * radius
    local y = math.sin(radians) * radius

    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", Minimap, "CENTER", x, y)
    self.angle = normalizedAngle
    return true
end

function MinimapButton:PersistPosition()
    local state = loadMinimapState()
    state.angle = self.angle or MINIMAP_DEFAULT_ANGLE
    saveMinimapState(state)
end

function MinimapButton:UpdateDragPosition()
    if not self.frame or not Minimap or not GetCursorPosition then
        return false
    end

    local scale = Minimap.GetEffectiveScale and Minimap:GetEffectiveScale() or 1
    local cursorX, cursorY = GetCursorPosition()
    cursorX = cursorX / scale
    cursorY = cursorY / scale

    local left = Minimap.GetLeft and Minimap:GetLeft() or 0
    local bottom = Minimap.GetBottom and Minimap:GetBottom() or 0
    local width = Minimap.GetWidth and Minimap:GetWidth() or 0
    local height = Minimap.GetHeight and Minimap:GetHeight() or width
    local centerX = left + (width * 0.5)
    local centerY = bottom + (height * 0.5)
    local radians = atan2(cursorY - centerY, cursorX - centerX)
    local angle = math.deg(radians) % 360

    return self:ApplyPosition(angle)
end

function MinimapButton:ShowFirstRunHelp()
    if not self.frame or type(Help.Register) ~= "function" or type(Help.Show) ~= "function" then
        return false
    end

    Help:Register(MINIMAP_HELP_ID, {
        text = "Click the RPE icon to open the RPE menu.",
    })
    return Help:Show(MINIMAP_HELP_ID, self.frame)
end

function MinimapButton:Create()
    if self.frame or not Minimap or not CreateFrame then
        return self.frame
    end

    local state = loadMinimapState()
    local button = CreateFrame("Button", "RPEMinimapButton", Minimap)
    button:SetSize(MINIMAP_BUTTON_SIZE, MINIMAP_BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)
    button:EnableMouse(true)

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(HEADER_ICON)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", -11, 11)
    button.border = border

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(button)
    button.highlight = highlight

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton ~= "LeftButton" then
            return
        end
        if type(Client.ToggleLauncherMenu) == "function" then
            Client:ToggleLauncherMenu()
        end
        if type(Help.Acknowledge) == "function" then
            Help:Acknowledge(MINIMAP_HELP_ID)
        end
    end)

    button:SetScript("OnEnter", function(frame)
        if not GameTooltip then
            return
        end
        GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
        GameTooltip:SetText("RPE")
        GameTooltip:AddLine("Left-click to open the RPE menu.", 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    button:SetScript("OnDragStart", function(frame)
        frame:LockHighlight()
        frame:SetScript("OnUpdate", function()
            self:UpdateDragPosition()
        end)
    end)

    button:SetScript("OnDragStop", function(frame)
        frame:SetScript("OnUpdate", nil)
        frame:UnlockHighlight()
        self:PersistPosition()
    end)

    self.frame = button
    self:ApplyPosition(state.angle)

    if state.hidden then
        button:Hide()
    else
        button:Show()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if self.frame and self.frame:IsShown() then
                    self:ShowFirstRunHelp()
                end
            end)
        else
            self:ShowFirstRunHelp()
        end
    end

    return button
end

function MinimapButton:GetFrame()
    return self.frame
end

function MinimapButton:SetHidden(hidden)
    local state = loadMinimapState()
    state.hidden = hidden == true
    saveMinimapState(state)

    if self.frame then
        if state.hidden then
            self.frame:Hide()
        else
            self.frame:Show()
        end
    end
    return state.hidden
end

MinimapButton:Create()

return LauncherMenu
