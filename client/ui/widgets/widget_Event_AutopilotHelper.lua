local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local EventWidget = ClientUI.EventWidget

if type(EventWidget) ~= "table"
    or EventWidget._autopilotHelperExtensionInstalled == true
    or type(EventWidget.ShowCombatLogHistoryPanel) ~= "function"
then
    return true
end

local HELPER_BUTTON_WIDTH = 90
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
        return
    end
    if shown and frame.Show then
        frame:Show()
    elseif not shown and frame.Hide then
        frame:Hide()
    end
end

local function getActiveEventState()
    if type(Client.GetEventState) == "function" then
        return Client:GetEventState()
    end
    return Client.EventState
end

local function isLocalHost(state)
    return type(state) == "table"
        and state.active == true
        and type(Client.IsLocalEventHost) == "function"
        and Client:IsLocalEventHost(state) == true
end

local function buildButton(parentFrame, name, text, width, onClick)
    local button = UI.TextButton:New({
        name = name,
        width = width or HELPER_BUTTON_WIDTH,
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
    local host = isLocalHost(state)
    local helperMode = tostring(self.combatLogHistoryMode or "") == "dm-helper"
    setShown(self.autopilotHelperControlFrame, host and helperMode)
    if not host or not helperMode then
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
    setShown(self.autopilotHelperAuthorizeAllButton, type(pending) == "table")
    setShown(self.autopilotHelperReplanButton, type(pending) == "table")
    return true
end

function EventWidget:EnsureAutopilotHelperUI()
    if self.autopilotHelperButton then
        return true
    end
    if type(self.EnsureCombatLogHistoryUI) ~= "function" then
        return false
    end
    self:EnsureCombatLogHistoryUI()
    if not self.combatLogHistoryButtonRow or not self.combatLogHistoryPanel then
        return false
    end

    local buttonRowFrame = getFrame(self.combatLogHistoryButtonRow)
    if not buttonRowFrame then
        return false
    end
    self.autopilotHelperButton = buildButton(
        buttonRowFrame,
        "RPEClientEventWidgetDMHelperButton",
        "DM Helper",
        HELPER_BUTTON_WIDTH,
        function()
            local state = getActiveEventState()
            if not isLocalHost(state) then
                return
            end
            if type(self.IsCombatLogHistoryPanelShown) == "function"
                and self:IsCombatLogHistoryPanelShown()
                and tostring(self.combatLogHistoryMode or "") == "dm-helper"
            then
                self:HideCombatLogHistoryPanel()
                return
            end
            self.selectedDMHelperActionId = nil
            self:ShowCombatLogHistoryPanel("dm-helper")
        end
    )
    self.combatLogHistoryButtonRow:AddChild(self.autopilotHelperButton)

    local contentFrame = self.combatLogHistoryPanel:GetContentFrame()
    self.autopilotHelperControlFrame = CreateFrame("Frame", "RPEClientEventWidgetDMHelperControls", contentFrame)
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

    self._autopilotHelperBaseRowRenderer = self.combatLogHistoryScroll and self.combatLogHistoryScroll.rowRenderer or nil
    self._autopilotHelperBaseVisibleRows = self.combatLogHistoryScroll and self.combatLogHistoryScroll.visibleRows or 8
    self._autopilotHelperRenderer = function(row, item)
        local selected = tostring(item and item.actionId or "") ~= ""
            and tostring(item.actionId) == tostring(self.selectedDMHelperActionId or "")
        if row and row.SetText then
            row:SetText((selected and "> " or "") .. tostring(item and item.text or ""))
        end
        if row and row.SetJustifyH then
            row:SetJustifyH("LEFT")
        end
        if row and row.SetJustifyV then
            row:SetJustifyV("MIDDLE")
        end
        if row and row.SetWordWrap then
            row:SetWordWrap(false)
        end
        local rowFrame = getFrame(row)
        if rowFrame and rowFrame.EnableMouse then
            rowFrame:EnableMouse(true)
        end
        if rowFrame and rowFrame.SetScript then
            if type(item) == "table" and tostring(item.actionId or "") ~= "" then
                rowFrame:SetScript("OnMouseUp", function(_, button)
                    if button == "LeftButton" and isLocalHost(getActiveEventState()) then
                        self.selectedDMHelperActionId = item.actionId
                        if self.combatLogHistoryScroll and self.combatLogHistoryScroll.RefreshRows then
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

function EventWidget:RefreshAutopilotHelperHostVisibility()
    self:EnsureAutopilotHelperUI()
    local state = getActiveEventState()
    local host = isLocalHost(state)
    setShown(self.autopilotHelperButton, host)
    if not host and tostring(self.combatLogHistoryMode or "") == "dm-helper" then
        self:HideCombatLogHistoryPanel()
    end
    return host
end

local originalBuild = EventWidget.Build
local originalRefresh = EventWidget.Refresh
local originalGetViewEntries = EventWidget.GetCombatLogHistoryViewEntries
local originalGetViewTitle = EventWidget.GetCombatLogHistoryViewTitle
local originalRefreshPanel = EventWidget.RefreshCombatLogHistoryPanel

function EventWidget:Build(...)
    local result = originalBuild(self, ...)
    self:EnsureAutopilotHelperUI()
    self:RefreshAutopilotHelperHostVisibility()
    return result
end

function EventWidget:Refresh(...)
    local result = originalRefresh(self, ...)
    self:EnsureAutopilotHelperUI()
    self:RefreshAutopilotHelperHostVisibility()
    return result
end

function EventWidget:GetCombatLogHistoryViewEntries()
    if tostring(self.combatLogHistoryMode or "") == "dm-helper" then
        local state = getActiveEventState()
        if not isLocalHost(state) or type(Client.GetDMHelperEntries) ~= "function" then
            return {}
        end
        return Client:GetDMHelperEntries(state)
    end
    return originalGetViewEntries(self)
end

function EventWidget:GetCombatLogHistoryViewTitle()
    if tostring(self.combatLogHistoryMode or "") == "dm-helper" then
        return "DM Helper"
    end
    return originalGetViewTitle(self)
end

local function configureScrollForMode(self, helperMode)
    local scroll = self.combatLogHistoryScroll
    local scrollFrame = getFrame(scroll)
    local titleFrame = getFrame(self.combatLogHistoryTitle)
    local contentFrame = self.combatLogHistoryPanel and self.combatLogHistoryPanel:GetContentFrame() or nil
    if not scroll or not scrollFrame or not titleFrame or not contentFrame then
        return
    end

    if helperMode then
        if scroll.rowRenderer ~= self._autopilotHelperRenderer then
            scroll:SetRowRenderer(self._autopilotHelperRenderer)
        end
        scroll.visibleRows = HELPER_VISIBLE_ROWS
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, HELPER_CONTROL_HEIGHT + 2)
        setShown(self.autopilotHelperControlFrame, true)
    else
        if scroll.rowRenderer ~= self._autopilotHelperBaseRowRenderer then
            scroll:SetRowRenderer(self._autopilotHelperBaseRowRenderer)
        end
        scroll.visibleRows = self._autopilotHelperBaseVisibleRows or 8
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 0)
        setShown(self.autopilotHelperControlFrame, false)
    end
    if scroll.EnsureVisibleRowCount then
        scroll:EnsureVisibleRowCount()
    end
    if scroll.UpdateGeometry then
        scroll:UpdateGeometry()
    end
end

function EventWidget:RefreshCombatLogHistoryPanel()
    self:EnsureAutopilotHelperUI()
    local helperMode = tostring(self.combatLogHistoryMode or "") == "dm-helper"
    if not helperMode then
        configureScrollForMode(self, false)
        return originalRefreshPanel(self)
    end

    local state = getActiveEventState()
    if not isLocalHost(state) then
        self:HideCombatLogHistoryPanel()
        return false
    end

    configureScrollForMode(self, true)
    local entries = type(Client.GetDMHelperEntries) == "function" and Client:GetDMHelperEntries(state) or {}
    if self.combatLogHistoryTitle and self.combatLogHistoryTitle.SetText then
        self.combatLogHistoryTitle:SetText("DM Helper")
    end
    if self.combatLogHistoryScroll and self.combatLogHistoryScroll.SetItems then
        self.combatLogHistoryScroll:SetItems(entries)
    end
    local emptyFrame = getFrame(self.combatLogHistoryEmptyText)
    if emptyFrame then
        if #entries == 0 and emptyFrame.Show then
            emptyFrame:Show()
        elseif #entries > 0 and emptyFrame.Hide then
            emptyFrame:Hide()
        end
    end
    self:RefreshAutopilotHelperControls()
    return true
end

EventWidget._autopilotHelperExtensionInstalled = true
return true
