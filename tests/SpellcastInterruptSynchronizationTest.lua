local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local spells = {
    ["test:kick"] = { castTime = 0, components = { { effect = { type = "interrupt" } } } },
    ["test:fireball"] = { castTime = 2, components = { { effect = { type = "damage" } } } },
    ["test:instant"] = { castTime = 0, components = {} },
}
local units = {
    { eventID = 1, isPlayer = true, name = "Attacker", ownerID = "Attacker" },
    { eventID = 2, isPlayer = true, name = "Victim", ownerID = "Victim" },
    { eventID = 3, isPlayer = false, name = "Host NPC", active = true },
}
local eventState = {
    active = true, id = "interrupt-test", name = "Interrupt Test",
    hostName = "Host", turnNumber = 1, tickNumber = 1, units = units,
}
local sessionState = { active = true, channelName = "test-channel", channelId = 7 }
local packets = {}
local Addon = {
    Debug = {},
    Client = { Spellcasting = {} },
    Server = {},
    Utils = {
        Common = {
            NormalizeName = function(value) return tostring(value or "") end,
            GetPlayerName = function() return "Attacker" end,
        },
        Lookup = {
            FindEventUnitById = function(sourceUnits, eventId)
                for _, unit in ipairs(sourceUnits or {}) do
                    if tonumber(unit.eventID) == tonumber(eventId) then return unit end
                end
                return nil
            end,
        },
    },
    Internal = {
        Database = { Classes = { Event = { IsUnitActive = function(unit) return unit and unit.active ~= false end } } },
        Registry = {
            ResolveSpellReference = function(_, ref)
                if spells[ref] then return { id = "test" }, spells[ref] end
                return nil
            end,
            ResolveSpellName = function(_, ref) return ref end,
        },
        Comms = {
            Operations = {
                GetOpcode = function(_, name)
                    return ({ SPELLCAST_START = 11, SPELLCAST_COMPLETE = 12, SPELLCAST_INTERRUPT = 13 })[name]
                end,
            },
            ResolveChannelId = function() return 7 end,
            SendToChannel = function(_, channelId, opcode, arguments)
                packets[#packets + 1] = { channelId = channelId, opcode = opcode, arguments = arguments }
                return true
            end,
        },
    },
}

function Addon.Client:GetState() return sessionState end
function Addon.Client:GetEventState() return eventState end
function Addon.Client:CanPerformEventAction() return true end
function Addon.Server:GetState() return sessionState end
function Addon.Server:GetEventState() return eventState end

TestSupport.LoadAddonFile("client/spellcasting/Helpers.lua", Addon)
TestSupport.LoadAddonFile("client/spellcasting/Lifecycle.lua", Addon)
TestSupport.LoadAddonFile("server/server_Spellcasting.lua", Addon)

local Client = Addon.Client
local Server = Addon.Server
local Spellcasting = Client.Spellcasting
local victimEntry = {
    spellRef = "test:fireball", spellName = "Fireball",
    authorityType = "player", turnsTotal = 2, casterEventId = 2,
}
local function resetCasts()
    Server:ResetSpellcastingState(eventState.id)
    Spellcasting.ClearEventCastBucket(Client, eventState.id)
    assertTrue(Server:HandleSpellcastStart({
        sessionState.channelName, eventState.id, 2, "test:fireball", 2, "player",
    }, "Victim"), "target cast starts on server")
    Spellcasting.SetCastEntry(Client, eventState.id, 2, victimEntry)
end

resetCasts()
local applied, removed = Spellcasting.InterruptUnitSpellcast(Client, eventState, units[2], {
    reason = "spell-effect",
    sourceContext = { casterUnit = units[1], spellRef = "test:kick" },
})
assertTrue(applied, "interrupt effect cancels local target cast")
assertEqual(removed.spellRef, "test:fireball", "interrupt removes the target spell")
assertEqual(Spellcasting.GetCastEntry(Client, eventState.id, 2), nil, "local cast entry removed")
local packet = packets[#packets].arguments
assertEqual(packet[3], 2, "interrupt identifies interrupted target")
assertEqual(packet[4], "test:fireball", "interrupt preserves interrupted spell ref")
assertEqual(packet[5], "player", "interrupt preserves victim authority type")
assertEqual(packet[6], 1, "interrupt identifies attacking caster")
assertEqual(packet[7], "test:kick", "interrupt identifies attacking spell")

-- An attacker is not the owner of the interrupted player: both the server
-- and the victim must accept the source-validated interrupt instead.
assertTrue(Server:HandleSpellcastInterrupt(packet, "Attacker"), "server accepts attacker interrupt")
assertEqual(Server:GetSpellcastEntry(eventState.id, 2), nil, "server cast is cancelled")
local remoteClient = setmetatable({
    ActiveSpellcastsByEventId = {},
    ActiveSpellcastRevisionByEventId = {},
}, { __index = Client })
function remoteClient:GetState() return sessionState end
function remoteClient:GetEventState() return eventState end
Spellcasting.SetCastEntry(remoteClient, eventState.id, 2, victimEntry)
assertTrue(remoteClient:HandleSpellcastInterrupt(packet, "Attacker"), "victim accepts attacker interrupt")
assertEqual(Spellcasting.GetCastEntry(remoteClient, eventState.id, 2), nil, "victim cast removed")

-- A cancelled cast must not complete on the server or client after the
-- interrupt, even if its completion packet was already scheduled.
local completion = { sessionState.channelName, eventState.id, 2, "test:fireball", "player" }
assertEqual(Server:HandleSpellcastComplete(completion, "Victim"), false, "late completion rejected on server")
assertEqual(remoteClient:HandleSpellcastComplete(completion, "Victim"), false, "late completion ignored by victim")
function Client:ResolveActiveSpellcasterUnit() return units[2] end
assertEqual(Client:OnSpellcastComplete("test:fireball", victimEntry), false, "queued caster completion cannot resurrect interrupted cast")

-- Valid instantaneous completions are intentionally unaffected.
assertTrue(Server:HandleSpellcastComplete({
    sessionState.channelName, eventState.id, 2, "test:instant", "player",
}, "Victim"), "instant spell completion still works")

-- A forged source, or a source spell without an interrupt, is not accepted.
resetCasts()
assertEqual(Server:HandleSpellcastInterrupt(packet, "Intruder"), false, "stranger cannot interrupt victim")
local bogusSourceSpell = {
    sessionState.channelName, eventState.id, 2, "test:fireball", "player", 1, "test:instant",
}
assertEqual(Server:HandleSpellcastInterrupt(bogusSourceSpell, "Attacker"), false, "non-interrupting spell cannot cancel cast")
assertTrue(Server:GetSpellcastEntry(eventState.id, 2) ~= nil, "rejected interrupts preserve active cast")

-- Legacy self-interruption packets remain accepted.
local selfInterrupt = {
    sessionState.channelName, eventState.id, 2, "test:fireball", "player",
}
assertTrue(Server:HandleSpellcastInterrupt(selfInterrupt, "Victim"), "caster can interrupt own spell")
assertEqual(Server:GetSpellcastEntry(eventState.id, 2), nil, "self-interrupt removes cast")

-- A host-owned NPC can use its own interrupt effect without impersonating
-- the spellcaster being interrupted.
resetCasts()
local hostNpcInterrupt = {
    sessionState.channelName, eventState.id, 2, "test:fireball", "player", 3, "test:kick",
}
assertTrue(Server:HandleSpellcastInterrupt(hostNpcInterrupt, "Host"), "NPC interrupt authorized by host")
assertEqual(Server:GetSpellcastEntry(eventState.id, 2), nil, "NPC interrupt cancels the target")

print("SpellcastInterruptSynchronizationTest passed")
