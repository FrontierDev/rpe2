local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Client = Addon.Client
local Debug = Addon.Debug
local Common = Addon.Utils.Common
local Commands = Addon.Commands
local Comms = Addon.Internal.Comms
local Event = Addon.Internal.Database.Classes.Event
local ResourceSync = Addon.Internal.Comms and Addon.Internal.Comms.ResourceSync or {}
local EventUnit = Addon.Internal.Database.Classes.EventUnit
local Runtime = Addon.Internal.Runtime or {}

local function getTimings()
    return Addon.Debug and Addon.Debug.Timings or nil
end

local function startTiming(label, thresholdMs, context)
    local timings = getTimings()
    if timings and type(timings.Start) == "function" then
        if type(timings.IsEnabled) == "function" and not timings:IsEnabled() then
            return nil
        end
        return timings:Start(label, {
            thresholdMs = thresholdMs,
            context = context,
        })
    end
    return nil
end

local function stopTiming(timer, cardinality)
    if not timer then
        return nil
    end

    local timings = getTimings()
    if timings and type(timings.Stop) == "function" then
        return timings:Stop(timer, { cardinality = cardinality })
    end

    return nil
end

local function isTimingsEnabled()
    local timings = getTimings()
    return timings
        and type(timings.IsEnabled) == "function"
        and timings:IsEnabled() == true
end

local function countList(value)
    return type(value) == "table" and #value or 0
end

local function countMap(value)
    local count = 0
    if type(value) == "table" then
        for _ in pairs(value) do
            count = count + 1
        end
    end
    return count
end

local function getActiveEventCardinality(client, eventState)
    if type(client) ~= "table" or type(eventState) ~= "table" then
        return 0, 0
    end

    local eventId = tostring(eventState.id or "")
    local spellcasting = client.Spellcasting
    local castBuckets = spellcasting and spellcasting.ActiveSpellcastsByEventId or client.ActiveSpellcastsByEventId
    local auraBuckets = spellcasting and spellcasting.ActiveAurasByEventId or client.ActiveAurasByEventId
    local castBucket = type(castBuckets) == "table" and castBuckets[eventId] or nil
    local auraBucket = type(auraBuckets) == "table" and auraBuckets[eventId] or nil
    if type(auraBucket) == "table" and type(auraBucket.byKey) == "table" then
        auraBucket = auraBucket.byKey
    end
    return countMap(castBucket), countMap(auraBucket)
end

local function getTimingNowMilliseconds()
    if not isTimingsEnabled() then
        return 0
    end

    local timings = getTimings()
    return type(timings) == "table" and type(timings.GetNowMilliseconds) == "function"
        and timings.GetNowMilliseconds()
        or 0
end

local function logTimingParts(label, context, parts, totalElapsedMs, thresholdMs)
    local timings = getTimings()
    if type(timings) == "table" and type(timings.LogParts) == "function" then
        return timings:LogParts(label, context, parts, totalElapsedMs, thresholdMs)
    end

    return false
end

local function appendTimingPart(parts, label, startedAtMs, thresholdMs)
    if type(parts) ~= "table" or startedAtMs == nil then
        return
    end

    parts[#parts + 1] = {
        label = label,
        elapsedMs = getTimingNowMilliseconds() - startedAtMs,
        thresholdMs = thresholdMs,
    }
end

local function stopEventTiming(timer, eventState, cardinality)
    if not timer then
        return nil
    end

    cardinality = cardinality or {}
    cardinality.eventUnits = type(eventState) == "table" and countList(eventState.units) or 0
    return stopTiming(timer, cardinality)
end

local function stopTransitionPhaseTiming(transition, timer, eventState, cardinality, label)
    local elapsedMs = stopEventTiming(timer, eventState, cardinality)
    if type(transition) == "table" and elapsedMs ~= nil then
        transition.phaseTimings = transition.phaseTimings or {}
        transition.phaseTimings[#transition.phaseTimings + 1] = {
            label = tostring(label or cardinality and cardinality.startupPhase or cardinality and cardinality.teardownPhase or "phase"),
            elapsedMs = elapsedMs,
            thresholdMs = tonumber(timer and timer.thresholdMs) or 8,
        }
    end
    return elapsedMs
end

local function recordTransitionSlice(transition, startedAtMs, label)
    if type(transition) ~= "table" or tonumber(startedAtMs) == nil or tonumber(startedAtMs) <= 0 then
        return nil
    end

    local elapsedMs = math.max(0, getTimingNowMilliseconds() - startedAtMs)
    transition.lastSliceElapsedMs = elapsedMs
    transition.maxSliceElapsedMs = math.max(tonumber(transition.maxSliceElapsedMs) or 0, elapsedMs)
    transition.maxSliceLabel = label or transition.maxSliceLabel
    return elapsedMs
end

local function getInline()
    return Addon.UI and Addon.UI.Inline or nil
end

local function getSound()
    return Addon.Core and Addon.Core.Sound or nil
end

local function getUI()
    return Addon.UI or nil
end

local function coerceEventUnitBoolean(value, defaultValue)
    local eventUnitClass = Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.EventUnit
        or nil
    if eventUnitClass and eventUnitClass.CoerceBoolean then
        return eventUnitClass.CoerceBoolean(value, defaultValue)
    end

    if value == nil then
        return defaultValue == true
    end

    if value == true or value == false then
        return value
    end

    local numericValue = tonumber(value)
    if numericValue ~= nil then
        return numericValue ~= 0
    end

    if type(value) == "string" then
        local normalized = string.lower(value)
        if normalized == "true" or normalized == "yes" or normalized == "on" then
            return true
        end
        if normalized == "false" or normalized == "no" or normalized == "off" then
            return false
        end
    end

    return defaultValue == true
end

Client.EventState = Client.EventState or nil
Client.EventTransition = Client.EventTransition or nil
Client.EventTransitionGeneration = tonumber(Client.EventTransitionGeneration) or 0
Client.LastEventEndReason = Client.LastEventEndReason or nil
Client.EventWidgetRefreshQueued = Client.EventWidgetRefreshQueued or false
Client.EventStartupRuntimeByEventId = Client.EventStartupRuntimeByEventId or {}
Client.ControlledEventUnitId = Client.ControlledEventUnitId or nil
Client.TurnEndPending = Client.TurnEndPending or false
Client.PendingTurnCommit = Client.PendingTurnCommit or nil
Client.TurnCommitGeneration = math.max(0, math.floor(tonumber(Client.TurnCommitGeneration) or 0))
Client.LastTurnCommit = Client.LastTurnCommit or nil
Client.EventUnitInteractionMarkers = Client.EventUnitInteractionMarkers or {}
Client.LastLocalInteractionMarker = Client.LastLocalInteractionMarker or nil

local function refreshEventManageDashboard()
    local server = Addon.Server
    local eventManage = type(server) == "table" and server.UI and server.UI.EventManage or nil
    if type(eventManage) ~= "table"
        or type(eventManage.IsWindowVisible) ~= "function"
        or eventManage:IsWindowVisible() ~= true
        or type(eventManage.IsDashboardPageActive) ~= "function"
        or eventManage:IsDashboardPageActive() ~= true
        or type(eventManage.RefreshDashboard) ~= "function"
    then
        return false
    end

    return eventManage:RefreshDashboard() == true
end

local EVENT_STARTUP_STEP_COUNT = 9

local function getTransitionGeneration(client)
    return math.max(0, math.floor(tonumber(client and client.EventTransitionGeneration) or 0))
end

function Client:BeginEventTransition(kind, eventId, transaction)
    self.EventTransitionGeneration = getTransitionGeneration(self) + 1
    local normalizedKind = tostring(kind or "starting")
    local normalizedEventId = tostring(eventId or "")
    local totalLabel = normalizedKind == "ending"
        and "Event end total transition"
        or "Event start total transition"
    local transition = {
        kind = normalizedKind,
        eventId = normalizedEventId,
        transactionId = type(transaction) == "table" and transaction.id or nil,
        transaction = transaction,
        phase = normalizedKind == "ending" and "ending" or "starting",
        generation = self.EventTransitionGeneration,
        revision = self.EventTransitionGeneration,
        eventState = self.EventState,
        startedAtMs = getTimingNowMilliseconds(),
        totalTimer = startTiming(totalLabel, 16, normalizedEventId),
        phaseTimings = {},
        lastSliceElapsedMs = 0,
        maxSliceElapsedMs = 0,
        maxSliceLabel = nil,
    }
    if type(transition.eventState) == "table" then
        transition.eventState.transitionPhase = transition.phase
    end
    self.EventTransition = transition
    refreshEventManageDashboard()
    return transition
end

function Client:IsEventTransitionCurrent(eventId, generation, kind, eventState)
    local transition = self.EventTransition
    if type(transition) ~= "table" then
        return false
    end
    if eventId ~= nil and tostring(transition.eventId or "") ~= tostring(eventId or "") then
        return false
    end
    if generation ~= nil and tonumber(transition.generation) ~= tonumber(generation) then
        return false
    end
    if kind ~= nil and transition.kind ~= kind then
        return false
    end
    if eventState ~= nil and transition.eventState ~= eventState then
        return false
    end
    return true
end

function Client:SetEventTransitionPhase(phase, eventState)
    local transition = self.EventTransition
    if type(transition) ~= "table" then
        return false
    end
    if eventState ~= nil and transition.eventState ~= eventState then
        return false
    end
    transition.phase = tostring(phase or transition.phase or "starting")
    if type(eventState) == "table" then
        eventState.transitionPhase = transition.phase
    end
    return true
end

function Client:EndEventTransition(eventId, generation, eventState, reason)
    local transition = self.EventTransition
    if not self:IsEventTransitionCurrent(eventId, generation, nil, eventState) then
        return false
    end
    if transition.totalTimer then
        stopEventTiming(transition.totalTimer, eventState, {
            transitionKind = transition.kind,
            transitionPhase = transition.phase,
            transitionGeneration = transition.generation,
            transitionReason = reason,
        })
        transition.totalTimer = nil
    end
    if type(transition.eventState) == "table" then
        transition.eventState.transitionPhase = nil
    end
    transition.eventState = nil
    transition.transaction = nil
    self.EventTransition = nil
    refreshEventManageDashboard()
    return true
end

function Client:CanPerformEventAction(eventState, actionKind)
    local state = eventState or self:GetEventState()
    if type(state) ~= "table" or state.active ~= true or state.ending == true then
        return false, "event-inactive"
    end

    local transition = self.EventTransition
    if type(transition) == "table"
        and (transition.eventState == state or tostring(transition.eventId or "") == tostring(state.id or ""))
    then
        return false, transition.kind == "ending" and "event-ending" or "event-starting"
    end
    if state.startupReady ~= true then
        return false, "event-startup"
    end
    if tostring(actionKind or "") == "advance-event-step"
        and type(self.PendingTurnCommit) == "table"
        and self.PendingTurnCommit.status == "pending"
    then
        return false, "turn-commit-pending"
    end
    return true
end

local function getEventStartupRuntime(client, eventId, createIfMissing)
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId == "" then
        return nil
    end

    client.EventStartupRuntimeByEventId = client.EventStartupRuntimeByEventId or {}
    local runtime = client.EventStartupRuntimeByEventId[normalizedEventId]
    if runtime or not createIfMissing then
        return runtime
    end

    runtime = {
        queued = false,
        startupStateReceived = false,
        actionBarPrimed = false,
        visualGate = "",
        traitRuntimeRefreshed = false,
        automaticAurasSynced = false,
        eventAurasSynced = false,
        resolvedStateRefreshed = false,
        resourceSyncQueued = false,
        consumablesQueued = false,
        consumablePromptPending = false,
        transitionGeneration = nil,
        eventState = nil,
        achievementStartIdentity = nil,
    }
    client.EventStartupRuntimeByEventId[normalizedEventId] = runtime
    return runtime
end

local function resetEventStartupRuntime(client, eventId)
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId == "" then
        return false
    end

    client.EventStartupRuntimeByEventId = client.EventStartupRuntimeByEventId or {}
    local existed = client.EventStartupRuntimeByEventId[normalizedEventId] ~= nil
    client.EventStartupRuntimeByEventId[normalizedEventId] = nil
    return existed
end

local function getStartupProgressReceived(runtime)
    if type(runtime) ~= "table" then
        return 0
    end

    local completed = 0
    if runtime.startupStateReceived == true then
        completed = completed + 1
    end
    if runtime.actionBarPrimed == true then
        completed = completed + 1
    end
    if runtime.traitRuntimeRefreshed == true then
        completed = completed + 1
    end
    if runtime.automaticAurasSynced == true then
        completed = completed + 1
    end
    if runtime.eventAurasSynced == true then
        completed = completed + 1
    end
    if runtime.resolvedStateRefreshed == true then
        completed = completed + 1
    end
    if runtime.consumablesQueued == true then
        completed = completed + 1
    end
    if runtime.resourceSyncQueued == true then
        completed = completed + 1
    end
    if runtime.phase == "ready" then
        completed = completed + 1
    end

    return completed
end

local function setEventStartupPhase(eventState, runtime, phase)
    if type(eventState) ~= "table" then
        return false
    end

    local normalizedPhase = tostring(phase or "starting")
    eventState.startupPhase = normalizedPhase
    if type(runtime) == "table" then
        runtime.phase = normalizedPhase
    end
    eventState.startupProgressExpected = EVENT_STARTUP_STEP_COUNT
    eventState.startupProgressReceived = getStartupProgressReceived(runtime)
    eventState.startupReady = normalizedPhase == "ready"
    return true
end

local function refreshEventStartupPhase(eventState, runtime)
    if type(eventState) ~= "table" then
        return false
    end

    if eventState.startupReady == true then
        return setEventStartupPhase(eventState, runtime, "ready")
    end
    local readiness = type(ResourceSync.GetEventReadinessState) == "function"
        and ResourceSync.GetEventReadinessState(eventState)
        or nil
    if type(readiness) ~= "table" or readiness.rosterComplete ~= true then
        return setEventStartupPhase(eventState, runtime, "waiting-units")
    end
    if type(runtime) ~= "table" or runtime.startupStateReceived ~= true then
        return setEventStartupPhase(eventState, runtime, "apply-validate-state")
    end

    if runtime.actionBarPrimed ~= true then
        return setEventStartupPhase(eventState, runtime, "action-bar-metadata")
    end
    if runtime.traitRuntimeRefreshed ~= true then
        return setEventStartupPhase(eventState, runtime, "trait-runtime")
    end
    if runtime.automaticAurasSynced ~= true then
        return setEventStartupPhase(eventState, runtime, "automatic-auras")
    end
    if runtime.eventAurasSynced ~= true then
        return setEventStartupPhase(eventState, runtime, "event-auras")
    end
    if runtime.resolvedStateRefreshed ~= true then
        return setEventStartupPhase(eventState, runtime, "resolved-trait")
    end
    if runtime.resourceSyncQueued ~= true then
        return setEventStartupPhase(eventState, runtime, "resource-sync")
    end
    if type(readiness) ~= "table" or readiness.resourcesReady ~= true then
        return setEventStartupPhase(eventState, runtime, "waiting-resources")
    end
    if runtime.consumablesQueued ~= true then
        return setEventStartupPhase(eventState, runtime, "consumable-prompts")
    end
    return setEventStartupPhase(eventState, runtime, "ready")
end

local function isEventStartupPending(eventState)
    return type(eventState) == "table"
        and eventState.active == true
        and (eventState.unitsReady ~= true or eventState.startupReady ~= true)
end

local function hasLocalSessionMemberForStartup(sessionState)
    if type(sessionState) ~= "table" or type(sessionState.membersByName) ~= "table" then
        return false
    end
    local playerName = Common.GetPlayerName and Common.GetPlayerName() or nil
    playerName = Common.NormalizeName and Common.NormalizeName(playerName) or playerName
    return type(playerName) == "string" and playerName ~= "" and sessionState.membersByName[playerName] ~= nil
end

local function getMovementTracker()
    return type(RPE) == "table" and type(RPE.Core) == "table" and type(RPE.Core.Movement) == "table" and RPE.Core.Movement or nil
end

local function refreshActionBarBars(reason)
    if type(Client.QueueActionBarCompanionBarsRefresh) == "function" then
        Client:QueueActionBarCompanionBarsRefresh(reason)
        return
    end

    if type(Client.RefreshActionBarCompanionBars) == "function" then
        Client:RefreshActionBarCompanionBars(reason)
    end
end

local function queueSharedEventVisualRefresh(client, reason, options)
    if type(client) ~= "table" then
        return false
    end

    local totalStartTime = getTimingNowMilliseconds()
    local timingParts = totalStartTime > 0 and {} or nil
    options = type(options) == "table" and options or {}
    local refreshed = false
    local normalizedReason = tostring(reason or "event")

    local eventStartTime = timingParts and getTimingNowMilliseconds() or nil
    if options.eventWidget ~= false and type(client.QueueEventWidgetRefresh) == "function" then
        refreshed = client:QueueEventWidgetRefresh(normalizedReason) or refreshed
    end
    appendTimingPart(timingParts, "event-widget", eventStartTime, 10)

    if options.targeting ~= false then
        local targetingStartTime = timingParts and getTimingNowMilliseconds() or nil
        if type(client.QueueTargetingWidgetRefresh) == "function" then
            refreshed = client:QueueTargetingWidgetRefresh(normalizedReason) or refreshed
        elseif type(client.RefreshTargetingWidget) == "function" then
            refreshed = client:RefreshTargetingWidget(normalizedReason) or refreshed
        end
        appendTimingPart(timingParts, "targeting", targetingStartTime, 10)
    end

    if options.actionBar ~= false then
        local actionBarStartTime = timingParts and getTimingNowMilliseconds() or nil
        if type(client.QueueActionBarRefresh) == "function" then
            refreshed = client:QueueActionBarRefresh(normalizedReason) or refreshed
        elseif type(client.RefreshActionBarWidget) == "function" then
            refreshed = client:RefreshActionBarWidget(normalizedReason) or refreshed
        else
            refreshActionBarBars(normalizedReason)
        end
        appendTimingPart(timingParts, "action-bar", actionBarStartTime, 10)
    elseif options.companionBars == true then
        local companionStartTime = timingParts and getTimingNowMilliseconds() or nil
        refreshActionBarBars(normalizedReason)
        appendTimingPart(timingParts, "companion-bars", companionStartTime, 10)
    end

    if timingParts then
        logTimingParts(
            tostring(normalizedReason),
            "event-visual-enqueue",
            timingParts,
            getTimingNowMilliseconds() - totalStartTime,
            15
        )
    end

    return refreshed
end

local function emitChatLine(line)
    local output = tostring(line or "")

    local function emit()
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(output)
            return
        end

        if print then
            print(output)
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, emit)
        return
    end

    emit()
end

local function getColorHex(token, fallback)
    local UI = getUI()
    local color = UI and type(UI.ResolveColor) == "function" and UI.ResolveColor(nil, token, fallback) or fallback
    local r = math.max(0, math.min(255, math.floor(((color and color.r) or 1) * 255 + 0.5)))
    local g = math.max(0, math.min(255, math.floor(((color and color.g) or 1) * 255 + 0.5)))
    local b = math.max(0, math.min(255, math.floor(((color and color.b) or 1) * 255 + 0.5)))
    return ("%02x%02x%02x"):format(r, g, b)
end

local function getEventDisplayName(eventState)
    if type(eventState) ~= "table" then
        return "Active Event"
    end

    local eventName = tostring(eventState.name or eventState.title or eventState.id or "Active Event")
    if eventName == "" then
        return "Active Event"
    end

    return eventName
end

local function getTurnAnnouncementIconMarkup()
    local Inline = getInline()
    local spec = Inline and type(Inline.GetSpec) == "function" and Inline:GetSpec("RPE") or nil
    local texture = spec and tostring(spec.texture or spec.file or spec.path or "") or ""
    if texture == "" then
        return Inline and type(Inline.Get) == "function" and Inline:Get("RPE", 14, 14) or ""
    end

    return ("|T%s:14:14:0:0|t"):format(texture)
end

local function emitTurnStartAnnouncement(eventState)
    local turnNumber = math.max(1, tonumber(eventState and eventState.turnNumber) or 1)
    local icon = getTurnAnnouncementIconMarkup()
    local eventName = getEventDisplayName(eventState)
    local prefix = icon ~= "" and (icon .. " ") or ""
    emitChatLine(("|cffffff00%s%s: Turn %d|r"):format(prefix, eventName, turnNumber))
end

local function emitLocalTurnStartAnnouncement()
    local icon = getTurnAnnouncementIconMarkup()
    local prefix = icon ~= "" and (icon .. " ") or ""
    local hex = getColorHex("text.secondary", { r = 0.8, g = 0.82, b = 0.88, a = 1 })
    emitChatLine(("|cff%s%sYour turn begins.|r"):format(hex, prefix))
end

local function playEventStartSound()
    local sound = getSound()
    if type(sound) == "table" and type(sound.PlayEventStartCue) == "function" then
        return sound:PlayEventStartCue()
    end

    if type(PlaySound) == "function" then
        PlaySound(567438)
        return true
    end

    return false
end

local function playLocalTurnStartSound()
    local sound = getSound()
    if type(sound) == "table" and type(sound.PlayLocalTurnStartCue) == "function" then
        return sound:PlayLocalTurnStartCue()
    end

    if type(PlaySound) == "function" then
        PlaySound(567416)
        return true
    end

    return false
end

local function bumpEventTooltipContextRevision(eventState, casterEventId)
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(builder) == "table" and type(builder.BumpEventTooltipContextRevision) == "function" then
        builder.BumpEventTooltipContextRevision(eventState and eventState.id or nil, casterEventId)
    end
end

local function bumpAllEventTooltipContextRevisions(eventState)
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(builder) == "table" and type(builder.BumpEventTooltipContextRevisionForAllUnits) == "function" then
        builder.BumpEventTooltipContextRevisionForAllUnits(eventState)
    end
end

local function syncMovementTracking(client, wasLocalTurn, eventState, previousTurnNumber, previousTickNumber)
    local tracker = getMovementTracker()
    if not tracker then
        return false
    end

    local isLocalTurn = client.IsLocalTurnActive and client:IsLocalTurnActive(eventState) or false
    if isLocalTurn and wasLocalTurn ~= true then
        if type(tracker.OnPlayerTurnStart) == "function" then
            tracker:OnPlayerTurnStart()
        end
        if not isEventStartupPending(eventState) then
            queueSharedEventVisualRefresh(client, "local-turn-start", {
                eventWidget = false,
                targeting = false,
                actionBar = true,
            })
        end
        return true
    end

    if wasLocalTurn == isLocalTurn then
        if isLocalTurn and type(tracker.RefreshMaxDistance) == "function" then
            tracker:RefreshMaxDistance()
        end
        return false
    end

    if type(tracker.OnPlayerTurnEnd) == "function" then
        tracker:OnPlayerTurnEnd()
    end
    if not isEventStartupPending(eventState) then
        queueSharedEventVisualRefresh(client, "local-turn-end", {
            eventWidget = false,
            targeting = false,
            actionBar = true,
        })
    end
    return true
end

local function getEventUnitsOpcode()
    return  Addon.Internal.Comms.Operations:GetOpcode("EVENT_UNITS") or nil
end

local function isEventUnitActive(unit)
    if Event and Event.IsUnitActive then
        return Event.IsUnitActive(unit)
    end

    return type(unit) == "table" and (unit.isPlayer == true or coerceEventUnitBoolean(unit.active, true))
end

local function deferEventWidget(fn, ...)
    if Addon.Internal.Tasks then
        Addon.Internal.Tasks:Enqueue(fn, ...)
        return
    end

    fn(...)
end

local function deferEventPresentation(fn, ...)
    if Addon.Internal and Addon.Internal.Tasks and type(Addon.Internal.Tasks.Enqueue) == "function" then
        Addon.Internal.Tasks:Enqueue(fn, ...)
        return true
    end

    if C_Timer and C_Timer.After then
        local args = { ... }
        local argCount = select("#", ...)
        C_Timer.After(0, function()
            fn(unpack(args, 1, argCount))
        end)
        return true
    end

    fn(...)
    return true
end

local function enqueueClientTask(fn, ...)
    if Addon.Internal and Addon.Internal.Tasks and type(Addon.Internal.Tasks.Enqueue) == "function" then
        Addon.Internal.Tasks:Enqueue(fn, ...)
        return true
    end

    if C_Timer and C_Timer.After then
        local args = { ... }
        local argCount = select("#", ...)
        C_Timer.After(0, function()
            fn(unpack(args, 1, argCount))
        end)
        return true
    end

    fn(...)
    return true
end

local function enqueueClientSliceable(options)
    local tasks = Addon.Internal and Addon.Internal.Tasks or nil
    if type(tasks) == "table" and type(tasks.EnqueueSliceable) == "function" then
        return tasks:EnqueueSliceable(options)
    end

    if Debug and Debug.Error then
        Debug.Error("Event startup sliceable queue unavailable: Addon.Internal.Tasks is missing EnqueueSliceable.")
    end
    return nil
end

local function shouldYieldTaskSlice(deadlineMs)
    local tasks = Addon.Internal and Addon.Internal.Tasks or nil
    return deadlineMs ~= nil
        and type(tasks) == "table"
        and type(tasks.ShouldYield) == "function"
        and tasks:ShouldYield(deadlineMs) == true
end

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function getEquipmentRevision()
    local runtime = Addon.Internal and Addon.Internal.Runtime or nil
    if type(runtime) == "table" and type(runtime.GetRevision) == "function" then
        return math.max(0, math.floor(tonumber(runtime:GetRevision("EquipmentRevision")) or 0))
    end

    return 0
end

local function cancelEventSliceableWork(client, eventId, reason)
    local tasks = Addon.Internal and Addon.Internal.Tasks or nil
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId == ""
        or type(tasks) ~= "table"
        or type(tasks.CancelScope) ~= "function"
    then
        return 0
    end

    return tasks:CancelScope("event:" .. normalizedEventId, reason or "event-reset")
end

local function queueDeferredMovementSync(client, wasLocalTurn, eventState, previousTurnNumber, previousTickNumber, reason)
    local expectedEventId = tostring(type(eventState) == "table" and eventState.id or "")
    if expectedEventId == "" then
        return false
    end

    return enqueueClientTask(function(targetClient, queuedEventId, queuedEventState, queuedTransitionGeneration, queuedWasLocalTurn, queuedPreviousTurnNumber, queuedPreviousTickNumber)
        if type(targetClient) ~= "table" then
            return
        end

        local currentEventState = targetClient.GetEventState and targetClient:GetEventState() or targetClient.EventState
        if type(currentEventState) ~= "table"
            or currentEventState.active ~= true
            or tostring(currentEventState.id or "") ~= queuedEventId
            or (queuedEventState ~= nil and currentEventState ~= queuedEventState)
        then
            return
        end

        syncMovementTracking(
            targetClient,
            queuedWasLocalTurn == true,
            currentEventState,
            queuedPreviousTurnNumber,
            queuedPreviousTickNumber
        )
    end, client, expectedEventId, eventState, getTransitionGeneration(client), wasLocalTurn == true, previousTurnNumber, previousTickNumber, reason)
end

local tryQueueInitialLocalResourceSync

local function runEventStartupStep(targetClient, queuedEventId, queuedGeneration, queuedEventState, deadlineMs)
    if type(targetClient) ~= "table" then
        return false
    end

    local eventState = targetClient.GetEventState and targetClient:GetEventState() or targetClient.EventState
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or tostring(eventState.id or "") ~= tostring(queuedEventId or "")
        or eventState ~= queuedEventState
        or type(targetClient.IsEventTransitionCurrent) ~= "function"
        or not targetClient:IsEventTransitionCurrent(queuedEventId, queuedGeneration, "starting", queuedEventState)
    then
        return false
    end

    local runtime = getEventStartupRuntime(targetClient, eventState.id, true)
    if type(runtime) ~= "table" then
        return false
    end

    local readiness = type(ResourceSync.GetEventReadinessState) == "function"
        and ResourceSync.GetEventReadinessState(eventState)
        or nil
    if type(readiness) ~= "table" or readiness.rosterComplete ~= true then
        setEventStartupPhase(eventState, runtime, "waiting-units")
        targetClient:SetEventTransitionPhase("waiting-units", eventState)
        return true
    end

    if runtime.startupStateReceived ~= true then
        setEventStartupPhase(eventState, runtime, "apply-validate-state")
        targetClient:SetEventTransitionPhase("apply-validate-state", eventState)
        return true
    end

    if runtime.actionBarPrimed ~= true and runtime.visualGate ~= "syncing-local" then
        runtime.visualGate = "syncing-local"
        runtime.actionBarPrimed = true
        setEventStartupPhase(eventState, runtime, "action-bar-metadata")
        targetClient:SetEventTransitionPhase("action-bar-metadata", eventState)
        local phaseTimer = startTiming("Event startup phase: action-bar", 8, queuedEventId)
        queueSharedEventVisualRefresh(targetClient, "startup-action-bar", {
            eventWidget = false,
            targeting = false,
            actionBar = true,
        })
        if phaseTimer then
            stopTransitionPhaseTiming(targetClient.EventTransition, phaseTimer, eventState, { startupPhase = "action-bar" }, "action-bar-metadata")
        end
        setEventStartupPhase(eventState, runtime, "action-bar-metadata")
        return true
    end

    if runtime.traitRuntimeRefreshed ~= true then
        setEventStartupPhase(eventState, runtime, "trait-runtime")
        targetClient:SetEventTransitionPhase("trait-runtime", eventState)
        local phaseTimer = startTiming("Event startup phase: trait-runtime", 8, queuedEventId)
        if type(targetClient.CreateTraitRuntimeRefreshContinuation) ~= "function"
            or type(targetClient.StepTraitRuntimeRefreshContinuation) ~= "function"
        then
            error("Event startup trait-runtime continuation is unavailable.")
        end
        runtime.traitRuntimeContinuation = runtime.traitRuntimeContinuation
            or targetClient:CreateTraitRuntimeRefreshContinuation(eventState)
        if type(runtime.traitRuntimeContinuation) ~= "table" then
            error("Event startup trait-runtime continuation could not be created.")
        end
        local completed = targetClient:StepTraitRuntimeRefreshContinuation(runtime.traitRuntimeContinuation, deadlineMs) == true
        if phaseTimer then
            stopTransitionPhaseTiming(targetClient.EventTransition, phaseTimer, eventState, {
                startupPhase = "trait-runtime",
                completed = completed and 1 or 0,
            }, "trait-runtime")
        end
        if not completed then
            return true
        end
        runtime.traitRuntimeContinuation = nil
        runtime.traitRuntimeRefreshed = true
        setEventStartupPhase(eventState, runtime, "trait-runtime")
        return true
    end

    if runtime.automaticAurasSynced ~= true then
        setEventStartupPhase(eventState, runtime, "automatic-auras")
        targetClient:SetEventTransitionPhase("automatic-auras", eventState)
        local phaseTimer = startTiming("Event startup phase: automatic-auras", 8, queuedEventId)
        if type(targetClient.CreateAutomaticTraitAuraContinuation) ~= "function"
            or type(targetClient.StepAutomaticTraitAuraContinuation) ~= "function"
        then
            error("Event startup automatic-aura continuation is unavailable.")
        end
        runtime.automaticAuraContinuation = runtime.automaticAuraContinuation
            or targetClient:CreateAutomaticTraitAuraContinuation(eventState, { suppressResolvedRefresh = true })
        if type(runtime.automaticAuraContinuation) ~= "table" then
            error("Event startup automatic-aura continuation could not be created.")
        end
        local completed = targetClient:StepAutomaticTraitAuraContinuation(runtime.automaticAuraContinuation, deadlineMs) == true
        if phaseTimer then
            stopTransitionPhaseTiming(targetClient.EventTransition, phaseTimer, eventState, {
                startupPhase = "automatic-auras",
                completed = completed and 1 or 0,
            }, "automatic-auras")
        end
        if not completed then
            return true
        end
        runtime.automaticAuraContinuation = nil
        runtime.automaticAurasSynced = true
        setEventStartupPhase(eventState, runtime, "automatic-auras")
        return true
    end

    if runtime.eventAurasSynced ~= true then
        setEventStartupPhase(eventState, runtime, "event-auras")
        targetClient:SetEventTransitionPhase("event-auras", eventState)
        local phaseTimer = startTiming("Event startup phase: event-auras", 8, queuedEventId)
        if type(targetClient.CreateEventAuraContinuation) ~= "function"
            or type(targetClient.StepEventAuraContinuation) ~= "function"
        then
            error("Event startup event-aura continuation is unavailable.")
        end
        runtime.eventAuraContinuation = runtime.eventAuraContinuation
            or targetClient:CreateEventAuraContinuation(eventState, { suppressResolvedRefresh = true })
        if type(runtime.eventAuraContinuation) ~= "table" then
            error("Event startup event-aura continuation could not be created.")
        end
        local completed = targetClient:StepEventAuraContinuation(runtime.eventAuraContinuation, deadlineMs) == true
        if phaseTimer then
            stopTransitionPhaseTiming(targetClient.EventTransition, phaseTimer, eventState, {
                startupPhase = "event-auras",
                completed = completed and 1 or 0,
            }, "event-auras")
        end
        if not completed then
            return true
        end
        runtime.eventAuraContinuation = nil
        runtime.eventAurasSynced = true
        setEventStartupPhase(eventState, runtime, "event-auras")
        return true
    end

    if runtime.resolvedStateRefreshed ~= true and type(targetClient.RefreshTraitResolvedState) == "function" then
        setEventStartupPhase(eventState, runtime, "resolved-trait")
        targetClient:SetEventTransitionPhase("resolved-trait", eventState)
        local phaseTimer = startTiming("Event startup phase: resolved-state", 8, queuedEventId)
        local auraManager = targetClient.Spellcasting and targetClient.Spellcasting.AuraManager or nil
        runtime.resolvedStateContinuation = runtime.resolvedStateContinuation
            or (type(auraManager) == "table"
                and type(auraManager.CreateLocalPlayerDerivedStateContinuation) == "function"
                and auraManager:CreateLocalPlayerDerivedStateContinuation(targetClient, eventState)
                or nil)
        if type(runtime.resolvedStateContinuation) ~= "table"
            or type(auraManager) ~= "table"
            or type(auraManager.StepLocalPlayerDerivedStateContinuation) ~= "function"
        then
            error("Event startup resolved-state continuation is unavailable.")
        end
        local completed, continuationReason = auraManager:StepLocalPlayerDerivedStateContinuation(
            runtime.resolvedStateContinuation,
            deadlineMs
        )
        if completed == nil then
            if type(auraManager.ReleaseLocalPlayerDerivedStateContinuation) == "function" then
                auraManager:ReleaseLocalPlayerDerivedStateContinuation(runtime.resolvedStateContinuation)
            end
            runtime.resolvedStateContinuation = nil
            if phaseTimer then
                stopTransitionPhaseTiming(targetClient.EventTransition, phaseTimer, eventState, {
                    startupPhase = "resolved-state",
                    completed = 0,
                    stale = continuationReason or "unknown",
                }, "resolved-trait")
            end
            return true
        end
        if completed ~= true then
            if phaseTimer then
                stopTransitionPhaseTiming(targetClient.EventTransition, phaseTimer, eventState, {
                    startupPhase = "resolved-state",
                    completed = 0,
                }, "resolved-trait")
            end
            return true
        end
        runtime.resolvedStateContinuation = nil
        targetClient:RefreshTraitResolvedState(eventState, "startup", {
            suppressDerivedStateRefresh = true,
            suppressVisualRefresh = true,
        })
        runtime.resolvedStateRefreshed = true
        if phaseTimer then
            stopTransitionPhaseTiming(targetClient.EventTransition, phaseTimer, eventState, { startupPhase = "resolved-state", completed = 1 }, "resolved-trait")
        end
        setEventStartupPhase(eventState, runtime, "resolved-trait")
        return true
    end

    if runtime.resourceSyncQueued ~= true then
        setEventStartupPhase(eventState, runtime, "resource-sync")
        targetClient:SetEventTransitionPhase("resource-sync", eventState)
        local phaseTimer = startTiming("Event startup phase: resource-sync", 8, queuedEventId)
        local sessionState = targetClient.GetState and targetClient:GetState() or targetClient.State
        local queuedResourceSync = tryQueueInitialLocalResourceSync(
            targetClient,
            sessionState,
            eventState,
            "startup-resolved-state"
        ) == true
        runtime.resourceSyncQueued = queuedResourceSync
            or type(sessionState) ~= "table"
            or sessionState.lastResourceSyncEventId == eventState.id
            or not hasLocalSessionMemberForStartup(sessionState)
            or type(targetClient.QueueClientResourceSync) ~= "function"
        if phaseTimer then
            stopTransitionPhaseTiming(targetClient.EventTransition, phaseTimer, eventState, {
                startupPhase = "resource-sync",
                queued = runtime.resourceSyncQueued and 1 or 0,
            }, "resource-sync")
        end
        if not runtime.resourceSyncQueued then
            return true
        end
        return true
    end

    readiness = type(ResourceSync.GetEventReadinessState) == "function"
        and ResourceSync.GetEventReadinessState(eventState)
        or nil
    if type(readiness) ~= "table" or readiness.resourcesReady ~= true then
        setEventStartupPhase(eventState, runtime, "waiting-resources")
        targetClient:SetEventTransitionPhase("waiting-resources", eventState)
        return true
    end

    if runtime.consumablesQueued ~= true and not runtime.consumablePromptPending then
        setEventStartupPhase(eventState, runtime, "consumable-prompts")
        targetClient:SetEventTransitionPhase("consumable-prompts", eventState)
        local phaseTimer = startTiming("Event startup phase: consumable-prompts", 8, queuedEventId)
        runtime.consumablePromptPending = true
        if type(targetClient.QueueDeferredConsumablePrompt) == "function" then
            local promptQueued = targetClient:QueueDeferredConsumablePrompt(eventState, "event_start", function()
                if not targetClient:IsEventTransitionCurrent(queuedEventId, queuedGeneration, "starting", queuedEventState) then
                    return
                end
                local currentRuntime = getEventStartupRuntime(targetClient, queuedEventId, false)
                if currentRuntime ~= runtime then
                    return
                end
                runtime.consumablePromptPending = false
                runtime.consumablesQueued = true
                setEventStartupPhase(eventState, runtime, "consumable-prompts")
            end)
            if promptQueued ~= true then
                runtime.consumablePromptPending = false
                runtime.consumablesQueued = true
            end
        else
            runtime.consumablePromptPending = false
            runtime.consumablesQueued = true
        end
        if type(targetClient.QueueEventWidgetRefresh) == "function" then
            targetClient:QueueEventWidgetRefresh("startup-consumable-prompts")
        end
        if phaseTimer then
            stopTransitionPhaseTiming(targetClient.EventTransition, phaseTimer, eventState, { startupPhase = "consumable-prompts" }, "consumable-prompts")
        end
        return true
    end

    if runtime.consumablePromptPending then
        setEventStartupPhase(eventState, runtime, "consumable-prompts")
        targetClient:SetEventTransitionPhase("consumable-prompts", eventState)
        return true
    end

    setEventStartupPhase(eventState, runtime, "ready")
    targetClient:SetEventTransitionPhase("ready", eventState)
    runtime.phase = "ready"
    runtime.visualGate = "ready"
    local readyTimer = startTiming("Event startup phase: ready", 8, queuedEventId)
    if type(targetClient.QueueEventWidgetRefresh) == "function" then
        targetClient:QueueEventWidgetRefresh("startup-ready")
    end
    if type(targetClient.QueueActionBarRefresh) == "function" then
        targetClient:QueueActionBarRefresh("startup-ready")
    end
    if type(targetClient.QueueActionBarCompanionBarsRefresh) == "function" then
        targetClient:QueueActionBarCompanionBarsRefresh("startup-ready", { immediate = true })
    elseif type(targetClient.RefreshActionBarCompanionBars) == "function" then
        targetClient:RefreshActionBarCompanionBars("startup-ready")
    end
    if readyTimer then
        stopTransitionPhaseTiming(targetClient.EventTransition, readyTimer, eventState, { startupPhase = "ready" }, "ready")
    end
    return false
end

local function queueEventStartupWork(client, eventState, reason)
    if type(client) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local runtime = getEventStartupRuntime(client, eventState.id, true)
    if type(runtime) ~= "table" or runtime.queued == true then
        return runtime ~= nil
    end

    local queuedEventId = tostring(eventState.id or "")
    local queuedEventState = eventState
    local queuedGeneration = getTransitionGeneration(client)
    if type(client.IsEventTransitionCurrent) ~= "function"
        or not client:IsEventTransitionCurrent(queuedEventId, queuedGeneration, "starting", queuedEventState)
    then
        return false
    end
    runtime.queued = true
    runtime.transitionGeneration = queuedGeneration
    runtime.eventState = queuedEventState
    local sliceJob = enqueueClientSliceable({
        label = "event-startup",
        scope = "event:" .. queuedEventId,
        state = {
            client = client,
            eventId = queuedEventId,
            reason = reason or "startup",
            eventState = queuedEventState,
            transitionGeneration = queuedGeneration,
            configurationRevision = getConfigurationRevision(),
            equipmentRevision = getEquipmentRevision(),
        },
        isStale = function(work)
            local targetClient = work and work.client or nil
            local currentEventState = targetClient and targetClient.GetEventState and targetClient:GetEventState() or nil
            return type(currentEventState) ~= "table"
                or currentEventState.active ~= true
                or tostring(currentEventState.id or "") ~= tostring(work and work.eventId or "")
                or currentEventState ~= work.eventState
                or type(targetClient.IsEventTransitionCurrent) ~= "function"
                or not targetClient:IsEventTransitionCurrent(
                    work and work.eventId,
                    work and work.transitionGeneration,
                    "starting",
                    work and work.eventState
                )
                or getConfigurationRevision() ~= math.max(0, math.floor(tonumber(work and work.configurationRevision) or 0))
                or getEquipmentRevision() ~= math.max(0, math.floor(tonumber(work and work.equipmentRevision) or 0))
        end,
        step = function(work, deadlineMs)
            local targetClient = work and work.client or nil
            local expectedEventId = work and work.eventId or nil
            if type(targetClient) ~= "table" then
                return true
            end
            local transition = targetClient.EventTransition
            local sliceStartedAtMs = getTimingNowMilliseconds()
            if runEventStartupStep(
                targetClient,
                expectedEventId,
                work and work.transitionGeneration,
                work and work.eventState,
                deadlineMs
            ) then
                recordTransitionSlice(transition, sliceStartedAtMs, "event-startup")
                return false
            end
            recordTransitionSlice(transition, sliceStartedAtMs, "event-startup")
            return true
        end,
        onCancel = function(work, cancelReason)
            local targetClient = work and work.client or nil
            local currentRuntime = targetClient and getEventStartupRuntime(targetClient, work.eventId, false) or nil
            if type(currentRuntime) == "table" then
                local auraManager = targetClient.Spellcasting and targetClient.Spellcasting.AuraManager or nil
                if type(auraManager) == "table"
                    and type(auraManager.ReleaseLocalPlayerDerivedStateContinuation) == "function"
                then
                    auraManager:ReleaseLocalPlayerDerivedStateContinuation(currentRuntime.resolvedStateContinuation)
                end
                currentRuntime.queued = false
                currentRuntime.sliceJob = nil
                currentRuntime.traitRuntimeContinuation = nil
                currentRuntime.automaticAuraContinuation = nil
                currentRuntime.eventAuraContinuation = nil
                currentRuntime.resolvedStateContinuation = nil
            end
            if cancelReason ~= "stale"
                and type(targetClient) == "table"
                and type(targetClient.IsEventTransitionCurrent) == "function"
                and targetClient:IsEventTransitionCurrent(
                    work and work.eventId,
                    work and work.transitionGeneration,
                    "starting",
                    work and work.eventState
                )
            then
                targetClient:EndEventTransition(work and work.eventId, work and work.transitionGeneration, work and work.eventState, cancelReason)
            end
            if cancelReason == "stale" and type(targetClient) == "table" then
                local currentEventState = targetClient.GetEventState and targetClient:GetEventState() or nil
                if type(currentEventState) == "table"
                    and currentEventState.active == true
                    and tostring(currentEventState.id or "") == tostring(work and work.eventId or "")
                    and currentEventState == (work and work.eventState)
                    and type(targetClient.IsEventTransitionCurrent) == "function"
                    and targetClient:IsEventTransitionCurrent(
                        work and work.eventId,
                        work and work.transitionGeneration,
                        "starting",
                        work and work.eventState
                    )
                    and type(currentRuntime) == "table"
                then
                    currentRuntime.traitRuntimeRefreshed = false
                    currentRuntime.automaticAurasSynced = false
                    currentRuntime.eventAurasSynced = false
                    currentRuntime.resolvedStateRefreshed = false
                    if currentRuntime.consumablePromptPending then
                        currentRuntime.consumablePromptPending = false
                        currentRuntime.consumablesQueued = false
                        if type(targetClient.CancelDeferredConsumablePrompt) == "function" then
                            targetClient:CancelDeferredConsumablePrompt(currentEventState, "event_start")
                        end
                    end
                    targetClient:EndEventTransition(
                        work and work.eventId,
                        work and work.transitionGeneration,
                        work and work.eventState,
                        "startup-stale"
                    )
                    local transition = targetClient:BeginEventTransition("starting", currentEventState.id)
                    transition.eventState = currentEventState
                    currentRuntime.transitionGeneration = transition.generation
                    currentRuntime.eventState = currentEventState
                    queueEventStartupWork(targetClient, currentEventState, "startup-stale-restart")
                end
            end
        end,
        onComplete = function(work)
            local targetClient = work and work.client or nil
            local currentRuntime = targetClient and getEventStartupRuntime(targetClient, work.eventId, false) or nil
            if type(currentRuntime) == "table" then
                local auraManager = targetClient.Spellcasting and targetClient.Spellcasting.AuraManager or nil
                if type(auraManager) == "table"
                    and type(auraManager.ReleaseLocalPlayerDerivedStateContinuation) == "function"
                then
                    auraManager:ReleaseLocalPlayerDerivedStateContinuation(currentRuntime.resolvedStateContinuation)
                end
                currentRuntime.queued = false
                currentRuntime.sliceJob = nil
                currentRuntime.traitRuntimeContinuation = nil
                currentRuntime.automaticAuraContinuation = nil
                currentRuntime.eventAuraContinuation = nil
                currentRuntime.resolvedStateContinuation = nil
                currentRuntime.transitionGeneration = nil
                currentRuntime.eventState = nil
                if type(targetClient) == "table"
                    and type(targetClient.IsEventTransitionCurrent) == "function"
                    and targetClient:IsEventTransitionCurrent(
                        work and work.eventId,
                        work and work.transitionGeneration,
                        "starting",
                        work and work.eventState
                    )
                then
                    targetClient:EndEventTransition(work and work.eventId, work and work.transitionGeneration, work and work.eventState, "startup-ready")
                    if type(targetClient.QueueActionBarRefresh) == "function" then
                        targetClient:QueueActionBarRefresh("startup-ready-transition-complete")
                    end
                    if type(targetClient.QueueTargetingWidgetRefresh) == "function" then
                        targetClient:QueueTargetingWidgetRefresh("startup-ready-transition-complete")
                    end
                end
            end
        end,
    })
    if sliceJob then
        runtime.sliceJob = sliceJob
        return true
    end

    runtime.queued = false
    return false
end

local function queueEventTraitRuntimeRefresh(client, eventState, reason)
    if type(client) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    -- A roster delta invalidates target selection and derived output. Cancel the
    -- old event-scoped state machine first, then let startup replay the same
    -- ordered phases against the new roster.
    cancelEventSliceableWork(client, eventState.id, reason or "event-units-changed")
    local runtime = getEventStartupRuntime(client, eventState.id, true)
    if type(runtime) ~= "table" then
        return false
    end
    local traitState = type(client.GetTraitRuntimeState) == "function"
        and client:GetTraitRuntimeState(eventState.id, true)
        or nil
    if type(traitState) == "table" then
        -- Runtime unit deltas restart startup work, but they do not represent
        -- a new aura source. Keep these ownership maps so reconciliation can
        -- remove only identities that actually disappeared.
        traitState.automaticAuraStateByKey = type(traitState.automaticAuraStateByKey) == "table"
            and traitState.automaticAuraStateByKey
            or {}
        traitState.appliedEventAuras = type(traitState.appliedEventAuras) == "table"
            and traitState.appliedEventAuras
            or {}
    end

    local previousTransition = client.EventTransition
    if type(previousTransition) == "table"
        and previousTransition.eventState == eventState
        and previousTransition.kind == "starting"
    then
        client:EndEventTransition(eventState.id, previousTransition.generation, eventState, reason or "event-units-changed")
    end
    local transition = client:BeginEventTransition("starting", eventState.id)
    transition.eventState = eventState
    runtime.queued = false
    runtime.transitionGeneration = transition.generation
    runtime.eventState = eventState
    eventState.startupReady = false
    runtime.actionBarPrimed = false
    runtime.visualGate = ""
    runtime.traitRuntimeRefreshed = false
    runtime.automaticAurasSynced = false
    runtime.eventAurasSynced = false
    runtime.resolvedStateRefreshed = false
    runtime.consumablePromptPending = false
    if type(client.CancelDeferredConsumablePrompt) == "function" then
        client:CancelDeferredConsumablePrompt(eventState, "event_start")
    end
    return queueEventStartupWork(client, eventState, reason or "event-units-changed")
end

function Client:QueueEventTraitRuntimeRefresh(eventState, reason)
    return queueEventTraitRuntimeRefresh(self, eventState, reason)
end

local function hasLocalSessionMember(sessionState)
    if type(sessionState) ~= "table" or type(sessionState.membersByName) ~= "table" then
        return false
    end

    local playerName = Common.GetPlayerName and Common.GetPlayerName() or nil
    playerName = Common.NormalizeName and Common.NormalizeName(playerName) or playerName
    if type(playerName) ~= "string" or playerName == "" then
        return false
    end

    return sessionState.membersByName[playerName] ~= nil
end

function Client:GetEventState()
    return self.EventState
end

function Client:QueueEventWidgetRefresh(reason)
    self.PendingEventWidgetRefreshReason = tostring(reason or self.PendingEventWidgetRefreshReason or "event")
    self.PendingEventWidgetStructuralRefresh = true
    if self.EventWidgetRefreshQueued then
        return true
    end
    self.EventWidgetRefreshQueued = true
    if type(self.QueueVisualRefreshFlush) == "function" then
        return self:QueueVisualRefreshFlush()
    end

    local eventState = self:GetEventState()
    if not eventState or eventState.active ~= true then
        deferEventWidget(function(targetClient)
            targetClient.EventWidgetRefreshQueued = false
            targetClient.PendingEventWidgetRefreshReason = nil

            if targetClient.HideEventWidget then
                targetClient:HideEventWidget()
            end
        end, self)
        return true
    end

    deferEventWidget(function(targetClient, refreshReason)
        targetClient.EventWidgetRefreshQueued = false
        targetClient.PendingEventWidgetRefreshReason = nil

        local eventState = Addon.Client.EventState
        if eventState and eventState.active == true then
            if targetClient.BuildEventWidget then
                targetClient:BuildEventWidget()
            end
            if targetClient.ShowEventWidget then
                targetClient:ShowEventWidget()
            end
            if targetClient.RefreshEventWidget then
                targetClient:RefreshEventWidget(refreshReason)
            end
            if type(targetClient.FlushDeferredConsumablePrompt) == "function" then
                targetClient:FlushDeferredConsumablePrompt(eventState, "event_start")
            end
            return
        end

        if targetClient.HideEventWidget then
            targetClient:HideEventWidget()
        end
    end, self, reason)

    return true
end

local function findEventUnitById(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit, index
        end
    end

    return nil
end

local function findPlayerEventUnit(units, playerName)
    local normalizedPlayerName = Common.NormalizeName and Common.NormalizeName(playerName) or tostring(playerName or "")
    if normalizedPlayerName == "" then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if unit and unit.isPlayer == true then
            local candidateName = Common.NormalizeName and Common.NormalizeName(unit.ownerID or unit.controllerID or unit.name) or tostring(unit.ownerID or unit.controllerID or unit.name or "")
            if candidateName == normalizedPlayerName then
                return unit, index
            end
        end
    end

    return nil
end

local function countPlayerUnits(units)
    local playerCount = 0
    for index = 1, #(units or {}) do
        if units[index] and units[index].isPlayer == true then
            playerCount = playerCount + 1
        end
    end

    return playerCount
end

tryQueueInitialLocalResourceSync = function(client, sessionState, eventState, reason)
    if type(client) ~= "table"
        or type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or sessionState.lastResourceSyncEventId == eventState.id
        or not hasLocalSessionMember(sessionState)
        or type(client.QueueClientResourceSync) ~= "function"
    then
        return false
    end

    local profileLogic = Addon.Internal and Addon.Internal.Profile or nil
    if type(profileLogic) == "table" then
        if type(profileLogic.WarmResolvedBootstrapState) == "function" then
            if profileLogic.WarmResolvedBootstrapState(reason or "event-start") ~= true then
                return false
            end
        elseif type(profileLogic.IsBootstrapResolvedStateReady) == "function"
            and profileLogic.IsBootstrapResolvedStateReady() ~= true
        then
            return false
        end
    end

    return client:QueueClientResourceSync(reason or "event-start") or false
end

local function applyLocalProfileResourcesToEventUnits(sessionState, units)
    if type(units) ~= "table" then
        return false
    end

    local localPlayerName = Common.NormalizeName and Common.NormalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil) or ""
    if localPlayerName == "" then
        return false
    end

    local resources = ResourceSync.BuildProfileResourceSnapshot and ResourceSync.BuildProfileResourceSnapshot() or nil
    if type(resources) ~= "table" or #resources == 0 then
        return false
    end

    local sessionMember = type(sessionState) == "table"
        and type(sessionState.membersByName) == "table"
        and sessionState.membersByName[localPlayerName]
        or nil
    if sessionMember
        and (
            type(sessionMember.resources) ~= "table"
            or #sessionMember.resources == 0
            or not (ResourceSync.ResourcesEqual and ResourceSync.ResourcesEqual(sessionMember.resources, resources))
        )
    then
        sessionMember.resources = ResourceSync.CloneResources and ResourceSync.CloneResources(resources) or resources
    end

    local updated = false
    for index = 1, #units do
        local unit = units[index]
        if unit and unit.isPlayer == true then
            local ownerName = Common.NormalizeName and Common.NormalizeName(unit.ownerID or unit.controllerID or unit.name) or ""
            if ownerName == localPlayerName
                and (
                    type(unit.resources) ~= "table"
                    or #unit.resources == 0
                    or not (ResourceSync.ResourcesEqual and ResourceSync.ResourcesEqual(unit.resources, resources))
                )
            then
                unit.resources = ResourceSync.CloneResources and ResourceSync.CloneResources(resources) or resources
                updated = true
            end
        end
    end

    return updated
end

local function hydrateInboundEventUnit(unit, eventState)
    if not EventUnit or type(EventUnit.HydrateNetworkUnit) ~= "function" then
        return unit
    end

    return EventUnit.HydrateNetworkUnit(unit, {
        playerCount = countPlayerUnits(eventState and eventState.units or nil),
    })
end

local function upsertSortedEventUnit(units, unit)
    if type(units) ~= "table" or not unit then
        return false
    end

    local replaced = false
    for index = 1, #units do
        if tonumber(units[index] and units[index].eventID) == tonumber(unit.eventID) then
            units[index] = unit
            replaced = true
            break
        end
    end

    if not replaced then
        units[#units + 1] = unit
    end

    if Event and Event.SortUnitsByInitiative then
        Event.SortUnitsByInitiative(units)
    end

    return true
end

local function upsertAppendedEventUnit(units, unit)
    if type(units) ~= "table" or not unit then
        return false
    end

    local replaced = false
    for index = 1, #units do
        if tonumber(units[index] and units[index].eventID) == tonumber(unit.eventID) then
            units[index] = unit
            replaced = true
            break
        end
    end

    if not replaced then
        units[#units + 1] = unit
    end

    return true
end

local function removeEventUnitById(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 or type(units) ~= "table" then
        return nil
    end

    for index = 1, #units do
        if tonumber(units[index] and units[index].eventID) == numericEventId then
            local removed = units[index]
            table.remove(units, index)
            return removed
        end
    end

    return nil
end

local function isLocalPlayerEventUnit(unit)
    if type(unit) ~= "table" or unit.isPlayer ~= true then
        return false
    end

    local localPlayerName = Common.NormalizeName and Common.NormalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil) or ""
    if localPlayerName == "" then
        return false
    end

    local candidateName = Common.NormalizeName and Common.NormalizeName(unit.ownerID or unit.controllerID or unit.name) or tostring(unit.ownerID or unit.controllerID or unit.name or "")
    return candidateName ~= "" and candidateName == localPlayerName
end

local function isControlEligibleEventUnit(controlledUnit, localEventUnit)
    if type(controlledUnit) ~= "table" or controlledUnit.isPlayer == true then
        return false
    end

    local controllerId = tonumber(controlledUnit.controllerID) or nil
    if controllerId and tonumber(localEventUnit and localEventUnit.eventID) == controllerId then
        return true
    end

    local controllerName = Common.NormalizeName and Common.NormalizeName(controlledUnit.controllerID) or tostring(controlledUnit.controllerID or "")
    local localName = Common.NormalizeName and Common.NormalizeName(localEventUnit and (localEventUnit.ownerID or localEventUnit.controllerID or localEventUnit.name) or nil) or tostring(localEventUnit and (localEventUnit.ownerID or localEventUnit.controllerID or localEventUnit.name) or "")
    return controllerName ~= "" and localName ~= "" and controllerName == localName
end

local function isLocalPlayerTurnActive(client, eventState)
    if type(client) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local localEventUnit = client.ResolveLocalEventUnit and client:ResolveLocalEventUnit(eventState) or nil
    local localEventId = tonumber(localEventUnit and localEventUnit.eventID) or 0
    if localEventId <= 0 then
        return false
    end

    local spellcasting = client.Spellcasting or Addon.Client.Spellcasting or nil
    if spellcasting and type(spellcasting.IsCasterTurnOnTick) == "function" then
        return spellcasting.IsCasterTurnOnTick(eventState, localEventId) == true
    end

    return false
end

function Client:ResolveLocalEventUnit(eventState)
    local state = eventState or self:GetEventState()
    if type(state) ~= "table" or state.active ~= true then
        return nil
    end

    local playerName = Common.GetPlayerName and Common.GetPlayerName() or nil
    playerName = Common.NormalizeName and Common.NormalizeName(playerName) or playerName
    if type(playerName) ~= "string" or playerName == "" then
        return nil
    end

    return findPlayerEventUnit(state.units, playerName)
end

function Client:CanControlEventUnit(controlledUnit, eventState)
    local localEventUnit = self:ResolveLocalEventUnit(eventState)
    if not localEventUnit then
        return false
    end

    if not isEventUnitActive(controlledUnit) then
        return false
    end

    return isControlEligibleEventUnit(controlledUnit, localEventUnit)
end

function Client:ResolveControlledEventUnit(eventState)
    local state = eventState or self:GetEventState()
    if type(state) ~= "table" or state.active ~= true then
        return nil
    end

    local controlledEventUnitId = tonumber(self.ControlledEventUnitId) or 0
    if controlledEventUnitId <= 0 then
        return nil
    end

    local controlledUnit = findEventUnitById(state.units, controlledEventUnitId)
    if not controlledUnit or controlledUnit.isPlayer == true then
        self.ControlledEventUnitId = nil
        return nil
    end

    if not self:CanControlEventUnit(controlledUnit, state) then
        self.ControlledEventUnitId = nil
        return nil
    end

    return controlledUnit, state
end

function Client:GetActionBarControlContext(eventState)
    local state = eventState or self:GetEventState()
    if type(state) ~= "table" or state.active ~= true then
        return nil
    end

    local localEventUnit = self:ResolveLocalEventUnit(state)
    if not localEventUnit then
        return nil
    end

    local controlledUnit = self:ResolveControlledEventUnit(state)
    if controlledUnit then
        return {
            eventState = state,
            localEventUnit = localEventUnit,
            controlledUnit = controlledUnit,
            activeEventUnit = controlledUnit,
            isControlled = true,
        }
    end

    return {
        eventState = state,
        localEventUnit = localEventUnit,
        controlledUnit = nil,
        activeEventUnit = localEventUnit,
        isControlled = false,
    }
end

function Client:ResolveActiveSpellcasterUnit(eventState)
    local context = self:GetActionBarControlContext(eventState)
    if not context then
        return nil
    end

    return context.activeEventUnit, context.eventState, context
end

function Client:IsLocalTurnActive(eventState)
    if self.TurnEndPending == true then
        return false
    end

    local activeUnit, state = self:ResolveActiveSpellcasterUnit(eventState)
    if type(activeUnit) ~= "table" or type(state) ~= "table" or state.active ~= true then
        return false
    end

    local spellcasting = self.Spellcasting or Addon.Client.Spellcasting or nil
    if spellcasting and type(spellcasting.IsCasterTurnOnTick) == "function" then
        return spellcasting.IsCasterTurnOnTick(state, activeUnit.eventID) == true
    end

    return true
end

function Client:IsLocalEventHost(eventStateOverride)
    local eventState = eventStateOverride or (self.GetEventState and self:GetEventState() or self.EventState)
    local localPlayerName = Common.NormalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil)
    local hostName = Common.NormalizeName(eventState and eventState.hostName or nil)
    return localPlayerName ~= "" and hostName ~= "" and localPlayerName == hostName
end

function Client:MarkEventUnitInteraction(eventState, casterUnit, targetUnit, result, spellRef)
    local targetEventId = tonumber(targetUnit and targetUnit.eventID) or 0
    local casterEventId = tonumber(casterUnit and casterUnit.eventID) or 0
    local effectType = tostring(type(result) == "table" and result.effectType or "")
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or targetEventId <= 0
        or casterEventId <= 0
        or effectType ~= "damage"
    then
        return false
    end

    local marker = {
        eventId = tostring(eventState.id or ""),
        turnNumber = tonumber(eventState.turnNumber) or 0,
        tickNumber = tonumber(eventState.tickNumber) or 0,
        casterEventId = casterEventId,
        targetEventId = targetEventId,
        spellRef = tostring(spellRef or ""),
        effectType = effectType,
    }

    self.EventUnitInteractionMarkers = self.EventUnitInteractionMarkers or {}
    self.EventUnitInteractionMarkers[targetEventId] = marker
    self.LastLocalInteractionMarker = marker

    if self.QueueEventWidgetTargetedRefresh then
        self:QueueEventWidgetTargetedRefresh("event-unit-interaction", { targetEventId })
    elseif self.QueueEventWidgetRefresh then
        self:QueueEventWidgetRefresh("event-unit-interaction")
    end

    return true
end

function Client:ResolveEventUnitInteractionMarkerState(eventUnit, eventState)
    local eventUnitId = tonumber(eventUnit and eventUnit.eventID) or 0
    if type(eventState) ~= "table" or eventState.active ~= true or eventUnitId <= 0 then
        return {
            visible = false,
            alpha = 0,
        }
    end

    local marker = type(self.EventUnitInteractionMarkers) == "table" and self.EventUnitInteractionMarkers[eventUnitId] or nil
    if type(marker) ~= "table" then
        return {
            visible = false,
            alpha = 0,
        }
    end

    if tostring(marker.eventId or "") ~= tostring(eventState.id or "") then
        return {
            visible = false,
            alpha = 0,
        }
    end

    local currentTurnNumber = tonumber(eventState.turnNumber) or 0
    local markerTurnNumber = tonumber(marker.turnNumber) or 0
    if markerTurnNumber <= 0 or currentTurnNumber <= 0 then
        return {
            visible = false,
            alpha = 0,
        }
    end

    local turnDelta = currentTurnNumber - markerTurnNumber
    if turnDelta == 0 then
        return {
            visible = true,
            alpha = 1,
        }
    end
    if turnDelta == 1 then
        return {
            visible = true,
            alpha = 0.5,
        }
    end

    return {
        visible = false,
        alpha = 0,
    }
end

function Client:WasEventUnitInteractedWithLastAction(eventUnit, eventState)
    local state = self.ResolveEventUnitInteractionMarkerState and self:ResolveEventUnitInteractionMarkerState(eventUnit, eventState) or nil
    return type(state) == "table" and state.visible == true
end

local function isCurrentTurnCommit(client, commit)
    if type(client) ~= "table" or type(commit) ~= "table" then
        return false
    end

    local currentSessionState = client.GetState and client:GetState() or nil
    local currentEventState = client.GetEventState and client:GetEventState() or nil
    return currentSessionState == commit.sessionState
        and currentEventState == commit.eventState
        and type(currentSessionState) == "table"
        and currentSessionState.active == true
        and type(currentEventState) == "table"
        and currentEventState.active == true
        and currentEventState.ending ~= true
        and tostring(currentEventState.id or "") == tostring(commit.eventId or "")
        and tonumber(currentEventState.turnNumber) == tonumber(commit.sourceTurnNumber)
        and tonumber(currentEventState.tickNumber) == tonumber(commit.sourceTickNumber)
        and tonumber(client.TurnCommitGeneration) == tonumber(commit.requestGeneration)
        and getTransitionGeneration(client) == tonumber(commit.transitionGeneration)
end

local function refreshTurnCommitDisplays(client, reason)
    if type(client) ~= "table" then
        return
    end

    if type(client.QueueActionBarRefresh) == "function" then
        client:QueueActionBarRefresh(reason or "turn-commit")
    elseif type(client.RefreshActionBarWidget) == "function" then
        client:RefreshActionBarWidget(reason or "turn-commit")
    end
end

local function finishTurnCommit(client, commit, status, reason)
    if type(client) ~= "table" or type(commit) ~= "table" or client.PendingTurnCommit ~= commit then
        return false
    end

    commit.status = tostring(status or "failed")
    commit.failureReason = commit.status == "complete" and nil or tostring(reason or commit.failureReason or "turn-commit-failed")
    commit.completed = commit.status == "complete"
    client.PendingTurnCommit = nil
    client.LastTurnCommit = commit
    if commit.status ~= "complete" then
        -- A failed send keeps its batch for retry, but must release a non-host's
        -- turn gate so the user can request that retry.
        client.TurnEndPending = false
    end
    refreshTurnCommitDisplays(client, commit.status == "complete" and "turn-commit-complete" or "turn-commit-failed")

    if type(commit.onFinished) == "function" then
        commit.onFinished(commit, commit.status == "complete", commit.failureReason)
    end
    return true
end

local function stepPendingTurnCommit(commit, deadlineMs)
    local client = commit and commit.client or nil
    if type(client) ~= "table" or type(commit) ~= "table" then
        return true
    end

    while true do
        if commit.phase == "resource" then
            local hasPending = type(client.HasPendingTurnResourceDeltas) == "function"
                and client:HasPendingTurnResourceDeltas(
                    commit.sessionState,
                    commit.eventState,
                    commit.sourceTurnNumber,
                    commit.sourceTickNumber
                )
                or false
            if hasPending then
                commit.resourceFlushStatus = "sending"
                local flushed = type(client.FlushDeferredTurnResourceDeltas) == "function"
                    and client:FlushDeferredTurnResourceDeltas(
                        commit.sessionState,
                        commit.eventState,
                        commit.sourceTurnNumber,
                        commit.sourceTickNumber
                    )
                    or false
                local remainsPending = type(client.HasPendingTurnResourceDeltas) == "function"
                    and client:HasPendingTurnResourceDeltas(
                        commit.sessionState,
                        commit.eventState,
                        commit.sourceTurnNumber,
                        commit.sourceTickNumber
                    )
                    or false
                if remainsPending or not flushed then
                    commit.resourceFlushStatus = "failed"
                    commit.failureReason = "resource-send-failed"
                    commit.terminalStatus = "failed"
                    return true
                end
            end
            commit.resourceFlushStatus = "complete"
            commit.phase = "aura"
        elseif commit.phase == "aura" then
            local auraManager = client.Spellcasting and client.Spellcasting.AuraManager or nil
            local hasPending = type(auraManager) == "table"
                and type(auraManager.HasPendingOutboundAuraOperations) == "function"
                and auraManager:HasPendingOutboundAuraOperations(
                    client,
                    "turn",
                    commit.eventState,
                    commit.sourceTurnNumber,
                    commit.sourceTickNumber
                )
                or false
            if hasPending then
                commit.auraFlushStatus = "queued"
                local queued = type(auraManager) == "table"
                    and type(auraManager.FlushOutboundAuraOperations) == "function"
                    and auraManager:FlushOutboundAuraOperations(
                        client,
                        "turn",
                        commit.eventState,
                        commit.sourceTurnNumber,
                        commit.sourceTickNumber
                    )
                    or false
                if not queued then
                    commit.auraFlushStatus = "failed"
                    commit.failureReason = "aura-flush-queue-failed"
                    commit.terminalStatus = "failed"
                    return true
                end
                commit.phase = "aura-wait"
            else
                commit.auraFlushStatus = "complete"
                commit.phase = "complete"
            end
        elseif commit.phase == "aura-wait" then
            local auraManager = client.Spellcasting and client.Spellcasting.AuraManager or nil
            local hasPending = type(auraManager) == "table"
                and type(auraManager.HasPendingOutboundAuraOperations) == "function"
                and auraManager:HasPendingOutboundAuraOperations(
                    client,
                    "turn",
                    commit.eventState,
                    commit.sourceTurnNumber,
                    commit.sourceTickNumber
                )
                or false
            local status = type(auraManager) == "table"
                and type(auraManager.GetOutboundAuraFlushStatus) == "function"
                and auraManager:GetOutboundAuraFlushStatus(client, "turn")
                or "failed"
            local jobs = type(client.PendingOutboundAuraFlushJobsByScope) == "table"
                and client.PendingOutboundAuraFlushJobsByScope.turn
                or nil
            if hasPending then
                if status == "failed" or status == "cancelled" or jobs == nil then
                    commit.auraFlushStatus = "failed"
                    commit.failureReason = "aura-send-failed"
                    commit.terminalStatus = "failed"
                    return true
                end
                return false
            elseif type(jobs) == "table" and jobs.finalized ~= true then
                -- Entries may already have been removed, but the sliceable job
                -- is not complete until its completion callback has run.
                return false
            else
                if status == "failed" or status == "cancelled" then
                    commit.auraFlushStatus = "failed"
                    commit.failureReason = "aura-send-failed"
                    commit.terminalStatus = "failed"
                    return true
                end
                commit.auraFlushStatus = "complete"
                commit.phase = "complete"
            end
        elseif commit.phase == "complete" then
            return true
        else
            commit.failureReason = "invalid-turn-commit-phase"
            commit.terminalStatus = "failed"
            return true
        end

        if shouldYieldTaskSlice(deadlineMs) then
            return false
        end
    end
end

function Client:CancelPendingTurnCommit(reason, eventId)
    local commit = self.PendingTurnCommit
    if type(commit) ~= "table" then
        return false
    end
    if eventId ~= nil and tostring(commit.eventId or "") ~= tostring(eventId or "") then
        return false
    end

    local tasks = Addon.Internal and Addon.Internal.Tasks or nil
    if type(tasks) == "table" and type(tasks.Cancel) == "function" and commit.job then
        if tasks:Cancel(commit.job, reason or "turn-commit-cancelled") then
            return true
        end
    end

    return finishTurnCommit(self, commit, "cancelled", reason or "turn-commit-cancelled")
end

function Client:BeginPendingTurnCommit(sessionStateOverride, eventStateOverride, options)
    local sessionState = sessionStateOverride or self:GetState()
    local eventState = eventStateOverride or (self.GetEventState and self:GetEventState() or nil)
    options = type(options) == "table" and options or {}
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.ending == true
        or eventState.channelName ~= sessionState.channelName
        or not self:CanPerformEventAction(eventState, "pending-turn-flush")
    then
        return false
    end

    local existing = self.PendingTurnCommit
    if type(existing) == "table" and existing.status == "pending" then
        if isCurrentTurnCommit(self, existing) then
            if options.hostAdvancementRequested == true then
                existing.hostAdvancementRequested = true
                existing.onFinished = options.onFinished or existing.onFinished
            end
            return existing
        end
        self:CancelPendingTurnCommit("turn-commit-superseded")
    end

    self.TurnCommitGeneration = math.max(0, math.floor(tonumber(self.TurnCommitGeneration) or 0)) + 1
    local commit = {
        client = self,
        sessionState = sessionState,
        eventState = eventState,
        eventId = tostring(eventState.id or ""),
        sourceTurnNumber = math.floor(tonumber(eventState.turnNumber) or 0),
        sourceTickNumber = math.floor(tonumber(eventState.tickNumber) or 0),
        requestGeneration = self.TurnCommitGeneration,
        transitionGeneration = getTransitionGeneration(self),
        resourceFlushStatus = "pending",
        auraFlushStatus = "pending",
        hostAdvancementRequested = options.hostAdvancementRequested == true,
        onFinished = options.onFinished,
        phase = "resource",
        status = "pending",
        startedAtMs = getTimingNowMilliseconds(),
    }
    self.PendingTurnCommit = commit

    local job = enqueueClientSliceable({
        label = "pending-turn-commit",
        scope = "event-turn-commit:" .. commit.eventId,
        state = commit,
        isStale = function(work)
            return not isCurrentTurnCommit(work and work.client, work)
        end,
        step = stepPendingTurnCommit,
        onCancel = function(work, cancelReason)
            local currentEventState = work.client.GetEventState and work.client:GetEventState() or nil
            local sourceInvalidated = currentEventState ~= work.eventState
                or type(currentEventState) ~= "table"
                or currentEventState.active ~= true
                or tonumber(currentEventState.turnNumber) ~= tonumber(work.sourceTurnNumber)
                or tonumber(currentEventState.tickNumber) ~= tonumber(work.sourceTickNumber)
            if (cancelReason == "stale" and sourceInvalidated)
                or tostring(cancelReason or ""):find("source")
            then
                if type(work.client.DiscardPendingTurnResourceDeltas) == "function" then
                    work.client:DiscardPendingTurnResourceDeltas(
                        work.eventId,
                        work.sourceTurnNumber,
                        work.sourceTickNumber
                    )
                end
                local auraManager = work.client.Spellcasting and work.client.Spellcasting.AuraManager or nil
                if type(auraManager) == "table"
                    and type(auraManager.DiscardPendingOutboundAuraOperations) == "function"
                then
                    auraManager:DiscardPendingOutboundAuraOperations(
                        work.client,
                        "turn",
                        work.eventId,
                        work.sourceTurnNumber,
                        work.sourceTickNumber
                    )
                end
            end
            finishTurnCommit(work and work.client, work, "cancelled", cancelReason or "turn-commit-cancelled")
        end,
        onComplete = function(work)
            local status = work and work.terminalStatus or "complete"
            finishTurnCommit(work and work.client, work, status, work and work.failureReason or nil)
        end,
    })
    if not job then
        commit.terminalStatus = "failed"
        commit.failureReason = "turn-commit-queue-failed"
        finishTurnCommit(self, commit, "failed", commit.failureReason)
        return commit
    end
    commit.job = job
    return commit
end

-- Returns an explicit commit handle. `queued` is not completion: callers must
-- inspect handle.status or wait for onFinished before treating the turn scope
-- as sent.
function Client:FlushPendingTurnChanges(sessionStateOverride, eventStateOverride, options)
    return self:BeginPendingTurnCommit(sessionStateOverride, eventStateOverride, options)
end

-- Legacy callers that only need to request a drain use FlushPendingTurnChanges;
-- completion-aware callers use the handle returned above.
--
-- The old implementation intentionally remains absent: it conflated a queued
-- task with a completed send and allowed the authoritative step to overtake it.

function Client:EndTurn()
    local sessionState = self:GetState()
    local eventState = self:GetEventState()
    local canAct = self:CanPerformEventAction(eventState, "end-turn")
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or self:IsLocalEventHost(eventState)
        or not self:IsLocalTurnActive(eventState)
        or not canAct
    then
        return false
    end

    self.TurnEndPending = true
    local tracker = getMovementTracker()
    if tracker and type(tracker.OnPlayerTurnEnd) == "function" then
        tracker:OnPlayerTurnEnd()
    end
    local commit = self:FlushPendingTurnChanges(sessionState, eventState)
    if type(commit) ~= "table" then
        self.TurnEndPending = false
        return false
    end
    return true
end

function Client:TakeControlOfEventUnit(eventUnit)
    local eventState = self:GetEventState()
    if type(eventState) ~= "table" or eventState.active ~= true
        or not self:CanPerformEventAction(eventState, "companion-control")
    then
        return false
    end

    local controlledUnit = type(eventUnit) == "table" and eventUnit or nil
    if not controlledUnit or controlledUnit.isPlayer == true or not self:CanControlEventUnit(controlledUnit, eventState) then
        return false
    end

    local nextControlledId = tonumber(controlledUnit.eventID) or 0
    if nextControlledId <= 0 then
        return false
    end

    if self.ControlledEventUnitId == nextControlledId then
        return true
    end

    self.ControlledEventUnitId = nextControlledId
    if self.CancelSpellTargeting then
        self:CancelSpellTargeting("control-changed")
    end
    bumpAllEventTooltipContextRevisions(eventState)
    queueSharedEventVisualRefresh(self, "control-take", {
        eventWidget = true,
        targeting = false,
        actionBar = true,
    })
    return true
end

function Client:ReleaseControl(reason)
    if self.ControlledEventUnitId == nil then
        return false
    end

    self.ControlledEventUnitId = nil
    if self.CancelSpellTargeting then
        self:CancelSpellTargeting(reason or "control-release")
    end
    bumpAllEventTooltipContextRevisions(self:GetEventState())
    queueSharedEventVisualRefresh(self, reason or "control-release", {
        eventWidget = true,
        targeting = false,
        actionBar = true,
    })
    return true
end

local function processEventCompletionAchievement(client, eventState, reason)
    local achievements = type(client) == "table" and client.Achievements or nil
    if not achievements or type(achievements.HandleRPEEventComplete) ~= "function" then
        return true
    end
    local ok, err = pcall(achievements.HandleRPEEventComplete, achievements, eventState, reason)
    if not ok then
        if Debug and Debug.Error then
            Debug.Error("Event end achievement transaction failed: %s", tostring(err))
        end
        return false
    end
    return true
end

local function commitEventTransitionTransaction(client, transition, reason)
    local transaction = type(transition) == "table" and transition.transaction or nil
    if type(transaction) ~= "table" or transaction.status ~= "active" then
        return true
    end
    if type(Runtime) ~= "table" or type(Runtime.GetCurrentTransaction) ~= "function"
        or Runtime:GetCurrentTransaction() ~= transaction
    then
        return false
    end
    if transition.kind == "ending" and type(transition.eventState) == "table" then
        processEventCompletionAchievement(client, transition.eventState, reason)
    end
    local ok, committed = pcall(Runtime.CommitTransaction, Runtime, transaction)
    if not ok then
        if Debug and Debug.Error then
            Debug.Error("Event transition transaction commit failed (%s): %s", tostring(reason or "unknown"), tostring(committed))
        end
        return false
    end
    transition.transaction = nil
    transition.transactionId = transaction.id
    return committed == true
end

local function clearEventStateNow(client, state, reason, options)
    options = type(options) == "table" and options or {}
    local transition = client.EventTransition
    local eventState = type(state) == "table" and state or (transition and transition.eventState)
    local eventId = eventState and eventState.id or nil
    local combat = client.Combat or (Addon.Client and Addon.Client.Combat) or nil
    if type(combat) == "table" and type(combat.ClearDefensiveReactionUseLedger) == "function" then
        combat:ClearDefensiveReactionUseLedger(eventId)
    end
    if type(client.CancelPendingTurnCommit) == "function" then
        client:CancelPendingTurnCommit(options.cancelReason or "event-reset", eventId)
    end
    if type(client.ResetEventResourceDeltas) == "function" then
        client:ResetEventResourceDeltas(eventId)
    end
    if options.skipCancel ~= true then
        cancelEventSliceableWork(client, eventId, options.cancelReason or "event-reset")
    end
    commitEventTransitionTransaction(client, transition, reason or "event-reset")

    local sessionState = client:GetState()
    local timer = startTiming("Event end teardown", 16, reason or "ended")
    local activeCasts, activeAuras = 0, 0
    if timer then
        activeCasts, activeAuras = getActiveEventCardinality(client, eventState)
    end
    local tracker = getMovementTracker()
    if tracker and type(tracker.OnPlayerTurnEnd) == "function" then
        tracker:OnPlayerTurnEnd()
    end
    if eventState then
        eventState.active = false
        eventState.ending = false
        eventState.startupReady = false
        eventState.endedAt = Common.GetNow()
        client.LastEventEndReason = reason
        Debug.Info(
            "Event ended: %s.",
            tostring(eventState.name ~= "" and eventState.name or eventState.id or "unnamed")
        )
    end

    if client.EventState == eventState then
        client.EventState = nil
    end
    client.ControlledEventUnitId = nil
    client.TurnEndPending = false
    client.LastAppliedTurnRegenKey = nil
    client.PendingStartupActionBarRefresh = false
    client.PendingStartupActionBarRefreshReason = nil
    client.EventUnitInteractionMarkers = {}
    client.LastLocalInteractionMarker = nil

    local combatLogTimer = startTiming("Event end teardown: combat-log", 8, reason or "ended")
    if client.ClearEventWidgetCombatLog then
        client:ClearEventWidgetCombatLog(reason or "ended")
    end
    if combatLogTimer then
        stopEventTiming(combatLogTimer, eventState, { teardownPhase = "combat-log" })
    end
    local spellcastingTimer = startTiming("Event end teardown: spellcasting", 8, reason or "ended")
    if client.ResetSpellcastingState then
        client:ResetSpellcastingState(eventId)
    end
    if spellcastingTimer then
        stopEventTiming(spellcastingTimer, eventState, { teardownPhase = "spellcasting" })
    end
    local traitTimer = startTiming("Event end teardown: traits", 8, reason or "ended")
    if client.ResetTraitRuntime then
        client:ResetTraitRuntime(eventId)
    end
    if traitTimer then
        stopEventTiming(traitTimer, eventState, { teardownPhase = "traits" })
    end
    resetEventStartupRuntime(client, eventId)
    local targetingTimer = startTiming("Event end teardown: targeting", 8, reason or "ended")
    if client.CancelSpellTargeting then
        client:CancelSpellTargeting("")
    end
    if sessionState then
        sessionState.lastResourceSyncEventId = nil
    end
    if client.InvalidatePendingSpellTargetingDisplayState then
        client:InvalidatePendingSpellTargetingDisplayState()
    end
    if targetingTimer then
        stopEventTiming(targetingTimer, eventState, { teardownPhase = "targeting" })
    end
    if type(Runtime) == "table" and type(Runtime.ClearEventRevisions) == "function" then
        Runtime:ClearEventRevisions(eventId)
    end

    if options.queueVisual ~= false then
        local visualTimer = startTiming("Event end teardown: visual-queue", 8, reason or "ended")
        queueSharedEventVisualRefresh(client, reason or "ended", {
            eventWidget = true,
            targeting = false,
            actionBar = true,
        })
        if visualTimer then
            stopEventTiming(visualTimer, eventState, { teardownPhase = "visual-queue" })
        end
    end
    if type(client.IsEventTransitionCurrent) == "function" and transition then
        client:EndEventTransition(eventId, transition.generation, eventState, reason or "event-reset")
    end
    if timer then
        stopEventTiming(timer, eventState, {
            teardownReason = reason or "ended",
            activeCasts = activeCasts,
            activeAuras = activeAuras,
        })
    end
    return eventState
end

function Client:ResetEventState(reason)
    return clearEventStateNow(self, self.EventState, reason or "event-reset")
end

local function runEventEndStep(targetClient, work, deadlineMs)
    if type(targetClient) ~= "table" or type(work) ~= "table" then
        return false
    end

    local eventState = targetClient:GetEventState()
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.ending ~= true
        or eventState ~= work.eventState
        or type(targetClient.IsEventTransitionCurrent) ~= "function"
        or not targetClient:IsEventTransitionCurrent(work.eventId, work.transitionGeneration, "ending", work.eventState)
    then
        return false
    end

    if work.phase == "achievement" then
        targetClient:SetEventTransitionPhase("achievement", eventState)
        local timer = startTiming("Event end phase: achievement", 8, work.eventId)
        processEventCompletionAchievement(targetClient, eventState, work.reason)
        stopTransitionPhaseTiming(targetClient.EventTransition, timer, eventState, { teardownPhase = "achievement" }, "achievement")

        work.phase = "consumable-prompts"
        if targetClient.PromptPhaseConsumableTraits then
            local prompted = targetClient:PromptPhaseConsumableTraits(eventState, "event_end", function()
                if not targetClient:IsEventTransitionCurrent(work.eventId, work.transitionGeneration, "ending", eventState) then
                    return
                end
                work.promptResolved = true
                targetClient:SetEventTransitionPhase("consumable-prompts", eventState)
            end)
            if not prompted and not work.promptResolved then
                work.promptResolved = true
            end
        else
            work.promptResolved = true
        end
        return true
    end

    if work.phase == "consumable-prompts" then
        targetClient:SetEventTransitionPhase("consumable-prompts", eventState)
        if not work.promptResolved then
            return true
        end
        work.phase = "commit"
        return true
    end

    if work.phase == "commit" then
        targetClient:SetEventTransitionPhase("commit", eventState)
        local timer = startTiming("Event end phase: commit", 8, work.eventId)
        commitEventTransitionTransaction(targetClient, targetClient.EventTransition, work.reason)
        stopTransitionPhaseTiming(targetClient.EventTransition, timer, eventState, { teardownPhase = "commit" }, "commit")
        work.phase = "combat-log"
        return true
    end

    if work.phase == "combat-log" then
        targetClient:SetEventTransitionPhase("clear-combat-log", eventState)
        local timer = startTiming("Event end phase: combat-log", 8, work.eventId)
        if targetClient.ClearEventWidgetCombatLog then
            targetClient:ClearEventWidgetCombatLog(work.reason)
        end
        stopTransitionPhaseTiming(targetClient.EventTransition, timer, eventState, { teardownPhase = "combat-log" }, "clear-combat-log")
        work.phase = "spellcasting"
        return true
    end

    if work.phase == "spellcasting" then
        targetClient:SetEventTransitionPhase("clear-spellcasting", eventState)
        local timer = startTiming("Event end phase: spellcasting", 8, work.eventId)
        if targetClient.ResetSpellcastingState then
            targetClient:ResetSpellcastingState(work.eventId)
        end
        stopTransitionPhaseTiming(targetClient.EventTransition, timer, eventState, { teardownPhase = "spellcasting" }, "clear-spellcasting")
        work.phase = "traits"
        return true
    end

    if work.phase == "traits" then
        targetClient:SetEventTransitionPhase("clear-traits", eventState)
        local timer = startTiming("Event end phase: traits", 8, work.eventId)
        if targetClient.ResetTraitRuntime then
            targetClient:ResetTraitRuntime(work.eventId)
        end
        stopTransitionPhaseTiming(targetClient.EventTransition, timer, eventState, { teardownPhase = "traits" }, "clear-traits")
        work.phase = "targeting"
        return true
    end

    if work.phase == "targeting" then
        targetClient:SetEventTransitionPhase("clear-targeting", eventState)
        local timer = startTiming("Event end phase: targeting", 8, work.eventId)
        local tracker = getMovementTracker()
        if tracker and type(tracker.OnPlayerTurnEnd) == "function" then
            tracker:OnPlayerTurnEnd()
        end
        targetClient.ControlledEventUnitId = nil
        targetClient.TurnEndPending = false
        targetClient.LastAppliedTurnRegenKey = nil
        targetClient.PendingStartupActionBarRefresh = false
        targetClient.PendingStartupActionBarRefreshReason = nil
        targetClient.EventUnitInteractionMarkers = {}
        targetClient.LastLocalInteractionMarker = nil
        if targetClient.CancelSpellTargeting then
            targetClient:CancelSpellTargeting("")
        end
        local sessionState = targetClient:GetState()
        if sessionState then
            sessionState.lastResourceSyncEventId = nil
        end
        if targetClient.InvalidatePendingSpellTargetingDisplayState then
            targetClient:InvalidatePendingSpellTargetingDisplayState()
        end
        stopTransitionPhaseTiming(targetClient.EventTransition, timer, eventState, { teardownPhase = "targeting" }, "clear-targeting")
        work.phase = "clear-revisions"
        return true
    end

    if work.phase == "clear-revisions" then
        targetClient:SetEventTransitionPhase("clear-revisions", eventState)
        local timer = startTiming("Event end phase: clear-revisions", 8, work.eventId)
        if type(Runtime) == "table" and type(Runtime.ClearEventRevisions) == "function" then
            Runtime:ClearEventRevisions(work.eventId)
        end
        resetEventStartupRuntime(targetClient, work.eventId)
        stopTransitionPhaseTiming(targetClient.EventTransition, timer, eventState, { teardownPhase = "clear-revisions" }, "clear-revisions")
        work.phase = "visual-queue"
        return true
    end

    if work.phase == "visual-queue" then
        targetClient:SetEventTransitionPhase("visual-teardown", eventState)
        local timer = startTiming("Event end phase: visual-queue", 8, work.eventId)
        eventState.active = false
        eventState.ending = false
        eventState.startupReady = false
        eventState.endedAt = Common.GetNow()
        targetClient.LastEventEndReason = work.reason
        Debug.Info(
            "Event ended: %s.",
            tostring(eventState.name ~= "" and eventState.name or eventState.id or "unnamed")
        )
        if targetClient.EventState == eventState then
            targetClient.EventState = nil
        end
        queueSharedEventVisualRefresh(targetClient, work.reason, {
            eventWidget = true,
            targeting = false,
            actionBar = true,
        })
        stopTransitionPhaseTiming(targetClient.EventTransition, timer, eventState, { teardownPhase = "visual-queue" }, "visual-teardown")
        targetClient:EndEventTransition(work.eventId, work.transitionGeneration, eventState, work.reason)
        work.completed = true
        return false
    end

    return false
end

local function queueEventEndWork(client, eventState, transition, reason, work)
    if type(client) ~= "table" or type(eventState) ~= "table" or type(transition) ~= "table" then
        return false
    end
    local queuedEventId = tostring(eventState.id or "")
    local endWork = work or {
        client = client,
        eventId = queuedEventId,
        eventState = eventState,
        transitionGeneration = transition.generation,
        reason = reason or "ended",
        phase = "achievement",
        promptResolved = false,
    }
    local job = enqueueClientSliceable({
        label = "event-end",
        scope = "event:" .. queuedEventId,
        state = endWork,
        isStale = function(currentWork)
            local targetClient = currentWork and currentWork.client or nil
            local currentEventState = targetClient and targetClient:GetEventState() or nil
            return type(currentEventState) ~= "table"
                or currentEventState ~= (currentWork and currentWork.eventState)
                or currentEventState.active ~= true
                or currentEventState.ending ~= true
                or type(targetClient.IsEventTransitionCurrent) ~= "function"
                or not targetClient:IsEventTransitionCurrent(
                    currentWork and currentWork.eventId,
                    currentWork and currentWork.transitionGeneration,
                    "ending",
                    currentWork and currentWork.eventState
                )
        end,
        step = function(currentWork, deadlineMs)
            local transition = currentWork and currentWork.client and currentWork.client.EventTransition or nil
            local sliceStartedAtMs = getTimingNowMilliseconds()
            if runEventEndStep(currentWork and currentWork.client or nil, currentWork, deadlineMs) then
                recordTransitionSlice(transition, sliceStartedAtMs, "event-end")
                return false
            end
            recordTransitionSlice(transition, sliceStartedAtMs, "event-end")
            return true
        end,
        onCancel = function(currentWork, cancelReason)
            if type(currentWork) == "table" then
                currentWork.cancelled = true
                local targetClient = currentWork.client
                if (cancelReason == "error" or cancelReason == "stale-check-error")
                    and type(targetClient) == "table"
                    and type(targetClient.IsEventTransitionCurrent) == "function"
                    and targetClient.EventState == currentWork.eventState
                    and targetClient:IsEventTransitionCurrent(
                        currentWork.eventId,
                        currentWork.transitionGeneration,
                        "ending",
                        currentWork.eventState
                    )
                then
                    clearEventStateNow(targetClient, currentWork.eventState, "event-end-failed", {
                        skipCancel = true,
                        cancelReason = "event-end-failed",
                    })
                end
            end
        end,
        onComplete = function(currentWork)
            if type(currentWork) == "table" then
                currentWork.completed = true
            end
        end,
    })
    if not job then
        return false
    end
    endWork.job = job
    return true
end

function Client:HandleEventStart(arguments, sender)
    local totalStartTime = getTimingNowMilliseconds()
    local timingParts = totalStartTime > 0 and {} or nil
    local sessionState = self:GetState()
    if not sessionState or sessionState.active ~= true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or sessionState.channelName ~= channelName then
        return false
    end

    local timer = startTiming("Event start immediate handler", 8, "event-start")
    local parseStartTime = timingParts and getTimingNowMilliseconds() or nil
    local nextState = Event.FromStartArguments(arguments)
    appendTimingPart(timingParts, "parse-start", parseStartTime, 10)

    nextState.hostName = Common.NormalizeName(nextState.hostName ~= "" and nextState.hostName or sender)
    nextState.channelName = channelName
    nextState.active = true
    nextState.ending = false
    nextState.endedAt = 0
    nextState.turnNumber = math.max(1, tonumber(nextState.turnNumber) or 1)
    nextState.tickNumber = math.max(1, tonumber(nextState.tickNumber) or 1)
    nextState.totalTicks = math.max(1, tonumber(nextState.totalTicks) or 1)
    nextState.rosterReady = false
    nextState.unitsReady = false
    nextState.unitsChunkReceived = 0
    nextState.unitsChunkExpected = 0

    if type(self.EventState) == "table" then
        clearEventStateNow(self, self.EventState, "event-replaced", {
            cancelReason = "event-replaced",
        })
    end

    local hydrateStartTime = timingParts and getTimingNowMilliseconds() or nil
    if ResourceSync.ApplyTrackedPlayerResourcesToEventUnits then
        ResourceSync.ApplyTrackedPlayerResourcesToEventUnits(sessionState.membersByName, nextState.units)
    end
    applyLocalProfileResourcesToEventUnits(sessionState, nextState.units)
    if ResourceSync.UpdateEventReadiness then
        ResourceSync.UpdateEventReadiness(nextState)
    end
    appendTimingPart(timingParts, "hydrate-resources", hydrateStartTime, 10)

    self.EventState = nextState
    local transition = self:BeginEventTransition("starting", nextState.id)
    transition.eventState = nextState
    local startupRuntime = getEventStartupRuntime(self, nextState.id, true)
    if startupRuntime then
        startupRuntime.startupStateReceived = false
        startupRuntime.actionBarPrimed = false
        startupRuntime.visualGate = ""
        startupRuntime.traitRuntimeRefreshed = false
        startupRuntime.automaticAurasSynced = false
        startupRuntime.eventAurasSynced = false
        startupRuntime.resolvedStateRefreshed = false
        startupRuntime.resourceSyncQueued = false
        startupRuntime.consumablesQueued = false
        startupRuntime.consumablePromptPending = false
        startupRuntime.queued = false
        startupRuntime.transitionGeneration = transition.generation
        startupRuntime.eventState = nextState
    end
    setEventStartupPhase(nextState, startupRuntime, "starting")

    local achievements = Client.Achievements
    if achievements and type(achievements.HandleRPEEventStart) == "function" then
        local ok, err = pcall(function()
            if type(Runtime) == "table" and type(Runtime.RunTransaction) == "function" then
                Runtime:RunTransaction("event-start:" .. tostring(nextState.id), function()
                    local currentTransaction = type(Runtime.GetCurrentTransaction) == "function"
                        and Runtime:GetCurrentTransaction() or nil
                    transition.transactionId = currentTransaction and currentTransaction.id or nil
                    achievements:HandleRPEEventStart(nextState, startupRuntime)
                end, { eventId = nextState.id })
            else
                achievements:HandleRPEEventStart(nextState, startupRuntime)
            end
        end)
        if not ok and Debug and Debug.Error then
            Debug.Error("Event start achievement transaction failed: %s", tostring(err))
        end
    end

    local wasLocalTurn = false
    self.EventUnitInteractionMarkers = {}
    self.LastLocalInteractionMarker = nil
    if self.ClearEventWidgetCombatLog then
        self:ClearEventWidgetCombatLog("event-start")
    end
    if self.ResetSpellcastingState then
        self:ResetSpellcastingState(nextState.id)
    end
    self.LastEventEndReason = nil
    playEventStartSound()

    local movementStartTime = timingParts and getTimingNowMilliseconds() or nil
    queueDeferredMovementSync(self, wasLocalTurn, nextState, nil, nil, "event-start")
    appendTimingPart(timingParts, "movement-sync", movementStartTime, 10)

    local tooltipStartTime = timingParts and getTimingNowMilliseconds() or nil
    bumpAllEventTooltipContextRevisions(nextState)
    if self.InvalidatePendingSpellTargetingDisplayState then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    appendTimingPart(timingParts, "tooltip-context", tooltipStartTime, 10)

    local visualsStartTime = timingParts and getTimingNowMilliseconds() or nil
    queueSharedEventVisualRefresh(self, "event-start", {
        eventWidget = true,
        targeting = true,
        actionBar = false,
    })
    appendTimingPart(timingParts, "visual-queue", visualsStartTime, 10)

    local startupQueueStartTime = timingParts and getTimingNowMilliseconds() or nil
    refreshEventStartupPhase(nextState, startupRuntime)
    queueEventStartupWork(self, nextState, "event-start")
    appendTimingPart(timingParts, "startup-queue", startupQueueStartTime, 10)

    if timingParts then
        logTimingParts("HandleEventStart", "event-start-handler", timingParts, getTimingNowMilliseconds() - totalStartTime, 25)
    end
    if timer then
        stopEventTiming(timer, nextState, {
            eventId = nextState.id,
            startupQueued = 1,
        })
    end
    return true
end

function Client:HandleEventEnd(arguments)
    local state = self.EventState
    if not state then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or state.channelName ~= channelName then
        return false
    end

    local eventId = arguments and arguments[2] or nil
    if state.id and state.id ~= "" and eventId and eventId ~= "" and state.id ~= eventId then
        return false
    end

    local reason = arguments and arguments[3] or "ended"
    local activeTransition = self.EventTransition
    if state.ending == true
        and type(activeTransition) == "table"
        and activeTransition.kind == "ending"
        and activeTransition.eventState == state
    then
        return true
    end

    local timer = startTiming("Event end immediate handler", 8, reason)
    cancelEventSliceableWork(self, state.id, "event-ending")
    local startupRuntime = getEventStartupRuntime(self, state.id, false)
    if type(startupRuntime) == "table" then
        startupRuntime.consumablePromptPending = false
    end
    if type(self.CancelDeferredConsumablePrompt) == "function" then
        self:CancelDeferredConsumablePrompt(state, "event_start")
    end
    local transition = self:BeginEventTransition("ending", state.id)
    transition.eventState = state
    state.ending = true
    state.startupReady = false
    local transaction
    if type(Runtime) == "table" and type(Runtime.BeginTransaction) == "function" then
        transaction = Runtime:BeginTransaction("event-end:" .. tostring(state.id), { eventId = state.id })
        transition.transaction = transaction
        transition.transactionId = transaction and transaction.id or nil
    end
    local endWork = {
        client = self,
        eventId = tostring(state.id or ""),
        eventState = state,
        transitionGeneration = transition.generation,
        reason = reason,
        phase = "achievement",
        promptResolved = false,
    }

    local queued = queueEventEndWork(self, state, transition, reason, endWork)
    queueSharedEventVisualRefresh(self, "event-ending", {
        eventWidget = true,
        targeting = true,
        actionBar = true,
    })
    if timer then
        stopEventTiming(timer, state, { promptQueued = queued and 1 or 0 })
    end
    if not queued then
        clearEventStateNow(self, state, reason, { cancelReason = "event-end-queue-failed" })
    end
    return true
end

function Client:HandleEventUnits(arguments)
    local totalStartTime = getTimingNowMilliseconds()
    local timingParts = totalStartTime > 0 and {} or nil
    local sessionState = self:GetState()
    local eventState = self.EventState
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true or eventState.ending == true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or sessionState.channelName ~= channelName then
        return false
    end

    local eventId = arguments and arguments[2] or nil
    if eventState.id and eventState.id ~= "" and eventId and eventId ~= "" and eventState.id ~= eventId then
        return false
    end

    local previousTurnNumber = tonumber(eventState.turnNumber) or 0
    local previousTickNumber = tonumber(eventState.tickNumber) or 0
    local wasLocalTurn = self.IsLocalTurnActive and self:IsLocalTurnActive(eventState) or false
    local startupRuntime = getEventStartupRuntime(self, eventState.id, true)
    local deserializeStartTime = timingParts and getTimingNowMilliseconds() or nil
    local units = Event.DeserializeUnitsFromNetwork(arguments and arguments[3] or "")
    appendTimingPart(timingParts, "deserialize-units", deserializeStartTime, 15)

    local resourcesStartTime = timingParts and getTimingNowMilliseconds() or nil
    if ResourceSync.ApplyTrackedPlayerResourcesToEventUnits then
        ResourceSync.ApplyTrackedPlayerResourcesToEventUnits(sessionState.membersByName, units)
    end
    applyLocalProfileResourcesToEventUnits(sessionState, units)
    appendTimingPart(timingParts, "apply-resources", resourcesStartTime, 10)

    local readinessStartTime = timingParts and getTimingNowMilliseconds() or nil
    eventState.units = units
    eventState.rosterReady = true
    eventState.unitsChunkReceived = eventState.unitsChunkExpected or eventState.unitsChunkReceived or 0
    if ResourceSync.UpdateEventReadiness then
        ResourceSync.UpdateEventReadiness(eventState)
    end
    refreshEventStartupPhase(eventState, startupRuntime)
    appendTimingPart(timingParts, "readiness", readinessStartTime, 10)

    local cooldownStartTime = timingParts and getTimingNowMilliseconds() or nil
    if self.PruneCooldownState then
        self:PruneCooldownState(eventState)
    end
    appendTimingPart(timingParts, "cooldown-prune", cooldownStartTime, 10)
    if Addon.Server and Addon.Server.EventState and Addon.Server.EventState.id == eventState.id then
        Addon.Server.EventState.healthResourceRef = eventState.healthResourceRef
        Addon.Server.EventState.rosterReady = eventState.rosterReady
        Addon.Server.EventState.unitsReady = eventState.unitsReady
        Addon.Server.EventState.resourcesReady = eventState.resourcesReady
        Addon.Server.EventState.unitsChunkReceived = eventState.unitsChunkReceived
        Addon.Server.EventState.unitsChunkExpected = eventState.unitsChunkExpected
        Addon.Server.EventState.healthResourcesReceived = eventState.healthResourcesReceived
        Addon.Server.EventState.healthResourcesExpected = eventState.healthResourcesExpected
        Addon.Server.EventState.readyProgressReceived = eventState.readyProgressReceived
        Addon.Server.EventState.readyProgressExpected = eventState.readyProgressExpected
    end
    local movementStartTime = timingParts and getTimingNowMilliseconds() or nil
    queueDeferredMovementSync(self, wasLocalTurn, eventState, previousTurnNumber, previousTickNumber, "event-units")
    appendTimingPart(timingParts, "movement-sync", movementStartTime, 10)

    local tooltipStartTime = timingParts and getTimingNowMilliseconds() or nil
    bumpAllEventTooltipContextRevisions(eventState)
    if self.InvalidatePendingSpellTargetingDisplayState then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    appendTimingPart(timingParts, "tooltip-context", tooltipStartTime, 10)

    local visualsStartTime = timingParts and getTimingNowMilliseconds() or nil
    queueSharedEventVisualRefresh(self, "event-units", {
        eventWidget = true,
        targeting = true,
        actionBar = false,
    })
    appendTimingPart(timingParts, "visual-queue", visualsStartTime, 10)

    local startupQueueStartTime = timingParts and getTimingNowMilliseconds() or nil
    queueEventStartupWork(self, eventState, "event-units")
    appendTimingPart(timingParts, "startup-queue", startupQueueStartTime, 10)

    if timingParts then
        logTimingParts("HandleEventUnits", "event-units-handler", timingParts, getTimingNowMilliseconds() - totalStartTime, 30)
    end
    return true
end

function Client:HandleEventUnitDeltaBatch(arguments)
    local sessionState = self:GetState()
    local eventState = self.EventState
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true or eventState.ending == true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or sessionState.channelName ~= channelName then
        return false
    end

    local eventId = arguments and arguments[2] or nil
    if eventState.id and eventState.id ~= "" and eventId and eventId ~= "" and eventState.id ~= eventId then
        return false
    end

    local entries = Event and Event.DeserializeUnitDeltaBatchFromNetwork and Event.DeserializeUnitDeltaBatchFromNetwork(arguments and arguments[3] or "") or {}
    if #entries == 0 then
        return false
    end

    local wasLocalTurn = self.IsLocalTurnActive and self:IsLocalTurnActive(eventState) or false
    eventState.units = eventState.units or {}
    local changed = false
    for index = 1, #entries do
        local entry = entries[index]
        if entry.operation == "remove" then
            changed = removeEventUnitById(eventState.units, entry.eventID) ~= nil or changed
        elseif entry.operation == "upsert" and entry.unit then
            changed = upsertAppendedEventUnit(eventState.units, hydrateInboundEventUnit(entry.unit, eventState)) or changed
        end
    end

    if not changed then
        return false
    end

    if ResourceSync.ApplyTrackedPlayerResourcesToEventUnits then
        ResourceSync.ApplyTrackedPlayerResourcesToEventUnits(sessionState.membersByName, eventState.units)
    end
    applyLocalProfileResourcesToEventUnits(sessionState, eventState.units)
    if ResourceSync.UpdateEventReadiness then
        ResourceSync.UpdateEventReadiness(eventState)
    end
    if self.PruneCooldownState then
        self:PruneCooldownState(eventState)
    end
    syncMovementTracking(self, wasLocalTurn, eventState)
    bumpAllEventTooltipContextRevisions(eventState)
    if self.InvalidatePendingSpellTargetingDisplayState then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    queueSharedEventVisualRefresh(self, "event-unit-delta-batch", {
        eventWidget = true,
        targeting = true,
        actionBar = true,
    })
    queueEventTraitRuntimeRefresh(self, eventState, "event-unit-delta-batch")
    local auraManager = self.Spellcasting and self.Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.RecheckAuraOwnerOccurrences) == "function" then
        auraManager:RecheckAuraOwnerOccurrences(self)
    end
    return true
end

function Client:HandleInboundChunkProgress(packet, receivedCount, distribution, sender, target, startedAtMs)
    if not packet or packet.opcode ~= getEventUnitsOpcode() then
        return false
    end

    local eventState = self.EventState
    if not eventState or eventState.active ~= true or eventState.ending == true or eventState.unitsReady == true then
        return false
    end

    local expectedCount = math.max(0, tonumber(packet.partCount) or 0)
    local received = math.max(0, tonumber(receivedCount) or 0)
    eventState.unitsChunkExpected = expectedCount
    eventState.unitsChunkReceived = received
    if ResourceSync.UpdateEventReadiness then
        ResourceSync.UpdateEventReadiness(eventState)
    end
    refreshEventStartupPhase(eventState, getEventStartupRuntime(self, eventState.id, true))

    if Addon.Server and Addon.Server.EventState and Addon.Server.EventState.id == eventState.id then
        Addon.Server.EventState.healthResourceRef = eventState.healthResourceRef
        Addon.Server.EventState.rosterReady = eventState.rosterReady
        Addon.Server.EventState.unitsReady = eventState.unitsReady
        Addon.Server.EventState.resourcesReady = eventState.resourcesReady
        Addon.Server.EventState.unitsChunkExpected = eventState.unitsChunkExpected
        Addon.Server.EventState.unitsChunkReceived = eventState.unitsChunkReceived
        Addon.Server.EventState.healthResourcesReceived = eventState.healthResourcesReceived
        Addon.Server.EventState.healthResourcesExpected = eventState.healthResourcesExpected
        Addon.Server.EventState.readyProgressReceived = eventState.readyProgressReceived
        Addon.Server.EventState.readyProgressExpected = eventState.readyProgressExpected
    end

    if startedAtMs and tonumber(packet.partCount) and tonumber(packet.partCount) > 1 then
        logTimingParts(
            ("EVENT_UNITS %d/%d"):format(received, expectedCount),
            "event-receive-progress",
            nil,
            getTimingNowMilliseconds() - (tonumber(startedAtMs) or 0),
            25
        )
    end

    self:QueueEventWidgetRefresh("event-units-progress")
    return true
end

function Comms:HandleInboundChunkProgress(packet, receivedCount, distribution, sender, target)
    return Client:HandleInboundChunkProgress(packet, receivedCount, distribution, sender, target)
end

function Client:HandleEventState(arguments)
    local totalStartTime = getTimingNowMilliseconds()
    local timingParts = totalStartTime > 0 and {} or nil
    local sessionState = self:GetState()
    local eventState = self.EventState
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true or eventState.ending == true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or sessionState.channelName ~= channelName then
        return false
    end

    local eventId = arguments and arguments[2] or nil
    if eventState.id and eventState.id ~= "" and eventId and eventId ~= "" and eventState.id ~= eventId then
        return false
    end

    local timer = startTiming("Event-state immediate handler", 8, eventState.id or "event-state")

    local previousTurnNumber = tonumber(eventState.turnNumber) or 0
    local previousTickNumber = tonumber(eventState.tickNumber) or 0
    local wasLocalTurn = self.IsLocalTurnActive and self:IsLocalTurnActive(eventState) or false
    local wasLocalPlayerTurn = isLocalPlayerTurnActive(self, eventState)
    local startupRuntime = getEventStartupRuntime(self, eventState.id, true)

    local stateApplyStartTime = timingParts and getTimingNowMilliseconds() or nil
    if Event and Event.ApplyStateArguments then
        Event.ApplyStateArguments(eventState, arguments)
    else
        eventState.turnNumber = tonumber(arguments and arguments[3]) or eventState.turnNumber or 0
        eventState.tickNumber = tonumber(arguments and arguments[4]) or eventState.tickNumber or 0
        eventState.totalTicks = tonumber(arguments and arguments[5]) or eventState.totalTicks or 0
    end
    appendTimingPart(timingParts, "apply-state", stateApplyStartTime, 10)
    if startupRuntime then
        startupRuntime.startupStateReceived = true
        refreshEventStartupPhase(eventState, startupRuntime)
    end

    if previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
        or previousTickNumber ~= (tonumber(eventState.tickNumber) or 0)
    then
        self.TurnEndPending = false
    end

    local advanceStateStartTime = timingParts and getTimingNowMilliseconds() or nil
    if self.AdvanceSpellcastState then
        self:AdvanceSpellcastState(previousTurnNumber, previousTickNumber)
    end
    if self.AdvanceCooldownState then
        self:AdvanceCooldownState(previousTurnNumber, previousTickNumber)
    end
    if self.AdvanceAuraState then
        self:AdvanceAuraState(previousTurnNumber, previousTickNumber)
    end
    appendTimingPart(timingParts, "advance-state", advanceStateStartTime, 15)

    local turnEffectsStartTime = timingParts and getTimingNowMilliseconds() or nil
    local turnEffectParts = turnEffectsStartTime and {} or nil
    local isLocalTurn = self.IsLocalTurnActive and self:IsLocalTurnActive(eventState) or false
    local isLocalPlayerTurn = isLocalPlayerTurnActive(self, eventState)
    local stepAdvanced = previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
        or previousTickNumber ~= (tonumber(eventState.tickNumber) or 0)
    local turnAnnouncementStartTime = turnEffectParts and getTimingNowMilliseconds() or nil
    if previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0) then
        local eventName = getEventDisplayName(eventState)
        local turnNumber = math.max(1, tonumber(eventState.turnNumber) or 1)
        deferEventPresentation(function(name, announcedTurnNumber)
            emitTurnStartAnnouncement({
                name = name,
                turnNumber = announcedTurnNumber,
            })
        end, eventName, turnNumber)
    end
    appendTimingPart(turnEffectParts, "announcements", turnAnnouncementStartTime, 10)
    local turnCueStartTime = turnEffectParts and getTimingNowMilliseconds() or nil
    if stepAdvanced and not wasLocalPlayerTurn and isLocalPlayerTurn then
        deferEventPresentation(function()
            playLocalTurnStartSound()
            emitLocalTurnStartAnnouncement()
        end)
    end
    appendTimingPart(turnEffectParts, "local-turn-cue", turnCueStartTime, 10)
    local regenStartTime = turnEffectParts and getTimingNowMilliseconds() or nil
    if previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
        and isLocalTurn
        and type(self.ApplyLocalTurnStartResourceRegeneration) == "function"
    then
        self:ApplyLocalTurnStartResourceRegeneration(sessionState, eventState, {
            suppressLocalVisualRefresh = true,
        })
    end
    appendTimingPart(turnEffectParts, "resource-regen", regenStartTime, 15)
    local movementStartTime = turnEffectParts and getTimingNowMilliseconds() or nil
    queueDeferredMovementSync(self, wasLocalTurn, eventState, previousTurnNumber, previousTickNumber, "event-state")
    appendTimingPart(turnEffectParts, "movement", movementStartTime, 10)
    if turnEffectParts then
        logTimingParts(
            "HandleEventState turn-effects",
            "event-state-turn-effects",
            turnEffectParts,
            getTimingNowMilliseconds() - turnEffectsStartTime,
            15
        )
    end
    appendTimingPart(timingParts, "turn-effects", turnEffectsStartTime, 15)

    local tooltipStartTime = timingParts and getTimingNowMilliseconds() or nil
    bumpAllEventTooltipContextRevisions(eventState)
    if self.InvalidatePendingSpellTargetingDisplayState then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    appendTimingPart(timingParts, "tooltip-context", tooltipStartTime, 10)

    local visualsStartTime = timingParts and getTimingNowMilliseconds() or nil
    queueSharedEventVisualRefresh(self, "event-state", {
        eventWidget = true,
        targeting = true,
        actionBar = false,
    })
    appendTimingPart(timingParts, "visual-queue", visualsStartTime, 10)

    local startupQueueStartTime = timingParts and getTimingNowMilliseconds() or nil
    queueEventStartupWork(self, eventState, "event-state")
    appendTimingPart(timingParts, "startup-queue", startupQueueStartTime, 10)

    if timingParts then
        logTimingParts("HandleEventState", "event-state-handler", timingParts, getTimingNowMilliseconds() - totalStartTime, 25)
    end
    if timer then
        local activeCasts, activeAuras = getActiveEventCardinality(self, eventState)
        stopEventTiming(timer, eventState, {
            activeCasts = activeCasts,
            activeAuras = activeAuras,
            turnNumber = tonumber(eventState.turnNumber) or 0,
            tickNumber = tonumber(eventState.tickNumber) or 0,
        })
    end
    return true
end
