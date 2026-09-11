local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Comms = Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local ResourceSync = Comms.ResourceSync or {}
local Operations = Comms.Operations or {}
local Profile = Addon.Internal.Profile or {}
local Common = Addon.Utils.Common or {}

local CLIENT_CONNECT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("CLIENT_CONNECT") or nil

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

-- The profile resolver may still be cold when a freshly reloaded client sends
-- CLIENT_CONNECT. Warm it before the inner #236 transport wrapper snapshots the
-- local resources. If warming still cannot produce a resource snapshot, the
-- host-side late-join validation remains the final authority and rejects an
-- incomplete new roster insertion.
do
    local baseSendToChannel = Comms.SendToChannel
    if type(baseSendToChannel) == "function" then
        Comms.SendToChannel = function(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
            local opcode = tonumber(opcodeOrPayload)
            if opcode == CLIENT_CONNECT_OPCODE
                and type(ResourceSync.BuildProfileResourceSnapshot) == "function"
                and ResourceSync.BuildProfileResourceSnapshot() == nil
                and type(Profile.WarmResolvedBootstrapState) == "function"
            then
                Profile.WarmResolvedBootstrapState("event-sync-connect")
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
            local eventState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
            if type(eventState) == "table" and eventState.active == true then
                eventState.startupReady = false
                eventState.startupPhase = "syncing"
                if type(self.QueueEventWidgetRefresh) == "function" then
                    self:QueueEventWidgetRefresh("event-syncing")
                end
            end
            return baseRequestEventSyncRepair(self, reason)
        end
    end
end

-- Reject non-host, wrong-channel, or incompatible snapshot envelopes before
-- the main hydration handler can switch EventSyncState to a different event ID.
-- This keeps spoofed/stale traffic from discarding the current revision/buffer.
do
    local baseHandleEventSyncSnapshot = Client.HandleEventSyncSnapshot
    if type(baseHandleEventSyncSnapshot) == "function" then
        function Client:HandleEventSyncSnapshot(payload, sender)
            local sessionState = type(self.GetState) == "function" and self:GetState() or self.State
            if type(sessionState) ~= "table" or sessionState.active ~= true then
                return false
            end
            if normalizeName(sender) == ""
                or normalizeName(sender) ~= normalizeName(sessionState.hostName)
            then
                return false
            end

            if type(EventSync.DeserializeSnapshotEnvelope) == "function" then
                local snapshot = EventSync.DeserializeSnapshotEnvelope(payload)
                if type(snapshot) == "table" then
                    if snapshot.channelName ~= tostring(sessionState.channelName or "")
                        or type(EventSync.IsProtocolCompatible) ~= "function"
                        or EventSync.IsProtocolCompatible(snapshot.protocolVersion) ~= true
                    then
                        return false
                    end
                end
            end
            return baseHandleEventSyncSnapshot(self, payload, sender)
        end
    end
end

return Client
