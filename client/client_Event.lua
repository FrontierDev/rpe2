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
        return
    end

    local timings = getTimings()
    if timings and type(timings.Stop) == "function" then
        timings:Stop(timer, { cardinality = cardinality })
    end
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
        return
    end

    cardinality = cardinality or {}
    cardinality.eventUnits = type(eventState) == "table" and countList(eventState.units) or 0
    stopTiming(timer, cardinality)
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
Client.LastEventEndReason = Client.LastEventEndReason or nil
Client.EventWidgetRefreshQueued = Client.EventWidgetRefreshQueued or false
Client.EventStartupRuntimeByEventId = Client.EventStartupRuntimeByEventId or {}
Client.ControlledEventUnitId = Client.ControlledEventUnitId or nil
Client.TurnEndPending = Client.TurnEndPending or false
Client.EventUnitInteractionMarkers = Client.EventUnitInteractionMarkers or {}
Client.LastLocalInteractionMarker = Client.LastLocalInteractionMarker or nil

local EVENT_STARTUP_STEP_COUNT = 6

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
        consumablesQueued = false,
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

    return completed
end

local function setEventStartupPhase(eventState, runtime, phase)
    if type(eventState) ~= "table" then
        return false
    end

    eventState.startupPhase = tostring(phase or "starting")
    eventState.startupProgressExpected = EVENT_STARTUP_STEP_COUNT
    eventState.startupProgressReceived = getStartupProgressReceived(runtime)
    eventState.startupReady = eventState.startupPhase == "ready"
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
        return setEventStartupPhase(eventState, runtime, "waiting-state")
    end

    return setEventStartupPhase(eventState, runtime, "syncing-local")
end

local function isEventStartupPending(eventState)
    return type(eventState) == "table"
        and eventState.active == true
        and (eventState.unitsReady ~= true or eventState.startupReady ~= true)
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

    return enqueueClientTask(function(targetClient, queuedEventId, queuedWasLocalTurn, queuedPreviousTurnNumber, queuedPreviousTickNumber)
        if type(targetClient) ~= "table" then
            return
        end

        local currentEventState = targetClient.GetEventState and targetClient:GetEventState() or targetClient.EventState
        if type(currentEventState) ~= "table"
            or currentEventState.active ~= true
            or tostring(currentEventState.id or "") ~= queuedEventId
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
    end, client, expectedEventId, wasLocalTurn == true, previousTurnNumber, previousTickNumber, reason)
end

local tryQueueInitialLocalResourceSync

local function runEventStartupStep(targetClient, queuedEventId, deadlineMs)
    if type(targetClient) ~= "table" then
        return false
    end

    local eventState = targetClient.GetEventState and targetClient:GetEventState() or targetClient.EventState
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or tostring(eventState.id or "") ~= tostring(queuedEventId or "")
    then
        return false
    end

    local runtime = getEventStartupRuntime(targetClient, eventState.id, true)
    if type(runtime) ~= "table" then
        return false
    end

    if eventState.unitsReady ~= true then
        refreshEventStartupPhase(eventState, runtime)
        if type(targetClient.QueueEventWidgetRefresh) == "function" then
            targetClient:QueueEventWidgetRefresh("startup-waiting-units")
        end
        return false
    end

    if runtime.startupStateReceived ~= true then
        refreshEventStartupPhase(eventState, runtime)
        if type(targetClient.QueueEventWidgetRefresh) == "function" then
            targetClient:QueueEventWidgetRefresh("startup-waiting-state")
        end
        return false
    end

    setEventStartupPhase(eventState, runtime, "syncing-local")
    if type(targetClient.QueueEventWidgetRefresh) == "function" then
        targetClient:QueueEventWidgetRefresh("startup-syncing")
    end

    if runtime.actionBarPrimed ~= true and runtime.visualGate ~= "syncing-local" then
        runtime.visualGate = "syncing-local"
        runtime.actionBarPrimed = true
        local phaseTimer = startTiming("Event startup phase: action-bar", 8, queuedEventId)
        queueSharedEventVisualRefresh(targetClient, "startup-action-bar", {
            eventWidget = false,
            targeting = false,
            actionBar = true,
        })
        if phaseTimer then
            stopEventTiming(phaseTimer, eventState, { startupPhase = "action-bar" })
        end
        setEventStartupPhase(eventState, runtime, "syncing-local")
        return true
    end

    if runtime.traitRuntimeRefreshed ~= true and type(targetClient.RefreshTraitRuntimeEntries) == "function" then
        local phaseTimer = startTiming("Event startup phase: trait-runtime", 8, queuedEventId)
        runtime.traitRuntimeContinuation = runtime.traitRuntimeContinuation
            or (type(targetClient.CreateTraitRuntimeRefreshContinuation) == "function"
                and targetClient:CreateTraitRuntimeRefreshContinuation(eventState)
                or nil)
        local completed = runtime.traitRuntimeContinuation == nil
        if runtime.traitRuntimeContinuation and type(targetClient.StepTraitRuntimeRefreshContinuation) == "function" then
            completed = targetClient:StepTraitRuntimeRefreshContinuation(runtime.traitRuntimeContinuation, deadlineMs) == true
        elseif runtime.traitRuntimeContinuation == nil then
            targetClient:RefreshTraitRuntimeEntries(eventState)
            completed = true
        end
        if phaseTimer then
            stopEventTiming(phaseTimer, eventState, {
                startupPhase = "trait-runtime",
                completed = completed and 1 or 0,
            })
        end
        if not completed then
            return true
        end
        runtime.traitRuntimeContinuation = nil
        runtime.traitRuntimeRefreshed = true
        setEventStartupPhase(eventState, runtime, "syncing-local")
        return true
    end

    if runtime.automaticAurasSynced ~= true and type(targetClient.SyncAutomaticTraitAuras) == "function" then
        local phaseTimer = startTiming("Event startup phase: automatic-auras", 8, queuedEventId)
        runtime.automaticAuraContinuation = runtime.automaticAuraContinuation
            or (type(targetClient.CreateAutomaticTraitAuraContinuation) == "function"
                and targetClient:CreateAutomaticTraitAuraContinuation(eventState, { suppressResolvedRefresh = true })
                or nil)
        local completed = runtime.automaticAuraContinuation == nil
        if runtime.automaticAuraContinuation and type(targetClient.StepAutomaticTraitAuraContinuation) == "function" then
            completed = targetClient:StepAutomaticTraitAuraContinuation(runtime.automaticAuraContinuation, deadlineMs) == true
        elseif runtime.automaticAuraContinuation == nil then
            targetClient:SyncAutomaticTraitAuras(eventState, { suppressResolvedRefresh = true })
            completed = true
        end
        if phaseTimer then
            stopEventTiming(phaseTimer, eventState, {
                startupPhase = "automatic-auras",
                completed = completed and 1 or 0,
            })
        end
        if not completed then
            return true
        end
        runtime.automaticAuraContinuation = nil
        runtime.automaticAurasSynced = true
        setEventStartupPhase(eventState, runtime, "syncing-local")
        return true
    end

    if runtime.eventAurasSynced ~= true and type(targetClient.SyncEventAuras) == "function" then
        local phaseTimer = startTiming("Event startup phase: event-auras", 8, queuedEventId)
        runtime.eventAuraContinuation = runtime.eventAuraContinuation
            or (type(targetClient.CreateEventAuraContinuation) == "function"
                and targetClient:CreateEventAuraContinuation(eventState, { suppressResolvedRefresh = true })
                or nil)
        local completed = runtime.eventAuraContinuation == nil
        if runtime.eventAuraContinuation and type(targetClient.StepEventAuraContinuation) == "function" then
            completed = targetClient:StepEventAuraContinuation(runtime.eventAuraContinuation, deadlineMs) == true
        elseif runtime.eventAuraContinuation == nil then
            targetClient:SyncEventAuras(eventState, { suppressResolvedRefresh = true })
            completed = true
        end
        if phaseTimer then
            stopEventTiming(phaseTimer, eventState, {
                startupPhase = "event-auras",
                completed = completed and 1 or 0,
            })
        end
        if not completed then
            return true
        end
        runtime.eventAuraContinuation = nil
        runtime.eventAurasSynced = true
        setEventStartupPhase(eventState, runtime, "syncing-local")
        return true
    end

    if runtime.resolvedStateRefreshed ~= true and type(targetClient.RefreshTraitResolvedState) == "function" then
        local phaseTimer = startTiming("Event startup phase: resolved-state", 8, queuedEventId)
        targetClient:RefreshTraitResolvedState(eventState, "startup")
        runtime.resolvedStateRefreshed = true
        local sessionState = targetClient.GetState and targetClient:GetState() or targetClient.State
        tryQueueInitialLocalResourceSync(targetClient, sessionState, eventState, "startup-resolved-state")
        if phaseTimer then
            stopEventTiming(phaseTimer, eventState, { startupPhase = "resolved-state" })
        end
        setEventStartupPhase(eventState, runtime, "syncing-local")
        return true
    end

    if runtime.consumablesQueued ~= true and type(targetClient.QueueDeferredConsumablePrompt) == "function" then
        local phaseTimer = startTiming("Event startup phase: consumables", 8, queuedEventId)
        targetClient:QueueDeferredConsumablePrompt(eventState, "event_start")
        if phaseTimer then
            stopEventTiming(phaseTimer, eventState, { startupPhase = "consumables" })
        end
        runtime.consumablesQueued = true
        setEventStartupPhase(eventState, runtime, "syncing-local")
        return true
    end

    setEventStartupPhase(eventState, runtime, "ready")
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
        stopEventTiming(readyTimer, eventState, { startupPhase = "ready" })
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
    runtime.queued = true
    local sliceJob = enqueueClientSliceable({
        label = "event-startup",
        scope = "event:" .. queuedEventId,
        state = {
            client = client,
            eventId = queuedEventId,
            reason = reason or "startup",
            configurationRevision = getConfigurationRevision(),
            equipmentRevision = getEquipmentRevision(),
        },
        isStale = function(work)
            local targetClient = work and work.client or nil
            local currentEventState = targetClient and targetClient.GetEventState and targetClient:GetEventState() or nil
            return type(currentEventState) ~= "table"
                or currentEventState.active ~= true
                or tostring(currentEventState.id or "") ~= tostring(work and work.eventId or "")
                or getConfigurationRevision() ~= math.max(0, math.floor(tonumber(work and work.configurationRevision) or 0))
                or getEquipmentRevision() ~= math.max(0, math.floor(tonumber(work and work.equipmentRevision) or 0))
        end,
        step = function(work, deadlineMs)
            local targetClient = work and work.client or nil
            local expectedEventId = work and work.eventId or nil
            if type(targetClient) ~= "table" then
                return true
            end
            if runEventStartupStep(targetClient, expectedEventId, deadlineMs) then
                if type(targetClient.QueueEventWidgetRefresh) == "function" then
                    targetClient:QueueEventWidgetRefresh("startup-progress")
                end
                return false
            end
            return true
        end,
        onCancel = function(work, cancelReason)
            local targetClient = work and work.client or nil
            local currentRuntime = targetClient and getEventStartupRuntime(targetClient, work.eventId, false) or nil
            if type(currentRuntime) == "table" then
                currentRuntime.queued = false
                currentRuntime.sliceJob = nil
                currentRuntime.traitRuntimeContinuation = nil
                currentRuntime.automaticAuraContinuation = nil
                currentRuntime.eventAuraContinuation = nil
            end
            if cancelReason == "stale" and type(targetClient) == "table" then
                local currentEventState = targetClient.GetEventState and targetClient:GetEventState() or nil
                if type(currentEventState) == "table"
                    and currentEventState.active == true
                    and tostring(currentEventState.id or "") == tostring(work and work.eventId or "")
                then
                    queueEventStartupWork(targetClient, currentEventState, "startup-stale-restart")
                end
            end
        end,
        onComplete = function(work)
            local targetClient = work and work.client or nil
            local currentRuntime = targetClient and getEventStartupRuntime(targetClient, work.eventId, false) or nil
            if type(currentRuntime) == "table" then
                currentRuntime.queued = false
                currentRuntime.sliceJob = nil
                currentRuntime.traitRuntimeContinuation = nil
                currentRuntime.automaticAuraContinuation = nil
                currentRuntime.eventAuraContinuation = nil
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

function Client:FlushPendingTurnChanges(sessionStateOverride, eventStateOverride)
    local sessionState = sessionStateOverride or self:GetState()
    local eventState = eventStateOverride or self:GetEventState()
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.channelName ~= sessionState.channelName
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
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or self:IsLocalEventHost(eventState)
        or not self:IsLocalTurnActive(eventState)
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
    if type(eventState) ~= "table" or eventState.active ~= true then
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

function Client:ResetEventState(reason)
    local state = self.EventState
    cancelEventSliceableWork(self, state and state.id or nil, "event-reset")
    local sessionState = self:GetState()
    local timer = startTiming("Event end teardown", 16, reason or "ended")
    local activeCasts, activeAuras = 0, 0
    if timer then
        activeCasts, activeAuras = getActiveEventCardinality(self, state)
    end
    local tracker = getMovementTracker()
    if tracker and type(tracker.OnPlayerTurnEnd) == "function" then
        tracker:OnPlayerTurnEnd()
    end
    if state then
        state.active = false
        state.endedAt = Common.GetNow()
        self.LastEventEndReason = reason
        Debug.Info(
            "Event ended: %s.",
            tostring(state.name ~= "" and state.name or state.id or "unnamed")
        )
    end

    self.EventState = nil
    self.ControlledEventUnitId = nil
    self.TurnEndPending = false
    self.LastAppliedTurnRegenKey = nil
    self.PendingStartupActionBarRefresh = false
    self.PendingStartupActionBarRefreshReason = nil
    self.EventUnitInteractionMarkers = {}
    self.LastLocalInteractionMarker = nil
    local combatLogTimer = startTiming("Event end teardown: combat-log", 8, reason or "ended")
    if self.ClearEventWidgetCombatLog then
        self:ClearEventWidgetCombatLog(reason or "ended")
    end
    if combatLogTimer then
        stopEventTiming(combatLogTimer, state, { teardownPhase = "combat-log" })
    end
    local spellcastingTimer = startTiming("Event end teardown: spellcasting", 8, reason or "ended")
    if self.ResetSpellcastingState then
        self:ResetSpellcastingState(state and state.id or nil)
    end
    if spellcastingTimer then
        stopEventTiming(spellcastingTimer, state, { teardownPhase = "spellcasting" })
    end
    local traitTimer = startTiming("Event end teardown: traits", 8, reason or "ended")
    if self.ResetTraitRuntime then
        self:ResetTraitRuntime(state and state.id or nil)
    end
    if traitTimer then
        stopEventTiming(traitTimer, state, { teardownPhase = "traits" })
    end
    resetEventStartupRuntime(self, state and state.id or nil)
    local targetingTimer = startTiming("Event end teardown: targeting", 8, reason or "ended")
    if self.CancelSpellTargeting then
        self:CancelSpellTargeting("")
    end
    if sessionState then
        sessionState.lastResourceSyncEventId = nil
    end
    if self.InvalidatePendingSpellTargetingDisplayState then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    if targetingTimer then
        stopEventTiming(targetingTimer, state, { teardownPhase = "targeting" })
    end
    local visualTimer = startTiming("Event end teardown: visual-queue", 8, reason or "ended")
    queueSharedEventVisualRefresh(self, reason or "ended", {
        eventWidget = true,
        targeting = false,
        actionBar = true,
    })
    if visualTimer then
        stopEventTiming(visualTimer, state, { teardownPhase = "visual-queue" })
    end
    if timer then
        stopEventTiming(timer, state, {
            teardownReason = reason or "ended",
            activeCasts = activeCasts,
            activeAuras = activeAuras,
        })
    end
    return state
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

    local timer = startTiming("Event start total", 16, "event-start")

    local parseStartTime = timingParts and getTimingNowMilliseconds() or nil
    local nextState = Event.FromStartArguments(arguments)
    appendTimingPart(timingParts, "parse-start", parseStartTime, 10)

    nextState.hostName = Common.NormalizeName(nextState.hostName ~= "" and nextState.hostName or sender)
    nextState.channelName = channelName
    nextState.active = true
    nextState.endedAt = 0
    nextState.turnNumber = math.max(1, tonumber(nextState.turnNumber) or 1)
    nextState.tickNumber = math.max(1, tonumber(nextState.tickNumber) or 1)
    nextState.totalTicks = math.max(1, tonumber(nextState.totalTicks) or 1)
    nextState.rosterReady = true
    nextState.unitsReady = false
    nextState.unitsChunkReceived = 0
    nextState.unitsChunkExpected = 0

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
    local startupRuntime = getEventStartupRuntime(self, nextState.id, true)
    if startupRuntime then
        startupRuntime.startupStateReceived = false
        startupRuntime.actionBarPrimed = false
        startupRuntime.visualGate = ""
        startupRuntime.traitRuntimeRefreshed = false
        startupRuntime.automaticAurasSynced = false
        startupRuntime.eventAurasSynced = false
        startupRuntime.resolvedStateRefreshed = false
        startupRuntime.consumablesQueued = false
        startupRuntime.queued = false
    end
    setEventStartupPhase(nextState, startupRuntime, "starting")

    local achievements = Client.Achievements
    if achievements and type(achievements.HandleRPEEventStart) == "function" then
        pcall(achievements.HandleRPEEventStart, achievements, nextState, startupRuntime)
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

    local syncStartTime = timingParts and getTimingNowMilliseconds() or nil
    tryQueueInitialLocalResourceSync(self, sessionState, nextState, "event-start")
    appendTimingPart(timingParts, "resource-sync-queue", syncStartTime, 10)

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
    local timer = startTiming("Event end total", 16, reason)
    local achievements = Client.Achievements
    if achievements and type(achievements.HandleRPEEventComplete) == "function" then
        pcall(achievements.HandleRPEEventComplete, achievements, state, reason)
    end
    if self.PromptPhaseConsumableTraits then
        local prompted = self:PromptPhaseConsumableTraits(state, "event_end", function()
            Client:ResetEventState(reason)
        end)
        if prompted then
            if timer then
                stopEventTiming(timer, state, { prompted = 1 })
            end
            return true
        end
    end

    local resetState = self:ResetEventState(reason)
    if timer then
        stopEventTiming(timer, resetState, { prompted = 0 })
    end
    return resetState ~= nil
end

function Client:HandleEventUnits(arguments)
    local totalStartTime = getTimingNowMilliseconds()
    local timingParts = totalStartTime > 0 and {} or nil
    local sessionState = self:GetState()
    local eventState = self.EventState
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
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

    local syncStartTime = timingParts and getTimingNowMilliseconds() or nil
    tryQueueInitialLocalResourceSync(self, sessionState, eventState, "event-units")
    appendTimingPart(timingParts, "resource-sync-queue", syncStartTime, 10)

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
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
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
    tryQueueInitialLocalResourceSync(self, sessionState, eventState, "event-unit-delta-batch")
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
    if self.ActivateEventTraits then
        self:ActivateEventTraits(eventState)
    end
    return true
end

function Client:HandleInboundChunkProgress(packet, receivedCount, distribution, sender, target, startedAtMs)
    if not packet or packet.opcode ~= getEventUnitsOpcode() then
        return false
    end

    local eventState = self.EventState
    if not eventState or eventState.active ~= true or eventState.unitsReady == true then
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
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
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
