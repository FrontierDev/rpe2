local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local Addon = { Name = "RPEngine2", Data = {}, Internal = {}, Debug = { Internal = function() end } }
loadAddonFile("core/internal/database/Dependecies.lua", Addon)
loadAddonFile("core/internal/database/Database.lua", Addon)
loadAddonFile("data/default/Datasets.lua", Addon)
loadAddonFile("data/default/core.lua", Addon)
loadAddonFile("data/default/classes/druid.lua", Addon)

local definitions = Addon.Data.DefaultDatasets.Definitions
local core = definitions["f82db71a"] and definitions["f82db71a"].dataset
local druidDefinition = definitions["6e4d2a91"]
assertTrue(type(core) == "table", "Core definition is registered")
assertTrue(type(druidDefinition) == "table", "Druid definition is registered")
assertEqual(druidDefinition.dataset.datasetType, "class", "Druid dataset type")
assertEqual(druidDefinition.dataset.groupName, "Core", "Druid dataset group")
assertEqual(druidDefinition.dataset.dependencies[1], "f82db71a", "Druid dependency")

local dataset = druidDefinition.dataset
local class = dataset.classes[1]
assertEqual(class.name, "Druid", "Druid class name")
assertEqual(class.icon, "interface/icons/classicon_druid.blp", "Druid class icon")
assertEqual(#class.talentTraitRefs, 5, "Druid talent trait selection")
for index = 1, #class.talentTraitRefs do
    assertTrue(class.talentTraitRefs[index]:match("^6e4d2a91:") ~= nil, "Druid talent trait ownership")
end

local expectedStats = {
    ["f82db71a:zfqm8dxp"] = { 1, 0.75 },
    ["f82db71a:xqz0daz2"] = { 0, 0.68 },
    ["f82db71a:ygjno50i"] = { 0, 0.85 },
    ["f82db71a:75y3a8ib"] = { 2, 1.32 },
    ["f82db71a:kec9rhli"] = { 2, 1.49 },
}
for index = 1, #class.statProgressions do
    local progression = class.statProgressions[index]
    local expected = expectedStats[progression.statRef]
    assertTrue(expected ~= nil, "Druid stat progression uses an expected Core stat")
    assertEqual(progression.initialValue, expected[1], "Druid stat initial value for " .. progression.statRef)
    assertEqual(progression.perLevelValue, expected[2], "Druid stat level value for " .. progression.statRef)
    expectedStats[progression.statRef] = nil
end
assertTrue(next(expectedStats) == nil, "Druid includes every required stat progression")

local expectedResources = {
    ["f82db71a:q2ktkztt"] = { 33, 24.58 },
    ["f82db71a:4c8mfm99"] = { 17, 20.80 },
}
for index = 1, #class.resourceProgressions do
    local progression = class.resourceProgressions[index]
    local expected = expectedResources[progression.resourceRef]
    assertTrue(expected ~= nil, "Druid resource progression uses an expected Core resource")
    assertEqual(progression.initialValue, expected[1], "Druid resource initial value for " .. progression.resourceRef)
    assertEqual(progression.perLevelValue, expected[2], "Druid resource level value for " .. progression.resourceRef)
    expectedResources[progression.resourceRef] = nil
end
assertTrue(next(expectedResources) == nil, "Druid includes Health and Mana progression")

local function findByName(collection, name)
    for index = 1, #collection do
        if collection[index].name == name then return collection[index] end
    end
end
assertTrue(findByName(dataset.spells, "Wrath") ~= nil, "Balance spell is packaged")
assertTrue(findByName(dataset.spells, "Shred") ~= nil, "Feral spell is packaged")
assertTrue(findByName(dataset.spells, "Healing Touch") ~= nil, "Restoration spell is packaged")
assertTrue(findByName(dataset.spells, "Bear Form") == nil, "Bear Form spell is not packaged")
assertTrue(findByName(dataset.spells, "Cat Form") == nil, "Cat Form spell is not packaged")
assertTrue(findByName(dataset.auras, "Bear Form") == nil, "Bear Form aura is not packaged")
assertTrue(findByName(dataset.auras, "Cat Form") == nil, "Cat Form aura is not packaged")
for _, name in ipairs({ "Maul", "Swipe (Bear)", "Growl", "Demoralizing Roar", "Enrage", "Bash", "Challenging Roar" }) do
    assertEqual(findByName(dataset.spells, name).spellbookCategory, "Guardian", name .. " category")
end

local thorns = findByName(dataset.spells, "Thorns")
local thornsTokens = thorns.tooltipTemplateData.auraSections[1].tokens
assertEqual(#thornsTokens, 4, "Thorns spell tooltip token count")
local thornsTokenKeys = {}
for _, token in ipairs(thornsTokens) do
    assertTrue(type(token) == "table", "Thorns spell tooltip token is a table")
    assertTrue(type(token.key) == "string", "Thorns spell tooltip token has a key")
    assertTrue(thornsTokenKeys[token.key] == nil, "Thorns spell tooltip token keys are siblings")
    thornsTokenKeys[token.key] = true
end
for _, key in ipairs({ "AURA_STAT_1", "AURA_EVENT_DAMAGE_1", "AURA_EVENT_DAMAGE_2", "AURA_EVENT_DAMAGE_3" }) do
    assertTrue(thornsTokenKeys[key] == true, "Thorns spell tooltip includes " .. key)
end

local sunfireAura = findByName(dataset.auras, "Sunfire")
local sunfireSpell = findByName(dataset.spells, "Sunfire")
assertEqual(sunfireAura.effects[1].damageSchoolRefs[1], "f82db71a:qtr10qyj", "Sunfire periodic damage school")
assertEqual(sunfireSpell.components[1].effect.damageSchoolRefs[1], "f82db71a:qtr10qyj", "Sunfire direct damage school")
assertEqual(findByName(dataset.spells, "Prowl").icon, "interface/icons/ability_druid_prowl.blp", "Prowl icon")

local swipe = findByName(dataset.spells, "Swipe")
local swipeResource = swipe.components[2].effect
assertEqual(swipeResource.type, "resource", "Swipe combo-point component type")
assertEqual(swipeResource.resourceRef, "f82db71a:1h7yfxff", "Swipe combo-point resource")
assertEqual(swipeResource.amount, 1, "Swipe combo-point amount")

local rootsBody = findByName(dataset.auras, "Entangling Roots").tooltipTemplateData.bodyText
assertTrue(rootsBody:find("movement range", 1, true) == nil, "Entangling Roots omits movement-range wording")
assertTrue(rootsBody:find("preventing movement", 1, true) ~= nil, "Entangling Roots explains movement prevention")
assertTrue(rootsBody:find("automatically hit", 1, true) ~= nil, "Entangling Roots explains automatic hits")
assertTrue(rootsBody:find("Breaks when it takes damage", 1, true) ~= nil, "Entangling Roots explains its damage break")
assertEqual(findByName(dataset.auras, "Bash").tooltipTemplateData.bodyText, "Stuns the affected unit for 1 turn.", "Bash tooltip")
assertEqual(findByName(dataset.auras, "Pounce").tooltipTemplateData.bodyText, "Stuns the affected unit for 1 turn.", "Pounce tooltip")
assertEqual(findByName(dataset.auras, "Solar Beam").tooltipTemplateData.bodyText, "Silences the affected unit for 1 turn.", "Solar Beam tooltip")

local knownRefs = {}
local collections = { "achievements", "auras", "classes", "currencies", "damageSchools", "itemSlots", "items", "loot", "mounts", "pets", "races", "recipes", "resources", "skills", "spells", "stats", "traits", "units", "weaponTypes" }
for _, definition in pairs(definitions) do
    local source = definition.dataset
    for _, collectionName in ipairs(collections) do
        for _, entry in ipairs(source[collectionName] or {}) do
            if type(entry) == "table" and type(entry.id) == "string" then
                knownRefs[tostring(source.id) .. ":" .. entry.id] = true
            end
        end
    end
end

local function validateRefs(value, path)
    if type(value) == "string" then
        local datasetId, entryId = value:match("^([^:]+):([^:]+)$")
        if datasetId and entryId then
            assertTrue(knownRefs[value] == true, "Druid reference resolves at " .. path .. ": " .. value)
        end
    elseif type(value) == "table" then
        for key, child in pairs(value) do
            validateRefs(child, path .. "." .. tostring(key))
        end
    end
end
validateRefs(dataset, "Druid")

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
