-- Run from the addon root with a Lua interpreter:
--   lua tests/LightOfProtectorResolutionTest.lua

local function contains(values, expected)
    for index = 1, #(values or {}) do
        if values[index] == expected then
            return true
        end
    end

    return false
end

local registeredDataset = nil
local addon = {
    Client = {
        Combat = {},
        Spellcasting = {},
        UI = {},
    },
    Data = {
        DefaultDatasets = {
            Register = function(_, definition)
                registeredDataset = definition
            end,
        },
    },
    Internal = {},
    UI = {},
    Utils = {
        Common = {},
        Lookup = {},
    },
}

assert(loadfile("data/default/classes/paladin.lua"))("RPEngine2", addon)
assert(type(registeredDataset) == "table", "Paladin default dataset did not register")
assert(registeredDataset.version == 10, "Paladin default dataset version was not incremented")

local spell = nil
for index = 1, #(registeredDataset.dataset.spells or {}) do
    local candidate = registeredDataset.dataset.spells[index]
    if candidate and candidate.id == "x2qgj4wy" then
        spell = candidate
        break
    end
end

assert(type(spell) == "table", "Light of the Protector was not found")
local component = spell.components and spell.components[1] or nil
assert(type(component) == "table" and type(component.effect) == "table", "Light of the Protector heal component is missing")
assert(component.target.type == "caster", "Light of the Protector must target its caster")
assert(component.target.requiresTarget ~= true, "Light of the Protector must not require an external target")
assert(contains(spell.casterEvents, "on_heal"), "Light of the Protector must emit on_heal for its caster")
assert(contains(spell.casterEvents, "on_critical_heal"), "Light of the Protector must emit on_critical_heal for its caster")
assert(not contains(spell.casterEvents, "on_heal_taken"), "Target heal events must not be registered as caster events")
assert(not contains(spell.casterEvents, "on_critical_heal_taken"), "Target critical-heal events must not be registered as caster events")
assert(contains(component.effect.targetEvents, "on_heal_taken"), "Light of the Protector must emit on_heal_taken for its target")

assert(loadfile("client/spellcasting/Helpers.lua"))("RPEngine2", addon)
local caster = { eventID = 101, name = "Caster" }
local selectedOtherUnit = { eventID = 202, name = "Selected Other Unit" }
local targets = addon.Client.Spellcasting.ResolveComponentTargets({
    units = { caster, selectedOtherUnit },
}, caster, component, {
    focusedTargetEventId = selectedOtherUnit.eventID,
    targetEventIds = { selectedOtherUnit.eventID },
})

assert(#targets == 1, "Light of the Protector must resolve exactly one target")
assert(targets[1] == caster, "Light of the Protector must resolve the casting unit, not the selected unit")

print("LightOfProtectorResolutionTest: passed")
