local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local EventWidget = ClientUI.EventWidget

if type(EventWidget) ~= "table" or EventWidget._combatLogHistoryExtensionInstalled == true then
    return true
end

local HISTORY_LIMIT = 8
local HISTORY_BUTTON_WIDTH = 90
local HISTORY_BUTTON_HEIGHT = 20
local HISTORY_PANEL_WIDTH = 420
local HISTORY_PANEL_HEIGHT = 270
local HISTORY_PANEL_GAP = 8
local HISTORY_PANEL_INSET = 8
local HISTORY_TITLE_HEIGHT = 18
local HISTORY_ROW_HEIGHT = 27
local HISTORY_ROW_SPACING = 1

local function getActiveEventState()
    if type(Client.GetEventState) == "function" then
        return Client:GetEventState()
    end

    return Client.EventState
end

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

local function shallowCopyEntry(entry)
    local copy = {}
    for key, value in pairs(entry or {}) do
        copy[key] = value
    end
    return copy
end

local function buildCombatLogText(entry)
    if type(Client.BuildCombatLogDisplayText) == "function" then
        return Client:BuildCombatLogDisplayText(entry)
    end

    return ""
end

local function buildHistoryButton(parentFrame, name, text, onClick)
    local tabBackgroundColor = UI.ResolveColor(nil, "tab.bar")
    local tabHoverColor = UI.ResolveColor(nil, "panel.background")
    local tabPressedColor = UI.ResolveColor(nil, "window.headerBackground")
    local tabLabelColor = UI.ResolveColor(nil, "tab.inactive")
    local tabBorderColor = UI.ResolveColor(nil, "panel.border")
    local button = UI.TextButton:New({
        name = name,
        width = HISTORY_BUTTON_WIDTH,
        height = HISTORY_BUTTON_HEIGHT,
        text = text,
        fontSize = 9,
        fontFlags = "OUTLINE",
        labelColor = tabLabelColor,
        hoverLabelColor = UI.ResolveColor(nil, "text.primary"),
        pressedLabelColor = UI.ResolveColor(nil, "text.primary"),
        backgroundColor = tabBackgroundColor,
        hoverColor = tabHoverColor,
        pressedColor = tabPressedColor,
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
        button.leftBorder:SetColorTexture(
            tabBorderColor.r,
            tabBorderColor.g,
            tabBorderColor.b,
            tabBorderColor.a
        )

        button.rightBorder = frame:CreateTexture(nil, "ARTWORK")
        button.rightBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        button.rightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        button.rightBorder:SetWidth(1)
        button.rightBorder:SetColorTexture(
            tabBorderColor.r,
            tabBorderColor.g,
            tabBorderColor.b,
            tabBorderColor.a
        )
    end

    return button
end

function EventWidget:GetCombatLogHistory()
    self.combatLogHistory = self.combatLogHistory or {}
    return self.combatLogHistory
end

function EventWidget:GetCombatLogHistoryViewEntries()
    return self:GetCombatLogHistory()
end

function EventWidget:GetCombatLogHistoryViewTitle()
    return "Combat Log"
end

function EventWidget:IsCombatLogHistoryPanelShown()
    return isFrameShown(self.combatLogHistoryPanel)
end

function EventWidget:HideCombatLogHistoryPanel()
    local frame = getFrame(self.combatLogHistoryPanel)
    if frame and frame.Hide then
        frame:Hide()
    end
    return true
end

function EventWidget:ResetCombatLogHistory(eventId, reason)
    self.combatLogHistory = {}
    self.combatLogHistoryEventId = tostring(eventId or "")
    self.lastCombatLogHistoryResetReason = reason
    self:HideCombatLogHistoryPanel()

    if self.combatLogHistoryScroll and self.combatLogHistoryScroll.SetItems then
        self.combatLogHistoryScroll:SetItems({})
    end
    if self.combatLogHistoryEmptyText and self.combatLogHistoryEmptyText.SetText then
        self.combatLogHistoryEmptyText:SetText("No event messages yet.")
    end
    return true
end

function EventWidget:SyncCombatLogHistoryEvent(eventId)
    local normalizedEventId = tostring(eventId or "")
    local currentEventId = tostring(self.combatLogHistoryEventId or "")
    if currentEventId == normalizedEventId then
        return false
    end

    self:ResetCombatLogHistory(normalizedEventId, "event-changed")
    return true
end

function EventWidget:AppendCombatLogHistoryEntry(entry)
    if type(entry) ~= "table" then
        return false
    end

    local eventId = tostring(entry.eventId or "")
    if eventId ~= "" then
        self:SyncCombatLogHistoryEvent(eventId)
    end

    local history = self:GetCombatLogHistory()
    history[#history + 1] = shallowCopyEntry(entry)
    while #history > HISTORY_LIMIT do
        table.remove(history, 1)
    end

    if self:IsCombatLogHistoryPanelShown() then
        self:RefreshCombatLogHistoryPanel()
    end
    return true
end

function EventWidget:RefreshCombatLogHistoryPanel()
    if not self.combatLogHistoryPanel or not self.combatLogHistoryScroll then
        return false
    end

    local entries = {}
    local sourceEntries = self:GetCombatLogHistoryViewEntries() or {}
    for index = 1, math.min(#sourceEntries, HISTORY_LIMIT) do
        entries[#entries + 1] = sourceEntries[index]
    end

    if self.combatLogHistoryTitle and self.combatLogHistoryTitle.SetText then
        self.combatLogHistoryTitle:SetText(self:GetCombatLogHistoryViewTitle())
    end
    if self.combatLogHistoryScroll.SetItems then
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
    return true
end

function EventWidget:ShowCombatLogHistoryPanel(mode)
    self:EnsureCombatLogHistoryUI()
    self.combatLogHistoryMode = tostring(mode or "combat-log")
    self:RefreshCombatLogHistoryPanel()

    local frame = getFrame(self.combatLogHistoryPanel)
    if frame and frame.Show then
        frame:Show()
        return true
    end
    return false
end

function EventWidget:ToggleCombatLogHistoryPanel()
    if self:IsCombatLogHistoryPanelShown() and tostring(self.combatLogHistoryMode or "combat-log") == "combat-log" then
        return self:HideCombatLogHistoryPanel()
    end

    return self:ShowCombatLogHistoryPanel("combat-log")
end

function EventWidget:EnsureCombatLogHistoryUI()
    if self.combatLogHistoryPanel then
        return self.combatLogHistoryPanel
    end
    if not self.rootPanel or not self.headerBannerPanel then
        return nil
    end

    local rootFrame = getFrame(self.rootPanel)
    local headerBannerFrame = getFrame(self.headerBannerPanel)
    if not rootFrame or not headerBannerFrame then
        return nil
    end

    self.combatLogHistory = self.combatLogHistory or {}
    self.combatLogHistoryMode = self.combatLogHistoryMode or "combat-log"

    self.combatLogHistoryButtonRow = UI.CreateLayout(
        UI.HorizontalLayoutGroup,
        rootFrame,
        "RPEClientEventWidgetHistoryButtonRow",
        {
            spacing = 4,
            autoSize = true,
            fitChildrenWidth = false,
            fitChildrenHeight = false,
        }
    )
    local buttonRowFrame = self.combatLogHistoryButtonRow:GetFrame()
    buttonRowFrame:SetPoint("TOP", headerBannerFrame, "BOTTOM", 0, -4)

    self.combatLogHistoryButton = buildHistoryButton(
        buttonRowFrame,
        "RPEClientEventWidgetCombatLogHistoryButton",
        "Combat Log",
        function()
            self:ToggleCombatLogHistoryPanel()
        end
    )
    self.combatLogHistoryButtonRow:AddChild(self.combatLogHistoryButton)

    self.combatLogHistoryPanel = UI.CreatePanel(rootFrame, "RPEClientEventWidgetCombatLogHistoryPanel", {
        width = HISTORY_PANEL_WIDTH,
        height = HISTORY_PANEL_HEIGHT,
        contentInset = HISTORY_PANEL_INSET,
        showBorder = true,
        panelBorderSize = 1,
        panelBorderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
    })
    local historyPanelFrame = self.combatLogHistoryPanel:GetFrame()
    historyPanelFrame:SetPoint("TOPLEFT", rootFrame, "TOPRIGHT", HISTORY_PANEL_GAP, 0)
    historyPanelFrame:Hide()

    local contentFrame = self.combatLogHistoryPanel:GetContentFrame()
    self.combatLogHistoryTitle = UI.CreateText(contentFrame, "RPEClientEventWidgetCombatLogHistoryTitle", "Combat Log", {
        height = HISTORY_TITLE_HEIGHT,
        fontSize = 11,
        fontFlags = "OUTLINE",
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    local titleFrame = self.combatLogHistoryTitle:GetFrame()
    titleFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 2, 0)
    titleFrame:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", -2, 0)

    self.combatLogHistoryScroll = UI.ScrollLayout:New({
        name = "RPEClientEventWidgetCombatLogHistoryScroll",
        width = HISTORY_PANEL_WIDTH - (HISTORY_PANEL_INSET * 2),
        height = HISTORY_PANEL_HEIGHT - HISTORY_TITLE_HEIGHT - (HISTORY_PANEL_INSET * 2) - 4,
        visibleRows = HISTORY_LIMIT,
        rowHeight = HISTORY_ROW_HEIGHT,
        rowSpacing = HISTORY_ROW_SPACING,
        border = false,
        rowElementClass = UI.Text,
        rowFontSize = 10,
        rowFontFlags = "OUTLINE",
        rowWordWrap = false,
        rowInsetLeft = 2,
        rowInsetRight = 2,
        contentInsetLeft = 0,
        contentInsetRight = 0,
        contentInsetTop = 0,
        contentInsetBottom = 0,
    })
    self.combatLogHistoryScroll:SetParent(contentFrame)
    self.combatLogHistoryScroll:SetRowRenderer(function(row, item)
        if row and row.SetText then
            row:SetText(buildCombatLogText(item))
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
    end)
    self.combatLogHistoryScroll:Create()
    local scrollFrame = self.combatLogHistoryScroll:GetFrame()
    scrollFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 0)

    self.combatLogHistoryEmptyText = UI.CreateText(contentFrame, "RPEClientEventWidgetCombatLogHistoryEmpty", "No event messages yet.", {
        fontSize = 10,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.muted"),
    })
    local emptyFrame = self.combatLogHistoryEmptyText:GetFrame()
    emptyFrame:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    emptyFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)

    self:RefreshCombatLogHistoryPanel()
    return self.combatLogHistoryPanel
end

local originalBuild = EventWidget.Build
local originalHide = EventWidget.Hide
local originalRefresh = EventWidget.Refresh
local originalQueueCombatLogEntry = EventWidget.QueueCombatLogEntry
local originalClearCombatLogTicker = EventWidget.ClearCombatLogTicker

function EventWidget:Build(...)
    local result = originalBuild(self, ...)
    self:EnsureCombatLogHistoryUI()
    return result
end

function EventWidget:Hide(...)
    self:HideCombatLogHistoryPanel()
    return originalHide(self, ...)
end

function EventWidget:Refresh(...)
    local state = getActiveEventState()
    if type(state) == "table" and state.active == true then
        self:SyncCombatLogHistoryEvent(state.id)
    else
        self:ResetCombatLogHistory("", "event-inactive")
    end

    local result = originalRefresh(self, ...)
    if type(state) == "table" and state.active == true then
        self:EnsureCombatLogHistoryUI()
        self:RefreshCombatLogHistoryPanel()
    end
    return result
end

function EventWidget:QueueCombatLogEntry(entry)
    local logKind = tostring(type(entry) == "table" and entry.logKind or "")
    local shouldRetainInHistory = logKind ~= "aura_loss"

    local accepted = originalQueueCombatLogEntry(self, entry)
    if accepted == true and shouldRetainInHistory then
        self:AppendCombatLogHistoryEntry(entry)
    end
    return accepted
end

function EventWidget:ClearCombatLogTicker(reason)
    local result = originalClearCombatLogTicker(self, reason)
    if tostring(reason or "") ~= "hide" then
        self:ResetCombatLogHistory("", reason or "clear")
    end
    return result
end

EventWidget._combatLogHistoryExtensionInstalled = true
return true
