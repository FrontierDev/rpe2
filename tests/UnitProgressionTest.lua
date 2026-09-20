local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Addon = {
    Internal = {
        Database = { Classes = {} },
    },
}

local unitChunk, loadError = loadfile("core/classes/Unit.lua")
assert(unitChunk, loadError)
unitChunk(nil, Addon)
local Unit = Addon.Internal.Database.Classes.Unit

local legacyUnit = Unit:New({
    stats = { { statRef = "stats:power", value = 5000 } },
    resources = { { resourceRef = "resources:health", value = 5000 } },
})
assertEqual(legacyUnit.stats[1].initialValue, 5000, "legacy stat initial value")
assertEqual(legacyUnit.stats[1].perLevelValue, 0, "legacy stat per-level value")
assertEqual(legacyUnit.resources[1].initialValue, 5000, "legacy resource initial value")
assertEqual(legacyUnit.resources[1].perLevelValue, 0, "legacy resource per-level value")

local exportedLegacy = legacyUnit:ToTable()
assertEqual(exportedLegacy.stats[1].initialValue, 5000, "legacy stat canonical export")
assertEqual(exportedLegacy.stats[1].perLevelValue, 0, "legacy stat canonical export per-level")
assertEqual(exportedLegacy.stats[1].value, nil, "legacy stat value removed from export")
assertEqual(exportedLegacy.resources[1].initialValue, 5000, "legacy resource canonical export")
assertEqual(exportedLegacy.resources[1].perLevelValue, 0, "legacy resource canonical export per-level")
assertEqual(exportedLegacy.resources[1].value, nil, "legacy resource value removed from export")
assertEqual(Unit.ResolveStatValues(legacyUnit, 60)[1].value, 5000, "legacy stat stays level independent")
assertEqual(Unit.ResolveResourceValues(legacyUnit, 60)[1].value, 5000, "legacy resource stays level independent")

local progressingUnit = Unit:New({
    stats = { { statRef = "stats:power", initialValue = 100, perLevelValue = 10 } },
    resources = { { resourceRef = "resources:health", initialValue = 100, perLevelValue = 10 } },
})
assertEqual(Unit.ResolveProgressionValue(100, 10, 1), 100, "level 1 progression")
assertEqual(Unit.ResolveProgressionValue(100, 10, 30), 390, "level 30 progression")
assertEqual(Unit.ResolveProgressionValue(100, 10, 60), 690, "level 60 progression")
assertEqual(Unit.ResolveStatValues(progressingUnit, 30)[1].value, 390, "resolved stat row")
assertEqual(Unit.ResolveResourceValues(progressingUnit, 60)[1].value, 690, "resolved resource row")

assertEqual(Unit.ResolveProgressionValue(100, 10, nil), 100, "missing levels use level 1")
for _, level in ipairs({ "invalid", 0, -5 }) do
    assertEqual(Unit.ResolveProgressionValue(100, 10, level), 100, "invalid levels use level 1")
end

assertEqual(Unit.ResolveProgressionValue(-1.5, 0.25, 3), -1, "negative and decimal progression values")
assertEqual(Unit.ResolveProgressionValue(1.25, 0.5, 2), 1.75, "decimal progression values retain fractions")
local decimalUnit = Unit:New({
    stats = { { statRef = "stats:power", initialValue = -1.5, perLevelValue = 0.25 } },
    resources = { { resourceRef = "resources:health", initialValue = 1.25, perLevelValue = 0.5 } },
})
assertEqual(decimalUnit.stats[1].initialValue, -1.5, "negative stat progression normalization")
assertEqual(decimalUnit.stats[1].perLevelValue, 0.25, "decimal stat progression normalization")
assertEqual(Unit.ResolveStatValues(decimalUnit, 3)[1].value, -1, "negative stat progression resolution")
assertEqual(Unit.ResolveResourceValues(decimalUnit, 2)[1].value, 1.75, "decimal resource progression resolution")

local presetInput = {
    name = "Empowered",
    statModifiers = {
        { statRef = "stats:power", percentBonus = 12.5, flatBonus = -3.25 },
    },
    resourceModifiers = {
        { resourceRef = "resources:health", percentBonus = 20, flatBonus = 1.5 },
    },
}
local imported = Unit.FromTable({
    stats = { { statRef = "stats:power", initialValue = 2, perLevelValue = 0.5 } },
    resources = { { resourceRef = "resources:health", initialValue = 3, perLevelValue = 1.25 } },
    presets = { presetInput },
})
local exported = imported:ToTable()
local roundTrip = Unit.FromTable(exported):ToTable()
assertEqual(roundTrip.stats[1].statRef, "stats:power", "stat ref survives export and import")
assertEqual(roundTrip.resources[1].resourceRef, "resources:health", "resource ref survives export and import")
assertEqual(roundTrip.presets[1].statModifiers[1].statRef, "stats:power", "preset stat modifier ref survives")
assertEqual(roundTrip.presets[1].statModifiers[1].percentBonus, 12.5, "preset stat modifier percent unchanged")
assertEqual(roundTrip.presets[1].statModifiers[1].flatBonus, -3.25, "preset stat modifier flat bonus unchanged")
assertEqual(roundTrip.presets[1].resourceModifiers[1].resourceRef, "resources:health", "preset resource modifier ref survives")
assertEqual(roundTrip.presets[1].resourceModifiers[1].percentBonus, 20, "preset resource modifier percent unchanged")
assertEqual(roundTrip.presets[1].resourceModifiers[1].flatBonus, 1.5, "preset resource modifier flat bonus unchanged")

print("UnitProgressionTest passed")
