local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}
Addon.Internal = Addon.Internal or {}

local Server = Addon.Server
local EventManage = Addon.Server.UI.EventManage or {}
local Autopilot = Addon.Internal.Autopilot or {}
local UI = Addon.UI or {}

local WARNING_TEXT = "NPC Autopilot does not work in instances. Use Manual mode in dungeons, raids, battlegrounds and arenas."
local CONTROL_HEIGHT = 20

local function normalizeTurnMode(value)
    if type(Autopilot.NormalizeTurnMode) == "function" then
        return Autopilot.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end

local function setElementVisible(element, visible, height)
    if not element then
        return
    end

    local resolvedHeight = visible and math.max(0, tonumber(height) or 0) or 0
    if element.SetHeight then
        element:SetHeight(resolvedHeight)
    end
    local frame = element.GetFrame and element:GetFrame() or nil
    if frame and frame.SetHeight then
        frame:SetHeight(resolvedHeight)
    end
    if frame and frame.SetShown then
        frame:SetShown(visible == true)
    elseif frame then
        if visible then
            frame:Show()
        else
            frame:Hide()
        end
    end
end

local function showStartFailure(message)
    local normalized = tostring(message or "")
    if normalized == "" then
        return false
    end

    local popup = UI.Popup
    if type(popup) == "table" and type(popup.ShowConfirmation) == "function" then
        popup:ShowConfirmation({
            message = normalized,
            confirmText = "OK",
            cancelText = "Close",
            onConfirm = function() end,
        })
        return true
    end

    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
        DEFAULT_CHAT_FRAME:AddMessage(normalized)
        return true
    end

    return false
end

local baseBuildSettingsPage = EventManage.BuildSettingsPage
function EventManage:BuildSettingsPage(page)
    local root = baseBuildSettingsPage and baseBuildSettingsPage(self, page) or nil
    if not root or self.EventTurnModeRow then
        return root
    end

    local layout = self.Layout or {}
    local settingsWidth = layout.PageContentWidth or 480

    self.EventTurnModeRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEServerEventManageSettingsTurnModeRow", {
        width = settingsWidth,
        height = CONTROL_HEIGHT,
        spacing = 6,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })

    self.EventTurnModeLabel = UI.CreateText(self.EventTurnModeRow:GetFrame(), "RPEServerEventManageSettingsTurnModeLabel", "NPC Control", {
        width = 72,
        height = CONTROL_HEIGHT,
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.EventTurnModeRow:AddChild(self.EventTurnModeLabel)

    self.EventTurnModeDropdown = UI.CreateDropdown(self.EventTurnModeRow:GetFrame(), "RPEServerEventManageSettingsTurnModeDropdown", {
        width = 140,
        height = CONTROL_HEIGHT,
        items = {
            { label = "Manual", value = "manual" },
            { label = "NPC Autopilot", value = "autopilot" },
        },
        selectedValue = "manual",
        onValueChanged = function(value)
            if Server.IsEventActive and Server:IsEventActive() then
                self:RefreshSettingsPage()
                return
            end
            self:CommitEventSettings(function(eventState)
                eventState.turnMode = normalizeTurnMode(value)
            end)
        end,
    })
    self.EventTurnModeRow:AddChild(self.EventTurnModeDropdown)
    root:AddChild(self.EventTurnModeRow)

    self.EventAutopilotWarningText = UI.CreateText(root:GetFrame(), "RPEServerEventManageSettingsAutopilotWarning", WARNING_TEXT, {
        width = settingsWidth,
        height = 0,
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "warning"),
    })
    root:AddChild(self.EventAutopilotWarningText)

    self:RefreshSettingsPage()
    return root
end

local baseRefreshSettingsPage = EventManage.RefreshSettingsPage
function EventManage:RefreshSettingsPage()
    if baseRefreshSettingsPage then
        baseRefreshSettingsPage(self)
    end

    local eventState = self.GetEditableSettingsState and self:GetEditableSettingsState() or nil
    local turnMode = normalizeTurnMode(eventState and eventState.turnMode)

    if self.EventTurnModeDropdown and self.EventTurnModeDropdown.SetSelectedValue then
        self.EventTurnModeDropdown:SetSelectedValue(turnMode, true)
    end
    if self.EventTurnModeDropdown and self.EventTurnModeDropdown.SetEnabled then
        local eventActive = Server.IsEventActive and Server:IsEventActive() == true
        self.EventTurnModeDropdown:SetEnabled(not eventActive)
    end

    setElementVisible(self.EventAutopilotWarningText, turnMode == "autopilot", 30)
    if self.SettingsRootLayout and self.SettingsRootLayout.RefreshLayout then
        self.SettingsRootLayout:RefreshLayout()
    end
end

local baseBuildDashboardPage = EventManage.BuildDashboardPage
function EventManage:BuildDashboardPage(page)
    local root = baseBuildDashboardPage and baseBuildDashboardPage(self, page) or nil
    if not root or not self.StartEventButton or self.StartEventButton._npcAutopilotStartWrapped == true then
        return root
    end

    self.StartEventButton._npcAutopilotStartWrapped = true
    self.StartEventButton:SetScript("OnClick", function()
        local eventState, reason = nil, nil
        if Server.StartEvent then
            eventState, reason = Server:StartEvent({})
        end
        if eventState == nil and tostring(reason or "") ~= "" then
            showStartFailure(reason)
        end
        if EventManage.RefreshDashboard then
            EventManage:RefreshDashboard()
        end
    end)

    return root
end
