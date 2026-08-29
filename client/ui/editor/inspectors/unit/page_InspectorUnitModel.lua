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

local function getModelIdentityLabel(appearance)
    if type(appearance) ~= "table" then
        return "-"
    end

    local parts = {}
    if appearance.displayId ~= nil then
        parts[#parts + 1] = "D:" .. tostring(appearance.displayId)
    end
    if appearance.fileDataId ~= nil then
        parts[#parts + 1] = "F:" .. tostring(appearance.fileDataId)
    end

    return #parts > 0 and table.concat(parts, " ") or "-"
end

local function normalizeAppearance(value)
    if UnitClass and type(UnitClass.NormalizeAppearance) == "function" then
        return UnitClass.NormalizeAppearance(value)
    end

    return nil
end

-- Reusable appearance-list helpers. These deliberately operate on a supplied
-- target list so the Preset editor can reuse the same authoring operations.
function DataEditor:BuildUnitAppearanceRows(appearances)
    local rows = {}

    for index = 1, #(appearances or {}) do
        local appearance = appearances[index]
        local filePath = self.Database and self.Database.ResolveModelFilePath
            and self.Database.ResolveModelFilePath(appearance and appearance.displayId or nil, appearance and appearance.fileDataId or nil)
            or nil

        rows[#rows + 1] = {
            rowIndex = index,
            indexText = tostring(index),
            modelText = getModelLabel(filePath, appearance),
            identityText = getModelIdentityLabel(appearance),
        }
    end

    return rows
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
    self:ValidateUnitInspectorAppearanceSelection(unit)

    if self.UnitInspectorAppearancesScroll and self.UnitInspectorAppearancesScroll.SetItems then
        self.UnitInspectorAppearancesScroll:SetItems(self:BuildUnitAppearanceRows(unit and unit.appearances or {}))
    end

    self:RefreshUnitInspectorAppearanceEditor()
end

function DataEditor:OpenUnitInspectorAppearanceModelFinderForAdd()
    local dataset, unit = self:GetSelectedUnitAndDataset()
    if not dataset or not unit or type(Client.OpenModelFinder) ~= "function" then
        return
    end

    local datasetAtOpen = dataset
    local unitAtOpen = unit
    Client:OpenModelFinder(function(displayId, fileDataId)
        local currentDataset, currentUnit = self:GetSelectedUnitAndDataset()
        if currentDataset ~= datasetAtOpen or currentUnit ~= unitAtOpen then
            return
        end

        local newIndex = nil
        self:CommitSelectedUnit(function(targetUnit)
            targetUnit.appearances = type(targetUnit.appearances) == "table" and targetUnit.appearances or {}
            newIndex = self:AddUnitAppearance(targetUnit.appearances, {
                displayId = displayId,
                fileDataId = fileDataId,
                cam = APPEARANCE_DEFAULT_CAM,
                rot = APPEARANCE_DEFAULT_ROT,
                z = APPEARANCE_DEFAULT_Z,
            })
        end)

        if newIndex then
            self.SelectedUnitInspectorAppearanceIndex = newIndex
            self:RefreshUnitInspectorAppearancesTable()
        end
    end, {
        filter = "",
    })
end

function DataEditor:OpenUnitInspectorAppearanceModelFinderForSelected()
    local dataset, unit = self:GetSelectedUnitAndDataset()
    local _, selectedIndex = self:GetSelectedUnitInspectorAppearance()
    if not dataset or not unit or not selectedIndex or type(Client.OpenModelFinder) ~= "function" then
        return
    end

    local datasetAtOpen = dataset
    local unitAtOpen = unit
    local indexAtOpen = selectedIndex
    Client:OpenModelFinder(function(displayId, fileDataId)
        local currentDataset, currentUnit = self:GetSelectedUnitAndDataset()
        if currentDataset ~= datasetAtOpen or currentUnit ~= unitAtOpen then
            return
        end

        local edited = false
        self:CommitSelectedUnit(function(targetUnit)
            edited = self:EditUnitAppearance(targetUnit.appearances, indexAtOpen, function(appearance)
                appearance.displayId = displayId
                appearance.fileDataId = fileDataId
            end)
        end)

        if edited then
            self.SelectedUnitInspectorAppearanceIndex = indexAtOpen
            self:RefreshUnitInspectorAppearancesTable()
        end
    end, {
        filter = "",
    })
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
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorAppearancesLabel", "Appearances"))

    self.UnitInspectorAppearancesPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorUnitInspectorAppearancesPanel", {
        width = self.UnitInspectorFieldWidth,
        height = 92,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.UnitInspectorAppearancesPanel)

    self.UnitInspectorAppearancesScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitInspectorAppearancesScroll",
        width = self.UnitInspectorFieldWidth,
        height = 90,
        visibleRows = 5,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.UnitInspectorAppearancesScroll:SetParent(self.UnitInspectorAppearancesPanel:GetContentFrame())
    self.UnitInspectorAppearancesScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "indexText", width = 22, justifyH = "RIGHT" },
                { key = "modelText", width = 122, justifyH = "LEFT" },
                { key = "identityText", width = 88, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.background and row.background.SetColorTexture then
            local selected = item and tonumber(item.rowIndex) == tonumber(self.SelectedUnitInspectorAppearanceIndex)
            local color = UI.ResolveColor(nil, selected and "list.rowHover" or "list.rowBackground")
            row.background:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(_, button, rowData)
                if button ~= "LeftButton" then
                    return
                end

                self:SetSelectedUnitInspectorAppearanceIndex(rowData and rowData.rowIndex or nil)
                self:RefreshUnitInspectorAppearancesTable()
            end)
        end
    end)
    self.UnitInspectorAppearancesScroll:Create()
    UI.Utils.AnchorFill(self.UnitInspectorAppearancesScroll, self.UnitInspectorAppearancesPanel:GetContentFrame(), 0, 0, 0, 0)

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

    self.UnitInspectorAppearanceModelField = UI.EditorModelField:New({
        name = "RPEDataEditorUnitInspectorAppearanceModelField",
        width = self.UnitInspectorFieldWidth,
        height = 154,
        previewHeight = 86,
        buttonText = "Select Model",
    })
    self.UnitInspectorAppearanceModelField:SetParent(root:GetFrame())
    self.UnitInspectorAppearanceModelField:Create()

    local selectButton = self.UnitInspectorAppearanceModelField:GetButton()
    if selectButton and selectButton.SetScript then
        selectButton:SetScript("OnClick", function()
            if self._refreshingUnitInspector then
                return
            end
            self:OpenUnitInspectorAppearanceModelFinderForSelected()
        end)
    end

    local clearButton = self.UnitInspectorAppearanceModelField:GetClearButton()
    local clearFrame = clearButton and clearButton.GetFrame and clearButton:GetFrame() or nil
    if clearFrame and clearFrame.Hide then
        clearFrame:Hide()
    end

    root:AddChild(self.UnitInspectorAppearanceModelField)

    for index = 1, #APPEARANCE_SLIDER_FIELDS do
        local field = APPEARANCE_SLIDER_FIELDS[index]
        root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorAppearanceLabel" .. field.key, field.label))

        local slider = UI.SliderBar:New({
            name = "RPEDataEditorUnitInspectorAppearanceSlider" .. field.key,
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
            end,
        })
        slider:SetParent(root:GetFrame())
        slider:Create()
        root:AddChild(slider)
        self["UnitInspectorAppearanceSlider" .. field.key] = slider
    end

    self:RefreshUnitInspectorAppearanceEditor()
end
