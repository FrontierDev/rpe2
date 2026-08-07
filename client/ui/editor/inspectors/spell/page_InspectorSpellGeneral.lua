local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}

function DataEditor:BuildSpellInspectorGeneralPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSpellInspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorNameLabel", "Name"))
    self.SpellInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorSpellInspectorNameInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorNameInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedSpell(function(spell)
            spell.name = self.SpellInspectorNameInput:GetText()
        end)
    end)
    self.SpellInspectorNameInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSpell(function(spell)
            spell.name = self.SpellInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.SpellInspectorNameInput)

    self.SpellInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorSpellInspectorIdText", "ID: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = self.SpellInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
    })
    root:AddChild(self.SpellInspectorIdText)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorIconLabel", "Icon"))
    self.SpellInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorSpellInspectorIconField",
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.SpellInspectorIconField:SetParent(root:GetFrame())
    self.SpellInspectorIconField:Create()
    local iconButton = self.SpellInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local _, spell = self:GetSelectedSpellAndDataset()
            if not spell or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedSpell(function(selectedSpell)
                    selectedSpell.icon = filePath or ""
                end)
            end, {
                filter = spell.icon or "",
            })
        end)
    end
    root:AddChild(self.SpellInspectorIconField)

    self.SpellInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.SpellInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.SpellInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.SpellInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.SpellInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorTagsLabel", "Tags"))
    self.SpellInspectorTagsInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorSpellInspectorTagsInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorTagsInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedSpell(function(spell)
            spell.tags = UI.Utils.ParseCommaSeparatedList(self.SpellInspectorTagsInput:GetText())
        end)
    end)
    self.SpellInspectorTagsInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSpell(function(spell)
            spell.tags = UI.Utils.ParseCommaSeparatedList(self.SpellInspectorTagsInput:GetText())
        end)
    end)
    root:AddChild(self.SpellInspectorTagsInput)

    self.SpellInspectorSeedNPCSpellCheckbox = self:CreateSpellInspectorCheckbox(root:GetFrame(), "RPEDataEditorSpellInspectorSeedNPCSpellCheckbox", "Seed NPC Spell", false, function(checked)
        self:CommitSelectedSpell(function(spell)
            spell.seedNPCSpell = checked == true
        end)
    end)
    root:AddChild(self.SpellInspectorSeedNPCSpellCheckbox)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorDescriptionLabel", "Description"))
    self.SpellInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorSpellInspectorDescriptionInput", {
        width = self.SpellInspectorFieldWidth,
        height = 112,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSpell(function(spell)
            spell.description = self.SpellInspectorDescriptionInput:GetText()
        end)
    end)
    root:AddChild(self.SpellInspectorDescriptionInput)
end

function DataEditor:BuildSpellInspectorLearningPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSpellInspectorLearningLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorLearnModeLabel", "Learn Mode"))
    self.SpellInspectorLearnModeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorSpellInspectorLearnModeDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        items = self:GetSpellInspectorLearnModeItems(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end

            self:CommitSelectedSpell(function(spell)
                spell.learnMode = value or "trainer"
            end)
        end,
    })
    root:AddChild(self.SpellInspectorLearnModeDropdown)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorSpellbookCategoryLabel", "Spellbook Category"))
    self.SpellInspectorSpellbookCategoryInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorSpellInspectorSpellbookCategoryInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorSpellbookCategoryInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedSpell(function(spell)
            spell.spellbookCategory = self.SpellInspectorSpellbookCategoryInput:GetText()
        end)
    end)
    self.SpellInspectorSpellbookCategoryInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSpell(function(spell)
            spell.spellbookCategory = self.SpellInspectorSpellbookCategoryInput:GetText()
        end)
    end)
    root:AddChild(self.SpellInspectorSpellbookCategoryInput)

    self.SpellInspectorLearningHintText = UI.CreateText(root:GetFrame(), "RPEDataEditorSpellInspectorLearningHintText", "Always Learned spells are added to the effective spellbook automatically.", {
        width = self.SpellInspectorFieldWidth,
        height = 28,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.SpellInspectorLearningHintText)
end
