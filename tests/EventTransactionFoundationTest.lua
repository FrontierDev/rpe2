local Harness = dofile("tests/support/IsolationHarness.lua")

local function assertEqual(expected, actual, message)
    assert(expected == actual, (message or "values differ")
        .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function assertTrue(value, message)
    assert(value == true, message or "expected true")
end

local function setup(options)
    options = options or {}
    local world = Harness.New()
    local host = world:AddHost("Host")
    local playerA = world:AddClient("PlayerA")
    local playerB = world:AddClient("PlayerB")
    local counters = { executions = 0, presentations = 0 }

    world:StartEvent({
        id = options.eventId or "event-a",
        active = true,
        hostName = "Host",
        channelName = "RPE-TX",
        channelId = 9,
        turnNumber = 2,
        tickNumber = 3,
    })

    host.Addon.Server.EventTransactions:Register("synthetic", function(envelope)
        counters.executions = counters.executions + 1
        if envelope.input and envelope.input.reject then
            return { state = "rejected", outcome = { reason = "synthetic-rejection" } }
        end
        return {
            state = "committed",
            outcome = { accepted = true },
            authoritativeDelta = { synthetic = true },
            newRevision = 1,
        }
    end)

    local function create(input, eventId)
        local record = playerA.Addon.Client.EventTransactions:Create({
            eventId = eventId,
            operation = "synthetic",
            input = input or { value = 1 },
            onTerminal = function()
                counters.presentations = counters.presentations + 1
            end,
        })
        assertTrue(record ~= nil, "transaction was created")
        return record
    end

    return world, host, playerA, playerB, counters, create
end

do
    local world, host, playerA, playerB, counters, create = setup()
    local record = create()
    assertTrue(playerA.Addon.Client.EventTransactions:Submit(record), "submit accepted")
    world:DeliverAll()
    assertEqual(1, counters.executions, "successful transaction executed once")
    assertEqual("committed", record.state, "successful terminal state")
    assertEqual(1, counters.presentations, "successful presentation settled once")
    assertTrue(playerB.Addon.Client.EventTransactions.terminalByEventId["event-a"][record.id] ~= nil,
        "broadcast commit reached the second client")
end

do
    local world, host, playerA, playerB, counters, create = setup()
    local requestOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_REQUEST
    world:DropNext("PlayerA", "Host", requestOpcode)
    local record = create()
    playerA.Addon.Client.EventTransactions:Submit(record)
    world:DeliverAll()
    assertEqual(0, counters.executions, "dropped request executed early")
    world:AdvanceTime(1500)
    world:DeliverAll()
    assertEqual(1, counters.executions, "retry executed once")
    assertEqual(2, record.attempts, "retry reused the transaction")
end

do
    local world, host, playerA, playerB, counters, create = setup()
    local record = create()
    playerA.Addon.Client.EventTransactions:Submit(record)
    world:DeliverAll()
    playerA.Addon.Client.EventTransactions:Replay(record.id)
    world:DeliverAll()
    assertEqual(1, counters.executions, "duplicate command re-executed")
    assertEqual(1, counters.presentations, "duplicate terminal presented twice")
end

do
    local world, host, playerA, playerB, counters, create = setup()
    local commitOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_COMMIT
    world:DropNext("Host", "PlayerA", commitOpcode)
    local record = create()
    playerA.Addon.Client.EventTransactions:Submit(record)
    world:DeliverAll()
    assertEqual(1, counters.executions, "commit-drop executed more than once before retry")
    world:AdvanceTime(1500)
    world:DeliverAll()
    assertEqual(1, counters.executions, "commit retry re-executed mutation")
    assertEqual("committed", record.state, "commit replay settled client")
end

do
    local world, host, playerA, playerB, counters, create = setup()
    local record = create({ reject = true })
    playerA.Addon.Client.EventTransactions:Submit(record)
    world:DeliverAll()
    playerA.Addon.Client.EventTransactions:Replay(record.id)
    world:DeliverAll()
    assertEqual(1, counters.executions, "rejected duplicate executed")
    assertEqual("rejected", record.state, "rejection was terminal")
    assertEqual("synthetic-rejection", record.terminal.outcome.reason, "rejection reason")
end

do
    local world, host, playerA, playerB, counters, create = setup()
    local requestOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_REQUEST
    world:DropAll("PlayerA", "Host", requestOpcode)
    local record = create()
    playerA.Addon.Client.EventTransactions:Submit(record)
    world:AdvanceTime(15000)
    assertTrue(record.transportStalled == true, "transport timeout was not diagnosed")
    assertTrue(counters.executions == 0, "lost transaction reached the server")
    local diagnostics = playerA.Addon.Client.EventTransactions:GetDiagnostics()
    assertTrue(#diagnostics > 0, "timeout diagnostics were not recorded")
end

do
    local world, host, playerA, playerB, counters, create = setup()
    local record = create()
    local stale = Harness.Clone(record.envelope)
    world:StartEvent({
        id = "event-b",
        active = true,
        hostName = "Host",
        channelName = "RPE-TX",
        channelId = 9,
        turnNumber = 1,
        tickNumber = 1,
    })
    host.Addon.Server.EventTransactions:ReceiveRequest(stale, "PlayerA")
    assertEqual(0, counters.executions, "stale event reached the adapter")
    assertEqual("event-b", host.Addon.Server.EventTransactions.currentEventId, "server event scope")
end

do
    local world, host, playerA, playerB, counters, create = setup()
    local requestOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_REQUEST
    world:DropNext("PlayerA", "Host", requestOpcode)
    local record = create()
    playerA.Addon.Client.EventTransactions:Submit(record)
    world:DeliverAll()
    world:StartEvent({
        id = "event-b",
        active = true,
        hostName = "Host",
        channelName = "RPE-TX",
        channelId = 9,
        turnNumber = 1,
        tickNumber = 1,
    })
    world:AdvanceTime(20000)
    local sends = 0
    for _, send in ipairs(world.Router.sendHistory) do
        if send.sender == "PlayerA" and send.opcode == requestOpcode then
            sends = sends + 1
        end
    end
    assertEqual(1, sends, "Event-A retry crossed into Event B")
end

do
    local world, host, playerA, playerB, _, create = setup()
    local hostTransactions = host.Addon.Server.EventTransactions
    local aTransactions = playerA.Addon.Client.EventTransactions
    local bTransactions = playerB.Addon.Client.EventTransactions
    local record = create()
    assertTrue(hostTransactions ~= aTransactions and aTransactions ~= bTransactions,
        "transaction services share state")
    assertTrue(aTransactions.pendingByEventId["event-a"] ~= bTransactions.pendingByEventId["event-a"],
        "client pending ledgers share state")
    assertTrue(record.eventId == "event-a", "transaction event scope")
end

print("EventTransactionFoundationTest passed")
