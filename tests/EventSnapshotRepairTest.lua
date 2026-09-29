local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local sent = {}
local Addon = {
    Client = {},
    Internal = {
        Comms = {
            Operations = {
                GetOpcode = function(_, key)
                    return key == "EVENT_SNAPSHOT_REQUEST" and 91 or nil
                end,
            },
            SendMessage = function(_, distribution, opcode, arguments, target)
                sent[#sent + 1] = { distribution = distribution, opcode = opcode, arguments = arguments, target = target }
                return true
            end,
            ResourceSync = {},
        },
        Database = { Classes = { Event = {}, EventUnit = {} } },
        Runtime = {},
    },
    Utils = {
        Common = {
            NormalizeName = function(value) return tostring(value or "") end,
            GetPlayerName = function() return "Local" end,
        },
    },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("client/client_Event.lua")
loadAddonFile("client/client_Resources.lua")

local Client = Addon.Client
local Event = Addon.Internal.Database.Classes.Event
local eventState = {
    id = "event", channelName = "channel", hostName = "Host", active = true, liveUnitRevision = 1,
    level = 1, difficulty = "normal", units = {
        { eventID = 1, isPlayer = true, ownerID = "Local", resources = { { resourceRef = "health", currentValue = 10, maxValue = 10 } } },
    },
}
Client.EventState = eventState
Client.GetEventState = function() return eventState end
local sessionState = {
    active = true,
    channelName = "channel",
    membersByName = {
        Local = { resources = { { resourceRef = "health", currentValue = 10, maxValue = 10 } } },
    },
}
Client.GetState = function() return sessionState end
Client.IsLocalTurnActive = function() return false end
Client.PruneCooldownState = function() return false end
Client.InvalidatePendingSpellTargetingDisplayState = function() return false end
Client.QueueEventWidgetRefresh = function() return true end
Client.QueueTargetingWidgetRefresh = function() return true end
Client.QueueActionBarRefresh = function() return true end
Event.CountPlayerUnitsInNetwork = function() return 1 end
Event.DeserializeUnitsFromNetwork = function()
    return {
        { eventID = 1, isPlayer = true, ownerID = "Local", resources = { { resourceRef = "health", currentValue = 6, maxValue = 10 } } },
    }
end
Addon.Internal.Comms.ResourceSync.BuildProfileResourceSnapshot = function()
    return { { resourceRef = "health", currentValue = 10, maxValue = 10 } }
end
Addon.Internal.Comms.ResourceSync.CloneResources = function(resources)
    local copy = {}
    for index = 1, #(resources or {}) do
        local entry = resources[index]
        copy[index] = { resourceRef = entry.resourceRef, currentValue = entry.currentValue, maxValue = entry.maxValue }
    end
    return copy
end
Addon.Internal.Comms.ResourceSync.ApplyResourceDeltasToResources = function(resources, deltas)
    for index = 1, #(deltas or {}) do
        if resources[1] and deltas[index].resourceRef == resources[1].resourceRef then
            resources[1].currentValue = math.max(0, resources[1].currentValue + (tonumber(deltas[index].delta) or 0))
        end
    end
    return true
end
Event.ApplyStateArguments = function(state, arguments)
    state.turnNumber = tonumber(arguments[3]) or 0
    state.tickNumber = tonumber(arguments[4]) or 0
    state.totalTicks = tonumber(arguments[5]) or 0
    return state
end

assertEqual(Client:HandleEventState({ "channel", "event", 1, 0, 1, "rpe-live-unit-revision", 4 }), true, "revision mismatch state is accepted")
assertEqual(#sent, 1, "one repair request is emitted")
assertEqual(Client:ProcessEventSnapshotRepair(1500), true, "lost repair request retries after deadline")
assertEqual(#sent, 2, "repair retry is emitted")
assertEqual(sent[2].opcode, 91, "retry uses snapshot repair opcode")
assertEqual(sent[2].arguments[3], 4, "retry preserves requested revision")

assertEqual(Client:HandleEventUnits({ "channel", "event", "snapshot", 4 }), true, "authoritative full snapshot applies")
assertEqual(eventState.units[1].resources[1].currentValue, 6, "authoritative snapshot repairs stale local HP")
assertEqual(sessionState.membersByName.Local.resources[1].currentValue, 6, "authoritative snapshot also repairs local resource cache")
assertEqual(Client.EventSnapshotRepair, nil, "satisfying snapshot clears repair state")

eventState.liveUnitRevision = 5
eventState.units[1].resources[1].currentValue = 5
assertEqual(Client:RequestAuthoritativeEventSnapshot(eventState, 6, "newer-repair", 0), true, "newer repair is tracked")
assertEqual(Client:HandleEventUnits({ "channel", "event", "stale-snapshot", 4 }), true, "stale snapshot is ignored safely")
assertEqual(eventState.liveUnitRevision, 5, "stale snapshot cannot roll back revision")
assertEqual(eventState.units[1].resources[1].currentValue, 5, "stale snapshot cannot roll back HP")
assertEqual(Client.EventSnapshotRepairRequestedRevision, 6, "stale snapshot cannot cancel newer repair")

-- Channel resource commands are not an authority after a revisioned snapshot
-- has been accepted.  A delayed historical delta must therefore be unable to
-- roll the repaired HP backward without producing a revision mismatch.
Client.State = sessionState
eventState.liveUnitRevision = 6
eventState.units[1].resources[1].currentValue = 6
assertEqual(Client:HandleResourceDelta({ "channel", "Remote", "historical-delta", 1 }, "Remote"), true, "late resource command is acknowledged")
assertEqual(eventState.liveUnitRevision, 6, "late resource command cannot alter the authoritative revision")
assertEqual(eventState.units[1].resources[1].currentValue, 6, "late resource command cannot corrupt repaired HP")

-- A mutation remains pending when its first command is lost and resends the
-- same ID at the ACK deadline; the server-side idempotency test covers the
-- corresponding exactly-once commit.
local mutationSendCount = 0
sessionState._sendToChannel = function()
    mutationSendCount = mutationSendCount + 1
    return true
end
Client.PendingResourceMutations = {
    ["resource-retry"] = {
        state = sessionState,
        channelId = 1,
        opcode = 16,
        arguments = { "channel", "Local", "payload", 1, "", "resource-retry" },
        attempts = 1,
        nextRetryAtMs = 0,
    },
}
assertEqual(Client:ProcessPendingResourceMutations(0), true, "lost resource command enters retry processing")
assertEqual(mutationSendCount, 1, "resource retry resends the original mutation")
assertEqual(Client.PendingResourceMutations["resource-retry"].attempts, 2, "resource retry keeps one mutation identity")

-- Reward side effects settle from the server ACK, not the peer resource packet.
local awardedValor, awardedKills, awardedDamage = 0, 0, 0
Client.GrantConfiguredEventCurrency = function()
    awardedValor = awardedValor + 1
    return true
end
Client.Achievements = {
    HandleRPEKill = function() awardedKills = awardedKills + 1 end,
    HandleRPEDamage = function() awardedDamage = awardedDamage + 1 end,
}
eventState.healthResourceRef = "health"
local bossTarget = { eventID = 9, boss = true, team = 2, resources = { { resourceRef = "health", currentValue = 0, maxValue = 10 } } }
Client.PendingRPEKillAchievements = {
    { eventState = eventState, actionOwnerName = "Local", result = { kill = { targetEventId = 9, targetUnit = bossTarget, isBoss = true } }, allowLocalEchoApply = true, scope = "reaction" },
}
Client.PendingRPEHealthAchievements = {
    { eventState = eventState, actionOwnerName = "Local", targetEventId = 9, healthBefore = 10, healthMaxBefore = 10, resourceDeltas = { { resourceRef = "health", delta = -4 } }, result = { targetEventId = 9, targetUnit = bossTarget }, allowLocalEchoApply = true, scope = "reaction" },
}
Client.PendingResourceMutations = {
    ["resource-commit"] = {
        state = sessionState,
        sideEffects = { allowLocalEchoApply = true, scope = "reaction", targetedResourceDeltas = { { targetEventId = 9, resourceRef = "health", delta = -4 } }, targetEventIds = { [9] = true } },
    },
}
assertEqual(Client:HandleResourceMutationAck({ "channel", "resource-commit", 7 }, "Host"), true, "authoritative resource ACK settles queued side effects")
assertEqual(awardedValor, 1, "authoritative boss kill awards Valor once")
assertEqual(awardedKills, 1, "authoritative boss kill advances achievement once")
assertEqual(awardedDamage, 1, "authoritative resource damage advances achievement once")
assertEqual(Client:HandleResourceMutationAck({ "channel", "resource-commit", 7 }, "Host"), true, "duplicate ACK is idempotent")
assertEqual(awardedValor, 1, "duplicate ACK cannot duplicate Valor")
assertEqual(awardedKills, 1, "duplicate ACK cannot duplicate kill progress")
assertEqual(awardedDamage, 1, "duplicate ACK cannot duplicate damage progress")

-- Inbound resource combat text is now driven by the server-authored commit
-- notice, after the corresponding EventUnit revision is authoritative.
local inboundCombatText = 0
Addon.Internal.Comms.ResourceSync.CoalesceTargetedResourceDeltas = function()
    return { { targetEventId = 1, resourceRef = "health", delta = -4 } }
end
Client.Spellcasting = {
    ShowInboundResourceDeltaCombatText = function(_, _, targetUnit, deltas)
        if targetUnit and targetUnit.eventID == 1 and deltas[1].delta == -4 then
            inboundCombatText = inboundCombatText + 1
        end
        return true
    end,
}
assertEqual(Client:HandleAuthoritativeResourceMutationCommit(
    { "channel", "Remote", "committed-damage", "resource-commit-text", 6 },
    "Host"
), true, "server-authored commit is accepted after its authoritative revision")
assertEqual(inboundCombatText, 1, "authoritative resource commit restores inbound combat text")
assertEqual(Client:HandleAuthoritativeResourceMutationCommit(
    { "channel", "Remote", "committed-damage", "resource-commit-text", 6 },
    "Host"
), true, "duplicate server commit is idempotent")
assertEqual(inboundCombatText, 1, "duplicate server commit cannot duplicate inbound combat text")

return true
