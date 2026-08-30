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

    self._dmHelperBaseRowRenderer = self.combatLogHistoryScroll and self.combatLogHistoryScroll.rowRenderer or nil
    self._dmHelperRowRenderer = function(row, item)
        if row and type(row.SetText) == "function" then
            row:SetText(buildDMHelperText(item))
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
    end
    return self.dmHelperButton
end

function EventWidget:RefreshDMHelperHostVisibility()
    self:EnsureDMHelperUI()
    local host = isLocalHostForEvent(getActiveEventState())
    setShown(self.dmHelperButton, host)
    if not host and tostring(self.combatLogHistoryMode or "") == "dm-helper" then
        self:HideCombatLogHistoryPanel()
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
    if scroll and type(scroll.SetRowRenderer) == "function" then
        local renderer = helperMode and self._dmHelperRowRenderer or self._dmHelperBaseRowRenderer
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
