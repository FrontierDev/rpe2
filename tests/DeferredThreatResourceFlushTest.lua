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

local function splitPreservingEmpty(value, separator)
    local result = {}
    local startIndex = 1
    while true do
        local separatorStart, separatorEnd = string.find(value, separator, startIndex, true)
        if not separatorStart then
            result[#result + 1] = string.sub(value, startIndex)
            return result
        end
        result[#result + 1] = string.sub(value, startIndex, separatorStart - 1)
        startIndex = separatorEnd + 1
    end
end

local sent = {}
local Common = {
    GetNow = function() return 1 end,
    GetPlayerName = function() return "Alice" end,
    NormalizeName = function(name) return tostring(name or "") end,
    SplitPreservingEmpty = splitPreservingEmpty,
}
local Operations = {
    GetOpcode = function(_, name) return name end,
}
local Comms = {
    Operations = Operations,
    ResolveChannelId = function(_, channelName) return channelName == "channel" and 9 or nil end,
    SendToChannel = function(_, channelId, opcode, arguments, metadata)
        sent[#sent + 1] = {
            channelId = channelId,
            opcode = opcode,
            arguments = arguments,
            metadata = metadata,
        }
        return true
    end,
}
local Addon = {
    Client = {},
    Server = {},
    Internal = {
        Comms = Comms,
        Database = {},
        Profile = {},
        Ruleset = {},
    },
    Utils = { Common = Common },
}

loadAddonFile("core/internal/comms/ResourceSync.lua", Addon)
loadAddonFile("client/client_Resources.lua", Addon)

local Client = Addon.Client
local state = { active = true, channelName = "channel", channelId = 9 }
local sourceUnit = { eventID = 101, isPlayer = true, name = "Alice" }
local targetUnit = {
    eventID = 202,
    isPlayer = false,
    name = "Goblin",
    resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } },
}
local eventState = {
    id = "event",
    active = true,
    channelName = "channel",
    turnNumber = 4,
    tickNumber = 2,
    units = { sourceUnit, targetUnit },
}

function Client:GetState() return state end
function Client:GetEventState() return eventState end

Client.PendingResourceDeltaBatches = {
    first = {
        state = state,
        channelName = "channel",
        eventId = "event",
        sourceTurnNumber = 4,
        sourceTickNumber = 2,
        targetEventId = 202,
        scope = "turn",
        reason = "attack",
        resourceDeltas = {
            { resourceRef = "health", delta = -10, maxValue = 100, currentValue = 90 },
        },
        threatUpdates = {
            { targetEventId = 202, sourceEventId = 101, amount = 5, turnNumber = 4 },
        },
    },
    second = {
        state = state,
        channelName = "channel",
        eventId = "event",
        sourceTurnNumber = 4,
        sourceTickNumber = 2,
        targetEventId = 202,
        scope = "turn",
        reason = "attack-follow-up",
        resourceDeltas = {
            { resourceRef = "health", delta = -4, maxValue = 100, currentValue = 86 },
        },
        threatUpdates = {
            { targetEventId = 202, sourceEventId = 101, amount = 7, turnNumber = 4 },
        },
    },
}

assertTrue(
    Client:FlushDeferredTurnResourceDeltas(state, eventState, 4, 2),
    "deferred turn resource and threat batch flushes"
)
assertEqual(#sent, 1, "deferred flush sends one coalesced batch")
assertTrue(sent[1].arguments[3] ~= "", "deferred flush transmits resource deltas")
assertEqual(
    sent[1].arguments[4],
    table.concat({ "202", "101", "12", "4" }, string.char(31)),
    "deferred flush coalesces and transmits threat updates"
)
assertEqual(next(Client.PendingResourceDeltaBatches), nil, "sent deferred batches are removed")

local Server = Addon.Server
Server.State = {
    active = true,
    channelName = "channel",
    clientsByName = {},
    clientOrder = {},
}
Server.EventState = eventState
Server.EventDraftState = {
    units = {
        { eventID = 101, isPlayer = true, name = "Alice" },
        { eventID = 202, isPlayer = false, name = "Goblin" },
    },
}
local broadcasts = 0
function Server:BroadcastEventDeltaBatch() broadcasts = broadcasts + 1 end
loadAddonFile("server/server_Session.lua", Addon)

assertTrue(
    Server:HandleResourceDeltaBatch(sent[1].arguments, "Alice"),
    "server accepts the transmitted deferred resource batch"
)
assertEqual(targetUnit.threatTable[101], 12, "server applies deferred threat to the target NPC")
assertTrue(broadcasts > 0, "authoritative threat update is broadcast to other clients")

local reactionBatch = {
    state = state,
    channelName = "channel",
    eventId = "event",
    sourceTurnNumber = 4,
    sourceTickNumber = 2,
    targetEventId = 202,
    scope = "reaction",
    resourceDeltas = {
        { resourceRef = "health", delta = -1, maxValue = 100, currentValue = 85 },
    },
    threatUpdates = {
        { targetEventId = 202, sourceEventId = 101, amount = 3, turnNumber = 4 },
    },
}
Client.PendingResourceDeltaBatches = { reaction = reactionBatch }
Client:FlushDeferredTurnResourceDeltas(state, eventState, 4, 2)
assertEqual(#sent, 1, "turn flush leaves reaction-scoped handling untouched")
assertTrue(Client.PendingResourceDeltaBatches.reaction == reactionBatch, "reaction batch remains pending")

assertTrue(
    Client:SendClientResourceDeltaBatch(
        state,
        "immediate-reaction",
        nil,
        { { targetEventId = 202, resourceRef = "health", delta = -1, maxValue = 100, currentValue = 85 } },
        { threatUpdates = reactionBatch.threatUpdates }
    ),
    "existing immediate resource/threat send path remains available"
)
assertEqual(#sent, 2, "immediate/reaction-scoped send remains unchanged")

print("Deferred threat resource flush tests passed")
