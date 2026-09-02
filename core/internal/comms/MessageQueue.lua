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
-- These values are scheduler estimates only. The WoW server may reconfigure
-- real throttle limits at runtime; result codes from SendAddonMessage always
-- override the local model.
Queue.DefaultPrefixBurstCapacity = Queue.DefaultPrefixBurstCapacity or 10
Queue.PrefixBurstCapacity = Queue.PrefixBurstCapacity or Queue.DefaultPrefixBurstCapacity
Queue.DefaultPrefixRefillRate = Queue.DefaultPrefixRefillRate or 1
Queue.PrefixRefillRate = Queue.PrefixRefillRate or Queue.DefaultPrefixRefillRate
Queue.DefaultMaxImmediateBurstPackets = Queue.DefaultMaxImmediateBurstPackets or 10
Queue.MaxImmediateBurstPackets = Queue.MaxImmediateBurstPackets or Queue.DefaultMaxImmediateBurstPackets
Queue.DefaultChannelBackoffSeconds = Queue.DefaultChannelBackoffSeconds or 1
Queue.ChannelBackoffSeconds = Queue.ChannelBackoffSeconds or Queue.DefaultChannelBackoffSeconds
Queue.DefaultMaxChannelBackoffSeconds = Queue.DefaultMaxChannelBackoffSeconds or 8
Queue.MaxChannelBackoffSeconds = Queue.MaxChannelBackoffSeconds or Queue.DefaultMaxChannelBackoffSeconds
Queue.DefaultMaxAttempts = Queue.DefaultMaxAttempts or 0
Queue.MaxAttempts = Queue.MaxAttempts or Queue.DefaultMaxAttempts
-- Retained for compatibility: this limit continues to bound pending physical chunks,
-- not just the number of logical queue records.
Queue.DefaultMaxQueueLength = Queue.DefaultMaxQueueLength or 256
Queue.MaxQueueLength = Queue.MaxQueueLength or Queue.DefaultMaxQueueLength
Queue.Items = Queue.Items or {}
Queue.IsSending = Queue.IsSending or false
Queue.PendingChunkHighWater = math.max(0, math.floor(tonumber(Queue.PendingChunkHighWater) or 0))
Queue.LogicalMessageHighWater = math.max(0, math.floor(tonumber(Queue.LogicalMessageHighWater) or 0))
Queue.EnqueueSequence = math.max(0, math.floor(tonumber(Queue.EnqueueSequence) or 0))
Queue.PrefixBurstCapacityEstimate = tonumber(Queue.PrefixBurstCapacityEstimate)
Queue.PrefixAllowance = tonumber(Queue.PrefixAllowance)
Queue.PrefixAllowanceUpdatedAt = tonumber(Queue.PrefixAllowanceUpdatedAt)
Queue.PrefixBlockedUntil = math.max(0, tonumber(Queue.PrefixBlockedUntil) or 0)
Queue.PrefixRecoveryPending = Queue.PrefixRecoveryPending == true
Queue.ChannelThrottleState = type(Queue.ChannelThrottleState) == "table" and Queue.ChannelThrottleState or {}
Queue.ScheduledWakeAt = math.max(0, tonumber(Queue.ScheduledWakeAt) or 0)
Queue.ScheduledWakeHandle = nil
Queue.ScheduledWakeGeneration = math.max(0, math.floor(tonumber(Queue.ScheduledWakeGeneration) or 0))
Queue.CurrentImmediateBurstCount = math.max(0, math.floor(tonumber(Queue.CurrentImmediateBurstCount) or 0))
Queue.ImmediateYieldPending = Queue.ImmediateYieldPending == true
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

local function getConfiguredBurstCapacity(self)
    return math.max(
        1,
        math.floor(tonumber(self.PrefixBurstCapacity) or tonumber(self.DefaultPrefixBurstCapacity) or 10)
    )
end

local function getConfiguredRefillRate(self)
    return math.max(0.001, tonumber(self.PrefixRefillRate) or tonumber(self.DefaultPrefixRefillRate) or 1)
end

local function getConfiguredImmediateBurstLimit(self)
    return math.max(
        1,
        math.floor(tonumber(self.MaxImmediateBurstPackets) or tonumber(self.DefaultMaxImmediateBurstPackets) or 10)
    )
end

local function getConfiguredChannelBackoff(self)
    return math.max(0.05, tonumber(self.ChannelBackoffSeconds) or tonumber(self.DefaultChannelBackoffSeconds) or 1)
end

local function getConfiguredMaxChannelBackoff(self)
    local base = getConfiguredChannelBackoff(self)
    return math.max(base, tonumber(self.MaxChannelBackoffSeconds) or tonumber(self.DefaultMaxChannelBackoffSeconds) or 8)
end

local function ensureSchedulerState(self, now)
    local currentTime = tonumber(now) or getCurrentTime()
    local configuredCapacity = getConfiguredBurstCapacity(self)
    local estimate = tonumber(self.PrefixBurstCapacityEstimate)
    if estimate == nil then
        estimate = configuredCapacity
    end
    estimate = math.max(1, math.min(configuredCapacity, math.floor(estimate)))
    self.PrefixBurstCapacityEstimate = estimate

    if self.PrefixAllowance == nil then
        self.PrefixAllowance = estimate
    else
        self.PrefixAllowance = math.max(0, math.min(estimate, tonumber(self.PrefixAllowance) or 0))
    end
    if self.PrefixAllowanceUpdatedAt == nil then
        self.PrefixAllowanceUpdatedAt = currentTime
    end
    self.PrefixBlockedUntil = math.max(0, tonumber(self.PrefixBlockedUntil) or 0)
    self.ChannelThrottleState = type(self.ChannelThrottleState) == "table" and self.ChannelThrottleState or {}
    return currentTime
end

local function refreshPrefixAllowance(self, now)
    local currentTime = ensureSchedulerState(self, now)
    local previous = tonumber(self.PrefixAllowanceUpdatedAt) or currentTime
    local elapsed = math.max(0, currentTime - previous)
    if elapsed > 0 then
        self.PrefixAllowance = math.min(
            self.PrefixBurstCapacityEstimate,
            (tonumber(self.PrefixAllowance) or 0) + (elapsed * getConfiguredRefillRate(self))
        )
    end
    self.PrefixAllowanceUpdatedAt = currentTime
    if self.PrefixBlockedUntil > 0 and self.PrefixBlockedUntil <= currentTime then
        self.PrefixBlockedUntil = 0
    end
    return self.PrefixAllowance
end

local function getNextEstimatedRefillAt(self, now)
    local currentTime = tonumber(now) or getCurrentTime()
    refreshPrefixAllowance(self, currentTime)
    if self.PrefixBlockedUntil > currentTime then
        return self.PrefixBlockedUntil
    end
    if (tonumber(self.PrefixAllowance) or 0) >= 1 then
        return nil
    end
    local missing = 1 - math.max(0, tonumber(self.PrefixAllowance) or 0)
    return currentTime + (missing / getConfiguredRefillRate(self))
end

local function isOutsideInstanceWhisper(item)
    if tostring(item and item.distribution or ""):upper() ~= "WHISPER" or type(IsInInstance) ~= "function" then
        return false
    end
    local ok, inInstance = pcall(IsInInstance)
    return ok and inInstance == false
end

local function usesPrefixAllowance(item)
    return not isOutsideInstanceWhisper(item)
end

local function buildRouteKey(item)
    return tostring(item and item.distribution or "") .. "\31" .. tostring(item and item.target or "")
end

local function getRouteThrottleState(self, item, create)
    self.ChannelThrottleState = type(self.ChannelThrottleState) == "table" and self.ChannelThrottleState or {}
    local key = buildRouteKey(item)
    local state = self.ChannelThrottleState[key]
    if type(state) ~= "table" and create == true then
        state = {
            distribution = item and item.distribution or nil,
            target = item and item.target or nil,
            blockedUntil = 0,
            consecutiveThrottleCount = 0,
            recoveryPending = false,
        }
        self.ChannelThrottleState[key] = state
    end
    return state, key
end

local function recordSchedulerState(self, waitReason, waitUntil, item, now)
    local diagnostics = Diagnostics.GetQueueDiagnosticsStore and Diagnostics:GetQueueDiagnosticsStore() or nil
    if type(diagnostics) ~= "table" then
        return
    end
    local currentTime = tonumber(now) or getCurrentTime()
    diagnostics.estimatedAllowance = tonumber(self.PrefixAllowance) or 0
    diagnostics.estimatedBurstCapacity = tonumber(self.PrefixBurstCapacityEstimate) or getConfiguredBurstCapacity(self)
    diagnostics.estimatedRefillRate = getConfiguredRefillRate(self)
    diagnostics.nextEstimatedRefillAt = getNextEstimatedRefillAt(self, currentTime)
    diagnostics.prefixBlockedUntil = math.max(0, tonumber(self.PrefixBlockedUntil) or 0)
    diagnostics.scheduledWakeAt = math.max(0, tonumber(self.ScheduledWakeAt) or 0)
    diagnostics.waitReason = waitReason or "none"
    diagnostics.waitUntil = tonumber(waitUntil)
    diagnostics.currentImmediateBurstCount = math.max(0, math.floor(tonumber(self.CurrentImmediateBurstCount) or 0))
    if item then
        diagnostics.waitDistribution = item.distribution
        diagnostics.waitTarget = item.target
    elseif (waitReason or "none") == "none" then
        diagnostics.waitDistribution = nil
        diagnostics.waitTarget = nil
    end
end

local function recordRecoveryAttempt(self, item, reason, now)
    local diagnostics = Diagnostics.GetQueueDiagnosticsStore and Diagnostics:GetQueueDiagnosticsStore() or nil
    if type(diagnostics) ~= "table" then
        return
    end
    diagnostics.recoveryAttemptCount = (diagnostics.recoveryAttemptCount or 0) + 1
    diagnostics.lastRecoveryAttempt = {
        at = tonumber(now) or getCurrentTime(),
        reason = reason,
        distribution = item and item.distribution or nil,
        target = item and item.target or nil,
        opcode = getItemOpcode(item),
    }
end

local function recordSuccessfulBurstSend(self, item, now)
    self.CurrentImmediateBurstCount = math.max(0, math.floor(tonumber(self.CurrentImmediateBurstCount) or 0)) + 1
    local diagnostics = Diagnostics.GetQueueDiagnosticsStore and Diagnostics:GetQueueDiagnosticsStore() or nil
    if type(diagnostics) == "table" then
        diagnostics.actualBurstSendCount = (diagnostics.actualBurstSendCount or 0) + 1
        diagnostics.currentImmediateBurstCount = self.CurrentImmediateBurstCount
        diagnostics.maxImmediateBurstCount = math.max(
            math.floor(tonumber(diagnostics.maxImmediateBurstCount) or 0),
            self.CurrentImmediateBurstCount
        )
        diagnostics.lastBurstSend = {
            at = tonumber(now) or getCurrentTime(),
            burstIndex = self.CurrentImmediateBurstCount,
            distribution = item and item.distribution or nil,
            target = item and item.target or nil,
            opcode = getItemOpcode(item),
        }
    end
end

local function clearScheduledWake(self)
    local handle = self.ScheduledWakeHandle
    if type(handle) == "table" and type(handle.Cancel) == "function" then
        pcall(handle.Cancel, handle)
    end
    self.ScheduledWakeGeneration = math.max(0, math.floor(tonumber(self.ScheduledWakeGeneration) or 0)) + 1
    self.ScheduledWakeHandle = nil
    self.ScheduledWakeAt = 0
end

local function scheduleNextProcess(self, wakeAt, waitReason, item)
    local now = getCurrentTime()
    local targetTime = math.max(now, tonumber(wakeAt) or now)
    local delay = math.max(0, targetTime - now)
    self.CurrentImmediateBurstCount = 0

    local existingWakeAt = math.max(0, tonumber(self.ScheduledWakeAt) or 0)
    if existingWakeAt > now and existingWakeAt <= targetTime + 0.001 then
        recordSchedulerState(self, waitReason, targetTime, item, now)
        return true
    end

    clearScheduledWake(self)
    if delay <= 0 then
        recordSchedulerState(self, "none", nil, nil, now)
        return false
    end

    self.ScheduledWakeAt = targetTime
    self.ScheduledWakeGeneration = math.max(0, math.floor(tonumber(self.ScheduledWakeGeneration) or 0)) + 1
    local generation = self.ScheduledWakeGeneration
    recordSchedulerState(self, waitReason, targetTime, item, now)

    local function retry()
        if generation ~= self.ScheduledWakeGeneration then
            return
        end
        self.ScheduledWakeHandle = nil
        self.ScheduledWakeAt = 0
        self:ProcessNext()
    end

    if C_Timer and type(C_Timer.NewTimer) == "function" then
        self.ScheduledWakeHandle = C_Timer.NewTimer(delay, retry)
        return true
    end
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(delay, retry)
        return true
    end

    self.ScheduledWakeAt = 0
    recordSchedulerState(self, waitReason, targetTime, item, now)
    return false
end

local function scheduleImmediateYield(self)
    if self.ImmediateYieldPending == true then
        return true
    end

    clearScheduledWake(self)
    self.CurrentImmediateBurstCount = 0
    self.ImmediateYieldPending = true
    self.ScheduledWakeGeneration = math.max(0, math.floor(tonumber(self.ScheduledWakeGeneration) or 0)) + 1
    local generation = self.ScheduledWakeGeneration
    recordSchedulerState(self, "none", nil, nil, getCurrentTime())

    local function retry()
        if generation ~= self.ScheduledWakeGeneration then
            return
        end
        self.ImmediateYieldPending = false
        self.ScheduledWakeHandle = nil
        self:ProcessNext()
    end

    if C_Timer and type(C_Timer.NewTimer) == "function" then
        self.ScheduledWakeHandle = C_Timer.NewTimer(0, retry)
        return true
    end
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, retry)
        return true
    end

    self.ImmediateYieldPending = false
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

local function getRemainingChunkBytes(item)
    local totalBytes = 0
    for chunkIndex = getNextChunkIndex(item), getChunkCount(item) do
        totalBytes = totalBytes + #(tostring(item and item.chunks and item.chunks[chunkIndex] or ""))
    end
    return totalBytes
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

local function recordSkippedChunks(item, firstIndex, reason)
    if type(Diagnostics.RecordQueueSkipped) ~= "function" then
        return
    end
    local chunkCount = getChunkCount(item)
    for chunkIndex = math.max(1, math.floor(tonumber(firstIndex) or 1)), chunkCount do
        setCurrentChunkFields(item, chunkIndex)
        Diagnostics:RecordQueueSkipped(item, reason or "logical-message-cancelled")
    end
end

local function normalizeReplaceKey(value)
    local normalized = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return normalized ~= "" and normalized or nil
end

local function isSameReplacementScope(item, replaceKey, prefix, opcode, distribution, target)
    if type(item) ~= "table" or normalizeReplaceKey(item.replaceKey) ~= replaceKey then
        return false
    end
    if tostring(item.prefix or "") ~= tostring(prefix or "") then
        return false
    end
    if tonumber(item.opcode) ~= tonumber(opcode) then
        return false
    end
    if tostring(item.distribution or "") ~= tostring(distribution or "") then
        return false
    end
    return tostring(item.target or "") == tostring(target or "")
end

local function findReplaceableMessage(self, replaceKey, prefix, opcode, distribution, target)
    local normalizedKey = normalizeReplaceKey(replaceKey)
    if not normalizedKey then
        return nil, nil
    end

    for itemIndex = #(self.Items or {}), 1, -1 do
        local item = self.Items[itemIndex]
        if isSameReplacementScope(item, normalizedKey, prefix, opcode, distribution, target)
            and item.started ~= true
            and (tonumber(item.totalAttempts) or 0) <= 0
        then
            return itemIndex, item
        end
    end

    return nil, nil
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

local function getItemEligibility(self, item, now)
    local currentTime = tonumber(now) or getCurrentTime()
    refreshPrefixAllowance(self, currentTime)

    local waitUntil = nil
    local waitReason = "none"
    if self.PrefixBlockedUntil > currentTime then
        waitUntil = self.PrefixBlockedUntil
        waitReason = "prefix-throttle"
    elseif usesPrefixAllowance(item) and (tonumber(self.PrefixAllowance) or 0) < 1 then
        waitUntil = getNextEstimatedRefillAt(self, currentTime)
        waitReason = "allowance"
    end

    local routeState = getRouteThrottleState(self, item, false)
    local routeBlockedUntil = type(routeState) == "table" and math.max(0, tonumber(routeState.blockedUntil) or 0) or 0
    if routeBlockedUntil > currentTime and (waitUntil == nil or routeBlockedUntil >= waitUntil) then
        waitUntil = routeBlockedUntil
        waitReason = "channel-throttle"
    end

    return waitUntil == nil, waitUntil, waitReason
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

local function selectNextMessage(self, now)
    if #(self.Items or {}) == 0 then
        return nil, nil, "none", nil
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
            local eligible, waitUntil, waitReason = getItemEligibility(self, item, now)
            return eligible and item or nil, waitUntil, waitReason, item
        end
    end

    local bestIndex = nil
    local bestEffectiveRank = -1
    local bestSequence = math.huge
    local eligibleByIndex = {}
    local earliestWaitUntil = nil
    local earliestWaitReason = "none"
    local earliestWaitItem = nil

    for itemIndex = 1, #self.Items do
        local item = self.Items[itemIndex]
        local eligible, waitUntil, waitReason = getItemEligibility(self, item, now)
        eligibleByIndex[itemIndex] = eligible == true
        if eligible then
            local effectiveRank = getEffectivePriorityRank(self, item)
            local sequence = math.max(0, math.floor(tonumber(item and item.enqueueSequence) or itemIndex))
            if effectiveRank > bestEffectiveRank
                or (effectiveRank == bestEffectiveRank and sequence < bestSequence)
            then
                bestIndex = itemIndex
                bestEffectiveRank = effectiveRank
                bestSequence = sequence
            end
        elseif waitUntil ~= nil and (earliestWaitUntil == nil or waitUntil < earliestWaitUntil) then
            earliestWaitUntil = waitUntil
            earliestWaitReason = waitReason
            earliestWaitItem = item
        end
    end

    if not bestIndex then
        return nil, earliestWaitUntil, earliestWaitReason, earliestWaitItem
    end

    local selected = self.Items[bestIndex]
    local _, baseRank = getEffectivePriorityRank(self, selected)
    selected.effectivePriority = PRIORITY_ORDER[bestEffectiveRank]
    selected.priorityPromoted = bestEffectiveRank > baseRank

    -- Age every other currently eligible logical message once per logical
    -- dispatch. Temporarily throttled routes do not gain bypasses while they
    -- are ineligible, but resume normal starvation protection on recovery.
    for itemIndex = 1, #self.Items do
        if itemIndex ~= bestIndex and eligibleByIndex[itemIndex] == true then
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
    return selected, nil, "none", nil
end

local function consumePrefixAllowance(self, item, now)
    local currentTime = tonumber(now) or getCurrentTime()
    refreshPrefixAllowance(self, currentTime)
    if self.PrefixBlockedUntil > currentTime then
        return false
    end
    if not usesPrefixAllowance(item) then
        return true
    end
    local allowance = tonumber(self.PrefixAllowance) or 0
    if allowance < 1 then
        return false
    end
    self.PrefixAllowance = allowance - 1
    return true
end

local function recordPendingRecoveries(self, item, now)
    local currentTime = tonumber(now) or getCurrentTime()
    if self.PrefixRecoveryPending == true and self.PrefixBlockedUntil <= currentTime then
        self.PrefixRecoveryPending = false
        recordRecoveryAttempt(self, item, "prefix-throttle", currentTime)
    end

    local routeState = getRouteThrottleState(self, item, false)
    if type(routeState) == "table"
        and routeState.recoveryPending == true
        and (tonumber(routeState.blockedUntil) or 0) <= currentTime
    then
        routeState.recoveryPending = false
        recordRecoveryAttempt(self, item, "channel-throttle", currentTime)
    end
end

local function clearRouteThrottleAfterSuccess(self, item)
    local routeState = getRouteThrottleState(self, item, false)
    if type(routeState) ~= "table" then
        return
    end
    routeState.blockedUntil = 0
    routeState.consecutiveThrottleCount = 0
    routeState.recoveryPending = false
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
    clearScheduledWake(self)
    self.Items = {}
    self.IsSending = false
    self.PendingChunkHighWater = 0
    self.LogicalMessageHighWater = 0
    self.EnqueueSequence = 0
    self.PrefixBurstCapacityEstimate = getConfiguredBurstCapacity(self)
    self.PrefixAllowance = self.PrefixBurstCapacityEstimate
    self.PrefixAllowanceUpdatedAt = getCurrentTime()
    self.PrefixBlockedUntil = 0
    self.PrefixRecoveryPending = false
    self.ChannelThrottleState = {}
    self.CurrentImmediateBurstCount = 0
    self.ImmediateYieldPending = false
    if Diagnostics.RecordQueueReset then
        Diagnostics:RecordQueueReset()
    end
    updateQueueMetrics(self)
    recordSchedulerState(self, "none", nil, nil, self.PrefixAllowanceUpdatedAt)
    return self
end

function Queue:Enqueue(item)
    if type(item) ~= "table" then
        error("Addon.Internal.Comms.MessageQueue:Enqueue(item) requires a table.", 2)
    end

    item.priority = self:NormalizePriority(item.priority or (item.metadata and item.metadata.priority))
    item.priorityBypassCount = math.max(0, math.floor(tonumber(item.priorityBypassCount) or 0))
    item.replaceKey = normalizeReplaceKey(item.replaceKey or (item.metadata and item.metadata.replaceKey))

    local requestedChunkCount = getChunkCount(item)
    if requestedChunkCount <= 0 then
        error("Addon.Internal.Comms.MessageQueue:Enqueue(item) requires one or more chunks.", 2)
    end

    if not self:CanAccept(
        requestedChunkCount,
        item.replaceKey,
        item.prefix,
        item.opcode,
        item.distribution,
        item.target
    ) then
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

    local supersededIndex, supersededItem = findReplaceableMessage(
        self,
        item.replaceKey,
        item.prefix,
        item.opcode,
        item.distribution,
        item.target
    )
    local supersededPendingChunks = supersededItem and getRemainingChunkCount(supersededItem) or 0
    local supersededPendingBytes = supersededItem and getRemainingChunkBytes(supersededItem) or 0
    if supersededItem then
        recordSkippedChunks(
            supersededItem,
            getNextChunkIndex(supersededItem),
            "logical-message-superseded"
        )
        table.remove(self.Items, supersededIndex)
        if Diagnostics.RecordQueueLogicalSuperseded then
            Diagnostics:RecordQueueLogicalSuperseded(
                supersededItem,
                item,
                supersededPendingChunks,
                supersededPendingBytes
            )
        end
        if Diagnostics.SupersedeLogicalSend then
            Diagnostics:SupersedeLogicalSend(supersededItem._rpeLogicalDiagnosticId, "superseded")
        end
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

    if supersededItem then
        invokeCallback(supersededItem.callbacks and supersededItem.callbacks.onFailed, supersededItem, "superseded")
    end

    self:ProcessNext()
    return item
end

function Queue:CanAccept(count, replaceKey, prefix, opcode, distribution, target)
    local requestedCount = math.max(0, math.floor(tonumber(count) or 0))
    local maxQueueLength = tonumber(self.MaxQueueLength) or tonumber(self.DefaultMaxQueueLength) or 0
    if maxQueueLength <= 0 then
        return true
    end

    local pendingChunkCount = self:GetPendingChunkCount()
    local _, replaceableItem = findReplaceableMessage(
        self,
        replaceKey,
        prefix,
        opcode,
        distribution,
        target
    )
    if replaceableItem then
        pendingChunkCount = math.max(0, pendingChunkCount - getRemainingChunkCount(replaceableItem))
    end

    return (pendingChunkCount + requestedCount) <= maxQueueLength
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
        replaceKey = metadata and metadata.replaceKey or nil,
    })
end

function Queue:HandleSuccess(item, result)
    local now = getCurrentTime()
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

    clearRouteThrottleAfterSuccess(self, item)
    recordSuccessfulBurstSend(self, item, now)
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
    recordSchedulerState(self, "none", nil, nil, now)
    self:ProcessNext()
    return delivered
end

function Queue:HandleThrottle(item, result)
    local maxAttempts = tonumber(self.MaxAttempts) or tonumber(self.DefaultMaxAttempts) or 0
    if maxAttempts > 0 and (item.attempts or 0) >= maxAttempts then
        self:HandleFailure(item, "max-attempts")
        return
    end

    local now = getCurrentTime()
    if Diagnostics.RecordQueueThrottle then
        Diagnostics:RecordQueueThrottle(item, result)
    end

    local diagnostics = Diagnostics.GetQueueDiagnosticsStore and Diagnostics:GetQueueDiagnosticsStore() or nil
    if tonumber(result) == 3 then
        refreshPrefixAllowance(self, now)
        local previousEstimate = tonumber(self.PrefixBurstCapacityEstimate) or getConfiguredBurstCapacity(self)
        local reducedEstimate = math.max(1, math.floor(previousEstimate * 0.75))
        if previousEstimate > 1 and reducedEstimate >= previousEstimate then
            reducedEstimate = previousEstimate - 1
        end
        self.PrefixBurstCapacityEstimate = reducedEstimate
        self.PrefixAllowance = 0
        self.PrefixAllowanceUpdatedAt = now
        local blockedDuration = 1 / getConfiguredRefillRate(self)
        self.PrefixBlockedUntil = now + blockedDuration
        self.PrefixRecoveryPending = true
        if type(diagnostics) == "table" then
            diagnostics.lastPrefixThrottleBlockedDuration = blockedDuration
            diagnostics.lastPrefixThrottleBurstEstimateBefore = previousEstimate
            diagnostics.lastPrefixThrottleBurstEstimateAfter = reducedEstimate
            diagnostics.prefixBlockedUntil = self.PrefixBlockedUntil
        end
    elseif tonumber(result) == 8 then
        local routeState, routeKey = getRouteThrottleState(self, item, true)
        routeState.consecutiveThrottleCount = math.max(
            0,
            math.floor(tonumber(routeState.consecutiveThrottleCount) or 0)
        ) + 1
        local blockedDuration = math.min(
            getConfiguredChannelBackoff(self) * (2 ^ math.max(0, routeState.consecutiveThrottleCount - 1)),
            getConfiguredMaxChannelBackoff(self)
        )
        routeState.blockedUntil = now + blockedDuration
        routeState.recoveryPending = true
        if type(diagnostics) == "table" then
            diagnostics.lastChannelThrottleRouteKey = routeKey
            diagnostics.lastChannelThrottleDistribution = item and item.distribution or nil
            diagnostics.lastChannelThrottleTarget = item and item.target or nil
            diagnostics.lastChannelThrottleBlockedDuration = blockedDuration
            diagnostics.lastChannelBlockedUntil = routeState.blockedUntil
        end
    end

    self.IsSending = false
    self.CurrentImmediateBurstCount = 0
    recordSchedulerState(
        self,
        tonumber(result) == 3 and "prefix-throttle" or "channel-throttle",
        nil,
        item,
        now
    )
    self:ProcessNext()
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
    recordSchedulerState(self, "none", nil, nil, getCurrentTime())
    self:ProcessNext()
end

function Queue:ProcessNext()
    if self.IsSending or self.ImmediateYieldPending == true then
        return false
    end

    removeSkippedItems(self)
    if #self.Items == 0 then
        clearScheduledWake(self)
        recordSchedulerState(self, "none", nil, nil, getCurrentTime())
        return false
    end

    local now = getCurrentTime()
    refreshPrefixAllowance(self, now)
    local item, waitUntil, waitReason, waitingItem = selectNextMessage(self, now)
    if not item then
        if waitUntil ~= nil and waitUntil > now then
            scheduleNextProcess(self, waitUntil, waitReason, waitingItem)
        else
            recordSchedulerState(self, waitReason or "none", waitUntil, waitingItem, now)
        end
        return false
    end

    if self.CurrentImmediateBurstCount >= getConfiguredImmediateBurstLimit(self) then
        scheduleImmediateYield(self)
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

    if not consumePrefixAllowance(self, item, now) then
        local _, nextEligibleAt, reason = getItemEligibility(self, item, now)
        if nextEligibleAt and nextEligibleAt > now then
            scheduleNextProcess(self, nextEligibleAt, reason, item)
        end
        return false
    end

    recordPendingRecoveries(self, item, now)
    recordSchedulerState(self, "none", nil, nil, now)
    self.IsSending = true
    item.attempts = (item.attempts or 0) + 1
    item.totalAttempts = (item.totalAttempts or 0) + 1

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
    local now = getCurrentTime()
    refreshPrefixAllowance(self, now)
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
    stats.estimatedAllowance = tonumber(self.PrefixAllowance) or 0
    stats.estimatedBurstCapacity = tonumber(self.PrefixBurstCapacityEstimate) or getConfiguredBurstCapacity(self)
    stats.estimatedRefillRate = getConfiguredRefillRate(self)
    stats.nextEstimatedRefillAt = getNextEstimatedRefillAt(self, now)
    stats.prefixBlockedUntil = math.max(0, tonumber(self.PrefixBlockedUntil) or 0)
    stats.scheduledWakeAt = math.max(0, tonumber(self.ScheduledWakeAt) or 0)
    stats.isWaiting = stats.scheduledWakeAt > now or self.ImmediateYieldPending == true
    stats.isSending = self.IsSending and true or false
    return stats
end