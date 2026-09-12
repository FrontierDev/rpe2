local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor

local GetEntryDefinition = DataEditor.GetEntryDefinition
local GetContentPageDefinitions = DataEditor.GetContentPageDefinitions
local BuildGuildSettingInspectorRequisitionsPage = DataEditor.BuildGuildSettingInspectorRequisitionsPage

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

-- #272: the Role inspector owns the final Shop Category visibility state, but
-- the base Character Limit commit previously did not request an immediate page
-- refresh. Wrap only that input's two commit handlers after the complete Guild
-- Setting inspector stack has loaded so 0 <-> positive transitions repaint in
-- the same interaction without changing quantity or other numeric fields.
if type(BuildGuildSettingInspectorRequisitionsPage) == "function" then
    function DataEditor:BuildGuildSettingInspectorRequisitionsPage(parent)
        local page = BuildGuildSettingInspectorRequisitionsPage(self, parent)
        local input = self.GuildSettingInspectorRequisitionLimitInput
        if input and input._guildSettingLimitRefreshWrapped ~= true and type(input.SetScript) == "function" then
            input._guildSettingLimitRefreshWrapped = true
            for _, scriptName in ipairs({ "OnEnterPressed", "OnEditFocusLost" }) do
                local original = input.scripts and input.scripts[scriptName] or nil
                if type(original) == "function" then
                    input:SetScript(scriptName, function(...)
                        original(...)
                        if type(self.RefreshGuildSettingRequisitionsPage) == "function" then
                            self:RefreshGuildSettingRequisitionsPage()
                        end
                    end)
                end
            end
        end
        return page
    end
end

return DataEditor
