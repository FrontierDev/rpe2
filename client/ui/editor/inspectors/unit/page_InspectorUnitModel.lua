local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}

local MODEL_SLIDER_FIELDS = {
    { key = "cam", label = "Camera Distance", minValue = 0.1, maxValue = 5, step = 0.05, defaultValue = 1, valueFormat = "%.2f" },
    { key = "rot", label = "Rotation", minValue = -3.14, maxValue = 3.14, step = 0.05, defaultValue = 0, valueFormat = "%.2f" },
    { key = "z", label = "Vertical Offset", minValue = -2, maxValue = 2, step = 0.01, defaultValue = -0.35, valueFormat = "%.2f" },
}

function DataEditor:BuildUnitInspectorModelPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorModelLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    self.UnitInspectorModelField = UI.EditorModelField:New({
        name = "RPEDataEditorUnitInspectorModelField",
        width = self.UnitInspectorFieldWidth,
        height = 190,
        buttonText = "Select Model",
    })
    self.UnitInspectorModelField:SetParent(root:GetFrame())
    self.UnitInspectorModelField:Create()

    local selectButton = self.UnitInspectorModelField:GetButton()
    if selectButton and selectButton.SetScript then
        selectButton:SetScript("OnClick", function()
            if self._refreshingUnitInspector or not Client.OpenModelFinder then
                return
            end

            Client:OpenModelFinder(function(displayId, fileDataId)
                self:CommitSelectedUnit(function(unit)
                    unit.displayId = tonumber(displayId) or nil
                    unit.fileDataId = tonumber(fileDataId) or nil
                end)
            end, {
                filter = "",
            })
        end)
    end

    local clearButton = self.UnitInspectorModelField:GetClearButton()
    if clearButton and clearButton.SetScript then
        clearButton:SetScript("OnClick", function()
            if self._refreshingUnitInspector then
                return
            end

            self:CommitSelectedUnit(function(unit)
                unit.displayId = nil
                unit.fileDataId = nil
            end)
        end)
    end

    root:AddChild(self.UnitInspectorModelField)

    for index = 1, #MODEL_SLIDER_FIELDS do
        local field = MODEL_SLIDER_FIELDS[index]
        root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorModelLabel" .. field.key, field.label))

        local slider = UI.SliderBar:New({
            name = "RPEDataEditorUnitInspectorModelSlider" .. field.key,
            width = self.UnitInspectorFieldWidth,
            height = 18,
            minValue = field.minValue,
            maxValue = field.maxValue,
            step = field.step,
            value = field.defaultValue,
            valueFormat = field.valueFormat,
            resetValue = field.defaultValue,
            onValueChanged = function(value)
                if self._refreshingUnitInspector then
                    return
                end

                self:CommitSelectedUnit(function(unit)
                    unit[field.key] = tonumber(value) or field.defaultValue
                end)
            end,
        })
        slider:SetParent(root:GetFrame())
        slider:Create()
        root:AddChild(slider)
        self["UnitInspectorModelSlider" .. field.key] = slider
    end
end
