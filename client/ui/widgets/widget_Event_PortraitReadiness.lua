local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local EventWidget = ClientUI.EventWidget

if type(EventWidget) ~= "table" or EventWidget._portraitReadinessExtensionInstalled == true then
    return true
end

local EVENT_LOG_BUTTON_ROW_BOTTOM_SPACING = 10

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

local function arePortraitsReady(state)
    return type(state) == "table"
        and state.active == true
        and state.unitsReady == true
        and state.startupReady == true
end

local function applyEventLogButtonRowSpacing(widget, state)
    if type(widget) ~= "table" or type(state) ~= "table" or state.active ~= true then
        return false
    end

    local buttonRowFrame = getFrame(widget.combatLogHistoryButtonRow)
    if not buttonRowFrame then
        return false
    end

    local contentFrame = arePortraitsReady(state)
        and getFrame(widget.portraitPanel)
        or getFrame(widget.waitingPanel)
    if not contentFrame then
        return false
    end

    contentFrame:ClearAllPoints()
    contentFrame:SetPoint(
        "TOP",
        buttonRowFrame,
        "BOTTOM",
        0,
        -EVENT_LOG_BUTTON_ROW_BOTTOM_SPACING
    )
    return true
end

function EventWidget:ApplyPortraitStartupVisibility(state, context)
    local ready = arePortraitsReady(state)
    local portraitHostFrame = getFrame(self.portraitPanel)
    local bossHostFrame = getFrame(self.bossPortraitPanel)
    local initiativeHostFrame = getFrame(self.initiativePortraitPanel)

    applyEventLogButtonRowSpacing(self, state)

    if not ready then
        if portraitHostFrame and portraitHostFrame.Hide then
            portraitHostFrame:Hide()
        end
        if bossHostFrame and bossHostFrame.Hide then
            bossHostFrame:Hide()
        end
        if initiativeHostFrame and initiativeHostFrame.Hide then
            initiativeHostFrame:Hide()
        end
        return false
    end

    if portraitHostFrame and portraitHostFrame.Show then
        portraitHostFrame:Show()
    end
    if initiativeHostFrame and initiativeHostFrame.Show then
        initiativeHostFrame:Show()
    end

    local bossUnits = type(context) == "table" and context.bossUnits or nil
    local hasBossUnits = type(bossUnits) == "table" and #bossUnits > 0
    if bossHostFrame then
        if hasBossUnits and bossHostFrame.Show then
            bossHostFrame:Show()
        elseif not hasBossUnits and bossHostFrame.Hide then
            bossHostFrame:Hide()
        end
    end

    return true
end

local originalBuildPortraitRefreshContext = EventWidget.BuildPortraitRefreshContext
local originalRefreshPortraitSlot = EventWidget.RefreshPortraitSlot
local originalRefreshPortraitsForEventIds = EventWidget.RefreshPortraitsForEventIds
local originalRefresh = EventWidget.Refresh

function EventWidget:BuildPortraitRefreshContext(state)
    local context = originalBuildPortraitRefreshContext(self, state)
    if type(context) == "table" then
        context.portraitsReady = arePortraitsReady(state)
    end
    return context
end

function EventWidget:RefreshPortraitSlot(index, eventUnit, state, context, options)
    context = type(context) == "table" and context or self:BuildPortraitRefreshContext(state)
    local portraitsReady = type(context) == "table" and context.portraitsReady == true

    if not portraitsReady then
        eventUnit = nil
    end

    return originalRefreshPortraitSlot(self, index, eventUnit, state, context, options)
end

function EventWidget:RefreshPortraitsForEventIds(eventIds, reason)
    local result = originalRefreshPortraitsForEventIds(self, eventIds, reason)
    local state = getEventState()
    local context = type(state) == "table" and self:BuildPortraitRefreshContext(state) or nil
    self:ApplyPortraitStartupVisibility(state, context)
    return result
end

function EventWidget:Refresh(...)
    local result = originalRefresh(self, ...)
    local state = getEventState()
    local context = type(state) == "table" and self:BuildPortraitRefreshContext(state) or nil
    self:ApplyPortraitStartupVisibility(state, context)
    return result
end

-- Issue #182: the final startup structural refresh used to execute every visible
-- portrait/model update inside one normal TaskQueue job after the transition
-- timer had already stopped. Keep the canonical EventWidget rendering methods,
-- but drive the expensive portrait portion through a resumable continuation.
local Tasks = Addon.Internal and Addon.Internal.Tasks or {}
local Debug = Addon.Debug or {}
local startupBaseRefreshEventWidget = Client.RefreshEventWidget
local startupBaseRefreshEventWidgetPortraits = Client.RefreshEventWidgetPortraits
local startupBaseHideEventWidget = Client.HideEventWidget
local startupBaseBuildPortraitRefreshContext = EventWidget.BuildPortraitRefreshContext
local startupBaseRefreshPortraitSlot = EventWidget.RefreshPortraitSlot

Client.EventWidgetStartupStructuralRefreshGeneration = math.max(
    0,
    math.floor(tonumber(Client.EventWidgetStartupStructuralRefreshGeneration) or 0)
)
Client.EventWidgetStartupStructuralRefreshRuntime = nil
Client.EventWidgetStartupStructuralRefreshJob = nil

local function getStartupRefreshNowMilliseconds()
    if type(debugprofilestop) == "function" then
        return tonumber(debugprofilestop()) or 0
    end
    if type(GetTimePreciseSec) == "function" then
        return (tonumber(GetTimePreciseSec()) or 0) * 1000
    end
    if type(GetTime) == "function" then
        return (tonumber(GetTime()) or 0) * 1000
    end
    return 0
end

local function isStartupRefreshTimingEnabled()
    local timings = Debug.Timings
    return type(Debug.Internal) == "function"
        and type(timings) == "table"
        and (type(timings.IsEnabled) ~= "function" or timings:IsEnabled() == true)
end

local function shouldYieldStartupRefresh(deadlineMs)
    return deadlineMs ~= nil
        and type(Tasks.ShouldYield) == "function"
        and Tasks:ShouldYield(deadlineMs) == true
end

local function recordStartupRefreshSlice(work, startedAtMs, yielded)
    if type(work) ~= "table" then
        return 0
    end
    local elapsedMs = math.max(0, getStartupRefreshNowMilliseconds() - (tonumber(startedAtMs) or 0))
    work.maxSliceMs = math.max(tonumber(work.maxSliceMs) or 0, elapsedMs)
    if yielded == true then
        work.yields = math.max(0, math.floor(tonumber(work.yields) or 0)) + 1
    end
    return elapsedMs
end

local function isFinalStartupRefresh(reason, eventState)
    if type(eventState) ~= "table" or eventState.active ~= true or eventState.startupReady ~= true then
        return false
    end
    return string.find(tostring(reason or ""), "startup-ready", 1, true) ~= nil
end

local function mergeStartupRefreshEventIds(target, eventIds)
    target = type(target) == "table" and target or {}
    if type(eventIds) ~= "table" then
        return target
    end

    for key, value in pairs(eventIds) do
        local candidate = value == true and key or (type(key) == "number" and value or key)
        local numericId = tonumber(candidate) or 0
        if numericId > 0 then
            target[numericId] = true
        end
    end
    for index = 1, #eventIds do
        local numericId = tonumber(eventIds[index]) or 0
        if numericId > 0 then
            target[numericId] = true
        end
    end
    return target
end

local function restoreStartupRefreshRawMethod(target, key, previousValue)
    if previousValue == nil then
        target[key] = nil
    else
        target[key] = previousValue
    end
end

local function finalizeStartupStructuralRefresh(work)
    local widget = work and work.widget or nil
    if type(widget) ~= "table" then
        return false
    end

    local previousRefreshPortraitSlot = rawget(widget, "RefreshPortraitSlot")
    local previousBuildPortraitRefreshContext = rawget(widget, "BuildPortraitRefreshContext")

    -- Run the canonical final layout/header/control refresh, but do not repeat
    -- the portraits already rendered by the continuation.
    widget.RefreshPortraitSlot = function()
        return true
    end
    widget.BuildPortraitRefreshContext = function()
        return work.context
    end

    local ok, result = xpcall(function()
        return startupBaseRefreshEventWidget(Client, work.reason)
    end, function(message)
        return tostring(message)
    end)

    restoreStartupRefreshRawMethod(widget, "RefreshPortraitSlot", previousRefreshPortraitSlot)
    restoreStartupRefreshRawMethod(widget, "BuildPortraitRefreshContext", previousBuildPortraitRefreshContext)

    if not ok then
        error(result, 0)
    end
    return result == true
end

local function stepStartupStructuralRefresh(work, deadlineMs)
    work.slices = math.max(0, math.floor(tonumber(work.slices) or 0)) + 1
    local sliceStartedAtMs = getStartupRefreshNowMilliseconds()

    while true do
        if work.phase == "build" then
            -- Build() is idempotent; by startup-ready the waiting-state widget
            -- normally already exists, so this avoids reconstructing its tree.
            work.widget:Build()
            work.phase = "show"
        elseif work.phase == "show" then
            work.widget:Show()
            work.phase = "context"
        elseif work.phase == "context" then
            work.context = startupBaseBuildPortraitRefreshContext(work.widget, work.eventState)
            if type(work.context) ~= "table" then
                error("Event Widget startup refresh could not build portrait context.")
            end
            work.maxEventUnits = math.max(1, math.floor(tonumber(work.context.maxEventUnits) or 1))
            work.pageUnits = type(work.context.pageUnits) == "table" and work.context.pageUnits or {}
            work.bossUnits = type(work.context.bossUnits) == "table" and work.context.bossUnits or {}
            work.totalSlots = work.maxEventUnits + #work.bossUnits
            work.phase = "ensure-normal"
        elseif work.phase == "ensure-normal" then
            if work.normalEnsureIndex <= work.maxEventUnits then
                work.widget:EnsurePortraitSlot(work.normalEnsureIndex)
                work.normalEnsureIndex = work.normalEnsureIndex + 1
            else
                work.phase = "ensure-boss"
            end
        elseif work.phase == "ensure-boss" then
            if work.bossEnsureIndex <= #work.bossUnits then
                work.widget:EnsureBossPortraitSlot(work.bossEnsureIndex)
                work.bossEnsureIndex = work.bossEnsureIndex + 1
            else
                work.phase = "refresh-boss"
            end
        elseif work.phase == "refresh-boss" then
            if work.bossRefreshIndex <= #work.bossUnits then
                local index = work.bossRefreshIndex
                startupBaseRefreshPortraitSlot(work.widget, index, work.bossUnits[index], work.eventState, work.context, {
                    ensureSlot = work.widget.EnsureBossPortraitSlot,
                    currentKeys = work.widget.bossCurrentKeys,
                    currentVisualKeys = work.widget.bossCurrentVisualKeys,
                })
                work.bossRefreshIndex = index + 1
            else
                work.phase = "refresh-normal"
            end
        elseif work.phase == "refresh-normal" then
            if work.normalRefreshIndex <= work.maxEventUnits then
                local index = work.normalRefreshIndex
                startupBaseRefreshPortraitSlot(
                    work.widget,
                    index,
                    work.pageUnits[index] or nil,
                    work.eventState,
                    work.context
                )
                work.normalRefreshIndex = index + 1
            else
                work.phase = "finalize"
            end
        elseif work.phase == "finalize" then
            finalizeStartupStructuralRefresh(work)
            work.phase = "complete"
        elseif work.phase == "complete" then
            recordStartupRefreshSlice(work, sliceStartedAtMs, false)
            return true
        else
            error(("Unknown Event Widget startup refresh phase '%s'."):format(tostring(work.phase)))
        end

        if shouldYieldStartupRefresh(deadlineMs) then
            recordStartupRefreshSlice(work, sliceStartedAtMs, true)
            return false
        end
    end
end

local function logStartupStructuralRefresh(work, outcome, reason)
    if not isStartupRefreshTimingEnabled() or type(work) ~= "table" then
        return
    end

    Debug.Internal(
        "Event widget startup refresh complete event=%s slots=%d slices=%d yields=%d maxSlice=%.2fms wall=%.2fms outcome=%s reason=%s",
        tostring(work.eventId or ""),
        math.max(0, math.floor(tonumber(work.totalSlots) or 0)),
        math.max(0, math.floor(tonumber(work.slices) or 0)),
        math.max(0, math.floor(tonumber(work.yields) or 0)),
        math.max(0, tonumber(work.maxSliceMs) or 0),
        math.max(0, getStartupRefreshNowMilliseconds() - (tonumber(work.startedAtMs) or getStartupRefreshNowMilliseconds())),
        tostring(outcome or "unknown"),
        tostring(reason or "")
    )
end

local function clearStartupStructuralRuntimeIfCurrent(work)
    if Client.EventWidgetStartupStructuralRefreshRuntime ~= work then
        return false
    end
    Client.EventWidgetStartupStructuralRefreshRuntime = nil
    Client.EventWidgetStartupStructuralRefreshJob = nil
    return true
end

local function cancelStartupStructuralRefresh(reason)
    local job = Client.EventWidgetStartupStructuralRefreshJob
    if type(job) == "table" and type(Tasks.Cancel) == "function" then
        return Tasks:Cancel(job, reason or "cancelled") == true
    end

    Client.EventWidgetStartupStructuralRefreshRuntime = nil
    Client.EventWidgetStartupStructuralRefreshJob = nil
    return false
end

local function queueStartupStructuralRefresh(targetClient, reason, eventState)
    if type(Tasks.EnqueueSliceable) ~= "function"
        or type(Tasks.ShouldYield) ~= "function"
        or type(startupBaseBuildPortraitRefreshContext) ~= "function"
        or type(startupBaseRefreshPortraitSlot) ~= "function"
    then
        return startupBaseRefreshEventWidget(targetClient, reason)
    end

    local transitionGeneration = math.max(0, math.floor(tonumber(targetClient.EventTransitionGeneration) or 0))
    local existing = targetClient.EventWidgetStartupStructuralRefreshRuntime
    if type(existing) == "table"
        and existing.eventState == eventState
        and tonumber(existing.transitionGeneration) == transitionGeneration
    then
        existing.reason = tostring(reason or existing.reason or "startup-ready")
        return true
    end

    if type(existing) == "table" then
        cancelStartupStructuralRefresh("event-replaced")
    end

    targetClient.EventWidgetStartupStructuralRefreshGeneration = math.max(
        0,
        math.floor(tonumber(targetClient.EventWidgetStartupStructuralRefreshGeneration) or 0)
    ) + 1
    local generation = targetClient.EventWidgetStartupStructuralRefreshGeneration
    local work = {
        client = targetClient,
        widget = EventWidget:Get(),
        eventState = eventState,
        eventId = tostring(eventState.id or ""),
        generation = generation,
        transitionGeneration = transitionGeneration,
        reason = tostring(reason or "startup-ready"),
        phase = "build",
        normalEnsureIndex = 1,
        bossEnsureIndex = 1,
        normalRefreshIndex = 1,
        bossRefreshIndex = 1,
        pendingTargetEventIds = {},
        pendingTargetReason = nil,
        slices = 0,
        yields = 0,
        maxSliceMs = 0,
        totalSlots = 0,
        startedAtMs = getStartupRefreshNowMilliseconds(),
    }

    local job = Tasks:EnqueueSliceable({
        label = ("EventWidget.StartupRefresh event=%s"):format(work.eventId),
        scope = "event-widget:" .. work.eventId,
        state = work,
        isStale = function(current)
            local currentEventState = getEventState()
            return type(currentEventState) ~= "table"
                or currentEventState.active ~= true
                or currentEventState.startupReady ~= true
                or currentEventState ~= current.eventState
                or tostring(currentEventState.id or "") ~= tostring(current.eventId or "")
                or math.max(0, math.floor(tonumber(current.client and current.client.EventTransitionGeneration) or 0))
                    ~= math.max(0, math.floor(tonumber(current.transitionGeneration) or 0))
                or tonumber(current.generation) ~= tonumber(
                    current.client and current.client.EventWidgetStartupStructuralRefreshGeneration
                )
        end,
        step = stepStartupStructuralRefresh,
        onCancel = function(current, cancelReason)
            clearStartupStructuralRuntimeIfCurrent(current)
            logStartupStructuralRefresh(current, "cancelled", cancelReason)
        end,
        onComplete = function(current)
            local wasCurrent = clearStartupStructuralRuntimeIfCurrent(current)
            logStartupStructuralRefresh(current, "completed", "")
            if wasCurrent
                and type(startupBaseRefreshEventWidgetPortraits) == "function"
                and next(type(current.pendingTargetEventIds) == "table" and current.pendingTargetEventIds or {}) ~= nil
            then
                startupBaseRefreshEventWidgetPortraits(
                    current.client,
                    current.pendingTargetEventIds,
                    current.pendingTargetReason or "startup-followup"
                )
            end
        end,
    })

    if type(job) ~= "table" then
        return startupBaseRefreshEventWidget(targetClient, reason)
    end

    targetClient.EventWidgetStartupStructuralRefreshRuntime = work
    targetClient.EventWidgetStartupStructuralRefreshJob = job
    return true
end

function Client:RefreshEventWidget(reason)
    local eventState = getEventState()
    if isFinalStartupRefresh(reason, eventState) then
        return queueStartupStructuralRefresh(self, reason, eventState)
    end

    local runtime = self.EventWidgetStartupStructuralRefreshRuntime
    if type(runtime) == "table" then
        -- A newer full refresh for the same ready event must not fall back to
        -- the old synchronous all-portrait path while the startup continuation
        -- is live. Restart the bounded continuation against the current state.
        if runtime.eventState == eventState
            and type(eventState) == "table"
            and eventState.active == true
            and eventState.startupReady == true
        then
            cancelStartupStructuralRefresh("superseded-full-refresh")
            return queueStartupStructuralRefresh(self, reason, eventState)
        end
        cancelStartupStructuralRefresh("superseded-full-refresh")
    end
    return startupBaseRefreshEventWidget(self, reason)
end

function Client:RefreshEventWidgetPortraits(eventIds, reason)
    local runtime = self.EventWidgetStartupStructuralRefreshRuntime
    local eventState = getEventState()
    if type(runtime) == "table" and runtime.eventState == eventState then
        runtime.pendingTargetEventIds = mergeStartupRefreshEventIds(runtime.pendingTargetEventIds, eventIds)
        runtime.pendingTargetReason = tostring(reason or runtime.pendingTargetReason or "startup-followup")
        return true
    end
    return startupBaseRefreshEventWidgetPortraits(self, eventIds, reason)
end

if type(startupBaseHideEventWidget) == "function" then
    function Client:HideEventWidget(...)
        if type(self.EventWidgetStartupStructuralRefreshRuntime) == "table" then
            cancelStartupStructuralRefresh("event-widget-hidden")
        end
        return startupBaseHideEventWidget(self, ...)
    end
end

EventWidget._portraitReadinessExtensionInstalled = true
return true
