local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local definitions = TestSupport.LoadPackagedDefaultData(TestSupport.CreateAddon())
local collections = {
    "achievements", "auras", "classes", "currencies", "damageSchools", "guildSettings",
    "itemSlots", "items", "loot", "mounts", "pets", "races", "recipes", "resources",
    "skills", "spells", "stats", "traits", "units", "weaponTypes",
}
local entries = TestSupport.IndexDatasetEntries(definitions, collections)
local typedEntries = {}
for _, collectionName in ipairs(collections) do
    typedEntries[collectionName] = {}
    for datasetId, definition in pairs(definitions) do
        for _, entry in ipairs(definition.dataset[collectionName] or {}) do
            if type(entry) == "table" and type(entry.id) == "string" and entry.id ~= "" then
                typedEntries[collectionName][datasetId .. ":" .. entry.id] = entry
            end
        end
    end
end

local function countEntry(collection, id)
    local count = 0
    for _, entry in ipairs(collection or {}) do
        if type(entry) == "table" and entry.id == id then count = count + 1 end
    end
    return count
end

for datasetId, definition in pairs(definitions) do
    local dataset = definition.dataset
    assertTrue(dataset.id == datasetId, "dataset registration key matches payload: " .. tostring(datasetId))
    assertTrue(type(definition.version) == "number" and definition.version > 0 and definition.version == math.floor(definition.version),
        datasetId .. " has a positive integer packaged version")
    for _, collectionName in ipairs(collections) do
        local ids = {}
        for index, entry in ipairs(dataset[collectionName] or {}) do
            assertTrue(type(entry) == "table",
                datasetId .. " " .. collectionName .. " entry " .. index .. " is a table")
            assertTrue(type(entry) == "table" and entry.id ~= nil,
                datasetId .. " " .. collectionName .. " entry " .. index .. " has an ID")
            if type(entry) == "table" and entry.id ~= nil then
                assertTrue(type(entry.id) == "string" and entry.id ~= "",
                    datasetId .. " " .. collectionName .. " entry " .. index .. " has an ID")
                assertTrue(not ids[entry.id], datasetId .. " " .. collectionName .. " has duplicate ID " .. entry.id)
                ids[entry.id] = true

                if collectionName == "auras" then
                    assertTrue(entry.components == nil,
                        datasetId .. " aura " .. entry.id .. " is not a spell-shaped entry")
                    assertTrue(type(entry.duration) == "number" and type(entry.effects) == "table" and entry.stackBehavior ~= nil,
                        datasetId .. " aura " .. entry.id .. " has a valid aura shape")
                elseif collectionName == "spells" then
                    assertTrue(entry.duration == nil and entry.effects == nil and entry.stackBehavior == nil,
                        datasetId .. " spell " .. entry.id .. " is not an aura-shaped entry")
                    assertTrue(type(entry.components) == "table" and #entry.components > 0,
                        datasetId .. " spell " .. entry.id .. " has components")
                    for componentIndex, component in ipairs(entry.components) do
                        assertTrue(type(component) == "table" and type(component.effect) == "table" and type(component.target) == "table",
                            ("%s spell %s component %d is structurally valid"):format(datasetId, entry.id, componentIndex))
                    end
                end
            end
        end
    end
end

local referenceFields = {
    auraRef = true, classRef = true, currencyRef = true, damageSchoolRef = true,
    itemRef = true, itemSlotRef = true, lootRef = true, mountRef = true, petRef = true,
    raceRef = true, resourceRef = true, skillRef = true, spellRef = true, statRef = true,
    traitRef = true, unitRef = true, weaponTypeRef = true,
}

local function assertReference(reference, path)
    if type(reference) ~= "string" or not reference:find(":", 1, true) then return end
    assertTrue(entries[reference] ~= nil, "packaged reference resolves at " .. path .. ": " .. reference)
end

local function assertTypedReference(reference, collectionName, path)
    assertReference(reference, path)
    if type(reference) == "string" and reference:find(":", 1, true) then
        assertTrue(typedEntries[collectionName][reference] ~= nil,
            "typed packaged reference resolves at " .. path .. ": " .. reference .. " (expected " .. collectionName .. ")")
    end
end

local core = definitions["f82db71a"].dataset
for _, auraId in ipairs({ "nrbvenau", "harscrau" }) do
    assertEqual(countEntry(core.auras, auraId), 1, "Core aura appears exactly once: " .. auraId)
    assertEqual(countEntry(core.spells, auraId), 0, "Core aura is not in spells: " .. auraId)
end
for _, spellId in ipairs({ "nrbven01", "harscr01" }) do
    assertEqual(countEntry(core.spells, spellId), 1, "Core consuming spell appears exactly once: " .. spellId)
end

local warrior = definitions["7bbb4cb9"].dataset
assertEqual(countEntry(warrior.spells, "cncblow1"), 1, "Warrior Concussive Blow is a top-level spell")
assertEqual(countEntry(warrior.auras, "cncblwau"), 1, "Warrior Concussive Blow aura appears exactly once")
assertTypedReference("f82db71a:nrbvenau", "auras", "Core nrbven01 aura")
assertTypedReference("f82db71a:harscrau", "auras", "Core harscr01 aura")
assertTypedReference("7bbb4cb9:cncblwau", "auras", "Warrior cncblow1 aura")

local expectedConcussivePresetUnits = {
    { unitId = "furbolg01", presetName = "Ursa Warrior" },
    { unitId = "quilbr01", presetName = "Berserker" },
    { unitId = "trogg001", presetName = "Brawler" },
    { unitId = "ogre001", presetName = "Enforcer" },
}
for _, expected in ipairs(expectedConcussivePresetUnits) do
    local unit
    for _, candidate in ipairs(core.units or {}) do
        if candidate.id == expected.unitId then unit = candidate break end
    end
    assertTrue(type(unit) == "table", "Core NPC exists: " .. expected.unitId)
    local preset
    for _, candidate in ipairs(unit.presets or {}) do
        if candidate.name == expected.presetName then preset = candidate break end
    end
    assertTrue(type(preset) == "table", "Core NPC preset exists: " .. expected.unitId .. "/" .. expected.presetName)
    local found = false
    for _, spellRef in ipairs(preset.spells or {}) do
        if spellRef == "7bbb4cb9:cncblow1" then found = true break end
    end
    assertTrue(found, "Core NPC preset resolves Concussive Blow: " .. expected.unitId .. "/" .. expected.presetName)
end

local function validateReferences(value, path, visited)
    if type(value) ~= "table" or visited[value] then return end
    visited[value] = true
    for key, child in pairs(value) do
        local childPath = path .. "." .. tostring(key)
        if referenceFields[key] then
            -- Damage/heal effects retain normalized aura fields even when aura
            -- application is disabled. Only validate auraRef when it is active.
            if key ~= "auraRef" or value.applyAura ~= false then
                assertReference(child, childPath)
                if key == "auraRef" then
                    assertTypedReference(child, "auras", childPath)
                elseif key == "spellRef" then
                    assertTypedReference(child, "spells", childPath)
                end
            end
        elseif type(key) == "string" and key:match("Refs$") and type(child) == "table" then
            for index = 1, #child do assertReference(child[index], childPath .. "." .. index) end
        elseif key == "spells" and type(child) == "table" then
            for index = 1, #child do
                if type(child[index]) == "string" and child[index]:find(":", 1, true) then
                    assertTypedReference(child[index], "spells", childPath .. "." .. index)
                end
            end
        end
        validateReferences(child, childPath, visited)
    end
end

for datasetId, definition in pairs(definitions) do
    validateReferences(definition.dataset, datasetId, {})
end

print("DatasetReferenceIntegrityTest passed")
