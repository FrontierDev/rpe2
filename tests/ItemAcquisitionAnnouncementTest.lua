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

local function assertFalse(value, message)
    if value ~= false then
        error(message, 2)
    end
end

local function newAddon(playerName, resolveItem)
    local packets = {}
    local chatLines = {}
    local addon = {
        Client = {
            State = {
                active = false,
            },
        },
        Internal = {
            Comms = {
                Operations = {
                    GetOpcode = function(_, key)
                        if key == "ITEM_GAIN_REPORT" then
                            error("obsolete item-gain report opcode requested")
                        end
                        return key == "ITEM_GAIN_ANNOUNCEMENT" and 42 or nil
                    end,
                },
                SendToChannel = function(_, channelId, opcode, arguments, metadata)
                    packets[#packets + 1] = {
                        channelId = channelId,
                        opcode = opcode,
                        arguments = arguments,
                        metadata = metadata,
                    }
                    return true
                end,
            },
            Registry = {
                ResolveItemReference = function(_, itemRef)
                    if type(resolveItem) == "function" then
                        return resolveItem(itemRef)
                    end
                    return nil, nil
                end,
            },
            Runtime = {
                RegisterBeforeCommitProcessor = function(_, _, callback)
                    addon._itemGainProcessor = callback
                    return 1
                end,
            },
        },
        Utils = {
            Common = {
                GetPlayerName = function()
                    return playerName
                end,
                NormalizeName = function(value)
                    return tostring(value or "")
                end,
            },
        },
    }

    DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, message)
            chatLines[#chatLines + 1] = message
        end,
    }

    local chunk, loadError = loadfile("core/internal/ItemTier.lua")
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
    chunk, loadError = loadfile("client/client_LootNotifications.lua")
    assert(chunk, loadError)
    chunk("RPEngine2", addon)

    return addon, packets, chatLines
end

local function resolveBlade(itemRef)
    if itemRef ~= "items:blade" then
        return nil, nil
    end
    return { id = "items" }, {
        id = "blade",
        name = "Runed Blade",
        quality = "rare",
    }
end

local alice, alicePackets, aliceChat = newAddon("Alice", resolveBlade)
local lootNotifications = alice.Client.LootNotifications

assertTrue(lootNotifications:HandleCommittedAcquisition({
    playerName = "Alice",
    eventId = "inventory:received:1",
    itemRef = "items:blade",
    itemTier = "heroic",
    quantity = 1,
    category = "received",
}), "offline acquisition renders locally")
assertEqual(#aliceChat, 1, "offline acquisition emits one local line")
assertTrue(aliceChat[1]:find("You receive loot:", 1, true) ~= nil, "offline acquisition keeps the local loot format")
assertEqual(#alicePackets, 0, "offline acquisition sends no channel packet")

alice.Client.State = {
    active = true,
    hostName = "Host",
    channelId = 7,
}
assertTrue(lootNotifications:HandleCommittedAcquisition({
    playerName = "Alice",
    eventId = "craft:1:1",
    itemRef = "items:blade",
    itemTier = "mythic",
    quantity = 2,
    category = "crafted",
}), "connected acquisition publishes directly to the channel")
assertEqual(#alicePackets, 1, "connected acquisition sends one channel packet")
assertEqual(alicePackets[1].opcode, 42, "connected acquisition uses opcode 42")
assertEqual(alicePackets[1].channelId, 7, "connected acquisition uses the active RPE channel")
assertEqual(alicePackets[1].arguments[1], "Alice", "packet carries the acquiring player")
assertEqual(alicePackets[1].arguments[6], "crafted", "packet carries the normalized category")
assertEqual(alicePackets[1].metadata.scope, "client", "packet is a client announcement")
assertEqual(#aliceChat, 2, "connected acquisition renders exactly one immediate local line")
assertTrue(aliceChat[2]:find("[Alice] crafted", 1, true) ~= nil, "local line contains the actor and verb")
assertTrue(aliceChat[2]:find("x2.", 1, true) ~= nil, "local line contains the actual quantity")

assertFalse(alice.Client:HandleItemGainAnnouncement(
    alicePackets[1].arguments,
    "Alice",
    "CHANNEL",
    7
), "local channel loopback is deduplicated")
assertEqual(#aliceChat, 2, "local loopback emits no duplicate line")

local bob, _, bobChat = newAddon("Bob", resolveBlade)
bob.Client.State = {
    active = true,
    hostName = "Host",
    channelId = 7,
}
assertTrue(bob.Client:HandleItemGainAnnouncement(
    alicePackets[1].arguments,
    "Alice",
    "CHANNEL",
    7
), "recipient accepts the acquiring player as sender")
assertEqual(#bobChat, 1, "recipient renders one announcement")
assertTrue(bobChat[1]:find("[Alice] crafted", 1, true) ~= nil, "recipient renders the actor and verb")
assertFalse(bob.Client:HandleItemGainAnnouncement(
    alicePackets[1].arguments,
    "Alice",
    "CHANNEL",
    7
), "recipient deduplicates retransmission")
assertEqual(#bobChat, 1, "duplicate recipient packet emits no second line")
assertFalse(bob.Client:HandleItemGainAnnouncement(
    { "Alice", "craft:1:2", "items:blade", "mythic", 2, "crafted" },
    "Host",
    "CHANNEL",
    7
), "recipient rejects a mismatched sender")
assertFalse(bob.Client:HandleItemGainAnnouncement(
    { "Alice", "craft:1:3", "items:blade", "mythic", 2, "crafted" },
    "Alice",
    "CHANNEL",
    8
), "recipient rejects a wrong channel")

local unknown, _, unknownChat = newAddon("Bob", function()
    return nil, nil
end)
unknown.Client.State = {
    active = true,
    hostName = "Host",
    channelId = 7,
}
assertFalse(unknown.Client:HandleItemGainAnnouncement(
    alicePackets[1].arguments,
    "Alice",
    "CHANNEL",
    7
), "recipient ignores an unresolved item reference")
assertEqual(#unknownChat, 0, "unresolved item emits no fallback line")

print("ItemAcquisitionAnnouncementTest passed")
