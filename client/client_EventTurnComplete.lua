local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Common = Addon.Utils and Addon.Utils.Common or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local EVENT_TURN_COMPLETE_OPCODE = type(Operations.GetOpcode) == "function" and Operations:GetOpcode("EVENT_TURN_COMPLETE") or nil

local function normalizeName(name)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(name)
    end

    return type(name) == "string" and name or ""
end

local function resolveChannelId(sessionState)
    if type(sessionState) ~= "table" then
        return nil
    end

    if sessionState.channelId ~= nil and sessionState.channelId ~= "" then
        return sessionState.channelId
    end

    if type(Comms.ResolveChannelId) == "function" then
        return Comms:ResolveChannelId(sessionState.channelName)
    end

    return nil
end

function Client:MarkEventUnitTurnComplete(eventId, eventUnitId, turnNumber, tickNumber)
    local numericEventUnitId = math.floor(tonumber(eventUnitId) or 0)
    local numericTurnNumber = math.floor(tonumber(turnNumber) or 0)
    local numericTickNumber = math.floor(tonumber(tickNumber) or 0)
    if tostring(eventId or "") == "" or numericEventUnitId <= 0 or numericTurnNumber <= 0 or numericTickNumber <= 0 then
        return false
    end

    self.EventTurnCompletionMarkers = self.EventTurnCompletionMarkers or {}
    local previous = self.EventTurnCompletionMarkers[numericEventUnitId]
    if type(previous) == "table"
        and tostring(previous.eventId or "") == tostring(eventId)
        and tonumber(previous.turnNumber) == numericTurnNumber
        and tonumber(previous.tickNumber) == numericTickNumber
    then
        return true
    end

    self.EventTurnCompletionMarkers[numericEventUnitId] = {
        eventId = tostring(eventId),
        turnNumber = numericTurnNumber,
        tickNumber = numericTickNumber,
    }

    if type(self.QueueEventWidgetTargetedRefresh) == "function" then
        self:QueueEventWidgetTargetedRefresh("event-turn-complete", { numericEventUnitId })
    elseif type(self.QueueEventWidgetRefresh) == "function" then
        self:QueueEventWidgetRefresh("event-turn-complete")
    end
    return true
end

function Client:IsEventUnitTurnComplete(eventUnit, eventState)
    local eventUnitId = math.floor(tonumber(eventUnit and eventUnit.eventID) or 0)
    local marker = type(self.EventTurnCompletionMarkers) == "table" and self.EventTurnCompletionMarkers[eventUnitId] or nil
    return type(eventState) == "table"
        and eventState.active == true
        and type(marker) == "table"
        and tostring(marker.eventId or "") == tostring(eventState.id or "")
        and tonumber(marker.turnNumber) == tonumber(eventState.turnNumber)
        and tonumber(marker.tickNumber) == tonumber(eventState.tickNumber)
end

function Client:SendEventTurnComplete(eventState, eventUnit)
    local sessionState = type(self.GetState) == "function" and self:GetState() or nil
    local activeEventState = eventState or (type(self.GetEventState) == "function" and self:GetEventState() or nil)
    local eventUnitId = math.floor(tonumber(eventUnit and eventUnit.eventID) or 0)
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(activeEventState) ~= "table"
        or activeEventState.active ~= true
        or eventUnitId <= 0
        or not EVENT_TURN_COMPLETE_OPCODE
        or type(Comms.SendToChannel) ~= "function"
    then
        return false
    end

    local channelId = resolveChannelId(sessionState)
    if channelId == nil or channelId == "" then
        return false
    end

    return Comms:SendToChannel(channelId, EVENT_TURN_COMPLETE_OPCODE, {
        sessionState.channelName or "",
        activeEventState.id,
        eventUnitId,
        activeEventState.turnNumber,
        activeEventState.tickNumber,
    }, {
        opcode = EVENT_TURN_COMPLETE_OPCODE,
        scope = "client",
    }) == true
end

function Client:HandleEventTurnComplete(arguments, sender)
    local sessionState = type(self.GetState) == "function" and self:GetState() or nil
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or nil
    if type(sessionState) ~= "table" or sessionState.active ~= true or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    if type(arguments) ~= "table"
        or arguments[6] ~= "confirmed"
        or tostring(arguments[1] or "") ~= tostring(sessionState.channelName or "")
        or tostring(arguments[2] or "") ~= tostring(eventState.id or "")
        or tonumber(arguments[4]) ~= tonumber(eventState.turnNumber)
        or tonumber(arguments[5]) ~= tonumber(eventState.tickNumber)
        or normalizeName(sender) ~= normalizeName(eventState.hostName)
    then
        return false
    end

    return self:MarkEventUnitTurnComplete(arguments[2], arguments[3], arguments[4], arguments[5])
end
