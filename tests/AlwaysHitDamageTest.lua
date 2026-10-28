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
    if value == true then
        error(message, 2)
    end
end

local function findById(entries, id)
    for index = 1, #(entries or {}) do
        if entries[index].id == id then
            return entries[index]
        end
    end

    return nil
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local definitions = TestSupport.LoadPackagedDefaultData(TestSupport.CreateAddon())

local expectedSpells = {
    { datasetId = "b0211ab3", spellId = "tu5g28q8", name = "Divine Storm" },
    { datasetId = "b0211ab3", spellId = "eg4gydsa", name = "Templar's Verdict" },
    { datasetId = "1c1038a7", spellId = "am7ew5wl", name = "Eviscerate" },
    { datasetId = "1c1038a7", spellId = "envenom1", name = "Envenom" },
    { datasetId = "7bbb4cb9", spellId = "0jiq0uoc", name = "Mortal Strike" },
}

local spellsById = {}
for index = 1, #expectedSpells do
    local expected = expectedSpells[index]
    local dataset = assert(definitions[expected.datasetId] and definitions[expected.datasetId].dataset,
        "missing dataset for " .. expected.name)
    local spell = assert(findById(dataset.spells, expected.spellId), "missing " .. expected.name)
    assertEqual(spell.name, expected.name, expected.name .. " name")
    assertEqual(#spell.components, 1, expected.name .. " component count")
    assertTrue(spell.components[1].effect.alwaysHits == true, expected.name .. " always-hit flag")
    spellsById[expected.spellId] = spell
end

local spellAddon = TestSupport.CreateAddon()
spellAddon.Internal.Database.Classes = {}
TestSupport.LoadAddonFile("core/classes/Spell.lua", spellAddon)
for index = 1, #expectedSpells do
    local expected = expectedSpells[index]
    local spell = spellsById[expected.spellId]
    local roundTripped = spellAddon.Internal.Database.Classes.Spell:FromTable(spell):ToTable()
    assertTrue(roundTripped.components[1].effect.alwaysHits == true,
        expected.name .. " serialization preserves always-hit")
end

local function normalize(value)
    local text = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return text ~= "" and string.lower(text) or nil
end

local pendingEntries = {}
local completeCalls = {}
local applyCalls = {}
local finalizeCalls = {}
local historyCalls = {}
local outcomeCalls = 0
local reactionCalls = 0
local missCalls = 0
local defenceEventCalls = 0
local nextCheckId = 0

local auraManager = {
    ShouldForceAutoHitAgainstTarget = function()
        return false
    end,
}

local combat = {
    Normalization = {
        TrimText = function(value)
            return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
        end,
        NormalizeToken = normalize,
        NormalizeResultToken = normalize,
        SplitList = function(value)
            if type(value) == "table" then
                return value
            end
            return {}
        end,
    },
}

local client = {
    Spellcasting = { AuraManager = auraManager },
    Combat = combat,
}

local addon = {
    Client = client,
    Debug = {},
    Internal = {
        Comms = { Operations = {} },
        Database = { Classes = {} },
        Profile = {},
        Registry = {},
    },
    Utils = {
        Common = {
            Round = function(value)
                return math.floor((tonumber(value) or 0) + 0.5)
            end,
        },
        Dice = {},
        Lookup = {},
    },
}

function combat:CreateEffectContract(definition)
    return definition
end

TestSupport.LoadAddonFile("client/combat/effects/Damage.lua", addon)

function client:SetPendingCombatHitCheck(entry)
    pendingEntries[entry.checkId] = entry
    return entry
end

function client:ClearPendingCombatHitCheck(checkId)
    local previous = pendingEntries[checkId]
    pendingEntries[checkId] = nil
    return previous
end

function client:ResolveLocalEventUnit()
    return self.localEventUnit
end

function client:ShowCombatReaction()
    reactionCalls = reactionCalls + 1
    return true
end

function combat:BuildHitCheckEntry(context, effect, component)
    nextCheckId = nextCheckId + 1
    local entry = {
        attackerEventId = context.attackerUnit.eventID,
        attackerUnit = context.attackerUnit,
        checkId = "always-hit-test:" .. nextCheckId,
        component = component,
        componentKey = component and component.key or "damage",
        context = context,
        defenderEventId = context.defenderUnit.eventID,
        defenderUnit = context.defenderUnit,
        effect = effect,
        eventId = context.eventId,
        eventState = context.eventState,
        absorbedAmount = effect and effect.absorbedAmount or 0,
        damageAmount = effect and effect.damageAmount or 10,
        hitType = effect and effect.hitType or "critical",
        wasCritical = effect and effect.wasCritical,
        spellRef = context.spellRef,
    }
    return entry
end

function combat:CompleteHitCheck(entry, resultToken, reason)
    completeCalls[#completeCalls + 1] = {
        entry = entry,
        reason = reason,
        resultToken = resultToken,
    }
    return true, {
        landed = resultToken == "pass",
        resultType = reason,
    }
end

function combat:ApplyResolvedDamage(entry)
    applyCalls[#applyCalls + 1] = entry
    return true, {
        absorbedAmount = entry.absorbedAmount or 0,
        applied = true,
        appliedDelta = -(entry.damageAmount or 10),
        amount = entry.damageAmount or 10,
        hitType = entry.hitType or "critical",
        wasCritical = entry.wasCritical ~= false,
    }
end

function combat:FinalizeLocalDamageResult(entry, result)
    finalizeCalls[#finalizeCalls + 1] = { entry = entry, result = result }
    return true
end

function combat:RecordResolvedCombatAttackHistory(_, entry, resultToken)
    historyCalls[#historyCalls + 1] = {
        entry = entry,
        resultToken = resultToken,
    }
    return true
end

function combat:ChooseAutomaticReactionAction()
    return "defend"
end

function combat:FindReactionAction()
    return { enabled = true, id = "defend" }
end

function combat:ResolveHitCheckOutcome()
    outcomeCalls = outcomeCalls + 1
    return "fail", { defenceSystem = "percent" }
end

function combat:LogDefenceAttempt()
    defenceEventCalls = defenceEventCalls + 1
end

function combat:EmitSuccessfulDefenceEvent()
    defenceEventCalls = defenceEventCalls + 1
end

function combat:CompleteActionDamageResolution()
    defenceEventCalls = defenceEventCalls + 1
end

function combat:ShowMissCombatText()
    missCalls = missCalls + 1
end

local attacker = { eventID = 1, isPlayer = true }
local function makeContext(defender, spellRef)
    return {
        attackerUnit = attacker,
        defenderUnit = defender,
        eventId = "always-hit-event",
        eventState = { active = true, id = "always-hit-event" },
        sessionState = { active = true },
        spellRef = spellRef,
    }
end

local function resetResolutionCounters()
    completeCalls = {}
    applyCalls = {}
    finalizeCalls = {}
    historyCalls = {}
    outcomeCalls = 0
    reactionCalls = 0
    missCalls = 0
    defenceEventCalls = 0
    pendingEntries = {}
end

local alwaysHitEffect = {
    alwaysHits = true,
    absorbedAmount = 10,
    damageAmount = 25,
    hitType = "critical",
}

local divineStormTarget = spellsById.tu5g28q8.components[1].target
assertEqual(divineStormTarget.type, "raid_marker", "Divine Storm target policy")
assertEqual(divineStormTarget.minTargets, 1, "Divine Storm minimum selected targets")
assertEqual(divineStormTarget.maxTargets, 3, "Divine Storm maximum selected targets")

resetResolutionCounters()
local npcCompleted, npcOutcome = combat:BeginHitCheck(
    makeContext({ eventID = 2, isPlayer = false, highDefence = true }, "test:npc"),
    alwaysHitEffect,
    { key = "npc-damage" }
)
assertTrue(npcCompleted == true, "always-hit NPC damage completes")
assertTrue(npcOutcome.landed == true, "always-hit NPC result is landed")
assertEqual(completeCalls[1].resultToken, "pass", "always-hit NPC result is PASS")
assertEqual(completeCalls[1].reason, "always-hit", "always-hit NPC result reason")
assertEqual(outcomeCalls, 0, "always-hit NPC bypasses defence resolution")
assertEqual(#applyCalls, 1, "always-hit NPC applies damage once")
assertEqual(#finalizeCalls, 1, "always-hit NPC finalizes damage once")
assertEqual(#historyCalls, 1, "always-hit NPC records attack history once")
assertEqual(#pendingEntries, 0, "always-hit NPC leaves no pending hit check")
assertEqual(finalizeCalls[1].result.wasCritical, true, "always-hit preserves critical result")
assertEqual(finalizeCalls[1].result.absorbedAmount, 10, "always-hit preserves ordinary absorption result")

resetResolutionCounters()
local playerDefender = { eventID = 3, isPlayer = true, highDefence = true, reactionAvailable = true }
client.localEventUnit = playerDefender
local playerCompleted, playerOutcome = combat:BeginHitCheck(
    makeContext(playerDefender, "test:player"),
    alwaysHitEffect,
    { key = "player-damage" }
)
assertTrue(playerCompleted == true, "always-hit player damage completes")
assertTrue(playerOutcome.landed == true, "always-hit player result is landed")
assertTrue(completeCalls[1].entry.defenderUnit.reactionAvailable == true,
    "always-hit player test has an available defender reaction")
assertEqual(completeCalls[1].reason, "always-hit", "always-hit player result reason")
assertEqual(reactionCalls, 0, "always-hit player damage does not show a reaction prompt")
assertEqual(#pendingEntries, 0, "always-hit player damage leaves no pending hit check")

resetResolutionCounters()
local selectedTargets = {
    { eventID = 10, isPlayer = false, raidMarker = 1 },
    { eventID = 11, isPlayer = false, raidMarker = 1 },
    { eventID = 12, isPlayer = false, raidMarker = 1 },
}
local divineStormEffect = spellsById.tu5g28q8.components[1].effect
for index = 1, #selectedTargets do
    local entry = combat:BeginHitCheck(
        makeContext(selectedTargets[index], "b0211ab3:tu5g28q8"),
        divineStormEffect,
        { key = "divine-storm-damage-" .. index }
    )
    assertTrue(entry == true, "Divine Storm selected target completes")
end
assertEqual(#applyCalls, #selectedTargets, "Divine Storm applies once per selected target")
assertEqual(#historyCalls, #selectedTargets, "Divine Storm records one history row per selected target")
for index = 1, #applyCalls do
    assertEqual(applyCalls[index].defenderEventId, selectedTargets[index].eventID,
        "Divine Storm does not redirect selected target " .. index)
end

resetResolutionCounters()
local mortalStrikeEffect = {
    alwaysHits = true,
    absorbedAmount = 25,
    applyAura = true,
    auraRef = "7bbb4cb9:sb4b9ef3",
    damageAmount = 0,
}
local mortalStrikeResult = combat:BeginHitCheck(
    makeContext({ eventID = 20, isPlayer = false }, "7bbb4cb9:0jiq0uoc"),
    mortalStrikeEffect,
    { key = "mortal-strike-damage" }
)
assertTrue(mortalStrikeResult == true, "Mortal Strike completes when damage is fully absorbed")
assertEqual(#finalizeCalls, 1, "Mortal Strike finalizes a fully absorbed landed hit")
assertEqual(finalizeCalls[1].entry.effect.applyAura, true, "Mortal Strike keeps its Aura application")
assertEqual(finalizeCalls[1].entry.effect.auraRef, "7bbb4cb9:sb4b9ef3", "Mortal Strike Aura reference")

local rogueDataset = definitions["1c1038a7"].dataset
local envenom = spellsById.envenom1
assertEqual(#envenom.conditions, 2, "Envenom retains its two requirements")
assertEqual(envenom.conditions[2].type, "aura_requirement", "Envenom retains its poison requirement")
assertEqual(#envenom.resourceCosts, 2, "Envenom retains both resource costs")
assertTrue(findById(rogueDataset.spells, "envenom1") == envenom, "Envenom remains the packaged Rogue spell")

resetResolutionCounters()
local normalResult = combat:BeginHitCheck(
    makeContext({ eventID = 30, isPlayer = false, highDefence = true }, "test:normal"),
    { alwaysHits = false, damageAmount = 10 },
    { key = "normal-damage" }
)
assertTrue(normalResult == true, "normal NPC hit check completes")
assertEqual(completeCalls[1].resultToken, "fail", "normal NPC attack still fails defence")
assertEqual(outcomeCalls, 1, "normal NPC attack uses defence resolution")
assertEqual(#applyCalls, 0, "normal NPC miss does not apply damage")
assertEqual(missCalls, 1, "normal NPC miss displays miss feedback")

resetResolutionCounters()
client.localEventUnit = { eventID = 40, isPlayer = true }
local normalPlayerResult = combat:BeginHitCheck(
    makeContext(client.localEventUnit, "test:normal-player"),
    { alwaysHits = false, damageAmount = 10 },
    { key = "normal-player-damage" }
)
assertTrue(normalPlayerResult == true, "normal player-defender hit check remains pending")
assertEqual(#completeCalls, 0, "normal player-defender attack waits for reaction")
assertEqual(reactionCalls, 1, "normal player-defender attack shows reaction")
assertTrue(next(pendingEntries) ~= nil, "normal player-defender attack remains pending")

print("AlwaysHitDamageTest passed")
