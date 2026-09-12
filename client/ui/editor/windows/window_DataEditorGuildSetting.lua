local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor

local GetEntryDefinition = DataEditor.GetEntryDefinition
local GetContentPageDefinitions = DataEditor.GetContentPageDefinitions

local GUILD_SETTING_ENTRY_DEFINITION = {
    className = "GuildSetting",
    singular = "Guild Setting",
    buttonLabel = "New Guild Setting",
    emptyName = "Unnamed Guild Setting",
    assignsId = true,
}

function DataEditor:GetEntryDefinition(collectionKey)
    if collectionKey == "guildSettings" then
        return GUILD_SETTING_ENTRY_DEFINITION
    end

    return GetEntryDefinition(self, collectionKey)
end

function DataEditor:GetContentPageDefinitions()
    local definitions = GetContentPageDefinitions(self)
    for index = 1, #(definitions or {}) do
        local definition = definitions[index]
        if definition and definition.key == "guildSettings" then
            definition.label = "Guild Settings"
            break
        end
    end
    return definitions
end

return DataEditor
