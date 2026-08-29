local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local UnitClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Unit or nil

function DataEditor:GetUnitInspectorChallengeLevelItems()
    if UnitClass and type(UnitClass.GetChallengeLevelDefinitions) == "function" then
        return UnitClass.GetChallengeLevelDefinitions()
    end

    return {}
end

function DataEditor:NormalizeUnitInspectorChallengeLevel(value)
    if UnitClass and type(UnitClass.NormalizeChallengeLevel) == "function" then
        return UnitClass.NormalizeChallengeLevel(value)
    end

    return "normal"
end

function DataEditor:BuildUnitInspectorGeneralPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorNameLabel", "Name"))
    self.UnitInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorUnitInspectorNameInput", {
        width = self.UnitInspectorFieldWidth,
        height = 24,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.UnitInspectorNameInput:SetScript("OnEnterPressed", function()
        if self._refreshingUnitInspector then
            return
        end

        self:CommitSelectedUnit(function(unit)
            unit.name = self.UnitInspectorNameInput:GetText()
        end)
    end)
    self.UnitInspectorNameInput:SetScript("OnEditFocusLost", function()
        if self._refreshingUnitInspector then
            return
        end

        self:CommitSelectedUnit(function(unit)
            unit.name = self.UnitInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.UnitInspectorNameInput)

    self.UnitInspectorIdText = self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorIdText", "ID: -")
    root:AddChild(self.UnitInspectorIdText)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorTagsLabel", "Tags"))
    self.UnitInspectorTagsInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorUnitInspectorTagsInput", {
        width = self.UnitInspectorFieldWidth,
        height = 24,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.UnitInspectorTagsInput:SetScript("OnEnterPressed", function()
        if self._refreshingUnitInspector then
            return
        end

        self:CommitSelectedUnit(function(unit)
            unit.tags = UI.Utils.ParseCommaSeparatedList(self.UnitInspectorTagsInput:GetText())
        end)
    end)
    self.UnitInspectorTagsInput:SetScript("OnEditFocusLost", function()
        if self._refreshingUnitInspector then
            return
        end

        self:CommitSelectedUnit(function(unit)
            unit.tags = UI.Utils.ParseCommaSeparatedList(self.UnitInspectorTagsInput:GetText())
        end)
    end)
    root:AddChild(self.UnitInspectorTagsInput)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorCreatureTypeLabel", "Creature Type"))
    self.UnitInspectorCreatureTypeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorUnitInspectorCreatureTypeDropdown", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        items = self:GetUnitInspectorCreatureTypeItems(),
        onValueChanged = function(value)
            if self._refreshingUnitInspector then
                return
            end

            self:CommitSelectedUnit(function(unit)
                unit.creatureType = value
            end)
        end,
    })
    root:AddChild(self.UnitInspectorCreatureTypeDropdown)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorCreatureSizeLabel", "Creature Size"))
    self.UnitInspectorCreatureSizeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorUnitInspectorCreatureSizeDropdown", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        items = self:GetUnitInspectorCreatureSizeItems(),
        onValueChanged = function(value)
            if self._refreshingUnitInspector then
                return
            end

            self:CommitSelectedUnit(function(unit)
                unit.creatureSize = value
            end)
        end,
    })
    root:AddChild(self.UnitInspectorCreatureSizeDropdown)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorChallengeLevelLabel", "Challenge Level"))
    self.UnitInspectorChallengeLevelDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorUnitInspectorChallengeLevelDropdown", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        items = self:GetUnitInspectorChallengeLevelItems(),
        onValueChanged = function(value)
            if self._refreshingUnitInspector then
                return
            end

            self:CommitSelectedUnit(function(unit)
                unit.challengeLevel = self:NormalizeUnitInspectorChallengeLevel(value)
            end)
        end,
    })
    root:AddChild(self.UnitInspectorChallengeLevelDropdown)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorAttributesLabel", "Attributes"))
    self.UnitInspectorAttributesDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorUnitInspectorAttributesDropdown", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        multiSelect = true,
        items = self:GetUnitInspectorAttributeItems(),
        onValueChanged = function()
            if self._refreshingUnitInspector then
                return
            end

            local values = self.UnitInspectorAttributesDropdown and self.UnitInspectorAttributesDropdown.GetSelectedValues and self.UnitInspectorAttributesDropdown:GetSelectedValues() or {}
            self:CommitSelectedUnit(function(unit)
                unit.attributes = values
            end)
        end,
    })
    root:AddChild(self.UnitInspectorAttributesDropdown)
end
