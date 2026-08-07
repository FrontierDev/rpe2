local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Currency = {}
Currency.__index = Currency

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function normalizeMax(value)
    local numeric = math.floor(tonumber(value) or 0)
    if numeric < 0 then
        return 0
    end

    return numeric
end

local function normalizeTagList(value)
    if type(value) ~= "table" then
        return {}
    end

    local tags = {}
    for index = 1, #value do
        local tag = ensureString(value[index])
        if tag ~= "" then
            tags[#tags + 1] = tag
        end
    end

    return tags
end

function Currency:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = "",
        category = "",
        max = 0,
        tags = {},
    }, Currency):Merge(data)
end

function Currency:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    self.name = ensureString(self.name)
    self.description = ensureString(self.description)
    self.icon = ensureString(self.icon)
    self.category = ensureString(self.category)
    self.max = normalizeMax(self.max)
    self.tags = normalizeTagList(self.tags)

    return self
end

function Currency:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        category = self.category,
        max = self.max,
        tags = self.tags,
    }
end

function Currency.FromTable(data)
    return Currency:New(data)
end

Addon.Internal.Database.Classes.Currency = Currency
