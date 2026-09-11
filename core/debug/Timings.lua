local addonName, Addon = ...

local Debug = Addon.Debug or {}
Addon.Debug = Debug

Debug.Timings = Debug.Timings or {}
local Timings = Debug.Timings

local unpackValues = unpack or table.unpack

-- Timings.Enabled is the explicit detailed-diagnostics switch controlled by
-- /rpe debug timings. RPE INTERNAL independently enables high-level process
-- timings without enabling per-phase or per-slice diagnostics.
Timings.Enabled = Timings.Enabled == true
Timings.DefaultThresholdMs = tonumber(Timings.DefaultThresholdMs) or 0
Timings.MaxRecentRecords = math.max(1, math.floor(tonumber(Timings.MaxRecentRecords) or 100))
Timings.RecentRecords = Timings.RecentRecords or Timings.RecentSlowRecords or {}
Timings.RecentSlowRecords = Timings.RecentRecords
Timings.RecentRecordOrder = tonumber(Timings.RecentRecordOrder) or 0
Timings.RuntimeHooks = Timings.RuntimeHooks or {}
Timings.RuntimeProcessDepth = 0
Timings.PendingAdvanceProcess = nil
Timings.ProcessLabels = Timings.ProcessLabels or {
    ["Event start total transition"] = true,
}

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

local function isEnabled()
    return Timings.Enabled == true or isInternalEnabled()
end

local function isProcessLabel(label)
    return Timings.ProcessLabels[tostring(label or "")] == true
end

local function resolveProcessTiming(label, options)
    return (type(options) == "table" and options.process == true)
        or isProcessLabel(label)
end

local function canCollect(processTiming, force)
    if force == true then
        return true
    end
    if processTiming == true then
        return isEnabled()
    end
    return Timings.Enabled == true
end

local function shouldLog(processTiming, force)
    if force == true then
        return true
    end
    if not isInternalEnabled() then
        return false
    end
    return processTiming == true or Timings.Enabled == true
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

local function packValues(...)
    return { n = select("#", ...), ... }
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

function Timings.IsDetailedEnabled()
    return Timings.Enabled == true
end

function Timings.IsActive()
    return isEnabled()
        and isInternalEnabled()
        and type(Debug) == "table"
        and type(Debug.Internal) == "function"
end

function Timings:Start(label, options)
    local resolvedOptions = type(options) == "table" and options or {}
    local processTiming = resolveProcessTiming(label, resolvedOptions)
    local force = resolvedOptions.force == true
    if not canCollect(processTiming, force) then
        return nil
    end

    return {
        label = tostring(label or "operation"),
        context = resolvedOptions.context,
        thresholdMs = tonumber(resolvedOptions.thresholdMs),
        startedAtMs = getNowMilliseconds(),
        force = force,
        process = processTiming,
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

    local label = resolvedOptions.label or timer.label
    local processTiming = timer.process == true
        or resolvedOptions.process == true
        or isProcessLabel(label)
    local force = resolvedOptions.force == true or timer.force == true
    local slow = shouldMarkSlow(elapsedMs, thresholdMs)

    appendRecentRecord(
        label,
        elapsedMs,
        context,
        thresholdMs,
        resolvedOptions.cardinality,
        getNowMilliseconds(),
        slow
    )

    local logged = false
    if shouldLog(processTiming, force) then
        logged = emitTiming(
            label,
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

    local timer = self:Start(label, options)
    if timer == nil then
        return fn(...)
    end

    local results = packValues(pcall(fn, ...))
    local ok = results[1] == true
    self:Stop(timer, options)

    if not ok then
        error(results[2], 0)
    end

    return unpackValues(results, 2, results.n)
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
    local processTiming = isProcessLabel(label)
    if not canCollect(processTiming, false) then
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

    if not shouldLog(processTiming, false) then
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

local function buildRuntimeCardinality(target, extras)
    local eventState = getEventStateFromTarget(target)
    local cardinality = {}
    if type(eventState) == "table" then
        cardinality.eventId = tostring(eventState.id or "")
        cardinality.eventUnits = type(eventState.units) == "table" and #eventState.units or 0
        cardinality.turn = tonumber(eventState.turnNumber) or 0
        cardinality.tick = tonumber(eventState.tickNumber) or 0
    end
    if type(extras) == "table" then
        for key, value in pairs(extras) do
            cardinality[key] = value
        end
    end
    return next(cardinality) ~= nil and cardinality or nil
end

local function wrapProcessMethod(target, methodName, label, context, thresholdMs, hookKey)
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

        local previousDepth = math.max(0, math.floor(tonumber(Timings.RuntimeProcessDepth) or 0))
        if previousDepth > 0 then
            return original(self, ...)
        end

        Timings.RuntimeProcessDepth = previousDepth + 1
        local timer = Timings:Start(label, {
            context = context,
            thresholdMs = thresholdMs or 8,
            process = true,
        })
        local results = packValues(pcall(original, self, ...))
        Timings.RuntimeProcessDepth = previousDepth

        Timings:Stop(timer, {
            cardinality = buildRuntimeCardinality(self, {
                outcome = results[1] == true and "completed" or "error",
            }),
            process = true,
        })

        if results[1] ~= true then
            error(results[2], 0)
        end
        return unpackValues(results, 2, results.n)
    end

    Timings.RuntimeHooks[hookKey] = true
    return true
end

local function eventStepIdentity(eventState)
    if type(eventState) ~= "table" then
        return nil
    end
    return {
        eventId = tostring(eventState.id or ""),
        turn = tonumber(eventState.turnNumber) or 0,
        tick = tonumber(eventState.tickNumber) or 0,
    }
end

local function eventStepChanged(before, after)
    if type(before) ~= "table" or type(after) ~= "table" then
        return before ~= after
    end
    return tostring(before.eventId or "") ~= tostring(after.eventId or "")
        or tonumber(before.turn) ~= tonumber(after.turn)
        or tonumber(before.tick) ~= tonumber(after.tick)
end

local function finishAdvanceProcess(pending, server, outcome)
    if type(pending) ~= "table" or pending.finished == true then
        return false
    end

    pending.finished = true
    if Timings.PendingAdvanceProcess == pending then
        Timings.PendingAdvanceProcess = nil
    end

    Timings:Stop(pending.timer, {
        process = true,
        cardinality = buildRuntimeCardinality(server, {
            outcome = tostring(outcome or "completed"),
        }),
    })
    return true
end

local function wrapAdvanceProcess(server)
    if type(server) ~= "table" or type(server.AdvanceEventStep) ~= "function" then
        return false
    end
    if Timings.RuntimeHooks["Server.AdvanceEventStepProcess"] == true then
        return false
    end

    local originalAdvance = server.AdvanceEventStep
    local originalCommit = server._AdvanceEventStepAfterCommit

    if type(originalCommit) == "function" then
        server._AdvanceEventStepAfterCommit = function(self, ...)
            local pending = Timings.PendingAdvanceProcess
            local results = packValues(pcall(originalCommit, self, ...))
            if type(pending) == "table" and pending.server == self then
                finishAdvanceProcess(pending, self, results[1] == true and "completed" or "error")
            end
            if results[1] ~= true then
                error(results[2], 0)
            end
            return unpackValues(results, 2, results.n)
        end
        Timings.RuntimeHooks["Server._AdvanceEventStepAfterCommitProcess"] = true
    end

    server.AdvanceEventStep = function(self, ...)
        if not isEnabled() then
            return originalAdvance(self, ...)
        end

        local previous = Timings.PendingAdvanceProcess
        if type(previous) == "table" and previous.finished ~= true then
            finishAdvanceProcess(previous, previous.server or self, "replaced")
        end

        local pending = {
            server = self,
            before = eventStepIdentity(self.EventState),
            timer = Timings:Start("Advance turn/tick", {
                context = "event-advance",
                thresholdMs = 8,
                process = true,
            }),
            finished = false,
        }
        Timings.PendingAdvanceProcess = pending

        local results = packValues(pcall(originalAdvance, self, ...))
        if results[1] ~= true then
            finishAdvanceProcess(pending, self, "error")
            error(results[2], 0)
        end

        if pending.finished ~= true then
            local after = eventStepIdentity(self.EventState)
            local accepted = results[2] == true
            if eventStepChanged(pending.before, after) then
                finishAdvanceProcess(pending, self, "completed")
            elseif not accepted then
                finishAdvanceProcess(pending, self, "rejected")
            elseif type(originalCommit) ~= "function" then
                finishAdvanceProcess(pending, self, "completed")
            end
        end

        return unpackValues(results, 2, results.n)
    end

    Timings.RuntimeHooks["Server.AdvanceEventStepProcess"] = true
    return true
end

local function buildPlanCardinality(plan, state, outcome)
    local source = type(plan) == "table" and plan or {}
    local stateSource = type(state) == "table" and state or {}
    return {
        eventId = tostring(source.eventId or stateSource.eventId or ""),
        turn = tonumber(source.turnNumber or stateSource.turnNumber) or 0,
        tick = tonumber(source.tickNumber or stateSource.tickNumber) or 0,
        actor = tostring(source.actorKey or stateSource.actorKey or ""),
        outcome = tostring(outcome or "completed"),
    }
end

local function wrapAutopilotPlanning(client)
    if type(client) ~= "table" or type(client.StartAutopilotStep) ~= "function" then
        return false
    end
    if Timings.RuntimeHooks["Client.StartAutopilotStepProcess"] == true then
        return false
    end

    local original = client.StartAutopilotStep
    client.StartAutopilotStep = function(self, ...)
        if not isEnabled() then
            return original(self, ...)
        end

        local timer = Timings:Start("Autopilot planning", {
            context = "autopilot",
            thresholdMs = 8,
            process = true,
        })
        local results = packValues(pcall(original, self, ...))
        if results[1] ~= true then
            Timings:Stop(timer, {
                process = true,
                cardinality = { outcome = "error" },
            })
            error(results[2], 0)
        end

        local plan = results[2]
        local created = results[3] == true
        local job = type(plan) == "table" and plan.job or nil
        if not created then
            return unpackValues(results, 2, results.n)
        end

        if type(job) ~= "table" then
            Timings:Stop(timer, {
                process = true,
                cardinality = buildPlanCardinality(plan, nil, "failed"),
            })
            return unpackValues(results, 2, results.n)
        end

        if job._rpeProcessTimingWrapped == true then
            return unpackValues(results, 2, results.n)
        end
        job._rpeProcessTimingWrapped = true

        local finalized = false
        local function finalize(state, outcome)
            if finalized then
                return
            end
            finalized = true
            Timings:Stop(timer, {
                process = true,
                cardinality = buildPlanCardinality(plan, state, outcome),
            })
        end

        local originalComplete = job.onComplete
        job.onComplete = function(state, completedJob)
            local callbackResults = nil
            if type(originalComplete) == "function" then
                callbackResults = packValues(pcall(originalComplete, state, completedJob))
            else
                callbackResults = { n = 1, true }
            end
            finalize(state, callbackResults[1] == true and "completed" or "error")
            if callbackResults[1] ~= true then
                error(callbackResults[2], 0)
            end
            return unpackValues(callbackResults, 2, callbackResults.n)
        end

        local originalCancel = job.onCancel
        job.onCancel = function(state, reason, cancelledJob)
            local callbackResults = nil
            if type(originalCancel) == "function" then
                callbackResults = packValues(pcall(originalCancel, state, reason, cancelledJob))
            else
                callbackResults = { n = 1, true }
            end
            finalize(state, callbackResults[1] == true and tostring(reason or "cancelled") or "error")
            if callbackResults[1] ~= true then
                error(callbackResults[2], 0)
            end
            return unpackValues(callbackResults, 2, callbackResults.n)
        end

        return unpackValues(results, 2, results.n)
    end

    Timings.RuntimeHooks["Client.StartAutopilotStepProcess"] = true
    return true
end

function Timings:InstallRuntimeHooks()
    local server = Addon.Server
    local client = Addon.Client

    -- Full process boundaries only. Detailed phase/slice instrumentation remains
    -- available through /rpe debug timings on, but INTERNAL alone does not emit it.
    wrapProcessMethod(server, "StartEvent", "Event start (host)", "event-start", 8, "Server.StartEventProcess")
    wrapAdvanceProcess(server)
    wrapAutopilotPlanning(client)

    -- These are complete host actions. RuntimeProcessDepth prevents nested
    -- authorization/execution calls from producing duplicate process lines.
    wrapProcessMethod(client, "AuthorizeAllAutopilotPendingActions", "Autopilot authorize all", "autopilot", 8, "Client.AuthorizeAllAutopilotPendingActionsProcess")
    wrapProcessMethod(client, "AuthorizeAutopilotPendingAction", "Autopilot authorize action", "autopilot", 8, "Client.AuthorizeAutopilotPendingActionProcess")
    wrapProcessMethod(client, "ConfirmAutopilotPendingMovement", "Autopilot confirm movement", "autopilot", 8, "Client.ConfirmAutopilotPendingMovementProcess")
    wrapProcessMethod(client, "ExecuteEventUnitSpell", "Autopilot execute spell", "autopilot", 8, "Client.ExecuteEventUnitSpellProcess")

    return true
end

-- Timings.lua loads before event/autopilot implementation files. Install after
-- the addon's TOC has finished so the final wrapped methods are measured.
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