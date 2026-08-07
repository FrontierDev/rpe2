local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Mount = {}
Mount.__index = Mount

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

local function normalizeStatEntries(values)
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

function Mount:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = "",
        spells = {},
        stats = {},
    }, Mount):Merge(data)
end

function Mount:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    self.id = self.id ~= nil and tostring(self.id) or nil
    self.name = ensureString(self.name)
    self.description = ensureString(self.description)
    self.icon = ensureString(self.icon)
    self.spells = normalizeRefList(self.spells)
    self.stats = normalizeStatEntries(self.stats)

    self.displayId = nil
    self.fileDataId = nil
    self.cam = nil
    self.rot = nil
    self.z = nil
    self.equipmentSlotRefs = nil

    return self
end

function Mount:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        spells = normalizeRefList(self.spells),
        stats = normalizeStatEntries(self.stats),
    }
end

function Mount.FromTable(data)
    return Mount:New(data)
end

Addon.Internal.Database.Classes.Mount = Mount
