local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local PetClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Pet or nil

DataEditor.PetInspectorSidePadding = DataEditor.PetInspectorSidePadding or 8
DataEditor.PetInspectorControlHeight = DataEditor.PetInspectorControlHeight or 20
DataEditor.PetInspectorFieldWidth = DataEditor.PetInspectorFieldWidth or 236

local PET_INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "spells", label = "Spells" },
    { key = "equipment", label = "Equipment" },
}

local function applyTable(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return
    end

    for key in pairs(target) do
        if source[key] == nil then
            target[key] = nil
        end
    end

    for key, value in pairs(source) do
        target[key] = value
    end
end

function DataEditor:GetSelectedPetAndDataset()
    return self:GetSelectedDataset(), self:GetSelectedPet()
end

function DataEditor:NormalizePetDefinition(pet)
    if PetClass and PetClass.ToTable then
        return PetClass.ToTable(PetClass:New(pet))
    end

    return pet or {}
end

function DataEditor:CommitSelectedPet(mutate)
    local dataset, pet = self:GetSelectedPetAndDataset()
    if not dataset or not pet or type(mutate) ~= "function" then
        return
    end

    local before = self:DeepCopyValue(pet)
    mutate(pet, dataset)
    applyTable(pet, self:NormalizePetDefinition(pet))

    if self:DeepEqualValues(before, pet) then
        return
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "pets")
end

function DataEditor:SetPetInspectorDropdownEnabled(dropdown, enabled)
    local frame = dropdown and dropdown.GetFrame and dropdown:GetFrame() or nil
    if not frame then
        return
    end

    if frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end
    if frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
end

function DataEditor:SetPetInspectorTextElementEnabled(element, enabled)
    if not element then
        return
    end

    if element.SetEnabled then
        element:SetEnabled(enabled == true)
    end
    if element.SetReadOnly then
        element:SetReadOnly(enabled ~= true)
    end
end

function DataEditor:BuildPetInspectorLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or self.PetInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
    })
end

function DataEditor:BuildPetInspectorReferencesAcrossDatasets(collectionKey)
    return self:BuildReferenceItemsAcrossDatasets(collectionKey, {
        includeNone = true,
        noneLabel = "None",
    })
end

function DataEditor:GetPetInspectorPageDefinitions()
    return PET_INSPECTOR_PAGE_DEFINITIONS
end

function DataEditor:GetPetInspectorPageIndexByKey(key)
    local pages = self:GetPetInspectorPageDefinitions()
    for index = 1, #pages do
        if pages[index].key == key then
            return index
        end
    end

    return 1
end

function DataEditor:BuildPetInspectorPageSelectorItems()
    local items = {}
    local pages = self:GetPetInspectorPageDefinitions()

    for index = 1, #pages do
        items[#items + 1] = {
            label = pages[index].label,
            value = pages[index].key,
        }
    end

    return items
end

function DataEditor:RefreshPetInspectorPageSelector()
    local pages = self:GetPetInspectorPageDefinitions()
    local pageCount = #pages
    local activeIndex = math.max(1, math.min(self.ActivePetInspectorPageIndex or 1, pageCount))
    self.ActivePetInspectorPageIndex = activeIndex
    self.ActivePetInspectorTabKey = pages[activeIndex] and pages[activeIndex].key or "general"

    local activeDefinition = pages[activeIndex]
    if self.PetInspectorPageDropdown and activeDefinition then
        self._refreshingPetInspectorPageSelector = true
        self.PetInspectorPageDropdown:SetSelectedValue(activeDefinition.key, true)
        self._refreshingPetInspectorPageSelector = false
    end

    if self.PetInspectorPreviousButton and self.PetInspectorPreviousButton.SetEnabled then
        self.PetInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end

    if self.PetInspectorNextButton and self.PetInspectorNextButton.SetEnabled then
        self.PetInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetPetInspectorTab(tabKey)
    local pages = self:GetPetInspectorPageDefinitions()
    self.ActivePetInspectorPageIndex = self:GetPetInspectorPageIndexByKey(tabKey or "general")
    self.ActivePetInspectorTabKey = pages[self.ActivePetInspectorPageIndex] and pages[self.ActivePetInspectorPageIndex].key or "general"

    local pageFrames = {
        general = self.PetInspectorGeneralPage,
        spells = self.PetInspectorSpellsPage,
        equipment = self.PetInspectorEquipmentPage,
    }

    for key, page in pairs(pageFrames) do
        if page then
            if key == self.ActivePetInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    self:RefreshPetInspectorPageSelector()
end
