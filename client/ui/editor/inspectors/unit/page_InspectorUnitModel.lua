local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}
local UnitClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Unit or nil

local APPEARANCE_DEFAULT_CAM = 1
local APPEARANCE_DEFAULT_ROT = 0
local APPEARANCE_DEFAULT_Z = -0.35
local APPEARANCE_EDITOR_MODEL_HEIGHT = 78
local APPEARANCE_EDITOR_PREVIEW_HEIGHT = 54
local APPEARANCE_EDITOR_SPACING = 3
local APPEARANCE_TRANSFORM_LABEL_WIDTH = 78
local APPEARANCE_TRANSFORM_SLIDER_WIDTH = 154

local APPEARANCE_SLIDER_FIELDS = {
    { key = "cam", label = "Camera Distance", minValue = 0.1, maxValue = 5, step = 0.05, defaultValue = APPEARANCE_DEFAULT_CAM, valueFormat = "%.2f" },
    { key = "rot", label = "Rotation", minValue = -3.14, maxValue = 3.14, step = 0.05, defaultValue = APPEARANCE_DEFAULT_ROT, valueFormat = "%.2f" },
    { key = "z", label = "Vertical Offset", minValue = -2, maxValue = 2, step = 0.01, defaultValue = APPEARANCE_DEFAULT_Z, valueFormat = "%.2f" },
}

local function setButtonEnabled(button, enabled)
    if button and button.SetEnabled then
        button:SetEnabled(enabled == true)
    end
end

local function getModelLabel(filePath, appearance)
    if type(filePath) == "string" and filePath ~= "" then
        local normalizedPath = filePath:gsub("\\", "/")
        return normalizedPath:match("([^/]+)$") or normalizedPath
    end

    if appearance and appearance.displayId ~= nil then
        return "Display " .. tostring(appearance.displayId)
    end

    if appearance and appearance.fileDataId ~= nil then
        return "File " .. tostring(appearance.fileDataId)
    end

    return "Unknown"
end

local function normalizeAppearance(value)
    if UnitClass and type(UnitClass.NormalizeAppearance) == "function" then
        return UnitClass.NormalizeAppearance(value)
    end

    return nil
end

local function hideElementFrame(element)
    local frame = element and element.GetFrame and element:GetFrame() or nil
    if frame and frame.Hide then
        frame:Hide()
    end
end

function DataEditor:GetUnitAppearanceSliderFields()
    return APPEARANCE_SLIDER_FIELDS
end

function DataEditor:BuildUnitAppearanceSelectorItems(appearances)
    local items = {}

    for index = 1, #(appearances or {}) do
        local appearance = appearances[index]
        local filePath = self.Database and self.Database.ResolveModelFilePath
            and self.Database.ResolveModelFilePath(appearance and appearance.displayId or nil, appearance and appearance.fileDataId or nil)
            or nil
        items[#items + 1] = {
            label = ("%d - %s"):format(index, getModelLabel(filePath, appearance)),
            value = tostring(index),
        }
    end

    return items
end

function DataEditor:AddUnitAppearance(targetList, appearance)
    if type(targetList) ~= "table" then
        return nil
    end

    local normalized = normalizeAppearance(appearance)
    if not normalized then
        return nil
    end

    targetList[#targetList + 1] = normalized
    return #targetList
end

function DataEditor:RemoveUnitAppearance(targetList, index)
    if type(targetList) ~= "table" then
        return nil
    end

    index = tonumber(index)
    if not index or index < 1 or math.floor(index) ~= index or not targetList[index] then
        return nil
    end

    table.remove(targetList, index)
    if #targetList == 0 then
        return nil
    end

    return math.min(index, #targetList)
end

function DataEditor:MoveUnitAppearance(targetList, index, delta)
    if type(targetList) ~= "table" then
        return nil
    end

    index = tonumber(index)
    delta = tonumber(delta)
    if not index or not delta or math.floor(index) ~= index or math.floor(delta) ~= delta or not targetList[index] then
        return nil
    end

    local destination = index + delta
    if destination < 1 or destination > #targetList then
        return index
    end

    targetList[index], targetList[destination] = targetList[destination], targetList[index]
    return destination
end

function DataEditor:EditUnitAppearance(targetList, index, mutate)
    if type(targetList) ~= "table" or type(mutate) ~= "function" then
        return false
    end

    index = tonumber(index)
    if not index or index < 1 or math.floor(index) ~= index or type(targetList[index]) ~= "table" then
        return false
    end

    local draft = self.DeepCopyValue and self:DeepCopyValue(targetList[index]) or nil
    if type(draft) ~= "table" then
        return false
    end

    mutate(draft)
    local normalized = normalizeAppearance(draft)
    if not normalized then
        return false
    end

    targetList[index] = normalized
    return true
end

function DataEditor:SetSelectedUnitInspectorAppearanceIndex(index)
    local _, unit = self:GetSelectedUnitAndDataset()
    local appearances = unit and unit.appearances or {}
    index = tonumber(index)

    if not index or index < 1 or math.floor(index) ~= index or not appearances[index] then
        self.SelectedUnitInspectorAppearanceIndex = nil
    else
        self.SelectedUnitInspectorAppearanceIndex = index
    end
end

function DataEditor:ValidateUnitInspectorAppearanceSelection(unit)
    local appearances = unit and unit.appearances or {}

    if self.UnitInspectorAppearanceSelectionUnit ~= unit then
        self.UnitInspectorAppearanceSelectionUnit = unit
        self.SelectedUnitInspectorAppearanceIndex = #appearances > 0 and 1 or nil
        return self.SelectedUnitInspectorAppearanceIndex
    end

    local index = tonumber(self.SelectedUnitInspectorAppearanceIndex)
    if index and index >= 1 and math.floor(index) == index and appearances[index] then
        return index
    end

    if #appearances == 0 then
        self.SelectedUnitInspectorAppearanceIndex = nil
    elseif index and index > #appearances then
        self.SelectedUnitInspectorAppearanceIndex = #appearances
    else
        self.SelectedUnitInspectorAppearanceIndex = nil
    end

    return self.SelectedUnitInspectorAppearanceIndex
end

function DataEditor:GetSelectedUnitInspectorAppearance()
    local _, unit = self:GetSelectedUnitAndDataset()
    local appearances = unit and unit.appearances or {}
    local index = tonumber(self.SelectedUnitInspectorAppearanceIndex)
    if not index or not appearances[index] then
        return nil, nil
    end

    return appearances[index], index
end

function DataEditor:CreateCompactUnitAppearanceModelField(parent, name, onSelect)
    local modelField = UI.EditorModelField:New({
        name = name,
        width = self.UnitInspectorFieldWidth,
        height = APPEARANCE_EDITOR_MODEL_HEIGHT,
        previewHeight = APPEARANCE_EDITOR_PREVIEW_HEIGHT,
        spacing = APPEARANCE_EDITOR_SPACING,
        buttonText = "Select Model",
    })
    modelField:SetParent(parent)
    modelField:Create()

    local selectButton = modelField:GetButton()
    if selectButton and selectButton.SetScript then
        selectButton:SetScript("OnClick", onSelect)
    end

    hideElementFrame(modelField:GetClearButton())
    hideElementFrame(modelField.displayIdElement)
    hideElementFrame(modelField.fileDataIdElement)
    hideElementFrame(modelField.pathElement)

    return modelField
end

function DataEditor:CreateUnitAppearanceTransformRow(parent, name, field, onValueChanged)
    local row = UI.CreateLayout(UI.HorizontalLayoutGroup, parent, name, {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })

    row:AddChild(UI.CreateText(row:GetFrame(), name .. "Label", field.label, {
        width = APPEARANCE_TRANSFORM_LABEL_WIDTH,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    }))

    local slider = UI.SliderBar:New({
        name = name .. "Slider",
        width = APPEARANCE_TRANSFORM_SLIDER_WIDTH,
        height = 18,
        minValue = field.minValue,
        maxValue = field.maxValue,
        step = field.step,
        value = field.defaultValue,
        valueFormat = field.valueFormat,
        resetValue = field.defaultValue,
        onValueChanged = onValueChanged,
    })
    slider:SetParent(row:GetFrame())
    slider:Create()
    row:AddChild(slider)

    return row, slider
end

-- Shared Model Finder bridge for Base and Preset Appearance arrays. All writes
-- remain behind CommitSelectedUnit(...), and stale finder contexts are ignored.
function DataEditor:OpenUnitAppearanceModelFinderForTarget(options)
    options = type(options) == "table" and options or {}
    if type(Client.OpenModelFinder) ~= "function" or type(options.resolveTargetList) ~= "function" then
        return
    end

    local dataset, unit = self:GetSelectedUnitAndDataset()
    if not dataset or not unit then
        return
    end

    local mode = options.mode == "edit" and "edit" or "add"
    local selectedIndex = tonumber(options.selectedIndex)
    if mode == "edit" and (not selectedIndex or selectedIndex < 1 or math.floor(selectedIndex) ~= selectedIndex) then
        return
    end

    local datasetAtOpen = dataset
    local unitAtOpen = unit

    Client:OpenModelFinder(function(displayId, fileDataId)
        local currentDataset, currentUnit = self:GetSelectedUnitAndDataset()
        if currentDataset ~= datasetAtOpen or currentUnit ~= unitAtOpen then
            return
        end
        if type(options.isContextValid) == "function" and not options.isContextValid(self, currentUnit) then
            return
        end

        local committedIndex = nil
        self:CommitSelectedUnit(function(targetUnit)
            local targetList = options.resolveTargetList(targetUnit, mode == "add")
            if type(targetList) ~= "table" then
                return
            end

            if mode == "add" then
                committedIndex = self:AddUnitAppearance(targetList, {
                    displayId = displayId,
                    fileDataId = fileDataId,
                    cam = APPEARANCE_DEFAULT_CAM,
                    rot = APPEARANCE_DEFAULT_ROT,
                    z = APPEARANCE_DEFAULT_Z,
                })
            else
                local edited = self:EditUnitAppearance(targetList, selectedIndex, function(appearance)
                    appearance.displayId = displayId
                    appearance.fileDataId = fileDataId
                end)
                if edited then
                    committedIndex = selectedIndex
                end
            end
        end)

        if committedIndex and type(options.onCommitted) == "function" then
            options.onCommitted(self, committedIndex)
        end
    end, {
        filter = tostring(options.filter or ""),
    })
end

function DataEditor:OpenUnitInspectorAppearanceModelFinderForAdd()
    return self:OpenUnitAppearanceModelFinderForTarget({
        mode = "add",
        resolveTargetList = function(unit, create)
            if create and type(unit.appearances) ~= "table" then
                unit.appearances = {}
            end
            return unit.appearances
        end,
        onCommitted = function(editor, index)
            editor.SelectedUnitInspectorAppearanceIndex = index
            editor:RefreshUnitInspectorAppearancesTable()
        end,
    })
end

function DataEditor:OpenUnitInspectorAppearanceModelFinderForSelected()
    local _, selectedIndex = self:GetSelectedUnitInspectorAppearance()
    if not selectedIndex then
        return
    end

    return self:OpenUnitAppearanceModelFinderForTarget({
        mode = "edit",
        selectedIndex = selectedIndex,
        resolveTargetList = function(unit)
            return unit.appearances
        end,
        isContextValid = function(editor)
            local _, currentIndex = editor:GetSelectedUnitInspectorAppearance()
            return currentIndex == selectedIndex
        end,
        onCommitted = function(editor, index)
            editor.SelectedUnitInspectorAppearanceIndex = index
            editor:RefreshUnitInspectorAppearancesTable()
        end,
    })
end

function DataEditor:RefreshUnitInspectorAppearanceEditor()
    local _, unit = self:GetSelectedUnitAndDataset()
    local appearance, index = self:GetSelectedUnitInspectorAppearance()
    local hasUnit = unit ~= nil
    local hasAppearance = appearance ~= nil

    if self.UnitInspectorAppearanceModelField then
        local filePath = self.Database and self.Database.ResolveModelFilePath
            and self.Database.ResolveModelFilePath(appearance and appearance.displayId or nil, appearance and appearance.fileDataId or nil)
            or nil
        self.UnitInspectorAppearanceModelField:SetModel(
            appearance and appearance.displayId or nil,
            appearance and appearance.fileDataId or nil,
            filePath
        )
        self.UnitInspectorAppearanceModelField:SetPreviewTransforms(
            appearance and appearance.cam or APPEARANCE_DEFAULT_CAM,
            appearance and appearance.rot or APPEARANCE_DEFAULT_ROT,
            appearance and appearance.z or APPEARANCE_DEFAULT_Z
        )
        self.UnitInspectorAppearanceModelField:SetEnabled(hasAppearance)
    end

    for fieldIndex = 1, #APPEARANCE_SLIDER_FIELDS do
        local field = APPEARANCE_SLIDER_FIELDS[fieldIndex]
        local slider = self["UnitInspectorAppearanceSlider" .. field.key]
        if slider then
            slider:SetValue(appearance and appearance[field.key] or field.defaultValue, true)
            self:SetUnitInspectorSliderEnabled(slider, hasAppearance)
        end
    end

    setButtonEnabled(self.UnitInspectorAddAppearanceButton, hasUnit and type(Client.OpenModelFinder) == "function")
    setButtonEnabled(self.UnitInspectorRemoveAppearanceButton, hasAppearance)
    setButtonEnabled(self.UnitInspectorMoveAppearanceUpButton, hasAppearance and index > 1)
    setButtonEnabled(self.UnitInspectorMoveAppearanceDownButton, hasAppearance and index < #(unit and unit.appearances or {}))
end

function DataEditor:RefreshUnitInspectorAppearancesTable()
    local _, unit = self:GetSelectedUnitAndDataset()
    local appearances = unit and unit.appearances or {}
    local selectedIndex = self:ValidateUnitInspectorAppearanceSelection(unit)

    if self.UnitInspectorAppearanceDropdown then
        self.UnitInspectorAppearanceDropdown:SetItems(self:BuildUnitAppearanceSelectorItems(appearances))
        self.UnitInspectorAppearanceDropdown:SetSelectedValue(selectedIndex and tostring(selectedIndex) or "", true)
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorAppearanceDropdown, unit ~= nil and #appearances > 0)
    end

    self:RefreshUnitInspectorAppearanceEditor()
end

function DataEditor:RemoveSelectedUnitInspectorAppearance()
    local _, selectedIndex = self:GetSelectedUnitInspectorAppearance()
    if not selectedIndex then
        return
    end

    local nextIndex = nil
    self:CommitSelectedUnit(function(unit)
        nextIndex = self:RemoveUnitAppearance(unit.appearances, selectedIndex)
    end)
    self.SelectedUnitInspectorAppearanceIndex = nextIndex
    self:RefreshUnitInspectorAppearancesTable()
end

function DataEditor:MoveSelectedUnitInspectorAppearance(delta)
    local _, selectedIndex = self:GetSelectedUnitInspectorAppearance()
    if not selectedIndex then
        return
    end

    local nextIndex = selectedIndex
    self:CommitSelectedUnit(function(unit)
        nextIndex = self:MoveUnitAppearance(unit.appearances, selectedIndex, delta) or selectedIndex
    end)
    self.SelectedUnitInspectorAppearanceIndex = nextIndex
    self:RefreshUnitInspectorAppearancesTable()
end

function DataEditor:BuildUnitInspectorAppearancesPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorAppearancesLayout", {
        spacing = APPEARANCE_EDITOR_SPACING,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorAppearancesLabel", "Appearance"))

    self.UnitInspectorAppearanceDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorUnitInspectorAppearanceDropdown", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        items = {},
        onValueChanged = function(value)
            if self._refreshingUnitInspector then
                return
            end
            self:SetSelectedUnitInspectorAppearanceIndex(tonumber(value))
            self:RefreshUnitInspectorAppearancesTable()
        end,
    })
    root:AddChild(self.UnitInspectorAppearanceDropdown)

    self.UnitInspectorAppearanceToolbar = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorAppearanceToolbar", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.UnitInspectorAppearanceToolbar)

    self.UnitInspectorAddAppearanceButton = UI.CreateButton(self.UnitInspectorAppearanceToolbar:GetFrame(), "RPEDataEditorUnitInspectorAddAppearanceButton", "Add", 56, function()
        if self._refreshingUnitInspector then
            return
        end
        self:OpenUnitInspectorAppearanceModelFinderForAdd()
    end, { height = 18, fontSize = 7 })
    self.UnitInspectorAppearanceToolbar:AddChild(self.UnitInspectorAddAppearanceButton)

    self.UnitInspectorRemoveAppearanceButton = UI.CreateButton(self.UnitInspectorAppearanceToolbar:GetFrame(), "RPEDataEditorUnitInspectorRemoveAppearanceButton", "Remove", 56, function()
        if self._refreshingUnitInspector then
            return
        end
        self:RemoveSelectedUnitInspectorAppearance()
    end, { height = 18, fontSize = 7 })
    self.UnitInspectorAppearanceToolbar:AddChild(self.UnitInspectorRemoveAppearanceButton)

    self.UnitInspectorMoveAppearanceUpButton = UI.CreateButton(self.UnitInspectorAppearanceToolbar:GetFrame(), "RPEDataEditorUnitInspectorMoveAppearanceUpButton", "Up", 56, function()
        if self._refreshingUnitInspector then
            return
        end
        self:MoveSelectedUnitInspectorAppearance(-1)
    end, { height = 18, fontSize = 7 })
    self.UnitInspectorAppearanceToolbar:AddChild(self.UnitInspectorMoveAppearanceUpButton)

    self.UnitInspectorMoveAppearanceDownButton = UI.CreateButton(self.UnitInspectorAppearanceToolbar:GetFrame(), "RPEDataEditorUnitInspectorMoveAppearanceDownButton", "Down", 56, function()
        if self._refreshingUnitInspector then
            return
        end
        self:MoveSelectedUnitInspectorAppearance(1)
    end, { height = 18, fontSize = 7 })
    self.UnitInspectorAppearanceToolbar:AddChild(self.UnitInspectorMoveAppearanceDownButton)

    self.UnitInspectorAppearanceModelField = self:CreateCompactUnitAppearanceModelField(
        root:GetFrame(),
        "RPEDataEditorUnitInspectorAppearanceModelField",
        function()
            if self._refreshingUnitInspector then
                return
            end
            self:OpenUnitInspectorAppearanceModelFinderForSelected()
        end
    )
    root:AddChild(self.UnitInspectorAppearanceModelField)

    for index = 1, #APPEARANCE_SLIDER_FIELDS do
        local field = APPEARANCE_SLIDER_FIELDS[index]
        local row, slider = self:CreateUnitAppearanceTransformRow(
            root:GetFrame(),
            "RPEDataEditorUnitInspectorAppearanceTransform" .. field.key,
            field,
            function(value)
                if self._refreshingUnitInspector then
                    return
                end

                local _, selectedIndex = self:GetSelectedUnitInspectorAppearance()
                if not selectedIndex then
                    return
                end

                local edited = false
                self:CommitSelectedUnit(function(unit)
                    edited = self:EditUnitAppearance(unit.appearances, selectedIndex, function(appearance)
                        appearance[field.key] = tonumber(value) or field.defaultValue
                    end)
                end)

                if edited then
                    self:RefreshUnitInspectorAppearanceEditor()
                end
            end
        )
        root:AddChild(row)
        self["UnitInspectorAppearanceSlider" .. field.key] = slider
    end

    self:RefreshUnitInspectorAppearancesTable()
end
