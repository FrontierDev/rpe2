local _, Addon = ...

local Debug = Addon.Debug or {}
Addon.Debug = Debug

Debug.Levels = Debug.Levels or {
    info = {
        label = "INFO",
        color = "|cff66c2ff",
    },
    warn = {
        label = "WARN",
        color = "|cffffd166",
    },
    error = {
        label = "ERROR",
        color = "|cffff6b6b",
    },
    internal = {
        label = "INTERNAL",
        color = "|cffc792ea",
    },
}

Debug.EnabledLevels = Debug.EnabledLevels or {
    info = true,
    warn = true,
    error = true,
    internal = false,
}

Debug.CommsTracing = Debug.CommsTracing == true
Debug.ResourceTracing = Debug.ResourceTracing == true
Debug.SpellcastTiming = false

local PREFIX = ("|cff33ff99%s|r"):format(Addon.Name or "Addon")

local function safeToString(value)
    local ok, result = pcall(function()
        return tostring(value)
    end)

    if ok then
        return result
    end

    return "[unprintable]"
end

local function safeFormat(message, ...)
    if select("#", ...) == 0 then
        return safeToString(message)
    end

    local ok, result = pcall(string.format, message, ...)
    if ok then
        return result
    end

    return safeToString(message)
end

local function emitChatLine(line)
    local output = safeToString(line)

    local function emit()
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(output)
            return
        end

        print(output)
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, emit)
        return
    end

    emit()
end

local function isLevelEnabled(level)
    local normalizedLevel = type(level) == "string" and string.lower(level) or "info"
    local enabledLevels = type(Debug.EnabledLevels) == "table" and Debug.EnabledLevels or nil
    if enabledLevels and enabledLevels[normalizedLevel] ~= nil then
        return enabledLevels[normalizedLevel] == true
    end

    return normalizedLevel == "warn" or normalizedLevel == "error"
end

function Debug.FormattedDebug(level, message, ...)
    local resolvedLevel = "info"
    local resolvedMessage = level

    if type(level) == "string" then
        local normalized = string.lower(level)

        if Debug.Levels[normalized] then
            resolvedLevel = normalized
            resolvedMessage = message
        end
    end

    if not isLevelEnabled(resolvedLevel) then
        return false
    end

    resolvedMessage = safeFormat(resolvedMessage, ...)

    local levelData = Debug.Levels[resolvedLevel]
    local text = ("%s[%s]|r %s: %s"):format(levelData.color, levelData.label, PREFIX, safeToString(resolvedMessage))

    if string.find(text, "\n", 1, true) then
        for line in string.gmatch(text, "([^\n]+)") do
            emitChatLine(line)
        end
        return
    end

    emitChatLine(text)
    return true
end

function Debug.Info(message, ...)
    return Debug.FormattedDebug("info", message, ...)
end

function Debug.Warn(message, ...)
    return Debug.FormattedDebug("warn", message, ...)
end

function Debug.Error(message, ...)
    return Debug.FormattedDebug("error", message, ...)
end

function Debug.Internal(message, ...)
    return Debug.FormattedDebug("internal", message, ...)
end

function Debug.EnsureInternalLevelEnabled()
    -- Kept for callers that opt into detailed diagnostics, but internal output
    -- is always controlled explicitly by the runtime debug setting.
    return Debug.IsLevelEnabled and Debug.IsLevelEnabled("internal") or false
end

function Debug.SetLevelEnabled(level, enabled)
    local normalizedLevel = type(level) == "string" and string.lower(level) or nil
    if normalizedLevel == nil or Debug.Levels[normalizedLevel] == nil then
        return false
    end

    local nextEnabled = enabled == true
    Debug.EnabledLevels = Debug.EnabledLevels or {}
    Debug.EnabledLevels[normalizedLevel] = nextEnabled

    -- INTERNAL is the development diagnostics level. Keep timing collection in
    -- lockstep with it so enabling RPE INTERNAL immediately exposes the timing
    -- scopes that already instrument event startup and other hot paths.
    if normalizedLevel == "internal" then
        local timings = Debug.Timings
        if type(timings) == "table" and type(timings.SetEnabled) == "function" then
            timings:SetEnabled(nextEnabled)
        elseif type(timings) == "table" then
            timings.Enabled = nextEnabled
        end
    end

    return true
end

function Debug.IsLevelEnabled(level)
    return isLevelEnabled(level)
end
