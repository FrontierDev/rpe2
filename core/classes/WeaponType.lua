local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local WeaponType = {}
WeaponType.__index = WeaponType

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function normalizeStringList(values)
    local normalized = {}
    local seen = {}

    for index = 1, #(values or {}) do
        local entry = ensureString(values[index])
        if entry ~= "" and not seen[entry] then
            normalized[#normalized + 1] = entry
            seen[entry] = true
        end
    end

    return normalized
end

function WeaponType:New(data)
    return setmetatable({
        id = nil,
        name = "",
        icon = "",
        allowedSlotRefs = {},
    }, WeaponType):Merge(data)
end

function WeaponType:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        if key ~= "allowedSlotRefs" then
            self[key] = value
        end
    end

    self.name = ensureString(self.name)
    self.icon = ensureString(self.icon)
    self.allowedSlotRefs = normalizeStringList(data.allowedSlotRefs or self.allowedSlotRefs)

    return self
end

function WeaponType:ToTable()
    return {
        id = self.id,
        name = self.name,
        icon = self.icon,
        allowedSlotRefs = normalizeStringList(self.allowedSlotRefs),
    }
end

function WeaponType.FromTable(data)
    return WeaponType:New(data)
end

Addon.Internal.Database.Classes.WeaponType = WeaponType
