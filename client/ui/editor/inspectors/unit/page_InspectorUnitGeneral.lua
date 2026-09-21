local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local UnitClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Unit or nil

function DataEditor:GetUnitInspectorEffectiveDefinition(unit)
    if type(unit) ~= "table" or type(unit.extendsUnitRef) ~= "string" or unit.extendsUnitRef == "" then
        return unit
    end
    if type(Registry.ResolveUnitDefinition) ~= "function" then
        return unit
    end
    local ok, _, resolved = pcall(function()
        local dataset = self:GetSelectedDataset()
        local reference = dataset and unit.id and (tostring(dataset.id) .. ":" .. tostring(unit.id)) or nil
        return reference and Registry:ResolveUnitDefinition(reference, { includeInactive = true })
    end)
    return ok and resolved or unit
end

function DataEditor:BuildUnitInspectorExtendsItems(unit)
    local items = { { label = "None", value = "" } }
    local selectedDataset = self:GetSelectedDataset()
    local selfRef = selectedDataset and unit and unit.id
        and (tostring(selectedDataset.id) .. ":" .. tostring(unit.id)) or ""
    local datasets = type(Database.ListDatasets) == "function" and Database.ListDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local children = {}
        for unitIndex = 1, #(dataset and dataset.units or {}) do
            local candidate = dataset.units[unitIndex]
            local ref = candidate and candidate.id
                and (tostring(dataset.id) .. ":" .. tostring(candidate.id)) or ""
            if ref ~= "" and ref ~= selfRef then
                local displayName = candidate.name
                if type(Registry.ResolveUnitDefinition) == "function" then
                    local ok, _, resolved = pcall(function()
                        return Registry:ResolveUnitDefinition(ref, { includeInactive = true })
                    end)
                    if ok and resolved then
                        displayName = resolved.name
                    end
                end
                children[#children + 1] = {
                    label = (displayName and displayName ~= "" and displayName or tostring(candidate.id))
                        .. (candidate.extendsUnitRef and " (extends)" or ""),
                    value = ref,
                }
            end
        end
        if #children > 0 then
            table.sort(children, function(left, right)
                if left.label == right.label then return left.value < right.value end
                return left.label < right.label
            end)
            items[#items + 1] = {
                label = tostring(dataset.name or dataset.id or "Dataset"),
                value = "dataset:" .. tostring(dataset.id or datasetIndex),
                enabled = true,
                notCheckable = true,
                keepShownOnClick = true,
                children = children,
            }
        end
    end

    local currentRef = tostring(unit and unit.extendsUnitRef or "")
    if currentRef ~= "" then
        local found = false
        if currentRef ~= selfRef then
            for datasetIndex = 1, #datasets do
                local dataset = datasets[datasetIndex]
                for unitIndex = 1, #(dataset and dataset.units or {}) do
                    local candidate = dataset.units[unitIndex]
                    if candidate and currentRef == (tostring(dataset.id) .. ":" .. tostring(candidate.id)) then
                        found = true
                        break
                    end
                end
                if found then break end
            end
        end
        if not found then
            items[#items + 1] = {
                label = (currentRef == selfRef and "Invalid self-reference: " or "Missing Unit: ") .. currentRef,
                value = currentRef,
                enabled = false,
            }
        end
    end
    return items
end

function DataEditor:CommitUnitInspectorExtendsUnit(value)
    if self._refreshingUnitInspector then
        return
    end
    local dataset, unit = self:GetSelectedUnitAndDataset()
    if not dataset or not unit then
        return
    end

    local nextRef = tostring(value or "")
    local selfRef = tostring(dataset.id or "") .. ":" .. tostring(unit.id or "")
    if nextRef == selfRef then
        self:RefreshUnitInspectorPage()
        return
    end

    self:CommitSelectedUnit(function(targetUnit)
        if nextRef == "" then
            targetUnit.extendsUnitRef = nil
            return
        end

        -- Unit records created before choosing a parent contain constructor
        -- defaults. Those values are not authored overrides for a new extension.
        if targetUnit.extendsUnitRef == nil then
            if targetUnit.name == "New Unit" then targetUnit.name = nil end
            if targetUnit.creatureType == "humanoid" then targetUnit.creatureType = nil end
            if targetUnit.creatureSize == "medium" then targetUnit.creatureSize = nil end
            if targetUnit.challengeLevel == "normal" then targetUnit.challengeLevel = nil end
            for _, key in ipairs({ "appearances", "presets", "spells", "stats", "resources", "resistances", "attributes", "tags" }) do
                if type(targetUnit[key]) == "table" and #targetUnit[key] == 0 then
                    targetUnit[key] = nil
                end
            end
        end
        targetUnit.extendsUnitRef = nextRef
    end)
    self:RefreshUnitInspectorPage()
end

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

        local _, unit = self:GetSelectedUnitAndDataset()
        local effective = self:GetUnitInspectorEffectiveDefinition(unit)
        local name = self.UnitInspectorNameInput:GetText()
        if name == tostring(effective and effective.name or "") then
            return
        end
        self:CommitSelectedUnit(function(targetUnit)
            targetUnit.name = name
        end)
    end)
    self.UnitInspectorNameInput:SetScript("OnEditFocusLost", function()
        if self._refreshingUnitInspector then
            return
        end

        local _, unit = self:GetSelectedUnitAndDataset()
        local effective = self:GetUnitInspectorEffectiveDefinition(unit)
        local name = self.UnitInspectorNameInput:GetText()
        if name == tostring(effective and effective.name or "") then
            return
        end
        self:CommitSelectedUnit(function(targetUnit)
            targetUnit.name = name
        end)
    end)
    root:AddChild(self.UnitInspectorNameInput)

    self.UnitInspectorIdText = self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorIdText", "ID: -")
    root:AddChild(self.UnitInspectorIdText)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorExtendsLabel", "Extends Unit"))
    self.UnitInspectorExtendsDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorUnitInspectorExtendsDropdown", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        items = {},
        onValueChanged = function(value)
            self:CommitUnitInspectorExtendsUnit(value)
        end,
    })
    root:AddChild(self.UnitInspectorExtendsDropdown)
    self.UnitInspectorExtendsStatus = UI.CreateText(root:GetFrame(), "RPEDataEditorUnitInspectorExtendsStatus", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = self.UnitInspectorFieldWidth,
        height = 28,
        justifyH = "LEFT",
        wordWrap = true,
    })
    root:AddChild(self.UnitInspectorExtendsStatus)

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
