local function assertEqual(actual, expected, message)
    if actual ~= expected then error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2) end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local sent = {}
local flushes = 0
local eventState = { id = "event", active = true, turnNumber = 4, tickNumber = 2 }
local sessionState = { active = true, channelName = "channel", channelId = 9 }
local Addon = {
    Client = {},
    Internal = {
        Comms = {
            Operations = { GetOpcode = function() return 41 end },
            SendToChannel = function(_, channelId, opcode, arguments)
                sent[#sent + 1] = { channelId = channelId, opcode = opcode, arguments = arguments }
                return true
            end,
        },
    },
}

local Client = Addon.Client
function Client:GetState() return sessionState end
function Client:GetEventState() return eventState end
function Client:FlushPendingTurnChanges(_, _, options)
    flushes = flushes + 1
    options.onFinished({}, true)
    return { status = "complete" }
end

loadAddonFile("client/client_EventTurnCommitBarrier.lua", Addon)

local request = { "channel", "event", 4, 2, "event:4:2:1", "request" }
assertEqual(Client:HandleEventTurnCommitBarrierRequest(request), true, "current-step request is handled")
assertEqual(flushes, 1, "request flushes the current source step")
assertEqual(sent[1].arguments[6], "ack", "completed flush acknowledges the server")
assertEqual(sent[1].arguments[7], "complete", "completed flush reports completion")

assertEqual(Client:HandleEventTurnCommitBarrierRequest(request), true, "duplicate request is handled")
assertEqual(flushes, 1, "duplicate request does not resend gameplay changes")
assertEqual(sent[2].arguments[7], "complete", "duplicate request re-acknowledges completion")

print("EventTurnCommitBarrierTest passed")
