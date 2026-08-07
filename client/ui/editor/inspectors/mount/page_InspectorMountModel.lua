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

function DataEditor:BuildMountInspectorModelPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorMountInspectorModelLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    self.MountInspectorModelField = UI.EditorModelField:New({
        name = "RPEDataEditorMountInspectorModelField",
        width = self.MountInspectorFieldWidth,
        height = 190,
        buttonText = "Select Model",
    })
    self.MountInspectorModelField:SetParent(root:GetFrame())
    self.MountInspectorModelField:Create()

    local selectButton = self.MountInspectorModelField:GetButton()
    if selectButton and selectButton.SetScript then
        selectButton:SetScript("OnClick", function()
            if self._refreshingMountInspector or not Client.OpenModelFinder then
                return
            end

            Client:OpenModelFinder(function(displayId, fileDataId)
                self:CommitSelectedMount(function(mount)
                    mount.displayId = tonumber(displayId) or nil
                    mount.fileDataId = tonumber(fileDataId) or nil
                end)
            end, {
                filter = "",
            })
        end)
    end

    local clearButton = self.MountInspectorModelField:GetClearButton()
    if clearButton and clearButton.SetScript then
        clearButton:SetScript("OnClick", function()
            if self._refreshingMountInspector then
                return
            end

            self:CommitSelectedMount(function(mount)
                mount.displayId = nil
                mount.fileDataId = nil
            end)
        end)
    end

    root:AddChild(self.MountInspectorModelField)

    for index = 1, #MODEL_SLIDER_FIELDS do
        local field = MODEL_SLIDER_FIELDS[index]
        root:AddChild(self:BuildMountInspectorLabel(root:GetFrame(), "RPEDataEditorMountInspectorModelLabel" .. field.key, field.label))

        local slider = UI.SliderBar:New({
            name = "RPEDataEditorMountInspectorModelSlider" .. field.key,
            width = self.MountInspectorFieldWidth,
            height = 18,
            minValue = field.minValue,
            maxValue = field.maxValue,
            step = field.step,
            value = field.defaultValue,
            valueFormat = field.valueFormat,
            resetValue = field.defaultValue,
            onValueChanged = function(value)
                if self._refreshingMountInspector then
                    return
                end

                self:CommitSelectedMount(function(mount)
                    mount[field.key] = tonumber(value) or field.defaultValue
                end)
            end,
        })
        slider:SetParent(root:GetFrame())
        slider:Create()
        root:AddChild(slider)
        self["MountInspectorModelSlider" .. field.key] = slider
    end
end

