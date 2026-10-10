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

function Autopilot.EvaluateCoordinateCapability(_, unitPositionFn)
    -- Instanced maps can provide valid UnitPosition coordinates.  Probe the
    -- position API instead of rejecting an environment by its instance type.
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
    if normalizedReason == "position-api-unavailable" or normalizedReason == "position-unavailable" then
        return "Position data is unavailable. NPC Autopilot can still run, but spatial movement and melee decisions may be limited."
    end

    return "Spatial positioning is unavailable. NPC Autopilot can still run without spatial actions."
end

function Autopilot.SetEventStartTurnModeContext(value)
    if value == nil then
        Autopilot.EventStartTurnModeContext = nil
    else
        Autopilot.EventStartTurnModeContext = Autopilot.NormalizeTurnMode(value)
    end
    return Autopilot.EventStartTurnModeContext
end

function Autopilot.GetEventStartTurnModeContext()
    if Autopilot.EventStartTurnModeContext == nil then
        return nil
    end
    return Autopilot.NormalizeTurnMode(Autopilot.EventStartTurnModeContext)
end

return Autopilot
