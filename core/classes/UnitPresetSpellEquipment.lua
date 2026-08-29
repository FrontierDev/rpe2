local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Unit = Addon.Internal.Database.Classes.Unit
if type(Unit) ~= "table" or Unit._presetSpellEquipmentInstalled == true then
    return
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end
    return copy
end

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeRef(value)
    local ref = trim(value)
    return ref ~= "" and ref or nil
end

local function normalizeSpells(values)
    local normalized = {}
    if type(values) ~= "table" then
        return normalized
    end

    for index = 1, #values do
        local spellRef = normalizeRef(values[index])
        if spellRef then
            normalized[#normalized + 1] = spellRef
        end
    end
    return normalized
end

local EQUIPMENT_FIELDS = {
    "mainHandWeapon",
    "offHandWeapon",
    "rangedWeapon",
    "shield",
}

local function normalizeEquipment(value)
    local source = type(value) == "table" and value or {}
    local normalized = {}
    for index = 1, #EQUIPMENT_FIELDS do
        local key = EQUIPMENT_FIELDS[index]
        local itemRef = normalizeRef(source[key])
        if itemRef then
            normalized[key] = itemRef
        end
    end
    return normalized
end

local baseNormalizePreset = Unit.NormalizePreset
local baseNormalizePresets = Unit.NormalizePresets
local baseMerge = Unit.Merge
local baseToTable = Unit.ToTable

local function normalizePreset(value)
    local source = type(value) == "table" and value or {}
    local normalized = type(baseNormalizePreset) == "function" and baseNormalizePreset(source) or {}

    -- Field presence is authoritative for inheritance. An explicit empty table
    -- is therefore retained as an explicit replacement rather than normalized
    -- back to nil/Base inheritance.
    if source.spells ~= nil then
        normalized.spells = normalizeSpells(source.spells)
    else
        normalized.spells = nil
    end

    if source.equipment ~= nil then
        normalized.equipment = normalizeEquipment(source.equipment)
    else
        normalized.equipment = nil
    end

    return normalized
end

local function normalizePresets(values)
    local normalized = {}
    if type(values) ~= "table" then
        return normalized
    end

    for index = 1, #values do
        normalized[index] = normalizePreset(values[index])
    end
    return normalized
end

function Unit.NormalizePreset(value)
    return normalizePreset(value)
end

function Unit.NormalizePresets(values)
    return normalizePresets(values)
end

function Unit.ResolvePreset(unit, presetIndex)
    local normalizedIndex = Unit.NormalizePresetIndex(unit, presetIndex)
    if normalizedIndex == 0 then
        return nil, 0
    end
    return normalizePreset(unit.presets[normalizedIndex]), normalizedIndex
end

function Unit.ResolveEffectiveSpells(unit, presetIndex)
    local preset = Unit.ResolvePreset(unit, presetIndex)
    if preset and preset.spells ~= nil then
        return normalizeSpells(preset.spells)
    end
    return normalizeSpells(type(unit) == "table" and unit.spells or nil)
end

function Unit.ResolveEffectiveEquipment(unit, presetIndex)
    local preset = Unit.ResolvePreset(unit, presetIndex)
    if preset and preset.equipment ~= nil then
        return normalizeEquipment(preset.equipment)
    end

    local base = {}
    if type(unit) == "table" then
        for index = 1, #EQUIPMENT_FIELDS do
            local key = EQUIPMENT_FIELDS[index]
            base[key] = unit[key]
        end
    end
    return normalizeEquipment(base)
end

function Unit:Merge(data)
    -- The base #84 normalizer predates spell/equipment overrides and strips
    -- unknown Preset keys. Capture the authored Presets before delegating, then
    -- restore them through the #94 canonical normalizer.
    local sourcePresets = nil
    if type(data) == "table" and data.presets ~= nil then
        sourcePresets = deepCopy(data.presets)
    elseif type(self.presets) == "table" then
        sourcePresets = deepCopy(self.presets)
    end

    local merged = type(baseMerge) == "function" and baseMerge(self, data) or self
    merged.presets = normalizePresets(sourcePresets)
    return merged
end

function Unit:ToTable()
    local data = type(baseToTable) == "function" and baseToTable(self) or {}
    data.presets = normalizePresets(self.presets)
    return data
end

Unit.NormalizePresetEquipment = normalizeEquipment
Unit.NormalizePresetSpells = normalizeSpells
Unit.PresetEquipmentFields = deepCopy(EQUIPMENT_FIELDS)
Unit._presetSpellEquipmentInstalled = true
