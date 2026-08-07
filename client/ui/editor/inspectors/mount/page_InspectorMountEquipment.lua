local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildMountInspectorEquipmentPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorMountInspectorEquipmentLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildMountInspectorLabel(root:GetFrame(), "RPEDataEditorMountInspectorEquipmentLabel", "Equipment Slots"))
    self.MountInspectorEquipmentSlotsDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorMountInspectorEquipmentSlotsDropdown", {
        width = self.MountInspectorFieldWidth,
        height = 18,
        items = self:BuildMountInspectorReferencesAcrossDatasets("itemSlots"),
        multiSelect = true,
        showSelectionActions = false,
        onValueChanged = function(values)
            if self._refreshingMountInspector then
                return
            end

            self:CommitSelectedMount(function(mount)
                mount.equipmentSlotRefs = values or {}
            end)
        end,
    })
    root:AddChild(self.MountInspectorEquipmentSlotsDropdown)

    self.MountInspectorEquipmentHintText = UI.CreateText(root:GetFrame(), "RPEDataEditorMountInspectorEquipmentHintText", "Mount equipment uses regular item slots. Items become mount-only by targeting the selected slot refs.", {
        width = self.MountInspectorFieldWidth,
        height = 36,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.MountInspectorEquipmentHintText)
end

