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
Queue.DefaultMaxQueueLength = Queue.DefaultMaxQueueLength or 256
Queue.MaxQueueLength = Queue.MaxQueueLength or Queue.DefaultMaxQueueLength
Queue.Items = Queue.Items or {}
Queue.IsSending = Queue.IsSending or false
Queue.NextSendAt = Queue.NextSendAt or 0

-- Helpers
local invokeCallback = Common.InvokeCallback

local function getItemOpcode(item)
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

function Queue:Reset()
    self.Items = {}
    self.IsSending = false
    self.NextSendAt = 0
    if Diagnostics.RecordQueueReset then
        Diagnostics:RecordQueueReset()
    end
    return self
end

function Queue:Enqueue(item)
    if type(item) ~= "table" then
        error("Addon.Internal.Comms.MessageQueue:Enqueue(item) requires a table.", 2)
    end

    local maxQueueLength = tonumber(self.MaxQueueLength) or tonumber(self.DefaultMaxQueueLength) or 0
    if maxQueueLength > 0 and (#self.Items + 1) > maxQueueLength then
        if Diagnostics.RecordQueueFailure then
            Diagnostics:RecordQueueFailure(item, "queue-full")
        end
        invokeCallback(item.callbacks and item.callbacks.onFailed, item, "queue-full")
        return nil
    end

    item.attempts = tonumber(item.attempts) or 0
    self.Items[#self.Items + 1] = item
    if Diagnostics.RecordQueueEnqueued then
        Diagnostics:RecordQueueEnqueued(item)
    end

    self:ProcessNext()
    return item
end

function Queue:CanAccept(count)
    local requestedCount = math.max(0, math.floor(tonumber(count) or 0))
    local maxQueueLength = tonumber(self.MaxQueueLength) or tonumber(self.DefaultMaxQueueLength) or 0
    if maxQueueLength <= 0 then
        return true
    end

    return (#self.Items + requestedCount) <= maxQueueLength
end

function Queue:EnqueueAddonMessage(prefix, payload, distribution, target, callbacks)
    return self:Enqueue({
        prefix = prefix,
        payload = payload,
        distribution = distribution,
        target = target,
        chunkPartIndex = callbacks and callbacks.chunkPartIndex or nil,
        chunkPartCount = callbacks and callbacks.chunkPartCount or nil,
        shouldSkip = callbacks and callbacks.shouldSkip or nil,
        callbacks = callbacks,
    })
end

function Queue:HandleSuccess(item, result)
    table.remove(self.Items, 1)
    if Diagnostics.RecordQueueSent then
        Diagnostics:RecordQueueSent(item, result)
    end

    local chunkSuffix = ""
    local chunkPartCount = tonumber(item and item.chunkPartCount) or 0
    if chunkPartCount > 1 then
        chunkSuffix = (" part=%d/%d"):format(
            math.max(1, tonumber(item and item.chunkPartIndex) or 1),
            chunkPartCount
        )
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

    invokeCallback(item.callbacks and item.callbacks.onSent, item, result)
    self.IsSending = false
    self:ProcessNext()
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
    table.remove(self.Items, 1)
    self.IsSending = false
    if Diagnostics.RecordQueueFailure then
        Diagnostics:RecordQueueFailure(item, result)
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

    while #self.Items > 0 do
        local nextItem = self.Items[1]
        if not nextItem or type(nextItem.shouldSkip) ~= "function" or not nextItem.shouldSkip() then
            break
        end

        table.remove(self.Items, 1)
    end

    if #self.Items == 0 then
        return false
    end

    local item = self.Items[1]
    if not item then
        return false
    end

    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
        self:HandleFailure(item, "missing-api")
        return false
    end

    self.IsSending = true
    item.attempts = (item.attempts or 0) + 1
    self.NextSendAt = now + getMinimumSendDelay(self)

    local result = C_ChatInfo.SendAddonMessage(item.prefix, item.payload, item.distribution, item.target)
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
    stats.sendDelay = self.SendDelay
    stats.isSending = self.IsSending and true or false
    return stats
end
