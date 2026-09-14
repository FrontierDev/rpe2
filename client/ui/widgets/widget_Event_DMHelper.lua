local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local EventWidget = ClientUI.EventWidget

if type(EventWidget) ~= "table"
    or EventWidget._dmHelperExtensionInstalled == true
    or type(EventWidget.ShowCombatLogHistoryPanel) ~= "function"
then
    return true
end

local DM_HELPER_BUTTON_WIDTH = 90
local DM_HELPER_BUTTON_HEIGHT = 20
local DM_HELPER_PANEL_WIDTH = 520
local DM_HELPER_PANEL_HEIGHT = 420
local DM_HELPER_DETAIL_HEIGHT = 150
local DM_HELPER_DETAIL_GAP = 6
local DM_HELPER_DETAIL_TITLE_HEIGHT = 18

Client.DMHelperProviders = Client.DMHelperProviders or {}
Client.DMHelperProviderOrder = Client.DMHelperProviderOrder or {}

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

local function isLocalHostForEvent(state)
    if type(state) ~= "table" or state.active ~= true then
        return false
    end

    local server = Addon.Server
    if type(server) ~= "table" or type(server.IsActive) ~= "function" or server:IsActive() ~= true then
        return false
    end

    local serverEventState = server.EventState
    if type(serverEventState) ~= "table" or serverEventState.active ~= true then
        return false
    end
    if tostring(serverEventState.id or "") ~= ""
        and tostring(serverEventState.id or "") ~= tostring(state.id or "")
    then
        return false
    end

    return type(Client.IsLocalEventHost) == "function" and Client:IsLocalEventHost(state) == true
end

local function shallowCopy(entry)
    local copy = {}
    for key, value in pairs(type(entry) == "table" and entry or {}) do
        copy[key] = value
    end
    return copy
end

local function buildDMHelperText(entry)
    if type(entry) ~= "table" then
        return tostring(entry or "")
    end
    if tostring(entry.entryType or "") ~= "" and type(Client.BuildCombatLogDisplayText) == "function" then
        return Client:BuildCombatLogDisplayText(entry)
    end
    return tostring(entry.text or entry.message or entry.description or entry.label or "")
end

local function buildDMHelperSummary(entry)
    if type(entry) ~= "table" then
        return tostring(entry or "")
    end
    local summary = tostring(entry.summary or "")
    if summary ~= "" then
        return summary
    end
    return buildDMHelperText(entry)
end

local function buildDMHelperDetails(entry)
    if type(entry) ~= "table" then
        return tostring(entry or "")
    end
    local details = tostring(entry.details or "")
    if details ~= "" then
        return details
    end

    local text = buildDMHelperText(entry)
    local reasonText = tostring(entry.reasonText or "")
    local reasonCode = tostring(entry.reasonCode or "")
    if reasonText ~= "" and reasonText ~= text then
        text = text ~= "" and (text .. "\n\nReason: " .. reasonText) or ("Reason: " .. reasonText)
    end
    if reasonCode ~= "" and reasonCode ~= reasonText then
        text = text ~= "" and (text .. "\nReason code: " .. reasonCode) or ("Reason code: " .. reasonCode)
    end
    return text
end

local function getDMHelperEntryKey(entry)
    if type(entry) ~= "table" then
        return nil
    end
    local entryId = tostring(entry.entryId or "")
    if entryId ~= "" then
        return entryId
    end
    local actionId = tostring(entry.actionId or "")
    if actionId ~= "" then
        return "action:" .. actionId
    end
    return nil
end

local function buildButton(parentFrame, name, text, onClick)
    local button = UI.TextButton:New({
        name = name,
        width = DM_HELPER_BUTTON_WIDTH,
        height = DM_HELPER_BUTTON_HEIGHT,
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

function Client:RegisterDMHelperProvider(key, provider)
    local normalizedKey = tostring(key or "")
    if normalizedKey == "" or type(provider) ~= "function" then
        return false
    end

    if self.DMHelperProviders[normalizedKey] == nil then
        self.DMHelperProviderOrder[#self.DMHelperProviderOrder + 1] = normalizedKey
    end
    self.DMHelperProviders[normalizedKey] = provider
    return true
end

function Client:GetDMHelperEntries(eventStateOverride)
    local eventState = type(eventStateOverride) == "table"
        and eventStateOverride
        or getActiveEventState()
    if not isLocalHostForEvent(eventState) then
        return {}
    end

    local entries = {}
    local turnNumber = math.max(0, math.floor(tonumber(eventState.turnNumber) or 0))
    local widget = type(EventWidget.Get) == "function" and EventWidget:Get() or nil
    local history = type(widget) == "table" and type(widget.GetCombatLogHistory) == "function"
        and widget:GetCombatLogHistory()
        or {}
    for index = 1, #(history or {}) do
        local entry = history[index]
        if type(entry) == "table" and tonumber(entry.turnNumber) == turnNumber then
            local copied = shallowCopy(entry)
            copied.dmHelperSource = "combat-log"
            copied.entryId = ("combat-log:%s:%d:%d:%s"):format(
                tostring(eventState.id or ""),
                turnNumber,
                index,
                buildDMHelperText(copied)
            )
            entries[#entries + 1] = copied
        end
    end

    for index = 1, #(self.DMHelperProviderOrder or {}) do
        local key = self.DMHelperProviderOrder[index]
        local provider = self.DMHelperProviders[key]
        if type(provider) == "function" then
            local provided = provider(self, eventState)
            for providedIndex = 1, #(provided or {}) do
                local providedEntry = provided[providedIndex]
                if type(providedEntry) == "table" then
                    entries[#entries + 1] = providedEntry
                end
            end
        end
    end

    return entries
end

function EventWidget:ClearDMHelperSelection()
    self.selectedDMHelperEntryKey = nil
    self.selectedDMHelperActionId = nil
    self.selectedDMHelperEventId = nil
    return true
end

function EventWidget:GetSelectedDMHelperEntry(entriesOverride)
    local selectedKey = tostring(self.selectedDMHelperEntryKey or "")
    if selectedKey == "" then
        return nil
    end

    local state = getActiveEventState()
    if tostring(self.selectedDMHelperEventId or "") ~= tostring(type(state) == "table" and state.id or "") then
        self:ClearDMHelperSelection()
        return nil
    end

    local entries = type(entriesOverride) == "table"
        and entriesOverride
        or (type(Client.GetDMHelperEntries) == "function" and Client:GetDMHelperEntries(state) or {})
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        if tostring(getDMHelperEntryKey(entry) or "") == selectedKey then
            return entry, index
        end
    end

    self:ClearDMHelperSelection()
    return nil
end

function EventWidget:SelectDMHelperEntry(entry)
    local key = getDMHelperEntryKey(entry)
    if not key then
        return false
    end

    local state = getActiveEventState()
    self.selectedDMHelperEntryKey = key
    self.selectedDMHelperActionId = tostring(entry and entry.actionId or "") ~= ""
        and tostring(entry.actionId)
        or nil
    self.selectedDMHelperEventId = tostring(type(state) == "table" and state.id or "")

    if self.combatLogHistoryScroll and type(self.combatLogHistoryScroll.RefreshRows) == "function" then
        self.combatLogHistoryScroll:RefreshRows()
    end
    if type(self.RefreshDMHelperDetail) == "function" then
        self:RefreshDMHelperDetail()
    end
    if type(self.RefreshAutopilotHelperControls) == "function" then
        self:RefreshAutopilotHelperControls()
    end
    return true
end

function EventWidget:RefreshDMHelperDetail(entriesOverride)
    if not self.dmHelperDetailPanel or not self.dmHelperDetailScroll then
        return false
    end

    local helperMode = tostring(self.combatLogHistoryMode or "") == "dm-helper"
    setShown(self.dmHelperDetailPanel, helperMode)
    if not helperMode then
        return false
    end

    local selected = self:GetSelectedDMHelperEntry(entriesOverride)
    local title = "Details"
    local details = "Select a DM Helper row to inspect its full details."
    if type(selected) == "table" then
        title = buildDMHelperSummary(selected)
        details = buildDMHelperDetails(selected)
        if details == "" then
            details = "No additional details are available for this entry."
        end
    end

    if self.dmHelperDetailTitle and type(self.dmHelperDetailTitle.SetText) == "function" then
        self.dmHelperDetailTitle:SetText(title)
    end
    self.dmHelperDetailScroll:ClearMessages()
    self.dmHelperDetailScroll:AddMessage(details)

    local detailFrame = getFrame(self.dmHelperDetailScroll)
    if detailFrame and type(detailFrame.ScrollToTop) == "function" then
        detailFrame:ScrollToTop()
    end
    return true
end

function EventWidget:ConfigureDMHelperLayout(bottomInset)
    if not self.combatLogHistoryPanel or not self.combatLogHistoryScroll or not self.dmHelperDetailPanel then
        return false
    end
    if tostring(self.combatLogHistoryMode or "") ~= "dm-helper" then
        return false
    end

    self.dmHelperDetailBottomInset = math.max(0, tonumber(bottomInset) or 0)
    local panelFrame = getFrame(self.combatLogHistoryPanel)
    local contentFrame = self.combatLogHistoryPanel:GetContentFrame()
    local titleFrame = getFrame(self.combatLogHistoryTitle)
    local scrollFrame = getFrame(self.combatLogHistoryScroll)
    local detailFrame = getFrame(self.dmHelperDetailPanel)
    if not panelFrame or not contentFrame or not titleFrame or not scrollFrame or not detailFrame then
        return false
    end

    if self.autopilotDMHelperOwnsPanelSize ~= true and type(panelFrame.SetSize) == "function" then
        panelFrame:SetSize(DM_HELPER_PANEL_WIDTH, DM_HELPER_PANEL_HEIGHT)
    end

    detailFrame:ClearAllPoints()
    detailFrame:SetPoint("BOTTOMLEFT", contentFrame, "BOTTOMLEFT", 0, self.dmHelperDetailBottomInset)
    detailFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, self.dmHelperDetailBottomInset)
    detailFrame:SetHeight(DM_HELPER_DETAIL_HEIGHT)
    detailFrame:Show()

    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", detailFrame, "TOPRIGHT", 0, DM_HELPER_DETAIL_GAP)

    self.combatLogHistoryScroll.autoFitRows = true
    self.combatLogHistoryScroll.minVisibleRows = 1
    self.combatLogHistoryScroll.maxVisibleRows = nil
    if type(self.combatLogHistoryScroll.UpdateGeometry) == "function" then
        self.combatLogHistoryScroll:UpdateGeometry()
    end
    return true
end

function EventWidget:RestoreCombatLogHistoryLayout()
    if not self.combatLogHistoryPanel or not self.combatLogHistoryScroll then
        return false
    end

    local panelFrame = getFrame(self.combatLogHistoryPanel)
    local contentFrame = self.combatLogHistoryPanel:GetContentFrame()
    local titleFrame = getFrame(self.combatLogHistoryTitle)
    local scrollFrame = getFrame(self.combatLogHistoryScroll)
    if not panelFrame or not contentFrame or not titleFrame or not scrollFrame then
        return false
    end

    if self._dmHelperBasePanelWidth and self._dmHelperBasePanelHeight and type(panelFrame.SetSize) == "function" then
        panelFrame:SetSize(self._dmHelperBasePanelWidth, self._dmHelperBasePanelHeight)
    end
    setShown(self.dmHelperDetailPanel, false)

    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 0)
    self.combatLogHistoryScroll.autoFitRows = false
    self.combatLogHistoryScroll.visibleRows = self._dmHelperBaseVisibleRows or 8
    if type(self.combatLogHistoryScroll.EnsureVisibleRowCount) == "function" then
        self.combatLogHistoryScroll:EnsureVisibleRowCount()
    end
    if type(self.combatLogHistoryScroll.UpdateGeometry) == "function" then
        self.combatLogHistoryScroll:UpdateGeometry()
    end
    return true
end

function EventWidget:EnsureDMHelperUI()
    if self.dmHelperButton then
        return self.dmHelperButton
    end
    if type(self.EnsureCombatLogHistoryUI) ~= "function" then
        return nil
    end

    self:EnsureCombatLogHistoryUI()
    local buttonRowFrame = getFrame(self.combatLogHistoryButtonRow)
    if not buttonRowFrame then
        return nil
    end

    self.dmHelperButton = buildButton(
        buttonRowFrame,
        "RPEClientEventWidgetDMHelperButton",
        "DM Helper",
        function()
            local state = getActiveEventState()
            if not isLocalHostForEvent(state) then
                return
            end

            if type(self.IsCombatLogHistoryPanelShown) == "function"
                and self:IsCombatLogHistoryPanelShown() == true
                and tostring(self.combatLogHistoryMode or "") == "dm-helper"
            then
                self:HideCombatLogHistoryPanel()
                return
            end

            self:ShowCombatLogHistoryPanel("dm-helper")
        end
    )
    self.combatLogHistoryButtonRow:AddChild(self.dmHelperButton)
    setShown(self.dmHelperButton, false)

    local historyPanelFrame = getFrame(self.combatLogHistoryPanel)
    self._dmHelperBasePanelWidth = historyPanelFrame and historyPanelFrame:GetWidth() or 420
    self._dmHelperBasePanelHeight = historyPanelFrame and historyPanelFrame:GetHeight() or 270
    self._dmHelperBaseVisibleRows = self.combatLogHistoryScroll and self.combatLogHistoryScroll.visibleRows or 8
    self._dmHelperBaseRowRenderer = self.combatLogHistoryScroll and self.combatLogHistoryScroll.rowRenderer or nil

    local contentFrame = self.combatLogHistoryPanel:GetContentFrame()
    self.dmHelperDetailPanel = UI.CreatePanel(contentFrame, "RPEClientEventWidgetDMHelperDetailPanel", {
        height = DM_HELPER_DETAIL_HEIGHT,
        contentInset = 6,
        showBorder = true,
        panelBorderSize = 1,
        panelBorderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
    })
    local detailPanelFrame = getFrame(self.dmHelperDetailPanel)
    detailPanelFrame:Hide()

    local detailContent = self.dmHelperDetailPanel:GetContentFrame()
    self.dmHelperDetailTitle = UI.CreateText(detailContent, "RPEClientEventWidgetDMHelperDetailTitle", "Details", {
        height = DM_HELPER_DETAIL_TITLE_HEIGHT,
        fontSize = 10,
        fontFlags = "OUTLINE",
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    local detailTitleFrame = getFrame(self.dmHelperDetailTitle)
    detailTitleFrame:SetPoint("TOPLEFT", detailContent, "TOPLEFT", 0, 0)
    detailTitleFrame:SetPoint("TOPRIGHT", detailContent, "TOPRIGHT", 0, 0)

    self.dmHelperDetailScroll = UI.ScrollingMessageFrame:New({
        name = "RPEClientEventWidgetDMHelperDetailScroll",
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
    self.dmHelperDetailScroll:SetParent(detailContent)
    self.dmHelperDetailScroll:Create()
    local detailScrollFrame = getFrame(self.dmHelperDetailScroll)
    detailScrollFrame:SetPoint("TOPLEFT", detailTitleFrame, "BOTTOMLEFT", 0, -2)
    detailScrollFrame:SetPoint("BOTTOMRIGHT", detailContent, "BOTTOMRIGHT", 0, 0)
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

    self._dmHelperRowRenderer = function(row, item)
        local key = getDMHelperEntryKey(item)
        local selected = key ~= nil and key == tostring(self.selectedDMHelperEntryKey or "")
        local summary = buildDMHelperSummary(item)
        if row and type(row.SetText) == "function" then
            row:SetText((selected and "> " or "") .. summary)
        end
        if row and type(row.SetJustifyH) == "function" then
            row:SetJustifyH("LEFT")
        end
        if row and type(row.SetJustifyV) == "function" then
            row:SetJustifyV("MIDDLE")
        end
        if row and type(row.SetWordWrap) == "function" then
            row:SetWordWrap(false)
        end

        local rowFrame = getFrame(row)
        if rowFrame and type(rowFrame.EnableMouse) == "function" then
            rowFrame:EnableMouse(key ~= nil)
        end
        if rowFrame and type(rowFrame.SetScript) == "function" then
            if key ~= nil then
                rowFrame:SetScript("OnMouseUp", function(_, button)
                    if button == "LeftButton" and isLocalHostForEvent(getActiveEventState()) then
                        self:SelectDMHelperEntry(item)
                    end
                end)
            else
                rowFrame:SetScript("OnMouseUp", nil)
            end
        end
    end
    return self.dmHelperButton
end

function EventWidget:RefreshDMHelperHostVisibility()
    self:EnsureDMHelperUI()
    local host = isLocalHostForEvent(getActiveEventState())
    setShown(self.dmHelperButton, host)
    if not host then
        self:ClearDMHelperSelection()
        if tostring(self.combatLogHistoryMode or "") == "dm-helper" then
            self:HideCombatLogHistoryPanel()
        end
    end
    return host
end

local originalBuild = EventWidget.Build
local originalRefresh = EventWidget.Refresh
local originalShowCombatLogHistoryPanel = EventWidget.ShowCombatLogHistoryPanel
local originalGetCombatLogHistoryViewEntries = EventWidget.GetCombatLogHistoryViewEntries
local originalGetCombatLogHistoryViewTitle = EventWidget.GetCombatLogHistoryViewTitle
local originalRefreshCombatLogHistoryPanel = EventWidget.RefreshCombatLogHistoryPanel

function EventWidget:Build(...)
    local result = originalBuild(self, ...)
    self:EnsureDMHelperUI()
    self:RefreshDMHelperHostVisibility()
    return result
end

function EventWidget:Refresh(...)
    local result = originalRefresh(self, ...)
    self:EnsureDMHelperUI()
    self:RefreshDMHelperHostVisibility()
    return result
end

function EventWidget:ShowCombatLogHistoryPanel(mode)
    local normalizedMode = tostring(mode or "combat-log")
    if normalizedMode == "dm-helper" and not isLocalHostForEvent(getActiveEventState()) then
        return false
    end
    return originalShowCombatLogHistoryPanel(self, normalizedMode)
end

function EventWidget:GetCombatLogHistoryViewEntries()
    if tostring(self.combatLogHistoryMode or "") == "dm-helper" then
        local state = getActiveEventState()
        if not isLocalHostForEvent(state) then
            return {}
        end
        return type(Client.GetDMHelperEntries) == "function" and Client:GetDMHelperEntries(state) or {}
    end
    return originalGetCombatLogHistoryViewEntries(self)
end

function EventWidget:GetCombatLogHistoryViewTitle()
    if tostring(self.combatLogHistoryMode or "") == "dm-helper" then
        return "DM Helper"
    end
    return originalGetCombatLogHistoryViewTitle(self)
end

function EventWidget:RefreshCombatLogHistoryPanel()
    self:EnsureDMHelperUI()
    local helperMode = tostring(self.combatLogHistoryMode or "") == "dm-helper"
    local scroll = self.combatLogHistoryScroll

    if helperMode then
        local entries = self:GetCombatLogHistoryViewEntries() or {}
        if self.combatLogHistoryTitle and type(self.combatLogHistoryTitle.SetText) == "function" then
            self.combatLogHistoryTitle:SetText("DM Helper")
        end
        if scroll and type(scroll.SetRowRenderer) == "function"
            and scroll.rowRenderer ~= self._dmHelperRowRenderer
        then
            scroll:SetRowRenderer(self._dmHelperRowRenderer)
        end
        self:ConfigureDMHelperLayout(self.dmHelperDetailBottomInset or 0)
        if scroll and type(scroll.SetItems) == "function" then
            -- DM Helper is an operational view, not the last-eight combat history.
            -- Preserve every current helper/provider entry and let ScrollLayout page it.
            scroll:SetItems(entries)
        end

        local emptyFrame = getFrame(self.combatLogHistoryEmptyText)
        if emptyFrame then
            if #entries == 0 and type(emptyFrame.Show) == "function" then
                emptyFrame:Show()
            elseif #entries > 0 and type(emptyFrame.Hide) == "function" then
                emptyFrame:Hide()
            end
        end
        self:RefreshDMHelperDetail(entries)
        self:RefreshDMHelperHostVisibility()
        return true
    end

    self.dmHelperDetailBottomInset = 0
    self:RestoreCombatLogHistoryLayout()
    if scroll and type(scroll.SetRowRenderer) == "function" then
        local renderer = self._dmHelperBaseRowRenderer
        if renderer and scroll.rowRenderer ~= renderer then
            scroll:SetRowRenderer(renderer)
        end
    end

    local result = originalRefreshCombatLogHistoryPanel(self)
    self:RefreshDMHelperHostVisibility()
    return result
end

EventWidget._dmHelperExtensionInstalled = true
return true
