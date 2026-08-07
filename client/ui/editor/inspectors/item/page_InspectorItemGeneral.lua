local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}
local Shared = DataEditor.ItemInspectorShared or {}
local FIELD_WIDTH = Shared.FIELD_WIDTH or 236
local CONTROL_HEIGHT = Shared.CONTROL_HEIGHT or 20
local QUALITY_ITEMS = Shared.QUALITY_ITEMS or {}
local buildLabel = Shared.buildLabel
local getSelectedItemAndDataset = Shared.getSelectedItemAndDataset

local function buildGeneralPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorItemInspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorNameLabel", "Name"))
    self.ItemInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorItemInspectorNameInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorNameInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedItem(function(item)
            item.name = self.ItemInspectorNameInput:GetText()
        end)
    end)
    self.ItemInspectorNameInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            item.name = self.ItemInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.ItemInspectorNameInput)

    self.ItemInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorItemInspectorIdText", "ID: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
    root:AddChild(self.ItemInspectorIdText)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorIconLabel", "Icon"))
    self.ItemInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorItemInspectorIconField",
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.ItemInspectorIconField:SetParent(root:GetFrame())
    self.ItemInspectorIconField:Create()
    local iconButton = self.ItemInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local dataset, item = getSelectedItemAndDataset(self)
            if not dataset or not item or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedItem(function(selectedItem)
                    selectedItem.icon = filePath or ""
                end)
            end, {
                filter = item.icon or "",
            })
        end)
    end
    root:AddChild(self.ItemInspectorIconField)

    self.ItemInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.ItemInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.ItemInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.ItemInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.ItemInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorTagsLabel", "Tags"))
    self.ItemInspectorTagsInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorItemInspectorTagsInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorTagsInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedItem(function(item)
            item.tags = UI.Utils.ParseCommaSeparatedList(self.ItemInspectorTagsInput:GetText())
        end)
    end)
    self.ItemInspectorTagsInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            item.tags = UI.Utils.ParseCommaSeparatedList(self.ItemInspectorTagsInput:GetText())
        end)
    end)
    root:AddChild(self.ItemInspectorTagsInput)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorQualityLabel", "Quality"))
    self.ItemInspectorQualityDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorItemInspectorQualityDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = QUALITY_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.quality = value or "common"
            end)
        end,
    })
    root:AddChild(self.ItemInspectorQualityDropdown)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorSetKeyLabel", "Item Set Key"))
    self.ItemInspectorItemSetKeyInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorItemInspectorSetKeyInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorItemSetKeyInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedItem(function(item)
            item.itemSetKey = self.ItemInspectorItemSetKeyInput:GetText()
        end)
    end)
    self.ItemInspectorItemSetKeyInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            item.itemSetKey = self.ItemInspectorItemSetKeyInput:GetText()
        end)
    end)
    root:AddChild(self.ItemInspectorItemSetKeyInput)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorDescriptionLabel", "Description"))
    self.ItemInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorItemInspectorDescriptionInput", {
        width = FIELD_WIDTH,
        height = 64,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            item.description = self.ItemInspectorDescriptionInput:GetText()
        end)
    end)
    root:AddChild(self.ItemInspectorDescriptionInput)
end

function DataEditor:BuildItemInspectorGeneralPage(page)
    return buildGeneralPage(self, page)
end
