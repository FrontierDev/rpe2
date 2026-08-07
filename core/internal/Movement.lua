local _, Addon = ...

RPE = RPE or {}
RPE.Core = RPE.Core or {}

local Profile = Addon.Internal and Addon.Internal.Profile or {}
local MOVEMENT_POLL_INTERVAL = 1

local Movement = RPE.Core.Movement or {
    isTracking = false,
    isPolling = false,
    totalDistance = 0,
    maxDistance = 0,
    playerX = nil,
    playerY = nil,
    pollToken = 0,
}

RPE.Core.Movement = Movement

local function getMovementRangeValue()
    return type(Profile) == "table"
        and type(Profile.GetMovementRangeValue) == "function"
        and math.max(0, tonumber(Profile.GetMovementRangeValue()) or 0)
        or 0
end

local function getPlayerPosition()
    if type(UnitPosition) ~= "function" then
        return nil, nil
    end

    local x, y = UnitPosition("player")
    return tonumber(x), tonumber(y)
end

function Movement:IsTracking()
    return self.isTracking == true
end

function Movement:GetTraveledDistance()
    return math.max(0, tonumber(self.totalDistance) or 0)
end

function Movement:GetRemainingDistance()
    return math.max(0, (tonumber(self.maxDistance) or 0) - (tonumber(self.totalDistance) or 0))
end

function Movement:NotifyDistanceUpdate()
    if type(self.OnDistanceUpdate) ~= "function" then
        return false
    end

    self:OnDistanceUpdate(self:GetRemainingDistance(), math.max(0, tonumber(self.maxDistance) or 0))
    return true
end

function Movement:RefreshMaxDistance()
    self.maxDistance = getMovementRangeValue()
    return self.maxDistance
end

function Movement:StopPolling()
    self.isPolling = false
    self.pollToken = (tonumber(self.pollToken) or 0) + 1
    return true
end

function Movement:PollDistance(token)
    if token ~= self.pollToken or self.isTracking ~= true then
        self.isPolling = false
        return false
    end

    local nextX, nextY = getPlayerPosition()
    if nextX ~= nil and nextY ~= nil then
        if self.playerX ~= nil and self.playerY ~= nil then
            local dx = nextX - self.playerX
            local dy = nextY - self.playerY
            local delta = math.sqrt((dx * dx) + (dy * dy))
            if delta > 0 then
                self.totalDistance = math.max(0, tonumber(self.totalDistance) or 0) + delta
                if self.totalDistance >= (tonumber(self.maxDistance) or 0) then
                    self.totalDistance = math.max(0, tonumber(self.maxDistance) or 0)
                    self.playerX, self.playerY = nextX, nextY
                    self:NotifyDistanceUpdate()
                    self:EndTracking()
                    return true
                end

                self:NotifyDistanceUpdate()
            end
        end

        self.playerX, self.playerY = nextX, nextY
    end

    if self.isTracking == true and type(C_Timer) == "table" and type(C_Timer.After) == "function" then
        C_Timer.After(MOVEMENT_POLL_INTERVAL, function()
            Movement:PollDistance(token)
        end)
    else
        self.isPolling = false
    end

    return true
end

function Movement:StartPolling()
    if self.isTracking ~= true or self.isPolling == true then
        return false
    end

    self.isPolling = true
    self.pollToken = (tonumber(self.pollToken) or 0) + 1
    self:PollDistance(self.pollToken)
    return true
end

function Movement:HandlePlayerStartedMoving()
    if self.isTracking ~= true then
        return false
    end

    return self:StartPolling()
end

function Movement:HandlePlayerStoppedMoving()
    return self.isTracking == true
end

function Movement:BeginTracking()
    self.totalDistance = 0
    self.playerX, self.playerY = getPlayerPosition()
    self:RefreshMaxDistance()
    self.isTracking = (tonumber(self.maxDistance) or 0) > 0
    self:StopPolling()
    self:NotifyDistanceUpdate()

    if self.isTracking ~= true then
        return false
    end

    self:StartPolling()
    return true
end

function Movement:EndTracking()
    self.isTracking = false
    self:StopPolling()
    return true
end

function Movement:OnPlayerTurnStart()
    return self:BeginTracking()
end

function Movement:OnPlayerTurnEnd()
    return self:EndTracking()
end

local movementObserver = CreateFrame and CreateFrame("Frame") or nil
if movementObserver then
    Movement.Observer = movementObserver
    movementObserver:RegisterEvent("PLAYER_STARTED_MOVING")
    movementObserver:RegisterEvent("PLAYER_STOPPED_MOVING")
    movementObserver:SetScript("OnEvent", function(_, eventName)
        if eventName == "PLAYER_STARTED_MOVING" then
            Movement:HandlePlayerStartedMoving()
        elseif eventName == "PLAYER_STOPPED_MOVING" then
            Movement:HandlePlayerStoppedMoving()
        end
    end)
end

return Movement
