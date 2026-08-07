local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildPetInspectorGeneralPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorPetInspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildPetInspectorLabel(root:GetFrame(), "RPEDataEditorPetInspectorNameLabel", "Name"))
    self.PetInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorPetInspectorNameInput", {
        width = self.PetInspectorFieldWidth,
        height = self.PetInspectorControlHeight,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.PetInspectorNameInput:SetScript("OnEnterPressed", function()
        if self._refreshingPetInspector then
            return
        end

        self:CommitSelectedPet(function(pet)
            pet.name = self.PetInspectorNameInput:GetText()
        end)
    end)
    self.PetInspectorNameInput:SetScript("OnEditFocusLost", function()
        if self._refreshingPetInspector then
            return
        end

        self:CommitSelectedPet(function(pet)
            pet.name = self.PetInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.PetInspectorNameInput)

    root:AddChild(self:BuildPetInspectorLabel(root:GetFrame(), "RPEDataEditorPetInspectorUnitLabel", "Unit"))
    self.PetInspectorUnitDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorPetInspectorUnitDropdown", {
        width = self.PetInspectorFieldWidth,
        height = 18,
        items = self:BuildPetInspectorReferencesAcrossDatasets("units"),
        onValueChanged = function(value)
            if self._refreshingPetInspector then
                return
            end

            self:CommitSelectedPet(function(pet)
                pet.unitRef = value ~= "" and value or nil
            end)
        end,
    })
    root:AddChild(self.PetInspectorUnitDropdown)

    self.PetInspectorUnitHintText = UI.CreateText(root:GetFrame(), "RPEDataEditorPetInspectorUnitHintText", "Pets wrap a Unit definition. The selected unit provides the pet's base runtime data; the pet wrapper supplies slot layout and spell override.", {
        width = self.PetInspectorFieldWidth,
        height = 36,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.PetInspectorUnitHintText)

    self.PetInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorPetInspectorIdText", "ID: -", {
        width = self.PetInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.PetInspectorIdText)
end
