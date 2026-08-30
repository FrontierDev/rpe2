local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Internal = Addon.Internal or {}

local EventWidget = Addon.Client.UI.EventWidget
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local EventUnit = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.EventUnit
    or nil

if type(EventWidget) ~= "table"
    or type(EventWidget.BuildPortraitRefreshContext) ~= "function"
    or type(Event) ~= "table"
then
    return
end

local baseBuildPortraitRefreshContext = EventWidget.BuildPortraitRefreshContext

local function normalizeTurnMode(value)
    if type(Event.NormalizeTurnMode) == "function" then
        return Event.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end

local function isBoss(unit)
    if type(EventUnit) == "table" and type(EventUnit.IsBoss) == "function" then
        return EventUnit.IsBoss(unit) == true
    end
    return type(unit) == "table" and unit.boss == true
end

function EventWidget:BuildPortraitRefreshContext(state)
    local context = baseBuildPortraitRefreshContext(self, state)
    if type(context) ~= "table"
        or normalizeTurnMode(state and state.turnMode) ~= "autopilot"
        or type(Event.GetUnitsForTurnStep) ~= "function"
    then
        return context
    end

    local maxEventUnits = math.max(1, math.floor(tonumber(context.maxEventUnits) or 5))
    local stepUnits = Event.GetUnitsForTurnStep(
        state,
        state and state.tickNumber or 1,
        maxEventUnits
    )
    local portraitUnits = {}

    -- Boss portraits retain their existing dedicated row.  The ordinary row
    -- shows only members of the active Autopilot TurnStep.  Oversized actors
    -- remain fully eligible even though the existing portrait pool displays
    -- only the first visual page of that atomic step.
    for index = 1, #stepUnits do
        local unit = stepUnits[index]
        if not isBoss(unit) and #portraitUnits < maxEventUnits then
            portraitUnits[#portraitUnits + 1] = unit
        end
    end

    context.pageUnits = portraitUnits
    return context
end
