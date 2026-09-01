local _, Addon = ...

local Movement = RPE and RPE.Core and RPE.Core.Movement or nil
if type(Movement) ~= "table" or type(Movement.ResolveEventUnitMovementAllowance) ~= "function" then
    return
end

local baseResolveEventUnitMovementAllowance = Movement.ResolveEventUnitMovementAllowance

function Movement:ResolveEventUnitMovementAllowance(eventState, eventUnit)
    local frozen = type(eventUnit) == "table" and eventUnit.__autopilotMovementSnapshot or nil
    if type(frozen) == "table" and frozen.effectiveValue ~= nil then
        local controlState = type(frozen.controlState) == "table" and frozen.controlState or nil
        local reason = tostring(frozen.reason or "")
        local statRef = tostring(frozen.statRef or "")
        local baseStatFound = frozen.baseStatFound
        if baseStatFound == nil then
            baseStatFound = statRef ~= "" and reason ~= "movement-range-stat-missing"
        end
        return math.max(0, tonumber(frozen.effectiveValue) or 0), {
            available = frozen.available ~= false,
            reason = frozen.reason,
            statRef = frozen.statRef,
            baseStatFound = baseStatFound == true,
            baseValue = frozen.baseValue,
            movementRangeOverride = frozen.movementRangeOverride,
            effectiveValue = math.max(0, tonumber(frozen.effectiveValue) or 0),
            controlState = controlState,
            frozen = true,
        }
    end

    return baseResolveEventUnitMovementAllowance(self, eventState, eventUnit)
end

return Movement
