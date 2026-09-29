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

local Serialization = Addon.Internal.Comms.Serialization
local ThreatUpdates = Addon.Internal.Comms.ThreatUpdates
local Server = Addon.Server
local Selector = Addon.Client.AutopilotTargetSelector

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

local selectionState = assert(Selector.CreateState({
    canCast = true,
    casterUnit = npc,
    eventState = { units = { playerA, playerB, npc } },
    policy = { type = "single", targetDisposition = "enemy", minTargets = 1, maxTargets = 1 },
    targetCandidates = { playerA, playerB },
}, { intent = "hostile" }))
assertTrue(Selector.Step(selectionState), "target selection completes")
assertEqual(Selector.CopyResult(selectionState).primaryTargetEventId, 4, "NPC selects highest-threat player")

-- A local UI state must not mask a malformed transport payload. The outer
-- separator truncates this legacy payload to a single field at the server.
local authoritativeNpc = { eventID = 12, isPlayer = false, threatTable = {} }
Server.EventState = { units = { playerA, authoritativeNpc } }
Server.EventDraftState = { units = { playerA, { eventID = 12, isPlayer = false, threatTable = {} } } }
warnings = {}
local legacyPayload = table.concat({ "12", "3", "40", "2" }, string.char(31))
local corruptedArguments = Serialization:DeserializeArguments(
    Serialization:SerializeArguments({ "channel", "PlayerA", "", legacyPayload })
)
assertTrue(not Server:HandleResourceDeltaBatch(corruptedArguments, "PlayerA"), "malformed nested payload is rejected")
assertEqual(Server.EventState.units[2].threatTable[3], nil, "server did not accept local-only threat")
assertTrue(#warnings > 0, "malformed threat transport is diagnosable")

-- Ordinary resource commits must participate in the same authoritative
-- revision stream as EventUnit deltas, otherwise a missed HP update cannot be
-- repaired at the next event-state boundary.
local resourceTarget = { eventID = 3, isPlayer = true, ownerID = "PlayerA", resources = { health = { currentValue = 10, maxValue = 10 } } }
local resourceDraftTarget = { eventID = 3, isPlayer = true, ownerID = "PlayerA", resources = { health = { currentValue = 10, maxValue = 10 } } }
Addon.Internal.Comms.ResourceSync.CoalesceResourceDeltas = function()
    return { { resourceRef = "health", delta = -4 } }
end
Addon.Internal.Comms.ResourceSync.NormalizeResourceDeltas = function()
    return { { resourceRef = "health", delta = -4 } }
end
Addon.Internal.Comms.ResourceSync.ApplyResourceDeltasToEventUnitByEventID = function(units, eventId, deltas)
    local unit = units and units[1] or nil
    if not unit or tonumber(unit.eventID) ~= tonumber(eventId) then return false end
    unit.resources.health.currentValue = unit.resources.health.currentValue + (tonumber(deltas[1].delta) or 0)
    return true, unit
end
Addon.Internal.Comms.ResourceSync.CloneResources = function(resources) return resources end
Server.State = { active = true, channelName = "channel", clientsByName = {}, clientOrder = {} }
Server.EventState = { active = true, units = { resourceTarget }, liveUnitRevision = 7 }
Server.EventDraftState = { units = { resourceDraftTarget } }
Server.AdvanceLiveUnitRevision = function(self)
    self.EventState.liveUnitRevision = self.EventState.liveUnitRevision + 1
    return self.EventState.liveUnitRevision
end
assertTrue(Server:HandleResourceDelta({ "channel", "PlayerA", "resource", 3 }, "PlayerA"), "server accepts resource delta")
assertEqual(resourceTarget.resources.health.currentValue, 6, "authoritative event HP is committed")
assertEqual(Server.EventState.liveUnitRevision, 8, "authoritative resource commit advances live-unit revision")

Addon.Internal.Comms.ResourceSync.NormalizeResources = function()
    return { { resourceRef = "health", currentValue = 4, maxValue = 10 } }
end
Addon.Internal.Comms.ResourceSync.ApplyResourcesToEventUnitByEventID = function(units, eventId, resources)
    local unit = units and units[1] or nil
    if not unit or tonumber(unit.eventID) ~= tonumber(eventId) then return false end
    unit.resources = resources
    return true
end
assertTrue(Server:HandleResource({ "channel", "PlayerA", "resources", 3 }, "PlayerA"), "server accepts full resource sync")
assertEqual(Server.EventState.liveUnitRevision, 9, "full authoritative resource sync advances live-unit revision")

-- Exercise the real Event Unit delta codec and client application path with a
-- separate remote client runtime. The remote meter must only see the table
-- materialized from the authoritative network delta.
local RemoteAddon = {
    Client = {},
    Server = {},
    Internal = {
        Comms = { Operations = {}, ResourceSync = {} },
        Database = { Classes = {} },
        Tasks = {},
    },
    Utils = { Common = { SplitPreservingEmpty = splitPreservingEmpty } },
}

local function loadRemoteAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, RemoteAddon)
end

loadRemoteAddonFile("core/classes/EventUnit.lua")
loadRemoteAddonFile("core/classes/EventUnitVariantIdentity.lua")
loadRemoteAddonFile("core/classes/Event.lua")
loadRemoteAddonFile("client/client_EventMeters.lua")
loadRemoteAddonFile("client/client_Event.lua")

local RemoteClient = RemoteAddon.Client
local RemoteEventUnit = RemoteAddon.Internal.Database.Classes.EventUnit
local RemoteEvent = RemoteAddon.Internal.Database.Classes.Event
local remotePlayerA = RemoteEventUnit:New({ eventID = 3, isPlayer = true, name = "Player A", team = 1 })
local remotePlayerB = RemoteEventUnit:New({ eventID = 4, isPlayer = true, name = "Player B", team = 1 })
local remoteNpc = RemoteEventUnit:New({ eventID = 12, isPlayer = false, name = "NPC", team = 2, threatTable = {} })
RemoteClient.EventState = {
    id = "event",
    channelName = "channel",
    active = true,
    level = 1,
    difficulty = "normal",
    units = { remotePlayerA, remotePlayerB, remoteNpc },
}
RemoteClient.GetState = function()
    return { active = true, channelName = "channel", membersByName = {} }
end
RemoteClient.IsLocalTurnActive = function()
    return false
end
RemoteClient.PruneCooldownState = function()
    return false
end
RemoteClient.InvalidatePendingSpellTargetingDisplayState = function()
    return false
end
RemoteClient.QueueEventWidgetRefresh = function()
    return true
end
RemoteClient.QueueTargetingWidgetRefresh = function()
    return true
end
RemoteClient.QueueActionBarRefresh = function()
    return true
end

local deltaText = RemoteEvent.SerializeUnitDeltaBatchForNetwork(broadcastEntries)
assertTrue(RemoteClient:HandleEventUnitDeltaBatch({ "channel", "event", deltaText }), "remote client applies Event Unit delta")
assertEqual(remoteNpc.threatTable[3], 40, "remote EventUnit receives player A threat")
assertEqual(remoteNpc.threatTable[4], 250, "remote EventUnit receives player B threat")
local remoteRows = RemoteClient.EventMeters:GetThreatRows(RemoteClient.EventState, 12)
assertEqual(#remoteRows, 2, "remote meter reads the applied Event Unit threat table")
assertEqual(remoteRows[1].eventId, 4, "remote meter ranks authoritative threat")
assertEqual(remoteRows[1].amount, 250, "remote meter receives authoritative total")

RemoteClient.AutopilotPlanner = {}
loadRemoteAddonFile("client/autopilot/PlannerIntegration.lua")
local Planner = RemoteClient.AutopilotPlanner
local frozenState = {
    snapshot = {
        unitsFrozen = true,
        eventState = {
            units = {
                { eventID = 3, isPlayer = true, threatTable = {} },
                { eventID = 12, isPlayer = false, threatTable = { [3] = 40, [4] = 250 } },
            },
        },
    },
    sourceEventState = {
        units = {
            { eventID = 3, isPlayer = true, threatTable = {} },
            { eventID = 12, isPlayer = false, threatTable = { [3] = 40, [4] = 250 } },
        },
    },
}
assertTrue(not Planner.IsFrozenSnapshotStale(frozenState), "matching frozen threat table remains valid")
frozenState.sourceEventState.units[2].threatTable[4] = 251
assertTrue(Planner.IsFrozenSnapshotStale(frozenState), "threat-only change invalidates frozen plan")

print("Threat synchronization tests passed")
