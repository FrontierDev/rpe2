local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Race = {}
Race.__index = Race

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

function Race:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = "",
        statProgressions = {},
        resourceProgressions = {},
        skillBonuses = {},
        traitRefs = {},
    }, Race):Merge(data)
end

function Race:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        if key ~= "statProgressions" and key ~= "resourceProgressions" and key ~= "skillBonuses" and key ~= "traitRefs" then
            self[key] = value
        end
    end

    self.statProgressions = normalizeProgressions(data.statProgressions or self.statProgressions, "statRef")
    self.resourceProgressions = normalizeProgressions(data.resourceProgressions or self.resourceProgressions, "resourceRef")
    self.skillBonuses = normalizeSkillBonuses(data.skillBonuses or self.skillBonuses)
    self.traitRefs = normalizeTraitRefs(data.traitRefs or self.traitRefs)
    return self
end

function Race:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        statProgressions = self.statProgressions,
        resourceProgressions = self.resourceProgressions,
        skillBonuses = self.skillBonuses,
        traitRefs = self.traitRefs,
    }
end

function Race.FromTable(data)
    return Race:New(data)
end

Addon.Internal.Database.Classes.Race = Race
