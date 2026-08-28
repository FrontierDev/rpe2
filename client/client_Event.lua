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

local function getEventStepNowMilliseconds()
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

    local elapsedMs = math.max(0, getEventStepNowMilliseconds() - startedAtMs)
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
Client.EventStepWork = Client.EventStepWork or nil
Client.PendingEventStatePackets = Client.PendingEventStatePackets or {}
Client.LastEventStepDiagnostics = Client.LastEventStepDiagnostics or nil
Client.LastEventEndReason = Client.LastEventEndReason or nil
Client.EventWidgetRefreshQueued = Client.EventWidgetRefreshQueued or false
Client.EventStartupRuntimeByEventId = Client.EventStartupRuntimeByEventId or {}
Client.ControlledEventUnitId = Client.ControlledEventUnitId or nil
Client.TurnEndPending = Client.TurnEndPending or false
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
        or normalizedKind == "advancing"
        and "Event-step total transition"
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
        startedAtMs = getEventStepNowMilliseconds(),
        totalTimer = startTiming(totalLabel, 16, normalizedEventId),
        phaseTimings = {},
        lastSliceElapsedMs = 0,
        maxSliceElapsedMs = 0,
        maxSliceLabel = nil,
        contextId = ("event:%s:%s:%d"):format(normalizedKind, normalizedEventId, self.EventTransitionGeneration),
        transactionContextId = ("event:%s:%s:%d"):format(normalizedKind, normalizedEventId, self.EventTransitionGeneration),
        stepDiagnostics = normalizedKind == "advancing" and {
            immediateElapsedMs = 0,
            phaseTimings = {},
            sliceTimings = {},
            castsInspected = 0,
            castsProcessed = 0,
            cooldownsInspected = 0,
            cooldownsProcessed = 0,
            aurasInspected = 0,
            aurasProcessed = 0,
            dirtyScopes = {},
            maxPhaseElapsedMs = 0,
            maxPhase = nil,
            maxSliceElapsedMs = 0,
            maxSlicePhase = nil,
        } or nil,
    }
    if type(transition.eventState) == "table" then
        transition.eventState.transitionPhase = transition.phase
    end
    self.EventTransition = transition
    -- Advancing is packet-driven and must keep its immediate path limited to
    -- state/transition setup.  The dashboard is refreshed when the transition
    -- reaches its release point (and call-time guards cover the interval).
    if normalizedKind ~= "advancing" then
        refreshEventManageDashboard()
    end
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
    transition.totalElapsedMs = 0
    if tonumber(transition.startedAtMs) and tonumber(transition.startedAtMs) > 0 then
        transition.totalElapsedMs = math.max(0, getEventStepNowMilliseconds() - transition.startedAtMs)
    end
    if transition.totalTimer then
        local totalCardinality = {
            transitionKind = transition.kind,
            transitionPhase = transition.phase,
            transitionGeneration = transition.generation,
            transitionReason = reason,
            transitionElapsedMs = transition.totalElapsedMs,
        }
        if type(transition.stepDiagnostics) == "table" then
            totalCardinality.eventStepImmediateMs = transition.stepDiagnostics.immediateElapsedMs or 0
            totalCardinality.eventStepPhaseTimings = transition.stepDiagnostics.phaseTimings
            totalCardinality.eventStepSliceTimings = transition.stepDiagnostics.sliceTimings
            totalCardinality.castsInspected = transition.stepDiagnostics.castsInspected or 0
            totalCardinality.castsProcessed = transition.stepDiagnostics.castsProcessed or 0
            totalCardinality.cooldownsInspected = transition.stepDiagnostics.cooldownsInspected or 0
            totalCardinality.cooldownsProcessed = transition.stepDiagnostics.cooldownsProcessed or 0
            totalCardinality.aurasInspected = transition.stepDiagnostics.aurasInspected or 0
            totalCardinality.aurasProcessed = transition.stepDiagnostics.aurasProcessed or 0
            totalCardinality.dirtyScopes = transition.stepDiagnostics.dirtyScopes
            transition.stepDiagnostics.dirtyScopeCount = countMap(transition.stepDiagnostics.dirtyScopes)
            totalCardinality.dirtyScopeCount = transition.stepDiagnostics.dirtyScopeCount
            totalCardinality.maxPhaseElapsedMs = transition.stepDiagnostics.maxPhaseElapsedMs or 0
            totalCardinality.maxSliceElapsedMs = transition.stepDiagnostics.maxSliceElapsedMs or 0
            totalCardinality.maxSlicePhase = transition.stepDiagnostics.maxSlicePhase
        end
        stopEventTiming(transition.totalTimer, eventState, totalCardinality)
        transition.totalTimer = nil
    end
    if transition.kind == "advancing" then
        self.LastEventStepDiagnostics = transition.stepDiagnostics
        if type(self.LastEventStepDiagnostics) == "table" then
            self.LastEventStepDiagnostics.transitionElapsedMs = transition.totalElapsedMs or 0
        end
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
        if transition.kind == "advancing" and self.EventStepInternal == true then
            return true
        end
        return false, transition.kind == "ending" and "event-ending"
            or transition.kind == "advancing" and "event-advancing"
            or "event-starting"
    end
    local auraManager = self.Spellcasting and self.Spellcasting.AuraManager or nil
    if type(auraManager) == "table"
        and type(self.PendingFullAuraDerivedStateRefreshByEventId) == "table"
        and self.PendingFullAuraDerivedStateRefreshByEventId[tostring(state.id or "")] ~= nil
        and self.EventStepInternal ~= true
    then
        return false, "event-derived-state"
    end
    if state.startupReady ~= true then
        return false, "event-startup"
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
    if eventState.unitsReady ~= true then
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
    if options.eventWidget ~= false then
        if type(options.eventIds) == "table"
            and #options.eventIds > 0
            and type(client.QueueEventWidgetTargetedRefresh) == "function"
        then
            refreshed = client:QueueEventWidgetTargetedRefresh(normalizedReason, options.eventIds) or refreshed
        elseif type(client.QueueEventWidgetRefresh) == "function" then
            refreshed = client:QueueEventWidgetRefresh(normalizedReason) or refreshed
        end
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

local function syncMovementTracking(client, wasLocalTurn, eventState, previousTurnNumber, previousTickNumber, turnOptions)
    local tracker = getMovementTracker()
    if not tracker then
        return false
    end

    local isLocalTurn = client.IsLocalTurnActive
        and client:IsLocalTurnActive(eventState, turnOptions)
        or false
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
        Debug.Error("Event transition sliceable queue unavailable: Addon.Internal.Tasks is missing EnqueueSliceable.")
    end
    return nil
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

local function queueDeferredMovementSync(client, wasLocalTurn, eventState, previousTurnNumber, previousTickNumber, reason, turnOptions)
    local expectedEventId = tostring(type(eventState) == "table" and eventState.id or "")
    if expectedEventId == "" then
        return false
    end

    return enqueueClientTask(function(targetClient, queuedEventId, queuedEventState, queuedTransitionGeneration, queuedWasLocalTurn, queuedPreviousTurnNumber, queuedPreviousTickNumber, queuedReason, queuedTurnOptions)
        if type(targetClient) ~= "table" then
            return
        end

        local currentEventState = targetClient.GetEventState and targetClient:GetEventState() or targetClient.EventState
        if type(currentEventState) ~= "table"
            or currentEventState.active ~= true
            or currentEventState.ending == true
            or tostring(currentEventState.id or "") ~= queuedEventId
            or (queuedEventState ~= nil and currentEventState ~= queuedEventState)
        then
            return
        end

        local currentTransition = targetClient.EventTransition
        if type(currentTransition) == "table"
            and queuedTransitionGeneration ~= nil
            and tonumber(currentTransition.generation) ~= tonumber(queuedTransitionGeneration)
        then
            return
        end

        syncMovementTracking(
            targetClient,
            queuedWasLocalTurn == true,
            currentEventState,
            queuedPreviousTurnNumber,
            queuedPreviousTickNumber,
            queuedTurnOptions
        )
    end, client, expectedEventId, eventState, getTransitionGeneration(client), wasLocalTurn == true, previousTurnNumber, previousTickNumber, reason, turnOptions)
end

local tryQueueInitialLocalResourceSync
local queueNextEventStatePacket

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

    if eventState.unitsReady ~= true then
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
                    if type(queueNextEventStatePacket) == "function" then
                        queueNextEventStatePacket(targetClient, work and work.eventState)
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

-- The order below is the order observed in the pre-refactor
-- HandleEventState() call graph:
--   apply state -> AdvanceSpellcastState (including local completion) ->
--   AdvanceCooldownState -> AdvanceAuraState (aura work was queued FIFO) ->
--   turn announcement -> local-turn cue -> local turn-start regeneration ->
--   deferred movement/ownership sync -> tooltip context/targeting invalidation
--   -> shared event/targeting visual queue -> startup queue.
-- The phase names make that dependency explicit without moving any gameplay
-- effect to a different semantic position.
local EVENT_ADVANCE_PHASES = {
    "advance-casts",
    "complete-casts",
    "advance-cooldowns",
    "advance-auras",
    "turn-effects",
    "tooltip-invalidation",
    "network-resource-flush",
    "commit-runtime",
    "presentation",
}

local function compareEventStep(leftTurn, leftTick, rightTurn, rightTick)
    local normalizedLeftTurn = tonumber(leftTurn) or 0
    local normalizedRightTurn = tonumber(rightTurn) or 0
    if normalizedLeftTurn ~= normalizedRightTurn then
        return normalizedLeftTurn < normalizedRightTurn and -1 or 1
    end

    local normalizedLeftTick = tonumber(leftTick) or 0
    local normalizedRightTick = tonumber(rightTick) or 0
    if normalizedLeftTick == normalizedRightTick then
        return 0
    end
    return normalizedLeftTick < normalizedRightTick and -1 or 1
end

local function getEventStatePacketStep(arguments, eventState)
    local usesLevelField = type(arguments) == "table" and #arguments >= 6
    local fallbackTurn = tonumber(eventState and eventState.turnNumber) or 0
    local fallbackTick = tonumber(eventState and eventState.tickNumber) or 0
    local fallbackTotalTicks = tonumber(eventState and eventState.totalTicks) or 0
    return tonumber(arguments and arguments[usesLevelField and 4 or 3]) or fallbackTurn,
        tonumber(arguments and arguments[usesLevelField and 5 or 4]) or fallbackTick,
        tonumber(arguments and arguments[usesLevelField and 6 or 5]) or fallbackTotalTicks
end

local function copyEventStateArguments(arguments)
    if type(arguments) ~= "table" then
        return nil
    end

    local copy = {}
    for key, value in pairs(arguments) do
        copy[key] = value
    end
    return copy
end

local function stageEventStatePacket(client, eventId, arguments, turnNumber, tickNumber, totalTicks)
    if type(client) ~= "table" or tostring(eventId or "") == "" then
        return false
    end

    client.PendingEventStatePackets = client.PendingEventStatePackets or {}
    local normalizedEventId = tostring(eventId)
    local packets = client.PendingEventStatePackets[normalizedEventId]
    if type(packets) ~= "table" then
        packets = {}
        client.PendingEventStatePackets[normalizedEventId] = packets
    end

    for index = 1, #packets do
        local pending = packets[index]
        if compareEventStep(turnNumber, tickNumber, pending.turnNumber, pending.tickNumber) == 0 then
            return false
        end
    end

    packets[#packets + 1] = {
        arguments = copyEventStateArguments(arguments),
        turnNumber = tonumber(turnNumber) or 0,
        tickNumber = tonumber(tickNumber) or 0,
        totalTicks = tonumber(totalTicks) or 0,
    }
    return true
end

local function takeNextEventStatePacket(client, eventState)
    local eventId = tostring(eventState and eventState.id or "")
    local packets = client and client.PendingEventStatePackets and client.PendingEventStatePackets[eventId] or nil
    if type(packets) ~= "table" then
        return nil
    end

    local currentTurn = tonumber(eventState and eventState.turnNumber) or 0
    local currentTick = tonumber(eventState and eventState.tickNumber) or 0
    local candidateIndex = nil
    for index = 1, #packets do
        local pending = packets[index]
        if compareEventStep(pending.turnNumber, pending.tickNumber, currentTurn, currentTick) > 0
            and (candidateIndex == nil
                or compareEventStep(
                    pending.turnNumber,
                    pending.tickNumber,
                    packets[candidateIndex].turnNumber,
                    packets[candidateIndex].tickNumber
                ) < 0)
        then
            candidateIndex = index
        end
    end

    if candidateIndex == nil then
        return nil
    end
    local pending = table.remove(packets, candidateIndex)
    if #packets == 0 then
        client.PendingEventStatePackets[eventId] = nil
    end
    return pending
end

queueNextEventStatePacket = function(client, eventState)
    local pending = takeNextEventStatePacket(client, eventState)
    if not pending or type(pending.arguments) ~= "table" then
        return false
    end

    return enqueueClientTask(function(targetClient, queuedArguments)
        if type(targetClient) == "table" and type(targetClient.HandleEventState) == "function" then
            targetClient:HandleEventState(queuedArguments)
        end
    end, client, pending.arguments)
end

local function markEventStepDirty(work, scope)
    local diagnostics = work and work.diagnostics or nil
    if type(diagnostics) ~= "table" then
        return
    end
    diagnostics.dirtyScopes = diagnostics.dirtyScopes or {}
    diagnostics.dirtyScopes[tostring(scope or "event")] = true
end

local function getEventStepAffectedEventIds(work)
    local result = {}
    if type(work and work.affectedEventUnitList) == "table" then
        for index = 1, #work.affectedEventUnitList do
            result[index] = work.affectedEventUnitList[index]
        end
        return result
    end
    local seen = {}
    for eventUnitId in pairs(work and work.affectedEventUnitIds or {}) do
        local numericEventUnitId = tonumber(eventUnitId) or 0
        if numericEventUnitId > 0 and not seen[numericEventUnitId] then
            seen[numericEventUnitId] = true
            result[#result + 1] = numericEventUnitId
        end
    end
    return result
end

local function recordEventStepContinuationDiagnostics(work, continuation, scope, inspected, processed)
    local diagnostics = work and work.diagnostics or nil
    if type(diagnostics) ~= "table" or type(continuation) ~= "table" then
        return
    end

    work.continuationDiagnosticCursors = work.continuationDiagnosticCursors or {}
    local cursor = work.continuationDiagnosticCursors[scope]
    if type(cursor) ~= "table" then
        cursor = { inspected = 0, processed = 0 }
        work.continuationDiagnosticCursors[scope] = cursor
    end

    local inspectedTotal = math.max(0, math.floor(tonumber(inspected and inspected(continuation)) or 0))
    local processedTotal = math.max(0, math.floor(tonumber(processed and processed(continuation)) or 0))
    diagnostics[scope .. "Inspected"] = (tonumber(diagnostics[scope .. "Inspected"]) or 0)
        + math.max(0, inspectedTotal - cursor.inspected)
    diagnostics[scope .. "Processed"] = (tonumber(diagnostics[scope .. "Processed"]) or 0)
        + math.max(0, processedTotal - cursor.processed)
    cursor.inspected = inspectedTotal
    cursor.processed = processedTotal

    local affectedList = continuation.affectedEventUnitList
    if type(affectedList) == "table" then
        for index = 1, #affectedList do
            local eventUnitId = tonumber(affectedList[index]) or 0
            if eventUnitId > 0 and not work.affectedEventUnitIds[eventUnitId] then
                work.affectedEventUnitIds[eventUnitId] = true
                work.affectedEventUnitList[#work.affectedEventUnitList + 1] = eventUnitId
            end
        end
    else
        for eventUnitId in pairs(continuation.affectedEventUnitIds or {}) do
            local numericEventUnitId = tonumber(eventUnitId) or 0
            if numericEventUnitId > 0 and not work.affectedEventUnitIds[numericEventUnitId] then
                work.affectedEventUnitIds[numericEventUnitId] = true
                work.affectedEventUnitList[#work.affectedEventUnitList + 1] = numericEventUnitId
            end
        end
    end
end

local function beginEventStepPhase(work, phase)
    local transition = work and work.client and work.client.EventTransition or nil
    work.phase = phase
    work.phaseStartedAtMs = getEventStepNowMilliseconds()
    if type(transition) == "table" then
        transition.phase = phase
        transition.continuation = work
        if type(work.eventState) == "table" then
            work.eventState.transitionPhase = phase
        end
    end
end

local function finishEventStepPhase(work, phase)
    local transition = work and work.client and work.client.EventTransition or nil
    local elapsedMs = 0
    if tonumber(work and work.phaseStartedAtMs) and tonumber(work.phaseStartedAtMs) > 0 then
        elapsedMs = math.max(0, getEventStepNowMilliseconds() - work.phaseStartedAtMs)
    end

    local diagnostics = work and work.diagnostics or nil
    if type(diagnostics) == "table" then
        diagnostics.phaseTimings = diagnostics.phaseTimings or {}
        local phaseTiming = diagnostics.phaseTimings[phase]
        if type(phaseTiming) ~= "table" then
            phaseTiming = { elapsedMs = 0, slices = 0 }
            diagnostics.phaseTimings[phase] = phaseTiming
        end
        phaseTiming.elapsedMs = (tonumber(phaseTiming.elapsedMs) or 0) + elapsedMs
        phaseTiming.slices = (tonumber(phaseTiming.slices) or 0) + 1
        if elapsedMs > (tonumber(diagnostics.maxPhaseElapsedMs) or 0) then
            diagnostics.maxPhaseElapsedMs = elapsedMs
            diagnostics.maxPhase = phase
        end
    end
    if type(transition) == "table" then
        transition.phaseTimings[#transition.phaseTimings + 1] = {
            label = phase,
            elapsedMs = elapsedMs,
            thresholdMs = 8,
        }
    end
    work.phaseStartedAtMs = nil
end

local function runEventStepTransaction(work, phase, callback)
    local client = work and work.client or nil
    local transition = client and client.EventTransition or nil
    local reason = (transition and transition.contextId or "event-step") .. ":" .. tostring(phase or "phase")
    local options = {
        eventId = work and work.eventId,
        transitionGeneration = work and work.transitionGeneration,
        contextId = transition and transition.contextId or nil,
    }

    if type(Runtime) ~= "table" or type(Runtime.RunTransaction) ~= "function" then
        return callback()
    end

    -- Runtime keeps one global current transaction.  Event-step continuations
    -- may span frames, but their transactions may not: never join unrelated
    -- work that happens to be current when this slice is resumed.
    if type(Runtime.GetCurrentTransaction) == "function"
        and Runtime:GetCurrentTransaction() ~= nil
    then
        return false, "incomplete"
    end

    local results = { pcall(function()
        return Runtime:RunTransaction(reason, callback, options)
    end) }
    if results[1] ~= true then
        if Debug and Debug.Error then
            Debug.Error("Event-step phase failed: phase=%s error=%s", tostring(phase or ""), tostring(results[2] or ""))
        end
        return nil, "error"
    end

    local summary = type(Runtime.GetLastCommittedSummary) == "function" and Runtime.GetLastCommittedSummary() or nil
    if type(transition) == "table" then
        transition.lastTransactionId = summary and summary.id or transition.lastTransactionId
        transition.transactionId = nil
    end
    return results[2], results[3]
end

local function shouldYieldEventStep(deadlineMs)
    local tasks = Addon.Internal and Addon.Internal.Tasks or nil
    return type(tasks) == "table"
        and type(tasks.ShouldYield) == "function"
        and tasks:ShouldYield(deadlineMs) == true
end

local function eventStepContinuationIsCurrent(work)
    local client = work and work.client or nil
    if type(client) ~= "table"
        or type(work.eventState) ~= "table"
        or work.eventState.ending == true
        or type(client.GetEventState) ~= "function"
        or client:GetEventState() ~= work.eventState
        or tostring(work.eventState.id or "") ~= tostring(work.eventId or "")
        or type(client.IsEventTransitionCurrent) ~= "function"
        or not client:IsEventTransitionCurrent(work.eventId, work.transitionGeneration, "advancing", work.eventState)
    then
        return false
    end
    return true
end

local function ensureEventStepTurnPageIndex(work, deadlineMs)
    if type(work) ~= "table" then
        return nil, "error"
    end
    if type(work.turnPageIndex) == "table" then
        return true, "complete"
    end

    local spellcasting = work.client and work.client.Spellcasting or Addon.Client and Addon.Client.Spellcasting or nil
    if type(spellcasting) ~= "table"
        or type(spellcasting.CreateTurnPageIndexContinuation) ~= "function"
        or type(spellcasting.StepTurnPageIndexContinuation) ~= "function"
    then
        return nil, "error"
    end

    work.turnPageContinuation = work.turnPageContinuation
        or spellcasting.CreateTurnPageIndexContinuation(work.client, work.eventState)
    if type(work.turnPageContinuation) ~= "table" then
        return nil, "error"
    end

    local complete, status = spellcasting.StepTurnPageIndexContinuation(work.turnPageContinuation, deadlineMs)
    if complete == nil then
        return nil, status or "stale"
    end
    if complete ~= true then
        return false, status or "incomplete"
    end

    work.turnPageIndex = work.turnPageContinuation.pageByEventId or {}
    work.turnPageUnitsByEventId = work.turnPageContinuation.unitsByEventId or {}
    work.turnPagePlayerUnitsByName = work.turnPageContinuation.playerUnitsByName or {}
    work.localEventUnit = work.turnPageContinuation.localEventUnit
    return true, "complete"
end

local function runEventAdvanceStep(work, deadlineMs)
    if not eventStepContinuationIsCurrent(work) then
        return nil, "stale"
    end

    local turnPageReady, turnPageStatus = ensureEventStepTurnPageIndex(work, deadlineMs)
    if turnPageReady == nil then
        return nil, turnPageStatus or "error"
    end
    if turnPageReady ~= true then
        return false, "incomplete"
    end

    local client = work.client
    local transition = client.EventTransition
    local completed = false
    while not completed do
        if not eventStepContinuationIsCurrent(work) then
            return nil, "stale"
        end
        if shouldYieldEventStep(deadlineMs) then
            return false, "incomplete"
        end
        local phase = work.phase
        if not phase then
            beginEventStepPhase(work, EVENT_ADVANCE_PHASES[1])
            phase = work.phase
        elseif work.phaseStartedAtMs == nil then
            beginEventStepPhase(work, phase)
        end

        if phase == "advance-casts" then
            if not work.spellcastContinuation then
                work.spellcastContinuation = client:CreateSpellcastAdvanceContinuation(
                    work.previousTurnNumber,
                    work.previousTickNumber,
                    {
                        deferPresentation = true,
                        turnPageIndex = work.turnPageIndex,
                        unitsByEventId = work.turnPageUnitsByEventId,
                        playerUnitsByName = work.turnPagePlayerUnitsByName,
                        localEventUnit = work.localEventUnit,
                    }
                )
            end
            local continuation = work.spellcastContinuation
            if not continuation or continuation.phase == "done" then
                finishEventStepPhase(work, phase)
                beginEventStepPhase(work, "complete-casts")
            else
                local advanced, status = runEventStepTransaction(work, phase, function()
                    return client:StepSpellcastAdvanceContinuation(continuation, deadlineMs)
                end)
                if advanced == nil then
                    return nil, status or "error"
                end
                if advanced ~= true then
                    if continuation.phase == "complete" then
                        finishEventStepPhase(work, phase)
                        beginEventStepPhase(work, "complete-casts")
                    end
                    return false, "incomplete"
                end
                finishEventStepPhase(work, phase)
                beginEventStepPhase(work, "complete-casts")
            end
        elseif phase == "complete-casts" then
            local continuation = work.spellcastContinuation
            if not continuation or continuation.phase == "done" then
                finishEventStepPhase(work, phase)
                beginEventStepPhase(work, "advance-cooldowns")
            else
                local completedCasts, status = runEventStepTransaction(work, phase, function()
                    return client:StepSpellcastAdvanceContinuation(continuation, deadlineMs)
                end)
                if completedCasts == nil then
                    return nil, status or "error"
                end
                if completedCasts ~= true then
                    return false, "incomplete"
                end
                finishEventStepPhase(work, phase)
                beginEventStepPhase(work, "advance-cooldowns")
            end
            recordEventStepContinuationDiagnostics(
                work,
                continuation,
                "casts",
                function(value) return value.inspected end,
                function(value) return value.processed end
            )
            if continuation and continuation.changed then
                markEventStepDirty(work, "casts")
            end
        elseif phase == "advance-cooldowns" then
            if not work.cooldownContinuation then
                work.cooldownContinuation = client:CreateCooldownAdvanceContinuation(
                    work.previousTurnNumber,
                    work.previousTickNumber,
                    {
                        deferPresentation = true,
                        turnPageIndex = work.turnPageIndex,
                        localEventUnit = work.localEventUnit,
                    }
                )
            end
            local continuation = work.cooldownContinuation
            if not continuation or continuation.phase == "done" then
                finishEventStepPhase(work, phase)
                beginEventStepPhase(work, "advance-auras")
            else
                local advanced, status = runEventStepTransaction(work, phase, function()
                    return client:StepCooldownAdvanceContinuation(continuation, deadlineMs)
                end)
                if advanced == nil then
                    return nil, status or "error"
                end
                if advanced ~= true then
                    return false, "incomplete"
                end
                finishEventStepPhase(work, phase)
                beginEventStepPhase(work, "advance-auras")
            end
            recordEventStepContinuationDiagnostics(
                work,
                continuation,
                "cooldowns",
                function(value) return (value.inspectedUnits or 0) + (value.inspectedSpells or 0) end,
                function(value) return (value.processedUnits or 0) + (value.processedSpells or 0) end
            )
            if continuation and continuation.changed then
                markEventStepDirty(work, "cooldowns")
            end
        elseif phase == "advance-auras" then
            if not work.auraContinuation then
                work.auraContinuation = client:CreateAuraAdvanceContinuation(
                    work.previousTurnNumber,
                    work.previousTickNumber,
                    {
                        client = client,
                        deferPresentation = true,
                        turnPageIndex = work.turnPageIndex,
                        unitsByEventId = work.turnPageUnitsByEventId,
                        playerUnitsByName = work.turnPagePlayerUnitsByName,
                        localEventUnit = work.localEventUnit,
                    }
                )
            end
            local continuation = work.auraContinuation
            if not continuation or continuation.phase == "done" then
                finishEventStepPhase(work, phase)
                beginEventStepPhase(work, "turn-effects")
            else
                local advanced, status = runEventStepTransaction(work, phase, function()
                    return client:StepAuraAdvanceContinuation(continuation, deadlineMs)
                end)
                if advanced == nil then
                    return nil, status or "error"
                end
                if advanced ~= true then
                    return false, "incomplete"
                end
                finishEventStepPhase(work, phase)
                beginEventStepPhase(work, "turn-effects")
            end
            recordEventStepContinuationDiagnostics(
                work,
                continuation,
                "auras",
                function(value) return value.inspected end,
                function(value) return value.processed end
            )
            if continuation and continuation.changed then
                markEventStepDirty(work, "auras")
            end
        elseif phase == "turn-effects" then
            local turnEffectsComplete, turnEffectsStatus = runEventStepTransaction(work, phase, function()
                if not work.turnEffectsApplied then
                    local eventState = work.eventState
                    local activeTurnUnit = work.localEventUnit
                    local controlledEventId = tonumber(client.ControlledEventUnitId) or 0
                    local controlledUnit = controlledEventId > 0
                        and work.turnPageUnitsByEventId[controlledEventId]
                        or nil
                    if controlledUnit
                        and controlledUnit.isPlayer ~= true
                        and client:CanControlEventUnit(controlledUnit, eventState, work.localEventUnit)
                    then
                        activeTurnUnit = controlledUnit
                    end
                    local currentTurnOptions = {
                        turnPageIndex = work.turnPageIndex,
                        unitsByEventId = work.turnPageUnitsByEventId,
                        localEventUnit = work.localEventUnit,
                        activeEventUnit = activeTurnUnit,
                        controlContext = { isControlled = activeTurnUnit ~= work.localEventUnit },
                        tickNumber = eventState.tickNumber,
                        turnEndPending = false,
                    }
                    local previousTurnOptions = {
                        turnPageIndex = work.turnPageIndex,
                        unitsByEventId = work.turnPageUnitsByEventId,
                        localEventUnit = work.localEventUnit,
                        tickNumber = work.previousTickNumber,
                        turnEndPending = work.wasTurnEndPending == true,
                    }
                    local isLocalTurn = client.IsLocalTurnActive
                        and client:IsLocalTurnActive(eventState, currentTurnOptions)
                        or false
                    local wasLocalTurn = client.IsLocalTurnActive
                        and client:IsLocalTurnActive(eventState, previousTurnOptions)
                        or false
                    local isLocalPlayerTurn = isLocalPlayerTurnActive(
                        client,
                        eventState,
                        work.turnPageIndex,
                        work.localEventUnit,
                        eventState.tickNumber
                    )
                    local wasLocalPlayerTurn = isLocalPlayerTurnActive(
                        client,
                        eventState,
                        work.turnPageIndex,
                        work.localEventUnit,
                        work.previousTickNumber
                    )
                    if work.previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0) then
                        local eventName = getEventDisplayName(eventState)
                        local turnNumber = math.max(1, tonumber(eventState.turnNumber) or 1)
                        deferEventPresentation(function(name, announcedTurnNumber)
                            emitTurnStartAnnouncement({ name = name, turnNumber = announcedTurnNumber })
                        end, eventName, turnNumber)
                        markEventStepDirty(work, "turn-cues")
                    end
                    if work.stepAdvanced and not work.wasLocalPlayerTurn and isLocalPlayerTurn then
                        deferEventPresentation(function()
                            playLocalTurnStartSound()
                            emitLocalTurnStartAnnouncement()
                        end)
                        markEventStepDirty(work, "turn-cues")
                    end
                    if work.previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
                        and isLocalTurn
                        and type(client.ApplyLocalTurnStartResourceRegeneration) == "function"
                    then
                        client:ApplyLocalTurnStartResourceRegeneration(client:GetState(), eventState, {
                            suppressLocalVisualRefresh = true,
                            activeEventUnit = activeTurnUnit,
                            controlContext = currentTurnOptions.controlContext,
                        })
                        markEventStepDirty(work, "resources")
                        markEventStepDirty(work, "network")
                    end
                    queueDeferredMovementSync(
                        client,
                        work.wasLocalTurn,
                        eventState,
                        work.previousTurnNumber,
                        work.previousTickNumber,
                        "event-state",
                        currentTurnOptions
                    )
                    markEventStepDirty(work, "movement")
                    work.turnEffectsApplied = true
                end
                return true, "complete"
            end)
            if turnEffectsComplete == nil then
                return nil, turnEffectsStatus or "error"
            end
            finishEventStepPhase(work, phase)
            beginEventStepPhase(work, "tooltip-invalidation")
        elseif phase == "tooltip-invalidation" then
            work.tooltipEventIds = work.tooltipEventIds or getEventStepAffectedEventIds(work)
            work.tooltipIndex = (tonumber(work.tooltipIndex) or 1)
            local tooltipEventId = work.tooltipEventIds[work.tooltipIndex]
            if tooltipEventId ~= nil then
                bumpEventTooltipContextRevision(work.eventState, tooltipEventId)
                work.tooltipIndex = work.tooltipIndex + 1
                if shouldYieldEventStep(deadlineMs) then
                    return false, "incomplete"
                end
            else
                if work.tooltipInvalidationFinalized ~= true then
                    if #work.tooltipEventIds == 0 then
                        bumpAllEventTooltipContextRevisions(work.eventState)
                    end
                    if type(client.InvalidatePendingSpellTargetingDisplayState) == "function" then
                        client:InvalidatePendingSpellTargetingDisplayState()
                    end
                    markEventStepDirty(work, "tooltips")
                    markEventStepDirty(work, "targeting")
                    work.tooltipInvalidationFinalized = true
                end
                finishEventStepPhase(work, phase)
                beginEventStepPhase(work, "network-resource-flush")
            end
        elseif phase == "network-resource-flush" then
            -- Resource regeneration queues protocol work in the existing
            -- ResourceSync path.  This phase is an ordering boundary only; it
            -- intentionally adds no packet and changes no protocol meaning.
            work.networkResourceBoundaryReached = true
            finishEventStepPhase(work, phase)
            beginEventStepPhase(work, "commit-runtime")
        elseif phase == "commit-runtime" then
            -- Every mutation slice above ran in a short Runtime transaction.
            -- Never commit or retain a transaction across a TaskQueue yield.
            if type(Runtime) == "table" and type(Runtime.GetCurrentTransaction) == "function"
                and Runtime.GetCurrentTransaction() ~= nil
            then
                return nil, "error"
            end
            finishEventStepPhase(work, phase)
            beginEventStepPhase(work, "presentation")
        elseif phase == "presentation" then
            local affectedEventIds = getEventStepAffectedEventIds(work)
            local localEventId = tonumber(work.localEventUnit and work.localEventUnit.eventID) or 0
            local localEventStateAffected = localEventId > 0 and work.affectedEventUnitIds[localEventId] == true
            local actionBarDirty = work.diagnostics.dirtyScopes["resources"] == true
                or work.diagnostics.dirtyScopes["cooldowns"] == true
                or localEventStateAffected
            if localEventStateAffected and type(client.MarkActionBarCompanionBarsDirty) == "function" then
                client:MarkActionBarCompanionBarsDirty("event-state-step")
            end
            if work.diagnostics.dirtyScopes["auras"] == true
                and type(client.MarkVisiblePlayerTooltipDirty) == "function"
            then
                client:MarkVisiblePlayerTooltipDirty("event-state-step")
            end
            queueSharedEventVisualRefresh(client, "event-state-step", {
                eventWidget = true,
                eventIds = #affectedEventIds > 0 and affectedEventIds or nil,
                targeting = true,
                actionBar = actionBarDirty,
            })
            markEventStepDirty(work, "event-widget")
            markEventStepDirty(work, "presentation")
            finishEventStepPhase(work, phase)
            beginEventStepPhase(work, "release")
            completed = true
        else
            return nil, "error"
        end

        if completed or shouldYieldEventStep(deadlineMs) then
            break
        end
    end

    return completed and true or false, completed and "complete" or "incomplete"
end

local function queueEventAdvanceWork(client, eventState, transition, work)
    local eventId = tostring(eventState and eventState.id or "")
    if type(client) ~= "table" or type(eventState) ~= "table" or eventId == "" then
        return false
    end

    local sliceJob = enqueueClientSliceable({
        label = "event-step",
        scope = "event:" .. eventId,
        state = work,
        isStale = function(currentWork)
            return not eventStepContinuationIsCurrent(currentWork)
        end,
        step = function(currentWork, deadlineMs)
            local targetClient = currentWork and currentWork.client or nil
            local currentTransition = targetClient and targetClient.EventTransition or nil
            local sliceStartedAtMs = getEventStepNowMilliseconds()
            local completed, status = runEventAdvanceStep(currentWork, deadlineMs)
            local elapsedMs = 0
            if sliceStartedAtMs > 0 then
                elapsedMs = math.max(0, getEventStepNowMilliseconds() - sliceStartedAtMs)
            end
            local diagnostics = currentWork and currentWork.diagnostics or nil
            if type(diagnostics) == "table" then
                diagnostics.sliceTimings[#diagnostics.sliceTimings + 1] = {
                    phase = currentWork.phase,
                    elapsedMs = elapsedMs,
                }
                diagnostics.maxSliceElapsedMs = math.max(tonumber(diagnostics.maxSliceElapsedMs) or 0, elapsedMs)
                if elapsedMs >= (tonumber(diagnostics.maxSliceElapsedMs) or 0) then
                    diagnostics.maxSlicePhase = currentWork.phase
                end
            end
            recordTransitionSlice(currentTransition, sliceStartedAtMs, "event-step:" .. tostring(currentWork and currentWork.phase or "unknown"))
            if completed == nil then
                return nil, status or "error"
            end
            return completed == true, status or (completed and "complete" or "incomplete")
        end,
        onCancel = function(currentWork, cancelReason)
            local targetClient = currentWork and currentWork.client or nil
            if type(targetClient) ~= "table" then
                return
            end
            if targetClient.EventStepWork == currentWork then
                targetClient.EventStepWork = nil
            end
            if cancelReason == "error" then
                local currentTransition = targetClient.EventTransition
                if targetClient:IsEventTransitionCurrent(currentWork.eventId, currentWork.transitionGeneration, "advancing", currentWork.eventState) then
                    currentTransition.phase = "error"
                    currentTransition.failed = true
                    currentWork.eventState.transitionPhase = "error"
                end
            elseif cancelReason ~= "stale"
                and targetClient:IsEventTransitionCurrent(currentWork.eventId, currentWork.transitionGeneration, "advancing", currentWork.eventState)
            then
                targetClient:EndEventTransition(currentWork.eventId, currentWork.transitionGeneration, currentWork.eventState, cancelReason)
            end
        end,
        onComplete = function(currentWork)
            local targetClient = currentWork and currentWork.client or nil
            if type(targetClient) ~= "table" then
                return
            end
            local currentTransition = targetClient.EventTransition
            if not targetClient:IsEventTransitionCurrent(currentWork.eventId, currentWork.transitionGeneration, "advancing", currentWork.eventState) then
                return
            end
            targetClient:SetEventTransitionPhase("release", currentWork.eventState)
            if type(currentTransition) == "table" then
                currentTransition.continuation = nil
                currentTransition.stepDiagnostics = currentWork.diagnostics
            end
            if targetClient.EventStepWork == currentWork then
                targetClient.EventStepWork = nil
            end
            targetClient:EndEventTransition(
                currentWork.eventId,
                currentWork.transitionGeneration,
                currentWork.eventState,
                "advance-complete"
            )
            queueNextEventStatePacket(targetClient, currentWork.eventState)
        end,
    })
    if sliceJob then
        work.sliceJob = sliceJob
        transition.continuation = work
        return true
    end
    return false
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

local function isLocalPlayerTurnActive(client, eventState, turnPageIndex, localEventUnit, tickNumber)
    if type(client) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    if type(turnPageIndex) == "table" then
        local localEventId = tonumber(localEventUnit and localEventUnit.eventID) or 0
        local currentTick = math.max(1, math.floor(tonumber(tickNumber or eventState.tickNumber) or 0))
        return localEventId > 0 and tonumber(turnPageIndex[localEventId]) == currentTick
    end

    localEventUnit = localEventUnit
        or (client.ResolveLocalEventUnit and client:ResolveLocalEventUnit(eventState) or nil)
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

function Client:CanControlEventUnit(controlledUnit, eventState, localEventUnitOverride)
    local localEventUnit = localEventUnitOverride or self:ResolveLocalEventUnit(eventState)
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

function Client:IsLocalTurnActive(eventState, options)
    options = type(options) == "table" and options or {}
    local turnEndPending = options.turnEndPending
    if turnEndPending == nil then
        turnEndPending = self.TurnEndPending
    end
    if turnEndPending == true then
        return false
    end

    if type(options.turnPageIndex) == "table" then
        local state = eventState or self:GetEventState()
        local localEventUnit = options.localEventUnit
        if type(state) ~= "table" or state.active ~= true or type(localEventUnit) ~= "table" then
            return false
        end

        local activeUnit = localEventUnit
        local controlledEventId = tonumber(self.ControlledEventUnitId) or 0
        local unitsByEventId = options.unitsByEventId
        local controlledUnit = controlledEventId > 0
            and type(unitsByEventId) == "table"
            and unitsByEventId[controlledEventId]
            or nil
        if controlledUnit
            and controlledUnit.isPlayer ~= true
            and self:CanControlEventUnit(controlledUnit, state, localEventUnit)
        then
            activeUnit = controlledUnit
        end

        local activeEventId = tonumber(activeUnit.eventID) or 0
        local currentTick = math.max(1, math.floor(tonumber(options.tickNumber or state.tickNumber) or 0))
        return activeEventId > 0
            and tonumber(options.turnPageIndex[activeEventId]) == currentTick
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

function Client:FlushPendingTurnChanges(sessionStateOverride, eventStateOverride)
    local sessionState = sessionStateOverride or self:GetState()
    local eventState = eventStateOverride or self:GetEventState()
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.channelName ~= sessionState.channelName
        or not self:CanPerformEventAction(eventState, "pending-turn-flush")
    then
        return false
    end

    local timer = startTiming("Network/resource flush", 8, eventState.id or "turn-flush")
    local flushed = false

    if type(self.FlushDeferredTurnResourceDeltas) == "function" then
        flushed = self:FlushDeferredTurnResourceDeltas(sessionState, eventState) or flushed
    end

    local auraManager = self.Spellcasting and self.Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.FlushOutboundAuraOperations) == "function" then
        flushed = auraManager:FlushOutboundAuraOperations(self) or flushed
    end

    if self.QueueActionBarRefresh then
        self:QueueActionBarRefresh("pending-flush")
    elseif self.RefreshActionBarWidget then
        self:RefreshActionBarWidget("pending-flush")
    end
    if self.RefreshPendingTurnChangesTooltip then
        self:RefreshPendingTurnChangesTooltip()
    end
    if timer then
        stopEventTiming(timer, eventState, {
            resourceFlush = flushed and 1 or 0,
            queuedTasks = Addon.Internal and Addon.Internal.Tasks and Addon.Internal.Tasks.GetStats
                and (tonumber(Addon.Internal.Tasks:GetStats().queueLength) or 0) or 0,
        })
    end
    return flushed
end

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
    self:FlushPendingTurnChanges(sessionState, eventState)
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
    client.PendingEventStatePackets = client.PendingEventStatePackets or {}
    client.PendingEventStatePackets[tostring(eventId or "")] = nil
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
    nextState.rosterReady = true
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
    self.PendingEventStatePackets = self.PendingEventStatePackets or {}
    self.PendingEventStatePackets[tostring(nextState.id or "")] = nil
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
    self.PendingEventStatePackets = self.PendingEventStatePackets or {}
    self.PendingEventStatePackets[tostring(state.id or "")] = nil
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
    local immediateStartTime = getEventStepNowMilliseconds()
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

    local usesLevelField = type(arguments) == "table" and #arguments >= 6
    local turnIndex = usesLevelField and 4 or 3
    local tickIndex = usesLevelField and 5 or 4
    if type(arguments) ~= "table"
        or tonumber(arguments[turnIndex]) == nil
        or tonumber(arguments[tickIndex]) == nil
    then
        return false
    end

    local timer = startTiming("Event-state immediate handler", 8, eventState.id or "event-state")

    local incomingTurnNumber, incomingTickNumber, incomingTotalTicks = getEventStatePacketStep(arguments, eventState)
    local activeTransition = self.EventTransition
    if type(activeTransition) == "table"
        and activeTransition.eventState == eventState
        and (activeTransition.kind == "advancing" or activeTransition.kind == "starting")
    then
        local referenceTurn = activeTransition.newTurnNumber or eventState.turnNumber
        local referenceTick = activeTransition.newTickNumber or eventState.tickNumber
        local packetOrder = compareEventStep(incomingTurnNumber, incomingTickNumber, referenceTurn, referenceTick)
        if packetOrder > 0 then
            stageEventStatePacket(self, eventState.id, arguments, incomingTurnNumber, incomingTickNumber, incomingTotalTicks)
            if timer then
                stopEventTiming(timer, eventState, {
                    duplicateOrQueued = 1,
                    queuedLaterStep = 1,
                    turnNumber = incomingTurnNumber,
                    tickNumber = incomingTickNumber,
                    transitionGeneration = activeTransition.generation,
                })
            end
            return true
        end
        if activeTransition.kind == "advancing" then
            if timer then
                stopEventTiming(timer, eventState, {
                    duplicateOrStale = 1,
                    turnNumber = incomingTurnNumber,
                    tickNumber = incomingTickNumber,
                    transitionGeneration = activeTransition.generation,
                })
            end
            return packetOrder == 0
        end
        if packetOrder < 0 then
            if timer then
                stopEventTiming(timer, eventState, {
                    duplicateOrStale = 1,
                    turnNumber = incomingTurnNumber,
                    tickNumber = incomingTickNumber,
                    transitionGeneration = activeTransition.generation,
                })
            end
            return false
        end
    end

    local currentOrder = compareEventStep(
        incomingTurnNumber,
        incomingTickNumber,
        tonumber(eventState.turnNumber) or 0,
        tonumber(eventState.tickNumber) or 0
    )
    if currentOrder < 0 then
        if timer then
            stopEventTiming(timer, eventState, {
                duplicateOrStale = 1,
                turnNumber = incomingTurnNumber,
                tickNumber = incomingTickNumber,
            })
        end
        return false
    end

    local previousTurnNumber = tonumber(eventState.turnNumber) or 0
    local previousTickNumber = tonumber(eventState.tickNumber) or 0
    local wasTurnEndPending = self.TurnEndPending == true
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

    local stepAdvanced = previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
        or previousTickNumber ~= (tonumber(eventState.tickNumber) or 0)
    if not stepAdvanced then
        if timingParts then
            logTimingParts("HandleEventState", "event-state-handler", timingParts, getTimingNowMilliseconds() - totalStartTime, 25)
        end
        if timer then
            stopEventTiming(timer, eventState, {
                stepChanged = 0,
                turnNumber = tonumber(eventState.turnNumber) or 0,
                tickNumber = tonumber(eventState.tickNumber) or 0,
            })
        end
        return true
    end

    local transition = self:BeginEventTransition("advancing", eventState.id)
    transition.eventState = eventState
    transition.previousTurnNumber = previousTurnNumber
    transition.previousTickNumber = previousTickNumber
    transition.newTurnNumber = tonumber(eventState.turnNumber) or 0
    transition.newTickNumber = tonumber(eventState.tickNumber) or 0
    transition.newTotalTicks = tonumber(eventState.totalTicks) or 0
    transition.phase = EVENT_ADVANCE_PHASES[1]
    transition.continuation = nil

    local work = {
        client = self,
        eventId = tostring(eventState.id or ""),
        eventState = eventState,
        transitionGeneration = transition.generation,
        contextId = transition.contextId,
        previousTurnNumber = previousTurnNumber,
        previousTickNumber = previousTickNumber,
        newTurnNumber = tonumber(eventState.turnNumber) or 0,
        newTickNumber = tonumber(eventState.tickNumber) or 0,
        stepAdvanced = stepAdvanced,
        wasTurnEndPending = wasTurnEndPending,
        phase = EVENT_ADVANCE_PHASES[1],
        affectedEventUnitIds = {},
        affectedEventUnitList = {},
        diagnostics = transition.stepDiagnostics,
    }
    transition.continuation = work
    self.EventStepWork = work

    local queueStartTime = timingParts and getTimingNowMilliseconds() or nil
    local queued = queueEventAdvanceWork(self, eventState, transition, work)
    appendTimingPart(timingParts, "advance-queue", queueStartTime, 10)
    if not queued then
        self.EventStepWork = nil
        transition.phase = "error"
        transition.failed = true
        eventState.transitionPhase = "error"
        if Debug and Debug.Error then
            Debug.Error("Unable to queue event-step transition: event=%s", tostring(eventState.id or ""))
        end
    end

    if type(transition.stepDiagnostics) == "table" then
        transition.stepDiagnostics.immediateElapsedMs = math.max(0, getEventStepNowMilliseconds() - immediateStartTime)
    end

    if timingParts then
        logTimingParts("HandleEventState", "event-state-handler", timingParts, getTimingNowMilliseconds() - totalStartTime, 25)
    end
    if timer then
        stopEventTiming(timer, eventState, {
            stepChanged = 1,
            advancingQueued = queued and 1 or 0,
            immediateElapsedMs = transition.stepDiagnostics and transition.stepDiagnostics.immediateElapsedMs or 0,
            turnNumber = tonumber(eventState.turnNumber) or 0,
            tickNumber = tonumber(eventState.tickNumber) or 0,
            transitionGeneration = transition.generation,
        })
    end
    return queued == true
end
