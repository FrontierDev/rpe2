local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Ruleset = Addon.Client.UI.Ruleset or {}

local RulesetWindow = Addon.Client.UI.Ruleset
local UI = Addon.UI or {}
local RulesetLogic = Addon.Internal and Addon.Internal.Ruleset or {}

local INSPECTOR_SIDE_PADDING = 8
local TABLE_WIDTH = 368
local TABLE_HEIGHT = 220
local TABLE_VISIBLE_ROWS = 10
local TABLE_ROW_HEIGHT = 18
local TOOLBAR_HEIGHT = 20
local EDITOR_WIDTH = 170
local RULE_DROPDOWN_WIDTH = 160
local getActiveCategoryDefinition

getActiveCategoryDefinition = function(self)
    local categoryKey = self.ActiveRulesetCategoryKey or RulesetLogic.GetDefaultRulesetCategoryKey()
    return RulesetLogic.GetRulesetCategoryDefinition(categoryKey)
end

local function ensureSelectedRuleDefinition(self)
    local categoryDefinition = getActiveCategoryDefinition(self)
    local ruleDefinition = RulesetLogic.GetRulesetRuleDefinition(categoryDefinition and categoryDefinition.key or nil, self.SelectedRulesetRuleKey)
    if ruleDefinition then
        return ruleDefinition
    end

    self.SelectedRulesetRuleKey = RulesetLogic.GetDefaultRulesetRuleKey(categoryDefinition and categoryDefinition.key or nil)
    return RulesetLogic.GetRulesetRuleDefinition(categoryDefinition and categoryDefinition.key or nil, self.SelectedRulesetRuleKey)
end

local function buildCategorySelectorItems()
    local items = {}
    local definitions = RulesetLogic.GetRulesetCategoryDefinitions()

    for index = 1, #definitions do
        items[#items + 1] = {
            label = definitions[index].label,
            value = definitions[index].key,
        }
    end

    return items
end

local function buildRuleDropdownItems(self)
    local items = {}
    local categoryDefinition = getActiveCategoryDefinition(self)
    local rules = categoryDefinition and categoryDefinition.rules or {}

    for index = 1, #rules do
        items[#items + 1] = {
            label = rules[index].label,
            value = rules[index].key,
        }
    end

    return items
end

local function getRuleValueLabel(ruleDefinition, value)
    if not ruleDefinition then
        return "-"
    end

    if ruleDefinition.type == "checkbox" then
        return value == true and "True" or "False"
    end

    if ruleDefinition.type == "dropdown" then
        local options = RulesetLogic.GetRulesetRuleOptions(ruleDefinition)
        if ruleDefinition.multiSelect == true then
            local values = type(value) == "table" and value or {}
            local labels = {}

            for valueIndex = 1, #values do
                local selectedValue = values[valueIndex]
                for optionIndex = 1, #options do
                    if options[optionIndex].value == selectedValue then
                        labels[#labels + 1] = options[optionIndex].label
                        break
                    end
                end
            end

            if #labels > 0 then
                return table.concat(labels, ", ")
            end

            return "None"
        end

        for index = 1, #options do
            if options[index].value == value then
                return options[index].label
            end
        end

        return value ~= nil and tostring(value) ~= "" and tostring(value) or "None"
    end

    return value ~= nil and tostring(value) or ""
end

local function buildTableRows(self)
    local categoryDefinition = getActiveCategoryDefinition(self)
    local ruleset = self:GetSelectedRuleset()
    local rows = {}
    local rules = categoryDefinition and categoryDefinition.rules or {}

    for index = 1, #rules do
        local ruleDefinition = rules[index]
        local value = RulesetLogic.GetRulesetRuleValue(ruleset, categoryDefinition.key, ruleDefinition)
        rows[#rows + 1] = {
            key = ruleDefinition.key,
            ruleLabel = ruleDefinition.label,
            valueLabel = getRuleValueLabel(ruleDefinition, value),
            description = ruleDefinition.description or "",
        }
    end

    return rows
end

local function refreshRulesetTable(self)
    if self.RulesetInspectorTable and self.RulesetInspectorTable.SetRows then
        self.RulesetInspectorTable:SetRows(buildTableRows(self))
        self:RefreshRulesetTableRowSelection()
    end
end

local function buildLayout(parent, name, spacing, height)
    return UI.CreateLayout(UI.VerticalLayoutGroup, parent, name, {
        spacing = spacing or 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = height,
    })
end

local function buildHorizontalLayout(parent, name, spacing, height)
    return UI.CreateLayout(UI.HorizontalLayoutGroup, parent, name, {
        spacing = spacing or 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = height,
    })
end

local function buildCheckbox(parent, name, text, onValueChanged)
    local checkbox = UI.Checkbox:New({
        name = name,
        width = EDITOR_WIDTH,
        height = 18,
        text = text,
        checked = false,
        border = false,
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Checkbox) or 8,
        labelColor = UI.ResolveColor(nil, "text.primary"),
        onValueChanged = onValueChanged,
    })
    checkbox:SetParent(parent)
    checkbox:Create()
    return checkbox
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

local function setCheckboxEnabled(checkbox, enabled)
    if not checkbox then
        return
    end

    local frame = checkbox.GetFrame and checkbox:GetFrame() or nil
    if frame and frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end
    if frame and frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
end

local function setTextInputEnabled(input, enabled)
    if not input then
        return
    end

    if input.SetEnabled then
        input:SetEnabled(enabled == true)
    end
    if input.SetReadOnly then
        input:SetReadOnly(enabled ~= true)
    end
end

function RulesetWindow:RefreshRulesetCategorySelector()
    local definitions = RulesetLogic.GetRulesetCategoryDefinitions()
    local activeIndex = RulesetLogic.GetRulesetCategoryIndexByKey(self.ActiveRulesetCategoryKey)

    if self.RulesetInspectorCategoryDropdown and definitions[activeIndex] then
        self._refreshingRulesetCategoryDropdown = true
        self.RulesetInspectorCategoryDropdown:SetSelectedValue(definitions[activeIndex].key, true)
        self._refreshingRulesetCategoryDropdown = false
    end

    if self.RulesetInspectorPreviousButton and self.RulesetInspectorPreviousButton.SetEnabled then
        self.RulesetInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end

    if self.RulesetInspectorNextButton and self.RulesetInspectorNextButton.SetEnabled then
        self.RulesetInspectorNextButton:SetEnabled(activeIndex < #definitions)
    end
end

function RulesetWindow:RefreshRulesetTableRowSelection()
    local rows = self.RulesetInspectorTable and self.RulesetInspectorTable.bodyScroll and self.RulesetInspectorTable.bodyScroll.rows or nil
    if not rows then
        return
    end

    for index = 1, #rows do
        local row = rows[index]
        local isSelected = row and row.rowData and row.rowData.key == self.SelectedRulesetRuleKey
        if row and row.background and row.background.SetColorTexture then
            local token = isSelected and "list.rowHover" or "list.rowBackground"
            local color = UI.ResolveColor(nil, token)
            row.background:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
        end
        if row and row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(_, button, rowData)
                if button == "LeftButton" and rowData and rowData.key then
                    self:SetSelectedRulesetRuleKey(rowData.key)
                end
            end)
        end
    end
end

local function buildCategoryToolbar(self, parent)
    local toolbar = buildHorizontalLayout(parent, "RPERulesetInspectorCategoryToolbar", 4, TOOLBAR_HEIGHT)

    self.RulesetInspectorPreviousButton = UI.CreateButton(toolbar:GetFrame(), "RPERulesetInspectorPreviousButton", "Prev", 42, function()
        self:SetActiveRulesetCategory(RulesetLogic.GetRulesetCategoryIndexByKey(self.ActiveRulesetCategoryKey) - 1)
    end, {
        height = 20,
        fontSize = 7,
    })
    toolbar:AddChild(self.RulesetInspectorPreviousButton)

    self.RulesetInspectorCategoryDropdown = UI.CreateDropdown(toolbar:GetFrame(), "RPERulesetInspectorCategoryDropdown", {
        width = 132,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = buildCategorySelectorItems(),
        onValueChanged = function(value)
            if self._refreshingRulesetCategoryDropdown then
                return
            end

            self:SetActiveRulesetCategory(RulesetLogic.GetRulesetCategoryIndexByKey(value))
        end,
    })
    toolbar:AddChild(self.RulesetInspectorCategoryDropdown)

    self.RulesetInspectorNextButton = UI.CreateButton(toolbar:GetFrame(), "RPERulesetInspectorNextButton", "Next", 42, function()
        self:SetActiveRulesetCategory(RulesetLogic.GetRulesetCategoryIndexByKey(self.ActiveRulesetCategoryKey) + 1)
    end, {
        height = 20,
        fontSize = 7,
    })
    toolbar:AddChild(self.RulesetInspectorNextButton)

    return toolbar
end

local function buildTablePanel(self, parent)
    local panel = UI.CreatePanel(parent, "RPERulesetInspectorTablePanel", {
        width = TABLE_WIDTH + 4,
        height = TABLE_HEIGHT,
        contentInset = 2,
        showBorder = false,
    })

    self.RulesetInspectorTable = UI.Table:New({
        name = "RPERulesetInspectorTable",
        width = TABLE_WIDTH,
        height = TABLE_HEIGHT,
        visibleRows = TABLE_VISIBLE_ROWS,
        rowHeight = TABLE_ROW_HEIGHT,
        showColumnHeaders = true,
        border = false,
        columns = {
            {
                key = "ruleLabel",
                label = "Rule",
                width = 180,
                sortable = true,
                cellTooltip = function(_, row)
                    return {
                        title = row.ruleLabel,
                        lines = { tostring(row.description or "") },
                    }
                end,
            },
            {
                key = "valueLabel",
                label = "Value",
                width = 180,
                sortable = true,
                cellTooltip = function(_, row)
                    return {
                        title = row.ruleLabel,
                        lines = { tostring(row.description or "") },
                    }
                end,
            },
        },
        rows = {},
    })
    self.RulesetInspectorTable:SetParent(panel:GetContentFrame())
    self.RulesetInspectorTable:Create()
    self.RulesetInspectorTable:GetFrame():SetPoint("TOPLEFT", panel:GetContentFrame(), "TOPLEFT", 0, 0)

    return panel
end

local function commitSelectedRuleValue(self)
    local categoryDefinition = getActiveCategoryDefinition(self)
    local ruleDefinition = ensureSelectedRuleDefinition(self)
    local ruleset = self:GetSelectedRuleset()
    if not (categoryDefinition and ruleDefinition and ruleset) then
        return
    end

    local value = nil
    if ruleDefinition.type == "checkbox" then
        value = self.RulesetInspectorValueCheckbox and self.RulesetInspectorValueCheckbox.GetChecked and self.RulesetInspectorValueCheckbox:GetChecked() == true or false
    elseif ruleDefinition.type == "dropdown" then
        if ruleDefinition.multiSelect == true then
            value = self.RulesetInspectorValueDropdown and self.RulesetInspectorValueDropdown.GetSelectedValues and self.RulesetInspectorValueDropdown:GetSelectedValues() or {}
        else
            value = self.RulesetInspectorValueDropdown and self.RulesetInspectorValueDropdown.GetSelectedValue and self.RulesetInspectorValueDropdown:GetSelectedValue() or ""
        end
    else
        value = self.RulesetInspectorValueInput and self.RulesetInspectorValueInput.GetText and self.RulesetInspectorValueInput:GetText() or ""
    end

    RulesetLogic.SetRulesetRuleValue(ruleset.id, categoryDefinition.key, ruleDefinition, value)
    if RulesetLogic.SetActiveRulesetId then
        RulesetLogic.SetActiveRulesetId(ruleset.id)
    end
    self:RefreshRulesetInspectorPage()
end

local function buildEditorToolbar(self, parent)
    local toolbar = buildHorizontalLayout(parent, "RPERulesetInspectorEditorToolbar", 4, TOOLBAR_HEIGHT)

    self.RulesetInspectorRuleDropdown = UI.CreateDropdown(toolbar:GetFrame(), "RPERulesetInspectorRuleDropdown", {
        width = RULE_DROPDOWN_WIDTH,
        height = 18,
        items = {},
        onValueChanged = function(value)
            if self._refreshingRulesetRuleDropdown then
                return
            end

            self:SetSelectedRulesetRuleKey(value)
        end,
    })
    toolbar:AddChild(self.RulesetInspectorRuleDropdown)

    self.RulesetInspectorValueHost = UI.CreatePanel(toolbar:GetFrame(), "RPERulesetInspectorValueHost", {
        width = EDITOR_WIDTH,
        height = 20,
        contentInset = 0,
        showBorder = false,
    })
    toolbar:AddChild(self.RulesetInspectorValueHost)

    local valueHost = self.RulesetInspectorValueHost:GetContentFrame()

    self.RulesetInspectorValueInput = UI.CreateTextInput(valueHost, "RPERulesetInspectorValueInput", {
        width = EDITOR_WIDTH,
        height = 20,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    UI.Utils.AnchorFill(self.RulesetInspectorValueInput, valueHost, 0, 0, 0, 0)

    self.RulesetInspectorValueDropdown = UI.CreateDropdown(valueHost, "RPERulesetInspectorValueDropdown", {
        width = EDITOR_WIDTH,
        height = 18,
        items = {},
        onValueChanged = function() end,
    })
    UI.Utils.AnchorFill(self.RulesetInspectorValueDropdown, valueHost, 0, 0, 0, 1)

    self.RulesetInspectorValueCheckbox = buildCheckbox(valueHost, "RPERulesetInspectorValueCheckbox", "Enabled", function() end)
    local checkboxFrame = self.RulesetInspectorValueCheckbox.GetFrame and self.RulesetInspectorValueCheckbox:GetFrame() or nil
    if checkboxFrame then
        checkboxFrame:SetPoint("TOPLEFT", valueHost, "TOPLEFT", 0, 0)
        checkboxFrame:SetPoint("BOTTOMLEFT", valueHost, "BOTTOMLEFT", 0, 0)
        checkboxFrame:SetPoint("RIGHT", valueHost, "RIGHT", 0, 0)
    end

    self.RulesetInspectorApplyButton = UI.CreateButton(toolbar:GetFrame(), "RPERulesetInspectorApplyButton", "Apply", 52, function()
        commitSelectedRuleValue(self)
    end, {
        height = 20,
        fontSize = 7,
    })
    toolbar:AddChild(self.RulesetInspectorApplyButton)

    return toolbar
end

function RulesetWindow:BuildRulesetInspectorPage(parent)
    if self.RulesetInspectorPage then
        return self.RulesetInspectorPage
    end

    self.RulesetInspectorPage = CreateFrame("Frame", "RPERulesetInspectorPage", parent)

    local root = buildLayout(self.RulesetInspectorPage, "RPERulesetInspectorLayout", 6)
    UI.Utils.AnchorFill(root, self.RulesetInspectorPage, INSPECTOR_SIDE_PADDING, 0, INSPECTOR_SIDE_PADDING, 0)

    self.RulesetInspectorCategoryToolbar = buildCategoryToolbar(self, root:GetFrame())
    root:AddChild(self.RulesetInspectorCategoryToolbar)

    self.RulesetInspectorTablePanel = buildTablePanel(self, root:GetFrame())
    root:AddChild(self.RulesetInspectorTablePanel)

    self.RulesetInspectorEditorToolbar = buildEditorToolbar(self, root:GetFrame())
    root:AddChild(self.RulesetInspectorEditorToolbar)

    self.ActiveRulesetCategoryKey = self.ActiveRulesetCategoryKey or RulesetLogic.GetDefaultRulesetCategoryKey()
    self:RefreshRulesetInspectorPage()
    return self.RulesetInspectorPage
end

function RulesetWindow:RefreshRulesetInspectorPage()
    local ruleset = self:GetSelectedRuleset()
    local categoryDefinition = getActiveCategoryDefinition(self)
    local ruleDefinition = ensureSelectedRuleDefinition(self)
    local value = categoryDefinition and ruleDefinition and RulesetLogic.GetRulesetRuleValue(ruleset, categoryDefinition.key, ruleDefinition) or nil
    local hasRuleset = ruleset ~= nil

    refreshRulesetTable(self)

    self:RefreshRulesetCategorySelector()

    if self.RulesetInspectorRuleDropdown then
        self._refreshingRulesetRuleDropdown = true
        self.RulesetInspectorRuleDropdown:SetItems(buildRuleDropdownItems(self))
        self.RulesetInspectorRuleDropdown:SetSelectedValue(ruleDefinition and ruleDefinition.key or "", true)
        self._refreshingRulesetRuleDropdown = false
        setDropdownEnabled(self.RulesetInspectorRuleDropdown, hasRuleset and ruleDefinition ~= nil)
    end

    if self.RulesetInspectorValueInput then
        self.RulesetInspectorValueInput:SetText(ruleDefinition and ruleDefinition.type == "text" and tostring(value or "") or "")
        setTextInputEnabled(self.RulesetInspectorValueInput, hasRuleset and ruleDefinition and ruleDefinition.type == "text")
        local frame = self.RulesetInspectorValueInput.GetFrame and self.RulesetInspectorValueInput:GetFrame() or nil
        if frame then
            frame:SetShown(ruleDefinition and ruleDefinition.type == "text")
        end
    end

    if self.RulesetInspectorValueDropdown then
        self._refreshingRulesetValueDropdown = true
        self.RulesetInspectorValueDropdown.multiSelect = ruleDefinition and ruleDefinition.multiSelect == true or false
        self.RulesetInspectorValueDropdown:SetItems(ruleDefinition and RulesetLogic.GetRulesetRuleOptions(ruleDefinition) or {})
        if ruleDefinition and ruleDefinition.type == "dropdown" and ruleDefinition.multiSelect == true then
            self.RulesetInspectorValueDropdown:SetSelectedValues(type(value) == "table" and value or {}, true)
        else
            self.RulesetInspectorValueDropdown:SetSelectedValue(ruleDefinition and ruleDefinition.type == "dropdown" and value or "", true)
        end
        self._refreshingRulesetValueDropdown = false
        setDropdownEnabled(self.RulesetInspectorValueDropdown, hasRuleset and ruleDefinition and ruleDefinition.type == "dropdown")
        local frame = self.RulesetInspectorValueDropdown.GetFrame and self.RulesetInspectorValueDropdown:GetFrame() or nil
        if frame then
            frame:SetShown(ruleDefinition and ruleDefinition.type == "dropdown")
        end
    end

    if self.RulesetInspectorValueCheckbox then
        self._refreshingRulesetValueCheckbox = true
        self.RulesetInspectorValueCheckbox:SetText(ruleDefinition and ruleDefinition.label or "Enabled")
        self.RulesetInspectorValueCheckbox:SetChecked(ruleDefinition and ruleDefinition.type == "checkbox" and value == true or false, true)
        self._refreshingRulesetValueCheckbox = false
        setCheckboxEnabled(self.RulesetInspectorValueCheckbox, hasRuleset and ruleDefinition and ruleDefinition.type == "checkbox")
        local frame = self.RulesetInspectorValueCheckbox.GetFrame and self.RulesetInspectorValueCheckbox:GetFrame() or nil
        if frame then
            frame:SetShown(ruleDefinition and ruleDefinition.type == "checkbox")
        end
    end

    if self.RulesetInspectorApplyButton and self.RulesetInspectorApplyButton.SetEnabled then
        self.RulesetInspectorApplyButton:SetEnabled(hasRuleset and ruleDefinition ~= nil)
    end

end
