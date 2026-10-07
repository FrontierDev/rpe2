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
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, nestedValue in pairs(value) do copy[key] = deepCopy(nestedValue) end
    return copy
end

local function deepEqual(left, right)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    for key, value in pairs(left) do
        if not deepEqual(value, right[key]) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function findRow(rows, refKey, ref)
    for index = 1, #(rows or {}) do
        if rows[index][refKey] == ref then return rows[index] end
    end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")

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
    TestSupport.LoadAddonFile(path, Addon, "RPEngine2")
end

loadAddonFile("core/classes/Unit.lua")
loadAddonFile("core/classes/UnitPresetSpellEquipment.lua")
loadAddonFile("data/default/core.lua")
loadAddonFile("data/default/classes/warrior.lua")
loadAddonFile("data/default/classes/rogue.lua")
loadAddonFile("data/default/classes/priest.lua")
loadAddonFile("data/default/classes/mage.lua")
loadAddonFile("data/default/classes/warlock.lua")
loadAddonFile("data/default/classes/hunter.lua")
loadAddonFile("data/default/classes/death_knight.lua")
loadAddonFile("data/default/classes/demon_hunter.lua")
loadAddonFile("data/default/classes/druid.lua")
loadAddonFile("data/default/classes/evoker.lua")
loadAddonFile("data/default/classes/monk.lua")
loadAddonFile("data/default/classes/paladin.lua")
loadAddonFile("data/default/classes/shaman.lua")

local Unit = Addon.Internal.Database.Classes.Unit
local core = definitions["f82db71a"]
assert(core, "Core dataset loaded")

local function findUnit(id)
    for index = 1, #(core.units or {}) do
        if core.units[index].id == id then return core.units[index] end
    end
end

local human = findUnit("7i40epa5")
assert(human, "Human Unit exists in Core")
local felguard = findUnit("felgrd01")
assert(felguard, "Felguard Unit exists in Core")
assertEqual(felguard.name, "Felguard", "Felguard unit name")
assertEqual(felguard.creatureType, "demon", "Felguard creature type")
assertEqual(felguard.challengeLevel, "normal", "Felguard challenge level")
assert(#(felguard.presets or {}) > 0, "Felguard has role presets")
assertEqual(felguard.resources[1].initialValue, 208, "Felguard base Health")
assertEqual(felguard.resources[2].resourceRef, "f82db71a:e2tfklq7", "Felguard uses Rage")

local entityRefs = { stats = {}, resources = {}, items = {}, spells = {} }
for datasetId, dataset in pairs(definitions) do
    for _, collection in ipairs({ "stats", "resources", "items", "spells" }) do
        for index = 1, #(dataset[collection] or {}) do
            local entity = dataset[collection][index]
            entityRefs[collection][datasetId .. ":" .. tostring(entity.id)] = true
        end
    end
end

local voidwalker = findUnit("voidw001")
assert(voidwalker, "Voidwalker Unit exists in Core")
local corruptor
for index = 1, #(voidwalker.presets or {}) do
    if voidwalker.presets[index].name == "Corruptor" then
        corruptor = voidwalker.presets[index]
        break
    end
end
assert(corruptor, "Voidwalker Corruptor preset exists")
for index = 1, #(corruptor.spells or {}) do
    assert(entityRefs.spells[corruptor.spells[index]], "Voidwalker Corruptor Spell ref resolves: " .. corruptor.spells[index])
end

assert(#(human.presets or {}) > 0, "Human has role presets")
local originalHuman = deepCopy(human)
local presetNames = {}
for index = 1, #human.presets do
    local preset = human.presets[index]
    assert(type(preset.name) == "string" and preset.name ~= "", "Preset has a display name")
    assert(not presetNames[preset.name], "Preset names are unique: " .. preset.name)
    presetNames[preset.name] = true

    local function verifyModifiers(actual, refKey, collection, label)
        local seen = {}
        for modifierIndex = 1, #(actual or {}) do
            local modifier = actual[modifierIndex]
            local ref = modifier[refKey]
            assert(type(ref) == "string" and ref ~= "", label .. " ref is present for " .. preset.name)
            assert(not seen[ref], label .. " refs are unique for " .. preset.name)
            seen[ref] = true
            assert(entityRefs[collection][ref], label .. " ref resolves: " .. ref)
            assert(type(modifier.percentBonus) == "number", label .. " percent bonus is numeric")
            assert(type(modifier.flatBonus) == "number", label .. " flat bonus is numeric")
        end
    end
    verifyModifiers(preset.statModifiers, "statRef", "stats", "stat")
    verifyModifiers(preset.resourceModifiers, "resourceRef", "resources", "resource")

    local effectiveSpells = Unit.ResolveEffectiveSpells(human, index)
    for spellIndex = 1, #effectiveSpells do
        assert(entityRefs.spells[effectiveSpells[spellIndex]], "Spell ref resolves: " .. effectiveSpells[spellIndex])
    end
    local effectiveEquipment = Unit.ResolveEffectiveEquipment(human, index)
    for slot, itemRef in pairs(effectiveEquipment) do
        assert(entityRefs.items[itemRef], "Equipment ref resolves for " .. slot .. ": " .. itemRef)
    end

    local resolvedPreset = Unit.ResolvePreset(human, index)
    for _, level in ipairs({ 1, 60 }) do
        local baseStats = Unit.ResolveStatValues(human, level)
        local baseResources = Unit.ResolveResourceValues(human, level)
        local actualStats = Unit.ApplyStatModifiers(baseStats, resolvedPreset)
        local actualResources = Unit.ApplyResourceModifiers(baseResources, resolvedPreset)
        for modifierIndex = 1, #(resolvedPreset.statModifiers or {}) do
            local modifier = resolvedPreset.statModifiers[modifierIndex]
            local baseRow = findRow(baseStats, "statRef", modifier.statRef)
            local actualRow = findRow(actualStats, "statRef", modifier.statRef)
            if baseRow and actualRow then
                local expected = baseRow.value * (1 + modifier.percentBonus / 100) + modifier.flatBonus
                assertNear(actualRow.value, expected, preset.name .. " stat modifier at level " .. level)
            end
        end
        for modifierIndex = 1, #(resolvedPreset.resourceModifiers or {}) do
            local modifier = resolvedPreset.resourceModifiers[modifierIndex]
            local baseRow = findRow(baseResources, "resourceRef", modifier.resourceRef)
            local actualRow = findRow(actualResources, "resourceRef", modifier.resourceRef)
            if baseRow and actualRow then
                local expected = math.max(0, baseRow.value * (1 + modifier.percentBonus / 100) + modifier.flatBonus)
                assertNear(actualRow.value, expected, preset.name .. " resource modifier at level " .. level)
            end
        end
    end
    assert(deepEqual(human, originalHuman), "Resolving presets does not mutate the base Human")
end

local noPresetStats = Unit.ResolveStatValues(human, 60)
local noPresetResources = Unit.ResolveResourceValues(human, 60)
local noPreset = Unit.ResolvePreset(human, 0)
assert(deepEqual(Unit.ApplyStatModifiers(noPresetStats, noPreset), noPresetStats), "No preset keeps base Human stats")
assert(deepEqual(Unit.ApplyResourceModifiers(noPresetResources, noPreset), noPresetResources), "No preset keeps base Human resources")
assert(deepEqual(Unit.ResolveEffectiveSpells(human, 0), human.spells), "No preset keeps base Human spells")
assert(deepEqual(Unit.ResolveEffectiveEquipment(human, 0), {
    mainHandWeapon = "f82db71a:stwswd01",
}), "No preset keeps base Human equipment")

local serialized = Unit.FromTable(human):ToTable()
assertEqual(#serialized.presets, #human.presets, "Preset count survives serialization")
for index = 1, #serialized.presets do
    assert(deepEqual(serialized.presets[index].spells, human.presets[index].spells), "Preset spells survive serialization at index " .. index)
    assert(deepEqual(serialized.presets[index].equipment, human.presets[index].equipment), "Preset equipment survives serialization at index " .. index)
end

print("NpcRolePresetsTest passed")
