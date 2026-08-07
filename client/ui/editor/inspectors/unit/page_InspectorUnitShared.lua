local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local RulesetLogic = Addon.Internal and Addon.Internal.Ruleset or {}

local UnitClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Unit or nil

DataEditor.UnitInspectorSidePadding = DataEditor.UnitInspectorSidePadding or 8
DataEditor.UnitInspectorControlHeight = DataEditor.UnitInspectorControlHeight or 20
DataEditor.UnitInspectorFieldWidth = DataEditor.UnitInspectorFieldWidth or 236

local UNIT_ATTRIBUTE_ITEMS = {
    { label = "Flying", value = "flying" },
    { label = "Invulnerable", value = "invulnerable" },
    { label = "Invisible", value = "invisible" },
}

local UNIT_CREATURE_TYPE_ITEMS = {
    { label = "Aberration", value = "aberration" },
    { label = "Beast", value = "beast" },
    { label = "Demon", value = "demon" },
    { label = "Dragonkin", value = "dragonkin" },
    { label = "Elemental", value = "elemental" },
    { label = "Giant", value = "giant" },
    { label = "Humanoid", value = "humanoid" },
    { label = "Mechanical", value = "mechanical" },
    { label = "Undead", value = "undead" },
}

local UNIT_CREATURE_SIZE_ITEMS = {
    { label = "Tiny", value = "tiny" },
    { label = "Small", value = "small" },
    { label = "Medium", value = "medium" },
    { label = "Large", value = "large" },
    { label = "Huge", value = "huge" },
    { label = "Gargantuan", value = "gargantuan" },
}

local UNIT_INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "model", label = "Model" },
    { key = "equipment", label = "Equipment" },
    { key = "spells", label = "Spells" },
    { key = "stats", label = "Stats" },
    { key = "resources", label = "Resources" },
}

local UNIT_EQUIPMENT_FIELD_DEFINITIONS = {
    { fieldKey = "mainHandWeapon", ruleKey = "mainhand_slot", label = "Main Hand Weapon" },
    { fieldKey = "offHandWeapon", ruleKey = "offhand_slot", label = "Off Hand Weapon" },
    { fieldKey = "rangedWeapon", ruleKey = "ranged_slot", label = "Ranged Weapon" },
    { fieldKey = "shield", ruleKey = "shield_slot", label = "Shield" },
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

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimString(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function titleCaseWords(value)
    local text = trimString(value):gsub("[%-%_]+", " "):lower()
    if text == "" then
        return ""
    end

    return (text:gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. rest
    end))
end

local function getFirstTag(entry)
    if type(entry) ~= "table" or type(entry.tags) ~= "table" then
        return ""
    end

    return trimString(entry.tags[1])
end

local function getAlphabeticBucketLabel(name)
    local firstCharacter = trimString(name):sub(1, 1):upper()
    if firstCharacter == "" then
        return "Other"
    end
    if firstCharacter:match("%d") then
        return "0-9"
    end
    if firstCharacter >= "A" and firstCharacter <= "F" then
        return "A-F"
    end
    if firstCharacter >= "G" and firstCharacter <= "L" then
        return "G-L"
    end
    if firstCharacter >= "M" and firstCharacter <= "R" then
        return "M-R"
    end
    if firstCharacter >= "S" and firstCharacter <= "Z" then
        return "S-Z"
    end

    return "Other"
end

local function buildSubgroupInfo(label, key)
    local subgroupLabel = trimString(label)
    if subgroupLabel == "" then
        subgroupLabel = "Other"
    end

    local subgroupKey = trimString(key)
    if subgroupKey == "" then
        subgroupKey = string.lower(subgroupLabel)
    end

    return {
        label = subgroupLabel,
        key = subgroupKey,
    }
end

local function compareSubgroupLabels(left, right)
    local orderedLabels = {
        ["0-9"] = 1,
        ["A-F"] = 2,
        ["G-L"] = 3,
        ["M-R"] = 4,
        ["S-Z"] = 5,
        ["Other"] = 6,
    }

    local leftLabel = trimString(left)
    local rightLabel = trimString(right)
    local leftOrder = orderedLabels[leftLabel]
    local rightOrder = orderedLabels[rightLabel]

    if leftOrder and rightOrder then
        return leftOrder < rightOrder
    end
    if leftOrder then
        return true
    end
    if rightOrder then
        return false
    end

    return string.lower(leftLabel) < string.lower(rightLabel)
end

function DataEditor:GetReferenceEntrySubgroupInfo(collectionKey, entry)
    local entryName = self:GetEntryDisplayName(collectionKey, entry)
    local firstTag = getFirstTag(entry)
    local normalizedCollectionKey = ensureString(collectionKey)

    if normalizedCollectionKey == "units" then
        local creatureType = trimString(type(entry) == "table" and entry.creatureType or nil)
        if creatureType ~= "" then
            return buildSubgroupInfo(titleCaseWords(creatureType), "creature:" .. string.lower(creatureType))
        end
        if firstTag ~= "" then
            return buildSubgroupInfo(titleCaseWords(firstTag), "tag:" .. string.lower(firstTag))
        end
        return buildSubgroupInfo("Other", "other")
    end

    if normalizedCollectionKey == "items" then
        local itemType = trimString(type(entry) == "table" and entry.itemType or nil)
        if itemType ~= "" then
            local consumableType = trimString(type(entry) == "table" and entry.consumableType or nil)
            if string.lower(itemType) == "consumable" and consumableType ~= "" then
                return buildSubgroupInfo(
                    ("%s: %s"):format(titleCaseWords(itemType), titleCaseWords(consumableType)),
                    ("type:%s:%s"):format(string.lower(itemType), string.lower(consumableType))
                )
            end

            return buildSubgroupInfo(titleCaseWords(itemType), "type:" .. string.lower(itemType))
        end
        return buildSubgroupInfo("Other", "other")
    end

    if normalizedCollectionKey == "spells" then
        local spellbookCategory = trimString(type(entry) == "table" and entry.spellbookCategory or nil)
        if spellbookCategory ~= "" then
            return buildSubgroupInfo(titleCaseWords(spellbookCategory), "category:" .. string.lower(spellbookCategory))
        end

        local learnMode = trimString(type(entry) == "table" and entry.learnMode or nil)
        if learnMode ~= "" then
            return buildSubgroupInfo(titleCaseWords(learnMode), "learn:" .. string.lower(learnMode))
        end

        return buildSubgroupInfo("Other", "other")
    end

    if normalizedCollectionKey == "stats" then
        local category = trimString(type(entry) == "table" and entry.category or nil)
        if category ~= "" then
            return buildSubgroupInfo(titleCaseWords(category), "category:" .. string.lower(category))
        end
    end

    if firstTag ~= "" and (
        normalizedCollectionKey == "resources"
        or normalizedCollectionKey == "stats"
        or normalizedCollectionKey == "damageSchools"
    ) then
        return buildSubgroupInfo(titleCaseWords(firstTag), "tag:" .. string.lower(firstTag))
    end

    return buildSubgroupInfo(getAlphabeticBucketLabel(entryName), "alpha:" .. string.lower(getAlphabeticBucketLabel(entryName)))
end

function DataEditor:BuildReferenceItemsAcrossDatasets(collectionKey, options)
    local items = {}
    if type(options) == "table" and options.includeNone ~= false then
        items[#items + 1] = {
            label = options.noneLabel or "None",
            value = "",
        }
    end

    local datasets = self:GetDatasets()
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local subgroupMap = {}
        local subgroupOrder = {}

        for entryIndex = 1, #(dataset[collectionKey] or {}) do
            local entry = dataset[collectionKey][entryIndex]
            if entry and entry.id then
                local subgroup = self:GetReferenceEntrySubgroupInfo(collectionKey, entry)
                local subgroupKey = subgroup and subgroup.key or "other"
                local subgroupLabel = subgroup and subgroup.label or "Other"

                if not subgroupMap[subgroupKey] then
                    subgroupMap[subgroupKey] = {
                        label = subgroupLabel,
                        children = {},
                    }
                    subgroupOrder[#subgroupOrder + 1] = subgroupKey
                end

                subgroupMap[subgroupKey].children[#subgroupMap[subgroupKey].children + 1] = {
                    label = self:GetEntryDisplayName(collectionKey, entry),
                    value = ("%s:%s"):format(dataset.id, entry.id),
                }
            end
        end

        if #subgroupOrder > 0 then
            table.sort(subgroupOrder, function(leftKey, rightKey)
                local leftGroup = subgroupMap[leftKey]
                local rightGroup = subgroupMap[rightKey]
                return compareSubgroupLabels(leftGroup and leftGroup.label or "", rightGroup and rightGroup.label or "")
            end)

            local children = {}
            for subgroupIndex = 1, #subgroupOrder do
                local subgroupKey = subgroupOrder[subgroupIndex]
                local subgroupGroup = subgroupMap[subgroupKey]
                children[#children + 1] = {
                    label = subgroupGroup.label,
                    value = ("subgroup:%s:%s:%s"):format(collectionKey, dataset.id or datasetIndex, subgroupKey),
                    enabled = true,
                    keepShownOnClick = true,
                    notCheckable = true,
                    children = subgroupGroup.children,
                }
            end

            items[#items + 1] = {
                label = self:GetDatasetDisplayName(dataset),
                value = ("dataset:%s:%s"):format(collectionKey, dataset.id or datasetIndex),
                enabled = true,
                keepShownOnClick = true,
                notCheckable = true,
                children = children,
            }
        end
    end

    return items
end

function DataEditor:GetSelectedUnitAndDataset()
    return self:GetSelectedDataset(), self:GetSelectedUnit()
end

function DataEditor:SetUnitInspectorDropdownEnabled(dropdown, enabled)
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

function DataEditor:SetUnitInspectorTextElementEnabled(element, enabled)
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

function DataEditor:SetUnitInspectorCheckboxEnabled(checkbox, enabled)
    if not checkbox then
        return
    end

    local frame = checkbox.GetFrame and checkbox:GetFrame() or nil
    if frame and frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end
    if frame and frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
end

function DataEditor:SetUnitInspectorSliderEnabled(slider, enabled)
    if not slider then
        return
    end

    local frame = slider.GetFrame and slider:GetFrame() or nil
    if frame and frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end
    if frame and frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
end

function DataEditor:BuildUnitInspectorLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or self.UnitInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
    })
end

function DataEditor:CreateUnitInspectorCheckbox(parent, name, text, checked, onValueChanged)
    local checkbox = UI.Checkbox:New({
        name = name,
        width = self.UnitInspectorFieldWidth,
        height = 18,
        text = text,
        checked = checked == true,
        border = false,
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Checkbox) or 8,
        labelColor = UI.ResolveColor(nil, "text.primary"),
        onValueChanged = onValueChanged,
    })
    checkbox:SetParent(parent)
    checkbox:Create()
    return checkbox
end

function DataEditor:NormalizeUnitDefinition(unit)
    if UnitClass and UnitClass.ToTable then
        return UnitClass.ToTable(UnitClass:New(unit))
    end

    return unit or {}
end

function DataEditor:CommitSelectedUnit(mutate)
    local dataset, unit = self:GetSelectedUnitAndDataset()
    if not dataset or not unit or type(mutate) ~= "function" then
        return
    end

    mutate(unit, dataset)
    applyTable(unit, self:NormalizeUnitDefinition(unit))

    if self.Database and self.Database.NotifyDatasetEntryChanged then
        self.Database.NotifyDatasetEntryChanged(dataset.id, "units", {
            deferConfigurationChanged = true,
        })
    end

    self:RefreshAfterDatasetEntryChanged("units")
end

function DataEditor:BuildUnitInspectorReferencesAcrossDatasets(collectionKey)
    return self:BuildReferenceItemsAcrossDatasets(collectionKey, {
        includeNone = true,
        noneLabel = "None",
    })
end

function DataEditor:GetUnitInspectorAttributeItems()
    return UNIT_ATTRIBUTE_ITEMS
end

function DataEditor:GetUnitInspectorCreatureTypeItems()
    return UNIT_CREATURE_TYPE_ITEMS
end

function DataEditor:GetUnitInspectorCreatureSizeItems()
    return UNIT_CREATURE_SIZE_ITEMS
end

function DataEditor:GetUnitInspectorEquipmentFieldDefinitions()
    return UNIT_EQUIPMENT_FIELD_DEFINITIONS
end

function DataEditor:GetUnitInspectorActiveSlotReference(ruleKey)
    local ruleset = RulesetLogic and RulesetLogic.GetActiveRuleset and RulesetLogic.GetActiveRuleset() or nil
    local ruleDefinition = RulesetLogic and RulesetLogic.GetRulesetRuleDefinition and RulesetLogic.GetRulesetRuleDefinition("equipment", ruleKey) or nil
    local value = RulesetLogic and RulesetLogic.GetRulesetRuleValue and RulesetLogic.GetRulesetRuleValue(ruleset, "equipment", ruleDefinition) or nil
    return type(value) == "string" and value or ""
end

function DataEditor:UnitInspectorItemMatchesSlot(item, slotRef, equipmentFieldKey)
    if type(item) ~= "table" or type(slotRef) ~= "string" or slotRef == "" then
        return false
    end

    if equipmentFieldKey == "shield" and tostring(item.armorWeight or "") ~= "shield" then
        return false
    end

    for index = 1, #(item.validSlotRefs or {}) do
        if item.validSlotRefs[index] == slotRef then
            return true
        end
    end

    return false
end

function DataEditor:BuildUnitInspectorItemItemsForSlot(slotRef, equipmentFieldKey)
    local items = {
        { label = "None", value = "" },
    }

    if type(slotRef) ~= "string" or slotRef == "" then
        return items
    end

    local datasets = self:GetDatasets()
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local children = {}

        for itemIndex = 1, #(dataset and dataset.items or {}) do
            local item = dataset.items[itemIndex]
            if item and item.id and self:UnitInspectorItemMatchesSlot(item, slotRef, equipmentFieldKey) then
                children[#children + 1] = {
                    label = self:GetEntryDisplayName("items", item),
                    value = ("%s:%s"):format(dataset.id, item.id),
                }
            end
        end

        if #children > 0 then
            items[#items + 1] = {
                label = self:GetDatasetDisplayName(dataset),
                value = ("dataset:%s"):format(dataset.id or datasetIndex),
                enabled = true,
                keepShownOnClick = true,
                notCheckable = true,
                children = children,
            }
        end
    end

    return items
end

function DataEditor:ResolveUnitInspectorReferenceLabel(collectionKey, reference)
    if type(reference) ~= "string" or reference == "" then
        return "-"
    end

    local datasetId, entryId = string.match(reference, "^([^:]+):(.+)$")
    if not datasetId or not entryId or not self.Database or not self.Database.GetDatasetByID then
        return reference
    end

    local dataset = self.Database.GetDatasetByID(datasetId)
    local entries = dataset and dataset[collectionKey] or nil
    if type(entries) ~= "table" then
        return reference
    end

    for index = 1, #entries do
        local entry = entries[index]
        if entry and entry.id == entryId then
            return ("%s / %s"):format(self:GetDatasetDisplayName(dataset), self:GetEntryDisplayName(collectionKey, entry))
        end
    end

    return reference
end

function DataEditor:GetUnitInspectorPageDefinitions()
    return UNIT_INSPECTOR_PAGE_DEFINITIONS
end

function DataEditor:GetUnitInspectorPageIndexByKey(key)
    local pages = self:GetUnitInspectorPageDefinitions()
    for index = 1, #pages do
        if pages[index].key == key then
            return index
        end
    end

    return 1
end

function DataEditor:BuildUnitInspectorPageSelectorItems()
    local items = {}
    local pages = self:GetUnitInspectorPageDefinitions()

    for index = 1, #pages do
        items[#items + 1] = {
            label = pages[index].label,
            value = pages[index].key,
        }
    end

    return items
end

function DataEditor:RefreshUnitInspectorPageSelector()
    local pages = self:GetUnitInspectorPageDefinitions()
    local pageCount = #pages
    local activeIndex = math.max(1, math.min(self.ActiveUnitInspectorPageIndex or 1, pageCount))
    self.ActiveUnitInspectorPageIndex = activeIndex
    self.ActiveUnitInspectorTabKey = pages[activeIndex] and pages[activeIndex].key or "general"

    local activeDefinition = pages[activeIndex]
    if self.UnitInspectorPageDropdown and activeDefinition then
        self._refreshingUnitInspectorPageSelector = true
        self.UnitInspectorPageDropdown:SetSelectedValue(activeDefinition.key, true)
        self._refreshingUnitInspectorPageSelector = false
    end

    if self.UnitInspectorPreviousButton and self.UnitInspectorPreviousButton.SetEnabled then
        self.UnitInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end

    if self.UnitInspectorNextButton and self.UnitInspectorNextButton.SetEnabled then
        self.UnitInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetUnitInspectorTab(tabKey)
    local pages = self:GetUnitInspectorPageDefinitions()
    self.ActiveUnitInspectorPageIndex = self:GetUnitInspectorPageIndexByKey(tabKey or "general")
    self.ActiveUnitInspectorTabKey = pages[self.ActiveUnitInspectorPageIndex] and pages[self.ActiveUnitInspectorPageIndex].key or "general"

    local pageFrames = {
        general = self.UnitInspectorGeneralPage,
        model = self.UnitInspectorModelPage,
        equipment = self.UnitInspectorEquipmentPage,
        spells = self.UnitInspectorSpellsPage,
        stats = self.UnitInspectorStatsPage,
        resources = self.UnitInspectorResourcesPage,
    }

    for key, page in pairs(pageFrames) do
        if page then
            if key == self.ActiveUnitInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    self:RefreshUnitInspectorPageSelector()
end
