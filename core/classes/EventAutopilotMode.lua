local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Event = Addon.Internal.Database.Classes.Event
local Autopilot = Addon.Internal.Autopilot or {}

if type(Event) ~= "table" then
    return
end

local function normalizeTurnMode(value)
    if type(Autopilot.NormalizeTurnMode) == "function" then
        return Autopilot.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end

Event.NormalizeTurnMode = normalizeTurnMode

local baseMerge = Event.Merge
function Event:Merge(data)
    local result = baseMerge and baseMerge(self, data) or self
    local explicitMode = type(data) == "table" and data.turnMode or nil
    local contextMode = type(Autopilot.GetEventStartTurnModeContext) == "function"
        and Autopilot.GetEventStartTurnModeContext()
        or nil

    if explicitMode ~= nil then
        self.turnMode = normalizeTurnMode(explicitMode)
    elseif self.turnMode ~= nil then
        self.turnMode = normalizeTurnMode(self.turnMode)
    elseif contextMode ~= nil then
        self.turnMode = normalizeTurnMode(contextMode)
    else
        self.turnMode = "manual"
    end

    return result
end

local baseToTable = Event.ToTable
function Event:ToTable()
    local values = baseToTable and baseToTable(self) or {}
    values.turnMode = normalizeTurnMode(self.turnMode)
    return values
end

local baseToStartArguments = Event.ToStartArguments
function Event:ToStartArguments(includeUnits)
    local arguments = baseToStartArguments and baseToStartArguments(self, includeUnits) or {}
    arguments[#arguments + 1] = normalizeTurnMode(self.turnMode)
    return arguments
end

local baseFromStartArguments = Event.FromStartArguments
function Event.FromStartArguments(arguments)
    local eventState = baseFromStartArguments and baseFromStartArguments(arguments) or Event:New({})
    if type(eventState) == "table" then
        eventState.turnMode = normalizeTurnMode(type(arguments) == "table" and arguments[18] or nil)
    end
    return eventState
end
