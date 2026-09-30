local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if not value then
        error(message, 2)
    end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local queued = {}
local buildCalls = 0
local Addon = {
    Client = {},
    Internal = {
        Comms = {
            Operations = {
                GetOpcode = function(_, name) return name end,
            },
        },
        Profile = {},
        Ruleset = {},
    },
    Utils = { Common = {} },
}

loadAddonFile("core/internal/comms/ResourceSync.lua", Addon)
local ResourceSync = Addon.Internal.Comms.ResourceSync
ResourceSync.BuildPlayerTurnRegenResourceDeltas = function(resources)
    buildCalls = buildCalls + 1
    return {
        {
            resourceRef = resources[1].resourceRef,
            delta = 5,
            maxValue = resources[1].maxValue,
            currentValue = resources[1].currentValue + 5,
        },
    }
end

loadAddonFile("client/client_Resources.lua", Addon)
local Client = Addon.Client
local state = { active = true, channelName = "channel" }
local eventState = {
    id = "event",
    active = true,
    channelName = "channel",
    turnNumber = 2,
}
local player = {
    eventID = 101,
    isPlayer = true,
    resources = { { resourceRef = "mana", currentValue = 10, maxValue = 100 } },
}
local npc = {
    eventID = 202,
    isPlayer = false,
    resources = { { resourceRef = "health", currentValue = 50, maxValue = 100 } },
}

function Client:ResolveActiveSpellcasterUnit()
    return self.testActiveUnit, nil, self.testControlContext
end
function Client:QueueClientResourceDeltas(_, reason, resourceDeltas, targetEventId, options)
    queued[#queued + 1] = {
        reason = reason,
        resourceDeltas = resourceDeltas,
        targetEventId = targetEventId,
        options = options,
    }
    return true
end

Client.testActiveUnit = player
Client.testControlContext = nil
assertTrue(
    Client:ApplyLocalTurnStartResourceRegeneration(state, eventState),
    "player Event Unit receives automatic turn-start regeneration"
)
assertEqual(buildCalls, 1, "player regeneration calculates resource deltas")
assertEqual(#queued, 1, "player regeneration queues a resource delta")
assertEqual(queued[1].targetEventId, player.eventID, "player regeneration targets the active player")

Client.LastAppliedTurnRegenKey = nil
Client.testActiveUnit = npc
Client.testControlContext = { isControlled = false }
assertEqual(
    Client:ApplyLocalTurnStartResourceRegeneration(state, eventState),
    false,
    "uncontrolled NPC receives no automatic turn-start regeneration"
)
assertEqual(buildCalls, 1, "uncontrolled NPC does not calculate regeneration")
assertEqual(#queued, 1, "uncontrolled NPC does not queue a resource delta")

Client.LastAppliedTurnRegenKey = nil
Client.testControlContext = { isControlled = true }
assertEqual(
    Client:ApplyLocalTurnStartResourceRegeneration(state, eventState),
    false,
    "host-controlled NPC receives no automatic turn-start regeneration"
)
assertEqual(buildCalls, 1, "host-controlled NPC does not calculate regeneration")
assertEqual(#queued, 1, "host-controlled NPC does not queue a resource delta")

local npcResources = {
    { resourceRef = "health", currentValue = 50, maxValue = 100 },
}
local changed, applied = ResourceSync.ApplyResourceDeltasToResources(npcResources, {
    { resourceRef = "health", delta = 10, maxValue = 100 },
})
assertTrue(changed, "explicit NPC resource changes remain applicable")
assertEqual(npcResources[1].currentValue, 60, "explicit NPC resource change updates the resource")
assertEqual(applied[1].delta, 10, "explicit NPC resource change reports the applied delta")

print("Local turn-start resource regeneration tests passed")
