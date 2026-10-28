local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Addon = {
    Internal = {
        Database = {
            Classes = {},
        },
    },
}

local chunk, loadError = loadfile("core/classes/Aura.lua")
assert(chunk, loadError)
chunk(nil, Addon)

local Aura = Addon.Internal.Database.Classes.Aura
local resolve = Aura.ResolveDisposition

assertEqual(resolve({ effects = { { type = "damage", baseDamage = 1 } } }), "harmful",
    "damage is automatically harmful")
assertEqual(resolve({ effects = { { type = "stat", baseAmount = -3 } } }), "harmful",
    "negative stat changes are automatically harmful")
assertEqual(resolve({ effects = { { type = "resource", amount = -1 } } }), "harmful",
    "negative resource changes are automatically harmful")
assertEqual(resolve({ effects = { { type = "stat", baseAmount = 3 } } }), "helpful",
    "positive stat changes are automatically helpful")
assertEqual(resolve({ effects = { { type = "resource", amount = 1 } } }), "helpful",
    "positive resource changes are automatically helpful")
assertEqual(resolve({ effects = { { type = "control", preventCasting = true } } }), "harmful",
    "disabling control is automatically harmful")
assertEqual(resolve({ effects = { { type = "heal", baseHealing = 1 } } }), "helpful",
    "healing is automatically helpful")
assertEqual(resolve({ effects = { { type = "absorb", baseAbsorption = 1 } } }), "helpful",
    "absorption is automatically helpful")

assertEqual(resolve({
    events = {
        { triggerTarget = "event_other", effects = { { type = "damage" } } },
    },
}), "helpful", "event-other damage does not classify the aura recipient as harmful")
assertEqual(resolve({
    events = {
        { triggerTarget = "event_source", effects = { { type = "damage" } } },
    },
}), "helpful", "event-source retaliation damage does not classify the aura recipient as harmful")
assertEqual(resolve({
    events = {
        { triggerTarget = "aura_target", effects = { { type = "damage" } } },
    },
}), "harmful", "aura-target damage is automatically harmful")
assertEqual(resolve({
    events = {
        { triggerTarget = "aura_caster", effects = { { type = "damage" } } },
    },
}, { auraCasterEventId = 7, auraTargetEventId = 7 }), "harmful",
    "self-targeted aura-caster damage is automatically harmful")
assertEqual(resolve({
    events = {
        { triggerTarget = "aura_caster", effects = { { type = "damage" } } },
    },
}, { auraCasterEventId = 7, auraTargetEventId = 8 }), "helpful",
    "other-target aura-caster damage does not classify the recipient as harmful")

assertEqual(resolve({
    effects = {
        { type = "heal" },
        { type = "damage" },
    },
}), "harmful", "mixed automatic effects use the deterministic harmful result")
assertEqual(resolve({
    disposition = "helpful",
    effects = { { type = "damage" } },
}), "helpful", "explicit helpful disposition overrides automatic damage semantics")
assertEqual(resolve({
    disposition = "harmful",
    effects = { { type = "heal" } },
}), "harmful", "explicit harmful disposition overrides automatic healing semantics")

local nestedDefinitions = {
    ["test:nested"] = { effects = { { type = "control", movementRangeOverride = 0 } } },
    ["test:cycle-a"] = { effects = { { type = "apply_aura", auraRef = "test:cycle-b" } } },
    ["test:cycle-b"] = { effects = { { type = "apply_aura", auraRef = "test:cycle-a" } } },
}
assertEqual(resolve({
    effects = { { type = "apply_aura", auraRef = "test:nested" } },
}, {
    resolveAura = function(auraRef)
        return nestedDefinitions[auraRef]
    end,
}), "harmful", "nested disabling aura effects are included in automatic semantics")
assertEqual(resolve(nestedDefinitions["test:cycle-a"], {
    resolveAura = function(auraRef)
        return nestedDefinitions[auraRef]
    end,
}), "helpful", "cyclic nested aura definitions terminate safely")

local helpfulAura = Aura:New({ disposition = "helpful" })
local helpfulRoundTrip = Aura:FromTable(helpfulAura:ToTable())
assertEqual(helpfulAura.disposition, "helpful", "Aura model stores explicit helpful disposition")
assertEqual(helpfulAura.polarity, "helpful", "legacy polarity remains synchronized for explicit disposition")
assertEqual(helpfulRoundTrip.disposition, "helpful", "Aura disposition round-trip preserves explicit value")
assertEqual(Aura:New({}).disposition, "auto", "missing disposition defaults to automatic")
assertEqual(Aura:New({ polarity = "harmful" }).disposition, "harmful",
    "legacy polarity remains a backward-compatible input")
assertEqual(#helpfulAura:Validate(), 0, "valid Aura disposition passes validation")
