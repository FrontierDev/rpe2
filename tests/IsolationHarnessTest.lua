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
local received = {
    Host = {},
    PlayerA = {},
    PlayerB = {},
}

local function register(opcode)
    for _, node in ipairs(world.nodes) do
        local receiver = node
        receiver:RegisterOperation(opcode, function(arguments, sender, distribution, target, message)
            local entries = received[receiver.Name]
            entries[#entries + 1] = {
                arguments = arguments,
                sender = sender,
                distribution = distribution,
                target = target,
                message = message,
            }
        end, "harness-test-" .. tostring(opcode))
    end
end

for opcode = 100, 106 do
    register(opcode)
end

world:StartEvent({
    id = "harness-event",
    active = true,
    channelName = "RPE-Test",
    channelId = 7,
    turnNumber = 1,
    tickNumber = 1,
    units = {
        { eventID = 1, health = 100 },
        { eventID = 2, health = 100 },
        { eventID = 3, health = 100 },
    },
})

assertTrue(host.EventState ~= playerA.EventState, "host and client state must be isolated")
assertTrue(playerA.EventState ~= playerB.EventState, "client state must be isolated")
assertTrue(host.EventState ~= host.ServerEventState, "host client/server state must be isolated")
assertTrue(host.Addon ~= playerA.Addon and playerA.Addon ~= playerB.Addon,
    "runtime addon tables must be isolated")
host.EventState.units[1].health = 42
assertEqual(100, playerA.EventState.units[1].health, "client A state leaked")
assertEqual(100, playerB.EventState.units[1].health, "client B state leaked")
assertEqual(100, host.ServerEventState.units[1].health, "server state leaked")

playerA.Comms:SendMessage("WHISPER", 100, { "hello" }, "PlayerB")
world:DeliverAll()
assertEqual(0, #received.PlayerA, "whisper reached sender")
assertEqual(1, #received.PlayerB, "whisper recipient count")
assertEqual("PlayerA", received.PlayerB[1].sender, "whisper sender")
assertEqual("WHISPER", received.PlayerB[1].distribution, "whisper distribution")
assertEqual(100, received.PlayerB[1].message.opcode, "whisper opcode")
assertEqual("PlayerB", received.PlayerB[1].target, "whisper target")
assertEqual("hello", received.PlayerB[1].arguments[1], "whisper arguments")
assertEqual(1, world.Router.deliveryCount, "whisper delivery history")

host.Comms:SendToChannel(7, 101, { "broadcast" }, { includeSender = false })
world:DeliverAll()
assertEqual(1, #received.PlayerA, "channel delivery to player A")
assertEqual(2, #received.PlayerB, "channel delivery to player B")
assertEqual(0, #received.Host, "channel excluded sender")

world:DropNext("PlayerA", "PlayerB", 102)
playerA.Comms:SendMessage("WHISPER", 102, { "lost" }, "PlayerB")
world:DeliverAll()
assertEqual(2, #received.PlayerB, "dropped packet was delivered")

world:DropAll("PlayerA", "PlayerB", 106)
playerA.Comms:SendMessage("WHISPER", 106, { "lost-1" }, "PlayerB")
playerA.Comms:SendMessage("WHISPER", 106, { "lost-2" }, "PlayerB")
world:DeliverAll()
assertEqual(2, #received.PlayerB, "drop-all packet was delivered")

world:HoldNext("PlayerA", "PlayerB", 103)
playerA.Comms:SendMessage("WHISPER", 103, { "held" }, "PlayerB")
world:DeliverAll()
assertEqual(2, #received.PlayerB, "held packet was delivered early")
assertEqual(1, world:ReleaseHeld("PlayerA", "PlayerB", 103), "held packet count")
world:DeliverAll()
assertEqual(3, #received.PlayerB, "released packet count")

world:HoldNext("PlayerA", "PlayerB", 104)
world:HoldNext("PlayerA", "PlayerB", 104)
playerA.Comms:SendMessage("WHISPER", 104, { "first" }, "PlayerB")
playerA.Comms:SendMessage("WHISPER", 104, { "second" }, "PlayerB")
assertEqual(2, world:DeliverOutOfOrder("PlayerA", "PlayerB", 104), "held reorder count")
world:DeliverAll()
assertEqual("second", received.PlayerB[4].arguments[1], "reverse delivery first packet")
assertEqual("first", received.PlayerB[5].arguments[1], "reverse delivery second packet")

local sendsBeforeDuplicate = world.Router.logicalSendCount
world:DuplicateNext("PlayerA", "PlayerB", 105)
playerA.Comms:SendMessage("WHISPER", 105, { "duplicate" }, "PlayerB")
world:DeliverAll()
assertEqual(sendsBeforeDuplicate + 1, world.Router.logicalSendCount, "duplicate changed logical send count")
assertEqual(7, #received.PlayerB, "duplicate delivery count")

local timerCalls = 0
playerA.env.C_Timer.After(1.5, function() timerCalls = timerCalls + 1 end)
world:AdvanceTime(1499)
assertEqual(0, timerCalls, "timer ran early")
world:AdvanceTime(1)
assertEqual(1, timerCalls, "timer did not run at due time")
world:AdvanceTime(10000)
assertEqual(1, timerCalls, "timer ran more than once")
assertEqual(0, #world:GetScheduledWork(), "completed timer remained scheduled")

print("IsolationHarnessTest passed")
