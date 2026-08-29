local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}

local PRESET_SECTION_MODIFIERS = "modifiers"
local PRESET_SECTION_APPEARANCES = "appearances"

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

local function getPresetAppearanceList(unit, presetIndex, create)
    if type(unit) ~= "table" then
        return nil
    end

    presetIndex = tonumber(presetIndex)
    local preset = presetIndex and unit.presets and unit.presets[presetIndex] or nil
    if type(preset) ~= "table" then
        return nil
    end

    if create and type(preset.appearances) ~= "table" then
        preset.appearances = {}
    end

    return type(preset.appearances) == "table" and preset.appearances or nil
end

-- Shared Model Finder bridge for any authored Appearance list. #85 already owns
-- normalization/list mutation; this helper only supplies the target-list resolver
-- and keeps all writes behind CommitSelectedUnit(...).
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

-- Route the Base Appearance page through the same Model Finder bridge used by
-- Presets. The #85 list/edit helpers remain the single Appearance mutation API.
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

function DataEditor:ResetUnitInspectorPresetAppearanceSelection()
    self.SelectedUnitInspectorPresetAppearanceIndex = nil
    self.UnitInspectorPresetAppearanceSelectionUnit = nil
    self.UnitInspectorPresetAppearanceSelectionPresetIndex = nil
end

local baseResetUnitInspectorPresetModifierSelections = DataEditor.ResetUnitInspectorPresetModifierSelections
function DataEditor:ResetUnitInspectorPresetModifierSelections()
    if baseResetUnitInspectorPresetModifierSelections then
        baseResetUnitInspectorPresetModifierSelections(self)
    end
    self:ResetUnitInspectorPresetAppearanceSelection()
end

function DataEditor:ValidateUnitInspectorPresetAppearanceSelection(unit, preset, presetIndex)
    local appearances = preset and preset.appearances or {}

    if self.UnitInspectorPresetAppearanceSelectionUnit ~= unit
        or self.UnitInspectorPresetAppearanceSelectionPresetIndex ~= presetIndex then
        self.UnitInspectorPresetAppearanceSelectionUnit = unit
        self.UnitInspectorPresetAppearanceSelectionPresetIndex = presetIndex
        self.SelectedUnitInspectorPresetAppearanceIndex = appearances[1] and 1 or nil
        return self.SelectedUnitInspectorPresetAppearanceIndex
    end

    local index = tonumber(self.SelectedUnitInspectorPresetAppearanceIndex)
    if index and index >= 1 and math.floor(index) == index and appearances[index] then
        return index
    end

    if #appearances == 0 then
        self.SelectedUnitInspectorPresetAppearanceIndex = nil
    elseif index and index > #appearances then
        self.SelectedUnitInspectorPresetAppearanceIndex = #appearances
    else
        self.SelectedUnitInspectorPresetAppearanceIndex = nil
    end

    return self.SelectedUnitInspectorPresetAppearanceIndex
end

function DataEditor:SetSelectedUnitInspectorPresetAppearanceIndex(index)
    local preset = self:GetSelectedUnitInspectorPreset()
    local appearances = preset and preset.appearances or {}
    index = tonumber(index)

    if not index or index < 1 or math.floor(index) ~= index or not appearances[index] then
        self.SelectedUnitInspectorPresetAppearanceIndex = nil
    else
        self.SelectedUnitInspectorPresetAppearanceIndex = index
    end
end

function DataEditor:GetSelectedUnitInspectorPresetAppearance()
    local preset = self:GetSelectedUnitInspectorPreset()
    local appearances = preset and preset.appearances or {}
    local index = tonumber(self.SelectedUnitInspectorPresetAppearanceIndex)
    if not index or not appearances[index] then
        return nil, nil
    end

    return appearances[index], index
end

function DataEditor:OpenUnitInspectorPresetAppearanceModelFinderForAdd()
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not presetIndex then
        return
    end

    return self:OpenUnitAppearanceModelFinderForTarget({
        mode = "add",
        resolveTargetList = function(unit, create)
            return getPresetAppearanceList(unit, presetIndex, create)
        end,
        isContextValid = function(editor)
            local _, currentPresetIndex = editor:GetSelectedUnitInspectorPreset()
            return currentPresetIndex == presetIndex
        end,
        onCommitted = function(editor, index)
            editor.SelectedUnitInspectorPresetAppearanceIndex = index
            editor:RefreshUnitInspectorPresetAppearanceView()
        end,
    })
end

function DataEditor:OpenUnitInspectorPresetAppearanceModelFinderForSelected()
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    local _, appearanceIndex = self:GetSelectedUnitInspectorPresetAppearance()
    if not presetIndex or not appearanceIndex then
        return
    end

    return self:OpenUnitAppearanceModelFinderForTarget({
        mode = "edit",
        selectedIndex = appearanceIndex,
        resolveTargetList = function(unit)
            return getPresetAppearanceList(unit, presetIndex, false)
        end,
        isContextValid = function(editor)
            local _, currentPresetIndex = editor:GetSelectedUnitInspectorPreset()
            local _, currentAppearanceIndex = editor:GetSelectedUnitInspectorPresetAppearance()
            return currentPresetIndex == presetIndex and currentAppearanceIndex == appearanceIndex
        end,
        onCommitted = function(editor, index)
            editor.SelectedUnitInspectorPresetAppearanceIndex = index
            editor:RefreshUnitInspectorPresetAppearanceView()
        end,
    })
end

function DataEditor:RemoveSelectedUnitInspectorPresetAppearance()
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    local _, appearanceIndex = self:GetSelectedUnitInspectorPresetAppearance()
    if not presetIndex or not appearanceIndex then
        return
    end

    local nextIndex = nil
    self:CommitSelectedUnit(function(unit)
        local appearances = getPresetAppearanceList(unit, presetIndex, false)
        if type(appearances) == "table" then
            nextIndex = self:RemoveUnitAppearance(appearances, appearanceIndex)
        end
    end)

    self.SelectedUnitInspectorPresetAppearanceIndex = nextIndex
    self:RefreshUnitInspectorPresetAppearanceView()
end

function DataEditor:MoveSelectedUnitInspectorPresetAppearance(delta)
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    local _, appearanceIndex = self:GetSelectedUnitInspectorPresetAppearance()
    if not presetIndex or not appearanceIndex then
        return
    end

    local nextIndex = appearanceIndex
    self:CommitSelectedUnit(function(unit)
        local appearances = getPresetAppearanceList(unit, presetIndex, false)
        if type(appearances) == "table" then
            nextIndex = self:MoveUnitAppearance(appearances, appearanceIndex, delta) or appearanceIndex
        end
    end)

    self.SelectedUnitInspectorPresetAppearanceIndex = nextIndex
    self:RefreshUnitInspectorPresetAppearanceView()
end

function DataEditor:CommitSelectedUnitInspectorPresetAppearanceTransform(key, value)
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    local _, appearanceIndex = self:GetSelectedUnitInspectorPresetAppearance()
    if not presetIndex or not appearanceIndex then
        return
    end

    local edited = false
    self:CommitSelectedUnit(function(unit)
        local appearances = getPresetAppearanceList(unit, presetIndex, false)
        if type(appearances) ~= "table" then
            return
        end

        edited = self:EditUnitAppearance(appearances, appearanceIndex, function(appearance)
            appearance[key] = value
        end)
    end)

    if edited then
        self:RefreshUnitInspectorPresetAppearanceView()
    end
end

function DataEditor:SetUnitInspectorPresetEditorSection(sectionKey)
    if sectionKey ~= PRESET_SECTION_APPEARANCES then
        sectionKey = PRESET_SECTION_MODIFIERS
    end

    self.ActiveUnitInspectorPresetEditorSection = sectionKey

    if self.UnitInspectorPresetModifiersView then
        if sectionKey == PRESET_SECTION_MODIFIERS then
            self.UnitInspectorPresetModifiersView:Show()
        else
            self.UnitInspectorPresetModifiersView:Hide()
        end
    end

    if self.UnitInspectorPresetAppearancesView then
        if sectionKey == PRESET_SECTION_APPEARANCES then
            self.UnitInspectorPresetAppearancesView:Show()
        else
            self.UnitInspectorPresetAppearancesView:Hide()
        end
    end

    if self.UnitInspectorPresetSectionDropdown and self.UnitInspectorPresetSectionDropdown.SetSelectedValue then
        self._refreshingUnitInspectorPresetSection = true
        self.UnitInspectorPresetSectionDropdown:SetSelectedValue(sectionKey, true)
        self._refreshingUnitInspectorPresetSection = false
    end
end

function DataEditor:RefreshUnitInspectorPresetAppearanceView()
    local _, unit = self:GetSelectedUnitAndDataset()
    local preset, presetIndex = self:GetSelectedUnitInspectorPreset()
    local hasUnit = unit ~= nil
    local hasPreset = preset ~= nil
    local appearances = preset and preset.appearances or {}

    self:ValidateUnitInspectorPresetAppearanceSelection(unit, preset, presetIndex)
    local appearance, appearanceIndex = self:GetSelectedUnitInspectorPresetAppearance()
    local hasPresetAppearance = appearance ~= nil
    local inheritsBase = hasPreset and #appearances == 0
    local previewAppearance = appearance

    if not previewAppearance and inheritsBase then
        previewAppearance = unit and unit.appearances and unit.appearances[1] or nil
    end

    self._refreshingUnitInspectorPresetAppearances = true

    if self.UnitInspectorPresetAppearancePresetDropdown then
        self.UnitInspectorPresetAppearancePresetDropdown:SetItems(self:BuildUnitInspectorPresetSelectorItems(unit))
        self.UnitInspectorPresetAppearancePresetDropdown:SetSelectedValue(presetIndex and tostring(presetIndex) or "", true)
        self:SetUnitInspectorDropdownEnabled(
            self.UnitInspectorPresetAppearancePresetDropdown,
            hasUnit and #(unit and unit.presets or {}) > 0
        )
    end

    if self.UnitInspectorPresetAppearanceStatusText then
        if not hasPreset then
            self.UnitInspectorPresetAppearanceStatusText:SetText("Select a Preset to edit appearance overrides.")
        elseif inheritsBase then
            self.UnitInspectorPresetAppearanceStatusText:SetText("Using Base Unit appearance pool")
        else
            self.UnitInspectorPresetAppearanceStatusText:SetText("Preset appearance pool overrides Base Unit appearances")
        end
    end

    if self.UnitInspectorPresetAppearancesScroll and self.UnitInspectorPresetAppearancesScroll.SetItems then
        self.UnitInspectorPresetAppearancesScroll:SetItems(self:BuildUnitAppearanceRows(appearances))
    end

    if self.UnitInspectorPresetAppearanceModelField then
        local filePath = self.Database and self.Database.ResolveModelFilePath
            and self.Database.ResolveModelFilePath(
                previewAppearance and previewAppearance.displayId or nil,
                previewAppearance and previewAppearance.fileDataId or nil
            )
            or nil
        self.UnitInspectorPresetAppearanceModelField:SetModel(
            previewAppearance and previewAppearance.displayId or nil,
            previewAppearance and previewAppearance.fileDataId or nil,
            filePath
        )
        self.UnitInspectorPresetAppearanceModelField:SetPreviewTransforms(
            previewAppearance and previewAppearance.cam or APPEARANCE_DEFAULT_CAM,
            previewAppearance and previewAppearance.rot or APPEARANCE_DEFAULT_ROT,
            previewAppearance and previewAppearance.z or APPEARANCE_DEFAULT_Z
        )
        self.UnitInspectorPresetAppearanceModelField:SetEnabled(hasPresetAppearance)
    end

    for index = 1, #APPEARANCE_SLIDER_FIELDS do
        local field = APPEARANCE_SLIDER_FIELDS[index]
        local slider = self["UnitInspectorPresetAppearanceSlider" .. field.key]
        if slider then
            slider:SetValue(previewAppearance and previewAppearance[field.key] or field.defaultValue, true)
            self:SetUnitInspectorSliderEnabled(slider, hasPresetAppearance)
        end
    end

    setButtonEnabled(
        self.UnitInspectorPresetAddAppearanceButton,
        hasPreset and type(Client.OpenModelFinder) == "function"
    )
    setButtonEnabled(self.UnitInspectorPresetRemoveAppearanceButton, hasPresetAppearance)
    setButtonEnabled(self.UnitInspectorPresetMoveAppearanceUpButton, hasPresetAppearance and appearanceIndex > 1)
    setButtonEnabled(
        self.UnitInspectorPresetMoveAppearanceDownButton,
        hasPresetAppearance and appearanceIndex < #appearances
    )

    self._refreshingUnitInspectorPresetAppearances = false
end

function DataEditor:BuildUnitInspectorPresetAppearanceView(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorPresetAppearancesLayout", {
        spacing = 5,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    local presetRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorPresetAppearancePresetRow", {
        width = 132,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(presetRow)

    presetRow:AddChild(UI.CreateText(presetRow:GetFrame(), "RPEDataEditorUnitInspectorPresetAppearancePresetLabel", "Preset", {
        width = 34,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    }))

    self.UnitInspectorPresetAppearancePresetDropdown = UI.CreateDropdown(
        presetRow:GetFrame(),
        "RPEDataEditorUnitInspectorPresetAppearancePresetDropdown",
        {
            width = 94,
            height = 18,
            items = {},
            onValueChanged = function(value)
                if self._refreshingUnitInspector
                    or self._refreshingUnitInspectorPresets
                    or self._refreshingUnitInspectorPresetAppearances then
                    return
                end

                self:SetSelectedUnitInspectorPresetIndex(tonumber(value))
                self:RefreshUnitInspectorPresetsPage()
            end,
        }
    )
    presetRow:AddChild(self.UnitInspectorPresetAppearancePresetDropdown)

    self.UnitInspectorPresetAppearanceStatusText = UI.CreateText(
        root:GetFrame(),
        "RPEDataEditorUnitInspectorPresetAppearanceStatusText",
        "Select a Preset to edit appearance overrides.",
        {
            width = self.UnitInspectorFieldWidth,
            height = 16,
            justifyH = "LEFT",
            textColor = UI.ResolveColor(nil, "text.secondary"),
        }
    )
    root:AddChild(self.UnitInspectorPresetAppearanceStatusText)

    self.UnitInspectorPresetAppearancesPanel = UI.CreatePanel(
        root:GetFrame(),
        "RPEDataEditorUnitInspectorPresetAppearancesPanel",
        {
            width = self.UnitInspectorFieldWidth,
            height = 74,
            contentInset = 1,
            showBorder = true,
        }
    )
    root:AddChild(self.UnitInspectorPresetAppearancesPanel)

    self.UnitInspectorPresetAppearancesScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitInspectorPresetAppearancesScroll",
        width = self.UnitInspectorFieldWidth,
        height = 72,
        visibleRows = 4,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.UnitInspectorPresetAppearancesScroll:SetParent(self.UnitInspectorPresetAppearancesPanel:GetContentFrame())
    self.UnitInspectorPresetAppearancesScroll:SetRowRenderer(function(row, item, itemIndex)
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
            local selected = item
                and tonumber(item.rowIndex) == tonumber(self.SelectedUnitInspectorPresetAppearanceIndex)
            local color = UI.ResolveColor(nil, selected and "list.rowHover" or "list.rowBackground")
            row.background:SetColorTexture(
                color.r or 0.08,
                color.g or 0.09,
                color.b or 0.11,
                color.a or 0.85
            )
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(_, button, rowData)
                if button ~= "LeftButton" then
                    return
                end
                self:SetSelectedUnitInspectorPresetAppearanceIndex(rowData and rowData.rowIndex or nil)
                self:RefreshUnitInspectorPresetAppearanceView()
            end)
        end
    end)
    self.UnitInspectorPresetAppearancesScroll:Create()
    UI.Utils.AnchorFill(
        self.UnitInspectorPresetAppearancesScroll,
        self.UnitInspectorPresetAppearancesPanel:GetContentFrame(),
        0,
        0,
        0,
        0
    )

    self.UnitInspectorPresetAppearanceToolbar = UI.CreateLayout(
        UI.HorizontalLayoutGroup,
        root:GetFrame(),
        "RPEDataEditorUnitInspectorPresetAppearanceToolbar",
        {
            width = self.UnitInspectorFieldWidth,
            height = 18,
            spacing = 4,
            fitChildrenWidth = false,
            fitChildrenHeight = false,
        }
    )
    root:AddChild(self.UnitInspectorPresetAppearanceToolbar)

    self.UnitInspectorPresetAddAppearanceButton = UI.CreateButton(
        self.UnitInspectorPresetAppearanceToolbar:GetFrame(),
        "RPEDataEditorUnitInspectorPresetAddAppearanceButton",
        "Add",
        56,
        function()
            if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetAppearances then
                return
            end
            self:OpenUnitInspectorPresetAppearanceModelFinderForAdd()
        end,
        { height = 18, fontSize = 7 }
    )
    self.UnitInspectorPresetAppearanceToolbar:AddChild(self.UnitInspectorPresetAddAppearanceButton)

    self.UnitInspectorPresetRemoveAppearanceButton = UI.CreateButton(
        self.UnitInspectorPresetAppearanceToolbar:GetFrame(),
        "RPEDataEditorUnitInspectorPresetRemoveAppearanceButton",
        "Remove",
        56,
        function()
            if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetAppearances then
                return
            end
            self:RemoveSelectedUnitInspectorPresetAppearance()
        end,
        { height = 18, fontSize = 7 }
    )
    self.UnitInspectorPresetAppearanceToolbar:AddChild(self.UnitInspectorPresetRemoveAppearanceButton)

    self.UnitInspectorPresetMoveAppearanceUpButton = UI.CreateButton(
        self.UnitInspectorPresetAppearanceToolbar:GetFrame(),
        "RPEDataEditorUnitInspectorPresetMoveAppearanceUpButton",
        "Up",
        56,
        function()
            if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetAppearances then
                return
            end
            self:MoveSelectedUnitInspectorPresetAppearance(-1)
        end,
        { height = 18, fontSize = 7 }
    )
    self.UnitInspectorPresetAppearanceToolbar:AddChild(self.UnitInspectorPresetMoveAppearanceUpButton)

    self.UnitInspectorPresetMoveAppearanceDownButton = UI.CreateButton(
        self.UnitInspectorPresetAppearanceToolbar:GetFrame(),
        "RPEDataEditorUnitInspectorPresetMoveAppearanceDownButton",
        "Down",
        56,
        function()
            if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetAppearances then
                return
            end
            self:MoveSelectedUnitInspectorPresetAppearance(1)
        end,
        { height = 18, fontSize = 7 }
    )
    self.UnitInspectorPresetAppearanceToolbar:AddChild(self.UnitInspectorPresetMoveAppearanceDownButton)

    self.UnitInspectorPresetAppearanceModelField = UI.EditorModelField:New({
        name = "RPEDataEditorUnitInspectorPresetAppearanceModelField",
        width = self.UnitInspectorFieldWidth,
        height = 150,
        previewHeight = 82,
        buttonText = "Select Model",
    })
    self.UnitInspectorPresetAppearanceModelField:SetParent(root:GetFrame())
    self.UnitInspectorPresetAppearanceModelField:Create()

    local selectButton = self.UnitInspectorPresetAppearanceModelField:GetButton()
    if selectButton and selectButton.SetScript then
        selectButton:SetScript("OnClick", function()
            if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetAppearances then
                return
            end
            self:OpenUnitInspectorPresetAppearanceModelFinderForSelected()
        end)
    end

    local clearButton = self.UnitInspectorPresetAppearanceModelField:GetClearButton()
    local clearFrame = clearButton and clearButton.GetFrame and clearButton:GetFrame() or nil
    if clearFrame and clearFrame.Hide then
        clearFrame:Hide()
    end

    root:AddChild(self.UnitInspectorPresetAppearanceModelField)

    for index = 1, #APPEARANCE_SLIDER_FIELDS do
        local field = APPEARANCE_SLIDER_FIELDS[index]
        root:AddChild(
            self:BuildUnitInspectorLabel(
                root:GetFrame(),
                "RPEDataEditorUnitInspectorPresetAppearanceLabel" .. field.key,
                field.label
            )
        )

        local slider = UI.SliderBar:New({
            name = "RPEDataEditorUnitInspectorPresetAppearanceSlider" .. field.key,
            width = self.UnitInspectorFieldWidth,
            height = 18,
            minValue = field.minValue,
            maxValue = field.maxValue,
            step = field.step,
            value = field.defaultValue,
            valueFormat = field.valueFormat,
            resetValue = field.defaultValue,
            onValueChanged = function(value)
                if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetAppearances then
                    return
                end
                self:CommitSelectedUnitInspectorPresetAppearanceTransform(
                    field.key,
                    tonumber(value) or field.defaultValue
                )
            end,
        })
        slider:SetParent(root:GetFrame())
        slider:Create()
        root:AddChild(slider)
        self["UnitInspectorPresetAppearanceSlider" .. field.key] = slider
    end

    self:RefreshUnitInspectorPresetAppearanceView()
end

local baseRefreshUnitInspectorPresetsPage = DataEditor.RefreshUnitInspectorPresetsPage
function DataEditor:RefreshUnitInspectorPresetsPage()
    if baseRefreshUnitInspectorPresetsPage then
        baseRefreshUnitInspectorPresetsPage(self)
    end
    self:RefreshUnitInspectorPresetAppearanceView()
end

local baseBuildUnitInspectorPresetsPage = DataEditor.BuildUnitInspectorPresetsPage
function DataEditor:BuildUnitInspectorPresetsPage(page)
    if self.UnitInspectorPresetModifiersView or self.UnitInspectorPresetAppearancesView then
        self:RefreshUnitInspectorPresetsPage()
        self:SetUnitInspectorPresetEditorSection(self.ActiveUnitInspectorPresetEditorSection)
        return
    end

    self.UnitInspectorPresetModifiersView = CreateFrame(
        "Frame",
        "RPEDataEditorUnitInspectorPresetModifiersView",
        page
    )
    self.UnitInspectorPresetModifiersView:SetAllPoints(page)

    if baseBuildUnitInspectorPresetsPage then
        baseBuildUnitInspectorPresetsPage(self, self.UnitInspectorPresetModifiersView)
    end

    self.UnitInspectorPresetAppearancesView = CreateFrame(
        "Frame",
        "RPEDataEditorUnitInspectorPresetAppearancesView",
        page
    )
    self.UnitInspectorPresetAppearancesView:SetAllPoints(page)
    self:BuildUnitInspectorPresetAppearanceView(self.UnitInspectorPresetAppearancesView)

    self.UnitInspectorPresetSectionDropdown = UI.CreateDropdown(
        page,
        "RPEDataEditorUnitInspectorPresetSectionDropdown",
        {
            width = 102,
            height = 18,
            items = {
                { label = "Modifiers", value = PRESET_SECTION_MODIFIERS },
                { label = "Appearance", value = PRESET_SECTION_APPEARANCES },
            },
            selectedValue = self.ActiveUnitInspectorPresetEditorSection or PRESET_SECTION_MODIFIERS,
            onValueChanged = function(value)
                if self._refreshingUnitInspectorPresetSection then
                    return
                end
                self:SetUnitInspectorPresetEditorSection(value)
            end,
        }
    )
    self.UnitInspectorPresetSectionDropdown:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)

    self:SetUnitInspectorPresetEditorSection(
        self.ActiveUnitInspectorPresetEditorSection or PRESET_SECTION_MODIFIERS
    )
    self:RefreshUnitInspectorPresetsPage()
end
