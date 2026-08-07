local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}

local INSPECTOR_SIDE_PADDING = 8
local CONTROL_HEIGHT = 20
local FIELD_WIDTH = 236

local PROGRESSION_DEFINITION_INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "stats", label = "Stats" },
    { key = "resources", label = "Resources" },
    { key = "skills", label = "Skills" },
    { key = "traits", label = "Traits" },
}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function getInspectorPrefix(collectionKey)
    return collectionKey == "classes" and "Class" or "Race"
end

local function getSelectedDefinition(self, collectionKey)
    local dataset = self:GetSelectedDataset()
    local definition = self:GetSelectedDatasetEntry(collectionKey)
    return dataset, definition
end

local function buildLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
end

local function setTextElementEnabled(element, enabled)
    if not element then
        return
    end

    if element.SetEnabled then
        element:SetEnabled(enabled == true)
    end
    if element.SetReadOnly then
        element:SetReadOnly(enabled ~= true)
    end
end

local function setDropdownEnabled(dropdown, enabled)
    local frame = dropdown and dropdown.GetFrame and dropdown:GetFrame() or nil
    if not frame then
        return
    end

    if frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end
    if frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
end

local function setButtonEnabled(button, enabled)
    if not button then
        return
    end

    if button.SetEnabled then
        button:SetEnabled(enabled == true)
    end

    local frame = button.GetFrame and button:GetFrame() or nil
    if frame and frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end
    if frame and frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
end

local function commitSelectedDefinition(self, collectionKey, mutate)
    local dataset, definition = getSelectedDefinition(self, collectionKey)
    if not dataset or not definition or type(mutate) ~= "function" then
        return
    end

    mutate(definition, dataset)
    if self.Database and self.Database.NotifyDatasetEntryChanged then
        self.Database.NotifyDatasetEntryChanged(dataset.id, collectionKey, {
            deferConfigurationChanged = true,
        })
    end
    self:RefreshAfterDatasetEntryChanged(collectionKey)
end

local function getInspectorState(self, collectionKey)
    self.ProgressionInspectorState = self.ProgressionInspectorState or {}
    self.ProgressionInspectorState[collectionKey] = self.ProgressionInspectorState[collectionKey] or {}
    return self.ProgressionInspectorState[collectionKey]
end

local function getWidgets(self, collectionKey)
    return self[getInspectorPrefix(collectionKey) .. "InspectorWidgets"] or {}
end

local function getContextMenu(self, collectionKey, progressionKey)
    local menuKey = getInspectorPrefix(collectionKey) .. progressionKey .. "ContextMenu"
    return self[menuKey]
end

local function setContextMenu(self, collectionKey, progressionKey, menu)
    local menuKey = getInspectorPrefix(collectionKey) .. progressionKey .. "ContextMenu"
    self[menuKey] = menu
end

local function buildRefItems(self, collectionKey)
    local items = {
        { label = "None", value = "" },
    }

    local datasets = self:GetDatasets()
    local dependencies = self.Database and self.Database.Dependecies or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local entries = dataset and dataset[collectionKey] or {}
        for entryIndex = 1, #entries do
            local entry = entries[entryIndex]
            if entry and entry.id then
                items[#items + 1] = {
                    label = ("%s: %s"):format(self:GetDatasetDisplayName(dataset), self:GetEntryDisplayName(collectionKey, entry)),
                    value = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, entry.id) or "",
                }
            end
        end
    end

    return items
end

local function buildProgressionRows(self, definition, progressionKey, refKey, labelCollectionKey)
    local rows = {}
    local entries = definition and definition[progressionKey] or {}

    for index = 1, #entries do
        local entry = entries[index]
        rows[#rows + 1] = {
            rowIndex = index,
            ref = entry and entry[refKey] or "",
            refText = self:ResolveSpellInspectorReferenceLabel(labelCollectionKey, entry and entry[refKey] or ""),
            initialValueText = tostring(entry and entry.initialValue or 0),
            perLevelValueText = tostring(entry and entry.perLevelValue or 0),
        }
    end

    return rows
end

local function buildTraitRefRows(self, definition)
    local rows = {}
    local entries = definition and definition.traitRefs or {}

    for index = 1, #entries do
        local traitRef = entries[index]
        rows[#rows + 1] = {
            rowIndex = index,
            ref = traitRef,
            refText = self:ResolveSpellInspectorReferenceLabel("traits", traitRef or ""),
        }
    end

    return rows
end

local function buildSkillBonusRows(self, definition)
    local rows = {}
    local entries = definition and definition.skillBonuses or {}

    for index = 1, #entries do
        local entry = entries[index]
        rows[#rows + 1] = {
            rowIndex = index,
            ref = entry and entry.skillRef or "",
            refText = self:ResolveSpellInspectorReferenceLabel("skills", entry and entry.skillRef or ""),
            valueText = tostring(entry and entry.value or 0),
        }
    end

    return rows
end

local function hasDuplicateProgressionRef(self, collectionKey, progressionKey, refKey, refValue, ignoreIndex)
    local _, definition = getSelectedDefinition(self, collectionKey)
    if type(refValue) ~= "string" or refValue == "" then
        return false
    end

    local entries = definition and definition[progressionKey] or {}
    for index = 1, #entries do
        local entry = entries[index]
        if index ~= ignoreIndex and entry and entry[refKey] == refValue then
            return true
        end
    end

    return false
end

local function hasDuplicateTraitRef(self, collectionKey, refValue, ignoreIndex)
    local _, definition = getSelectedDefinition(self, collectionKey)
    if type(refValue) ~= "string" or refValue == "" then
        return false
    end

    local entries = definition and definition.traitRefs or {}
    for index = 1, #entries do
        if index ~= ignoreIndex and entries[index] == refValue then
            return true
        end
    end

    return false
end

local function setSelectedProgressionIndex(self, collectionKey, progressionKey, index)
    local _, definition = getSelectedDefinition(self, collectionKey)
    local entries = definition and definition[progressionKey] or {}
    local numericIndex = tonumber(index)
    local state = getInspectorState(self, collectionKey)

    if not numericIndex or not entries[numericIndex] then
        state["selected" .. progressionKey .. "Index"] = nil
    else
        state["selected" .. progressionKey .. "Index"] = numericIndex
    end
end

local function getSelectedProgressionEntry(self, collectionKey, progressionKey)
    local _, definition = getSelectedDefinition(self, collectionKey)
    local entries = definition and definition[progressionKey] or {}
    local state = getInspectorState(self, collectionKey)
    local index = tonumber(state["selected" .. progressionKey .. "Index"])
    if not index or not entries[index] then
        return nil, nil
    end

    return entries[index], index
end

local function ensureProgressionContextMenu(self, collectionKey, progressionKey)
    local existing = getContextMenu(self, collectionKey, progressionKey)
    if existing then
        return existing
    end

    local menu = UI.ContextMenu:New({
        name = "RPEDataEditor" .. getInspectorPrefix(collectionKey) .. progressionKey .. "ContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 1,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, contextMenu)
            if not item or item.value ~= "remove" then
                return
            end

            local _, removeIndex = getSelectedProgressionEntry(self, collectionKey, progressionKey)
            if not removeIndex then
                return
            end

            commitSelectedDefinition(self, collectionKey, function(definition)
                table.remove(definition[progressionKey] or {}, removeIndex)
            end)
            setSelectedProgressionIndex(self, collectionKey, progressionKey, nil)

            if contextMenu and contextMenu.HideMenus then
                contextMenu:HideMenus()
            end
        end,
    })
    menu:SetParent(self[getInspectorPrefix(collectionKey) .. "InspectorPage"] or UIParent)
    menu:Create()
    setContextMenu(self, collectionKey, progressionKey, menu)
    return menu
end

local function showProgressionContextMenu(self, collectionKey, progressionKey, anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    setSelectedProgressionIndex(self, collectionKey, progressionKey, rowData.rowIndex)
    local menu = ensureProgressionContextMenu(self, collectionKey, progressionKey)
    menu:SetItems({
        { label = "Remove", value = "remove" },
    })
    menu:ShowAt(anchorFrame)
end

local function refreshProgressionEditor(self, collectionKey, progressionKey, refKey)
    local widgets = getWidgets(self, collectionKey)
    local entry, index = getSelectedProgressionEntry(self, collectionKey, progressionKey)
    local prefix = progressionKey == "statProgressions" and "pendingStat" or "pendingResource"
    local dropdown = widgets[prefix .. "RefDropdown"]
    local initialInput = widgets[prefix .. "InitialInput"]
    local perLevelInput = widgets[prefix .. "PerLevelInput"]
    local saveButton = widgets[prefix .. "SaveButton"]
    local removeButton = widgets[prefix .. "RemoveButton"]

    if dropdown and dropdown.SetSelectedValue then
        dropdown:SetSelectedValue(entry and entry[refKey] or "", true)
    end
    if initialInput then
        initialInput:SetText(tostring(entry and entry.initialValue or 0))
    end
    if perLevelInput then
        perLevelInput:SetText(tostring(entry and entry.perLevelValue or 0))
    end
    if saveButton and saveButton.SetText then
        saveButton:SetText(index and "Apply" or "Add")
    end
    setButtonEnabled(removeButton, index ~= nil)
end

local function refreshTraitRefEditor(self, collectionKey)
    local widgets = getWidgets(self, collectionKey)
    local entry, index = getSelectedProgressionEntry(self, collectionKey, "traitRefs")
    local dropdown = widgets.pendingTraitRefDropdown
    local saveButton = widgets.pendingTraitSaveButton
    local removeButton = widgets.pendingTraitRemoveButton

    if dropdown and dropdown.SetSelectedValue then
        dropdown:SetSelectedValue(type(entry) == "string" and entry or "", true)
    end
    if saveButton and saveButton.SetText then
        saveButton:SetText(index and "Apply" or "Add")
    end
    setButtonEnabled(removeButton, index ~= nil)
end

local function refreshSkillBonusEditor(self, collectionKey)
    local widgets = getWidgets(self, collectionKey)
    local entry, index = getSelectedProgressionEntry(self, collectionKey, "skillBonuses")
    local dropdown = widgets.pendingSkillRefDropdown
    local valueInput = widgets.pendingSkillValueInput
    local saveButton = widgets.pendingSkillSaveButton
    local removeButton = widgets.pendingSkillRemoveButton

    if dropdown and dropdown.SetSelectedValue then
        dropdown:SetSelectedValue(entry and entry.skillRef or "", true)
    end
    if valueInput then
        valueInput:SetText(tostring(entry and entry.value or 0))
    end
    if saveButton and saveButton.SetText then
        saveButton:SetText(index and "Apply" or "Add")
    end
    setButtonEnabled(removeButton, index ~= nil)
end

local function refreshGeneralControls(self, collectionKey, definition)
    local hasDefinition = definition ~= nil
    local widgets = getWidgets(self, collectionKey)

    if widgets.nameInput then
        widgets.nameInput:SetText(definition and ensureString(definition.name) or "")
        setTextElementEnabled(widgets.nameInput, hasDefinition)
    end
    if widgets.idText then
        widgets.idText:SetText(("ID: %s"):format(definition and definition.id ~= nil and tostring(definition.id) or "-"))
    end
    if widgets.iconInput then
        widgets.iconInput:SetText(definition and ensureString(definition.icon) or "")
        setTextElementEnabled(widgets.iconInput, hasDefinition)
    end
    if widgets.descriptionInput then
        widgets.descriptionInput:SetText(definition and ensureString(definition.description) or "")
        setTextElementEnabled(widgets.descriptionInput, hasDefinition)
    end
end

local function refreshProgressionControls(self, collectionKey, definition)
    local hasDefinition = definition ~= nil
    local widgets = getWidgets(self, collectionKey)

    if widgets.statScroll and widgets.statScroll.SetItems then
        widgets.statScroll:SetItems(buildProgressionRows(self, definition, "statProgressions", "statRef", "stats"))
    end
    if widgets.resourceScroll and widgets.resourceScroll.SetItems then
        widgets.resourceScroll:SetItems(buildProgressionRows(self, definition, "resourceProgressions", "resourceRef", "resources"))
    end
    if widgets.traitsScroll and widgets.traitsScroll.SetItems then
        widgets.traitsScroll:SetItems(buildTraitRefRows(self, definition))
    end
    if widgets.skillsScroll and widgets.skillsScroll.SetItems then
        widgets.skillsScroll:SetItems(buildSkillBonusRows(self, definition))
    end

    if widgets.pendingStatRefDropdown then
        widgets.pendingStatRefDropdown:SetItems(buildRefItems(self, "stats"))
        setDropdownEnabled(widgets.pendingStatRefDropdown, hasDefinition)
    end
    if widgets.pendingResourceRefDropdown then
        widgets.pendingResourceRefDropdown:SetItems(buildRefItems(self, "resources"))
        setDropdownEnabled(widgets.pendingResourceRefDropdown, hasDefinition)
    end
    if widgets.pendingTraitRefDropdown then
        widgets.pendingTraitRefDropdown:SetItems(buildRefItems(self, "traits"))
        setDropdownEnabled(widgets.pendingTraitRefDropdown, hasDefinition)
    end
    if widgets.pendingSkillRefDropdown then
        widgets.pendingSkillRefDropdown:SetItems(buildRefItems(self, "skills"))
        setDropdownEnabled(widgets.pendingSkillRefDropdown, hasDefinition)
    end

    setTextElementEnabled(widgets.pendingStatInitialInput, hasDefinition)
    setTextElementEnabled(widgets.pendingStatPerLevelInput, hasDefinition)
    setTextElementEnabled(widgets.pendingResourceInitialInput, hasDefinition)
    setTextElementEnabled(widgets.pendingResourcePerLevelInput, hasDefinition)
    setTextElementEnabled(widgets.pendingSkillValueInput, hasDefinition)
    setButtonEnabled(widgets.pendingStatSaveButton, hasDefinition)
    setButtonEnabled(widgets.pendingResourceSaveButton, hasDefinition)
    setButtonEnabled(widgets.pendingTraitSaveButton, hasDefinition)
    setButtonEnabled(widgets.pendingSkillSaveButton, hasDefinition)

    refreshProgressionEditor(self, collectionKey, "statProgressions", "statRef")
    refreshProgressionEditor(self, collectionKey, "resourceProgressions", "resourceRef")
    refreshTraitRefEditor(self, collectionKey)
    refreshSkillBonusEditor(self, collectionKey)

    if not hasDefinition then
        setButtonEnabled(widgets.pendingStatRemoveButton, false)
        setButtonEnabled(widgets.pendingResourceRemoveButton, false)
        setButtonEnabled(widgets.pendingTraitRemoveButton, false)
        setButtonEnabled(widgets.pendingSkillRemoveButton, false)
    end
end

function DataEditor:GetProgressionDefinitionInspectorPageDefinitions()
    return PROGRESSION_DEFINITION_INSPECTOR_PAGE_DEFINITIONS
end

function DataEditor:GetProgressionDefinitionInspectorPageIndexByKey(key)
    local pages = self:GetProgressionDefinitionInspectorPageDefinitions()
    for index = 1, #pages do
        if pages[index].key == key then
            return index
        end
    end

    return 1
end

function DataEditor:BuildProgressionDefinitionInspectorPageSelectorItems()
    local items = {}
    local pages = self:GetProgressionDefinitionInspectorPageDefinitions()

    for index = 1, #pages do
        items[#items + 1] = {
            label = pages[index].label,
            value = pages[index].key,
        }
    end

    return items
end

function DataEditor:RefreshProgressionDefinitionInspectorPageSelector(collectionKey)
    local prefix = getInspectorPrefix(collectionKey)
    local pages = self:GetProgressionDefinitionInspectorPageDefinitions()
    local pageCount = #pages
    local activeIndex = math.max(1, math.min(self["Active" .. prefix .. "InspectorPageIndex"] or 1, pageCount))

    self["Active" .. prefix .. "InspectorPageIndex"] = activeIndex
    self["Active" .. prefix .. "InspectorTabKey"] = pages[activeIndex] and pages[activeIndex].key or "general"

    local dropdown = self[prefix .. "InspectorPageDropdown"]
    local activeDefinition = pages[activeIndex]
    if dropdown and activeDefinition then
        self["_refreshing" .. prefix .. "InspectorPageSelector"] = true
        dropdown:SetSelectedValue(activeDefinition.key, true)
        self["_refreshing" .. prefix .. "InspectorPageSelector"] = false
    end

    local previousButton = self[prefix .. "InspectorPreviousButton"]
    if previousButton and previousButton.SetEnabled then
        previousButton:SetEnabled(activeIndex > 1)
    end

    local nextButton = self[prefix .. "InspectorNextButton"]
    if nextButton and nextButton.SetEnabled then
        nextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetProgressionDefinitionInspectorTab(collectionKey, tabKey)
    local prefix = getInspectorPrefix(collectionKey)
    local pages = self:GetProgressionDefinitionInspectorPageDefinitions()
    local activeIndex = self:GetProgressionDefinitionInspectorPageIndexByKey(tabKey or "general")

    self["Active" .. prefix .. "InspectorPageIndex"] = activeIndex
    self["Active" .. prefix .. "InspectorTabKey"] = pages[activeIndex] and pages[activeIndex].key or "general"

    local frames = {
        general = self[prefix .. "InspectorGeneralPage"],
        stats = self[prefix .. "InspectorStatsPage"],
        resources = self[prefix .. "InspectorResourcesPage"],
        skills = self[prefix .. "InspectorSkillsPage"],
        traits = self[prefix .. "InspectorTraitsPage"],
    }

    for key, page in pairs(frames) do
        if page then
            if key == self["Active" .. prefix .. "InspectorTabKey"] then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    self:RefreshProgressionDefinitionInspectorPageSelector(collectionKey)
end

function DataEditor:RefreshProgressionDefinitionInspectorPage(collectionKey)
    local _, definition = getSelectedDefinition(self, collectionKey)
    local prefix = getInspectorPrefix(collectionKey)
    local hasDefinition = definition ~= nil

    self["_refreshing" .. prefix .. "Inspector"] = true
    refreshGeneralControls(self, collectionKey, definition)
    refreshProgressionControls(self, collectionKey, definition)
    self["_refreshing" .. prefix .. "Inspector"] = false

    local emptyText = self[prefix .. "InspectorEmptyText"]
    if emptyText then
        local singularLabel = collectionKey == "classes" and "class" or "race"
        emptyText:SetText(hasDefinition and ("Adjust the selected %s definition here."):format(singularLabel) or ("Select a %s to inspect it."):format(singularLabel))
    end

    if hasDefinition and self["Active" .. prefix .. "InspectorTabKey"] == nil then
        self:SetProgressionDefinitionInspectorTab(collectionKey, "general")
    else
        self:RefreshProgressionDefinitionInspectorPageSelector(collectionKey)
    end
end

local function buildGeneralPage(self, page, collectionKey)
    local prefix = getInspectorPrefix(collectionKey)
    local widgets = getWidgets(self, collectionKey)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditor" .. prefix .. "InspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditor" .. prefix .. "InspectorNameLabel", "Name"))
    widgets.nameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditor" .. prefix .. "InspectorNameInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    widgets.nameInput:SetScript("OnEnterPressed", function()
        if self["_refreshing" .. prefix .. "Inspector"] then
            return
        end

        commitSelectedDefinition(self, collectionKey, function(definition)
            definition.name = widgets.nameInput:GetText()
        end)
    end)
    widgets.nameInput:SetScript("OnEditFocusLost", function()
        if self["_refreshing" .. prefix .. "Inspector"] then
            return
        end

        commitSelectedDefinition(self, collectionKey, function(definition)
            definition.name = widgets.nameInput:GetText()
        end)
    end)
    root:AddChild(widgets.nameInput)

    widgets.idText = UI.CreateText(root:GetFrame(), "RPEDataEditor" .. prefix .. "InspectorIdText", "ID: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
    root:AddChild(widgets.idText)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditor" .. prefix .. "InspectorIconLabel", "Icon"))
    widgets.iconField = UI.EditorIconField:New({
        name = "RPEDataEditor" .. prefix .. "InspectorIconField",
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    widgets.iconField:SetParent(root:GetFrame())
    widgets.iconField:Create()

    local iconButton = widgets.iconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local _, definition = getSelectedDefinition(self, collectionKey)
            if not definition or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                commitSelectedDefinition(self, collectionKey, function(selectedDefinition)
                    selectedDefinition.icon = filePath or ""
                end)
            end, {
                filter = definition.icon or "",
            })
        end)
    end
    root:AddChild(widgets.iconField)

    widgets.iconInput = {
        SetText = function(_, value)
            local iconPath = ensureString(value)
            widgets.iconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            widgets.iconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            widgets.iconField:SetEnabled(enabled == true)
        end,
        SetReadOnly = function(_, readOnly)
            widgets.iconField:SetEnabled(readOnly ~= true)
        end,
    }

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditor" .. prefix .. "InspectorDescriptionLabel", "Description"))
    widgets.descriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditor" .. prefix .. "InspectorDescriptionInput", {
        width = FIELD_WIDTH,
        height = 112,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    widgets.descriptionInput:SetScript("OnEditFocusLost", function()
        if self["_refreshing" .. prefix .. "Inspector"] then
            return
        end

        commitSelectedDefinition(self, collectionKey, function(definition)
            definition.description = widgets.descriptionInput:GetText()
        end)
    end)
    root:AddChild(widgets.descriptionInput)
end

local function buildProgressionPage(self, page, collectionKey, title, progressionKey, refKey, refCollection)
    local prefix = getInspectorPrefix(collectionKey)
    local widgets = getWidgets(self, collectionKey)
    local editorPrefix = progressionKey == "statProgressions" and "pendingStat" or "pendingResource"

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditor" .. prefix .. progressionKey .. "Layout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditor" .. prefix .. progressionKey .. "Title", title))

    local panel = UI.CreatePanel(root:GetFrame(), "RPEDataEditor" .. prefix .. progressionKey .. "Panel", {
        width = FIELD_WIDTH,
        height = 144,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(panel)

    local scroll = UI.ScrollLayout:New({
        name = "RPEDataEditor" .. prefix .. progressionKey .. "Scroll",
        width = FIELD_WIDTH,
        height = 142,
        visibleRows = 8,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    scroll:SetParent(panel:GetContentFrame())
    scroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "refText", width = 140, justifyH = "LEFT" },
                { key = "initialValueText", width = 42, justifyH = "RIGHT" },
                { key = "perLevelValueText", width = 42, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "LeftButton" then
                    setSelectedProgressionIndex(self, collectionKey, progressionKey, rowData and rowData.rowIndex or nil)
                    refreshProgressionEditor(self, collectionKey, progressionKey, refKey)
                elseif button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    showProgressionContextMenu(self, collectionKey, progressionKey, anchor, rowData)
                end
            end)
        end
    end)
    scroll:Create()
    UI.Utils.AnchorFill(scroll, panel:GetContentFrame(), 0, 0, 0, 0)
    widgets[progressionKey == "statProgressions" and "statScroll" or "resourceScroll"] = scroll

    local editorRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditor" .. prefix .. progressionKey .. "EditorRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    root:AddChild(editorRow)

    widgets[editorPrefix .. "RefDropdown"] = UI.CreateDropdown(editorRow:GetFrame(), "RPEDataEditor" .. prefix .. progressionKey .. "RefDropdown", {
        width = 96,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = buildRefItems(self, refCollection),
    })
    editorRow:AddChild(widgets[editorPrefix .. "RefDropdown"])

    widgets[editorPrefix .. "InitialInput"] = UI.CreateTextInput(editorRow:GetFrame(), "RPEDataEditor" .. prefix .. progressionKey .. "InitialInput", {
        width = 40,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    editorRow:AddChild(widgets[editorPrefix .. "InitialInput"])

    widgets[editorPrefix .. "PerLevelInput"] = UI.CreateTextInput(editorRow:GetFrame(), "RPEDataEditor" .. prefix .. progressionKey .. "PerLevelInput", {
        width = 40,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    editorRow:AddChild(widgets[editorPrefix .. "PerLevelInput"])

    widgets[editorPrefix .. "SaveButton"] = UI.CreateButton(editorRow:GetFrame(), "RPEDataEditor" .. prefix .. progressionKey .. "SaveButton", "Add", 44, function()
        if self["_refreshing" .. prefix .. "Inspector"] then
            return
        end

        local reference = widgets[editorPrefix .. "RefDropdown"] and widgets[editorPrefix .. "RefDropdown"].GetSelectedValue and widgets[editorPrefix .. "RefDropdown"]:GetSelectedValue() or ""
        if reference == "" then
            return
        end

        local _, selectedIndex = getSelectedProgressionEntry(self, collectionKey, progressionKey)
        if hasDuplicateProgressionRef(self, collectionKey, progressionKey, refKey, reference, selectedIndex) then
            return
        end

        local initialValue = tonumber(widgets[editorPrefix .. "InitialInput"] and widgets[editorPrefix .. "InitialInput"]:GetText()) or 0
        local perLevelValue = tonumber(widgets[editorPrefix .. "PerLevelInput"] and widgets[editorPrefix .. "PerLevelInput"]:GetText()) or 0

        commitSelectedDefinition(self, collectionKey, function(definition)
            definition[progressionKey] = definition[progressionKey] or {}
            local entry = {
                [refKey] = reference,
                initialValue = initialValue,
                perLevelValue = perLevelValue,
            }

            if selectedIndex and definition[progressionKey][selectedIndex] then
                definition[progressionKey][selectedIndex] = entry
            else
                definition[progressionKey][#definition[progressionKey] + 1] = entry
            end
        end)
        setSelectedProgressionIndex(self, collectionKey, progressionKey, nil)
    end, {
        height = 18,
        fontSize = 7,
    })
    editorRow:AddChild(widgets[editorPrefix .. "SaveButton"])

    local actionRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditor" .. prefix .. progressionKey .. "ActionRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    root:AddChild(actionRow)

    widgets[editorPrefix .. "RemoveButton"] = UI.CreateButton(actionRow:GetFrame(), "RPEDataEditor" .. prefix .. progressionKey .. "RemoveButton", "Remove Selected", 92, function()
        local _, removeIndex = getSelectedProgressionEntry(self, collectionKey, progressionKey)
        if not removeIndex then
            return
        end

        commitSelectedDefinition(self, collectionKey, function(definition)
            table.remove(definition[progressionKey] or {}, removeIndex)
        end)
        setSelectedProgressionIndex(self, collectionKey, progressionKey, nil)
    end, {
        height = 18,
        fontSize = 7,
    })
    actionRow:AddChild(widgets[editorPrefix .. "RemoveButton"])

    local hintText = UI.CreateText(actionRow:GetFrame(), "RPEDataEditor" .. prefix .. progressionKey .. "Hint", "Left-click to edit. Right-click to remove.", {
        width = 64,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
        expandWidth = true,
        weight = 1,
    })
    actionRow:AddChild(hintText)
end

local function buildTraitRefsPage(self, page, collectionKey)
    local prefix = getInspectorPrefix(collectionKey)
    local widgets = getWidgets(self, collectionKey)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditor" .. prefix .. "TraitRefsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditor" .. prefix .. "TraitRefsTitle", "Assigned Traits"))

    local panel = UI.CreatePanel(root:GetFrame(), "RPEDataEditor" .. prefix .. "TraitRefsPanel", {
        width = FIELD_WIDTH,
        height = 144,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(panel)

    local scroll = UI.ScrollLayout:New({
        name = "RPEDataEditor" .. prefix .. "TraitRefsScroll",
        width = FIELD_WIDTH,
        height = 142,
        visibleRows = 8,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    scroll:SetParent(panel:GetContentFrame())
    scroll:SetRowRenderer(function(row, item)
        if row.SetColumns then
            row:SetColumns({
                { key = "refText", width = 224, justifyH = "LEFT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, item and item.rowIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "LeftButton" then
                    setSelectedProgressionIndex(self, collectionKey, "traitRefs", rowData and rowData.rowIndex or nil)
                    refreshTraitRefEditor(self, collectionKey)
                elseif button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    showProgressionContextMenu(self, collectionKey, "traitRefs", anchor, rowData)
                end
            end)
        end
    end)
    scroll:Create()
    UI.Utils.AnchorFill(scroll, panel:GetContentFrame(), 0, 0, 0, 0)
    widgets.traitsScroll = scroll

    local editorRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditor" .. prefix .. "TraitRefsEditorRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    root:AddChild(editorRow)

    widgets.pendingTraitRefDropdown = UI.CreateDropdown(editorRow:GetFrame(), "RPEDataEditor" .. prefix .. "TraitRefsDropdown", {
        width = 96,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = buildRefItems(self, "traits"),
    })
    editorRow:AddChild(widgets.pendingTraitRefDropdown)

    widgets.pendingTraitSaveButton = UI.CreateButton(editorRow:GetFrame(), "RPEDataEditor" .. prefix .. "TraitRefsSaveButton", "Add", 44, function()
        if self["_refreshing" .. prefix .. "Inspector"] then
            return
        end

        local traitRef = widgets.pendingTraitRefDropdown and widgets.pendingTraitRefDropdown.GetSelectedValue and widgets.pendingTraitRefDropdown:GetSelectedValue() or ""
        if traitRef == "" then
            return
        end

        local _, selectedIndex = getSelectedProgressionEntry(self, collectionKey, "traitRefs")
        if hasDuplicateTraitRef(self, collectionKey, traitRef, selectedIndex) then
            return
        end

        commitSelectedDefinition(self, collectionKey, function(definition)
            definition.traitRefs = definition.traitRefs or {}
            if selectedIndex and definition.traitRefs[selectedIndex] then
                definition.traitRefs[selectedIndex] = traitRef
            else
                definition.traitRefs[#definition.traitRefs + 1] = traitRef
            end
        end)
        setSelectedProgressionIndex(self, collectionKey, "traitRefs", nil)
    end, {
        height = 18,
        fontSize = 7,
    })
    editorRow:AddChild(widgets.pendingTraitSaveButton)

    local actionRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditor" .. prefix .. "TraitRefsActionRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    root:AddChild(actionRow)

    widgets.pendingTraitRemoveButton = UI.CreateButton(actionRow:GetFrame(), "RPEDataEditor" .. prefix .. "TraitRefsRemoveButton", "Remove Selected", 92, function()
        local _, removeIndex = getSelectedProgressionEntry(self, collectionKey, "traitRefs")
        if not removeIndex then
            return
        end

        commitSelectedDefinition(self, collectionKey, function(definition)
            table.remove(definition.traitRefs or {}, removeIndex)
        end)
        setSelectedProgressionIndex(self, collectionKey, "traitRefs", nil)
    end, {
        height = 18,
        fontSize = 7,
    })
    actionRow:AddChild(widgets.pendingTraitRemoveButton)

    local hintText = UI.CreateText(actionRow:GetFrame(), "RPEDataEditor" .. prefix .. "TraitRefsHint", "Left-click to edit. Right-click to remove.", {
        width = 64,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
        expandWidth = true,
        weight = 1,
    })
    actionRow:AddChild(hintText)
end

local function buildSkillBonusesPage(self, page, collectionKey)
    local prefix = getInspectorPrefix(collectionKey)
    local widgets = getWidgets(self, collectionKey)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditor" .. prefix .. "SkillBonusesLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditor" .. prefix .. "SkillBonusesTitle", "Skill Bonuses"))

    local panel = UI.CreatePanel(root:GetFrame(), "RPEDataEditor" .. prefix .. "SkillBonusesPanel", {
        width = FIELD_WIDTH,
        height = 144,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(panel)

    local scroll = UI.ScrollLayout:New({
        name = "RPEDataEditor" .. prefix .. "SkillBonusesScroll",
        width = FIELD_WIDTH,
        height = 142,
        visibleRows = 8,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    scroll:SetParent(panel:GetContentFrame())
    scroll:SetRowRenderer(function(row, item)
        if row.SetColumns then
            row:SetColumns({
                { key = "refText", width = 184, justifyH = "LEFT" },
                { key = "valueText", width = 40, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, item and item.rowIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(_, button, rowData)
                if button == "LeftButton" then
                    setSelectedProgressionIndex(self, collectionKey, "skillBonuses", rowData and rowData.rowIndex or nil)
                    refreshSkillBonusEditor(self, collectionKey)
                elseif button == "RightButton" then
                    setSelectedProgressionIndex(self, collectionKey, "skillBonuses", rowData and rowData.rowIndex or nil)
                    refreshSkillBonusEditor(self, collectionKey)
                end
            end)
        end
    end)
    scroll:Create()
    UI.Utils.AnchorFill(scroll, panel:GetContentFrame(), 0, 0, 0, 0)
    widgets.skillsScroll = scroll

    local editorRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditor" .. prefix .. "SkillBonusesEditorRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    root:AddChild(editorRow)

    widgets.pendingSkillRefDropdown = UI.CreateDropdown(editorRow:GetFrame(), "RPEDataEditor" .. prefix .. "SkillBonusesDropdown", {
        width = 96,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = buildRefItems(self, "skills"),
    })
    editorRow:AddChild(widgets.pendingSkillRefDropdown)

    widgets.pendingSkillValueInput = UI.CreateTextInput(editorRow:GetFrame(), "RPEDataEditor" .. prefix .. "SkillBonusesValueInput", {
        width = 34,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    editorRow:AddChild(widgets.pendingSkillValueInput)

    widgets.pendingSkillSaveButton = UI.CreateButton(editorRow:GetFrame(), "RPEDataEditor" .. prefix .. "SkillBonusesSaveButton", "Add", 42, function()
        if self["_refreshing" .. prefix .. "Inspector"] then
            return
        end

        local skillRef = widgets.pendingSkillRefDropdown and widgets.pendingSkillRefDropdown.GetSelectedValue and widgets.pendingSkillRefDropdown:GetSelectedValue() or ""
        if skillRef == "" then
            return
        end

        local _, selectedIndex = getSelectedProgressionEntry(self, collectionKey, "skillBonuses")
        local value = tonumber(widgets.pendingSkillValueInput and widgets.pendingSkillValueInput:GetText()) or 0

        commitSelectedDefinition(self, collectionKey, function(definition)
            definition.skillBonuses = definition.skillBonuses or {}
            local entry = {
                skillRef = skillRef,
                value = value,
            }

            if selectedIndex and definition.skillBonuses[selectedIndex] then
                definition.skillBonuses[selectedIndex] = entry
            else
                definition.skillBonuses[#definition.skillBonuses + 1] = entry
            end
        end)
        setSelectedProgressionIndex(self, collectionKey, "skillBonuses", nil)
    end, {
        height = 18,
        fontSize = 7,
    })
    editorRow:AddChild(widgets.pendingSkillSaveButton)

    local actionRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditor" .. prefix .. "SkillBonusesActionRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    root:AddChild(actionRow)

    widgets.pendingSkillRemoveButton = UI.CreateButton(actionRow:GetFrame(), "RPEDataEditor" .. prefix .. "SkillBonusesRemoveButton", "Remove Selected", 92, function()
        local _, removeIndex = getSelectedProgressionEntry(self, collectionKey, "skillBonuses")
        if not removeIndex then
            return
        end

        commitSelectedDefinition(self, collectionKey, function(definition)
            table.remove(definition.skillBonuses or {}, removeIndex)
        end)
        setSelectedProgressionIndex(self, collectionKey, "skillBonuses", nil)
    end, {
        height = 18,
        fontSize = 7,
    })
    actionRow:AddChild(widgets.pendingSkillRemoveButton)

    local hintText = UI.CreateText(actionRow:GetFrame(), "RPEDataEditor" .. prefix .. "SkillBonusesHint", "Select a row to edit it.", {
        width = 64,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
        expandWidth = true,
        weight = 1,
    })
    actionRow:AddChild(hintText)
end

local function buildInspector(self, parent, collectionKey)
    local prefix = getInspectorPrefix(collectionKey)
    local pageKey = prefix .. "InspectorPage"
    if self[pageKey] then
        self:RefreshProgressionDefinitionInspectorPage(collectionKey)
        return self[pageKey]
    end

    self[pageKey] = CreateFrame("Frame", "RPEDataEditor" .. prefix .. "InspectorPage", parent)
    self[prefix .. "InspectorWidgets"] = self[prefix .. "InspectorWidgets"] or {}

    local selectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self[pageKey], "RPEDataEditor" .. prefix .. "InspectorSelectorBar", {
        spacing = 4,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    selectorBar:GetFrame():SetPoint("TOPLEFT", self[pageKey], "TOPLEFT", 0, 0)
    selectorBar:GetFrame():SetPoint("TOPRIGHT", self[pageKey], "TOPRIGHT", 0, 0)
    self[prefix .. "InspectorSelectorBar"] = selectorBar

    self[prefix .. "InspectorPreviousButton"] = UI.CreateButton(selectorBar:GetFrame(), "RPEDataEditor" .. prefix .. "InspectorPreviousButton", "Prev", 42, function()
        local pageDefinitions = self:GetProgressionDefinitionInspectorPageDefinitions()
        self:SetProgressionDefinitionInspectorTab(collectionKey, (pageDefinitions[(self["Active" .. prefix .. "InspectorPageIndex"] or 1) - 1] or {}).key or "general")
    end, {
        height = 18,
        fontSize = 8,
    })
    selectorBar:AddChild(self[prefix .. "InspectorPreviousButton"])

    self[prefix .. "InspectorPageDropdown"] = UI.CreateDropdown(selectorBar:GetFrame(), "RPEDataEditor" .. prefix .. "InspectorPageDropdown", {
        width = 132,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildProgressionDefinitionInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if self["_refreshing" .. prefix .. "InspectorPageSelector"] then
                return
            end

            self:SetProgressionDefinitionInspectorTab(collectionKey, value)
        end,
    })
    selectorBar:AddChild(self[prefix .. "InspectorPageDropdown"])

    self[prefix .. "InspectorNextButton"] = UI.CreateButton(selectorBar:GetFrame(), "RPEDataEditor" .. prefix .. "InspectorNextButton", "Next", 42, function()
        local pageDefinitions = self:GetProgressionDefinitionInspectorPageDefinitions()
        self:SetProgressionDefinitionInspectorTab(collectionKey, (pageDefinitions[(self["Active" .. prefix .. "InspectorPageIndex"] or 1) + 1] or {}).key or "resources")
    end, {
        height = 18,
        fontSize = 8,
    })
    selectorBar:AddChild(self[prefix .. "InspectorNextButton"])

    local function createPage(name)
        local frame = CreateFrame("Frame", name, self[pageKey])
        frame:SetPoint("TOPLEFT", self[pageKey], "TOPLEFT", INSPECTOR_SIDE_PADDING, -24)
        frame:SetPoint("TOPRIGHT", self[pageKey], "TOPRIGHT", -INSPECTOR_SIDE_PADDING, -24)
        frame:SetPoint("BOTTOMLEFT", self[pageKey], "BOTTOMLEFT", INSPECTOR_SIDE_PADDING, 24)
        frame:SetPoint("BOTTOMRIGHT", self[pageKey], "BOTTOMRIGHT", -INSPECTOR_SIDE_PADDING, 24)
        return frame
    end

    self[prefix .. "InspectorGeneralPage"] = createPage("RPEDataEditor" .. prefix .. "InspectorGeneralPage")
    buildGeneralPage(self, self[prefix .. "InspectorGeneralPage"], collectionKey)

    self[prefix .. "InspectorStatsPage"] = createPage("RPEDataEditor" .. prefix .. "InspectorStatsPage")
    buildProgressionPage(self, self[prefix .. "InspectorStatsPage"], collectionKey, "Stat Progressions", "statProgressions", "statRef", "stats")

    self[prefix .. "InspectorResourcesPage"] = createPage("RPEDataEditor" .. prefix .. "InspectorResourcesPage")
    buildProgressionPage(self, self[prefix .. "InspectorResourcesPage"], collectionKey, "Resource Progressions", "resourceProgressions", "resourceRef", "resources")

    self[prefix .. "InspectorSkillsPage"] = createPage("RPEDataEditor" .. prefix .. "InspectorSkillsPage")
    buildSkillBonusesPage(self, self[prefix .. "InspectorSkillsPage"], collectionKey)

    self[prefix .. "InspectorTraitsPage"] = createPage("RPEDataEditor" .. prefix .. "InspectorTraitsPage")
    buildTraitRefsPage(self, self[prefix .. "InspectorTraitsPage"], collectionKey)

    self[prefix .. "InspectorEmptyText"] = UI.CreateText(self[pageKey], "RPEDataEditor" .. prefix .. "InspectorEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = FIELD_WIDTH,
        height = 20,
        justifyH = "LEFT",
    })
    self[prefix .. "InspectorEmptyText"]:GetFrame():SetPoint("BOTTOMLEFT", self[pageKey], "BOTTOMLEFT", 0, 0)

    self:SetProgressionDefinitionInspectorTab(collectionKey, "general")
    self:RefreshProgressionDefinitionInspectorPage(collectionKey)
    return self[pageKey]
end

function DataEditor:BuildProgressionDefinitionInspectorPage(parent, collectionKey)
    return buildInspector(self, parent, collectionKey)
end

function DataEditor:BuildRaceInspectorPage(parent)
    return self:BuildProgressionDefinitionInspectorPage(parent, "races")
end

function DataEditor:RefreshRaceInspectorPage()
    self:RefreshProgressionDefinitionInspectorPage("races")
end
