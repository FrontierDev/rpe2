local addonName, Addon = ...

local Debug = Addon.Debug or {}
Addon.Debug = Debug

Debug.Timings = Debug.Timings or {}
local Timings = Debug.Timings

local unpackValues = unpack or table.unpack

Timings.Enabled = Timings.Enabled == true
Timings.DefaultThresholdMs = tonumber(Timings.DefaultThresholdMs) or 0
Timings.MaxRecentRecords = math.max(1, math.floor(tonumber(Timings.MaxRecentRecords) or 100))
Timings.RecentRecords = Timings.RecentRecords or Timings.RecentSlowRecords or {}
Timings.RecentSlowRecords = Timings.RecentRecords
Timings.RecentRecordOrder = tonumber(Timings.RecentRecordOrder) or 0
Timings.RuntimeHooks = Timings.RuntimeHooks or {}
while #Timings.RecentRecords > Timings.MaxRecentRecords do
    table.remove(Timings.RecentRecords, 1)
end

local function getNowMilliseconds()
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

local function isInternalEnabled()
    return type(Debug) == "table"
        and type(Debug.IsLevelEnabled) == "function"
        and Debug.IsLevelEnabled("internal") == true
end

-- RPE INTERNAL is the authoritative development diagnostics switch. Keep the
-- explicit Timings.Enabled flag for /rpe debug timings compatibility, but do
-- not require it when INTERNAL itself is enabled. This also covers settings/UI
-- paths that update EnabledLevels without calling Debug.SetLevelEnabled().
local function isEnabled()
    return Timings.Enabled == true or isInternalEnabled()
end

local function shouldLog(options)
    if type(options) == "table" and options.force == true then
        return true
    end

    return isInternalEnabled()
end

local function shouldMarkSlow(elapsedMs, thresholdMs)
    local threshold = tonumber(thresholdMs)
    return threshold ~= nil and threshold > 0 and elapsedMs >= threshold
end

local function buildContextSuffix(context)
    local text = tostring(context or "")
    if text == "" then
        return ""
    end

    return (" [%s]"):format(text)
end

local function formatCardinality(cardinality)
    if cardinality == nil then
        return ""
    end

    if type(cardinality) ~= "table" then
        return tostring(cardinality)
    end

    local keys = {}
    for key in pairs(cardinality) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)

    local parts = {}
    for index = 1, #keys do
        local key = keys[index]
        parts[#parts + 1] = ("%s=%s"):format(tostring(key), tostring(cardinality[key]))
    end
    return table.concat(parts, ",")
end

local function copyCardinality(cardinality)
    if type(cardinality) ~= "table" then
        return cardinality
    end

    local copy = {}
    for key, value in pairs(cardinality) do
        copy[key] = value
    end
    return copy
end

local function appendRecentRecord(label, elapsedMs, context, thresholdMs, cardinality, timestampMs, slow)
    if not isEnabled() then
        return
    end

    Timings.RecentRecordOrder = (tonumber(Timings.RecentRecordOrder) or 0) + 1
    local records = Timings.RecentRecords
    records[#records + 1] = {
        label = tostring(label or "operation"),
        elapsedMs = math.max(0, tonumber(elapsedMs) or 0),
        thresholdMs = tonumber(thresholdMs) or 0,
        context = context,
        cardinality = copyCardinality(cardinality),
        timestampMs = tonumber(timestampMs) or 0,
        order = Timings.RecentRecordOrder,
        slow = slow == true,
    }

    while #records > Timings.MaxRecentRecords do
        table.remove(records, 1)
    end
end

local function emitTiming(label, elapsedMs, context, thresholdMs, cardinality)
    if type(Debug) ~= "table" or type(Debug.Internal) ~= "function" or not isInternalEnabled() then
        return false
    end

    local slow = shouldMarkSlow(elapsedMs, thresholdMs)
    local cardinalityText = formatCardinality(cardinality)
    return Debug.Internal(
        "%sTiming%s %s took %.2fms%s",
        slow and "SLOW " or "",
        buildContextSuffix(context),
        tostring(label or "operation"),
        math.max(0, tonumber(elapsedMs) or 0),
        cardinalityText ~= "" and (" [" .. cardinalityText .. "]") or ""
    ) == true
end

local function buildPartSegment(part)
    if type(part) ~= "table" or type(part.label) ~= "string" then
        return nil, false
    end

    local elapsedMs = math.max(0, tonumber(part.elapsedMs) or tonumber(part.elapsed) or 0)
    local thresholdMs = tonumber(part.thresholdMs) or tonumber(part.threshold)
    local slow = shouldMarkSlow(elapsedMs, thresholdMs)
    return ("%s=%.2fms%s"):format(
        tostring(part.label),
        elapsedMs,
        slow and " SLOW" or ""
    ), slow
end

function Timings.GetNowMilliseconds()
    return getNowMilliseconds()
end

function Timings.SetEnabled(selfOrEnabled, maybeEnabled)
    local enabled = maybeEnabled
    if type(selfOrEnabled) ~= "table" then
        enabled = selfOrEnabled
    end

    Timings.Enabled = enabled == true
    return Timings.Enabled
end

function Timings.IsEnabled()
    return isEnabled()
end

function Timings.IsActive()
    return isEnabled()
        and isInternalEnabled()
        and type(Debug) == "table"
        and type(Debug.Internal) == "function"
end

function Timings:Start(label, options)
    if not isEnabled() and not (type(options) == "table" and options.force == true) then
        return nil
    end
    local resolvedOptions = type(options) == "table" and options or {}

    return {
        label = tostring(label or "operation"),
        context = resolvedOptions.context,
        thresholdMs = tonumber(resolvedOptions.thresholdMs),
        startedAtMs = getNowMilliseconds(),
        force = resolvedOptions.force == true,
    }
end

function Timings:Stop(timer, options)
    if type(timer) ~= "table" then
        return 0, false
    end

    local elapsedMs = math.max(0, getNowMilliseconds() - (tonumber(timer.startedAtMs) or 0))
    local resolvedOptions = type(options) == "table" and options or {}
    local context = resolvedOptions.context
    if context == nil then
        context = timer.context
    end

    local thresholdMs = tonumber(resolvedOptions.thresholdMs)
    if thresholdMs == nil then
        thresholdMs = timer.thresholdMs
    end
    if thresholdMs == nil then
        thresholdMs = Timings.DefaultThresholdMs
    end

    local slow = shouldMarkSlow(elapsedMs, thresholdMs)
    if isEnabled() then
        appendRecentRecord(
            resolvedOptions.label or timer.label,
            elapsedMs,
            context,
            thresholdMs,
            resolvedOptions.cardinality,
            getNowMilliseconds(),
            slow
        )
    end

    local logged = false
    if shouldLog({
        force = resolvedOptions.force == true or timer.force == true,
    }) then
        logged = emitTiming(
            resolvedOptions.label or timer.label,
            elapsedMs,
            context,
            thresholdMs,
            resolvedOptions.cardinality
        )
    end

    return elapsedMs, logged
end

function Timings:Measure(label, fn, options, ...)
    if type(fn) ~= "function" then
        return nil
    end

    if not isEnabled() and not (type(options) == "table" and options.force == true) then
        return fn(...)
    end
    local resolvedOptions = type(options) == "table" and options or {}

    local timer = self:Start(label, resolvedOptions)
    local results = { pcall(fn, ...) }
    local ok = table.remove(results, 1)
    self:Stop(timer, options)

    if not ok then
        error(results[1], 0)
    end

    return unpackValues(results)
end

function Timings:GetRecentRecords(options)
    local resolvedOptions = type(options) == "table" and options or {}
    local slowOnly = resolvedOptions.slowOnly == true
    local records = {}

    for index = 1, #(Timings.RecentRecords or {}) do
        local record = Timings.RecentRecords[index]
        if not slowOnly or record.slow == true then
            local copy = {}
            for key, value in pairs(record) do
                if key == "cardinality" then
                    copy[key] = copyCardinality(value)
                else
                    copy[key] = value
                end
            end
            records[#records + 1] = copy
        end
    end

    return records
end

function Timings:ClearRecentRecords()
    Timings.RecentRecords = {}
    Timings.RecentSlowRecords = Timings.RecentRecords
    return true
end

function Timings:GetRecentSlowRecords(options)
    local resolvedOptions = type(options) == "table" and options or {}
    local slowOptions = {}
    for key, value in pairs(resolvedOptions) do
        slowOptions[key] = value
    end
    slowOptions.slowOnly = true
    return self:GetRecentRecords(slowOptions)
end

function Timings:Wrap(label, fn, options)
    if type(fn) ~= "function" then
        return nil
    end

    return function(...)
        return Timings:Measure(label, fn, options, ...)
    end
end

function Timings:LogParts(label, context, parts, totalElapsedMs, thresholdMs, cardinality)
    if not isEnabled() then
        return false
    end

    local totalMs = math.max(0, tonumber(totalElapsedMs) or 0)
    local resolvedThreshold = tonumber(thresholdMs) or 0
    local segments = {}
    local totalSlow = shouldMarkSlow(totalMs, resolvedThreshold)
    segments[#segments + 1] = ("total=%.2fms%s"):format(totalMs, totalSlow and " SLOW" or "")
    local hasSlow = totalSlow

    for index = 1, #(parts or {}) do
        local segment, slow = buildPartSegment(parts[index])
        if segment then
            segments[#segments + 1] = segment
            hasSlow = hasSlow or slow
        end
    end

    appendRecentRecord(label, totalMs, context, resolvedThreshold, cardinality, getNowMilliseconds(), hasSlow)

    if not Timings.IsActive() then
        return false
    end

    local cardinalityText = formatCardinality(cardinality)
    return Debug.Internal(
        "%sTiming%s %s: %s%s",
        hasSlow and "SLOW " or "",
        buildContextSuffix(context),
        tostring(label or "operation"),
        table.concat(segments, ", "),
        cardinalityText ~= "" and (" [" .. cardinalityText .. "]") or ""
    ) == true
end

local function packValues(...)
    return { n = select("#", ...), ... }
end

local function getEventStateFromTarget(target)
    if type(target) == "table" then
        if type(target.GetEventState) == "function" then
            local state = target:GetEventState()
            if type(state) == "table" then
                return state
            end
        end
        if type(target.EventState) == "table" then
            return target.EventState
        end
    end

    local serverState = Addon.Server and Addon.Server.EventState or nil
    if type(serverState) == "table" then
        return serverState
    end
    return Addon.Client and Addon.Client.EventState or nil
end

local function buildRuntimeCardinality(target)
    local eventState = getEventStateFromTarget(target)
    if type(eventState) ~= "table" then
        return nil
    end

    return {
        eventId = tostring(eventState.id or ""),
        eventUnits = type(eventState.units) == "table" and #eventState.units or 0,
        turn = tonumber(eventState.turnNumber) or 0,
        tick = tonumber(eventState.tickNumber) or 0,
    }
end

local function wrapMethod(target, methodName, label, context, thresholdMs, hookKey)
    if type(target) ~= "table" or type(target[methodName]) ~= "function" then
        return false
    end
    hookKey = tostring(hookKey or methodName)
    if Timings.RuntimeHooks[hookKey] == true then
        return false
    end

    local original = target[methodName]
    target[methodName] = function(self, ...)
        if not isEnabled() then
            return original(self, ...)
        end

        local timer = Timings:Start(label, {
            context = context,
            thresholdMs = thresholdMs or 8,
        })
        local results = packValues(original(self, ...))
        Timings:Stop(timer, {
            cardinality = buildRuntimeCardinality(self),
        })
        return unpackValues(results, 1, results.n)
    end
    Timings.RuntimeHooks[hookKey] = true
    return true
end

local function wrapFunction(target, functionName, label, context, thresholdMs, hookKey)
    if type(target) ~= "table" or type(target[functionName]) ~= "function" then
        return false
    end
    hookKey = tostring(hookKey or functionName)
    if Timings.RuntimeHooks[hookKey] == true then
        return false
    end

    local original = target[functionName]
    target[functionName] = function(...)
        if not isEnabled() then
            return original(...)
        end

        local timer = Timings:Start(label, {
            context = context,
            thresholdMs = thresholdMs or 2,
        })
        local results = packValues(original(...))
        Timings:Stop(timer)
        return unpackValues(results, 1, results.n)
    end
    Timings.RuntimeHooks[hookKey] = true
    return true
end

function Timings:InstallRuntimeHooks()
    local server = Addon.Server
    local client = Addon.Client
    local planner = type(client) == "table" and client.AutopilotPlanner or nil

    -- Host event lifecycle. Existing inner scopes remain in place; these outer
    -- scopes guarantee a visible total even when execution passes through later
    -- wrappers such as autopilot integration.
    wrapMethod(server, "StartEvent", "Host event start", "event-start", 8, "Server.StartEvent")
    wrapMethod(server, "AdvanceEventStep", "Host advance turn/tick request", "event-advance", 8, "Server.AdvanceEventStep")
    wrapMethod(server, "_AdvanceEventStepAfterCommit", "Host advance turn/tick commit", "event-advance", 8, "Server._AdvanceEventStepAfterCommit")

    -- Client receive/application totals. These complement the detailed parts in
    -- client_Event.lua and make it obvious which side incurred the frame cost.
    wrapMethod(client, "HandleEventStart", "Client EVENT_START", "event-start", 8, "Client.HandleEventStart")
    wrapMethod(client, "HandleEventUnits", "Client EVENT_UNITS", "event-start", 8, "Client.HandleEventUnits")
    wrapMethod(client, "HandleEventState", "Client EVENT_STATE", "event-state", 8, "Client.HandleEventState")

    -- Autopilot orchestration and execution boundaries.
    wrapMethod(client, "InitializeAutopilotSpatialRuntime", "Autopilot spatial initialization", "autopilot", 4, "Client.InitializeAutopilotSpatialRuntime")
    wrapMethod(client, "ReconcileAutopilotSpatialRuntime", "Autopilot spatial reconciliation", "autopilot", 4, "Client.ReconcileAutopilotSpatialRuntime")
    wrapMethod(client, "RefreshAutopilotPlayerPositionsForCompletedStep", "Autopilot player position refresh", "autopilot", 4, "Client.RefreshAutopilotPlayerPositionsForCompletedStep")
    wrapMethod(client, "StartAutopilotStep", "Autopilot step start", "autopilot", 4, "Client.StartAutopilotStep")
    wrapMethod(client, "ReplaceAutopilotPlanForCurrentStep", "Autopilot replan", "autopilot", 4, "Client.ReplaceAutopilotPlanForCurrentStep")
    wrapMethod(client, "AuthorizeAutopilotPendingAction", "Autopilot authorize action", "autopilot", 4, "Client.AuthorizeAutopilotPendingAction")
    wrapMethod(client, "AuthorizeAllAutopilotPendingActions", "Autopilot authorize all", "autopilot", 4, "Client.AuthorizeAllAutopilotPendingActions")
    wrapMethod(client, "ConfirmAutopilotPendingMovement", "Autopilot confirm movement", "autopilot", 4, "Client.ConfirmAutopilotPendingMovement")
    wrapMethod(client, "ExecuteEventUnitSpell", "Autopilot execute spell", "autopilot", 4, "Client.ExecuteEventUnitSpell")
    wrapMethod(server, "GetNpcAutopilotCapability", "Autopilot capability check", "autopilot", 4, "Server.GetNpcAutopilotCapability")

    -- Planner.Step is the sliceable cost centre. TaskQueue also records each
    -- slice; this label makes the planner's own contribution explicit.
    wrapFunction(planner, "Step", "Autopilot planner step", "autopilot-planner", 2, "Planner.Step")
    wrapFunction(planner, "StepTargetSelection", "Autopilot target selection", "autopilot-planner", 2, "Planner.StepTargetSelection")
    wrapFunction(planner, "StepMovementSolve", "Autopilot movement solve", "autopilot-planner", 2, "Planner.StepMovementSolve")

    return true
end

-- Timings.lua loads before the event/autopilot implementation files. Install
-- the wrappers at ADDON_LOADED, which fires after every file in this addon's
-- TOC has executed, so the final wrapped call paths are the ones measured.
if type(CreateFrame) == "function" then
    local hookFrame = CreateFrame("Frame")
    hookFrame:RegisterEvent("ADDON_LOADED")
    hookFrame:SetScript("OnEvent", function(frame, _, loadedAddonName)
        if tostring(loadedAddonName or "") ~= tostring(addonName or "") then
            return
        end
        Timings:InstallRuntimeHooks()
        frame:UnregisterEvent("ADDON_LOADED")
        frame:SetScript("OnEvent", nil)
    end)
elseif C_Timer and type(C_Timer.After) == "function" then
    C_Timer.After(0, function()
        Timings:InstallRuntimeHooks()
    end)
end

return Timings
