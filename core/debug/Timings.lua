local _, Addon = ...

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
    if not Timings.Enabled then
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
    if type(Debug) ~= "table" or type(Debug.Internal) ~= "function" then
        return false
    end

    if type(Debug.EnsureInternalLevelEnabled) == "function" then
        Debug.EnsureInternalLevelEnabled()
    end

    local slow = shouldMarkSlow(elapsedMs, thresholdMs)
    local cardinalityText = formatCardinality(cardinality)
    Debug.Internal(
        "%sTiming%s %s took %.2fms%s",
        slow and "SLOW " or "",
        buildContextSuffix(context),
        tostring(label or "operation"),
        math.max(0, tonumber(elapsedMs) or 0),
        cardinalityText ~= "" and (" [" .. cardinalityText .. "]") or ""
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
    if not Timings.Enabled and not (type(options) == "table" and options.force == true) then
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
    if Timings.Enabled then
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

    if not Timings.Enabled and not (type(options) == "table" and options.force == true) then
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
    if not Timings.IsEnabled() then
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

    if type(Debug.EnsureInternalLevelEnabled) == "function" then
        Debug.EnsureInternalLevelEnabled()
    end

    local cardinalityText = formatCardinality(cardinality)
    Debug.Internal(
        "%sTiming%s %s: %s%s",
        hasSlow and "SLOW " or "",
        buildContextSuffix(context),
        tostring(label or "operation"),
        table.concat(segments, ", "),
        cardinalityText ~= "" and (" [" .. cardinalityText .. "]") or ""
    )
    return true
end

return Timings
