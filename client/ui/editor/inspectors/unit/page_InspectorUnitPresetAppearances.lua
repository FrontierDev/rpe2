local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}

local APPEARANCE_DEFAULT_CAM = 1
local APPEARANCE_DEFAULT_ROT = 0
local APPEARANCE_DEFAULT_Z = -0.35
local APPEARANCE_EDITOR_SPACING = 3

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

function DataEditor:RefreshUnitInspectorPresetAppearanceView()
    local _, unit = self:GetSelectedUnitAndDataset()
    local preset, presetIndex = self:GetSelectedUnitInspectorPreset()
    local hasPreset = preset ~= nil
    local appearances = preset and preset.appearances or {}

    local selectedIndex = self:ValidateUnitInspectorPresetAppearanceSelection(unit, preset, presetIndex)
    local appearance, appearanceIndex = self:GetSelectedUnitInspectorPresetAppearance()
    local hasPresetAppearance = appearance ~= nil
    local inheritsBase = hasPreset and #appearances == 0
    local previewAppearance = appearance

    if not previewAppearance and inheritsBase then
        previewAppearance = unit and unit.appearances and unit.appearances[1] or nil
    end

    self._refreshingUnitInspectorPresetAppearances = true

    if self.UnitInspectorPresetAppearanceStatusText then
        if not hasPreset then
            self.UnitInspectorPresetAppearanceStatusText:SetText("Select a Preset to edit appearance overrides.")
        elseif inheritsBase then
            self.UnitInspectorPresetAppearanceStatusText:SetText("Using Base Unit appearance pool")
        else
            self.UnitInspectorPresetAppearanceStatusText:SetText("Preset appearance pool overrides Base Unit appearances")
        end
    end

    if self.UnitInspectorPresetAppearanceDropdown then
        self.UnitInspectorPresetAppearanceDropdown:SetItems(self:BuildUnitAppearanceSelectorItems(appearances))
        self.UnitInspectorPresetAppearanceDropdown:SetSelectedValue(selectedIndex and tostring(selectedIndex) or "", true)
        self:SetUnitInspectorDropdownEnabled(
            self.UnitInspectorPresetAppearanceDropdown,
            hasPreset and #appearances > 0
        )
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

    for index = 1, #(self.GetUnitAppearanceSliderFields and self:GetUnitAppearanceSliderFields() or {}) do
        local field = self:GetUnitAppearanceSliderFields()[index]
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
        spacing = APPEARANCE_EDITOR_SPACING,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    self.UnitInspectorPresetAppearanceStatusText = UI.CreateText(
        root:GetFrame(),
        "RPEDataEditorUnitInspectorPresetAppearanceStatusText",
        "Select a Preset to edit appearance overrides.",
        {
            width = self.UnitInspectorFieldWidth,
            height = 14,
            justifyH = "LEFT",
            textColor = UI.ResolveColor(nil, "text.secondary"),
        }
    )
    root:AddChild(self.UnitInspectorPresetAppearanceStatusText)

    self.UnitInspectorPresetAppearanceDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorUnitInspectorPresetAppearanceDropdown", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        items = {},
        onValueChanged = function(value)
            if self._refreshingUnitInspector
                or self._refreshingUnitInspectorPresets
                or self._refreshingUnitInspectorPresetAppearances then
                return
            end
            self:SetSelectedUnitInspectorPresetAppearanceIndex(tonumber(value))
            self:RefreshUnitInspectorPresetAppearanceView()
        end,
    })
    root:AddChild(self.UnitInspectorPresetAppearanceDropdown)

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

    self.UnitInspectorPresetAppearanceModelField = self:CreateCompactUnitAppearanceModelField(
        root:GetFrame(),
        "RPEDataEditorUnitInspectorPresetAppearanceModelField",
        function()
            if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetAppearances then
                return
            end
            self:OpenUnitInspectorPresetAppearanceModelFinderForSelected()
        end
    )
    root:AddChild(self.UnitInspectorPresetAppearanceModelField)

    local sliderFields = self:GetUnitAppearanceSliderFields()
    for index = 1, #sliderFields do
        local field = sliderFields[index]
        local row, slider = self:CreateUnitAppearanceTransformRow(
            root:GetFrame(),
            "RPEDataEditorUnitInspectorPresetAppearanceTransform" .. field.key,
            field,
            function(value)
                if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetAppearances then
                    return
                end
                self:CommitSelectedUnitInspectorPresetAppearanceTransform(
                    field.key,
                    tonumber(value) or field.defaultValue
                )
            end
        )
        root:AddChild(row)
        self["UnitInspectorPresetAppearanceSlider" .. field.key] = slider
    end

    self:RefreshUnitInspectorPresetAppearanceView()
end
local SECTION_MODIFIERS = "modifiers"
local SECTION_APPEARANCE = "appearances"
local SECTION_EQUIPMENT = "equipment"
local SECTION_SPELLS = "spells"
local PRESET_HEADER_HEIGHT = 64
local PRESET_BODY_OFFSET = 68

local SECTION_ITEMS = {
    { label = "Modifiers", value = SECTION_MODIFIERS },
    { label = "Appearance", value = SECTION_APPEARANCE },
    { label = "Equipment", value = SECTION_EQUIPMENT },
    { label = "Spells", value = SECTION_SPELLS },
}

local function buildModifierHeader(parent, name, referenceLabel)
    local row = UI.CreateLayout(UI.HorizontalLayoutGroup, parent, name, {
        width = 236,
        height = 12,
        spacing = 0,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })

    row:AddChild(UI.CreateText(row:GetFrame(), name .. "Reference", referenceLabel, {
        width = 132,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    row:AddChild(UI.CreateText(row:GetFrame(), name .. "Percent", "%", {
        width = 42,
        height = 12,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    row:AddChild(UI.CreateText(row:GetFrame(), name .. "Flat", "Flat", {
        width = 42,
        height = 12,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    }))

    return row
end

local function isValidSection(sectionKey)
    return sectionKey == SECTION_MODIFIERS
        or sectionKey == SECTION_APPEARANCE
        or sectionKey == SECTION_EQUIPMENT
        or sectionKey == SECTION_SPELLS
end

function DataEditor:SetUnitInspectorPresetEditorSection(sectionKey)
    if not isValidSection(sectionKey) then
        sectionKey = SECTION_MODIFIERS
    end

    self.ActiveUnitInspectorPresetEditorSection = sectionKey

    local views = {
        [SECTION_MODIFIERS] = self.UnitInspectorPresetModifiersView,
        [SECTION_APPEARANCE] = self.UnitInspectorPresetAppearancesView,
        [SECTION_EQUIPMENT] = self.UnitInspectorPresetEquipmentView,
        [SECTION_SPELLS] = self.UnitInspectorPresetSpellsView,
    }
    for key, view in pairs(views) do
        if view then
            if key == sectionKey then
                view:Show()
            else
                view:Hide()
            end
        end
    end

    if self.UnitInspectorPresetSectionDropdown and self.UnitInspectorPresetSectionDropdown.SetSelectedValue then
        self._refreshingUnitInspectorPresetSection = true
        self.UnitInspectorPresetSectionDropdown:SetSelectedValue(sectionKey, true)
        self._refreshingUnitInspectorPresetSection = false
    end
end

function DataEditor:RefreshUnitInspectorPresetsPage()
    local _, unit = self:GetSelectedUnitAndDataset()
    local hasUnit = unit ~= nil
    self:ValidateUnitInspectorPresetSelection(unit)
    local preset, presetIndex = self:GetSelectedUnitInspectorPreset()
    local hasPreset = preset ~= nil

    self._refreshingUnitInspectorPresets = true

    if self.UnitInspectorPresetDropdown then
        self.UnitInspectorPresetDropdown:SetItems(self:BuildUnitInspectorPresetSelectorItems(unit))
        self.UnitInspectorPresetDropdown:SetSelectedValue(presetIndex and tostring(presetIndex) or "", true)
        self:SetUnitInspectorDropdownEnabled(
            self.UnitInspectorPresetDropdown,
            hasUnit and (#(unit and unit.presets or {}) > 0 or tostring(unit.extendsUnitRef or "") ~= "")
        )
    end

    if self.UnitInspectorPresetSectionDropdown then
        self.UnitInspectorPresetSectionDropdown:SetItems(SECTION_ITEMS)
    end

    setButtonEnabled(self.UnitInspectorPresetAddButton, hasUnit)
    setButtonEnabled(self.UnitInspectorPresetDuplicateButton, hasPreset)
    setButtonEnabled(self.UnitInspectorPresetDeleteButton, hasPreset)
    setButtonEnabled(self.UnitInspectorPresetMoveUpButton, hasPreset and presetIndex > 1)
    setButtonEnabled(self.UnitInspectorPresetMoveDownButton, hasPreset and presetIndex < #(unit and unit.presets or {}))

    if self.UnitInspectorPresetNameInput then
        self.UnitInspectorPresetNameEditingIndex = presetIndex
        self.UnitInspectorPresetNameInput:SetText(preset and preset.name or "")
        self:SetUnitInspectorTextElementEnabled(self.UnitInspectorPresetNameInput, hasPreset)
    end

    if self.UnitInspectorPresetStatDropdown then
        self.UnitInspectorPresetStatDropdown:SetItems(self:BuildUnitInspectorReferencesAcrossDatasets("stats"))
    end
    if self.UnitInspectorPresetResourceDropdown then
        self.UnitInspectorPresetResourceDropdown:SetItems(self:BuildUnitInspectorReferencesAcrossDatasets("resources"))
    end

    self:RefreshUnitInspectorPresetModifierTables()
    self._refreshingUnitInspectorPresets = false

    if self.RefreshUnitInspectorPresetAppearanceView then
        self:RefreshUnitInspectorPresetAppearanceView()
    end
    if self.RefreshUnitInspectorPresetEquipmentView then
        self:RefreshUnitInspectorPresetEquipmentView()
    end
    if self.RefreshUnitInspectorPresetSpellsView then
        self:RefreshUnitInspectorPresetSpellsView()
    end

    self:SetUnitInspectorPresetEditorSection(self.ActiveUnitInspectorPresetEditorSection or SECTION_MODIFIERS)
end

function DataEditor:BuildUnitInspectorPresetModifiersView(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorPresetModifiersLayout95", {
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetStatLabel95", "Stat Modifiers"))
    root:AddChild(buildModifierHeader(root:GetFrame(), "RPEDataEditorUnitInspectorPresetStatHeader95", "Stat"))

    local statPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetStatPanel95", {
        width = self.UnitInspectorFieldWidth,
        height = 38,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(statPanel)

    self.UnitInspectorPresetStatScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitInspectorPresetStatScroll95",
        width = self.UnitInspectorFieldWidth,
        height = 36,
        visibleRows = 2,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.UnitInspectorPresetStatScroll:SetParent(statPanel:GetContentFrame())
    self.UnitInspectorPresetStatScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "referenceText", width = 132, justifyH = "LEFT" },
                { key = "percentText", width = 42, justifyH = "RIGHT" },
                { key = "flatText", width = 42, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "LeftButton" then
                    self:SetSelectedUnitInspectorPresetStatModifierIndex(rowData and rowData.rowIndex or nil)
                    self:RefreshUnitInspectorPresetStatModifierEditor()
                elseif button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowUnitInspectorPresetStatContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.UnitInspectorPresetStatScroll:Create()
    UI.Utils.AnchorFill(self.UnitInspectorPresetStatScroll, statPanel:GetContentFrame(), 0, 0, 0, 0)

    local statEditorRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorPresetStatEditorRow95", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(statEditorRow)

    self.UnitInspectorPresetStatDropdown = UI.CreateDropdown(statEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetStatDropdown95", {
        width = 116,
        height = 18,
        items = { { label = "None", value = "" } },
    })
    statEditorRow:AddChild(self.UnitInspectorPresetStatDropdown)

    self.UnitInspectorPresetStatPercentInput = UI.CreateTextInput(statEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetStatPercentInput95", {
        width = 36,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    statEditorRow:AddChild(self.UnitInspectorPresetStatPercentInput)

    self.UnitInspectorPresetStatFlatInput = UI.CreateTextInput(statEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetStatFlatInput95", {
        width = 36,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    statEditorRow:AddChild(self.UnitInspectorPresetStatFlatInput)

    self.UnitInspectorPresetStatApplyButton = UI.CreateButton(statEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetStatApplyButton95", "Add", 40, function()
        self:ApplyUnitInspectorPresetStatModifier()
    end, { height = 18, fontSize = 7 })
    statEditorRow:AddChild(self.UnitInspectorPresetStatApplyButton)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceLabel95", "Resource Modifiers"))
    root:AddChild(buildModifierHeader(root:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceHeader95", "Resource"))

    local resourcePanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetResourcePanel95", {
        width = self.UnitInspectorFieldWidth,
        height = 38,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(resourcePanel)

    self.UnitInspectorPresetResourceScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitInspectorPresetResourceScroll95",
        width = self.UnitInspectorFieldWidth,
        height = 36,
        visibleRows = 2,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.UnitInspectorPresetResourceScroll:SetParent(resourcePanel:GetContentFrame())
    self.UnitInspectorPresetResourceScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "referenceText", width = 132, justifyH = "LEFT" },
                { key = "percentText", width = 42, justifyH = "RIGHT" },
                { key = "flatText", width = 42, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "LeftButton" then
                    self:SetSelectedUnitInspectorPresetResourceModifierIndex(rowData and rowData.rowIndex or nil)
                    self:RefreshUnitInspectorPresetResourceModifierEditor()
                elseif button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowUnitInspectorPresetResourceContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.UnitInspectorPresetResourceScroll:Create()
    UI.Utils.AnchorFill(self.UnitInspectorPresetResourceScroll, resourcePanel:GetContentFrame(), 0, 0, 0, 0)

    local resourceEditorRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceEditorRow95", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(resourceEditorRow)

    self.UnitInspectorPresetResourceDropdown = UI.CreateDropdown(resourceEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceDropdown95", {
        width = 116,
        height = 18,
        items = { { label = "None", value = "" } },
    })
    resourceEditorRow:AddChild(self.UnitInspectorPresetResourceDropdown)

    self.UnitInspectorPresetResourcePercentInput = UI.CreateTextInput(resourceEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetResourcePercentInput95", {
        width = 36,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    resourceEditorRow:AddChild(self.UnitInspectorPresetResourcePercentInput)

    self.UnitInspectorPresetResourceFlatInput = UI.CreateTextInput(resourceEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceFlatInput95", {
        width = 36,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    resourceEditorRow:AddChild(self.UnitInspectorPresetResourceFlatInput)

    self.UnitInspectorPresetResourceApplyButton = UI.CreateButton(resourceEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceApplyButton95", "Add", 40, function()
        self:ApplyUnitInspectorPresetResourceModifier()
    end, { height = 18, fontSize = 7 })
    resourceEditorRow:AddChild(self.UnitInspectorPresetResourceApplyButton)
end

function DataEditor:BuildUnitInspectorPresetsPage(page)
    if self.UnitInspectorPresetStableHeader then
        self:RefreshUnitInspectorPresetsPage()
        return
    end

    self.UnitInspectorPresetStableHeader = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorPresetStableHeader95", {
        width = self.UnitInspectorFieldWidth,
        height = PRESET_HEADER_HEIGHT,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    local headerFrame = self.UnitInspectorPresetStableHeader:GetFrame()
    headerFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    headerFrame:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)

    local selectorRow = UI.CreateLayout(UI.HorizontalLayoutGroup, headerFrame, "RPEDataEditorUnitInspectorPresetSelectorRow95", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.UnitInspectorPresetStableHeader:AddChild(selectorRow)

    selectorRow:AddChild(UI.CreateText(selectorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetSelectorLabel95", "Preset", {
        width = 32,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    }))

    self.UnitInspectorPresetDropdown = UI.CreateDropdown(selectorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetDropdown95", {
        width = 100,
        height = 18,
        items = {},
        onValueChanged = function(value)
            if self._refreshingUnitInspector or self._refreshingUnitInspectorPresets then
                return
            end
            self:SetSelectedUnitInspectorPresetIndex(tonumber(value))
            self:RefreshUnitInspectorPresetsPage()
        end,
    })
    selectorRow:AddChild(self.UnitInspectorPresetDropdown)

    self.UnitInspectorPresetSectionDropdown = UI.CreateDropdown(selectorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetSectionDropdown95", {
        width = 100,
        height = 18,
        items = SECTION_ITEMS,
        selectedValue = self.ActiveUnitInspectorPresetEditorSection or SECTION_MODIFIERS,
        onValueChanged = function(value)
            if self._refreshingUnitInspectorPresetSection then
                return
            end
            self:SetUnitInspectorPresetEditorSection(value)
        end,
    })
    selectorRow:AddChild(self.UnitInspectorPresetSectionDropdown)

    local lifecycleRow = UI.CreateLayout(UI.HorizontalLayoutGroup, headerFrame, "RPEDataEditorUnitInspectorPresetLifecycleRow95", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.UnitInspectorPresetStableHeader:AddChild(lifecycleRow)

    self.UnitInspectorPresetAddButton = UI.CreateButton(lifecycleRow:GetFrame(), "RPEDataEditorUnitInspectorPresetAddButton95", "Add", 34, function()
        self:AddUnitInspectorPreset()
    end, { height = 18, fontSize = 7 })
    lifecycleRow:AddChild(self.UnitInspectorPresetAddButton)

    self.UnitInspectorPresetDuplicateButton = UI.CreateButton(lifecycleRow:GetFrame(), "RPEDataEditorUnitInspectorPresetDuplicateButton95", "Duplicate", 50, function()
        self:DuplicateUnitInspectorPreset()
    end, { height = 18, fontSize = 7 })
    lifecycleRow:AddChild(self.UnitInspectorPresetDuplicateButton)

    self.UnitInspectorPresetDeleteButton = UI.CreateButton(lifecycleRow:GetFrame(), "RPEDataEditorUnitInspectorPresetDeleteButton95", "Delete", 40, function()
        self:DeleteUnitInspectorPreset()
    end, { height = 18, fontSize = 7 })
    lifecycleRow:AddChild(self.UnitInspectorPresetDeleteButton)

    self.UnitInspectorPresetMoveUpButton = UI.CreateButton(lifecycleRow:GetFrame(), "RPEDataEditorUnitInspectorPresetMoveUpButton95", "Move Up", 48, function()
        self:MoveUnitInspectorPreset(-1)
    end, { height = 18, fontSize = 7 })
    lifecycleRow:AddChild(self.UnitInspectorPresetMoveUpButton)

    self.UnitInspectorPresetMoveDownButton = UI.CreateButton(lifecycleRow:GetFrame(), "RPEDataEditorUnitInspectorPresetMoveDownButton95", "Move Down", 50, function()
        self:MoveUnitInspectorPreset(1)
    end, { height = 18, fontSize = 7 })
    lifecycleRow:AddChild(self.UnitInspectorPresetMoveDownButton)

    local nameRow = UI.CreateLayout(UI.HorizontalLayoutGroup, headerFrame, "RPEDataEditorUnitInspectorPresetNameRow95", {
        width = self.UnitInspectorFieldWidth,
        height = 20,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.UnitInspectorPresetStableHeader:AddChild(nameRow)

    nameRow:AddChild(UI.CreateText(nameRow:GetFrame(), "RPEDataEditorUnitInspectorPresetNameLabel95", "Name", {
        width = 32,
        height = 20,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    }))

    self.UnitInspectorPresetNameInput = UI.CreateTextInput(nameRow:GetFrame(), "RPEDataEditorUnitInspectorPresetNameInput95", {
        width = 200,
        height = 20,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.UnitInspectorPresetNameInput:SetScript("OnEnterPressed", function()
        self:CommitUnitInspectorPresetName()
    end)
    self.UnitInspectorPresetNameInput:SetScript("OnEditFocusLost", function()
        self:CommitUnitInspectorPresetName()
    end)
    nameRow:AddChild(self.UnitInspectorPresetNameInput)

    self.UnitInspectorPresetSectionBody = CreateFrame("Frame", "RPEDataEditorUnitInspectorPresetSectionBody95", page)
    self.UnitInspectorPresetSectionBody:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -PRESET_BODY_OFFSET)
    self.UnitInspectorPresetSectionBody:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

    self.UnitInspectorPresetModifiersView = CreateFrame("Frame", "RPEDataEditorUnitInspectorPresetModifiersView95", self.UnitInspectorPresetSectionBody)
    self.UnitInspectorPresetModifiersView:SetAllPoints(self.UnitInspectorPresetSectionBody)
    self:BuildUnitInspectorPresetModifiersView(self.UnitInspectorPresetModifiersView)

    self.UnitInspectorPresetAppearancesView = CreateFrame("Frame", "RPEDataEditorUnitInspectorPresetAppearancesView95", self.UnitInspectorPresetSectionBody)
    self.UnitInspectorPresetAppearancesView:SetAllPoints(self.UnitInspectorPresetSectionBody)
    self:BuildUnitInspectorPresetAppearanceView(self.UnitInspectorPresetAppearancesView)

    self.UnitInspectorPresetEquipmentView = CreateFrame("Frame", "RPEDataEditorUnitInspectorPresetEquipmentView95", self.UnitInspectorPresetSectionBody)
    self.UnitInspectorPresetEquipmentView:SetAllPoints(self.UnitInspectorPresetSectionBody)
    if self.BuildUnitInspectorPresetEquipmentView then
        self:BuildUnitInspectorPresetEquipmentView(self.UnitInspectorPresetEquipmentView)
    end

    self.UnitInspectorPresetSpellsView = CreateFrame("Frame", "RPEDataEditorUnitInspectorPresetSpellsView95", self.UnitInspectorPresetSectionBody)
    self.UnitInspectorPresetSpellsView:SetAllPoints(self.UnitInspectorPresetSectionBody)
    if self.BuildUnitInspectorPresetSpellsView then
        self:BuildUnitInspectorPresetSpellsView(self.UnitInspectorPresetSpellsView)
    end

    -- #95 has exactly one Preset selector. The old Appearance-local selector is
    -- not constructed by this stable shell.
    self.UnitInspectorPresetAppearancePresetDropdown = nil

    self:SetUnitInspectorPresetEditorSection(self.ActiveUnitInspectorPresetEditorSection or SECTION_MODIFIERS)
    self:RefreshUnitInspectorPresetsPage()
end
