local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}
local ItemClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Item or nil
local TraitClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Trait or nil

local INSPECTOR_SIDE_PADDING = 8
local CONTROL_HEIGHT = 20
local FIELD_WIDTH = 236

local ITEM_INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "behavior", label = "Behavior" },
    { key = "equipment", label = "Equipment" },
    { key = "modifications", label = "Modifications" },
    { key = "consumable", label = "Trait" },
    { key = "conditions", label = "Conditions" },
    { key = "stats", label = "Stats" },
}

local QUALITY_ITEMS = {
    { label = "Poor", value = "poor" },
    { label = "Common", value = "common" },
    { label = "Uncommon", value = "uncommon" },
    { label = "Rare", value = "rare" },
    { label = "Epic", value = "epic" },
    { label = "Legendary", value = "legendary" },
}

local UNIQUE_FLAG_ITEMS = {
    { label = "None", value = "none" },
    { label = "Unique Equipped", value = "unique_equipped" },
    { label = "Unique Owned", value = "unique_owned" },
}

local BINDING_FLAG_ITEMS = {
    { label = "None", value = "none" },
    { label = "Bind On Pickup", value = "bind_on_pickup" },
    { label = "Bind On Equip", value = "bind_on_equip" },
    { label = "Bind On Use", value = "bind_on_use" },
    { label = "Quest Item", value = "quest_item" },
}

local ITEM_TYPE_ITEMS = {
    { label = "None", value = "none" },
    { label = "Weapon", value = "weapon" },
    { label = "Armor", value = "armor" },
    { label = "Modification", value = "modification" },
    { label = "Consumable", value = "consumable" },
    { label = "Material", value = "material" },
}

local ARMOR_WEIGHT_ITEMS = {
    { label = "Cosmetic", value = "cosmetic" },
    { label = "Cloth", value = "cloth" },
    { label = "Leather", value = "leather" },
    { label = "Mail", value = "mail" },
    { label = "Plate", value = "plate" },
    { label = "Shield", value = "shield" },
}

local MODIFICATION_ARMOR_WEIGHT_ITEMS = {
    { label = "None", value = "none" },
    { label = "Cosmetic", value = "cosmetic" },
    { label = "Cloth", value = "cloth" },
    { label = "Leather", value = "leather" },
    { label = "Mail", value = "mail" },
    { label = "Plate", value = "plate" },
    { label = "Shield", value = "shield" },
}

local SOCKET_TYPE_ITEMS = {
    { label = "Red", value = "red" },
    { label = "Blue", value = "blue" },
    { label = "Yellow", value = "yellow" },
    { label = "Green", value = "green" },
    { label = "Meta", value = "meta" },
    { label = "Cogwheel", value = "cogwheel" },
    { label = "Prismatic", value = "prismatic" },
}

local MODIFICATION_KIND_ITEMS = {
    { label = "Generic", value = "generic" },
    { label = "Gem", value = "gem" },
    { label = "Enchant", value = "enchant" },
}

local SOCKET_COUNT_FIELDS = {
    { key = "red", field = "redSockets" },
    { key = "blue", field = "blueSockets" },
    { key = "yellow", field = "yellowSockets" },
    { key = "green", field = "greenSockets" },
    { key = "meta", field = "metaSockets" },
    { key = "cogwheel", field = "cogSockets" },
    { key = "prismatic", field = "prismaticSockets" },
}

local LEGACY_ARMOR_WEIGHT_MAP = {
    light = "cloth",
    medium = "leather",
    heavy = "plate",
}

local DAMAGE_MODE_ITEMS = {
    { label = "None", value = "none" },
    { label = "Fixed", value = "fixed" },
    { label = "Range", value = "range" },
}

local CONSUMABLE_PHASE_ITEMS = {
    { label = "Event Start", value = "event_start" },
    { label = "Event End", value = "event_end" },
}

local CONSUMABLE_TYPE_ITEMS = {
    { label = "None", value = "" },
    { label = "Potion", value = "potion" },
    { label = "Flask", value = "flask" },
    { label = "Elixir", value = "elixir" },
    { label = "Scroll", value = "scroll" },
    { label = "Rune", value = "rune" },
    { label = "Enhancement", value = "enhancement" },
}

local CONSUMABLE_ELIXIR_TYPE_ITEMS = {
    { label = "Generic", value = "generic" },
    { label = "Battle", value = "battle" },
    { label = "Guardian", value = "guardian" },
}

local AUTO_AURA_TARGET_ITEMS = {
    { label = "Self", value = "self" },
    { label = "All Allies", value = "all_allies" },
    { label = "All Enemies", value = "all_enemies" },
}

local TRIGGER_TARGET_ITEMS = {
    { label = "Event Other", value = "event_other" },
    { label = "Event Source", value = "event_source" },
    { label = "Owner", value = "aura_caster" },
}

local EVENT_EFFECT_ITEMS = {
    { label = "Damage", value = "damage" },
    { label = "Heal", value = "heal" },
    { label = "Apply Aura", value = "apply_aura" },
    { label = "Remove Aura", value = "remove_aura" },
    { label = "Resource", value = "resource" },
}

local TRIGGER_TARGET_LABELS = {
    event_other = "Other",
    event_source = "Source",
    aura_caster = "Owner",
}

local EVENT_EFFECT_LABELS = {
    damage = "Damage",
    heal = "Heal",
    apply_aura = "Apply",
    remove_aura = "Remove",
    resource = "Resource",
}

local function copyTable(values)
    local output = {}
    for index = 1, #(values or {}) do
        output[index] = values[index]
    end
    return output
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function parseDatasetQualifiedRef(reference)
    local normalizedReference = ensureString(reference)
    if normalizedReference == "" then
        return nil, nil
    end

    local datasetId, entryId = normalizedReference:match("^([^:]+):(.+)$")
    if not datasetId or not entryId then
        return nil, nil
    end

    return datasetId, entryId
end

local function getDependenciesApi()
    local database = Addon.Internal and Addon.Internal.Database or nil
    return database and database.Dependecies or {}
end

local function getSelectedItemAndDataset(self)
    return self:GetSelectedDataset(), self:GetSelectedItem()
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

local function buildHintText(parent, name, text, width, height)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or FIELD_WIDTH,
        height = height or 18,
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

local function setCheckboxEnabled(checkbox, enabled)
    if not checkbox then
        return
    end

    if checkbox.SetEnabled then
        checkbox:SetEnabled(enabled == true)
    end

    local frame = checkbox.GetFrame and checkbox:GetFrame() or nil
    if frame and frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end
    if frame and frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
end

local function setButtonEnabled(button, enabled)
    if not button then
        return
    end

    if button.SetEnabled then
        button:SetEnabled(enabled == true)
    end

    local frame = button.GetFrame and button:GetFrame() or nil
    if frame and frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end
    if frame and frame.SetAlpha then
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

local function createEquipmentFieldGroup(root, name, labelText, contentHeight)
    local groupHeight = 12 + 2 + (contentHeight or CONTROL_HEIGHT)
    local group = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), name, {
        width = FIELD_WIDTH,
        height = groupHeight,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    group._visibleHeight = groupHeight
    root:AddChild(group)

    group:AddChild(buildLabel(group:GetFrame(), name .. "Label", labelText))
    return group
end

local function createInspectorSection(root, name, titleText, height, descriptionText)
    local panel = UI.CreatePanel(root:GetFrame(), name, {
        width = FIELD_WIDTH,
        height = height,
        contentInset = 6,
        showBorder = true,
    })
    root:AddChild(panel)

    local layout = UI.CreateLayout(UI.VerticalLayoutGroup, panel:GetContentFrame(), name .. "Layout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(layout, panel:GetContentFrame(), 0, 0, 0, 0)
    layout:AddChild(buildLabel(layout:GetFrame(), name .. "Title", titleText, FIELD_WIDTH - 12))

    local hintText = nil
    if descriptionText and descriptionText ~= "" then
        hintText = buildHintText(layout:GetFrame(), name .. "Hint", descriptionText, FIELD_WIDTH - 12, 22)
        layout:AddChild(hintText)
    end

    panel._contentLayout = layout
    panel._contentInset = 6
    panel._minimumHeight = height or 0
    panel.UpdateHeight = function(sectionPanel)
        local contentLayout = sectionPanel and sectionPanel._contentLayout or nil
        if not contentLayout then
            return
        end

        local children = contentLayout.children or {}
        local spacing = contentLayout.options and (contentLayout.options.spacingY or contentLayout.options.spacing) or 0
        local contentHeight = 0
        local visibleChildren = 0

        for index = 1, #children do
            local child = children[index]
            local childHeight = child and child.options and child.options.height or nil
            if childHeight == nil then
                local childFrame = child and child.GetFrame and child:GetFrame() or nil
                childHeight = childFrame and childFrame.GetHeight and childFrame:GetHeight() or 0
            end

            childHeight = math.max(0, tonumber(childHeight) or 0)
            if childHeight > 0 then
                visibleChildren = visibleChildren + 1
                contentHeight = contentHeight + childHeight
            end
        end

        if visibleChildren > 1 then
            contentHeight = contentHeight + (spacing * (visibleChildren - 1))
        end

        local inset = tonumber(sectionPanel._contentInset) or 0
        local totalHeight = math.max(sectionPanel._minimumHeight or 0, contentHeight + (inset * 2))
        sectionPanel:SetHeight(totalHeight)
    end

    return panel, layout, hintText
end

local function createHorizontalFieldLabels(parent, name, columns, width)
    local row = UI.CreateLayout(UI.HorizontalLayoutGroup, parent:GetFrame(), name, {
        width = width or FIELD_WIDTH,
        height = 12,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    row._visibleHeight = 12
    parent:AddChild(row)

    local labels = {}
    for index = 1, #(columns or {}) do
        local column = columns[index]
        local label = UI.CreateText(row:GetFrame(), ("%sLabel%d"):format(name, index), ensureString(column and column.text), {
            width = column and column.width or 0,
            height = 12,
            justifyH = column and column.justifyH or "LEFT",
            textColor = UI.ResolveColor(nil, "text.secondary"),
            expandWidth = column and column.expandWidth == true or false,
        })
        row:AddChild(label)
        labels[index] = label
    end

    return row, labels
end

local function createCheckbox(parent, name, text, checked, onValueChanged)
    local checkbox = UI.Checkbox:New({
        name = name,
        width = FIELD_WIDTH,
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

local function getItemTypeLabel(itemType)
    local labels = {
        weapon = "Weapon",
        armor = "Armor",
        modification = "Modification",
        consumable = "Consumable",
        material = "Material",
        none = "Item",
    }

    return labels[tostring(itemType or "none")] or "Item"
end

local function getQualityLabel(quality)
    local labels = {
        poor = "Poor",
        common = "Common",
        uncommon = "Uncommon",
        rare = "Rare",
        epic = "Epic",
        legendary = "Legendary",
    }

    return labels[tostring(quality or "common")] or "Common"
end

local function normalizeArmorWeightValue(value)
    local key = tostring(value or "cosmetic")
    return LEGACY_ARMOR_WEIGHT_MAP[key] or key
end

local function normalizeItemStats(item)
    local normalized = {}
    if type(item) ~= "table" or type(item.stats) ~= "table" then
        return normalized
    end

    for index = 1, #item.stats do
        local entry = item.stats[index]
        local sourceStatRef = type(entry) == "table" and entry.sourceStatRef or nil
        if type(sourceStatRef) == "string" and sourceStatRef ~= "" then
            normalized[#normalized + 1] = {
                sourceStatRef = sourceStatRef,
                value = tonumber(entry.value) or 0,
            }
        end
    end

    return normalized
end

local function normalizeItemSkillBonuses(item)
    local normalized = {}
    if type(item) ~= "table" or type(item.skillBonuses) ~= "table" then
        return normalized
    end

    for index = 1, #item.skillBonuses do
        local entry = item.skillBonuses[index]
        local skillRef = type(entry) == "table" and ensureString(entry.skillRef) or ""
        if skillRef ~= "" then
            normalized[#normalized + 1] = {
                skillRef = skillRef,
                value = tonumber(entry.value) or 0,
            }
        end
    end

    return normalized
end

local function normalizeItemTrait(value, includePhase)
    if TraitClass and TraitClass.NormalizeRuntimePayload then
        local payload = TraitClass.NormalizeRuntimePayload(value)
        local hasContent = ensureString(payload and payload.description) ~= ""
            or #((payload and payload.statBonuses) or {}) > 0
            or #((payload and payload.skillBonuses) or {}) > 0
            or #((payload and payload.automaticAuras) or {}) > 0
            or #((payload and payload.events) or {}) > 0
        if not hasContent then
            return nil
        end

        payload.name = ""
        payload.icon = ""
        payload.phase = includePhase == true and (string.lower(ensureString(value and value.phase)) == "event_end" and "event_end" or "event_start") or nil
        return payload
    end

    return type(value) == "table" and value or nil
end

local function normalizeConsumableTrait(value)
    return normalizeItemTrait(value, true)
end

local function normalizeEquipmentTrait(value)
    return normalizeItemTrait(value, false)
end

local function normalizeConsumableTraitStatBonuses(value)
    return TraitClass and TraitClass.NormalizeStatBonuses and TraitClass.NormalizeStatBonuses(value) or (value or {})
end

local function normalizeConsumableTraitSkillBonuses(value)
    return TraitClass and TraitClass.NormalizeSkillBonuses and TraitClass.NormalizeSkillBonuses(value) or (value or {})
end

local function normalizeConsumableTraitAutomaticAuras(value)
    return TraitClass and TraitClass.NormalizeAutomaticAuras and TraitClass.NormalizeAutomaticAuras(value) or (value or {})
end

local function normalizeConsumableTraitEvents(value)
    return TraitClass and TraitClass.NormalizeEvents and TraitClass.NormalizeEvents(value) or (value or {})
end

local function isEquipmentItemType(itemType)
    local normalizedType = tostring(itemType or "none")
    return normalizedType == "weapon" or normalizedType == "armor"
end

local function itemSupportsEmbeddedTrait(item)
    local itemType = tostring(item and item.itemType or "none")
    return itemType == "consumable" or isEquipmentItemType(itemType)
end

local function usesConsumableTrait(item)
    return tostring(item and item.itemType or "none") == "consumable"
end

local function getEmbeddedItemTrait(item)
    if usesConsumableTrait(item) then
        return normalizeConsumableTrait(item and item.consumableTrait)
    end
    if isEquipmentItemType(item and item.itemType) then
        return normalizeEquipmentTrait(item and item.equipmentTrait)
    end

    return nil
end

local function setEmbeddedItemTrait(item, trait)
    if type(item) ~= "table" then
        return
    end

    if usesConsumableTrait(item) then
        item.consumableTrait = normalizeConsumableTrait(trait)
        return
    end

    if isEquipmentItemType(item.itemType) then
        item.equipmentTrait = normalizeEquipmentTrait(trait)
    end
end

local function applyItemTypeDefaults(item)
    local itemType = tostring(item and item.itemType or "none")
    if itemType == "weapon" or itemType == "armor" or itemType == "modification" then
        item.canStack = false
        item.maxStackSize = 1
    elseif itemType == "consumable" or itemType == "material" then
        if item.canStack == nil then
            item.canStack = true
        end
        item.maxStackSize = math.max(1, tonumber(item.maxStackSize) or 99)
    else
        item.maxStackSize = math.max(1, tonumber(item.maxStackSize) or 1)
    end

    if itemType ~= "consumable" then
        item.consumableType = ""
        item.consumableElixirType = ""
    elseif tostring(item.consumableType or "") ~= "elixir" then
        item.consumableElixirType = ""
    end
end

local function parseKeyValueCountString(text, allowedKeys)
    local counts = {}
    for token in string.gmatch(ensureString(text), "[^,]+") do
        local key, value = token:match("^%s*([^=:%s]+)%s*[:=]%s*(-?%d+)%s*$")
        key = string.lower(ensureString(key))
        if key ~= "" and (allowedKeys == nil or allowedKeys[key]) then
            counts[key] = math.max(0, math.floor(tonumber(value) or 0))
        end
    end
    return counts
end

local function normalizeSocketColor(value)
    local normalized = string.lower(ensureString(value))
    for index = 1, #SOCKET_TYPE_ITEMS do
        if SOCKET_TYPE_ITEMS[index].value == normalized then
            return normalized
        end
    end
    return nil
end

local function getSocketTypeLabel(value)
    local normalized = normalizeSocketColor(value)
    if not normalized then
        return "Unknown"
    end
    for index = 1, #SOCKET_TYPE_ITEMS do
        local item = SOCKET_TYPE_ITEMS[index]
        if item.value == normalized then
            return item.label
        end
    end
    return normalized
end

local function buildItemSocketRows(item)
    local rows = {}
    if type(item) == "table" and type(item.sockets) == "table" and #item.sockets > 0 then
        for index = 1, #item.sockets do
            local color = normalizeSocketColor(type(item.sockets[index]) == "table" and item.sockets[index].color or item.sockets[index])
            if color then
                rows[#rows + 1] = {
                    color = color,
                }
            end
        end
        return rows
    end

    for index = 1, #SOCKET_COUNT_FIELDS do
        local entry = SOCKET_COUNT_FIELDS[index]
        local count = math.max(0, math.floor(tonumber(item and item[entry.field] or 0) or 0))
        for _ = 1, count do
            rows[#rows + 1] = {
                color = entry.key,
            }
        end
    end

    return rows
end

local function applyItemSocketRows(item, rows)
    local sockets = {}
    local counts = {}
    for index = 1, #SOCKET_COUNT_FIELDS do
        counts[SOCKET_COUNT_FIELDS[index].key] = 0
    end

    for index = 1, #(rows or {}) do
        local color = normalizeSocketColor(type(rows[index]) == "table" and rows[index].color or rows[index])
        if color then
            sockets[#sockets + 1] = {
                color = color,
            }
            counts[color] = (counts[color] or 0) + 1
        end
    end

    item.sockets = sockets
    for index = 1, #SOCKET_COUNT_FIELDS do
        local entry = SOCKET_COUNT_FIELDS[index]
        item[entry.field] = counts[entry.key] or 0
    end
end

local function getItemGenericLimitMap(item)
    local normalized = {}
    local source = type(item) == "table" and (item.maxGenericModificationCounts or item.maxModificationCounts) or nil
    for key, value in pairs(type(source) == "table" and source or {}) do
        local normalizedKey = string.lower(ensureString(key)):gsub("^%s+", ""):gsub("%s+$", "")
        if normalizedKey ~= "" then
            normalized[normalizedKey] = math.max(0, math.floor(tonumber(value) or 0))
        end
    end
    return normalized
end

local function applyItemGenericLimitMap(item, counts)
    local normalized = {}
    for key, value in pairs(type(counts) == "table" and counts or {}) do
        local normalizedKey = string.lower(ensureString(key)):gsub("^%s+", ""):gsub("%s+$", "")
        if normalizedKey ~= "" then
            normalized[normalizedKey] = math.max(0, math.floor(tonumber(value) or 0))
        end
    end
    item.maxGenericModificationCounts = normalized
    item.maxModificationCounts = {}
    for key, value in pairs(normalized) do
        item.maxModificationCounts[key] = value
    end
end

function DataEditor:BuildItemInspectorDatasetItems()
    local items = {
        { label = "None", value = "" },
    }

    local datasets = self:GetDatasets()
    for index = 1, #datasets do
        local dataset = datasets[index]
        items[#items + 1] = {
            label = self:GetDatasetDisplayName(dataset),
            value = dataset.id,
        }
    end

    return items
end

local function compareItemInspectorSubgroupLabels(left, right)
    local orderedLabels = {
        ["0-9"] = 1,
        ["A-F"] = 2,
        ["G-L"] = 3,
        ["M-R"] = 4,
        ["S-Z"] = 5,
        ["Other"] = 6,
    }

    local leftLabel = string.gsub(string.gsub(ensureString(left), "^%s+", ""), "%s+$", "")
    local rightLabel = string.gsub(string.gsub(ensureString(right), "^%s+", ""), "%s+$", "")
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

function DataEditor:BuildItemInspectorDatasetCollectionItems(collectionKey, sourceDatasetId, options)
    local items = {
        { label = type(options) == "table" and options.noneLabel or "None", value = "" },
    }

    if not sourceDatasetId or sourceDatasetId == "" or not self.Database or not self.Database.GetDatasetByID then
        return items
    end

    local dataset = self.Database.GetDatasetByID(sourceDatasetId)
    local collection = dataset and dataset[collectionKey] or {}
    local subgroupMap = {}
    local subgroupOrder = {}

    for index = 1, #collection do
        local entry = collection[index]
        if entry and entry.id then
            local subgroup = self.GetReferenceEntrySubgroupInfo and self:GetReferenceEntrySubgroupInfo(collectionKey, entry) or nil
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

    table.sort(subgroupOrder, function(leftKey, rightKey)
        local leftGroup = subgroupMap[leftKey]
        local rightGroup = subgroupMap[rightKey]
        return compareItemInspectorSubgroupLabels(leftGroup and leftGroup.label or "", rightGroup and rightGroup.label or "")
    end)

    for subgroupIndex = 1, #subgroupOrder do
        local subgroupKey = subgroupOrder[subgroupIndex]
        local subgroupGroup = subgroupMap[subgroupKey]
        items[#items + 1] = {
            label = subgroupGroup.label,
            value = ("subgroup:%s:%s:%s"):format(collectionKey, dataset.id or sourceDatasetId, subgroupKey),
            enabled = true,
            keepShownOnClick = true,
            notCheckable = true,
            children = subgroupGroup.children,
        }
    end

    return items
end

function DataEditor:BuildItemInspectorStatItems(sourceDatasetId)
    local items = self:BuildItemInspectorDatasetCollectionItems("stats", sourceDatasetId)
    for index = 1, #items do
        local item = items[index]
        if item and type(item.value) == "string" and item.value ~= "" and not item.children then
            local _, statId = parseDatasetQualifiedRef(item.value)
            item.value = statId or ""
        elseif item and type(item.children) == "table" then
            for childIndex = 1, #item.children do
                local child = item.children[childIndex]
                if child and type(child.value) == "string" then
                    local _, statId = parseDatasetQualifiedRef(child.value)
                    child.value = statId or ""
                end
            end
        end
    end

    return items
end

function DataEditor:BuildItemInspectorCollectionItems(collectionKey, sourceDatasetId)
    return self:BuildItemInspectorDatasetCollectionItems(collectionKey, sourceDatasetId)
end

function DataEditor:BuildItemInspectorItemSlotItems()
    local items = {}
    local datasets = self:GetDatasets()
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local slots = dataset and dataset.itemSlots or {}
        for slotIndex = 1, #slots do
            local itemSlot = slots[slotIndex]
            if itemSlot and itemSlot.id then
                items[#items + 1] = {
                    label = ("%s / %s"):format(self:GetDatasetDisplayName(dataset), self:GetEntryDisplayName("itemSlots", itemSlot)),
                    value = ("%s:%s"):format(dataset.id, itemSlot.id),
                }
            end
        end
    end
    return items
end

function DataEditor:BuildItemInspectorWeaponTypeItems(includeNone)
    local items = {}
    if includeNone ~= false then
        items[#items + 1] = {
            label = "None",
            value = "",
        }
    end

    local datasets = self:GetDatasets()
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local weaponTypes = dataset and dataset.weaponTypes or {}
        for weaponTypeIndex = 1, #weaponTypes do
            local weaponType = weaponTypes[weaponTypeIndex]
            if weaponType and weaponType.id then
                items[#items + 1] = {
                    label = ("%s / %s"):format(self:GetDatasetDisplayName(dataset), self:GetEntryDisplayName("weaponTypes", weaponType)),
                    value = ("%s:%s"):format(dataset.id, weaponType.id),
                }
            end
        end
    end

    return items
end

function DataEditor:BuildItemInspectorDamageSchoolItems()
    local items = {
        { label = "None", value = "" },
    }

    local datasets = self:GetDatasets()
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local damageSchools = dataset and dataset.damageSchools or {}
        for schoolIndex = 1, #damageSchools do
            local damageSchool = damageSchools[schoolIndex]
            if damageSchool and damageSchool.id then
                items[#items + 1] = {
                    label = ("%s / %s"):format(self:GetDatasetDisplayName(dataset), self:GetEntryDisplayName("damageSchools", damageSchool)),
                    value = ("%s:%s"):format(dataset.id, damageSchool.id),
                }
            end
        end
    end

    return items
end

function DataEditor:BuildItemInspectorStatRowItems(item)
    local dependencies = getDependenciesApi()
    local rows = {}
    local stats = normalizeItemStats(item)

    for index = 1, #stats do
        local entry = stats[index]
        local datasetId, statId = nil, nil
        if dependencies.ParseSourceStatRef then
            datasetId, statId = dependencies.ParseSourceStatRef(entry.sourceStatRef)
        end

        local dataset = datasetId and self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
        local sourceStat = nil
        if dataset and dataset.stats then
            for statIndex = 1, #dataset.stats do
                if dataset.stats[statIndex] and dataset.stats[statIndex].id == statId then
                    sourceStat = dataset.stats[statIndex]
                    break
                end
            end
        end

        rows[#rows + 1] = {
            rowIndex = index,
            datasetId = datasetId or "",
            statId = statId or "",
            datasetName = dataset and self:GetDatasetDisplayName(dataset) or (datasetId ~= "" and datasetId or "-"),
            statName = sourceStat and self:GetEntryDisplayName("stats", sourceStat) or (statId ~= "" and statId or "-"),
            valueText = tostring(entry.value or 0),
        }
    end

    return rows
end

function DataEditor:BuildItemInspectorSkillRowItems(item)
    local rows = {}
    local bonuses = normalizeItemSkillBonuses(item)

    for index = 1, #bonuses do
        local entry = bonuses[index]
        local datasetId, skillId = parseDatasetQualifiedRef(entry and entry.skillRef)
        local dataset = datasetId and self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
        local skillName = skillId or "-"
        if dataset and dataset.skills then
            for skillIndex = 1, #dataset.skills do
                local skill = dataset.skills[skillIndex]
                if skill and skill.id == skillId then
                    skillName = self:GetEntryDisplayName("skills", skill)
                    break
                end
            end
        end

        rows[#rows + 1] = {
            rowIndex = index,
            datasetName = dataset and self:GetDatasetDisplayName(dataset) or (datasetId ~= "" and datasetId or "-"),
            skillName = skillName,
            valueText = tostring(entry and entry.value or 0),
        }
    end

    return rows
end

function DataEditor:BuildItemInspectorSocketRowItems(item)
    local rows = {}
    local sockets = buildItemSocketRows(item)
    local selectedIndex = tonumber(self and self.SelectedItemInspectorSocketIndex)
    for index = 1, #sockets do
        rows[#rows + 1] = {
            rowIndex = index,
            socketColor = getSocketTypeLabel(sockets[index].color),
            slotText = selectedIndex == index and "Selected" or tostring(index),
            nameText = getSocketTypeLabel(sockets[index].color),
            statusText = selectedIndex == index and "Selected" or tostring(index),
            detailText = ("Socket %d"):format(index),
        }
    end
    return rows
end

function DataEditor:BuildItemInspectorGenericLimitRowItems(item)
    local rows = {}
    local counts = getItemGenericLimitMap(item)
    local orderedKeys = {}
    local selectedKey = string.lower(ensureString(self and self.SelectedItemInspectorGenericLimitKey))
    for key in pairs(counts) do
        orderedKeys[#orderedKeys + 1] = key
    end
    table.sort(orderedKeys)

    for index = 1, #orderedKeys do
        local key = orderedKeys[index]
        rows[#rows + 1] = {
            rowIndex = index,
            key = key,
            keyText = key,
            maxCountText = tostring(counts[key] or 0),
            nameText = key,
            statusText = tostring(counts[key] or 0),
            detailText = selectedKey == key and "Selected generic modification limit." or "Generic modification limit.",
        }
    end

    return rows
end

function DataEditor:RefreshItemInspectorSocketTable()
    local item = self:GetSelectedItem()
    local rows = self:BuildItemInspectorSocketRowItems(item)
    if tonumber(self.SelectedItemInspectorSocketIndex) and not rows[tonumber(self.SelectedItemInspectorSocketIndex)] then
        self.SelectedItemInspectorSocketIndex = nil
        rows = self:BuildItemInspectorSocketRowItems(item)
    end
    if self.ItemInspectorModificationSocketsScroll and self.ItemInspectorModificationSocketsScroll.SetItems then
        self.ItemInspectorModificationSocketsScroll:SetItems(rows)
    end
end

function DataEditor:RefreshItemInspectorGenericLimitTable()
    local item = self:GetSelectedItem()
    local selectedKey = string.lower(ensureString(self.SelectedItemInspectorGenericLimitKey))
    if selectedKey ~= "" and getItemGenericLimitMap(item)[selectedKey] == nil then
        self.SelectedItemInspectorGenericLimitKey = nil
    end

    if self.ItemInspectorModificationGenericLimitScroll and self.ItemInspectorModificationGenericLimitScroll.SetItems then
        self.ItemInspectorModificationGenericLimitScroll:SetItems(self:BuildItemInspectorGenericLimitRowItems(item))
    end
end

function DataEditor:BuildItemInspectorConsumableTraitStatRows(item)
    local rows = {}
    local consumableTrait = getEmbeddedItemTrait(item)

    for index = 1, #((consumableTrait and consumableTrait.statBonuses) or {}) do
        local entry = consumableTrait.statBonuses[index]
        local datasetId, statId = parseDatasetQualifiedRef(entry and entry.statRef)
        local dataset = datasetId and self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
        local statName = statId or "-"

        if dataset and dataset.stats then
            for statIndex = 1, #dataset.stats do
                local stat = dataset.stats[statIndex]
                if stat and stat.id == statId then
                    statName = self:GetEntryDisplayName("stats", stat)
                    break
                end
            end
        end

        rows[#rows + 1] = {
            rowIndex = index,
            datasetName = dataset and self:GetDatasetDisplayName(dataset) or (datasetId or "-"),
            statName = statName,
            valueText = tostring(entry and entry.value or 0),
        }
    end

    return rows
end

function DataEditor:BuildItemInspectorConsumableTraitSkillRows(item)
    local rows = {}
    local consumableTrait = getEmbeddedItemTrait(item)

    for index = 1, #((consumableTrait and consumableTrait.skillBonuses) or {}) do
        local entry = consumableTrait.skillBonuses[index]
        local datasetId, skillId = parseDatasetQualifiedRef(entry and entry.skillRef)
        local dataset = datasetId and self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
        local skillName = skillId or "-"

        if dataset and dataset.skills then
            for skillIndex = 1, #dataset.skills do
                local skill = dataset.skills[skillIndex]
                if skill and skill.id == skillId then
                    skillName = self:GetEntryDisplayName("skills", skill)
                    break
                end
            end
        end

        rows[#rows + 1] = {
            rowIndex = index,
            datasetName = dataset and self:GetDatasetDisplayName(dataset) or (datasetId or "-"),
            skillName = skillName,
            valueText = tostring(entry and entry.value or 0),
        }
    end

    return rows
end

function DataEditor:BuildItemInspectorConsumableTraitEventRows(item)
    local rows = {}
    local consumableTrait = getEmbeddedItemTrait(item)

    for index = 1, #((consumableTrait and consumableTrait.events) or {}) do
        local entry = consumableTrait.events[index]
        local effect = entry and entry.effects and entry.effects[1] or nil
        local amountText = "0"
        local detailText = ""
        local effectType = ensureString(effect and effect.type)

        if effectType == "heal" then
            amountText = tostring(effect and effect.baseHealing or 0)
        elseif effectType == "apply_aura" then
            amountText = tostring(effect and effect.stacks or 1)
            detailText = self:ResolveSpellInspectorReferenceLabel("auras", effect and effect.auraRef or "")
        elseif effectType == "remove_aura" then
            amountText = tostring(effect and effect.stacks or 1)
            detailText = self:ResolveSpellInspectorReferenceLabel("auras", effect and effect.auraRef or "")
        elseif effectType == "resource" then
            amountText = tostring(effect and effect.amount or 0)
            detailText = self:ResolveSpellInspectorReferenceLabel("resources", effect and effect.resourceRef or "")
        else
            amountText = tostring(effect and effect.baseDamage or 0)
        end

        local effectSummary = EVENT_EFFECT_LABELS[effectType] or ensureString(effectType, "-")
        if detailText ~= "" then
            effectSummary = effectSummary .. " " .. detailText
        end

        rows[#rows + 1] = {
            rowIndex = index,
            combatEventText = ensureString(entry and entry.combatEventId),
            targetText = TRIGGER_TARGET_LABELS[ensureString(entry and entry.triggerTarget)] or ensureString(entry and entry.triggerTarget, "-"),
            effectSummary = effectSummary,
            amountText = amountText,
        }
    end

    return rows
end

function DataEditor:CommitSelectedItem(mutate)
    local dataset, item = getSelectedItemAndDataset(self)
    if not dataset or not item or type(mutate) ~= "function" then
        return
    end

    mutate(item, dataset)
    applyItemTypeDefaults(item)
    local normalized = ItemClass and ItemClass.New and ItemClass:New(item):ToTable() or item
    for key in pairs(item) do
        if normalized[key] == nil then
            item[key] = nil
        end
    end
    for key, value in pairs(normalized) do
        item[key] = value
    end

    if self.Database and self.Database.NotifyDatasetEntryChanged then
        self.Database.NotifyDatasetEntryChanged(dataset.id, "items", {
            deferConfigurationChanged = true,
        })
    end

    self:RefreshAfterDatasetEntryChanged("items")
end

function DataEditor:GetItemInspectorPageDefinitions()
    local _, item = getSelectedItemAndDataset(self)
    if itemSupportsEmbeddedTrait(item) then
        return ITEM_INSPECTOR_PAGE_DEFINITIONS
    end

    return {
        ITEM_INSPECTOR_PAGE_DEFINITIONS[1],
        ITEM_INSPECTOR_PAGE_DEFINITIONS[2],
        ITEM_INSPECTOR_PAGE_DEFINITIONS[3],
        ITEM_INSPECTOR_PAGE_DEFINITIONS[4],
        ITEM_INSPECTOR_PAGE_DEFINITIONS[6],
        ITEM_INSPECTOR_PAGE_DEFINITIONS[7],
    }
end

function DataEditor:GetItemInspectorPageIndexByKey(key)
    local pages = self:GetItemInspectorPageDefinitions()
    for index = 1, #pages do
        if pages[index].key == key then
            return index
        end
    end

    return 1
end

function DataEditor:BuildItemInspectorPageSelectorItems()
    local items = {}
    local pages = self:GetItemInspectorPageDefinitions()

    for index = 1, #pages do
        items[#items + 1] = {
            label = pages[index].label,
            value = pages[index].key,
        }
    end

    return items
end

function DataEditor:RefreshItemInspectorPageSelector()
    local pages = self:GetItemInspectorPageDefinitions()
    local pageCount = #pages
    local activeIndex = math.max(1, math.min(self.ActiveItemInspectorPageIndex or 1, pageCount))
    self.ActiveItemInspectorPageIndex = activeIndex
    self.ActiveItemInspectorTabKey = pages[activeIndex] and pages[activeIndex].key or "general"

    local activeDefinition = pages[activeIndex]
    if self.ItemInspectorPageDropdown and activeDefinition then
        self._refreshingItemInspectorPageSelector = true
        self.ItemInspectorPageDropdown:SetItems(self:BuildItemInspectorPageSelectorItems())
        self.ItemInspectorPageDropdown:SetSelectedValue(activeDefinition.key, true)
        self._refreshingItemInspectorPageSelector = false
    end

    if self.ItemInspectorPreviousButton and self.ItemInspectorPreviousButton.SetEnabled then
        self.ItemInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end

    if self.ItemInspectorNextButton and self.ItemInspectorNextButton.SetEnabled then
        self.ItemInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetItemInspectorTab(tabKey)
    local pageDefinitions = self:GetItemInspectorPageDefinitions()
    self.ActiveItemInspectorPageIndex = self:GetItemInspectorPageIndexByKey(tabKey or "general")
    self.ActiveItemInspectorTabKey = pageDefinitions[self.ActiveItemInspectorPageIndex] and pageDefinitions[self.ActiveItemInspectorPageIndex].key or "general"

    local pageFrames = {
        general = self.ItemInspectorGeneralPage,
        behavior = self.ItemInspectorBehaviorPage,
        equipment = self.ItemInspectorEquipmentPage,
        modifications = self.ItemInspectorModificationsPage,
        consumable = self.ItemInspectorConsumablePage,
        conditions = self.ItemInspectorConditionsPage,
        stats = self.ItemInspectorStatsPage,
    }

    for key, page in pairs(pageFrames) do
        if page then
            if key == self.ActiveItemInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    self:RefreshItemInspectorPageSelector()
end

function DataEditor:EnsureItemInspectorStatContextMenu()
    if self.ItemInspectorStatContextMenu then
        return self.ItemInspectorStatContextMenu
    end

    self.ItemInspectorStatContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorItemInspectorStatContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-stat" or not self.ContextMenuItemStatRowIndex then
                return
            end

            local removeIndex = self.ContextMenuItemStatRowIndex
            self:CommitSelectedItem(function(selectedItem)
                local stats = normalizeItemStats(selectedItem)
                table.remove(stats, removeIndex)
                selectedItem.stats = stats
            end)

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.ItemInspectorStatContextMenu:SetParent(self.ItemInspectorPage or UIParent)
    self.ItemInspectorStatContextMenu:Create()
    return self.ItemInspectorStatContextMenu
end

function DataEditor:ShowItemInspectorStatContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureItemInspectorStatContextMenu()
    self.ContextMenuItemStatRowIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-stat" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:EnsureItemInspectorSkillContextMenu()
    if self.ItemInspectorSkillContextMenu then
        return self.ItemInspectorSkillContextMenu
    end

    self.ItemInspectorSkillContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorItemInspectorSkillContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-skill" or not self.ContextMenuItemSkillRowIndex then
                return
            end

            local removeIndex = self.ContextMenuItemSkillRowIndex
            self:CommitSelectedItem(function(selectedItem)
                local bonuses = normalizeItemSkillBonuses(selectedItem)
                table.remove(bonuses, removeIndex)
                selectedItem.skillBonuses = bonuses
            end)

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.ItemInspectorSkillContextMenu:SetParent(self.ItemInspectorPage or UIParent)
    self.ItemInspectorSkillContextMenu:Create()
    return self.ItemInspectorSkillContextMenu
end

function DataEditor:ShowItemInspectorSkillContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureItemInspectorSkillContextMenu()
    self.ContextMenuItemSkillRowIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-skill" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:RefreshItemInspectorPendingStatDropdown()
    local selectedDatasetId = self.ItemInspectorPendingStatDatasetDropdown and self.ItemInspectorPendingStatDatasetDropdown.GetSelectedValue and self.ItemInspectorPendingStatDatasetDropdown:GetSelectedValue() or ""
    if self.ItemInspectorPendingStatDropdown and self.ItemInspectorPendingStatDropdown.SetItems then
        self.ItemInspectorPendingStatDropdown:SetItems(self:BuildItemInspectorStatItems(selectedDatasetId))
    end
end

function DataEditor:RefreshItemInspectorPendingSkillDropdown()
    local selectedDatasetId = self.ItemInspectorPendingSkillDatasetDropdown and self.ItemInspectorPendingSkillDatasetDropdown.GetSelectedValue and self.ItemInspectorPendingSkillDatasetDropdown:GetSelectedValue() or ""
    if self.ItemInspectorPendingSkillDropdown and self.ItemInspectorPendingSkillDropdown.SetItems then
        self.ItemInspectorPendingSkillDropdown:SetItems(self:BuildItemInspectorCollectionItems("skills", selectedDatasetId))
    end
end

function DataEditor:RefreshItemInspectorStatsTable()
    local _, item = getSelectedItemAndDataset(self)
    local rows = self:BuildItemInspectorStatRowItems(item)

    if self.ItemInspectorStatsScroll and self.ItemInspectorStatsScroll.SetItems then
        self.ItemInspectorStatsScroll:SetItems(rows)
    end
end

function DataEditor:RefreshItemInspectorSkillsTable()
    local _, item = getSelectedItemAndDataset(self)
    local rows = self:BuildItemInspectorSkillRowItems(item)

    if self.ItemInspectorSkillsScroll and self.ItemInspectorSkillsScroll.SetItems then
        self.ItemInspectorSkillsScroll:SetItems(rows)
    end
end

function DataEditor:RefreshItemInspectorConsumablePendingStatDropdown()
    local selectedDatasetId = self.ItemInspectorConsumablePendingStatDatasetDropdown and self.ItemInspectorConsumablePendingStatDatasetDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingStatDatasetDropdown:GetSelectedValue() or ""
    if self.ItemInspectorConsumablePendingStatDropdown and self.ItemInspectorConsumablePendingStatDropdown.SetItems then
        self.ItemInspectorConsumablePendingStatDropdown:SetItems(self:BuildItemInspectorCollectionItems("stats", selectedDatasetId))
    end
end

function DataEditor:RefreshItemInspectorConsumablePendingSkillDropdown()
    local selectedDatasetId = self.ItemInspectorConsumablePendingSkillDatasetDropdown and self.ItemInspectorConsumablePendingSkillDatasetDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingSkillDatasetDropdown:GetSelectedValue() or ""
    if self.ItemInspectorConsumablePendingSkillDropdown and self.ItemInspectorConsumablePendingSkillDropdown.SetItems then
        self.ItemInspectorConsumablePendingSkillDropdown:SetItems(self:BuildItemInspectorCollectionItems("skills", selectedDatasetId))
    end
end

function DataEditor:RefreshItemInspectorConsumablePendingAuraDropdown()
    local selectedDatasetId = self.ItemInspectorConsumableAutoAuraDatasetDropdown and self.ItemInspectorConsumableAutoAuraDatasetDropdown.GetSelectedValue and self.ItemInspectorConsumableAutoAuraDatasetDropdown:GetSelectedValue() or ""
    if self.ItemInspectorConsumableAutoAuraDropdown and self.ItemInspectorConsumableAutoAuraDropdown.SetItems then
        self.ItemInspectorConsumableAutoAuraDropdown:SetItems(self:BuildItemInspectorCollectionItems("auras", selectedDatasetId))
    end
end

function DataEditor:RefreshItemInspectorConsumablePendingEffectReferenceDropdown()
    local selectedDatasetId = self.ItemInspectorConsumablePendingEffectDatasetDropdown and self.ItemInspectorConsumablePendingEffectDatasetDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingEffectDatasetDropdown:GetSelectedValue() or ""
    local effectType = self.ItemInspectorConsumablePendingEffectDropdown and self.ItemInspectorConsumablePendingEffectDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingEffectDropdown:GetSelectedValue() or "damage"
    local collectionKey = nil

    if effectType == "apply_aura" or effectType == "remove_aura" then
        collectionKey = "auras"
    elseif effectType == "resource" then
        collectionKey = "resources"
    end

    if self.ItemInspectorConsumablePendingEffectReferenceDropdown and self.ItemInspectorConsumablePendingEffectReferenceDropdown.SetItems then
        self.ItemInspectorConsumablePendingEffectReferenceDropdown:SetItems(collectionKey and self:BuildItemInspectorCollectionItems(collectionKey, selectedDatasetId) or {
            { label = "None", value = "" },
        })
    end
end

function DataEditor:RefreshItemInspectorConsumableTraitStatTable()
    local _, item = getSelectedItemAndDataset(self)
    local rows = self:BuildItemInspectorConsumableTraitStatRows(item)
    if self.ItemInspectorConsumableStatsScroll and self.ItemInspectorConsumableStatsScroll.SetItems then
        self.ItemInspectorConsumableStatsScroll:SetItems(rows)
    end
end

function DataEditor:RefreshItemInspectorConsumableTraitSkillTable()
    local _, item = getSelectedItemAndDataset(self)
    local rows = self:BuildItemInspectorConsumableTraitSkillRows(item)
    if self.ItemInspectorConsumableSkillsScroll and self.ItemInspectorConsumableSkillsScroll.SetItems then
        self.ItemInspectorConsumableSkillsScroll:SetItems(rows)
    end
end

function DataEditor:RefreshItemInspectorConsumableTraitEventTable()
    local _, item = getSelectedItemAndDataset(self)
    local rows = self:BuildItemInspectorConsumableTraitEventRows(item)
    if self.ItemInspectorConsumableEventsScroll and self.ItemInspectorConsumableEventsScroll.SetItems then
        self.ItemInspectorConsumableEventsScroll:SetItems(rows)
    end
end

DataEditor.ItemInspectorShared = DataEditor.ItemInspectorShared or {}
local ItemInspectorShared = DataEditor.ItemInspectorShared

ItemInspectorShared.INSPECTOR_SIDE_PADDING = INSPECTOR_SIDE_PADDING
ItemInspectorShared.CONTROL_HEIGHT = CONTROL_HEIGHT
ItemInspectorShared.FIELD_WIDTH = FIELD_WIDTH
ItemInspectorShared.QUALITY_ITEMS = QUALITY_ITEMS
ItemInspectorShared.UNIQUE_FLAG_ITEMS = UNIQUE_FLAG_ITEMS
ItemInspectorShared.BINDING_FLAG_ITEMS = BINDING_FLAG_ITEMS
ItemInspectorShared.ITEM_TYPE_ITEMS = ITEM_TYPE_ITEMS
ItemInspectorShared.ARMOR_WEIGHT_ITEMS = ARMOR_WEIGHT_ITEMS
ItemInspectorShared.MODIFICATION_ARMOR_WEIGHT_ITEMS = MODIFICATION_ARMOR_WEIGHT_ITEMS
ItemInspectorShared.SOCKET_TYPE_ITEMS = SOCKET_TYPE_ITEMS
ItemInspectorShared.MODIFICATION_KIND_ITEMS = MODIFICATION_KIND_ITEMS
ItemInspectorShared.DAMAGE_MODE_ITEMS = DAMAGE_MODE_ITEMS
ItemInspectorShared.CONSUMABLE_PHASE_ITEMS = CONSUMABLE_PHASE_ITEMS
ItemInspectorShared.CONSUMABLE_TYPE_ITEMS = CONSUMABLE_TYPE_ITEMS
ItemInspectorShared.CONSUMABLE_ELIXIR_TYPE_ITEMS = CONSUMABLE_ELIXIR_TYPE_ITEMS
ItemInspectorShared.AUTO_AURA_TARGET_ITEMS = AUTO_AURA_TARGET_ITEMS
ItemInspectorShared.TRIGGER_TARGET_ITEMS = TRIGGER_TARGET_ITEMS
ItemInspectorShared.EVENT_EFFECT_ITEMS = EVENT_EFFECT_ITEMS
ItemInspectorShared.TRIGGER_TARGET_LABELS = TRIGGER_TARGET_LABELS
ItemInspectorShared.EVENT_EFFECT_LABELS = EVENT_EFFECT_LABELS
ItemInspectorShared.copyTable = copyTable
ItemInspectorShared.ensureString = ensureString
ItemInspectorShared.parseDatasetQualifiedRef = parseDatasetQualifiedRef
ItemInspectorShared.getDependenciesApi = getDependenciesApi
ItemInspectorShared.getSelectedItemAndDataset = getSelectedItemAndDataset
ItemInspectorShared.buildLabel = buildLabel
ItemInspectorShared.buildHintText = buildHintText
ItemInspectorShared.setDropdownEnabled = setDropdownEnabled
ItemInspectorShared.setTextElementEnabled = setTextElementEnabled
ItemInspectorShared.setCheckboxEnabled = setCheckboxEnabled
ItemInspectorShared.setButtonEnabled = setButtonEnabled
ItemInspectorShared.setElementGroupVisible = setElementGroupVisible
ItemInspectorShared.createEquipmentFieldGroup = createEquipmentFieldGroup
ItemInspectorShared.createInspectorSection = createInspectorSection
ItemInspectorShared.createHorizontalFieldLabels = createHorizontalFieldLabels
ItemInspectorShared.createCheckbox = createCheckbox
ItemInspectorShared.getItemTypeLabel = getItemTypeLabel
ItemInspectorShared.getQualityLabel = getQualityLabel
ItemInspectorShared.normalizeArmorWeightValue = normalizeArmorWeightValue
ItemInspectorShared.normalizeItemStats = normalizeItemStats
ItemInspectorShared.normalizeItemSkillBonuses = normalizeItemSkillBonuses
ItemInspectorShared.normalizeItemTrait = normalizeItemTrait
ItemInspectorShared.normalizeConsumableTrait = normalizeConsumableTrait
ItemInspectorShared.normalizeEquipmentTrait = normalizeEquipmentTrait
ItemInspectorShared.normalizeConsumableTraitStatBonuses = normalizeConsumableTraitStatBonuses
ItemInspectorShared.normalizeConsumableTraitSkillBonuses = normalizeConsumableTraitSkillBonuses
ItemInspectorShared.normalizeConsumableTraitAutomaticAuras = normalizeConsumableTraitAutomaticAuras
ItemInspectorShared.normalizeConsumableTraitEvents = normalizeConsumableTraitEvents
ItemInspectorShared.isEquipmentItemType = isEquipmentItemType
ItemInspectorShared.itemSupportsEmbeddedTrait = itemSupportsEmbeddedTrait
ItemInspectorShared.usesConsumableTrait = usesConsumableTrait
ItemInspectorShared.getEmbeddedItemTrait = getEmbeddedItemTrait
ItemInspectorShared.setEmbeddedItemTrait = setEmbeddedItemTrait
ItemInspectorShared.applyItemTypeDefaults = applyItemTypeDefaults
ItemInspectorShared.normalizeSocketColor = normalizeSocketColor
ItemInspectorShared.getSocketTypeLabel = getSocketTypeLabel
ItemInspectorShared.buildItemSocketRows = buildItemSocketRows
ItemInspectorShared.applyItemSocketRows = applyItemSocketRows
ItemInspectorShared.getItemGenericLimitMap = getItemGenericLimitMap
ItemInspectorShared.applyItemGenericLimitMap = applyItemGenericLimitMap

