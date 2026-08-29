local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

if type(DataEditor) ~= "table" or DataEditor._presetSpellEquipmentEditorInstalled == true then
    return
end

local SECTION_MODIFIERS = "modifiers"
local SECTION_APPEARANCE = "appearances"
local SECTION_EQUIPMENT = "equipment"
local SECTION_SPELLS = "spells"

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end
    return copy
end

local function setButtonEnabled(button, enabled)
    if button and button.SetEnabled then
        button:SetEnabled(enabled == true)
    end
end

local function getPreset(targetUnit, presetIndex)
    presetIndex = tonumber(presetIndex)
    return presetIndex and targetUnit and targetUnit.presets and targetUnit.presets[presetIndex] or nil
end

local function buildBaseEquipment(unit)
    local equipment = {}
    for _, definition in ipairs(DataEditor:GetUnitInspectorEquipmentFieldDefinitions() or {}) do
        local value = unit and unit[definition.fieldKey] or nil
        if value ~= nil and tostring(value) ~= "" then
            equipment[definition.fieldKey] = value
        end
    end
    return equipment
end

function DataEditor:SetUnitInspectorPresetEquipmentInherited(useBase)
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not presetIndex then
        return
    end

    self:CommitSelectedUnit(function(unit)
        local preset = getPreset(unit, presetIndex)
        if not preset then
            return
        end
        if useBase == true then
            preset.equipment = nil
        elseif preset.equipment == nil then
            preset.equipment = buildBaseEquipment(unit)
        end
    end)
    self:RefreshUnitInspectorPresetEquipmentView()
end

function DataEditor:SetUnitInspectorPresetEquipmentSlot(fieldKey, value)
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not presetIndex then
        return
    end

    self:CommitSelectedUnit(function(unit)
        local preset = getPreset(unit, presetIndex)
        if not preset or preset.equipment == nil then
            return
        end
        preset.equipment = type(preset.equipment) == "table" and preset.equipment or {}
        preset.equipment[fieldKey] = value ~= nil and tostring(value) ~= "" and value or nil
    end)
    self:RefreshUnitInspectorPresetEquipmentView()
end

function DataEditor:SetUnitInspectorPresetSpellsInherited(useBase)
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not presetIndex then
        return
    end

    self:CommitSelectedUnit(function(unit)
        local preset = getPreset(unit, presetIndex)
        if not preset then
            return
        end
        if useBase == true then
            preset.spells = nil
        elseif preset.spells == nil then
            preset.spells = deepCopy(unit.spells or {})
        end
    end)
    self:RefreshUnitInspectorPresetSpellsView()
end

function DataEditor:AddUnitInspectorPresetSpell(spellRef)
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    local normalizedRef = tostring(spellRef or "")
    if not presetIndex or normalizedRef == "" then
        return false
    end

    local added = false
    self:CommitSelectedUnit(function(unit)
        local preset = getPreset(unit, presetIndex)
        if not preset or preset.spells == nil then
            return
        end
        preset.spells = type(preset.spells) == "table" and preset.spells or {}
        for index = 1, #preset.spells do
            if preset.spells[index] == normalizedRef then
                return
            end
        end
        preset.spells[#preset.spells + 1] = normalizedRef
        added = true
    end)
    self:RefreshUnitInspectorPresetSpellsView()
    return added
end

function DataEditor:RemoveUnitInspectorPresetSpell(spellIndex, expectedPresetIndex)
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    local index = tonumber(spellIndex)
    if not presetIndex or (expectedPresetIndex and presetIndex ~= expectedPresetIndex) or not index then
        return false
    end

    local removed = false
    self:CommitSelectedUnit(function(unit)
        local preset = getPreset(unit, presetIndex)
        if not preset or preset.spells == nil or not preset.spells[index] then
            return
        end
        table.remove(preset.spells, index)
        removed = true
    end)
    self:RefreshUnitInspectorPresetSpellsView()
    return removed
end

function DataEditor:BuildUnitInspectorPresetSpellRows(spells)
    local rows = {}
    for index = 1, #(spells or {}) do
        rows[#rows + 1] = {
            rowIndex = index,
            spellText = self:ResolveUnitInspectorReferenceLabel("spells", spells[index]),
        }
    end
    return rows
end

function DataEditor:EnsureUnitInspectorPresetSpellContextMenu()
    if self.UnitInspectorPresetSpellContextMenu then
        return self.UnitInspectorPresetSpellContextMenu
    end

    self.UnitInspectorPresetSpellContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorUnitInspectorPresetSpellContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            local context = self.ContextMenuUnitPresetSpell
            if item and item.value == "remove" and context then
                self:RemoveUnitInspectorPresetSpell(context.spellIndex, context.presetIndex)
            end
            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.UnitInspectorPresetSpellContextMenu:SetParent(self.UnitInspectorPage or UIParent)
    self.UnitInspectorPresetSpellContextMenu:Create()
    return self.UnitInspectorPresetSpellContextMenu
end

function DataEditor:ShowUnitInspectorPresetSpellContextMenu(anchorFrame, rowData)
    local preset = self:GetSelectedUnitInspectorPreset()
    local _, presetIndex = self:GetSelectedUnitInspectorPreset()
    if not preset or preset.spells == nil or not presetIndex or not rowData or not rowData.rowIndex then
        return
    end

    self.ContextMenuUnitPresetSpell = {
        presetIndex = presetIndex,
        spellIndex = rowData.rowIndex,
    }
    local menu = self:EnsureUnitInspectorPresetSpellContextMenu()
    menu:SetItems({ { label = "Remove", value = "remove" } })
    menu:ShowAt(anchorFrame)
end

function DataEditor:RefreshUnitInspectorPresetEquipmentView()
    local _, unit = self:GetSelectedUnitAndDataset()
    local preset = self:GetSelectedUnitInspectorPreset()
    local hasPreset = preset ~= nil
    local inherits = not hasPreset or preset.equipment == nil
    local shownEquipment = inherits and buildBaseEquipment(unit) or (preset and preset.equipment or {})

    self._refreshingUnitInspectorPresetEquipment = true
    if self.UnitInspectorPresetUseBaseEquipmentCheckbox then
        self.UnitInspectorPresetUseBaseEquipmentCheckbox:SetChecked(inherits, true)
        self:SetUnitInspectorCheckboxEnabled(self.UnitInspectorPresetUseBaseEquipmentCheckbox, hasPreset)
    end

    for _, definition in ipairs(self:GetUnitInspectorEquipmentFieldDefinitions() or {}) do
        local dropdown = self["UnitInspectorPreset" .. definition.fieldKey .. "Dropdown"]
        if dropdown then
            local slotRef = self:GetUnitInspectorActiveSlotReference(definition.ruleKey)
            dropdown:SetItems(self:BuildUnitInspectorItemItemsForSlot(slotRef, definition.fieldKey))
            dropdown:SetSelectedValue(shownEquipment and shownEquipment[definition.fieldKey] or "", true)
            self:SetUnitInspectorDropdownEnabled(dropdown, hasPreset and not inherits and slotRef ~= "")
        end
    end
    self._refreshingUnitInspectorPresetEquipment = false
end

function DataEditor:RefreshUnitInspectorPresetSpellsView()
    local _, unit = self:GetSelectedUnitAndDataset()
    local preset = self:GetSelectedUnitInspectorPreset()
    local hasPreset = preset ~= nil
    local inherits = not hasPreset or preset.spells == nil
    local shownSpells = inherits and (unit and unit.spells or {}) or (preset and preset.spells or {})

    self._refreshingUnitInspectorPresetSpells = true
    if self.UnitInspectorPresetUseBaseSpellsCheckbox then
        self.UnitInspectorPresetUseBaseSpellsCheckbox:SetChecked(inherits, true)
        self:SetUnitInspectorCheckboxEnabled(self.UnitInspectorPresetUseBaseSpellsCheckbox, hasPreset)
    end
    if self.UnitInspectorPresetSpellsScroll and self.UnitInspectorPresetSpellsScroll.SetItems then
        self.UnitInspectorPresetSpellsScroll:SetItems(self:BuildUnitInspectorPresetSpellRows(shownSpells))
    end
    if self.UnitInspectorPresetPendingSpellDropdown then
        self.UnitInspectorPresetPendingSpellDropdown:SetItems(self:BuildUnitInspectorReferencesAcrossDatasets("spells"))
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorPresetPendingSpellDropdown, hasPreset and not inherits)
    end
    setButtonEnabled(self.UnitInspectorPresetAddSpellButton, hasPreset and not inherits)
    self._refreshingUnitInspectorPresetSpells = false
end

function DataEditor:BuildUnitInspectorPresetEquipmentView(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorPresetEquipmentLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetEquipmentLabel", "Preset Equipment"))
    self.UnitInspectorPresetUseBaseEquipmentCheckbox = self:CreateUnitInspectorCheckbox(
        root:GetFrame(),
        "RPEDataEditorUnitInspectorPresetUseBaseEquipmentCheckbox",
        "Use Base Equipment",
        true,
        function(checked)
            if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetEquipment then
                return
            end
            self:SetUnitInspectorPresetEquipmentInherited(checked)
        end
    )
    root:AddChild(self.UnitInspectorPresetUseBaseEquipmentCheckbox)

    for _, definition in ipairs(self:GetUnitInspectorEquipmentFieldDefinitions() or {}) do
        local fieldDefinition = definition
        root:AddChild(self:BuildUnitInspectorLabel(
            root:GetFrame(),
            "RPEDataEditorUnitInspectorPreset" .. fieldDefinition.fieldKey .. "Label",
            fieldDefinition.label
        ))
        local dropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorUnitInspectorPreset" .. fieldDefinition.fieldKey .. "Dropdown", {
            width = self.UnitInspectorFieldWidth,
            height = 18,
            items = { { label = "None", value = "" } },
            onValueChanged = function(value)
                if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetEquipment then
                    return
                end
                self:SetUnitInspectorPresetEquipmentSlot(fieldDefinition.fieldKey, value)
            end,
        })
        self["UnitInspectorPreset" .. fieldDefinition.fieldKey .. "Dropdown"] = dropdown
        root:AddChild(dropdown)
    end
end

function DataEditor:BuildUnitInspectorPresetSpellsView(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorPresetSpellsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetSpellsLabel", "Preset Spells"))
    self.UnitInspectorPresetUseBaseSpellsCheckbox = self:CreateUnitInspectorCheckbox(
        root:GetFrame(),
        "RPEDataEditorUnitInspectorPresetUseBaseSpellsCheckbox",
        "Use Base Spells",
        true,
        function(checked)
            if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetSpells then
                return
            end
            self:SetUnitInspectorPresetSpellsInherited(checked)
        end
    )
    root:AddChild(self.UnitInspectorPresetUseBaseSpellsCheckbox)

    self.UnitInspectorPresetSpellsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorUnitInspectorPresetSpellsPanel", {
        width = self.UnitInspectorFieldWidth,
        height = 128,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.UnitInspectorPresetSpellsPanel)

    self.UnitInspectorPresetSpellsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitInspectorPresetSpellsScroll",
        width = self.UnitInspectorFieldWidth,
        height = 126,
        visibleRows = 7,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.UnitInspectorPresetSpellsScroll:SetParent(self.UnitInspectorPresetSpellsPanel:GetContentFrame())
    self.UnitInspectorPresetSpellsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({ { key = "spellText", width = 220, justifyH = "LEFT" } })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowUnitInspectorPresetSpellContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.UnitInspectorPresetSpellsScroll:Create()
    UI.Utils.AnchorFill(self.UnitInspectorPresetSpellsScroll, self.UnitInspectorPresetSpellsPanel:GetContentFrame(), 0, 0, 0, 0)

    local pendingRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorPresetPendingSpellRow", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(pendingRow)

    self.UnitInspectorPresetPendingSpellDropdown = UI.CreateDropdown(pendingRow:GetFrame(), "RPEDataEditorUnitInspectorPresetPendingSpellDropdown", {
        width = 198,
        height = 18,
        items = { { label = "None", value = "" } },
    })
    pendingRow:AddChild(self.UnitInspectorPresetPendingSpellDropdown)

    self.UnitInspectorPresetAddSpellButton = UI.CreateButton(pendingRow:GetFrame(), "RPEDataEditorUnitInspectorPresetAddSpellButton", "Add", 36, function()
        if self._refreshingUnitInspector or self._refreshingUnitInspectorPresetSpells then
            return
        end
        local spellRef = self.UnitInspectorPresetPendingSpellDropdown
            and self.UnitInspectorPresetPendingSpellDropdown.GetSelectedValue
            and self.UnitInspectorPresetPendingSpellDropdown:GetSelectedValue()
            or ""
        if spellRef ~= "" then
            self:AddUnitInspectorPresetSpell(spellRef)
        end
    end, { height = 18, fontSize = 7 })
    pendingRow:AddChild(self.UnitInspectorPresetAddSpellButton)
end

local baseSetUnitInspectorPresetEditorSection = DataEditor.SetUnitInspectorPresetEditorSection
function DataEditor:SetUnitInspectorPresetEditorSection(sectionKey)
    if sectionKey == SECTION_MODIFIERS or sectionKey == SECTION_APPEARANCE then
        if self.UnitInspectorPresetEquipmentView then self.UnitInspectorPresetEquipmentView:Hide() end
        if self.UnitInspectorPresetSpellsView then self.UnitInspectorPresetSpellsView:Hide() end
        if type(baseSetUnitInspectorPresetEditorSection) == "function" then
            return baseSetUnitInspectorPresetEditorSection(self, sectionKey)
        end
        return
    end

    if sectionKey ~= SECTION_EQUIPMENT and sectionKey ~= SECTION_SPELLS then
        sectionKey = SECTION_MODIFIERS
        if type(baseSetUnitInspectorPresetEditorSection) == "function" then
            return baseSetUnitInspectorPresetEditorSection(self, sectionKey)
        end
        return
    end

    self.ActiveUnitInspectorPresetEditorSection = sectionKey
    if self.UnitInspectorPresetModifiersView then self.UnitInspectorPresetModifiersView:Hide() end
    if self.UnitInspectorPresetAppearancesView then self.UnitInspectorPresetAppearancesView:Hide() end
    if self.UnitInspectorPresetEquipmentView then
        if sectionKey == SECTION_EQUIPMENT then self.UnitInspectorPresetEquipmentView:Show() else self.UnitInspectorPresetEquipmentView:Hide() end
    end
    if self.UnitInspectorPresetSpellsView then
        if sectionKey == SECTION_SPELLS then self.UnitInspectorPresetSpellsView:Show() else self.UnitInspectorPresetSpellsView:Hide() end
    end
    if self.UnitInspectorPresetSectionDropdown and self.UnitInspectorPresetSectionDropdown.SetSelectedValue then
        self._refreshingUnitInspectorPresetSection = true
        self.UnitInspectorPresetSectionDropdown:SetSelectedValue(sectionKey, true)
        self._refreshingUnitInspectorPresetSection = false
    end
end

local baseRefreshUnitInspectorPresetsPage = DataEditor.RefreshUnitInspectorPresetsPage
function DataEditor:RefreshUnitInspectorPresetsPage()
    if type(baseRefreshUnitInspectorPresetsPage) == "function" then
        baseRefreshUnitInspectorPresetsPage(self)
    end
    self:RefreshUnitInspectorPresetEquipmentView()
    self:RefreshUnitInspectorPresetSpellsView()
end

local baseBuildUnitInspectorPresetsPage = DataEditor.BuildUnitInspectorPresetsPage
function DataEditor:BuildUnitInspectorPresetsPage(page)
    if type(baseBuildUnitInspectorPresetsPage) == "function" then
        baseBuildUnitInspectorPresetsPage(self, page)
    end

    if not self.UnitInspectorPresetEquipmentView then
        self.UnitInspectorPresetEquipmentView = CreateFrame("Frame", "RPEDataEditorUnitInspectorPresetEquipmentView", page)
        self.UnitInspectorPresetEquipmentView:SetAllPoints(page)
        self:BuildUnitInspectorPresetEquipmentView(self.UnitInspectorPresetEquipmentView)
    end

    if not self.UnitInspectorPresetSpellsView then
        self.UnitInspectorPresetSpellsView = CreateFrame("Frame", "RPEDataEditorUnitInspectorPresetSpellsView", page)
        self.UnitInspectorPresetSpellsView:SetAllPoints(page)
        self:BuildUnitInspectorPresetSpellsView(self.UnitInspectorPresetSpellsView)
    end

    if self.UnitInspectorPresetSectionDropdown and self.UnitInspectorPresetSectionDropdown.SetItems then
        self.UnitInspectorPresetSectionDropdown:SetItems({
            { label = "Modifiers", value = SECTION_MODIFIERS },
            { label = "Appearance", value = SECTION_APPEARANCE },
            { label = "Equipment", value = SECTION_EQUIPMENT },
            { label = "Spells", value = SECTION_SPELLS },
        })
    end

    self:SetUnitInspectorPresetEditorSection(self.ActiveUnitInspectorPresetEditorSection or SECTION_MODIFIERS)
    self:RefreshUnitInspectorPresetsPage()
end

DataEditor._presetSpellEquipmentEditorInstalled = true
