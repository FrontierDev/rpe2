local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}
local CONTROL_HEIGHT = 20

function DataEditor:BuildStatInspectorGeneralPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorStatInspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorNameLabel", "Name"))
    self.StatInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorStatInspectorNameInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.StatInspectorNameInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedStat(function(stat)
            stat.name = self.StatInspectorNameInput:GetText()
        end)
    end)
    self.StatInspectorNameInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedStat(function(stat)
            stat.name = self.StatInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.StatInspectorNameInput)

    self.StatInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorStatInspectorIdText", "ID: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 236,
        height = 12,
        justifyH = "LEFT",
    })
    root:AddChild(self.StatInspectorIdText)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorIconLabel", "Icon"))
    self.StatInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorStatInspectorIconField",
        width = 236,
        height = CONTROL_HEIGHT,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.StatInspectorIconField:SetParent(root:GetFrame())
    self.StatInspectorIconField:Create()
    local iconButton = self.StatInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local dataset, stat = self:GetSelectedStatAndDataset()
            if not dataset or not stat or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedStat(function(selectedStat)
                    selectedStat.icon = filePath or ""
                end)
            end, {
                filter = stat.icon or "",
            })
        end)
    end
    root:AddChild(self.StatInspectorIconField)

    self.StatInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.StatInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.StatInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.StatInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.StatInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorTagsLabel", "Tags"))
    self.StatInspectorTagsInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorStatInspectorTagsInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.StatInspectorTagsInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedStat(function(stat)
            stat.tags = UI.Utils.ParseCommaSeparatedList(self.StatInspectorTagsInput:GetText())
        end)
    end)
    self.StatInspectorTagsInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedStat(function(stat)
            stat.tags = UI.Utils.ParseCommaSeparatedList(self.StatInspectorTagsInput:GetText())
        end)
    end)
    root:AddChild(self.StatInspectorTagsInput)

    self.StatInspectorSeedNPCStatCheckbox = UI.Checkbox:New({
        name = "RPEDataEditorStatInspectorSeedNPCStatCheckbox",
        width = 236,
        height = 18,
        text = "Seed NPC Stat",
        checked = false,
        border = false,
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Checkbox) or 8,
        labelColor = UI.ResolveColor(nil, "text.primary"),
        onValueChanged = function(checked)
            self:CommitSelectedStat(function(stat)
                stat.seedNPCStat = checked == true
            end)
        end,
    })
    self.StatInspectorSeedNPCStatCheckbox:SetParent(root:GetFrame())
    self.StatInspectorSeedNPCStatCheckbox:Create()
    root:AddChild(self.StatInspectorSeedNPCStatCheckbox)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorDescriptionLabel", "Description"))
    self.StatInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorStatInspectorDescriptionInput", {
        width = 236,
        height = 98,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.StatInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedStat(function(stat)
            stat.description = self.StatInspectorDescriptionInput:GetText()
        end)
    end)
    root:AddChild(self.StatInspectorDescriptionInput)
end
