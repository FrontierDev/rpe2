local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local definitions = TestSupport.LoadPackagedDefaultData(TestSupport.CreateAddon())
local collections = {
    "achievements", "auras", "classes", "currencies", "damageSchools", "guildSettings",
    "itemSlots", "items", "loot", "mounts", "pets", "races", "recipes", "resources",
    "skills", "spells", "stats", "traits", "units", "weaponTypes",
}
local entries = TestSupport.IndexDatasetEntries(definitions, collections)

for datasetId, definition in pairs(definitions) do
    local dataset = definition.dataset
    assertTrue(dataset.id == datasetId, "dataset registration key matches payload: " .. tostring(datasetId))
    for _, collectionName in ipairs(collections) do
        local ids = {}
        for index, entry in ipairs(dataset[collectionName] or {}) do
            if type(entry) == "table" and entry.id ~= nil then
                assertTrue(type(entry.id) == "string" and entry.id ~= "",
                    datasetId .. " " .. collectionName .. " entry " .. index .. " has an ID")
                assertTrue(not ids[entry.id], datasetId .. " " .. collectionName .. " has duplicate ID " .. entry.id)
                ids[entry.id] = true
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

local function validateReferences(value, path, visited)
    if type(value) ~= "table" or visited[value] then return end
    visited[value] = true
    for key, child in pairs(value) do
        local childPath = path .. "." .. tostring(key)
        if referenceFields[key] then
            assertReference(child, childPath)
        elseif type(key) == "string" and key:match("Refs$") and type(child) == "table" then
            for index = 1, #child do assertReference(child[index], childPath .. "." .. index) end
        end
        validateReferences(child, childPath, visited)
    end
end

for datasetId, definition in pairs(definitions) do
    validateReferences(definition.dataset, datasetId, {})
end

print("DatasetReferenceIntegrityTest passed")
