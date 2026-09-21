local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Utils = Addon.Utils or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Server = Addon.Server
local Common = Addon.Utils.Common or {}
local Comms = Addon.Internal.Comms
local Operations = Comms.Operations or {}
local EVENT_UNIT_TAUNT_APPLIED_OPCODE = type(Operations.GetOpcode) == "function"
    and Operations:GetOpcode("EVENT_UNIT_TAUNT_APPLIED")
    or nil
local EventUnit = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.EventUnit
    or nil

local function normalizeName(name)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(name)
    end

    return type(name) == "string" and name or ""
end

local function findEventUnitById(eventState, eventId)
    local numericEventId = math.floor(tonumber(eventId) or 0)
    if numericEventId <= 0 then
        return nil
    end

    for index = 1, #(eventState and eventState.units or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end

    return nil
end

local function resolveControllingPlayer(eventState, unit)
    if type(unit) ~= "table" then
        return nil
    end

    if unit.isPlayer == true then
        return unit
    end

    local controllerEventId = math.floor(tonumber(unit.controllerID) or 0)
    if controllerEventId <= 0 then
        return nil
    end

    local controller = findEventUnitById(eventState, controllerEventId)
    return type(controller) == "table" and controller.isPlayer == true and controller or nil
end

local function senderControlsUnit(eventState, unit, sender)
    local controller = resolveControllingPlayer(eventState, unit)
    if type(controller) ~= "table" then
        return false
    end

    local expectedSender = normalizeName(controller.ownerID or controller.name)
    local normalizedSender = normalizeName(sender)
    return expectedSender ~= "" and normalizedSender ~= "" and expectedSender == normalizedSender
end

function Server:HandleEventUnitTaunt(arguments, sender)
    local sessionState = type(self.GetState) == "function" and self:GetState() or nil
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or nil
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
    then
        return false
    end

    local channelName = type(arguments) == "table" and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or channelName ~= sessionState.channelName then
        return false
    end

    local eventId = type(arguments) == "table" and arguments[2] or nil
    if type(eventId) ~= "string" or eventId == "" or eventId ~= eventState.id then
        return false
    end

    local sourceEventId = math.floor(tonumber(arguments and arguments[3]) or 0)
    local targetEventId = math.floor(tonumber(arguments and arguments[4]) or 0)
    local remainingTurns = math.floor(tonumber(arguments and arguments[5]) or 0)
    if sourceEventId <= 0 or targetEventId <= 0 or remainingTurns <= 0 then
        return false
    end

    local sourceUnit = findEventUnitById(eventState, sourceEventId)
    local targetUnit = findEventUnitById(eventState, targetEventId)
    if type(sourceUnit) ~= "table"
        or type(targetUnit) ~= "table"
        or not senderControlsUnit(eventState, sourceUnit, sender)
    then
        return false
    end

    if type(self.SetEventTauntRuntimeState) ~= "function" then
        return false
    end

    local accepted, isNewApplication, record = self:SetEventTauntRuntimeState(targetEventId, sourceEventId, remainingTurns)
    if accepted ~= true then
        return false
    end

    if isNewApplication == true and type(record) == "table" then
        local applicationId = math.floor(tonumber(record.applicationId) or 0)
        local sessionState = type(self.GetState) == "function" and self:GetState() or nil
        local channelId = sessionState and sessionState.channelId or nil
        if (channelId == nil or channelId == "") and type(Comms.ResolveChannelId) == "function" then
            channelId = Comms:ResolveChannelId(sessionState and sessionState.channelName or nil)
        end

        local client = Addon.Client
        if client and type(client.HandleEventUnitTauntApplied) == "function" then
            client:HandleEventUnitTauntApplied({
                sessionState and sessionState.channelName or "",
                eventState.id,
                sourceEventId,
                targetEventId,
                applicationId,
                remainingTurns,
            })
        end

        if EVENT_UNIT_TAUNT_APPLIED_OPCODE and channelId and channelId ~= "" and type(Comms.SendToChannel) == "function" then
            Comms:SendToChannel(channelId, EVENT_UNIT_TAUNT_APPLIED_OPCODE, {
                sessionState and sessionState.channelName or "",
                eventState.id,
                sourceEventId,
                targetEventId,
                applicationId,
                remainingTurns,
            }, {
                opcode = EVENT_UNIT_TAUNT_APPLIED_OPCODE,
                scope = "client",
            })
        end
    end

    return true
end
