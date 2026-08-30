local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Autopilot = Addon.Internal.Autopilot or {}

local Autopilot = Addon.Internal.Autopilot

local TURN_MODE_MANUAL = "manual"
local TURN_MODE_AUTOPILOT = "autopilot"

Autopilot.TurnMode = Autopilot.TurnMode or {
    Manual = TURN_MODE_MANUAL,
    Autopilot = TURN_MODE_AUTOPILOT,
}

function Autopilot.NormalizeTurnMode(value)
    local normalized = string.lower(tostring(value or ""))
    if normalized == TURN_MODE_AUTOPILOT then
        return TURN_MODE_AUTOPILOT
    end
    return TURN_MODE_MANUAL
end

function Autopilot.EvaluateCoordinateCapability(isInInstanceFn, unitPositionFn)
    if type(isInInstanceFn) == "function" then
        local inInstance, instanceType = isInInstanceFn()
        if inInstance == true then
            return false, "instance", {
                instanceType = tostring(instanceType or ""),
            }
        end
    end

    if type(unitPositionFn) ~= "function" then
        return false, "position-api-unavailable"
    end

    local x, y, z, instanceID = unitPositionFn("player")
    x = tonumber(x)
    y = tonumber(y)
    if x == nil or y == nil then
        return false, "position-unavailable"
    end

    return true, nil, {
        x = x,
        y = y,
        z = tonumber(z) or 0,
        instanceID = tonumber(instanceID) or instanceID,
    }
end

function Autopilot.GetCoordinateCapability()
    return Autopilot.EvaluateCoordinateCapability(IsInInstance, UnitPosition)
end

function Autopilot.GetCapabilityMessage(reason, details)
    local normalizedReason = tostring(reason or "")
    if normalizedReason == "instance" then
        return "NPC Autopilot does not work in instances. Use Manual mode in dungeons, raids, battlegrounds and arenas."
    end
    if normalizedReason == "position-api-unavailable" or normalizedReason == "position-unavailable" then
        return "NPC Autopilot requires outdoor party/raid position data, but position data is unavailable. Use Manual mode."
    end

    return "NPC Autopilot is unavailable. Use Manual mode."
end

function Autopilot.SetEventStartTurnModeContext(value)
    Autopilot.EventStartTurnModeContext = value == nil and nil or Autopilot.NormalizeTurnMode(value)
    return Autopilot.EventStartTurnModeContext
end

function Autopilot.GetEventStartTurnModeContext()
    if Autopilot.EventStartTurnModeContext == nil then
        return nil
    end
    return Autopilot.NormalizeTurnMode(Autopilot.EventStartTurnModeContext)
end

return Autopilot
