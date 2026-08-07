local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildPetInspectorPage(parent)
    if self.PetInspectorPage then
        self:RefreshPetInspectorPage()
        return self.PetInspectorPage
    end

    self.PetInspectorPage = CreateFrame("Frame", "RPEDataEditorPetInspectorPage", parent)

    self.PetInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.PetInspectorPage, "RPEDataEditorPetInspectorSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    self.PetInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.PetInspectorPage, "TOPLEFT", 0, 0)
    self.PetInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.PetInspectorPage, "TOPRIGHT", 0, 0)

    self.PetInspectorPreviousButton = UI.CreateButton(self.PetInspectorSelectorBar:GetFrame(), "RPEDataEditorPetInspectorPreviousButton", "Prev", 40, function()
        self:SetPetInspectorTab((self:GetPetInspectorPageDefinitions()[(self.ActivePetInspectorPageIndex or 1) - 1] or {}).key or "general")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.PetInspectorSelectorBar:AddChild(self.PetInspectorPreviousButton)

    self.PetInspectorPageDropdown = UI.CreateDropdown(self.PetInspectorSelectorBar:GetFrame(), "RPEDataEditorPetInspectorPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildPetInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if self._refreshingPetInspectorPageSelector then
                return
            end

            self:SetPetInspectorTab(value)
        end,
    })
    self.PetInspectorSelectorBar:AddChild(self.PetInspectorPageDropdown)

    self.PetInspectorNextButton = UI.CreateButton(self.PetInspectorSelectorBar:GetFrame(), "RPEDataEditorPetInspectorNextButton", "Next", 40, function()
        self:SetPetInspectorTab((self:GetPetInspectorPageDefinitions()[(self.ActivePetInspectorPageIndex or 1) + 1] or {}).key or "equipment")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.PetInspectorSelectorBar:AddChild(self.PetInspectorNextButton)

    local function createPage(name)
        local page = CreateFrame("Frame", name, self.PetInspectorPage)
        page:SetPoint("TOPLEFT", self.PetInspectorPage, "TOPLEFT", self.PetInspectorSidePadding, -24)
        page:SetPoint("TOPRIGHT", self.PetInspectorPage, "TOPRIGHT", -self.PetInspectorSidePadding, -24)
        page:SetPoint("BOTTOMLEFT", self.PetInspectorPage, "BOTTOMLEFT", self.PetInspectorSidePadding, 24)
        page:SetPoint("BOTTOMRIGHT", self.PetInspectorPage, "BOTTOMRIGHT", -self.PetInspectorSidePadding, 24)
        return page
    end

    self.PetInspectorGeneralPage = createPage("RPEDataEditorPetInspectorGeneralPage")
    self:BuildPetInspectorGeneralPage(self.PetInspectorGeneralPage)

    self.PetInspectorSpellsPage = createPage("RPEDataEditorPetInspectorSpellsPage")
    self:BuildPetInspectorSpellsPage(self.PetInspectorSpellsPage)

    self.PetInspectorEquipmentPage = createPage("RPEDataEditorPetInspectorEquipmentPage")
    self:BuildPetInspectorEquipmentPage(self.PetInspectorEquipmentPage)

    self.PetInspectorEmptyText = UI.CreateText(self.PetInspectorPage, "RPEDataEditorPetInspectorEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = self.PetInspectorFieldWidth,
        height = 20,
        justifyH = "LEFT",
    })
    self.PetInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.PetInspectorPage, "BOTTOMLEFT", 0, 0)

    self.ActivePetInspectorPageIndex = self.ActivePetInspectorPageIndex or self:GetPetInspectorPageIndexByKey(self.ActivePetInspectorTabKey or "general")
    self:SetPetInspectorTab("general")
    self:RefreshPetInspectorPage()
    return self.PetInspectorPage
end

function DataEditor:RefreshPetInspectorPage()
    local _, pet = self:GetSelectedPetAndDataset()
    local hasPet = pet ~= nil

    self._refreshingPetInspector = true

    if self.PetInspectorNameInput then
        self.PetInspectorNameInput:SetText(pet and (pet.name or "") or "")
        self:SetPetInspectorTextElementEnabled(self.PetInspectorNameInput, hasPet)
    end
    if self.PetInspectorIdText then
        self.PetInspectorIdText:SetText(("ID: %s"):format(pet and pet.id ~= nil and tostring(pet.id) or "-"))
    end
    if self.PetInspectorUnitDropdown then
        self.PetInspectorUnitDropdown:SetItems(self:BuildPetInspectorReferencesAcrossDatasets("units"))
        self.PetInspectorUnitDropdown:SetSelectedValue(pet and (pet.unitRef or "") or "", true)
        self:SetPetInspectorDropdownEnabled(self.PetInspectorUnitDropdown, hasPet)
    end
    if self.PetInspectorPendingSpellDropdown then
        self.PetInspectorPendingSpellDropdown:SetItems(self:BuildPetInspectorReferencesAcrossDatasets("spells"))
        self:SetPetInspectorDropdownEnabled(self.PetInspectorPendingSpellDropdown, hasPet)
    end
    if self.PetInspectorAddSpellButton then
        self.PetInspectorAddSpellButton:SetEnabled(hasPet)
    end
    if self.PetInspectorEquipmentSlotsDropdown then
        self.PetInspectorEquipmentSlotsDropdown:SetItems(self:BuildPetInspectorReferencesAcrossDatasets("itemSlots"))
        self.PetInspectorEquipmentSlotsDropdown:SetSelectedValues(pet and pet.equipmentSlotRefs or {}, true)
        self:SetPetInspectorDropdownEnabled(self.PetInspectorEquipmentSlotsDropdown, hasPet)
    end

    self:RefreshPetInspectorSpellsTable()

    if self.PetInspectorEmptyText then
        self.PetInspectorEmptyText:SetText(hasPet and "Adjust the selected pet definition here." or "Select a pet to inspect it.")
    end

    self._refreshingPetInspector = false
    self:RefreshPetInspectorPageSelector()
end
