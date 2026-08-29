local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function buildUnitInspectorPageSelectorItems(editor)
    local items = editor:BuildUnitInspectorPageSelectorItems()
    for index = 1, #items do
        if items[index].value == "model" then
            items[index].label = "Appearances"
        end
    end
    return items
end

function DataEditor:BuildUnitInspectorPage(parent)
    if self.UnitInspectorPage then
        self:RefreshUnitInspectorPage()
        return self.UnitInspectorPage
    end

    self.UnitInspectorPage = CreateFrame("Frame", "RPEDataEditorUnitInspectorPage", parent)

    self.UnitInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.UnitInspectorPage, "RPEDataEditorUnitInspectorSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    self.UnitInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.UnitInspectorPage, "TOPLEFT", 0, 0)
    self.UnitInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.UnitInspectorPage, "TOPRIGHT", 0, 0)

    self.UnitInspectorPreviousButton = UI.CreateButton(self.UnitInspectorSelectorBar:GetFrame(), "RPEDataEditorUnitInspectorPreviousButton", "Prev", 40, function()
        self:SetUnitInspectorTab((self:GetUnitInspectorPageDefinitions()[(self.ActiveUnitInspectorPageIndex or 1) - 1] or {}).key or "general")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.UnitInspectorSelectorBar:AddChild(self.UnitInspectorPreviousButton)

    self.UnitInspectorPageDropdown = UI.CreateDropdown(self.UnitInspectorSelectorBar:GetFrame(), "RPEDataEditorUnitInspectorPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = buildUnitInspectorPageSelectorItems(self),
        onValueChanged = function(value)
            if self._refreshingUnitInspectorPageSelector then
                return
            end

            self:SetUnitInspectorTab(value)
        end,
    })
    self.UnitInspectorSelectorBar:AddChild(self.UnitInspectorPageDropdown)

    self.UnitInspectorNextButton = UI.CreateButton(self.UnitInspectorSelectorBar:GetFrame(), "RPEDataEditorUnitInspectorNextButton", "Next", 40, function()
        self:SetUnitInspectorTab((self:GetUnitInspectorPageDefinitions()[(self.ActiveUnitInspectorPageIndex or 1) + 1] or {}).key or "resources")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.UnitInspectorSelectorBar:AddChild(self.UnitInspectorNextButton)

    local function createPage(name)
        local page = CreateFrame("Frame", name, self.UnitInspectorPage)
        page:SetPoint("TOPLEFT", self.UnitInspectorPage, "TOPLEFT", self.UnitInspectorSidePadding, -24)
        page:SetPoint("TOPRIGHT", self.UnitInspectorPage, "TOPRIGHT", -self.UnitInspectorSidePadding, -24)
        page:SetPoint("BOTTOMLEFT", self.UnitInspectorPage, "BOTTOMLEFT", self.UnitInspectorSidePadding, 24)
        page:SetPoint("BOTTOMRIGHT", self.UnitInspectorPage, "BOTTOMRIGHT", -self.UnitInspectorSidePadding, 24)
        return page
    end

    self.UnitInspectorGeneralPage = createPage("RPEDataEditorUnitInspectorGeneralPage")
    self:BuildUnitInspectorGeneralPage(self.UnitInspectorGeneralPage)

    self.UnitInspectorModelPage = createPage("RPEDataEditorUnitInspectorAppearancesPage")
    self:BuildUnitInspectorAppearancesPage(self.UnitInspectorModelPage)

    self.UnitInspectorEquipmentPage = createPage("RPEDataEditorUnitInspectorEquipmentPage")
    self:BuildUnitInspectorEquipmentPage(self.UnitInspectorEquipmentPage)

    self.UnitInspectorSpellsPage = createPage("RPEDataEditorUnitInspectorSpellsPage")
    self:BuildUnitInspectorSpellsPage(self.UnitInspectorSpellsPage)

    self.UnitInspectorStatsPage = createPage("RPEDataEditorUnitInspectorStatsPage")
    self:BuildUnitInspectorStatsPage(self.UnitInspectorStatsPage)

    self.UnitInspectorResourcesPage = createPage("RPEDataEditorUnitInspectorResourcesPage")
    self:BuildUnitInspectorResourcesPage(self.UnitInspectorResourcesPage)

    self.UnitInspectorEmptyText = UI.CreateText(self.UnitInspectorPage, "RPEDataEditorUnitInspectorEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = self.UnitInspectorFieldWidth,
        height = 20,
        justifyH = "LEFT",
    })
    self.UnitInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.UnitInspectorPage, "BOTTOMLEFT", 0, 0)

    self.ActiveUnitInspectorPageIndex = self.ActiveUnitInspectorPageIndex or self:GetUnitInspectorPageIndexByKey(self.ActiveUnitInspectorTabKey or "general")
    self:SetUnitInspectorTab("general")
    self:RefreshUnitInspectorPage()
    return self.UnitInspectorPage
end

function DataEditor:RefreshUnitInspectorPage()
    local _, unit = self:GetSelectedUnitAndDataset()
    local hasUnit = unit ~= nil

    self._refreshingUnitInspector = true

    if self.UnitInspectorNameInput then
        self.UnitInspectorNameInput:SetText(unit and (unit.name or "") or "")
        self:SetUnitInspectorTextElementEnabled(self.UnitInspectorNameInput, hasUnit)
    end
    if self.UnitInspectorIdText then
        self.UnitInspectorIdText:SetText(("ID: %s"):format(unit and unit.id ~= nil and tostring(unit.id) or "-"))
    end
    if self.UnitInspectorTagsInput then
        self.UnitInspectorTagsInput:SetText(UI.Utils.JoinCommaSeparatedList(unit and unit.tags or nil))
        self:SetUnitInspectorTextElementEnabled(self.UnitInspectorTagsInput, hasUnit)
    end
    if self.UnitInspectorCreatureTypeDropdown then
        self.UnitInspectorCreatureTypeDropdown:SetItems(self:GetUnitInspectorCreatureTypeItems())
        self.UnitInspectorCreatureTypeDropdown:SetSelectedValue(unit and unit.creatureType or "humanoid", true)
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorCreatureTypeDropdown, hasUnit)
    end
    if self.UnitInspectorCreatureSizeDropdown then
        self.UnitInspectorCreatureSizeDropdown:SetItems(self:GetUnitInspectorCreatureSizeItems())
        self.UnitInspectorCreatureSizeDropdown:SetSelectedValue(unit and unit.creatureSize or "medium", true)
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorCreatureSizeDropdown, hasUnit)
    end
    if self.UnitInspectorChallengeLevelDropdown then
        self.UnitInspectorChallengeLevelDropdown:SetItems(self:GetUnitInspectorChallengeLevelItems())
        self.UnitInspectorChallengeLevelDropdown:SetSelectedValue(self:NormalizeUnitInspectorChallengeLevel(unit and unit.challengeLevel or nil), true)
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorChallengeLevelDropdown, hasUnit)
    end
    if self.UnitInspectorAttributesDropdown then
        self.UnitInspectorAttributesDropdown:SetItems(self:GetUnitInspectorAttributeItems())
        self.UnitInspectorAttributesDropdown:SetSelectedValues(unit and unit.attributes or {}, true)
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorAttributesDropdown, hasUnit)
    end
    for index = 1, #(self.GetUnitInspectorEquipmentFieldDefinitions and self:GetUnitInspectorEquipmentFieldDefinitions() or {}) do
        local definition = self:GetUnitInspectorEquipmentFieldDefinitions()[index]
        local dropdown = self["UnitInspector" .. definition.fieldKey .. "Dropdown"]
        if dropdown then
            local slotRef = self:GetUnitInspectorActiveSlotReference(definition.ruleKey)
            dropdown:SetItems(self:BuildUnitInspectorItemItemsForSlot(slotRef, definition.fieldKey))
            dropdown:SetSelectedValue(unit and unit[definition.fieldKey] or "", true)
            self:SetUnitInspectorDropdownEnabled(dropdown, hasUnit and slotRef ~= "")
        end
    end

    if self.RefreshUnitInspectorAppearancesTable then
        self:RefreshUnitInspectorAppearancesTable()
    end

    if self.UnitInspectorPendingSpellDropdown then
        self.UnitInspectorPendingSpellDropdown:SetItems(self:BuildUnitInspectorReferencesAcrossDatasets("spells"))
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorPendingSpellDropdown, hasUnit)
    end
    if self.UnitInspectorAddSpellButton then
        self.UnitInspectorAddSpellButton:SetEnabled(hasUnit)
    end

    if self.UnitInspectorPendingStatDropdown then
        self.UnitInspectorPendingStatDropdown:SetItems(self:BuildUnitInspectorReferencesAcrossDatasets("stats"))
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorPendingStatDropdown, hasUnit)
    end
    if self.UnitInspectorPendingStatValueInput then
        self:SetUnitInspectorTextElementEnabled(self.UnitInspectorPendingStatValueInput, hasUnit)
    end
    if self.UnitInspectorAddStatButton then
        self.UnitInspectorAddStatButton:SetEnabled(hasUnit)
    end
    if self.UnitInspectorPendingResistanceDropdown then
        self.UnitInspectorPendingResistanceDropdown:SetItems(self:BuildUnitInspectorReferencesAcrossDatasets("damageSchools"))
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorPendingResistanceDropdown, hasUnit)
    end
    if self.UnitInspectorPendingResistanceCoefficientInput then
        self:SetUnitInspectorTextElementEnabled(self.UnitInspectorPendingResistanceCoefficientInput, hasUnit)
    end
    if self.UnitInspectorAddResistanceButton then
        self.UnitInspectorAddResistanceButton:SetEnabled(hasUnit)
    end

    if self.UnitInspectorPendingResourceDropdown then
        self.UnitInspectorPendingResourceDropdown:SetItems(self:BuildUnitInspectorReferencesAcrossDatasets("resources"))
        self:SetUnitInspectorDropdownEnabled(self.UnitInspectorPendingResourceDropdown, hasUnit)
    end
    if self.UnitInspectorPendingResourceValueInput then
        self:SetUnitInspectorTextElementEnabled(self.UnitInspectorPendingResourceValueInput, hasUnit)
    end
    if self.UnitInspectorPendingResourcePerPlayerInput then
        self:SetUnitInspectorTextElementEnabled(self.UnitInspectorPendingResourcePerPlayerInput, hasUnit)
    end
    if self.UnitInspectorAddResourceButton then
        self.UnitInspectorAddResourceButton:SetEnabled(hasUnit)
    end

    self:RefreshUnitInspectorSpellsTable()
    self:RefreshUnitInspectorStatsTable()
    self:RefreshUnitInspectorResistancesTable()
    self:RefreshUnitInspectorResourcesTable()

    if self.UnitInspectorEmptyText then
        if hasUnit then
            self.UnitInspectorEmptyText:SetText("Adjust the selected unit definition here.")
        else
            self.UnitInspectorEmptyText:SetText("Select a unit to inspect it.")
        end
    end

    self._refreshingUnitInspector = false
    self:RefreshUnitInspectorPageSelector()
end
