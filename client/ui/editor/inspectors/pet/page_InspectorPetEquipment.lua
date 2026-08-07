local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildPetInspectorEquipmentPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorPetInspectorEquipmentLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildPetInspectorLabel(root:GetFrame(), "RPEDataEditorPetInspectorEquipmentLabel", "Equipment Slots"))
    self.PetInspectorEquipmentSlotsDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorPetInspectorEquipmentSlotsDropdown", {
        width = self.PetInspectorFieldWidth,
        height = 18,
        items = self:BuildPetInspectorReferencesAcrossDatasets("itemSlots"),
        multiSelect = true,
        showSelectionActions = false,
        onValueChanged = function(values)
            if self._refreshingPetInspector then
                return
            end

            self:CommitSelectedPet(function(pet)
                pet.equipmentSlotRefs = values or {}
            end)
        end,
    })
    root:AddChild(self.PetInspectorEquipmentSlotsDropdown)

    self.PetInspectorEquipmentHintText = UI.CreateText(root:GetFrame(), "RPEDataEditorPetInspectorEquipmentHintText", "Only the selected slot refs appear on the profile equipment page for this pet. Pet equipment uses regular item slots and regular items.", {
        width = self.PetInspectorFieldWidth,
        height = 36,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.PetInspectorEquipmentHintText)
end
