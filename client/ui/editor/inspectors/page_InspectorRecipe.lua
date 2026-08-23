local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local RecipeClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Recipe or nil
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Equipment = Addon.Internal and Addon.Internal.Profile and Addon.Internal.Profile.Equipment or {}
local Tooltips = Addon.Tooltips or {}
local ItemTooltip = Tooltips.Item or nil

local SIDE_PADDING = 8
local FIELD_WIDTH = 236
local CONTROL_HEIGHT = 20

local INPUT_KIND_ITEMS = {
    { label = "RPE Material", value = "rpe_item" },
    { label = "Tool", value = "tool" },
}

local RECIPE_LEARN_MODE_ITEMS = {
    { label = "Always Learned", value = "always_learned" },
    { label = "Trainer", value = "trainer" },
    { label = "Book", value = "book" },
    { label = "Unavailable", value = "unavailable" },
}

local RECIPE_INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "output", label = "Output" },
    { key = "inputs", label = "Inputs" },
}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function parseDatasetQualifiedRef(value)
    local datasetId, entryId = ensureString(value):match("^([^:]+):(.+)$")
    return datasetId, entryId
end

local function titleCaseWords(text)
    local normalized = ensureString(text):gsub("_", " "):gsub("%s+", " ")
    return (normalized:gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end))
end

local function buildLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
end

local function setTextElementEnabled(element, enabled)
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

local function setElementGroupVisible(group, visible)
    if not group then
        return
    end

    local frame = group.GetFrame and group:GetFrame() or nil
    local targetHeight = visible and group._visibleHeight or 0

    if group.SetHeight then
        group:SetHeight(targetHeight or 0)
    elseif group.options then
        group.options.height = targetHeight or 0
    end

    if frame then
        if frame.SetHeight then
            frame:SetHeight(targetHeight or 0)
        end

        if visible then
            frame:Show()
        else
            frame:Hide()
        end
    end
end

local function createPageFrame(parent, name)
    local page = CreateFrame("Frame", name, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", SIDE_PADDING, -24)
    page:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -SIDE_PADDING, -24)
    page:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", SIDE_PADDING, 24)
    page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -SIDE_PADDING, 24)
    return page
end

local function createFieldGroup(parent, name, labelText, height)
    local groupHeight = 14 + 2 + (height or CONTROL_HEIGHT)
    local group = UI.CreateLayout(UI.VerticalLayoutGroup, parent:GetFrame(), name, {
        width = FIELD_WIDTH,
        height = groupHeight,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    group._visibleHeight = groupHeight
    parent:AddChild(group)
    group:AddChild(buildLabel(group:GetFrame(), name .. "Label", labelText))
    return group
end

local function deriveRecipeCategoryFromItem(item)
    if type(item) ~= "table" then
        return "General"
    end

    local itemType = tostring(item.itemType or "none")
    if itemType == "armor" then
        local armorWeight = tostring(item.armorWeight or "")
        if armorWeight == "shield" then
            return "Shield"
        end
        if armorWeight ~= "" and armorWeight ~= "cosmetic" and armorWeight ~= "none" then
            return titleCaseWords(armorWeight) .. " Armor"
        end
        return "Armor"
    end
    if itemType == "weapon" then
        local weaponTypeName = Registry.ResolveWeaponTypeName and Registry:ResolveWeaponTypeName(item.weaponTypeRef) or ""
        if weaponTypeName ~= "" and weaponTypeName ~= ensureString(item.weaponTypeRef) then
            return weaponTypeName
        end
        return "Weapon"
    end
    if itemType == "modification" then
        local modificationKind = tostring(item.modificationKind or "generic")
        if modificationKind == "gem" then
            return "Gem"
        end
        if modificationKind == "enchant" then
            return "Enchantment"
        end
        return "Modification"
    end
    if itemType == "consumable" then
        local consumableType = tostring(item.consumableType or "")
        if consumableType == "elixir" then
            return "Elixir"
        end
        if consumableType ~= "" then
            return titleCaseWords(consumableType)
        end
        return "Consumable"
    end
    if itemType == "material" then
        return "Material"
    end

    return titleCaseWords(itemType ~= "" and itemType or "General")
end

local function getRecipeOutputItemTypeLabel(itemType)
    local normalizedType = ensureString(itemType)
    if normalizedType == "material" then
        return "Material"
    end
    if normalizedType == "modification" then
        return "Modification"
    end
    if normalizedType == "consumable" then
        return "Consumable"
    end
    if normalizedType == "weapon" then
        return "Weapon"
    end
    if normalizedType == "armor" then
        return "Armor"
    end
    if normalizedType == "tool" then
        return "Tool"
    end

    return titleCaseWords(normalizedType ~= "" and normalizedType or "General")
end

local function compareRecipeDropdownLabels(left, right)
    return string.lower(ensureString(left)) < string.lower(ensureString(right))
end

local function resolveRecipeOutputNameFromRef(itemRef)
    if not Registry.ResolveItemReference then
        return nil
    end

    local _, item = Registry:ResolveItemReference(itemRef)
    if type(item) ~= "table" then
        return nil
    end

    local name = ensureString(item.name)
    if name == "" then
        return nil
    end

    return name
end

local function resolveRecipeOutputSlotLabel(self, slotRef)
    if Equipment.ResolveSlotDefinition then
        local itemSlot = Equipment.ResolveSlotDefinition(slotRef)
        if itemSlot then
            local slotName = ensureString(itemSlot.name) ~= "" and ensureString(itemSlot.name) or ensureString(itemSlot.id)
            if slotName ~= "" then
                return Equipment.PrettySlotLabel and Equipment.PrettySlotLabel(slotName) or slotName
            end
        end
    end

    local datasetId, slotId = parseDatasetQualifiedRef(slotRef)
    if datasetId == "" or slotId == "" then
        return nil
    end

    local dataset = self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
    local itemSlots = dataset and dataset.itemSlots or nil
    if type(itemSlots) ~= "table" then
        return nil
    end

    for index = 1, #itemSlots do
        local itemSlot = itemSlots[index]
        if itemSlot and itemSlot.id == slotId then
            local slotName = ensureString(itemSlot.name) ~= "" and ensureString(itemSlot.name) or ensureString(itemSlot.id)
            return Equipment.PrettySlotLabel and Equipment.PrettySlotLabel(slotName) or slotName
        end
    end

    return nil
end

local function collectRecipeOutputSlotLabels(self, slotRefs)
    local labels = {}
    local seen = {}
    for index = 1, #(slotRefs or {}) do
        local label = resolveRecipeOutputSlotLabel(self, ensureString(slotRefs[index]))
        if label and label ~= "" and not seen[label] then
            seen[label] = true
            labels[#labels + 1] = label
        end
    end

    if #labels > 0 then
        table.sort(labels, compareRecipeDropdownLabels)
    end

    return labels
end

local function getRecipeOutputCategoryLabels(self, item)
    if type(item) ~= "table" then
        return { "General" }
    end

    local itemType = tostring(item.itemType or "")
    if itemType == "modification" then
        local labels = collectRecipeOutputSlotLabels(self, item.targetSlotRefs)
        if #labels > 0 then
            return labels
        end
    elseif itemType == "armor" then
        local labels = collectRecipeOutputSlotLabels(self, item.validSlotRefs)
        if #labels > 0 then
            return labels
        end
    end

    return { deriveRecipeCategoryFromItem(item) }
end

function DataEditor:GetSelectedRecipe()
    return self:GetSelectedDatasetEntry("recipes")
end

function DataEditor:GetSelectedRecipeAndDataset()
    return self:GetSelectedDataset(), self:GetSelectedRecipe()
end

function DataEditor:NormalizeRecipeDefinition(recipe)
    if RecipeClass and RecipeClass.New and RecipeClass.ToTable then
        return RecipeClass.ToTable(RecipeClass:New(recipe))
    end

    return recipe or {}
end

function DataEditor:CommitSelectedRecipe(mutate)
    local dataset, recipe = self:GetSelectedRecipeAndDataset()
    if not dataset or not recipe or type(mutate) ~= "function" then
        return
    end

    local before = self:DeepCopyValue(recipe)
    mutate(recipe, dataset)
    local normalized = self:NormalizeRecipeDefinition(recipe)
    for key in pairs(recipe) do
        if normalized[key] == nil then
            recipe[key] = nil
        end
    end
    for key, value in pairs(normalized) do
        recipe[key] = value
    end

    if self:DeepEqualValues(before, recipe) then
        return
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "recipes")
end

function DataEditor:GetDerivedRecipeOutputItem(recipe)
    if not recipe or not recipe.output or not recipe.output.itemRef or not Registry.ResolveItemReference then
        return nil
    end

    local _, item = Registry:ResolveItemReference(recipe.output.itemRef)
    return item
end

function DataEditor:GetDerivedRecipeName(recipe)
    local storedName = recipe and recipe.name ~= nil and ensureString(recipe.name) or ""
    if storedName ~= "" then
        return storedName
    end

    local item = self:GetDerivedRecipeOutputItem(recipe)
    if item and ensureString(item.name) ~= "" then
        return ensureString(item.name)
    end

    return "Missing Output Item"
end

function DataEditor:GetDerivedRecipeCategory(recipe)
    return deriveRecipeCategoryFromItem(self:GetDerivedRecipeOutputItem(recipe))
end

function DataEditor:GetRecipeInspectorPageDefinitions()
    return RECIPE_INSPECTOR_PAGE_DEFINITIONS
end

function DataEditor:GetRecipeInspectorPageIndexByKey(key)
    local pages = self:GetRecipeInspectorPageDefinitions()
    for index = 1, #pages do
        if pages[index].key == key then
            return index
        end
    end

    return 1
end

function DataEditor:BuildRecipeInspectorPageSelectorItems()
    local items = {}
    local pages = self:GetRecipeInspectorPageDefinitions()
    for index = 1, #pages do
        items[#items + 1] = {
            label = pages[index].label,
            value = pages[index].key,
        }
    end

    return items
end

function DataEditor:RefreshRecipeInspectorPageSelector()
    local pages = self:GetRecipeInspectorPageDefinitions()
    local pageCount = #pages
    local activeIndex = math.max(1, math.min(self.ActiveRecipeInspectorPageIndex or 1, pageCount))
    self.ActiveRecipeInspectorPageIndex = activeIndex
    self.ActiveRecipeInspectorTabKey = pages[activeIndex] and pages[activeIndex].key or "general"

    local activeDefinition = pages[activeIndex]
    if self.RecipeInspectorPageDropdown and activeDefinition then
        self._refreshingRecipeInspectorPageSelector = true
        self.RecipeInspectorPageDropdown:SetItems(self:BuildRecipeInspectorPageSelectorItems())
        self.RecipeInspectorPageDropdown:SetSelectedValue(activeDefinition.key, true)
        self._refreshingRecipeInspectorPageSelector = false
    end

    if self.RecipeInspectorPreviousButton and self.RecipeInspectorPreviousButton.SetEnabled then
        self.RecipeInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end
    if self.RecipeInspectorNextButton and self.RecipeInspectorNextButton.SetEnabled then
        self.RecipeInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetRecipeInspectorTab(tabKey, skipRefresh)
    local pageDefinitions = self:GetRecipeInspectorPageDefinitions()
    self.ActiveRecipeInspectorPageIndex = self:GetRecipeInspectorPageIndexByKey(tabKey or "general")
    self.ActiveRecipeInspectorTabKey = pageDefinitions[self.ActiveRecipeInspectorPageIndex] and pageDefinitions[self.ActiveRecipeInspectorPageIndex].key or "general"

    local pageFrames = {
        general = self.RecipeInspectorGeneralPage,
        output = self.RecipeInspectorOutputPage,
        inputs = self.RecipeInspectorInputsPage,
    }

    for key, page in pairs(pageFrames) do
        if page then
            if key == self.ActiveRecipeInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    self:RefreshRecipeInspectorPageSelector()
    if skipRefresh ~= true then
        self:RefreshRecipeInspectorPage()
    end
end

local function getRecipeInputItemTypeFilter(kind)
    if kind == "tool" then
        return "tool"
    end
    if kind == "rpe_item" then
        return "material"
    end

    return nil
end

function DataEditor:BuildRecipeInspectorDatasetItems(inputKind)
    local itemTypeFilter = getRecipeInputItemTypeFilter(inputKind)
    if itemTypeFilter == nil or itemTypeFilter == "" then
        return self:BuildItemInspectorDatasetItems()
    end

    local items = {
        { label = "None", value = "" },
    }

    local datasets = self:GetDatasets()
    for index = 1, #datasets do
        local dataset = datasets[index]
        local collection = dataset and dataset.items or {}
        local hasMatch = false

        for itemIndex = 1, #collection do
            local item = collection[itemIndex]
            if item and item.id and tostring(item.itemType or "") == itemTypeFilter then
                hasMatch = true
                break
            end
        end

        if hasMatch then
            items[#items + 1] = {
                label = self:GetDatasetDisplayName(dataset),
                value = dataset.id,
            }
        end
    end

    return items
end

function DataEditor:BuildRecipeInspectorDatasetItemItems(datasetId, inputKind)
    local items = self:BuildItemInspectorDatasetCollectionItems("items", datasetId, {
        noneLabel = "None",
    })

    local itemTypeFilter = getRecipeInputItemTypeFilter(inputKind)
    if itemTypeFilter == nil or itemTypeFilter == "" or datasetId == nil or datasetId == "" or not self.Database or not self.Database.GetDatasetByID then
        return items
    end

    local dataset = self.Database.GetDatasetByID(datasetId)
    local allowedRefs = {}
    for index = 1, #(dataset and dataset.items or {}) do
        local item = dataset.items[index]
        if item and item.id and tostring(item.itemType or "") == itemTypeFilter then
            allowedRefs[("%s:%s"):format(datasetId, item.id)] = true
        end
    end

    local filtered = {
        items[1] or { label = "None", value = "" },
    }

    for index = 2, #items do
        local item = items[index]
        if item and type(item.children) == "table" then
            local children = {}
            for childIndex = 1, #item.children do
                local child = item.children[childIndex]
                if child and allowedRefs[ensureString(child.value)] then
                    children[#children + 1] = child
                end
            end

            if #children > 0 then
                filtered[#filtered + 1] = {
                    label = item.label,
                    value = item.value,
                    enabled = item.enabled,
                    keepShownOnClick = item.keepShownOnClick,
                    notCheckable = item.notCheckable,
                    children = children,
                }
            end
        elseif item and allowedRefs[ensureString(item.value)] then
            filtered[#filtered + 1] = item
        end
    end

    return filtered
end

function DataEditor:BuildRecipeInspectorOutputItemItems(datasetId)
    local items = {
        { label = "None", value = "" },
    }

    if datasetId == nil or datasetId == "" or not self.Database or not self.Database.GetDatasetByID then
        return items
    end

    local dataset = self.Database.GetDatasetByID(datasetId)
    local collection = dataset and dataset.items or {}
    local typeMap = {}
    local typeOrder = {}

    local function ensureTypeGroup(itemType)
        local normalizedType = ensureString(itemType)
        local existing = typeMap[normalizedType]
        if existing then
            return existing
        end

        local group = {
            label = getRecipeOutputItemTypeLabel(normalizedType),
            value = ("recipe-output-type:%s:%s"):format(datasetId, normalizedType ~= "" and normalizedType or "general"),
            enabled = true,
            keepShownOnClick = true,
            notCheckable = true,
            children = {},
            _categoryMap = {},
            _categoryOrder = {},
        }
        typeMap[normalizedType] = group
        typeOrder[#typeOrder + 1] = normalizedType
        return group
    end

    local function ensureCategoryGroup(typeGroup, categoryLabel)
        local normalizedLabel = ensureString(categoryLabel)
        local categoryMap = typeGroup._categoryMap or {}
        local existing = categoryMap[normalizedLabel]
        if existing then
            return existing
        end

        local group = {
            label = normalizedLabel ~= "" and normalizedLabel or "General",
            value = ("%s:category:%s"):format(typeGroup.value, normalizedLabel ~= "" and normalizedLabel or "General"),
            enabled = true,
            keepShownOnClick = true,
            notCheckable = true,
            children = {},
        }
        categoryMap[normalizedLabel] = group
        typeGroup._categoryMap = categoryMap
        typeGroup._categoryOrder = typeGroup._categoryOrder or {}
        typeGroup._categoryOrder[#typeGroup._categoryOrder + 1] = normalizedLabel
        return group
    end

    for index = 1, #collection do
        local item = collection[index]
        if item and item.id then
            local itemType = ensureString(item.itemType)
            local typeGroup = ensureTypeGroup(itemType)
            local itemLeaf = {
                label = self:GetEntryDisplayName("items", item),
                value = ("%s:%s"):format(datasetId, item.id),
            }
            if ItemTooltip and ItemTooltip.Build then
                itemLeaf.tooltip = ItemTooltip:Build(item, {
                    itemId = item.id,
                    isActive = true,
                })
            end

            if itemType == "material" then
                typeGroup.children[#typeGroup.children + 1] = itemLeaf
            else
                local categoryLabels = getRecipeOutputCategoryLabels(self, item)
                for categoryIndex = 1, #categoryLabels do
                    local categoryGroup = ensureCategoryGroup(typeGroup, categoryLabels[categoryIndex])
                    categoryGroup.children[#categoryGroup.children + 1] = itemLeaf
                end
            end
        end
    end

    table.sort(typeOrder, function(left, right)
        local leftGroup = typeMap[left]
        local rightGroup = typeMap[right]
        return compareRecipeDropdownLabels(leftGroup and leftGroup.label or "", rightGroup and rightGroup.label or "")
    end)

    for typeIndex = 1, #typeOrder do
        local typeGroup = typeMap[typeOrder[typeIndex]]
        if typeGroup then
            if typeOrder[typeIndex] == "material" then
                table.sort(typeGroup.children, function(left, right)
                    return compareRecipeDropdownLabels(left and left.label or "", right and right.label or "")
                end)
            else
                table.sort(typeGroup._categoryOrder or {}, function(left, right)
                    return compareRecipeDropdownLabels(left, right)
                end)

                typeGroup.children = {}
                for categoryIndex = 1, #(typeGroup._categoryOrder or {}) do
                    local categoryKey = typeGroup._categoryOrder[categoryIndex]
                    local categoryGroup = typeGroup._categoryMap and typeGroup._categoryMap[categoryKey] or nil
                    if categoryGroup then
                        table.sort(categoryGroup.children, function(left, right)
                            return compareRecipeDropdownLabels(left and left.label or "", right and right.label or "")
                        end)
                        typeGroup.children[#typeGroup.children + 1] = categoryGroup
                    end
                end
            end

            typeGroup._categoryMap = nil
            typeGroup._categoryOrder = nil

            if #typeGroup.children > 0 then
                items[#items + 1] = typeGroup
            end
        end
    end

    return items
end

function DataEditor:EnsureRecipeInspectorInputDraft()
    self.RecipeInspectorInputDraft = self.RecipeInspectorInputDraft or {
        kind = "rpe_item",
        datasetId = "",
        itemRef = "",
        quantity = "1",
    }

    local draft = self.RecipeInspectorInputDraft
    draft.kind = ensureString(draft.kind)
    if draft.kind ~= "rpe_item" and draft.kind ~= "tool" then
        draft.kind = "rpe_item"
    end
    draft.datasetId = ensureString(draft.datasetId)
    draft.itemRef = ensureString(draft.itemRef)
    draft.quantity = ensureString(draft.quantity) ~= "" and ensureString(draft.quantity) or "1"
    return draft
end

function DataEditor:SetRecipeInspectorInputDraft(input)
    local draft = self:EnsureRecipeInspectorInputDraft()

    if type(input) ~= "table" then
        draft.kind = "rpe_item"
        draft.datasetId = ""
        draft.itemRef = ""
        draft.quantity = "1"
        return
    end

    local kind = ensureString(input.kind)
    if kind ~= "rpe_item" and kind ~= "tool" then
        kind = "rpe_item"
    end

    draft.kind = kind
    draft.quantity = tostring(math.max(1, tonumber(input.quantity) or 1))
    draft.datasetId = ensureString(select(1, parseDatasetQualifiedRef(input.itemRef)))
    draft.itemRef = ensureString(input.itemRef)
end

function DataEditor:RefreshRecipeInspectorOutputControls(hasRecipe, recipe)
    local outputRef = hasRecipe and ensureString(recipe.output and recipe.output.itemRef) or ""
    local outputDatasetId = ensureString(select(1, parseDatasetQualifiedRef(outputRef)))

    self.RecipeInspectorOutputDatasetDraftId = outputDatasetId

    if self.RecipeInspectorOutputDatasetDropdown then
        self.RecipeInspectorOutputDatasetDropdown:SetItems(self:BuildItemInspectorDatasetItems())
        self.RecipeInspectorOutputDatasetDropdown:SetSelectedValue(outputDatasetId, true)
        setDropdownEnabled(self.RecipeInspectorOutputDatasetDropdown, hasRecipe)
    end

    if self.RecipeInspectorOutputItemDropdown then
        self.RecipeInspectorOutputItemDropdown:SetItems(self:BuildRecipeInspectorOutputItemItems(outputDatasetId))
        self.RecipeInspectorOutputItemDropdown:SetSelectedValue(outputRef, true)
        setDropdownEnabled(self.RecipeInspectorOutputItemDropdown, hasRecipe and outputDatasetId ~= "")
    end

    if self.RecipeInspectorOutputMinInput then
        self.RecipeInspectorOutputMinInput:SetText(tostring(hasRecipe and (tonumber(recipe.output and recipe.output.minQuantity) or 1) or 1))
        setTextElementEnabled(self.RecipeInspectorOutputMinInput, hasRecipe)
    end

    if self.RecipeInspectorOutputMaxInput then
        self.RecipeInspectorOutputMaxInput:SetText(tostring(hasRecipe and (tonumber(recipe.output and recipe.output.maxQuantity) or 1) or 1))
        setTextElementEnabled(self.RecipeInspectorOutputMaxInput, hasRecipe)
    end

    if self.RecipeInspectorOutputRoot and self.RecipeInspectorOutputRoot.RefreshLayout then
        self.RecipeInspectorOutputRoot:RefreshLayout()
    end
end

function DataEditor:RefreshRecipeInspectorInputEditorControls(hasRecipe)
    local draft = self:EnsureRecipeInspectorInputDraft()

    if self.RecipeInspectorInputKindDropdown then
        self.RecipeInspectorInputKindDropdown:SetSelectedValue(draft.kind, true)
        setDropdownEnabled(self.RecipeInspectorInputKindDropdown, hasRecipe)
    end

    if self.RecipeInspectorInputDatasetDropdown then
        self.RecipeInspectorInputDatasetDropdown:SetItems(self:BuildRecipeInspectorDatasetItems(draft.kind))
        self.RecipeInspectorInputDatasetDropdown:SetSelectedValue(draft.datasetId, true)
        setDropdownEnabled(self.RecipeInspectorInputDatasetDropdown, hasRecipe)
    end

    if self.RecipeInspectorInputItemDropdown then
        self.RecipeInspectorInputItemDropdown:SetItems(self:BuildRecipeInspectorDatasetItemItems(draft.datasetId, draft.kind))
        self.RecipeInspectorInputItemDropdown:SetSelectedValue(draft.itemRef, true)
        setDropdownEnabled(self.RecipeInspectorInputItemDropdown, hasRecipe and ensureString(draft.datasetId) ~= "")
    end

    if self.RecipeInspectorInputQuantityInput then
        self.RecipeInspectorInputQuantityInput:SetText(draft.quantity)
        setTextElementEnabled(self.RecipeInspectorInputQuantityInput, hasRecipe)
    end

    if self.RecipeInspectorApplyInputButton then
        self.RecipeInspectorApplyInputButton:SetEnabled(hasRecipe)
    end

    setElementGroupVisible(self.RecipeInspectorInputDatasetGroup, true)
    setElementGroupVisible(self.RecipeInspectorInputItemGroup, true)

    if self.RecipeInspectorInputsRoot and self.RecipeInspectorInputsRoot.RefreshLayout then
        self.RecipeInspectorInputsRoot:RefreshLayout()
    end
end

function DataEditor:BuildRecipeInspectorInputRows(recipe)
    local rows = {}
    for index = 1, #(recipe and recipe.inputs or {}) do
        local input = recipe.inputs[index]
        local summary = Registry.ResolveItemName and Registry:ResolveItemName(input.itemRef) or ensureString(input.itemRef)

        rows[#rows + 1] = {
            rowIndex = index,
            kindText = titleCaseWords(ensureString(input.kind):gsub("_", " ")),
            summary = summary,
            quantityText = tostring(tonumber(input.quantity) or 1),
        }
    end

    return rows
end

function DataEditor:RefreshRecipeInspectorInputsTable()
    local _, recipe = self:GetSelectedRecipeAndDataset()
    local rows = self:BuildRecipeInspectorInputRows(recipe)
    if self.RecipeInspectorInputsScroll and self.RecipeInspectorInputsScroll.SetItems then
        self.RecipeInspectorInputsScroll:SetItems(rows)
    end
end

function DataEditor:EnsureRecipeInspectorInputContextMenu()
    if self.RecipeInspectorInputContextMenu then
        return self.RecipeInspectorInputContextMenu
    end

    self.RecipeInspectorInputContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorRecipeInspectorInputContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 1,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-input" or not self.ContextMenuRecipeInputIndex then
                return
            end

            local removeIndex = self.ContextMenuRecipeInputIndex
            self:CommitSelectedRecipe(function(recipe)
                recipe.inputs = recipe.inputs or {}
                table.remove(recipe.inputs, removeIndex)
            end)

            self.SelectedRecipeInputIndex = nil
            self.ContextMenuRecipeInputIndex = nil
            self:SetRecipeInspectorInputDraft(nil)
            self:RefreshRecipeInspectorPage()

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.RecipeInspectorInputContextMenu:SetParent(self.Window and self.Window:GetFrame() or UIParent)
    self.RecipeInspectorInputContextMenu:Create()
    return self.RecipeInspectorInputContextMenu
end

function DataEditor:ShowRecipeInspectorInputContextMenu(anchorFrame, rowData)
    if not anchorFrame or not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureRecipeInspectorInputContextMenu()
    self.ContextMenuRecipeInputIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-input" },
    })
    menu:ShowAt(anchorFrame)
end

local function buildGeneralPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorRecipeInspectorGeneralRoot", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)
    self.RecipeInspectorGeneralRoot = root

    self.RecipeInspectorIdText = buildLabel(root:GetFrame(), "RPEDataEditorRecipeInspectorIdText", "ID: -")
    root:AddChild(self.RecipeInspectorIdText)

    self.RecipeInspectorNameText = buildLabel(root:GetFrame(), "RPEDataEditorRecipeInspectorNameText", "Output Item: -")
    root:AddChild(self.RecipeInspectorNameText)

    self.RecipeInspectorCategoryText = buildLabel(root:GetFrame(), "RPEDataEditorRecipeInspectorCategoryText", "Category: -")
    root:AddChild(self.RecipeInspectorCategoryText)

    local skillGroup = createFieldGroup(root, "RPEDataEditorRecipeInspectorSkillGroup", "Crafting Skill")
    self.RecipeInspectorSkillDropdown = UI.CreateDropdown(skillGroup:GetFrame(), "RPEDataEditorRecipeInspectorSkillDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = self:BuildSpellInspectorSkillsAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingRecipeInspector then
                return
            end

            self:CommitSelectedRecipe(function(recipe)
                recipe.skillRef = value ~= "" and value or nil
            end)
        end,
    })
    skillGroup:AddChild(self.RecipeInspectorSkillDropdown)

    local requiredLevelGroup = createFieldGroup(root, "RPEDataEditorRecipeInspectorRequiredLevelGroup", "Required Level")
    self.RecipeInspectorRequiredLevelInput = UI.CreateTextInput(requiredLevelGroup:GetFrame(), "RPEDataEditorRecipeInspectorRequiredLevelInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.RecipeInspectorRequiredLevelInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedRecipe(function(recipe)
            recipe.requiredSkillLevel = tonumber(self.RecipeInspectorRequiredLevelInput:GetText()) or 0
        end)
    end)
    self.RecipeInspectorRequiredLevelInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedRecipe(function(recipe)
            recipe.requiredSkillLevel = tonumber(self.RecipeInspectorRequiredLevelInput:GetText()) or 0
        end)
    end)
    requiredLevelGroup:AddChild(self.RecipeInspectorRequiredLevelInput)

    local learnModeGroup = createFieldGroup(root, "RPEDataEditorRecipeInspectorLearnModeGroup", "Learn Mode")
    self.RecipeInspectorLearnModeDropdown = UI.CreateDropdown(learnModeGroup:GetFrame(), "RPEDataEditorRecipeInspectorLearnModeDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = RECIPE_LEARN_MODE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingRecipeInspector then
                return
            end

            self:CommitSelectedRecipe(function(recipe)
                recipe.learnMode = value or "trainer"
            end)
        end,
    })
    learnModeGroup:AddChild(self.RecipeInspectorLearnModeDropdown)
end

local function buildOutputPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorRecipeInspectorOutputRoot", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)
    self.RecipeInspectorOutputRoot = root

    local datasetGroup = createFieldGroup(root, "RPEDataEditorRecipeInspectorOutputDatasetGroup", "Output Dataset")
    self.RecipeInspectorOutputDatasetDropdown = UI.CreateDropdown(datasetGroup:GetFrame(), "RPEDataEditorRecipeInspectorOutputDatasetDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = self:BuildItemInspectorDatasetItems(),
        onValueChanged = function(value)
            if self._refreshingRecipeInspector then
                return
            end

            self.RecipeInspectorOutputDatasetDraftId = ensureString(value)
            if self.RecipeInspectorOutputItemDropdown then
                self.RecipeInspectorOutputItemDropdown:SetItems(self:BuildRecipeInspectorOutputItemItems(value))
                self.RecipeInspectorOutputItemDropdown:SetSelectedValue("", true)
                setDropdownEnabled(self.RecipeInspectorOutputItemDropdown, value ~= "")
            end
        end,
    })
    datasetGroup:AddChild(self.RecipeInspectorOutputDatasetDropdown)

    local itemGroup = createFieldGroup(root, "RPEDataEditorRecipeInspectorOutputItemGroup", "Output Item")
    self.RecipeInspectorOutputItemDropdown = UI.CreateDropdown(itemGroup:GetFrame(), "RPEDataEditorRecipeInspectorOutputItemDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingRecipeInspector then
                return
            end

            self:CommitSelectedRecipe(function(recipe)
                recipe.output = recipe.output or {}
                recipe.output.itemRef = value ~= "" and value or nil
                recipe.name = value ~= "" and (resolveRecipeOutputNameFromRef(value) or "") or ""
            end)
        end,
    })
    itemGroup:AddChild(self.RecipeInspectorOutputItemDropdown)

    local minGroup = createFieldGroup(root, "RPEDataEditorRecipeInspectorOutputMinGroup", "Output Min")
    self.RecipeInspectorOutputMinInput = UI.CreateTextInput(minGroup:GetFrame(), "RPEDataEditorRecipeInspectorOutputMinInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.RecipeInspectorOutputMinInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedRecipe(function(recipe)
            recipe.output = recipe.output or {}
            recipe.output.minQuantity = tonumber(self.RecipeInspectorOutputMinInput:GetText()) or 1
        end)
    end)
    self.RecipeInspectorOutputMinInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedRecipe(function(recipe)
            recipe.output = recipe.output or {}
            recipe.output.minQuantity = tonumber(self.RecipeInspectorOutputMinInput:GetText()) or 1
        end)
    end)
    minGroup:AddChild(self.RecipeInspectorOutputMinInput)

    local maxGroup = createFieldGroup(root, "RPEDataEditorRecipeInspectorOutputMaxGroup", "Output Max")
    self.RecipeInspectorOutputMaxInput = UI.CreateTextInput(maxGroup:GetFrame(), "RPEDataEditorRecipeInspectorOutputMaxInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.RecipeInspectorOutputMaxInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedRecipe(function(recipe)
            recipe.output = recipe.output or {}
            recipe.output.maxQuantity = tonumber(self.RecipeInspectorOutputMaxInput:GetText()) or 1
        end)
    end)
    self.RecipeInspectorOutputMaxInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedRecipe(function(recipe)
            recipe.output = recipe.output or {}
            recipe.output.maxQuantity = tonumber(self.RecipeInspectorOutputMaxInput:GetText()) or 1
        end)
    end)
    maxGroup:AddChild(self.RecipeInspectorOutputMaxInput)
end

local function buildInputsPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorRecipeInspectorInputsRoot", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)
    self.RecipeInspectorInputsRoot = root

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorRecipeInspectorInputsLabel", "Inputs"))

    self.RecipeInspectorInputsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorRecipeInspectorInputsPanel", {
        width = FIELD_WIDTH,
        height = 92,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.RecipeInspectorInputsPanel)

    self.RecipeInspectorInputsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorRecipeInspectorInputsScroll",
        width = FIELD_WIDTH,
        height = 90,
        visibleRows = 5,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.RecipeInspectorInputsScroll:SetParent(self.RecipeInspectorInputsPanel:GetContentFrame())
    self.RecipeInspectorInputsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "kindText", width = 72, justifyH = "LEFT" },
                { key = "summary", width = 120, justifyH = "LEFT" },
                { key = "quantityText", width = 32, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "LeftButton" then
                    local _, recipe = self:GetSelectedRecipeAndDataset()
                    self.SelectedRecipeInputIndex = rowData and rowData.rowIndex or nil
                    self:SetRecipeInspectorInputDraft(recipe and recipe.inputs and recipe.inputs[self.SelectedRecipeInputIndex] or nil)
                    self:RefreshRecipeInspectorPage()
                elseif button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowRecipeInspectorInputContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.RecipeInspectorInputsScroll:Create()
    UI.Utils.AnchorFill(self.RecipeInspectorInputsScroll, self.RecipeInspectorInputsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.RecipeInspectorInputKindGroup = createFieldGroup(root, "RPEDataEditorRecipeInspectorInputKindGroup", "Input Kind")
    self.RecipeInspectorInputKindDropdown = UI.CreateDropdown(self.RecipeInspectorInputKindGroup:GetFrame(), "RPEDataEditorRecipeInspectorInputKindDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = INPUT_KIND_ITEMS,
        onValueChanged = function(value)
            if self._refreshingRecipeInspector then
                return
            end

            local draft = self:EnsureRecipeInspectorInputDraft()
            draft.kind = ensureString(value) ~= "" and ensureString(value) or "rpe_item"
            draft.datasetId = ""
            draft.itemRef = ""
            self:RefreshRecipeInspectorInputEditorControls(true)
        end,
    })
    self.RecipeInspectorInputKindGroup:AddChild(self.RecipeInspectorInputKindDropdown)

    self.RecipeInspectorInputDatasetGroup = createFieldGroup(root, "RPEDataEditorRecipeInspectorInputDatasetGroup", "Item Dataset")
    self.RecipeInspectorInputDatasetDropdown = UI.CreateDropdown(self.RecipeInspectorInputDatasetGroup:GetFrame(), "RPEDataEditorRecipeInspectorInputDatasetDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingRecipeInspector then
                return
            end

            local draft = self:EnsureRecipeInspectorInputDraft()
            draft.datasetId = ensureString(value)
            draft.itemRef = ""
            self:RefreshRecipeInspectorInputEditorControls(true)
        end,
    })
    self.RecipeInspectorInputDatasetGroup:AddChild(self.RecipeInspectorInputDatasetDropdown)

    self.RecipeInspectorInputItemGroup = createFieldGroup(root, "RPEDataEditorRecipeInspectorInputItemGroup", "Item")
    self.RecipeInspectorInputItemDropdown = UI.CreateDropdown(self.RecipeInspectorInputItemGroup:GetFrame(), "RPEDataEditorRecipeInspectorInputItemDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingRecipeInspector then
                return
            end

            local draft = self:EnsureRecipeInspectorInputDraft()
            draft.itemRef = ensureString(value)
        end,
    })
    self.RecipeInspectorInputItemGroup:AddChild(self.RecipeInspectorInputItemDropdown)

    self.RecipeInspectorInputQuantityGroup = createFieldGroup(root, "RPEDataEditorRecipeInspectorInputQuantityGroup", "Quantity")
    self.RecipeInspectorInputQuantityInput = UI.CreateTextInput(self.RecipeInspectorInputQuantityGroup:GetFrame(), "RPEDataEditorRecipeInspectorInputQuantityInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.RecipeInspectorInputQuantityInput:SetScript("OnEditFocusLost", function()
        local draft = self:EnsureRecipeInspectorInputDraft()
        draft.quantity = self.RecipeInspectorInputQuantityInput:GetText()
    end)
    self.RecipeInspectorInputQuantityInput:SetScript("OnTextChanged", function()
        local draft = self:EnsureRecipeInspectorInputDraft()
        draft.quantity = self.RecipeInspectorInputQuantityInput:GetText()
    end)
    self.RecipeInspectorInputQuantityGroup:AddChild(self.RecipeInspectorInputQuantityInput)

    self.RecipeInspectorInputActionRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorRecipeInspectorInputActionRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.RecipeInspectorInputActionRow._visibleHeight = 18
    root:AddChild(self.RecipeInspectorInputActionRow)

    self.RecipeInspectorApplyInputButton = UI.CreateButton(self.RecipeInspectorInputActionRow:GetFrame(), "RPEDataEditorRecipeInspectorApplyInputButton", "Apply", 48, function()
        if self._refreshingRecipeInspector then
            return
        end

        local draft = self:EnsureRecipeInspectorInputDraft()
        draft.quantity = self.RecipeInspectorInputQuantityInput and self.RecipeInspectorInputQuantityInput:GetText() or draft.quantity

        local definition = {
            kind = draft.kind,
            quantity = math.max(1, tonumber(draft.quantity) or 1),
        }

        definition.itemRef = ensureString(draft.itemRef)
        if definition.itemRef == "" then
            return
        end

        local selectedIndex = tonumber(self.SelectedRecipeInputIndex)
        self:CommitSelectedRecipe(function(recipe)
            recipe.inputs = recipe.inputs or {}
            if selectedIndex and recipe.inputs[selectedIndex] then
                recipe.inputs[selectedIndex] = definition
            else
                recipe.inputs[#recipe.inputs + 1] = definition
            end
        end)

        self.SelectedRecipeInputIndex = nil
        self:SetRecipeInspectorInputDraft(nil)
        self:RefreshRecipeInspectorPage()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.RecipeInspectorInputActionRow:AddChild(self.RecipeInspectorApplyInputButton)
end

function DataEditor:BuildRecipeInspectorPage(parent)
    if self.RecipeInspectorPage then
        self:RefreshRecipeInspectorPage()
        return self.RecipeInspectorPage
    end

    self._refreshingRecipeInspector = true
    self.RecipeInspectorPage = CreateFrame("Frame", "RPEDataEditorRecipeInspectorPage", parent)

    self.RecipeInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.RecipeInspectorPage, "RPEDataEditorRecipeInspectorSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    self.RecipeInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.RecipeInspectorPage, "TOPLEFT", 0, 0)
    self.RecipeInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.RecipeInspectorPage, "TOPRIGHT", 0, 0)

    self.RecipeInspectorPreviousButton = UI.CreateButton(self.RecipeInspectorSelectorBar:GetFrame(), "RPEDataEditorRecipeInspectorPreviousButton", "Prev", 40, function()
        self:SetRecipeInspectorTab((self:GetRecipeInspectorPageDefinitions()[(self.ActiveRecipeInspectorPageIndex or 1) - 1] or {}).key or "general")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.RecipeInspectorSelectorBar:AddChild(self.RecipeInspectorPreviousButton)

    self.RecipeInspectorPageDropdown = UI.CreateDropdown(self.RecipeInspectorSelectorBar:GetFrame(), "RPEDataEditorRecipeInspectorPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildRecipeInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if self._refreshingRecipeInspectorPageSelector then
                return
            end

            self:SetRecipeInspectorTab(value)
        end,
    })
    self.RecipeInspectorSelectorBar:AddChild(self.RecipeInspectorPageDropdown)

    self.RecipeInspectorNextButton = UI.CreateButton(self.RecipeInspectorSelectorBar:GetFrame(), "RPEDataEditorRecipeInspectorNextButton", "Next", 40, function()
        self:SetRecipeInspectorTab((self:GetRecipeInspectorPageDefinitions()[(self.ActiveRecipeInspectorPageIndex or 1) + 1] or {}).key or "inputs")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.RecipeInspectorSelectorBar:AddChild(self.RecipeInspectorNextButton)

    self.RecipeInspectorGeneralPage = createPageFrame(self.RecipeInspectorPage, "RPEDataEditorRecipeInspectorGeneralPage")
    buildGeneralPage(self, self.RecipeInspectorGeneralPage)

    self.RecipeInspectorOutputPage = createPageFrame(self.RecipeInspectorPage, "RPEDataEditorRecipeInspectorOutputPage")
    buildOutputPage(self, self.RecipeInspectorOutputPage)

    self.RecipeInspectorInputsPage = createPageFrame(self.RecipeInspectorPage, "RPEDataEditorRecipeInspectorInputsPage")
    buildInputsPage(self, self.RecipeInspectorInputsPage)

    self.RecipeInspectorEmptyText = UI.CreateText(self.RecipeInspectorPage, "RPEDataEditorRecipeInspectorEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = FIELD_WIDTH,
        height = 34,
        justifyH = "LEFT",
        wordWrap = true,
    })
    self.RecipeInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.RecipeInspectorPage, "BOTTOMLEFT", 0, 0)

    self.ActiveRecipeInspectorPageIndex = self.ActiveRecipeInspectorPageIndex or self:GetRecipeInspectorPageIndexByKey(self.ActiveRecipeInspectorTabKey or "general")
    self._refreshingRecipeInspector = false
    self:SetRecipeInspectorTab(self.ActiveRecipeInspectorTabKey or "general", true)
    self:RefreshRecipeInspectorPage()
    return self.RecipeInspectorPage
end

function DataEditor:RefreshRecipeInspectorPage()
    if not self.RecipeInspectorPage then
        return
    end
    if self.ActiveInspectorPageKey ~= "recipe" then
        return
    end

    local _, recipe = self:GetSelectedRecipeAndDataset()
    local hasRecipe = recipe ~= nil
    local selectedRecipeId = hasRecipe and ensureString(recipe.id) or ""
    local activeTab = self.ActiveRecipeInspectorTabKey or "general"

    if self.RecipeInspectorLastRecipeId ~= selectedRecipeId then
        self.RecipeInspectorLastRecipeId = selectedRecipeId
        self.SelectedRecipeInputIndex = nil
        self:SetRecipeInspectorInputDraft(nil)
    end

    self._refreshingRecipeInspector = true

    if activeTab == "general" then
        if self.RecipeInspectorIdText then
            self.RecipeInspectorIdText:SetText(("ID: %s"):format(hasRecipe and ensureString(recipe.id) or "-"))
        end
        if self.RecipeInspectorNameText then
            self.RecipeInspectorNameText:SetText(("Output Item: %s"):format(hasRecipe and self:GetDerivedRecipeName(recipe) or "-"))
        end
        if self.RecipeInspectorCategoryText then
            self.RecipeInspectorCategoryText:SetText(("Category: %s"):format(hasRecipe and self:GetDerivedRecipeCategory(recipe) or "-"))
        end

        if self.RecipeInspectorSkillDropdown then
            self.RecipeInspectorSkillDropdown:SetItems(self:BuildSpellInspectorSkillsAcrossDatasets())
            self.RecipeInspectorSkillDropdown:SetSelectedValue(hasRecipe and ensureString(recipe.skillRef) or "", true)
            setDropdownEnabled(self.RecipeInspectorSkillDropdown, hasRecipe)
        end

        if self.RecipeInspectorRequiredLevelInput then
            self.RecipeInspectorRequiredLevelInput:SetText(tostring(hasRecipe and (tonumber(recipe.requiredSkillLevel) or 0) or 0))
            setTextElementEnabled(self.RecipeInspectorRequiredLevelInput, hasRecipe)
        end
        if self.RecipeInspectorLearnModeDropdown then
            self.RecipeInspectorLearnModeDropdown:SetItems(RECIPE_LEARN_MODE_ITEMS)
            self.RecipeInspectorLearnModeDropdown:SetSelectedValue(hasRecipe and ensureString(recipe.learnMode) or "trainer", true)
            setDropdownEnabled(self.RecipeInspectorLearnModeDropdown, hasRecipe)
        end
    elseif activeTab == "output" then
        self:RefreshRecipeInspectorOutputControls(hasRecipe, recipe or {})
    elseif activeTab == "inputs" then
        self:RefreshRecipeInspectorInputsTable()
        self:RefreshRecipeInspectorInputEditorControls(hasRecipe)
    end

    local statusText = "Select a recipe to inspect it."
    if hasRecipe then
        if ensureString(recipe.output and recipe.output.itemRef) == "" then
            statusText = "Output item is missing."
        else
            statusText = "Recipe definition is valid."
        end
    end

    if self.RecipeInspectorEmptyText then
        self.RecipeInspectorEmptyText:SetText(statusText)
    end

    self._refreshingRecipeInspector = false
    self:RefreshRecipeInspectorPageSelector()
end

return DataEditor
