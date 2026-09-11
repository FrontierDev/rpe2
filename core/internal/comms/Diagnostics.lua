local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Utils = Addon.Utils or {}

-- Forward Declarations
local Common = Addon.Utils.Common or {}
local Comms = Addon.Internal.Comms
local Diagnostics = Addon.Internal.Comms.Diagnostics or {}
Addon.Internal.Comms.Diagnostics = Diagnostics

-- Runtime State
Diagnostics.State = Diagnostics.State or {}

-- Helpers
local copyTable = Common.CopyTable
local getNow = Common.GetNow
local trimForDebug = Common.TrimForDebug
local function getStore(self, key)
    self.State = self.State or {}
    self.State[key] = self.State[key] or {}
    return self.State[key]
end

local function getItemPriority(item)
    return tostring(item and item.priority or "NORMAL")
end

local function buildSendDiagnostics(metadata, distribution, target, payloadText, packetCount)
    return {
        at = getNow(),
        distribution = distribution,
        target = target ~= nil and tostring(target) or nil,
        payloadPreview = trimForDebug(payloadText, 120),
        opcode = metadata and metadata.opcode or nil,
        scope = metadata and metadata.scope or nil,
        packetCount = packetCount,
        chunked = packetCount > 1,
    }
end

function Diagnostics:GetTransportDiagnosticsStore()
    return getStore(self, "transport")
end

function Diagnostics:GetQueueDiagnosticsStore()
    return getStore(self, "queue")
end

function Diagnostics:ResetTransportDiagnostics()
    self.State = self.State or {}
    self.State.transport = {}
    return self.State.transport
end

function Diagnostics:ResetQueueDiagnostics()
    self.State = self.State or {}
    self.State.queue = {
        lastResetAt = getNow(),
        currentLogicalMessageCount = 0,
        currentPendingChunkCount = 0,
        highWaterLogicalMessageCount = 0,
        highWaterPendingChunkCount = 0,
        selectedCountByPriority = {},
        selectedEffectiveCountByPriority = {},
        queueWaitByPriority = {},
        starvationPromotionCount = 0,
        supersededMessageCount = 0,
        supersededPendingChunkCount = 0,
        supersededPendingBytes = 0,
    }
    return self.State.queue
end

function Diagnostics:ResetDiagnostics()
    self.State = {}
    self:ResetTransportDiagnostics()
    self:ResetQueueDiagnostics()
    return self.State
end

function Diagnostics:RecordPrefixRegistration(registered)
    local diagnostics = self:GetTransportDiagnosticsStore()
    diagnostics.prefixRegistered = registered and true or false
    diagnostics.lastPrefix = registered and Comms.Prefix or nil
end

function Diagnostics:RecordSendFailure(code)
    local diagnostics = self:GetTransportDiagnosticsStore()
    diagnostics.failedSendCount = (diagnostics.failedSendCount or 0) + 1
    diagnostics.lastSendFailed = true
    diagnostics.lastSendFailureCode = code
end

function Diagnostics:RecordSendSuccess(metadata, distribution, target, payloadText, packetCount)
    local diagnostics = self:GetTransportDiagnosticsStore()
    diagnostics.sentCount = (diagnostics.sentCount or 0) + 1
    diagnostics.lastSendFailed = false
    diagnostics.lastSent = buildSendDiagnostics(metadata, distribution, target, payloadText, packetCount)
end

function Diagnostics:RecordChunkPlan(metadata, distribution, target, payloadBytes, chunkLength, packetCount, packetPayloadLimit)
    local diagnostics = self:GetTransportDiagnosticsStore()
    local record = {
        at = getNow(),
        distribution = distribution,
        target = target ~= nil and tostring(target) or nil,
        opcode = metadata and metadata.opcode or nil,
        scope = metadata and metadata.scope or nil,
        serializedArgumentBytes = math.max(0, math.floor(tonumber(payloadBytes) or 0)),
        chunkPayloadBytes = math.max(0, math.floor(tonumber(chunkLength) or 0)),
        packetPayloadLimit = math.max(0, math.floor(tonumber(packetPayloadLimit) or 0)),
        packetCount = math.max(0, math.floor(tonumber(packetCount) or 0)),
        optionalChunkCap = tonumber(Comms.SafeChunkLength),
    }
    diagnostics.chunkPlanCount = (diagnostics.chunkPlanCount or 0) + 1
    diagnostics.lastChunkPlan = record
    diagnostics.chunkPlansByOpcode = diagnostics.chunkPlansByOpcode or {}
    if record.opcode ~= nil then
        diagnostics.chunkPlansByOpcode[tostring(record.opcode)] = copyTable(record)
    end
end

function Diagnostics:RecordInboundMessage(payload, distribution, sender, target, partCount, opcode)
    local diagnostics = self:GetTransportDiagnosticsStore()
    diagnostics.receivedCount = (diagnostics.receivedCount or 0) + 1
    diagnostics.lastReceived = {
        at = getNow(),
        distribution = distribution,
        sender = sender,
        target = target,
        payloadPreview = trimForDebug(payload, 120),
        opcode = opcode,
        packetCount = partCount,
        chunked = partCount > 1,
    }
end

function Diagnostics:RecordInvalidInbound(message, distribution, sender)
    local diagnostics = self:GetTransportDiagnosticsStore()
    diagnostics.invalidInboundCount = (diagnostics.invalidInboundCount or 0) + 1
    diagnostics.lastInvalidInbound = {
        at = getNow(),
        sender = sender,
        distribution = distribution,
        payloadPreview = trimForDebug(message, 120),
    }
end

function Diagnostics:RecordChannelJoin(channelName, channelId)
    local diagnostics = self:GetTransportDiagnosticsStore()
    diagnostics.lastJoinedChannelName = channelName
    diagnostics.lastJoinedChannelId = channelId
    diagnostics.lastJoinAt = getNow()
end

function Diagnostics:RecordChannelLeave(channelName)
    local diagnostics = self:GetTransportDiagnosticsStore()
    diagnostics.lastLeftChannelName = channelName
    diagnostics.lastLeaveAt = getNow()
end

function Diagnostics:AnnotateLastReceived(opcode, scope)
    local diagnostics = self:GetTransportDiagnosticsStore()
    if diagnostics.lastReceived then
        diagnostics.lastReceived.opcode = opcode
        diagnostics.lastReceived.scope = scope
    end
end

function Diagnostics:RecordQueueReset()
    self:ResetQueueDiagnostics()
end

function Diagnostics:RecordQueueLogicalEnqueued(item)
    local diagnostics = self:GetQueueDiagnosticsStore()
    diagnostics.enqueuedMessageCount = (diagnostics.enqueuedMessageCount or 0) + 1
    diagnostics.lastLogicalEnqueued = {
        at = getNow(),
        prefix = item and item.prefix or nil,
        opcode = item and item.opcode or nil,
        distribution = item and item.distribution or nil,
        target = item and item.target or nil,
        chunkCount = type(item) == "table" and type(item.chunks) == "table" and #item.chunks or 0,
        priority = getItemPriority(item),
        enqueueSequence = item and item.enqueueSequence or nil,
        replaceKey = item and item.replaceKey or nil,
    }
end

function Diagnostics:RecordQueueLogicalSelected(item, queueWaitSeconds, effectivePriority, promoted)
    local diagnostics = self:GetQueueDiagnosticsStore()
    local priority = getItemPriority(item)
    local effective = tostring(effectivePriority or priority)
    local waitSeconds = math.max(0, tonumber(queueWaitSeconds) or 0)

    diagnostics.selectedCountByPriority = type(diagnostics.selectedCountByPriority) == "table"
        and diagnostics.selectedCountByPriority or {}
    diagnostics.selectedCountByPriority[priority] = (diagnostics.selectedCountByPriority[priority] or 0) + 1

    diagnostics.selectedEffectiveCountByPriority = type(diagnostics.selectedEffectiveCountByPriority) == "table"
        and diagnostics.selectedEffectiveCountByPriority or {}
    diagnostics.selectedEffectiveCountByPriority[effective] = (diagnostics.selectedEffectiveCountByPriority[effective] or 0) + 1

    diagnostics.queueWaitByPriority = type(diagnostics.queueWaitByPriority) == "table"
        and diagnostics.queueWaitByPriority or {}
    local waitBucket = diagnostics.queueWaitByPriority[priority]
    if type(waitBucket) ~= "table" then
        waitBucket = {
            count = 0,
            totalSeconds = 0,
            maxSeconds = 0,
            lastSeconds = 0,
            averageSeconds = 0,
        }
        diagnostics.queueWaitByPriority[priority] = waitBucket
    end
    waitBucket.count = (waitBucket.count or 0) + 1
    waitBucket.totalSeconds = (waitBucket.totalSeconds or 0) + waitSeconds
    waitBucket.maxSeconds = math.max(tonumber(waitBucket.maxSeconds) or 0, waitSeconds)
    waitBucket.lastSeconds = waitSeconds
    waitBucket.averageSeconds = waitBucket.totalSeconds / waitBucket.count

    if promoted == true then
        diagnostics.starvationPromotionCount = (diagnostics.starvationPromotionCount or 0) + 1
    end

    diagnostics.lastLogicalSelected = {
        at = getNow(),
        prefix = item and item.prefix or nil,
        opcode = item and item.opcode or nil,
        distribution = item and item.distribution or nil,
        target = item and item.target or nil,
        priority = priority,
        effectivePriority = effective,
        queueWaitSeconds = waitSeconds,
        priorityBypassCount = math.max(0, math.floor(tonumber(item and item.priorityBypassCount) or 0)),
        starvationPromoted = promoted == true,
        enqueueSequence = item and item.enqueueSequence or nil,
        replaceKey = item and item.replaceKey or nil,
    }
end

function Diagnostics:RecordQueueLogicalSuperseded(item, replacement, savedPendingChunkCount, savedPendingBytes)
    local diagnostics = self:GetQueueDiagnosticsStore()
    local savedChunks = math.max(0, math.floor(tonumber(savedPendingChunkCount) or 0))
    local savedBytes = math.max(0, math.floor(tonumber(savedPendingBytes) or 0))
    diagnostics.supersededMessageCount = (diagnostics.supersededMessageCount or 0) + 1
    diagnostics.supersededPendingChunkCount = (diagnostics.supersededPendingChunkCount or 0) + savedChunks
    diagnostics.supersededPendingBytes = (diagnostics.supersededPendingBytes or 0) + savedBytes
    diagnostics.lastLogicalSuperseded = {
        at = getNow(),
        prefix = item and item.prefix or nil,
        opcode = item and item.opcode or nil,
        distribution = item and item.distribution or nil,
        target = item and item.target or nil,
        priority = getItemPriority(item),
        effectivePriority = item and item.effectivePriority or nil,
        replaceKey = item and item.replaceKey or nil,
        savedPendingChunkCount = savedChunks,
        savedPendingBytes = savedBytes,
        replacementOpcode = replacement and replacement.opcode or nil,
        replacementPriority = getItemPriority(replacement),
    }
end

function Diagnostics:RecordQueueLogicalDelivered(item, result)
    local diagnostics = self:GetQueueDiagnosticsStore()
    diagnostics.deliveredMessageCount = (diagnostics.deliveredMessageCount or 0) + 1
    diagnostics.lastLogicalDelivered = {
        at = getNow(),
        prefix = item and item.prefix or nil,
        opcode = item and item.opcode or nil,
        distribution = item and item.distribution or nil,
        target = item and item.target or nil,
        chunkCount = type(item) == "table" and type(item.chunks) == "table" and #item.chunks or 0,
        result = result,
        priority = getItemPriority(item),
        effectivePriority = item and item.effectivePriority or nil,
        replaceKey = item and item.replaceKey or nil,
    }
end

function Diagnostics:RecordQueueLogicalFailure(item, result)
    local diagnostics = self:GetQueueDiagnosticsStore()
    diagnostics.failedMessageCount = (diagnostics.failedMessageCount or 0) + 1
    diagnostics.lastLogicalFailure = {
        at = getNow(),
        prefix = item and item.prefix or nil,
        opcode = item and item.opcode or nil,
        distribution = item and item.distribution or nil,
        target = item and item.target or nil,
        chunkCount = type(item) == "table" and type(item.chunks) == "table" and #item.chunks or 0,
        result = result,
        priority = getItemPriority(item),
        effectivePriority = item and item.effectivePriority or nil,
        replaceKey = item and item.replaceKey or nil,
    }
end

function Diagnostics:RecordQueueLogicalSkipped(item, remainingChunkCount)
    local diagnostics = self:GetQueueDiagnosticsStore()
    diagnostics.skippedMessageCount = (diagnostics.skippedMessageCount or 0) + 1
    diagnostics.lastLogicalSkipped = {
        at = getNow(),
        prefix = item and item.prefix or nil,
        opcode = item and item.opcode or nil,
        distribution = item and item.distribution or nil,
        target = item and item.target or nil,
        remainingChunkCount = math.max(0, math.floor(tonumber(remainingChunkCount) or 0)),
        priority = getItemPriority(item),
        replaceKey = item and item.replaceKey or nil,
    }
end

function Diagnostics:RecordQueueEnqueued(item)
    local diagnostics = self:GetQueueDiagnosticsStore()
    diagnostics.enqueuedCount = (diagnostics.enqueuedCount or 0) + 1
    diagnostics.lastEnqueued = {
        at = getNow(),
        prefix = item.prefix,
        distribution = item.distribution,
        target = item.target,
        chunkPartIndex = item.chunkPartIndex,
        chunkPartCount = item.chunkPartCount,
        priority = getItemPriority(item),
    }
end

function Diagnostics:RecordQueueSent(item, result)
    local diagnostics = self:GetQueueDiagnosticsStore()
    diagnostics.sentCount = (diagnostics.sentCount or 0) + 1
    diagnostics.lastResult = result
    diagnostics.lastSent = {
        at = getNow(),
        prefix = item.prefix,
        distribution = item.distribution,
        target = item.target,
        chunkPartIndex = item.chunkPartIndex,
        chunkPartCount = item.chunkPartCount,
        priority = getItemPriority(item),
        effectivePriority = item and item.effectivePriority or nil,
    }
end

function Diagnostics:RecordQueueThrottle(item, result)
    local diagnostics = self:GetQueueDiagnosticsStore()
    diagnostics.throttledCount = (diagnostics.throttledCount or 0) + 1
    diagnostics.lastResult = result
    diagnostics.lastThrottle = {
        at = getNow(),
        prefix = item.prefix,
        distribution = item.distribution,
        target = item.target,
        attempts = item.attempts,
        chunkPartIndex = item.chunkPartIndex,
        chunkPartCount = item.chunkPartCount,
        priority = getItemPriority(item),
        effectivePriority = item and item.effectivePriority or nil,
    }
end

function Diagnostics:RecordQueueFailure(item, result)
    local diagnostics = self:GetQueueDiagnosticsStore()
    diagnostics.failedCount = (diagnostics.failedCount or 0) + 1
    diagnostics.lastResult = result
    diagnostics.lastFailure = {
        at = getNow(),
        prefix = item.prefix,
        distribution = item.distribution,
        target = item.target,
        attempts = item.attempts,
        code = result,
        chunkPartIndex = item.chunkPartIndex,
        chunkPartCount = item.chunkPartCount,
        priority = getItemPriority(item),
        effectivePriority = item and item.effectivePriority or nil,
    }
end

function Diagnostics:RecordQueueSkipped(item, reason)
    local diagnostics = self:GetQueueDiagnosticsStore()
    diagnostics.skippedCount = (diagnostics.skippedCount or 0) + 1
    diagnostics.lastSkipped = {
        at = getNow(),
        prefix = item and item.prefix or nil,
        distribution = item and item.distribution or nil,
        target = item and item.target or nil,
        chunkPartIndex = item and item.chunkPartIndex or nil,
        chunkPartCount = item and item.chunkPartCount or nil,
        reason = reason or "skipped",
        priority = getItemPriority(item),
    }
end

function Diagnostics:GetMessageQueueDiagnostics()
    return copyTable(self:GetQueueDiagnosticsStore())
end

function Diagnostics:GetDiagnostics()
    local diagnostics = copyTable(self:GetTransportDiagnosticsStore())
    diagnostics.prefix = Comms.Prefix
    diagnostics.messageQueue = self:GetMessageQueueDiagnostics()
    return diagnostics
end
