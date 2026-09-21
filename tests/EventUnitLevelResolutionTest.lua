local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertClose(actual, expected, message)
    if math.abs((tonumber(actual) or 0) - expected) > 0.000001 then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local dataset
local Addon = {
    Internal = {
        Database = { Classes = {} },
        Registry = {
            GetActivatedDatasets = function()
                return { dataset }
            end,
        },
        Ruleset = {},
    },
    Server = {},
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("core/classes/Unit.lua")
loadAddonFile("core/classes/EventUnit.lua")
loadAddonFile("core/classes/EventUnitResourcePipeline.lua")

local Unit = Addon.Internal.Database.Classes.Unit
local EventUnit = Addon.Internal.Database.Classes.EventUnit
local baseUnit = Unit:New({
    id = "npc",
    name = "Progressing NPC",
    challengeLevel = "normal",
    stats = {
        { statRef = "test:power", initialValue = 100, perLevelValue = 10 },
    },
    resources = {
        { resourceRef = "test:health", initialValue = 100, perLevelValue = 10 },
        { resourceRef = "test:mana", initialValue = 20, perLevelValue = 2 },
    },
    presets = {
        {
            name = "Empowered",
            challengeLevel = "elite",
            statModifiers = {
                { statRef = "test:power", percentBonus = 50, flatBonus = 5 },
                { statRef = "test:missing-stat", percentBonus = 25, flatBonus = 7 },
            },
            resourceModifiers = {
                { resourceRef = "test:health", percentBonus = 50, flatBonus = 0 },
                { resourceRef = "test:mana", percentBonus = 0, flatBonus = 5 },
                { resourceRef = "test:missing-resource", percentBonus = 50, flatBonus = 7 },
            },
        },
    },
}):ToTable()
dataset = { id = "test", name = "Test", units = { baseUnit } }

local function findRow(rows, key, ref)
    for index = 1, #(rows or {}) do
        local row = rows[index]
        if row and row[key] == ref then
            return row
        end
    end
    return nil
end

for _, sample in ipairs({ { 1, 100 }, { 30, 390 }, { 60, 690 } }) do
    local level, expected = sample[1], sample[2]
    assertEqual(findRow(Unit.ResolveStatValues(baseUnit, level), "statRef", "test:power").value, expected, "base stat progression at level " .. level)
    assertEqual(findRow(Unit.ResolveResourceValues(baseUnit, level), "resourceRef", "test:health").value, expected, "base resource progression at level " .. level)
end

local rawProgressionEventUnit = EventUnit:New({
    registryID = "test:npc",
    stats = baseUnit.stats,
    resources = baseUnit.resources,
})
assertEqual(#rawProgressionEventUnit.stats, 0, "Unit progression rows are not normalized as runtime stats")
assertEqual(#rawProgressionEventUnit.resources, 0, "Unit progression rows are not normalized as runtime resources")
assertEqual(findRow(EventUnit.BuildResolvedStats(rawProgressionEventUnit, nil, { level = 30 }), "statRef", "test:power").value, 390, "raw stat rows resolve through the shared EventUnit helper")
assertEqual(findRow(EventUnit.BuildResolvedResources(rawProgressionEventUnit, 0, { level = 30, healthPercent = 0 }), "resourceRef", "test:health").maxValue, 390, "raw resource rows resolve through the shared EventUnit helper")

local variantEventUnit = EventUnit:New({ registryID = "test:npc", presetIndex = 1 })
local resolvedStats = EventUnit.BuildResolvedStats(variantEventUnit, nil, { level = 10 })
assertEqual(findRow(resolvedStats, "statRef", "test:power").value, 290, "stat preset applies to level-resolved base")
assertEqual(findRow(resolvedStats, "statRef", "test:missing-stat").value, 7, "missing stat modifier uses base zero")
assertEqual(Unit.ResolveEffectiveChallengeLevel(baseUnit, 0), "normal", "No preset resolves the base challenge level")
assertEqual(Unit.ResolveEffectiveChallengeLevel(baseUnit, 1), "elite", "Preset override resolves through Unit")

local resourceOptions = {
    level = 10,
    difficulty = "heroic",
    healthResourceRef = "test:health",
    applyPerPlayerScaling = true,
    healthBonusPerPlayerPercent = 20,
    healthPercent = 10,
}
local resolvedResources, policy = EventUnit.BuildUnitDerivedResources(baseUnit, 1, 2, resourceOptions)
assertClose(findRow(resolvedResources, "resourceRef", "test:health").maxValue, 438.9, "player and difficulty scaling apply once after level and preset")
assertClose(findRow(resolvedResources, "resourceRef", "test:health").currentValue, 438.9, "health current value follows resolved maximum")
assertEqual(findRow(resolvedResources, "resourceRef", "test:mana").maxValue, 43, "non-health resource receives preset flat modifier only")
assertEqual(findRow(resolvedResources, "resourceRef", "test:missing-resource").maxValue, 7, "missing resource modifier retains base-zero behavior")
assertEqual(policy.level, 10, "resource policy records the explicit Event level")

local effectiveChallengeScalingResources, effectiveChallengePolicy = EventUnit.BuildUnitDerivedResources(baseUnit, 1, 2, {
    level = 10,
    difficulty = "normal",
    healthResourceRef = "test:health",
    playerScalingChallengeLevels = { "elite" },
    healthBonusPerPlayerPercent = 10,
    healthPercent = 0,
})
assertEqual(effectiveChallengePolicy.challengeLevel, "elite", "Resource policy uses the preset challenge level")
assertEqual(effectiveChallengePolicy.applyPerPlayerScaling, true, "Player scaling eligibility uses the preset challenge level")
assertEqual(findRow(effectiveChallengeScalingResources, "resourceRef", "test:health").maxValue, 342, "Health player scaling applies for an elite preset")

local inheritedChallengeResources, inheritedChallengePolicy = EventUnit.BuildUnitDerivedResources(baseUnit, 0, 2, {
    level = 10,
    difficulty = "normal",
    healthResourceRef = "test:health",
    playerScalingChallengeLevels = { "elite" },
    healthBonusPerPlayerPercent = 10,
    healthPercent = 0,
})
assertEqual(inheritedChallengePolicy.challengeLevel, "normal", "No preset resource policy retains base challenge level")
assertEqual(inheritedChallengePolicy.applyPerPlayerScaling, false, "No preset keeps base-level scaling eligibility")
assertEqual(findRow(inheritedChallengeResources, "resourceRef", "test:health").maxValue, 190, "Base-level health remains unscaled when only elite is selected")

local beforeResolve = Unit:New(baseUnit):ToTable()
for _ = 1, 3 do
    local repeatedStats = EventUnit.BuildResolvedStats(variantEventUnit, nil, { level = 10 })
    local repeatedResources = EventUnit.BuildUnitDerivedResources(baseUnit, 1, 2, resourceOptions)
    assertEqual(findRow(repeatedStats, "statRef", "test:power").value, 290, "repeated stat resolution is deterministic")
    assertClose(findRow(repeatedResources, "resourceRef", "test:health").maxValue, 438.9, "repeated resource resolution is deterministic")
end
local afterResolve = Unit:New(baseUnit):ToTable()
assertEqual(afterResolve.stats[1].initialValue, beforeResolve.stats[1].initialValue, "resolution does not mutate Unit stat progression")
assertEqual(afterResolve.stats[1].perLevelValue, beforeResolve.stats[1].perLevelValue, "resolution does not mutate Unit stat growth")
assertEqual(afterResolve.resources[1].initialValue, beforeResolve.resources[1].initialValue, "resolution does not mutate Unit resource progression")
assertEqual(afterResolve.presets[1].statModifiers[1].percentBonus, beforeResolve.presets[1].statModifiers[1].percentBonus, "resolution does not mutate preset modifiers")

Addon.Server.GetEditableEventState = function(server)
    return server.EventState
end
Addon.Server.EventState = {
    active = true,
    level = 10,
    difficulty = "normal",
    units = { { isPlayer = true }, { isPlayer = true } },
    teams = {},
}
loadAddonFile("server/server_EventVariants.lua")

local resolvedNpcVariant = Addon.Server:BuildResolvedNpcVariant("test:npc", {
    presetIndex = 1,
    level = 10,
    playerCount = 0,
})
assertEqual(resolvedNpcVariant.challengeLevel, "elite", "Resolved NPC variant reports the effective preset challenge level")

local summonedUnitData = Addon.Server:BuildEventNpcUnitDataFromDefinition("test:npc", {
    presetIndex = 1,
    selectRandomAppearance = false,
})
assertEqual(findRow(summonedUnitData.stats, "statRef", "test:power").value, 290, "mid-event NPC materialization uses the active Event level")

Addon.Server.EventState.level = 1
local disabledLevelUnitData = Addon.Server:BuildEventNpcUnitDataFromDefinition("test:npc", {
    presetIndex = 1,
    selectRandomAppearance = false,
})
assertEqual(findRow(disabledLevelUnitData.stats, "statRef", "test:power").value, 155, "Event level one resolves to initial value before preset")

print("EventUnitLevelResolutionTest passed")
