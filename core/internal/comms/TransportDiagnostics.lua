local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Utils = Addon.Utils or {}

local Comms = Addon.Internal.Comms
local Diagnostics = Comms.Diagnostics or {}
local Queue = Comms.MessageQueue or {}
local Operations = Comms.Operations or {}
local Serialization = Comms.Serialization or {}
local Common = Addon.Utils.Common or {}

if type(Comms) ~= "table"
    or type(Diagnostics) ~= "table"
    or type(Queue) ~= "table"
    or Diagnostics._baselineTransportDiagnosticsInstalled == true
then
    return
end

local unpackValues = unpack or table.unpack
local STARTUP_KEYS = {
    EVENT_START = true,
    EVENT_UNITS = true,
    EVENT_STATE = true,
}
local MAX_RECENT_LOGICAL_SENDS = 128
local MAX_THROTTLE_EVENTS = 64
local MAX_STARTUP_SESSIONS = 8
local MAX_STARTUP_MESSAGES_PER_SESSION = 128

Diagnostics.LogicalMessageSequence = math.max(0, math.floor(tonumber(Diagnostics.LogicalMessageSequence) or 0))
Diagnostics.ActiveLogicalMessages = type(Diagnostics.ActiveLogicalMessages) == "table" and Diagnostics.ActiveLogicalMessages or {}
Diagnostics.RecentLogicalMessages = type(Diagnostics.RecentLogicalMessages) == "table" and Diagnostics.RecentLogicalMessages or {}
Diagnostics.StartupBySession = type(Diagnostics.StartupBySession) == "table" and Diagnostics.StartupBySession or {}
Diagnostics.StartupSessionOrder = type(Diagnostics.StartupSessionOrder) == "table" and Diagnostics.StartupSessionOrder or {}
Diagnostics.LastStartupSessionId = tostring(Diagnostics.LastStartupSessionId or "")

local activeEnqueueContext = nil

local function pack(...)
    return { n = select("#", ...), ... }
end

local function deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, nested in pairs(value) do
        copy[key] = deepCopy(nested, seen)
    end
    return copy
end

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function getNowMilliseconds()
    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if type(timings) == "table" and type(timings.GetNowMilliseconds) == "function" then
        return tonumber(timings.GetNowMilliseconds()) or 0
    end
    if type(GetTimePreciseSec) == "function" then
        return (tonumber(GetTimePreciseSec()) or 0) * 1000
    end
    if type(GetTime) == "function" then
        return (tonumber(GetTime()) or 0) * 1000
    end
    if type(Common.GetNow) == "function" then
        return (tonumber(Common.GetNow()) or 0) * 1000
    end
    return 0
end

local function getOperationKey(opcode)
    local operation = type(Operations.Get) == "function" and Operations:Get(opcode) or nil
    return type(operation) == "table" and trim(operation.key) or ""
end

local function appendBounded(list, value, maximum)
    list[#list + 1] = value
    while #list > maximum do
        table.remove(list, 1)
    end
end

local function updateQueueDepth(diagnostics)
    local length = #(type(Queue.Items) == "table" and Queue.Items or {})
    diagnostics.currentQueueLength = length
    diagnostics.highWaterQueueLength = math.max(
        math.floor(tonumber(diagnostics.highWaterQueueLength) or 0),
        length
    )
    return length
end

local function getLogical(logicalId)
    return Diagnostics.ActiveLogicalMessages[tostring(logicalId or "")]
end

local function touchStartupSession(sessionId)
    local normalized = trim(sessionId)
    if normalized == "" then
        return nil
    end
    for index = #Diagnostics.StartupSessionOrder, 1, -1 do
        if Diagnostics.StartupSessionOrder[index] == normalized then
            table.remove(Diagnostics.StartupSessionOrder, index)
            break
        end
    end
    Diagnostics.StartupSessionOrder[#Diagnostics.StartupSessionOrder + 1] = normalized
    Diagnostics.LastStartupSessionId = normalized
    while #Diagnostics.StartupSessionOrder > MAX_STARTUP_SESSIONS do
        local oldest = table.remove(Diagnostics.StartupSessionOrder, 1)
        Diagnostics.StartupBySession[oldest] = nil
    end
    return normalized
end

local function newStartupBucket()
    return {
        logicalMessages = 0,
        logicalBytes = 0,
        physicalPackets = 0,
        physicalBytes = 0,
        deliveredMessages = 0,
        failedMessages = 0,
        supersededMessages = 0,
        firstEnqueuedAtMs = nil,
        lastTerminalAtMs = nil,
        deliveryDurationMs = 0,
    }
end

local function ensureStartupBucket(session, operationKey, distribution, target)
    session.total = type(session.total) == "table" and session.total or newStartupBucket()
    session.byOpcode = type(session.byOpcode) == "table" and session.byOpcode or {}
    session.byRoute = type(session.byRoute) == "table" and session.byRoute or {}

    local opcodeBucket = session.byOpcode[operationKey]
    if type(opcodeBucket) ~= "table" then
        opcodeBucket = newStartupBucket()
        opcodeBucket.operationKey = operationKey
        session.byOpcode[operationKey] = opcodeBucket
    end

    local routeKey = tostring(distribution or "") .. "\31" .. tostring(target or "")
    local routeBucket = session.byRoute[routeKey]
    if type(routeBucket) ~= "table" then
        routeBucket = newStartupBucket()
        routeBucket.distribution = distribution
        routeBucket.target = target
        session.byRoute[routeKey] = routeBucket
    end
    return session.total, opcodeBucket, routeBucket
end

local function updateBucketWindow(bucket, enqueuedAtMs, terminalAtMs)
    if enqueuedAtMs ~= nil then
        if bucket.firstEnqueuedAtMs == nil or enqueuedAtMs < bucket.firstEnqueuedAtMs then
            bucket.firstEnqueuedAtMs = enqueuedAtMs
        end
    end
    if terminalAtMs ~= nil then
        if bucket.lastTerminalAtMs == nil or terminalAtMs > bucket.lastTerminalAtMs then
            bucket.lastTerminalAtMs = terminalAtMs
        end
    end
    if bucket.firstEnqueuedAtMs ~= nil and bucket.lastTerminalAtMs ~= nil then
        bucket.deliveryDurationMs = math.max(0, bucket.lastTerminalAtMs - bucket.firstEnqueuedAtMs)
    end
end

local function registerStartupLogical(logical)
    if not STARTUP_KEYS[logical.operationKey] or trim(logical.eventSessionId) == "" then
        return
    end
    local sessionId = touchStartupSession(logical.eventSessionId)
    local session = Diagnostics.StartupBySession[sessionId]
    if type(session) ~= "table" then
        session = {
            eventSessionId = sessionId,
            messages = {},
        }
        Diagnostics.StartupBySession[sessionId] = session
    end
    local total, opcodeBucket, routeBucket = ensureStartupBucket(
        session,
        logical.operationKey,
        logical.distribution,
        logical.target
    )
    for _, bucket in ipairs({ total, opcodeBucket, routeBucket }) do
        bucket.logicalMessages = (bucket.logicalMessages or 0) + 1
        bucket.logicalBytes = (bucket.logicalBytes or 0) + (logical.serializedArgumentBytes or 0)
    end
    for _, bucket in ipairs({ total, opcodeBucket, routeBucket }) do
        bucket.physicalPackets = (bucket.physicalPackets or 0) + (logical.physicalPacketCount or 0)
        bucket.physicalBytes = (bucket.physicalBytes or 0) + (logical.physicalPacketBytes or 0)
    end
    session.messageOrder = type(session.messageOrder) == "table" and session.messageOrder or {}
    session.messages[logical.id] = {
        id = logical.id,
        operationKey = logical.operationKey,
        distribution = logical.distribution,
        target = logical.target,
        priority = logical.priority,
        logicalBytes = logical.serializedArgumentBytes or 0,
        physicalPackets = logical.physicalPacketCount or 0,
        physicalBytes = logical.physicalPacketBytes or 0,
        status = "queued",
        deliveryDurationMs = nil,
        replaceKey = logical.replaceKey,
    }
    session.messageOrder[#session.messageOrder + 1] = logical.id
    while #session.messageOrder > MAX_STARTUP_MESSAGES_PER_SESSION do
        local oldest = table.remove(session.messageOrder, 1)
        session.messages[oldest] = nil
    end
end

local function registerStartupTerminal(logical, status, terminalAtMs)
    local session = Diagnostics.StartupBySession[trim(logical.eventSessionId)]
    if type(session) ~= "table" then
        return
    end
    local total, opcodeBucket, routeBucket = ensureStartupBucket(
        session,
        logical.operationKey,
        logical.distribution,
        logical.target
    )
    for _, bucket in ipairs({ total, opcodeBucket, routeBucket }) do
        if status == "delivered" then
            bucket.deliveredMessages = (bucket.deliveredMessages or 0) + 1
        elseif status == "superseded" then
            bucket.supersededMessages = (bucket.supersededMessages or 0) + 1
        else
            bucket.failedMessages = (bucket.failedMessages or 0) + 1
        end
        updateBucketWindow(bucket, logical.enqueuedAtMs, terminalAtMs)
    end
    local message = session.messages and session.messages[logical.id] or nil
    if type(message) == "table" then
        message.status = status
        message.deliveryDurationMs = logical.totalDeliveryMs
        message.queueWaitMs = logical.queueWaitMs
    end
end

local function archiveLogical(logical)
    Diagnostics.ActiveLogicalMessages[logical.id] = nil
    appendBounded(Diagnostics.RecentLogicalMessages, deepCopy(logical), MAX_RECENT_LOGICAL_SENDS)
end

local function finalizeLogicalFailure(logical, reason, nowMs)
    if type(logical) ~= "table" or logical.terminal == true then
        return false
    end
    local terminalAt = tonumber(nowMs) or getNowMilliseconds()
    logical.terminal = true
    logical.status = "failed"
    logical.failureReason = reason
    logical.failedAt = terminalAt
    logical.failedAtMs = terminalAt
    logical.totalDeliveryMs = logical.enqueuedAtMs ~= nil
        and math.max(0, terminalAt - logical.enqueuedAtMs)
        or math.max(0, terminalAt - (tonumber(logical.startedAtMs) or terminalAt))
    if logical.firstAttemptAtMs ~= nil and logical.enqueuedAtMs ~= nil then
        logical.queueWaitMs = math.max(0, logical.firstAttemptAtMs - logical.enqueuedAtMs)
    end
    local transport = Diagnostics:GetTransportDiagnosticsStore()
    transport.logicalFailedCount = (transport.logicalFailedCount or 0) + 1
    transport.lastLogicalSend = deepCopy(logical)
    registerStartupTerminal(logical, "failed", terminalAt)
    archiveLogical(logical)
    return true
end

local function finalizeLogicalSuperseded(logical, reason, nowMs)
    if type(logical) ~= "table" or logical.terminal == true then
        return false
    end
    local terminalAt = tonumber(nowMs) or getNowMilliseconds()
    logical.terminal = true
    logical.status = "superseded"
    logical.supersedeReason = reason or "superseded"
    logical.supersededAt = terminalAt
    logical.supersededAtMs = terminalAt
    logical.totalDeliveryMs = logical.enqueuedAtMs ~= nil
        and math.max(0, terminalAt - logical.enqueuedAtMs)
        or math.max(0, terminalAt - (tonumber(logical.startedAtMs) or terminalAt))
    if logical.firstAttemptAtMs ~= nil and logical.enqueuedAtMs ~= nil then
        logical.queueWaitMs = math.max(0, logical.firstAttemptAtMs - logical.enqueuedAtMs)
    end
    local transport = Diagnostics:GetTransportDiagnosticsStore()
    transport.logicalSupersededCount = (transport.logicalSupersededCount or 0) + 1
    transport.lastLogicalSend = deepCopy(logical)
    registerStartupTerminal(logical, "superseded", terminalAt)
    archiveLogical(logical)
    return true
end

local function finalizeLogicalSuccess(logical, nowMs)
    if type(logical) ~= "table" or logical.terminal == true then
        return false
    end
    local terminalAt = tonumber(nowMs) or getNowMilliseconds()
    logical.terminal = true
    logical.status = "delivered"
    logical.deliveredAt = terminalAt
    logical.deliveredAtMs = terminalAt
    logical.totalDeliveryMs = logical.enqueuedAtMs ~= nil
        and math.max(0, terminalAt - logical.enqueuedAtMs)
        or math.max(0, terminalAt - (tonumber(logical.startedAtMs) or terminalAt))
    if logical.firstAttemptAtMs ~= nil and logical.enqueuedAtMs ~= nil then
        logical.queueWaitMs = math.max(0, logical.firstAttemptAtMs - logical.enqueuedAtMs)
    end
    local transport = Diagnostics:GetTransportDiagnosticsStore()
    transport.logicalSentCount = (transport.logicalSentCount or 0) + 1
    transport.lastLogicalSend = deepCopy(logical)
    registerStartupTerminal(logical, "delivered", terminalAt)
    archiveLogical(logical)
    return true
end

local function markLogicalAttempt(item, nowMs)
    local logical = getLogical(item and item._rpeLogicalDiagnosticId)
    if type(logical) ~= "table" then
        return nil
    end
    local attemptAt = tonumber(nowMs) or getNowMilliseconds()
    if logical.firstAttemptAtMs == nil then
        logical.firstAttemptAt = attemptAt
        logical.firstAttemptAtMs = attemptAt
        if logical.enqueuedAtMs ~= nil then
            logical.queueWaitMs = math.max(0, attemptAt - logical.enqueuedAtMs)
        end
    end
    logical.attemptCount = (logical.attemptCount or 0) + 1
    return logical
end

function Diagnostics:BeginLogicalSend(metadata, distribution, target, payloadText, eventSessionId, packetCount, packetBytes)
    self.LogicalMessageSequence = math.max(0, math.floor(tonumber(self.LogicalMessageSequence) or 0)) + 1
    local opcode = tonumber(metadata and metadata.opcode)
    local logical = {
        id = ("logical:%d"):format(self.LogicalMessageSequence),
        opcode = opcode,
        operationKey = getOperationKey(opcode),
        scope = metadata and metadata.scope or nil,
        distribution = distribution,
        target = target ~= nil and tostring(target) or nil,
        priority = metadata and metadata.priority or nil,
        replaceKey = metadata and metadata.replaceKey or nil,
        serializedArgumentBytes = #(payloadText or ""),
        physicalPacketCount = math.max(0, math.floor(tonumber(packetCount) or 0)),
        physicalPacketBytes = math.max(0, math.floor(tonumber(packetBytes) or 0)),
        enqueuedPacketCount = 0,
        sentPacketCount = 0,
        failedPacketCount = 0,
        skippedPacketCount = 0,
        attemptCount = 0,
        startedAtMs = getNowMilliseconds(),
        enqueuedAt = nil,
        enqueuedAtMs = nil,
        firstAttemptAt = nil,
        firstAttemptAtMs = nil,
        deliveredAt = nil,
        deliveredAtMs = nil,
        failedAt = nil,
        failedAtMs = nil,
        queueWaitMs = nil,
        totalDeliveryMs = nil,
        status = "created",
        eventSessionId = trim(eventSessionId),
        terminal = false,
    }
    self.ActiveLogicalMessages[logical.id] = logical
    local transport = self:GetTransportDiagnosticsStore()
    transport.logicalSendCount = (transport.logicalSendCount or 0) + 1
    transport.lastLogicalStarted = deepCopy(logical)
    registerStartupLogical(logical)
    return logical.id
end

function Diagnostics:FailLogicalSend(logicalId, reason)
    return finalizeLogicalFailure(getLogical(logicalId), reason or "send-rejected", getNowMilliseconds())
end

function Diagnostics:SupersedeLogicalSend(logicalId, reason)
    return finalizeLogicalSuperseded(getLogical(logicalId), reason or "superseded", getNowMilliseconds())
end

function Diagnostics:GetLogicalSendDiagnostics()
    return {
        active = deepCopy(self.ActiveLogicalMessages),
        recent = deepCopy(self.RecentLogicalMessages),
    }
end

function Diagnostics:GetEventStartupDiagnostics(eventSessionId)
    local sessionId = trim(eventSessionId)
    if sessionId == "" then
        sessionId = self.LastStartupSessionId
    end
    local session = self.StartupBySession[sessionId]
    return type(session) == "table" and deepCopy(session) or nil
end

function Diagnostics:ResetEventStartupDiagnostics()
    self.StartupBySession = {}
    self.StartupSessionOrder = {}
    self.LastStartupSessionId = ""
    return true
end

local baseResetDiagnostics = Diagnostics.ResetDiagnostics
if type(baseResetDiagnostics) == "function" then
    function Diagnostics:ResetDiagnostics(...)
        local result = baseResetDiagnostics(self, ...)
        self.ActiveLogicalMessages = {}
        self.RecentLogicalMessages = {}
        self.LogicalMessageSequence = 0
        self:ResetEventStartupDiagnostics()
        return result
    end
end

local baseResetQueueDiagnostics = Diagnostics.ResetQueueDiagnostics
if type(baseResetQueueDiagnostics) == "function" then
    function Diagnostics:ResetQueueDiagnostics(...)
        local diagnostics = baseResetQueueDiagnostics(self, ...)
        diagnostics.currentQueueLength = #(type(Queue.Items) == "table" and Queue.Items or {})
        diagnostics.highWaterQueueLength = diagnostics.currentQueueLength
        diagnostics.skippedCount = 0
        diagnostics.enqueuedPacketCount = 0
        diagnostics.sentPacketCount = 0
        diagnostics.failedPacketCount = 0
        diagnostics.skippedPacketCount = 0
        diagnostics.addonMessageThrottleCount = 0
        diagnostics.channelThrottleCount = 0
        diagnostics.throttleEvents = {}
        return diagnostics
    end
end

local baseRecordQueueEnqueued = Diagnostics.RecordQueueEnqueued
if type(baseRecordQueueEnqueued) == "function" then
    function Diagnostics:RecordQueueEnqueued(item, ...)
        local results = pack(baseRecordQueueEnqueued(self, item, ...))
        local queueDiagnostics = self:GetQueueDiagnosticsStore()
        queueDiagnostics.enqueuedPacketCount = queueDiagnostics.enqueuedCount or 0
        updateQueueDepth(queueDiagnostics)
        local logical = getLogical(item and item._rpeLogicalDiagnosticId)
        if type(logical) == "table" then
            local nowMs = getNowMilliseconds()
            if logical.enqueuedAtMs == nil then
                logical.enqueuedAt = nowMs
                logical.enqueuedAtMs = nowMs
                logical.status = "queued"
                local transport = self:GetTransportDiagnosticsStore()
                transport.logicalEnqueuedCount = (transport.logicalEnqueuedCount or 0) + 1
            end
            local packetBytes = #(tostring(item and item.payload or ""))
            logical.enqueuedPacketCount = (logical.enqueuedPacketCount or 0) + 1
            logical.enqueuedPacketBytes = (logical.enqueuedPacketBytes or 0) + packetBytes
        end
        return unpackValues(results, 1, results.n)
    end
end

local baseRecordQueueSent = Diagnostics.RecordQueueSent
if type(baseRecordQueueSent) == "function" then
    function Diagnostics:RecordQueueSent(item, result, ...)
        local logical = markLogicalAttempt(item, getNowMilliseconds())
        local results = pack(baseRecordQueueSent(self, item, result, ...))
        local queueDiagnostics = self:GetQueueDiagnosticsStore()
        queueDiagnostics.sentPacketCount = queueDiagnostics.sentCount or 0
        updateQueueDepth(queueDiagnostics)
        if type(logical) == "table" and logical.terminal ~= true then
            logical.sentPacketCount = (logical.sentPacketCount or 0) + 1
            if logical.sentPacketCount >= logical.physicalPacketCount
                and logical.enqueuedPacketCount >= math.max(1, tonumber(item and item.chunkPartCount) or 1)
            then
                finalizeLogicalSuccess(logical, getNowMilliseconds())
            end
        end
        return unpackValues(results, 1, results.n)
    end
end

local baseRecordQueueThrottle = Diagnostics.RecordQueueThrottle
if type(baseRecordQueueThrottle) == "function" then
    function Diagnostics:RecordQueueThrottle(item, result, ...)
        local nowMs = getNowMilliseconds()
        local logical = markLogicalAttempt(item, nowMs)
        local results = pack(baseRecordQueueThrottle(self, item, result, ...))
        local diagnostics = self:GetQueueDiagnosticsStore()
        local code = tonumber(result)
        if code == 3 then
            diagnostics.addonMessageThrottleCount = (diagnostics.addonMessageThrottleCount or 0) + 1
        elseif code == 8 then
            diagnostics.channelThrottleCount = (diagnostics.channelThrottleCount or 0) + 1
        end
        diagnostics.throttleEvents = type(diagnostics.throttleEvents) == "table" and diagnostics.throttleEvents or {}
        local event = {
            time = nowMs,
            atMs = nowMs,
            result = result,
            resultCode = tonumber(result) or result,
            kind = code == 3 and "AddonMessageThrottle" or (code == 8 and "ChannelThrottle" or "Throttle"),
            distribution = item and item.distribution or nil,
            target = item and item.target or nil,
            opcode = item and item._rpeDiagnosticOpcode or nil,
            operationKey = item and item._rpeDiagnosticOperationKey or nil,
            attempt = item and item.attempts or nil,
            logicalMessageId = logical and logical.id or nil,
        }
        appendBounded(diagnostics.throttleEvents, event, MAX_THROTTLE_EVENTS)
        if code == 3 then
            diagnostics.lastAddonMessageThrottle = deepCopy(event)
        elseif code == 8 then
            diagnostics.lastChannelThrottle = deepCopy(event)
        end
        updateQueueDepth(diagnostics)
        return unpackValues(results, 1, results.n)
    end
end

local baseRecordQueueFailure = Diagnostics.RecordQueueFailure
if type(baseRecordQueueFailure) == "function" then
    function Diagnostics:RecordQueueFailure(item, result, ...)
        local logical = getLogical(item and item._rpeLogicalDiagnosticId)
        if type(item) == "table" and (tonumber(item.attempts) or 0) > 0 then
            logical = markLogicalAttempt(item, getNowMilliseconds()) or logical
        end
        local results = pack(baseRecordQueueFailure(self, item, result, ...))
        local queueDiagnostics = self:GetQueueDiagnosticsStore()
        queueDiagnostics.failedPacketCount = queueDiagnostics.failedCount or 0
        updateQueueDepth(queueDiagnostics)
        if type(logical) == "table" and logical.terminal ~= true then
            logical.failedPacketCount = (logical.failedPacketCount or 0) + 1
            finalizeLogicalFailure(logical, result or "send-failed", getNowMilliseconds())
        end
        return unpackValues(results, 1, results.n)
    end
end

function Diagnostics:RecordQueueSkipped(item, reason)
    local diagnostics = self:GetQueueDiagnosticsStore()
    diagnostics.skippedCount = (diagnostics.skippedCount or 0) + 1
    diagnostics.skippedPacketCount = diagnostics.skippedCount
    diagnostics.lastSkipped = {
        atMs = getNowMilliseconds(),
        prefix = item and item.prefix or nil,
        distribution = item and item.distribution or nil,
        target = item and item.target or nil,
        opcode = item and item._rpeDiagnosticOpcode or nil,
        operationKey = item and item._rpeDiagnosticOperationKey or nil,
        reason = reason or "skipped",
    }
    diagnostics.currentQueueLength = math.max(0, #(type(Queue.Items) == "table" and Queue.Items or {}) - 1)
    diagnostics.highWaterQueueLength = math.max(
        math.floor(tonumber(diagnostics.highWaterQueueLength) or 0),
        diagnostics.currentQueueLength
    )
    local logical = getLogical(item and item._rpeLogicalDiagnosticId)
    if type(logical) == "table" then
        logical.skippedPacketCount = (logical.skippedPacketCount or 0) + 1
    end
end

local baseGetDiagnostics = Diagnostics.GetDiagnostics
if type(baseGetDiagnostics) == "function" then
    function Diagnostics:GetDiagnostics(...)
        local diagnostics = baseGetDiagnostics(self, ...)
        diagnostics.logicalMessages = self:GetLogicalSendDiagnostics()
        diagnostics.eventStartup = self:GetEventStartupDiagnostics()
        return diagnostics
    end
end

local baseEnqueue = Queue.Enqueue
if type(baseEnqueue) == "function" then
    function Queue:Enqueue(item, ...)
        local context = activeEnqueueContext
        if type(context) == "table" and type(item) == "table" then
            item._rpeLogicalDiagnosticId = context.logicalMessageId
            item._rpeDiagnosticOpcode = context.opcode
            item._rpeDiagnosticOperationKey = context.operationKey
            if type(item.shouldSkip) == "function" and item._rpeDiagnosticSkipWrapped ~= true then
                local baseShouldSkip = item.shouldSkip
                item.shouldSkip = function(...)
                    local skipped = baseShouldSkip(...)
                    if skipped and item._rpeDiagnosticSkipRecorded ~= true then
                        item._rpeDiagnosticSkipRecorded = true
                        Diagnostics:RecordQueueSkipped(item, "logical-message-cancelled")
                    end
                    return skipped
                end
                item._rpeDiagnosticSkipWrapped = true
            end
        end
        return baseEnqueue(self, item, ...)
    end
end

local function deriveEventSessionId(operationKey, argumentsText, metadata)
    local explicit = trim(metadata and metadata.eventSessionId)
    if explicit ~= "" then
        return explicit
    end
    if not STARTUP_KEYS[operationKey] or type(Serialization.DeserializeArguments) ~= "function" then
        return ""
    end
    local ok, values = pcall(Serialization.DeserializeArguments, Serialization, argumentsText or "")
    if ok and type(values) == "table" then
        return trim(values[2])
    end
    return ""
end

local function buildPhysicalPlan(comms, argumentsText, opcode)
    if type(comms.ResolveChunkPlan) ~= "function"
        or type(Serialization.BuildChunkToken) ~= "function"
        or type(Serialization.SerializePacket) ~= "function"
    then
        return 0, 0
    end
    local chunkLength, partCount = comms:ResolveChunkPlan(argumentsText or "", opcode)
    if not chunkLength or not partCount then
        return 0, 0
    end
    local totalBytes = 0
    for partIndex = 1, partCount do
        local rangeStart = ((partIndex - 1) * chunkLength) + 1
        local rangeEnd = partIndex * chunkLength
        local chunk = string.sub(argumentsText or "", rangeStart, rangeEnd)
        local token = Serialization:BuildChunkToken(partIndex, partCount)
        local packet = Serialization:SerializePacket(comms.Prefix, token, opcode, chunk)
        totalBytes = totalBytes + #packet
    end
    return partCount, totalBytes
end

local baseSendMessage = Comms.SendMessage
if type(baseSendMessage) == "function" then
    function Comms:SendMessage(distribution, opcodeOrPayload, argumentsOrTarget, targetOrMetadata, metadata)
        local opcode, argumentsText, target, diagnosticsMetadata = self:BuildOutboundMessage(
            opcodeOrPayload,
            argumentsOrTarget,
            targetOrMetadata,
            metadata
        )
        if not opcode then
            return baseSendMessage(self, distribution, opcodeOrPayload, argumentsOrTarget, targetOrMetadata, metadata)
        end

        local operationKey = getOperationKey(opcode)
        local eventSessionId = deriveEventSessionId(operationKey, argumentsText, diagnosticsMetadata)
        local physicalPacketCount, physicalPacketBytes = buildPhysicalPlan(self, argumentsText, opcode)
        local logicalMessageId = Diagnostics:BeginLogicalSend(
            diagnosticsMetadata,
            distribution,
            target,
            argumentsText,
            eventSessionId,
            physicalPacketCount,
            physicalPacketBytes
        )
        local previousContext = activeEnqueueContext
        activeEnqueueContext = {
            logicalMessageId = logicalMessageId,
            opcode = opcode,
            operationKey = operationKey,
        }

        local results = pack(pcall(
            baseSendMessage,
            self,
            distribution,
            opcodeOrPayload,
            argumentsOrTarget,
            targetOrMetadata,
            metadata
        ))
        activeEnqueueContext = previousContext

        if results[1] ~= true then
            Diagnostics:FailLogicalSend(logicalMessageId, "send-error")
            error(results[2], 0)
        end

        local sendResult = results[2]
        if sendResult ~= true then
            local transport = Diagnostics:GetTransportDiagnosticsStore()
            Diagnostics:FailLogicalSend(logicalMessageId, transport.lastSendFailureCode or "send-rejected")
        end
        return unpackValues(results, 2, results.n)
    end
end

Diagnostics._baselineTransportDiagnosticsInstalled = true
