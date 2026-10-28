local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
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
local warrior = assert(definitions["7bbb4cb9"] and definitions["7bbb4cb9"].dataset, "missing Warrior dataset")

local function assertTier(set, requiredPieces, message)
    for index = 1, #(set.bonuses or {}) do
        if set.bonuses[index].requiredPieces == requiredPieces then
            return set.bonuses[index]
        end
    end

    error(message .. ": missing " .. tostring(requiredPieces) .. "-piece tier", 2)
end

local function countItemsForSet(itemSetKey)
    local count = 0
    for index = 1, #(warrior.items or {}) do
        if warrior.items[index].itemSetKey == itemSetKey then
            count = count + 1
        end
    end
    return count
end

local immoveable = assert(findById(warrior.itemSets, "t2_warrior_tank"), "missing Immoveable Wrath set")
assertEqual(immoveable.key, "t2_warrior_tank", "Immoveable Wrath key")
assertEqual(immoveable.name, "Immoveable Wrath", "Immoveable Wrath name")
assertEqual(countItemsForSet(immoveable.key), 8, "Immoveable Wrath armor piece count")
assertEqual(#immoveable.bonuses, 3, "Immoveable Wrath tier count")

local immoveableTwo = assertTier(immoveable, 2, "Immoveable Wrath")
local resolve = assert(immoveableTwo.equipmentBonuses[1], "Immoveable Resolve bonus")
assertEqual(resolve.name, "Immoveable Resolve", "Immoveable Resolve name")
assertEqual(resolve.events[1].combatEventId, "on_defence", "Immoveable Resolve trigger")
assertEqual(resolve.events[1].defenceStatRef, "f82db71a:tcn0s8kx", "Immoveable Resolve defence stat")
assertEqual(resolve.events[1].effects[1].amount, 10, "Immoveable Resolve Rage amount")

local immoveableFour = assertTier(immoveable, 4, "Immoveable Wrath")
assertEqual(immoveableFour.statBonuses[1].statRef, "f82db71a:u7b49vs9", "Immoveable Wrath 4-piece stat")
assertEqual(immoveableFour.statBonuses[1].value, 35, "Immoveable Wrath 4-piece value")

local immoveableSix = assertTier(immoveable, 6, "Immoveable Wrath")
local retaliation = assert(immoveableSix.equipmentBonuses[1], "Immoveable Retaliation bonus")
assertEqual(retaliation.name, "Immoveable Retaliation", "Immoveable Retaliation name")
assertEqual(retaliation.events[1].chance, 20, "Immoveable Retaliation chance")
assertEqual(retaliation.events[1].effects[1].baseDamage, 100, "Immoveable Retaliation base damage")
assertEqual(retaliation.events[1].effects[1].damageSchoolRefs[1], "f82db71a:v1azo4j6", "Immoveable Retaliation damage school")

local unstoppable = assert(findById(warrior.itemSets, "t2_warrior_dps"), "missing Unstoppable Wrath set")
assertEqual(unstoppable.key, "t2_warrior_dps", "Unstoppable Wrath key")
assertEqual(unstoppable.name, "Unstoppable Wrath", "Unstoppable Wrath name")
assertEqual(countItemsForSet(unstoppable.key), 8, "Unstoppable Wrath armor piece count")
assertEqual(#unstoppable.bonuses, 3, "Unstoppable Wrath tier count")

local unstoppableTwo = assertTier(unstoppable, 2, "Unstoppable Wrath")
local rend = assert(unstoppableTwo.equipmentBonuses[1], "Unstoppable Rend bonus")
assertEqual(rend.name, "Unstoppable Rend", "Unstoppable Rend name")
assertEqual(rend.events[1].combatEventId, "on_critical_hit", "Unstoppable Rend trigger")
assertEqual(rend.events[1].effects[1].auraRef, "7bbb4cb9:jkptpqlh", "Unstoppable Rend aura")
assertEqual(rend.events[1].effects[1].duration, 5, "Unstoppable Rend duration")

local unstoppableFour = assertTier(unstoppable, 4, "Unstoppable Wrath")
assertEqual(unstoppableFour.statBonuses[1].statRef, "f82db71a:gj9wxb0x", "Unstoppable Wrath 4-piece stat")
assertEqual(unstoppableFour.statBonuses[1].value, 5, "Unstoppable Wrath 4-piece value")

local unstoppableSix = assertTier(unstoppable, 6, "Unstoppable Wrath")
local momentum = assert(unstoppableSix.equipmentBonuses[1], "Unstoppable Momentum bonus")
assertEqual(momentum.name, "Unstoppable Momentum", "Unstoppable Momentum name")
assertEqual(momentum.events[1].combatEventId, "on_melee_hit", "Unstoppable Momentum trigger")
assertEqual(momentum.events[1].effects[1].amount, 10, "Unstoppable Momentum Rage amount")

print("WarriorTier2ItemSetTest passed")
