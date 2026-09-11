local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Loot = {}
Loot.__index = Loot
local Condition = Addon.Internal.Database.Classes.Condition or {}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
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

local function ensureTableCopy(value)
    if type(value) ~= "table" then
        return {}
    end

    return deepCopy(value)
end

local function finiteNumberOrOriginal(value, fallback)
    if value == nil then
        return fallback
    end

    local numericValue = tonumber(value)
    if numericValue ~= nil
        and numericValue == numericValue
        and numericValue ~= math.huge
        and numericValue ~= -math.huge
    then
        return numericValue
    end

    -- Keep invalid authored values intact so the editor/runtime validator can
    -- report them instead of silently changing table probability semantics.
    return value
end

local function normalizePositiveIntegerOrOriginal(value, fallback)
    if value == nil then
        return fallback
    end

    local numericValue = tonumber(value)
    if numericValue ~= nil
        and numericValue == numericValue
        and numericValue ~= math.huge
        and numericValue ~= -math.huge
        and numericValue > 0
        and numericValue == math.floor(numericValue)
    then
        return numericValue
    end

    return value
end

local function normalizeEntry(entry)
    if type(entry) ~= "table" then
        return deepCopy(entry)
    end

    local normalized = deepCopy(entry)
    normalized.id = ensureString(entry.id)
    normalized.type = string.lower(ensureString(entry.type))
    normalized.ref = ensureString(entry.ref)
    normalized.weight = finiteNumberOrOriginal(entry.weight, 1)
    normalized.minQuantity = normalizePositiveIntegerOrOriginal(entry.minQuantity, 1)
    normalized.maxQuantity = normalizePositiveIntegerOrOriginal(entry.maxQuantity, normalized.minQuantity)
    return normalized
end

local function normalizeEntries(entries)
    if type(entries) ~= "table" then
        return {}
    end

    -- Preserve unknown/sparse imported keys rather than collapsing malformed data
    -- that a later editor/runtime validator needs to diagnose explicitly.
    local normalized = deepCopy(entries)
    for key, entry in pairs(entries) do
        if type(key) == "number" then
            normalized[key] = normalizeEntry(entry)
        end
    end
    return normalized
end

function Loot:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        drawCount = 1,
        entries = {},

        -- Legacy field retained losslessly. No executable legacy shape exists in
        -- current source, so schema 23 does not guess a conversion into entries.
        items = {},

        conditions = {},
        tags = {},
    }, Loot):Merge(data)
end

function Loot:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    self.name = ensureString(self.name)
    self.description = ensureString(self.description)
    self.drawCount = normalizePositiveIntegerOrOriginal(self.drawCount, 1)
    self.entries = normalizeEntries(self.entries)
    self.items = ensureTableCopy(self.items)
    self.conditions = Condition.NormalizeList and Condition.NormalizeList(self.conditions) or {}
    self.tags = ensureTableCopy(self.tags)

    return self
end

function Loot:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        drawCount = self.drawCount,
        entries = normalizeEntries(self.entries),
        items = ensureTableCopy(self.items),
        conditions = Condition.NormalizeList and Condition.NormalizeList(self.conditions) or {},
        tags = ensureTableCopy(self.tags),
    }
end

function Loot.FromTable(data)
    return Loot:New(data)
end

Addon.Internal.Database.Classes.Loot = Loot
