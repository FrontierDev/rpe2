local addonName, Addon = ...

local Commands = Addon.Commands or {}
Addon.Commands = Commands
local Debug = Addon.Debug or {}

Commands.Registry = Commands.Registry or {}
Commands.Initialized = Commands.Initialized or false

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function getTimings()
    return Addon.Debug and Addon.Debug.Timings or nil
end

local function formatCardinality(cardinality)
    if type(cardinality) ~= "table" then
        return cardinality ~= nil and tostring(cardinality) or ""
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

local function printTaskStats(router, prefix)
    local tasks = getTasks()
    local stats = tasks and type(tasks.GetStats) == "function" and tasks:GetStats() or nil
    if type(stats) ~= "table" then
        router:Print("%sTaskQueue diagnostics unavailable.", nil, prefix or "")
        return false
    end

    router:Print(
        "%sTaskQueue pending=%d normal=%d sliceable=%d lastFlushJobs=%d lastFlush=%.2fms maxFlush=%.2fms budget=%d timeBudget=%.2fms sliceBudget=%.2fms lastSlice=%s/%.2fms maxSlice=%.2fms slices=%d cancelled=%d stale=%d interval=%.3fs paused=%s totalExecuted=%d.",
        nil,
        prefix or "",
        tonumber(stats.queueLength) or 0,
        tonumber(stats.normalQueuedJobs) or 0,
        tonumber(stats.sliceableQueuedJobs) or 0,
        tonumber(stats.jobsExecutedLastFlush) or 0,
        tonumber(stats.lastFlushElapsedMs) or 0,
        tonumber(stats.maxFlushElapsedMs) or 0,
        tonumber(stats.budget) or 0,
        tonumber(stats.timeBudget) or 0,
        tonumber(stats.sliceBudget) or 0,
        tostring(stats.lastSliceLabel or "none"),
        tonumber(stats.lastSliceElapsedMs) or 0,
        tonumber(stats.maxSliceElapsedMs) or 0,
        tonumber(stats.totalSlicesExecuted) or 0,
        tonumber(stats.totalCancelled) or 0,
        tonumber(stats.totalStaleCancelled) or 0,
        tonumber(stats.flushInterval) or 0,
        stats.paused and "yes" or "no",
        tonumber(stats.totalExecuted) or 0
    )
    return true
end

local function printRecentSlowRecords(router)
    local timings = getTimings()
    local records = timings and type(timings.GetRecentRecords) == "function"
        and timings:GetRecentRecords({ slowOnly = true }) or {}

    router:Print("Recent slow operations (%d):", nil, #records)
    if #records == 0 then
        router:Print("  none recorded.")
        return 0
    end

    for index = 1, #records do
        local record = records[index]
        local context = record.context and (" context=" .. tostring(record.context)) or ""
        local cardinality = formatCardinality(record.cardinality)
        if cardinality ~= "" then
            cardinality = " cardinality=" .. cardinality
        end
        router:Print(
            "  #%d %s %.2fms (threshold %.2fms)%s%s",
            nil,
            tonumber(record.order) or index,
            tostring(record.label or "operation"),
            tonumber(record.elapsedMs) or 0,
            tonumber(record.thresholdMs) or 0,
            context,
            cardinality
        )
    end

    return #records
end

local function printPerformanceDiagnostics(router)
    printRecentSlowRecords(router)
    printTaskStats(router, "")
    return true
end

local function copyPathTokens(path)
    local tokens = {}

    if type(path) == "string" then
        for token in string.gmatch(string.lower(path), "%S+") do
            tokens[#tokens + 1] = token
        end
        return tokens
    end

    for index = 1, #(path or {}) do
        local token = string.lower(tostring(path[index] or ""))
        if token ~= "" then
            tokens[#tokens + 1] = token
        end
    end

    return tokens
end

local function tokenizeMessage(message)
    local tokens = {}

    for token in string.gmatch(string.lower(tostring(message or "")), "%S+") do
        tokens[#tokens + 1] = token
    end

    return tokens
end

local function joinTokens(tokens, limit)
    return table.concat(tokens, " ", 1, limit or #tokens)
end

function Commands:Print(message, level, ...)
    if level == "error" and Debug.Error then
        return Debug.Error(message, ...)
    end

    if level == "warn" and Debug.Warn then
        return Debug.Warn(message, ...)
    end

    if Debug.Info then
        return Debug.Info(message, ...)
    end

    local text = select("#", ...) > 0 and string.format(message, ...) or tostring(message)
    print(text)
end

function Commands:RegisterCommand(path, handler, options)
    local tokens = copyPathTokens(path)
    if #tokens == 0 then
        error("Addon.Commands:RegisterCommand(path, handler, options) requires a non-empty path.", 2)
    end

    if type(handler) ~= "function" then
        error("Addon.Commands:RegisterCommand(path, handler, options) requires a function handler.", 2)
    end

    local key = joinTokens(tokens)
    self.Registry[key] = {
        key = key,
        tokens = tokens,
        handler = handler,
        description = options and options.description or "",
    }

    return self.Registry[key]
end

function Commands:GetRegisteredCommands()
    local commands = {}

    for _, entry in pairs(self.Registry or {}) do
        commands[#commands + 1] = entry
    end

    table.sort(commands, function(left, right)
        return left.key < right.key
    end)

    return commands
end

local function buildHelpGroups(commands)
    local groups = {}
    local groupOrder = {}

    for index = 1, #commands do
        local entry = commands[index]
        local tokens = entry.tokens or {}
        local head = tokens[1] or entry.key

        if groups[head] == nil then
            groups[head] = {
                root = nil,
                children = {},
            }
            groupOrder[#groupOrder + 1] = head
        end

        if #tokens <= 1 then
            groups[head].root = entry
        else
            groups[head].children[#groups[head].children + 1] = entry
        end
    end

    table.sort(groupOrder)
    for index = 1, #groupOrder do
        table.sort(groups[groupOrder[index]].children, function(left, right)
            return left.key < right.key
        end)
    end

    return groups, groupOrder
end

function Commands:PrintHelp()
    self:Print("Available /rpe commands:")

    local commands = self:GetRegisteredCommands()
    local groups, groupOrder = buildHelpGroups(commands)

    for index = 1, #groupOrder do
        local key = groupOrder[index]
        local group = groups[key]
        local root = group.root
        local children = group.children or {}

        if root then
            if root.description ~= "" then
                self:Print("  /rpe %s - %s", nil, root.key, root.description)
            else
                self:Print("  /rpe %s", nil, root.key)
            end
        else
            self:Print("  /rpe %s", nil, key)
        end

        for childIndex = 1, #children do
            local entry = children[childIndex]
            local suffix = table.concat(entry.tokens, " ", 2)

            if entry.description ~= "" then
                self:Print("    %s - %s", nil, suffix, entry.description)
            else
                self:Print("    %s", nil, suffix)
            end
        end
    end
end

Commands:RegisterCommand({ "debug", "timings" }, function(context)
    local Debug = Addon.Debug or {}
    local Timings = Debug.Timings or nil
    local requestedState = context and context.args and context.args[1] or nil
    local enabled = nil

    if requestedState == "on" or requestedState == "1" or requestedState == "true" then
        enabled = true
    elseif requestedState == "off" or requestedState == "0" or requestedState == "false" then
        enabled = false
    elseif Timings and type(Timings.IsEnabled) == "function" then
        enabled = not Timings:IsEnabled()
    else
        enabled = true
    end

    if Debug.SetLevelEnabled then
        Debug.SetLevelEnabled("internal", enabled)
    end
    if Timings and type(Timings.SetEnabled) == "function" then
        Timings:SetEnabled(enabled)
    else
        Debug.Timings = Debug.Timings or {}
        Debug.Timings.Enabled = enabled
    end

    context.router:Print("Debug timings %s.", nil, enabled and "enabled" or "disabled")
    return true
end, {
    description = "Toggle internal timing debug output. Use /rpe debug timings on or off.",
})

Commands:RegisterCommand({ "debug", "perf" }, function(context)
    return printPerformanceDiagnostics(context.router)
end, {
    description = "Print recent slow timing records and TaskQueue diagnostics.",
})

Commands:RegisterCommand({ "debug", "tasks" }, function(context)
    return printTaskStats(context.router, "")
end, {
    description = "Print TaskQueue diagnostics.",
})

Commands:RegisterCommand({ "debug" }, function(context)
    return printPerformanceDiagnostics(context.router)
end, {
    description = "Print recent slow timing records and TaskQueue diagnostics.",
})

function Commands:Run(message)
    local tokens = tokenizeMessage(message)
    if #tokens == 0 then
        local client = Addon.Client or nil
        if type(client) == "table" and type(client.ToggleLauncherMenu) == "function" then
            local handled = client:ToggleLauncherMenu()
            if handled ~= false then
                return true
            end
        end

        self:PrintHelp()
        return true
    end

    if tokens[1] == "help" then
        self:PrintHelp()
        return true
    end

    for tokenCount = #tokens, 1, -1 do
        local entry = self.Registry[joinTokens(tokens, tokenCount)]
        if entry then
            local args = {}
            for index = tokenCount + 1, #tokens do
                args[#args + 1] = tokens[index]
            end

            local context = {
                router = self,
                command = entry,
                args = args,
                tokens = tokens,
                raw = tostring(message or ""),
            }

            return entry.handler(context)
        end
    end

    self:Print("Unknown command: %s", "warn", tostring(message or ""))
    self:PrintHelp()
    return false
end

function Commands:Execute(message, options)
    local tasks = getTasks()
    local immediate = type(options) == "table" and options.immediate == true

    if tasks and tasks.Enqueue and not immediate then
        tasks:Enqueue(function()
            self:Run(message)
        end)
        return true
    end

    return self:Run(message)
end

function Commands:Initialize()
    if self.Initialized then
        return true
    end

    SLASH_RPEENGINEDEV1 = "/rpe"
    SlashCmdList.RPEENGINEDEV = function(message)
        Commands:Execute(message)
    end

    self.Initialized = true
    return true
end

Commands:Initialize()
