local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Skill = {}
Skill.__index = Skill

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

local function normalizeBoolean(value)
    return value == true
end

local function normalizeSkillType(value)
    local skillType = string.lower(ensureString(value))
    if skillType == "weapon" or skillType == "crafting" or skillType == "language" then
        return skillType
    end

    return "noncombat"
end

local function normalizeLearnMode(value)
    local learnMode = string.lower(ensureString(value))
    if learnMode == "always_available" or learnMode == "trainer" or learnMode == "book" or learnMode == "unavailable" then
        return learnMode
    end

    return "always_available"
end

function Skill:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = "",
        skillType = "noncombat",
        weaponTypeRef = nil,
        learnMode = "always_available",
        rollable = false,
        derivedStatRef = nil,
        derivedMultiplier = 1,
    }, Skill):Merge(data)
end

function Skill:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        if key ~= "derivedStatRef" then
            self[key] = value
        end
    end

    self.name = ensureString(self.name)
    self.description = ensureString(self.description)
    self.icon = ensureString(self.icon)
    self.skillType = normalizeSkillType(self.skillType)
    self.weaponTypeRef = normalizeRef(self.weaponTypeRef)
    self.learnMode = normalizeLearnMode(self.learnMode)
    self.rollable = normalizeBoolean(self.rollable)
    self.derivedStatRef = normalizeRef(data.derivedStatRef or self.derivedStatRef)
    self.derivedMultiplier = tonumber(self.derivedMultiplier) or 1

    if self.skillType ~= "weapon" then
        self.weaponTypeRef = nil
    end

    if self.skillType ~= "noncombat" then
        self.rollable = false
        self.derivedStatRef = nil
        self.derivedMultiplier = 1
    end

    return self
end

function Skill:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        skillType = normalizeSkillType(self.skillType),
        weaponTypeRef = self.skillType == "weapon" and normalizeRef(self.weaponTypeRef) or nil,
        learnMode = normalizeLearnMode(self.learnMode),
        rollable = self.rollable == true,
        derivedStatRef = normalizeRef(self.derivedStatRef),
        derivedMultiplier = tonumber(self.derivedMultiplier) or 1,
    }
end

function Skill.FromTable(data)
    return Skill:New(data)
end

Addon.Internal.Database.Classes.Skill = Skill
