local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Profile = Addon.Internal.Profile or {}
local Lookup = Addon.Utils.Lookup or {}
local Movement = RPE and RPE.Core and RPE.Core.Movement or nil

if type(Movement) ~= "table" then
    return
end

local function getAuraManager()
    return Addon.Client
        and Addon.Client.Spellcasting
        and Addon.Client.Spellcasting.AuraManager
        or nil
end

local function resolveMovementStatRef()
    if type(Profile.GetMovementRangeStatRef) == "function" then
        local statRef = Profile.GetMovementRangeStatRef()
        return type(statRef) == "string" and statRef or ""
    end
    return ""
end

function Movement:ResolveEventUnitMovementAllowance(eventState, eventUnit)
    if type(eventUnit) ~= "table" then
        return nil, {
            available = false,
            reason = "event-unit-unavailable",
        }
    end

    local statRef = resolveMovementStatRef()
    local baseValue = nil
    if statRef ~= "" then
        baseValue = tonumber(
            type(Lookup.GetStatValue) == "function"
                and Lookup.GetStatValue(eventUnit, statRef, 0)
                or 0
        ) or 0
    end

    local controlState = nil
    local auraManager = getAuraManager()
    local unitEventId = math.floor(tonumber(eventUnit.eventID) or 0)
    if type(auraManager) == "table"
        and type(auraManager.BuildControlState) == "function"
        and unitEventId > 0
    then
        controlState = auraManager:BuildControlState(eventState, unitEventId)
    end

    local movementRangeOverride = type(controlState) == "table"
        and tonumber(controlState.movementRangeOverride)
        or nil
    local effectiveValue = movementRangeOverride ~= nil and movementRangeOverride or baseValue
    local reason = nil
    if effectiveValue == nil then
        -- The existing local-player movement tracker converts an unavailable
        -- Profile.GetMovementRangeValue() to zero. Preserve that behavior
        -- rather than inventing an Autopilot-specific movement default.
        effectiveValue = 0
        reason = "movement-range-unconfigured"
    end
    effectiveValue = math.max(0, tonumber(effectiveValue) or 0)

    return effectiveValue, {
        available = true,
        reason = reason,
        statRef = statRef,
        baseValue = baseValue,
        movementRangeOverride = movementRangeOverride,
        effectiveValue = effectiveValue,
        controlState = controlState,
    }
end

return Movement
