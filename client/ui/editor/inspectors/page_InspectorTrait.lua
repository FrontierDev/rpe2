local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local TraitClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Trait or nil

local SIDE_PADDING = 8
local FIELD_WIDTH = 236
local CONTROL_HEIGHT = 20

local AUTO_AURA_TARGET_ITEMS = {
    { label = "Self", value = "self" },
    { label = "All Allies", value = "all_allies" },
    { label = "All Enemies", value = "all_enemies" },
}

local TRAIT_EVENT_EFFECT_TYPE_ITEMS = {
    { label = "Damage", value = "damage" },
    { label = "Heal", value = "heal" },
    { label = "Apply Aura", value = "apply_aura" },
    { label = "Remove Aura", value = "remove_aura" },
    { label = "Resource", value = "resource" },
}

local STAT_BONUS_OPERATION_ITEMS = {
    { label = "Flat", value = "flat" },
    { label = "Percent", value = "percent" },
}

local AMOUNT_MODE_ITEMS = {
    { label = "Flat", value = "flat" },
    { label = "% Base", value = "base_percent" },
    { label = "% Max", value = "max_percent" },
}

local TRAIT_INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "bonuses", label = "Bonuses & Auras" },
    { key = "conditions", label = "Conditions" },
    { key = "events", label = "Events" },
}

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

local function resolveItemLabel(items, value, fallback)
    local resolvedValue = ensureString(value)
    for index = 1, #(items or {}) do
        local item = items[index]
        if ensureString(item and item.value) == resolvedValue then
            return ensureString(item and item.label)
        end
    end

    return fallback or resolvedValue
end

local function normalizeTraitEvents(values)
    return TraitClass and TraitClass.NormalizeEvents and TraitClass.NormalizeEvents(values) or (values or {})
end

local function normalizeTraitStatBonuses(values)
    return TraitClass and TraitClass.NormalizeStatBonuses and TraitClass.NormalizeStatBonuses(values) or (values or {})
end

local function normalizeTraitSkillBonuses(values)
    return TraitClass and TraitClass.NormalizeSkillBonuses and TraitClass.NormalizeSkillBonuses(values) or (values or {})
end

local function normalizeAutomaticAuras(values)
    return TraitClass and TraitClass.NormalizeAutomaticAuras and TraitClass.NormalizeAutomaticAuras(values) or (values or {})
end

local function normalizeTraitInspectorEventEffect(effect)
    if type(effect) ~= "table" then
        return
    end

    local effectType = tostring(effect.type or "damage")
    if effectType == "heal" then
        effect.type = "heal"
        effect.baseHealing = tonumber(effect.baseHealing) or tonumber(effect.baseAmount) or 0
        effect.statScaling = effect.statScaling or {}
        effect.damageSchoolRefs = nil
        effect.auraRef = nil
        effect.stacks = nil
        effect.duration = nil
        effect.basePower = nil
        effect.resourceRef = nil
        effect.amount = nil
        return
    end

    if effectType == "apply_aura" then
        effect.type = "apply_aura"
        effect.auraRef = ensureString(effect.auraRef) ~= "" and ensureString(effect.auraRef) or nil
        effect.stacks = math.max(1, math.floor(tonumber(effect.stacks) or tonumber(effect.auraStacks) or 1))
        effect.duration = math.max(1, math.floor(tonumber(effect.duration) or tonumber(effect.turns) or 12))
        effect.basePower = tonumber(effect.basePower) or tonumber(effect.powerLevel) or 0
        effect.baseDamage = nil
        effect.baseHealing = nil
        effect.statScaling = nil
        effect.damageSchoolRefs = nil
        effect.resourceRef = nil
        effect.amount = nil
        return
    end

    if effectType == "remove_aura" then
        effect.type = "remove_aura"
        effect.auraRef = ensureString(effect.auraRef) ~= "" and ensureString(effect.auraRef) or nil
        effect.stacks = math.max(1, math.floor(tonumber(effect.stacks) or tonumber(effect.auraStacks) or 1))
        effect.baseDamage = nil
        effect.baseHealing = nil
        effect.statScaling = nil
        effect.damageSchoolRefs = nil
        effect.duration = nil
        effect.basePower = nil
        effect.resourceRef = nil
        effect.amount = nil
        return
    end

    if effectType == "resource" then
        effect.type = "resource"
        effect.resourceRef = ensureString(effect.resourceRef) ~= "" and ensureString(effect.resourceRef) or nil
        effect.amount = tonumber(effect.amount) or tonumber(effect.baseAmount) or 0
        effect.baseDamage = nil
        effect.baseHealing = nil
        effect.statScaling = nil
        effect.damageSchoolRefs = nil
        effect.auraRef = nil
        effect.stacks = nil
        effect.duration = nil
        effect.basePower = nil
        return
    end

    effect.type = "damage"
    effect.baseDamage = tonumber(effect.baseDamage) or tonumber(effect.baseAmount) or 0
    effect.statScaling = effect.statScaling or {}
    effect.damageSchoolRefs = effect.damageSchoolRefs or {}
    effect.baseHealing = nil
    effect.auraRef = nil
    effect.stacks = nil
    effect.duration = nil
    effect.basePower = nil
    effect.resourceRef = nil
    effect.amount = nil
end

function DataEditor:GetTraitInspectorPageDefinitions()
    return TRAIT_INSPECTOR_PAGE_DEFINITIONS
end

function DataEditor:GetTraitInspectorPageIndexByKey(key)
    local pages = self:GetTraitInspectorPageDefinitions()
    for index = 1, #pages do
        if pages[index].key == key then
            return index
        end
    end

    return 1
end

function DataEditor:BuildTraitInspectorPageSelectorItems()
    local items = {}
    local pages = self:GetTraitInspectorPageDefinitions()

    for index = 1, #pages do
        items[#items + 1] = {
            label = pages[index].label,
            value = pages[index].key,
        }
    end

    return items
end

function DataEditor:RefreshTraitInspectorPageSelector()
    local pages = self:GetTraitInspectorPageDefinitions()
    local pageCount = #pages
    local activeIndex = math.max(1, math.min(self.ActiveTraitInspectorPageIndex or 1, pageCount))
    self.ActiveTraitInspectorPageIndex = activeIndex
    self.ActiveTraitInspectorTabKey = pages[activeIndex] and pages[activeIndex].key or "general"

    local activeDefinition = pages[activeIndex]
    if self.TraitInspectorPageDropdown and activeDefinition then
        self._refreshingTraitInspectorPageSelector = true
        self.TraitInspectorPageDropdown:SetSelectedValue(activeDefinition.key, true)
        self._refreshingTraitInspectorPageSelector = false
    end

    if self.TraitInspectorPreviousButton and self.TraitInspectorPreviousButton.SetEnabled then
        self.TraitInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end

    if self.TraitInspectorNextButton and self.TraitInspectorNextButton.SetEnabled then
        self.TraitInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetTraitInspectorTab(tabKey)
    local definitions = self:GetTraitInspectorPageDefinitions()
    self.ActiveTraitInspectorPageIndex = self:GetTraitInspectorPageIndexByKey(tabKey or "general")
    self.ActiveTraitInspectorTabKey = definitions[self.ActiveTraitInspectorPageIndex] and definitions[self.ActiveTraitInspectorPageIndex].key or "general"

    local pages = {
        general = self.TraitInspectorGeneralPage,
        bonuses = self.TraitInspectorBonusesPage,
        conditions = self.TraitInspectorConditionsPage,
        events = self.TraitInspectorEventsPage,
    }

    for key, page in pairs(pages) do
        if page then
            if key == self.ActiveTraitInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    self:RefreshTraitInspectorPageSelector()
end

function DataEditor:GetSelectedTraitAndDataset()
    return self:GetSelectedDataset(), self:GetSelectedTrait()
end

function DataEditor:NormalizeTraitDefinition(trait)
    if TraitClass and TraitClass.New and TraitClass.ToTable then
        return TraitClass.ToTable(TraitClass:New(trait))
    end

    return trait or {}
end

function DataEditor:CommitSelectedTrait(mutate)
    local dataset, trait = self:GetSelectedTraitAndDataset()
    if not dataset or not trait or type(mutate) ~= "function" then
        return
    end

    local before = self:DeepCopyValue(trait)
    mutate(trait, dataset)
    local normalized = self:NormalizeTraitDefinition(trait)
    for key in pairs(trait) do
        if normalized[key] == nil then
            trait[key] = nil
        end
    end
    for key, value in pairs(normalized) do
        trait[key] = value
    end

    if self:DeepEqualValues(before, trait) then
        return
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "traits")
end

function DataEditor:BuildTraitInspectorDatasetItems()
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

function DataEditor:BuildTraitInspectorCollectionItems(collectionKey, datasetId)
    local items = {
        { label = "None", value = "" },
    }

    if not datasetId or datasetId == "" or not self.Database or not self.Database.GetDatasetByID then
        return items
    end

    local dataset = self.Database.GetDatasetByID(datasetId)
    local collection = dataset and dataset[collectionKey] or {}
    for index = 1, #collection do
        local entry = collection[index]
        if entry and entry.id then
            items[#items + 1] = {
                label = self:GetEntryDisplayName(collectionKey, entry),
                value = ("%s:%s"):format(dataset.id, entry.id),
            }
        end
    end

    return items
end

function DataEditor:BuildTraitInspectorStatRows(trait)
    local rows = {}
    for index = 1, #(trait and trait.statBonuses or {}) do
        local entry = trait.statBonuses[index]
        local statRef = ensureString(entry and entry.statRef)
        local datasetId, statId = parseDatasetQualifiedRef(statRef)
        local dataset = datasetId and self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
        local statName = statId
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
            datasetName = dataset and self:GetDatasetDisplayName(dataset) or (datasetId ~= nil and datasetId or "-"),
            statName = statName ~= nil and statName or "-",
            valueText = tostring(entry and entry.value or 0) .. (tostring(entry and entry.operation or "flat") == "percent" and "%" or ""),
        }
    end

    return rows
end

function DataEditor:BuildTraitInspectorSkillRows(trait)
    local rows = {}
    for index = 1, #(trait and trait.skillBonuses or {}) do
        local entry = trait.skillBonuses[index]
        local skillRef = ensureString(entry and entry.skillRef)
        local datasetId, skillId = parseDatasetQualifiedRef(skillRef)
        local dataset = datasetId and self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
        local skillName = skillId
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
            datasetName = dataset and self:GetDatasetDisplayName(dataset) or (datasetId ~= nil and datasetId or "-"),
            skillName = skillName ~= nil and skillName or "-",
            valueText = tostring(entry and entry.value or 0),
        }
    end

    return rows
end

function DataEditor:BuildTraitInspectorEventRows(trait)
    local rows = {}
    for index = 1, #(trait and trait.events or {}) do
        local entry = trait.events[index]
        local eventLabel = resolveItemLabel(self:GetAuraInspectorCombatEventItems(), entry and entry.combatEventId or "", "None")
        local triggerLabel = entry and entry.combatEventId and resolveItemLabel(
            self:GetAuraInspectorTriggerTargetItems(),
            entry.triggerTarget,
            "Event Other"
        ) or ""
        rows[#rows + 1] = {
            rowIndex = index,
            title = eventLabel,
            detail = triggerLabel,
            statusText = tostring(#(entry and entry.effects or {})),
        }
    end

    return rows
end

function DataEditor:RefreshTraitInspectorPendingStatDropdown()
    local selectedDatasetId = self.TraitInspectorPendingStatDatasetDropdown and self.TraitInspectorPendingStatDatasetDropdown.GetSelectedValue and self.TraitInspectorPendingStatDatasetDropdown:GetSelectedValue() or ""
    if self.TraitInspectorPendingStatDropdown and self.TraitInspectorPendingStatDropdown.SetItems then
        self.TraitInspectorPendingStatDropdown:SetItems(self:BuildTraitInspectorCollectionItems("stats", selectedDatasetId))
    end
end

function DataEditor:RefreshTraitInspectorPendingSkillDropdown()
    local selectedDatasetId = self.TraitInspectorPendingSkillDatasetDropdown and self.TraitInspectorPendingSkillDatasetDropdown.GetSelectedValue and self.TraitInspectorPendingSkillDatasetDropdown:GetSelectedValue() or ""
    if self.TraitInspectorPendingSkillDropdown and self.TraitInspectorPendingSkillDropdown.SetItems then
        self.TraitInspectorPendingSkillDropdown:SetItems(self:BuildTraitInspectorCollectionItems("skills", selectedDatasetId))
    end
end

function DataEditor:RefreshTraitInspectorPendingAuraDropdown()
    if self.TraitInspectorAutoAuraDropdown and self.TraitInspectorAutoAuraDropdown.SetItems then
        self.TraitInspectorAutoAuraDropdown:SetItems(self:BuildSpellInspectorAurasAcrossDatasets())
    end
end

function DataEditor:RefreshTraitInspectorStatTable()
    local _, trait = self:GetSelectedTraitAndDataset()
    local rows = self:BuildTraitInspectorStatRows(trait)
    if self.TraitInspectorStatsScroll and self.TraitInspectorStatsScroll.SetItems then
        self.TraitInspectorStatsScroll:SetItems(rows)
    end
end

function DataEditor:RefreshTraitInspectorSkillTable()
    local _, trait = self:GetSelectedTraitAndDataset()
    local rows = self:BuildTraitInspectorSkillRows(trait)
    if self.TraitInspectorSkillsScroll and self.TraitInspectorSkillsScroll.SetItems then
        self.TraitInspectorSkillsScroll:SetItems(rows)
    end
end

function DataEditor:RefreshTraitInspectorEventTable()
    local _, trait = self:GetSelectedTraitAndDataset()
    local rows = self:BuildTraitInspectorEventRows(trait)
    if self.TraitInspectorEventsScroll and self.TraitInspectorEventsScroll.SetItems then
        self.TraitInspectorEventsScroll:SetItems(rows)
    end

    local selectedIndex = tonumber(self.SelectedTraitEventIndex)
    if not selectedIndex or not rows[selectedIndex] then
        self.SelectedTraitEventIndex = rows[1] and 1 or nil
    end
end

function DataEditor:EnsureTraitInspectorStatContextMenu()
    if self.TraitInspectorStatContextMenu then
        return self.TraitInspectorStatContextMenu
    end

    self.TraitInspectorStatContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorTraitInspectorStatContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-stat" or not self.ContextMenuTraitStatRowIndex then
                return
            end

            local removeIndex = self.ContextMenuTraitStatRowIndex
            self:CommitSelectedTrait(function(trait)
                local bonuses = normalizeTraitStatBonuses(trait.statBonuses)
                table.remove(bonuses, removeIndex)
                trait.statBonuses = bonuses
            end)

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.TraitInspectorStatContextMenu:SetParent(self.TraitInspectorPage or UIParent)
    self.TraitInspectorStatContextMenu:Create()
    return self.TraitInspectorStatContextMenu
end

function DataEditor:ShowTraitInspectorStatContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureTraitInspectorStatContextMenu()
    self.ContextMenuTraitStatRowIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-stat" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:EnsureTraitInspectorSkillContextMenu()
    if self.TraitInspectorSkillContextMenu then
        return self.TraitInspectorSkillContextMenu
    end

    self.TraitInspectorSkillContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorTraitInspectorSkillContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-skill" or not self.ContextMenuTraitSkillRowIndex then
                return
            end

            local removeIndex = self.ContextMenuTraitSkillRowIndex
            self:CommitSelectedTrait(function(trait)
                local bonuses = normalizeTraitSkillBonuses(trait.skillBonuses)
                table.remove(bonuses, removeIndex)
                trait.skillBonuses = bonuses
            end)

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.TraitInspectorSkillContextMenu:SetParent(self.TraitInspectorPage or UIParent)
    self.TraitInspectorSkillContextMenu:Create()
    return self.TraitInspectorSkillContextMenu
end

function DataEditor:ShowTraitInspectorSkillContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureTraitInspectorSkillContextMenu()
    self.ContextMenuTraitSkillRowIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-skill" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:GetDefaultTraitInspectorCombatEventId()
    local items = self:GetAuraInspectorCombatEventItems()
    for index = 1, #items do
        local value = tostring(items[index].value or "")
        if value ~= "" then
            return value
        end
    end

    return nil
end

function DataEditor:SetSelectedTraitInspectorEventIndex(index)
    local _, trait = self:GetSelectedTraitAndDataset()
    local events = trait and trait.events or {}
    index = tonumber(index)

    if not index or not events[index] then
        self.SelectedTraitEventIndex = nil
    else
        self.SelectedTraitEventIndex = index
    end
end

function DataEditor:GetSelectedTraitInspectorEvent()
    local _, trait = self:GetSelectedTraitAndDataset()
    local events = trait and trait.events or {}
    local index = tonumber(self.SelectedTraitEventIndex)
    if not index or not events[index] then
        return nil, nil
    end

    return events[index], index
end

function DataEditor:CommitSelectedTraitInspectorEvent(mutate)
    local traitEvent = self:GetSelectedTraitInspectorEvent()
    if type(traitEvent) ~= "table" or type(mutate) ~= "function" then
        return
    end

    self:CommitSelectedTrait(function(trait)
        mutate(traitEvent, trait)
    end)
end

function DataEditor:AddTraitInspectorEvent()
    self:CommitSelectedTrait(function(trait)
        trait.events = normalizeTraitEvents(trait.events)
        trait.events[#trait.events + 1] = {
            combatEventId = self:GetDefaultTraitInspectorCombatEventId(),
            triggerTarget = "event_other",
            chance = 100,
            effects = {
                {
                    type = "damage",
                    baseDamage = 0,
                    damageSchoolRefs = {},
                    statScaling = {},
                },
            },
        }
        self.SelectedTraitEventIndex = #trait.events
        self.SelectedTraitEventEffectIndex = 1
        self.SelectedTraitEventScalingIndex = nil
    end)
end

function DataEditor:RemoveSelectedTraitInspectorEvent()
    local _, eventIndex = self:GetSelectedTraitInspectorEvent()
    if not eventIndex then
        return
    end

    self:CommitSelectedTrait(function(trait)
        local events = normalizeTraitEvents(trait.events)
        table.remove(events, eventIndex)
        trait.events = events
        if #events > 0 then
            self.SelectedTraitEventIndex = math.min(eventIndex, #events)
        else
            self.SelectedTraitEventIndex = nil
        end
        self.SelectedTraitEventEffectIndex = nil
        self.SelectedTraitEventScalingIndex = nil
    end)
end

function DataEditor:SetSelectedTraitInspectorEventEffectIndex(index)
    local traitEvent = self:GetSelectedTraitInspectorEvent()
    local effects = traitEvent and traitEvent.effects or {}
    index = tonumber(index)

    if not index or not effects[index] then
        self.SelectedTraitEventEffectIndex = nil
    else
        self.SelectedTraitEventEffectIndex = index
    end
end

function DataEditor:GetSelectedTraitInspectorEventEffect()
    local traitEvent = self:GetSelectedTraitInspectorEvent()
    local effects = traitEvent and traitEvent.effects or {}
    local index = tonumber(self.SelectedTraitEventEffectIndex)
    if not index or not effects[index] then
        return nil, nil
    end

    return effects[index], index
end

function DataEditor:CommitSelectedTraitInspectorEventEffect(mutate)
    local effect = self:GetSelectedTraitInspectorEventEffect()
    if type(effect) ~= "table" or type(mutate) ~= "function" then
        return
    end

    self:CommitSelectedTrait(function(trait)
        mutate(effect, trait)
    end)
end

function DataEditor:AddTraitInspectorEventEffect()
    local traitEvent = self:GetSelectedTraitInspectorEvent()
    if not traitEvent then
        return
    end

    self:CommitSelectedTrait(function()
        traitEvent.effects = traitEvent.effects or {}
        traitEvent.effects[#traitEvent.effects + 1] = {
            type = "damage",
            baseDamage = 0,
            damageSchoolRefs = {},
            statScaling = {},
        }
        self.SelectedTraitEventEffectIndex = #traitEvent.effects
        self.SelectedTraitEventScalingIndex = nil
    end)
end

function DataEditor:RemoveSelectedTraitInspectorEventEffect()
    local traitEvent = self:GetSelectedTraitInspectorEvent()
    local _, effectIndex = self:GetSelectedTraitInspectorEventEffect()
    if not traitEvent or not effectIndex then
        return
    end

    self:CommitSelectedTrait(function()
        table.remove(traitEvent.effects or {}, effectIndex)
        if #(traitEvent.effects or {}) > 0 then
            self.SelectedTraitEventEffectIndex = math.min(effectIndex, #traitEvent.effects)
        else
            self.SelectedTraitEventEffectIndex = nil
        end
        self.SelectedTraitEventScalingIndex = nil
    end)
end

function DataEditor:BuildTraitInspectorEventEffectRows(traitEvent)
    local rows = {}

    for index = 1, #(traitEvent and traitEvent.effects or {}) do
        local effect = traitEvent.effects[index]
        local effectType = tostring(effect and effect.type or "damage")
        local statusText = tostring(tonumber(effect and effect.baseDamage) or 0)
        local detailText = ""
        if effectType == "heal" then
            statusText = tostring(tonumber(effect and effect.baseHealing) or 0)
        elseif effectType == "apply_aura" then
            statusText = tostring(tonumber(effect and effect.stacks) or 1)
            detailText = self:ResolveSpellInspectorReferenceLabel("auras", effect and effect.auraRef or "")
        elseif effectType == "remove_aura" then
            statusText = tostring(tonumber(effect and effect.stacks) or 1)
            detailText = self:ResolveSpellInspectorReferenceLabel("auras", effect and effect.auraRef or "")
        elseif effectType == "resource" then
            statusText = tostring(tonumber(effect and effect.amount) or 0)
            detailText = self:ResolveSpellInspectorReferenceLabel("resources", effect and effect.resourceRef or "")
        else
            detailText = UI.Utils.JoinCommaSeparatedList(effect and effect.damageSchoolRefs or nil)
        end

        rows[#rows + 1] = {
            rowIndex = index,
            title = effectType,
            detail = detailText,
            statusText = statusText,
        }
    end

    return rows
end

function DataEditor:RefreshTraitInspectorEventEffectsTable()
    local traitEvent = self:GetSelectedTraitInspectorEvent()
    local rows = self:BuildTraitInspectorEventEffectRows(traitEvent)

    if self.TraitInspectorEventEffectsScroll and self.TraitInspectorEventEffectsScroll.SetItems then
        self.TraitInspectorEventEffectsScroll:SetItems(rows)
    end

    local selectedIndex = tonumber(self.SelectedTraitEventEffectIndex)
    if not selectedIndex or not rows[selectedIndex] then
        self.SelectedTraitEventEffectIndex = rows[1] and 1 or nil
    end
end

function DataEditor:BuildTraitInspectorEventScalingRows(effect)
    local rows = {}
    local scaling = effect and effect.statScaling or {}

    for index = 1, #scaling do
        local entry = scaling[index]
        rows[#rows + 1] = {
            rowIndex = index,
            title = self:ResolveSpellInspectorReferenceLabel("stats", entry and entry.statRef or ""),
            detail = "",
            statusText = tostring(entry and entry.coefficient or 0),
        }
    end

    return rows
end

function DataEditor:RefreshTraitInspectorEventScalingTable()
    local effect = self:GetSelectedTraitInspectorEventEffect()
    local rows = self:BuildTraitInspectorEventScalingRows(effect)

    if self.TraitInspectorEventScalingScroll and self.TraitInspectorEventScalingScroll.SetItems then
        self.TraitInspectorEventScalingScroll:SetItems(rows)
    end

    local selectedIndex = tonumber(self.SelectedTraitEventScalingIndex)
    if not selectedIndex or not rows[selectedIndex] then
        self.SelectedTraitEventScalingIndex = rows[1] and 1 or nil
    end
end

local function createTraitInspectorPageFrame(self, name)
    local page = CreateFrame("Frame", name, self.TraitInspectorPage)
    page:SetPoint("TOPLEFT", self.TraitInspectorPage, "TOPLEFT", SIDE_PADDING, -24)
    page:SetPoint("TOPRIGHT", self.TraitInspectorPage, "TOPRIGHT", -SIDE_PADDING, -24)
    page:SetPoint("BOTTOMLEFT", self.TraitInspectorPage, "BOTTOMLEFT", SIDE_PADDING, 24)
    page:SetPoint("BOTTOMRIGHT", self.TraitInspectorPage, "BOTTOMRIGHT", -SIDE_PADDING, 24)
    return page
end

local function buildTraitInspectorGeneralPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorTraitInspectorGeneralRoot", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)
    self.TraitInspectorGeneralRoot = root

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorTraitInspectorNameLabel", "Name"))
    self.TraitInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorTraitInspectorNameInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.TraitInspectorNameInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedTrait(function(trait)
            trait.name = self.TraitInspectorNameInput:GetText()
        end)
    end)
    self.TraitInspectorNameInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedTrait(function(trait)
            trait.name = self.TraitInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.TraitInspectorNameInput)

    self.TraitInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorTraitInspectorIdText", "ID: -", {
        width = FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.TraitInspectorIdText)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorTraitInspectorIconLabel", "Icon"))
    self.TraitInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorTraitInspectorIconField",
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.TraitInspectorIconField:SetParent(root:GetFrame())
    self.TraitInspectorIconField:Create()
    local iconButton = self.TraitInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local _, trait = self:GetSelectedTraitAndDataset()
            local client = Addon.Client or {}
            if not trait or not client.OpenIconFinder then
                return
            end

            client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedTrait(function(selectedTrait)
                    selectedTrait.icon = filePath or ""
                end)
            end, {
                filter = trait.icon or "",
            })
        end)
    end
    root:AddChild(self.TraitInspectorIconField)

    self.TraitInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = ensureString(value)
            self.TraitInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.TraitInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.TraitInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.TraitInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorTraitInspectorDescriptionLabel", "Description"))
    self.TraitInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorTraitInspectorDescriptionInput", {
        width = FIELD_WIDTH,
        height = 48,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.TraitInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedTrait(function(trait)
            trait.description = self.TraitInspectorDescriptionInput:GetText()
        end)
    end)
    root:AddChild(self.TraitInspectorDescriptionInput)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorTraitInspectorCategoryLabel", "Ownership is assigned by Race/Class definitions."))

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorTraitInspectorDisplayCategoryLabel", "Category"))
    self.TraitInspectorDisplayCategoryInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorTraitInspectorDisplayCategoryInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.TraitInspectorDisplayCategoryInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedTrait(function(trait)
            trait.category = self.TraitInspectorDisplayCategoryInput:GetText()
        end)
    end)
    self.TraitInspectorDisplayCategoryInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedTrait(function(trait)
            trait.category = self.TraitInspectorDisplayCategoryInput:GetText()
        end)
    end)
    root:AddChild(self.TraitInspectorDisplayCategoryInput)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorTraitInspectorUnlockLevelLabel", "Unlock Level"))
    self.TraitInspectorUnlockLevelInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorTraitInspectorUnlockLevelInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.TraitInspectorUnlockLevelInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedTrait(function(trait)
            trait.unlockLevel = self.TraitInspectorUnlockLevelInput:GetText()
        end)
    end)
    self.TraitInspectorUnlockLevelInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedTrait(function(trait)
            trait.unlockLevel = self.TraitInspectorUnlockLevelInput:GetText()
        end)
    end)
    root:AddChild(self.TraitInspectorUnlockLevelInput)

    self.TraitInspectorEnvironmentalCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorTraitInspectorEnvironmentalCheckbox", "Environmental Trait", false, function(checked)
        if self._refreshingTraitInspector then
            return
        end

        self:CommitSelectedTrait(function(trait)
            trait.isEnvironmental = checked == true
        end)
    end)
    root:AddChild(self.TraitInspectorEnvironmentalCheckbox)
end

local function buildTraitInspectorBonusesPage(self, page)
    local function handleMouseWheel(_, delta)
        local _, maxValue = self.TraitInspectorBonusesScrollBar:GetMinMaxValues()
        local current = self.TraitInspectorBonusesScrollBar:GetValue() or 0
        local nextValue = math.max(0, math.min(maxValue or 0, current - ((delta or 0) * 24)))
        self.TraitInspectorBonusesScrollBar:SetValue(nextValue)
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

    local function attachMouseWheelRecursive(frame, visited)
        frame = frame and (frame.GetFrame and frame:GetFrame() or frame) or nil
        if not frame then
            return
        end

        visited = visited or {}
        if visited[frame] then
            return
        end
        visited[frame] = true

        attachMouseWheel(frame)
        local children = { frame:GetChildren() }
        for index = 1, #children do
            attachMouseWheelRecursive(children[index], visited)
        end
    end

    self.TraitInspectorBonusesScrollFrame = CreateFrame("ScrollFrame", "RPEDataEditorTraitInspectorBonusesScrollFrame", page)
    self.TraitInspectorBonusesScrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.TraitInspectorBonusesScrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -20, 0)
    self.TraitInspectorBonusesScrollFrame:EnableMouseWheel(true)
    self.TraitInspectorBonusesScrollFrame:SetClipsChildren(true)
    attachMouseWheel(page)
    attachMouseWheel(self.TraitInspectorBonusesScrollFrame)

    self.TraitInspectorBonusesScrollBar = CreateFrame("Slider", "RPEDataEditorTraitInspectorBonusesScrollBar", page)
    self.TraitInspectorBonusesScrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -2)
    self.TraitInspectorBonusesScrollBar:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 2)
    self.TraitInspectorBonusesScrollBar:SetOrientation("VERTICAL")
    self.TraitInspectorBonusesScrollBar:SetMinMaxValues(0, 0)
    self.TraitInspectorBonusesScrollBar:SetValueStep(12)
    if self.TraitInspectorBonusesScrollBar.SetObeyStepOnDrag then
        self.TraitInspectorBonusesScrollBar:SetObeyStepOnDrag(true)
    end
    self.TraitInspectorBonusesScrollBar:SetWidth(12)

    self.TraitInspectorBonusesScrollBarTrack = self.TraitInspectorBonusesScrollBarTrack or self.TraitInspectorBonusesScrollBar:CreateTexture(nil, "BACKGROUND")
    self.TraitInspectorBonusesScrollBarTrack:SetAllPoints(self.TraitInspectorBonusesScrollBar)
    do
        local trackColor = UI.ResolveColor(nil, "scrollbar.track")
        self.TraitInspectorBonusesScrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)
    end

    self.TraitInspectorBonusesScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    do
        local thumb = self.TraitInspectorBonusesScrollBar.GetThumbTexture and self.TraitInspectorBonusesScrollBar:GetThumbTexture() or nil
        if thumb and thumb.SetVertexColor then
            local thumbColor = UI.ResolveColor(nil, "scrollbar.thumb")
            thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
        end
    end
    self.TraitInspectorBonusesScrollBar:SetValue(0)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.TraitInspectorBonusesScrollFrame, "RPEDataEditorTraitInspectorBonusesRoot", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = true,
    })
    root:GetFrame():SetPoint("TOPLEFT", self.TraitInspectorBonusesScrollFrame, "TOPLEFT", 0, 0)
    root:GetFrame():SetPoint("TOPRIGHT", self.TraitInspectorBonusesScrollFrame, "TOPRIGHT", 0, 0)
    self.TraitInspectorBonusesScrollFrame:SetScrollChild(root:GetFrame())
    self.TraitInspectorBonusesScrollBar:SetScript("OnValueChanged", function(_, value)
        self.TraitInspectorBonusesScrollFrame:SetVerticalScroll(value or 0)
    end)
    self.TraitInspectorBonusesScrollFrame:SetScript("OnMouseWheel", handleMouseWheel)
    self.TraitInspectorBonusesScrollFrame:SetScript("OnSizeChanged", function(scrollFrame)
        local width = math.max(1, (scrollFrame:GetWidth() or FIELD_WIDTH) - 4)
        root:GetFrame():SetWidth(width)
        if root.RefreshLayout then
            root:RefreshLayout()
        end
    end)
    self.TraitInspectorBonusesRoot = root

    local function createGroup(name, labelText, height)
        local groupHeight = 12 + 2 + (height or CONTROL_HEIGHT)
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

    local function createEffectTextGroup(groupName, labelText, fieldName)
        local group = createGroup(groupName, labelText)
        self[fieldName] = UI.CreateTextInput(group:GetFrame(), fieldName, {
            width = FIELD_WIDTH,
            height = CONTROL_HEIGHT,
            text = "",
            borderColor = UI.ResolveColor(nil, "panel.border"),
        })
        group:AddChild(self[fieldName])
        return group
    end

    local function bindInput(fieldName, callback)
        self[fieldName]:SetScript("OnEnterPressed", callback)
        self[fieldName]:SetScript("OnEditFocusLost", callback)
    end

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorTraitInspectorStatsLabel", "Stat Bonuses"))
    self.TraitInspectorStatsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorTraitInspectorStatsPanel", {
        width = FIELD_WIDTH,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.TraitInspectorStatsPanel)

    self.TraitInspectorStatsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorTraitInspectorStatsScroll",
        width = FIELD_WIDTH,
        height = 54,
        visibleRows = 3,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.TraitInspectorStatsScroll:SetParent(self.TraitInspectorStatsPanel:GetContentFrame())
    self.TraitInspectorStatsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "datasetName", width = 82, justifyH = "LEFT" },
                { key = "statName", width = 84, justifyH = "LEFT" },
                { key = "valueText", width = 58, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "LeftButton" then
                    self.SelectedTraitStatBonusIndex = rowData and rowData.rowIndex or nil
                    self:RefreshTraitInspectorPage()
                elseif button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowTraitInspectorStatContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.TraitInspectorStatsScroll:Create()
    UI.Utils.AnchorFill(self.TraitInspectorStatsScroll, self.TraitInspectorStatsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.TraitInspectorPendingStatRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorTraitInspectorPendingStatRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.TraitInspectorPendingStatRow)

    self.TraitInspectorPendingStatDatasetDropdown = UI.CreateDropdown(self.TraitInspectorPendingStatRow:GetFrame(), "RPEDataEditorTraitInspectorPendingStatDatasetDropdown", {
        width = 72,
        height = 18,
        items = self:BuildTraitInspectorDatasetItems(),
        onValueChanged = function()
            if self._refreshingTraitInspector then
                return
            end

            self:RefreshTraitInspectorPendingStatDropdown()
            if self.TraitInspectorPendingStatDropdown and self.TraitInspectorPendingStatDropdown.SetSelectedValue then
                self.TraitInspectorPendingStatDropdown:SetSelectedValue("", true)
            end
        end,
    })
    self.TraitInspectorPendingStatRow:AddChild(self.TraitInspectorPendingStatDatasetDropdown)

    self.TraitInspectorPendingStatDropdown = UI.CreateDropdown(self.TraitInspectorPendingStatRow:GetFrame(), "RPEDataEditorTraitInspectorPendingStatDropdown", {
        width = 90,
        height = 18,
        items = { { label = "None", value = "" } },
    })
    self.TraitInspectorPendingStatRow:AddChild(self.TraitInspectorPendingStatDropdown)

    self.TraitInspectorPendingStatValueInput = UI.CreateTextInput(self.TraitInspectorPendingStatRow:GetFrame(), "RPEDataEditorTraitInspectorPendingStatValueInput", {
        width = 38,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.TraitInspectorPendingStatRow:AddChild(self.TraitInspectorPendingStatValueInput)

    self.TraitInspectorPendingStatOperationGroup = createGroup("RPEDataEditorTraitInspectorPendingStatOperationGroup", "Stat Bonus Type", 18)
    self.TraitInspectorPendingStatOperationDropdown = UI.CreateDropdown(self.TraitInspectorPendingStatOperationGroup:GetFrame(), "RPEDataEditorTraitInspectorPendingStatOperationDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = STAT_BONUS_OPERATION_ITEMS,
    })
    self.TraitInspectorPendingStatOperationGroup:AddChild(self.TraitInspectorPendingStatOperationDropdown)

    self.TraitInspectorAddStatButton = UI.CreateButton(self.TraitInspectorPendingStatRow:GetFrame(), "RPEDataEditorTraitInspectorAddStatButton", "Add", 34, function()
        if self._refreshingTraitInspector then
            return
        end

        local statRef = self.TraitInspectorPendingStatDropdown and self.TraitInspectorPendingStatDropdown.GetSelectedValue and self.TraitInspectorPendingStatDropdown:GetSelectedValue() or ""
        if statRef == "" then
            return
        end

        local value = tonumber(self.TraitInspectorPendingStatValueInput and self.TraitInspectorPendingStatValueInput:GetText()) or 0
        local operation = self.TraitInspectorPendingStatOperationDropdown and self.TraitInspectorPendingStatOperationDropdown.GetSelectedValue and self.TraitInspectorPendingStatOperationDropdown:GetSelectedValue() or "flat"
        self:CommitSelectedTrait(function(trait)
            local bonuses = normalizeTraitStatBonuses(trait.statBonuses)
            bonuses[#bonuses + 1] = {
                statRef = statRef,
                operation = operation,
                value = value,
            }
            trait.statBonuses = bonuses
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.TraitInspectorPendingStatRow:AddChild(self.TraitInspectorAddStatButton)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorTraitInspectorSkillsLabel", "Skill Bonuses"))
    self.TraitInspectorSkillsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorTraitInspectorSkillsPanel", {
        width = FIELD_WIDTH,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.TraitInspectorSkillsPanel)

    self.TraitInspectorSkillsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorTraitInspectorSkillsScroll",
        width = FIELD_WIDTH,
        height = 54,
        visibleRows = 3,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.TraitInspectorSkillsScroll:SetParent(self.TraitInspectorSkillsPanel:GetContentFrame())
    self.TraitInspectorSkillsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "datasetName", width = 82, justifyH = "LEFT" },
                { key = "skillName", width = 84, justifyH = "LEFT" },
                { key = "valueText", width = 58, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "LeftButton" then
                    self.SelectedTraitSkillBonusIndex = rowData and rowData.rowIndex or nil
                    self:RefreshTraitInspectorPage()
                elseif button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowTraitInspectorSkillContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.TraitInspectorSkillsScroll:Create()
    UI.Utils.AnchorFill(self.TraitInspectorSkillsScroll, self.TraitInspectorSkillsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.TraitInspectorPendingSkillRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorTraitInspectorPendingSkillRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.TraitInspectorPendingSkillRow)

    self.TraitInspectorPendingSkillDatasetDropdown = UI.CreateDropdown(self.TraitInspectorPendingSkillRow:GetFrame(), "RPEDataEditorTraitInspectorPendingSkillDatasetDropdown", {
        width = 72,
        height = 18,
        items = self:BuildTraitInspectorDatasetItems(),
        onValueChanged = function()
            if self._refreshingTraitInspector then
                return
            end

            self:RefreshTraitInspectorPendingSkillDropdown()
            if self.TraitInspectorPendingSkillDropdown and self.TraitInspectorPendingSkillDropdown.SetSelectedValue then
                self.TraitInspectorPendingSkillDropdown:SetSelectedValue("", true)
            end
        end,
    })
    self.TraitInspectorPendingSkillRow:AddChild(self.TraitInspectorPendingSkillDatasetDropdown)

    self.TraitInspectorPendingSkillDropdown = UI.CreateDropdown(self.TraitInspectorPendingSkillRow:GetFrame(), "RPEDataEditorTraitInspectorPendingSkillDropdown", {
        width = 90,
        height = 18,
        items = { { label = "None", value = "" } },
    })
    self.TraitInspectorPendingSkillRow:AddChild(self.TraitInspectorPendingSkillDropdown)

    self.TraitInspectorPendingSkillValueInput = UI.CreateTextInput(self.TraitInspectorPendingSkillRow:GetFrame(), "RPEDataEditorTraitInspectorPendingSkillValueInput", {
        width = 38,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.TraitInspectorPendingSkillRow:AddChild(self.TraitInspectorPendingSkillValueInput)

    self.TraitInspectorAddSkillButton = UI.CreateButton(self.TraitInspectorPendingSkillRow:GetFrame(), "RPEDataEditorTraitInspectorAddSkillButton", "Add", 34, function()
        if self._refreshingTraitInspector then
            return
        end

        local skillRef = self.TraitInspectorPendingSkillDropdown and self.TraitInspectorPendingSkillDropdown.GetSelectedValue and self.TraitInspectorPendingSkillDropdown:GetSelectedValue() or ""
        if skillRef == "" then
            return
        end

        local value = tonumber(self.TraitInspectorPendingSkillValueInput and self.TraitInspectorPendingSkillValueInput:GetText()) or 0
        self:CommitSelectedTrait(function(trait)
            local bonuses = normalizeTraitSkillBonuses(trait.skillBonuses)
            bonuses[#bonuses + 1] = {
                skillRef = skillRef,
                value = value,
            }
            trait.skillBonuses = bonuses
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.TraitInspectorPendingSkillRow:AddChild(self.TraitInspectorAddSkillButton)

    self.TraitInspectorAutoAuraGroup = createGroup("RPEDataEditorTraitInspectorAutoAuraGroup", "Aura", 18)
    self.TraitInspectorAutoAuraDropdown = UI.CreateDropdown(self.TraitInspectorAutoAuraGroup:GetFrame(), "RPEDataEditorTraitInspectorAutoAuraDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:BuildSpellInspectorAurasAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingTraitInspector then
                return
            end

            self:CommitSelectedTrait(function(trait)
                local automaticAuras = normalizeAutomaticAuras(trait.automaticAuras)
                local current = automaticAuras[1] or {
                    targetScope = "self",
                    stacks = 1,
                    turns = 1,
                    powerLevel = 0,
                }
                if value == "" then
                    trait.automaticAuras = {}
                    return
                end
                current.auraRef = value
                automaticAuras[1] = current
                trait.automaticAuras = automaticAuras
            end)
        end,
    })
    self.TraitInspectorAutoAuraGroup:AddChild(self.TraitInspectorAutoAuraDropdown)

    self.TraitInspectorAutoAuraTargetGroup = createGroup("RPEDataEditorTraitInspectorAutoAuraTargetGroup", "Aura Target", 18)
    self.TraitInspectorAutoAuraTargetDropdown = UI.CreateDropdown(self.TraitInspectorAutoAuraTargetGroup:GetFrame(), "RPEDataEditorTraitInspectorAutoAuraTargetDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = AUTO_AURA_TARGET_ITEMS,
        onValueChanged = function(value)
            if self._refreshingTraitInspector then
                return
            end

            self:CommitSelectedTrait(function(trait)
                local automaticAuras = normalizeAutomaticAuras(trait.automaticAuras)
                local current = automaticAuras[1]
                if not current then
                    return
                end
                current.targetScope = value or "self"
                automaticAuras[1] = current
                trait.automaticAuras = automaticAuras
            end)
        end,
    })
    self.TraitInspectorAutoAuraTargetGroup:AddChild(self.TraitInspectorAutoAuraTargetDropdown)

    self.TraitInspectorAutoAuraStacksGroup = createEffectTextGroup("RPEDataEditorTraitInspectorAutoAuraStacksGroup", "Aura Stacks", "TraitInspectorAutoAuraStacksInput")
    self.TraitInspectorAutoAuraDurationGroup = createEffectTextGroup("RPEDataEditorTraitInspectorAutoAuraDurationGroup", "Aura Duration", "TraitInspectorAutoAuraTurnsInput")
    self.TraitInspectorAutoAuraPowerGroup = createEffectTextGroup("RPEDataEditorTraitInspectorAutoAuraPowerGroup", "Base Power", "TraitInspectorAutoAuraPowerInput")

    bindInput("TraitInspectorAutoAuraStacksInput", function()
        self:CommitSelectedTrait(function(trait)
            local automaticAuras = normalizeAutomaticAuras(trait.automaticAuras)
            local current = automaticAuras[1]
            if not current then
                return
            end
            current.stacks = tonumber(self.TraitInspectorAutoAuraStacksInput:GetText()) or 1
            automaticAuras[1] = current
            trait.automaticAuras = automaticAuras
        end)
    end)
    bindInput("TraitInspectorAutoAuraTurnsInput", function()
        self:CommitSelectedTrait(function(trait)
            local automaticAuras = normalizeAutomaticAuras(trait.automaticAuras)
            local current = automaticAuras[1]
            if not current then
                return
            end
            current.turns = tonumber(self.TraitInspectorAutoAuraTurnsInput:GetText()) or 1
            automaticAuras[1] = current
            trait.automaticAuras = automaticAuras
        end)
    end)
    bindInput("TraitInspectorAutoAuraPowerInput", function()
        self:CommitSelectedTrait(function(trait)
            local automaticAuras = normalizeAutomaticAuras(trait.automaticAuras)
            local current = automaticAuras[1]
            if not current then
                return
            end
            current.powerLevel = tonumber(self.TraitInspectorAutoAuraPowerInput:GetText()) or 0
            automaticAuras[1] = current
            trait.automaticAuras = automaticAuras
        end)
    end)

    local function refreshScrollBounds()
        local viewportHeight = self.TraitInspectorBonusesScrollFrame and self.TraitInspectorBonusesScrollFrame:GetHeight() or 0
        local contentHeight = root:GetFrame() and root:GetFrame():GetHeight() or 0
        local maxScroll = math.max(0, math.floor(contentHeight - viewportHeight + 0.5))

        self.TraitInspectorBonusesScrollBar:SetMinMaxValues(0, maxScroll)
        if self.TraitInspectorBonusesScrollBar.SetShown then
            self.TraitInspectorBonusesScrollBar:SetShown(maxScroll > 0)
        elseif maxScroll > 0 and self.TraitInspectorBonusesScrollBar.Show then
            self.TraitInspectorBonusesScrollBar:Show()
        elseif self.TraitInspectorBonusesScrollBar.Hide then
            self.TraitInspectorBonusesScrollBar:Hide()
        end
        if (self.TraitInspectorBonusesScrollBar:GetValue() or 0) > maxScroll then
            self.TraitInspectorBonusesScrollBar:SetValue(maxScroll)
        end
    end

    self.RefreshTraitInspectorBonusesScrollBounds = refreshScrollBounds
    self.TraitInspectorBonusesScrollFrame:SetScript("OnShow", refreshScrollBounds)
    attachMouseWheelRecursive(root)
end

local function buildTraitInspectorEventsPage(self, page)
    local function handleMouseWheel(_, delta)
        local _, maxValue = self.TraitInspectorEventsScrollBar:GetMinMaxValues()
        local current = self.TraitInspectorEventsScrollBar:GetValue() or 0
        local nextValue = math.max(0, math.min(maxValue or 0, current - ((delta or 0) * 24)))
        self.TraitInspectorEventsScrollBar:SetValue(nextValue)
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

    attachMouseWheel(page)
    self.TraitInspectorEventsScrollFrame = CreateFrame("ScrollFrame", "RPEDataEditorTraitInspectorEventsScrollFrame", page)
    self.TraitInspectorEventsScrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.TraitInspectorEventsScrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -20, 0)
    self.TraitInspectorEventsScrollFrame:EnableMouseWheel(true)
    self.TraitInspectorEventsScrollFrame:SetClipsChildren(true)
    attachMouseWheel(self.TraitInspectorEventsScrollFrame)

    self.TraitInspectorEventsScrollBar = CreateFrame("Slider", "RPEDataEditorTraitInspectorEventsScrollBar", page)
    self.TraitInspectorEventsScrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -2)
    self.TraitInspectorEventsScrollBar:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 2)
    self.TraitInspectorEventsScrollBar:SetOrientation("VERTICAL")
    self.TraitInspectorEventsScrollBar:SetMinMaxValues(0, 0)
    self.TraitInspectorEventsScrollBar:SetValueStep(12)
    if self.TraitInspectorEventsScrollBar.SetObeyStepOnDrag then
        self.TraitInspectorEventsScrollBar:SetObeyStepOnDrag(true)
    end
    self.TraitInspectorEventsScrollBar:SetWidth(12)

    self.TraitInspectorEventsScrollBarTrack = self.TraitInspectorEventsScrollBarTrack or self.TraitInspectorEventsScrollBar:CreateTexture(nil, "BACKGROUND")
    self.TraitInspectorEventsScrollBarTrack:SetAllPoints(self.TraitInspectorEventsScrollBar)
    local trackColor = UI.ResolveColor(nil, "list.rowBackground")
    self.TraitInspectorEventsScrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)

    self.TraitInspectorEventsScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = self.TraitInspectorEventsScrollBar.GetThumbTexture and self.TraitInspectorEventsScrollBar:GetThumbTexture() or nil
    if thumb and thumb.SetVertexColor then
        local thumbColor = UI.ResolveColor(nil, "button.primary")
        thumb:SetVertexColor(thumbColor.r or 0.8, thumbColor.g or 0.8, thumbColor.b or 0.8, thumbColor.a or 0.95)
    end
    self.TraitInspectorEventsScrollBar:SetValue(0)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.TraitInspectorEventsScrollFrame, "RPEDataEditorTraitInspectorEventsRoot", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = true,
    })
    root:GetFrame():SetPoint("TOPLEFT", self.TraitInspectorEventsScrollFrame, "TOPLEFT", 0, 0)
    root:GetFrame():SetPoint("TOPRIGHT", self.TraitInspectorEventsScrollFrame, "TOPRIGHT", 0, 0)
    self.TraitInspectorEventsScrollFrame:SetScrollChild(root:GetFrame())
    self.TraitInspectorEventsScrollBar:SetScript("OnValueChanged", function(_, value)
        self.TraitInspectorEventsScrollFrame:SetVerticalScroll(value or 0)
    end)
    self.TraitInspectorEventsScrollFrame:SetScript("OnMouseWheel", handleMouseWheel)
    self.TraitInspectorEventsScrollFrame:SetScript("OnSizeChanged", function(scrollFrame)
        local width = math.max(1, (scrollFrame:GetWidth() or FIELD_WIDTH) - 4)
        root:GetFrame():SetWidth(width)
        if root.RefreshLayout then
            root:RefreshLayout()
        end
    end)

    self.TraitInspectorEventsRoot = root
    attachMouseWheel(root)

    local function createGroup(name, labelText, height)
        local groupHeight = 12 + 2 + (height or CONTROL_HEIGHT)
        local group = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), name, {
            width = FIELD_WIDTH,
            height = groupHeight,
            spacing = 2,
            fitChildrenWidth = true,
            fitChildrenHeight = false,
        })
        group._visibleHeight = groupHeight
        root:AddChild(group)
        local label = buildLabel(group:GetFrame(), name .. "Label", labelText)
        group:AddChild(label)
        attachMouseWheel(group)
        return group, label
    end

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorTraitInspectorEventsLabel", "Permanent Events"))

    self.TraitInspectorEventsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorTraitInspectorEventsPanel", {
        width = FIELD_WIDTH,
        height = 92,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.TraitInspectorEventsPanel)
    attachMouseWheel(self.TraitInspectorEventsPanel)

    self.TraitInspectorEventsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorTraitInspectorEventsScroll",
        width = FIELD_WIDTH,
        height = 90,
        visibleRows = 5,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 130,
        statusWidth = 26,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.TraitInspectorEventsScroll:SetParent(self.TraitInspectorEventsPanel:GetContentFrame())
    self.TraitInspectorEventsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetCategory then
            row:SetCategory(item and item.title or "")
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(item and item.statusText or "")
        end
        if row.SetDetail then
            row:SetDetail(item and item.detail or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedTraitInspectorEventIndex(itemIndex)
                    self.SelectedTraitEventEffectIndex = nil
                    self.SelectedTraitEventScalingIndex = nil
                    self:RefreshTraitInspectorPage()
                end
            end)

            local isSelected = tonumber(self.SelectedTraitEventIndex) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.TraitInspectorEventsScroll:Create()
    UI.Utils.AnchorFill(self.TraitInspectorEventsScroll, self.TraitInspectorEventsPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.TraitInspectorEventsScroll)

    self.TraitInspectorEventButtons = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorTraitInspectorEventButtons", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.TraitInspectorEventButtons)
    attachMouseWheel(self.TraitInspectorEventButtons)

    self.TraitInspectorAddEventButton = UI.CreateButton(self.TraitInspectorEventButtons:GetFrame(), "RPEDataEditorTraitInspectorAddEventButton", "Add Event", 72, function()
        self:AddTraitInspectorEvent()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.TraitInspectorEventButtons:AddChild(self.TraitInspectorAddEventButton)
    attachMouseWheel(self.TraitInspectorAddEventButton)

    self.TraitInspectorDeleteEventButton = UI.CreateButton(self.TraitInspectorEventButtons:GetFrame(), "RPEDataEditorTraitInspectorDeleteEventButton", "Delete Event", 78, function()
        self:RemoveSelectedTraitInspectorEvent()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.TraitInspectorEventButtons:AddChild(self.TraitInspectorDeleteEventButton)
    attachMouseWheel(self.TraitInspectorDeleteEventButton)

    self.TraitInspectorSelectedEventHeader = UI.CreateText(root:GetFrame(), "RPEDataEditorTraitInspectorSelectedEventHeader", "Select an event to edit it.", {
        width = FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.TraitInspectorSelectedEventHeader)

    self.TraitInspectorCombatEventGroup = createGroup("RPEDataEditorTraitInspectorCombatEventGroup", "Combat Trigger", 18)
    self.TraitInspectorCombatEventDropdown = UI.CreateDropdown(self.TraitInspectorCombatEventGroup:GetFrame(), "RPEDataEditorTraitInspectorCombatEventDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:GetAuraInspectorCombatEventItems(),
        onValueChanged = function(value)
            if self._refreshingTraitInspector then
                return
            end

            self:CommitSelectedTraitInspectorEvent(function(traitEvent)
                traitEvent.combatEventId = value ~= "" and value or nil
                if traitEvent.combatEventId == nil then
                    traitEvent.triggerTarget = nil
                end
                self:NormalizeAuraInspectorEvent(traitEvent)
            end)
        end,
    })
    self.TraitInspectorCombatEventGroup:AddChild(self.TraitInspectorCombatEventDropdown)
    attachMouseWheel(self.TraitInspectorCombatEventDropdown)

    self.TraitInspectorTriggerTargetGroup = createGroup("RPEDataEditorTraitInspectorTriggerTargetGroup", "Trigger Target", 18)
    self.TraitInspectorTriggerTargetDropdown = UI.CreateDropdown(self.TraitInspectorTriggerTargetGroup:GetFrame(), "RPEDataEditorTraitInspectorTriggerTargetDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:GetAuraInspectorTriggerTargetItems(),
        onValueChanged = function(value)
            if self._refreshingTraitInspector then
                return
            end

            self:CommitSelectedTraitInspectorEvent(function(traitEvent)
                traitEvent.triggerTarget = value ~= "" and value or nil
                self:NormalizeAuraInspectorEvent(traitEvent)
            end)
        end,
    })
    self.TraitInspectorTriggerTargetGroup:AddChild(self.TraitInspectorTriggerTargetDropdown)
    attachMouseWheel(self.TraitInspectorTriggerTargetDropdown)

    self.TraitInspectorEventChanceGroup = createGroup("RPEDataEditorTraitInspectorEventChanceGroup", "Trigger Chance %", 18)
    self.TraitInspectorEventChanceInput = UI.CreateTextInput(self.TraitInspectorEventChanceGroup:GetFrame(), "RPEDataEditorTraitInspectorEventChanceInput", {
        width = FIELD_WIDTH,
        height = 18,
        text = "100",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.TraitInspectorEventChanceGroup:AddChild(self.TraitInspectorEventChanceInput)
    attachMouseWheel(self.TraitInspectorEventChanceInput)

    self.TraitInspectorSelectedEventEffectHeader = UI.CreateText(root:GetFrame(), "RPEDataEditorTraitInspectorSelectedEventEffectHeader", "Select an event effect to edit it.", {
        width = FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.TraitInspectorSelectedEventEffectHeader)

    self.TraitInspectorEventEffectsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorTraitInspectorEventEffectsPanel", {
        width = FIELD_WIDTH,
        height = 92,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.TraitInspectorEventEffectsPanel)
    attachMouseWheel(self.TraitInspectorEventEffectsPanel)

    self.TraitInspectorEventEffectsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorTraitInspectorEventEffectsScroll",
        width = FIELD_WIDTH,
        height = 90,
        visibleRows = 5,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 110,
        statusWidth = 44,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.TraitInspectorEventEffectsScroll:SetParent(self.TraitInspectorEventEffectsPanel:GetContentFrame())
    self.TraitInspectorEventEffectsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetCategory then
            row:SetCategory(item and item.title or "")
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(item and item.statusText or "")
        end
        if row.SetDetail then
            row:SetDetail(item and item.detail or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedTraitInspectorEventEffectIndex(itemIndex)
                    self.SelectedTraitEventScalingIndex = nil
                    self:RefreshTraitInspectorPage()
                end
            end)

            local isSelected = tonumber(self.SelectedTraitEventEffectIndex) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.TraitInspectorEventEffectsScroll:Create()
    UI.Utils.AnchorFill(self.TraitInspectorEventEffectsScroll, self.TraitInspectorEventEffectsPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.TraitInspectorEventEffectsScroll)

    self.TraitInspectorEventEffectButtons = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorTraitInspectorEventEffectButtons", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.TraitInspectorEventEffectButtons)
    attachMouseWheel(self.TraitInspectorEventEffectButtons)

    self.TraitInspectorAddEventEffectButton = UI.CreateButton(self.TraitInspectorEventEffectButtons:GetFrame(), "RPEDataEditorTraitInspectorAddEventEffectButton", "Add Effect", 72, function()
        self:AddTraitInspectorEventEffect()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.TraitInspectorEventEffectButtons:AddChild(self.TraitInspectorAddEventEffectButton)
    attachMouseWheel(self.TraitInspectorAddEventEffectButton)

    self.TraitInspectorDeleteEventEffectButton = UI.CreateButton(self.TraitInspectorEventEffectButtons:GetFrame(), "RPEDataEditorTraitInspectorDeleteEventEffectButton", "Delete Effect", 78, function()
        self:RemoveSelectedTraitInspectorEventEffect()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.TraitInspectorEventEffectButtons:AddChild(self.TraitInspectorDeleteEventEffectButton)
    attachMouseWheel(self.TraitInspectorDeleteEventEffectButton)

    self.TraitInspectorEventEffectTypeGroup = createGroup("RPEDataEditorTraitInspectorEventEffectTypeGroup", "Effect Type", 18)
    self.TraitInspectorEventEffectTypeDropdown = UI.CreateDropdown(self.TraitInspectorEventEffectTypeGroup:GetFrame(), "RPEDataEditorTraitInspectorEventEffectTypeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = TRAIT_EVENT_EFFECT_TYPE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingTraitInspector then
                return
            end

            self:CommitSelectedTraitInspectorEventEffect(function(effect)
                effect.type = value
                normalizeTraitInspectorEventEffect(effect)
            end)
        end,
    })
    self.TraitInspectorEventEffectTypeGroup:AddChild(self.TraitInspectorEventEffectTypeDropdown)
    attachMouseWheel(self.TraitInspectorEventEffectTypeDropdown)

    self.TraitInspectorEventBaseAmountGroup, self.TraitInspectorEventBaseAmountLabel = createGroup("RPEDataEditorTraitInspectorEventBaseAmountGroup", "Base Damage")
    self.TraitInspectorEventBaseAmountInput = UI.CreateTextInput(self.TraitInspectorEventBaseAmountGroup:GetFrame(), "RPEDataEditorTraitInspectorEventBaseAmountInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.TraitInspectorEventBaseAmountGroup:AddChild(self.TraitInspectorEventBaseAmountInput)
    attachMouseWheel(self.TraitInspectorEventBaseAmountInput)

    self.TraitInspectorEventAmountModeGroup = createGroup("RPEDataEditorTraitInspectorEventAmountModeGroup", "Amount Mode", 18)
    self.TraitInspectorEventAmountModeDropdown = UI.CreateDropdown(self.TraitInspectorEventAmountModeGroup:GetFrame(), "RPEDataEditorTraitInspectorEventAmountModeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = AMOUNT_MODE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingTraitInspector then
                return
            end

            self:CommitSelectedTraitInspectorEventEffect(function(effect)
                effect.amountMode = value
            end)
        end,
    })
    self.TraitInspectorEventAmountModeGroup:AddChild(self.TraitInspectorEventAmountModeDropdown)
    attachMouseWheel(self.TraitInspectorEventAmountModeDropdown)

    self.TraitInspectorEventDamageSchoolsGroup = createGroup("RPEDataEditorTraitInspectorEventDamageSchoolsGroup", "Damage Schools", 18)
    self.TraitInspectorEventDamageSchoolsDropdown = UI.CreateDropdown(self.TraitInspectorEventDamageSchoolsGroup:GetFrame(), "RPEDataEditorTraitInspectorEventDamageSchoolsDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        multiSelect = true,
        items = self:BuildSpellInspectorDamageSchoolsAcrossDatasets(),
        onValueChanged = function()
            if self._refreshingTraitInspector then
                return
            end

            self:CommitSelectedTraitInspectorEventEffect(function(effect)
                effect.damageSchoolRefs = self.TraitInspectorEventDamageSchoolsDropdown:GetSelectedValues()
            end)
        end,
    })
    self.TraitInspectorEventDamageSchoolsGroup:AddChild(self.TraitInspectorEventDamageSchoolsDropdown)
    attachMouseWheel(self.TraitInspectorEventDamageSchoolsDropdown)

    local function createEffectTextGroup(groupName, labelText, fieldName)
        local group = createGroup(groupName, labelText)
        self[fieldName] = UI.CreateTextInput(group:GetFrame(), fieldName, {
            width = FIELD_WIDTH,
            height = CONTROL_HEIGHT,
            text = "",
            borderColor = UI.ResolveColor(nil, "panel.border"),
        })
        group:AddChild(self[fieldName])
        attachMouseWheel(self[fieldName])
        return group
    end

    self.TraitInspectorEventAuraGroup = createGroup("RPEDataEditorTraitInspectorEventAuraGroup", "Aura", 18)
    self.TraitInspectorEventAuraDropdown = UI.CreateDropdown(self.TraitInspectorEventAuraGroup:GetFrame(), "RPEDataEditorTraitInspectorEventAuraDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:BuildSpellInspectorAurasAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingTraitInspector then
                return
            end

            self:CommitSelectedTraitInspectorEventEffect(function(effect)
                effect.auraRef = value ~= "" and value or nil
            end)
        end,
    })
    self.TraitInspectorEventAuraGroup:AddChild(self.TraitInspectorEventAuraDropdown)
    attachMouseWheel(self.TraitInspectorEventAuraDropdown)

    self.TraitInspectorEventAuraStacksGroup = createEffectTextGroup("RPEDataEditorTraitInspectorEventAuraStacksGroup", "Aura Stacks", "TraitInspectorEventAuraStacksInput")
    self.TraitInspectorEventAuraDurationGroup = createEffectTextGroup("RPEDataEditorTraitInspectorEventAuraDurationGroup", "Aura Duration", "TraitInspectorEventAuraDurationInput")
    self.TraitInspectorEventBasePowerGroup = createEffectTextGroup("RPEDataEditorTraitInspectorEventBasePowerGroup", "Base Power", "TraitInspectorEventBasePowerInput")
    self.TraitInspectorEventResourceAmountGroup = createEffectTextGroup("RPEDataEditorTraitInspectorEventResourceAmountGroup", "Resource Amount", "TraitInspectorEventResourceAmountInput")

    self.TraitInspectorEventResourceAmountModeGroup = createGroup("RPEDataEditorTraitInspectorEventResourceAmountModeGroup", "Amount Mode", 18)
    self.TraitInspectorEventResourceAmountModeDropdown = UI.CreateDropdown(self.TraitInspectorEventResourceAmountModeGroup:GetFrame(), "RPEDataEditorTraitInspectorEventResourceAmountModeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = AMOUNT_MODE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingTraitInspector then
                return
            end

            self:CommitSelectedTraitInspectorEventEffect(function(effect)
                effect.amountMode = value
            end)
        end,
    })
    self.TraitInspectorEventResourceAmountModeGroup:AddChild(self.TraitInspectorEventResourceAmountModeDropdown)
    attachMouseWheel(self.TraitInspectorEventResourceAmountModeDropdown)

    self.TraitInspectorEventResourceGroup = createGroup("RPEDataEditorTraitInspectorEventResourceGroup", "Resource", 18)
    self.TraitInspectorEventResourceDropdown = UI.CreateDropdown(self.TraitInspectorEventResourceGroup:GetFrame(), "RPEDataEditorTraitInspectorEventResourceDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:BuildSpellInspectorResourcesAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingTraitInspector then
                return
            end

            self:CommitSelectedTraitInspectorEventEffect(function(effect)
                effect.resourceRef = value ~= "" and value or nil
            end)
        end,
    })
    self.TraitInspectorEventResourceGroup:AddChild(self.TraitInspectorEventResourceDropdown)
    attachMouseWheel(self.TraitInspectorEventResourceDropdown)

    self.TraitInspectorEventScalingGroup = createGroup("RPEDataEditorTraitInspectorEventScalingGroup", "Stat Scaling", 110)
    self.TraitInspectorEventScalingPanel = UI.CreatePanel(self.TraitInspectorEventScalingGroup:GetFrame(), "RPEDataEditorTraitInspectorEventScalingPanel", {
        width = FIELD_WIDTH,
        height = 74,
        contentInset = 1,
        showBorder = true,
    })
    self.TraitInspectorEventScalingGroup:AddChild(self.TraitInspectorEventScalingPanel)
    attachMouseWheel(self.TraitInspectorEventScalingPanel)

    self.TraitInspectorEventScalingScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorTraitInspectorEventScalingScroll",
        width = FIELD_WIDTH,
        height = 72,
        visibleRows = 4,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 150,
        statusWidth = 40,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.TraitInspectorEventScalingScroll:SetParent(self.TraitInspectorEventScalingPanel:GetContentFrame())
    self.TraitInspectorEventScalingScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetCategory then
            row:SetCategory(item and item.title or "")
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(item and item.statusText or "")
        end
        if row.SetDetail then
            row:SetDetail(item and item.detail or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedTraitEventScalingIndex = itemIndex
                    self:RefreshTraitInspectorPage()
                end
            end)

            local isSelected = tonumber(self.SelectedTraitEventScalingIndex) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.TraitInspectorEventScalingScroll:Create()
    UI.Utils.AnchorFill(self.TraitInspectorEventScalingScroll, self.TraitInspectorEventScalingPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.TraitInspectorEventScalingScroll)

    self.TraitInspectorPendingEventScalingRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.TraitInspectorEventScalingGroup:GetFrame(), "RPEDataEditorTraitInspectorPendingEventScalingRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.TraitInspectorEventScalingGroup:AddChild(self.TraitInspectorPendingEventScalingRow)
    attachMouseWheel(self.TraitInspectorPendingEventScalingRow)

    self.TraitInspectorPendingEventScalingStatDropdown = UI.CreateDropdown(self.TraitInspectorPendingEventScalingRow:GetFrame(), "RPEDataEditorTraitInspectorPendingEventScalingStatDropdown", {
        width = 146,
        height = 18,
        items = self:BuildSpellInspectorStatsAcrossDatasets(),
    })
    self.TraitInspectorPendingEventScalingRow:AddChild(self.TraitInspectorPendingEventScalingStatDropdown)
    attachMouseWheel(self.TraitInspectorPendingEventScalingStatDropdown)

    self.TraitInspectorPendingEventScalingCoefficientInput = UI.CreateTextInput(self.TraitInspectorPendingEventScalingRow:GetFrame(), "RPEDataEditorTraitInspectorPendingEventScalingCoefficientInput", {
        width = 44,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.TraitInspectorPendingEventScalingRow:AddChild(self.TraitInspectorPendingEventScalingCoefficientInput)
    attachMouseWheel(self.TraitInspectorPendingEventScalingCoefficientInput)

    self.TraitInspectorAddEventScalingButton = UI.CreateButton(self.TraitInspectorPendingEventScalingRow:GetFrame(), "RPEDataEditorTraitInspectorAddEventScalingButton", "Add", 36, function()
        local effect = self:GetSelectedTraitInspectorEventEffect()
        if not effect then
            return
        end

        local statRef = self.TraitInspectorPendingEventScalingStatDropdown and self.TraitInspectorPendingEventScalingStatDropdown.GetSelectedValue and self.TraitInspectorPendingEventScalingStatDropdown:GetSelectedValue() or ""
        if statRef == "" then
            return
        end

        local coefficient = tonumber(self.TraitInspectorPendingEventScalingCoefficientInput and self.TraitInspectorPendingEventScalingCoefficientInput:GetText()) or 0
        self:CommitSelectedTraitInspectorEventEffect(function(selectedEffect)
            selectedEffect.statScaling = selectedEffect.statScaling or {}
            selectedEffect.statScaling[#selectedEffect.statScaling + 1] = {
                statRef = statRef,
                coefficient = coefficient,
            }
            self.SelectedTraitEventScalingIndex = #selectedEffect.statScaling
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.TraitInspectorPendingEventScalingRow:AddChild(self.TraitInspectorAddEventScalingButton)
    attachMouseWheel(self.TraitInspectorAddEventScalingButton)

    self.TraitInspectorDeleteEventScalingButton = UI.CreateButton(self.TraitInspectorPendingEventScalingRow:GetFrame(), "RPEDataEditorTraitInspectorDeleteEventScalingButton", "Delete", 44, function()
        local effect = self:GetSelectedTraitInspectorEventEffect()
        local scalingIndex = tonumber(self.SelectedTraitEventScalingIndex) or 0
        if not effect or scalingIndex <= 0 or type(effect.statScaling) ~= "table" or not effect.statScaling[scalingIndex] then
            return
        end

        self:CommitSelectedTraitInspectorEventEffect(function(selectedEffect)
            table.remove(selectedEffect.statScaling, scalingIndex)
            if #(selectedEffect.statScaling or {}) > 0 then
                self.SelectedTraitEventScalingIndex = math.min(scalingIndex, #selectedEffect.statScaling)
            else
                self.SelectedTraitEventScalingIndex = nil
            end
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.TraitInspectorPendingEventScalingRow:AddChild(self.TraitInspectorDeleteEventScalingButton)
    attachMouseWheel(self.TraitInspectorDeleteEventScalingButton)

    local function bindInput(fieldName, callback)
        self[fieldName]:SetScript("OnEnterPressed", callback)
        self[fieldName]:SetScript("OnEditFocusLost", callback)
    end

    bindInput("TraitInspectorEventBaseAmountInput", function()
        self:CommitSelectedTraitInspectorEventEffect(function(effect)
            local amount = tonumber(self.TraitInspectorEventBaseAmountInput:GetText()) or 0
            if tostring(effect.type or "damage") == "heal" then
                effect.baseHealing = amount
            else
                effect.baseDamage = amount
            end
        end)
    end)
    bindInput("TraitInspectorEventAuraStacksInput", function()
        self:CommitSelectedTraitInspectorEventEffect(function(effect)
            effect.stacks = math.max(1, math.floor(tonumber(self.TraitInspectorEventAuraStacksInput:GetText()) or 1))
        end)
    end)
    bindInput("TraitInspectorEventAuraDurationInput", function()
        self:CommitSelectedTraitInspectorEventEffect(function(effect)
            effect.duration = math.max(1, math.floor(tonumber(self.TraitInspectorEventAuraDurationInput:GetText()) or 12))
        end)
    end)
    bindInput("TraitInspectorEventBasePowerInput", function()
        self:CommitSelectedTraitInspectorEventEffect(function(effect)
            effect.basePower = tonumber(self.TraitInspectorEventBasePowerInput:GetText()) or 0
        end)
    end)
    bindInput("TraitInspectorEventResourceAmountInput", function()
        self:CommitSelectedTraitInspectorEventEffect(function(effect)
            effect.amount = tonumber(self.TraitInspectorEventResourceAmountInput:GetText()) or 0
        end)
    end)
    bindInput("TraitInspectorEventChanceInput", function()
        self:CommitSelectedTraitInspectorEvent(function(traitEvent)
            traitEvent.chance = tonumber(self.TraitInspectorEventChanceInput:GetText()) or 100
            self:NormalizeAuraInspectorEvent(traitEvent)
        end)
    end)

    local function refreshScrollBounds()
        local frame = root:GetFrame()
        local viewportHeight = self.TraitInspectorEventsScrollFrame and self.TraitInspectorEventsScrollFrame:GetHeight() or 0
        local contentHeight = frame and frame:GetHeight() or 0
        local maxScroll = math.max(0, (contentHeight or 0) - (viewportHeight or 0))

        self.TraitInspectorEventsScrollBar:SetMinMaxValues(0, maxScroll)
        if self.TraitInspectorEventsScrollBar.SetShown then
            self.TraitInspectorEventsScrollBar:SetShown(maxScroll > 0)
        elseif maxScroll > 0 and self.TraitInspectorEventsScrollBar.Show then
            self.TraitInspectorEventsScrollBar:Show()
        elseif self.TraitInspectorEventsScrollBar.Hide then
            self.TraitInspectorEventsScrollBar:Hide()
        end

        if (self.TraitInspectorEventsScrollBar:GetValue() or 0) > maxScroll then
            self.TraitInspectorEventsScrollBar:SetValue(maxScroll)
        end
    end

    self.RefreshTraitInspectorEventsScrollBounds = refreshScrollBounds
    self.TraitInspectorEventsScrollFrame:SetScript("OnShow", refreshScrollBounds)
end

function DataEditor:BuildTraitInspectorPage(parent)
    if self.TraitInspectorPage then
        self:RefreshTraitInspectorPage()
        return self.TraitInspectorPage
    end

    self.TraitInspectorPage = CreateFrame("Frame", "RPEDataEditorTraitInspectorPage", parent)

    self.TraitInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.TraitInspectorPage, "RPEDataEditorTraitInspectorSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    self.TraitInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.TraitInspectorPage, "TOPLEFT", 0, 0)
    self.TraitInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.TraitInspectorPage, "TOPRIGHT", 0, 0)

    self.TraitInspectorPreviousButton = UI.CreateButton(self.TraitInspectorSelectorBar:GetFrame(), "RPEDataEditorTraitInspectorPreviousButton", "Prev", 40, function()
        self:SetTraitInspectorTab((self:GetTraitInspectorPageDefinitions()[(self.ActiveTraitInspectorPageIndex or 1) - 1] or {}).key or "general")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.TraitInspectorSelectorBar:AddChild(self.TraitInspectorPreviousButton)

    self.TraitInspectorPageDropdown = UI.CreateDropdown(self.TraitInspectorSelectorBar:GetFrame(), "RPEDataEditorTraitInspectorPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildTraitInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if self._refreshingTraitInspectorPageSelector then
                return
            end

            self:SetTraitInspectorTab(value)
        end,
    })
    self.TraitInspectorSelectorBar:AddChild(self.TraitInspectorPageDropdown)

    self.TraitInspectorNextButton = UI.CreateButton(self.TraitInspectorSelectorBar:GetFrame(), "RPEDataEditorTraitInspectorNextButton", "Next", 40, function()
        local pages = self:GetTraitInspectorPageDefinitions()
        self:SetTraitInspectorTab((pages[(self.ActiveTraitInspectorPageIndex or 1) + 1] or {}).key or pages[#pages].key or "events")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.TraitInspectorSelectorBar:AddChild(self.TraitInspectorNextButton)

    self.TraitInspectorGeneralPage = createTraitInspectorPageFrame(self, "RPEDataEditorTraitInspectorGeneralPage")
    buildTraitInspectorGeneralPage(self, self.TraitInspectorGeneralPage)

    self.TraitInspectorBonusesPage = createTraitInspectorPageFrame(self, "RPEDataEditorTraitInspectorBonusesPage")
    buildTraitInspectorBonusesPage(self, self.TraitInspectorBonusesPage)

    self.TraitInspectorConditionsPage = createTraitInspectorPageFrame(self, "RPEDataEditorTraitInspectorConditionsPage")
    self:BuildTraitInspectorConditionsPage(self.TraitInspectorConditionsPage)

    self.TraitInspectorEventsPage = createTraitInspectorPageFrame(self, "RPEDataEditorTraitInspectorEventsPage")
    buildTraitInspectorEventsPage(self, self.TraitInspectorEventsPage)

    self.TraitInspectorEmptyText = UI.CreateText(self.TraitInspectorPage, "RPEDataEditorTraitInspectorEmptyText", "", {
        width = FIELD_WIDTH,
        height = 20,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.TraitInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.TraitInspectorPage, "BOTTOMLEFT", 0, 0)

    self.ActiveTraitInspectorPageIndex = self.ActiveTraitInspectorPageIndex or self:GetTraitInspectorPageIndexByKey(self.ActiveTraitInspectorTabKey or "general")
    self:SetTraitInspectorTab("general")
    self:RefreshTraitInspectorPage()
    return self.TraitInspectorPage
end

function DataEditor:RefreshTraitInspectorPage()
    local _, trait = self:GetSelectedTraitAndDataset()
    local hasTrait = trait ~= nil
    local automaticAura = hasTrait and trait.automaticAuras and trait.automaticAuras[1] or nil

    self._refreshingTraitInspector = true

    if self.TraitInspectorNameInput then
        self.TraitInspectorNameInput:SetText(hasTrait and ensureString(trait.name) or "")
        setTextElementEnabled(self.TraitInspectorNameInput, hasTrait)
    end
    if self.TraitInspectorIdText then
        self.TraitInspectorIdText:SetText(("ID: %s"):format(hasTrait and ensureString(trait.id) or "-"))
    end
    if self.TraitInspectorIconInput then
        self.TraitInspectorIconInput:SetText(hasTrait and ensureString(trait.icon) or "")
        setTextElementEnabled(self.TraitInspectorIconInput, hasTrait)
    end
    if self.TraitInspectorDescriptionInput then
        self.TraitInspectorDescriptionInput:SetText(hasTrait and ensureString(trait.description) or "")
        setTextElementEnabled(self.TraitInspectorDescriptionInput, hasTrait)
    end
    if self.TraitInspectorDisplayCategoryInput then
        self.TraitInspectorDisplayCategoryInput:SetText(hasTrait and ensureString(trait.category) or "")
        setTextElementEnabled(self.TraitInspectorDisplayCategoryInput, hasTrait)
    end
    if self.TraitInspectorUnlockLevelInput then
        self.TraitInspectorUnlockLevelInput:SetText(tostring(hasTrait and math.max(1, math.floor(tonumber(trait.unlockLevel) or 1)) or 1))
        setTextElementEnabled(self.TraitInspectorUnlockLevelInput, hasTrait)
    end
    if self.TraitInspectorEnvironmentalCheckbox then
        self.TraitInspectorEnvironmentalCheckbox:SetChecked(hasTrait and trait.isEnvironmental == true or false, true)
        setCheckboxEnabled(self.TraitInspectorEnvironmentalCheckbox, hasTrait)
    end

    self:RefreshTraitInspectorConditionsPage()

    if self.TraitInspectorPendingStatDatasetDropdown then
        self.TraitInspectorPendingStatDatasetDropdown:SetItems(self:BuildTraitInspectorDatasetItems())
        setDropdownEnabled(self.TraitInspectorPendingStatDatasetDropdown, hasTrait)
    end
    if self.TraitInspectorPendingStatDropdown then
        self:RefreshTraitInspectorPendingStatDropdown()
        setDropdownEnabled(self.TraitInspectorPendingStatDropdown, hasTrait)
    end
    if self.TraitInspectorStatsScroll and self.TraitInspectorStatsScroll.SetItems then
        self:RefreshTraitInspectorStatTable()
    end
    if self.TraitInspectorPendingStatValueInput then
        setTextElementEnabled(self.TraitInspectorPendingStatValueInput, hasTrait)
    end
    if self.TraitInspectorPendingStatOperationDropdown then
        self.TraitInspectorPendingStatOperationDropdown:SetSelectedValue("flat", true)
        setDropdownEnabled(self.TraitInspectorPendingStatOperationDropdown, hasTrait)
    end
    if self.TraitInspectorAddStatButton then
        self.TraitInspectorAddStatButton:SetEnabled(hasTrait)
    end
    if self.TraitInspectorPendingSkillDatasetDropdown then
        self.TraitInspectorPendingSkillDatasetDropdown:SetItems(self:BuildTraitInspectorDatasetItems())
        setDropdownEnabled(self.TraitInspectorPendingSkillDatasetDropdown, hasTrait)
    end
    if self.TraitInspectorPendingSkillDropdown then
        self:RefreshTraitInspectorPendingSkillDropdown()
        setDropdownEnabled(self.TraitInspectorPendingSkillDropdown, hasTrait)
    end
    if self.TraitInspectorSkillsScroll and self.TraitInspectorSkillsScroll.SetItems then
        self:RefreshTraitInspectorSkillTable()
    end
    if self.TraitInspectorPendingSkillValueInput then
        setTextElementEnabled(self.TraitInspectorPendingSkillValueInput, hasTrait)
    end
    if self.TraitInspectorAddSkillButton then
        self.TraitInspectorAddSkillButton:SetEnabled(hasTrait)
    end
    if self.TraitInspectorAutoAuraDropdown then
        self.TraitInspectorAutoAuraDropdown:SetItems(self:BuildSpellInspectorAurasAcrossDatasets())
        self.TraitInspectorAutoAuraDropdown:SetSelectedValue(automaticAura and automaticAura.auraRef or "", true)
        setDropdownEnabled(self.TraitInspectorAutoAuraDropdown, hasTrait)
    end
    if self.TraitInspectorAutoAuraTargetDropdown then
        self.TraitInspectorAutoAuraTargetDropdown:SetSelectedValue(automaticAura and automaticAura.targetScope or "self", true)
        setDropdownEnabled(self.TraitInspectorAutoAuraTargetDropdown, automaticAura ~= nil)
    end
    if self.TraitInspectorAutoAuraStacksInput then
        self.TraitInspectorAutoAuraStacksInput:SetText(tostring(automaticAura and automaticAura.stacks or 1))
        setTextElementEnabled(self.TraitInspectorAutoAuraStacksInput, automaticAura ~= nil)
    end
    if self.TraitInspectorAutoAuraTurnsInput then
        self.TraitInspectorAutoAuraTurnsInput:SetText(tostring(automaticAura and automaticAura.turns or 1))
        setTextElementEnabled(self.TraitInspectorAutoAuraTurnsInput, automaticAura ~= nil)
    end
    if self.TraitInspectorAutoAuraPowerInput then
        self.TraitInspectorAutoAuraPowerInput:SetText(tostring(automaticAura and automaticAura.powerLevel or 0))
        setTextElementEnabled(self.TraitInspectorAutoAuraPowerInput, automaticAura ~= nil)
    end
    setGroupVisible(self.TraitInspectorAutoAuraTargetGroup, automaticAura ~= nil)
    setGroupVisible(self.TraitInspectorAutoAuraStacksGroup, automaticAura ~= nil)
    setGroupVisible(self.TraitInspectorAutoAuraDurationGroup, automaticAura ~= nil)
    setGroupVisible(self.TraitInspectorAutoAuraPowerGroup, automaticAura ~= nil)
    if self.TraitInspectorBonusesRoot and self.TraitInspectorBonusesRoot.RefreshLayout then
        self.TraitInspectorBonusesRoot:RefreshLayout()
    end
    if self.RefreshTraitInspectorBonusesScrollBounds then
        self:RefreshTraitInspectorBonusesScrollBounds()
    end

    if self.TraitInspectorEventsScroll and self.TraitInspectorEventsScroll.SetItems then
        self:RefreshTraitInspectorEventTable()
    end
    local traitEvent = self:GetSelectedTraitInspectorEvent()
    local hasTraitEventTrigger = traitEvent ~= nil and type(traitEvent.combatEventId) == "string" and traitEvent.combatEventId ~= ""
    if self.TraitInspectorCombatEventDropdown then
        self.TraitInspectorCombatEventDropdown:SetItems(self:GetAuraInspectorCombatEventItems())
        self.TraitInspectorCombatEventDropdown:SetSelectedValue(traitEvent and traitEvent.combatEventId or "", true)
        setDropdownEnabled(self.TraitInspectorCombatEventDropdown, traitEvent ~= nil)
    end
    if self.TraitInspectorTriggerTargetDropdown then
        self.TraitInspectorTriggerTargetDropdown:SetItems(self:GetAuraInspectorTriggerTargetItems())
        self.TraitInspectorTriggerTargetDropdown:SetSelectedValue(traitEvent and traitEvent.triggerTarget or "event_other", true)
        setDropdownEnabled(self.TraitInspectorTriggerTargetDropdown, traitEvent ~= nil and hasTraitEventTrigger)
    end
    if self.TraitInspectorEventChanceInput then
        self.TraitInspectorEventChanceInput:SetText(tostring(traitEvent and traitEvent.chance or 100))
        setTextElementEnabled(self.TraitInspectorEventChanceInput, traitEvent ~= nil)
    end
    if self.TraitInspectorAddEventButton then
        self.TraitInspectorAddEventButton:SetEnabled(hasTrait)
    end
    if self.TraitInspectorDeleteEventButton then
        self.TraitInspectorDeleteEventButton:SetEnabled(traitEvent ~= nil)
    end
    if self.TraitInspectorSelectedEventHeader then
        self.TraitInspectorSelectedEventHeader:SetText(traitEvent and ("Editing event %d"):format(self.SelectedTraitEventIndex or 1) or "Select an event to edit it.")
    end
    if self.TraitInspectorEventEffectsScroll and self.TraitInspectorEventEffectsScroll.SetItems then
        self:RefreshTraitInspectorEventEffectsTable()
    end
    local eventEffect = self:GetSelectedTraitInspectorEventEffect()
    local eventEffectType = tostring(eventEffect and eventEffect.type or "damage")
    local isEventDamage = eventEffectType == "damage"
    local isEventHeal = eventEffectType == "heal"
    local isEventApplyAura = eventEffectType == "apply_aura"
    local isEventResource = eventEffectType == "resource"
    local supportsEventScaling = isEventDamage or isEventHeal
    if self.TraitInspectorAddEventEffectButton then
        self.TraitInspectorAddEventEffectButton:SetEnabled(traitEvent ~= nil)
    end
    if self.TraitInspectorDeleteEventEffectButton then
        self.TraitInspectorDeleteEventEffectButton:SetEnabled(eventEffect ~= nil)
    end
    if self.TraitInspectorSelectedEventEffectHeader then
        self.TraitInspectorSelectedEventEffectHeader:SetText(eventEffect and ("Editing event effect %d"):format(self.SelectedTraitEventEffectIndex or 1) or "Select an event effect to edit it.")
    end
    if self.TraitInspectorEventEffectTypeDropdown then
        self.TraitInspectorEventEffectTypeDropdown:SetItems(TRAIT_EVENT_EFFECT_TYPE_ITEMS)
        self.TraitInspectorEventEffectTypeDropdown:SetSelectedValue(eventEffectType, true)
        setDropdownEnabled(self.TraitInspectorEventEffectTypeDropdown, eventEffect ~= nil)
    end
    if self.TraitInspectorEventBaseAmountLabel then
        self.TraitInspectorEventBaseAmountLabel:SetText(isEventHeal and "Base Healing" or "Base Damage")
    end
    if self.TraitInspectorEventBaseAmountInput then
        local eventAmount = isEventHeal and tonumber(eventEffect and eventEffect.baseHealing) or tonumber(eventEffect and eventEffect.baseDamage)
        self.TraitInspectorEventBaseAmountInput:SetText(tostring(eventAmount or 0))
        setTextElementEnabled(self.TraitInspectorEventBaseAmountInput, eventEffect ~= nil and (isEventDamage or isEventHeal))
    end
    if self.TraitInspectorEventAmountModeDropdown then
        self.TraitInspectorEventAmountModeDropdown:SetSelectedValue(eventEffect and eventEffect.amountMode or "flat", true)
        setDropdownEnabled(self.TraitInspectorEventAmountModeDropdown, eventEffect ~= nil and (isEventDamage or isEventHeal))
    end
    if self.TraitInspectorEventDamageSchoolsDropdown then
        self.TraitInspectorEventDamageSchoolsDropdown:SetItems(self:BuildSpellInspectorDamageSchoolsAcrossDatasets())
        self.TraitInspectorEventDamageSchoolsDropdown:SetSelectedValues(eventEffect and eventEffect.damageSchoolRefs or {}, true)
        setDropdownEnabled(self.TraitInspectorEventDamageSchoolsDropdown, eventEffect ~= nil and isEventDamage)
    end
    if self.TraitInspectorEventAuraDropdown then
        self.TraitInspectorEventAuraDropdown:SetItems(self:BuildSpellInspectorAurasAcrossDatasets())
        self.TraitInspectorEventAuraDropdown:SetSelectedValue(eventEffect and eventEffect.auraRef or "", true)
        setDropdownEnabled(self.TraitInspectorEventAuraDropdown, eventEffect ~= nil and isEventApplyAura)
    end
    if self.TraitInspectorEventAuraStacksInput then
        self.TraitInspectorEventAuraStacksInput:SetText(tostring(eventEffect and eventEffect.stacks or 1))
        setTextElementEnabled(self.TraitInspectorEventAuraStacksInput, eventEffect ~= nil and isEventApplyAura)
    end
    if self.TraitInspectorEventAuraDurationInput then
        self.TraitInspectorEventAuraDurationInput:SetText(tostring(eventEffect and eventEffect.duration or 12))
        setTextElementEnabled(self.TraitInspectorEventAuraDurationInput, eventEffect ~= nil and isEventApplyAura)
    end
    if self.TraitInspectorEventBasePowerInput then
        self.TraitInspectorEventBasePowerInput:SetText(tostring(eventEffect and eventEffect.basePower or 0))
        setTextElementEnabled(self.TraitInspectorEventBasePowerInput, eventEffect ~= nil and isEventApplyAura)
    end
    if self.TraitInspectorEventResourceDropdown then
        self.TraitInspectorEventResourceDropdown:SetItems(self:BuildSpellInspectorResourcesAcrossDatasets())
        self.TraitInspectorEventResourceDropdown:SetSelectedValue(eventEffect and eventEffect.resourceRef or "", true)
        setDropdownEnabled(self.TraitInspectorEventResourceDropdown, eventEffect ~= nil and isEventResource)
    end
    if self.TraitInspectorEventResourceAmountInput then
        self.TraitInspectorEventResourceAmountInput:SetText(tostring(eventEffect and eventEffect.amount or 0))
        setTextElementEnabled(self.TraitInspectorEventResourceAmountInput, eventEffect ~= nil and isEventResource)
    end
    if self.TraitInspectorEventResourceAmountModeDropdown then
        self.TraitInspectorEventResourceAmountModeDropdown:SetSelectedValue(eventEffect and eventEffect.amountMode or "flat", true)
        setDropdownEnabled(self.TraitInspectorEventResourceAmountModeDropdown, eventEffect ~= nil and isEventResource)
    end
    if self.TraitInspectorEventScalingScroll and self.TraitInspectorEventScalingScroll.SetItems then
        self:RefreshTraitInspectorEventScalingTable()
    end
    if self.TraitInspectorPendingEventScalingStatDropdown then
        self.TraitInspectorPendingEventScalingStatDropdown:SetItems(self:BuildSpellInspectorStatsAcrossDatasets())
        setDropdownEnabled(self.TraitInspectorPendingEventScalingStatDropdown, eventEffect ~= nil and supportsEventScaling)
    end
    if self.TraitInspectorPendingEventScalingCoefficientInput then
        setTextElementEnabled(self.TraitInspectorPendingEventScalingCoefficientInput, eventEffect ~= nil and supportsEventScaling)
    end
    if self.TraitInspectorAddEventScalingButton then
        self.TraitInspectorAddEventScalingButton:SetEnabled(eventEffect ~= nil and supportsEventScaling)
    end
    if self.TraitInspectorDeleteEventScalingButton then
        self.TraitInspectorDeleteEventScalingButton:SetEnabled(eventEffect ~= nil and supportsEventScaling and tonumber(self.SelectedTraitEventScalingIndex) ~= nil)
    end

    self:RefreshTraitInspectorStatTable()

    self._refreshingTraitInspector = false

    setGroupVisible(self.TraitInspectorCombatEventGroup, traitEvent ~= nil)
    setGroupVisible(self.TraitInspectorTriggerTargetGroup, traitEvent ~= nil and hasTraitEventTrigger)
    setGroupVisible(self.TraitInspectorEventChanceGroup, traitEvent ~= nil)
    setGroupVisible(self.TraitInspectorEventEffectTypeGroup, eventEffect ~= nil)
    setGroupVisible(self.TraitInspectorEventBaseAmountGroup, eventEffect ~= nil and (isEventDamage or isEventHeal))
    setGroupVisible(self.TraitInspectorEventAmountModeGroup, eventEffect ~= nil and (isEventDamage or isEventHeal))
    setGroupVisible(self.TraitInspectorEventDamageSchoolsGroup, eventEffect ~= nil and isEventDamage)
    setGroupVisible(self.TraitInspectorEventAuraGroup, eventEffect ~= nil and (isEventApplyAura or eventEffectType == "remove_aura"))
    setGroupVisible(self.TraitInspectorEventAuraStacksGroup, eventEffect ~= nil and (isEventApplyAura or eventEffectType == "remove_aura"))
    setGroupVisible(self.TraitInspectorEventAuraDurationGroup, eventEffect ~= nil and isEventApplyAura)
    setGroupVisible(self.TraitInspectorEventBasePowerGroup, eventEffect ~= nil and isEventApplyAura)
    setGroupVisible(self.TraitInspectorEventResourceGroup, eventEffect ~= nil and isEventResource)
    setGroupVisible(self.TraitInspectorEventResourceAmountGroup, eventEffect ~= nil and isEventResource)
    setGroupVisible(self.TraitInspectorEventResourceAmountModeGroup, eventEffect ~= nil and isEventResource)
    setGroupVisible(self.TraitInspectorEventScalingGroup, eventEffect ~= nil and supportsEventScaling)
    if self.TraitInspectorEventsRoot and self.TraitInspectorEventsRoot.RefreshLayout then
        self.TraitInspectorEventsRoot:RefreshLayout()
    end
    if self.RefreshTraitInspectorEventsScrollBounds then
        self:RefreshTraitInspectorEventsScrollBounds()
    end

    if self.TraitInspectorEmptyText then
        self.TraitInspectorEmptyText:SetText(hasTrait and "Edit the selected trait here." or "Select a trait to inspect it.")
    end

    if hasTrait and self.ActiveTraitInspectorTabKey == nil then
        self:SetTraitInspectorTab("general")
    else
        self:RefreshTraitInspectorPageSelector()
    end
end
