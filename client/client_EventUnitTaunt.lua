local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Client = Addon.Client
local Comms = Addon.Internal.Comms
local Operations = Comms.Operations or {}
local EventUnit = Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.EventUnit
    or nil
local EVENT_UNIT_TAUNT_OPCODE = type(Operations.GetOpcode) == "function"
    and Operations:GetOpcode("EVENT_UNIT_TAUNT")
    or nil

local function resolveChannelId(sessionState)
    if type(sessionState) ~= "table" then
        return nil
    end

    local channelId = nil
    if type(sessionState.channelName) == "string"
        and sessionState.channelName ~= ""
        and type(Comms.ResolveChannelId) == "function"
    then
        channelId = Comms:ResolveChannelId(sessionState.channelName)
    end

    if channelId == nil or channelId == "" then
        channelId = sessionState.channelId
    end

    return channelId
end

local function findEventUnit(eventState, eventId)
    local numericEventId = math.floor(tonumber(eventId) or 0)
    if numericEventId <= 0 or type(eventState) ~= "table" then
        return nil
    end

    for index = 1, #(eventState.units or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end

    return nil
end

local function resolveSourceUnit(self, eventState, context)
    local sourceUnit = type(context) == "table" and (
        context.eventSourceUnit
        or context.casterUnit
        or context.caster
        or context.sourceUnit
    ) or nil
    if type(sourceUnit) == "table" then
        return sourceUnit
    end

    local sourceEventId = type(context) == "table" and (
        context.sourceEventId
        or context.casterEventId
        or context.sourceUnitId
    ) or nil
    sourceUnit = findEventUnit(eventState, sourceEventId)
    if sourceUnit then
        return sourceUnit
    end

    if type(self.ResolveLocalEventUnit) == "function" then
        return self:ResolveLocalEventUnit(eventState)
    end

    return nil
end

function Client:SetEventUnitTauntState(context, targetUnit, duration)
    local eventState = type(context) == "table" and context.eventState or nil
    if eventState == nil and type(self.GetEventState) == "function" then
        eventState = self:GetEventState()
    end

    local sessionState = type(context) == "table" and context.sessionState or nil
    if sessionState == nil and type(self.GetState) == "function" then
        sessionState = self:GetState()
    end

    local targetEventId = math.floor(tonumber(type(targetUnit) == "table" and targetUnit.eventID or nil) or 0)
    local normalizedDuration = math.floor(tonumber(duration) or 0)
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(targetUnit) ~= "table"
        or targetUnit.isPlayer == true
        or (EventUnit and type(EventUnit.IsActive) == "function" and not EventUnit.IsActive(targetUnit))
        or targetEventId <= 0
        or normalizedDuration <= 0
        or not EVENT_UNIT_TAUNT_OPCODE
    then
        return false
    end

    local sourceUnit = resolveSourceUnit(self, eventState, context)
    local sourceEventId = math.floor(tonumber(sourceUnit and sourceUnit.eventID) or 0)
    if sourceEventId <= 0 then
        return false
    end

    local channelId = resolveChannelId(sessionState)
    if channelId == nil or channelId == "" or type(Comms.SendToChannel) ~= "function" then
        return false
    end

    return Comms:SendToChannel(channelId, EVENT_UNIT_TAUNT_OPCODE, {
        sessionState.channelName or "",
        eventState.id,
        sourceEventId,
        targetEventId,
        normalizedDuration,
    }, {
        opcode = EVENT_UNIT_TAUNT_OPCODE,
        scope = "client",
    }) == true
end
