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
local Common = Addon.Utils and Addon.Utils.Common or {}
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

function Client:HandleEventUnitTauntApplied(arguments, sender)
    local sessionState = type(self.GetState) == "function" and self:GetState() or nil
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or nil
    local channelName = type(arguments) == "table" and arguments[1] or nil
    local eventId = type(arguments) == "table" and arguments[2] or nil
    local sourceEventId = math.floor(tonumber(arguments and arguments[3]) or 0)
    local targetEventId = math.floor(tonumber(arguments and arguments[4]) or 0)
    local applicationId = math.floor(tonumber(arguments and arguments[5]) or 0)
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or type(channelName) ~= "string"
        or channelName == ""
        or channelName ~= sessionState.channelName
        or tostring(eventId or "") == ""
        or tostring(eventId) ~= tostring(eventState.id or "")
        or sourceEventId <= 0
        or targetEventId <= 0
        or applicationId <= 0
    then
        return false
    end

    local expectedHost = tostring(eventState.hostName or "")
    local normalizedSender = type(Common.NormalizeName) == "function" and Common.NormalizeName(sender) or tostring(sender or "")
    local normalizedHost = type(Common.NormalizeName) == "function" and Common.NormalizeName(expectedHost) or expectedHost
    if normalizedHost ~= "" and normalizedSender ~= "" and normalizedHost ~= normalizedSender then
        return false
    end

    self.EventUnitTauntApplications = self.EventUnitTauntApplications or {}
    local eventApplications = self.EventUnitTauntApplications[eventState.id]
    if type(eventApplications) ~= "table" then
        eventApplications = {}
        self.EventUnitTauntApplications[eventState.id] = eventApplications
    end
    if eventApplications[applicationId] then
        return true
    end

    local sourceUnit = findEventUnit(eventState, sourceEventId)
    local targetUnit = findEventUnit(eventState, targetEventId)
    if type(sourceUnit) ~= "table" or type(targetUnit) ~= "table" then
        return false
    end

    local combat = self.Combat or (Addon.Client and Addon.Client.Combat) or nil
    local events = type(combat) == "table" and combat.Events or nil
    if type(events) ~= "table" or type(events.Run) ~= "function" then
        return false
    end

    eventApplications[applicationId] = true
    local context = {
        eventState = eventState,
        sessionState = sessionState,
        sourceEventId = sourceEventId,
        targetEventIds = { targetEventId },
        sourceUnit = sourceUnit,
        targetUnit = targetUnit,
        eventSourceUnit = sourceUnit,
        eventOtherUnit = targetUnit,
        actionContext = {
            eventState = eventState,
            sessionState = sessionState,
            sourceUnit = sourceUnit,
            targetUnit = targetUnit,
        },
    }
    context.combatEventId = "on_taunt"
    local changed = events:Run(self, context) or false
    context.combatEventId = "on_taunted"
    changed = events:Run(self, context) or changed
    return changed or true
end
