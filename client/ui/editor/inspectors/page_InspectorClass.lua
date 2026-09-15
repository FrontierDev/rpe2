local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Shared = DataEditor.ItemInspectorShared or {}

local FIELD_WIDTH = 236
local ARMOR_WEIGHT_ITEMS = Shared.ARMOR_WEIGHT_ITEMS or {
    { label = "Cosmetic", value = "cosmetic" },
    { label = "Cloth", value = "cloth" },
    { label = "Leather", value = "leather" },
    { label = "Mail", value = "mail" },
    { label = "Plate", value = "plate" },
    { label = "Shield", value = "shield" },
}

local function buildLabel(parent, name, text)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
end

local function setDropdownEnabled(dropdown, enabled)
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

local function commitSelectedClass(self, mutate)
    local dataset = self:GetSelectedDataset()
    local class = self:GetSelectedClass()
    if not dataset or not class or type(mutate) ~= "function" then
        return
    end

    local before = self:DeepCopyValue(class)
    mutate(class, dataset)
    if self:DeepEqualValues(before, class) then
        return
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "classes")
end

local function ensureClassEquipmentControls(self)
    if self.ClassInspectorArmorWeightsDropdown or not self.ClassInspectorGeneralPage then
        return
    end

    local page = self.ClassInspectorGeneralPage

    self.ClassInspectorArmorWeightsLabel = buildLabel(page, "RPEDataEditorClassInspectorArmorWeightsLabel", "Allowed Armor Types")
    self.ClassInspectorArmorWeightsLabel:GetFrame():SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 56)

    self.ClassInspectorArmorWeightsDropdown = UI.CreateDropdown(page, "RPEDataEditorClassInspectorArmorWeightsDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = ARMOR_WEIGHT_ITEMS,
        multiSelect = true,
        showSelectionActions = false,
        onValueChanged = function(values)
            if self._refreshingClassInspector then
                return
            end

            commitSelectedClass(self, function(class)
                class.armorWeights = values or {}
            end)
        end,
    })
    self.ClassInspectorArmorWeightsDropdown:GetFrame():SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 36)

    self.ClassInspectorWeaponTypesLabel = buildLabel(page, "RPEDataEditorClassInspectorWeaponTypesLabel", "Allowed Weapon Types")
    self.ClassInspectorWeaponTypesLabel:GetFrame():SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 20)

    self.ClassInspectorWeaponTypesDropdown = UI.CreateDropdown(page, "RPEDataEditorClassInspectorWeaponTypesDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self.BuildItemInspectorWeaponTypeItems and self:BuildItemInspectorWeaponTypeItems(false) or {},
        multiSelect = true,
        showSelectionActions = false,
        onValueChanged = function(values)
            if self._refreshingClassInspector then
                return
            end

            commitSelectedClass(self, function(class)
                class.weaponTypeRefs = values or {}
            end)
        end,
    })
    self.ClassInspectorWeaponTypesDropdown:GetFrame():SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
end

function DataEditor:RefreshClassInspectorEquipmentFields()
    local class = self:GetSelectedClass()
    local hasClass = class ~= nil

    if self.ClassInspectorArmorWeightsDropdown then
        self.ClassInspectorArmorWeightsDropdown:SetItems(ARMOR_WEIGHT_ITEMS)
        self.ClassInspectorArmorWeightsDropdown:SetSelectedValues(class and class.armorWeights or {}, true)
        setDropdownEnabled(self.ClassInspectorArmorWeightsDropdown, hasClass)
    end

    if self.ClassInspectorWeaponTypesDropdown then
        local items = self.BuildItemInspectorWeaponTypeItems and self:BuildItemInspectorWeaponTypeItems(false) or {}
        self.ClassInspectorWeaponTypesDropdown:SetItems(items)
        self.ClassInspectorWeaponTypesDropdown:SetSelectedValues(class and class.weaponTypeRefs or {}, true)
        setDropdownEnabled(self.ClassInspectorWeaponTypesDropdown, hasClass)
    end
end

function DataEditor:BuildClassInspectorPage(parent)
    local page = self:BuildProgressionDefinitionInspectorPage(parent, "classes")
    ensureClassEquipmentControls(self)
    self:RefreshClassInspectorEquipmentFields()
    return page
end

function DataEditor:RefreshClassInspectorPage()
    self:RefreshProgressionDefinitionInspectorPage("classes")
    self:RefreshClassInspectorEquipmentFields()
end
