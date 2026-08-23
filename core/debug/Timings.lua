local _, Addon = ...

local Debug = Addon.Debug or {}
Addon.Debug = Debug

Debug.Timings = Debug.Timings or {}
local Timings = Debug.Timings

local unpackValues = unpack or table.unpack

Timings.Enabled = Timings.Enabled == true
Timings.DefaultThresholdMs = tonumber(Timings.DefaultThresholdMs) or 0

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

local function shouldLog(options)
    if type(options) == "table" and options.force == true then
        return true
    end

    return Timings.Enabled == true
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

local function emitTiming(label, elapsedMs, context, thresholdMs)
    if type(Debug) ~= "table" or type(Debug.Internal) ~= "function" then
        return false
    end

    if type(Debug.EnsureInternalLevelEnabled) == "function" then
        Debug.EnsureInternalLevelEnabled()
    end

    local slow = shouldMarkSlow(elapsedMs, thresholdMs)
    Debug.Internal(
        "%sTiming%s %s took %.2fms",
        slow and "SLOW " or "",
        buildContextSuffix(context),
        tostring(label or "operation"),
        math.max(0, tonumber(elapsedMs) or 0)
    )
    return true
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
    return Timings.Enabled == true
end

function Timings.IsActive()
    return Timings.Enabled == true
        and type(Debug) == "table"
        and type(Debug.Internal) == "function"
end

function Timings:Start(label, options)
    return {
        label = tostring(label or "operation"),
        context = type(options) == "table" and options.context or nil,
        thresholdMs = type(options) == "table" and tonumber(options.thresholdMs) or nil,
        startedAtMs = getNowMilliseconds(),
        force = type(options) == "table" and options.force == true or false,
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

    local logged = false
    if shouldLog({
        force = resolvedOptions.force == true or timer.force == true,
    }) then
        logged = emitTiming(resolvedOptions.label or timer.label, elapsedMs, context, thresholdMs)
    end

    return elapsedMs, logged
end

function Timings:Measure(label, fn, options, ...)
    if type(fn) ~= "function" then
        return nil
    end

    local timer = self:Start(label, options)
    local results = { pcall(fn, ...) }
    local ok = table.remove(results, 1)
    self:Stop(timer, options)

    if not ok then
        error(results[1], 0)
    end

    return unpackValues(results)
end

function Timings:Wrap(label, fn, options)
    if type(fn) ~= "function" then
        return nil
    end

    return function(...)
        return Timings:Measure(label, fn, options, ...)
    end
end

function Timings:LogParts(label, context, parts, totalElapsedMs, thresholdMs)
    if not Timings.IsActive() then
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

    if type(Debug.EnsureInternalLevelEnabled) == "function" then
        Debug.EnsureInternalLevelEnabled()
    end

    Debug.Internal(
        "%sTiming%s %s: %s",
        hasSlow and "SLOW " or "",
        buildContextSuffix(context),
        tostring(label or "operation"),
        table.concat(segments, ", ")
    )
    return true
end

return Timings
