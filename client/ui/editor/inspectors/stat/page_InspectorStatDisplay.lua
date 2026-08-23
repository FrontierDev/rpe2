local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local CONTROL_HEIGHT = 20

local DISPLAY_MODE_ITEMS = {
    { label = "+X Value", value = "signed_value" },
    { label = "X Value", value = "value" },
    { label = "+X% Value", value = "signed_percent" },
    { label = "Equip", value = "equip" },
    { label = "Equip %", value = "equip_percent" },
}

local CATEGORY_ITEMS = {
    { label = "Primary", value = "Primary" },
    { label = "Secondary", value = "Secondary" },
    { label = "Melee", value = "Melee" },
    { label = "Ranged", value = "Ranged" },
    { label = "Spell", value = "Spell" },
    { label = "Defense", value = "Defense" },
    { label = "Resistances", value = "Resistances" },
    { label = "Mounted", value = "Mounted" },
    { label = "Utility", value = "Utility" },
    { label = "Special", value = "Special" },
}

local function createCheckbox(parent, name, text, checked, onValueChanged)
    local checkbox = UI.Checkbox:New({
        name = name,
        width = 236,
        height = 18,
        text = text,
        checked = checked == true,
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

function DataEditor:BuildStatInspectorDisplayPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorStatInspectorDisplayLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorDisplayModeLabel", "Display Mode"))
    self.StatInspectorDisplayModeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorStatInspectorDisplayModeDropdown", {
        width = 236,
        height = 18,
        items = DISPLAY_MODE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingStatInspector then
                return
            end

            self:CommitSelectedStatDisplayMode(value)
        end,
    })
    root:AddChild(self.StatInspectorDisplayModeDropdown)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorPriorityLabel", "Priority"))
    self.StatInspectorPriorityInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorStatInspectorPriorityInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local function commitPriority()
        if self._refreshingStatInspector then
            return
        end

        self:CommitSelectedStatPriority(self.StatInspectorPriorityInput:GetText())
    end
    self.StatInspectorPriorityInput:SetScript("OnEnterPressed", commitPriority)
    self.StatInspectorPriorityInput:SetScript("OnEditFocusLost", commitPriority)
    root:AddChild(self.StatInspectorPriorityInput)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorColorLabel", "Color"))
    self.StatInspectorSelectedColor = UI.SelectedColor:New({
        name = "RPEDataEditorStatInspectorSelectedColor",
        width = 236,
        height = CONTROL_HEIGHT,
        buttonWidth = 96,
        buttonText = "Select Color",
        border = false,
    })
    self.StatInspectorSelectedColor:SetParent(root:GetFrame())
    self.StatInspectorSelectedColor:Create()
    local colorButton = self.StatInspectorSelectedColor:GetButton()
    if colorButton and colorButton.SetScript then
        colorButton:SetScript("OnClick", function()
            self:OpenStatInspectorColorPicker()
        end)
    end
    root:AddChild(self.StatInspectorSelectedColor)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorDefenceLabel", "Defence Text"))
    self.StatInspectorDefenceLabelInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorStatInspectorDefenceLabelInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.StatInspectorDefenceLabelInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedStat(function(stat)
            stat.defenceLabel = self.StatInspectorDefenceLabelInput:GetText()
        end)
    end)
    self.StatInspectorDefenceLabelInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedStat(function(stat)
            stat.defenceLabel = self.StatInspectorDefenceLabelInput:GetText()
        end)
    end)
    root:AddChild(self.StatInspectorDefenceLabelInput)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorCategoryLabel", "Category"))
    self.StatInspectorCategoryDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorStatInspectorCategoryDropdown", {
        width = 236,
        height = 18,
        items = CATEGORY_ITEMS,
        onValueChanged = function(value)
            if self._refreshingStatInspector then
                return
            end

            self:CommitSelectedStatCategory(value)
        end,
    })
    root:AddChild(self.StatInspectorCategoryDropdown)

    self.StatInspectorVisibilityCheckbox = createCheckbox(
        root:GetFrame(),
        "RPEDataEditorStatInspectorVisibilityCheckbox",
        "Visible In Profile",
        false,
        function(value)
            if self._refreshingStatInspector then
                return
            end

            self:CommitSelectedStatVisibility(value)
        end
    )
    root:AddChild(self.StatInspectorVisibilityCheckbox)
end
