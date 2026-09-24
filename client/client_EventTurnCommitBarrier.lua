local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local OPCODE = type(Operations.GetOpcode) == "function" and Operations:GetOpcode("EVENT_TURN_COMMIT_BARRIER") or nil

local function acknowledge(client, sessionState, eventState, requestId, status)
    if not OPCODE or type(Comms.SendToChannel) ~= "function" then return false end
    local channelId = sessionState and sessionState.channelId
    if (channelId == nil or channelId == "") and type(Comms.ResolveChannelId) == "function" then channelId = Comms:ResolveChannelId(sessionState.channelName) end
    return channelId ~= nil and channelId ~= "" and Comms:SendToChannel(channelId, OPCODE, {
        sessionState.channelName, eventState.id, eventState.turnNumber, eventState.tickNumber, requestId, "ack", status,
    }, { opcode = OPCODE, scope = "client" }) == true
end

function Client:HandleEventTurnCommitBarrierRequest(arguments)
    local sessionState = self.GetState and self:GetState() or nil
    local eventState = self.GetEventState and self:GetEventState() or nil
    local requestId = tostring(arguments and arguments[5] or "")
    if type(sessionState) ~= "table" or sessionState.active ~= true or type(eventState) ~= "table" or eventState.active ~= true
        or tostring(arguments and arguments[1] or "") ~= tostring(sessionState.channelName or "")
        or tostring(arguments and arguments[2] or "") ~= tostring(eventState.id or "")
        or requestId == ""
    then return false end

    if tonumber(arguments[3]) ~= tonumber(eventState.turnNumber) or tonumber(arguments[4]) ~= tonumber(eventState.tickNumber) then
        return acknowledge(self, sessionState, eventState, requestId, "stale")
    end

    self.ForcedTurnCommitBarriers = self.ForcedTurnCommitBarriers or {}
    local previous = self.ForcedTurnCommitBarriers[requestId]
    if type(previous) == "table" then
        if previous.status ~= "pending" then acknowledge(self, sessionState, eventState, requestId, previous.status) end
        return true
    end

    local record = { status = "pending" }
    self.ForcedTurnCommitBarriers[requestId] = record
    local commit = self:FlushPendingTurnChanges(sessionState, eventState, {
        hostAdvancementRequested = true,
        onFinished = function(_, completed)
            record.status = completed == true and "complete" or "failed"
            acknowledge(self, sessionState, eventState, requestId, record.status)
        end,
    })
    if type(commit) ~= "table" then
        record.status = "failed"
        acknowledge(self, sessionState, eventState, requestId, record.status)
    end
    return true
end
