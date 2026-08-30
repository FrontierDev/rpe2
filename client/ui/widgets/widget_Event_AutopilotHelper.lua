local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local EventWidget = ClientUI.EventWidget

if type(EventWidget) ~= "table"
    or EventWidget._autopilotHelperExtensionInstalled == true
    or type(EventWidget.EnsureDMHelperUI) ~= "function"
    or type(EventWidget.RefreshCombatLogHistoryPanel) ~= "function"
then
    return true
end

local HELPER_BUTTON_HEIGHT = 20
local HELPER_CONTROL_HEIGHT = 50
local HELPER_VISIBLE_ROWS = 6

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

local function buildButton(parentFrame, name, text, width, onClick)
    local button = UI.TextButton:New({
        name = name,
        width = width,
        height = HELPER_BUTTON_HEIGHT,
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

local function findHelperEntryByActionId(actionId)
    local wanted = tostring(actionId or "")
    if wanted == "" or type(Client.GetDMHelperEntries) ~= "function" then
        return nil
    end
    local state = getActiveEventState()
    local entries = Client:GetDMHelperEntries(state) or {}
    for index = 1, #entries do
        local entry = entries[index]
        if tostring(entry and entry.actionId or "") == wanted then
            return entry
        end
    end
    return nil
end

function EventWidget:RefreshAutopilotHelperControls()
    if not self.autopilotHelperControlFrame then
        return false
    end

    local state = getActiveEventState()
    local active = isHostAutopilotEvent(state)
        and tostring(self.combatLogHistoryMode or "") == "dm-helper"
    setShown(self.autopilotHelperControlFrame, active)
    if not active then
        return false
    end

    local selected = findHelperEntryByActionId(self.selectedDMHelperActionId)
    setShown(self.autopilotHelperAuthorizeButton, selected and selected.canAuthorize == true)
    setShown(self.autopilotHelperRejectButton, selected and selected.canReject == true)
    setShown(self.autopilotHelperConfirmButton, selected and selected.canConfirm == true)
    setShown(self.autopilotHelperSkipButton, selected and selected.canSkip == true)

    local pending = type(Client.GetAutopilotPendingPlan) == "function"
        and select(1, Client:GetAutopilotPendingPlan(state))
        or nil
    local currentPending = type(pending) == "table" and tostring(pending.status or "") ~= "stale"
    setShown(self.autopilotHelperAuthorizeAllButton, currentPending)
    setShown(self.autopilotHelperReplanButton, currentPending)
    return true
end

function EventWidget:EnsureAutopilotHelperUI()
    if self.autopilotHelperControlFrame then
        return true
    end

    self:EnsureDMHelperUI()
    if not self.combatLogHistoryPanel or not self.combatLogHistoryScroll then
        return false
    end

    local contentFrame = self.combatLogHistoryPanel:GetContentFrame()
    if not contentFrame then
        return false
    end

    self.autopilotHelperControlFrame = CreateFrame("Frame", "RPEClientEventWidgetDMAutopilotControls", contentFrame)
    self.autopilotHelperControlFrame:SetPoint("BOTTOMLEFT", contentFrame, "BOTTOMLEFT", 0, 0)
    self.autopilotHelperControlFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 0)
    self.autopilotHelperControlFrame:SetHeight(HELPER_CONTROL_HEIGHT)

    self.autopilotHelperAuthorizeButton = buildButton(
        self.autopilotHelperControlFrame,
        "RPEClientEventWidgetDMAuthorizeButton",
        "Authorize",
        72,
        function()
            if type(Client.AuthorizeAutopilotPendingAction) == "function" then
                Client:AuthorizeAutopilotPendingAction(self.selectedDMHelperActionId, getActiveEventState())
                self:RefreshCombatLogHistoryPanel()
            end
        end
    )
    getFrame(self.autopilotHelperAuthorizeButton):SetPoint("TOPLEFT", self.autopilotHelperControlFrame, "TOPLEFT", 0, 0)

    self.autopilotHelperRejectButton = buildButton(
        self.autopilotHelperControlFrame,
        "RPEClientEventWidgetDMRejectButton",
        "Reject",
        60,
        function()
            if type(Client.RejectAutopilotPendingAction) == "function" then
                Client:RejectAutopilotPendingAction(self.selectedDMHelperActionId, getActiveEventState())
                self:RefreshCombatLogHistoryPanel()
            end
        end
    )
    getFrame(self.autopilotHelperRejectButton):SetPoint("LEFT", getFrame(self.autopilotHelperAuthorizeButton), "RIGHT", 4, 0)

    self.autopilotHelperConfirmButton = buildButton(
        self.autopilotHelperControlFrame,
        "RPEClientEventWidgetDMConfirmMovedButton",
        "Confirm Moved",
        96,
        function()
            if type(Client.ConfirmAutopilotPendingMovement) == "function" then
                Client:ConfirmAutopilotPendingMovement(self.selectedDMHelperActionId, getActiveEventState())
                self:RefreshCombatLogHistoryPanel()
            end
        end
    )
    getFrame(self.autopilotHelperConfirmButton):SetPoint("TOPLEFT", self.autopilotHelperControlFrame, "TOPLEFT", 0, 0)

    self.autopilotHelperSkipButton = buildButton(
        self.autopilotHelperControlFrame,
        "RPEClientEventWidgetDMSkipMovementButton",
        "Skip",
        52,
        function()
            if type(Client.SkipAutopilotPendingMovement) == "function" then
                Client:SkipAutopilotPendingMovement(self.selectedDMHelperActionId, getActiveEventState())
                self:RefreshCombatLogHistoryPanel()
            end
        end
    )
    getFrame(self.autopilotHelperSkipButton):SetPoint("LEFT", getFrame(self.autopilotHelperConfirmButton), "RIGHT", 4, 0)

    self.autopilotHelperAuthorizeAllButton = buildButton(
        self.autopilotHelperControlFrame,
        "RPEClientEventWidgetDMAuthorizeAllButton",
        "Authorize All",
        86,
        function()
            if type(Client.AuthorizeAllAutopilotPendingActions) == "function" then
                Client:AuthorizeAllAutopilotPendingActions(getActiveEventState())
                self:RefreshCombatLogHistoryPanel()
            end
        end
    )
    getFrame(self.autopilotHelperAuthorizeAllButton):SetPoint("BOTTOMLEFT", self.autopilotHelperControlFrame, "BOTTOMLEFT", 0, 0)

    self.autopilotHelperReplanButton = buildButton(
        self.autopilotHelperControlFrame,
        "RPEClientEventWidgetDMReplanButton",
        "Replan Pending",
        98,
        function()
            if type(Client.ReplanPendingAutopilotPlan) == "function" then
                Client:ReplanPendingAutopilotPlan(getActiveEventState())
                self.selectedDMHelperActionId = nil
                self:RefreshCombatLogHistoryPanel()
            end
        end
    )
    getFrame(self.autopilotHelperReplanButton):SetPoint("LEFT", getFrame(self.autopilotHelperAuthorizeAllButton), "RIGHT", 4, 0)

    self._autopilotHelperBaseDMRenderer = self._dmHelperRowRenderer
    self._autopilotHelperBaseVisibleRows = self.combatLogHistoryScroll.visibleRows or 8
    self._autopilotHelperRenderer = function(row, item)
        if type(self._autopilotHelperBaseDMRenderer) == "function" then
            self._autopilotHelperBaseDMRenderer(row, item)
        elseif row and type(row.SetText) == "function" then
            row:SetText(tostring(item and item.text or ""))
        end

        local actionId = tostring(item and item.actionId or "")
        local selected = actionId ~= "" and actionId == tostring(self.selectedDMHelperActionId or "")
        if selected and row and type(row.SetText) == "function" then
            row:SetText("> " .. tostring(item and item.text or ""))
        end

        local rowFrame = getFrame(row)
        if rowFrame and type(rowFrame.EnableMouse) == "function" then
            rowFrame:EnableMouse(actionId ~= "")
        end
        if rowFrame and type(rowFrame.SetScript) == "function" then
            if actionId ~= "" then
                rowFrame:SetScript("OnMouseUp", function(_, button)
                    if button == "LeftButton" and isHostAutopilotEvent(getActiveEventState()) then
                        self.selectedDMHelperActionId = actionId
                        if self.combatLogHistoryScroll and type(self.combatLogHistoryScroll.RefreshRows) == "function" then
                            self.combatLogHistoryScroll:RefreshRows()
                        end
                        self:RefreshAutopilotHelperControls()
                    end
                end)
            else
                rowFrame:SetScript("OnMouseUp", nil)
            end
        end
    end

    setShown(self.autopilotHelperControlFrame, false)
    return true
end

local function configureAutopilotControlsForMode(self)
    local scroll = self.combatLogHistoryScroll
    local scrollFrame = getFrame(scroll)
    local titleFrame = getFrame(self.combatLogHistoryTitle)
    local contentFrame = self.combatLogHistoryPanel and self.combatLogHistoryPanel:GetContentFrame() or nil
    if not scroll or not scrollFrame or not titleFrame or not contentFrame then
        return false
    end

    local active = tostring(self.combatLogHistoryMode or "") == "dm-helper"
        and isHostAutopilotEvent(getActiveEventState())
    if active then
        scroll.visibleRows = HELPER_VISIBLE_ROWS
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, HELPER_CONTROL_HEIGHT + 2)
        if scroll.rowRenderer ~= self._autopilotHelperRenderer then
            scroll:SetRowRenderer(self._autopilotHelperRenderer)
        end
    else
        scroll.visibleRows = self._autopilotHelperBaseVisibleRows or 8
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 0)
    end

    if type(scroll.EnsureVisibleRowCount) == "function" then
        scroll:EnsureVisibleRowCount()
    end
    if type(scroll.UpdateGeometry) == "function" then
        scroll:UpdateGeometry()
    end
    self:RefreshAutopilotHelperControls()
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
    if tostring(self.combatLogHistoryMode or "") == "dm-helper" then
        self:RefreshCombatLogHistoryPanel()
    else
        configureAutopilotControlsForMode(self)
    end
    return result
end

function EventWidget:RefreshCombatLogHistoryPanel(...)
    self:EnsureAutopilotHelperUI()
    local result = originalRefreshPanel(self, ...)
    configureAutopilotControlsForMode(self)
    if tostring(self.combatLogHistoryMode or "") == "dm-helper"
        and isHostAutopilotEvent(getActiveEventState())
        and self.combatLogHistoryScroll
        and type(self.combatLogHistoryScroll.RefreshRows) == "function"
    then
        self.combatLogHistoryScroll:RefreshRows()
    end
    return result
end

EventWidget._autopilotHelperExtensionInstalled = true
return true
