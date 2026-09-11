local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Server = Addon.Server
local Comms = Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local Common = Addon.Utils.Common or {}
local Debug = Addon.Debug or {}

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function logInternal(message, ...)
    if type(Debug.Internal) == "function" then
        Debug.Internal(message, ...)
    end
end

local function getNowMilliseconds()
    local timings = Debug.Timings
    if type(timings) == "table" and type(timings.GetNowMilliseconds) == "function" then
        return tonumber(timings.GetNowMilliseconds()) or 0
    end
    if type(debugprofilestop) == "function" then
        return tonumber(debugprofilestop()) or 0
    end
    return 0
end

-- A newer repair snapshot supersedes acknowledgements for every older snapshot.
-- Accept an ACK at or beyond the most recently sent snapshot revision because
-- the client may have drained contiguous buffered commits before acknowledging.
do
    local baseHandleEventSyncAck = Server.HandleEventSyncAck
    if type(baseHandleEventSyncAck) == "function" then
        function Server:HandleEventSyncAck(payload, sender)
            local ack = type(EventSync.DeserializeSyncAck) == "function"
                and EventSync.DeserializeSyncAck(payload)
                or nil
            local state = self.State
            local senderName = normalizeName(sender)
            local clientState = type(state) == "table" and type(state.clientsByName) == "table"
                and state.clientsByName[senderName]
                or nil
            if type(ack) == "table" and type(clientState) == "table" then
                local sentEventId = tostring(clientState.eventSyncSnapshotSentEventId or "")
                local sentRevision = tonumber(clientState.eventSyncSnapshotSentRevision)
                if sentEventId ~= "" and tostring(ack.eventId or "") ~= sentEventId then
                    logInternal(
                        "EventSync: rejected stale ACK client=%s event=%s expectedEvent=%s revision=%s.",
                        senderName,
                        tostring(ack.eventId or ""),
                        sentEventId,
                        tostring(ack.appliedRevision or "")
                    )
                    return false
                end
                if sentRevision ~= nil and tonumber(ack.appliedRevision) < sentRevision then
                    logInternal(
                        "EventSync: rejected stale ACK client=%s event=%s revision=%s latestSnapshot=%s.",
                        senderName,
                        tostring(ack.eventId or ""),
                        tostring(ack.appliedRevision or ""),
                        tostring(sentRevision)
                    )
                    return false
                end
            end
            return baseHandleEventSyncAck(self, payload, sender)
        end
    end
end

-- Record coherent snapshot capture/serialization cost without changing the
-- synchronous capture boundary owned by BuildEventSyncSnapshot.
do
    local baseBuildEventSyncSnapshot = Server.BuildEventSyncSnapshot
    if type(baseBuildEventSyncSnapshot) == "function" then
        function Server:BuildEventSyncSnapshot(reason)
            local startedAt = getNowMilliseconds()
            local snapshot, failureReason = baseBuildEventSyncSnapshot(self, reason)
            local elapsedMs = math.max(0, getNowMilliseconds() - startedAt)
            logInternal(
                "EventSync: snapshot capture event=%s revision=%s sections=%s bytes=%s elapsedMs=%.2f reason=%s result=%s.",
                tostring(snapshot and snapshot.eventId or self.EventState and self.EventState.id or ""),
                tostring(snapshot and snapshot.revision or self.EventRuntime and self.EventRuntime.revision or 0),
                tostring(snapshot and snapshot.sectionCount or 0),
                tostring(snapshot and snapshot.byteCount or 0),
                elapsedMs,
                tostring(reason or "rejoin"),
                tostring(snapshot and "ok" or failureReason or "failed")
            )
            return snapshot, failureReason
        end
    end
end

-- Keep repair requests observable at INTERNAL level; the underlying handler
-- still performs all validation and snapshot response work.
do
    local baseHandleEventSyncRequest = Server.HandleEventSyncRequest
    if type(baseHandleEventSyncRequest) == "function" then
        function Server:HandleEventSyncRequest(payload, sender)
            local request = type(EventSync.DeserializeSyncRequest) == "function"
                and EventSync.DeserializeSyncRequest(payload)
                or nil
            local handled = baseHandleEventSyncRequest(self, payload, sender)
            logInternal(
                "EventSync: repair request client=%s event=%s revision=%s reason=%s handled=%s.",
                normalizeName(sender),
                tostring(request and request.eventId or ""),
                tostring(request and request.appliedRevision or 0),
                tostring(request and request.reason or "invalid"),
                tostring(handled == true)
            )
            return handled
        end
    end
end

return Server