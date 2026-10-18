local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local definitions = TestSupport.LoadPackagedDefaultData(TestSupport.CreateAddon())
local paladin = assert(definitions["b0211ab3"] and definitions["b0211ab3"].dataset, "missing Paladin dataset")

local cleanse
for _, spell in ipairs(paladin.spells or {}) do
    if spell.name == "Cleanse" then
        cleanse = spell
        break
    end
end

assertTrue(type(cleanse) == "table", "Cleanse exists in the Paladin dataset")
assertEqual(cleanse.cooldownChannel, 2, "Cleanse is a Bonus Action")
assertEqual(cleanse.cooldown, 1, "Cleanse has a one-turn cooldown")
assertEqual(cleanse.castTime, 0, "Cleanse is instant")

local cost = cleanse.resourceCosts and cleanse.resourceCosts[1]
assertTrue(type(cost) == "table", "Cleanse has a resource cost")
assertEqual(cost.amount, 5, "Cleanse costs 5% base mana")
assertEqual(cost.amountMode, "base_percent", "Cleanse uses base-percent mana")
assertEqual(cost.resourceRef, "f82db71a:4c8mfm99", "Cleanse costs mana")

local component = cleanse.components and cleanse.components[1]
local effect = component and component.effect
assertTrue(type(effect) == "table", "Cleanse has an effect")
assertEqual(effect.type, "remove_aura_by_tag", "Cleanse removes auras by tag")

local expectedTags = { magic = true, poison = true, disease = true }
assertEqual(#(effect.tags or {}), 3, "Cleanse removes three aura tags")
for _, tag in ipairs(effect.tags or {}) do
    assertTrue(expectedTags[tag] == true, "Cleanse includes the " .. tostring(tag) .. " tag")
    expectedTags[tag] = nil
end
assertTrue(next(expectedTags) == nil, "Cleanse includes magic, poison, and disease tags")

local target = component and component.target
assertEqual(target and target.targetDisposition, "ally", "Cleanse targets an ally")
assertEqual(target and target.type, "single", "Cleanse targets one ally")

print("PaladinCleanseTest passed")
