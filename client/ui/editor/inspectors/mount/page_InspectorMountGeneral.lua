local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}

function DataEditor:BuildMountInspectorGeneralPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorMountInspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildMountInspectorLabel(root:GetFrame(), "RPEDataEditorMountInspectorNameLabel", "Name"))
    self.MountInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorMountInspectorNameInput", {
        width = self.MountInspectorFieldWidth,
        height = self.MountInspectorControlHeight,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.MountInspectorNameInput:SetScript("OnEnterPressed", function()
        if self._refreshingMountInspector then
            return
        end
        self:CommitSelectedMount(function(mount)
            mount.name = self.MountInspectorNameInput:GetText()
        end)
    end)
    self.MountInspectorNameInput:SetScript("OnEditFocusLost", function()
        if self._refreshingMountInspector then
            return
        end
        self:CommitSelectedMount(function(mount)
            mount.name = self.MountInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.MountInspectorNameInput)

    self.MountInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorMountInspectorIdText", "ID: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = self.MountInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
    })
    root:AddChild(self.MountInspectorIdText)

    root:AddChild(self:BuildMountInspectorLabel(root:GetFrame(), "RPEDataEditorMountInspectorIconLabel", "Icon"))
    self.MountInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorMountInspectorIconField",
        width = self.MountInspectorFieldWidth,
        height = self.MountInspectorControlHeight,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.MountInspectorIconField:SetParent(root:GetFrame())
    self.MountInspectorIconField:Create()
    local iconButton = self.MountInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local _, mount = self:GetSelectedMountAndDataset()
            if not mount or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedMount(function(selectedMount)
                    selectedMount.icon = filePath or ""
                end)
            end, {
                filter = mount.icon or "",
            })
        end)
    end
    root:AddChild(self.MountInspectorIconField)

    self.MountInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.MountInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.MountInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.MountInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.MountInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    root:AddChild(self:BuildMountInspectorLabel(root:GetFrame(), "RPEDataEditorMountInspectorDescriptionLabel", "Description"))
    self.MountInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorMountInspectorDescriptionInput", {
        width = self.MountInspectorFieldWidth,
        height = 132,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.MountInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        if self._refreshingMountInspector then
            return
        end
        self:CommitSelectedMount(function(mount)
            mount.description = self.MountInspectorDescriptionInput:GetText()
        end)
    end)
    root:AddChild(self.MountInspectorDescriptionInput)
end

