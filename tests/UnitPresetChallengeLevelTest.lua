local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Addon = {
    Internal = { Database = { Classes = {} } },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("core/classes/Unit.lua")
loadAddonFile("core/classes/UnitPresetSpellEquipment.lua")

local Unit = Addon.Internal.Database.Classes.Unit
local normalBase = Unit:New({
    id = "normal-base",
    challengeLevel = "normal",
    presets = {
        { name = "Legacy" },
        { name = "Elite", challengeLevel = "elite" },
    },
})

assertEqual(Unit.ResolveEffectiveChallengeLevel(normalBase, nil), "normal", "No preset retains the base challenge level")
assertEqual(Unit.ResolveEffectiveChallengeLevel(normalBase, 0), "normal", "Preset index zero retains the base challenge level")
assertEqual(Unit.ResolveEffectiveChallengeLevel(normalBase, 1), "normal", "Preset without an override inherits the base challenge level")
assertEqual(Unit.ResolveEffectiveChallengeLevel(normalBase, 2), "elite", "Explicit preset challenge level overrides the base")
for _, challengeLevel in ipairs({ "swarm", "minor", "normal", "elite", "boss" }) do
    local challengeUnit = Unit:New({
        challengeLevel = "normal",
        presets = { { name = challengeLevel, challengeLevel = challengeLevel } },
    })
    assertEqual(Unit.ResolveEffectiveChallengeLevel(challengeUnit, 1), challengeLevel, "Explicit challenge level resolves: " .. challengeLevel)
end

local bossBase = Unit:New({
    id = "boss-base",
    challengeLevel = "boss",
    presets = { { name = "Minor", challengeLevel = "minor" } },
})
assertEqual(Unit.ResolveEffectiveChallengeLevel(bossBase, 1), "minor", "Preset can override a boss base as minor")
assertEqual(Unit.ResolveEffectiveChallengeLevel(bossBase, 0), "boss", "No preset keeps a boss base unchanged")

local exportedUnit = normalBase:ToTable()
assertEqual(exportedUnit.presets[1].challengeLevel, nil, "Inherited override stays omitted in Unit:ToTable")
assertEqual(exportedUnit.presets[2].challengeLevel, "elite", "Explicit override survives Unit:ToTable")
local importedUnit = Unit.FromTable(exportedUnit)
assertEqual(importedUnit.presets[1].challengeLevel, nil, "Inherited override stays omitted after Unit import")
assertEqual(importedUnit.presets[2].challengeLevel, "elite", "Explicit override survives Unit import")
assertEqual(Unit.ResolveEffectiveChallengeLevel(importedUnit, 1), "normal", "Imported legacy preset remains backward compatible")
assertEqual(Unit.ResolveEffectiveChallengeLevel(importedUnit, 2), "elite", "Imported explicit override resolves")

local invalidOk = pcall(Unit.NormalizePreset, { name = "Invalid", challengeLevel = "mythic" })
assertEqual(invalidOk, false, "Invalid preset override is rejected during normalization")
local invalidResolveOk = pcall(Unit.ResolveEffectiveChallengeLevel, {
    challengeLevel = "boss",
    presets = { { name = "Invalid", challengeLevel = "mythic" } },
}, 1)
assertEqual(invalidResolveOk, false, "Invalid preset override is not normalized into a different challenge level")
local invalidUnitOk = pcall(Unit.FromTable, {
    challengeLevel = "boss",
    presets = { { name = "Invalid", challengeLevel = "" } },
})
assertEqual(invalidUnitOk, false, "Invalid empty preset override is rejected while loading a Unit")
assertEqual(Unit.IsValidChallengeLevel("Elite"), true, "Challenge level validation accepts normalized enum values")
assertEqual(Unit.IsValidChallengeLevel("mythic"), false, "Challenge level validation rejects unknown values")

loadAddonFile("core/internal/database/Database.lua")
local Database = Addon.Internal.Database
local datasetRoot = Database.EnsureDatasets()
local exportDataset = {
    id = "preset-level-test",
    name = "Preset Level Test",
    units = { exportedUnit },
}
datasetRoot.datasets[exportDataset.id] = exportDataset

local datasetText = Database.ExportDataset(exportDataset.id)
assert(type(datasetText) == "string", "Dataset export succeeds")
local importedDataset, importError = Database.ImportDataset(datasetText)
assert(importedDataset, importError or "Dataset import succeeds")
assertEqual(importedDataset.units[1].presets[1].challengeLevel, nil, "Dataset import preserves inherited omission")
assertEqual(importedDataset.units[1].presets[2].challengeLevel, "elite", "Dataset import preserves explicit override")

Addon.Client = { UI = { Editor = {} } }
Addon.UI = {}
loadAddonFile("client/ui/editor/inspectors/unit/page_InspectorUnitPresets.lua")
local editor = Addon.Client.UI.Editor
local challengeLevelItems = editor:BuildUnitInspectorPresetChallengeLevelItems()
local expectedChallengeLevelItems = {
    { label = "Inherit", value = "" },
    { label = "Swarm", value = "swarm" },
    { label = "Minor", value = "minor" },
    { label = "Normal", value = "normal" },
    { label = "Elite", value = "elite" },
    { label = "Boss", value = "boss" },
}
for index = 1, #expectedChallengeLevelItems do
    assertEqual(challengeLevelItems[index].label, expectedChallengeLevelItems[index].label, "Preset challenge dropdown label at index " .. index)
    assertEqual(challengeLevelItems[index].value, expectedChallengeLevelItems[index].value, "Preset challenge dropdown value at index " .. index)
end
local editedUnit = Unit.FromTable({ presets = { { name = "Editable" } } }):ToTable()
editor.GetSelectedUnitInspectorPreset = function()
    return editedUnit.presets[1], 1
end
editor.CommitSelectedUnit = function(_, mutate)
    mutate(editedUnit)
    editedUnit = Unit.FromTable(editedUnit):ToTable()
end
editor.RefreshUnitInspectorPresetsPage = function() end
editor:CommitUnitInspectorPresetChallengeLevel("elite")
assertEqual(editedUnit.presets[1].challengeLevel, "elite", "Preset editor stores explicit challenge level")
editor:CommitUnitInspectorPresetChallengeLevel("")
assertEqual(editedUnit.presets[1].challengeLevel, nil, "Preset editor stores Inherit as omitted")
editor:CommitUnitInspectorPresetChallengeLevel("mythic")
assertEqual(editedUnit.presets[1].challengeLevel, nil, "Preset editor ignores invalid challenge levels")

print("UnitPresetChallengeLevelTest passed")
