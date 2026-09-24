local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local Addon = { Data = {} }
loadAddonFile("data/default/Datasets.lua", Addon)

local datasets = {
    { path = "data/default/classes/druid.lua", id = "6e4d2a91", version = 1 },
    { path = "data/default/classes/hunter.lua", id = "a93f7c12", version = 10 },
    { path = "data/default/classes/mage.lua", id = "d7c874c4", version = 38 },
    { path = "data/default/classes/paladin.lua", id = "b0211ab3", version = 49 },
    { path = "data/default/classes/priest.lua", id = "1c1038a7", version = 31 },
    { path = "data/default/classes/rogue.lua", id = "23d5dce2", version = 32 },
    { path = "data/default/classes/warrior.lua", id = "7bbb4cb9", version = 44 },
}

for _, definition in ipairs(datasets) do
    loadAddonFile(definition.path, Addon)
end

for _, definition in ipairs(datasets) do
    local registered = Addon.Data.DefaultDatasets.Definitions[definition.id]
    assert(registered, "missing registered dataset " .. definition.id)
    assertEqual(registered.version, definition.version, "dataset version " .. definition.id)
end

local expected = {
    ["6e4d2a91"] = {
        ["Moonfire"] = { duration = 5, baseDamage = 17.68, coefficient = 0.22, statRef = "f82db71a:7t7xgzcx" },
        ["Sunfire"] = { duration = 5, baseDamage = 17.68, coefficient = 0.22, statRef = "f82db71a:7t7xgzcx" },
        ["Rake"] = { duration = 5, baseDamage = 17.68, coefficient = 0.1275, statRef = "f82db71a:u7b49vs9" },
        ["Rip"] = { duration = 5, baseDamage = 20.8, coefficient = 0.2, statRef = "f82db71a:u7b49vs9" },
    },
    ["a93f7c12"] = {
        ["Serpent Sting"] = { duration = 5, baseDamage = 20.8, coefficient = 0.15, statRef = "f82db71a:v2rs9cpy" },
        ["Explosive Shot"] = { duration = 2, baseDamage = 19.06125, coefficient = 0.08, statRef = "f82db71a:v2rs9cpy" },
    },
    ["d7c874c4"] = {
        ["Fireball"] = { duration = 5, baseDamage = 17.68, coefficient = 0.22, statRef = "f82db71a:7t7xgzcx" },
        ["Ignite"] = { duration = 3, baseDamage = 28.1667, coefficient = 0.25, statRef = "f82db71a:7t7xgzcx" },
        ["Pyroblast"] = { duration = 5, baseDamage = 17.68, coefficient = 0.26, statRef = "f82db71a:7t7xgzcx" },
    },
    ["b0211ab3"] = {
        ["Consecration"] = { duration = 3, baseDamage = 11.2667, coefficient = 0.14, statRef = "f82db71a:7t7xgzcx" },
        ["Expurgation"] = { duration = 3, baseDamage = 23.9417, coefficient = 0.1, statRef = "f82db71a:u7b49vs9" },
    },
    ["1c1038a7"] = {
        ["Holy Fire"] = { duration = 3, baseDamage = 16.7592, coefficient = 0.18, statRef = "f82db71a:7t7xgzcx" },
        ["Shadow Word: Pain"] = { duration = 5, baseDamage = 20.8, coefficient = 0.42, statRef = "f82db71a:7t7xgzcx" },
        ["Vampiric Touch"] = { duration = 5, baseDamage = 17.68, coefficient = 0.32, statRef = "f82db71a:7t7xgzcx" },
    },
}

expected["23d5dce2"] = {
    ["Rupture"] = { duration = 5, baseDamage = 20.8, coefficient = 0.2, statRef = "f82db71a:u7b49vs9" },
    ["Garrote"] = { duration = 2, baseDamage = 31.7688, coefficient = 0.2224, statRef = "f82db71a:u7b49vs9" },
    ["Deadly Poison"] = { duration = 5, baseDamage = 4.16, coefficient = 0.03, statRef = "f82db71a:u7b49vs9" },
}
expected["7bbb4cb9"] = {
    ["Rend"] = { duration = 5, baseDamage = 20.8, coefficient = 0.15, statRef = "f82db71a:u7b49vs9" },
    ["Deep Wounds"] = { duration = 3, baseDamage = 28.1667, coefficient = 0.0875, statRef = "f82db71a:u7b49vs9" },
}

for datasetId, auraExpectations in pairs(expected) do
    local definition = Addon.Data.DefaultDatasets.Definitions[datasetId]
    assert(definition, "missing periodic dataset " .. datasetId)
    local auras = {}
    for _, aura in ipairs(definition.dataset.auras or {}) do
        auras[aura.name] = aura
    end
    for name, expectedAura in pairs(auraExpectations) do
        local aura = auras[name]
        assert(aura, "missing periodic aura " .. name)
        local effect = aura.effects and aura.effects[1]
        local scaling = effect and effect.statScaling and effect.statScaling[1]
        assertEqual(aura.duration, expectedAura.duration, name .. " duration")
        assertEqual(effect and effect.baseDamage, expectedAura.baseDamage, name .. " base damage")
        assertEqual(scaling and scaling.coefficient, expectedAura.coefficient, name .. " per-tick coefficient")
        assertEqual(scaling and scaling.statRef, expectedAura.statRef, name .. " scaling stat")
    end
end

print("PeriodicAuraAuthoringTest passed")
