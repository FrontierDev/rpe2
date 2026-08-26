local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Inventory = Addon.Client.UI.Inventory or {}

local Client = Addon.Client
local UI = Addon.UI or {}
local Inventory = Addon.Client.Inventory or {}
local InventoryUI = Addon.Client.UI.Inventory
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}

local function startTiming(label, thresholdMs, context)
    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Start) == "function" then
        if type(timings.IsEnabled) == "function" and not timings:IsEnabled() then
            return nil
        end
        return timings:Start(label, {
            thresholdMs = thresholdMs,
            context = context,
        })
    end
    return nil
end

local function stopTiming(timer, cardinality)
    if not timer then
        return
    end

    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Stop) == "function" then
        timings:Stop(timer, { cardinality = cardinality })
    end
end

local function enqueueRefreshWork(fn, ...)
    local tasks = Addon.Internal and Addon.Internal.Tasks or nil
    if type(tasks) == "table" and type(tasks.Enqueue) == "function" then
        tasks:Enqueue(fn, ...)
        return true
    end

    if C_Timer and type(C_Timer.After) == "function" then
        local args = { ... }
        local argCount = select("#", ...)
        C_Timer.After(0, function()
            fn(unpack(args, 1, argCount))
        end)
        return true
    end

    fn(...)
    return true
end

local InventoryWindow = InventoryUI.Window or {}
InventoryUI.Window = InventoryWindow
InventoryWindow.__index = InventoryWindow

local GRID_COLUMNS = 8
local GRID_ROWS = 6
local SLOT_SIZE = 28
local SLOT_SPACING = 4
local GRID_PADDING = 4
local WINDOW_CONTENT_INSET_X = 8
local WINDOW_CONTENT_INSET_TOP = 28
local WINDOW_CONTENT_INSET_BOTTOM = 4
local PAGE_PADDING_TOP = 2
local TAB_HEIGHT = 16
local TOOLBAR_HEIGHT = 40
local TOOLBAR_TO_GRID_SPACING = 4
local CURRENCY_PANEL_COLLAPSED_HEIGHT = 22
local CURRENCY_PANEL_EXPANDED_HEIGHT = 108
local GRID_TO_CURRENCY_PANEL_SPACING = 4
local GRID_WIDTH = (GRID_PADDING * 2) + (GRID_COLUMNS * SLOT_SIZE) + ((GRID_COLUMNS - 1) * SLOT_SPACING)
local WINDOW_WIDTH = GRID_WIDTH + (WINDOW_CONTENT_INSET_X * 2) + 8
local GRID_HEIGHT = (GRID_PADDING * 2) + (GRID_ROWS * SLOT_SIZE) + ((GRID_ROWS - 1) * SLOT_SPACING)
local WINDOW_BASE_HEIGHT = WINDOW_CONTENT_INSET_TOP
    + WINDOW_CONTENT_INSET_BOTTOM
    + TAB_HEIGHT
    + PAGE_PADDING_TOP
    + TOOLBAR_HEIGHT
    + TOOLBAR_TO_GRID_SPACING
    + GRID_HEIGHT
    + GRID_TO_CURRENCY_PANEL_SPACING
    + 2
local WINDOW_HEIGHT = WINDOW_BASE_HEIGHT + CURRENCY_PANEL_COLLAPSED_HEIGHT

local function createInstance()
    return setmetatable({
        window = nil,
        inventoryPage = InventoryUI.InventoryPage,
        consumablesPage = InventoryUI.ConsumablesPage,
        reagentsPage = InventoryUI.ReagentsPage,
        changeListenerHandle = nil,
        runtimeChangeListenerHandle = nil,
        refreshQueued = false,
    }, InventoryWindow)
end

function InventoryWindow:Get()
    if not self._singleton then
        self._singleton = createInstance()
    end

    return self._singleton
end

function InventoryWindow:GetPageForTabIndex(index)
    if index == 2 then
        return self.consumablesPage
    end

    if index == 3 then
        return self.reagentsPage
    end

    return self.inventoryPage
end

function InventoryWindow:GetActivePage()
    local activeTabIndex = self.window and self.window.tabContainer and self.window.tabContainer.activeTabIndex or 1
    return self:GetPageForTabIndex(activeTabIndex)
end

function InventoryWindow:IsVisible()
    local frame = self.window and self.window.GetFrame and self.window:GetFrame() or nil
    return frame and frame.IsShown and frame:IsShown() == true or false
end

function InventoryWindow:MarkPagesDirty()
    local pages = {
        self.inventoryPage,
        self.consumablesPage,
        self.reagentsPage,
    }
    for index = 1, #pages do
        local page = pages[index]
        if page and page.MarkDirty then
            page:MarkDirty()
        end
    end
end

function InventoryWindow:EnsureChangeListeners()
    if not self.changeListenerHandle and Inventory.RegisterChangeListener then
        self.changeListenerHandle = Inventory.RegisterChangeListener(function()
            self:QueueRefresh("inventory-changed")
        end)
    end

    if not self.runtimeChangeListenerHandle
        and type(Runtime) == "table"
        and type(Runtime.RegisterPostCommitListener) == "function"
    then
        self.runtimeChangeListenerHandle = Runtime:RegisterPostCommitListener(function(changeSet)
            if type(changeSet) == "table" and type(changeSet.currencies) == "table" then
                self:QueueRefresh("currency-changed")
            end
        end)
    end
end

function InventoryWindow:QueueRefresh()
    self:MarkPagesDirty()
    if not self:IsVisible() then
        return self.window
    end

    if self.refreshQueued then
        return self.window
    end

    self.refreshQueued = true
    enqueueRefreshWork(function(controller)
        controller.refreshQueued = false
        if controller:IsVisible() then
            controller:Refresh()
        else
            controller:MarkPagesDirty()
        end
    end, self)

    return self.window
end

function InventoryWindow:RefreshWindowLayout()
    if not self.window then
        return nil
    end

    local activePage = self:GetActivePage()
    local currencyPanelHeight = activePage and activePage.GetCurrencyPanelHeight and activePage:GetCurrencyPanelHeight() or CURRENCY_PANEL_COLLAPSED_HEIGHT
    local desiredHeight = WINDOW_BASE_HEIGHT + math.max(CURRENCY_PANEL_COLLAPSED_HEIGHT, math.min(CURRENCY_PANEL_EXPANDED_HEIGHT, tonumber(currencyPanelHeight) or CURRENCY_PANEL_COLLAPSED_HEIGHT))
    self.window:SetHeight(desiredHeight)
    return desiredHeight
end

function InventoryWindow:BuildWindow()
    if self.window then
        self:EnsureChangeListeners()
        return self.window
    end

    if self.inventoryPage and self.inventoryPage.SetWindowController then
        self.inventoryPage:SetWindowController(self)
    end
    if self.consumablesPage and self.consumablesPage.SetWindowController then
        self.consumablesPage:SetWindowController(self)
    end
    if self.reagentsPage and self.reagentsPage.SetWindowController then
        self.reagentsPage:SetWindowController(self)
    end

    self.window = UI.Window:New({
        name = "RPEInventoryWindow",
        width = WINDOW_WIDTH,
        height = WINDOW_HEIGHT,
        point = "TOPLEFT",
        relativeTo = UIParent,
        relativePoint = "TOPLEFT",
        x = 24,
        y = -24,
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
                label = "Inventory",
                width = 60,
                builder = function(page)
                    self.inventoryPage:Build(page)
                end,
            },
            {
                label = "Consumables",
                width = 78,
                builder = function(page)
                    self.consumablesPage:Build(page)
                end,
            },
            {
                label = "Reagents",
                width = 60,
                builder = function(page)
                    self.reagentsPage:Build(page)
                end,
            },
        },
    })
    self.window:SetTitle("")
    self.window:Create()

    if self.window.tabContainer and self.window.tabContainer.SetActiveTab and not self._tabLayoutHookInstalled then
        local tabContainer = self.window.tabContainer
        local originalSetActiveTab = tabContainer.SetActiveTab
        tabContainer.SetActiveTab = function(container, index)
            local result = originalSetActiveTab(container, index)
            self:RefreshWindowLayout()
            local page = self:GetActivePage()
            if page then
                if self:IsVisible() and page.RefreshIfDirty then
                    page:RefreshIfDirty()
                elseif page.MarkDirty then
                    page:MarkDirty()
                end
            end
            return result
        end
        self._tabLayoutHookInstalled = true
    end

    self:EnsureChangeListeners()

    self:RefreshWindowLayout()

    return self.window
end

function InventoryWindow:Refresh()
    local activePage = self:GetActivePage()
    if not self:IsVisible() then
        self:MarkPagesDirty()
        return self.window
    end

    local pages = {
        self.inventoryPage,
        self.consumablesPage,
        self.reagentsPage,
    }
    for index = 1, #pages do
        local page = pages[index]
        if page == activePage then
            if page.RefreshIfDirty then
                page:RefreshIfDirty()
            end
        elseif page and page.MarkDirty then
            page:MarkDirty()
        end
    end

    return self.window
end

function InventoryWindow:Show()
    local timer = startTiming("InventoryWindow:Show", 8, self.activeTabKey or "inventory")
    local window = self:BuildWindow()
    if window and window.Show then
        window:Show()
    end
    self:RefreshWindowLayout()
    self:Refresh()
    if timer then
        stopTiming(timer, {
            activeTab = self.activeTabKey or "inventory",
            builtPages = (self.inventoryPage and self.inventoryPage.frame and 1 or 0)
                + (self.consumablesPage and self.consumablesPage.frame and 1 or 0)
                + (self.reagentsPage and self.reagentsPage.frame and 1 or 0),
        })
    end
    return window
end

function InventoryWindow:Hide()
    if self.window and self.window.Hide then
        self.window:Hide()
    end
    return self.window
end

function Client:BuildInventoryWindow()
    return InventoryWindow:Get():BuildWindow()
end

function Client:ShowInventoryWindow()
    return InventoryWindow:Get():Show()
end

function Client:HideInventoryWindow()
    return InventoryWindow:Get():Hide()
end

return InventoryWindow
