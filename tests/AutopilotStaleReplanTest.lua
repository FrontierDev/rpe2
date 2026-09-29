local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then
        error(message, 2)
    end
end

local scheduled = {}
local Addon = {
    Client = {
        AutopilotPlanner = {
            ResolveActiveNpcStep = function()
                return { actorKey = "npc:12", actorKeys = { "npc:12" }, scheduleRevision = "1" }
            end,
            BuildPlanIdentity = function()
                return "plan:current-step"
            end,
            CreateState = function()
                return { eventId = "event", turnNumber = 1, tickNumber = 0 }
            end,
            Step = function()
                return false
            end,
            ReleaseScratch = function() end,
        },
    },
    Server = {},
    Internal = {
        Database = { Classes = { Event = { NormalizeTurnMode = function() return "autopilot" end } } },
        Tasks = {
            EnqueueSliceable = function(_, definition)
                scheduled[#scheduled + 1] = definition
                return definition
            end,
            CancelScope = function() return 0 end,
        },
        Ruleset = {},
        Autopilot = {},
    },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("client/client_AutopilotPlanner.lua")

local Client = Addon.Client
local eventState = {
    id = "event", active = true, turnMode = "autopilot", turnNumber = 1, tickNumber = 0,
}
Addon.Server.EventState = eventState
Client.IsLocalEventHost = function() return true end
Client.AutopilotRuntimeByEventId = {
    event = { status = "ready", planByStepKey = {}, plannerStatus = "ready" },
}

local firstPlan, started = Client:StartAutopilotStep(eventState)
assertTrue(started, "initial planner job starts")
assertEqual(#scheduled, 1, "one initial planner job is scheduled")
assertEqual(firstPlan.status, "queued", "initial plan is queued")

scheduled[1].onCancel(scheduled[1].state, "stale")
assertEqual(firstPlan.status, "cancelled-stale", "stale planner job is cancelled")
assertEqual(#scheduled, 2, "stale planner cancellation schedules a replacement")
assertEqual(Client.AutopilotRuntimeByEventId.event.plannerStatus, "planning", "replacement planner restores active planning state")

return true
