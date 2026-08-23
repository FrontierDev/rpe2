local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Profile = Addon.Client.UI.Profile or {}

local Client = Addon.Client
local ProfileUI = Addon.Client.UI.Profile
local UI = Addon.UI or {}

local ProfileWindow = ProfileUI.Window or {}
ProfileUI.Window = ProfileWindow
ProfileWindow.__index = ProfileWindow

local WINDOW_CONTENT_INSET_X = 8
local WINDOW_CONTENT_INSET_TOP = 28
local WINDOW_CONTENT_INSET_BOTTOM = 8
local PAGE_PADDING_TOP = 2
local WINDOW_WIDTH = 524
local WINDOW_HEIGHT = 420

local function refreshPageOnShow(page, refreshFn)
    if not page or type(refreshFn) ~= "function" or not page.SetScript then
        return
    end

    page:SetScript("OnShow", function()
        refreshFn()
    end)
end

local function createInstance()
    return setmetatable({
        window = nil,
        SelectedSlotKey = nil,
        equipmentStatsPage = ProfileUI.EquipmentStatsPage,
        spellbookPage = ProfileUI.SpellbookPage,
        traitsPage = ProfileUI.TraitsPage,
        skillsPage = ProfileUI.SkillsPage,
    }, ProfileWindow)
end

function ProfileWindow:Get()
    if not self._singleton then
        self._singleton = createInstance()
    end

    return self._singleton
end

function ProfileWindow:SetSelectedSlotKey(slotKey, skipRefresh)
    self.SelectedSlotKey = slotKey
    if not skipRefresh then
        self:Refresh()
    end
end

function ProfileWindow:IsVisible()
    local frame = self.window and self.window.GetFrame and self.window:GetFrame() or nil
    return frame and frame.IsShown and frame:IsShown() == true or false
end

function ProfileWindow:GetActiveTabKey()
    local activeTab = self.window and self.window.GetActiveTab and self.window:GetActiveTab() or nil
    return tostring(activeTab and activeTab.name or "equipment")
end

function ProfileWindow:GetTabIndex(tabKey)
    local normalizedKey = tostring(tabKey or "equipment")
    local tabs = self.window and self.window.GetTabs and self.window:GetTabs() or nil
    for index = 1, #(tabs or {}) do
        local tab = tabs[index]
        if tostring(tab and tab.name or "") == normalizedKey then
            return index
        end
    end

    return 1
end

function ProfileWindow:RefreshTab(tabKey)
    local normalizedKey = tostring(tabKey or "equipment")
    if normalizedKey == "equipment" then
        if self.equipmentStatsPage and self.equipmentStatsPage.Refresh then
            self.equipmentStatsPage:Refresh()
        end
    elseif normalizedKey == "spellbook" then
        if self.spellbookPage and self.spellbookPage.Refresh then
            self.spellbookPage:Refresh()
        end
    elseif normalizedKey == "traits" then
        if self.traitsPage and self.traitsPage.Refresh then
            self.traitsPage:Refresh()
        end
    elseif normalizedKey == "skills" then
        if self.skillsPage and self.skillsPage.Refresh then
            self.skillsPage:Refresh()
        end
    end
end

function ProfileWindow:RefreshVisible()
    if self:IsVisible() then
        self:Refresh()
    end

    return self.window
end

function ProfileWindow:BuildWindow()
    if self.window then
        local frame = self.window.GetFrame and self.window:GetFrame() or nil
        if frame and frame.SetSize then
            frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
        end
        if self.equipmentStatsPage and self.equipmentStatsPage.ApplyMetrics then
            self.equipmentStatsPage:ApplyMetrics()
        end
        return self.window
    end

    self.window = UI.Window:New({
        name = "RPEProfileWindow",
        width = WINDOW_WIDTH,
        height = WINDOW_HEIGHT,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 25,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = WINDOW_CONTENT_INSET_X,
        contentInsetRight = WINDOW_CONTENT_INSET_X,
        contentInsetTop = WINDOW_CONTENT_INSET_TOP,
        contentInsetBottom = WINDOW_CONTENT_INSET_BOTTOM,
        pagePaddingTop = PAGE_PADDING_TOP,
        tabs = {
            {
                name = "equipment",
                label = "Equipment & Stats",
                width = 118,
                builder = function(page)
                    self.equipmentStatsPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("equipment")
                    end)
                    self.equipmentStatsPage:Refresh()
                end,
            },
            {
                name = "spellbook",
                label = "Spellbook",
                width = 70,
                builder = function(page)
                    self.spellbookPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("spellbook")
                    end)
                end,
            },
            {
                name = "traits",
                label = "Traits",
                width = 60,
                builder = function(page)
                    self.traitsPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("traits")
                    end)
                    self.traitsPage:Refresh()
                end,
            },
            {
                name = "skills",
                label = "Skills",
                width = 60,
                builder = function(page)
                    self.skillsPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("skills")
                    end)
                    self.skillsPage:Refresh()
                end,
            },
        },
    })
    self.window:SetTitle("Character")
    self.window:Create()
    local frame = self.window.GetFrame and self.window:GetFrame() or nil
    if frame and frame.SetSize then
        frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    end

    return self.window
end

function ProfileWindow:Refresh()
    self:RefreshTab(self:GetActiveTabKey())

    return self.window
end

function ProfileWindow:ShowTab(tabKey)
    local window = self:BuildWindow()
    local tabIndex = self:GetTabIndex(tabKey)
    if window and window.SetActiveTab then
        window:SetActiveTab(tabIndex)
    end
    self:RefreshTab(tabKey)
    if window and window.Show then
        window:Show()
    end
    return window
end

function ProfileWindow:Show()
    local window = self:BuildWindow()
    self:Refresh()
    if window and window.Show then
        window:Show()
    end
    return window
end

function ProfileWindow:Hide()
    if Client.Crafting and Client.Crafting.HandleProfileWindowClosed then
        Client.Crafting:HandleProfileWindowClosed()
    end
    if self.window and self.window.Hide then
        self.window:Hide()
    end
    return self.window
end

function Client:BuildProfileWindow()
    return ProfileWindow:Get():BuildWindow()
end

function Client:ShowProfileWindow()
    return ProfileWindow:Get():Show()
end

function Client:ShowProfileWindowTab(tabKey)
    return ProfileWindow:Get():ShowTab(tabKey)
end

function Client:HideProfileWindow()
    return ProfileWindow:Get():Hide()
end

return ProfileWindow
