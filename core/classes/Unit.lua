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

local function ensureTable(value)
    if type(value) == "table" then
        return value
    end

    return {}
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
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
            normalized[#normalized + 1] = {
                statRef = statRef,
                value = tonumber(entry.value) or 0,
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
            normalized[#normalized + 1] = {
                resourceRef = resourceRef,
                value = tonumber(entry.value) or 0,
                perPlayer = tonumber(entry.perPlayer) or 0,
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

function Unit:New(data)
    local instance = setmetatable({
        id = nil,
        name = "",
        creatureType = "humanoid",
        creatureSize = "medium",
        challengeLevel = "normal",
        displayId = nil,
        fileDataId = nil,
        cam = 1,
        rot = 0,
        z = -0.35,
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
    }, Unit)

    return instance:Merge(data)
end

function Unit:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    self.id = self.id ~= nil and tostring(self.id) or nil
    self.name = ensureString(self.name)
    self.creatureType = ensureString(self.creatureType ~= "" and self.creatureType or "humanoid")
    self.creatureSize = ensureString(self.creatureSize ~= "" and self.creatureSize or "medium")
    self.challengeLevel = Unit.NormalizeChallengeLevel(self.challengeLevel)
    self.displayId = tonumber(self.displayId) or nil
    self.fileDataId = tonumber(self.fileDataId) or nil
    self.cam = tonumber(self.cam) or 1
    self.rot = tonumber(self.rot) or 0
    self.z = tonumber(self.z) or -0.35
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
    return {
        id = self.id,
        name = self.name,
        creatureType = self.creatureType,
        creatureSize = self.creatureSize,
        challengeLevel = Unit.NormalizeChallengeLevel(self.challengeLevel),
        displayId = self.displayId,
        fileDataId = self.fileDataId,
        cam = self.cam,
        rot = self.rot,
        z = self.z,
        mainHandWeapon = self.mainHandWeapon,
        offHandWeapon = self.offHandWeapon,
        rangedWeapon = self.rangedWeapon,
        shield = self.shield,
        spells = normalizeList(self.spells),
        stats = normalizeUnitStats(self.stats),
        resources = normalizeUnitResources(self.resources),
        resistances = normalizeUnitResistances(self.resistances),
        attributes = normalizeList(self.attributes),
        tags = normalizeList(self.tags),
    }
end

function Unit.FromTable(data)
    return Unit:New(data)
end

Addon.Internal.Database.Classes.Unit = Unit
