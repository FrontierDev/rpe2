local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Internal = Addon.Internal or {}

local Spellcasting = Addon.Client.Spellcasting
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil

if type(Event) ~= "table" or type(Spellcasting.IsCasterTurnOnTick) ~= "function" then
    return
end

local baseIsCasterTurnOnTick = Spellcasting.IsCasterTurnOnTick

local function normalizeTurnMode(value)
    if type(Event.NormalizeTurnMode) == "function" then
        return Event.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end

function Spellcasting.IsCasterTurnOnTick(eventState, casterEventId)
    if normalizeTurnMode(eventState and eventState.turnMode) ~= "autopilot"
        or type(Event.GetUnitTurnStepIndex) ~= "function"
    then
        return baseIsCasterTurnOnTick(eventState, casterEventId)
    end

    local currentTick = math.max(1, math.floor(tonumber(eventState and eventState.tickNumber) or 0))
    local pageSize = type(Spellcasting.GetMaxEventUnits) == "function"
        and Spellcasting.GetMaxEventUnits()
        or 5
    local casterTick = Event.GetUnitTurnStepIndex(eventState, casterEventId, pageSize)
    return casterTick ~= nil and currentTick == casterTick
end
