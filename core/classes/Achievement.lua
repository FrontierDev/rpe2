local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Achievement = {}
Achievement.__index = Achievement

function Achievement:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = nil,
        criteria = {},
        rewards = {},
        tags = {},
    }, Achievement):Merge(data)
end

function Achievement:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    return self
end

function Achievement:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        criteria = self.criteria,
        rewards = self.rewards,
        tags = self.tags,
    }
end

function Achievement.FromTable(data)
    return Achievement:New(data)
end

Addon.Internal.Database.Classes.Achievement = Achievement
