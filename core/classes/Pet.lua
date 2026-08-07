local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Pet = {}
Pet.__index = Pet

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

local function normalizeRefList(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local ref = normalizeRef(values[index])
        if ref then
            normalized[#normalized + 1] = ref
        end
    end

    return normalized
end

function Pet:New(data)
    return setmetatable({
        id = nil,
        name = "",
        unitRef = nil,
        spells = {},
        equipmentSlotRefs = {},
    }, Pet):Merge(data)
end

function Pet:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    self.id = self.id ~= nil and tostring(self.id) or nil
    self.name = ensureString(self.name)
    self.unitRef = normalizeRef(self.unitRef)
    self.spells = normalizeRefList(self.spells)
    self.equipmentSlotRefs = normalizeRefList(self.equipmentSlotRefs)

    return self
end

function Pet:ToTable()
    return {
        id = self.id,
        name = self.name,
        unitRef = self.unitRef,
        spells = normalizeRefList(self.spells),
        equipmentSlotRefs = normalizeRefList(self.equipmentSlotRefs),
    }
end

function Pet.FromTable(data)
    return Pet:New(data)
end

Addon.Internal.Database.Classes.Pet = Pet
