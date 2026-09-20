local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Unit = {}
Unit.__index = Unit

local CHALLENGE_LEVEL_DEFINITIONS = {
    { label = "Swarm", value = "swarm" },
    { label = "Minor", value = "minor" },
    { label = "Normal", value = "normal" },
    { label = "Elite", value = "elite" },
    { label = "Boss", value = "boss" },
}

local VALID_CHALLENGE_LEVELS = {}
for index = 1, #CHALLENGE_LEVEL_DEFINITIONS do
    VALID_CHALLENGE_LEVELS[CHALLENGE_LEVEL_DEFINITIONS[index].value] = true
end

local APPEARANCE_DEFAULT_CAM = 1
local APPEARANCE_DEFAULT_ROT = 0
local APPEARANCE_DEFAULT_Z = -0.35

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimString(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeNumber(value, fallback)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return fallback or 0
    end

    return numeric
end

local function normalizeOptionalNumber(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return nil
    end

    return numeric
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

local function normalizeList(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local value = values[index]
        if value ~= nil then
            normalized[#normalized + 1] = value
        end
    end

    return normalized
end

local function normalizeTags(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local tag = ensureString(values[index])
        if tag ~= "" then
            normalized[#normalized + 1] = tag
        end
    end

    return normalized
end

local function normalizeRef(value)
    local ref = ensureString(value)
    if ref == "" then
        return nil
    end

    return ref
end

local function normalizeExtendsUnitRef(value)
    local ref = trimString(value)
    return ref ~= "" and ref or nil
end

local function normalizeModifierRef(value)
    local ref = trimString(value)
    if ref == "" then
        return nil
    end

    return ref
end

local function normalizeUnitSpells(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local spellRef = normalizeRef(values[index])
        if spellRef then
            normalized[#normalized + 1] = spellRef
        end
    end

    return normalized
end

local function normalizeUnitStats(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local statRef = type(entry) == "table" and normalizeRef(entry.statRef) or nil
        if statRef then
            local initialValue = entry.initialValue
            if initialValue == nil then
                initialValue = entry.value
            end
            normalized[#normalized + 1] = {
                statRef = statRef,
                initialValue = normalizeNumber(initialValue, 0),
                perLevelValue = normalizeNumber(entry.perLevelValue, 0),
            }
        end
    end

    return normalized
end

local function normalizeUnitResources(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local resourceRef = type(entry) == "table" and normalizeRef(entry.resourceRef) or nil
        if resourceRef then
            local initialValue = entry.initialValue
            if initialValue == nil then
                initialValue = entry.value
            end
            normalized[#normalized + 1] = {
                resourceRef = resourceRef,
                initialValue = normalizeNumber(initialValue, 0),
                perLevelValue = normalizeNumber(entry.perLevelValue, 0),
            }
        end
    end

    return normalized
end

local function normalizeUnitAttributes(values)
    local normalized = {}
    local seen = {}

    for index = 1, #(values or {}) do
        local attribute = ensureString(values[index])
        if attribute ~= "" and not seen[attribute] then
            normalized[#normalized + 1] = attribute
            seen[attribute] = true
        end
    end

    return normalized
end

local function normalizeUnitResistances(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local damageSchoolRef = type(entry) == "table" and normalizeRef(entry.damageSchoolRef) or nil
        if damageSchoolRef then
            normalized[#normalized + 1] = {
                damageSchoolRef = damageSchoolRef,
                coefficient = tonumber(entry.coefficient) or 0,
            }
        end
    end

    return normalized
end

local function normalizeAppearance(value)
    if type(value) ~= "table" then
        return nil
    end

    local displayId = normalizeOptionalNumber(value.displayId)
    local fileDataId = normalizeOptionalNumber(value.fileDataId)
    if displayId == nil and fileDataId == nil then
        return nil
    end

    return {
        displayId = displayId,
        fileDataId = fileDataId,
        cam = normalizeNumber(value.cam, APPEARANCE_DEFAULT_CAM),
        rot = normalizeNumber(value.rot, APPEARANCE_DEFAULT_ROT),
        z = normalizeNumber(value.z, APPEARANCE_DEFAULT_Z),
    }
end

local function normalizeUnitAppearances(values)
    local normalized = {}
    if type(values) ~= "table" then
        return normalized
    end

    for index = 1, #values do
        local appearance = normalizeAppearance(values[index])
        if appearance then
            normalized[#normalized + 1] = appearance
        end
    end

    return normalized
end

local function normalizeModifierList(values, refKey)
    local normalized = {}
    local seen = {}
    if type(values) ~= "table" then
        return normalized
    end

    for index = 1, #values do
        local entry = values[index]
        local ref = type(entry) == "table" and normalizeModifierRef(entry[refKey]) or nil
        if ref and not seen[ref] then
            normalized[#normalized + 1] = {
                [refKey] = ref,
                percentBonus = normalizeNumber(entry.percentBonus, 0),
                flatBonus = normalizeNumber(entry.flatBonus, 0),
            }
            seen[ref] = true
        end
    end

    return normalized
end

local function normalizePresetChallengeLevel(value)
    if value == nil then
        return nil
    end

    local candidate = trimString(value):lower()
    if not VALID_CHALLENGE_LEVELS[candidate] then
        error(("Invalid Unit preset challenge level '%s'."):format(tostring(value)), 3)
    end

    return candidate
end

local function normalizePreset(value)
    local source = type(value) == "table" and value or {}
    return {
        name = trimString(source.name),
        challengeLevel = normalizePresetChallengeLevel(source.challengeLevel),
        statModifiers = normalizeModifierList(source.statModifiers, "statRef"),
        resourceModifiers = normalizeModifierList(source.resourceModifiers, "resourceRef"),
        appearances = normalizeUnitAppearances(source.appearances),
    }
end

local function normalizeUnitPresets(values)
    local normalized = {}
    if type(values) ~= "table" then
        return normalized
    end

    for index = 1, #values do
        normalized[#normalized + 1] = normalizePreset(values[index])
    end

    return normalized
end

local function normalizeBaseAppearances(unit)
    if type(unit) ~= "table" then
        return {}
    end

    if unit.appearances ~= nil then
        return normalizeUnitAppearances(unit.appearances)
    end

    local legacyAppearance = normalizeAppearance(unit)
    if legacyAppearance then
        return { legacyAppearance }
    end

    return {}
end

local function applyNumericModifier(baseValue, modifier)
    local base = normalizeNumber(baseValue, 0)
    local percentBonus = normalizeNumber(modifier and modifier.percentBonus, 0)
    local flatBonus = normalizeNumber(modifier and modifier.flatBonus, 0)
    return base * (1 + percentBonus / 100) + flatBonus
end

local function normalizeProgressionLevel(level)
    local numeric = normalizeOptionalNumber(level)
    if numeric == nil then
        return 1
    end

    return math.max(1, math.floor(numeric))
end

function Unit.ResolveProgressionValue(initialValue, perLevelValue, level)
    local normalizedInitial = normalizeNumber(initialValue, 0)
    local normalizedPerLevel = normalizeNumber(perLevelValue, 0)
    return normalizedInitial + ((normalizeProgressionLevel(level) - 1) * normalizedPerLevel)
end

function Unit.ResolveStatValues(unit, level)
    local resolved = {}
    local stats = normalizeUnitStats(type(unit) == "table" and unit.stats or nil)

    for index = 1, #stats do
        local entry = stats[index]
        resolved[#resolved + 1] = {
            statRef = entry.statRef,
            value = Unit.ResolveProgressionValue(entry.initialValue, entry.perLevelValue, level),
        }
    end

    return resolved
end

function Unit.ResolveResourceValues(unit, level)
    local resolved = {}
    local resources = normalizeUnitResources(type(unit) == "table" and unit.resources or nil)

    for index = 1, #resources do
        local entry = resources[index]
        resolved[#resolved + 1] = {
            resourceRef = entry.resourceRef,
            value = Unit.ResolveProgressionValue(entry.initialValue, entry.perLevelValue, level),
        }
    end

    return resolved
end

function Unit.GetChallengeLevelDefinitions()
    local definitions = {}
    for index = 1, #CHALLENGE_LEVEL_DEFINITIONS do
        local definition = CHALLENGE_LEVEL_DEFINITIONS[index]
        definitions[index] = {
            label = definition.label,
            value = definition.value,
        }
    end
    return definitions
end

function Unit.NormalizeChallengeLevel(value)
    local candidate = ensureString(value):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if VALID_CHALLENGE_LEVELS[candidate] then
        return candidate
    end

    return "normal"
end

function Unit.IsValidChallengeLevel(value)
    local candidate = trimString(value):lower()
    return VALID_CHALLENGE_LEVELS[candidate] == true
end

function Unit.NormalizeAppearance(value)
    return normalizeAppearance(value)
end

function Unit.NormalizeAppearances(values)
    return normalizeUnitAppearances(values)
end

function Unit.NormalizePreset(value)
    return normalizePreset(value)
end

function Unit.NormalizePresets(values)
    return normalizeUnitPresets(values)
end

function Unit.NormalizePresetIndex(unit, presetIndex)
    local numericIndex = tonumber(presetIndex)
    if numericIndex == nil
        or numericIndex ~= numericIndex
        or numericIndex == math.huge
        or numericIndex == -math.huge
        or numericIndex < 1
        or math.floor(numericIndex) ~= numericIndex
    then
        return 0
    end

    local presets = type(unit) == "table" and unit.presets or nil
    if type(presets) ~= "table" or numericIndex > #presets then
        return 0
    end

    return numericIndex
end

function Unit.ResolvePreset(unit, presetIndex)
    local normalizedIndex = Unit.NormalizePresetIndex(unit, presetIndex)
    if normalizedIndex == 0 then
        return nil, 0
    end

    return normalizePreset(unit.presets[normalizedIndex]), normalizedIndex
end

function Unit.ResolveEffectiveChallengeLevel(unit, presetIndex)
    local preset = Unit.ResolvePreset(unit, presetIndex)
    if preset and preset.challengeLevel ~= nil then
        return preset.challengeLevel
    end

    return Unit.NormalizeChallengeLevel(type(unit) == "table" and unit.challengeLevel or nil)
end

function Unit.ResolveVariantName(unit, presetIndex)
    local baseName = type(unit) == "table" and ensureString(unit.name) or ""
    local preset = Unit.ResolvePreset(unit, presetIndex)
    if not preset or preset.name == "" then
        return baseName
    end

    if baseName == "" then
        return preset.name
    end

    return baseName .. " " .. preset.name
end

function Unit.ResolveEffectiveAppearances(unit, presetIndex)
    local preset = Unit.ResolvePreset(unit, presetIndex)
    if preset and #preset.appearances > 0 then
        return normalizeUnitAppearances(preset.appearances)
    end

    return normalizeBaseAppearances(unit)
end

function Unit.ResolveAppearance(unit, presetIndex, appearanceIndex)
    local appearances = Unit.ResolveEffectiveAppearances(unit, presetIndex)
    if #appearances == 0 then
        return nil
    end

    local numericIndex = tonumber(appearanceIndex)
    if numericIndex == nil
        or numericIndex ~= numericIndex
        or numericIndex == math.huge
        or numericIndex == -math.huge
        or numericIndex <= 0
    then
        return nil
    end

    if math.floor(numericIndex) == numericIndex and numericIndex <= #appearances then
        return deepCopy(appearances[numericIndex])
    end

    return deepCopy(appearances[1])
end

function Unit.ApplyStatModifiers(stats, preset)
    local resolved = deepCopy(type(stats) == "table" and stats or {})
    local indexByRef = {}

    for index = 1, #resolved do
        local entry = resolved[index]
        local statRef = type(entry) == "table" and normalizeModifierRef(entry.statRef) or nil
        if statRef then
            entry.statRef = statRef
            entry.value = normalizeNumber(entry.value, 0)
            if indexByRef[statRef] == nil then
                indexByRef[statRef] = index
            end
        end
    end

    local normalizedPreset = normalizePreset(preset)
    for index = 1, #normalizedPreset.statModifiers do
        local modifier = normalizedPreset.statModifiers[index]
        local targetIndex = indexByRef[modifier.statRef]
        if targetIndex then
            local entry = resolved[targetIndex]
            entry.value = applyNumericModifier(entry.value, modifier)
        else
            resolved[#resolved + 1] = {
                statRef = modifier.statRef,
                value = applyNumericModifier(0, modifier),
            }
            indexByRef[modifier.statRef] = #resolved
        end
    end

    return resolved
end

function Unit.ApplyResourceModifiers(resources, preset)
    local resolved = deepCopy(type(resources) == "table" and resources or {})
    local indexByRef = {}

    for index = 1, #resolved do
        local entry = resolved[index]
        local resourceRef = type(entry) == "table" and normalizeModifierRef(entry.resourceRef) or nil
        if resourceRef then
            entry.resourceRef = resourceRef
            entry.value = math.max(0, normalizeNumber(entry.value, 0))
            if indexByRef[resourceRef] == nil then
                indexByRef[resourceRef] = index
            end
        end
    end

    local normalizedPreset = normalizePreset(preset)
    for index = 1, #normalizedPreset.resourceModifiers do
        local modifier = normalizedPreset.resourceModifiers[index]
        local targetIndex = indexByRef[modifier.resourceRef]
        if targetIndex then
            local entry = resolved[targetIndex]
            entry.value = math.max(0, applyNumericModifier(entry.value, modifier))
        end
    end

    return resolved
end

function Unit:New(data)
    local instance = setmetatable({
        id = nil,
        extendsUnitRef = nil,
        name = "",
        description = nil,
        creatureType = "humanoid",
        creatureSize = "medium",
        challengeLevel = "normal",
        appearances = {},
        presets = {},
        -- Temporary in-memory aliases for consumers that still read the old
        -- single-model fields. Canonical persistence is appearances/presets.
        displayId = nil,
        fileDataId = nil,
        cam = APPEARANCE_DEFAULT_CAM,
        rot = APPEARANCE_DEFAULT_ROT,
        z = APPEARANCE_DEFAULT_Z,
        mainHandWeapon = nil,
        offHandWeapon = nil,
        rangedWeapon = nil,
        shield = nil,
        spells = {},
        stats = {},
        resources = {},
        resistances = {},
        attributes = {},
        tags = {},
        _authoredFields = {},
    }, Unit)

    return instance:Merge(data)
end

function Unit:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    self._authoredFields = type(self._authoredFields) == "table" and self._authoredFields or {}
    for key in pairs(data) do
        self._authoredFields[key] = true
    end

    local hasCanonicalAppearances = data.appearances ~= nil
    local legacyAppearance = nil
    if not hasCanonicalAppearances then
        legacyAppearance = normalizeAppearance(data)
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    self.id = self.id ~= nil and tostring(self.id) or nil
    self.extendsUnitRef = normalizeExtendsUnitRef(self.extendsUnitRef)
    self.name = ensureString(self.name)
    self.description = self.description ~= nil and ensureString(self.description) or nil
    self.creatureType = ensureString(self.creatureType ~= "" and self.creatureType or "humanoid")
    self.creatureSize = ensureString(self.creatureSize ~= "" and self.creatureSize or "medium")
    self.challengeLevel = Unit.NormalizeChallengeLevel(self.challengeLevel)

    if hasCanonicalAppearances then
        self.appearances = normalizeUnitAppearances(data.appearances)
    elseif legacyAppearance then
        self.appearances = { legacyAppearance }
    else
        self.appearances = {}
    end
    self.presets = normalizeUnitPresets(self.presets)

    -- Keep old model readers functional in memory without treating these
    -- fields as the persisted source of truth after canonical migration.
    local primaryAppearance = self.appearances[1]
    self.displayId = primaryAppearance and primaryAppearance.displayId or nil
    self.fileDataId = primaryAppearance and primaryAppearance.fileDataId or nil
    self.cam = primaryAppearance and primaryAppearance.cam or APPEARANCE_DEFAULT_CAM
    self.rot = primaryAppearance and primaryAppearance.rot or APPEARANCE_DEFAULT_ROT
    self.z = primaryAppearance and primaryAppearance.z or APPEARANCE_DEFAULT_Z

    self.mainHandWeapon = normalizeRef(self.mainHandWeapon)
    self.offHandWeapon = normalizeRef(self.offHandWeapon)
    self.rangedWeapon = normalizeRef(self.rangedWeapon)
    self.shield = normalizeRef(self.shield)
    self.spells = normalizeUnitSpells(self.spells)
    self.stats = normalizeUnitStats(self.stats)
    self.resources = normalizeUnitResources(self.resources)
    self.resistances = normalizeUnitResistances(self.resistances)
    self.attributes = normalizeUnitAttributes(self.attributes)
    self.tags = normalizeTags(self.tags)

    return self
end

function Unit:ToTable()
    local data = {
        id = self.id,
        extendsUnitRef = self.extendsUnitRef,
    }

    local extending = self.extendsUnitRef ~= nil
    local authored = type(self._authoredFields) == "table" and self._authoredFields or {}
    local constructorDefaults = {
        name = "",
        creatureType = "humanoid",
        creatureSize = "medium",
        challengeLevel = "normal",
    }
    local function includeScalar(key, value)
        if not extending or authored[key] or value ~= constructorDefaults[key] then
            data[key] = value
        end
    end

    includeScalar("name", self.name)
    includeScalar("description", self.description)
    includeScalar("creatureType", self.creatureType)
    includeScalar("creatureSize", self.creatureSize)
    includeScalar("challengeLevel", Unit.NormalizeChallengeLevel(self.challengeLevel))
    includeScalar("mainHandWeapon", self.mainHandWeapon)
    includeScalar("offHandWeapon", self.offHandWeapon)
    includeScalar("rangedWeapon", self.rangedWeapon)
    includeScalar("shield", self.shield)

    local function includeOverlay(key, value, legacyPresence)
        if not extending or authored[key] or legacyPresence or #value > 0 then
            data[key] = value
        end
    end

    includeOverlay("appearances", normalizeUnitAppearances(self.appearances),
        authored.displayId or authored.fileDataId)
    includeOverlay("presets", normalizeUnitPresets(self.presets))
    includeOverlay("spells", normalizeList(self.spells))
    includeOverlay("stats", normalizeUnitStats(self.stats))
    includeOverlay("resources", normalizeUnitResources(self.resources))
    includeOverlay("resistances", normalizeUnitResistances(self.resistances))
    includeOverlay("attributes", normalizeList(self.attributes))
    includeOverlay("tags", normalizeList(self.tags))

    return data
end

local function appendOrderedUnique(target, seen, values, normalize)
    for index = 1, #(values or {}) do
        local value = normalize(values[index])
        if value ~= nil and value ~= "" and not seen[value] then
            target[#target + 1] = value
            seen[value] = true
        end
    end
end

local function mergeOrderedRefs(parentValues, childValues)
    local values = {}
    local seen = {}
    local function add(value)
        local ref = normalizeRef(value)
        if ref and not seen[ref] then
            values[#values + 1] = ref
            seen[ref] = true
        end
    end
    for index = 1, #(parentValues or {}) do add(parentValues[index]) end
    for index = 1, #(childValues or {}) do add(childValues[index]) end
    return values
end

local function mergeByReference(parentValues, childValues, refKey, normalize)
    local values = {}
    local indexByRef = {}
    local function add(entry)
        local normalized = normalize(entry)
        local ref = normalized and normalized[refKey] or nil
        if ref then
            local index = indexByRef[ref]
            if index then
                values[index] = normalized
            else
                values[#values + 1] = normalized
                indexByRef[ref] = #values
            end
        end
    end
    for index = 1, #(parentValues or {}) do add(parentValues[index]) end
    for index = 1, #(childValues or {}) do add(childValues[index]) end
    return values
end

function Unit.MergeDefinitions(parent, child)
    local parentDefinition = type(parent) == "table" and parent or {}
    local childDefinition = type(child) == "table" and child or {}
    local merged = deepCopy(parentDefinition)

    -- The child's entry identity always wins; an ancestor's ID is never copied.
    merged.id = childDefinition.id
    merged.extendsUnitRef = normalizeExtendsUnitRef(childDefinition.extendsUnitRef)
    local scalarFields = {
        "name", "description", "creatureType", "creatureSize", "challengeLevel",
        "mainHandWeapon", "offHandWeapon", "rangedWeapon", "shield",
    }
    for index = 1, #scalarFields do
        local key = scalarFields[index]
        if childDefinition[key] ~= nil then
            if key == "mainHandWeapon" or key == "offHandWeapon" or key == "rangedWeapon" or key == "shield" then
                merged[key] = normalizeRef(childDefinition[key])
            else
                merged[key] = deepCopy(childDefinition[key])
            end
        end
    end

    local childAppearances
    if childDefinition.appearances ~= nil then
        childAppearances = normalizeUnitAppearances(childDefinition.appearances)
    else
        local legacyAppearance = normalizeAppearance(childDefinition)
        childAppearances = legacyAppearance and { legacyAppearance } or {}
    end
    merged.appearances = normalizeUnitAppearances(parentDefinition.appearances)
    for index = 1, #childAppearances do
        merged.appearances[#merged.appearances + 1] = deepCopy(childAppearances[index])
    end

    local parentPresets = type(Unit.NormalizePresets) == "function"
        and Unit.NormalizePresets(parentDefinition.presets) or normalizeUnitPresets(parentDefinition.presets)
    local childPresets = type(Unit.NormalizePresets) == "function"
        and Unit.NormalizePresets(childDefinition.presets) or normalizeUnitPresets(childDefinition.presets)
    merged.presets = parentPresets
    for index = 1, #childPresets do
        merged.presets[#merged.presets + 1] = deepCopy(childPresets[index])
    end

    merged.spells = mergeOrderedRefs(parentDefinition.spells, childDefinition.spells)
    merged.stats = mergeByReference(parentDefinition.stats, childDefinition.stats, "statRef", function(entry)
        return normalizeUnitStats({ entry })[1]
    end)
    merged.resources = mergeByReference(parentDefinition.resources, childDefinition.resources, "resourceRef", function(entry)
        return normalizeUnitResources({ entry })[1]
    end)
    merged.resistances = mergeByReference(parentDefinition.resistances, childDefinition.resistances, "damageSchoolRef", function(entry)
        return normalizeUnitResistances({ entry })[1]
    end)

    merged.attributes = {}
    local attributeSeen = {}
    appendOrderedUnique(merged.attributes, attributeSeen, parentDefinition.attributes, function(value)
        return ensureString(value)
    end)
    appendOrderedUnique(merged.attributes, attributeSeen, childDefinition.attributes, function(value)
        return ensureString(value)
    end)
    merged.tags = {}
    local tagSeen = {}
    appendOrderedUnique(merged.tags, tagSeen, parentDefinition.tags, function(value)
        return ensureString(value)
    end)
    appendOrderedUnique(merged.tags, tagSeen, childDefinition.tags, function(value)
        return ensureString(value)
    end)

    return Unit:New(merged):ToTable()
end

function Unit.FromTable(data)
    return Unit:New(data)
end

Addon.Internal.Database.Classes.Unit = Unit
