local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local Tasks = Addon.Internal.Tasks or {}
local EventWidget = ClientUI.EventWidget

if type(EventWidget) ~= "table"
    or type(EventWidget.RefreshAutopilotHelperDashboard) ~= "function"
    or type(EventWidget.RefreshCombatLogHistoryPanel) ~= "function"
then
    return true
end

local DASHBOARD_PANEL_WIDTH = 560
-- Keep this in sync with widget_Event_AutopilotHelper.lua. The dashboard's
-- fixed-height sections are laid out for 654px; forcing it to 460px causes
-- the pending/outcome/cue-authoring regions to overlap and clip.
local DASHBOARD_PANEL_HEIGHT = 654
local COMBAT_LOG_HISTORY_LIMIT = 15
local COMBAT_LOG_ROW_HEIGHT = 20
local COMBAT_LOG_ROW_SPACING = 0

Client.AutopilotHelperRefreshState = type(Client.AutopilotHelperRefreshState) == "table"
    and Client.AutopilotHelperRefreshState
    or {
        pending = false,
        eventId = nil,
        job = nil,
    }

local RefreshState = Client.AutopilotHelperRefreshState

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

local function getEventWidget()
    local widgetNamespace = Client.UI and Client.UI.EventWidget or nil
    return type(widgetNamespace) == "table"
        and type(widgetNamespace.Get) == "function"
        and widgetNamespace:Get()
        or widgetNamespace
end

local function refreshScrollGeometry(scroll)
    if type(scroll) ~= "table" then
        return false
    end
    if type(scroll.EnsureVisibleRowCount) == "function" then
        scroll:EnsureVisibleRowCount()
    end
    if type(scroll.UpdateGeometry) == "function" then
        scroll:UpdateGeometry()
    end
    return true
end

-- Combat Log is hosted by the shared Event utility window. The original
-- history implementation retained only eight 27px rows, leaving a large
-- amount of the 340px window unused. Compact the rows and retain enough
-- history to fill the available viewport.
local originalEnsureEventUtilityWindow = EventWidget.EnsureEventUtilityWindow
if type(originalEnsureEventUtilityWindow) == "function" then
    function EventWidget:EnsureEventUtilityWindow(...)
        local result = originalEnsureEventUtilityWindow(self, ...)
        local scroll = self.combatLogUtilityScroll
        if type(scroll) == "table" and self._compactCombatLogLayoutApplied ~= true then
            scroll.rowHeight = COMBAT_LOG_ROW_HEIGHT
            scroll.rowSpacing = COMBAT_LOG_ROW_SPACING
            scroll.visibleRows = COMBAT_LOG_HISTORY_LIMIT
            scroll.minVisibleRows = COMBAT_LOG_HISTORY_LIMIT
            scroll.maxVisibleRows = COMBAT_LOG_HISTORY_LIMIT
            refreshScrollGeometry(scroll)
            self._compactCombatLogLayoutApplied = true
        end
        return result
    end
end

function EventWidget:AppendCombatLogHistoryEntry(entry)
    if type(entry) ~= "table" then
        return false
    end

    local eventId = tostring(entry.eventId or "")
    if eventId ~= "" and type(self.SyncCombatLogHistoryEvent) == "function" then
        self:SyncCombatLogHistoryEvent(eventId)
    end

    local history = type(self.GetCombatLogHistory) == "function" and self:GetCombatLogHistory() or nil
    if type(history) ~= "table" then
        return false
    end

    local copy = {}
    for key, value in pairs(entry) do
        copy[key] = value
    end
    history[#history + 1] = copy
    while #history > COMBAT_LOG_HISTORY_LIMIT do
        table.remove(history, 1)
    end

    if type(self.IsCombatLogHistoryPanelShown) == "function"
        and self:IsCombatLogHistoryPanelShown() == true
        and type(self.RefreshCombatLogHistoryPanel) == "function"
    then
        self:RefreshCombatLogHistoryPanel()
    end
    return true
end

local baseRefreshCombatLogHistoryPanel = EventWidget.RefreshCombatLogHistoryPanel
function EventWidget:RefreshCombatLogHistoryPanel(...)
    local result = baseRefreshCombatLogHistoryPanel(self, ...)
    if tostring(self.eventUtilityMode or "") == "combat-log"
        and type(self.combatLogUtilityScroll) == "table"
    then
        local sourceEntries = type(self.GetCombatLogHistoryViewEntries) == "function"
            and self:GetCombatLogHistoryViewEntries()
            or {}
        local entries = {}
        local firstIndex = math.max(1, #sourceEntries - COMBAT_LOG_HISTORY_LIMIT + 1)
        for index = firstIndex, #sourceEntries do
            entries[#entries + 1] = sourceEntries[index]
        end
        self.combatLogUtilityScroll:SetItems(entries)
        local emptyFrame = getFrame(self.combatLogUtilityEmptyText)
        if emptyFrame then
            if #entries == 0 and type(emptyFrame.Show) == "function" then
                emptyFrame:Show()
            elseif #entries > 0 and type(emptyFrame.Hide) == "function" then
                emptyFrame:Hide()
            end
        end
    end
    return result
end

function EventWidget:RefreshAutopilotDMHelperNow(eventStateOverride)
    local state = type(eventStateOverride) == "table" and eventStateOverride or getActiveEventState()
    if tostring(self.combatLogHistoryMode or "") ~= "dm-helper"
        or not isHostAutopilotEvent(state)
    then
        return false
    end

    self:EnsureAutopilotHelperUI()
    if self.combatLogHistoryTitle and type(self.combatLogHistoryTitle.SetText) == "function" then
        self.combatLogHistoryTitle:SetText("DM Helper")
    end

    local panelFrame = getFrame(self.combatLogHistoryPanel)
    if panelFrame and type(panelFrame.SetSize) == "function" then
        panelFrame:SetSize(DASHBOARD_PANEL_WIDTH, DASHBOARD_PANEL_HEIGHT)
    end
    setShown(self.autopilotDashboardFrame, true)
    setShown(self.combatLogHistoryScroll, false)
    setShown(self.combatLogHistoryEmptyText, false)
    setShown(self.dmHelperDetailPanel, false)
    return self:RefreshAutopilotHelperDashboard()
end

function Client:FlushAutopilotDMHelperRefresh(expectedEventId)
    RefreshState.pending = false
    RefreshState.job = nil

    local widget = getEventWidget()
    local state = getActiveEventState()
    if type(widget) ~= "table"
        or type(state) ~= "table"
        or tostring(state.id or "") ~= tostring(expectedEventId or "")
        or not isHostAutopilotEvent(state)
        or tostring(widget.combatLogHistoryMode or "") ~= "dm-helper"
        or type(widget.IsCombatLogHistoryPanelShown) ~= "function"
        or widget:IsCombatLogHistoryPanelShown() ~= true
        or type(widget.RefreshAutopilotDMHelperNow) ~= "function"
    then
        return false
    end

    return widget:RefreshAutopilotDMHelperNow(state)
end

function Client:QueueAutopilotDMHelperRefresh()
    local widget = getEventWidget()
    local state = getActiveEventState()
    if type(widget) ~= "table"
        or type(state) ~= "table"
        or not isHostAutopilotEvent(state)
        or tostring(widget.combatLogHistoryMode or "") ~= "dm-helper"
        or type(widget.IsCombatLogHistoryPanelShown) ~= "function"
        or widget:IsCombatLogHistoryPanelShown() ~= true
        or type(Tasks.Enqueue) ~= "function"
    then
        return false
    end

    RefreshState.eventId = tostring(state.id or "")
    if RefreshState.eventId == "" then
        return false
    end
    if RefreshState.pending == true then
        return true
    end

    RefreshState.pending = true
    RefreshState.job = Tasks:Enqueue(function()
        local expectedEventId = RefreshState.eventId
        Client:FlushAutopilotDMHelperRefresh(expectedEventId)
    end)
    return true
end

local originalRefreshCombatLogHistoryPanel = EventWidget.RefreshCombatLogHistoryPanel

function EventWidget:RefreshCombatLogHistoryPanel(...)
    local state = getActiveEventState()
    if tostring(self.combatLogHistoryMode or "") == "dm-helper" and isHostAutopilotEvent(state) then
        -- Opening the panel calls Refresh before the panel is shown. Render that
        -- first frame immediately; subsequent refresh requests are coalesced.
        if type(self.IsCombatLogHistoryPanelShown) ~= "function"
            or self:IsCombatLogHistoryPanelShown() ~= true
        then
            return self:RefreshAutopilotDMHelperNow(state)
        end
        if type(Client.QueueAutopilotDMHelperRefresh) == "function" then
            return Client:QueueAutopilotDMHelperRefresh()
        end
        return self:RefreshAutopilotDMHelperNow(state)
    end
    return originalRefreshCombatLogHistoryPanel(self, ...)
end

local originalRefreshAutopilotHelperControls = EventWidget.RefreshAutopilotHelperControls
if type(originalRefreshAutopilotHelperControls) == "function" then
    function EventWidget:RefreshAutopilotHelperControls(actionRowsOverride, markerStatesOverride)
        local result = originalRefreshAutopilotHelperControls(self, actionRowsOverride, markerStatesOverride)
        if self.autopilotAuthoriseAllButton and type(self.autopilotAuthoriseAllButton.SetEnabled) == "function" then
            local state = getActiveEventState()
            local pending = type(Client.GetAutopilotPendingPlan) == "function"
                and select(1, Client:GetAutopilotPendingPlan(state))
                or nil
            if type(pending) == "table" and pending.authorizeAllInProgress == true then
                self.autopilotAuthoriseAllButton:SetEnabled(false)
            end
        end
        return result
    end
end

-- The state-changing APIs already mark the helper dirty. The original UI
-- callbacks also forced a second synchronous panel refresh. Rebind the visible
-- controls so one canonical queued invalidation owns presentation updates.
local originalEnsureAutopilotHelperUI = EventWidget.EnsureAutopilotHelperUI
if type(originalEnsureAutopilotHelperUI) == "function" then
    function EventWidget:EnsureAutopilotHelperUI(...)
        local result = originalEnsureAutopilotHelperUI(self, ...)
        if self._autopilotPerformanceCallbacksInstalled == true then
            return result
        end
        if not self.autopilotDashboardFrame then
            return result
        end

        if self.autopilotSetPositionButton and type(self.autopilotSetPositionButton.SetScript) == "function" then
            self.autopilotSetPositionButton:SetScript("OnClick", function()
                local marker = math.floor(tonumber(self.selectedAutopilotMarker) or 0)
                if marker >= 1 and marker <= 8 and type(Client.SetAutopilotMarkerPositionHere) == "function" then
                    Client:SetAutopilotMarkerPositionHere(getActiveEventState(), marker)
                end
            end)
        end
        if self.autopilotAuthoriseAllButton and type(self.autopilotAuthoriseAllButton.SetScript) == "function" then
            self.autopilotAuthoriseAllButton:SetScript("OnClick", function()
                if type(Client.AuthorizeAllAutopilotPendingActions) == "function" then
                    Client:AuthorizeAllAutopilotPendingActions(getActiveEventState())
                end
            end)
        end
        if self.autopilotReplanButton and type(self.autopilotReplanButton.SetScript) == "function" then
            self.autopilotReplanButton:SetScript("OnClick", function()
                if type(Client.ReplanPendingAutopilotPlan) == "function" then
                    Client:ReplanPendingAutopilotPlan(getActiveEventState())
                    self.selectedAutopilotDetailKey = nil
                end
            end)
        end
        if self.autopilotSkipMovementButton and type(self.autopilotSkipMovementButton.SetScript) == "function" then
            self.autopilotSkipMovementButton:SetScript("OnClick", function()
                local selected = self:GetSelectedAutopilotHelperEntry()
                if type(selected) == "table"
                    and selected.actionType == "movement"
                    and selected.canSkip == true
                    and type(Client.SkipAutopilotPendingMovement) == "function"
                then
                    Client:SkipAutopilotPendingMovement(selected.actionId, getActiveEventState())
                end
            end)
        end

        local scroll = self.autopilotPendingScroll
        local baseRenderer = type(scroll) == "table" and scroll.rowRenderer or nil
        if type(scroll) == "table"
            and type(baseRenderer) == "function"
            and type(scroll.SetRowRenderer) == "function"
        then
            scroll:SetRowRenderer(function(row, item)
                baseRenderer(row, item)
                if type(row) ~= "table" then
                    return
                end
                if row.doneButton and type(row.doneButton.SetScript) == "function" then
                    row.doneButton:SetScript("OnClick", function()
                        local current = row.item
                        if type(current) == "table"
                            and current.canConfirm == true
                            and type(Client.ConfirmAutopilotPendingMovement) == "function"
                        then
                            Client:ConfirmAutopilotPendingMovement(current.actionId, getActiveEventState())
                        end
                    end)
                end
                if row.rejectButton and type(row.rejectButton.SetScript) == "function" then
                    row.rejectButton:SetScript("OnClick", function()
                        local current = row.item
                        if type(current) == "table"
                            and current.canReject == true
                            and type(Client.RejectAutopilotPendingAction) == "function"
                        then
                            Client:RejectAutopilotPendingAction(current.actionId, getActiveEventState())
                        end
                    end)
                end
                if row.authoriseButton and type(row.authoriseButton.SetScript) == "function" then
                    row.authoriseButton:SetScript("OnClick", function()
                        local current = row.item
                        if type(current) == "table"
                            and current.canAuthorize == true
                            and type(Client.AuthorizeAutopilotPendingAction) == "function"
                        then
                            Client:AuthorizeAutopilotPendingAction(current.actionId, getActiveEventState())
                        end
                    end)
                end
            end)
        end

        self._autopilotPerformanceCallbacksInstalled = true
        return result
    end
end

return true