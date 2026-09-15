local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Shared = DataEditor.ItemInspectorShared or {}
local Database = Addon.Internal and Addon.Internal.Database or {}

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

local function buildClassTraitReferenceItems(self)
    local items = {}
    local datasets = Database.ListDatasets and Database.ListDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = tostring(dataset and dataset.id or "")
        local datasetName = tostring(dataset and dataset.name or datasetId)
        for traitIndex = 1, #(dataset and dataset.traits or {}) do
            local trait = dataset.traits[traitIndex]
            if trait and trait.id and datasetId ~= "" then
                items[#items + 1] = {
                    label = ("%s / %s"):format(datasetName, tostring(trait.name or trait.id)),
                    value = ("%s:%s"):format(datasetId, tostring(trait.id)),
                }
            end
        end
    end
    return items
end

local function normalizeTraitRefs(values, excluded)
    local refs, seen = {}, {}
    for index = 1, #(values or {}) do
        local ref = tostring(values[index] or "")
        if ref ~= "" and not seen[ref] and not (excluded and excluded[ref]) then
            seen[ref] = true
            refs[#refs + 1] = ref
        end
    end
    return refs
end

local function ensureClassTraitOwnershipControls(self)
    if self.ClassInspectorPassiveTraitsDropdown or not self.ClassInspectorTraitsPage then return end
    local page = self.ClassInspectorTraitsPage
    local overlay = CreateFrame("Frame", "RPEDataEditorClassInspectorTraitOwnershipPage", page)
    overlay:SetAllPoints(page)
    overlay:SetFrameLevel(page:GetFrameLevel() + 10)
    self.ClassInspectorTraitOwnershipOverlay = overlay
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, overlay, "RPEDataEditorClassInspectorTraitOwnershipLayout", {
        spacing = 8, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, overlay, 0, 0, 0, 0)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorClassPassivesLabel", "Class Passives"))
    self.ClassInspectorPassiveTraitsDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorClassPassivesDropdown", {
        width = FIELD_WIDTH, height = 48, multiSelect = true, showSelectionActions = false, items = {},
        onValueChanged = function(values)
            if self._refreshingClassTraitOwnership then return end
            commitSelectedClass(self, function(class)
                local excluded = {}
                for index = 1, #(class.talentTraitRefs or {}) do excluded[class.talentTraitRefs[index]] = true end
                class.passiveTraitRefs = normalizeTraitRefs(values, excluded)
            end)
        end,
    })
    root:AddChild(self.ClassInspectorPassiveTraitsDropdown)
    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorClassTalentsLabel", "Talents"))
    self.ClassInspectorTalentTraitsDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorClassTalentsDropdown", {
        width = FIELD_WIDTH, height = 48, multiSelect = true, showSelectionActions = false, items = {},
        onValueChanged = function(values)
            if self._refreshingClassTraitOwnership then return end
            commitSelectedClass(self, function(class)
                local excluded = {}
                for index = 1, #(class.passiveTraitRefs or {}) do excluded[class.passiveTraitRefs[index]] = true end
                class.talentTraitRefs = normalizeTraitRefs(values, excluded)
            end)
        end,
    })
    root:AddChild(self.ClassInspectorTalentTraitsDropdown)
    self.ClassInspectorTraitOwnershipHint = buildLabel(root:GetFrame(), "RPEDataEditorClassTraitOwnershipHint", "A trait may be a passive or talent, not both.")
    root:AddChild(self.ClassInspectorTraitOwnershipHint)
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

function DataEditor:RefreshClassInspectorTraitOwnershipFields()
    local class = self:GetSelectedClass()
    local hasClass = class ~= nil
    local items = buildClassTraitReferenceItems(self)
    self._refreshingClassTraitOwnership = true
    if self.ClassInspectorPassiveTraitsDropdown then
        self.ClassInspectorPassiveTraitsDropdown:SetItems(items)
        self.ClassInspectorPassiveTraitsDropdown:SetSelectedValues(class and class.passiveTraitRefs or {}, true)
        setDropdownEnabled(self.ClassInspectorPassiveTraitsDropdown, hasClass)
    end
    if self.ClassInspectorTalentTraitsDropdown then
        self.ClassInspectorTalentTraitsDropdown:SetItems(items)
        self.ClassInspectorTalentTraitsDropdown:SetSelectedValues(class and class.talentTraitRefs or {}, true)
        setDropdownEnabled(self.ClassInspectorTalentTraitsDropdown, hasClass)
    end
    self._refreshingClassTraitOwnership = false
end

function DataEditor:BuildClassInspectorPage(parent)
    local page = self:BuildProgressionDefinitionInspectorPage(parent, "classes")
    ensureClassEquipmentControls(self)
    ensureClassTraitOwnershipControls(self)
    self:RefreshClassInspectorEquipmentFields()
    self:RefreshClassInspectorTraitOwnershipFields()
    return page
end

function DataEditor:RefreshClassInspectorPage()
    self:RefreshProgressionDefinitionInspectorPage("classes")
    self:RefreshClassInspectorEquipmentFields()
    self:RefreshClassInspectorTraitOwnershipFields()
end
