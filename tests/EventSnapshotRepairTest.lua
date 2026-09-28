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
        },
    },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("client/client_Event.lua")

local Client = Addon.Client
local eventState = { id = "event", channelName = "channel", hostName = "Host", active = true, liveUnitRevision = 1 }
Client.GetEventState = function() return eventState end

assertEqual(Client:RequestAuthoritativeEventSnapshot(eventState, 4, "revision-mismatch", 0), true, "first repair request is sent")
assertEqual(#sent, 1, "one repair request is emitted")
assertEqual(Client:ProcessEventSnapshotRepair(1500), true, "lost repair request retries after deadline")
assertEqual(#sent, 2, "repair retry is emitted")
assertEqual(sent[2].opcode, 91, "retry uses snapshot repair opcode")
assertEqual(sent[2].arguments[3], 4, "retry preserves requested revision")

return true
