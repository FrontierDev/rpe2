local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertNear(actual, expected, message)
    if type(actual) ~= "number" or math.abs(actual - expected) > 0.000001 then
        error(("%s: expected %.9f, got %s"):format(message, expected, tostring(actual)), 2)
    end
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end
    return copy
end

local function deepEqual(left, right)
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return left == right
    end
    for key, value in pairs(left) do
        if not deepEqual(value, right[key]) then
            return false
        end
    end
    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function findRow(rows, refKey, ref)
    for index = 1, #(rows or {}) do
        if rows[index][refKey] == ref then
            return rows[index]
        end
    end
end

local definitions = {}
local Addon = {
    Internal = { Database = { Classes = {} } },
    Data = {
        DefaultDatasets = {
            Register = function(_, definition)
                definitions[definition.dataset.id] = definition.dataset
                return definition
            end,
        },
    },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("core/classes/Unit.lua")
loadAddonFile("core/classes/UnitPresetSpellEquipment.lua")
loadAddonFile("data/default/core.lua")
loadAddonFile("data/default/classes/warrior.lua")
loadAddonFile("data/default/classes/rogue.lua")
loadAddonFile("data/default/classes/priest.lua")
loadAddonFile("data/default/classes/mage.lua")

local Unit = Addon.Internal.Database.Classes.Unit
local core = definitions["f82db71a"]
assert(core, "Core dataset loaded")

local human
for index = 1, #(core.units or {}) do
    if core.units[index].id == "7i40epa5" then
        human = core.units[index]
        break
    end
end
assert(human, "Human Unit exists in Core")

local expected = {
    Footman = {
        resources = { ["f82db71a:q2ktkztt"] = { 15, 0 } },
        stats = {
            ["f82db71a:v42albuv"] = { 35, 0 },
            ["f82db71a:p8syz5ba"] = { 0, 10 },
            ["f82db71a:tcn0s8kx"] = { 0, 3 },
            ["f82db71a:u7b49vs9"] = { 5, 0 },
        },
        spells = { "f82db71a:z36xzk0w", "7bbb4cb9:ti2j4umn", "7bbb4cb9:tntwar01" },
        equipment = { mainHandWeapon = "f82db71a:stwswd01", shield = "f82db71a:stshld01" },
    },
    Berserker = {
        resources = { ["f82db71a:q2ktkztt"] = { 10, 0 } },
        stats = {
            ["f82db71a:v42albuv"] = { -25, 0 },
            ["f82db71a:u7b49vs9"] = { 20, 0 },
            ["f82db71a:jslmczbi"] = { 0, 5 },
            ["f82db71a:gj9wxb0x"] = { 0, 10 },
        },
        spells = { "f82db71a:z36xzk0w", "7bbb4cb9:c1s93sif", "7bbb4cb9:e0mooybr", "7bbb4cb9:berrage1" },
        equipment = { mainHandWeapon = "f82db71a:stw2sw01" },
    },
    Archer = {
        resources = { ["f82db71a:q2ktkztt"] = { -15, 0 } },
        stats = {
            ["f82db71a:v42albuv"] = { -25, 0 },
            ["f82db71a:v2rs9cpy"] = { 20, 0 },
            ["f82db71a:dd88li4c"] = { 0, 5 },
            ["f82db71a:fercjhm5"] = { 0, 5 },
        },
        equipment = { rangedWeapon = "f82db71a:stwbow01" },
    },
    Assassin = {
        resources = { ["f82db71a:q2ktkztt"] = { -20, 0 } },
        stats = {
            ["f82db71a:v42albuv"] = { -35, 0 },
            ["f82db71a:u7b49vs9"] = { 15, 0 },
            ["f82db71a:wbj4zuf3"] = { 0, 5 },
            ["f82db71a:jslmczbi"] = { 0, 10 },
            ["f82db71a:o6113cir"] = { 0, 10 },
        },
        spells = { "f82db71a:z36xzk0w", "23d5dce2:3yvu5lwf", "23d5dce2:pfskjkhi", "23d5dce2:kbifnqpj" },
        equipment = { mainHandWeapon = "f82db71a:stwdgr01" },
    },
    Mage = {
        resources = { ["f82db71a:q2ktkztt"] = { -25, 0 } },
        stats = {
            ["f82db71a:v42albuv"] = { -60, 0 },
            ["f82db71a:7t7xgzcx"] = { 25, 0 },
            ["f82db71a:v2g0tw0o"] = { 0, 5 },
            ["f82db71a:69hfqhne"] = { 0, 5 },
            ["f82db71a:zs1nbz13"] = { 0, 5 },
        },
        spells = {
            "d7c874c4:68dy7na1", "d7c874c4:lywroiqu", "d7c874c4:7ha8pdoy",
            "d7c874c4:polymr01", "d7c874c4:fireward", "d7c874c4:mgarma01",
        },
        equipment = { mainHandWeapon = "f82db71a:stwstf01" },
    },
    Priest = {
        resources = { ["f82db71a:q2ktkztt"] = { -20, 0 } },
        stats = {
            ["f82db71a:v42albuv"] = { -45, 0 },
            ["f82db71a:hj6d4kvy"] = { 30, 0 },
            ["f82db71a:7t7xgzcx"] = { 10, 0 },
            ["f82db71a:v2g0tw0o"] = { 0, 5 },
            ["f82db71a:69hfqhne"] = { 0, 5 },
            ["f82db71a:zs1nbz13"] = { 0, 5 },
        },
        spells = { "1c1038a7:eet5xd4t", "1c1038a7:pwshld01", "1c1038a7:qqkkenuw", "1c1038a7:rm9rekvj" },
        equipment = { mainHandWeapon = "f82db71a:stwmac01" },
    },
    Battlemage = {
        resources = { ["f82db71a:q2ktkztt"] = { 5, 0 } },
        stats = {
            ["f82db71a:v42albuv"] = { 25, 0 },
            ["f82db71a:7t7xgzcx"] = { 15, 0 },
            ["f82db71a:v2g0tw0o"] = { 0, 3 },
            ["f82db71a:69hfqhne"] = { 0, 3 },
            ["f82db71a:zs1nbz13"] = { 0, 10 },
            ["f82db71a:u7b49vs9"] = { 10, 0 },
        },
        spells = { "f82db71a:z36xzk0w", "d7c874c4:68dy7na1", "d7c874c4:fireward", "d7c874c4:mgarma01" },
        equipment = { mainHandWeapon = "f82db71a:stwmac01", shield = "f82db71a:stshld01" },
    },
    Commander = {
        resources = { ["f82db71a:q2ktkztt"] = { 30, 0 } },
        stats = {
            ["f82db71a:v42albuv"] = { 20, 0 },
            ["f82db71a:u7b49vs9"] = { 10, 0 },
            ["f82db71a:wbj4zuf3"] = { 0, 3 },
            ["f82db71a:tcn0s8kx"] = { 0, 5 },
            ["f82db71a:j8n012e6"] = { 0, 25 },
            ["f82db71a:gj9wxb0x"] = { 0, 5 },
        },
        spells = {
            "f82db71a:z36xzk0w", "7bbb4cb9:c1s93sif", "7bbb4cb9:tntwar01",
            "7bbb4cb9:9gh28pe5", "7bbb4cb9:demoshot",
        },
        equipment = { mainHandWeapon = "f82db71a:stwswd01" },
    },
}

local entityRefs = { stats = {}, resources = {}, items = {}, spells = {} }
for datasetId, dataset in pairs(definitions) do
    for _, collection in ipairs({ "stats", "resources", "items", "spells" }) do
        for index = 1, #(dataset[collection] or {}) do
            local entity = dataset[collection][index]
            entityRefs[collection][datasetId .. ":" .. tostring(entity.id)] = true
        end
    end
end

assertEqual(#human.presets, 8, "Human has eight role presets")
local originalHuman = deepCopy(human)
local presetIndexes = {}
for index = 1, #human.presets do
    local preset = human.presets[index]
    local name = preset.name
    local expectedPreset = expected[name]
    assert(expectedPreset, "Known Human preset " .. tostring(name))
    assertEqual(presetIndexes[name], nil, "Preset name is unique")
    presetIndexes[name] = index

    local function verifyModifiers(actual, expectedModifiers, refKey, label)
        local actualByRef = {}
        for modifierIndex = 1, #(actual or {}) do
            local modifier = actual[modifierIndex]
            local ref = modifier[refKey]
            assertEqual(actualByRef[ref], nil, label .. " refs are unique for " .. name)
            actualByRef[ref] = modifier
            assert(entityRefs[refKey == "statRef" and "stats" or "resources"][ref], label .. " ref resolves: " .. tostring(ref))
        end
        local expectedCount = 0
        for ref, values in pairs(expectedModifiers) do
            expectedCount = expectedCount + 1
            local modifier = actualByRef[ref]
            assert(modifier, label .. " modifier exists for " .. name .. ": " .. ref)
            assertNear(modifier.percentBonus, values[1], label .. " percent for " .. name .. ": " .. ref)
            assertNear(modifier.flatBonus, values[2], label .. " flat for " .. name .. ": " .. ref)
        end
        local actualCount = 0
        for _ in pairs(actualByRef) do actualCount = actualCount + 1 end
        assertEqual(actualCount, expectedCount, label .. " modifier count for " .. name)
    end

    verifyModifiers(preset.statModifiers, expectedPreset.stats, "statRef", "stat")
    verifyModifiers(preset.resourceModifiers, expectedPreset.resources, "resourceRef", "resource")

    local effectiveSpells = Unit.ResolveEffectiveSpells(human, index)
    assert(deepEqual(effectiveSpells, expectedPreset.spells or human.spells), "Effective spells match the role or inherit for " .. name)
    for spellIndex = 1, #effectiveSpells do
        assert(entityRefs.spells[effectiveSpells[spellIndex]], "Spell ref resolves: " .. effectiveSpells[spellIndex])
    end

    local effectiveEquipment = Unit.ResolveEffectiveEquipment(human, index)
    assert(deepEqual(effectiveEquipment, expectedPreset.equipment), "Effective equipment matches the role for " .. name)
    for _, itemRef in pairs(effectiveEquipment) do
        assert(entityRefs.items[itemRef], "Item ref resolves: " .. itemRef)
    end

    local resolvedPreset = Unit.ResolvePreset(human, index)
    for _, level in ipairs({ 1, 60 }) do
        local baseStats = Unit.ResolveStatValues(human, level)
        local baseResources = Unit.ResolveResourceValues(human, level)
        local actualStats = Unit.ApplyStatModifiers(baseStats, resolvedPreset)
        local actualResources = Unit.ApplyResourceModifiers(baseResources, resolvedPreset)

        for ref, values in pairs(expectedPreset.stats) do
            local baseRow = findRow(baseStats, "statRef", ref)
            local baseValue = baseRow and baseRow.value or 0
            local expectedValue = baseValue * (1 + values[1] / 100) + values[2]
            assertNear(findRow(actualStats, "statRef", ref).value, expectedValue, name .. " stat at level " .. level .. ": " .. ref)
        end
        for ref, values in pairs(expectedPreset.resources) do
            local baseRow = findRow(baseResources, "resourceRef", ref)
            local baseValue = baseRow and baseRow.value or 0
            local expectedValue = math.max(0, baseValue * (1 + values[1] / 100) + values[2])
            assertNear(findRow(actualResources, "resourceRef", ref).value, expectedValue, name .. " resource at level " .. level .. ": " .. ref)
        end

        if index == 1 and level == 60 then
            assertNear(findRow(actualStats, "statRef", "f82db71a:v42albuv").value, 2025, "Footman Armor at level 60")
        elseif index == 2 and level == 60 then
            assertNear(findRow(actualStats, "statRef", "f82db71a:u7b49vs9").value, 361.2, "Berserker Melee AP at level 60")
        elseif index == 3 and level == 60 then
            assertNear(findRow(actualStats, "statRef", "f82db71a:v2rs9cpy").value, 361.2, "Archer Ranged AP at level 60")
        elseif index == 5 and level == 60 then
            assertNear(findRow(actualStats, "statRef", "f82db71a:7t7xgzcx").value, 374.65, "Mage Spell Power at level 60")
        elseif index == 6 and level == 60 then
            assertNear(findRow(actualStats, "statRef", "f82db71a:hj6d4kvy").value, 383.5, "Priest Healing Power at level 60")
        elseif index == 8 and level == 60 then
            assertNear(findRow(actualResources, "resourceRef", "f82db71a:q2ktkztt").value, 2543.021, "Commander Health at level 60")
        end
    end

    assert(deepEqual(human, originalHuman), "Resolving presets does not mutate the base Human")
end

local noPresetStats = Unit.ResolveStatValues(human, 60)
local noPresetResources = Unit.ResolveResourceValues(human, 60)
assert(deepEqual(Unit.ApplyStatModifiers(noPresetStats, Unit.ResolvePreset(human, 0)), noPresetStats), "No preset keeps base Human stats")
assert(deepEqual(Unit.ApplyResourceModifiers(noPresetResources, Unit.ResolvePreset(human, 0)), noPresetResources), "No preset keeps base Human resources")
assert(deepEqual(Unit.ResolveEffectiveSpells(human, 0), human.spells), "No preset keeps base Human spells")
assert(deepEqual(Unit.ResolveEffectiveEquipment(human, 0), { mainHandWeapon = "f82db71a:stwswd01" }), "No preset keeps base Human equipment")
for _, level in ipairs({ 1, 60 }) do
    assert(deepEqual(Unit.ApplyStatModifiers(Unit.ResolveStatValues(human, level), Unit.ResolvePreset(human, 0)), Unit.ResolveStatValues(human, level)), "No preset keeps base stats at level " .. level)
    assert(deepEqual(Unit.ApplyResourceModifiers(Unit.ResolveResourceValues(human, level), Unit.ResolvePreset(human, 0)), Unit.ResolveResourceValues(human, level)), "No preset keeps base resources at level " .. level)
end
assert(findRow(human.stats, "statRef", "f82db71a:gj9wxb0x") == nil, "Damage Done stays variant-only on Human")
for index = 1, #(core.stats or {}) do
    local stat = core.stats[index]
    if stat.name == "Damage Reduction" then
        assert(findRow(human.stats, "statRef", "f82db71a:" .. stat.id) == nil, "Damage Reduction stays absent from Human")
    end
end

local serialized = Unit.FromTable(human):ToTable()
assertEqual(#serialized.presets, 8, "Preset count survives serialization")
for index = 1, #serialized.presets do
    assert(deepEqual(serialized.presets[index].spells, human.presets[index].spells), "Preset spells survive serialization at index " .. index)
    assert(deepEqual(serialized.presets[index].equipment, human.presets[index].equipment), "Preset equipment survives serialization at index " .. index)
end

print("NpcRolePresetsTest passed")
