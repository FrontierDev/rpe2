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

local transactionHandlers = {}
local Addon = {
    Client = {},
    Server = {},
    Debug = {
        Warn = function() end,
    },
    Internal = {
        Comms = {
            Operations = {
                GetOpcode = function()
                    return 1
                end,
            },
            EventTransactions = {
                Server = {
                    Register = function(_, operation, handler)
                        transactionHandlers[operation] = handler
                        return true
                    end,
                },
            },
            ResourceSync = {},
        },
        Registry = {},
        Tasks = {},
    },
    Utils = {
        Common = {
            GetNow = function()
                return 1
            end,
            GetPlayerName = function()
                return "Host"
            end,
            NormalizeName = function(name)
                return tostring(name or "")
            end,
            SplitPreservingEmpty = splitPreservingEmpty,
        },
    },
}

local function cloneResources(resources)
    local result = {}
    for index = 1, #(resources or {}) do
        local resource = resources[index]
        result[index] = {
            resourceRef = resource.resourceRef,
            currentValue = resource.currentValue,
            maxValue = resource.maxValue,
        }
    end
    return result
end

local ResourceSync = Addon.Internal.Comms.ResourceSync
ResourceSync.CloneResources = cloneResources
ResourceSync.CoalesceResourceDeltas = function(resourceDeltas)
    return resourceDeltas or {}
end
ResourceSync.CoalesceTargetedResourceDeltas = function(targetedResourceDeltas)
    return targetedResourceDeltas or {}
end
ResourceSync.ApplyResourceDeltasToEventUnitByEventID = function(units, eventId, deltas)
    local target = nil
    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == tonumber(eventId) then
            target = unit
            break
        end
    end
    if not target then
        return false
    end

    local applied = {}
    for deltaIndex = 1, #(deltas or {}) do
        local delta = deltas[deltaIndex]
        for resourceIndex = 1, #(target.resources or {}) do
            local resource = target.resources[resourceIndex]
            if resource and resource.resourceRef == delta.resourceRef then
                local before = tonumber(resource.currentValue) or 0
                local maximum = tonumber(delta.maxValue or resource.maxValue) or before
                local nextValue = math.max(0, math.min(maximum, before + (tonumber(delta.delta) or 0)))
                resource.currentValue = nextValue
                resource.maxValue = maximum
                applied[#applied + 1] = {
                    resourceRef = delta.resourceRef,
                    delta = nextValue - before,
                    maxValue = maximum,
                    currentValue = nextValue,
                }
                break
            end
        end
    end

    return true, target, applied
end

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("server/server_Session.lua")
loadAddonFile("client/autopilot/TargetSelector.lua")

local Server = Addon.Server
local Selector = Addon.Client.AutopilotTargetSelector
local resourceBatchHandler = transactionHandlers["event-resource-batch"]
assertTrue(type(resourceBatchHandler) == "function", "event resource batch transaction handler is registered")

local first = { targetEventId = 12, sourceEventId = 3, amount = 40, turnNumber = 2 }
local second = { targetEventId = 12, sourceEventId = 4, amount = 250, turnNumber = 2 }
local playerA = {
    eventID = 3,
    isPlayer = true,
    ownerID = "PlayerA",
    name = "Player A",
    team = 1,
    resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } },
}
local playerB = {
    eventID = 4,
    isPlayer = true,
    ownerID = "PlayerB",
    name = "Player B",
    team = 1,
    resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } },
}
local npc = {
    eventID = 12,
    isPlayer = false,
    name = "NPC",
    team = 2,
    resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } },
    threatTable = {},
}
local draftNpc = {
    eventID = 12,
    isPlayer = false,
    name = "NPC",
    team = 2,
    resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } },
    threatTable = {},
}

Server.State = {
    active = true,
    channelName = "channel",
    clientsByName = {
        Host = { name = "Host" },
    },
    clientOrder = { "Host" },
}
Server.EventState = {
    id = "event",
    active = true,
    hostName = "Host",
    channelName = "channel",
    healthResourceRef = "health",
    liveUnitRevision = 7,
    units = { playerA, playerB, npc },
}
Server.EventDraftState = {
    id = "event",
    active = true,
    hostName = "Host",
    channelName = "channel",
    healthResourceRef = "health",
    liveUnitRevision = 7,
    units = { playerA, playerB, draftNpc },
}

local broadcastEntries = nil
Server.BroadcastEventDeltaBatch = function(self, entries)
    broadcastEntries = entries
    self.EventState.liveUnitRevision = (tonumber(self.EventState.liveUnitRevision) or 0) + 1
    return true
end

local terminal = resourceBatchHandler({
    eventId = "event",
    originName = "Host",
    actorEventId = 3,
    input = {
        reason = "threat-sync-regression",
        targetedResourceDeltas = {
            {
                targetEventId = 12,
                resourceRef = "health",
                delta = -1,
                maxValue = 100,
            },
        },
        threatUpdates = { first, second },
    },
}, {
    eventState = Server.EventState,
})

assertEqual(terminal.state, "committed", "transaction commits threat batch")
assertTrue(terminal.outcome.threatChanged == true, "transaction records authoritative threat change")
assertEqual(npc.threatTable[3], 40, "host stores player A threat")
assertEqual(npc.threatTable[4], 250, "host stores player B threat")
assertEqual(draftNpc.threatTable[3], 40, "draft stores player A threat")
assertEqual(draftNpc.threatTable[4], 250, "draft stores player B threat")
assertEqual(npc.resources[1].currentValue, 99, "resource mutation shares the authoritative transaction")
assertEqual(Server.EventState.liveUnitRevision, 8, "transaction advances live-unit revision once")
assertTrue(type(broadcastEntries) == "table" and #broadcastEntries == 1, "host broadcasts one authoritative NPC delta")
assertEqual(broadcastEntries[1].unit.threatTable[4], 250, "authoritative delta carries threat")


local selectionState = assert(Selector.CreateState({
    canCast = true,
    casterUnit = npc,
    eventState = { units = { playerA, playerB, npc } },
    policy = { type = "single", targetDisposition = "enemy", minTargets = 1, maxTargets = 1 },
    targetCandidates = { playerA, playerB },
}, { intent = "hostile" }))
assertTrue(Selector.Step(selectionState), "target selection completes")
assertEqual(Selector.CopyResult(selectionState).primaryTargetEventId, 4, "NPC selects highest-threat player")

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
frozenState.sourceEventState.units[2].threatTable[4] = 250
assertTrue(not Planner.IsFrozenSnapshotStale(frozenState), "restored frozen state remains valid")
frozenState.sourceEventState.units[2].active = false
assertTrue(Planner.IsFrozenSnapshotStale(frozenState), "unit activation change invalidates frozen plan")
frozenState.sourceEventState.units[2].active = true
frozenState.sourceEventState.units[2].hidden = true
assertTrue(Planner.IsFrozenSnapshotStale(frozenState), "unit visibility change invalidates frozen plan")

print("Threat synchronization tests passed")
