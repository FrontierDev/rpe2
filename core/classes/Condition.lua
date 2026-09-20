local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Condition = {}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function ensureTable(value)
    if type(value) == "table" then
        return value
    end

    return {}
end

local function normalizeBoolean(value, fallback)
    if value == nil then
        return fallback == true
    end

    return value == true
end

local function normalizeRef(value)
    local ref = ensureString(value)
    if ref == "" then
        return nil
    end

    return ref
end

local function normalizeRefList(values)
    local normalized = {}
    local seen = {}

    for index = 1, #(values or {}) do
        local ref = normalizeRef(values[index])
        if ref and not seen[ref] then
            seen[ref] = true
            normalized[#normalized + 1] = ref
        end
    end

    return normalized
end

local function normalizeStringList(values)
    local normalized = {}
    local seen = {}

    for index = 1, #(values or {}) do
        local entry = string.lower(ensureString(values[index]))
        if entry ~= "" and not seen[entry] then
            seen[entry] = true
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

local function normalizeUnitSelector(value)
    local selector = string.lower(ensureString(value))
    if selector == "target" then
        return "target"
    end

    return "caster"
end

local function normalizeComparisonCondition(data)
    return {
        minimumValue = tonumber(data.minimumValue),
        maximumValue = tonumber(data.maximumValue),
    }
end

local TYPE_DEFAULTS = {
    level = {
        minimumValue = nil,
        maximumValue = nil,
    },
    class = {
        classRefs = {},
    },
    race = {
        raceRefs = {},
    },
    weapon_type = {
        slotKey = "",
        weaponTypeRefs = {},
    },
    item_equipped = {
        slotKey = "",
        weaponTypeRefs = {},
        requiresShield = false,
    },
    aura_requirement = {
        unit = "caster",
        auraRef = nil,
        minimumValue = 1,
    },
    trait_requirement = {
        unit = "caster",
        traitRef = nil,
    },
    caster_dead = {},
    caster_defended_melee_this_turn = {},
    caster_failed_attack_this_turn = {},
    caster_killed_this_turn = {},
    target_killed_this_turn = {},
    caster_health_percent = {
        minimumValue = nil,
        maximumValue = nil,
    },
    target_health_percent = {
        minimumValue = nil,
        maximumValue = nil,
    },
    target_creature_type = {
        creatureTypes = {},
    },
    target_creature_size = {
        creatureSizes = {},
    },
    mounted = {
        unit = "caster",
    },
    skill_requirement = {
        skillRef = nil,
        minimumValue = nil,
        maximumValue = nil,
    },
    resource_type = {
        resourceRef = nil,
        allowHealth = false,
    },
}

local function createDefaults(conditionType)
    local defaults = TYPE_DEFAULTS[conditionType]
    if type(defaults) ~= "table" then
        return nil
    end

    local copy = {
        type = conditionType,
        showOnTooltip = false,
        tooltipTextOverride = "",
        invert = false,
    }
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            local list = {}
            for index = 1, #value do
                list[index] = value[index]
            end
            copy[key] = list
        else
            copy[key] = value
        end
    end
    return copy
end

function Condition.CreateDefaults(conditionType)
    return createDefaults(string.lower(ensureString(conditionType)))
end

function Condition.GetKnownTypes()
    local items = {}
    for conditionType in pairs(TYPE_DEFAULTS) do
        items[#items + 1] = conditionType
    end
    table.sort(items)
    return items
end

function Condition.IsKnownType(conditionType)
    return TYPE_DEFAULTS[string.lower(ensureString(conditionType))] ~= nil
end

function Condition.Normalize(value)
    local data = type(value) == "table" and value or nil
    local conditionType = string.lower(ensureString(data and data.type))
    local normalized = createDefaults(conditionType)
    if not normalized then
        return nil
    end

    normalized.showOnTooltip = normalizeBoolean(data.showOnTooltip, false)
    normalized.tooltipTextOverride = ensureString(data.tooltipTextOverride)
    normalized.invert = normalizeBoolean(data.invert, false)

    if conditionType == "level"
        or conditionType == "caster_health_percent"
        or conditionType == "target_health_percent"
    then
        local comparison = normalizeComparisonCondition(data)
        normalized.minimumValue = comparison.minimumValue
        normalized.maximumValue = comparison.maximumValue
        if normalized.minimumValue == nil and normalized.maximumValue == nil then
            return nil
        end
        return normalized
    end

    if conditionType == "class" then
        normalized.classRefs = normalizeRefList(data.classRefs)
        return #normalized.classRefs > 0 and normalized or nil
    end

    if conditionType == "race" then
        normalized.raceRefs = normalizeRefList(data.raceRefs)
        return #normalized.raceRefs > 0 and normalized or nil
    end

    if conditionType == "weapon_type" then
        normalized.slotKey = string.lower(ensureString(data.slotKey))
        normalized.weaponTypeRefs = normalizeRefList(data.weaponTypeRefs)
        return #normalized.weaponTypeRefs > 0 and normalized or nil
    end

    if conditionType == "item_equipped" then
        normalized.slotKey = string.lower(ensureString(data.slotKey))
        normalized.weaponTypeRefs = normalizeRefList(data.weaponTypeRefs)
        normalized.requiresShield = normalizeBoolean(data.requiresShield, false)
        return normalized.slotKey ~= "" and normalized or nil
    end

    if conditionType == "aura_requirement" then
        normalized.unit = normalizeUnitSelector(data.unit)
        normalized.auraRef = normalizeRef(data.auraRef)
        normalized.minimumValue = math.max(1, math.floor(tonumber(data.minimumValue) or 1))
        return normalized.auraRef and normalized or nil
    end

    if conditionType == "trait_requirement" then
        normalized.unit = normalizeUnitSelector(data.unit)
        normalized.traitRef = normalizeRef(data.traitRef)
        return normalized.traitRef and normalized or nil
    end

    if conditionType == "caster_dead"
        or conditionType == "caster_defended_melee_this_turn"
        or conditionType == "caster_failed_attack_this_turn"
        or conditionType == "caster_killed_this_turn"
        or conditionType == "target_killed_this_turn"
    then
        return normalized
    end

    if conditionType == "target_creature_type" then
        normalized.creatureTypes = normalizeStringList(data.creatureTypes)
        return #normalized.creatureTypes > 0 and normalized or nil
    end

    if conditionType == "target_creature_size" then
        normalized.creatureSizes = normalizeStringList(data.creatureSizes)
        return #normalized.creatureSizes > 0 and normalized or nil
    end

    if conditionType == "mounted" then
        normalized.unit = normalizeUnitSelector(data.unit)
        return normalized
    end

    if conditionType == "skill_requirement" then
        local comparison = normalizeComparisonCondition(data)
        normalized.skillRef = normalizeRef(data.skillRef)
        normalized.minimumValue = comparison.minimumValue
        normalized.maximumValue = comparison.maximumValue
        if not normalized.skillRef or (normalized.minimumValue == nil and normalized.maximumValue == nil) then
            return nil
        end
        return normalized
    end

    if conditionType == "resource_type" then
        normalized.resourceRef = normalizeRef(data.resourceRef)
        normalized.allowHealth = normalizeBoolean(data.allowHealth, false)
        return normalized.resourceRef and normalized or nil
    end

    return nil
end

function Condition.NormalizeList(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = Condition.Normalize(values[index])
        if entry then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

Addon.Internal.Database.Classes.Condition = Condition
