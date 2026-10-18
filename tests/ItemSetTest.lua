local Support = dofile("tests/support/RuntimeStubs.lua")

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertContains(values, expected, message)
    for index = 1, #(values or {}) do
        if values[index] == expected then
            return
        end
    end
    error(message .. ": missing " .. tostring(expected), 2)
end

local Addon = Support.CreateAddon()
Addon.Internal.Database = { Classes = {} }
Support.LoadAddonFile("core/classes/Trait.lua", Addon)
Support.LoadAddonFile("core/classes/Item.lua", Addon)
Support.LoadAddonFile("core/classes/ItemSet.lua", Addon)
Support.LoadAddonFile("core/internal/database/Dependecies.lua", Addon)
Support.LoadAddonFile("core/internal/database/Database.lua", Addon)
Support.LoadAddonFile("core/internal/Registry.lua", Addon)
Support.LoadAddonFile("core/internal/profile/Equipment.lua", Addon)

local Database = Addon.Internal.Database
local Item = Database.Classes.Item
local ItemSet = Database.Classes.ItemSet
local Registry = Addon.Internal.Registry
local Equipment = Addon.Internal.Profile.Equipment
local root = Database.EnsureDatasets()

local function item(id, itemSetKey)
    return Item:New({
        id = id,
        name = id,
        itemSetKey = itemSetKey,
    }):ToTable()
end

root.datasets = {
    gear = {
        id = "gear",
        name = "Gear",
        items = {
            item("helm", "sets:raid"),
            item("chest", "sets:raid"),
            item("gloves", "sets:raid"),
            item("boots", "sets:raid"),
            item("local", "local-set"),
        },
        itemSets = {
            ItemSet:New({ id = "local-set-id", key = "local-set", name = "Local Set" }):ToTable(),
        },
    },
    other = {
        id = "other",
        name = "Other",
        items = {
            item("belt", "sets:raid"),
        },
        itemSets = {},
    },
    sets = {
        id = "sets",
        name = "Sets",
        items = {},
        itemSets = {
            ItemSet:New({
                id = "raid-set",
                key = "raid",
                name = "Raid Set",
                bonuses = {
                    {
                        requiredPieces = 4,
                        statBonuses = { { statRef = "stats:power", value = 3 } },
                        skillBonuses = { { skillRef = "skills:sword", value = 4 } },
                    },
                    {
                        requiredPieces = 2,
                        statBonuses = { { statRef = "stats:power", value = 2 } },
                        equipmentBonuses = {
                            {
                                name = "Set Attunement",
                                statBonuses = { { statRef = "stats:power", value = 1 } },
                                skillBonuses = { { skillRef = "skills:sword", value = 1 } },
                            },
                        },
                    },
                },
            }):ToTable(),
        },
    },
    stats = { id = "stats", name = "Stats", stats = { { id = "power", name = "Power" } }, items = {}, itemSets = {} },
    skills = { id = "skills", name = "Skills", skills = { { id = "sword", name = "Sword" } }, items = {}, itemSets = {} },
    roundtrip = { id = "roundtrip", name = "Round Trip", items = {}, itemSets = {} },
}
root.activatedDatasets = { "gear", "other", "sets", "stats", "skills" }
Database.Datasets = root

local equipped = {}
Database.ListProfileEquipmentByScope = function(scope)
    return scope == "character" and equipped or {}
end

local members, memberDataset, memberSet = Registry:ListItemSetMembers("sets:raid")
assertEqual(memberDataset.id, "sets", "qualified member lookup returns the set dataset")
assertEqual(memberSet.key, "raid", "qualified member lookup returns the set by key")
assertEqual(#members, 4, "member lookup includes all items regardless of owning dataset or slot")

local localMembers = Registry:ListItemSetMembers("local-set", "gear")
assertEqual(#localMembers, 1, "legacy item set references resolve only in the owning dataset")
assertEqual(localMembers[1].item.id, "local", "legacy item set membership resolves the local set")
local _, invalidLegacySet = Registry:ResolveItemSetReference("local-set", "other")
assertEqual(invalidLegacySet, nil, "legacy item set references do not search other datasets")

local function progressForRaid()
    local progress = Equipment.GetEquippedItemSetProgress("sets:raid")
    return progress and progress.count or 0, progress
end

local function assertRaidCount(expectedCount, expectedStat, expectedSkill)
    local count, progress = progressForRaid()
    assertEqual(count, expectedCount, "equipped Item Set count")
    local bonuses = Equipment.GetEquippedItemSetBonuses()
    assertEqual(bonuses.stats["stats:power"] or 0, expectedStat, "cumulative Item Set stat bonus")
    assertEqual(bonuses.skills["skills:sword"] or 0, expectedSkill, "cumulative Item Set skill bonus")
    return progress
end

assertRaidCount(0, 0, 0)
equipped = { head = { itemRef = "gear:helm" } }
assertRaidCount(1, 0, 0)
equipped = {
    head = { itemRef = "gear:helm" },
    chest = { itemRef = "gear:chest" },
}
assertRaidCount(2, 2, 0)
equipped = {
    head = { itemRef = "gear:helm" },
    chest = { itemRef = "gear:chest" },
    hands = { itemRef = "gear:gloves" },
    feet = { itemRef = "other:belt" },
    duplicate = { itemRef = "gear:helm" },
}
local fourPieceProgress = assertRaidCount(4, 5, 4)
assertEqual(#fourPieceProgress.itemRefs, 4, "duplicate equipped copies do not count twice")
assertEqual(#fourPieceProgress.unlockedBonuses, 2, "all unlocked Item Set tiers apply cumulatively")
local equipmentBonusEntries = Equipment.ListEquippedItemSetEquipmentBonuses()
assertEqual(#equipmentBonusEntries, 1, "fulfilled Item Set equipment bonuses are listed once")
assertEqual(equipmentBonusEntries[1].payload.name, "Set Attunement", "Item Set equipment bonus payload is preserved")
assertRaidCount(4, 5, 4)

root.activatedDatasets = { "gear", "other", "stats", "skills" }
assertRaidCount(0, 0, 0)
root.activatedDatasets = { "gear", "other", "sets", "stats", "skills" }

Support.LoadAddonFile("core/internal/profile/Profile.lua", Addon)
local equippedTraitRows = Addon.Internal.Profile.ListEquippedItemTraits()
assertEqual(#equippedTraitRows, 1, "fulfilled Item Set equipment traits are exposed to the profile")
assertEqual(equippedTraitRows[1].payload.name, "Set Attunement", "profile exposes the Item Set equipment payload")
Addon.Internal.Profile.Modifications = {
    GetAggregatedBonuses = function()
        return { stats = {}, skills = {} }
    end,
}
Addon.Internal.ItemTier = {
    ResolveAuthoredStatValue = function(statEntry)
        return tonumber(statEntry and statEntry.value) or 0
    end,
}
Addon.Internal.Profile.IsMounted = function()
    return false
end
Addon.Internal.Profile.ListActiveTraits = function()
    return {}
end
Database.GetActiveProfile = function()
    return {}
end
Support.LoadAddonFile("core/internal/profile/Resolver.lua", Addon)
local Resolver = Addon.Internal.Profile.Resolver
local runtimeRows = Resolver.BuildUnitRuntimeStatRows({}, Equipment.ListEquippedSlots(), {}, "character")
local runtimePower = nil
for index = 1, #runtimeRows do
    if runtimeRows[index].statRef == "stats:power" then
        runtimePower = runtimeRows[index].value
    end
end
assertEqual(runtimePower, 5, "runtime stat aggregation includes direct Item Set bonuses")
local resolvedStats = Resolver.GetResolvedStatRowsByRefs({ "stats:power" })
assertEqual(resolvedStats[1].traitBonusBaseValue, 1, "resolved stats include Item Set equipment bonuses")
local resolvedSkills = Resolver.GetResolvedSkillRowsByRefs({ "skills:sword" })
assertEqual(resolvedSkills[1].itemBonus, 4, "normal skill resolution includes Item Set bonuses")
assertEqual(resolvedSkills[1].traitBonus, 1, "resolved skills include Item Set equipment bonuses")
local continuation = Resolver.CreateResolvedStateContinuation()
while not Resolver.StepResolvedStateContinuation(continuation, 1000000) do
end
local continuationPower = nil
for index = 1, #(continuation.statRows or {}) do
    if continuation.statRows[index].ref == "stats:power" then
        continuationPower = continuation.statRows[index].equipmentBonus
    end
end
assertEqual(continuationPower, 5, "resolved-state continuation retains direct Item Set bonuses")
local continuationTraitPower = nil
for index = 1, #(continuation.statRows or {}) do
    if continuation.statRows[index].ref == "stats:power" then
        continuationTraitPower = continuation.statRows[index].traitBonusBaseValue
    end
end
assertEqual(continuationTraitPower, 1, "resolved-state continuation includes Item Set equipment bonuses")

local malformedValid, malformedDiagnostics = ItemSet.Validate({
    id = "malformed-set",
    key = "malformed",
    bonuses = {
        { requiredPieces = 2, statBonuses = { "not-a-bonus-row" } },
        { requiredPieces = 2 },
    },
})
assertEqual(malformedValid, false, "malformed Item Set tiers produce validation diagnostics")
assert(#malformedDiagnostics > 0, "malformed Item Set diagnostics are retained")

local duplicateSet = ItemSet:New({ key = "raid", name = "Duplicate" }):ToTable()
root.datasets.sets.itemSets[#root.datasets.sets.itemSets + 1] = duplicateSet
local _, _, duplicateReason = Registry:ResolveItemSetReference("sets:raid")
assertEqual(duplicateReason, "duplicate-key", "duplicate Item Set keys are rejected deterministically")
local valid, diagnostics = Database.ValidateDataset("sets")
assertEqual(valid, false, "duplicate Item Set keys produce validation failure")
assertContains(diagnostics, "itemSets[2] duplicates key 'raid' also used at itemSets[1].", "duplicate diagnostics identify the conflicting key")
table.remove(root.datasets.sets.itemSets)

local invalidItem = item("invalid", "sets:missing")
root.datasets.gear.items[#root.datasets.gear.items + 1] = invalidItem
local gearValid, gearDiagnostics = Database.ValidateDataset("gear")
assertEqual(gearValid, false, "unresolved Item Set references produce validation failure")
assert(#gearDiagnostics > 0, "unresolved Item Set diagnostics are retained")
table.remove(root.datasets.gear.items)

local exported = Database.ExportDatasetEntry("sets", "itemSets", "raid-set")
assert(type(exported) == "string", "Item Set per-entry export succeeds")
assertContains(Database.Dependecies.RecomputeDatasetDependencies("gear"), "sets", "cross-dataset Item Set membership contributes a dependency")
local renamed = Database.RenameDatasetEntry("sets", "itemSets", 1, "renamed-raid")
assert(renamed, "Item Set key rename succeeds")
assertEqual(root.datasets.gear.items[1].itemSetKey, "sets:renamed-raid", "Item Set key rename updates canonical memberships")
assertEqual(Registry:ResolveItemSetReference("sets:raid"), nil, "old Item Set key no longer resolves after rename")
assert(Registry:ResolveItemSetReference("sets:renamed-raid"), "renamed Item Set key resolves")
Database.RenameDatasetEntry("sets", "itemSets", 1, "raid")
local imported, importError = Database.ImportDatasetEntry("roundtrip", "itemSets", exported)
assert(imported, importError or "Item Set per-entry import succeeds")
assertEqual(imported.key, "raid", "Item Set import preserves the stable key")

root._schema = 24
root.datasets.roundtrip.itemSets = {
    {
        id = "legacy-set",
        key = "legacy",
        name = "Legacy",
        bonuses = {
            {
                requiredPieces = 2,
                statBonuses = { { sourceStatRef = "stats:power", value = 1 } },
                equipmentBonuses = { { name = "Migrated Equipment" } },
            },
        },
    },
}
root.datasets.gear.items[1].itemSetKey = "legacy"
Support.LoadAddonFile("core/internal/database/DatasetSchema25.lua", Addon)
assertEqual(root._schema, 25, "schema-25 migration advances the dataset schema")
assertEqual(root.datasets.gear.items[1].itemSetKey, "legacy", "schema migration retains existing item membership")
assertEqual(root.datasets.roundtrip.itemSets[1].bonuses[1].statBonuses[1].statRef, "stats:power", "schema migration normalizes legacy Item Set stat refs")
assertEqual(root.datasets.roundtrip.itemSets[1].bonuses[1].equipmentBonuses[1].name, "Migrated Equipment", "schema migration preserves Item Set equipment bonuses")
assert(Database.DeleteDatasetEntry("sets", "itemSets", 1), "Item Set deletion succeeds")
assertEqual(root.datasets.gear.items[2].itemSetKey, "", "Item Set deletion prunes canonical item memberships")

print("ItemSetTest passed")
