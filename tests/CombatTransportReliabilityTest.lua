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

loadAddonFile("client/combat/Normalization.lua")
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
assertEqual(Client.ActiveCombatReactionEntry.checkId, "check-1", "first received hit check activates one reaction")
assertTrue(Combat:HandleDamageHitCheckRequest(Client, request, "Attacker"), "duplicate request is accepted idempotently")
assertEqual(sent[#sent].opcode, opcodes.COMBAT_HIT_CHECK_ACK, "duplicate request is acknowledged again")
assertEqual(Client.ActiveCombatReactionEntry.checkId, "check-1", "retried hit check leaves the original reaction active")
assertEqual(#Client.CombatReactionQueue, 0, "retried hit check is not queued twice")

eventState.active = false
assertTrue(not Combat:HandleDamageHitCheckRequest(Client, { "check-reject", "event", 10, 20, "spell", "component", 12, 4, "hit" }, "Attacker"), "stale request is rejected")
assertEqual(sent[#sent].opcode, opcodes.COMBAT_HIT_CHECK_REJECT, "stale request sends explicit rejection")
assertEqual(sent[#sent].arguments[3], "event-inactive", "rejection preserves its explicit reason")
eventState.active = true

local rejectedPending = { checkId = "check-rejected", eventId = "event", requestTargetName = "Defender", eventState = eventState }
Client:SetPendingCombatHitCheck(rejectedPending)
assertTrue(Combat:HandleDamageHitCheckReject(Client, { "check-rejected", "event", "event-inactive" }, "Defender"), "sender consumes explicit rejection")
assertEqual(Client:GetPendingCombatHitCheck("check-rejected"), nil, "explicit rejection terminates the pending hit check")

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

local earlyOutcome = {
    checkId = "out-of-order", eventId = "event", attackerEventId = 10, defenderEventId = 20,
    eventState = eventState, defenderUnit = eventState.units[2], attackerUnit = eventState.units[1],
    turnNumber = 1, tickNumber = 0, defenceSystem = "simple",
}
local appliedOutcomeCount = 0
Combat.ApplyResolvedDamage = function()
    appliedOutcomeCount = appliedOutcomeCount + 1
    return true, { appliedDelta = -4, resourceDeltas = {} }
end
Client:SetPendingCombatHitCheck(earlyOutcome)
assertTrue(Combat:HandleCombatDamageResolved(Client, { "out-of-order", "event", "physical", "-4", "1" }, "Defender"), "early outcome is buffered")
assertTrue(type(earlyOutcome.pendingDamageOutcome) == "table", "early outcome is retained until hit response")
assertTrue(Combat:HandleDamageHitCheckResponse(Client, { "out-of-order", "event", "pass", "", "" }, "Defender"), "later hit response consumes buffered outcome")
assertEqual(Client:GetPendingCombatHitCheck("out-of-order"), nil, "buffered outcome completes exactly one hit transaction")
assertEqual(appliedOutcomeCount, 1, "first damage outcome applies resources exactly once")
assertEqual(sent[#sent].opcode, opcodes.COMBAT_DAMAGE_RESOLVED_ACK, "outcome is ACKed only after completion")
assertTrue(Combat:HandleCombatDamageResolved(Client, { "out-of-order", "event", "physical", "-4", "1" }, "Defender"), "resent outcome is acknowledged idempotently")
assertEqual(appliedOutcomeCount, 1, "resent damage outcome cannot apply resources twice")

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

Client.ActiveCombatReactionEntry = {
    checkId = "stale", eventId = "event", eventState = eventState,
    attackerEventId = 10, defenderEventId = 20,
    turnNumber = 1, tickNumber = 0, createdAtMs = 0,
}
Client.CombatReactionQueue = {
    {
        checkId = "next", eventId = "event", eventState = eventState,
        attackerEventId = 10, defenderEventId = 20,
        turnNumber = 1, tickNumber = 0, createdAtMs = 15999,
    },
}
Client:PruneCombatReactionTransactions("test", 16000)
assertEqual(Client.ActiveCombatReactionEntry.checkId, "next", "stale active reaction promotes the next valid queued reaction")
assertEqual(#Client.CombatReactionQueue, 0, "promoted reaction is removed from the queue")

Client:SetPendingCombatHitCheck({ checkId = "event-end", eventId = "event", eventState = eventState })
Client.ActiveCombatReactionEntry = { checkId = "event-end-active", eventId = "event" }
Client.CombatReactionQueue = { { checkId = "event-end-queued", eventId = "event" } }
Client:ClearCombatReactionRuntime("event", "event-end")
assertEqual(Client.ActiveCombatReactionEntry, nil, "event end clears active reaction")
assertEqual(#Client.CombatReactionQueue, 0, "event end clears queued reactions")
assertEqual(Client:GetPendingCombatHitCheck("event-end"), nil, "event end clears pending hit checks")

return true
