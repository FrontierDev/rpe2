local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Event = Addon.Internal.Database.Classes.Event
if type(Event) ~= "table" then
    return
end

local function normalizeEventMode(value)
    local normalized = string.lower(tostring(value or ""))
    if normalized == "npc" then
        return "npc"
    end
    return "combat"
end

Event.NormalizeEventMode = normalizeEventMode

local baseMerge = Event.Merge
function Event:Merge(data)
    local result = baseMerge and baseMerge(self, data) or self
    if type(data) == "table" and data.eventMode ~= nil then
        self.eventMode = normalizeEventMode(data.eventMode)
    else
        self.eventMode = normalizeEventMode(self.eventMode)
    end
    return result
end

local baseToTable = Event.ToTable
function Event:ToTable()
    local values = baseToTable and baseToTable(self) or {}
    values.eventMode = normalizeEventMode(self.eventMode)
    return values
end

local baseToStartArguments = Event.ToStartArguments
function Event:ToStartArguments(includeUnits)
    local arguments = baseToStartArguments and baseToStartArguments(self, includeUnits) or {}
    arguments[#arguments + 1] = normalizeEventMode(self.eventMode)
    return arguments
end

local baseFromStartArguments = Event.FromStartArguments
function Event.FromStartArguments(arguments)
    local eventState = baseFromStartArguments and baseFromStartArguments(arguments) or Event:New({})
    if type(eventState) == "table" then
        eventState.eventMode = normalizeEventMode(type(arguments) == "table" and arguments[19] or nil)
    end
    return eventState
end

local baseToStateArguments = Event.ToStateArguments
function Event:ToStateArguments()
    local arguments = baseToStateArguments and baseToStateArguments(self) or {}
    arguments[#arguments + 1] = normalizeEventMode(self.eventMode)
    return arguments
end

local baseApplyStateArguments = Event.ApplyStateArguments
local function isEventModeToken(value)
    if type(value) ~= "string" then
        return false
    end
    local normalized = string.lower(value)
    return normalized == "combat" or normalized == "npc"
end

function Event.ApplyStateArguments(eventState, arguments)
    if type(eventState) ~= "table" or type(arguments) ~= "table" then
        return baseApplyStateArguments and baseApplyStateArguments(eventState, arguments) or eventState
    end

    local argumentCount = #arguments
    local modeIndex = argumentCount > 0 and argumentCount or nil
    local eventMode = modeIndex and isEventModeToken(arguments[modeIndex]) and normalizeEventMode(arguments[modeIndex]) or nil
    if eventMode ~= nil then
        -- Keep the base parser's five-field and legacy level-bearing layouts intact.
        local existingArguments = {}
        for index = 1, argumentCount - 1 do
            existingArguments[index] = arguments[index]
        end
        if baseApplyStateArguments then
            baseApplyStateArguments(eventState, existingArguments)
        end
        eventState.eventMode = eventMode
    elseif baseApplyStateArguments then
        baseApplyStateArguments(eventState, arguments)
    end

    eventState.eventMode = normalizeEventMode(eventMode or nil)
    return eventState
end
