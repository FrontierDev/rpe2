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

local acknowledgements = 0
local deltasEmitted = 0
local Addon = {
    Client = {},
    Server = {},
    Internal = {
        Comms = {
            Operations = {
                GetOpcode = function(_, key)
                    return ({ RESOURCE_DELTA = 16, RESOURCE_MUTATION_ACK = 41, RESOURCE_MUTATION_COMMIT = 42 })[key]
                end,
            },
            SendMessage = function(_, _, opcode, arguments)
                if opcode == 41 then
                    acknowledgements = acknowledgements + 1
                    Addon.Client:HandleResourceMutationAck(arguments, "Host")
                end
                return true
            end,
            SendToChannel = function()
                return true
            end,
            ResourceSync = {},
        },
        Database = { Classes = {} },
        Registry = {},
        Tasks = {},
    },
    Utils = {
        Common = {
            GetNow = function() return 0 end,
            GetPlayerName = function() return "Local" end,
            NormalizeName = function(value) return tostring(value or "") end,
        },
    },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

local ResourceSync = Addon.Internal.Comms.ResourceSync
ResourceSync.SerializeResourceDeltas = function() return "damage" end
ResourceSync.NormalizeResourceDeltas = function(payload)
    return payload == "damage" and { { resourceRef = "health", delta = -4 } } or {}
end
ResourceSync.CoalesceResourceDeltas = function(deltas) return deltas end
ResourceSync.CloneResources = function(resources) return resources end
ResourceSync.ApplyResourceDeltasToEventUnitByEventID = function(units, eventId, deltas)
    local unit = units and units[1] or nil
    if not unit or tonumber(unit.eventID) ~= tonumber(eventId) then
        return false
    end
    unit.resources.health.currentValue = unit.resources.health.currentValue + (tonumber(deltas[1].delta) or 0)
    return true, unit
end
ResourceSync.SerializeTargetedResourceDeltas = function() return "committed" end

loadAddonFile("client/client_Resources.lua")
loadAddonFile("server/server_Session.lua")

local Client = Addon.Client
local Server = Addon.Server
local target = {
    eventID = 7,
    isPlayer = true,
    ownerID = "Local",
    resources = { health = { currentValue = 10, maxValue = 10 } },
}
local draftTarget = {
    eventID = 7,
    isPlayer = true,
    ownerID = "Local",
    resources = { health = { currentValue = 10, maxValue = 10 } },
}
local eventState = {
    id = "event",
    active = true,
    channelName = "channel",
    hostName = "Host",
    liveUnitRevision = 4,
    units = { target },
}
local sessionState = {
    active = true,
    channelName = "channel",
    channelId = 1,
    membersByName = {},
}

Client.State = sessionState
Client.GetState = function() return sessionState end
Client.GetEventState = function() return eventState end
Server.State = { active = true, channelName = "channel", channelId = 1, clientsByName = {}, clientOrder = {} }
Server.EventState = eventState
Server.EventDraftState = { units = { draftTarget } }
Server.BroadcastEventDeltaBatch = function(self)
    deltasEmitted = deltasEmitted + 1
    self.EventState.liveUnitRevision = self.EventState.liveUnitRevision + 1
    return true
end

local sends = 0
sessionState._sendToChannel = function(_, _, _, arguments)
    sends = sends + 1
    if sends == 1 then
        return true -- Transport accepted the send, but the server never receives it.
    end
    assertTrue(Server:HandleResourceDelta(arguments, "Local"), "retry reaches the authoritative server")
    return true
end

local sent, mutationId = Client:SendClientResourceDeltas(
    sessionState,
    "reliability-test",
    "Local",
    { { resourceRef = "health", delta = -4 } },
    7
)
assertTrue(sent and mutationId ~= nil, "initial resource command is tracked")
assertEqual(target.resources.health.currentValue, 10, "dropped first command cannot mutate authoritative HP")

local pending = Client.PendingResourceMutations[mutationId]
assertTrue(pending ~= nil, "dropped command remains pending for ACK retry")
assertTrue(Client:ProcessPendingResourceMutations(pending.nextRetryAtMs), "missing ACK retries the same mutation")
assertEqual(sends, 2, "one retry reaches the server")
assertEqual(target.resources.health.currentValue, 6, "authoritative server commits the retried damage")
assertEqual(deltasEmitted, 1, "exactly one authoritative EventUnit delta is emitted")
assertEqual(eventState.liveUnitRevision, 5, "exactly one authoritative revision is advanced")
assertEqual(acknowledgements, 1, "server ACK settles the tracked mutation")
assertEqual(Client.PendingResourceMutations[mutationId], nil, "ACK clears the pending mutation")

return true
