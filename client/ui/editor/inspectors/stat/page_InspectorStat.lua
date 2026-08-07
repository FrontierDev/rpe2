local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildStatInspectorPage(parent)
    if self.StatInspectorPage then
        self:RefreshStatInspectorPage()
        return self.StatInspectorPage
    end

    self.StatInspectorPage = CreateFrame("Frame", "RPEDataEditorStatInspectorPage", parent)

    self.StatInspectorTabBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.StatInspectorPage, "RPEDataEditorStatInspectorTabBar", {
        spacing = 2,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.StatInspectorTabBar:GetFrame():SetPoint("TOPLEFT", self.StatInspectorPage, "TOPLEFT", 0, 0)

    self.StatInspectorGeneralTabButton = UI.CreateButton(self.StatInspectorTabBar:GetFrame(), "RPEDataEditorStatInspectorGeneralTabButton", "General", 64, function()
        self:SetStatInspectorTab("general")
    end, {
        height = 18,
        fontSize = 8,
    })
    self.StatInspectorTabBar:AddChild(self.StatInspectorGeneralTabButton)

    self.StatInspectorDisplayTabButton = UI.CreateButton(self.StatInspectorTabBar:GetFrame(), "RPEDataEditorStatInspectorDisplayTabButton", "Display", 64, function()
        self:SetStatInspectorTab("display")
    end, {
        height = 18,
        fontSize = 8,
    })
    self.StatInspectorTabBar:AddChild(self.StatInspectorDisplayTabButton)

    self.StatInspectorMechanicsTabButton = UI.CreateButton(self.StatInspectorTabBar:GetFrame(), "RPEDataEditorStatInspectorMechanicsTabButton", "Derived", 64, function()
        self:SetStatInspectorTab("mechanics")
    end, {
        height = 18,
        fontSize = 8,
    })
    self.StatInspectorTabBar:AddChild(self.StatInspectorMechanicsTabButton)

    self.StatInspectorGeneralPage = CreateFrame("Frame", "RPEDataEditorStatInspectorGeneralPage", self.StatInspectorPage)
    self.StatInspectorGeneralPage:SetPoint("TOPLEFT", self.StatInspectorPage, "TOPLEFT", self.StatInspectorSidePadding, -24)
    self.StatInspectorGeneralPage:SetPoint("TOPRIGHT", self.StatInspectorPage, "TOPRIGHT", -self.StatInspectorSidePadding, -24)
    self.StatInspectorGeneralPage:SetPoint("BOTTOMLEFT", self.StatInspectorPage, "BOTTOMLEFT", self.StatInspectorSidePadding, 24)
    self.StatInspectorGeneralPage:SetPoint("BOTTOMRIGHT", self.StatInspectorPage, "BOTTOMRIGHT", -self.StatInspectorSidePadding, 24)
    self:BuildStatInspectorGeneralPage(self.StatInspectorGeneralPage)

    self.StatInspectorDisplayPage = CreateFrame("Frame", "RPEDataEditorStatInspectorDisplayPage", self.StatInspectorPage)
    self.StatInspectorDisplayPage:SetPoint("TOPLEFT", self.StatInspectorPage, "TOPLEFT", self.StatInspectorSidePadding, -24)
    self.StatInspectorDisplayPage:SetPoint("TOPRIGHT", self.StatInspectorPage, "TOPRIGHT", -self.StatInspectorSidePadding, -24)
    self.StatInspectorDisplayPage:SetPoint("BOTTOMLEFT", self.StatInspectorPage, "BOTTOMLEFT", self.StatInspectorSidePadding, 24)
    self.StatInspectorDisplayPage:SetPoint("BOTTOMRIGHT", self.StatInspectorPage, "BOTTOMRIGHT", -self.StatInspectorSidePadding, 24)
    self:BuildStatInspectorDisplayPage(self.StatInspectorDisplayPage)

    self.StatInspectorMechanicsPage = CreateFrame("Frame", "RPEDataEditorStatInspectorMechanicsPage", self.StatInspectorPage)
    self.StatInspectorMechanicsPage:SetPoint("TOPLEFT", self.StatInspectorPage, "TOPLEFT", self.StatInspectorSidePadding, -24)
    self.StatInspectorMechanicsPage:SetPoint("TOPRIGHT", self.StatInspectorPage, "TOPRIGHT", -self.StatInspectorSidePadding, -24)
    self.StatInspectorMechanicsPage:SetPoint("BOTTOMLEFT", self.StatInspectorPage, "BOTTOMLEFT", self.StatInspectorSidePadding, 24)
    self.StatInspectorMechanicsPage:SetPoint("BOTTOMRIGHT", self.StatInspectorPage, "BOTTOMRIGHT", -self.StatInspectorSidePadding, 24)
    self:BuildStatInspectorMechanicsPage(self.StatInspectorMechanicsPage)

    self.StatInspectorEmptyText = UI.CreateText(self.StatInspectorPage, "RPEDataEditorStatInspectorEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 236,
        height = 20,
        justifyH = "LEFT",
    })
    self.StatInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.StatInspectorPage, "BOTTOMLEFT", 0, 0)

    self:SetStatInspectorTab("general")
    self:RefreshStatInspectorPage()
    return self.StatInspectorPage
end

function DataEditor:RefreshStatInspectorPage()
    local dataset, stat = self:GetSelectedStatAndDataset()
    local hasStat = stat ~= nil
    local isDerived = hasStat and stat.valueMode == "derived"

    self._refreshingStatInspector = true

    if self.StatInspectorNameInput then
        self.StatInspectorNameInput:SetText(stat and (stat.name or "") or "")
        self:SetInspectorTextElementEnabled(self.StatInspectorNameInput, hasStat)
    end

    self:RefreshStatDisplayFields(stat, hasStat)

    if self.StatInspectorIdText then
        self.StatInspectorIdText:SetText(("ID: %s"):format(stat and stat.id ~= nil and tostring(stat.id) or "-"))
    end

    if self.StatInspectorIconInput then
        self.StatInspectorIconInput:SetText(stat and (stat.icon or "") or "")
        self:SetInspectorTextElementEnabled(self.StatInspectorIconInput, hasStat)
    end

    if self.StatInspectorTagsInput then
        self.StatInspectorTagsInput:SetText(UI.Utils.JoinCommaSeparatedList(stat and stat.tags or nil))
        self:SetInspectorTextElementEnabled(self.StatInspectorTagsInput, hasStat)
    end

    if self.StatInspectorDefenceLabelInput then
        self.StatInspectorDefenceLabelInput:SetText(stat and (stat.defenceLabel or "") or "")
        self:SetInspectorTextElementEnabled(self.StatInspectorDefenceLabelInput, hasStat)
    end

    if self.StatInspectorSeedNPCStatCheckbox then
        self.StatInspectorSeedNPCStatCheckbox:SetChecked(stat and stat.seedNPCStat == true or false, true)
        local frame = self.StatInspectorSeedNPCStatCheckbox.GetFrame and self.StatInspectorSeedNPCStatCheckbox:GetFrame() or nil
        if frame and frame.EnableMouse then
            frame:EnableMouse(hasStat == true)
        end
        if frame and frame.SetAlpha then
            frame:SetAlpha(hasStat == true and 1 or 0.5)
        end
    end

    if self.StatInspectorDescriptionInput then
        self.StatInspectorDescriptionInput:SetText(stat and (stat.description or "") or "")
        self:SetInspectorTextElementEnabled(self.StatInspectorDescriptionInput, hasStat)
    end

    if self.StatInspectorValueModeDropdown then
        self.StatInspectorValueModeDropdown:SetSelectedValue(stat and stat.valueMode or "manual", true)
        self:SetInspectorDropdownEnabled(self.StatInspectorValueModeDropdown, hasStat)
    end

    if self.StatInspectorBaseValueInput then
        self.StatInspectorBaseValueInput:SetText(tostring(stat and stat.baseValue or 0))
        self:SetInspectorTextElementEnabled(self.StatInspectorBaseValueInput, hasStat and not isDerived)
    end

    if self.StatInspectorItemLevelWeightInput then
        self.StatInspectorItemLevelWeightInput:SetText(tostring(stat and stat.itemLevelWeight or 0))
        self:SetInspectorTextElementEnabled(self.StatInspectorItemLevelWeightInput, hasStat)
    end

    if self.StatInspectorPendingSourceDatasetDropdown then
        self.StatInspectorPendingSourceDatasetDropdown:SetItems(self:BuildStatInspectorDatasetItems())
        self.StatInspectorPendingSourceDatasetDropdown:SetSelectedValue("", true)
        self:SetInspectorDropdownEnabled(self.StatInspectorPendingSourceDatasetDropdown, hasStat and isDerived)
    end

    if self.StatInspectorPendingSourceStatDropdown then
        self:RefreshStatInspectorPendingSourceStatDropdown()
        self.StatInspectorPendingSourceStatDropdown:SetSelectedValue("", true)
        self:SetInspectorDropdownEnabled(self.StatInspectorPendingSourceStatDropdown, hasStat and isDerived)
    end

    if self.StatInspectorPendingCoefficientInput then
        self.StatInspectorPendingCoefficientInput:SetText("1")
        self:SetInspectorTextElementEnabled(self.StatInspectorPendingCoefficientInput, hasStat and isDerived)
    end

    self._refreshingStatInspector = false

    self:RefreshStatInspectorDerivedSourceTable()

    if self.StatInspectorAddSourceButton and self.StatInspectorAddSourceButton.SetEnabled then
        self.StatInspectorAddSourceButton:SetEnabled(hasStat and isDerived)
    end

    if self.StatInspectorEmptyText then
        self.StatInspectorEmptyText:SetText(hasStat and "Adjust the selected stat definition here." or "Select a stat to inspect it.")
    end

    if hasStat and self.ActiveStatInspectorTabKey == nil then
        self:SetStatInspectorTab("general")
    end
end
