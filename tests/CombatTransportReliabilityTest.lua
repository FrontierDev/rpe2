local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local sent = {}
local opcodes = {
    COMBAT_HIT_CHECK_REQUEST = 1,
    COMBAT_HIT_CHECK_RESPONSE = 2,
    COMBAT_DAMAGE_RESOLVED = 3,
    COMBAT_DAMAGE_RESOLVED_ACK = 4,
    COMBAT_HIT_CHECK_ACK = 5,
    COMBAT_HIT_CHECK_REJECT = 6,
}
local Addon = {
    Client = { Combat = {} },
    Internal = { Comms = {}, Ruleset = {}, Registry = {}, Database = {}, Profile = {} },
    Utils = {
        Common = { NormalizeName = function(value) return tostring(value or "") end },
        Dice = {},
    },
    UI = {},
}
Addon.Internal.Comms.Operations = {
    GetOpcode = function(_, key) return opcodes[key] end,
}
Addon.Internal.Comms.SendMessage = function(_, _, opcode, arguments, target)
    sent[#sent + 1] = { opcode = opcode, arguments = arguments, target = target }
    return true
end

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("client/combat/Reaction.lua")

local Client = Addon.Client
local Combat = Client.Combat
Client.CombatReactionQueue = {}
local eventState = {
    id = "event", active = true, turnNumber = 1, tickNumber = 0,
    units = {
        { eventID = 10, name = "Attacker", ownerID = "Attacker" },
        { eventID = 20, name = "Defender", ownerID = "Defender", isPlayer = true },
    },
}
Client.GetState = function() return { active = true } end
Client.GetEventState = function() return eventState end
Client.ResolveLocalEventUnit = function() return eventState.units[2] end
Combat.ResolveSpellComponent = function()
    return nil, {}, { effect = { type = "damage", targetEvents = {} } }
end
Combat.ResolveHitCheckAttackType = function() return "melee" end
Combat.ResolveDefenceSystem = function() return "simple" end
Combat.CloneValue = function(_, value) return value end

local request = { "check-1", "event", 10, 20, "spell", "component", 12, 4, "hit" }
assertTrue(Combat:HandleDamageHitCheckRequest(Client, request, "Attacker"), "valid request is accepted")
assertEqual(sent[#sent].opcode, opcodes.COMBAT_HIT_CHECK_ACK, "valid request sends an acknowledgement")
assertTrue(Combat:HandleDamageHitCheckRequest(Client, request, "Attacker"), "duplicate request is accepted idempotently")
assertEqual(sent[#sent].opcode, opcodes.COMBAT_HIT_CHECK_ACK, "duplicate request is acknowledged again")
assertEqual(#Client.CombatReactionQueue, 0, "duplicate request is not queued twice")

eventState.active = false
assertTrue(not Combat:HandleDamageHitCheckRequest(Client, { "check-reject", "event", 10, 20, "spell", "component", 12, 4, "hit" }, "Attacker"), "stale request is rejected")
assertEqual(sent[#sent].opcode, opcodes.COMBAT_HIT_CHECK_REJECT, "stale request sends explicit rejection")
eventState.active = true

local pending = {
    checkId = "check-retry", eventId = "event", attackerEventId = 10, defenderEventId = 20,
    eventState = eventState, turnNumber = 1, tickNumber = 0,
}
Client:SetPendingCombatHitCheck(pending)
assertTrue(Client:SendPendingCombatHitCheckRequest(pending, "Defender", { "check-retry", "event" }), "request enters retry tracking")
local firstRequestCount = #sent
Combat:ProcessPendingCombatTransactions(Client, 1501)
assertTrue(#sent > firstRequestCount, "unacknowledged request is retried after its deadline")
assertTrue(Combat:HandleDamageHitCheckAck(Client, { "check-retry", "event" }, "Defender"), "matching ACK stops request retry")

Client.PendingCombatDamageOutcomes = {
    ["damage-1"] = {
        checkId = "damage-1", eventId = "event", attackerEventId = 10, defenderEventId = 20,
        eventState = eventState, turnNumber = 1, tickNumber = 0, targetName = "Attacker",
        arguments = { "damage-1", "event", "physical", "-4", "1" }, nextRetryAtMs = 0,
    },
}
Combat:ProcessPendingCombatTransactions(Client, 1)
assertEqual(sent[#sent].opcode, opcodes.COMBAT_DAMAGE_RESOLVED, "damage outcome is sent")
Combat:ProcessPendingCombatTransactions(Client, 1502)
assertEqual(sent[#sent].opcode, opcodes.COMBAT_DAMAGE_RESOLVED, "missing outcome ACK resends the same outcome")
assertTrue(Combat:HandleCombatDamageResolvedAck(Client, { "damage-1", "event" }, "Attacker"), "outcome ACK is accepted")
assertEqual(Client.PendingCombatDamageOutcomes["damage-1"], nil, "outcome ACK clears retry state")

Client.ActiveCombatReactionEntry = { checkId = "stale", eventId = "event", eventState = eventState, turnNumber = 1, tickNumber = 0, createdAtMs = 0 }
Client.CombatReactionQueue = { { checkId = "next", eventId = "event", eventState = eventState, turnNumber = 1, tickNumber = 0, createdAtMs = 1 } }
Client:PruneCombatReactionTransactions("test", 16000)
assertEqual(Client.ActiveCombatReactionEntry, nil, "expired active reaction is cleared")
assertEqual(#Client.CombatReactionQueue, 0, "expired queued reaction is cleared")

Client:SetPendingCombatHitCheck({ checkId = "event-end", eventId = "event", eventState = eventState })
Client.ActiveCombatReactionEntry = { checkId = "event-end-active", eventId = "event" }
Client.CombatReactionQueue = { { checkId = "event-end-queued", eventId = "event" } }
Client:ClearCombatReactionRuntime("event", "event-end")
assertEqual(Client.ActiveCombatReactionEntry, nil, "event end clears active reaction")
assertEqual(#Client.CombatReactionQueue, 0, "event end clears queued reactions")
assertEqual(Client:GetPendingCombatHitCheck("event-end"), nil, "event end clears pending hit checks")

return true
