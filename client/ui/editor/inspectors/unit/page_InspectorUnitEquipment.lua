local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildUnitInspectorEquipmentPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorEquipmentLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    local equipmentFields = self:GetUnitInspectorEquipmentFieldDefinitions()
    for index = 1, #equipmentFields do
        local definition = equipmentFields[index]
        root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspector" .. definition.fieldKey .. "Label", definition.label))

        local dropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorUnitInspector" .. definition.fieldKey .. "Dropdown", {
            width = self.UnitInspectorFieldWidth,
            height = 18,
            items = {
                { label = "None", value = "" },
            },
            onValueChanged = function(value)
                if self._refreshingUnitInspector then
                    return
                end

                self:CommitSelectedUnit(function(unit)
                    unit[definition.fieldKey] = value ~= "" and value or nil
                end)
            end,
        })
        self["UnitInspector" .. definition.fieldKey .. "Dropdown"] = dropdown
        root:AddChild(dropdown)
    end
end
