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

local Addon = {
    Client = {
        Combat = {},
    },
    Internal = {
        Database = {},
        Ruleset = {},
    },
    Utils = {
        Common = {
            Round = function(value)
                return math.floor((tonumber(value) or 0) + 0.5)
            end,
        },
        Dice = {},
        Lookup = {},
    },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("client/combat/Normalization.lua")
loadAddonFile("client/combat/Helpers.lua")

local Combat = Addon.Client.Combat
local mitigationModel = "level_scaled_percent"
Combat.GetCombatRule = function(_, key, fallback)
    if key == "damage_school_mitigation_model" then
        return mitigationModel
    end
    if key == "damage_school_mitigation_reference_level" then
        return 60
    end
    return fallback
end
Combat.GetRuleValue = function(_, category, key, fallback)
    if category == "character" and key == "use_level_system" then
        return true
    end
    return fallback
end

local natureSchool = {
    mitigationCoefficient = 0.1,
    mitigationMode = "percent",
    mitigationReferenceAmount = 300,
    mitigationReferencePercent = 75,
}

local negativeResistance = Combat:ResolveDamageSchoolMitigation(natureSchool, -290, 60)
assertClose(negativeResistance.rawPercent, -72.5, "negative resistance keeps its negative mitigation percentage")
assertClose(negativeResistance.percent, -72.5, "negative resistance is not clamped to zero")

local positiveResistance = Combat:ResolveDamageSchoolMitigation(natureSchool, 600, 60)
assertEqual(positiveResistance.percent, 100, "positive mitigation remains capped at 100 percent")

mitigationModel = "legacy"
local legacyNegativeResistance = Combat:ResolveDamageSchoolMitigation(natureSchool, -300, 60)
assertClose(legacyNegativeResistance.rawPercent, -30, "legacy negative resistance keeps its negative mitigation percentage")
assertClose(legacyNegativeResistance.percent, -30, "legacy negative resistance is not clamped to zero")

print("Negative resistance mitigation tests passed")
