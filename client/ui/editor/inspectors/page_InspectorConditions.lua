local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Conditions = Addon.Client and Addon.Client.Conditions or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Equipment = Profile and Profile.Equipment or {}

local DEFAULT_FIELD_WIDTH = 236

local CONDITION_TYPE_LABELS = {
    level = "Level",
    class = "Class",
    race = "Race",
    weapon_type = "Weapon Type",
    item_equipped = "Item Equipped",
    aura_requirement = "Aura Requirement",
    trait_requirement = "Trait Requirement",
    caster_dead = "Caster Dead",
    caster_defended_melee_this_turn = "Caster Defended Melee This Turn",
    caster_failed_attack_this_turn = "Failed Attack This Turn",
    caster_killed_this_turn = "Caster Killed This Turn",
    target_killed_this_turn = "Target Killed This Turn",
    caster_health_percent = "Caster Health %",
    target_health_percent = "Target Health %",
    target_creature_type = "Target Creature Type",
    target_creature_size = "Target Creature Size",
    mounted = "Mounted",
    skill_requirement = "Skill Requirement",
}

local AUTHORABLE_CONDITION_TYPES = {
    "level",
    "class",
    "race",
    "weapon_type",
    "item_equipped",
    "aura_requirement",
    "trait_requirement",
    "caster_dead",
    "caster_defended_melee_this_turn",
    "caster_failed_attack_this_turn",
    "caster_killed_this_turn",
    "target_killed_this_turn",
    "caster_health_percent",
    "target_health_percent",
    "target_creature_type",
    "target_creature_size",
    "mounted",
    "skill_requirement",
}

local UNIT_ITEMS = {
    { label = "Caster", value = "caster" },
    { label = "Target", value = "target" },
}

local CREATURE_TYPE_ITEMS = {
    { label = "Beast", value = "beast" },
    { label = "Critter", value = "critter" },
    { label = "Demon", value = "demon" },
    { label = "Dragonkin", value = "dragonkin" },
    { label = "Elemental", value = "elemental" },
    { label = "Giant", value = "giant" },
    { label = "Humanoid", value = "humanoid" },
    { label = "Mechanical", value = "mechanical" },
    { label = "Undead", value = "undead" },
}

local CREATURE_SIZE_ITEMS = {
    { label = "Tiny", value = "tiny" },
    { label = "Small", value = "small" },
    { label = "Medium", value = "medium" },
    { label = "Large", value = "large" },
    { label = "Huge", value = "huge" },
    { label = "Gargantuan", value = "gargantuan" },
}

local OWNER_CONFIGS = {
    spell = {
        getOwner = function(self)
            local _, owner = self:GetSelectedSpellAndDataset()
            return owner
        end,
        commitOwner = function(self, mutate)
            self:CommitSelectedSpell(mutate)
        end,
        pageField = "SpellInspectorConditionsPage",
        refreshField = "RefreshSpellInspectorPage",
        defaultType = "level",
        fieldWidthField = "SpellInspectorFieldWidth",
        sidePaddingField = "SpellInspectorSidePadding",
    },
    item = {
        getOwner = function(self)
            return self:GetSelectedItem()
        end,
        commitOwner = function(self, mutate)
            self:CommitSelectedItem(mutate)
        end,
        pageField = "ItemInspectorConditionsPage",
        refreshField = "RefreshItemInspectorPage",
        defaultType = "level",
        fieldWidthField = nil,
        sidePaddingField = nil,
    },
    trait = {
        getOwner = function(self)
            local _, owner = self:GetSelectedTraitAndDataset()
            return owner
        end,
        commitOwner = function(self, mutate)
            self:CommitSelectedTrait(mutate)
        end,
        pageField = "TraitInspectorConditionsPage",
        refreshField = "RefreshTraitInspectorPage",
        defaultType = "level",
        fieldWidthField = nil,
        sidePaddingField = nil,
    },
}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
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

local function setGroupVisible(group, visible)
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

local function buildLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or DEFAULT_FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
end

local function createCheckbox(parent, name, text, checked, onValueChanged, width)
    local checkbox = UI.Checkbox:New({
        name = name,
        width = width or DEFAULT_FIELD_WIDTH,
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

local function getOwnerConfig(ownerKey)
    return OWNER_CONFIGS[tostring(ownerKey or "")]
end

local function getUi(self, ownerKey)
    self.ConditionInspectorUi = self.ConditionInspectorUi or {}
    self.ConditionInspectorUi[ownerKey] = self.ConditionInspectorUi[ownerKey] or {}
    return self.ConditionInspectorUi[ownerKey]
end

local function getFieldWidth(self, ownerKey)
    local config = getOwnerConfig(ownerKey)
    if config and config.fieldWidthField and tonumber(self[config.fieldWidthField]) then
        return tonumber(self[config.fieldWidthField])
    end

    return DEFAULT_FIELD_WIDTH
end

local function buildAcrossDatasets(self, collectionKey, includeNone)
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
        local collection = dataset and dataset[collectionKey] or {}
        for index = 1, #collection do
            local entry = collection[index]
            if entry and entry.id then
                items[#items + 1] = {
                    label = ("%s / %s"):format(self:GetDatasetDisplayName(dataset), self:GetEntryDisplayName(collectionKey, entry)),
                    value = ("%s:%s"):format(dataset.id, entry.id),
                }
            end
        end
    end

    return items
end

local function getFirstSelectableValue(items)
    for index = 1, #(items or {}) do
        local value = ensureString(items[index] and items[index].value)
        if value ~= "" then
            return value
        end
    end

    return nil
end

local function getFirstSelectableValues(items)
    local value = getFirstSelectableValue(items)
    if value then
        return { value }
    end

    return {}
end

function DataEditor:CreateAuthoringConditionDefaults(conditionType)
    local normalizedType = ensureString(conditionType)
    local condition = Conditions:CreateConditionDefaults(normalizedType) or {
        type = normalizedType,
        showOnTooltip = false,
        tooltipTextOverride = "",
        invert = false,
    }

    if normalizedType == "level" then
        condition.minimumValue = condition.minimumValue ~= nil and condition.minimumValue or 1
    elseif normalizedType == "class" then
        condition.classRefs = #(condition.classRefs or {}) > 0 and condition.classRefs or getFirstSelectableValues(buildAcrossDatasets(self, "classes", false))
    elseif normalizedType == "race" then
        condition.raceRefs = #(condition.raceRefs or {}) > 0 and condition.raceRefs or getFirstSelectableValues(buildAcrossDatasets(self, "races", false))
    elseif normalizedType == "weapon_type" then
        condition.weaponTypeRefs = #(condition.weaponTypeRefs or {}) > 0 and condition.weaponTypeRefs or getFirstSelectableValues(buildAcrossDatasets(self, "weaponTypes", false))
    elseif normalizedType == "item_equipped" then
        condition.slotKey = ensureString(condition.slotKey) ~= "" and condition.slotKey or getFirstSelectableValue(self:BuildInspectorConditionSlotItems()) or "head"
        condition.weaponTypeRefs = condition.weaponTypeRefs or {}
        condition.requiresShield = condition.requiresShield == true
    elseif normalizedType == "aura_requirement" then
        condition.unit = ensureString(condition.unit) ~= "" and condition.unit or "caster"
        condition.auraRef = ensureString(condition.auraRef) ~= "" and condition.auraRef or getFirstSelectableValue(buildAcrossDatasets(self, "auras", true))
    elseif normalizedType == "trait_requirement" then
        condition.unit = ensureString(condition.unit) ~= "" and condition.unit or "caster"
        condition.traitRef = ensureString(condition.traitRef) ~= "" and condition.traitRef or getFirstSelectableValue(buildAcrossDatasets(self, "traits", true))
    elseif normalizedType == "caster_health_percent" or normalizedType == "target_health_percent" then
        condition.maximumValue = condition.maximumValue ~= nil and condition.maximumValue or 50
    elseif normalizedType == "target_creature_type" then
        condition.creatureTypes = #(condition.creatureTypes or {}) > 0 and condition.creatureTypes or { "humanoid" }
    elseif normalizedType == "target_creature_size" then
        condition.creatureSizes = #(condition.creatureSizes or {}) > 0 and condition.creatureSizes or { "medium" }
    elseif normalizedType == "mounted" then
        condition.unit = ensureString(condition.unit) ~= "" and condition.unit or "caster"
    elseif normalizedType == "skill_requirement" then
        condition.skillRef = ensureString(condition.skillRef) ~= "" and condition.skillRef or getFirstSelectableValue(self:BuildSpellInspectorSkillsAcrossDatasets())
        condition.minimumValue = condition.minimumValue ~= nil and condition.minimumValue or 1
    end

    return condition
end

function DataEditor:GetInspectorConditionTypeItems()
    local items = {}
    for index = 1, #AUTHORABLE_CONDITION_TYPES do
        local conditionType = AUTHORABLE_CONDITION_TYPES[index]
        items[#items + 1] = {
            label = CONDITION_TYPE_LABELS[conditionType] or conditionType,
            value = conditionType,
        }
    end
    return items
end

function DataEditor:BuildInspectorConditionSlotItems()
    local items = {
        { label = "Any Slot", value = "" },
    }
    local definitions = Profile and Profile.Definitions or {}
    local slotTextures = definitions and definitions.SlotTextures or {}
    local seen = {}
    local keys = {}

    for slotKey in pairs(slotTextures) do
        local normalized = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(slotKey) or ensureString(slotKey)
        if normalized ~= "" and not seen[normalized] then
            seen[normalized] = true
            keys[#keys + 1] = normalized
        end
    end

    table.sort(keys, function(left, right)
        return (Equipment.PrettySlotLabel and Equipment.PrettySlotLabel(left) or left) < (Equipment.PrettySlotLabel and Equipment.PrettySlotLabel(right) or right)
    end)

    for index = 1, #keys do
        local slotKey = keys[index]
        items[#items + 1] = {
            label = Equipment.PrettySlotLabel and Equipment.PrettySlotLabel(slotKey) or slotKey,
            value = slotKey,
        }
    end

    return items
end

function DataEditor:GetInspectorConditionOwner(ownerKey)
    local config = getOwnerConfig(ownerKey)
    if not config or type(config.getOwner) ~= "function" then
        return nil
    end

    return config.getOwner(self)
end

function DataEditor:CommitInspectorConditionOwner(ownerKey, mutate)
    local config = getOwnerConfig(ownerKey)
    if not config or type(config.commitOwner) ~= "function" or type(mutate) ~= "function" then
        return
    end

    config.commitOwner(self, function(owner)
        owner.conditions = owner.conditions or {}
        mutate(owner)
    end)
end

function DataEditor:SetSelectedInspectorConditionIndex(ownerKey, index)
    local owner = self:GetInspectorConditionOwner(ownerKey)
    local conditions = owner and owner.conditions or {}
    self.SelectedInspectorConditionIndices = self.SelectedInspectorConditionIndices or {}
    index = tonumber(index)

    if not index or not conditions[index] then
        self.SelectedInspectorConditionIndices[ownerKey] = nil
    else
        self.SelectedInspectorConditionIndices[ownerKey] = index
    end
end

function DataEditor:GetSelectedInspectorConditionIndex(ownerKey)
    self.SelectedInspectorConditionIndices = self.SelectedInspectorConditionIndices or {}
    return tonumber(self.SelectedInspectorConditionIndices[ownerKey])
end

function DataEditor:GetSelectedInspectorCondition(ownerKey)
    local owner = self:GetInspectorConditionOwner(ownerKey)
    local conditions = owner and owner.conditions or {}
    local index = self:GetSelectedInspectorConditionIndex(ownerKey)
    if not index or not conditions[index] then
        return nil, nil
    end

    return conditions[index], index
end

function DataEditor:BuildInspectorConditionRows(ownerKey)
    local owner = self:GetInspectorConditionOwner(ownerKey)
    local rows = {}
    local context = type(Conditions.BuildContext) == "function" and Conditions:BuildContext(ownerKey, owner, {}) or nil

    for index = 1, #((owner and owner.conditions) or {}) do
        local condition = owner.conditions[index]
        rows[#rows + 1] = {
            rowIndex = index,
            typeText = CONDITION_TYPE_LABELS[condition and condition.type] or ensureString(condition and condition.type),
            detailText = type(Conditions.ResolveConditionText) == "function" and Conditions:ResolveConditionText(condition, context) or "",
            tooltipText = condition and condition.showOnTooltip == true and "Shown" or "",
        }
    end

    return rows
end

function DataEditor:RefreshInspectorConditionsTable(ownerKey)
    local ui = getUi(self, ownerKey)
    local rows = self:BuildInspectorConditionRows(ownerKey)
    if ui.ConditionsScroll and ui.ConditionsScroll.SetItems then
        ui.ConditionsScroll:SetItems(rows)
    end

    local selectedIndex = self:GetSelectedInspectorConditionIndex(ownerKey)
    if not selectedIndex or not rows[selectedIndex] then
        self:SetSelectedInspectorConditionIndex(ownerKey, rows[1] and 1 or nil)
    end
end

function DataEditor:EnsureInspectorConditionContextMenu()
    if self.InspectorConditionContextMenu then
        return self.InspectorConditionContextMenu
    end

    self.InspectorConditionContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorInspectorConditionContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-condition" or not self.ContextMenuConditionOwnerKey or not self.ContextMenuConditionIndex then
                return
            end

            local ownerKey = self.ContextMenuConditionOwnerKey
            local removeIndex = self.ContextMenuConditionIndex
            self:CommitInspectorConditionOwner(ownerKey, function(owner)
                table.remove(owner.conditions or {}, removeIndex)
            end)

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.InspectorConditionContextMenu:SetParent(UIParent)
    self.InspectorConditionContextMenu:Create()
    return self.InspectorConditionContextMenu
end

function DataEditor:ShowInspectorConditionContextMenu(ownerKey, anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureInspectorConditionContextMenu()
    self.ContextMenuConditionOwnerKey = ownerKey
    self.ContextMenuConditionIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-condition" },
    })
    menu:ShowAt(anchorFrame)
end

local function createGroup(ui, root, name, labelText, height)
    local groupHeight = 12 + 2 + (height or 18)
    local group = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), name, {
        width = ui.FieldWidth,
        height = groupHeight,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    group._visibleHeight = groupHeight
    root:AddChild(group)
    group:AddChild(buildLabel(group:GetFrame(), name .. "Label", labelText, ui.FieldWidth))
    return group
end

local function bindTextInput(input, callback)
    input:SetScript("OnEnterPressed", callback)
    input:SetScript("OnEditFocusLost", callback)
end

local function createTextInput(group, name, defaultText, width)
    local input = UI.CreateTextInput(group:GetFrame(), name, {
        width = width or DEFAULT_FIELD_WIDTH,
        height = 18,
        text = defaultText or "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    group:AddChild(input)
    return input
end

local function createDropdown(group, name, items, width, onValueChanged, multiSelect)
    local dropdown = UI.CreateDropdown(group:GetFrame(), name, {
        width = width or DEFAULT_FIELD_WIDTH,
        height = 18,
        items = items or {},
        multiSelect = multiSelect == true,
        onValueChanged = onValueChanged,
    })
    group:AddChild(dropdown)
    return dropdown
end

local function createEditorRoot(self, ownerKey, page)
    local ui = getUi(self, ownerKey)
    if ui.Root then
        return ui
    end

    ui.FieldWidth = getFieldWidth(self, ownerKey)
    ui.Root = UI.CreateLayout(UI.VerticalLayoutGroup, page, ("RPEDataEditor%sInspectorConditionsRoot"):format(ownerKey), {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = false,
    })
    ui.Root:GetFrame():SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    ui.Root:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
    ui.Root:GetFrame():SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
    ui.Root:GetFrame():SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

    ui.Root:AddChild(buildLabel(ui.Root:GetFrame(), ("RPEDataEditor%sInspectorConditionsLabel"):format(ownerKey), "Conditions", ui.FieldWidth))

    ui.ConditionsPanel = UI.CreatePanel(ui.Root:GetFrame(), ("RPEDataEditor%sInspectorConditionsPanel"):format(ownerKey), {
        width = ui.FieldWidth,
        height = 74,
        contentInset = 1,
        showBorder = true,
    })
    ui.Root:AddChild(ui.ConditionsPanel)

    ui.ConditionsScroll = UI.ScrollLayout:New({
        name = ("RPEDataEditor%sInspectorConditionsScroll"):format(ownerKey),
        width = ui.FieldWidth,
        height = 72,
        visibleRows = 4,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    ui.ConditionsScroll:SetParent(ui.ConditionsPanel:GetContentFrame())
    ui.ConditionsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "typeText", width = 74, justifyH = "LEFT" },
                { key = "detailText", width = ui.FieldWidth - 130, justifyH = "LEFT" },
                { key = "tooltipText", width = 46, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "LeftButton" then
                    self:SetSelectedInspectorConditionIndex(ownerKey, rowData and rowData.rowIndex or nil)
                    self:RefreshInspectorConditionsPage(ownerKey)
                elseif button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowInspectorConditionContextMenu(ownerKey, anchor, rowData)
                end
            end)
        end
    end)
    ui.ConditionsScroll:Create()
    UI.Utils.AnchorFill(ui.ConditionsScroll, ui.ConditionsPanel:GetContentFrame(), 0, 0, 0, 0)

    local function handleMouseWheel(_, delta)
        local _, maxValue = ui.EditorScrollBar:GetMinMaxValues()
        local current = ui.EditorScrollBar:GetValue() or 0
        local nextValue = math.max(0, math.min(maxValue or 0, current - ((delta or 0) * 24)))
        ui.EditorScrollBar:SetValue(nextValue)
    end

    local function attachMouseWheel(target)
        local frame = target and target.GetFrame and target:GetFrame() or target
        if not frame then
            return
        end

        if frame.EnableMouseWheel then
            frame:EnableMouseWheel(true)
        end

        if frame.HookScript then
            frame:HookScript("OnMouseWheel", handleMouseWheel)
        elseif frame.SetScript then
            frame:SetScript("OnMouseWheel", handleMouseWheel)
        end
    end

    ui.EditorScrollFrame = CreateFrame("ScrollFrame", ("RPEDataEditor%sInspectorConditionEditorScrollFrame"):format(ownerKey), page)
    ui.EditorScrollFrame:SetPoint("TOPLEFT", ui.ConditionsPanel:GetFrame(), "BOTTOMLEFT", 0, -6)
    ui.EditorScrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -20, 0)
    ui.EditorScrollFrame:EnableMouseWheel(true)
    ui.EditorScrollFrame:SetClipsChildren(true)
    attachMouseWheel(page)
    attachMouseWheel(ui.EditorScrollFrame)

    ui.EditorScrollBar = CreateFrame("Slider", ("RPEDataEditor%sInspectorConditionEditorScrollBar"):format(ownerKey), page)
    ui.EditorScrollBar:SetPoint("TOPRIGHT", ui.EditorScrollFrame, "TOPRIGHT", 16, -2)
    ui.EditorScrollBar:SetPoint("BOTTOMRIGHT", ui.EditorScrollFrame, "BOTTOMRIGHT", 16, 2)
    ui.EditorScrollBar:SetOrientation("VERTICAL")
    ui.EditorScrollBar:SetMinMaxValues(0, 0)
    ui.EditorScrollBar:SetValueStep(12)
    if ui.EditorScrollBar.SetObeyStepOnDrag then
        ui.EditorScrollBar:SetObeyStepOnDrag(true)
    end
    ui.EditorScrollBar:SetWidth(12)

    ui.EditorScrollBarTrack = ui.EditorScrollBarTrack or ui.EditorScrollBar:CreateTexture(nil, "BACKGROUND")
    ui.EditorScrollBarTrack:SetAllPoints(ui.EditorScrollBar)
    do
        local trackColor = UI.ResolveColor(nil, "scrollbar.track")
        ui.EditorScrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)
    end

    ui.EditorScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    do
        local thumb = ui.EditorScrollBar.GetThumbTexture and ui.EditorScrollBar:GetThumbTexture() or nil
        if thumb and thumb.SetVertexColor then
            local thumbColor = UI.ResolveColor(nil, "scrollbar.thumb")
            thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
        end
    end
    ui.EditorScrollBar:SetValue(0)

    ui.EditorRoot = UI.CreateLayout(UI.VerticalLayoutGroup, ui.EditorScrollFrame, ("RPEDataEditor%sInspectorConditionEditorRoot"):format(ownerKey), {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = true,
    })
    ui.EditorRoot:GetFrame():SetPoint("TOPLEFT", ui.EditorScrollFrame, "TOPLEFT", 0, 0)
    ui.EditorRoot:GetFrame():SetPoint("TOPRIGHT", ui.EditorScrollFrame, "TOPRIGHT", 0, 0)
    ui.EditorScrollFrame:SetScrollChild(ui.EditorRoot:GetFrame())
    ui.EditorScrollBar:SetScript("OnValueChanged", function(_, value)
        ui.EditorScrollFrame:SetVerticalScroll(value or 0)
    end)
    ui.EditorScrollFrame:SetScript("OnMouseWheel", handleMouseWheel)
    ui.EditorScrollFrame:SetScript("OnSizeChanged", function(scrollFrame)
        local width = math.max(1, (scrollFrame:GetWidth() or ui.FieldWidth) - 4)
        ui.EditorRoot:GetFrame():SetWidth(width)
        if ui.EditorRoot.RefreshLayout then
            ui.EditorRoot:RefreshLayout()
        end
        if self.RefreshInspectorConditionsScrollBounds then
            self:RefreshInspectorConditionsScrollBounds(ownerKey)
        end
    end)
    attachMouseWheel(ui.EditorRoot)

    ui.Toolbar = UI.CreateLayout(UI.HorizontalLayoutGroup, ui.EditorRoot:GetFrame(), ("RPEDataEditor%sInspectorConditionsToolbar"):format(ownerKey), {
        width = ui.FieldWidth,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    ui.EditorRoot:AddChild(ui.Toolbar)

    ui.AddConditionButton = UI.CreateButton(ui.Toolbar:GetFrame(), ("RPEDataEditor%sInspectorAddConditionButton"):format(ownerKey), "Add Condition", 92, function()
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions = owner.conditions or {}
            owner.conditions[#owner.conditions + 1] = self:CreateAuthoringConditionDefaults((getOwnerConfig(ownerKey) or {}).defaultType or "level")
            self:SetSelectedInspectorConditionIndex(ownerKey, #owner.conditions)
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    ui.Toolbar:AddChild(ui.AddConditionButton)

    ui.TypeGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionTypeGroup"):format(ownerKey), "Condition Type", 18)
    ui.TypeDropdown = createDropdown(ui.TypeGroup, ("RPEDataEditor%sInspectorConditionTypeDropdown"):format(ownerKey), self:GetInspectorConditionTypeItems(), ui.FieldWidth, function(value)
        if self._refreshingConditionInspector then
            return
        end

        local current, index = self:GetSelectedInspectorCondition(ownerKey)
        if not current or not index then
            return
        end

        local replacement = self:CreateAuthoringConditionDefaults(value) or { type = value }
        replacement.showOnTooltip = current.showOnTooltip == true
        replacement.tooltipTextOverride = ensureString(current.tooltipTextOverride)
        replacement.invert = current.invert == true
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index] = replacement
        end)
    end, false)

    ui.ShowOnTooltipCheckbox = createCheckbox(ui.EditorRoot:GetFrame(), ("RPEDataEditor%sInspectorConditionShowOnTooltipCheckbox"):format(ownerKey), "Show On Tooltip", false, function(checked)
        if self._refreshingConditionInspector then
            return
        end

        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end

        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].showOnTooltip = checked == true
        end)
    end, ui.FieldWidth)
    ui.EditorRoot:AddChild(ui.ShowOnTooltipCheckbox)

    ui.InvertCheckbox = createCheckbox(ui.EditorRoot:GetFrame(), ("RPEDataEditor%sInspectorConditionInvertCheckbox"):format(ownerKey), "Invert Requirement", false, function(checked)
        if self._refreshingConditionInspector then
            return
        end

        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end

        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].invert = checked == true
        end)
    end, ui.FieldWidth)
    ui.EditorRoot:AddChild(ui.InvertCheckbox)

    ui.TooltipOverrideGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionTooltipOverrideGroup"):format(ownerKey), "Tooltip Override", 18)
    ui.TooltipOverrideInput = createTextInput(ui.TooltipOverrideGroup, ("RPEDataEditor%sInspectorConditionTooltipOverrideInput"):format(ownerKey), "", ui.FieldWidth)
    bindTextInput(ui.TooltipOverrideInput, function()
        if self._refreshingConditionInspector then
            return
        end

        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end

        local text = ensureString(ui.TooltipOverrideInput:GetText())
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].tooltipTextOverride = text
        end)
    end)

    ui.MinimumGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionMinimumGroup"):format(ownerKey), "Minimum", 18)
    ui.MinimumInput = createTextInput(ui.MinimumGroup, ("RPEDataEditor%sInspectorConditionMinimumInput"):format(ownerKey), "", ui.FieldWidth)
    bindTextInput(ui.MinimumInput, function()
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        local text = ensureString(ui.MinimumInput:GetText())
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].minimumValue = text ~= "" and tonumber(text) or nil
        end)
    end)

    ui.MaximumGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionMaximumGroup"):format(ownerKey), "Maximum", 18)
    ui.MaximumInput = createTextInput(ui.MaximumGroup, ("RPEDataEditor%sInspectorConditionMaximumInput"):format(ownerKey), "", ui.FieldWidth)
    bindTextInput(ui.MaximumInput, function()
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        local text = ensureString(ui.MaximumInput:GetText())
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].maximumValue = text ~= "" and tonumber(text) or nil
        end)
    end)

    ui.ClassGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionClassGroup"):format(ownerKey), "Classes", 18)
    ui.ClassDropdown = createDropdown(ui.ClassGroup, ("RPEDataEditor%sInspectorConditionClassDropdown"):format(ownerKey), buildAcrossDatasets(self, "classes", false), ui.FieldWidth, function()
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].classRefs = ui.ClassDropdown:GetSelectedValues() or {}
        end)
    end, true)

    ui.RaceGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionRaceGroup"):format(ownerKey), "Races", 18)
    ui.RaceDropdown = createDropdown(ui.RaceGroup, ("RPEDataEditor%sInspectorConditionRaceDropdown"):format(ownerKey), buildAcrossDatasets(self, "races", false), ui.FieldWidth, function()
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].raceRefs = ui.RaceDropdown:GetSelectedValues() or {}
        end)
    end, true)

    ui.SlotGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionSlotGroup"):format(ownerKey), "Slot", 18)
    ui.SlotDropdown = createDropdown(ui.SlotGroup, ("RPEDataEditor%sInspectorConditionSlotDropdown"):format(ownerKey), self:BuildInspectorConditionSlotItems(), ui.FieldWidth, function(value)
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].slotKey = value or ""
        end)
    end, false)

    ui.WeaponTypeGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionWeaponTypeGroup"):format(ownerKey), "Weapon Types", 18)
    ui.WeaponTypeDropdown = createDropdown(ui.WeaponTypeGroup, ("RPEDataEditor%sInspectorConditionWeaponTypeDropdown"):format(ownerKey), buildAcrossDatasets(self, "weaponTypes", false), ui.FieldWidth, function()
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].weaponTypeRefs = ui.WeaponTypeDropdown:GetSelectedValues() or {}
        end)
    end, true)

    ui.ItemGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionItemGroup"):format(ownerKey), "Items", 18)
    ui.ItemDropdown = createDropdown(ui.ItemGroup, ("RPEDataEditor%sInspectorConditionItemDropdown"):format(ownerKey), buildAcrossDatasets(self, "weaponTypes", false), ui.FieldWidth, function()
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].weaponTypeRefs = ui.ItemDropdown:GetSelectedValues() or {}
        end)
    end, true)

    ui.RequiresShieldCheckbox = createCheckbox(ui.EditorRoot:GetFrame(), ("RPEDataEditor%sInspectorConditionRequiresShieldCheckbox"):format(ownerKey), "Require Shield (invert for no shield)", false, function(checked)
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].requiresShield = checked == true
        end)
    end, ui.FieldWidth)
    ui.EditorRoot:AddChild(ui.RequiresShieldCheckbox)

    ui.UnitGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionUnitGroup"):format(ownerKey), "Unit", 18)
    ui.UnitDropdown = createDropdown(ui.UnitGroup, ("RPEDataEditor%sInspectorConditionUnitDropdown"):format(ownerKey), UNIT_ITEMS, ui.FieldWidth, function(value)
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].unit = value or "caster"
        end)
    end, false)

    ui.AuraGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionAuraGroup"):format(ownerKey), "Aura", 18)
    ui.AuraDropdown = createDropdown(ui.AuraGroup, ("RPEDataEditor%sInspectorConditionAuraDropdown"):format(ownerKey), buildAcrossDatasets(self, "auras", true), ui.FieldWidth, function(value)
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].auraRef = value ~= "" and value or nil
        end)
    end, false)

    ui.TraitGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionTraitGroup"):format(ownerKey), "Trait", 18)
    ui.TraitDropdown = createDropdown(ui.TraitGroup, ("RPEDataEditor%sInspectorConditionTraitDropdown"):format(ownerKey), buildAcrossDatasets(self, "traits", true), ui.FieldWidth, function(value)
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].traitRef = value ~= "" and value or nil
        end)
    end, false)

    ui.SkillGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionSkillGroup"):format(ownerKey), "Skill", 18)
    ui.SkillDropdown = createDropdown(ui.SkillGroup, ("RPEDataEditor%sInspectorConditionSkillDropdown"):format(ownerKey), self:BuildSpellInspectorSkillsAcrossDatasets(), ui.FieldWidth, function(value)
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].skillRef = value ~= "" and value or nil
        end)
    end, false)

    ui.CreatureTypeGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionCreatureTypeGroup"):format(ownerKey), "Creature Types", 18)
    ui.CreatureTypeDropdown = createDropdown(ui.CreatureTypeGroup, ("RPEDataEditor%sInspectorConditionCreatureTypeDropdown"):format(ownerKey), CREATURE_TYPE_ITEMS, ui.FieldWidth, function()
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].creatureTypes = ui.CreatureTypeDropdown:GetSelectedValues() or {}
        end)
    end, true)

    ui.CreatureSizeGroup = createGroup(ui, ui.EditorRoot, ("RPEDataEditor%sInspectorConditionCreatureSizeGroup"):format(ownerKey), "Creature Sizes", 18)
    ui.CreatureSizeDropdown = createDropdown(ui.CreatureSizeGroup, ("RPEDataEditor%sInspectorConditionCreatureSizeDropdown"):format(ownerKey), CREATURE_SIZE_ITEMS, ui.FieldWidth, function()
        if self._refreshingConditionInspector then
            return
        end
        local _, index = self:GetSelectedInspectorCondition(ownerKey)
        if not index then
            return
        end
        self:CommitInspectorConditionOwner(ownerKey, function(owner)
            owner.conditions[index].creatureSizes = ui.CreatureSizeDropdown:GetSelectedValues() or {}
        end)
    end, true)

    return ui
end

function DataEditor:RefreshInspectorConditionsScrollBounds(ownerKey)
    local ui = getUi(self, ownerKey)
    if not ui or not ui.EditorScrollBar or not ui.EditorScrollFrame or not ui.EditorRoot then
        return
    end

    local viewportHeight = ui.EditorScrollFrame:GetHeight() or 0
    local contentHeight = ui.EditorRoot:GetFrame() and ui.EditorRoot:GetFrame():GetHeight() or 0
    local maxScroll = math.max(0, math.floor(contentHeight - viewportHeight + 0.5))

    ui.EditorScrollBar:SetMinMaxValues(0, maxScroll)
    if ui.EditorScrollBar.SetShown then
        ui.EditorScrollBar:SetShown(maxScroll > 0)
    elseif maxScroll > 0 and ui.EditorScrollBar.Show then
        ui.EditorScrollBar:Show()
    elseif ui.EditorScrollBar.Hide then
        ui.EditorScrollBar:Hide()
    end
    if (ui.EditorScrollBar:GetValue() or 0) > maxScroll then
        ui.EditorScrollBar:SetValue(maxScroll)
    end
end

function DataEditor:BuildInspectorConditionsPage(ownerKey, page)
    createEditorRoot(self, ownerKey, page)
end

function DataEditor:RefreshInspectorConditionsPage(ownerKey)
    local ui = getUi(self, ownerKey)
    local owner = self:GetInspectorConditionOwner(ownerKey)
    local hasOwner = owner ~= nil

    self._refreshingConditionInspector = true

    self:RefreshInspectorConditionsTable(ownerKey)

    local condition = self:GetSelectedInspectorCondition(ownerKey)
    local conditionType = condition and tostring(condition.type or "") or ""

    if ui.TypeDropdown then
        ui.TypeDropdown:SetItems(self:GetInspectorConditionTypeItems())
        ui.TypeDropdown:SetSelectedValue(conditionType ~= "" and conditionType or "level", true)
        setDropdownEnabled(ui.TypeDropdown, condition ~= nil)
    end
    if ui.ShowOnTooltipCheckbox then
        ui.ShowOnTooltipCheckbox:SetChecked(condition and condition.showOnTooltip == true or false, true)
        setCheckboxEnabled(ui.ShowOnTooltipCheckbox, condition ~= nil)
    end
    if ui.InvertCheckbox then
        ui.InvertCheckbox:SetChecked(condition and condition.invert == true or false, true)
        setCheckboxEnabled(ui.InvertCheckbox, condition ~= nil)
    end
    if ui.TooltipOverrideInput then
        ui.TooltipOverrideInput:SetText(condition and ensureString(condition.tooltipTextOverride) or "")
        setTextElementEnabled(ui.TooltipOverrideInput, condition ~= nil)
    end
    if ui.MinimumInput then
        ui.MinimumInput:SetText(condition and condition.minimumValue ~= nil and tostring(condition.minimumValue) or "")
        setTextElementEnabled(ui.MinimumInput, condition ~= nil)
    end
    if ui.MaximumInput then
        ui.MaximumInput:SetText(condition and condition.maximumValue ~= nil and tostring(condition.maximumValue) or "")
        setTextElementEnabled(ui.MaximumInput, condition ~= nil)
    end
    if ui.ClassDropdown then
        ui.ClassDropdown:SetItems(buildAcrossDatasets(self, "classes", false))
        ui.ClassDropdown:SetSelectedValues(condition and condition.classRefs or {}, true)
        setDropdownEnabled(ui.ClassDropdown, condition ~= nil)
    end
    if ui.RaceDropdown then
        ui.RaceDropdown:SetItems(buildAcrossDatasets(self, "races", false))
        ui.RaceDropdown:SetSelectedValues(condition and condition.raceRefs or {}, true)
        setDropdownEnabled(ui.RaceDropdown, condition ~= nil)
    end
    if ui.SlotDropdown then
        ui.SlotDropdown:SetItems(self:BuildInspectorConditionSlotItems())
        ui.SlotDropdown:SetSelectedValue(condition and ensureString(condition.slotKey) or "", true)
        setDropdownEnabled(ui.SlotDropdown, condition ~= nil)
    end
    if ui.WeaponTypeDropdown then
        ui.WeaponTypeDropdown:SetItems(buildAcrossDatasets(self, "weaponTypes", false))
        ui.WeaponTypeDropdown:SetSelectedValues(condition and condition.weaponTypeRefs or {}, true)
        setDropdownEnabled(ui.WeaponTypeDropdown, condition ~= nil)
    end
    if ui.ItemDropdown then
        ui.ItemDropdown:SetItems(buildAcrossDatasets(self, "weaponTypes", false))
        ui.ItemDropdown:SetSelectedValues(condition and condition.weaponTypeRefs or {}, true)
        setDropdownEnabled(ui.ItemDropdown, condition ~= nil)
    end
    if ui.RequiresShieldCheckbox then
        ui.RequiresShieldCheckbox:SetChecked(condition and condition.requiresShield == true or false, true)
        setCheckboxEnabled(ui.RequiresShieldCheckbox, condition ~= nil)
    end
    if ui.UnitDropdown then
        ui.UnitDropdown:SetSelectedValue(condition and ensureString(condition.unit) or "caster", true)
        setDropdownEnabled(ui.UnitDropdown, condition ~= nil)
    end
    if ui.AuraDropdown then
        ui.AuraDropdown:SetItems(buildAcrossDatasets(self, "auras", true))
        ui.AuraDropdown:SetSelectedValue(condition and ensureString(condition.auraRef) or "", true)
        setDropdownEnabled(ui.AuraDropdown, condition ~= nil)
    end
    if ui.TraitDropdown then
        ui.TraitDropdown:SetItems(buildAcrossDatasets(self, "traits", true))
        ui.TraitDropdown:SetSelectedValue(condition and ensureString(condition.traitRef) or "", true)
        setDropdownEnabled(ui.TraitDropdown, condition ~= nil)
    end
    if ui.SkillDropdown then
        ui.SkillDropdown:SetItems(self:BuildSpellInspectorSkillsAcrossDatasets())
        ui.SkillDropdown:SetSelectedValue(condition and ensureString(condition.skillRef) or "", true)
        setDropdownEnabled(ui.SkillDropdown, condition ~= nil)
    end
    if ui.CreatureTypeDropdown then
        ui.CreatureTypeDropdown:SetSelectedValues(condition and condition.creatureTypes or {}, true)
        setDropdownEnabled(ui.CreatureTypeDropdown, condition ~= nil)
    end
    if ui.CreatureSizeDropdown then
        ui.CreatureSizeDropdown:SetSelectedValues(condition and condition.creatureSizes or {}, true)
        setDropdownEnabled(ui.CreatureSizeDropdown, condition ~= nil)
    end
    if ui.AddConditionButton then
        ui.AddConditionButton:SetEnabled(hasOwner)
    end

    self._refreshingConditionInspector = false

    setGroupVisible(ui.TypeGroup, condition ~= nil)
    setGroupVisible(ui.TooltipOverrideGroup, condition ~= nil)
    setGroupVisible(ui.MinimumGroup, conditionType == "level" or conditionType == "caster_health_percent" or conditionType == "target_health_percent" or conditionType == "skill_requirement")
    setGroupVisible(ui.MaximumGroup, conditionType == "level" or conditionType == "caster_health_percent" or conditionType == "target_health_percent" or conditionType == "skill_requirement")
    setGroupVisible(ui.ClassGroup, conditionType == "class")
    setGroupVisible(ui.RaceGroup, conditionType == "race")
    setGroupVisible(ui.SlotGroup, conditionType == "weapon_type" or conditionType == "item_equipped")
    setGroupVisible(ui.WeaponTypeGroup, conditionType == "weapon_type")
    setGroupVisible(ui.ItemGroup, conditionType == "item_equipped")
    if ui.RequiresShieldCheckbox and ui.RequiresShieldCheckbox.GetFrame then
        local frame = ui.RequiresShieldCheckbox:GetFrame()
        if frame then
            if conditionType == "item_equipped" then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end
    setGroupVisible(ui.UnitGroup, conditionType == "aura_requirement" or conditionType == "trait_requirement" or conditionType == "mounted")
    setGroupVisible(ui.AuraGroup, conditionType == "aura_requirement")
    setGroupVisible(ui.TraitGroup, conditionType == "trait_requirement")
    setGroupVisible(ui.SkillGroup, conditionType == "skill_requirement")
    setGroupVisible(ui.CreatureTypeGroup, conditionType == "target_creature_type")
    setGroupVisible(ui.CreatureSizeGroup, conditionType == "target_creature_size")

    if ui.EditorRoot and ui.EditorRoot.RefreshLayout then
        ui.EditorRoot:RefreshLayout()
    end
    if self.RefreshInspectorConditionsScrollBounds then
        self:RefreshInspectorConditionsScrollBounds(ownerKey)
    end
end

function DataEditor:BuildSpellInspectorConditionsPage(page)
    self:BuildInspectorConditionsPage("spell", page)
end

function DataEditor:BuildItemInspectorConditionsPage(page)
    self:BuildInspectorConditionsPage("item", page)
end

function DataEditor:BuildTraitInspectorConditionsPage(page)
    self:BuildInspectorConditionsPage("trait", page)
end

function DataEditor:RefreshSpellInspectorConditionsPage()
    self:RefreshInspectorConditionsPage("spell")
end

function DataEditor:RefreshItemInspectorConditionsPage()
    self:RefreshInspectorConditionsPage("item")
end

function DataEditor:RefreshTraitInspectorConditionsPage()
    self:RefreshInspectorConditionsPage("trait")
end
