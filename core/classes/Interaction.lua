local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Interaction = {}
Interaction.__index = Interaction

function Interaction:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        prompts = {},
        outcomes = {},
        tags = {},
    }, Interaction):Merge(data)
end

function Interaction:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    return self
end

function Interaction:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        prompts = self.prompts,
        outcomes = self.outcomes,
        tags = self.tags,
    }
end

function Interaction.FromTable(data)
    return Interaction:New(data)
end

Addon.Internal.Database.Classes.Interaction = Interaction
