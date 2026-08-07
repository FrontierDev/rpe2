local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor

function DataEditor:BuildClassInspectorPage(parent)
    return self:BuildProgressionDefinitionInspectorPage(parent, "classes")
end

function DataEditor:RefreshClassInspectorPage()
    self:RefreshProgressionDefinitionInspectorPage("classes")
end
