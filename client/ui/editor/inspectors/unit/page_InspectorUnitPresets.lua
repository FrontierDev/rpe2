local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local PRESET_PAGE_KEY = "presets"

local function trimString(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function setButtonEnabled(button, enabled)
    if button and button.SetEnabled then
        button:SetEnabled(enabled == true)
    end
end

local function deepCopyValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopyValue(nestedValue)
    end
    return copy
end

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

function DataEditor:UnitInspectorPresetNameExists(unit, name, ignoreIndex)
    local normalizedName = trimString(name)
    if normalizedName == "" then
        return false
    end

    for index = 1, #(unit and unit.presets or {}) do
        local preset = unit.presets[index]
        if index ~= ignoreIndex and trimString(preset and preset.name or "") == normalizedName then
            return true
        end
    end

    return false
end

function DataEditor:BuildUniqueUnitInspectorPresetName(unit, desiredName, ignoreIndex)
    local baseName = trimString(desiredName)
    if baseName == "" then
        baseName = "New Preset"
    end

    if not self:UnitInspectorPresetNameExists(unit, baseName, ignoreIndex) then
        return baseName
    end

    local suffix = 2
    while self:UnitInspectorPresetNameExists(unit, baseName .. " " .. tostring(suffix), ignoreIndex) do
        suffix = suffix + 1
    end

    return baseName .. " " .. tostring(suffix)
end

function DataEditor:ResetUnitInspectorPresetModifierSelections()
    self.SelectedUnitInspectorPresetStatModifierIndex = nil
    self.SelectedUnitInspectorPresetResourceModifierIndex = nil
end

function DataEditor:SetSelectedUnitInspectorPresetIndex(index)
    local _, unit = self:GetSelectedUnitAndDataset()
    local presets = unit and unit.presets or {}
    index = tonumber(index)

    local nextIndex = nil
    if index and index >= 1 and math.floor(index) == index and presets[index] then
        nextIndex = index
    end

    if self.SelectedUnitInspectorPresetIndex ~= nextIndex then
        self.SelectedUnitInspectorPresetIndex = nextIndex
        self:ResetUnitInspectorPresetModifierSelections()
    end
end

function DataEditor:ValidateUnitInspectorPresetSelection(unit)
    local presets = unit and unit.presets or {}

    if self.UnitInspectorPresetSelectionUnit ~= unit then
        self.UnitInspectorPresetSelectionUnit = unit
        self.SelectedUnitInspectorPresetIndex = presets[1] and 1 or nil
        self:ResetUnitInspectorPresetModifierSelections()
        return self.SelectedUnitInspectorPresetIndex
    end

    local index = tonumber(self.SelectedUnitInspectorPresetIndex)
    if index and index >= 1 and math.floor(index) == index and presets[index] then
        return index
    end

    if index and #presets > 0 then
        self.SelectedUnitInspectorPresetIndex = math.min(math.max(1, index), #presets)
    else
        self.SelectedUnitInspectorPresetIndex = nil
    end
    self:ResetUnitInspectorPresetModifierSelections()
    return self.SelectedUnitInspectorPresetIndex
end

function DataEditor:GetSelectedUnitInspectorPreset()
    local _, unit = self:GetSelectedUnitAndDataset()
    local presets = unit and unit.presets or {}
    local index = tonumber(self.SelectedUnitInspectorPresetIndex)
    if not index or not presets[index] then
        return nil, nil
    end

    return presets[index], index
end

function DataEditor:BuildUnitInspectorPresetSelectorItems(unit)
    local items = {}
    for index = 1, #(unit and unit.presets or {}) do
        local preset = unit.presets[index]
        local name = trimString(preset and preset.name or "")
        if name == "" then
            name = "Preset " .. tostring(index)
        end
        items[#items + 1] = {
            label = name,
            value = tostring(index),
        }
    end
    return items
end

function DataEditor:AddUnitInspectorPreset()
    local _, unit = self:GetSelectedUnitAndDataset()
    if not unit then
        return
    end

    local newIndex = nil
    self:CommitSelectedUnit(function(targetUnit)
        targetUnit.presets = type(targetUnit.presets) == "table" and targetUnit.presets or {}
        local name = self:BuildUniqueUnitInspectorPresetName(targetUnit, "New Preset")
        targetUnit.presets[#targetUnit.presets + 1] = {
            name = name,
            statModifiers = {},
            resourceModifiers = {},
            appearances = {},
        }
        newIndex = #targetUnit.presets
    end)

    self:SetSelectedUnitInspectorPresetIndex(newIndex)
    self:RefreshUnitInspectorPresetsPage()
end

function DataEditor:DuplicateUnitInspectorPreset()
    local preset, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not preset or not presetIndex then
        return
    end

    local newIndex = nil
    self:CommitSelectedUnit(function(unit)
        local source = unit.presets and unit.presets[presetIndex] or nil
        if not source then
            return
        end

        local duplicate = self.DeepCopyValue and self:DeepCopyValue(source) or deepCopyValue(source)
        local sourceName = trimString(source.name)
        duplicate.name = self:BuildUniqueUnitInspectorPresetName(unit, (sourceName ~= "" and sourceName or "Preset") .. " Copy")
        unit.presets[#unit.presets + 1] = duplicate
        newIndex = #unit.presets
    end)

    self:SetSelectedUnitInspectorPresetIndex(newIndex)
    self:RefreshUnitInspectorPresetsPage()
end

function DataEditor:DeleteUnitInspectorPreset()
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not presetIndex then
        return
    end

    local nextIndex = nil
    self:CommitSelectedUnit(function(unit)
        if not unit.presets or not unit.presets[presetIndex] then
            return
        end
        table.remove(unit.presets, presetIndex)
        if #unit.presets > 0 then
            nextIndex = math.min(presetIndex, #unit.presets)
        end
    end)

    self.SelectedUnitInspectorPresetIndex = nextIndex
    self:ResetUnitInspectorPresetModifierSelections()
    self:RefreshUnitInspectorPresetsPage()
end

function DataEditor:MoveUnitInspectorPreset(delta)
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    delta = tonumber(delta)
    if not presetIndex or not delta or math.floor(delta) ~= delta then
        return
    end

    local destination = presetIndex + delta
    local _, unit = self:GetSelectedUnitAndDataset()
    if not unit or destination < 1 or destination > #(unit.presets or {}) then
        return
    end

    self:CommitSelectedUnit(function(targetUnit)
        local presets = targetUnit.presets or {}
        if not presets[presetIndex] or not presets[destination] then
            return
        end
        presets[presetIndex], presets[destination] = presets[destination], presets[presetIndex]
    end)

    self.SelectedUnitInspectorPresetIndex = destination
    self:ResetUnitInspectorPresetModifierSelections()
    self:RefreshUnitInspectorPresetsPage()
end

function DataEditor:CommitUnitInspectorPresetName()
    if self._refreshingUnitInspector or self._refreshingUnitInspectorPresets then
        return
    end

    local preset, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not preset or not presetIndex or self.UnitInspectorPresetNameEditingIndex ~= presetIndex then
        self:RefreshUnitInspectorPresetsPage()
        return
    end

    local name = trimString(self.UnitInspectorPresetNameInput and self.UnitInspectorPresetNameInput:GetText() or "")
    local _, unit = self:GetSelectedUnitAndDataset()
    if name == "" or self:UnitInspectorPresetNameExists(unit, name, presetIndex) then
        self:RefreshUnitInspectorPresetsPage()
        return
    end

    self:CommitSelectedUnit(function(targetUnit)
        if targetUnit.presets and targetUnit.presets[presetIndex] then
            targetUnit.presets[presetIndex].name = name
        end
    end)
    self:RefreshUnitInspectorPresetsPage()
end

function DataEditor:SetSelectedUnitInspectorPresetStatModifierIndex(index)
    local preset = self:GetSelectedUnitInspectorPreset()
    local modifiers = preset and preset.statModifiers or {}
    index = tonumber(index)
    if not index or not modifiers[index] then
        self.SelectedUnitInspectorPresetStatModifierIndex = nil
    else
        self.SelectedUnitInspectorPresetStatModifierIndex = index
    end
end

function DataEditor:GetSelectedUnitInspectorPresetStatModifier()
    local preset = self:GetSelectedUnitInspectorPreset()
    local modifiers = preset and preset.statModifiers or {}
    local index = tonumber(self.SelectedUnitInspectorPresetStatModifierIndex)
    if not index or not modifiers[index] then
        return nil, nil
    end
    return modifiers[index], index
end

function DataEditor:SetSelectedUnitInspectorPresetResourceModifierIndex(index)
    local preset = self:GetSelectedUnitInspectorPreset()
    local modifiers = preset and preset.resourceModifiers or {}
    index = tonumber(index)
    if not index or not modifiers[index] then
        self.SelectedUnitInspectorPresetResourceModifierIndex = nil
    else
        self.SelectedUnitInspectorPresetResourceModifierIndex = index
    end
end

function DataEditor:GetSelectedUnitInspectorPresetResourceModifier()
    local preset = self:GetSelectedUnitInspectorPreset()
    local modifiers = preset and preset.resourceModifiers or {}
    local index = tonumber(self.SelectedUnitInspectorPresetResourceModifierIndex)
    if not index or not modifiers[index] then
        return nil, nil
    end
    return modifiers[index], index
end

function DataEditor:UnitInspectorPresetHasDuplicateModifierRef(listKey, refKey, reference, ignoreIndex)
    local preset = self:GetSelectedUnitInspectorPreset()
    local modifiers = preset and preset[listKey] or {}
    if type(reference) ~= "string" or reference == "" then
        return false
    end

    for index = 1, #modifiers do
        local modifier = modifiers[index]
        if index ~= ignoreIndex and modifier and modifier[refKey] == reference then
            return true
        end
    end

    return false
end

function DataEditor:BuildUnitInspectorPresetStatModifierRows(preset)
    local rows = {}
    for index = 1, #(preset and preset.statModifiers or {}) do
        local modifier = preset.statModifiers[index]
        rows[#rows + 1] = {
            rowIndex = index,
            referenceText = self:ResolveUnitInspectorReferenceLabel("stats", modifier and modifier.statRef or ""),
            percentText = tostring(modifier and modifier.percentBonus or 0),
            flatText = tostring(modifier and modifier.flatBonus or 0),
        }
    end
    return rows
end

function DataEditor:BuildUnitInspectorPresetResourceModifierRows(preset)
    local rows = {}
    for index = 1, #(preset and preset.resourceModifiers or {}) do
        local modifier = preset.resourceModifiers[index]
        rows[#rows + 1] = {
            rowIndex = index,
            referenceText = self:ResolveUnitInspectorReferenceLabel("resources", modifier and modifier.resourceRef or ""),
            percentText = tostring(modifier and modifier.percentBonus or 0),
            flatText = tostring(modifier and modifier.flatBonus or 0),
        }
    end
    return rows
end

function DataEditor:RefreshUnitInspectorPresetStatModifierEditor()
    local preset = self:GetSelectedUnitInspectorPreset()
    local modifier, modifierIndex = self:GetSelectedUnitInspectorPresetStatModifier()
    local enabled = preset ~= nil

    if self.UnitInspectorPresetStatDropdown then
        self.UnitInspectorPresetStatDropdown:SetSelectedValue(modifier and modifier.statRef or "", true)
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorPresetStatDropdown, enabled)
    end
    if self.UnitInspectorPresetStatPercentInput then
        self.UnitInspectorPresetStatPercentInput:SetText(tostring(modifier and modifier.percentBonus or 0))
        self:SetUnitInspectorTextElementEnabled(self.UnitInspectorPresetStatPercentInput, enabled)
    end
    if self.UnitInspectorPresetStatFlatInput then
        self.UnitInspectorPresetStatFlatInput:SetText(tostring(modifier and modifier.flatBonus or 0))
        self:SetUnitInspectorTextElementEnabled(self.UnitInspectorPresetStatFlatInput, enabled)
    end
    if self.UnitInspectorPresetStatApplyButton then
        self.UnitInspectorPresetStatApplyButton:SetText(modifierIndex and "Apply" or "Add")
        setButtonEnabled(self.UnitInspectorPresetStatApplyButton, enabled)
    end
end

function DataEditor:RefreshUnitInspectorPresetResourceModifierEditor()
    local preset = self:GetSelectedUnitInspectorPreset()
    local modifier, modifierIndex = self:GetSelectedUnitInspectorPresetResourceModifier()
    local enabled = preset ~= nil

    if self.UnitInspectorPresetResourceDropdown then
        self.UnitInspectorPresetResourceDropdown:SetSelectedValue(modifier and modifier.resourceRef or "", true)
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorPresetResourceDropdown, enabled)
    end
    if self.UnitInspectorPresetResourcePercentInput then
        self.UnitInspectorPresetResourcePercentInput:SetText(tostring(modifier and modifier.percentBonus or 0))
        self:SetUnitInspectorTextElementEnabled(self.UnitInspectorPresetResourcePercentInput, enabled)
    end
    if self.UnitInspectorPresetResourceFlatInput then
        self.UnitInspectorPresetResourceFlatInput:SetText(tostring(modifier and modifier.flatBonus or 0))
        self:SetUnitInspectorTextElementEnabled(self.UnitInspectorPresetResourceFlatInput, enabled)
    end
    if self.UnitInspectorPresetResourceApplyButton then
        self.UnitInspectorPresetResourceApplyButton:SetText(modifierIndex and "Apply" or "Add")
        setButtonEnabled(self.UnitInspectorPresetResourceApplyButton, enabled)
    end
end

function DataEditor:RefreshUnitInspectorPresetModifierTables()
    local preset = self:GetSelectedUnitInspectorPreset()

    if self.UnitInspectorPresetStatScroll and self.UnitInspectorPresetStatScroll.SetItems then
        self.UnitInspectorPresetStatScroll:SetItems(self:BuildUnitInspectorPresetStatModifierRows(preset))
    end
    if self.UnitInspectorPresetResourceScroll and self.UnitInspectorPresetResourceScroll.SetItems then
        self.UnitInspectorPresetResourceScroll:SetItems(self:BuildUnitInspectorPresetResourceModifierRows(preset))
    end

    self:SetSelectedUnitInspectorPresetStatModifierIndex(self.SelectedUnitInspectorPresetStatModifierIndex)
    self:SetSelectedUnitInspectorPresetResourceModifierIndex(self.SelectedUnitInspectorPresetResourceModifierIndex)
    self:RefreshUnitInspectorPresetStatModifierEditor()
    self:RefreshUnitInspectorPresetResourceModifierEditor()
end

function DataEditor:ApplyUnitInspectorPresetStatModifier()
    if self._refreshingUnitInspector or self._refreshingUnitInspectorPresets then
        return
    end

    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not presetIndex then
        return
    end

    local statRef = self.UnitInspectorPresetStatDropdown and self.UnitInspectorPresetStatDropdown.GetSelectedValue and self.UnitInspectorPresetStatDropdown:GetSelectedValue() or ""
    if statRef == "" then
        return
    end

    local _, modifierIndex = self:GetSelectedUnitInspectorPresetStatModifier()
    if self:UnitInspectorPresetHasDuplicateModifierRef("statModifiers", "statRef", statRef, modifierIndex) then
        return
    end

    local percentBonus = tonumber(self.UnitInspectorPresetStatPercentInput and self.UnitInspectorPresetStatPercentInput:GetText()) or 0
    local flatBonus = tonumber(self.UnitInspectorPresetStatFlatInput and self.UnitInspectorPresetStatFlatInput:GetText()) or 0

    self:CommitSelectedUnit(function(unit)
        local preset = unit.presets and unit.presets[presetIndex] or nil
        if not preset then
            return
        end
        preset.statModifiers = type(preset.statModifiers) == "table" and preset.statModifiers or {}
        if modifierIndex and preset.statModifiers[modifierIndex] then
            preset.statModifiers[modifierIndex].statRef = statRef
            preset.statModifiers[modifierIndex].percentBonus = percentBonus
            preset.statModifiers[modifierIndex].flatBonus = flatBonus
        else
            preset.statModifiers[#preset.statModifiers + 1] = {
                statRef = statRef,
                percentBonus = percentBonus,
                flatBonus = flatBonus,
            }
        end
    end)

    self.SelectedUnitInspectorPresetStatModifierIndex = nil
    self:RefreshUnitInspectorPresetModifierTables()
end

function DataEditor:ApplyUnitInspectorPresetResourceModifier()
    if self._refreshingUnitInspector or self._refreshingUnitInspectorPresets then
        return
    end

    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not presetIndex then
        return
    end

    local resourceRef = self.UnitInspectorPresetResourceDropdown and self.UnitInspectorPresetResourceDropdown.GetSelectedValue and self.UnitInspectorPresetResourceDropdown:GetSelectedValue() or ""
    if resourceRef == "" then
        return
    end

    local _, modifierIndex = self:GetSelectedUnitInspectorPresetResourceModifier()
    if self:UnitInspectorPresetHasDuplicateModifierRef("resourceModifiers", "resourceRef", resourceRef, modifierIndex) then
        return
    end

    local percentBonus = tonumber(self.UnitInspectorPresetResourcePercentInput and self.UnitInspectorPresetResourcePercentInput:GetText()) or 0
    local flatBonus = tonumber(self.UnitInspectorPresetResourceFlatInput and self.UnitInspectorPresetResourceFlatInput:GetText()) or 0

    self:CommitSelectedUnit(function(unit)
        local preset = unit.presets and unit.presets[presetIndex] or nil
        if not preset then
            return
        end
        preset.resourceModifiers = type(preset.resourceModifiers) == "table" and preset.resourceModifiers or {}
        if modifierIndex and preset.resourceModifiers[modifierIndex] then
            preset.resourceModifiers[modifierIndex].resourceRef = resourceRef
            preset.resourceModifiers[modifierIndex].percentBonus = percentBonus
            preset.resourceModifiers[modifierIndex].flatBonus = flatBonus
        else
            preset.resourceModifiers[#preset.resourceModifiers + 1] = {
                resourceRef = resourceRef,
                percentBonus = percentBonus,
                flatBonus = flatBonus,
            }
        end
    end)

    self.SelectedUnitInspectorPresetResourceModifierIndex = nil
    self:RefreshUnitInspectorPresetModifierTables()
end

function DataEditor:EnsureUnitInspectorPresetStatContextMenu()
    if self.UnitInspectorPresetStatContextMenu then
        return self.UnitInspectorPresetStatContextMenu
    end

    self.UnitInspectorPresetStatContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorUnitInspectorPresetStatContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove" then
                return
            end

            local context = self.ContextMenuUnitPresetStatModifier
            local _, currentUnit = self:GetSelectedUnitAndDataset()
            if not context or currentUnit ~= context.unit then
                return
            end

            self:CommitSelectedUnit(function(unit)
                local preset = unit.presets and unit.presets[context.presetIndex] or nil
                if preset and preset.statModifiers and preset.statModifiers[context.modifierIndex] then
                    table.remove(preset.statModifiers, context.modifierIndex)
                end
            end)
            self.SelectedUnitInspectorPresetStatModifierIndex = nil
            self:RefreshUnitInspectorPresetModifierTables()

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.UnitInspectorPresetStatContextMenu:SetParent(self.UnitInspectorPage or UIParent)
    self.UnitInspectorPresetStatContextMenu:Create()
    return self.UnitInspectorPresetStatContextMenu
end

function DataEditor:ShowUnitInspectorPresetStatContextMenu(anchorFrame, rowData)
    local _, unit = self:GetSelectedUnitAndDataset()
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not unit or not presetIndex or not rowData or not rowData.rowIndex then
        return
    end

    self.ContextMenuUnitPresetStatModifier = {
        unit = unit,
        presetIndex = presetIndex,
        modifierIndex = rowData.rowIndex,
    }
    local menu = self:EnsureUnitInspectorPresetStatContextMenu()
    menu:SetItems({ { label = "Remove", value = "remove" } })
    menu:ShowAt(anchorFrame)
end

function DataEditor:EnsureUnitInspectorPresetResourceContextMenu()
    if self.UnitInspectorPresetResourceContextMenu then
        return self.UnitInspectorPresetResourceContextMenu
    end

    self.UnitInspectorPresetResourceContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorUnitInspectorPresetResourceContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove" then
                return
            end

            local context = self.ContextMenuUnitPresetResourceModifier
            local _, currentUnit = self:GetSelectedUnitAndDataset()
            if not context or currentUnit ~= context.unit then
                return
            end

            self:CommitSelectedUnit(function(unit)
                local preset = unit.presets and unit.presets[context.presetIndex] or nil
                if preset and preset.resourceModifiers and preset.resourceModifiers[context.modifierIndex] then
                    table.remove(preset.resourceModifiers, context.modifierIndex)
                end
            end)
            self.SelectedUnitInspectorPresetResourceModifierIndex = nil
            self:RefreshUnitInspectorPresetModifierTables()

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.UnitInspectorPresetResourceContextMenu:SetParent(self.UnitInspectorPage or UIParent)
    self.UnitInspectorPresetResourceContextMenu:Create()
    return self.UnitInspectorPresetResourceContextMenu
end

function DataEditor:ShowUnitInspectorPresetResourceContextMenu(anchorFrame, rowData)
    local _, unit = self:GetSelectedUnitAndDataset()
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not unit or not presetIndex or not rowData or not rowData.rowIndex then
        return
    end

    self.ContextMenuUnitPresetResourceModifier = {
        unit = unit,
        presetIndex = presetIndex,
        modifierIndex = rowData.rowIndex,
    }
    local menu = self:EnsureUnitInspectorPresetResourceContextMenu()
    menu:SetItems({ { label = "Remove", value = "remove" } })
    menu:ShowAt(anchorFrame)
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
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorPresetDropdown, hasUnit and #(unit and unit.presets or {}) > 0)
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
end

function DataEditor:BuildUnitInspectorPresetsPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorPresetsLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetSelectorLabel", "Preset"))
    self.UnitInspectorPresetDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorUnitInspectorPresetDropdown", {
        width = self.UnitInspectorFieldWidth,
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
    root:AddChild(self.UnitInspectorPresetDropdown)

    local lifecycleRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorPresetLifecycleRow", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(lifecycleRow)

    self.UnitInspectorPresetAddButton = UI.CreateButton(lifecycleRow:GetFrame(), "RPEDataEditorUnitInspectorPresetAddButton", "Add", 34, function()
        self:AddUnitInspectorPreset()
    end, { height = 18, fontSize = 7 })
    lifecycleRow:AddChild(self.UnitInspectorPresetAddButton)

    self.UnitInspectorPresetDuplicateButton = UI.CreateButton(lifecycleRow:GetFrame(), "RPEDataEditorUnitInspectorPresetDuplicateButton", "Duplicate", 50, function()
        self:DuplicateUnitInspectorPreset()
    end, { height = 18, fontSize = 7 })
    lifecycleRow:AddChild(self.UnitInspectorPresetDuplicateButton)

    self.UnitInspectorPresetDeleteButton = UI.CreateButton(lifecycleRow:GetFrame(), "RPEDataEditorUnitInspectorPresetDeleteButton", "Delete", 40, function()
        self:DeleteUnitInspectorPreset()
    end, { height = 18, fontSize = 7 })
    lifecycleRow:AddChild(self.UnitInspectorPresetDeleteButton)

    self.UnitInspectorPresetMoveUpButton = UI.CreateButton(lifecycleRow:GetFrame(), "RPEDataEditorUnitInspectorPresetMoveUpButton", "Move Up", 48, function()
        self:MoveUnitInspectorPreset(-1)
    end, { height = 18, fontSize = 7 })
    lifecycleRow:AddChild(self.UnitInspectorPresetMoveUpButton)

    self.UnitInspectorPresetMoveDownButton = UI.CreateButton(lifecycleRow:GetFrame(), "RPEDataEditorUnitInspectorPresetMoveDownButton", "Move Down", 50, function()
        self:MoveUnitInspectorPreset(1)
    end, { height = 18, fontSize = 7 })
    lifecycleRow:AddChild(self.UnitInspectorPresetMoveDownButton)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetNameLabel", "Name"))
    self.UnitInspectorPresetNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorUnitInspectorPresetNameInput", {
        width = self.UnitInspectorFieldWidth,
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
    root:AddChild(self.UnitInspectorPresetNameInput)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetStatLabel", "Stat Modifiers"))
    root:AddChild(buildModifierHeader(root:GetFrame(), "RPEDataEditorUnitInspectorPresetStatHeader", "Stat"))

    local statPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetStatPanel", {
        width = self.UnitInspectorFieldWidth,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(statPanel)

    self.UnitInspectorPresetStatScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitInspectorPresetStatScroll",
        width = self.UnitInspectorFieldWidth,
        height = 54,
        visibleRows = 3,
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

    local statEditorRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorPresetStatEditorRow", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(statEditorRow)

    self.UnitInspectorPresetStatDropdown = UI.CreateDropdown(statEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetStatDropdown", {
        width = 116,
        height = 18,
        items = { { label = "None", value = "" } },
    })
    statEditorRow:AddChild(self.UnitInspectorPresetStatDropdown)

    self.UnitInspectorPresetStatPercentInput = UI.CreateTextInput(statEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetStatPercentInput", {
        width = 36,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    statEditorRow:AddChild(self.UnitInspectorPresetStatPercentInput)

    self.UnitInspectorPresetStatFlatInput = UI.CreateTextInput(statEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetStatFlatInput", {
        width = 36,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    statEditorRow:AddChild(self.UnitInspectorPresetStatFlatInput)

    self.UnitInspectorPresetStatApplyButton = UI.CreateButton(statEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetStatApplyButton", "Add", 40, function()
        self:ApplyUnitInspectorPresetStatModifier()
    end, { height = 18, fontSize = 7 })
    statEditorRow:AddChild(self.UnitInspectorPresetStatApplyButton)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceLabel", "Resource Modifiers"))
    root:AddChild(buildModifierHeader(root:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceHeader", "Resource"))

    local resourcePanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetResourcePanel", {
        width = self.UnitInspectorFieldWidth,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(resourcePanel)

    self.UnitInspectorPresetResourceScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitInspectorPresetResourceScroll",
        width = self.UnitInspectorFieldWidth,
        height = 54,
        visibleRows = 3,
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

    local resourceEditorRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceEditorRow", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(resourceEditorRow)

    self.UnitInspectorPresetResourceDropdown = UI.CreateDropdown(resourceEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceDropdown", {
        width = 116,
        height = 18,
        items = { { label = "None", value = "" } },
    })
    resourceEditorRow:AddChild(self.UnitInspectorPresetResourceDropdown)

    self.UnitInspectorPresetResourcePercentInput = UI.CreateTextInput(resourceEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetResourcePercentInput", {
        width = 36,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    resourceEditorRow:AddChild(self.UnitInspectorPresetResourcePercentInput)

    self.UnitInspectorPresetResourceFlatInput = UI.CreateTextInput(resourceEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceFlatInput", {
        width = 36,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    resourceEditorRow:AddChild(self.UnitInspectorPresetResourceFlatInput)

    self.UnitInspectorPresetResourceApplyButton = UI.CreateButton(resourceEditorRow:GetFrame(), "RPEDataEditorUnitInspectorPresetResourceApplyButton", "Add", 40, function()
        self:ApplyUnitInspectorPresetResourceModifier()
    end, { height = 18, fontSize = 7 })
    resourceEditorRow:AddChild(self.UnitInspectorPresetResourceApplyButton)

    self:RefreshUnitInspectorPresetsPage()
end

-- Integrate this page without duplicating the shared Unit inspector implementation.
-- The module is loaded after page_InspectorUnit.lua; all addon files load before the
-- Data Editor window is instantiated, so these wrappers extend the existing page.
local baseGetUnitInspectorPageDefinitions = DataEditor.GetUnitInspectorPageDefinitions
local baseSetUnitInspectorTab = DataEditor.SetUnitInspectorTab
local baseBuildUnitInspectorPage = DataEditor.BuildUnitInspectorPage
local baseRefreshUnitInspectorPage = DataEditor.RefreshUnitInspectorPage

function DataEditor:GetUnitInspectorPageDefinitions()
    local source = baseGetUnitInspectorPageDefinitions and baseGetUnitInspectorPageDefinitions(self) or {}
    local pages = {}
    local hasPresets = false

    for index = 1, #source do
        local definition = source[index]
        pages[#pages + 1] = {
            key = definition.key,
            label = definition.label,
        }
        if definition.key == PRESET_PAGE_KEY then
            hasPresets = true
        end
    end

    if not hasPresets then
        pages[#pages + 1] = { key = PRESET_PAGE_KEY, label = "Presets" }
    end

    return pages
end

function DataEditor:SetUnitInspectorTab(tabKey)
    if baseSetUnitInspectorTab then
        baseSetUnitInspectorTab(self, tabKey)
    end

    if self.UnitInspectorPresetsPage then
        if self.ActiveUnitInspectorTabKey == PRESET_PAGE_KEY then
            self.UnitInspectorPresetsPage:Show()
        else
            self.UnitInspectorPresetsPage:Hide()
        end
    end
end

function DataEditor:BuildUnitInspectorPage(parent)
    local page = baseBuildUnitInspectorPage and baseBuildUnitInspectorPage(self, parent) or nil
    if not page then
        return nil
    end

    if not self.UnitInspectorPresetsPage then
        self.UnitInspectorPresetsPage = CreateFrame("Frame", "RPEDataEditorUnitInspectorPresetsPage", page)
        self.UnitInspectorPresetsPage:SetPoint("TOPLEFT", page, "TOPLEFT", self.UnitInspectorSidePadding, -24)
        self.UnitInspectorPresetsPage:SetPoint("TOPRIGHT", page, "TOPRIGHT", -self.UnitInspectorSidePadding, -24)
        self.UnitInspectorPresetsPage:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", self.UnitInspectorSidePadding, 24)
        self.UnitInspectorPresetsPage:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -self.UnitInspectorSidePadding, 24)
        self:BuildUnitInspectorPresetsPage(self.UnitInspectorPresetsPage)
    end

    self:RefreshUnitInspectorPresetsPage()
    self:SetUnitInspectorTab(self.ActiveUnitInspectorTabKey or "general")
    return page
end

function DataEditor:RefreshUnitInspectorPage()
    if baseRefreshUnitInspectorPage then
        baseRefreshUnitInspectorPage(self)
    end
    self:RefreshUnitInspectorPresetsPage()
end
