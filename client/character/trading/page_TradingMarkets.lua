local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Trading = Addon.Client.UI.Trading or {}

local Client = Addon.Client
local TradingUI = Addon.Client.UI.Trading
local UI = Addon.UI or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local MarketsPage = TradingUI.Markets or {}
TradingUI.Markets = MarketsPage
MarketsPage.__index = MarketsPage

local FILTERS = {
    { label = "All Markets", value = "all" },
    { label = "Exchanges", value = "exchange" },
    { label = "Trackers", value = "tracker" },
}

local MARKET_ROW_HEIGHT = 30
local MARKET_ROWS_PER_PAGE = 10
local FILTER_NAV_HEIGHT = 20
local PAGE_NAV_HEIGHT = 20
local PAGE_BUTTON_WIDTH = 24
local PAGE_TEXT_WIDTH = 82

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function lower(value)
    return string.lower(trim(value))
end

local function setShown(element, shown, height)
    local frame = element and element.GetFrame and element:GetFrame() or nil
    if frame then
        if frame.SetShown then
            frame:SetShown(shown == true)
        elseif shown then
            frame:Show()
        else
            frame:Hide()
        end
        if height ~= nil and frame.SetHeight then
            frame:SetHeight(height)
        end
    end
    if element and type(element.options) == "table" and height ~= nil then
        element.options.height = height
        element.options.expandHeight = false
    end
end

local function getMarketName(entry)
    local market = entry and entry.market or {}
    local name = trim(market.name)
    return name ~= "" and name or trim(entry and entry.marketRef)
end

local function getMarketType(entry)
    return lower(entry and entry.market and entry.market.marketType)
end

local function marketSort(left, right)
    local leftMarket = left and left.market or {}
    local rightMarket = right and right.market or {}
    local leftIndex = lower(leftMarket.index)
    local rightIndex = lower(rightMarket.index)
    if leftIndex ~= rightIndex then
        return leftIndex < rightIndex
    end

    local leftName = lower(getMarketName(left))
    local rightName = lower(getMarketName(right))
    if leftName ~= rightName then
        return leftName < rightName
    end

    return trim(left and left.marketRef) < trim(right and right.marketRef)
end

local function createInstance()
    return setmetatable({
        owner = nil,
        root = nil,
        filterIndex = 1,
        page = 1,
        markets = {},
        filteredMarkets = {},
        selectedMarketRef = nil,
        rows = {},
        filterDropdown = nil,
        pageText = nil,
        emptyText = nil,
        statusText = nil,
        listLayout = nil,
        built = false,
    }, MarketsPage)
end

function MarketsPage:New()
    return createInstance()
end

function MarketsPage:GetSelectedMarket()
    for index = 1, #self.filteredMarkets do
        local entry = self.filteredMarkets[index]
        if entry and entry.marketRef == self.selectedMarketRef then
            return entry
        end
    end
    return nil
end

function MarketsPage:GetFilterValue()
    return FILTERS[self.filterIndex] and FILTERS[self.filterIndex].value or "all"
end

function MarketsPage:LoadMarkets()
    if type(Registry.ListActivatedMarkets) ~= "function" then
        return nil, "Activated Market registry is unavailable."
    end

    local ok, entries = pcall(Registry.ListActivatedMarkets, Registry)
    if not ok or type(entries) ~= "table" then
        return nil, "Activated Markets could not be loaded."
    end

    local markets = {}
    for index = 1, #entries do
        local entry = entries[index]
        if type(entry) == "table"
            and trim(entry.marketRef) ~= ""
            and type(entry.market) == "table"
            and (getMarketType(entry) == "exchange" or getMarketType(entry) == "tracker")
        then
            markets[#markets + 1] = entry
        end
    end
    table.sort(markets, marketSort)
    return markets
end

function MarketsPage:ApplyFilter()
    local wantedType = self:GetFilterValue()
    self.filteredMarkets = {}
    for index = 1, #self.markets do
        local entry = self.markets[index]
        if wantedType == "all" or getMarketType(entry) == wantedType then
            self.filteredMarkets[#self.filteredMarkets + 1] = entry
        end
    end
end

function MarketsPage:FindOpeningSelection()
    for index = 1, #self.filteredMarkets do
        if getMarketType(self.filteredMarkets[index]) == "exchange" then
            return self.filteredMarkets[index].marketRef
        end
    end
    return self.filteredMarkets[1] and self.filteredMarkets[1].marketRef or nil
end

function MarketsPage:EnsureSelection(initialOpen)
    local selectedVisible = self:GetSelectedMarket()
    if selectedVisible then
        return self.selectedMarketRef
    end

    if initialOpen then
        self.selectedMarketRef = self:FindOpeningSelection()
    else
        local first = self.filteredMarkets[1]
        self.selectedMarketRef = first and first.marketRef or nil
    end
    return self.selectedMarketRef
end

function MarketsPage:UpdateRows()
    local total = #self.filteredMarkets
    local pageCount = math.max(1, math.ceil(total / MARKET_ROWS_PER_PAGE))
    self.page = math.max(1, math.min(self.page, pageCount))
    local firstIndex = ((self.page - 1) * MARKET_ROWS_PER_PAGE) + 1

    for rowIndex = 1, #self.rows do
        local row = self.rows[rowIndex]
        local market = self.filteredMarkets[firstIndex + rowIndex - 1]
        if market then
            local marketDefinition = market.market or {}
            local marketType = getMarketType(market)
            local indexLabel = trim(marketDefinition.index)
            local displayIndex = indexLabel ~= "" and indexLabel or "--"
            local typeLabel = marketType == "exchange" and "Exchange" or "Tracker"
            local label = ("[%s] %s (%s)"):format(displayIndex, getMarketName(market), typeLabel)
            row._marketRef = market.marketRef
            row:SetText(label)
            row:SetTooltip({
                type = "custom",
                title = getMarketName(market),
                lines = {
                    { left = typeLabel, colorToken = "text.secondary" },
                    { left = trim(market.marketRef), colorToken = "text.muted" },
                },
            })

            local selected = market.marketRef == self.selectedMarketRef
            local textColor = UI.ResolveColor(nil, selected and "accent" or "text.primary")
            row:SetLabelColor(textColor.r, textColor.g, textColor.b, textColor.a)
            if row.background and row.background.SetColorTexture then
                local background = UI.ResolveColor(nil, selected and "tab.bar" or "list.rowBackground")
                row.background:SetColorTexture(background.r, background.g, background.b, background.a)
            end
            setShown(row, true, MARKET_ROW_HEIGHT)
        else
            row._marketRef = nil
            row:SetText("")
            row:SetTooltip(nil)
            setShown(row, false, 0)
        end
    end

    if total == 0 then
        local message = self.statusText and self.statusText ~= ""
            and self.statusText
            or "No active Markets match this filter."
        self.emptyText:SetText(message)
        setShown(self.emptyText, true, 34)
    else
        setShown(self.emptyText, false, 0)
    end

    self.pageText:SetText(("Page %d / %d"):format(self.page, pageCount))
    self.previousPageButton:SetEnabled(self.page > 1)
    self.nextPageButton:SetEnabled(self.page < pageCount)
    self.listLayout:RefreshLayout()
end

function MarketsPage:SelectMarket(marketRef)
    if type(marketRef) ~= "string" or marketRef == "" then
        return false
    end
    self.selectedMarketRef = marketRef
    self:UpdateRows()
    if self.owner and type(self.owner.SelectMarket) == "function" then
        self.owner:SelectMarket(marketRef)
    end
    return true
end

function MarketsPage:SelectAdjacentFilter(offset)
    local nextIndex = self.filterIndex + (tonumber(offset) or 0)
    nextIndex = math.max(1, math.min(#FILTERS, nextIndex))
    if nextIndex == self.filterIndex then
        return
    end
    self.filterIndex = nextIndex
    self.page = 1
    self.filterDropdown:SetSelectedValue(FILTERS[nextIndex].value, true)
    self:Refresh("filter")
end

function MarketsPage:SetFilter(value)
    for index = 1, #FILTERS do
        if FILTERS[index].value == value then
            self.filterIndex = index
            self.page = 1
            self:Refresh("filter")
            return true
        end
    end
    return false
end

function MarketsPage:PreviousPage()
    self.page = math.max(1, self.page - 1)
    self:UpdateRows()
end

function MarketsPage:NextPage()
    self.page = self.page + 1
    self:UpdateRows()
end

function MarketsPage:Refresh(reason)
    local oldSelection = self.selectedMarketRef
    local initialOpen = self.owner and self.owner.hasOpened ~= true or false
    local markets, loadError = self:LoadMarkets()
    self.statusText = loadError
    self.markets = markets or {}
    self:ApplyFilter()
    self:EnsureSelection(initialOpen)
    self:UpdateRows()

    local changed = oldSelection ~= self.selectedMarketRef
    if changed and self.owner and type(self.owner.SelectMarket) == "function" then
        self.owner:SelectMarket(self.selectedMarketRef, reason)
    end
    return changed
end

function MarketsPage:Build(parent, owner)
    if self.built then
        return self.root
    end
    self.owner = owner

    self.root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPETradingMarketsRoot", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.root, parent, 0, 0, 0, 0)

    self.heading = UI.CreateText(self.root:GetFrame(), "RPETradingMarketsHeading", "Markets", {
        height = 18,
        expandWidth = true,
        justifyH = "LEFT",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Heading2) or 10,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.root:AddChild(self.heading)

    self.filterNav = UI.CreateLayout(UI.HorizontalLayoutGroup, self.root:GetFrame(), "RPETradingMarketsFilterNav", {
        height = FILTER_NAV_HEIGHT,
        expandWidth = true,
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.root:AddChild(self.filterNav)

    self.previousFilterButton = UI.CreateButton(self.filterNav:GetFrame(), "RPETradingMarketsPreviousFilter", "<", 22, function()
        self:SelectAdjacentFilter(-1)
    end, { height = FILTER_NAV_HEIGHT, fontSize = 8 })
    self.filterNav:AddChild(self.previousFilterButton)

    self.filterDropdown = UI.CreateDropdown(self.filterNav:GetFrame(), "RPETradingMarketsFilterDropdown", {
        width = 0,
        height = FILTER_NAV_HEIGHT,
        expandWidth = true,
        weight = 1,
        items = FILTERS,
        selectedValue = FILTERS[1].value,
        onValueChanged = function(value)
            if value and value ~= self:GetFilterValue() then
                self:SetFilter(value)
            end
        end,
    })
    self.filterNav:AddChild(self.filterDropdown)

    self.nextFilterButton = UI.CreateButton(self.filterNav:GetFrame(), "RPETradingMarketsNextFilter", ">", 22, function()
        self:SelectAdjacentFilter(1)
    end, { height = FILTER_NAV_HEIGHT, fontSize = 8 })
    self.filterNav:AddChild(self.nextFilterButton)

    self.listLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.root:GetFrame(), "RPETradingMarketsList", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.root:AddChild(self.listLayout)

    for index = 1, MARKET_ROWS_PER_PAGE do
        local row
        row = UI.CreateButton(self.listLayout:GetFrame(), "RPETradingMarketRow" .. index, "", 0, function()
            self:SelectMarket(row._marketRef)
        end, {
            height = MARKET_ROW_HEIGHT,
            expandWidth = true,
            fontSize = 9,
            backgroundColor = UI.ResolveColor(nil, "list.rowBackground"),
            labelColor = UI.ResolveColor(nil, "text.primary"),
        })
        self.rows[index] = row
        self.listLayout:AddChild(row)
    end

    self.emptyText = UI.CreateText(self.listLayout:GetFrame(), "RPETradingMarketsEmpty", "", {
        height = 0,
        expandWidth = true,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.muted"),
    })
    self.listLayout:AddChild(self.emptyText)

    self.pagination = UI.CreateLayout(UI.HorizontalLayoutGroup, self.root:GetFrame(), "RPETradingMarketsPagination", {
        height = PAGE_NAV_HEIGHT,
        expandWidth = true,
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.root:AddChild(self.pagination)

    self.previousPageButton = UI.CreateButton(self.pagination:GetFrame(), "RPETradingMarketsPreviousPage", "<", PAGE_BUTTON_WIDTH, function()
        self:PreviousPage()
    end, { height = PAGE_NAV_HEIGHT, fontSize = 8 })
    self.pagination:AddChild(self.previousPageButton)

    self.pageText = UI.CreateText(self.pagination:GetFrame(), "RPETradingMarketsPageText", "Page 1 / 1", {
        width = PAGE_TEXT_WIDTH,
        height = PAGE_NAV_HEIGHT,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.pagination:AddChild(self.pageText)

    self.nextPageButton = UI.CreateButton(self.pagination:GetFrame(), "RPETradingMarketsNextPage", ">", PAGE_BUTTON_WIDTH, function()
        self:NextPage()
    end, { height = PAGE_NAV_HEIGHT, fontSize = 8 })
    self.pagination:AddChild(self.nextPageButton)

    self.built = true
    return self.root
end

return MarketsPage
