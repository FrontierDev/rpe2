local _, Addon = ...

local Client = Addon.Client or {}
local ClientUI = Addon.Client and Addon.Client.UI or {}
local UI = Addon.UI or {}
local EventClass = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local Inline = UI.Inline
local EventWidget = ClientUI.EventWidget

if type(EventWidget) ~= "table"
    or type(EventWidget.EnsureCombatLogHistoryUI) ~= "function"
    or type(EventWidget.ShowEventUtilityWindow) ~= "function"
then
    return
end

local ALL_UNITS_BUTTON_WIDTH = 78
local ALL_UNITS_BUTTON_HEIGHT = 20
local ALL_UNITS_PANEL_WIDTH = 500
local ALL_UNITS_PANEL_HEIGHT = 340
local ALL_UNITS_PANEL_INSET = 8
local ALL_UNITS_ROW_HEIGHT = 28
local ALL_UNITS_ROW_SPACING = 2
local ALL_UNITS_HEALTH_WIDTH = 185
local ALL_UNITS_HEADING_HEIGHT = 22

local function getFrame(element)
    return element and type(element.GetFrame) == "function" and element:GetFrame() or nil
end

local function setShown(element, shown)
    local frame = getFrame(element)
    if not frame then
        return
    end

    if shown == true then
        frame:Show()
    else
        frame:Hide()
    end
end

local function isShown(element)
    local frame = getFrame(element)
    return frame and type(frame.IsShown) == "function" and frame:IsShown() or false
end

local function normalizeTeam(team)
    return math.floor(tonumber(team) or 0)
end

local function normalizeEventId(eventId)
    return math.floor(tonumber(eventId) or 0)
end

local function normalizeMarker(marker)
    local value = math.floor(tonumber(marker) or 0)
    return value >= 1 and value <= 8 and value or 0
end

local function getTeamName(eventState, team)
    if type(EventClass) == "table" and type(EventClass.GetTeamName) == "function" then
        return tostring(EventClass.GetTeamName(eventState, team) or "")
    end

    return team > 0 and ("Team " .. tostring(team)) or "Unassigned Team"
end

local function getTeamColor(eventState, team)
    if type(EventClass) == "table" and type(EventClass.GetTeamColor) == "function" then
        return EventClass.GetTeamColor(eventState, team)
    end
    return nil
end

local function isUnitActive(unit)
    if type(EventWidget.IsEventUnitActive) == "function" then
        return EventWidget:IsEventUnitActive(unit) == true
    end

    return type(unit) == "table" and (unit.isPlayer == true or unit.active ~= false)
end

local function isCurrentTurn(eventState, eventUnit)
    local eventId = normalizeEventId(eventUnit and eventUnit.eventID)
    if eventId <= 0 or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local spellcasting = Client.Spellcasting or Addon.Client and Addon.Client.Spellcasting or nil
    if spellcasting and type(spellcasting.IsCasterTurnOnTick) == "function" then
        return spellcasting.IsCasterTurnOnTick(eventState, eventId) == true
    end

    return false
end

local function wasLocalPlayerAttackLastTurn(eventState, targetEventId)
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local currentTurn = math.floor(tonumber(eventState.turnNumber) or 0)
    if currentTurn <= 1 or type(Client.ResolveLocalEventUnit) ~= "function" then
        return false
    end

    local localUnit = Client:ResolveLocalEventUnit(eventState)
    local localEventId = normalizeEventId(localUnit and localUnit.eventID)
    local numericTargetEventId = normalizeEventId(targetEventId)
    if localEventId <= 0 or numericTargetEventId <= 0 then
        return false
    end

    return type(Client.HasUnitAttackedTargetOnTurn) == "function"
        and Client:HasUnitAttackedTargetOnTurn(
            eventState,
            localEventId,
            numericTargetEventId,
            currentTurn - 1
        ) == true
end

local function sortUnits(left, right)
    local leftMarker = normalizeMarker(left.displayUnit and left.displayUnit.raidMarker)
    local rightMarker = normalizeMarker(right.displayUnit and right.displayUnit.raidMarker)
    if leftMarker ~= rightMarker then
        if leftMarker == 0 then
            return false
        end
        if rightMarker == 0 then
            return true
        end
        return leftMarker < rightMarker
    end

    local leftEventId = normalizeEventId(left.displayUnit and left.displayUnit.eventID)
    local rightEventId = normalizeEventId(right.displayUnit and right.displayUnit.eventID)
    if leftEventId ~= rightEventId then
        return leftEventId < rightEventId
    end

    return left.sourceIndex < right.sourceIndex
end

local function appendTeamOrder(teamOrder, seen, team)
    team = normalizeTeam(team)
    if not seen[team] then
        seen[team] = true
        teamOrder[#teamOrder + 1] = team
    end
end

local function buildTeamOrder(eventState, groups)
    local order = {}
    local seen = {}
    for index = 1, #((eventState and eventState.teams) or {}) do
        appendTeamOrder(order, seen, index)
    end

    local extraTeams = {}
    for team in pairs(groups) do
        team = normalizeTeam(team)
        if not seen[team] then
            extraTeams[#extraTeams + 1] = team
        end
    end
    table.sort(extraTeams)
    for index = 1, #extraTeams do
        appendTeamOrder(order, seen, extraTeams[index])
    end
    return order
end

local function formatExactValue(value)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return "--"
    end

    return tostring(math.ceil(numericValue))
end

local function cloneHealthState(healthState)
    if type(healthState) ~= "table" then
        return nil
    end

    local current = tonumber(healthState.currentValue)
    local maximum = tonumber(healthState.maxValue)
    if current == nil or maximum == nil then
        return nil
    end

    local percentage = maximum > 0 and math.max(0, math.min(100, (current / maximum) * 100)) or 0
    local state = {}
    for key, value in pairs(healthState) do
        state[key] = value
    end
    state.currentText = formatExactValue(current)
    state.progressText = ("%.0f%%"):format(percentage)
    return state
end

local function isReadyEventState(eventState)
    return type(eventState) == "table"
        and eventState.active == true
        and eventState.ending ~= true
        and eventState.unitsReady == true
        and eventState.startupReady == true
end

local function getHealthStateForSignature(widget, eventUnit, eventState, displayUnit, concealed)
    if type(displayUnit) ~= "table" or concealed == true then
        return nil
    end
    if type(widget.ResolveEventUnitHealthState) ~= "function" then
        return nil
    end

    return widget:ResolveEventUnitHealthState(eventUnit, eventState)
end

function EventWidget:BuildAllUnitsPresentationSignature(eventState)
    local state = type(eventState) == "table" and eventState
        or (type(Client.GetEventState) == "function" and Client:GetEventState() or nil)
    if type(state) ~= "table" then
        return ""
    end

    local parts = {
        tostring(state.id or ""),
        tostring(state.turnNumber or 0),
        tostring(state.tickNumber or 0),
        tostring(state.unitsReady == true and 1 or 0),
        tostring(state.startupReady == true and 1 or 0),
    }
    for index = 1, #((state.teams) or {}) do
        local team = state.teams[index]
        parts[#parts + 1] = table.concat({
            "team",
            tostring(index),
            tostring(type(team) == "table" and team.name or ""),
        }, "\30")
    end

    local units = state.units or {}
    parts[#parts + 1] = "units:" .. tostring(#units)
    for index = 1, #units do
        local sourceUnit = units[index]
        local displayUnit = type(self.BuildWidgetDisplayUnit) == "function"
            and self:BuildWidgetDisplayUnit(sourceUnit, state)
            or sourceUnit
        local concealed = sourceUnit ~= displayUnit and displayUnit and displayUnit.hidden == true
        local active = isUnitActive(sourceUnit)
        local healthState = active and getHealthStateForSignature(self, sourceUnit, state, displayUnit, concealed) or nil
        local eventID = normalizeEventId(displayUnit and displayUnit.eventID or sourceUnit and sourceUnit.eventID)
        local attackedLastTurn = active and concealed ~= true
            and wasLocalPlayerAttackLastTurn(state, eventID)
        parts[#parts + 1] = table.concat({
            tostring(eventID),
            tostring(active and (displayUnit and displayUnit.team or sourceUnit and sourceUnit.team or 0) or 0),
            tostring(active and normalizeMarker(displayUnit and displayUnit.raidMarker) or 0),
            tostring(active and 1 or 0),
            tostring(concealed and 1 or 0),
            tostring(active and displayUnit and displayUnit.name or ""),
            tostring(healthState and healthState.resourceRef or ""),
            tostring(healthState and healthState.currentValue or ""),
            tostring(healthState and healthState.maxValue or ""),
            tostring(attackedLastTurn == true and 1 or 0),
        }, "\30")
    end

    return table.concat(parts, "\31")
end

function EventWidget:BuildAllUnitsRows(eventState)
    local state = type(eventState) == "table" and eventState
        or (type(Client.GetEventState) == "function" and Client:GetEventState() or nil)
    if type(state) ~= "table" then
        return {}
    end

    local groups = {}
    local units = state.units or {}
    for sourceIndex = 1, #units do
        local sourceUnit = units[sourceIndex]
        if isUnitActive(sourceUnit) then
            local displayUnit = type(self.BuildWidgetDisplayUnit) == "function"
                and self:BuildWidgetDisplayUnit(sourceUnit, state)
                or sourceUnit
            local team = normalizeTeam(displayUnit and displayUnit.team or sourceUnit and sourceUnit.team)
            groups[team] = groups[team] or {}
            groups[team][#groups[team] + 1] = {
                sourceIndex = sourceIndex,
                sourceUnit = sourceUnit,
                displayUnit = displayUnit,
            }
        end
    end

    local rows = {}
    local teamOrder = buildTeamOrder(state, groups)
    for index = 1, #teamOrder do
        local team = teamOrder[index]
        local group = groups[team]
        if group and #group > 0 then
            table.sort(group, sortUnits)
            rows[#rows + 1] = {
                kind = "team",
                team = team,
                name = getTeamName(state, team),
                color = getTeamColor(state, team),
            }

            for unitIndex = 1, #group do
                local entry = group[unitIndex]
                local displayUnit = entry.displayUnit or {}
                local hidden = entry.sourceUnit ~= displayUnit and displayUnit.hidden == true
                local eventID = normalizeEventId(displayUnit.eventID or entry.sourceUnit and entry.sourceUnit.eventID)
                rows[#rows + 1] = {
                    kind = "unit",
                    team = team,
                    unit = displayUnit,
                    sourceUnit = entry.sourceUnit,
                    eventID = eventID,
                    hidden = hidden,
                    healthState = not hidden and type(self.ResolveEventUnitHealthState) == "function"
                        and cloneHealthState(self:ResolveEventUnitHealthState(entry.sourceUnit, state))
                        or nil,
                    currentTurn = not hidden and isCurrentTurn(state, entry.sourceUnit),
                    attackedLastTurn = not hidden and wasLocalPlayerAttackLastTurn(state, eventID),
                }
            end
        end
    end

    return rows
end

local function buildButton(parentFrame, onClick)
    local borderColor = UI.ResolveColor(nil, "panel.border")
    local button = UI.TextButton:New({
        name = "RPEClientEventWidgetAllUnitsButton",
        width = ALL_UNITS_BUTTON_WIDTH,
        height = ALL_UNITS_BUTTON_HEIGHT,
        text = "All Units",
        fontSize = 9,
        fontFlags = "OUTLINE",
        labelColor = UI.ResolveColor(nil, "tab.inactive"),
        hoverLabelColor = UI.ResolveColor(nil, "text.primary"),
        pressedLabelColor = UI.ResolveColor(nil, "text.primary"),
        backgroundColor = UI.ResolveColor(nil, "tab.bar"),
        hoverColor = UI.ResolveColor(nil, "panel.background"),
        pressedColor = UI.ResolveColor(nil, "window.headerBackground"),
        borderTopColor = borderColor,
        borderBottomColor = borderColor,
        borderSize = 1,
    })
    button:SetParent(parentFrame)
    button:Create()
    button:SetScript("OnClick", onClick)
    return button
end

local function ensureRowElements(row)
    if row.allUnitsElements then
        return row.allUnitsElements
    end

    local rowFrame = row:GetFrame()
    local elements = {}
    elements.label = UI.CreateText(rowFrame, "RPEClientEventWidgetAllUnitsRowLabel", "", {
        fontSize = 10,
        fontFlags = "OUTLINE",
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    elements.health = UI.ResourceBar:New({
        name = "RPEClientEventWidgetAllUnitsRowHealth",
        width = ALL_UNITS_HEALTH_WIDTH,
        height = 16,
        iconSize = 14,
        valueWidth = 62,
        valuePlacement = "bar",
        progressFontSize = 10,
        progressTextToken = "text.primary",
        valueFontSize = 9,
        showWhenUIHidden = false,
    })
    elements.health:SetParent(rowFrame)
    elements.health:Create()

    local labelFrame = getFrame(elements.label)
    local healthFrame = getFrame(elements.health)
    labelFrame:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 6, 0)
    labelFrame:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", 6, 0)
    labelFrame:SetPoint("RIGHT", healthFrame, "LEFT", -8, 0)
    healthFrame:SetPoint("RIGHT", rowFrame, "RIGHT", -6, 0)
    healthFrame:SetPoint("CENTER", rowFrame, "CENTER", 0, 0)

    row.allUnitsElements = elements
    row.Reset = function(self)
        local rowElements = self.allUnitsElements
        setShown(rowElements and rowElements.label, false)
        setShown(rowElements and rowElements.health, false)
    end
    return elements
end

local function renderAllUnitsRow(row, item)
    local elements = ensureRowElements(row)
    local rowFrame = row:GetFrame()
    local labelFrame = getFrame(elements.label)
    local healthFrame = getFrame(elements.health)

    setShown(elements.label, true)
    if item.kind == "team" then
        setShown(elements.health, false)
        elements.label:SetText(item.name)
        elements.label:SetTextColor(
            tonumber(item.color and item.color.r) or 0.9,
            tonumber(item.color and item.color.g) or 0.9,
            tonumber(item.color and item.color.b) or 0.9,
            tonumber(item.color and item.color.a) or 1
        )
        labelFrame:ClearAllPoints()
        labelFrame:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 6, 0)
        labelFrame:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", -6, 0)
        rowFrame:SetHeight(ALL_UNITS_HEADING_HEIGHT)
        return
    end

    setShown(elements.health, item.hidden ~= true and item.healthState ~= nil)
    labelFrame:ClearAllPoints()
    labelFrame:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 6, 0)
    labelFrame:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", 6, 0)
    labelFrame:SetPoint("RIGHT", healthFrame, "LEFT", -8, 0)
    rowFrame:SetHeight(ALL_UNITS_ROW_HEIGHT)

    local unit = item.unit or {}
    local marker = normalizeMarker(unit.raidMarker)
    local markerText = Inline and type(Inline.RaidMarker) == "function"
        and Inline:RaidMarker(marker, 14, 14)
        or ""
    local name = tostring(unit.name or "Unknown Unit")
    local nameText = item.attackedLastTurn == true and "|cffffff00" .. name .. "|r" or name
    local eventIdText = item.eventID > 0 and ("  [#" .. tostring(item.eventID) .. "]") or ""
    elements.label:SetText(markerText .. (markerText ~= "" and " " or "") .. nameText .. eventIdText)
    elements.label:SetTextColor(1, 1, 1, 1)

    if item.hidden ~= true and item.healthState then
        elements.health:SetState(item.healthState)
        local isDead = tonumber(item.healthState.currentValue) ~= nil and tonumber(item.healthState.currentValue) <= 0
        rowFrame:SetAlpha(isDead and 0.55 or 1)
    else
        rowFrame:SetAlpha(0.7)
    end
end

function EventWidget:EnsureAllUnitsUI()
    if self.allUnitsPanel then
        self:RefreshAllUnitsAvailability()
        return self.allUnitsPanel
    end
    if not self.rootPanel or not self.headerBannerPanel then
        return nil
    end

    self:EnsureCombatLogHistoryUI()
    local utilityWindow = self:EnsureEventUtilityWindow()
    local utilityContentFrame = utilityWindow and utilityWindow:GetContentFrame()
    local buttonRowFrame = getFrame(self.combatLogHistoryButtonRow)
    if not utilityContentFrame or not buttonRowFrame then
        return nil
    end

    self.allUnitsButton = buildButton(buttonRowFrame, function()
        self:ToggleAllUnitsPanel()
    end)
    self:RefreshAllUnitsAvailability()
    self.combatLogHistoryButtonRow:AddChild(self.allUnitsButton)

    self.allUnitsPanel = UI.CreatePanel(utilityContentFrame, "RPEClientEventWidgetAllUnitsPanel", {
        width = ALL_UNITS_PANEL_WIDTH,
        height = ALL_UNITS_PANEL_HEIGHT,
        contentInset = ALL_UNITS_PANEL_INSET,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    local panelFrame = getFrame(self.allUnitsPanel)
    panelFrame:ClearAllPoints()
    panelFrame:SetPoint("TOPLEFT", utilityContentFrame, "TOPLEFT", 0, 0)
    panelFrame:SetPoint("BOTTOMRIGHT", utilityContentFrame, "BOTTOMRIGHT", 0, 0)
    panelFrame:Hide()

    self.allUnitsScroll = UI.ScrollLayout:New({
        name = "RPEClientEventWidgetAllUnitsScroll",
        width = ALL_UNITS_PANEL_WIDTH - (ALL_UNITS_PANEL_INSET * 2),
        height = ALL_UNITS_PANEL_HEIGHT - (ALL_UNITS_PANEL_INSET * 2),
        visibleRows = 10,
        rowHeight = ALL_UNITS_ROW_HEIGHT,
        rowSpacing = ALL_UNITS_ROW_SPACING,
        rowElementClass = UI.Panel,
        border = false,
        scrollbar = true,
    })
    self.allUnitsScroll:SetParent(self.allUnitsPanel:GetContentFrame())
    self.allUnitsScroll:Create()
    self.allUnitsScroll:SetRowRenderer(renderAllUnitsRow)
    local scrollFrame = getFrame(self.allUnitsScroll)
    scrollFrame:SetPoint("TOPLEFT", self.allUnitsPanel:GetContentFrame(), "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", self.allUnitsPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.allUnitsEmptyText = UI.CreateText(self.allUnitsPanel:GetContentFrame(), "RPEClientEventWidgetAllUnitsEmpty", "No active event units.", {
        fontSize = 10,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.muted"),
    })
    local emptyFrame = getFrame(self.allUnitsEmptyText)
    emptyFrame:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    emptyFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
    emptyFrame:Hide()

    return self.allUnitsPanel
end

function EventWidget:RefreshAllUnitsAvailability(eventState)
    local state = type(eventState) == "table" and eventState
        or (type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState)
    local ready = isReadyEventState(state)
    if self.allUnitsButton and self.allUnitsButton.SetEnabled then
        self.allUnitsButton:SetEnabled(ready)
    end
    return ready
end

function EventWidget:ClearAllUnitsPanel()
    self.allUnitsPresentationSignature = nil
    if self.allUnitsScroll then
        self.allUnitsScroll:SetItems({})
    end
    setShown(self.allUnitsEmptyText, false)
    setShown(self.allUnitsPanel, false)
    return true
end

function EventWidget:RefreshAllUnitsPanel(eventState, force)
    if not self.allUnitsScroll then
        return false
    end

    local state = type(eventState) == "table" and eventState
        or (type(Client.GetEventState) == "function" and Client:GetEventState() or nil)
    local ready = self:RefreshAllUnitsAvailability(state)
    if not ready then
        if self:IsAllUnitsPanelShown() then
            self:HideEventUtilityWindow()
        end
        self:ClearAllUnitsPanel()
        return false
    end
    if force ~= true and not self:IsAllUnitsPanelShown() then
        return false
    end

    local signature = self:BuildAllUnitsPresentationSignature(state)
    if force ~= true and signature == self.allUnitsPresentationSignature then
        return false
    end

    local rows = self:BuildAllUnitsRows(state)
    self.allUnitsPresentationSignature = signature
    self.allUnitsScroll:SetItems(rows)
    setShown(self.allUnitsEmptyText, #rows == 0)
    return true
end

function EventWidget:IsAllUnitsPanelShown()
    return self.eventUtilityMode == "all-units" and isShown(self.eventUtilityWindow)
end

function EventWidget:ShowAllUnitsPanel()
    self:EnsureAllUnitsUI()
    local state = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
    if self:RefreshAllUnitsPanel(state, true) ~= true then
        return false
    end
    return self:ShowEventUtilityWindow("all-units")
end

function EventWidget:HideAllUnitsPanel()
    if self.eventUtilityMode == "all-units" then
        self:HideEventUtilityWindow()
    end
    self:ClearAllUnitsPanel()
    return true
end

function EventWidget:ToggleAllUnitsPanel()
    if self:IsAllUnitsPanelShown() then
        return self:HideAllUnitsPanel()
    end
    return self:ShowAllUnitsPanel()
end

function EventWidget:RefreshAllUnits(...)
    return self:RefreshAllUnitsPanel(...)
end

local originalBuild = EventWidget.Build
local originalHide = EventWidget.Hide
local originalRefresh = EventWidget.Refresh
local originalRefreshPortraitsForEventIds = EventWidget.RefreshPortraitsForEventIds

function EventWidget:Build(...)
    local result = originalBuild(self, ...)
    self:EnsureAllUnitsUI()
    return result
end

function EventWidget:Hide(...)
    self:HideAllUnitsPanel()
    return originalHide(self, ...)
end

function EventWidget:RefreshPortraitsForEventIds(eventIds, reason)
    local result = type(originalRefreshPortraitsForEventIds) == "function"
        and originalRefreshPortraitsForEventIds(self, eventIds, reason)
        or false
    if self:IsAllUnitsPanelShown() then
        self:RefreshAllUnitsPanel(nil, false)
    end
    return result
end

function EventWidget:Refresh(...)
    local result = originalRefresh(self, ...)
    local state = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
    if isReadyEventState(state) then
        self:EnsureAllUnitsUI()
        if self:IsAllUnitsPanelShown() then
            self:RefreshAllUnitsPanel(state, false)
        end
    else
        self:HideAllUnitsPanel()
    end
    return result
end

EventWidget._allUnitsExtensionInstalled = true
return true
