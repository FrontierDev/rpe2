local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then
        error(message, 2)
    end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local savedDatasetRoot = rawget(_G, "RPEngineDatasetDB")
local savedManagerRoot = rawget(_G, "RPEngineManagerDB")
local diagnostics = {}
local Addon = {
    Name = "RPEngine2",
    Data = {},
    Internal = {},
    Debug = {
        Internal = function(message, ...)
            diagnostics[#diagnostics + 1] = select("#", ...) > 0
                and string.format(message, ...)
                or tostring(message)
        end,
    },
}

loadAddonFile("core/internal/database/Dependecies.lua", Addon)
loadAddonFile("core/internal/database/Database.lua", Addon)
loadAddonFile("data/default/Datasets.lua", Addon)

-- This mirrors the packaged-data section of the current TOC, including every
-- post-definition patch file that contributes to the final packaged payload.
local packagedDataFiles = {
    "data/default/core.lua",
    "data/default/core_guild_settings.lua",
    "data/default/classes/druid.lua",
    "data/default/classes/hunter.lua",
    "data/default/classes/mage.lua",
    "data/default/classes/paladin.lua",
    "data/default/classes/priest.lua",
    "data/default/classes/rogue.lua",
    "data/default/classes/warrior.lua",
    "data/default/professions/fishing.lua",
    "data/default/professions/alchemy.lua",
    "data/default/professions/alchemy_daily_rewards.lua",
    "data/default/professions/blacksmithing.lua",
    "data/default/professions/blacksmithing_daily_rewards.lua",
    "data/default/professions/enchanting.lua",
    "data/default/professions/enchanting_daily_rewards.lua",
    "data/default/professions/inscription.lua",
    "data/default/professions/inscription_daily_rewards.lua",
    "data/default/professions/jewelcrafting.lua",
    "data/default/professions/jewelcrafting_daily_rewards.lua",
    "data/default/professions/leatherworking.lua",
    "data/default/professions/leatherworking_daily_rewards.lua",
    "data/default/professions/misc.lua",
    "data/default/professions/tailoring.lua",
    "data/default/professions/tailoring_daily_rewards_cleanup.lua",
    "data/default/professions/engineering.lua",
}
for index = 1, #packagedDataFiles do
    loadAddonFile(packagedDataFiles[index], Addon)
end

loadAddonFile("data/default/Install.lua", Addon)
loadAddonFile("core/internal/manager/ExternalManager.lua", Addon)
loadAddonFile("core/internal/Runtime.lua", Addon)

local Database = Addon.Internal.Database
local Dependecies = Database.Dependecies
local definitions = Addon.Data.DefaultDatasets.Definitions
assertTrue(type(Addon.Data.SyncDefaultDatasets) == "function", "installer exposes the runtime dataset synchronizer")

local expectedDefinitionCount = 0
for datasetId, definition in pairs(definitions) do
    assertTrue(type(definition) == "table" and type(definition.dataset) == "table", "packaged definition is valid: " .. tostring(datasetId))
    expectedDefinitionCount = expectedDefinitionCount + 1
end

local coreDefinition = definitions["f82db71a"]
assertTrue(type(coreDefinition) == "table" and type(coreDefinition.dataset) == "table", "Core packaged definition exists")

local function findCoreSpell(spellId)
    for index = 1, #(coreDefinition.dataset.spells or {}) do
        local spell = coreDefinition.dataset.spells[index]
        if spell and spell.id == spellId then
            return spell
        end
    end
end

local function assertBasicWeaponAttack(spellId, expectedDamageType, expectedStatRef, label)
    local spell = findCoreSpell(spellId)
    assertTrue(type(spell) == "table", label .. " exists in Core")
    assertEqual(spell.cooldownChannel, 4, label .. " remains a Free Action")
    local component = spell.components and spell.components[1]
    local effect = component and component.effect
    assertTrue(type(effect) == "table", label .. " has a damage effect")
    assertEqual(effect.hitType, "auto", label .. " remains a basic auto attack")
    assertEqual(effect.damageType, expectedDamageType, label .. " uses the correct attack type")
    assertEqual(effect.weaponDamageMode, "main_hand", label .. " includes its equipped ranged-slot weapon")
    assertEqual(effect.weaponDamageCoefficient, 1, label .. " uses full weapon damage")
    assertEqual(effect.statScaling and effect.statScaling[1] and effect.statScaling[1].statRef, expectedStatRef, label .. " uses the correct offensive stat")
    assertEqual(effect.statScaling and effect.statScaling[1] and effect.statScaling[1].coefficient, 0.5, label .. " uses the basic-attack stat coefficient")
end

assertBasicWeaponAttack("shoota01", "ranged", "f82db71a:v2rs9cpy", "Shoot")
assertBasicWeaponAttack("throwa01", "ranged", "f82db71a:v2rs9cpy", "Throw")
assertBasicWeaponAttack("wandauto", "spell", "f82db71a:7t7xgzcx", "Wand")

local dependencyRecomputations = 0
local originalRecompute = Dependecies.RecomputeDatasetDependencies
Dependecies.RecomputeDatasetDependencies = function(datasetId)
    dependencyRecomputations = dependencyRecomputations + 1
    return originalRecompute(datasetId)
end

local managerSawSynchronizedDefaults = false
local manager = Addon.Internal.ExternalManager
local originalManagerInitialize = manager.Initialize
manager.Initialize = function(...)
    local root = rawget(_G, "RPEngineDatasetDB")
    managerSawSynchronizedDefaults = type(root) == "table"
        and type(root.datasets) == "table"
        and next(root.datasets) ~= nil
    return originalManagerInitialize(...)
end

rawset(_G, "RPEngineDatasetDB", nil)
rawset(_G, "RPEngineManagerDB", nil)
Database.Datasets = nil
Addon.Internal.DispatchEvent("ADDON_LOADED", Addon.Name)

local root = rawget(_G, "RPEngineDatasetDB")
assertTrue(type(root) == "table", "clean startup creates RPEngineDatasetDB")
assertEqual(managerSawSynchronizedDefaults, true, "Manager runs after default dataset synchronization")
assertTrue(Addon.Internal.ConfigurationRevision > 0, "default synchronization emits a configuration change")
assertTrue(dependencyRecomputations >= expectedDefinitionCount, "default synchronization recomputes dataset dependencies")
for datasetId, definition in pairs(definitions) do
    assertTrue(type(root.datasets[datasetId]) == "table", "clean startup installs " .. datasetId)
    assertEqual(root.defaultDatasetVersions[datasetId], definition.version, "clean startup records version for " .. datasetId)
    assertEqual(Database.IsDatasetActivated(datasetId), true, "clean startup activates " .. datasetId)
end

local installedCount = 0
for _ in pairs(root.datasets) do
    installedCount = installedCount + 1
end
Addon.Internal.DispatchEvent("ADDON_LOADED", Addon.Name)
local secondStartupCount = 0
for _ in pairs(root.datasets) do
    secondStartupCount = secondStartupCount + 1
end
assertEqual(secondStartupCount, installedCount, "second startup is idempotent")

local updatedDatasetId, updatedDefinition = next(definitions)
assertTrue(updatedDatasetId ~= nil, "a packaged definition exists for update coverage")
assertTrue(Database.SetDatasetActivated(updatedDatasetId, false), "user can deactivate a packaged dataset")
local originalVersion = updatedDefinition.version
updatedDefinition.version = originalVersion + 1
Addon.Internal.DispatchEvent("ADDON_LOADED", Addon.Name)
assertEqual(root.defaultDatasetVersions[updatedDatasetId], originalVersion + 1, "package version update rewrites its dataset")
assertEqual(Database.IsDatasetActivated(updatedDatasetId), false, "package update preserves user deactivation")
updatedDefinition.version = originalVersion

definitions["malformed-default-regression"] = {
    version = 0,
    dataset = { id = "malformed-default-regression", name = "Malformed" },
}
assertEqual(Addon.Data.SyncDefaultDatasets(), false, "malformed packaged data fails synchronization")
local foundPreciseDiagnostic = false
for index = 1, #diagnostics do
    if diagnostics[index]:find("malformed%-default%-regression") then
        foundPreciseDiagnostic = true
        break
    end
end
assertTrue(foundPreciseDiagnostic, "malformed packaged data identifies the offending definition")
definitions["malformed-default-regression"] = nil

Dependecies.RecomputeDatasetDependencies = originalRecompute
manager.Initialize = originalManagerInitialize
rawset(_G, "RPEngineDatasetDB", savedDatasetRoot)
rawset(_G, "RPEngineManagerDB", savedManagerRoot)
Database.Datasets = savedDatasetRoot

print("DefaultDatasetStartupTest passed")
