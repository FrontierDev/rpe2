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
local dataset = assert(definitions["6e4d2a91"] and definitions["6e4d2a91"].dataset, "Druid definition is registered")
local coreEntries = TestSupport.IndexDatasetEntries({ ["f82db71a"] = definitions["f82db71a"] }, { "resources", "stats" })
local traits = TestSupport.IndexDatasetEntries({ [dataset.id] = { dataset = dataset } }, { "traits" })

assertEqual(dataset.datasetType, "class", "Druid dataset type")
assertEqual(dataset.name, "Druid", "Druid dataset name")
local class = assert(dataset.classes[1], "Druid class definition exists")
assertEqual(class.name, "Druid", "Druid class name")

for _, field in ipairs({ "passiveTraitRefs", "talentTraitRefs" }) do
    local seen = {}
    for _, reference in ipairs(class[field] or {}) do
        assertTrue(traits[reference] ~= nil, "Druid " .. field .. " resolves: " .. tostring(reference))
        assertTrue(not seen[reference], "Druid " .. field .. " does not duplicate " .. reference)
        seen[reference] = true
    end
end

for _, specification in ipairs({
    { collection = "statProgressions", field = "statRef" },
    { collection = "resourceProgressions", field = "resourceRef" },
}) do
    local seen = {}
    assertTrue(#(class[specification.collection] or {}) > 0, "Druid has " .. specification.collection)
    for _, progression in ipairs(class[specification.collection]) do
        local reference = progression[specification.field]
        assertTrue(coreEntries[reference] ~= nil, "Druid progression resolves: " .. tostring(reference))
        assertTrue(not seen[reference], "Druid progression does not duplicate " .. reference)
        seen[reference] = true
        assertTrue(type(progression.initialValue) == "number", "Druid progression initial value is numeric")
        assertTrue(type(progression.perLevelValue) == "number", "Druid progression per-level value is numeric")
    end
end

local function findByName(collection, name)
    for _, entry in ipairs(collection or {}) do
        if entry.name == name then return entry end
    end
end

-- Role availability and resource generation are gameplay contracts; do not
-- turn tooltip text or the complete authored spell list into a data snapshot.
for _, name in ipairs({ "Wrath", "Shred", "Healing Touch" }) do
    assertTrue(findByName(dataset.spells, name) ~= nil, "Druid role spell is packaged: " .. name)
end
local bearFormTrait = assert(findByName(dataset.traits, "Bear Form"), "Bear Form trait is packaged")
assertEqual(bearFormTrait.events[1].combatEventId, "on_auto_attack_hit", "Bear Form hit trigger")
assertEqual(bearFormTrait.events[1].effects[1].amount, 10, "Bear Form hit resource")
assertEqual(bearFormTrait.events[2].combatEventId, "on_auto_attack_taken", "Bear Form taken trigger")
assertEqual(bearFormTrait.events[2].effects[1].amount, 2, "Bear Form taken resource")

for _, name in ipairs({ "Maul", "Swipe (Bear)", "Growl", "Demoralizing Roar", "Enrage", "Bash", "Challenging Roar" }) do
    assertEqual(assert(findByName(dataset.spells, name), name .. " is packaged").spellbookCategory, "Guardian", name .. " category")
end

local swipe = assert(findByName(dataset.spells, "Swipe"), "Swipe is packaged")
local swipeResource = swipe.components[2].effect
assertEqual(swipeResource.type, "resource", "Swipe combo-point component type")
assertEqual(swipeResource.amount, 1, "Swipe combo-point amount")
assertTrue(coreEntries[swipeResource.resourceRef] ~= nil, "Swipe combo-point resource resolves")

local toc = assert(io.open("RPEngine2.toc", "r"))
local tocText = toc:read("*a")
toc:close()
assertTrue(tocText:find("data/default/classes/druid.lua", 1, true) ~= nil, "Druid is registered in the packaged TOC")

local ruleset = assert(io.open("data/default/Ruleset.lua", "r"))
local rulesetText = ruleset:read("*a")
ruleset:close()
assertTrue(rulesetText:find("6e4d2a91:drdruid1", 1, true) ~= nil, "Druid is allowed by the default setup rules")
assertTrue(rulesetText:find('"6e4d2a91"', 1, true) ~= nil, "Druid dataset is forced by the default setup rules")

print("DruidDatasetTest passed")
