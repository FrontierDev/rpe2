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
    chunk(nil, addon)
end

local Addon = { Data = {} }
loadAddonFile("data/default/Datasets.lua", Addon)
loadAddonFile("data/default/core.lua", Addon)
loadAddonFile("data/default/classes/paladin.lua", Addon)
loadAddonFile("data/default/classes/warrior.lua", Addon)
loadAddonFile("data/default/classes/shaman.lua", Addon)

local definitions = Addon.Data.DefaultDatasets.Definitions
local coreDataset = definitions["f82db71a"].dataset
local paladinDataset = definitions["b0211ab3"].dataset
local warriorDataset = definitions["7bbb4cb9"].dataset
local shamanDataset = definitions["c4a91e7d"].dataset
local SHIELD_BLOCK_VALUE_REF = "f82db71a:sblkval1"
local BLOCK_CHANCE_REF = "f82db71a:p8syz5ba"

local shieldBlockValueStat
for index = 1, #coreDataset.stats do
    if coreDataset.stats[index].id == "sblkval1" then
        shieldBlockValueStat = coreDataset.stats[index]
        break
    end
end
assertTrue(shieldBlockValueStat ~= nil, "Core Shield Block Value stat resolves")

assertEqual(definitions["b0211ab3"].version, 57, "Paladin dataset version")
assertEqual(definitions["7bbb4cb9"].version, 46, "Warrior dataset version")
assertEqual(definitions["c4a91e7d"].version, 10, "Shaman dataset version remains unchanged")

local function findById(items, id)
    for index = 1, #items do
        if items[index].id == id then return items[index] end
    end
end

local function findByName(items, name)
    for index = 1, #items do
        if items[index].name == name then return items[index] end
    end
end

local function collectStats(item)
    assertTrue(type(item) == "table", "item exists")
    local values = {}
    for index = 1, #(item.stats or {}) do
        local stat = item.stats[index]
        assertTrue(values[stat.sourceStatRef] == nil, item.name .. " has no duplicate stat reference")
        values[stat.sourceStatRef] = stat.value
    end
    return values
end

local function assertItemValues(items, id, shieldBlockValue, blockChance)
    local item = findById(items, id)
    local values = collectStats(item)
    assertEqual(values[SHIELD_BLOCK_VALUE_REF], shieldBlockValue, item.name .. " Shield Block Value")
    assertEqual(values[BLOCK_CHANCE_REF], blockChance, item.name .. " Block Chance")
end

for id, value in pairs({
    i7f32pv7 = 12,
    t2p8grvs = 14,
    t2p8legs = 21,
    t2p8paul = 14,
    t2p8wast = 17,
    s05tlegs = 19,
    s05twais = 15,
}) do
    assertItemValues(paladinDataset.items, id, value, id == "t2p8grvs" and 2 or nil)
end

assertItemValues(paladinDataset.items, "t2p8chst", nil, 3)
assertItemValues(paladinDataset.items, "t2p8hand", nil, 1)
assertItemValues(paladinDataset.items, "s05thand", nil, 3)
assertItemValues(warriorDataset.items, "h05tchst", 15, nil)
assertItemValues(warriorDataset.items, "h05tlegs", 21, nil)
assertItemValues(warriorDataset.items, "h05thnds", nil, 3)

for index = 1, #shamanDataset.items do
    assertEqual(collectStats(shamanDataset.items[index])[SHIELD_BLOCK_VALUE_REF], nil, "Shaman items do not gain Shield Block Value")
end
for name, blockChance in pairs({
    ["Chestguard of The Five Thunders"] = 3,
    ["Handguards of The Five Thunders"] = 2,
    ["Chestguard of Ten Storms"] = 1,
    ["Faceguard of Ten Storms"] = 2,
    ["Legguards of Ten Storms"] = 2,
    ["Waistguard of Ten Storms"] = 1,
    ["Wristguards of Ten Storms"] = 1,
}) do
    assertEqual(collectStats(findByName(shamanDataset.items, name))[BLOCK_CHANCE_REF], blockChance, name .. " genuine Block Chance")
end

local function readFile(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a")
    file:close()
    return text
end

local function importStatValues(text, id)
    local idStart = assert(text:find('id = "' .. id .. '"', 1, true), id .. " import entry")
    local statsStart = assert(text:find("stats = {", idStart, true), id .. " import stats")
    local statsEnd = assert(text:find("        tags =", statsStart, true), id .. " import stats end")
    local stats = text:sub(statsStart, statsEnd)
    local function valueFor(statRef)
        return tonumber(stats:match('sourceStatRef = "' .. statRef .. '",%s*value = (%d+)'))
    end
    return valueFor(SHIELD_BLOCK_VALUE_REF), valueFor(BLOCK_CHANCE_REF)
end

local judgementImports = readFile(".docs/import-codes/paladin-tier-2-sod/wilfull-judgement-protection.md")
for id, value in pairs({ i7f32pv7 = 12, t2p8grvs = 14, t2p8legs = 21, t2p8paul = 14, t2p8wast = 17 }) do
    local shieldBlockValue, blockChance = importStatValues(judgementImports, id)
    assertEqual(shieldBlockValue, value, id .. " prepared Shield Block Value")
    assertEqual(blockChance, id == "t2p8grvs" and 2 or nil, id .. " prepared Block Chance")
end

local soulforgeImports = readFile(".docs/import-codes/paladin-tier-0.5-sod/soulforge-protection.md")
for id, value in pairs({ s05tlegs = 19, s05twais = 15 }) do
    local shieldBlockValue, blockChance = importStatValues(soulforgeImports, id)
    assertEqual(shieldBlockValue, value, id .. " prepared Shield Block Value")
    assertEqual(blockChance, nil, id .. " prepared Block Chance")
end

local heroismImports = readFile(".docs/import-codes/warrior-tier-0.5-sod/immoveable-heroism-tank.md")
for id, value in pairs({ h05tchst = 15, h05tlegs = 21 }) do
    local shieldBlockValue, blockChance = importStatValues(heroismImports, id)
    assertEqual(shieldBlockValue, value, id .. " prepared Shield Block Value")
    assertEqual(blockChance, nil, id .. " prepared Block Chance")
end

print("ShieldBlockValueMigrationTest passed")
