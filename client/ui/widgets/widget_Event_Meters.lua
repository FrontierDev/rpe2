local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local EventWidget = ClientUI.EventWidget
local EventClass = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local EventUnitClass = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.EventUnit
    or nil

if type(EventWidget) ~= "table"
    or EventWidget._metersExtensionInstalled == true
    or type(EventWidget.ShowCombatLogHistoryPanel) ~= "function"
then
    return true
end

local METER_BUTTON_WIDTH = 90
local METER_BUTTON_HEIGHT = 20
local METER_PANEL_WIDTH = 420
local METER_PANEL_HEIGHT = 320
local METER_PANEL_GAP = 8
local METER_PANEL_INSET = 8
local METER_TITLE_HEIGHT = 18
local METER_TAB_HEIGHT = 20
local METER_SELECTOR_LABEL_HEIGHT = 16
local METER_SELECTOR_HEIGHT = 20
local METER_ROW_HEIGHT = 27
local METER_ROW_SPACING = 1
local METER_TYPES = { "damage", "healing", "threat" }
local METER_LABELS = {
    damage = "Damage",
    healing = "Healing",
    threat = "Threat",
}

local function getFrame(element)
    if type(element) == "table" and type(element.GetFrame) == "function" then
        return element:GetFrame()
    end
    return element
end

local function isFrameShown(element)
    local frame = getFrame(element)
    return frame and type(frame.IsShown) == "function" and frame:IsShown() == true
end

local function setShown(element, shown)
    local frame = getFrame(element)
    if not frame then
        return false
    end
    if shown and type(frame.Show) == "function" then
        frame:Show()
    elseif not shown and type(frame.Hide) == "function" then
        frame:Hide()
    end
    return true
end

local function getActiveEventState()
    if type(Client.GetEventState) == "function" then
        return Client:GetEventState()
    end
    return Client.EventState
end

local function normalizeEventId(value)
    local eventId = tostring(value or "")
    return eventId ~= "" and eventId or nil
end

local function normalizeMeterType(value)
    local meterType = string.lower(tostring(value or ""))
    if meterType == "heal" then
        meterType = "healing"
    end
    return METER_LABELS[meterType] and meterType or "damage"
end

local function formatAmount(value)
    local number = math.floor(tonumber(value) or 0)
    local sign = number < 0 and "-" or ""
    local text = tostring(math.abs(number))
    while true do
        local replaced, count = string.gsub(text, "^(%d+)(%d%d%d)", "%1,%2")
        text = replaced
        if count == 0 then
            break
        end
    end
    return sign .. text
end

local function findEventUnit(eventState, eventId)
    local normalized = tostring(eventId or "")
    if normalized == "" then
        return nil
    end

    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if tostring(unit and unit.eventID or "") == normalized then
            return unit
        end
    end

    return nil
end

local function isUnitActive(unit)
    if type(EventClass) == "table" and type(EventClass.IsUnitActive) == "function" then
        return EventClass.IsUnitActive(unit) == true
    end
    return type(unit) == "table" and (unit.isPlayer == true or unit.active ~= false)
end

local function isUnitBoss(unit)
    if type(EventUnitClass) == "table" and type(EventUnitClass.IsBoss) == "function" then
        return EventUnitClass.IsBoss(unit) == true
    end
    return type(unit) == "table" and unit.boss == true
end

local function getTeamColor(eventState, team)
    if type(EventClass) == "table" and type(EventClass.GetTeamColor) == "function" then
        return EventClass.GetTeamColor(eventState, tonumber(team) or 0)
    end
    return nil
end

local function buildMeterButton(parentFrame, name, text, onClick)
    local tabBackgroundColor = UI.ResolveColor(nil, "tab.bar")
    local tabBorderColor = UI.ResolveColor(nil, "panel.border")
    local button = UI.TextButton:New({
        name = name,
        width = METER_BUTTON_WIDTH,
        height = METER_BUTTON_HEIGHT,
        text = text,
        fontSize = 9,
        fontFlags = "OUTLINE",
        labelColor = UI.ResolveColor(nil, "tab.inactive"),
        hoverLabelColor = UI.ResolveColor(nil, "text.primary"),
        pressedLabelColor = UI.ResolveColor(nil, "text.primary"),
        backgroundColor = tabBackgroundColor,
        hoverColor = UI.ResolveColor(nil, "panel.background"),
        pressedColor = UI.ResolveColor(nil, "window.headerBackground"),
        borderTopColor = tabBorderColor,
        borderBottomColor = tabBorderColor,
        borderSize = 1,
    })
    button:SetParent(parentFrame)
    button:Create()
    button:SetScript("OnClick", onClick)

    local frame = button:GetFrame()
    if frame and frame.CreateTexture then
        button.leftBorder = frame:CreateTexture(nil, "ARTWORK")
        button.leftBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        button.leftBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        button.leftBorder:SetWidth(1)
        button.leftBorder:SetColorTexture(tabBorderColor.r, tabBorderColor.g, tabBorderColor.b, tabBorderColor.a)

        button.rightBorder = frame:CreateTexture(nil, "ARTWORK")
        button.rightBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        button.rightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        button.rightBorder:SetWidth(1)
        button.rightBorder:SetColorTexture(tabBorderColor.r, tabBorderColor.g, tabBorderColor.b, tabBorderColor.a)
    end

    return button
end

local function hasPositiveThreat(threatTable)
    for _, value in pairs(type(threatTable) == "table" and threatTable or {}) do
        if (tonumber(value) or 0) > 0 then
            return true
        end
    end
    return false
end

local function buildThreatTargets(eventState)
    local targets = {}
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if type(unit) == "table" and unit.isPlayer ~= true and isUnitActive(unit) then
            targets[#targets + 1] = {
                eventId = tonumber(unit.eventID) or 0,
                name = tostring(unit.name or "Unknown"),
                boss = isUnitBoss(unit),
                hasThreat = hasPositiveThreat(unit.threatTable),
                order = index,
            }
        end
    end

    table.sort(targets, function(left, right)
        if left.boss ~= right.boss then
            return left.boss
        end
        if left.hasThreat ~= right.hasThreat then
            return left.hasThreat
        end
        if left.order ~= right.order then
            return left.order < right.order
        end
        return left.eventId < right.eventId
    end)
    return targets
end

local function buildThreatRows(eventState, selectedEventId)
    local target = findEventUnit(eventState, selectedEventId)
    local rows = {}
    if type(target) ~= "table" then
        return rows, 0
    end

    for sourceEventId, value in pairs(type(target.threatTable) == "table" and target.threatTable or {}) do
        local amount = tonumber(value) or 0
        local sourceUnit = findEventUnit(eventState, sourceEventId)
        if amount > 0 and type(sourceUnit) == "table" then
            rows[#rows + 1] = {
                eventId = tonumber(sourceUnit.eventID) or tonumber(sourceEventId) or 0,
                name = tostring(sourceUnit.name or "Unknown"),
                team = tonumber(sourceUnit.team) or 0,
                amount = amount,
            }
        end
    end

    table.sort(rows, function(left, right)
        if left.amount ~= right.amount then
            return left.amount > right.amount
        end
        return left.eventId < right.eventId
    end)
    return rows, rows[1] and rows[1].amount or 0
end

local function ensureMeterRowTextures(row)
    local frame = row and row.GetFrame and row:GetFrame() or nil
    if not frame or not frame.CreateTexture then
        return nil, nil, frame
    end

    if not row.meterBarBackground then
        row.meterBarBackground = frame:CreateTexture(nil, "BACKGROUND")
        row.meterBarBackground:SetAllPoints(frame)
        local color = UI.ResolveColor(nil, "panel.background")
        row.meterBarBackground:SetColorTexture(color.r or 0.06, color.g or 0.07, color.b or 0.1, 0.45)
    end
    if not row.meterBarFill then
        row.meterBarFill = frame:CreateTexture(nil, "ARTWORK")
        row.meterBarFill:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -3)
        row.meterBarFill:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 3)
    end
    return row.meterBarFill, row.meterBarBackground, frame
end

local function renderMeterRow(row, item, _, _, scroll)
    local fill, _, frame = ensureMeterRowTextures(row)
    local amount = tonumber(item and item.amount) or 0
    local largest = tonumber(scroll and scroll.meterLargestAmount) or 0
    local ratio = largest > 0 and math.max(0, math.min(1, amount / largest)) or 0
    local width = frame and frame.GetWidth and frame:GetWidth() or 0
    if width <= 0 then
        width = METER_PANEL_WIDTH - (METER_PANEL_INSET * 2)
    end
    if fill then
        fill:SetWidth(math.max(1, math.floor(width * ratio)))
        local color = item and item.color or UI.ResolveColor(nil, "accent")
        fill:SetColorTexture(color.r or 0.3, color.g or 0.6, color.b or 1, 0.28)
    end

    local percentage = tonumber(item and item.percentage) or 0
    row:SetText(("%d. %s   %s   %.1f%%"):format(
        tonumber(item and item.rank) or 0,
        tostring(item and item.name or "Unknown"),
        formatAmount(amount),
        percentage
    ))
    row:SetJustifyH("LEFT")
    row:SetJustifyV("MIDDLE")
    row:SetWordWrap(false)
    local color = item and item.color
    if type(color) == "table" then
        row:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    else
        local textColor = UI.ResolveColor(nil, "text.primary")
        row:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
    end
end

local function buildMeterRows(eventState, eventId, meterType)
    local rows = {}
    local largest = 0
    if meterType == "threat" then
        rows, largest = buildThreatRows(eventState, eventId)
    else
        local eventMeters = Client.EventMeters
        local sourceRows = type(eventMeters) == "table" and type(eventMeters.GetRows) == "function"
            and eventMeters:GetRows(eventId, meterType)
            or {}
        local total = 0
        for index = 1, #sourceRows do
            total = total + math.max(0, tonumber(sourceRows[index].amount) or 0)
            largest = math.max(largest, tonumber(sourceRows[index].amount) or 0)
        end
        for index = 1, #sourceRows do
            local source = sourceRows[index]
            local color = getTeamColor(eventState, source.team)
            rows[#rows + 1] = {
                rank = index,
                eventId = source.eventId,
                name = source.name,
                amount = source.amount,
                percentage = total > 0 and (source.amount / total) * 100 or 0,
                color = color,
            }
        end
    end

    if meterType == "threat" then
        for index = 1, #rows do
            local source = rows[index]
            source.rank = index
            source.percentage = largest > 0 and (source.amount / largest) * 100 or 0
            source.color = getTeamColor(eventState, source.team)
        end
    end
    return rows, largest
end

function EventWidget:IsMetersPanelShown()
    return isFrameShown(self.metersPanel)
end

function EventWidget:HideMetersPanel()
    setShown(self.metersPanel, false)
    return true
end

function EventWidget:HideMeters()
    return self:HideMetersPanel()
end

function EventWidget:SetMetersViewType(meterType)
    self.metersViewType = normalizeMeterType(meterType)
    self:RefreshMetersPanel()
    return self.metersViewType
end

function EventWidget:RefreshMetersThreatTargets(eventState)
    if not self.metersThreatDropdown then
        return
    end

    local targets = buildThreatTargets(eventState)
    local items = {}
    for index = 1, #targets do
        local target = targets[index]
        items[#items + 1] = {
            label = target.name .. (target.boss and " (Boss)" or ""),
            value = tostring(target.eventId),
        }
    end

    local selected = tostring(self.metersThreatEventId or "")
    local selectedTarget = nil
    for index = 1, #targets do
        if tostring(targets[index].eventId) == selected then
            selectedTarget = targets[index]
            break
        end
    end
    if not selectedTarget then
        selectedTarget = targets[1]
        selected = selectedTarget and tostring(selectedTarget.eventId) or ""
    end
    self.metersThreatEventId = selected ~= "" and selected or nil

    self._refreshingMetersThreatTargets = true
    self.metersThreatDropdown:SetItems(items)
    if selected ~= "" then
        self.metersThreatDropdown:SetSelectedValue(selected, true)
    end
    self._refreshingMetersThreatTargets = false
end

function EventWidget:RefreshMetersPanel()
    if not self.metersPanel or not self.metersScroll then
        return false
    end

    local state = getActiveEventState()
    if type(state) ~= "table" or state.active ~= true or state.ending == true then
        self:HideMetersPanel()
        return false
    end

    local eventId = normalizeEventId(state.id)
    if self.metersEventId ~= eventId then
        self.metersEventId = eventId
        self.metersViewType = "damage"
        self.metersThreatEventId = nil
    end
    self.metersViewType = normalizeMeterType(self.metersViewType)

    local meterType = self.metersViewType
    self.metersTitle:SetText((METER_LABELS[meterType] or "Damage") .. " Meter")
    setShown(self.metersThreatLabel, meterType == "threat")
    setShown(self.metersThreatDropdown, meterType == "threat")
    if meterType == "threat" then
        self:RefreshMetersThreatTargets(state)
    end

    local scrollFrame = getFrame(self.metersScroll)
    if scrollFrame then
        scrollFrame:ClearAllPoints()
        if meterType == "threat" then
            scrollFrame:SetPoint("TOPLEFT", getFrame(self.metersThreatDropdown), "BOTTOMLEFT", 0, -4)
        else
            scrollFrame:SetPoint("TOPLEFT", getFrame(self.metersTabs), "BOTTOMLEFT", 0, -4)
        end
        scrollFrame:SetPoint("BOTTOMRIGHT", self.metersPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)
    end

    local rows, largest = buildMeterRows(state, eventId, meterType)
    self.metersScroll.meterLargestAmount = largest
    self.metersScroll:SetItems(rows)
    setShown(self.metersEmptyText, #rows == 0)
    if #rows == 0 then
        self.metersEmptyText:SetText(meterType == "threat" and "No threat recorded for this target." or ("No " .. METER_LABELS[meterType]:lower() .. " recorded yet."))
    end
    return true
end

function EventWidget:RefreshMeters(...)
    return self:RefreshMetersPanel(...)
end

function EventWidget:ShowMetersPanel()
    self:EnsureMetersUI()
    if type(self.HideCombatLogHistoryPanel) == "function" then
        self:HideCombatLogHistoryPanel()
    end
    if self:RefreshMetersPanel() ~= true then
        return false
    end
    setShown(self.metersPanel, true)
    return true
end

function EventWidget:ToggleMetersPanel()
    if self:IsMetersPanelShown() then
        return self:HideMetersPanel()
    end
    return self:ShowMetersPanel()
end

function EventWidget:EnsureMetersUI()
    if self.metersPanel then
        return self.metersPanel
    end
    if type(self.EnsureCombatLogHistoryUI) ~= "function" or not self.rootPanel or not self.headerBannerPanel then
        return nil
    end

    self:EnsureCombatLogHistoryUI()
    local rootFrame = getFrame(self.rootPanel)
    local headerBannerFrame = getFrame(self.headerBannerPanel)
    local buttonRowFrame = getFrame(self.combatLogHistoryButtonRow)
    if not rootFrame or not headerBannerFrame or not buttonRowFrame then
        return nil
    end

    self.metersButton = buildMeterButton(
        buttonRowFrame,
        "RPEClientEventWidgetMetersButton",
        "Meters",
        function()
            self:ToggleMetersPanel()
        end
    )
    self.combatLogHistoryButtonRow:AddChild(self.metersButton)

    self.metersPanel = UI.CreatePanel(rootFrame, "RPEClientEventWidgetMetersPanel", {
        width = METER_PANEL_WIDTH,
        height = METER_PANEL_HEIGHT,
        contentInset = METER_PANEL_INSET,
        showBorder = true,
        panelBorderSize = 1,
        panelBorderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
    })
    local panelFrame = getFrame(self.metersPanel)
    panelFrame:SetPoint("TOPLEFT", rootFrame, "TOPRIGHT", METER_PANEL_GAP, 0)
    panelFrame:Hide()

    local contentFrame = self.metersPanel:GetContentFrame()
    self.metersTitle = UI.CreateText(contentFrame, "RPEClientEventWidgetMetersTitle", "Damage Meter", {
        height = METER_TITLE_HEIGHT,
        fontSize = 11,
        fontFlags = "OUTLINE",
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    local titleFrame = getFrame(self.metersTitle)
    titleFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 2, 0)
    titleFrame:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", -2, 0)

    self.metersTabs = UI.CreateLayout(UI.HorizontalLayoutGroup, contentFrame, "RPEClientEventWidgetMetersTabs", {
        spacing = 4,
        width = METER_PANEL_WIDTH - (METER_PANEL_INSET * 2),
        height = METER_TAB_HEIGHT,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    local tabsFrame = getFrame(self.metersTabs)
    tabsFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, -4)
    for index = 1, #METER_TYPES do
        local meterType = METER_TYPES[index]
        local tab = buildMeterButton(tabsFrame, "RPEClientEventWidgetMetersTab" .. meterType, METER_LABELS[meterType], function()
            self:SetMetersViewType(meterType)
        end)
        tab.options.width = 72
        tab:GetFrame():SetWidth(72)
        self.metersTabs:AddChild(tab)
    end

    self.metersThreatLabel = UI.CreateText(contentFrame, "RPEClientEventWidgetMetersThreatLabel", "Target", {
        height = METER_SELECTOR_LABEL_HEIGHT,
        fontSize = 9,
        fontFlags = "OUTLINE",
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    local threatLabelFrame = getFrame(self.metersThreatLabel)
    threatLabelFrame:SetPoint("TOPLEFT", tabsFrame, "BOTTOMLEFT", 0, -4)
    threatLabelFrame:SetPoint("TOPRIGHT", tabsFrame, "BOTTOMRIGHT", 0, -4)

    self.metersThreatDropdown = UI.CreateDropdown(contentFrame, "RPEClientEventWidgetMetersThreatDropdown", {
        width = METER_PANEL_WIDTH - (METER_PANEL_INSET * 2),
        height = METER_SELECTOR_HEIGHT,
        popupWidth = METER_PANEL_WIDTH - (METER_PANEL_INSET * 2),
        items = {},
        onValueChanged = function(value)
            if self._refreshingMetersThreatTargets then
                return
            end
            self.metersThreatEventId = tostring(value or "")
            self:RefreshMetersPanel()
        end,
    })
    local threatDropdownFrame = getFrame(self.metersThreatDropdown)
    threatDropdownFrame:SetPoint("TOPLEFT", threatLabelFrame, "BOTTOMLEFT", 0, -1)

    self.metersScroll = UI.ScrollLayout:New({
        name = "RPEClientEventWidgetMetersScroll",
        width = METER_PANEL_WIDTH - (METER_PANEL_INSET * 2),
        height = METER_PANEL_HEIGHT - METER_TITLE_HEIGHT - METER_TAB_HEIGHT - 16,
        visibleRows = 8,
        rowHeight = METER_ROW_HEIGHT,
        rowSpacing = METER_ROW_SPACING,
        border = false,
        rowElementClass = UI.Text,
        rowFontSize = 10,
        rowFontFlags = "OUTLINE",
        rowWordWrap = false,
        rowInsetLeft = 2,
        rowInsetRight = 2,
    })
    self.metersScroll:SetParent(contentFrame)
    self.metersScroll:SetRowRenderer(renderMeterRow)
    self.metersScroll:Create()
    local scrollFrame = getFrame(self.metersScroll)
    scrollFrame:SetPoint("TOPLEFT", tabsFrame, "BOTTOMLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 0)

    self.metersEmptyText = UI.CreateText(contentFrame, "RPEClientEventWidgetMetersEmpty", "", {
        fontSize = 10,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.muted"),
    })
    local emptyFrame = getFrame(self.metersEmptyText)
    emptyFrame:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    emptyFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)

    self.metersViewType = self.metersViewType or "damage"
    self:RefreshMetersPanel()
    return self.metersPanel
end

local originalBuild = EventWidget.Build
local originalHide = EventWidget.Hide
local originalRefresh = EventWidget.Refresh
local originalShowCombatLogHistoryPanel = EventWidget.ShowCombatLogHistoryPanel

function EventWidget:Build(...)
    local result = originalBuild(self, ...)
    self:EnsureMetersUI()
    return result
end

function EventWidget:Hide(...)
    self:HideMetersPanel()
    return originalHide(self, ...)
end

function EventWidget:Refresh(...)
    local result = originalRefresh(self, ...)
    local state = getActiveEventState()
    if type(state) == "table" and state.active == true and state.ending ~= true then
        self:EnsureMetersUI()
        if self:IsMetersPanelShown() then
            self:RefreshMetersPanel()
        end
    else
        self:HideMetersPanel()
    end
    return result
end

function EventWidget:ShowCombatLogHistoryPanel(...)
    self:HideMetersPanel()
    return originalShowCombatLogHistoryPanel(self, ...)
end

EventWidget._metersExtensionInstalled = true
return true
