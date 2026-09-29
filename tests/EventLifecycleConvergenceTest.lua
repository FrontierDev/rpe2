local Harness = dofile("tests/support/IsolationHarness.lua")

local function assertEqual(expected, actual, message)
    assert(expected == actual, (message or "values differ")
        .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function assertTrue(value, message)
    assert(value == true, message or "expected true")
end

local world = Harness.New()
local host = world:AddHost("Host")
local playerA = world:AddClient("PlayerA")
local playerB = world:AddClient("PlayerB")

local function startEvent(eventId, revision)
    world:StartEvent({
        id = eventId,
        active = true,
        channelName = "RPE-Lifecycle",
        channelId = "RPE-Lifecycle",
        liveUnitRevision = revision or 0,
        units = {
            { eventID = 1, isPlayer = true, ownerID = "PlayerA", health = 100 },
            { eventID = 2, isPlayer = true, ownerID = "PlayerB", health = 100 },
        },
    })
end

local function register(opcode, handler)
    for _, node in ipairs(world.nodes) do
        node:RegisterOperation(opcode, function(arguments, sender, distribution, target, message)
            return handler(node, arguments, sender, distribution, target, message)
        end, "lifecycle-test-" .. tostring(opcode))
    end
end

local function findUnit(state, eventUnitId)
    for index = 1, #((state and state.units) or {}) do
        if tonumber(state.units[index].eventID) == tonumber(eventUnitId) then
            return state.units[index]
        end
    end
    return nil
end

local function revisionOf(state)
    return math.max(0, math.floor(tonumber(state and state.liveUnitRevision) or 0))
end

-- These handlers model the existing Event revision transport at the router
-- boundary. They deliberately keep identity and monotonicity in the receiver,
-- which is the same ownership contract used by production Event handlers.
register(201, function(node, arguments, sender)
    local state = node.EventState
    local eventId = tostring(arguments and arguments[1] or "")
    local revision = tonumber(arguments and arguments[2]) or 0
    if type(state) ~= "table" or state.id ~= eventId or revision <= revisionOf(state) then
        return false
    end
    state.liveUnitRevision = revision
    return true
end)
register(202, function(node, arguments, sender)
    local state = node.EventState
    local eventId = tostring(arguments and arguments[1] or "")
    local revision = tonumber(arguments and arguments[2]) or 0
    if type(state) ~= "table" or state.id ~= eventId or revision < revisionOf(state) then
        return false
    end
    state.liveUnitRevision = revision
    local unit = findUnit(state, 2)
    if unit then
        unit.health = arguments[3]
        unit.hidden = arguments[4]
        unit.active = arguments[5]
        unit.threat = arguments[6]
    end
    return true
end)
register(203, function(node, arguments)
    local state = node.EventState
    local eventId = tostring(arguments and arguments[1] or "")
    local revision = tonumber(arguments and arguments[2]) or 0
    if type(state) ~= "table" or state.id ~= eventId or revision <= revisionOf(state) then
        return false
    end
    node.Comms:SendMessage("WHISPER", 204, { eventId, revision }, "Host")
    return true
end)
register(204, function(node, arguments, sender)
    if not node.IsHost then
        return false
    end
    local state = node.ServerEventState
    if type(state) ~= "table" or state.id ~= tostring(arguments and arguments[1] or "") then
        return false
    end
    node.Comms:SendMessage("WHISPER", 202, {
        state.id,
        revisionOf(state),
        findUnit(state, 2).health,
        findUnit(state, 2).hidden,
        findUnit(state, 2).active,
        findUnit(state, 2).threat,
    }, sender)
    return true
end)

-- 1/9: Event A teardown cancels pending work before Event B can reuse the
-- session/channel. The shared transaction ledger is the only pending owner.
startEvent("event-a", 0)
host.Addon.Server.EventTransactions:Register("lifecycle", function(envelope)
    return { state = "committed", outcome = { eventId = envelope.eventId } }
end)
local pending = playerA.Addon.Client.EventTransactions:Create({
    eventState = playerA.EventState,
    eventId = "event-a",
    operation = "lifecycle",
    targetEventIds = { 2 },
    input = {},
})
assertTrue(type(pending) == "table", "Event A transaction created")
world:EndEvent("event-replaced")
startEvent("event-b", 0)
world:AdvanceTime(20000)
assertEqual(nil, playerA.Addon.Client.EventTransactions:GetPending(pending.id, "event-a"),
    "Event A transaction is not live in Event B")

-- 2: an Event-A packet held by the router cannot mutate Event B.
world:HoldNext("Host", "PlayerB", 201)
host.Comms:SendMessage("CHANNEL", 201, { "event-a", 1 }, "RPE-Lifecycle")
world:DeliverAll()
world:EndEvent("event-replaced")
startEvent("event-b", 0)
assertEqual(0, revisionOf(playerB.EventState), "Event B starts at its own revision")
assertEqual(1, world:ReleaseHeld("Host", "PlayerB", 201), "held Event-A packet released")
world:DeliverAll()
assertEqual(0, revisionOf(playerB.EventState), "late Event-A packet cannot mutate Event B")

-- 3/4: a missed revision is repaired from one latest snapshot, not mutation
-- replay. B sees the later EventState announcement and asks the host directly.
startEvent("event-c", 0)
world:DropNext("Host", "PlayerB", 201)
host.Comms:SendMessage("CHANNEL", 201, { "event-c", 1 }, "RPE-Lifecycle")
world:DeliverAll()
host.ServerEventState.liveUnitRevision = 2
findUnit(host.ServerEventState, 2).health = 0
findUnit(host.ServerEventState, 2).active = false
findUnit(host.ServerEventState, 2).hidden = true
findUnit(host.ServerEventState, 2).threat = 7
host.Comms:SendMessage("CHANNEL", 203, { "event-c", 2 }, "RPE-Lifecycle")
world:DeliverAll()
assertEqual(2, revisionOf(playerB.EventState), "latest snapshot repairs both missed revisions")

-- 5: an older snapshot cannot roll back the repaired revision.
host.Comms:SendMessage("WHISPER", 202, { "event-c", 1, 99, true, true, 1 }, "PlayerB")
world:DeliverAll()
assertEqual(2, revisionOf(playerB.EventState), "stale snapshot is ignored")
assertEqual(0, findUnit(playerB.EventState, 2).health, "stale snapshot did not change state")

-- 6/7: rejoin is represented by the current authoritative snapshot and does
-- not alter the host or the other peer.
local hostRevision = revisionOf(host.ServerEventState)
local hostHealth = findUnit(host.ServerEventState, 2).health
host.Comms:SendMessage("WHISPER", 202, {
    "event-c", hostRevision, hostHealth, findUnit(host.ServerEventState, 2).hidden,
    findUnit(host.ServerEventState, 2).active, findUnit(host.ServerEventState, 2).threat,
}, "PlayerB")
world:DeliverAll()
assertEqual(hostRevision, revisionOf(playerB.EventState), "rejoin installs current revision")
assertEqual(hostHealth, findUnit(playerB.EventState, 2).health, "rejoin installs current health")
assertEqual(hostHealth, findUnit(host.ServerEventState, 2).health, "rejoin does not perturb host")

-- 8: the repaired eligibility fields are applied together.
local repaired = findUnit(playerB.EventState, 2)
assertTrue(repaired.active == false and repaired.hidden == true and repaired.threat == 7,
    "repaired eligibility state is complete")

print("EventLifecycleConvergenceTest passed")
