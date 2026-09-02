local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Utils = Addon.Utils or {}
Addon.Debug = Addon.Debug or {}

-- Forward Declarations
local Debug = Addon.Debug or {}
local Common = Addon.Utils.Common or {}
local Comms = Addon.Internal.Comms
local Diagnostics = Addon.Internal.Comms.Diagnostics or {}
local Queue = Addon.Internal.Comms.MessageQueue or {}
Addon.Internal.Comms.MessageQueue = Queue

-- Runtime State
Queue.DefaultSendDelay = Queue.DefaultSendDelay or 0.2
Queue.SendDelay = Queue.SendDelay or Queue.DefaultSendDelay
Queue.DefaultMaxSendDelay = Queue.DefaultMaxSendDelay or 2
Queue.MaxSendDelay = Queue.MaxSendDelay or Queue.DefaultMaxSendDelay
Queue.DefaultMaxAttempts = Queue.DefaultMaxAttempts or 0
Queue.MaxAttempts = Queue.MaxAttempts or Queue.DefaultMaxAttempts
-- Retained for compatibility: this limit continues to bound pending physical chunks,
-- not just the number of logical queue records.
Queue.DefaultMaxQueueLength = Queue.DefaultMaxQueueLength or 256
Queue.MaxQueueLength = Queue.MaxQueueLength or Queue.DefaultMaxQueueLength
Queue.Items = Queue.Items or {}
Queue.IsSending = Queue.IsSending or false
Queue.NextSendAt = Queue.NextSendAt or 0
Queue.PendingChunkHighWater = math.max(0, math.floor(tonumber(Queue.PendingChunkHighWater) or 0))
Queue.LogicalMessageHighWater = math.max(0, math.floor(tonumber(Queue.LogicalMessageHighWater) or 0))
Queue.EnqueueSequence = math.max(0, math.floor(tonumber(Queue.EnqueueSequence) or 0))
Queue.Priority = Queue.Priority or {}
Queue.Priority.CRITICAL = "CRITICAL"
Queue.Priority.NORMAL = "NORMAL"
Queue.Priority.BACKGROUND = "BACKGROUND"
-- One waiting logical message gains one priority level after this many other
-- logical messages are selected. A BACKGROUND message therefore reaches
-- CRITICAL after at most 8 bypasses and then wins FIFO ties against newer work.
Queue.PriorityAgingDispatchesPerLevel = math.max(
    1,
    math.floor(tonumber(Queue.PriorityAgingDispatchesPerLevel) or 4)
)

local PRIORITY_ORDER = {
    Queue.Priority.BACKGROUND,
    Queue.Priority.NORMAL,
    Queue.Priority.CRITICAL,
}
local PRIORITY_RANK = {}
for index = 1, #PRIORITY_ORDER do
    PRIORITY_RANK[PRIORITY_ORDER[index]] = index
end

-- Helpers
local invokeCallback = Common.InvokeCallback

local function getItemOpcode(item)
    local explicitOpcode = tonumber(item and item.opcode)
    if explicitOpcode then
        return explicitOpcode
    end

    local serialization = Addon.Internal
        and Addon.Internal.Comms
        and Addon.Internal.Comms.Serialization

    local packet = serialization
        and serialization.DeserializePacket
        and serialization:DeserializePacket(item and item.payload)

    if packet and packet.opcode then
        return packet.opcode
    end

    return nil
end

local function describeSendResult(result)
    local codes = {
        [1] = "InvalidPrefix",
        [2] = "InvalidMessage",
        [3] = "AddonThrottle",
        [4] = "InvalidChatType",
        [5] = "NotInGroup",
        [6] = "TargetRequired",
        [7] = "InvalidChannel",
        [8] = "ChannelThrottle",
        [9] = "GeneralError",
    }

    return codes[tonumber(result)] or "Unknown"
end

local function getCurrentTime()
    if type(GetTimePreciseSec) == "function" then
        return GetTimePreciseSec()
    end

    if type(GetTime) == "function" then
        return GetTime()
    end

    if type(Common.GetNow) == "function" then
        return Common.GetNow()
    end

    return 0
end

local function getMinimumSendDelay(self)
    local configuredDelay = tonumber(self.SendDelay) or tonumber(self.DefaultSendDelay) or 0.2
    return math.max(0.2, configuredDelay)
end

local function scheduleNextProcess(self, delay)
    local function retry()
        self.IsSending = false
        self:ProcessNext()
    end

    if C_Timer and C_Timer.After and delay and delay > 0 then
        C_Timer.After(delay, retry)
        return true
    end

    retry()
    return false
end

local function getChunkCount(item)
    return type(item) == "table" and type(item.chunks) == "table" and #item.chunks or 0
end

local function getNextChunkIndex(item)
    local chunkCount = getChunkCount(item)
    if chunkCount <= 0 then
        return 1
    end
    return math.max(1, math.min(chunkCount + 1, math.floor(tonumber(item.nextChunkIndex) or 1)))
end

local function getRemainingChunkCount(item)
    local chunkCount = getChunkCount(item)
    if chunkCount <= 0 then
        return 0
    end
    local nextChunkIndex = getNextChunkIndex(item)
    if nextChunkIndex > chunkCount then
        return 0
    end
    return chunkCount - nextChunkIndex + 1
end

local function setCurrentChunkFields(item, chunkIndex)
    local chunkCount = getChunkCount(item)
    local normalizedIndex = math.max(1, math.min(chunkCount, math.floor(tonumber(chunkIndex) or 1)))
    item.chunkPartIndex = normalizedIndex
    item.chunkPartCount = chunkCount
    item.payload = item.chunks and item.chunks[normalizedIndex] or nil
    return item.payload, normalizedIndex, chunkCount
end

local function updateQueueMetrics(self)
    local logicalCount = #(type(self.Items) == "table" and self.Items or {})
    local pendingChunks = self:GetPendingChunkCount()
    self.LogicalMessageHighWater = math.max(tonumber(self.LogicalMessageHighWater) or 0, logicalCount)
    self.PendingChunkHighWater = math.max(tonumber(self.PendingChunkHighWater) or 0, pendingChunks)

    local diagnostics = Diagnostics.GetQueueDiagnosticsStore and Diagnostics:GetQueueDiagnosticsStore() or nil
    if type(diagnostics) == "table" then
        diagnostics.currentLogicalMessageCount = logicalCount
        diagnostics.highWaterLogicalMessageCount = math.max(
            math.floor(tonumber(diagnostics.highWaterLogicalMessageCount) or 0),
            logicalCount
        )
        diagnostics.currentPendingChunkCount = pendingChunks
        diagnostics.highWaterPendingChunkCount = math.max(
            math.floor(tonumber(diagnostics.highWaterPendingChunkCount) or 0),
            pendingChunks
        )
    end
    return logicalCount, pendingChunks
end

local function recordSkippedChunks(item, firstIndex)
    if type(Diagnostics.RecordQueueSkipped) ~= "function" then
        return
    end
    local chunkCount = getChunkCount(item)
    for chunkIndex = math.max(1, math.floor(tonumber(firstIndex) or 1)), chunkCount do
        setCurrentChunkFields(item, chunkIndex)
        Diagnostics:RecordQueueSkipped(item, "logical-message-cancelled")
    end
end

local function getPriorityRank(item)
    return PRIORITY_RANK[tostring(item and item.priority or "")] or PRIORITY_RANK[Queue.Priority.NORMAL]
end

local function getEffectivePriorityRank(self, item)
    local baseRank = getPriorityRank(item)
    local bypassCount = math.max(0, math.floor(tonumber(item and item.priorityBypassCount) or 0))
    local agingStep = math.max(1, math.floor(tonumber(self.PriorityAgingDispatchesPerLevel) or 4))
    return math.min(#PRIORITY_ORDER, baseRank + math.floor(bypassCount / agingStep)), baseRank
end

local function removeSkippedItems(self)
    local removed = false
    for itemIndex = #(self.Items or {}), 1, -1 do
        local item = self.Items[itemIndex]
        if item and type(item.shouldSkip) == "function" and item.shouldSkip() then
            local currentIndex = getNextChunkIndex(item)
            local remainingChunkCount = getRemainingChunkCount(item)
            -- #164 wraps shouldSkip and records the current skipped packet. When
            -- that wrapper is absent, record the current packet here as well.
            local firstUnrecordedIndex = item._rpeDiagnosticSkipRecorded == true
                and (currentIndex + 1)
                or currentIndex
            recordSkippedChunks(item, firstUnrecordedIndex)
            table.remove(self.Items, itemIndex)
            if Diagnostics.RecordQueueLogicalSkipped then
                Diagnostics:RecordQueueLogicalSkipped(item, remainingChunkCount)
            end
            removed = true
        end
    end
    if removed then
        updateQueueMetrics(self)
    end
end

local function selectNextMessage(self)
    if #(self.Items or {}) == 0 then
        return nil
    end

    -- A started logical message owns the sender until terminal state so its
    -- chunks remain contiguous even if higher-priority work arrives meanwhile.
    for itemIndex = 1, #self.Items do
        local item = self.Items[itemIndex]
        if item and item.started == true then
            if itemIndex ~= 1 then
                table.remove(self.Items, itemIndex)
                table.insert(self.Items, 1, item)
            end
            return item
        end
    end

    local bestIndex = nil
    local bestEffectiveRank = -1
    local bestSequence = math.huge
    for itemIndex = 1, #self.Items do
        local item = self.Items[itemIndex]
        local effectiveRank = getEffectivePriorityRank(self, item)
        local sequence = math.max(0, math.floor(tonumber(item and item.enqueueSequence) or itemIndex))
        if effectiveRank > bestEffectiveRank
            or (effectiveRank == bestEffectiveRank and sequence < bestSequence)
        then
            bestIndex = itemIndex
            bestEffectiveRank = effectiveRank
            bestSequence = sequence
        end
    end

    if not bestIndex then
        return nil
    end

    local selected = self.Items[bestIndex]
    local _, baseRank = getEffectivePriorityRank(self, selected)
    selected.effectivePriority = PRIORITY_ORDER[bestEffectiveRank]
    selected.priorityPromoted = bestEffectiveRank > baseRank

    -- Age every other eligible logical message once per logical dispatch. This
    -- is independent of frame time and gives deterministic bounded starvation.
    for itemIndex = 1, #self.Items do
        if itemIndex ~= bestIndex then
            local item = self.Items[itemIndex]
            if item and item.started ~= true then
                item.priorityBypassCount = math.max(
                    0,
                    math.floor(tonumber(item.priorityBypassCount) or 0)
                ) + 1
            end
        end
    end

    if bestIndex ~= 1 then
        table.remove(self.Items, bestIndex)
        table.insert(self.Items, 1, selected)
    end
    return selected
end

function Queue:NormalizePriority(value)
    local normalized = tostring(value or ""):upper()
    if PRIORITY_RANK[normalized] then
        return normalized
    end
    return self.Priority.NORMAL
end

function Queue:GetPendingChunkCount()
    local pending = 0
    for index = 1, #(self.Items or {}) do
        pending = pending + getRemainingChunkCount(self.Items[index])
    end
    return pending
end

function Queue:Reset()
    self.Items = {}
    self.IsSending = false
    self.NextSendAt = 0
    self.PendingChunkHighWater = 0
    self.LogicalMessageHighWater = 0
    self.EnqueueSequence = 0
    if Diagnostics.RecordQueueReset then
        Diagnostics:RecordQueueReset()
    end
    updateQueueMetrics(self)
    return self
end

function Queue:Enqueue(item)
    if type(item) ~= "table" then
        error("Addon.Internal.Comms.MessageQueue:Enqueue(item) requires a table.", 2)
    end

    item.priority = self:NormalizePriority(item.priority or (item.metadata and item.metadata.priority))
    item.priorityBypassCount = math.max(0, math.floor(tonumber(item.priorityBypassCount) or 0))

    local requestedChunkCount = getChunkCount(item)
    if requestedChunkCount <= 0 then
        error("Addon.Internal.Comms.MessageQueue:Enqueue(item) requires one or more chunks.", 2)
    end

    if not self:CanAccept(requestedChunkCount) then
        if Diagnostics.RecordQueueFailure then
            setCurrentChunkFields(item, 1)
            Diagnostics:RecordQueueFailure(item, "queue-full")
        end
        if Diagnostics.RecordQueueLogicalFailure then
            Diagnostics:RecordQueueLogicalFailure(item, "queue-full")
        end
        invokeCallback(item.callbacks and item.callbacks.onFailed, item, "queue-full")
        return nil
    end

    self.EnqueueSequence = math.max(0, math.floor(tonumber(self.EnqueueSequence) or 0)) + 1
    item.enqueueSequence = self.EnqueueSequence
    item.enqueuedAt = getCurrentTime()
    item.nextChunkIndex = getNextChunkIndex(item)
    item.attempts = tonumber(item.attempts) or 0
    item.totalAttempts = tonumber(item.totalAttempts) or 0
    item.started = item.started == true
    self.Items[#self.Items + 1] = item

    if Diagnostics.RecordQueueLogicalEnqueued then
        Diagnostics:RecordQueueLogicalEnqueued(item)
    end
    if Diagnostics.RecordQueueEnqueued then
        for chunkIndex = 1, requestedChunkCount do
            setCurrentChunkFields(item, chunkIndex)
            Diagnostics:RecordQueueEnqueued(item)
        end
    end
    setCurrentChunkFields(item, item.nextChunkIndex)
    updateQueueMetrics(self)

    self:ProcessNext()
    return item
end

function Queue:CanAccept(count)
    local requestedCount = math.max(0, math.floor(tonumber(count) or 0))
    local maxQueueLength = tonumber(self.MaxQueueLength) or tonumber(self.DefaultMaxQueueLength) or 0
    if maxQueueLength <= 0 then
        return true
    end

    return (self:GetPendingChunkCount() + requestedCount) <= maxQueueLength
end

function Queue:EnqueueLogicalMessage(prefix, opcode, chunks, distribution, target, callbacks, metadata)
    return self:Enqueue({
        prefix = prefix,
        opcode = tonumber(opcode),
        distribution = distribution,
        target = target,
        chunks = chunks,
        nextChunkIndex = 1,
        shouldSkip = callbacks and callbacks.shouldSkip or nil,
        callbacks = callbacks,
        metadata = metadata,
        priority = metadata and metadata.priority or nil,
    })
end

function Queue:HandleSuccess(item, result)
    local chunk, chunkPartIndex, chunkPartCount = setCurrentChunkFields(item, item.nextChunkIndex)
    if Diagnostics.RecordQueueSent then
        Diagnostics:RecordQueueSent(item, result)
    end

    local chunkSuffix = ""
    if chunkPartCount > 1 then
        chunkSuffix = (" part=%d/%d"):format(chunkPartIndex, chunkPartCount)
    end

    if Addon.Debug and Addon.Debug.CommsTracing == true and Addon.Debug.Internal then
        Debug.Internal(
            "Message sent successfully: opcode=%s distribution=%s target=%s%s",
            tostring(getItemOpcode(item) or "unknown"),
            tostring(item.distribution or "unknown"),
            tostring(item.target or "unknown"),
            chunkSuffix
        )
    end

    invokeCallback(item.callbacks and item.callbacks.onChunkSent, item, chunk, result, chunkPartIndex, chunkPartCount)

    item.nextChunkIndex = chunkPartIndex + 1
    item.attempts = 0
    local delivered = item.nextChunkIndex > chunkPartCount
    if delivered then
        table.remove(self.Items, 1)
        if Diagnostics.RecordQueueLogicalDelivered then
            Diagnostics:RecordQueueLogicalDelivered(item, result)
        end
        invokeCallback(item.callbacks and item.callbacks.onDelivered, item, result)
    else
        setCurrentChunkFields(item, item.nextChunkIndex)
    end

    self.IsSending = false
    updateQueueMetrics(self)
    self:ProcessNext()
    return delivered
end

function Queue:HandleThrottle(item, result)
    local maxAttempts = tonumber(self.MaxAttempts) or tonumber(self.DefaultMaxAttempts) or 0
    if maxAttempts > 0 and (item.attempts or 0) >= maxAttempts then
        self:HandleFailure(item, "max-attempts")
        return
    end

    self.IsSending = true
    if Diagnostics.RecordQueueThrottle then
        Diagnostics:RecordQueueThrottle(item, result)
    end

    if C_Timer and C_Timer.After then
        local baseDelay = tonumber(self.SendDelay) or tonumber(self.DefaultSendDelay) or 0.2
        local maxDelay = tonumber(self.MaxSendDelay) or tonumber(self.DefaultMaxSendDelay) or baseDelay
        local delay = math.min(baseDelay * (2 ^ math.max(0, (item.attempts or 1) - 1)), maxDelay)
        scheduleNextProcess(self, delay)
        return
    end

    scheduleNextProcess(self, 0)
end

function Queue:HandleFailure(item, result)
    local failedIndex = getNextChunkIndex(item)
    recordSkippedChunks(item, failedIndex + 1)
    setCurrentChunkFields(item, failedIndex)
    table.remove(self.Items, 1)
    self.IsSending = false
    if Diagnostics.RecordQueueFailure then
        Diagnostics:RecordQueueFailure(item, result)
    end
    if Diagnostics.RecordQueueLogicalFailure then
        Diagnostics:RecordQueueLogicalFailure(item, result)
    end

    Debug.Internal(
        "Message send failed: opcode=%s distribution=%s target=%s result=%s (%s)",
        tostring(getItemOpcode(item) or "unknown"),
        tostring(item.distribution or "unknown"),
        tostring(item.target or "unknown"),
        tostring(result or "unknown"),
        describeSendResult(result)
    )

    invokeCallback(item.callbacks and item.callbacks.onFailed, item, result)
    updateQueueMetrics(self)
    self:ProcessNext()
end

function Queue:ProcessNext()
    if self.IsSending then
        return false
    end

    local now = getCurrentTime()
    local nextSendAt = tonumber(self.NextSendAt) or 0
    if nextSendAt > now then
        self.IsSending = true
        scheduleNextProcess(self, nextSendAt - now)
        return false
    end

    removeSkippedItems(self)
    if #self.Items == 0 then
        return false
    end

    local item = selectNextMessage(self)
    if not item then
        return false
    end

    if item.started ~= true then
        item.started = true
        item.startedAt = now
        item.queueWaitSeconds = math.max(0, now - (tonumber(item.enqueuedAt) or now))
        if Diagnostics.RecordQueueLogicalSelected then
            Diagnostics:RecordQueueLogicalSelected(
                item,
                item.queueWaitSeconds,
                item.effectivePriority or item.priority,
                item.priorityPromoted == true
            )
        end
    end

    local payload = setCurrentChunkFields(item, item.nextChunkIndex)
    if type(payload) ~= "string" then
        self:HandleFailure(item, "missing-chunk")
        return false
    end

    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
        self:HandleFailure(item, "missing-api")
        return false
    end

    self.IsSending = true
    item.attempts = (item.attempts or 0) + 1
    item.totalAttempts = (item.totalAttempts or 0) + 1
    self.NextSendAt = now + getMinimumSendDelay(self)

    local result = C_ChatInfo.SendAddonMessage(item.prefix, payload, item.distribution, item.target)
    if result == 3 or result == 8 then
        self:HandleThrottle(item, result)
        return false
    end

    if result == nil or result == true or result == 0 then
        self:HandleSuccess(item, result)
        return true
    end

    self:HandleFailure(item, result)
    return false
end

function Queue:GetStats()
    local stats = Diagnostics.GetMessageQueueDiagnostics and Diagnostics:GetMessageQueueDiagnostics() or {}
    stats.queueLength = #self.Items
    stats.logicalMessageCount = #self.Items
    stats.pendingChunkCount = self:GetPendingChunkCount()
    stats.highWaterLogicalMessageCount = math.max(
        math.floor(tonumber(stats.highWaterLogicalMessageCount) or 0),
        math.floor(tonumber(self.LogicalMessageHighWater) or 0)
    )
    stats.highWaterPendingChunkCount = math.max(
        math.floor(tonumber(stats.highWaterPendingChunkCount) or 0),
        math.floor(tonumber(self.PendingChunkHighWater) or 0)
    )
    stats.maxPendingChunkCount = tonumber(self.MaxQueueLength) or tonumber(self.DefaultMaxQueueLength) or 0
    stats.priorityAgingDispatchesPerLevel = self.PriorityAgingDispatchesPerLevel
    stats.sendDelay = self.SendDelay
    stats.isSending = self.IsSending and true or false
    return stats
end
