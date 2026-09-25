local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, nested in pairs(value) do copy[key] = deepCopy(nested) end
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

local function assertContains(values, expected, message)
    for index = 1, #(values or {}) do
        if values[index] == expected then return end
    end
    error(message .. ": missing " .. tostring(expected), 2)
end

local function findByRef(values, key, ref)
    for index = 1, #(values or {}) do
        if values[index] and values[index][key] == ref then return values[index] end
    end
end

local Addon = { Internal = { Database = { Classes = {} } } }
local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("core/classes/Unit.lua")
loadAddonFile("core/classes/UnitPresetSpellEquipment.lua")
loadAddonFile("core/internal/database/Dependecies.lua")
loadAddonFile("core/internal/database/Database.lua")
loadAddonFile("core/internal/Registry.lua")

local Database = Addon.Internal.Database
local Unit = Database.Classes.Unit
local Registry = Addon.Internal.Registry
local root = Database.EnsureDatasets()
root.datasets = {
    base = {
        id = "base",
        name = "Base",
        units = {
            Unit.FromTable({
                id = "human",
                name = "Human",
                description = "Base human",
                creatureType = "humanoid",
                creatureSize = "medium",
                challengeLevel = "normal",
                mainHandWeapon = "base:sword",
                spells = { "base:racial", "base:racial" },
                stats = {
                    { statRef = "common:power", initialValue = 5, perLevelValue = 2 },
                    { statRef = "common:armor", initialValue = 3, perLevelValue = 1 },
                },
                resources = { { resourceRef = "common:health", initialValue = 100, perLevelValue = 10 } },
                resistances = {
                    { damageSchoolRef = "common:fire", coefficient = 0.5 },
                    { damageSchoolRef = "common:frost", coefficient = 0.25 },
                },
                attributes = { "humanoid", "biped" },
                tags = { "core", "people" },
                appearances = { { displayId = 1001, cam = 1, rot = 0, z = 0 } },
                presets = {
                    { name = "Base Guard", spells = { "base:guard" }, equipment = { mainHandWeapon = "base:shield" } },
                },
            }):ToTable(),
        },
    },
    common = { id = "common", name = "Common", units = {} },
    campaign = { id = "campaign", name = "Campaign", units = {} },
}
root.activatedDatasets = { "base", "common", "campaign" }

local childOnly = Unit.FromTable({ id = "humanOnly", extendsUnitRef = "base:human" }):ToTable()
assertEqual(childOnly.name, nil, "extending Unit does not persist a constructor default name")
assertEqual(childOnly.challengeLevel, nil, "extending Unit does not persist a constructor default challenge level")
assertEqual(childOnly.stats, nil, "extending Unit does not persist unauthored empty stat data")
assertEqual(childOnly.presets, nil, "extending Unit does not persist unauthored empty presets")
local child = Unit.FromTable({
    id = "campaignHuman",
    extendsUnitRef = "base:human",
    presets = {
        { name = "Campaign Scout", spells = { "campaign:scout" }, equipment = { mainHandWeapon = "campaign:dagger" } },
    },
    spells = { "campaign:voice", "base:racial" },
    stats = {
        { statRef = "common:power", initialValue = 9, perLevelValue = 1 },
        { statRef = "common:focus", initialValue = 4, perLevelValue = 0 },
    },
    resources = {
        { resourceRef = "common:health", initialValue = 150, perLevelValue = 5 },
        { resourceRef = "common:mana", initialValue = 20, perLevelValue = 0 },
    },
    resistances = {
        { damageSchoolRef = "common:fire", coefficient = 0.8 },
        { damageSchoolRef = "common:shadow", coefficient = 0.1 },
    },
    attributes = { "humanoid", "campaign" },
    tags = { "people", "campaign", "scout" },
    appearances = { { displayId = 2002, cam = 2, rot = 30, z = 0.2 } },
}):ToTable()
root.datasets.campaign.units = { childOnly, child }

local parent = root.datasets.base.units[1]
local originalParent = deepCopy(parent)
local baseDataset, onlyResolved, onlyRaw = Registry:ResolveUnitDefinition("campaign:humanOnly")
assertEqual(baseDataset.id, "campaign", "resolver returns the extending dataset")
assertEqual(onlyRaw.id, "humanOnly", "resolver exposes the authored child record separately")
assertEqual(onlyResolved.id, "humanOnly", "effective Unit keeps the child's local identity")
for _, key in ipairs({ "name", "description", "creatureType", "creatureSize", "challengeLevel", "spells", "stats", "resources", "resistances", "attributes", "tags", "appearances", "presets", "mainHandWeapon" }) do
    assert(deepEqual(onlyResolved[key], parent[key]), "extension-only child inherits " .. key)
end
assert(deepEqual(parent, originalParent), "resolving child Units does not mutate the parent record")

local _, effective = Registry:ResolveUnitDefinition("campaign:campaignHuman")
assertEqual(effective.id, "campaignHuman", "effective child retains its ID")
assertEqual(#effective.presets, 2, "child presets append after the parent preset")
assertEqual(effective.presets[1].name, "Base Guard", "parent preset remains first")
assertEqual(effective.presets[2].name, "Campaign Scout", "child preset follows parent presets")
assertEqual(effective.presets[2].spells[1], "campaign:scout", "child preset spell override is preserved")
assertEqual(effective.presets[2].equipment.mainHandWeapon, "campaign:dagger", "child preset equipment override is preserved")
assertEqual(#effective.stats, 3, "stat refs merge without duplicates")
assertEqual(findByRef(effective.stats, "statRef", "common:power").initialValue, 9, "child stat replaces the matching parent progression")
assertEqual(findByRef(effective.stats, "statRef", "common:armor").initialValue, 3, "unmatched parent stat remains")
assertEqual(findByRef(effective.resources, "resourceRef", "common:health").initialValue, 150, "child resource replaces the matching parent progression")
assertEqual(#effective.resources, 2, "resource refs merge without duplicates")
assertEqual(#effective.spells, 2, "child spells append and deduplicate by ref")
assertEqual(effective.spells[1], "base:racial", "parent spell order is stable")
assertEqual(effective.spells[2], "campaign:voice", "new child spell appends")
assertEqual(#effective.appearances, 2, "child appearances append after inherited appearances")
assertEqual(effective.appearances[2].displayId, 2002, "child appearance is retained")
assertEqual(findByRef(effective.resistances, "damageSchoolRef", "common:fire").coefficient, 0.8, "child resistance replaces matching parent school")
assertEqual(#effective.resistances, 3, "new resistance appends")
assertEqual(table.concat(effective.attributes, ","), "humanoid,biped,campaign", "attributes form an ordered unique union")
assertEqual(table.concat(effective.tags, ","), "core,people,campaign,scout", "tags form an ordered unique union")
assert(deepEqual(parent, originalParent), "merging overlays leaves parent content unchanged")
local _, directlySelectedParent = Registry:ResolveUnitDefinition("base:human")
assertEqual(#directlySelectedParent.presets, 1, "selecting the parent directly does not include child presets")
root.datasets.campaign.units[#root.datasets.campaign.units + 1] = Unit.FromTable({
    id = "humanOverride",
    extendsUnitRef = "base:human",
    name = "Campaign Human",
    description = "Local description",
    creatureType = "undead",
    creatureSize = "large",
    challengeLevel = "elite",
    mainHandWeapon = "campaign:staff",
}):ToTable()
local _, scalarOverride = Registry:ResolveUnitDefinition("campaign:humanOverride")
assertEqual(scalarOverride.name, "Campaign Human", "authored child name overrides inheritance")
assertEqual(scalarOverride.description, "Local description", "authored child description overrides inheritance")
assertEqual(scalarOverride.creatureType, "undead", "authored child creature type overrides inheritance")
assertEqual(scalarOverride.creatureSize, "large", "authored child creature size overrides inheritance")
assertEqual(scalarOverride.challengeLevel, "elite", "authored child challenge level overrides inheritance")
assertEqual(scalarOverride.mainHandWeapon, "campaign:staff", "authored child equipment overrides inheritance")

local chainChild = Unit.FromTable({ id = "chainChild", extendsUnitRef = "base:human", tags = { "middle" } }):ToTable()
local chainLeaf = Unit.FromTable({ id = "chainLeaf", extendsUnitRef = "campaign:chainChild", tags = { "leaf" } }):ToTable()
root.datasets.campaign.units[#root.datasets.campaign.units + 1] = chainChild
root.datasets.campaign.units[#root.datasets.campaign.units + 1] = chainLeaf
local _, chainResolved = Registry:ResolveUnitDefinition("campaign:chainLeaf")
assertEqual(table.concat(chainResolved.tags, ","), "core,people,middle,leaf", "multi-level inheritance resolves oldest ancestor first")

local function expectResolutionError(ref, expectedText, message)
    local ok, err = pcall(function() Registry:ResolveUnitDefinition(ref) end)
    assertEqual(ok, false, message)
    assert(tostring(err):find(expectedText, 1, true), message .. " identifies the failure")
end

root.datasets.campaign.units[#root.datasets.campaign.units + 1] = Unit.FromTable({
    id = "missingParent", extendsUnitRef = "absent:unit",
}):ToTable()
expectResolutionError("campaign:missingParent", "absent:unit", "missing parent fails clearly")
root.datasets.campaign.units[#root.datasets.campaign.units + 1] = Unit.FromTable({
    id = "selfParent", extendsUnitRef = "campaign:selfParent",
}):ToTable()
expectResolutionError("campaign:selfParent", "campaign:selfParent -> campaign:selfParent", "self-reference is rejected")
root.datasets.campaign.units[#root.datasets.campaign.units + 1] = Unit.FromTable({
    id = "cycleA", extendsUnitRef = "campaign:cycleB",
}):ToTable()
root.datasets.campaign.units[#root.datasets.campaign.units + 1] = Unit.FromTable({
    id = "cycleB", extendsUnitRef = "campaign:cycleA",
}):ToTable()
expectResolutionError("campaign:cycleA", "campaign:cycleA -> campaign:cycleB -> campaign:cycleA", "cycle is rejected with its chain")

local childExport = Unit.FromTable(child):ToTable()
assertEqual(childExport.extendsUnitRef, "base:human", "Unit serialization preserves extendsUnitRef")
assertEqual(#childExport.stats, 2, "Unit serialization keeps only child stat overlay")
assertEqual(#childExport.presets, 1, "Unit serialization keeps only child presets")
assertEqual(childExport.name, nil, "Unit serialization does not materialize an inherited name")
local roundTripDataset = { id = "roundtrip", name = "Round Trip", units = {} }
root.datasets.roundtrip = roundTripDataset
local entryText = Database.ExportDatasetEntry("campaign", "units", "campaignHuman")
assert(type(entryText) == "string", "extending Unit entry export succeeds")
local importedChild, importError = Database.ImportDatasetEntry("roundtrip", "units", entryText)
assert(importedChild, importError or "extending Unit entry import succeeds")
assertEqual(importedChild.extendsUnitRef, "base:human", "entry import preserves extendsUnitRef")
assertEqual(#importedChild.presets, 1, "entry import does not materialize parent presets")
assertEqual(#importedChild.stats, 2, "entry import preserves only authored stats")
assertEqual(importedChild.name, nil, "entry import does not materialize the inherited name")

local dependencyList = Database.Dependecies.RecomputeDatasetDependencies("campaign")
assertContains(dependencyList, "base", "extendsUnitRef contributes the parent dataset dependency")
local hashBefore = Database.ExportDatasetForCompatibilityHash("campaign")
child.extendsUnitRef = "base:alternate"
root.datasets.campaign.units[2].extendsUnitRef = "base:alternate"
local hashAfter = Database.ExportDatasetForCompatibilityHash("campaign")
assert(hashBefore ~= hashAfter, "compatibility hash input changes when extendsUnitRef changes")
root.datasets.campaign.units[2].extendsUnitRef = "base:human"

loadAddonFile("core/classes/EventUnit.lua")
local EventUnit = Database.Classes.EventUnit
local hydratedUnit = EventUnit:New({ registryID = "campaign:campaignHuman" })
assertEqual(hydratedUnit:GetResolvedUnit().id, "campaignHuman", "EventUnit resolves the effective child definition")
assertEqual(findByRef(hydratedUnit:GetResolvedUnit().resources, "resourceRef", "common:health").initialValue, 150,
    "EventUnit resolution includes inherited resource overlays")

-- Planner preparation indexes raw authored records. EventUnit must continue to
-- resolve through Registry so the index cannot bypass Unit inheritance.
Addon.Internal.ConfigurationRevision = 5
local preparedUnitIndex = {}
for index = 1, #root.datasets.campaign.units do
    local unit = root.datasets.campaign.units[index]
    preparedUnitIndex[unit.id] = unit
end
root.datasets.campaign.__entryCacheByCollection = root.datasets.campaign.__entryCacheByCollection or {}
root.datasets.campaign.__entryCacheByCollection.units = {
    revision = 5,
    entries = root.datasets.campaign.units,
    byId = preparedUnitIndex,
}
Addon.Client = {
    AutopilotPlanner = { Step = function() return true end },
}
Addon.Internal.Tasks = {}
loadAddonFile("client/autopilot/PlannerPreparationPerformance.lua")
local preparedResolved = hydratedUnit:GetResolvedUnit()
assertEqual(#preparedResolved.presets, 2, "planner-prepared resolution retains inherited presets")
assertEqual(preparedResolved.presets[1].equipment.mainHandWeapon, "base:shield",
    "planner-prepared resolution retains inherited equipment")
assertEqual(preparedResolved.appearances[1].displayId, 1001,
    "planner-prepared resolution retains inherited appearances")
assertEqual(findByRef(preparedResolved.stats, "statRef", "common:armor").initialValue, 3,
    "planner-prepared resolution retains inherited stats")
assertEqual(findByRef(preparedResolved.resources, "resourceRef", "common:health").initialValue, 150,
    "planner-prepared resolution retains inherited resources")
assertEqual(preparedResolved.spells[1], "base:racial",
    "planner-prepared resolution retains inherited spells")
local ordinaryUnit = EventUnit:New({ registryID = "base:human" })
assertEqual(#ordinaryUnit:GetResolvedUnit().presets, 1, "planner-prepared ordinary Unit resolution is unchanged")

-- A revision change must invalidate the prepared raw index before the
-- canonical resolver reads the authored record again.
root.datasets.campaign.units[2].appearances[#root.datasets.campaign.units[2].appearances + 1] = {
    displayId = 2003,
    cam = 3,
    rot = 0,
    z = 0,
}
Addon.Internal.ConfigurationRevision = 6
local invalidatedResolved = hydratedUnit:GetResolvedUnit()
assertEqual(invalidatedResolved.appearances[3].displayId, 2003,
    "planner-prepared Unit index invalidates on configuration revision")

Addon.Internal.Ruleset = { Rules = {} }
Addon.Server = {
    SummonEventPetUnit = function(self, _, registryId, options)
        return self:BuildEventNpcUnitDataFromDefinition(registryId, options)
    end,
}
loadAddonFile("core/classes/EventUnitResourcePipeline.lua")
loadAddonFile("server/server_EventVariants.lua")
loadAddonFile("server/server_EventResourceIntegration.lua")
loadAddonFile("server/server_EventSpellEquipmentVariants.lua")
local variant = Addon.Server:BuildResolvedNpcVariant("campaign:campaignHuman", { presetIndex = 2, level = 3 })
assertEqual(variant.registryID, "campaign:campaignHuman", "runtime variant registry identity remains the child ref")
assertEqual(variant.stats[1].value, 11, "runtime variant stats use the child progression overlay")
assertEqual(variant.spells[1], "campaign:scout", "runtime variant uses inherited preset resolution and child spell override")
assertEqual(variant.equipment.mainHandWeapon, "campaign:dagger", "runtime variant uses the child preset equipment")
assertEqual(findByRef(variant.resources, "resourceRef", "common:health").maxValue, 160,
    "runtime variant resources use the child's inherited progression")
local inheritedPresetVariant = Addon.Server:BuildResolvedNpcVariant("campaign:campaignHuman", { presetIndex = 1, level = 3 })
assertEqual(inheritedPresetVariant.spells[1], "base:guard", "runtime child can select inherited parent preset spells")
assertEqual(inheritedPresetVariant.equipment.mainHandWeapon, "base:shield", "runtime child can select inherited parent preset equipment")
assertEqual(inheritedPresetVariant.registryID, "campaign:campaignHuman", "inherited preset retains the child runtime identity")
local eventData = Addon.Server:BuildEventNpcUnitDataFromDefinition("campaign:campaignHuman", {
    presetIndex = 1,
    level = 3,
    team = 1,
})
assertEqual(eventData.registryID, "campaign:campaignHuman", "event creation preserves child registry identity")
assertEqual(eventData.stats[1].value, 11, "event creation receives resolved child gameplay stats")
assertEqual(eventData.mainHandWeapon, "base:shield", "event creation receives inherited preset equipment")
assertEqual(eventData.spells[1], "base:guard", "event creation receives inherited preset spells")
assertEqual(findByRef(eventData.resources, "resourceRef", "common:health").maxValue, 160,
    "event creation receives resolved child resources")
local summonedData = Addon.Server:SummonEventPetUnit({ eventID = 1, team = 1 }, "campaign:campaignHuman", {
    presetIndex = 1,
    level = 3,
})
assertEqual(summonedData.registryID, "campaign:campaignHuman", "summoning keeps the extending Unit registry ref")
assertEqual(summonedData.stats[1].value, 11, "summoning receives the extending Unit stats")
assertEqual(summonedData.spells[1], "base:guard", "summoning receives inherited preset spells")
assertEqual(summonedData.mainHandWeapon, "base:shield", "summoning receives inherited preset equipment")
assertEqual(findByRef(summonedData.resources, "resourceRef", "common:health").maxValue, 160,
    "summoning receives the extending Unit resources")

Addon.Client = { UI = { Editor = {} } }
Addon.UI = {}
loadAddonFile("client/ui/editor/inspectors/unit/page_InspectorUnitGeneral.lua")
loadAddonFile("client/ui/editor/inspectors/unit/page_InspectorUnitPresets.lua")
local editor = Addon.Client.UI.Editor
editor.GetSelectedDataset = function() return root.datasets.campaign end
local extendsItems = editor:BuildUnitInspectorExtendsItems(child)
local function containsItem(items, value)
    for index = 1, #(items or {}) do
        local item = items[index]
        if item.value == value then return true end
        if containsItem(item.children, value) then return true end
    end
    return false
end
assert(containsItem(extendsItems, "base:human"), "Extends Unit selector lists full cross-dataset refs")
assert(not containsItem(extendsItems, "campaign:campaignHuman"), "Extends Unit selector prevents selecting itself")
local presetItems = editor:BuildUnitInspectorPresetSelectorItems(child)
assertEqual(presetItems[1].label, "Inherited presets (read-only)", "preset selector labels inherited presets as read-only")
assertEqual(presetItems[1].children[1].notCheckable, true, "inherited preset entries cannot be selected for editing")
assertEqual(presetItems[2].label, "Child presets (editable)", "preset selector separates editable child presets")
assertEqual(presetItems[2].children[1].value, "1", "child preset keeps its local edit index")

local newEditorUnit = Unit:New({ id = "newCampaignUnit" }):ToTable()
newEditorUnit.name = "New Unit"
editor.GetSelectedUnitAndDataset = function() return root.datasets.campaign, newEditorUnit end
editor.CommitSelectedUnit = function(_, mutate)
    mutate(newEditorUnit, root.datasets.campaign)
    newEditorUnit = Unit.FromTable(newEditorUnit):ToTable()
end
editor.RefreshUnitInspectorPage = function() end
editor:CommitUnitInspectorExtendsUnit("base:human")
assertEqual(newEditorUnit.extendsUnitRef, "base:human", "editor stores the selected parent ref")
assertEqual(newEditorUnit.name, nil, "editor does not turn a constructor name into a child override")
assertEqual(newEditorUnit.creatureType, nil, "editor does not turn constructor creature type into a child override")

local nonExtending = Unit.FromTable({ id = "ordinary", name = "Ordinary" }):ToTable()
assertEqual(nonExtending.extendsUnitRef, nil, "ordinary Unit schema remains unchanged")
assertEqual(nonExtending.creatureType, "humanoid", "ordinary Unit still receives its existing defaults")
assertEqual(nonExtending.challengeLevel, "normal", "ordinary Unit challenge default remains unchanged")

print("UnitInheritanceTest passed")
