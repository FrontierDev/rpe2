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

local function splitPreservingEmpty(text, separator, limit)
    local values = {}
    local source = tostring(text or "")
    local startIndex = 1
    while not limit or #values < limit - 1 do
        local separatorIndex = string.find(source, separator, startIndex, true)
        if not separatorIndex then break end
        values[#values + 1] = string.sub(source, startIndex, separatorIndex - 1)
        startIndex = separatorIndex + #separator
    end
    values[#values + 1] = string.sub(source, startIndex)
    return values
end

local warnings = {}
local Addon = {
    Client = {},
    Server = {},
    Debug = {
        Warn = function(message, ...)
            warnings[#warnings + 1] = string.format(message, ...)
        end,
    },
    Internal = {
        Comms = {
            Operations = {
                GetOpcode = function()
                    return 1
                end,
            },
            ResourceSync = {
                CoalesceTargetedResourceDeltas = function()
                    return {}
                end,
            },
        },
        Registry = {},
        Tasks = {},
    },
    Utils = {
        Common = {
            GetNow = function()
                return 1
            end,
            NormalizeName = function(name)
                return tostring(name or "")
            end,
            SplitPreservingEmpty = splitPreservingEmpty,
        },
    },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("core/internal/comms/Serialization.lua")
loadAddonFile("core/internal/comms/ThreatUpdates.lua")
loadAddonFile("server/server_Session.lua")
loadAddonFile("client/autopilot/TargetSelector.lua")
loadAddonFile("client/client_EventMeters.lua")

local Serialization = Addon.Internal.Comms.Serialization
local ThreatUpdates = Addon.Internal.Comms.ThreatUpdates
local Server = Addon.Server
local Selector = Addon.Client.AutopilotTargetSelector
local EventMeters = Addon.Client.EventMeters

local first = { targetEventId = 12, sourceEventId = 3, amount = 40, turnNumber = 2 }
local second = { targetEventId = 12, sourceEventId = 4, amount = 250, turnNumber = 2 }
local payload = assert(ThreatUpdates:Serialize({ first }))
local outer = Serialization:SerializeArguments({ "channel", "PlayerA", "resource", payload })
local outerArguments = Serialization:DeserializeArguments(outer)
assertEqual(#outerArguments, 4, "nested threat payload remains one outer argument")
local decoded = assert(ThreatUpdates:Deserialize(outerArguments[4]))
assertEqual(decoded[1].targetEventId, 12, "round-trip target event id")
assertEqual(decoded[1].sourceEventId, 3, "round-trip source event id")
assertEqual(decoded[1].amount, 40, "round-trip threat amount")
assertEqual(decoded[1].turnNumber, 2, "round-trip turn number")

local batchPayload = assert(ThreatUpdates:Serialize({ first, second }))
local batchOuter = Serialization:SerializeArguments({ "channel", "PlayerA", "resource", batchPayload })
local batchArguments = Serialization:DeserializeArguments(batchOuter)
assertEqual(#batchArguments, 4, "batched threat payload remains one outer argument")
local batchDecoded = assert(ThreatUpdates:Deserialize(batchArguments[4]))
assertEqual(#batchDecoded, 2, "batched threat record count")
assertEqual(batchDecoded[2].sourceEventId, 4, "batched second source")
assertEqual(batchDecoded[2].amount, 250, "batched second amount")

local playerA = { eventID = 3, isPlayer = true, name = "Player A", team = 1 }
local playerB = { eventID = 4, isPlayer = true, name = "Player B", team = 1 }
local npc = { eventID = 12, isPlayer = false, name = "NPC", team = 2, threatTable = {} }
local draftNpc = { eventID = 12, isPlayer = false, name = "NPC", team = 2, threatTable = {} }
Server.State = { active = true, channelName = "channel", clientsByName = {}, clientOrder = {} }
Server.EventState = { units = { playerA, playerB, npc } }
Server.EventDraftState = { units = { playerA, playerB, draftNpc } }
local broadcastEntries = nil
Server.BroadcastEventDeltaBatch = function(_, entries)
    broadcastEntries = entries
    return true
end

assertTrue(Server:HandleResourceDeltaBatch({ "channel", "PlayerA", "", batchPayload }, "PlayerA"), "server accepts valid threat batch")
assertEqual(npc.threatTable[3], 40, "host stores player A threat")
assertEqual(npc.threatTable[4], 250, "host stores player B threat")
assertEqual(draftNpc.threatTable[3], 40, "draft stores player A threat")
assertEqual(draftNpc.threatTable[4], 250, "draft stores player B threat")
assertTrue(type(broadcastEntries) == "table" and #broadcastEntries == 1, "host broadcasts authoritative NPC delta")
assertEqual(broadcastEntries[1].unit.threatTable[4], 250, "remote delta carries authoritative threat")
local remoteNpc = { eventID = 12, isPlayer = false, threatTable = broadcastEntries[1].unit.threatTable }
local remoteRows = EventMeters:GetThreatRows({ id = "event", units = { playerA, playerB, remoteNpc } }, 12)
assertEqual(#remoteRows, 2, "remote meter reads synchronized threat table")
assertEqual(remoteRows[1].eventId, 4, "remote meter ranks highest threat first")
assertEqual(remoteRows[1].amount, 250, "remote meter uses authoritative threat total")

local selectionState = assert(Selector.CreateState({
    canCast = true,
    casterUnit = npc,
    eventState = { units = { playerA, playerB, npc } },
    policy = { type = "single", targetDisposition = "enemy", minTargets = 1, maxTargets = 1 },
    targetCandidates = { playerA, playerB },
}, { intent = "hostile" }))
assertTrue(Selector.Step(selectionState), "target selection completes")
assertEqual(Selector.CopyResult(selectionState).primaryTargetEventId, 4, "NPC selects highest-threat player")

-- A local optimistic mutation must not mask a malformed transport payload. The
-- outer separator truncates this legacy payload to a single field at the server.
local optimisticClientNpc = { eventID = 12, isPlayer = false, threatTable = { [3] = 40 } }
local authoritativeNpc = { eventID = 12, isPlayer = false, threatTable = {} }
Server.EventState = { units = { playerA, authoritativeNpc } }
Server.EventDraftState = { units = { playerA, { eventID = 12, isPlayer = false, threatTable = {} } } }
warnings = {}
local legacyPayload = table.concat({ "12", "3", "40", "2" }, string.char(31))
local corruptedArguments = Serialization:DeserializeArguments(
    Serialization:SerializeArguments({ "channel", "PlayerA", "", legacyPayload })
)
assertTrue(not Server:HandleResourceDeltaBatch(corruptedArguments, "PlayerA"), "malformed nested payload is rejected")
assertEqual(optimisticClientNpc.threatTable[3], 40, "originating client retained optimistic threat")
assertEqual(Server.EventState.units[2].threatTable[3], nil, "server did not accept local-only threat")
assertTrue(#warnings > 0, "malformed threat transport is diagnosable")

print("Threat synchronization tests passed")
