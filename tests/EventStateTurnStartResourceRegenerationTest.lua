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

local localPlayerName = "LocalPlayer"
local localPlayerTick = 2
local queued = {}

local player = {
    eventID = 101,
    isPlayer = true,
    ownerID = localPlayerName,
    active = true,
    resources = { { resourceRef = "mana", currentValue = 10, maxValue = 100 } },
}
local otherPlayer = {
    eventID = 102,
    isPlayer = true,
    ownerID = "OtherPlayer",
    active = true,
    resources = { { resourceRef = "mana", currentValue = 20, maxValue = 100 } },
}
local controlledNpc = {
    eventID = 202,
    isPlayer = false,
    active = true,
    controllerID = player.eventID,
    resources = { { resourceRef = "energy", currentValue = 5, maxValue = 100 } },
}

local eventState = {
    id = "multi-tick-event",
    active = true,
    channelName = "channel",
    turnNumber = 5,
    tickNumber = 1,
    totalTicks = 3,
    startupReady = true,
    unitsReady = true,
    units = { player, otherPlayer, controlledNpc },
}
local sessionState = {
    active = true,
    channelName = "channel",
    membersByName = { [localPlayerName] = true },
}

local Addon = {
    Client = {
        Spellcasting = {
            IsCasterTurnOnTick = function(state, casterEventId)
                return tonumber(casterEventId) == player.eventID
                    and tonumber(state and state.tickNumber) == localPlayerTick
            end,
        },
    },
    Internal = {
        Comms = {
            Operations = {
                GetOpcode = function(_, name) return name end,
            },
        },
        Database = { Classes = { Event = {}, EventUnit = {} } },
        Profile = {},
        Ruleset = {},
        Tasks = {
            Enqueue = function() return true end,
            EnqueueSliceable = function() return {} end,
        },
    },
    Utils = {
        Common = {
            GetPlayerName = function() return localPlayerName end,
            NormalizeName = function(value) return tostring(value or "") end,
        },
    },
}

local Event = Addon.Internal.Database.Classes.Event
function Event.ApplyStateArguments(state, arguments)
    state.turnNumber = tonumber(arguments and arguments[3]) or state.turnNumber or 0
    state.tickNumber = tonumber(arguments and arguments[4]) or state.tickNumber or 0
    state.totalTicks = tonumber(arguments and arguments[5]) or state.totalTicks or 0
end
function Event.IsUnitActive(unit)
    return type(unit) == "table" and unit.active ~= false
end

loadAddonFile("core/internal/comms/ResourceSync.lua", Addon)
local ResourceSync = Addon.Internal.Comms.ResourceSync
ResourceSync.BuildPlayerTurnRegenResourceDeltas = function(resources)
    local resource = resources and resources[1]
    return {
        {
            resourceRef = resource.resourceRef,
            delta = 5,
            maxValue = resource.maxValue,
            currentValue = resource.currentValue + 5,
        },
    }
end

loadAddonFile("client/client_Resources.lua", Addon)
loadAddonFile("client/client_Event.lua", Addon)

local Client = Addon.Client
Client.EventState = eventState
function Client:GetState()
    return sessionState
end
function Client:ResolveActiveSpellcasterUnit(state)
    return self.testActiveUnit, state, { isControlled = self.testActiveUnit == controlledNpc }
end
function Client:IsLocalTurnActive(state)
    return self.testActiveUnit == player
        and self.Spellcasting.IsCasterTurnOnTick(state, player.eventID) == true
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
function Client:QueueEventWidgetRefresh()
    return true
end
function Client:IsEventTransitionCurrent()
    return true
end

Client.testActiveUnit = player
assertTrue(Client:HandleEventState({ "channel", eventState.id, 5, 1, 3 }), "initial event-state snapshot is accepted")
assertEqual(#queued, 0, "a player on a later tick does not regenerate at tick one")

assertTrue(Client:HandleEventState({ "channel", eventState.id, 5, 2, 3 }), "same-turn tick advance is accepted")
assertEqual(#queued, 1, "the local player regenerates when its tick becomes active")
assertEqual(queued[1].targetEventId, player.eventID, "same-turn regeneration targets the local player")
assertEqual(queued[1].options.scope, "turn", "same-turn regeneration uses the turn scope")

assertTrue(Client:HandleEventState({ "channel", eventState.id, 5, 2, 3 }), "duplicate event-state snapshot is accepted")
assertEqual(#queued, 1, "a duplicate snapshot does not queue another regeneration")

localPlayerTick = 3
assertTrue(Client:HandleEventState({ "channel", eventState.id, 5, 3, 3 }), "mid-event tick reorder is accepted")
assertEqual(#queued, 1, "tick reordering does not regenerate the same player twice in one round")

Client.testActiveUnit = controlledNpc
localPlayerTick = 1
assertTrue(Client:HandleEventState({ "channel", eventState.id, 6, 1, 3 }), "next-round NPC-selected snapshot is accepted")
assertEqual(#queued, 2, "a shared tick with a selected NPC still regenerates the local player once")
assertEqual(queued[2].targetEventId, player.eventID, "a selected NPC is never the regeneration target")

assertTrue(Client:HandleEventState({ "channel", eventState.id, 6, 1, 3 }), "duplicate next-round snapshot is accepted")
assertEqual(#queued, 2, "repeated next-round snapshots do not duplicate regeneration")

print("Event-state turn-start resource regeneration tests passed")
