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

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", Addon)
end

loadAddonFile("core/internal/comms/ResourceSync.lua")
loadAddonFile("client/client_Resources.lua")

local ResourceSync = Addon.Internal.Comms.ResourceSync
local Client = Addon.Client
local state = {
    active = true,
    channelName = "channel",
    channelId = 9,
    membersByName = {},
    memberOrder = {},
}
local sourceAlice = { eventID = 101, isPlayer = true, name = "Alice" }
local sourceBob = { eventID = 102, isPlayer = true, name = "Bob" }
local sourceNpc = { eventID = 303, isPlayer = false, name = "Totem" }
local targetUnit = {
    eventID = 202,
    isPlayer = false,
    name = "Goblin",
    resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } },
    threatTable = { [101] = 10 },
}
local eventState = {
    id = "event",
    active = true,
    channelName = "channel",
    healthResourceRef = "health",
    turnNumber = 4,
    units = { sourceAlice, sourceBob, sourceNpc, targetUnit },
}

Client.State = state
Client.EventState = eventState
function Client:GetState() return state end
function Client:GetEventState() return eventState end

local meterRecords = {}
local meterRefreshes = 0
local tooltipRevisions = {}
local targetingRefreshes = 0
local structuralRefreshes = 0
Client.EventMeters = {
    RecordThreatUpdate = function(_, _, update)
        local sourceEventId = tonumber(update and update.sourceEventId) or 0
        if sourceEventId == 101 or sourceEventId == 102 then
            meterRecords[#meterRecords + 1] = update
        end
    end,
}
Client.UI = {
    EventWidget = {
        Get = function()
            return {
                IsMetersPanelShown = function() return true end,
                RefreshMetersPanel = function() meterRefreshes = meterRefreshes + 1 end,
            }
        end,
    },
}
Client.PendingSpellTargeting = true
function Client:IsTargetingWidgetVisible() return true end
function Client:InvalidatePendingSpellTargetingDisplayState() end
function Client:QueueTargetingWidgetRefresh() targetingRefreshes = targetingRefreshes + 1 end
function Client:QueueEventWidgetTargetedRefresh() structuralRefreshes = structuralRefreshes + 1 end
Addon.Client.Spellcasting = {
    DescriptionBuilder = {
        BumpEventTooltipContextRevision = function(eventId, targetEventId)
            tooltipRevisions[#tooltipRevisions + 1] = {
                eventId = eventId,
                targetEventId = targetEventId,
            }
        end,
    },
}

local function serializeThreatUpdates(updates)
    local records = {}
    for index = 1, #updates do
        local update = updates[index]
        records[#records + 1] = table.concat({
            tostring(update.targetEventId),
            tostring(update.sourceEventId),
            tostring(update.amount),
            tostring(update.turnNumber or 0),
        }, string.char(29))
    end
    return table.concat(records, string.char(30))
end

local resourcePayload = ResourceSync.SerializeResourceDeltas({
    { resourceRef = "health", delta = 5, maxValue = 100 },
})
local singleThreatPayload = serializeThreatUpdates({
    { targetEventId = 202, sourceEventId = 101, amount = 5, turnNumber = 4 },
    { targetEventId = 202, sourceEventId = 102, amount = 3, turnNumber = 4 },
    { targetEventId = 202, sourceEventId = 303, amount = 4, turnNumber = 4 },
    { targetEventId = 999, sourceEventId = 101, amount = 20, turnNumber = 4 },
    { targetEventId = 101, sourceEventId = 101, amount = 20, turnNumber = 4 },
})

assertTrue(
    Client:HandleResourceDelta({ "channel", "Bob", resourcePayload, 202, singleThreatPayload }, "Bob"),
    "single resource delta with threat is accepted"
)
assertEqual(targetUnit.threatTable[101], 15, "single threat updates the local NPC threat table additively")
assertEqual(targetUnit.threatTable[102], 3, "single threat preserves per-source values")
assertEqual(targetUnit.threatTable[303], 4, "valid non-player sources remain valid transport updates")
assertEqual(targetUnit.resources[1].currentValue, 100, "capped resource delta does not change NPC resources")
assertEqual(#meterRecords, 2, "threat meter retains its player-source display filter")
assertEqual(meterRefreshes, 1, "single threat refreshes the visible threat meter")
assertEqual(#tooltipRevisions, 1, "single threat refreshes the affected tooltip context")
assertEqual(#targetingRefreshes, 1, "single threat refreshes threat-dependent targeting")
assertEqual(structuralRefreshes, 0, "single threat does not queue a structural event widget refresh")

local targetedPayload = ResourceSync.SerializeTargetedResourceDeltas({
    { targetEventId = 202, resourceRef = "health", delta = 5, maxValue = 100 },
})
local batchThreatPayload = serializeThreatUpdates({
    { targetEventId = 202, sourceEventId = 101, amount = 7, turnNumber = 4 },
    { targetEventId = 202, sourceEventId = 102, amount = 4, turnNumber = 4 },
})
assertTrue(
    Client:HandleResourceDeltaBatch({ "channel", "Bob", targetedPayload, batchThreatPayload }, "Bob"),
    "batch resource delta with threat is accepted even when the resource is capped"
)
assertEqual(targetUnit.threatTable[101], 22, "batch threat applies once when the resource delta changes nothing")
assertEqual(targetUnit.threatTable[102], 7, "batch threat applies every source update")
assertEqual(targetUnit.resources[1].currentValue, 100, "batch threat does not overwrite NPC resources")
assertEqual(#meterRecords, 4, "batch threat records player sources in the meter")
assertEqual(meterRefreshes, 2, "batch threat refreshes the visible threat meter")
assertEqual(#tooltipRevisions, 2, "batch threat refreshes the affected tooltip context")
assertEqual(#targetingRefreshes, 2, "batch threat refreshes threat-dependent targeting")
assertEqual(structuralRefreshes, 0, "batch threat does not queue a structural event widget refresh")

targetUnit.threatTable[101] = 40
assertTrue(
    Client:SendClientResourceDeltaBatch(
        state,
        "self-echo",
        nil,
        { { targetEventId = 202, resourceRef = "health", delta = 5, maxValue = 100 } },
        { allowLocalEchoApply = true, threatUpdates = { { targetEventId = 202, sourceEventId = 101, amount = 9 } } }
    ),
    "self-echo batch is sent"
)
assertTrue(
    Client:HandleResourceDeltaBatch(sent[#sent].arguments, "Alice"),
    "self-echo batch is accepted"
)
assertEqual(targetUnit.threatTable[101], 40, "self-echo does not double-add locally computed threat")
assertEqual(#meterRecords, 4, "self-echo does not double-count the threat meter")

local Server = Addon.Server
local serverActiveTarget = {
    eventID = 202,
    isPlayer = false,
    name = "Goblin",
    resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } },
}
local serverDraftTarget = {
    eventID = 202,
    isPlayer = false,
    name = "Goblin",
    resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } },
}
Server.State = {
    active = true,
    channelName = "channel",
    clientsByName = {},
    clientOrder = {},
}
Server.EventState = {
    id = "event",
    units = {
        { eventID = 101, isPlayer = true, name = "Alice" },
        { eventID = 102, isPlayer = true, name = "Bob" },
        serverActiveTarget,
    },
}
Server.EventDraftState = {
    units = {
        { eventID = 101, isPlayer = true, name = "Alice" },
        { eventID = 102, isPlayer = true, name = "Bob" },
        serverDraftTarget,
    },
}
local broadcastCount = 0
function Server:BroadcastEventDeltaBatch() broadcastCount = broadcastCount + 1 end
loadAddonFile("server/server_Session.lua")

local serverSingleThreatPayload = serializeThreatUpdates({
    { targetEventId = 202, sourceEventId = 101, amount = 6, turnNumber = 4 },
})
local serverSingleResourcePayload = ResourceSync.SerializeResourceDeltas({
    { resourceRef = "health", delta = -5, maxValue = 100 },
})
assertTrue(
    Server:HandleResourceDelta(
        { "channel", "Bob", serverSingleResourcePayload, 202, serverSingleThreatPayload },
        "Bob"
    ),
    "server accepts a single resource/threat delta"
)
assertEqual(serverActiveTarget.threatTable[101], 6, "server active state receives single threat")
assertEqual(serverDraftTarget.threatTable[101], 6, "server draft state receives single threat")

local serverBatchThreatPayload = serializeThreatUpdates({
    { targetEventId = 202, sourceEventId = 101, amount = 4, turnNumber = 4 },
    { targetEventId = 202, sourceEventId = 102, amount = 3, turnNumber = 4 },
})
local serverBatchResourcePayload = ResourceSync.SerializeTargetedResourceDeltas({
    { targetEventId = 202, resourceRef = "health", delta = -5, maxValue = 100 },
})
assertTrue(
    Server:HandleResourceDeltaBatch(
        { "channel", "Bob", serverBatchResourcePayload, serverBatchThreatPayload },
        "Bob"
    ),
    "server accepts a batched resource/threat delta"
)
assertEqual(serverActiveTarget.threatTable[101], 10, "server active state receives batched threat")
assertEqual(serverActiveTarget.threatTable[102], 3, "server active state keeps each source threat")
assertEqual(serverDraftTarget.threatTable[101], 10, "server draft state receives batched threat")
assertEqual(serverDraftTarget.threatTable[102], 3, "server draft state keeps each source threat")
assertEqual(broadcastCount, 0, "threat-only server state changes do not broadcast full NPC units")

print("Resource threat peer application tests passed")
