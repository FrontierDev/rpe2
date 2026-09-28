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
    local values, source, startIndex = {}, tostring(text or ""), 1
    while not limit or #values < limit - 1 do
        local separatorIndex = string.find(source, separator, startIndex, true)
        if not separatorIndex then break end
        values[#values + 1] = string.sub(source, startIndex, separatorIndex - 1)
        startIndex = separatorIndex + #separator
    end
    values[#values + 1] = string.sub(source, startIndex)
    return values
end

local received = {}
local Addon = {
    Internal = {
        Constants = { AddonMessagePrefix = "RPE" },
        Comms = {
            Diagnostics = {},
            MessageQueue = {},
            Operations = {
                Get = function() return nil end,
                Dispatch = function(_, opcode, arguments, sender)
                    received[#received + 1] = { opcode = opcode, arguments = arguments, sender = sender }
                    return true
                end,
            },
        },
    },
    Utils = {
        Common = {
            GetNow = function() return 1 end,
            NormalizeName = function(value) return tostring(value or "") end,
            GetPlayerName = function() return "Local" end,
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
loadAddonFile("core/internal/comms/Core.lua")

local Serialization = Addon.Internal.Comms.Serialization
local Comms = Addon.Internal.Comms
local function packet(messageId, partIndex, partCount, payload)
    return Serialization:SerializePacket("RPE", Serialization:BuildChunkToken(partIndex, partCount, messageId), 77, payload)
end

-- Message A loses its second part. Message B uses the same opcode and sender;
-- it must still reconstruct independently and cannot consume A's first part.
Comms:ReceiveMessage("RPE", packet("A", 1, 2, "old-"), "WHISPER", "Sender")
Comms:ReceiveMessage("RPE", packet("B", 2, 2, "world"), "WHISPER", "Sender")
Comms:ReceiveMessage("RPE", packet("B", 1, 2, "hello-"), "WHISPER", "Sender")
assertEqual(#received, 1, "new logical message reconstructs despite stale incomplete message")
assertEqual(received[1].arguments[1], "hello-world", "multipart chunks never mix across logical message IDs")

-- A duplicate and out-of-order delivery both remain safe.
Comms:ReceiveMessage("RPE", packet("C", 2, 3, "two-"), "WHISPER", "Sender")
Comms:ReceiveMessage("RPE", packet("C", 2, 3, "two-"), "WHISPER", "Sender")
Comms:ReceiveMessage("RPE", packet("C", 3, 3, "three"), "WHISPER", "Sender")
Comms:ReceiveMessage("RPE", packet("C", 1, 3, "one-"), "WHISPER", "Sender")
assertEqual(#received, 2, "out-of-order logical message reconstructs once")
assertEqual(received[2].arguments[1], "one-two-three", "duplicate chunk remains idempotent")
assertTrue(Serialization:DeserializePacket(packet("C", 1, 3, "x")).messageId == "C", "packet retains logical message identity")

return true
