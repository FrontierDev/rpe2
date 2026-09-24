local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk('RPEngine2', addon)
end

local Addon = { Data = {} }
loadAddonFile('data/default/Datasets.lua', Addon)

local files = {
    core = 'data/default/core.lua',
    mage = 'data/default/classes/mage.lua',
    paladin = 'data/default/classes/paladin.lua',
    priest = 'data/default/classes/priest.lua',
}
for _, path in pairs(files) do loadAddonFile(path, Addon) end

local spellPowerRef = 'f82db71a:7t7xgzcx'
local expected = {
    core = { 1.0 },
    mage = { 0.22, 0.25, 0.26, 0.4016, 0.46, 0.5526, 0.612, 0.63, 0.6826, 0.845, 0.8926, 1.04, 1.19, 1.2496, 1.2496, 1.9126, 2.6776, 2.8114, 3.5382 },
    paladin = { 0.14, 0.4, 0.845, 0.96, 1.105, 1.6 },
    priest = { 0.18, 0.32, 0.42, 0.7, 0.833, 1.2496, 1.47, 1.82, 2.25 },
}

local function collectDamageSpellPower(value, results, visited)
    if type(value) ~= 'table' or visited[value] then return end
    visited[value] = true
    if value.type == 'damage' then
        for _, scaling in ipairs(value.statScaling or {}) do
            if scaling.statRef == spellPowerRef then results[#results + 1] = scaling.coefficient end
        end
    end
    for _, child in pairs(value) do collectDamageSpellPower(child, results, visited) end
end

for name, path in pairs(files) do
    local datasetId = name == 'core' and 'f82db71a' or ({ mage = 'd7c874c4', paladin = 'b0211ab3', priest = '1c1038a7' })[name]
    local dataset = Addon.Data.DefaultDatasets.Definitions[datasetId].dataset
    local actual = {}
    collectDamageSpellPower(dataset, actual, {})
    table.sort(actual)
    table.sort(expected[name])
    assertEqual(#actual, #expected[name], name .. ' Spell Power damage effect count')
    for index = 1, #expected[name] do
        assertEqual(actual[index], expected[name][index], name .. ' Spell Power damage coefficient ' .. index)
    end
end

local priest = Addon.Data.DefaultDatasets.Definitions['1c1038a7'].dataset
local foundVampiricRegeneration = false
local function verifyVampiricRegeneration(value, visited)
    if type(value) ~= 'table' or visited[value] then return end
    visited[value] = true
    if value.type == 'heal' and value.baseDamage == 8.84 then
        for _, scaling in ipairs(value.statScaling or {}) do
            if scaling.statRef == spellPowerRef then
                assertEqual(scaling.coefficient, 0.221, 'Vampiric Regeneration remains non-damage scaling')
                foundVampiricRegeneration = true
            end
        end
    end
    for _, child in pairs(value) do verifyVampiricRegeneration(child, visited) end
end
verifyVampiricRegeneration(priest, {})
assertEqual(foundVampiricRegeneration, true, 'Vampiric Regeneration is present')

print('SpellPowerDamageBalanceTest passed')
