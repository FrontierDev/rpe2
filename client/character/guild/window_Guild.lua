local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local Client = Addon.Client
local GuildUI = Addon.Client.UI.Guild
local UI = Addon.UI or {}

local GuildWindow = GuildUI.Window or {}
GuildUI.Window = GuildWindow
GuildWindow.__index = GuildWindow

local WINDOW_WIDTH = 540
local WINDOW_HEIGHT = 420
local WINDOW_CONTENT_INSET_X = 8
local WINDOW_CONTENT_INSET_TOP = 28
local WINDOW_CONTENT_INSET_BOTTOM = 8
local PAGE_PADDING_TOP = 2

local function refreshPageOnShow(page, refreshFn)
    if not page or type(refreshFn) ~= "function" or not page.SetScript then
        return
    end

    page:SetScript("OnShow", function()
        refreshFn()
    end)
end

local function getAssignedRankLabel(status)
    local rank = status and status.rank or nil
    local rankName = tostring(rank and rank.name or "")
    if rankName ~= "" then
        return rankName
    end

    local rankId = tostring(rank and rank.id or "")
    if rankId ~= "" then
        return rankId
    end

    local assignedRankRef = tostring(status and status.assignedRankRef or "")
    return assignedRankRef ~= "" and assignedRankRef or "Unknown"
end

local function describeAssignedRankStatus(status)
    local statusKey = tostring(status and status.status or "not-in-guild")
    if statusKey == "valid" then
        return "Guild Rank: " .. getAssignedRankLabel(status)
    elseif statusKey == "unassigned" then
        return "Guild Rank: Not assigned"
    elseif statusKey == "not-eligible-for-current-wow-rank" then
        return "Guild Rank: " .. getAssignedRankLabel(status) .. " (no longer valid for current WoW rank)"
    elseif statusKey == "not-applicable" then
        return "Guild Rank: " .. getAssignedRankLabel(status) .. " (not applicable to this guild)"
    elseif statusKey == "unknown-rank" then
        return "Guild Rank: Unknown assignment"
    elseif statusKey == "guild-loading" then
        return "Guild Rank: Guild information is still loading"
    elseif statusKey == "not-in-guild" then
        return "Guild Rank: Not in a guild"
    end

    return "Guild Rank: Unavailable"
end

local function createInstance()
    return setmetatable({
        window = nil,
        requisitionsPage = GuildUI.RequisitionsPage,
        progressionPage = GuildUI.ProgressionPage,
        adminPage = GuildUI.AdminPage,
    }, GuildWindow)
end

function GuildWindow:Get()
    if not self._singleton then
        self._singleton = createInstance()
    end

    return self._singleton
end

function GuildWindow:IsVisible()
    local frame = self.window and self.window.GetFrame and self.window:GetFrame() or nil
    return frame and frame.IsShown and frame:IsShown() == true or false
end

function GuildWindow:GetActiveTabKey()
    local activeTab = self.window and self.window.GetActiveTab and self.window:GetActiveTab() or nil
    return tostring(activeTab and activeTab.name or "requisitions")
end

function GuildWindow:GetTabIndex(tabKey)
    local normalizedKey = tostring(tabKey or "requisitions")
    local tabs = self.window and self.window.GetTabs and self.window:GetTabs() or nil
    for index = 1, #(tabs or {}) do
        local tab = tabs[index]
        if tostring(tab and tab.name or "") == normalizedKey then
            return index
        end
    end

    return 1
end

function GuildWindow:GetAssignedGuildRankDisplay()
    local Guild = Client.Guild
    local status = {
        status = "not-in-guild",
    }
    if Guild and type(Guild.GetAssignedGuildRankStatus) == "function" then
        status = Guild:GetAssignedGuildRankStatus() or status
    end

    return status, describeAssignedRankStatus(status)
end

function GuildWindow:RefreshTab(tabKey)
    local normalizedKey = tostring(tabKey or "requisitions")
    if normalizedKey == "requisitions" then
        if self.requisitionsPage and self.requisitionsPage.Refresh then
            self.requisitionsPage:Refresh()
        end
    elseif normalizedKey == "progression" then
        if self.progressionPage and self.progressionPage.Refresh then
            self.progressionPage:Refresh()
        end
    elseif normalizedKey == "admin" then
        if self.adminPage and self.adminPage.Refresh then
            self.adminPage:Refresh()
        end
    end
end

function GuildWindow:BuildWindow()
    if self.window then
        local frame = self.window.GetFrame and self.window:GetFrame() or nil
        if frame and frame.SetSize then
            frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
        end
        return self.window
    end

    self.window = UI.Window:New({
        name = "RPEGuildWindow",
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
                name = "requisitions",
                label = "Requisitions",
                width = 92,
                builder = function(page)
                    self.requisitionsPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("requisitions")
                    end)
                end,
            },
            {
                name = "progression",
                label = "Progression",
                width = 82,
                builder = function(page)
                    self.progressionPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("progression")
                    end)
                end,
            },
            {
                name = "admin",
                label = "Admin",
                width = 54,
                builder = function(page)
                    self.adminPage:Build(page, self)
                    refreshPageOnShow(page, function()
                        self:RefreshTab("admin")
                    end)
                end,
            },
        },
    })
    self.window:SetTitle("Guild")
    self.window:Create()
    local frame = self.window.GetFrame and self.window:GetFrame() or nil
    if frame and frame.SetSize then
        frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    end

    return self.window
end

function GuildWindow:Refresh()
    if self.window and self.window.SetTitle then
        self.window:SetTitle("Guild")
    end
    self:RefreshTab(self:GetActiveTabKey())
    return self.window
end

function GuildWindow:RefreshVisible()
    if self:IsVisible() then
        self:Refresh()
    end
    return self.window
end

function GuildWindow:Show()
    local window = self:BuildWindow()
    self:Refresh()
    if window and window.Show then
        window:Show()
    end
    return window
end

function GuildWindow:Hide()
    if self.window and self.window.Hide then
        self.window:Hide()
    end
    return self.window
end

function Client:BuildGuildWindow()
    return GuildWindow:Get():BuildWindow()
end

function Client:ShowGuildWindow()
    return GuildWindow:Get():Show()
end

function Client:HideGuildWindow()
    return GuildWindow:Get():Hide()
end

return GuildWindow
