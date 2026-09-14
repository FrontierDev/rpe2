local _, Addon = ...

Addon.Server = Addon.Server or {}

local Server = Addon.Server
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

local function findEventUnitById(eventState, eventId)
    local numericEventId = math.floor(tonumber(eventId) or 0)
    for index = 1, #(eventState and eventState.units or {}) do
        local unit = eventState.units[index]
        if numericEventId > 0 and tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end
    return nil
end

function Server:HandleEventTurnComplete(arguments, sender)
    local sessionState = type(self.GetState) == "function" and self:GetState() or nil
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or nil
    if type(sessionState) ~= "table" or sessionState.active ~= true or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    if type(arguments) ~= "table"
        or tostring(arguments[1] or "") ~= tostring(sessionState.channelName or "")
        or tostring(arguments[2] or "") ~= tostring(eventState.id or "")
        or tonumber(arguments[4]) ~= tonumber(eventState.turnNumber)
        or tonumber(arguments[5]) ~= tonumber(eventState.tickNumber)
        or not EVENT_TURN_COMPLETE_OPCODE
        or type(Comms.SendToChannel) ~= "function"
    then
        return false
    end

    local eventUnit = findEventUnitById(eventState, arguments[3])
    local expectedSender = normalizeName(eventUnit and (eventUnit.ownerID or eventUnit.name))
    if not eventUnit or eventUnit.isPlayer ~= true or expectedSender == "" or expectedSender ~= normalizeName(sender) then
        return false
    end

    local channelId = sessionState.channelId
    if (channelId == nil or channelId == "") and type(Comms.ResolveChannelId) == "function" then
        channelId = Comms:ResolveChannelId(sessionState.channelName)
    end
    if channelId == nil or channelId == "" then
        return false
    end

    return Comms:SendToChannel(channelId, EVENT_TURN_COMPLETE_OPCODE, {
        sessionState.channelName,
        eventState.id,
        eventUnit.eventID,
        eventState.turnNumber,
        eventState.tickNumber,
        "confirmed",
    }, {
        opcode = EVENT_TURN_COMPLETE_OPCODE,
        scope = "server",
    }) == true
end
