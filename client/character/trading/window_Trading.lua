local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Trading = Addon.Client.UI.Trading or {}

local Client = Addon.Client
local TradingUI = Addon.Client.UI.Trading
local UI = Addon.UI or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}
local MarketRates = Client.MarketRates or {}

local TradingWindow = TradingUI.Window or {}
TradingUI.Window = TradingWindow
TradingWindow.__index = TradingWindow

local WINDOW_WIDTH = 840
local WINDOW_HEIGHT = 440
local MIN_WINDOW_WIDTH = 680
local MIN_WINDOW_HEIGHT = 360
local CONTENT_INSET_X = 8
local CONTENT_INSET_TOP = 28
local CONTENT_INSET_BOTTOM = 8
local PANEL_INSET = 4

local function createInstance()
    local instance = setmetatable({
        window = nil,
        root = nil,
        marketPanel = nil,
        chartPanel = nil,
        itemPanel = nil,
        marketPage = TradingUI.Markets and TradingUI.Markets:New() or nil,
        chartPage = TradingUI.Chart and TradingUI.Chart:New() or nil,
        itemsPage = TradingUI.Items and TradingUI.Items:New() or nil,
        selectedMarketRef = nil,
        selectedMarket = nil,
        hasOpened = false,
        marketRatesListener = nil,
        runtimeListener = nil,
    }, TradingWindow)

    if type(MarketRates.RegisterRefreshListener) == "function" then
        instance.marketRatesListener = MarketRates.RegisterRefreshListener(function(reason)
            instance:RefreshVisible(reason or "daily-reset")
        end)
    end
    if type(Runtime.RegisterPostCommitListener) == "function" then
        instance.runtimeListener = Runtime:RegisterPostCommitListener(function(changeSet)
            if not instance:IsVisible() or type(changeSet) ~= "table" then
                return
            end
            if changeSet.inventory or changeSet.currencies then
                instance:RefreshVisible("runtime")
            end
        end)
    end
    return instance
end

function TradingWindow:Get()
    if not self._singleton then
        self._singleton = createInstance()
    end
    return self._singleton
end

function TradingWindow:IsVisible()
    local frame = self.window and self.window.GetFrame and self.window:GetFrame() or nil
    return frame and frame.IsShown and frame:IsShown() == true or false
end

function TradingWindow:SelectMarket(marketRef, reason)
    self.selectedMarketRef = type(marketRef) == "string" and marketRef or nil
    self.selectedMarket = self.marketPage and self.marketPage:GetSelectedMarket() or nil

    if self.selectedMarket and self.selectedMarket.marketRef ~= self.selectedMarketRef then
        self.selectedMarket = nil
    end

    if self.chartPage then
        self.chartPage:Refresh(
            self.selectedMarket and self.selectedMarket.market or nil,
            self.selectedMarketRef
        )
    end
    if self.itemsPage then
        self.itemsPage:SetMarket(self.selectedMarketRef, reason)
    end
    return self.selectedMarket
end

function TradingWindow:BuildItemHost(parent)
    if self.itemsPage then
        return self.itemsPage:Build(parent, self)
    end
end

function TradingWindow:BuildWindow()
    if self.window then
        local frame = self.window.GetFrame and self.window:GetFrame() or nil
        if frame and frame.SetSize then
            frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
        end
        if self.itemsPage and self.itemsPage.built ~= true and self.itemPanel then
            self:BuildItemHost(self.itemPanel:GetContentFrame())
        end
        return self.window
    end

    self.window = UI.Window:New({
        name = "RPETradingWindow",
        width = WINDOW_WIDTH,
        height = WINDOW_HEIGHT,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 27,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = CONTENT_INSET_X,
        contentInsetRight = CONTENT_INSET_X,
        contentInsetTop = CONTENT_INSET_TOP,
        contentInsetBottom = CONTENT_INSET_BOTTOM,
    })
    self.window:SetTitle("Trading")
    self.window:Create()
    local windowFrame = self.window:GetFrame()
    if windowFrame and windowFrame.HookScript then
        windowFrame:HookScript("OnSizeChanged", function(frame)
            local width = tonumber(frame:GetWidth()) or WINDOW_WIDTH
            local height = tonumber(frame:GetHeight()) or WINDOW_HEIGHT
            if width < MIN_WINDOW_WIDTH or height < MIN_WINDOW_HEIGHT then
                frame:SetSize(math.max(MIN_WINDOW_WIDTH, width), math.max(MIN_WINDOW_HEIGHT, height))
            end
        end)
    end

    self.root = UI.CreateLayout(UI.HorizontalLayoutGroup, self.window:GetContentFrame(), "RPETradingRoot", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.root, self.window:GetContentFrame(), 0, 0, 0, 0)

    self.marketPanel = UI.CreatePanel(self.root:GetFrame(), "RPETradingMarketsPanel", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        contentInset = PANEL_INSET,
        showBorder = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
    })
    self.root:AddChild(self.marketPanel)

    self.chartPanel = UI.CreatePanel(self.root:GetFrame(), "RPETradingChartPanel", {
        expandWidth = true,
        expandHeight = true,
        weight = 2,
        contentInset = PANEL_INSET,
        showBorder = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
    })
    self.root:AddChild(self.chartPanel)

    self.itemPanel = UI.CreatePanel(self.root:GetFrame(), "RPETradingItemsPanel", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        contentInset = PANEL_INSET,
        showBorder = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
    })
    self.root:AddChild(self.itemPanel)

    if self.marketPage then
        self.marketPage:Build(self.marketPanel:GetContentFrame(), self)
    end
    if self.chartPage then
        self.chartPage:Build(self.chartPanel:GetContentFrame(), self)
    end
    self:BuildItemHost(self.itemPanel:GetContentFrame())

    if self.root.RefreshLayout then
        self.root:RefreshLayout()
    end
    return self.window
end

function TradingWindow:Refresh(reason)
    if not self.window then
        return nil
    end

    local selectionChanged = self.marketPage and self.marketPage:Refresh(reason) or false
    local selectedRef = self.marketPage and self.marketPage.selectedMarketRef or nil
    if not selectionChanged then
        self:SelectMarket(selectedRef, reason)
    end
    self.hasOpened = true
    return self.window
end

function TradingWindow:RefreshVisible(reason)
    if self:IsVisible() then
        return self:Refresh(reason)
    end
    return self.window
end

function TradingWindow:Show()
    local window = self:BuildWindow()
    self:Refresh("open")
    if window and window.Show then
        window:Show()
    end
    return window
end

function TradingWindow:Hide()
    if self.window and self.window.Hide then
        self.window:Hide()
    end
    return self.window
end

function Client:BuildTradingWindow()
    return TradingWindow:Get():BuildWindow()
end

function Client:ShowTradingWindow()
    if self:RequireSetupCompletion("trading-window") ~= true then
        return nil
    end
    return TradingWindow:Get():Show()
end

function Client:HideTradingWindow()
    return TradingWindow:Get():Hide()
end

return TradingWindow
