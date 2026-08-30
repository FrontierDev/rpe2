local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil

Client.AutopilotSpatial = Client.AutopilotSpatial or {}
local Spatial = Client.AutopilotSpatial

local function normalizeFiniteNumber(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return nil
    end
    return numeric
end

local function sameInstance(left, right)
    if left == nil or right == nil then
        return left == nil and right == nil
    end
    return tostring(left) == tostring(right)
end

local function isUnitActive(unit)
    if type(Event) == "table" and type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end
    return type(unit) == "table" and (unit.isPlayer == true or unit.active ~= false)
end

local function isPlayerSharedTurnPet(units, unit)
    return type(Event) == "table"
        and type(Event.IsPlayerSharedTurnPet) == "function"
        and Event.IsPlayerSharedTurnPet(units, unit) == true
end

local function newUnavailableActorPosition(actorKey, reason)
    return {
        actorKey = actorKey,
        available = false,
        reason = tostring(reason or "position-unset"),
    }
end

function Spatial.IsFiniteNumber(value)
    return normalizeFiniteNumber(value) ~= nil
end

function Spatial.IsPositionAvailable(position)
    return type(position) == "table"
        and position.available ~= false
        and normalizeFiniteNumber(position.x) ~= nil
        and normalizeFiniteNumber(position.y) ~= nil
end

function Spatial.CopyPosition(position)
    if type(position) ~= "table" then
        return nil
    end

    local copy = {}
    for key, value in pairs(position) do
        copy[key] = value
    end
    return copy
end

function Spatial.Vector2D(fromPosition, toPosition)
    if not Spatial.IsPositionAvailable(fromPosition) or not Spatial.IsPositionAvailable(toPosition) then
        return nil
    end

    return {
        x = (tonumber(toPosition.x) or 0) - (tonumber(fromPosition.x) or 0),
        y = (tonumber(toPosition.y) or 0) - (tonumber(fromPosition.y) or 0),
    }
end

function Spatial.VectorLength2D(vector)
    if type(vector) ~= "table" then
        return nil
    end

    local x = normalizeFiniteNumber(vector.x)
    local y = normalizeFiniteNumber(vector.y)
    if x == nil or y == nil then
        return nil
    end

    return math.sqrt((x * x) + (y * y))
end

function Spatial.Distance2D(leftPosition, rightPosition)
    local vector = Spatial.Vector2D(leftPosition, rightPosition)
    return vector and Spatial.VectorLength2D(vector) or nil
end

function Spatial.DistanceBetweenPositions(leftPosition, rightPosition)
    if not Spatial.IsPositionAvailable(leftPosition) or not Spatial.IsPositionAvailable(rightPosition) then
        return nil, "position-unavailable"
    end
    if leftPosition.instanceID == nil or rightPosition.instanceID == nil then
        return nil, "instance-unavailable"
    end
    if not sameInstance(leftPosition.instanceID, rightPosition.instanceID) then
        return nil, "instance-mismatch"
    end

    return Spatial.Distance2D(leftPosition, rightPosition)
end

function Spatial.GetNpcActorKey(unit)
    if type(unit) ~= "table" or unit.isPlayer == true then
        return nil
    end

    local raidMarker = math.max(0, math.floor(tonumber(unit.raidMarker) or 0))
    if raidMarker > 0 then
        return "marker:" .. tostring(raidMarker)
    end

    local eventId = tonumber(unit.eventID) or 0
    if eventId <= 0 then
        return nil
    end
    return "unit:" .. tostring(eventId)
end

function Spatial.BuildNpcActorKeySet(eventState)
    local units = type(eventState) == "table" and eventState.units or nil
    local keys = {}

    for index = 1, #(units or {}) do
        local unit = units[index]
        if type(unit) == "table"
            and unit.isPlayer ~= true
            and isUnitActive(unit)
            and not isPlayerSharedTurnPet(units, unit)
        then
            local actorKey = Spatial.GetNpcActorKey(unit)
            if actorKey then
                keys[actorKey] = true
            end
        end
    end

    return keys
end

function Spatial.ReconcileVirtualPositions(runtime, eventState)
    if type(runtime) ~= "table" then
        return nil
    end

    local allowedKeys = Spatial.BuildNpcActorKeySet(eventState)
    local previous = type(runtime.positionByActorKey) == "table" and runtime.positionByActorKey or {}
    local nextPositions = {}

    for actorKey in pairs(allowedKeys) do
        local existing = previous[actorKey]
        if type(existing) == "table" then
            existing.actorKey = actorKey
            nextPositions[actorKey] = existing
        else
            nextPositions[actorKey] = newUnavailableActorPosition(actorKey, "position-unset")
        end
    end

    runtime.positionByActorKey = nextPositions
    return nextPositions
end

function Spatial.GetActorPosition(runtime, eventState, actorKey)
    if type(runtime) ~= "table" or type(actorKey) ~= "string" or actorKey == "" then
        return nil, "actor-unavailable"
    end

    Spatial.ReconcileVirtualPositions(runtime, eventState)
    local position = runtime.positionByActorKey and runtime.positionByActorKey[actorKey] or nil
    if type(position) ~= "table" then
        return nil, "actor-unavailable"
    end
    if not Spatial.IsPositionAvailable(position) then
        return nil, tostring(position.reason or "position-unavailable")
    end

    return position
end

function Spatial.GetNpcPosition(runtime, eventState, unit)
    local actorKey = Spatial.GetNpcActorKey(unit)
    if not actorKey then
        return nil, "actor-unavailable"
    end
    return Spatial.GetActorPosition(runtime, eventState, actorKey)
end

function Spatial.SetActorPosition(runtime, eventState, actorKey, position)
    if type(runtime) ~= "table" or type(actorKey) ~= "string" or actorKey == "" then
        return false, "actor-unavailable"
    end

    local x = type(position) == "table" and normalizeFiniteNumber(position.x) or nil
    local y = type(position) == "table" and normalizeFiniteNumber(position.y) or nil
    if x == nil or y == nil then
        return false, "position-unavailable"
    end

    Spatial.ReconcileVirtualPositions(runtime, eventState)
    if type(runtime.positionByActorKey) ~= "table" or runtime.positionByActorKey[actorKey] == nil then
        return false, "actor-unavailable"
    end

    local instanceID = type(position) == "table" and position.instanceID or nil
    if instanceID == nil then
        instanceID = runtime.instanceID
    end
    if instanceID == nil then
        return false, "instance-unavailable"
    end
    if runtime.instanceID ~= nil and not sameInstance(runtime.instanceID, instanceID) then
        return false, "instance-mismatch"
    end
    if runtime.instanceID == nil then
        runtime.instanceID = instanceID
    end

    runtime.positionByActorKey[actorKey] = {
        actorKey = actorKey,
        available = true,
        x = x,
        y = y,
        instanceID = instanceID,
    }
    return true, runtime.positionByActorKey[actorKey]
end

function Spatial.SetNpcPosition(runtime, eventState, unit, position)
    local actorKey = Spatial.GetNpcActorKey(unit)
    if not actorKey then
        return false, "actor-unavailable"
    end
    return Spatial.SetActorPosition(runtime, eventState, actorKey, position)
end

function Spatial.ClearActorPosition(runtime, eventState, actorKey, reason)
    if type(runtime) ~= "table" or type(actorKey) ~= "string" or actorKey == "" then
        return false
    end

    Spatial.ReconcileVirtualPositions(runtime, eventState)
    if type(runtime.positionByActorKey) ~= "table" or runtime.positionByActorKey[actorKey] == nil then
        return false
    end

    runtime.positionByActorKey[actorKey] = newUnavailableActorPosition(actorKey, reason or "position-unset")
    return true
end

function Spatial.AreInstancesEqual(left, right)
    return sameInstance(left, right)
end

return Spatial
