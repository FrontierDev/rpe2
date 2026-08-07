local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Inventory = Addon.Client.UI.Inventory or {}

local Client = Addon.Client
local UI = Addon.UI or {}
local Inventory = Addon.Client.Inventory or {}
local InventoryUI = Addon.Client.UI.Inventory

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
        if not self.changeListenerHandle and Inventory.RegisterChangeListener then
            self.changeListenerHandle = Inventory.RegisterChangeListener(function()
                self:Refresh()
            end)
        end
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
                    self.inventoryPage:Refresh()
                end,
            },
            {
                label = "Consumables",
                width = 78,
                builder = function(page)
                    self.consumablesPage:Build(page)
                    self.consumablesPage:Refresh()
                end,
            },
            {
                label = "Reagents",
                width = 60,
                builder = function(page)
                    self.reagentsPage:Build(page)
                    self.reagentsPage:Refresh()
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
            return result
        end
        self._tabLayoutHookInstalled = true
    end

    if not self.changeListenerHandle and Inventory.RegisterChangeListener then
        self.changeListenerHandle = Inventory.RegisterChangeListener(function()
            self:Refresh()
        end)
    end

    self:RefreshWindowLayout()

    return self.window
end

function InventoryWindow:Refresh()
    if self.inventoryPage and self.inventoryPage.Refresh then
        self.inventoryPage:Refresh()
    end
    if self.consumablesPage and self.consumablesPage.Refresh then
        self.consumablesPage:Refresh()
    end
    if self.reagentsPage and self.reagentsPage.Refresh then
        self.reagentsPage:Refresh()
    end

    return self.window
end

function InventoryWindow:Show()
    local window = self:BuildWindow()
    self:Refresh()
    self:RefreshWindowLayout()
    if window and window.Show then
        window:Show()
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
