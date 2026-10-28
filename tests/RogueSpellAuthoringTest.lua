local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local function findById(entries, id)
    for _, entry in ipairs(entries or {}) do
        if entry.id == id then return entry end
    end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local definitions = TestSupport.LoadPackagedDefaultData(TestSupport.CreateAddon())
local rogue = assert(definitions["23d5dce2"] and definitions["23d5dce2"].dataset, "missing Rogue dataset")

local function findAura(id)
    return assert(findById(rogue.auras, id), "missing Rogue aura " .. id)
end

local function findSpell(id)
    return assert(findById(rogue.spells, id), "missing Rogue spell " .. id)
end

local adrenalineAura = findAura("8o3v4oj0")
assertEqual(adrenalineAura.duration, 3, "Adrenaline Rush duration")
assertEqual(adrenalineAura.effects[1].amount, 25, "Adrenaline Rush energy gain")

local adrenalineRush = findSpell("wf9orqz9")
assertEqual(adrenalineRush.components[1].effect.duration, 3, "Adrenaline Rush application duration")
assertEqual(adrenalineRush.tooltipTemplateData.auraSections[1].duration, 3,
    "Adrenaline Rush tooltip duration")

assertEqual(findSpell("shdblad1").cooldown, 6, "Shadow Blades cooldown")
assertEqual(findSpell("stealth01").cooldown, 5, "Stealth cooldown")

local shiv = findSpell("shiv0001")
assertEqual(shiv.name, "Shiv", "Shiv name")
assertEqual(shiv.cooldown, 4, "Shiv cooldown")
assertEqual(shiv.cooldownChannel, 2, "Shiv bonus-action channel")
assertEqual(shiv.resourceCosts[1].amount, 15, "Shiv energy cost")
assertEqual(shiv.resourceCosts[1].resourceRef, "f82db71a:c3gaf7dd", "Shiv energy resource")
assertEqual(#shiv.components, 1, "Shiv component count")

local shivEffect = shiv.components[1].effect
assertTrue(shivEffect.alwaysHits == true, "Shiv always hits")
assertEqual(shivEffect.baseDamage, 70.6875, "Shiv authored base damage")
assertEqual(shivEffect.statScaling[1].coefficient, 0.329875, "Shiv melee attack power scaling")
assertEqual(shivEffect.statScaling[1].statRef, "f82db71a:u7b49vs9", "Shiv melee attack power stat")
assertEqual(shivEffect.weaponDamageCoefficient, 0.9425, "Shiv weapon scaling")
assertEqual(shivEffect.weaponDamageMode, "off_hand", "Shiv off-hand weapon scaling")
assertEqual(shiv.components[1].target.maxTargets, 1, "Shiv single-target limit")

print("RogueSpellAuthoringTest passed")
