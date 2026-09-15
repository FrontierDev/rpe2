local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}

local Server = Addon.Server
local ServerUI = Addon.Server.UI
local UI = Addon.UI or {}
local C = UI.Constants or {}

ServerUI.EventManage = ServerUI.EventManage or {}
local EventManage = ServerUI.EventManage
EventManage.__index = EventManage

local function anchorPageRoot(root, page)
    if not root or not page then
        return root
    end

    if root.ClearAllPoints then
        root:ClearAllPoints()
    end
    if root.SetPoint then
        root:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
        root:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
        root:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
        root:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    end
    if root.RefreshLayout then
        root:RefreshLayout()
    end

    return root
end

function EventManage:IsWindowVisible()
    local window = self.Window
    local frame = window and window.GetFrame and window:GetFrame() or nil
    return frame and frame.IsShown and frame:IsShown() == true
end

function EventManage:SyncUpdaterState()
    local updater = self.UpdaterFrame
    if not updater then
        return
    end

    self.Elapsed = 0
    if self:IsWindowVisible() then
        if updater.Show then
            updater:Show()
        end
        return
    end

    if updater.Hide then
        updater:Hide()
    end
end

function EventManage:EnsureUpdater()
    self.UpdaterFrame = self.UpdaterFrame or CreateFrame("Frame")
    self.UpdaterFrame:SetScript("OnUpdate", nil)
    self:SyncUpdaterState()
end

function EventManage:BuildWindow()
    if self.Window then
        return self.Window
    end

    local layout = self.Layout or {}
    local window = UI.Window:New({
        name = "RPEServerEventManageWindow",
        width = layout.WindowWidth or 520,
        height = layout.WindowHeight or 360,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 20,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = false,
        titleFontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        titleFontSize = (C.FontSizes and C.FontSizes.Heading1) or 18,
        titleOffsetY = (C.Window and C.Window.TitleOffsetY) or 16,
        contentInsetLeft = (C.Window and C.Window.ContentInsetLeft) or 16,
        contentInsetRight = (C.Window and C.Window.ContentInsetRight) or 16,
        contentInsetTop = (C.Window and C.Window.ContentInsetTop) or 44,
        contentInsetBottom = (C.Window and C.Window.ContentInsetBottom) or 16,
        borderSize = (C.Window and C.Window.BorderSize) or 2,
        tabs = {
            {
                name = "page_Dashboard",
                label = "Dashboard",
                width = 84,
                builder = function(page)
                    EventManage:BuildDashboardPage(page)
                end,
            },
            {
                name = "page_Units",
                label = "Units",
                width = 56,
                builder = function(page)
                    EventManage:BuildUnitsPage(page)
                end,
            },
            {
                name = "page_Actions",
                label = "Actions",
                width = 60,
                builder = function(page)
                    local root = EventManage:BuildActionsPage(page)
                    anchorPageRoot(root, page)
                end,
            },
            {
                name = "page_Settings",
                label = "Settings",
                width = 64,
                builder = function(page)
                    EventManage:BuildSettingsPage(page)
                end,
            },
        },
        activeTabIndex = 1,
    })

    window:SetTitle("Event Management")
    window:Create()

    local frame = window.GetFrame and window:GetFrame() or nil
    if frame and frame.HookScript then
        frame:HookScript("OnShow", function()
            EventManage:SyncUpdaterState()
        end)
        frame:HookScript("OnHide", function()
            EventManage:SyncUpdaterState()
        end)
    end

    self.Window = window
    self:EnsureUpdater()
    self:SyncUpdaterState()
    self:RefreshDashboard()
    self:RefreshUnitsPage()
    if self.RefreshSettingsPage then
        self:RefreshSettingsPage()
    end
    return window
end

function EventManage:ShowWindow()
    local window = self:BuildWindow()
    if window and window.Show then
        window:Show()
    end

    self:SyncUpdaterState()
    self:RefreshDashboard()
    self:RefreshUnitsPage()
    if self.RefreshSettingsPage then
        self:RefreshSettingsPage()
    end
    return window
end

function EventManage:HideWindow()
    local window = self.Window
    if window and window.Hide then
        window:Hide()
    end

    self:SyncUpdaterState()
    return window
end

function Server:BuildEventManageWindow()
    return EventManage:BuildWindow()
end

function Server:ShowEventManageWindow()
    if not Addon.Client
        or type(Addon.Client.RequireSetupCompletion) ~= "function"
        or Addon.Client:RequireSetupCompletion("event-manager") ~= true
    then
        return nil
    end

    return EventManage:ShowWindow()
end

function Server:HideEventManageWindow()
    return EventManage:HideWindow()
end
