local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local definitions = TestSupport.LoadPackagedDefaultData(TestSupport.CreateAddon())
local stats = TestSupport.IndexDatasetEntries({ ["f82db71a"] = definitions["f82db71a"] }, { "stats" })

local expectedPeriodicAuras = {
    ["6e4d2a91"] = { "Moonfire", "Sunfire", "Rake", "Rip" },
    ["a93f7c12"] = { "Serpent Sting", "Explosive Shot" },
    ["d7c874c4"] = { "Fireball", "Ignite", "Pyroblast" },
    ["b0211ab3"] = { "Consecration", "Expurgation" },
    ["1c1038a7"] = { "Holy Fire", "Shadow Word: Pain", "Vampiric Touch" },
    ["23d5dce2"] = { "Rupture", "Garrote", "Deadly Poison" },
    ["7bbb4cb9"] = { "Rend", "Deep Wounds" },
}

local function findByName(collection, name)
    for _, entry in ipairs(collection or {}) do
        if entry.name == name then return entry end
    end
end

for datasetId, names in pairs(expectedPeriodicAuras) do
    local dataset = assert(definitions[datasetId] and definitions[datasetId].dataset,
        "missing periodic dataset " .. datasetId)
    for _, name in ipairs(names) do
        local aura = assert(findByName(dataset.auras, name), "missing periodic aura " .. name)
        local effect = assert(aura.effects and aura.effects[1], name .. " has a periodic effect")
        local scaling = assert(effect.statScaling and effect.statScaling[1], name .. " has stat scaling")
        assertTrue(type(aura.duration) == "number" and aura.duration > 0, name .. " has a positive duration")
        assertTrue(type(effect.baseDamage) == "number", name .. " base damage is numeric")
        assertTrue(type(scaling.coefficient) == "number", name .. " scaling coefficient is numeric")
        assertTrue(stats[scaling.statRef] ~= nil, name .. " scaling stat resolves")
    end
end

print("PeriodicAuraAuthoringTest passed")
