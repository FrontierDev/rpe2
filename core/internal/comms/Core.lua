local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Utils = Addon.Utils or {}

local Common = Addon.Utils.Common or {}
local Constants = Addon.Internal.Constants or {}
local Comms = Addon.Internal.Comms
local Diagnostics = Addon.Internal.Comms.Diagnostics or {}
local MessageQueue = Addon.Internal.Comms.MessageQueue or {}
local Operations = Addon.Internal.Comms.Operations or {}
local Serialization = Addon.Internal.Comms.Serialization or {}

Comms.Prefix = Comms.Prefix or Constants.AddonMessagePrefix or "RPE"
Comms.MaxAddonMessageLength = Comms.MaxAddonMessageLength or 255
-- Optional compatibility cap. Nil uses the full header-adjusted addon-message payload budget.
Comms.SafeChunkLength = tonumber(Comms.SafeChunkLength)
Comms.IncomingChunks = Comms.IncomingChunks or {}
Comms.IncomingChunkTimeout = Comms.IncomingChunkTimeout or 30
Comms.MaxIncomingChunkEntries = Comms.MaxIncomingChunkEntries or 128
Comms.RecentLocalEchoes = Comms.RecentLocalEchoes or {}
Comms.RecentLocalEchoTimeout = Comms.RecentLocalEchoTimeout or 5
Comms.MaxRecentLocalEchoes = Comms.MaxRecentLocalEchoes or 256

local getGroupType = Common.GetGroupType
local getNow = Common.GetNow
local getPlayerName = Common.GetPlayerName
local normalizeName = Common.NormalizeName

local function getTimings()
    return Addon.Debug and Addon.Debug.Timings or nil
end

local function getTimingNowMilliseconds()
    local timings = getTimings()
    return type(timings) == "table" and type(timings.GetNowMilliseconds) == "function"
        and timings.GetNowMilliseconds()
        or 0
end

local function getTimedEventOpcodeKey(opcode)
    local operation = Operations and Operations.Get and Operations:Get(opcode) or nil
    local key = type(operation) == "table" and tostring(operation.key or "") or ""
    if key == "EVENT_START" or key == "EVENT_UNITS" or key == "EVENT_STATE" then
        return key
    end

    return nil
end

local function shouldImmediatelyEchoOpcode(opcode)
    local operation = Operations and Operations.Get and Operations:Get(opcode) or nil
    local key = type(operation) == "table" and tostring(operation.key or "") or ""
    return key == "EVENT_START"
        or key == "EVENT_UNITS"
        or key == "EVENT_STATE"
        or key == "SPELLCAST_START"
        or key == "SPELLCAST_COMPLETE"
        or key == "SPELLCAST_INTERRUPT"
end

local function logTimingParts(label, context, parts, totalElapsedMs, thresholdMs)
    local timings = getTimings()
    if type(timings) == "table" and type(timings.LogParts) == "function" then
        return timings:LogParts(label, context, parts, totalElapsedMs, thresholdMs)
    end

    return false
end

local function buildInboundChunkKey(sender, opcode)
    return table.concat({
        tostring(sender or ""),
        tostring(opcode or ""),
    }, ":")
end

local function buildRecentLocalEchoKey(prefix, message, distribution, sender, target)
    local normalizedTarget = distribution == "CHANNEL" and "" or tostring(target or "")
    return table.concat({
        tostring(prefix or ""),
        tostring(distribution or ""),
        tostring(normalizeName and normalizeName(sender) or sender or ""),
        normalizedTarget,
        tostring(message or ""),
    }, ":")
end

local function getTimestamp()
    local now = Common.GetNow
    if type(now) == "function" then
        return now()
    end

    if type(getNow) == "function" then
        return getNow()
    end

    return 0
end

local function shouldEchoOutboundChannel(distribution, target)
    if distribution ~= "CHANNEL" then
        return false
    end

    local channelId = tonumber(target)
    return channelId ~= nil and channelId > 0
end

local function shouldDeliverImmediateLocalEcho(distribution, target, opcode)
    return shouldEchoOutboundChannel(distribution, target) and shouldImmediatelyEchoOpcode(opcode)
end

local function getEventUnitsOpcode()
    return Operations and Operations.GetOpcode and Operations:GetOpcode("EVENT_UNITS") or nil
end

local function notifyInboundChunkProgress(packet, distribution, sender, target, receivedCount, startedAtMs)
    if not packet or packet.opcode ~= getEventUnitsOpcode() then
        return
    end

    if type(Comms.HandleInboundChunkProgress) == "function" then
        Comms:HandleInboundChunkProgress(packet, receivedCount, distribution, sender, target, startedAtMs)
    end
end

local function cleanupIncomingChunks(self, now)
    local timeoutSeconds = tonumber(self.IncomingChunkTimeout) or 0
    local maxEntries = tonumber(self.MaxIncomingChunkEntries) or 0
    local entryCount = 0
    local oldestKey = nil
    local oldestAt = nil

    for key, entry in pairs(self.IncomingChunks or {}) do
        local receivedAt = tonumber(entry and entry.receivedAt) or 0
        if timeoutSeconds > 0 and (now - receivedAt) > timeoutSeconds then
            self.IncomingChunks[key] = nil
        else
            entryCount = entryCount + 1
            if maxEntries > 0 and (oldestAt == nil or receivedAt < oldestAt) then
                oldestAt = receivedAt
                oldestKey = key
            end
        end
    end

    while maxEntries > 0 and entryCount >= maxEntries and oldestKey do
        self.IncomingChunks[oldestKey] = nil
        entryCount = entryCount - 1

        oldestKey = nil
        oldestAt = nil
        for key, entry in pairs(self.IncomingChunks or {}) do
            local receivedAt = tonumber(entry and entry.receivedAt) or 0
            if oldestAt == nil or receivedAt < oldestAt then
                oldestAt = receivedAt
                oldestKey = key
            end
        end
    end
end

local function normalizeRecentLocalEchoEntry(self, key)
    local stored = self.RecentLocalEchoes and self.RecentLocalEchoes[key] or nil
    if stored == nil then
        return nil
    end

    if type(stored) == "table" then
        stored.pendingCount = math.max(0, math.floor(tonumber(stored.pendingCount) or 0))
        stored.sentCount = math.max(0, math.floor(tonumber(stored.sentCount) or 0))
        stored.recordedAt = tonumber(stored.recordedAt) or tonumber(stored.sentAt) or 0
        stored.sentAt = tonumber(stored.sentAt)
        return stored
    end

    local timestamp = tonumber(stored)
    if timestamp == nil then
        self.RecentLocalEchoes[key] = nil
        return nil
    end

    local entry = {
        pendingCount = 0,
        sentCount = 1,
        recordedAt = timestamp,
        sentAt = timestamp,
    }
    self.RecentLocalEchoes[key] = entry
    return entry
end

local function recordRecentLocalEcho(self, prefix, message, distribution, sender, target, now, pending)
    local key = buildRecentLocalEchoKey(prefix, message, distribution, sender, target)
    local entry = normalizeRecentLocalEchoEntry(self, key)
    if not entry then
        entry = {
            pendingCount = 0,
            sentCount = 0,
            recordedAt = tonumber(now) or 0,
            sentAt = nil,
        }
        self.RecentLocalEchoes[key] = entry
    end

    entry.recordedAt = tonumber(now) or entry.recordedAt or 0
    if pending == true then
        entry.pendingCount = entry.pendingCount + 1
    else
        entry.sentCount = entry.sentCount + 1
        entry.sentAt = tonumber(now) or entry.recordedAt or 0
    end
    return key, entry
end

local function markRecentLocalEchoSent(self, prefix, message, distribution, sender, target, now)
    local key = buildRecentLocalEchoKey(prefix, message, distribution, sender, target)
    local entry = normalizeRecentLocalEchoEntry(self, key)
    if not entry or entry.pendingCount <= 0 then
        return false
    end

    entry.pendingCount = entry.pendingCount - 1
    entry.sentCount = entry.sentCount + 1
    entry.sentAt = tonumber(now) or entry.recordedAt or 0
    return true
end

local function releasePendingRecentLocalEcho(self, prefix, message, distribution, sender, target)
    local key = buildRecentLocalEchoKey(prefix, message, distribution, sender, target)
    local entry = normalizeRecentLocalEchoEntry(self, key)
    if not entry or entry.pendingCount <= 0 then
        return false
    end

    entry.pendingCount = entry.pendingCount - 1
    if entry.pendingCount <= 0 and entry.sentCount <= 0 then
        self.RecentLocalEchoes[key] = nil
    end
    return true
end

local function cleanupRecentLocalEchoes(self, now)
    local timeoutSeconds = tonumber(self.RecentLocalEchoTimeout) or 0
    local maxEntries = tonumber(self.MaxRecentLocalEchoes) or 0
    local entryCount = 0
    local oldestKey = nil
    local oldestAt = nil

    for key in pairs(self.RecentLocalEchoes or {}) do
        local entry = normalizeRecentLocalEchoEntry(self, key)
        if entry then
            local pendingCount = math.max(0, tonumber(entry.pendingCount) or 0)
            local sentCount = math.max(0, tonumber(entry.sentCount) or 0)
            if pendingCount <= 0 and sentCount <= 0 then
                self.RecentLocalEchoes[key] = nil
            elseif pendingCount <= 0 then
                local referenceAt = tonumber(entry.sentAt) or tonumber(entry.recordedAt) or 0
                if timeoutSeconds > 0 and (now - referenceAt) > timeoutSeconds then
                    self.RecentLocalEchoes[key] = nil
                else
                    entryCount = entryCount + 1
                    if maxEntries > 0 and (oldestAt == nil or referenceAt < oldestAt) then
                        oldestAt = referenceAt
                        oldestKey = key
                    end
                end
            else
                -- A pending entry maps to a physical packet that is still queued/throttled.
                -- Pending entries are never age-expired or size-evicted.
                entryCount = entryCount + 1
            end
        end
    end

    while maxEntries > 0 and entryCount >= maxEntries and oldestKey do
        self.RecentLocalEchoes[oldestKey] = nil
        entryCount = entryCount - 1
        oldestKey = nil
        oldestAt = nil
        for key in pairs(self.RecentLocalEchoes or {}) do
            local entry = normalizeRecentLocalEchoEntry(self, key)
            if entry and (tonumber(entry.pendingCount) or 0) <= 0 and (tonumber(entry.sentCount) or 0) > 0 then
                local referenceAt = tonumber(entry.sentAt) or tonumber(entry.recordedAt) or 0
                if oldestAt == nil or referenceAt < oldestAt then
                    oldestAt = referenceAt
                    oldestKey = key
                end
            end
        end
    end
end

local function shouldSkipDuplicateLocalEcho(self, prefix, message, distribution, sender, target, options)
    if type(options) == "table" and options.localEcho == true then
        return false
    end
    if distribution ~= "CHANNEL" then
        return false
    end

    local localPlayerName = normalizeName and normalizeName(getPlayerName and getPlayerName() or nil) or ""
    local normalizedSender = normalizeName and normalizeName(sender) or tostring(sender or "")
    if localPlayerName == "" or normalizedSender ~= localPlayerName then
        return false
    end

    local key = buildRecentLocalEchoKey(prefix, message, distribution, sender, target)
    local entry = normalizeRecentLocalEchoEntry(self, key)
    if not entry then
        return false
    end

    if entry.sentCount > 0 then
        entry.sentCount = entry.sentCount - 1
    elseif entry.pendingCount > 0 then
        -- If the self-copy arrives before the send-success callback, consume the pending slot.
        entry.pendingCount = entry.pendingCount - 1
    else
        self.RecentLocalEchoes[key] = nil
        return false
    end

    if entry.pendingCount <= 0 and entry.sentCount <= 0 then
        self.RecentLocalEchoes[key] = nil
    end
    return true
end

local function buildSendMetadata(opcode, metadata)
    local details = {}

    for key, value in pairs(metadata or {}) do
        details[key] = value
    end

    details.opcode = tonumber(opcode)
    return details
end

function Comms:GetPacketPayloadLimit(opcode, partCount)
    local chunkToken = Serialization:BuildChunkToken(partCount, partCount)
    local headerPacket = Serialization:SerializePacket(self.Prefix, chunkToken, opcode, "")
    return (tonumber(self.MaxAddonMessageLength) or 255) - #headerPacket
end

function Comms:ResolveChunkPlan(argumentsText, opcode)
    local payloadLength = #(argumentsText or "")
    local optionalCap = tonumber(self.SafeChunkLength)
    if optionalCap ~= nil then
        optionalCap = math.floor(optionalCap)
        if optionalCap < 1 then
            optionalCap = nil
        end
    end

    local partCount = 1
    local seenPartCounts = {}
    while true do
        if seenPartCounts[partCount] then
            return nil
        end
        seenPartCounts[partCount] = true

        local packetPayloadLimit = math.floor(tonumber(self:GetPacketPayloadLimit(opcode, partCount)) or 0)
        if packetPayloadLimit < 1 then
            return nil
        end

        local chunkLength = optionalCap and math.min(packetPayloadLimit, optionalCap) or packetPayloadLimit
        if chunkLength < 1 then
            return nil
        end

        local requiredPartCount = math.max(1, math.ceil(payloadLength / chunkLength))
        if requiredPartCount == partCount then
            return chunkLength, partCount
        end

        partCount = requiredPartCount
    end
end

function Comms:RegisterPrefix()
    if not C_ChatInfo or not C_ChatInfo.RegisterAddonMessagePrefix then
        if Diagnostics.RecordPrefixRegistration then
            Diagnostics:RecordPrefixRegistration(false)
        end
        return false
    end

    C_ChatInfo.RegisterAddonMessagePrefix(self.Prefix)
    if Diagnostics.RecordPrefixRegistration then
        Diagnostics:RecordPrefixRegistration(true)
    end
    return true
end

function Comms:IsPlayerInCurrentGroup(name)
    local normalizedName = normalizeName(name)
    if normalizedName == "" then
        return false
    end

    if normalizedName == getPlayerName() then
        return true
    end

    if getGroupType() == "RAID" then
        local memberCount = GetNumGroupMembers and GetNumGroupMembers() or 0
        for index = 1, memberCount do
            local unitName = GetUnitName and GetUnitName("raid" .. index, true)
            if normalizeName(unitName) == normalizedName then
                return true
            end
        end
    elseif getGroupType() == "PARTY" then
        local memberCount = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for index = 1, memberCount do
            local unitName = GetUnitName and GetUnitName("party" .. index, true)
            if normalizeName(unitName) == normalizedName then
                return true
            end
        end
    end

    return false
end

function Comms:BuildOutboundMessage(opcodeOrPayload, argumentsOrTarget, targetOrMetadata, metadata)
    if type(opcodeOrPayload) == "number" then
        local opcode = opcodeOrPayload
        local argumentsText = type(argumentsOrTarget) == "table"
            and Serialization:SerializeArguments(argumentsOrTarget)
            or tostring(argumentsOrTarget or "")
        return opcode, argumentsText, targetOrMetadata, buildSendMetadata(opcode, metadata)
    end

    local payloadText = tostring(opcodeOrPayload or "")
    local compatibilityMetadata = targetOrMetadata or {}
    local opcode = tonumber(compatibilityMetadata.opcode)
    if not opcode then
        return nil
    end

    return opcode, payloadText, argumentsOrTarget, buildSendMetadata(opcode, compatibilityMetadata)
end

function Comms:SendMessage(distribution, opcodeOrPayload, argumentsOrTarget, targetOrMetadata, metadata)
    local totalStartTime = getTimingNowMilliseconds()
    local opcode, argumentsText, target, diagnosticsMetadata = self:BuildOutboundMessage(
        opcodeOrPayload,
        argumentsOrTarget,
        targetOrMetadata,
        metadata
    )
    local deliveredCallback = type(metadata) == "table" and metadata.onDelivered or nil
    local failedCallback = type(metadata) == "table" and metadata.onFailed or nil

    if not opcode then
        if Diagnostics.RecordSendFailure then
            Diagnostics:RecordSendFailure("missing-opcode")
        end
        return false
    end

    if not MessageQueue or not MessageQueue.EnqueueLogicalMessage or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
        if Diagnostics.RecordSendFailure then
            Diagnostics:RecordSendFailure("missing-api")
        end
        return false
    end

    local timedOpcodeKey = getTimedEventOpcodeKey(opcode)
    local chunkPlanStartTime = timedOpcodeKey and getTimingNowMilliseconds() or nil
    local chunkLength, partCount = self:ResolveChunkPlan(argumentsText, opcode)
    local chunkPlanElapsedMs = chunkPlanStartTime and (getTimingNowMilliseconds() - chunkPlanStartTime) or 0
    if not chunkLength or not partCount then
        if Diagnostics.RecordSendFailure then
            Diagnostics:RecordSendFailure("packet-too-large")
        end
        return false
    end

    if Diagnostics.RecordChunkPlan then
        Diagnostics:RecordChunkPlan(
            diagnosticsMetadata,
            distribution,
            target,
            #argumentsText,
            chunkLength,
            partCount,
            self:GetPacketPayloadLimit(opcode, partCount)
        )
    end

    local packets = {}
    for partIndex = 1, partCount do
        local chunkToken = Serialization:BuildChunkToken(partIndex, partCount)
        local rangeStart = ((partIndex - 1) * chunkLength) + 1
        local rangeEnd = partIndex * chunkLength
        local packet = Serialization:SerializePacket(
            self.Prefix,
            chunkToken,
            opcode,
            string.sub(argumentsText, rangeStart, rangeEnd)
        )

        if #packet > self.MaxAddonMessageLength then
            if Diagnostics.RecordSendFailure then
                Diagnostics:RecordSendFailure("packet-too-large")
            end
            return false
        end
        packets[partIndex] = packet
    end

    local queueCheckStartTime = timedOpcodeKey and getTimingNowMilliseconds() or nil
    if MessageQueue.CanAccept and not MessageQueue:CanAccept(
        partCount,
        diagnosticsMetadata and diagnosticsMetadata.replaceKey or nil,
        self.Prefix,
        opcode,
        distribution,
        target
    ) then
        if Diagnostics.RecordSendFailure then
            Diagnostics:RecordSendFailure("queue-full")
        end
        return false
    end
    local queueCheckElapsedMs = queueCheckStartTime and (getTimingNowMilliseconds() - queueCheckStartTime) or 0

    local localEchoSender = Common.GetPlayerName and Common.GetPlayerName() or (getPlayerName and getPlayerName() or "")
    local sendState = {
        failed = false,
        timedOpcodeKey = timedOpcodeKey,
        totalStartTime = totalStartTime,
        enqueueElapsedMs = 0,
        chunkPlanElapsedMs = chunkPlanElapsedMs,
        queueCheckElapsedMs = queueCheckElapsedMs,
        immediateLocalEcho = shouldDeliverImmediateLocalEcho(distribution, target, opcode),
    }

    if sendState.immediateLocalEcho == true then
        for partIndex = 1, partCount do
            self:ReceiveMessage(
                self.Prefix,
                packets[partIndex],
                distribution,
                localEchoSender,
                target,
                { localEcho = true, immediateLocalEcho = true }
            )
        end
    end

    local function releasePendingImmediateLocalEchoes()
        if sendState.immediateLocalEcho ~= true then
            return
        end
        for partIndex = 1, partCount do
            releasePendingRecentLocalEcho(
                self,
                self.Prefix,
                packets[partIndex],
                distribution,
                localEchoSender,
                target
            )
        end
    end

    local enqueueStartTime = timedOpcodeKey and getTimingNowMilliseconds() or nil
    local queued = MessageQueue:EnqueueLogicalMessage(self.Prefix, opcode, packets, distribution, target, {
        onChunkSent = function(item, packet, result)
            if sendState.failed then
                return
            end

            if sendState.immediateLocalEcho == true then
                markRecentLocalEchoSent(
                    self,
                    self.Prefix,
                    packet,
                    distribution,
                    localEchoSender,
                    target,
                    getTimestamp()
                )
            elseif shouldEchoOutboundChannel(distribution, target) then
                self:ReceiveMessage(
                    self.Prefix,
                    packet,
                    distribution,
                    localEchoSender,
                    target,
                    { localEcho = true }
                )
            end
        end,
        onDelivered = function(item, result)
            if sendState.failed then
                return
            end

            if Diagnostics.RecordSendSuccess then
                Diagnostics:RecordSendSuccess(diagnosticsMetadata, distribution, target, argumentsText, partCount)
            end

            if sendState.timedOpcodeKey then
                local deliveredElapsedMs = getTimingNowMilliseconds() - sendState.totalStartTime
                logTimingParts(
                    ("%s chunks=%d"):format(sendState.timedOpcodeKey, partCount),
                    "event-send",
                    {
                        { label = "chunk-plan", elapsedMs = sendState.chunkPlanElapsedMs },
                        { label = "queue-check", elapsedMs = sendState.queueCheckElapsedMs },
                        { label = "enqueue", elapsedMs = sendState.enqueueElapsedMs },
                    },
                    deliveredElapsedMs,
                    sendState.timedOpcodeKey == "EVENT_UNITS" and 25 or 15
                )
            end

            Common.InvokeCallback(deliveredCallback, item, result)
        end,
        onFailed = function(item, result)
            if sendState.failed then
                return
            end

            sendState.failed = true
            releasePendingImmediateLocalEchoes()
            if result ~= "superseded" and Diagnostics.RecordSendFailure then
                Diagnostics:RecordSendFailure(result)
            end

            Common.InvokeCallback(failedCallback, item, result)
        end,
    }, diagnosticsMetadata)
    if enqueueStartTime then
        sendState.enqueueElapsedMs = getTimingNowMilliseconds() - enqueueStartTime
    end

    if queued == nil then
        releasePendingImmediateLocalEchoes()
    end

    return queued ~= nil
end

function Comms:SendToChannel(channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
    if channelId == nil or channelId == "" then
        return false
    end

    local normalizedChannelId = tonumber(channelId) or channelId
    return self:SendMessage("CHANNEL", opcodeOrPayload, argumentsOrMetadata, normalizedChannelId, metadata)
end

function Comms:FinalizeInbound(packet, distribution, sender, target)
    local timedOpcodeKey = packet and getTimedEventOpcodeKey(packet.opcode) or nil
    local totalStartTime = timedOpcodeKey and getTimingNowMilliseconds() or nil
    local deserializeStartTime = totalStartTime
    local message = {
        prefix = packet.prefix,
        opcode = packet.opcode,
        argumentsText = packet.argumentsText,
        arguments = Serialization:DeserializeArguments(packet.argumentsText),
        distribution = distribution,
        sender = sender,
        target = target,
        chunkCount = packet.partCount,
        receivedAt = getNow(),
    }
    local deserializeElapsedMs = totalStartTime and (getTimingNowMilliseconds() - deserializeStartTime) or 0

    if Diagnostics.RecordInboundMessage then
        Diagnostics:RecordInboundMessage(packet.argumentsText, distribution, sender, target, packet.partCount, packet.opcode)
    end

    local dispatchStartTime = timedOpcodeKey and getTimingNowMilliseconds() or nil
    if Operations.Dispatch then
        Operations:Dispatch(message.opcode, message.arguments, sender, distribution, target, message)
    end
    if timedOpcodeKey then
        local dispatchElapsedMs = getTimingNowMilliseconds() - dispatchStartTime
        logTimingParts(
            ("%s chunks=%d"):format(timedOpcodeKey, math.max(1, tonumber(packet.partCount) or 1)),
            "event-receive",
            {
                { label = "deserialize", elapsedMs = deserializeElapsedMs },
                { label = "dispatch", elapsedMs = dispatchElapsedMs },
            },
            getTimingNowMilliseconds() - totalStartTime,
            timedOpcodeKey == "EVENT_UNITS" and 25 or 15
        )
    end

    return message
end

function Comms:ReceiveMessage(prefix, message, distribution, sender, target, options)
    if prefix ~= self.Prefix then
        return nil
    end

    local now = getTimestamp()
    cleanupRecentLocalEchoes(self, now)
    if shouldSkipDuplicateLocalEcho(self, prefix, message, distribution, sender, target, options) then
        return nil
    end

    if type(options) == "table" and options.localEcho == true then
        recordRecentLocalEcho(
            self,
            prefix,
            message,
            distribution,
            sender,
            target,
            now,
            options.immediateLocalEcho == true
        )
    end

    local packet = Serialization:DeserializePacket(message)
    if not packet or packet.prefix ~= self.Prefix then
        if Diagnostics.RecordInvalidInbound then
            Diagnostics:RecordInvalidInbound(message, distribution, sender)
        end
        return nil
    end

    cleanupIncomingChunks(self, now)

    if packet.partCount == 1 then
        notifyInboundChunkProgress(packet, distribution, sender, target, 1, now * 1000)
        return self:FinalizeInbound(packet, distribution, sender, target)
    end

    local chunkKey = buildInboundChunkKey(sender, packet.opcode)
    local entry = self.IncomingChunks[chunkKey]
    if not entry then
        entry = {
            opcode = packet.opcode,
            partCount = packet.partCount,
            distribution = distribution,
            sender = sender,
            target = target,
            parts = {},
            receivedAt = now,
            startedAtMs = getTimingNowMilliseconds(),
        }
        self.IncomingChunks[chunkKey] = entry
    end

    if entry.partCount ~= packet.partCount then
        self.IncomingChunks[chunkKey] = nil
        if Diagnostics.RecordInvalidInbound then
            Diagnostics:RecordInvalidInbound(message, distribution, sender)
        end
        return nil
    end

    entry.parts[packet.partIndex] = packet.argumentsText
    entry.receivedCount = entry.receivedCount or 0
    if entry._countedParts == nil then
        entry._countedParts = {}
    end
    if not entry._countedParts[packet.partIndex] then
        entry._countedParts[packet.partIndex] = true
        entry.receivedCount = (entry.receivedCount or 0) + 1
    end
    entry.receivedAt = now
    notifyInboundChunkProgress(packet, distribution, sender, target, entry.receivedCount or 0, entry.startedAtMs)

    for index = 1, entry.partCount do
        if entry.parts[index] == nil then
            return nil
        end
    end

    self.IncomingChunks[chunkKey] = nil
    if getTimedEventOpcodeKey(packet.opcode) == "EVENT_UNITS" then
        logTimingParts(
            ("EVENT_UNITS chunks=%d"):format(entry.partCount),
            "event-receive",
            {
                { label = "chunk-assembly", elapsedMs = getTimingNowMilliseconds() - (tonumber(entry.startedAtMs) or 0) },
            },
            getTimingNowMilliseconds() - (tonumber(entry.startedAtMs) or 0),
            25
        )
    end
    return self:FinalizeInbound({
        prefix = packet.prefix,
        opcode = packet.opcode,
        partCount = entry.partCount,
        argumentsText = table.concat(entry.parts, ""),
    }, distribution, sender, target)
end

function Comms:RecordInbound(prefix, message, distribution, sender, target)
    return self:ReceiveMessage(prefix, message, distribution, sender, target)
end
