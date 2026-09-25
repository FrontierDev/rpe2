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
    Internal = {},
    Utils = {},
}

local chunk, loadError = loadfile("client/spellcasting/Helpers.lua")
assert(chunk, loadError)
chunk("RPEngine2", Addon)

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

print("CombatHistoryAttackTest passed")
