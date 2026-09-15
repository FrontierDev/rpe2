local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Class = {}
Class.__index = Class

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function normalizeRef(value)
    local ref = ensureString(value)
    if ref == "" then
        return nil
    end

    return ref
end

local function normalizeProgressions(values, refKey)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local ref = type(entry) == "table" and normalizeRef(entry[refKey]) or nil
        if ref then
            normalized[#normalized + 1] = {
                [refKey] = ref,
                initialValue = tonumber(entry.initialValue) or 0,
                perLevelValue = tonumber(entry.perLevelValue) or 0,
            }
        end
    end

    return normalized
end

local function normalizeTraitRefs(values)
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
    local normalized, seen = {}, {}
    for index = 1, #(values or {}) do
        local value = ensureString(values[index])
        if value ~= "" and not seen[value] then
            seen[value] = true
            normalized[#normalized + 1] = value
        end
    end
    return normalized
end

local function normalizeSkillBonuses(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local skillRef = type(entry) == "table" and normalizeRef(entry.skillRef) or nil
        if skillRef then
            normalized[#normalized + 1] = {
                skillRef = skillRef,
                value = tonumber(entry.value) or 0,
            }
        end
    end

    return normalized
end

function Class:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = "",
        statProgressions = {},
        resourceProgressions = {},
        skillBonuses = {},
        -- Ownership, not trait flags, determines class trait semantics.
        passiveTraitRefs = {},
        talentTraitRefs = {},
        armorWeights = {},
        weaponTypeRefs = {},
    }, Class):Merge(data)
end

function Class:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        if key ~= "statProgressions" and key ~= "resourceProgressions" and key ~= "skillBonuses" and key ~= "traitRefs" and key ~= "passiveTraitRefs" and key ~= "talentTraitRefs" and key ~= "armorWeights" and key ~= "weaponTypeRefs" then
            self[key] = value
        end
    end

    self.statProgressions = normalizeProgressions(data.statProgressions or self.statProgressions, "statRef")
    self.resourceProgressions = normalizeProgressions(data.resourceProgressions or self.resourceProgressions, "resourceRef")
    self.skillBonuses = normalizeSkillBonuses(data.skillBonuses or self.skillBonuses)
    -- traitRefs is deliberately not retained. Database migration splits legacy
    -- records before this model is serialized.
    self.passiveTraitRefs = normalizeTraitRefs(data.passiveTraitRefs or self.passiveTraitRefs)
    self.talentTraitRefs = normalizeTraitRefs(data.talentTraitRefs or self.talentTraitRefs)
    local passiveLookup = {}
    for index = 1, #self.passiveTraitRefs do
        passiveLookup[self.passiveTraitRefs[index]] = true
    end
    local distinctTalents = {}
    for index = 1, #self.talentTraitRefs do
        if passiveLookup[self.talentTraitRefs[index]] ~= true then
            distinctTalents[#distinctTalents + 1] = self.talentTraitRefs[index]
        end
    end
    self.talentTraitRefs = distinctTalents
    self.armorWeights = normalizeStringList(data.armorWeights or self.armorWeights)
    self.weaponTypeRefs = normalizeStringList(data.weaponTypeRefs or self.weaponTypeRefs)
    return self
end

function Class:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        statProgressions = self.statProgressions,
        resourceProgressions = self.resourceProgressions,
        skillBonuses = self.skillBonuses,
        passiveTraitRefs = self.passiveTraitRefs,
        talentTraitRefs = self.talentTraitRefs,
        armorWeights = self.armorWeights,
        weaponTypeRefs = self.weaponTypeRefs,
    }
end

function Class.FromTable(data)
    return Class:New(data)
end

Addon.Internal.Database.Classes.Class = Class
