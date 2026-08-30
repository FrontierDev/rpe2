local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local Font = UI.Font or {}
local Inline = UI.Inline or {}
local EventWidget = ClientUI.EventWidget

if type(EventWidget) ~= "table"
    or EventWidget._autopilotHelperExtensionInstalled == true
    or type(EventWidget.EnsureDMHelperUI) ~= "function"
    or type(EventWidget.RefreshCombatLogHistoryPanel) ~= "function"
then
    return true
end

local DASHBOARD_PANEL_WIDTH = 560
local DASHBOARD_PANEL_HEIGHT = 460
local MARKER_BUTTON_SIZE = 28
local MARKER_GAP = 5
local SECTION_TITLE_HEIGHT = 16
local PENDING_HEIGHT = 100
local OUTCOMES_HEIGHT = 70
local DETAIL_TOGGLE_HEIGHT = 20
local DETAIL_HEIGHT = 92
local TOOLBAR_HEIGHT = 22
local SECTION_GAP = 4
local ACTION_ROW_HEIGHT = 30
local OUTCOME_ROW_HEIGHT = 26
local BUTTON_HEIGHT = 20

local function getFrame(element)
    if type(element) == "table" and type(element.GetFrame) == "function" then
        return element:GetFrame()
    end
    return element
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

local function isHostAutopilotEvent(state)
    return type(state) == "table"
        and state.active == true
        and tostring(state.turnMode or "manual") == "autopilot"
        and type(Client.IsLocalEventHost) == "function"
        and Client:IsLocalEventHost(state) == true
end

local function buildTextButton(parentFrame, name, text, width, onClick)
    local button = UI.TextButton:New({
        name = name,
        width = width,
        height = BUTTON_HEIGHT,
        text = text,
        fontSize = 9,
        fontFlags = "OUTLINE",
        labelColor = UI.ResolveColor(nil, "tab.inactive"),
        hoverLabelColor = UI.ResolveColor(nil, "text.primary"),
        pressedLabelColor = UI.ResolveColor(nil, "text.primary"),
        backgroundColor = UI.ResolveColor(nil, "tab.bar"),
        hoverColor = UI.ResolveColor(nil, "panel.background"),
        pressedColor = UI.ResolveColor(nil, "window.headerBackground"),
        borderTopColor = UI.ResolveColor(nil, "panel.border"),
        borderBottomColor = UI.ResolveColor(nil, "panel.border"),
        borderSize = 1,
    })
    button:SetParent(parentFrame)
    button:Create()
    button:SetScript("OnClick", onClick)
    return button
end

local function applyFont(region, size)
    if type(Font.Apply) == "function" then
        Font:Apply(region, {
            fontSize = size or 10,
            fontFlags = "OUTLINE",
        })
    elseif region and type(region.SetFontObject) == "function" then
        region:SetFontObject(GameFontHighlightSmall)
    end
end

local function setTextColor(region, token)
    if not region or type(region.SetTextColor) ~= "function" then
        return
    end
    local color = UI.ResolveColor(nil, token or "text.primary")
    region:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
end

local function actionStatusColorToken(status)
    local value = tostring(status or "")
    if value == "pending" then
        return "warning"
    end
    if value == "authorized" or value == "executing" or value == "completed" or value == "confirmed" then
        return "success"
    end
    return "danger"
end

local function applyRowBackground(texture, token, selected)
    if not texture or type(texture.SetColorTexture) ~= "function" then
        return
    end
    local color = UI.ResolveColor(nil, token or "panel.background")
    local alpha = selected and 0.34 or 0.18
    texture:SetColorTexture(color.r or 0.1, color.g or 0.1, color.b or 0.1, alpha)
end

local AutopilotActionRow = {}
AutopilotActionRow.__index = AutopilotActionRow

function AutopilotActionRow:New(options)
    return setmetatable({
        name = options and options.name or "RPEAutopilotActionRow",
        options = options or {},
        parent = nil,
        frame = nil,
        textRegion = nil,
        background = nil,
        doneButton = nil,
        authoriseButton = nil,
        rejectButton = nil,
        item = nil,
        ownerWidget = nil,
    }, self)
end

function AutopilotActionRow:SetParent(parent)
    self.parent = parent
end

function AutopilotActionRow:GetFrame()
    return self.frame
end

function AutopilotActionRow:Create()
    if self.frame then
        return self.frame
    end
    local frame = CreateFrame("Frame", self.name, self.parent)
    self.frame = frame
    frame:EnableMouse(true)

    self.background = frame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints(frame)

    self.textRegion = frame:CreateFontString(nil, "OVERLAY")
    self.textRegion:SetJustifyH("LEFT")
    self.textRegion:SetJustifyV("MIDDLE")
    self.textRegion:SetWordWrap(false)
    applyFont(self.textRegion, 10)
    setTextColor(self.textRegion, "text.primary")

    self.doneButton = buildTextButton(frame, self.name .. "Done", "Done", 50, function()
        local item = self.item
        if type(item) == "table"
            and item.canConfirm == true
            and type(Client.ConfirmAutopilotPendingMovement) == "function"
        then
            Client:ConfirmAutopilotPendingMovement(item.actionId, getActiveEventState())
            if self.ownerWidget and type(self.ownerWidget.RefreshCombatLogHistoryPanel) == "function" then
                self.ownerWidget:RefreshCombatLogHistoryPanel()
            end
        end
    end)

    self.rejectButton = buildTextButton(frame, self.name .. "Reject", "Reject", 54, function()
        local item = self.item
        if type(item) == "table"
            and item.canReject == true
            and type(Client.RejectAutopilotPendingAction) == "function"
        then
            Client:RejectAutopilotPendingAction(item.actionId, getActiveEventState())
            if self.ownerWidget and type(self.ownerWidget.RefreshCombatLogHistoryPanel) == "function" then
                self.ownerWidget:RefreshCombatLogHistoryPanel()
            end
        end
    end)

    self.authoriseButton = buildTextButton(frame, self.name .. "Authorise", "Authorise", 68, function()
        local item = self.item
        if type(item) == "table"
            and item.canAuthorize == true
            and type(Client.AuthorizeAutopilotPendingAction) == "function"
        then
            Client:AuthorizeAutopilotPendingAction(item.actionId, getActiveEventState())
            if self.ownerWidget and type(self.ownerWidget.RefreshCombatLogHistoryPanel) == "function" then
                self.ownerWidget:RefreshCombatLogHistoryPanel()
            end
        end
    end)

    frame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton"
            and type(self.item) == "table"
            and self.ownerWidget
            and type(self.ownerWidget.SelectAutopilotHelperDetail) == "function"
        then
            self.ownerWidget:SelectAutopilotHelperDetail(self.item)
        end
    end)
    return frame
end

function AutopilotActionRow:Reset()
    self.item = nil
    self.ownerWidget = nil
    if self.textRegion then
        self.textRegion:SetText("")
    end
    setShown(self.doneButton, false)
    setShown(self.authoriseButton, false)
    setShown(self.rejectButton, false)
end

function AutopilotActionRow:SetItem(item, ownerWidget)
    self.item = item
    self.ownerWidget = ownerWidget
    local frame = self.frame
    if not frame or type(item) ~= "table" then
        self:Reset()
        return
    end

    local selected = tostring(ownerWidget and ownerWidget.selectedAutopilotDetailKey or "")
        == tostring(item.entryId or "")
    applyRowBackground(self.background, actionStatusColorToken(item.status), selected)

    local doneVisible = item.actionType == "movement" and item.canConfirm == true
    local authoriseVisible = item.actionType == "spell" and item.canAuthorize == true
    local rejectVisible = item.actionType == "spell" and item.canReject == true
    setShown(self.doneButton, doneVisible)
    setShown(self.authoriseButton, authoriseVisible)
    setShown(self.rejectButton, rejectVisible)

    local rightAnchor = frame
    local rightPoint = "RIGHT"
    local rightOffset = -7

    local doneFrame = getFrame(self.doneButton)
    doneFrame:ClearAllPoints()
    doneFrame:SetPoint("RIGHT", frame, "RIGHT", -4, 0)

    local rejectFrame = getFrame(self.rejectButton)
    rejectFrame:ClearAllPoints()
    rejectFrame:SetPoint("RIGHT", frame, "RIGHT", -4, 0)

    local authoriseFrame = getFrame(self.authoriseButton)
    authoriseFrame:ClearAllPoints()
    if rejectVisible then
        authoriseFrame:SetPoint("RIGHT", rejectFrame, "LEFT", -4, 0)
    else
        authoriseFrame:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    end

    if doneVisible then
        rightAnchor = doneFrame
        rightPoint = "LEFT"
        rightOffset = -6
    elseif authoriseVisible then
        rightAnchor = authoriseFrame
        rightPoint = "LEFT"
        rightOffset = -6
    elseif rejectVisible then
        rightAnchor = rejectFrame
        rightPoint = "LEFT"
        rightOffset = -6
    end

    local displayText = tostring(item.displayText or item.summary or "")
    if item.actionType == "movement" and type(Inline.RaidMarker) == "function" then
        local markerIcon = Inline:RaidMarker(item.raidMarker, 14, 14)
        local objective = tostring(item.objectiveText or "")
        if markerIcon ~= "" then
            if objective ~= "" and objective ~= "no target" then
                displayText = ("Move %s near %s"):format(markerIcon, objective)
            else
                displayText = ("Move %s to the proposed position"):format(markerIcon)
            end
        end
    end

    self.textRegion:ClearAllPoints()
    self.textRegion:SetPoint("LEFT", frame, "LEFT", 8, 0)
    self.textRegion:SetPoint("RIGHT", rightAnchor, rightPoint, rightOffset, 0)
    self.textRegion:SetText(displayText)
end

local AutopilotOutcomeRow = {}
AutopilotOutcomeRow.__index = AutopilotOutcomeRow

function AutopilotOutcomeRow:New(options)
    return setmetatable({
        name = options and options.name or "RPEAutopilotOutcomeRow",
        parent = nil,
        frame = nil,
        textRegion = nil,
        background = nil,
        item = nil,
        ownerWidget = nil,
    }, self)
end

function AutopilotOutcomeRow:SetParent(parent)
    self.parent = parent
end

function AutopilotOutcomeRow:GetFrame()
    return self.frame
end

function AutopilotOutcomeRow:Create()
    if self.frame then
        return self.frame
    end
    local frame = CreateFrame("Frame", self.name, self.parent)
    self.frame = frame
    frame:EnableMouse(true)
    self.background = frame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints(frame)
    self.textRegion = frame:CreateFontString(nil, "OVERLAY")
    self.textRegion:SetPoint("LEFT", frame, "LEFT", 8, 0)
    self.textRegion:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    self.textRegion:SetJustifyH("LEFT")
    self.textRegion:SetJustifyV("MIDDLE")
    self.textRegion:SetWordWrap(false)
    applyFont(self.textRegion, 10)
    setTextColor(self.textRegion, "text.primary")
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton"
            and type(self.item) == "table"
            and self.ownerWidget
            and type(self.ownerWidget.SelectAutopilotHelperDetail) == "function"
        then
            self.ownerWidget:SelectAutopilotHelperDetail(self.item)
        end
    end)
    return frame
end

function AutopilotOutcomeRow:Reset()
    self.item = nil
    self.ownerWidget = nil
    if self.textRegion then
        self.textRegion:SetText("")
    end
end

function AutopilotOutcomeRow:SetItem(item, ownerWidget)
    self.item = item
    self.ownerWidget = ownerWidget
    if not self.frame or type(item) ~= "table" then
        self:Reset()
        return
    end
    local selected = tostring(ownerWidget and ownerWidget.selectedAutopilotDetailKey or "")
        == tostring(item.entryId or "")
    applyRowBackground(self.background, selected and "accent" or "panel.background", selected)
    self.textRegion:SetText(tostring(item.displayText or item.summary or ""))
end

local function createSectionTitle(parent, name, text)
    local title = UI.CreateText(parent, name, text, {
        height = SECTION_TITLE_HEIGHT,
        fontSize = 10,
        fontFlags = "OUTLINE",
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    return title
end

local function findEntryByKey(entries, key)
    local wanted = tostring(key or "")
    if wanted == "" then
        return nil
    end
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        if tostring(entry and entry.entryId or "") == wanted then
            return entry
        end
    end
    return nil
end

function EventWidget:ClearAutopilotHelperSelection()
    self.selectedAutopilotMarker = nil
    self.selectedAutopilotDetailKey = nil
    return true
end

function EventWidget:SelectAutopilotHelperDetail(entry)
    if type(entry) ~= "table" or tostring(entry.entryId or "") == "" then
        return false
    end
    self.selectedAutopilotDetailKey = tostring(entry.entryId)
    if tostring(entry.kind or "") == "marker-position" and entry.used == true then
        self.selectedAutopilotMarker = tonumber(entry.raidMarker)
    end
    if self.autopilotPendingScroll and type(self.autopilotPendingScroll.RefreshRows) == "function" then
        self.autopilotPendingScroll:RefreshRows()
    end
    if self.autopilotOutcomeScroll and type(self.autopilotOutcomeScroll.RefreshRows) == "function" then
        self.autopilotOutcomeScroll:RefreshRows()
    end
    self:RefreshAutopilotMarkerButtons()
    self:RefreshAutopilotHelperDetail()
    self:RefreshAutopilotHelperControls()
    return true
end

function EventWidget:GetSelectedAutopilotHelperEntry()
    local key = tostring(self.selectedAutopilotDetailKey or "")
    if key == "" then
        return nil
    end
    local state = getActiveEventState()
    local markers = type(Client.GetAutopilotMarkerStates) == "function"
        and Client:GetAutopilotMarkerStates(state)
        or {}
    local actions = type(Client.GetAutopilotPendingActionRows) == "function"
        and select(1, Client:GetAutopilotPendingActionRows(state))
        or {}
    local outcomes = type(Client.GetAutopilotTurnOutcomes) == "function"
        and Client:GetAutopilotTurnOutcomes(state)
        or {}
    return findEntryByKey(markers, key) or findEntryByKey(actions, key) or findEntryByKey(outcomes, key)
end

function EventWidget:RefreshAutopilotMarkerButtons(markerStatesOverride)
    if type(self.autopilotMarkerButtons) ~= "table" then
        return false
    end
    local state = getActiveEventState()
    local markerStates = type(markerStatesOverride) == "table"
        and markerStatesOverride
        or (type(Client.GetAutopilotMarkerStates) == "function" and Client:GetAutopilotMarkerStates(state) or {})
    local byMarker = {}
    for index = 1, #markerStates do
        local markerState = markerStates[index]
        local marker = math.floor(tonumber(markerState and markerState.raidMarker) or 0)
        if marker >= 1 and marker <= 8 then
            byMarker[marker] = markerState
        end
    end

    local selectedMarker = math.floor(tonumber(self.selectedAutopilotMarker) or 0)
    if selectedMarker > 0 and (not byMarker[selectedMarker] or byMarker[selectedMarker].used ~= true) then
        local selectedKey = "autopilot-marker:" .. tostring(selectedMarker)
        if tostring(self.selectedAutopilotDetailKey or "") == selectedKey then
            self.selectedAutopilotDetailKey = nil
        end
        self.selectedAutopilotMarker = nil
        selectedMarker = 0
    end

    for marker = 1, 8 do
        local button = self.autopilotMarkerButtons[marker]
        local markerState = byMarker[marker]
        local used = type(markerState) == "table" and markerState.used == true
        if button and type(button.SetEnabled) == "function" then
            button:SetEnabled(used)
        end
        local frame = getFrame(button)
        if frame then
            local texture = type(frame.GetNormalTexture) == "function" and frame:GetNormalTexture() or nil
            if texture and type(texture.SetDesaturated) == "function" then
                texture:SetDesaturated(not used)
            end
            if type(frame.SetAlpha) == "function" then
                frame:SetAlpha(not used and 0.28 or (selectedMarker == marker and 1 or 0.72))
            end
        end
    end
    return true
end

function EventWidget:RefreshAutopilotHelperDetail()
    if not self.autopilotDetailScroll then
        return false
    end
    local state = getActiveEventState()
    local selected = self:GetSelectedAutopilotHelperEntry()
    local text = nil
    if type(selected) == "table" then
        text = tostring(selected.details or selected.summary or "")
    elseif type(Client.GetAutopilotDMHelperOverview) == "function" then
        text = tostring(Client:GetAutopilotDMHelperOverview(state) or "")
    end
    if text == "" then
        text = "No additional Autopilot details are available."
    end
    self.autopilotDetailScroll:ClearMessages()
    self.autopilotDetailScroll:AddMessage(text)
    local detailFrame = getFrame(self.autopilotDetailScroll)
    if detailFrame and type(detailFrame.ScrollToTop) == "function" then
        detailFrame:ScrollToTop()
    end
    return true
end

function EventWidget:RefreshAutopilotHelperControls(actionRowsOverride, markerStatesOverride)
    if not self.autopilotToolbarFrame then
        return false
    end
    local state = getActiveEventState()
    local active = isHostAutopilotEvent(state)
        and tostring(self.combatLogHistoryMode or "") == "dm-helper"
    setShown(self.autopilotToolbarFrame, active)
    if not active then
        return false
    end

    local markers = type(markerStatesOverride) == "table"
        and markerStatesOverride
        or (type(Client.GetAutopilotMarkerStates) == "function" and Client:GetAutopilotMarkerStates(state) or {})
    local selectedMarkerState = nil
    local selectedMarker = math.floor(tonumber(self.selectedAutopilotMarker) or 0)
    for index = 1, #markers do
        if tonumber(markers[index] and markers[index].raidMarker) == selectedMarker then
            selectedMarkerState = markers[index]
            break
        end
    end
    self.autopilotSetPositionButton:SetEnabled(type(selectedMarkerState) == "table" and selectedMarkerState.canSetPosition == true)

    local rows, pending = nil, nil
    if type(actionRowsOverride) == "table" then
        rows = actionRowsOverride
        pending = type(Client.GetAutopilotPendingPlan) == "function"
            and select(1, Client:GetAutopilotPendingPlan(state))
            or nil
    elseif type(Client.GetAutopilotPendingActionRows) == "function" then
        rows, pending = Client:GetAutopilotPendingActionRows(state)
    else
        rows = {}
    end
    local canAuthoriseAll = false
    for index = 1, #(rows or {}) do
        if rows[index] and rows[index].canAuthorize == true then
            canAuthoriseAll = true
            break
        end
    end
    local currentPending = type(pending) == "table" and tostring(pending.status or "") ~= "stale"
    self.autopilotAuthoriseAllButton:SetEnabled(currentPending and canAuthoriseAll)
    self.autopilotReplanButton:SetEnabled(currentPending)

    local selected = self:GetSelectedAutopilotHelperEntry()
    local canSkip = type(selected) == "table"
        and selected.actionType == "movement"
        and selected.canSkip == true
    setShown(self.autopilotSkipMovementButton, canSkip)
    if canSkip then
        self.autopilotSkipMovementButton:SetEnabled(true)
    end
    return true
end

function EventWidget:SetAutopilotDetailsExpanded(expanded)
    self.autopilotDetailsExpanded = expanded == true
    setShown(self.autopilotDetailPanel, self.autopilotDetailsExpanded)
    self:LayoutAutopilotHelperDashboard()
    return self.autopilotDetailsExpanded
end

function EventWidget:LayoutAutopilotHelperDashboard()
    if not self.autopilotDashboardFrame then
        return false
    end
    local detailExpanded = self.autopilotDetailsExpanded == true
    local detailPanelFrame = getFrame(self.autopilotDetailPanel)
    local detailToggleFrame = getFrame(self.autopilotDetailToggleButton)
    local toolbar = self.autopilotToolbarFrame
    if not detailToggleFrame or not toolbar then
        return false
    end

    detailToggleFrame:ClearAllPoints()
    if detailExpanded and detailPanelFrame then
        detailPanelFrame:ClearAllPoints()
        detailPanelFrame:SetPoint("BOTTOMLEFT", toolbar, "TOPLEFT", 0, SECTION_GAP)
        detailPanelFrame:SetPoint("BOTTOMRIGHT", toolbar, "TOPRIGHT", 0, SECTION_GAP)
        detailPanelFrame:SetHeight(DETAIL_HEIGHT)
        detailToggleFrame:SetPoint("BOTTOMLEFT", detailPanelFrame, "TOPLEFT", 0, 2)
        detailToggleFrame:SetPoint("BOTTOMRIGHT", detailPanelFrame, "TOPRIGHT", 0, 2)
    else
        detailToggleFrame:SetPoint("BOTTOMLEFT", toolbar, "TOPLEFT", 0, SECTION_GAP)
        detailToggleFrame:SetPoint("BOTTOMRIGHT", toolbar, "TOPRIGHT", 0, SECTION_GAP)
    end
    detailToggleFrame:SetHeight(DETAIL_TOGGLE_HEIGHT)
    return true
end

function EventWidget:RefreshAutopilotHelperDashboard()
    if not self.autopilotDashboardFrame then
        return false
    end
    local state = getActiveEventState()
    if not isHostAutopilotEvent(state) then
        return false
    end

    local markerStates = type(Client.GetAutopilotMarkerStates) == "function"
        and Client:GetAutopilotMarkerStates(state)
        or {}
    local actionRows, pending = {}, nil
    if type(Client.GetAutopilotPendingActionRows) == "function" then
        actionRows, pending = Client:GetAutopilotPendingActionRows(state)
    end
    local outcomeRows = type(Client.GetAutopilotTurnOutcomes) == "function"
        and Client:GetAutopilotTurnOutcomes(state)
        or {}

    self:RefreshAutopilotMarkerButtons(markerStates)
    self.autopilotPendingScroll:SetItems(actionRows)
    self.autopilotOutcomeScroll:SetItems(outcomeRows)

    setShown(self.autopilotPendingEmptyText, #actionRows == 0)
    setShown(self.autopilotOutcomeEmptyText, #outcomeRows == 0)

    local selected = self:GetSelectedAutopilotHelperEntry()
    if self.selectedAutopilotDetailKey and not selected then
        self.selectedAutopilotDetailKey = nil
    end
    self:RefreshAutopilotHelperDetail()
    self:RefreshAutopilotHelperControls(actionRows, markerStates)
    self:LayoutAutopilotHelperDashboard()
    return pending ~= nil or #markerStates > 0 or #outcomeRows > 0
end

function EventWidget:EnsureAutopilotHelperUI()
    if self.autopilotDashboardFrame then
        return true
    end

    self:EnsureDMHelperUI()
    if not self.combatLogHistoryPanel then
        return false
    end
    local contentFrame = self.combatLogHistoryPanel:GetContentFrame()
    local titleFrame = getFrame(self.combatLogHistoryTitle)
    if not contentFrame or not titleFrame then
        return false
    end

    self.autopilotDashboardFrame = CreateFrame("Frame", "RPEClientEventWidgetDMAutopilotDashboard", contentFrame)
    self.autopilotDashboardFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, -4)
    self.autopilotDashboardFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 0)
    self.autopilotDashboardFrame:Hide()

    self.autopilotMarkerFrame = CreateFrame("Frame", "RPEClientEventWidgetDMAutopilotMarkers", self.autopilotDashboardFrame)
    self.autopilotMarkerFrame:SetPoint("TOPLEFT", self.autopilotDashboardFrame, "TOPLEFT", 0, 0)
    self.autopilotMarkerFrame:SetPoint("TOPRIGHT", self.autopilotDashboardFrame, "TOPRIGHT", 0, 0)
    self.autopilotMarkerFrame:SetHeight(MARKER_BUTTON_SIZE)
    self.autopilotMarkerButtons = {}
    local totalMarkerWidth = (8 * MARKER_BUTTON_SIZE) + (7 * MARKER_GAP)
    local firstOffset = math.max(0, math.floor((DASHBOARD_PANEL_WIDTH - totalMarkerWidth) / 2) - 8)
    for marker = 1, 8 do
        local button = UI.ImageButton:New({
            name = "RPEClientEventWidgetDMAutopilotMarker" .. marker,
            width = MARKER_BUTTON_SIZE,
            height = MARKER_BUTTON_SIZE,
            normalTexture = ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"):format(marker),
            highlightTexture = "Interface\\Buttons\\UI-Common-MouseHilight",
        })
        button:SetParent(self.autopilotMarkerFrame)
        button:Create()
        local frame = getFrame(button)
        frame:SetPoint("LEFT", self.autopilotMarkerFrame, "LEFT", firstOffset + ((marker - 1) * (MARKER_BUTTON_SIZE + MARKER_GAP)), 0)
        button:SetScript("OnClick", function()
            local states = type(Client.GetAutopilotMarkerStates) == "function"
                and Client:GetAutopilotMarkerStates(getActiveEventState())
                or {}
            local selected = nil
            for index = 1, #states do
                if tonumber(states[index] and states[index].raidMarker) == marker then
                    selected = states[index]
                    break
                end
            end
            if type(selected) == "table" and selected.used == true then
                self.selectedAutopilotMarker = marker
                self:SelectAutopilotHelperDetail(selected)
            end
        end)
        self.autopilotMarkerButtons[marker] = button
    end

    self.autopilotPendingTitle = createSectionTitle(
        self.autopilotDashboardFrame,
        "RPEClientEventWidgetDMAutopilotPendingTitle",
        "Pending Actions"
    )
    local pendingTitleFrame = getFrame(self.autopilotPendingTitle)
    pendingTitleFrame:SetPoint("TOPLEFT", self.autopilotMarkerFrame, "BOTTOMLEFT", 0, -SECTION_GAP)
    pendingTitleFrame:SetPoint("TOPRIGHT", self.autopilotMarkerFrame, "BOTTOMRIGHT", 0, -SECTION_GAP)

    self.autopilotPendingScroll = UI.ScrollLayout:New({
        name = "RPEClientEventWidgetDMAutopilotPendingScroll",
        rowHeight = ACTION_ROW_HEIGHT,
        rowSpacing = 2,
        visibleRows = 3,
        rowElementClass = AutopilotActionRow,
        rowRenderer = function(row, item)
            row:SetItem(item, self)
        end,
    })
    self.autopilotPendingScroll:SetParent(self.autopilotDashboardFrame)
    self.autopilotPendingScroll:Create()
    local pendingScrollFrame = getFrame(self.autopilotPendingScroll)
    pendingScrollFrame:SetPoint("TOPLEFT", pendingTitleFrame, "BOTTOMLEFT", 0, -2)
    pendingScrollFrame:SetPoint("TOPRIGHT", pendingTitleFrame, "BOTTOMRIGHT", 0, -2)
    pendingScrollFrame:SetHeight(PENDING_HEIGHT)

    self.autopilotPendingEmptyText = UI.CreateText(
        self.autopilotDashboardFrame,
        "RPEClientEventWidgetDMAutopilotPendingEmpty",
        "No pending actions.",
        {
            height = 20,
            fontSize = 10,
            fontFlags = "OUTLINE",
            justifyH = "CENTER",
            justifyV = "MIDDLE",
            wordWrap = false,
            textColor = UI.ResolveColor(nil, "text.muted"),
        }
    )
    local pendingEmptyFrame = getFrame(self.autopilotPendingEmptyText)
    pendingEmptyFrame:SetPoint("CENTER", pendingScrollFrame, "CENTER", 0, 0)

    self.autopilotOutcomeTitle = createSectionTitle(
        self.autopilotDashboardFrame,
        "RPEClientEventWidgetDMAutopilotOutcomeTitle",
        "Outcomes This Turn"
    )
    local outcomeTitleFrame = getFrame(self.autopilotOutcomeTitle)
    outcomeTitleFrame:SetPoint("TOPLEFT", pendingScrollFrame, "BOTTOMLEFT", 0, -SECTION_GAP)
    outcomeTitleFrame:SetPoint("TOPRIGHT", pendingScrollFrame, "BOTTOMRIGHT", 0, -SECTION_GAP)

    self.autopilotOutcomeScroll = UI.ScrollLayout:New({
        name = "RPEClientEventWidgetDMAutopilotOutcomeScroll",
        rowHeight = OUTCOME_ROW_HEIGHT,
        rowSpacing = 2,
        visibleRows = 2,
        rowElementClass = AutopilotOutcomeRow,
        rowRenderer = function(row, item)
            row:SetItem(item, self)
        end,
    })
    self.autopilotOutcomeScroll:SetParent(self.autopilotDashboardFrame)
    self.autopilotOutcomeScroll:Create()
    local outcomeScrollFrame = getFrame(self.autopilotOutcomeScroll)
    outcomeScrollFrame:SetPoint("TOPLEFT", outcomeTitleFrame, "BOTTOMLEFT", 0, -2)
    outcomeScrollFrame:SetPoint("TOPRIGHT", outcomeTitleFrame, "BOTTOMRIGHT", 0, -2)
    outcomeScrollFrame:SetHeight(OUTCOMES_HEIGHT)

    self.autopilotOutcomeEmptyText = UI.CreateText(
        self.autopilotDashboardFrame,
        "RPEClientEventWidgetDMAutopilotOutcomeEmpty",
        "No outcomes this turn.",
        {
            height = 20,
            fontSize = 10,
            fontFlags = "OUTLINE",
            justifyH = "CENTER",
            justifyV = "MIDDLE",
            wordWrap = false,
            textColor = UI.ResolveColor(nil, "text.muted"),
        }
    )
    local outcomeEmptyFrame = getFrame(self.autopilotOutcomeEmptyText)
    outcomeEmptyFrame:SetPoint("CENTER", outcomeScrollFrame, "CENTER", 0, 0)

    self.autopilotToolbarFrame = CreateFrame("Frame", "RPEClientEventWidgetDMAutopilotToolbar", self.autopilotDashboardFrame)
    self.autopilotToolbarFrame:SetPoint("BOTTOMLEFT", self.autopilotDashboardFrame, "BOTTOMLEFT", 0, 0)
    self.autopilotToolbarFrame:SetPoint("BOTTOMRIGHT", self.autopilotDashboardFrame, "BOTTOMRIGHT", 0, 0)
    self.autopilotToolbarFrame:SetHeight(TOOLBAR_HEIGHT)

    self.autopilotSetPositionButton = buildTextButton(
        self.autopilotToolbarFrame,
        "RPEClientEventWidgetDMAutopilotSetPosition",
        "Set Position Here",
        108,
        function()
            local marker = math.floor(tonumber(self.selectedAutopilotMarker) or 0)
            if marker >= 1 and marker <= 8 and type(Client.SetAutopilotMarkerPositionHere) == "function" then
                Client:SetAutopilotMarkerPositionHere(getActiveEventState(), marker)
                self:RefreshCombatLogHistoryPanel()
            end
        end
    )
    getFrame(self.autopilotSetPositionButton):SetPoint("LEFT", self.autopilotToolbarFrame, "LEFT", 0, 0)

    self.autopilotAuthoriseAllButton = buildTextButton(
        self.autopilotToolbarFrame,
        "RPEClientEventWidgetDMAutopilotAuthoriseAll",
        "Authorise All",
        86,
        function()
            if type(Client.AuthorizeAllAutopilotPendingActions) == "function" then
                Client:AuthorizeAllAutopilotPendingActions(getActiveEventState())
                self:RefreshCombatLogHistoryPanel()
            end
        end
    )
    getFrame(self.autopilotAuthoriseAllButton):SetPoint("LEFT", getFrame(self.autopilotSetPositionButton), "RIGHT", 4, 0)

    self.autopilotReplanButton = buildTextButton(
        self.autopilotToolbarFrame,
        "RPEClientEventWidgetDMAutopilotReplan",
        "Replan Pending",
        96,
        function()
            if type(Client.ReplanPendingAutopilotPlan) == "function" then
                Client:ReplanPendingAutopilotPlan(getActiveEventState())
                self.selectedAutopilotDetailKey = nil
                self:RefreshCombatLogHistoryPanel()
            end
        end
    )
    getFrame(self.autopilotReplanButton):SetPoint("LEFT", getFrame(self.autopilotAuthoriseAllButton), "RIGHT", 4, 0)

    self.autopilotSkipMovementButton = buildTextButton(
        self.autopilotToolbarFrame,
        "RPEClientEventWidgetDMAutopilotSkipMovement",
        "Skip Movement",
        90,
        function()
            local selected = self:GetSelectedAutopilotHelperEntry()
            if type(selected) == "table"
                and selected.actionType == "movement"
                and selected.canSkip == true
                and type(Client.SkipAutopilotPendingMovement) == "function"
            then
                Client:SkipAutopilotPendingMovement(selected.actionId, getActiveEventState())
                self:RefreshCombatLogHistoryPanel()
            end
        end
    )
    getFrame(self.autopilotSkipMovementButton):SetPoint("LEFT", getFrame(self.autopilotReplanButton), "RIGHT", 4, 0)
    setShown(self.autopilotSkipMovementButton, false)

    self.autopilotDetailToggleButton = buildTextButton(
        self.autopilotDashboardFrame,
        "RPEClientEventWidgetDMAutopilotDetailsToggle",
        "Details",
        DASHBOARD_PANEL_WIDTH - 12,
        function()
            self:SetAutopilotDetailsExpanded(self.autopilotDetailsExpanded ~= true)
        end
    )

    self.autopilotDetailPanel = UI.CreatePanel(self.autopilotDashboardFrame, "RPEClientEventWidgetDMAutopilotDetailPanel", {
        height = DETAIL_HEIGHT,
        contentInset = 6,
        showBorder = true,
        panelBorderSize = 1,
        panelBorderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
    })
    setShown(self.autopilotDetailPanel, false)
    local detailContent = self.autopilotDetailPanel:GetContentFrame()
    self.autopilotDetailScroll = UI.ScrollingMessageFrame:New({
        name = "RPEClientEventWidgetDMAutopilotDetailScroll",
        fontSize = 10,
        fontFlags = "OUTLINE",
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = true,
        indentedWordWrap = false,
        maxLines = 512,
        spacing = 1,
        fading = false,
        scrollTime = 0,
        insertMode = "bottom",
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.autopilotDetailScroll:SetParent(detailContent)
    self.autopilotDetailScroll:Create()
    local detailScrollFrame = getFrame(self.autopilotDetailScroll)
    detailScrollFrame:SetAllPoints(detailContent)
    if type(detailScrollFrame.EnableMouseWheel) == "function" then
        detailScrollFrame:EnableMouseWheel(true)
    end
    if type(detailScrollFrame.SetScript) == "function" then
        detailScrollFrame:SetScript("OnMouseWheel", function(frame, delta)
            if delta > 0 and type(frame.ScrollUp) == "function" then
                frame:ScrollUp()
            elseif delta < 0 and type(frame.ScrollDown) == "function" then
                frame:ScrollDown()
            end
        end)
    end

    self.autopilotDetailsExpanded = false
    self:LayoutAutopilotHelperDashboard()
    return true
end

local function configureAutopilotDashboardForMode(self)
    local state = getActiveEventState()
    local active = tostring(self.combatLogHistoryMode or "") == "dm-helper"
        and isHostAutopilotEvent(state)

    self:EnsureAutopilotHelperUI()
    setShown(self.autopilotDashboardFrame, active)
    if active then
        local panelFrame = getFrame(self.combatLogHistoryPanel)
        if panelFrame and type(panelFrame.SetSize) == "function" then
            panelFrame:SetSize(DASHBOARD_PANEL_WIDTH, DASHBOARD_PANEL_HEIGHT)
        end
        setShown(self.combatLogHistoryScroll, false)
        setShown(self.combatLogHistoryEmptyText, false)
        setShown(self.dmHelperDetailPanel, false)
        self:RefreshAutopilotHelperDashboard()
    else
        setShown(self.autopilotToolbarFrame, false)
        setShown(self.combatLogHistoryScroll, true)
    end
    return active
end

local originalBuild = EventWidget.Build
local originalRefresh = EventWidget.Refresh
local originalRefreshPanel = EventWidget.RefreshCombatLogHistoryPanel

function EventWidget:Build(...)
    local result = originalBuild(self, ...)
    self:EnsureAutopilotHelperUI()
    return result
end

function EventWidget:Refresh(...)
    local result = originalRefresh(self, ...)
    self:EnsureAutopilotHelperUI()
    configureAutopilotDashboardForMode(self)
    return result
end

function EventWidget:RefreshCombatLogHistoryPanel(...)
    self:EnsureAutopilotHelperUI()
    local result = originalRefreshPanel(self, ...)
    configureAutopilotDashboardForMode(self)
    return result
end

EventWidget._autopilotHelperExtensionInstalled = true
return true