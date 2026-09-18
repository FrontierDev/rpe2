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

local resolvedResources = {}
local statValues = {}
local Addon = {
    Internal = {
        Comms = {},
        Database = {},
        Profile = {
            ListResolvedResources = function()
                return resolvedResources
            end,
            GetResolvedStatValue = function(statRef, fallback)
                local value = statValues[statRef]
                return value ~= nil and value or fallback
            end,
        },
    },
    Utils = {
        Common = {},
    },
}

local resourceSyncChunk, loadError = loadfile("core/internal/comms/ResourceSync.lua")
assert(resourceSyncChunk, loadError)
resourceSyncChunk(nil, Addon)
local ResourceSync = Addon.Internal.Comms.ResourceSync

local function resourceRow(resourceRef, resource, maxValue)
    return {
        ref = resourceRef,
        value = maxValue or 100,
        resource = resource,
    }
end

local function build(resources, rows, options)
    resolvedResources = rows
    return ResourceSync.BuildPlayerTurnRegenResourceDeltas(resources, options or {})
end

local function findDelta(deltas, resourceRef)
    for index = 1, #deltas do
        if deltas[index].resourceRef == resourceRef then
            return deltas[index]
        end
    end
    return nil
end

local function fixedResource(regenPerSecond)
    return {
        regenMode = "fixed",
        regenPerSecond = regenPerSecond,
    }
end

local function derivedResource(sourceStatRef, regenMultiplier)
    return {
        regenMode = "derived",
        regenSourceStatRef = sourceStatRef,
        regenMultiplier = regenMultiplier,
    }
end

local function run()
    local resolver = function(statRef)
        return statValues[statRef] or 0
    end

    statValues = { regen = 5 }
    local fixed = build(
        { { resourceRef = "mana", currentValue = 0, maxValue = 100 } },
        { resourceRow("mana", fixedResource(20)) },
        { resourceRegenerationStatRef = "regen", resolveStatValue = resolver }
    )
    assertClose(findDelta(fixed, "mana").delta, 21, "fixed regeneration")

    statValues = { source = 100, regen = 25 }
    local derived = build(
        { { resourceRef = "mana", currentValue = 0, maxValue = 100 } },
        { resourceRow("mana", derivedResource("source", 0.2)) },
        { resourceRegenerationStatRef = "regen", resolveStatValue = resolver }
    )
    assertClose(findDelta(derived, "mana").delta, 25, "derived regeneration")

    statValues = { regen = 50 }
    local health = build(
        { { resourceRef = "health", currentValue = 50, maxValue = 100 } },
        { resourceRow("health", fixedResource(20)) },
        { healthResourceRef = "health", resourceRegenerationStatRef = "regen", resolveStatValue = resolver }
    )
    assertClose(findDelta(health, "health").delta, 20, "health exclusion")

    local multiple = build(
        {
            { resourceRef = "health", currentValue = 50, maxValue = 100 },
            { resourceRef = "mana", currentValue = 0, maxValue = 100 },
            { resourceRef = "energy", currentValue = 0, maxValue = 100 },
            { resourceRef = "holy", currentValue = 0, maxValue = 100 },
        },
        {
            resourceRow("health", fixedResource(20)),
            resourceRow("mana", fixedResource(20)),
            resourceRow("energy", fixedResource(10)),
            resourceRow("holy", { regenMode = "fixed", regenPerSecond = 12, special = true }),
        },
        { healthResourceRef = "health", resourceRegenerationStatRef = "regen", resolveStatValue = resolver }
    )
    assertClose(findDelta(multiple, "health").delta, 20, "multiple-resource health")
    assertClose(findDelta(multiple, "mana").delta, 30, "multiple-resource mana")
    assertClose(findDelta(multiple, "energy").delta, 15, "multiple-resource energy")
    assertClose(findDelta(multiple, "holy").delta, 12, "special-resource exclusion")

    statValues = { regen = -10 }
    local negative = build(
        { { resourceRef = "mana", currentValue = 0, maxValue = 100 } },
        { resourceRow("mana", fixedResource(20)) },
        { resourceRegenerationStatRef = "regen", resolveStatValue = resolver }
    )
    assertClose(findDelta(negative, "mana").delta, 18, "negative modifier")

    statValues = { regen = 50 }
    local unconfigured = build(
        { { resourceRef = "mana", currentValue = 0, maxValue = 100 } },
        { resourceRow("mana", fixedResource(20)) },
        { resourceRegenerationStatRef = "", resolveStatValue = resolver }
    )
    assertClose(findDelta(unconfigured, "mana").delta, 20, "unconfigured modifier")

    local directResources = { { resourceRef = "mana", currentValue = 0, maxValue = 100 } }
    local _, directApplied = ResourceSync.ApplyResourceDeltasToResources(directResources, {
        { resourceRef = "mana", delta = 20, maxValue = 100 },
    }, { resourceRegenerationStatRef = "regen" })
    assertEqual(directApplied[1].delta, 20, "direct resource restoration")

    for _, unitType in ipairs({ "player", "npc" }) do
        statValues = { regen = 5 }
        local eventUnit = build(
            { { resourceRef = "mana", currentValue = 0, maxValue = 100 } },
            { resourceRow("mana", fixedResource(20)) },
            { resourceRegenerationStatRef = "regen", resolveStatValue = resolver }
        )
        assertClose(findDelta(eventUnit, "mana").delta, 21, unitType .. " EventUnit stat resolution")
    end

    return true
end

run()
print("ResourceSync regeneration tests passed")
