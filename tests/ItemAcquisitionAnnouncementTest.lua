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

local chatLines = {}
local sentReports = {}
DEFAULT_CHAT_FRAME = {
    AddMessage = function(_, message)
        chatLines[#chatLines + 1] = message
    end,
}

local Addon = {
    Client = {
        State = {
            active = false,
        },
    },
    Internal = {
        Comms = {
            Operations = {
                GetOpcode = function(_, key)
                    return key == "ITEM_GAIN_REPORT" and 41 or 42
                end,
            },
            SendToChannel = function(_, channelId, opcode, arguments, metadata)
                sentReports[#sentReports + 1] = {
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
                if itemRef ~= "items:blade" then
                    return nil, nil
                end
                return { id = "items" }, {
                    id = "blade",
                    name = "Runed Blade",
                    quality = "rare",
                }
            end,
        },
        Runtime = {
            RegisterBeforeCommitProcessor = function(_, _, callback)
                Addon._itemGainProcessor = callback
                return 1
            end,
        },
    },
    Utils = {
        Common = {
            GetPlayerName = function()
                return "Alice"
            end,
            NormalizeName = function(value)
                return tostring(value or "")
            end,
        },
    },
}

local chunk, loadError = loadfile("core/internal/ItemTier.lua")
assert(chunk, loadError)
chunk("RPEngine2", Addon)
chunk, loadError = loadfile("client/client_LootNotifications.lua")
assert(chunk, loadError)
chunk("RPEngine2", Addon)

local LootNotifications = Addon.Client.LootNotifications
assertTrue(LootNotifications:HandleCommittedAcquisition({
    playerName = "Alice",
    eventId = "inventory:received:1",
    itemRef = "items:blade",
    itemTier = "heroic",
    quantity = 1,
    category = "received",
}), "offline acquisition renders locally")
assertEqual(#chatLines, 1, "offline acquisition emits one local line")
assertTrue(chatLines[1]:find("You receive loot:", 1, true) ~= nil, "offline acquisition keeps the local loot format")

Addon.Client.State = {
    active = true,
    hostName = "Host",
    channelId = 7,
}
assertTrue(LootNotifications:HandleCommittedAcquisition({
    playerName = "Alice",
    eventId = "craft:1:1",
    itemRef = "items:blade",
    itemTier = "mythic",
    quantity = 2,
    category = "crafted",
}), "connected acquisition reports to the server")
assertEqual(#chatLines, 1, "connected acquisition waits for the server echo")
assertEqual(#sentReports, 1, "connected acquisition sends one report")
assertEqual(sentReports[1].arguments[6], "crafted", "report carries the normalized category")

assertTrue(Addon.Client:HandleItemGainAnnouncement(
    { "Alice", "craft:1:1", "items:blade", "mythic", 2, "crafted" },
    "Host",
    "CHANNEL",
    7
), "host echo renders on the recipient")
assertEqual(#chatLines, 2, "server echo emits one announcement")
assertTrue(chatLines[2]:find("[Alice] crafted", 1, true) ~= nil, "announcement contains the actor and verb")
assertTrue(chatLines[2]:find("x2.", 1, true) ~= nil, "announcement contains the actual quantity")
assertTrue(not Addon.Client:HandleItemGainAnnouncement(
    { "Alice", "craft:1:1", "items:blade", "mythic", 2, "crafted" },
    "Host",
    "CHANNEL",
    7
), "duplicate server echo is ignored")
assertEqual(#chatLines, 2, "duplicate server echo emits no second line")
assertTrue(not Addon.Client:HandleItemGainAnnouncement(
    { "Alice", "craft:1:2", "items:blade", "mythic", 2, "crafted" },
    "ForgedSender",
    "CHANNEL",
    7
), "non-host announcement is ignored")

print("ItemAcquisitionAnnouncementTest passed")
