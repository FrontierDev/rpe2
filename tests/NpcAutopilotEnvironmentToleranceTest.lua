local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local savedIsInInstance = IsInInstance
local savedUnitPosition = UnitPosition
local savedGetUnitName = GetUnitName
local savedUnitName = UnitName
local savedGetNumSubgroupMembers = GetNumSubgroupMembers

local Addon = {
    Client = {
        IsLocalEventHost = function() return true end,
        AutopilotPlanner = {},
    },
    Server = {},
    Utils = {
        Common = { GetGroupType = function() return "PARTY" end },
    },
    Internal = {
        Database = {
            Classes = {
                Event = {
                    NormalizeTurnMode = function(value)
                        return value == "autopilot" and "autopilot" or "manual"
                    end,
                    GetUnitsForTurnStep = function(state)
                        return state.units
                    end,
                },
            },
        },
    },
}

local function load(path)
    TestSupport.LoadAddonFile(path, Addon)
end

GetUnitName = function(token)
    return ({ player = "Host", party1 = "Ally" })[token]
end
UnitName = GetUnitName
GetNumSubgroupMembers = function() return 1 end

local nextEventId = 0
function Addon.Server:StartEvent(data)
    nextEventId = nextEventId + 1
    local eventState = {
        id = "autopilot-environment-" .. tostring(nextEventId),
        active = true,
        hostName = "Host",
        turnMode = data.turnMode,
        turnNumber = 1,
        tickNumber = 1,
        units = {
            { eventID = 1, isPlayer = true, name = "Host", active = true },
            { eventID = 2, isPlayer = true, name = "Ally", active = true },
            { eventID = 3, isPlayer = false, name = "NPC", active = true },
        },
    }
    self.EventState = eventState
    return eventState
end

load("core/internal/Autopilot.lua")
load("client/autopilot/Spatial.lua")
load("server/server_EventAutopilot.lua")
load("client/client_Autopilot.lua")

local Client = Addon.Client
local Server = Addon.Server
local Autopilot = Addon.Internal.Autopilot

-- The location type must not override coordinates that are actually valid.
IsInInstance = function() return true, "party" end
UnitPosition = function(token)
    return 12, 24, 0, 501
end

local capable, _, details = Autopilot.EvaluateCoordinateCapability(IsInInstance, UnitPosition)
assertTrue(capable, "an instance with coordinates is spatially usable")
assertEqual(details.instanceID, 501, "instance map ID is preserved")

local inInstanceEvent = Server:StartEvent({ turnMode = "autopilot" })
assertTrue(type(inInstanceEvent) == "table", "NPC Autopilot starts inside an instance")
local instanceRuntime = Client:GetAutopilotSpatialRuntime(inInstanceEvent)
assertEqual(instanceRuntime.status, "ready", "instance does not suspend the entire runtime")
local hostPosition = Client:GetAutopilotPlayerPosition(inInstanceEvent, 1)
assertEqual(hostPosition.x, 12, "host coordinates sampled in an instance")
assertEqual(hostPosition.instanceID, 501, "host instance ID retained")

-- Missing position data should be a per-unit limitation, not an event-start error.
UnitPosition = nil
local noApiEvent = Server:StartEvent({ turnMode = "autopilot" })
assertTrue(type(noApiEvent) == "table", "NPC Autopilot starts without UnitPosition")
local noApiRuntime = Client:GetAutopilotSpatialRuntime(noApiEvent)
assertEqual(noApiRuntime.status, "ready", "missing API does not disable the runtime")
assertEqual(noApiRuntime.playerPositionByEventId[1].reason, "position-api-unavailable", "host position records the limitation")
assertEqual(noApiRuntime.playerPositionByEventId[2].reason, "position-api-unavailable", "party position records the limitation")
assertEqual(Server:GetLastEventStartError(), "", "coordinate failure does not become an event-start failure")

-- A partial sample and a cross-instance member must not prevent other actors
-- or subsequent player-position refreshes from being processed.
UnitPosition = function(token)
    if token == "player" then return 10, 20, 0, 501 end
    return 50, 60, 0, 999
end
local mixedEvent = Server:StartEvent({ turnMode = "autopilot" })
assertTrue(type(mixedEvent) == "table", "event starts despite a mismatched party member")
local mixedRuntime = Client:GetAutopilotSpatialRuntime(mixedEvent)
assertEqual(mixedRuntime.status, "ready", "cross-instance party member does not suspend runtime")
assertEqual(mixedRuntime.playerPositionByEventId[1].available, true, "valid host position remains available")
assertEqual(mixedRuntime.playerPositionByEventId[2].reason, "instance-mismatch", "mismatched party member is isolated")

UnitPosition = function(token)
    return 17, 27, 0, 501
end
local updated, attempted = Client:RefreshAutopilotPlayerPositionsForCompletedStep(mixedEvent, 1, 1)
assertEqual(attempted, 2, "a completed step retries both players")
assertEqual(updated, 2, "recovered party position does not require restarting the event")
assertEqual(mixedRuntime.playerPositionByEventId[2].available, true, "previously unavailable member recovers")
assertEqual(mixedRuntime.status, "ready", "runtime stays ready after recovery")

-- Planner readiness is independent of whether a player's coordinate sample succeeded.
load("client/client_AutopilotPlanner.lua")
local plannerRuntime, plannerReason = Client:GetAutopilotPlannerRuntime(noApiEvent)
assertTrue(type(plannerRuntime) == "table", "planner runtime remains accessible without positions: " .. tostring(plannerReason))
assertEqual(plannerRuntime.status, "ready", "planner runtime stays ready without position API")

IsInInstance = savedIsInInstance
UnitPosition = savedUnitPosition
GetUnitName = savedGetUnitName
UnitName = savedUnitName
GetNumSubgroupMembers = savedGetNumSubgroupMembers

print("NpcAutopilotEnvironmentToleranceTest passed")
