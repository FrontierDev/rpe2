local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Recipe = {}
Recipe.__index = Recipe

function Recipe:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        reagents = {},
        results = {},
        tags = {},
    }, Recipe):Merge(data)
end

function Recipe:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    return self
end

function Recipe:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        reagents = self.reagents,
        results = self.results,
        tags = self.tags,
    }
end

function Recipe.FromTable(data)
    return Recipe:New(data)
end

Addon.Internal.Database.Classes.Recipe = Recipe
