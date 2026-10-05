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

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Addon = {
    Client = {
        Spellcasting = {},
        CombatHistoryByEventId = {
            history = {
                turns = {
                    [1] = {
                        attacks = {
                            {
                                turnNumber = 1,
                                resolved = true,
                                attackerEventId = 5,
                                targetEventId = 4,
                            },
                        },
                    },
                },
            },
        },
    },
    Internal = {
        Registry = {
            ResolveStatReference = function(_, statRef)
                if statRef == "core:parry" then
                    return {}, { name = "Parry", defenceLabel = "Parry" }
                end
                if statRef == "core:dodge" then
                    return {}, { name = "Dodge", defenceLabel = "Dodge" }
                end
                return nil, nil
            end,
        },
        Database = {},
    },
    Utils = {},
}

local chunk, loadError = loadfile("client/spellcasting/Helpers.lua")
assert(chunk, loadError)
chunk("RPEngine2", Addon)

local conditionChunk, conditionLoadError = loadfile("core/classes/Condition.lua")
assert(conditionChunk, conditionLoadError)
conditionChunk("RPEngine2", Addon)
local conditionsCoreChunk, conditionsCoreLoadError = loadfile("client/conditions/Core.lua")
assert(conditionsCoreChunk, conditionsCoreLoadError)
conditionsCoreChunk("RPEngine2", Addon)
local defendedConditionChunk, defendedConditionLoadError = loadfile("client/conditions/CasterDefendedMeleeThisTurn.lua")
assert(defendedConditionChunk, defendedConditionLoadError)
defendedConditionChunk("RPEngine2", Addon)

local eventState = { active = true, id = "history", turnNumber = 2 }
assertTrue(
    Addon.Client:HasUnitAttackedTargetOnTurn(eventState, 5, 4, 1),
    "matching previous-turn attack is found"
)
assertFalse(
    Addon.Client:HasUnitAttackedTargetOnTurn(eventState, 5, 6, 1),
    "different target is not marked"
)
assertFalse(
    Addon.Client:HasUnitAttackedTargetOnTurn(eventState, 5, 4, 2),
    "current-turn history does not count as previous-turn history"
)

local caster = { eventID = 4 }
local attacker = { eventID = 5 }
local function record(eventId, turnNumber, attackType, defended, defenceStatRef, identity)
    local state = { active = true, id = eventId, turnNumber = turnNumber }
    assertTrue(
        Addon.Client:RecordCombatAttack(state, attacker, caster, attackType, false, defended, identity, defenceStatRef),
        "combat attack is recorded"
    )
    return state
end

local defendedState = record("defended", 3, "melee", true, "core:parry", "parry-1")
assertTrue(
    Addon.Client:HasSuccessfullyDefendedMeleeThisTurn(defendedState, caster.eventID),
    "unparameterised condition passes after any successful melee defence"
)
assertTrue(
    Addon.Client:HasSuccessfullyDefendedMeleeThisTurn(defendedState, caster.eventID, "core:parry"),
    "Parry condition passes for a Parry defence"
)
assertFalse(
    Addon.Client:HasSuccessfullyDefendedMeleeThisTurn(defendedState, caster.eventID, "core:dodge"),
    "Parry condition rejects a different defence"
)
local dodgeState = record("dodge", 3, "melee", true, "core:dodge", "dodge-1")
assertFalse(
    Addon.Client:HasSuccessfullyDefendedMeleeThisTurn(dodgeState, caster.eventID, "core:parry"),
    "Parry condition fails after a Dodge defence"
)
assertEqual(
    Addon.Client.CombatHistoryByEventId.defended.turns[3].attacks[1].defenceStatRef,
    "core:parry",
    "combat history preserves the canonical defence stat reference"
)

local previousTurnState = record("previous-turn", 1, "melee", true, "core:parry", "previous-parry")
previousTurnState = { active = true, id = "previous-turn", turnNumber = 2 }
assertFalse(
    Addon.Client:HasSuccessfullyDefendedMeleeThisTurn(previousTurnState, caster.eventID, "core:parry"),
    "a defence from a previous turn does not satisfy the condition"
)

local failedState = record("failed", 3, "melee", false, "core:parry", "failed-parry")
assertFalse(
    Addon.Client:HasSuccessfullyDefendedMeleeThisTurn(failedState, caster.eventID),
    "a failed defensive reaction does not satisfy the condition"
)
local failedEvaluation = Addon.Client.Conditions:Evaluate({
    type = "caster_defended_melee_this_turn",
}, {
    eventState = failedState,
    casterUnit = caster,
})
assertFalse(failedEvaluation.passed, "unparameterised condition fails without a successful melee defence")

local nonMeleeState = record("non-melee", 3, "spell", true, "core:parry", "spell-parry")
assertFalse(
    Addon.Client:HasSuccessfullyDefendedMeleeThisTurn(nonMeleeState, caster.eventID),
    "a non-melee defence does not satisfy the melee condition"
)

local normalizedCondition = Addon.Internal.Database.Classes.Condition.Normalize({
    type = "caster_defended_melee_this_turn",
    defenceStatRef = "  core:parry  ",
})
assertEqual(normalizedCondition.defenceStatRef, "core:parry", "defence stat reference is normalized and retained")
local evaluated = Addon.Client.Conditions:Evaluate(normalizedCondition, {
    eventState = defendedState,
    casterUnit = caster,
})
assertTrue(evaluated.passed, "parameterised condition evaluator uses the defence stat filter")
local genericEvaluation = Addon.Client.Conditions:Evaluate({
    type = "caster_defended_melee_this_turn",
}, {
    eventState = defendedState,
    casterUnit = caster,
})
assertTrue(genericEvaluation.passed, "unparameterised condition evaluator remains backward-compatible")
assertEqual(
    Addon.Client.Conditions:ResolveConditionText(normalizedCondition, {}),
    "Requires the caster to have successfully defended using Parry this turn",
    "parameterised condition tooltip names the resolved defence"
)

local invalidCondition = Addon.Internal.Database.Classes.Condition.Normalize({
    type = "caster_defended_melee_this_turn",
    defenceStatRef = "not-a-stat-reference",
})
local invalidEvaluation = Addon.Client.Conditions:Evaluate(invalidCondition, {
    eventState = defendedState,
    casterUnit = caster,
})
assertFalse(invalidEvaluation.passed, "an unresolved defence stat does not fall back to any defence")
assertFalse(
    Addon.Client:HasSuccessfullyDefendedMeleeThisTurn(defendedState, caster.eventID, "core:missing"),
    "an unresolved defence stat cannot match combat history"
)

print("CombatHistoryAttackTest passed")
