local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}

function DataEditor:BuildAuraInspectorGeneralPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorAuraInspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorNameLabel", "Name"))
    self.AuraInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAuraInspectorNameInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorNameInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedAura(function(aura)
            aura.name = self.AuraInspectorNameInput:GetText()
        end)
    end)
    self.AuraInspectorNameInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedAura(function(aura)
            aura.name = self.AuraInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.AuraInspectorNameInput)

    self.AuraInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorAuraInspectorIdText", "ID: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = self.AuraInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
    })
    root:AddChild(self.AuraInspectorIdText)

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorIconLabel", "Icon"))
    self.AuraInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorAuraInspectorIconField",
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.AuraInspectorIconField:SetParent(root:GetFrame())
    self.AuraInspectorIconField:Create()
    local iconButton = self.AuraInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local _, aura = self:GetSelectedAuraAndDataset()
            if not aura or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedAura(function(selectedAura)
                    selectedAura.icon = filePath or ""
                end)
            end, {
                filter = aura.icon or "",
            })
        end)
    end
    root:AddChild(self.AuraInspectorIconField)

    self.AuraInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.AuraInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.AuraInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.AuraInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.AuraInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorDurationLabel", "Duration"))
    self.AuraInspectorDurationInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAuraInspectorDurationInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorDurationInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedAura(function(aura)
            aura.duration = math.max(1, tonumber(self.AuraInspectorDurationInput:GetText()) or 1)
        end)
    end)
    self.AuraInspectorDurationInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedAura(function(aura)
            aura.duration = math.max(1, tonumber(self.AuraInspectorDurationInput:GetText()) or 1)
        end)
    end)
    root:AddChild(self.AuraInspectorDurationInput)

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorStackBehaviorLabel", "Stack Behavior"))
    self.AuraInspectorStackBehaviorDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorAuraInspectorStackBehaviorDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:GetAuraInspectorStackBehaviorItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAura(function(aura)
                aura.stackBehavior = value == "independent_duration" and "independent_duration" or "refresh_duration"
            end)
        end,
    })
    root:AddChild(self.AuraInspectorStackBehaviorDropdown)

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorMaxStacksLabel", "Max Stacks"))
    self.AuraInspectorMaxStacksInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAuraInspectorMaxStacksInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorMaxStacksInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedAura(function(aura)
            aura.maxStacks = math.max(1, tonumber(self.AuraInspectorMaxStacksInput:GetText()) or 1)
        end)
    end)
    self.AuraInspectorMaxStacksInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedAura(function(aura)
            aura.maxStacks = math.max(1, tonumber(self.AuraInspectorMaxStacksInput:GetText()) or 1)
        end)
    end)
    root:AddChild(self.AuraInspectorMaxStacksInput)

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorDescriptionLabel", "Description"))
    self.AuraInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorAuraInspectorDescriptionInput", {
        width = self.AuraInspectorFieldWidth,
        height = 56,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedAura(function(aura)
            aura.description = self.AuraInspectorDescriptionInput:GetText()
        end)
    end)
    root:AddChild(self.AuraInspectorDescriptionInput)
end
