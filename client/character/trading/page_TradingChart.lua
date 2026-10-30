local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Trading = Addon.Client.UI.Trading or {}

local TradingUI = Addon.Client.UI.Trading
local UI = Addon.UI or {}
local MarketRates = Addon.Client and Addon.Client.MarketRates or {}

local ChartPage = TradingUI.Chart or {}
TradingUI.Chart = ChartPage
ChartPage.__index = ChartPage

local PLOT_LEFT = 42
local PLOT_RIGHT = 10
local PLOT_TOP = 18
local PLOT_BOTTOM = 30
local TICK_COUNT = 5
local DATE_LABEL_COUNT = 3
local LINE_HEIGHT = 2

local function isFinite(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function formatPercent(value)
    local numeric = tonumber(value) or 0
    return (numeric >= 0 and "+" or "-") .. ("%.2f%%"):format(math.abs(numeric))
end

local function formatTariff(market)
    local tariff = tonumber(market and market.tariffPercent)
    if tariff == nil then
        tariff = 5
    end
    return ("Tariff: %.2f%%"):format(tariff)
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

local function getFontFile()
    return (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF"
end

local function getFontSize()
    return (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Small) or 9
end

local function createInstance()
    return setmetatable({
        owner = nil,
        root = nil,
        heading = nil,
        meta = nil,
        status = nil,
        plotPanel = nil,
        plotFrame = nil,
        lines = {},
        points = {},
        yLabels = {},
        xLabels = {},
        baseline = nil,
        rows = nil,
        selectedPointIndex = nil,
        built = false,
    }, ChartPage)
end

function ChartPage:New()
    return createInstance()
end

function ChartPage:CreateLabel(parent, justifyH)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(getFontFile(), getFontSize(), nil)
    label:SetTextColor(
        UI.ResolveColor(nil, "text.muted").r,
        UI.ResolveColor(nil, "text.muted").g,
        UI.ResolveColor(nil, "text.muted").b,
        1
    )
    label:SetJustifyH(justifyH or "LEFT")
    label:SetJustifyV("MIDDLE")
    return label
end

function ChartPage:EnsurePrimitives()
    if not self.plotFrame then
        return
    end

    if not self.baseline then
        self.baseline = self.plotFrame:CreateTexture(nil, "ARTWORK")
        self.baseline:SetColorTexture(
            UI.ResolveColor(nil, "text.muted").r,
            UI.ResolveColor(nil, "text.muted").g,
            UI.ResolveColor(nil, "text.muted").b,
            0.35
        )
    end

    for index = #self.lines + 1, 13 do
        local line = self.plotFrame:CreateTexture(nil, "ARTWORK")
        local color = UI.ResolveColor(nil, "accent")
        line:SetColorTexture(color.r, color.g, color.b, 0.95)
        self.lines[index] = line
    end

    for index = #self.points + 1, 14 do
        local pointIndex = index
        local point = CreateFrame("Button", nil, self.plotFrame)
        point:SetSize(8, 8)
        point.texture = point:CreateTexture(nil, "OVERLAY")
        point.texture:SetAllPoints(point)
        point:SetScript("OnEnter", function()
            self.selectedPointIndex = pointIndex
            self:UpdatePointColors()
            self:ShowPointTooltip(pointIndex)
        end)
        point:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)
        point:SetScript("OnClick", function()
            self.selectedPointIndex = pointIndex
            self:UpdatePointColors()
            self:ShowPointTooltip(pointIndex)
        end)
        self.points[index] = point
    end

    for index = #self.yLabels + 1, TICK_COUNT do
        self.yLabels[index] = self:CreateLabel(self.plotFrame, "RIGHT")
    end

    for index = #self.xLabels + 1, DATE_LABEL_COUNT do
        self.xLabels[index] = self:CreateLabel(self.plotFrame, "CENTER")
    end
end

function ChartPage:HidePlot()
    for index = 1, #self.lines do
        self.lines[index]:Hide()
    end
    for index = 1, #self.points do
        self.points[index]:Hide()
    end
    if self.baseline then
        self.baseline:Hide()
    end
    for index = 1, #self.yLabels do
        self.yLabels[index]:SetText("")
    end
    for index = 1, #self.xLabels do
        self.xLabels[index]:SetText("")
    end
end

function ChartPage:ShowPointTooltip(index)
    local row = self.rows and self.rows[index] or nil
    if not row or not GameTooltip then
        return
    end
    GameTooltip:SetOwner(self.points[index], "ANCHOR_TOP")
    GameTooltip:SetText(row.dayKey or "Unknown day")
    GameTooltip:AddLine(("Coefficient: %s"):format(formatPercent(row.coefficientPercent)), 1, 1, 1)
    GameTooltip:Show()
end

function ChartPage:UpdatePointColors()
    local normal = UI.ResolveColor(nil, "accent")
    local selected = UI.ResolveColor(nil, "warning")
    for index = 1, #self.points do
        local point = self.points[index]
        if point and point.texture then
            local color = index == self.selectedPointIndex and selected or normal
            point.texture:SetColorTexture(color.r, color.g, color.b, 1)
        end
    end
end

function ChartPage:Render()
    if not self.plotFrame or type(self.rows) ~= "table" or #self.rows ~= 14 then
        return false
    end

    local frameWidth = tonumber(self.plotFrame:GetWidth()) or 0
    local frameHeight = tonumber(self.plotFrame:GetHeight()) or 0
    local plotWidth = frameWidth - PLOT_LEFT - PLOT_RIGHT
    local plotHeight = frameHeight - PLOT_TOP - PLOT_BOTTOM
    if plotWidth <= 20 or plotHeight <= 20 then
        return false
    end

    local minimum, maximum = math.huge, -math.huge
    for index = 1, #self.rows do
        local value = tonumber(self.rows[index].coefficientPercent)
        if not isFinite(value) then
            self:HidePlot()
            return false
        end
        minimum = math.min(minimum, value)
        maximum = math.max(maximum, value)
    end

    local span = maximum - minimum
    local padding = span > 0 and math.max(0.5, span * 0.12) or math.max(1, math.abs(maximum) * 0.12)
    if padding <= 0 or not isFinite(padding) then
        padding = 1
    end
    minimum = minimum - padding
    maximum = maximum + padding
    span = maximum - minimum
    if span <= 0 or not isFinite(span) then
        return false
    end

    local function pointFor(index, value)
        local x = PLOT_LEFT + ((index - 1) / 13) * plotWidth
        local y = PLOT_BOTTOM + ((value - minimum) / span) * plotHeight
        return x, y
    end

    local baselineValue = math.max(minimum, math.min(maximum, 0))
    local baselineY = PLOT_BOTTOM + ((baselineValue - minimum) / span) * plotHeight
    self.baseline:ClearAllPoints()
    self.baseline:SetPoint("BOTTOMLEFT", self.plotFrame, "BOTTOMLEFT", PLOT_LEFT, baselineY)
    self.baseline:SetPoint("BOTTOMRIGHT", self.plotFrame, "BOTTOMRIGHT", -PLOT_RIGHT, baselineY)
    self.baseline:SetHeight(1)
    self.baseline:Show()

    for tick = 1, TICK_COUNT do
        local fraction = (tick - 1) / (TICK_COUNT - 1)
        local value = minimum + (span * (1 - fraction))
        local y = PLOT_BOTTOM + (plotHeight * fraction)
        local label = self.yLabels[tick]
        label:ClearAllPoints()
        label:SetPoint("RIGHT", self.plotFrame, "BOTTOMLEFT", PLOT_LEFT - 5, y)
        label:SetSize(PLOT_LEFT - 8, 14)
        label:SetText(formatPercent(value))
    end

    local dateIndexes = { 1, 7, 14 }
    for index = 1, #dateIndexes do
        local rowIndex = dateIndexes[index]
        local x = PLOT_LEFT + ((rowIndex - 1) / 13) * plotWidth
        local label = self.xLabels[index]
        label:ClearAllPoints()
        label:SetPoint("TOP", self.plotFrame, "BOTTOMLEFT", x, -(PLOT_BOTTOM - 2))
        label:SetSize(70, 16)
        label:SetText(trim(self.rows[rowIndex].dayKey))
    end

    local previousX, previousY
    for index = 1, 14 do
        local value = tonumber(self.rows[index].coefficientPercent)
        local x, y = pointFor(index, value)
        local point = self.points[index]
        point:ClearAllPoints()
        point:SetPoint("CENTER", self.plotFrame, "BOTTOMLEFT", x, y)
        point:Show()
        if previousX then
            local line = self.lines[index - 1]
            local dx, dy = x - previousX, y - previousY
            local length = math.sqrt((dx * dx) + (dy * dy))
            line:ClearAllPoints()
            line:SetPoint("CENTER", self.plotFrame, "BOTTOMLEFT", (x + previousX) * 0.5, (y + previousY) * 0.5)
            line:SetSize(math.max(1, length), LINE_HEIGHT)
            if line.SetRotation then
                line:SetRotation(atan2(dy, dx))
            end
            line:Show()
        end
        previousX, previousY = x, y
    end
    for index = 14, #self.lines do
        self.lines[index]:Hide()
    end
    self:UpdatePointColors()
    return true
end

function ChartPage:Refresh(market, marketRef)
    if not market then
        self.heading:SetText("Market Chart")
        self.meta:SetText("")
        self.status:SetText("Select a Market to view its coefficient history.")
        self.rows = nil
        self:HidePlot()
        return false
    end

    local index = trim(market.index)
    local name = trim(market.name)
    self.heading:SetText(("%s %s %s"):format(index ~= "" and index or "--", "\226\128\148", name ~= "" and name or marketRef or "Unknown Market"))

    local marketType = string.lower(trim(market.marketType))
    local tariffText = marketType == "tracker" and ("Tracker Market %s no tariff"):format("\226\128\148") or formatTariff(market)
    local trackerText = trim(market.trackerMarketRef)
    if trackerText ~= "" then
        trackerText = ("Linked tracker: %s (%.2f%% influence)"):format(
            trackerText,
            tonumber(market.trackerInfluencePercent) or 0
        )
    else
        trackerText = "No linked tracker"
    end
    self.meta:SetText(("Today: loading%s   |   %s   |   %s"):format("\226\128\166", tariffText, trackerText))

    if type(MarketRates.GetHistory) ~= "function" then
        self.rows = nil
        self:HidePlot()
        self.status:SetText("Market rate history is unavailable.")
        return false
    end

    local ok, rows, historyError = pcall(MarketRates.GetHistory, marketRef)
    if not ok or type(rows) ~= "table" or #rows ~= 14 then
        self.rows = nil
        self:HidePlot()
        local message = type(historyError) == "table" and historyError.message or nil
        self.status:SetText(message or "Fourteen-day Market history is unavailable.")
        return false
    end

    for rowIndex = 1, #rows do
        if type(rows[rowIndex]) ~= "table"
            or type(rows[rowIndex].dayKey) ~= "string"
            or not isFinite(tonumber(rows[rowIndex].coefficientPercent))
            or (rowIndex > 1
                and type(rows[rowIndex - 1]) == "table"
                and type(rows[rowIndex - 1].dayKey) == "string"
                and rows[rowIndex - 1].dayKey >= rows[rowIndex].dayKey)
        then
            self.rows = nil
            self:HidePlot()
            self.status:SetText("Market rate history contains invalid data.")
            return false
        end
    end

    self.rows = rows
    self.selectedPointIndex = 14
    self.meta:SetText(("Today: %s   |   %s   |   %s"):format(
        formatPercent(rows[14].coefficientPercent),
        tariffText,
        trackerText
    ))
    self.status:SetText("Fourteen daily coefficients; oldest on the left.")
    self:Render()
    return true
end

function ChartPage:Build(parent, owner)
    if self.built then
        return self.root
    end
    self.owner = owner
    self.root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPETradingChartRoot", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.root, parent, 0, 0, 0, 0)

    self.heading = UI.CreateText(self.root:GetFrame(), "RPETradingChartHeading", "Market Chart", {
        height = 18,
        expandWidth = true,
        justifyH = "LEFT",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Heading2) or 10,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.root:AddChild(self.heading)

    self.meta = UI.CreateText(self.root:GetFrame(), "RPETradingChartMeta", "", {
        height = 28,
        expandWidth = true,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.root:AddChild(self.meta)

    self.plotPanel = UI.CreatePanel(self.root:GetFrame(), "RPETradingChartPlotPanel", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
    })
    self.root:AddChild(self.plotPanel)

    self.plotFrame = CreateFrame("Frame", "RPETradingChartPlot", self.plotPanel:GetContentFrame())
    self.plotFrame:SetPoint("TOPLEFT", self.plotPanel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.plotFrame:SetPoint("BOTTOMRIGHT", self.plotPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)
    if self.plotFrame.SetClipsChildren then
        self.plotFrame:SetClipsChildren(true)
    end
    self.plotFrame:HookScript("OnSizeChanged", function()
        self:Render()
    end)
    self:EnsurePrimitives()

    self.status = UI.CreateText(self.root:GetFrame(), "RPETradingChartStatus", "", {
        height = 18,
        expandWidth = true,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.muted"),
    })
    self.root:AddChild(self.status)

    self.built = true
    return self.root
end

return ChartPage
