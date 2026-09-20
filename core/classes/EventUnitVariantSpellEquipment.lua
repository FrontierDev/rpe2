local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local EventUnit = Addon.Internal.Database.Classes.EventUnit
if type(EventUnit) ~= "table" or EventUnit._variantSpellEquipmentResolutionInstalled == true then
    return
end

local EQUIPMENT_KEYS = {
    mainHandWeapon = true,
    offHandWeapon = true,
    rangedWeapon = true,
    shield = true,
}

local function cloneList(values)
    local copy = {}
    for index = 1, #(values or {}) do
        copy[index] = values[index]
    end
    return copy
end

local function isPresetNpc(unit)
    if type(unit) ~= "table" or unit.isPlayer == true then
        return false
    end
    local index = type(EventUnit.NormalizeVariantIndex) == "function"
        and EventUnit.NormalizeVariantIndex(unit.presetIndex)
        or math.max(0, math.floor(tonumber(unit.presetIndex) or 0))
    return index > 0
end

local baseGetResolvedValue = EventUnit.GetResolvedValue
function EventUnit:GetResolvedValue(key, fallback, options)
    if isPresetNpc(self) then
        if key == "spells" then
            -- Preset spells are host-materialized runtime state. Empty is a
            -- meaningful replacement and must not fall through to Base.
            return cloneList(self.spells)
        end
        if EQUIPMENT_KEYS[key] then
            -- The same applies to explicit unequipped Presets: nil is the
            -- authoritative runtime value, not an instruction to inherit Base.
            return self[key]
        end
    end

    return type(baseGetResolvedValue) == "function" and baseGetResolvedValue(self, key, fallback, options) or fallback
end

local baseBuildResolvedSpellRefs = EventUnit.BuildResolvedSpellRefs
function EventUnit.BuildResolvedSpellRefs(eventUnit, fallback)
    if isPresetNpc(eventUnit) then
        return cloneList(eventUnit.spells)
    end
    return type(baseBuildResolvedSpellRefs) == "function" and baseBuildResolvedSpellRefs(eventUnit, fallback) or cloneList(fallback)
end

EventUnit._variantSpellEquipmentResolutionInstalled = true
