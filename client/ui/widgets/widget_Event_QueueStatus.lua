local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Client = Addon.Client
local EventWidget = Addon.Client.UI.EventWidget
local UI = Addon.UI or {}
local Queue = Addon.Internal.Comms.MessageQueue

if type(EventWidget) ~= "table" or EventWidget._queueStatusExtensionInstalled == true then
    return true
end

local INDICATOR_SIZE = 14
local INDICATOR_GAP = 6
local INDICATOR_REFRESH_INTERVAL = 0.25
local ORANGE_COLOR = { r = 1, g = 0.55, b = 0.12, a = 1 }

local function getFrame(element)
    if type(element) == "table" and type(element.GetFrame) == "function" then
        return element:GetFrame()
    end

    return element
end

local function getEventState()
    if type(Client.GetEventState) == "function" then
        return Client:GetEventState()
    end

    return Client.EventState
end

local function getNow()
    if type(GetTimePreciseSec) == "function" then
        return tonumber(GetTimePreciseSec()) or 0
    end
    if type(GetTime) == "function" then
        return tonumber(GetTime()) or 0
    end
    return 0
end

local function resolveColor(token, fallback)
    if type(UI.ResolveColor) == "function" then
        return UI.ResolveColor(nil, token, fallback)
    end

    return fallback
end

local function isLocalEventHost(state)
    if type(state) ~= "table" or state.active ~= true then
        return false
    end
    if type(Client.IsLocalEventHost) ~= "function" or Client:IsLocalEventHost(state) ~= true then
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

    local serverEventId = tostring(serverEventState.id or "")
    local clientEventId = tostring(state.id or "")
    return serverEventId == "" or serverEventId == clientEventId
end

local function getQueueStats()
    if type(Queue) ~= "table" or type(Queue.GetStats) ~= "function" then
        return {}
    end

    local ok, stats = pcall(Queue.GetStats, Queue)
    if ok and type(stats) == "table" then
        return stats
    end

    return {}
end

local function resolveQueuePresentation(stats)
    local reason = string.lower(tostring(type(stats) == "table" and stats.waitReason or "none"))
    local prefixBlockedUntil = math.max(0, tonumber(type(stats) == "table" and stats.prefixBlockedUntil) or 0)

    if reason == "channel-throttle" then
        return {
            key = "red",
            label = "Channel throttled",
            color = resolveColor("danger", { r = 0.95, g = 0.35, b = 0.35, a = 1 }),
        }
    end

    if reason == "prefix-throttle" or prefixBlockedUntil > getNow() then
        return {
            key = "red",
            label = "Addon message throttled",
            color = resolveColor("danger", { r = 0.95, g = 0.35, b = 0.35, a = 1 }),
        }
    end

    if reason == "allowance" then
        return {
            key = "orange",
            label = "Rate limited",
            color = ORANGE_COLOR,
        }
    end

    return {
        key = "green",
        label = "Normal",
        color = resolveColor("success", { r = 0.35, g = 0.9, b = 0.45, a = 1 }),
    }
end

local function formatAllowance(value)
    local numeric = tonumber(value)
    if numeric == nil then
        return "Unknown"
    end

    return ("%.1f"):format(numeric)
end

local function buildTooltipSpec(stats, presentation)
    stats = type(stats) == "table" and stats or {}
    presentation = presentation or resolveQueuePresentation(stats)
    local logicalMessages = math.max(0, math.floor(tonumber(stats.logicalMessageCount or stats.queueLength) or 0))
    local pendingChunks = math.max(0, math.floor(tonumber(stats.pendingChunkCount) or 0))
    local waitReason = tostring(stats.waitReason or "none")

    return {
        type = "custom",
        title = "Communications: " .. tostring(presentation.label or "Normal"),
        width = 250,
        lines = {
            { left = "Logical messages queued", right = tostring(logicalMessages) },
            { left = "Pending physical chunks", right = tostring(pendingChunks) },
            { left = "Estimated allowance", right = formatAllowance(stats.estimatedAllowance) },
            { left = "Wait reason", right = waitReason },
        },
    }
end

function EventWidget:StopQueueStatusRefresh()
    self.queueStatusRefreshGeneration = math.max(0, math.floor(tonumber(self.queueStatusRefreshGeneration) or 0)) + 1
    self.queueStatusRefreshActive = false

    local handle = self.queueStatusRefreshHandle
    self.queueStatusRefreshHandle = nil
    if type(handle) == "table" and type(handle.Cancel) == "function" then
        pcall(handle.Cancel, handle)
    end

    return true
end

function EventWidget:HideQueueStatusTooltip()
    if self.queueStatusTooltipVisible ~= true then
        return false
    end

    self.queueStatusTooltipVisible = false
    if type(UI.Tooltip) == "table" and type(UI.Tooltip.Hide) == "function" then
        UI.Tooltip:Hide()
    end
    return true
end

function EventWidget:ShowQueueStatusTooltip()
    local frame = self.queueStatusIndicatorFrame
    if not frame or type(UI.Tooltip) ~= "table" or type(UI.Tooltip.ShowForElement) ~= "function" then
        return false
    end

    self.queueStatusTooltipVisible = true
    local spec = buildTooltipSpec(self.queueStatusLastStats, self.queueStatusLastPresentation)
    UI.Tooltip:ShowForElement(frame, spec)
    return true
end

function EventWidget:EnsureQueueStatusIndicator()
    if self.queueStatusIndicatorFrame then
        return self.queueStatusIndicatorFrame
    end
    if not self.rootPanel or not self.headerBannerPanel or type(CreateFrame) ~= "function" then
        return nil
    end

    local rootFrame = getFrame(self.rootPanel)
    local headerBannerFrame = getFrame(self.headerBannerPanel)
    if not rootFrame or not headerBannerFrame then
        return nil
    end

    local frame = CreateFrame("Frame", "RPEClientEventWidgetQueueStatusIndicator", rootFrame)
    frame:SetSize(INDICATOR_SIZE, INDICATOR_SIZE)
    frame:SetPoint("LEFT", headerBannerFrame, "RIGHT", INDICATOR_GAP, 0)
    if type(frame.EnableMouse) == "function" then
        frame:EnableMouse(true)
    end
    if type(frame.SetFrameLevel) == "function" and type(rootFrame.GetFrameLevel) == "function" then
        frame:SetFrameLevel((tonumber(rootFrame:GetFrameLevel()) or 0) + 2)
    end

    local border = frame:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints(frame)
    border:SetTexture("Interface\\Buttons\\WHITE8x8")
    local borderColor = resolveColor("panel.border", { r = 0.18, g = 0.2, b = 0.25, a = 1 })
    border:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

    local fill = frame:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    fill:SetTexture("Interface\\Buttons\\WHITE8x8")

    frame:SetScript("OnEnter", function()
        self:ShowQueueStatusTooltip()
    end)
    frame:SetScript("OnLeave", function()
        self:HideQueueStatusTooltip()
    end)
    frame:SetScript("OnHide", function()
        self:HideQueueStatusTooltip()
        self:StopQueueStatusRefresh()
    end)
    frame:Hide()

    self.queueStatusIndicatorFrame = frame
    self.queueStatusIndicatorFill = fill
    self.queueStatusIndicatorBorder = border
    return frame
end

function EventWidget:RefreshQueueStatusIndicator()
    local frame = self:EnsureQueueStatusIndicator()
    if not frame then
        return false
    end

    local state = getEventState()
    local rootFrame = getFrame(self.rootPanel)
    local widgetVisible = rootFrame and type(rootFrame.IsShown) == "function" and rootFrame:IsShown() == true
    if not widgetVisible or not isLocalEventHost(state) then
        if type(frame.Hide) == "function" then
            frame:Hide()
        end
        self:StopQueueStatusRefresh()
        return false
    end

    local stats = getQueueStats()
    local presentation = resolveQueuePresentation(stats)
    local fill = self.queueStatusIndicatorFill
    if fill and type(fill.SetVertexColor) == "function" then
        local color = presentation.color or { r = 0.35, g = 0.9, b = 0.45, a = 1 }
        fill:SetVertexColor(color.r or 0, color.g or 0, color.b or 0, color.a or 1)
    end

    self.queueStatusLastStats = stats
    self.queueStatusLastPresentation = presentation
    self.queueStatusState = presentation.key

    if type(frame.Show) == "function" then
        frame:Show()
    end

    if self.queueStatusTooltipVisible == true
        and type(UI.Tooltip) == "table"
        and type(UI.Tooltip.RefreshForElement) == "function"
    then
        UI.Tooltip:RefreshForElement(frame, buildTooltipSpec(stats, presentation))
    end

    return true
end

local function scheduleFallbackRefresh(widget, generation)
    local function tick()
        if widget.queueStatusRefreshActive ~= true
            or tonumber(widget.queueStatusRefreshGeneration) ~= tonumber(generation)
        then
            return
        end

        widget.queueStatusRefreshHandle = nil
        if widget:RefreshQueueStatusIndicator() == true then
            scheduleFallbackRefresh(widget, generation)
        else
            widget:StopQueueStatusRefresh()
        end
    end

    if type(C_Timer) == "table" and type(C_Timer.NewTimer) == "function" then
        widget.queueStatusRefreshHandle = C_Timer.NewTimer(INDICATOR_REFRESH_INTERVAL, tick)
        return true
    end
    if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
        widget.queueStatusRefreshHandle = true
        C_Timer.After(INDICATOR_REFRESH_INTERVAL, tick)
        return true
    end

    widget.queueStatusRefreshActive = false
    widget.queueStatusRefreshHandle = nil
    return false
end

function EventWidget:StartQueueStatusRefresh()
    if self.queueStatusRefreshActive == true then
        return true
    end

    self.queueStatusRefreshGeneration = math.max(0, math.floor(tonumber(self.queueStatusRefreshGeneration) or 0)) + 1
    self.queueStatusRefreshActive = true
    local generation = self.queueStatusRefreshGeneration

    if type(C_Timer) == "table" and type(C_Timer.NewTicker) == "function" then
        local ticker = C_Timer.NewTicker(INDICATOR_REFRESH_INTERVAL, function()
            if self.queueStatusRefreshActive ~= true
                or tonumber(self.queueStatusRefreshGeneration) ~= tonumber(generation)
            then
                return
            end

            if self:RefreshQueueStatusIndicator() ~= true then
                self:StopQueueStatusRefresh()
            end
        end)
        if ticker then
            self.queueStatusRefreshHandle = ticker
            return true
        end
    end

    return scheduleFallbackRefresh(self, generation)
end

function EventWidget:UpdateQueueStatusIndicatorLifecycle()
    if self:RefreshQueueStatusIndicator() ~= true then
        return false
    end

    self:StartQueueStatusRefresh()
    return true
end

local originalBuild = EventWidget.Build
local originalShow = EventWidget.Show
local originalHide = EventWidget.Hide
local originalRefresh = EventWidget.Refresh

function EventWidget:Build(...)
    local result = originalBuild(self, ...)
    self:EnsureQueueStatusIndicator()
    return result
end

function EventWidget:Show(...)
    local result = originalShow(self, ...)
    self:UpdateQueueStatusIndicatorLifecycle()
    return result
end

function EventWidget:Hide(...)
    self:StopQueueStatusRefresh()
    self:HideQueueStatusTooltip()
    if self.queueStatusIndicatorFrame and type(self.queueStatusIndicatorFrame.Hide) == "function" then
        self.queueStatusIndicatorFrame:Hide()
    end
    return originalHide(self, ...)
end

function EventWidget:Refresh(...)
    local result = originalRefresh(self, ...)
    self:UpdateQueueStatusIndicatorLifecycle()
    return result
end

EventWidget._queueStatusExtensionInstalled = true
return true
