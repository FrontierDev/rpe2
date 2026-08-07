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

local function ensureTable(value)
    if type(value) == "table" then
        return value
    end

    return {}
end

function Loot:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
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
    self.items = ensureTable(self.items)
    self.conditions = Condition.NormalizeList and Condition.NormalizeList(self.conditions) or {}
    self.tags = ensureTable(self.tags)

    return self
end

function Loot:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        items = self.items,
        conditions = Condition.NormalizeList and Condition.NormalizeList(self.conditions) or {},
        tags = self.tags,
    }
end

function Loot.FromTable(data)
    return Loot:New(data)
end

Addon.Internal.Database.Classes.Loot = Loot
