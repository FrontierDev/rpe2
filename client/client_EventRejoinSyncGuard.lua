local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Server = Addon.Server
local Comms = Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local ResourceSync = Comms.ResourceSync or {}
local Operations = Comms.Operations or {}
local Profile = Addon.Internal.Profile or {}
local Common = Addon.Utils.Common or {}
local Debug = Addon.Debug or {}
local Spellcasting = Client.Spellcasting or {}
local AuraManager = Spellcasting.AuraManager or (Addon.Internal and Addon.Internal.AuraManager) or nil

local CLIENT_CONNECT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("CLIENT_CONNECT") or nil
local RESOURCE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE") or nil
local RESOURCE_DELTA_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE_DELTA") or nil
local RESOURCE_DELTA_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("RESOURCE_DELTA_BATCH") or nil

local FOUNDATION_RESOURCE_OPCODES = {
    [RESOURCE_OPCODE or -1] = true,
    [RESOURCE_DELTA_OPCODE or -2] = true,
    [RESOURCE_DELTA_BATCH_OPCODE or -3] = true,
}

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

local function logError(message, ...)
    if type(Debug.Error) == "function" then
        Debug.Error(message, ...)
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

local function getSessionState(client)
    return type(client.GetState) == "function" and client:GetState() or client.State
end

local function getEventState(client)
    return type(client.GetEventState) == "function" and client:GetEventState() or client.EventState
end

local function getSyncState(client, createIfMissing)
    if type(client.GetEventSyncState) == "function" then
        return client:GetEventSyncState(createIfMissing)
    end
    return client.EventSyncState
end

local function markEventSyncing(client, reason)
    local eventState = getEventState(client)
    if type(eventState) == "table" and eventState.active == true then
        eventState.startupReady = false
        eventState.startupPhase = "syncing"
        if type(client.QueueEventWidgetRefresh) == "function" then
            client:QueueEventWidgetRefresh("event-syncing")
        end
    end

    local syncState = getSyncState(client, true)
    if type(syncState) == "table" then
        if type(eventState) == "table" and eventState.active == true then
            local eventId = tostring(eventState.id or "")
            if eventId ~= "" then
                if tostring(syncState.eventId or "") ~= "" and tostring(syncState.eventId or "") ~= eventId then
                    syncState.appliedRevision = 0
                    syncState.bufferedCommits = {}
                end
                syncState.eventId = eventId
            end
        end
        syncState.status = "syncing"
        syncState.reason = tostring(reason or "event-sync")
        syncState.pipelineActive = true
        syncState.repairRequested = false
        syncState.bufferedCommits = syncState.bufferedCommits or {}
    end
    return syncState
end

local function isLocalSessionHost(client)
    local sessionState = getSessionState(client)
    local eventState = getEventState(client)
    local localName = normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or nil)
    local hostName = normalizeName(
        type(eventState) == "table" and eventState.hostName
            or type(sessionState) == "table" and sessionState.hostName
            or nil
    )
    return localName ~= "" and hostName ~= "" and localName == hostName
end

local function cloneResources(resources)
    return type(ResourceSync.CloneResources) == "function"
        and ResourceSync.CloneResources(resources or {})
        or resources or {}
end

local function hydrateSessionMembersFromEvent(client, eventState)
    local sessionState = getSessionState(client)
    if type(sessionState) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return 0
    end

    sessionState.membersByName = sessionState.membersByName or {}
    sessionState.memberOrder = sessionState.memberOrder or {}
    local ordered = {}
    for index = 1, #sessionState.memberOrder do
        ordered[normalizeName(sessionState.memberOrder[index])] = true
    end

    local hydrated = 0
    for index = 1, #(eventState.units or {}) do
        local unit = eventState.units[index]
        if unit and unit.isPlayer == true then
            local owner = normalizeName(unit.ownerID or unit.controllerID or unit.name)
            if owner ~= "" then
                local member = sessionState.membersByName[owner]
                if type(member) ~= "table" then
                    member = {
                        name = owner,
                        joinedAt = type(Common.GetNow) == "function" and Common.GetNow() or 0,
                    }
                    sessionState.membersByName[owner] = member
                end
                if ordered[owner] ~= true then
                    sessionState.memberOrder[#sessionState.memberOrder + 1] = owner
                    ordered[owner] = true
                end
                member.resources = cloneResources(unit.resources)
                hydrated = hydrated + 1
            end
        end
    end
    sessionState.lastResourceSyncEventId = eventState.id
    return hydrated
end

local function isExpectedSnapshotIdentity(client, snapshot)
    local eventId = tostring(snapshot and snapshot.eventId or "")
    local endedEventIds = client.EventSyncEndedEventIds
    if type(endedEventIds) == "table" and endedEventIds[eventId] == true then
        return false
    end

    local eventState = getEventState(client)
    local syncState = getSyncState(client, false)
    local awaitingConnectSnapshot = client.EventSyncAwaitingConnectSnapshot == true

    if type(eventState) == "table" and eventState.active == true then
        if tostring(eventState.id or "") == eventId then
            return true
        end
        return awaitingConnectSnapshot
    end

    if awaitingConnectSnapshot then
        return true
    end

    return type(syncState) == "table"
        and syncState.status == "syncing"
        and syncState.pipelineActive == true
        and tostring(syncState.eventId or "") ~= ""
        and tostring(syncState.eventId or "") == eventId
end

-- The profile resolver may still be cold when a freshly reloaded client sends
-- CLIENT_CONNECT. Warm it before the inner #236 transport wrapper snapshots the
-- local resources. A non-host client with an existing local event is also gated
-- immediately so stale state cannot submit mutations while the host snapshot is
-- in flight.
do
    local baseSendToChannel = Comms.SendToChannel
    if type(baseSendToChannel) == "function" then
        Comms.SendToChannel = function(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
            local opcode = tonumber(opcodeOrPayload)
            if opcode == CLIENT_CONNECT_OPCODE then
                if type(ResourceSync.BuildProfileResourceSnapshot) == "function"
                    and ResourceSync.BuildProfileResourceSnapshot() == nil
                    and type(Profile.WarmResolvedBootstrapState) == "function"
                then
                    Profile.WarmResolvedBootstrapState("event-sync-connect")
                end

                if not isLocalSessionHost(Client) then
                    Client.EventSyncAwaitingConnectSnapshot = true
                    local eventState = getEventState(Client)
                    if type(eventState) == "table" and eventState.active == true then
                        markEventSyncing(Client, "reconnect")
                    end
                end
            elseif opcode and FOUNDATION_RESOURCE_OPCODES[opcode] == true
                and type(metadata) == "table" and metadata.scope == "client"
            then
                local syncState = getSyncState(Client, false)
                if type(syncState) == "table" and syncState.status == "syncing" then
                    logInternal(
                        "EventSync: blocked client resource mutation while syncing opcode=%s event=%s reason=%s.",
                        tostring(opcode),
                        tostring(syncState.eventId or ""),
                        tostring(syncState.reason or "syncing")
                    )
                    return false
                end
            end
            return baseSendToChannel(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
        end
    end
end

-- Repair state is not only an action-legality gate. Mark the current event as
-- visibly syncing so event portraits/actions remain unavailable until a valid
-- snapshot plus any contiguous buffered commits are fully installed.
do
    local baseRequestEventSyncRepair = Client.RequestEventSyncRepair
    if type(baseRequestEventSyncRepair) == "function" then
        function Client:RequestEventSyncRepair(reason)
            markEventSyncing(self, reason or "repair")
            logInternal(
                "EventSync: sync requested event=%s revision=%s reason=%s.",
                tostring(self.EventSyncState and self.EventSyncState.eventId or ""),
                tostring(self.EventSyncState and self.EventSyncState.appliedRevision or 0),
                tostring(reason or "repair")
            )
            return baseRequestEventSyncRepair(self, reason)
        end
    end
end

-- Pending work cleanup is deliberately bounded to transient client work. Keep
-- an INTERNAL trace so failed repair reports can distinguish discarded local
-- work from authoritative snapshot replacement.
do
    local baseAbortPendingEventWork = Client.AbortPendingEventWork
    if type(baseAbortPendingEventWork) == "function" then
        function Client:AbortPendingEventWork(eventId, reason)
            local pendingResourceCount = 0
            for _, batch in pairs(self.PendingResourceDeltaBatches or {}) do
                if type(batch) == "table" and tostring(batch.eventId or "") == tostring(eventId or "") then
                    pendingResourceCount = pendingResourceCount + 1
                end
            end
            local result = baseAbortPendingEventWork(self, eventId, reason)
            logInternal(
                "EventSync: pending work aborted event=%s resources=%d reason=%s.",
                tostring(eventId or ""),
                pendingResourceCount,
                tostring(reason or "event-sync")
            )
            return result
        end
    end
end

-- Reject commits for an absent/different event unless this client has actually
-- sent CLIENT_CONNECT and is awaiting the host's active-event snapshot. This
-- prevents delayed commits from an ended event from manufacturing a repair
-- context which could later accept an equally stale snapshot.
do
    local baseHandleCommittedEventMutation = Client.HandleCommittedEventMutation
    if type(baseHandleCommittedEventMutation) == "function" then
        function Client:HandleCommittedEventMutation(payload, sender)
            local commit = type(EventSync.DeserializeMutationCommit) == "function"
                and EventSync.DeserializeMutationCommit(payload)
                or nil
            if type(commit) == "table" then
                local sessionState = getSessionState(self)
                local eventState = getEventState(self)
                local matchingEvent = type(eventState) == "table"
                    and eventState.active == true
                    and tostring(eventState.id or "") == tostring(commit.eventId or "")
                local trusted = type(sessionState) == "table"
                    and sessionState.active == true
                    and tostring(commit.channelName or "") == tostring(sessionState.channelName or "")
                    and normalizeName(sender) == normalizeName(sessionState.hostName)
                    and type(EventSync.IsProtocolCompatible) == "function"
                    and EventSync.IsProtocolCompatible(commit.protocolVersion) == true
                local endedEventIds = self.EventSyncEndedEventIds
                local ended = type(endedEventIds) == "table" and endedEventIds[tostring(commit.eventId or "")] == true
                if trusted and ended then
                    return true
                end
                if trusted and not matchingEvent and self.EventSyncAwaitingConnectSnapshot ~= true then
                    logInternal(
                        "EventSync: discarded delayed cross-event commit event=%s revision=%s.",
                        tostring(commit.eventId or ""),
                        tostring(commit.revision or "")
                    )
                    return true
                end
            end
            return baseHandleCommittedEventMutation(self, payload, sender)
        end
    end
end

-- Measure only the expensive derived-state pieces when they execute inside
-- snapshot hydration. The main handler still owns all state transitions.
do
    local baseRefreshTraitRuntimeEntries = Client.RefreshTraitRuntimeEntries
    if type(baseRefreshTraitRuntimeEntries) == "function" then
        function Client:RefreshTraitRuntimeEntries(...)
            local startedAt = self.EventSyncHydrationTimingActive == true and getNowMilliseconds() or nil
            local result = baseRefreshTraitRuntimeEntries(self, ...)
            if startedAt then
                self.EventSyncHydrationDerivedMilliseconds = (tonumber(self.EventSyncHydrationDerivedMilliseconds) or 0)
                    + math.max(0, getNowMilliseconds() - startedAt)
            end
            return result
        end
    end

    if type(AuraManager) == "table" then
        local baseRefreshLocalPlayerDerivedState = AuraManager.RefreshLocalPlayerDerivedState
        if type(baseRefreshLocalPlayerDerivedState) == "function" then
            function AuraManager:RefreshLocalPlayerDerivedState(...)
                local startedAt = Client.EventSyncHydrationTimingActive == true and getNowMilliseconds() or nil
                local result = baseRefreshLocalPlayerDerivedState(self, ...)
                if startedAt then
                    Client.EventSyncHydrationDerivedMilliseconds = (tonumber(Client.EventSyncHydrationDerivedMilliseconds) or 0)
                        + math.max(0, getNowMilliseconds() - startedAt)
                end
                return result
            end
        end
    end
end

-- Reject non-host, wrong-channel, incompatible, unsolicited cross-event, or
-- post-end snapshot envelopes before the main hydration handler can switch
-- EventSyncState identity. Expected connect snapshots may replace a stale local
-- event because reconnect can legitimately span an event boundary.
do
    local baseHandleEventSyncSnapshot = Client.HandleEventSyncSnapshot
    if type(baseHandleEventSyncSnapshot) == "function" then
        function Client:HandleEventSyncSnapshot(payload, sender)
            local sessionState = getSessionState(self)
            if type(sessionState) ~= "table" or sessionState.active ~= true then
                return false
            end
            if normalizeName(sender) == ""
                or normalizeName(sender) ~= normalizeName(sessionState.hostName)
            then
                return false
            end

            local snapshot, snapshotReason = nil, "snapshot-codec-unavailable"
            if type(EventSync.DeserializeSnapshotEnvelope) == "function" then
                snapshot, snapshotReason = EventSync.DeserializeSnapshotEnvelope(payload)
            end
            if type(snapshot) ~= "table" then
                local syncState = getSyncState(self, false)
                local expectedMalformed = self.EventSyncAwaitingConnectSnapshot == true
                    or (type(syncState) == "table" and syncState.status == "syncing")
                if not expectedMalformed then
                    return false
                end
            else
                if snapshot.channelName ~= tostring(sessionState.channelName or "")
                    or type(EventSync.IsProtocolCompatible) ~= "function"
                    or EventSync.IsProtocolCompatible(snapshot.protocolVersion) ~= true
                then
                    return false
                end
                if not isExpectedSnapshotIdentity(self, snapshot) then
                    logInternal(
                        "EventSync: discarded delayed cross-event snapshot event=%s revision=%s.",
                        tostring(snapshot.eventId or ""),
                        tostring(snapshot.revision or "")
                    )
                    return true
                end
                markEventSyncing(self, "snapshot-received")
            end

            local startedAt = getNowMilliseconds()
            self.EventSyncHydrationTimingActive = true
            self.EventSyncHydrationDerivedMilliseconds = 0
            local ok, handled = pcall(baseHandleEventSyncSnapshot, self, payload, sender)
            self.EventSyncHydrationTimingActive = false
            local totalMs = math.max(0, getNowMilliseconds() - startedAt)
            local derivedMs = math.max(0, tonumber(self.EventSyncHydrationDerivedMilliseconds) or 0)
            self.EventSyncHydrationDerivedMilliseconds = nil

            if not ok then
                local syncState = markEventSyncing(self, "snapshot-handler-error")
                if type(syncState) == "table" then
                    syncState.repairRequested = false
                end
                logError("EventSync snapshot hydration failed: %s", tostring(handled))
                self:RequestEventSyncRepair("snapshot-handler-error")
                return false
            end

            local eventState = getEventState(self)
            local hydratedMembers = 0
            if handled == true and type(eventState) == "table" and eventState.active == true then
                hydratedMembers = hydrateSessionMembersFromEvent(self, eventState)
            end
            local syncState = getSyncState(self, false)
            if handled == true
                and type(syncState) == "table"
                and syncState.status == "idle"
                and type(eventState) == "table"
                and eventState.active == true
                and eventState.startupReady == true
            then
                self.EventSyncAwaitingConnectSnapshot = false
                if type(self.EventSyncEndedEventIds) == "table" then
                    self.EventSyncEndedEventIds[tostring(eventState.id or "")] = nil
                end
            end

            logInternal(
                "EventSync: hydration result handled=%s event=%s revision=%s totalMs=%.2f derivedMs=%.2f members=%d reason=%s.",
                tostring(handled == true),
                tostring(eventState and eventState.id or snapshot and snapshot.eventId or ""),
                tostring(syncState and syncState.appliedRevision or snapshot and snapshot.revision or 0),
                totalMs,
                derivedMs,
                hydratedMembers,
                tostring(snapshotReason or "")
            )
            return handled
        end
    end
end

-- A genuinely new EVENT_START supersedes a connect-snapshot expectation, but a
-- duplicate start for the same stale event must not. EVENT_END records the ended
-- identity while preserving the expectation that reconnect may return a newer
-- active event snapshot.
do
    local baseHandleEventStart = Client.HandleEventStart
    if type(baseHandleEventStart) == "function" then
        function Client:HandleEventStart(arguments, sender, ...)
            local previousEventId = tostring(self.EventState and self.EventState.id or "")
            local result = baseHandleEventStart(self, arguments, sender, ...)
            local currentEventId = tostring(self.EventState and self.EventState.id or "")
            if result == true and currentEventId ~= "" and currentEventId ~= previousEventId then
                self.EventSyncAwaitingConnectSnapshot = false
                if type(self.EventSyncEndedEventIds) == "table" then
                    self.EventSyncEndedEventIds[currentEventId] = nil
                end
            end
            return result
        end
    end

    local baseHandleEventEnd = Client.HandleEventEnd
    if type(baseHandleEventEnd) == "function" then
        function Client:HandleEventEnd(arguments, ...)
            local eventId = tostring(self.EventState and self.EventState.id or arguments and arguments[2] or "")
            local result = baseHandleEventEnd(self, arguments, ...)
            if result == true and eventId ~= "" then
                self.EventSyncEndedEventIds = self.EventSyncEndedEventIds or {}
                self.EventSyncEndedEventIds[eventId] = true
            end
            return result
        end
    end
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

return Client