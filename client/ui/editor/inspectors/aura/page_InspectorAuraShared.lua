local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local AuraClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Aura or nil
local Combat = Addon.Client and Addon.Client.Combat or {}

DataEditor.AuraInspectorSidePadding = DataEditor.AuraInspectorSidePadding or 8
DataEditor.AuraInspectorControlHeight = DataEditor.AuraInspectorControlHeight or 20
DataEditor.AuraInspectorFieldWidth = DataEditor.AuraInspectorFieldWidth or 236

local STACK_BEHAVIOR_ITEMS = {
    { label = "Refresh Duration", value = "refresh_duration" },
    { label = "Independent Duration", value = "independent_duration" },
}

local EFFECT_TYPE_ITEMS = {
    { label = "Damage", value = "damage" },
    { label = "Heal", value = "heal" },
    { label = "Stat", value = "stat" },
    { label = "Skill", value = "skill" },
    { label = "Control", value = "control" },
    { label = "Apply Aura", value = "apply_aura" },
    { label = "Resource", value = "resource" },
}

local EVENT_EFFECT_TYPE_ITEMS = {
    { label = "Damage", value = "damage" },
    { label = "Heal", value = "heal" },
    { label = "Apply Aura", value = "apply_aura" },
    { label = "Remove Aura", value = "remove_aura" },
    { label = "Resource", value = "resource" },
}

local OPERATION_ITEMS = {
    { label = "Flat", value = "flat" },
    { label = "Percent", value = "percent" },
}

local AMOUNT_MODE_ITEMS = {
    { label = "Flat", value = "flat" },
    { label = "% Base", value = "base_percent" },
    { label = "% Max", value = "max_percent" },
}

local TRIGGER_TARGET_ITEMS = {
    { label = "Event Other", value = "event_other" },
    { label = "Event Source", value = "event_source" },
    { label = "Aura Caster", value = "aura_caster" },
    { label = "Aura Target", value = "aura_target" },
}

local AMOUNT_MODE_ITEMS = {
    { label = "Flat", value = "flat" },
    { label = "% Base", value = "base_percent" },
    { label = "% Max", value = "max_percent" },
}

local AURA_INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "effects", label = "Effects" },
    { key = "events", label = "Events" },
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

local function normalizeScalingEntries(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local statRef = type(entry) == "table" and tostring(entry.statRef or "") or ""
        if statRef ~= "" then
            normalized[#normalized + 1] = {
                statRef = statRef,
                coefficient = tonumber(entry.coefficient) or 0,
            }
        end
    end

    return normalized
end

local function normalizeCombatEventId(value)
    local combatEventId = string.lower(tostring(value or ""))
    if combatEventId == "" then
        return nil
    end

    return combatEventId
end

local function normalizeTriggerTarget(value)
    local triggerTarget = string.lower(tostring(value or ""))
    if triggerTarget == "event_source"
        or triggerTarget == "aura_caster"
        or triggerTarget == "aura_target"
    then
        return triggerTarget
    end

    return "event_other"
end

local function normalizeChancePercent(value)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return 100
    end

    return math.max(0, math.min(100, numericValue))
end

local function resolveItemLabel(items, value, fallback)
    local normalizedValue = tostring(value or "")
    for index = 1, #(items or {}) do
        local item = items[index]
        if tostring(item and item.value or "") == normalizedValue then
            return tostring(item and item.label or fallback or normalizedValue)
        end
    end

    return tostring(fallback or normalizedValue)
end

function DataEditor:GetSelectedAuraAndDataset()
    return self:GetSelectedDataset(), self:GetSelectedAura()
end

function DataEditor:SetAuraInspectorDropdownEnabled(dropdown, enabled)
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

function DataEditor:SetAuraInspectorTextElementEnabled(element, enabled)
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

function DataEditor:SetAuraInspectorCheckboxEnabled(checkbox, enabled)
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

function DataEditor:SetAuraInspectorGroupVisible(group, visible)
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

function DataEditor:BuildAuraInspectorLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or self.AuraInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
    })
end

function DataEditor:CreateAuraInspectorCheckbox(parent, name, text, checked, onValueChanged)
    local checkbox = UI.Checkbox:New({
        name = name,
        width = self.AuraInspectorFieldWidth,
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

function DataEditor:NormalizeAuraDefinition(aura)
    if AuraClass and AuraClass.New and AuraClass.ToTable then
        return AuraClass.ToTable(AuraClass:New(aura))
    end

    return aura or {}
end

function DataEditor:CommitSelectedAura(mutate)
    local dataset, aura = self:GetSelectedAuraAndDataset()
    if not dataset or not aura or type(mutate) ~= "function" then
        return
    end

    local before = self:DeepCopyValue(aura)
    mutate(aura, dataset)
    applyTable(aura, self:NormalizeAuraDefinition(aura))

    if self:DeepEqualValues(before, aura) then
        return
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "auras")
end

function DataEditor:GetAuraInspectorStackBehaviorItems()
    return STACK_BEHAVIOR_ITEMS
end

function DataEditor:GetAuraInspectorEffectTypeItems()
    return EFFECT_TYPE_ITEMS
end

function DataEditor:GetAuraInspectorEventEffectTypeItems()
    return EVENT_EFFECT_TYPE_ITEMS
end

function DataEditor:GetAuraInspectorAmountModeItems()
    return AMOUNT_MODE_ITEMS
end

function DataEditor:GetAuraInspectorOperationItems()
    return OPERATION_ITEMS
end

function DataEditor:GetAuraInspectorCombatEventItems()
    local events = Combat.Events or nil
    if type(events) ~= "table" or type(events.GetItems) ~= "function" then
        return {
            { label = "None", value = "" },
        }
    end

    local items = {
        { label = "None", value = "" },
    }
    local definitions = events:GetItems()
    for index = 1, #definitions do
        local definition = definitions[index]
        items[#items + 1] = {
            label = tostring(definition and definition.label or ""),
            value = tostring(definition and definition.id or ""),
        }
    end

    return items
end

function DataEditor:GetAuraInspectorTriggerTargetItems()
    return TRIGGER_TARGET_ITEMS
end

function DataEditor:GetAuraInspectorPageDefinitions()
    return AURA_INSPECTOR_PAGE_DEFINITIONS
end

function DataEditor:GetAuraInspectorPageIndexByKey(key)
    local pages = self:GetAuraInspectorPageDefinitions()
    for index = 1, #pages do
        if pages[index].key == key then
            return index
        end
    end

    return 1
end

function DataEditor:BuildAuraInspectorPageSelectorItems()
    local items = {}
    local pages = self:GetAuraInspectorPageDefinitions()

    for index = 1, #pages do
        items[#items + 1] = {
            label = pages[index].label,
            value = pages[index].key,
        }
    end

    return items
end

function DataEditor:RefreshAuraInspectorPageSelector()
    local pages = self:GetAuraInspectorPageDefinitions()
    local pageCount = #pages
    local activeIndex = math.max(1, math.min(self.ActiveAuraInspectorPageIndex or 1, pageCount))
    self.ActiveAuraInspectorPageIndex = activeIndex
    self.ActiveAuraInspectorTabKey = pages[activeIndex] and pages[activeIndex].key or "general"

    local activeDefinition = pages[activeIndex]
    if self.AuraInspectorPageDropdown and activeDefinition then
        self._refreshingAuraInspectorPageSelector = true
        self.AuraInspectorPageDropdown:SetSelectedValue(activeDefinition.key, true)
        self._refreshingAuraInspectorPageSelector = false
    end

    if self.AuraInspectorPreviousButton and self.AuraInspectorPreviousButton.SetEnabled then
        self.AuraInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end

    if self.AuraInspectorNextButton and self.AuraInspectorNextButton.SetEnabled then
        self.AuraInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetAuraInspectorTab(tabKey)
    local definitions = self:GetAuraInspectorPageDefinitions()
    self.ActiveAuraInspectorPageIndex = self:GetAuraInspectorPageIndexByKey(tabKey or "general")
    self.ActiveAuraInspectorTabKey = definitions[self.ActiveAuraInspectorPageIndex] and definitions[self.ActiveAuraInspectorPageIndex].key or "general"

    local pages = {
        general = self.AuraInspectorGeneralPage,
        effects = self.AuraInspectorEffectsPage,
        events = self.AuraInspectorEventsPage,
    }

    for key, page in pairs(pages) do
        if page then
            if key == self.ActiveAuraInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    self:RefreshAuraInspectorPageSelector()
end

function DataEditor:NormalizeAuraInspectorEffect(effect)
    if type(effect) ~= "table" then
        return
    end

    local effectType = tostring(effect.type or "damage")
    effect.statScaling = normalizeScalingEntries(effect.statScaling)

    if effectType == "heal" then
        effect.type = "heal"
        effect.baseHealing = tonumber(effect.baseHealing) or 0
        effect.amountMode = tostring(effect.amountMode or "flat")
        if effect.amountMode ~= "base_percent" and effect.amountMode ~= "max_percent" then
            effect.amountMode = "flat"
        end
        effect.baseDamage = nil
        effect.statRef = nil
        effect.operation = nil
        effect.baseAmount = nil
        effect.skillRef = nil
        effect.cancelOnDamage = nil
        effect.preventCasting = nil
        effect.movementRangeOverride = nil
        effect.forceAutoHitAgainstTarget = nil
        effect.auraRef = nil
        effect.stacks = nil
        effect.duration = nil
        effect.basePower = nil
        effect.resourceRef = nil
        effect.amount = nil
        return
    end

    if effectType == "stat" then
        effect.type = "stat"
        effect.statRef = effect.statRef ~= nil and tostring(effect.statRef) ~= "" and tostring(effect.statRef) or nil
        effect.operation = tostring(effect.operation or "flat") == "percent" and "percent" or "flat"
        effect.baseAmount = tonumber(effect.baseAmount) or 0
        effect.baseDamage = nil
        effect.baseHealing = nil
        effect.skillRef = nil
        effect.cancelOnDamage = nil
        effect.preventCasting = nil
        effect.movementRangeOverride = nil
        effect.forceAutoHitAgainstTarget = nil
        effect.auraRef = nil
        effect.stacks = nil
        effect.duration = nil
        effect.basePower = nil
        effect.resourceRef = nil
        effect.amount = nil
        return
    end

    if effectType == "skill" then
        effect.type = "skill"
        effect.skillRef = effect.skillRef ~= nil and tostring(effect.skillRef) ~= "" and tostring(effect.skillRef) or nil
        effect.baseAmount = tonumber(effect.baseAmount) or 0
        effect.statScaling = nil
        effect.damageSchoolRefs = nil
        effect.statRef = nil
        effect.operation = nil
        effect.baseDamage = nil
        effect.baseHealing = nil
        effect.cancelOnDamage = nil
        effect.preventCasting = nil
        effect.movementRangeOverride = nil
        effect.forceAutoHitAgainstTarget = nil
        effect.auraRef = nil
        effect.stacks = nil
        effect.duration = nil
        effect.basePower = nil
        effect.resourceRef = nil
        effect.amount = nil
        return
    end

    if effectType == "control" then
        effect.type = "control"
        effect.cancelOnDamage = effect.cancelOnDamage == true
        effect.preventCasting = effect.preventCasting == true
        effect.movementRangeOverride = effect.movementRangeOverride ~= nil and tonumber(effect.movementRangeOverride) or nil
        effect.forceAutoHitAgainstTarget = effect.forceAutoHitAgainstTarget == true
        effect.statScaling = nil
        effect.damageSchoolRefs = nil
        effect.statRef = nil
        effect.operation = nil
        effect.skillRef = nil
        effect.baseAmount = nil
        effect.baseDamage = nil
        effect.baseHealing = nil
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
        effect.auraRef = effect.auraRef ~= nil and tostring(effect.auraRef) ~= "" and tostring(effect.auraRef) or nil
        effect.stacks = math.max(1, math.floor(tonumber(effect.stacks) or tonumber(effect.auraStacks) or 1))
        effect.duration = math.max(1, math.floor(tonumber(effect.duration) or tonumber(effect.turns) or 12))
        effect.basePower = tonumber(effect.basePower) or tonumber(effect.powerLevel) or 0
        effect.baseDamage = nil
        effect.baseHealing = nil
        effect.statScaling = nil
        effect.damageSchoolRefs = nil
        effect.statRef = nil
        effect.operation = nil
        effect.skillRef = nil
        effect.baseAmount = nil
        effect.cancelOnDamage = nil
        effect.preventCasting = nil
        effect.movementRangeOverride = nil
        effect.forceAutoHitAgainstTarget = nil
        effect.resourceRef = nil
        effect.amount = nil
        return
    end

    if effectType == "resource" then
        effect.type = "resource"
        effect.resourceRef = effect.resourceRef ~= nil and tostring(effect.resourceRef) ~= "" and tostring(effect.resourceRef) or nil
        effect.amount = tonumber(effect.amount) or tonumber(effect.baseAmount) or 0
        effect.amountMode = tostring(effect.amountMode or "flat")
        if effect.amountMode ~= "base_percent" and effect.amountMode ~= "max_percent" then
            effect.amountMode = "flat"
        end
        effect.baseDamage = nil
        effect.baseHealing = nil
        effect.statScaling = nil
        effect.damageSchoolRefs = nil
        effect.statRef = nil
        effect.operation = nil
        effect.skillRef = nil
        effect.baseAmount = nil
        effect.cancelOnDamage = nil
        effect.preventCasting = nil
        effect.movementRangeOverride = nil
        effect.forceAutoHitAgainstTarget = nil
        effect.auraRef = nil
        effect.stacks = nil
        effect.duration = nil
        effect.basePower = nil
        return
    end

    effect.type = "damage"
    effect.baseDamage = tonumber(effect.baseDamage) or 0
    effect.amountMode = tostring(effect.amountMode or "flat")
    if effect.amountMode ~= "base_percent" and effect.amountMode ~= "max_percent" then
        effect.amountMode = "flat"
    end
    effect.damageSchoolRefs = effect.damageSchoolRefs or {}
    effect.baseHealing = nil
    effect.statRef = nil
    effect.operation = nil
    effect.baseAmount = nil
    effect.skillRef = nil
    effect.cancelOnDamage = nil
    effect.preventCasting = nil
    effect.movementRangeOverride = nil
    effect.forceAutoHitAgainstTarget = nil
    effect.auraRef = nil
    effect.stacks = nil
    effect.duration = nil
    effect.basePower = nil
    effect.resourceRef = nil
    effect.amount = nil
end

function DataEditor:NormalizeAuraInspectorEventEffect(effect)
    if type(effect) ~= "table" then
        return
    end

    local effectType = tostring(effect.type or "damage")
    effect.statScaling = normalizeScalingEntries(effect.statScaling)

    if effectType == "heal" then
        effect.type = "heal"
        effect.baseHealing = tonumber(effect.baseHealing) or 0
        effect.amountMode = tostring(effect.amountMode or "flat")
        if effect.amountMode ~= "base_percent" and effect.amountMode ~= "max_percent" then
            effect.amountMode = "flat"
        end
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
        effect.auraRef = effect.auraRef ~= nil and tostring(effect.auraRef) ~= "" and tostring(effect.auraRef) or nil
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
        effect.auraRef = effect.auraRef ~= nil and tostring(effect.auraRef) ~= "" and tostring(effect.auraRef) or nil
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
        effect.resourceRef = effect.resourceRef ~= nil and tostring(effect.resourceRef) ~= "" and tostring(effect.resourceRef) or nil
        effect.amount = tonumber(effect.amount) or tonumber(effect.baseAmount) or 0
        effect.amountMode = tostring(effect.amountMode or "flat")
        if effect.amountMode ~= "base_percent" and effect.amountMode ~= "max_percent" then
            effect.amountMode = "flat"
        end
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
    effect.baseDamage = tonumber(effect.baseDamage) or 0
    effect.amountMode = tostring(effect.amountMode or "flat")
    if effect.amountMode ~= "base_percent" and effect.amountMode ~= "max_percent" then
        effect.amountMode = "flat"
    end
    effect.damageSchoolRefs = effect.damageSchoolRefs or {}
    effect.auraRef = nil
    effect.stacks = nil
    effect.duration = nil
    effect.basePower = nil
    effect.resourceRef = nil
    effect.amount = nil
end

function DataEditor:NormalizeAuraInspectorEvent(auraEvent)
    if type(auraEvent) ~= "table" then
        return
    end

    auraEvent.combatEventId = normalizeCombatEventId(auraEvent.combatEventId)
    auraEvent.triggerTarget = auraEvent.combatEventId and normalizeTriggerTarget(auraEvent.triggerTarget) or nil
    auraEvent.chance = normalizeChancePercent(auraEvent.chance)
    auraEvent.effects = auraEvent.effects or {}

    for index = #auraEvent.effects, 1, -1 do
        local effect = auraEvent.effects[index]
        if type(effect) ~= "table" then
            table.remove(auraEvent.effects, index)
        else
            self:NormalizeAuraInspectorEventEffect(effect)
        end
    end
end

function DataEditor:SetSelectedAuraInspectorEffectIndex(index)
    local _, aura = self:GetSelectedAuraAndDataset()
    local effects = aura and aura.effects or {}
    index = tonumber(index)

    if not index or not effects[index] then
        self.SelectedAuraEffectIndex = nil
    else
        self.SelectedAuraEffectIndex = index
    end
end

function DataEditor:GetSelectedAuraInspectorEffect()
    local _, aura = self:GetSelectedAuraAndDataset()
    local effects = aura and aura.effects or {}
    local index = tonumber(self.SelectedAuraEffectIndex)
    if not index or not effects[index] then
        return nil, nil
    end

    return effects[index], index
end

function DataEditor:CommitSelectedAuraInspectorEffect(mutate)
    local effect = self:GetSelectedAuraInspectorEffect()
    if type(effect) ~= "table" or type(mutate) ~= "function" then
        return
    end

    self:CommitSelectedAura(function(aura)
        mutate(effect, aura)
    end)
end

function DataEditor:AddAuraEffect()
    self:CommitSelectedAura(function(aura)
        aura.effects = aura.effects or {}
        aura.effects[#aura.effects + 1] = {
            type = "damage",
            baseDamage = 0,
            damageSchoolRefs = {},
            statScaling = {},
        }
        self.SelectedAuraEffectIndex = #aura.effects
        self.SelectedAuraScalingIndex = nil
    end)
end

function DataEditor:RemoveSelectedAuraEffect()
    local _, effectIndex = self:GetSelectedAuraInspectorEffect()
    if not effectIndex then
        return
    end

    self:CommitSelectedAura(function(aura)
        table.remove(aura.effects or {}, effectIndex)
        if #(aura.effects or {}) > 0 then
            self.SelectedAuraEffectIndex = math.min(effectIndex, #aura.effects)
        else
            self.SelectedAuraEffectIndex = nil
        end
        self.SelectedAuraScalingIndex = nil
    end)
end

function DataEditor:BuildAuraInspectorEffectRows(aura)
    local rows = {}

    for index = 1, #(aura and aura.effects or {}) do
        local effect = aura.effects[index]
        local effectType = tostring(effect and effect.type or "damage")
        local statusText = tostring(tonumber(effect and effect.baseDamage) or 0)
        local detailText = ""

        if effectType == "heal" then
            statusText = tostring(tonumber(effect and effect.baseHealing) or 0)
        elseif effectType == "stat" then
            statusText = tostring(tonumber(effect and effect.baseAmount) or 0)
            detailText = self:ResolveSpellInspectorReferenceLabel("stats", effect and effect.statRef or "")
        elseif effectType == "skill" then
            statusText = tostring(tonumber(effect and effect.baseAmount) or 0)
            detailText = self:ResolveSpellInspectorReferenceLabel("skills", effect and effect.skillRef or "")
        elseif effectType == "apply_aura" then
            statusText = tostring(tonumber(effect and effect.stacks) or 1)
            detailText = self:ResolveSpellInspectorReferenceLabel("auras", effect and effect.auraRef or "")
        elseif effectType == "resource" then
            statusText = tostring(tonumber(effect and effect.amount) or 0)
            detailText = self:ResolveSpellInspectorReferenceLabel("resources", effect and effect.resourceRef or "")
        elseif effectType == "control" then
            statusText = ""
            local controlParts = {}
            if effect and effect.cancelOnDamage == true then
                controlParts[#controlParts + 1] = "cancel"
            end
            if effect and effect.preventCasting == true then
                controlParts[#controlParts + 1] = "silence"
            end
            if tonumber(effect and effect.movementRangeOverride) == 0 then
                controlParts[#controlParts + 1] = "root"
            end
            if effect and effect.forceAutoHitAgainstTarget == true then
                controlParts[#controlParts + 1] = "auto-hit"
            end
            detailText = table.concat(controlParts, ", ")
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

function DataEditor:RefreshAuraInspectorEffectsTable()
    local _, aura = self:GetSelectedAuraAndDataset()
    local rows = self:BuildAuraInspectorEffectRows(aura)

    if self.AuraInspectorEffectsScroll and self.AuraInspectorEffectsScroll.SetItems then
        self.AuraInspectorEffectsScroll:SetItems(rows)
    end

    local selectedIndex = tonumber(self.SelectedAuraEffectIndex)
    if not selectedIndex or not rows[selectedIndex] then
        self.SelectedAuraEffectIndex = rows[1] and 1 or nil
    end
end

function DataEditor:BuildAuraInspectorScalingRows(effect)
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

function DataEditor:RefreshAuraInspectorScalingTable()
    local effect = self:GetSelectedAuraInspectorEffect()
    local rows = self:BuildAuraInspectorScalingRows(effect)

    if self.AuraInspectorScalingScroll and self.AuraInspectorScalingScroll.SetItems then
        self.AuraInspectorScalingScroll:SetItems(rows)
    end

    local selectedIndex = tonumber(self.SelectedAuraScalingIndex)
    if not selectedIndex or not rows[selectedIndex] then
        self.SelectedAuraScalingIndex = rows[1] and 1 or nil
    end
end

function DataEditor:GetDefaultAuraInspectorCombatEventId()
    local items = self:GetAuraInspectorCombatEventItems()
    for index = 1, #items do
        local value = tostring(items[index].value or "")
        if value ~= "" then
            return value
        end
    end

    return nil
end

function DataEditor:SetSelectedAuraInspectorEventIndex(index)
    local _, aura = self:GetSelectedAuraAndDataset()
    local events = aura and aura.events or {}
    index = tonumber(index)

    if not index or not events[index] then
        self.SelectedAuraEventIndex = nil
    else
        self.SelectedAuraEventIndex = index
    end
end

function DataEditor:GetSelectedAuraInspectorEvent()
    local _, aura = self:GetSelectedAuraAndDataset()
    local events = aura and aura.events or {}
    local index = tonumber(self.SelectedAuraEventIndex)
    if not index or not events[index] then
        return nil, nil
    end

    return events[index], index
end

function DataEditor:CommitSelectedAuraInspectorEvent(mutate)
    local auraEvent = self:GetSelectedAuraInspectorEvent()
    if type(auraEvent) ~= "table" or type(mutate) ~= "function" then
        return
    end

    self:CommitSelectedAura(function(aura)
        mutate(auraEvent, aura)
    end)
end

function DataEditor:AddAuraEvent()
    self:CommitSelectedAura(function(aura)
        aura.events = aura.events or {}
        aura.events[#aura.events + 1] = {
            combatEventId = self:GetDefaultAuraInspectorCombatEventId(),
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
        self.SelectedAuraEventIndex = #aura.events
        self.SelectedAuraEventEffectIndex = 1
        self.SelectedAuraEventScalingIndex = nil
    end)
end

function DataEditor:RemoveSelectedAuraEvent()
    local _, eventIndex = self:GetSelectedAuraInspectorEvent()
    if not eventIndex then
        return
    end

    self:CommitSelectedAura(function(aura)
        table.remove(aura.events or {}, eventIndex)
        if #(aura.events or {}) > 0 then
            self.SelectedAuraEventIndex = math.min(eventIndex, #aura.events)
        else
            self.SelectedAuraEventIndex = nil
        end
        self.SelectedAuraEventEffectIndex = nil
        self.SelectedAuraEventScalingIndex = nil
    end)
end

function DataEditor:BuildAuraInspectorEventRows(aura)
    local rows = {}

    for index = 1, #(aura and aura.events or {}) do
        local auraEvent = aura.events[index]
        local eventLabel = resolveItemLabel(self:GetAuraInspectorCombatEventItems(), auraEvent and auraEvent.combatEventId or "", "None")
        local triggerLabel = auraEvent and auraEvent.combatEventId and resolveItemLabel(
            self:GetAuraInspectorTriggerTargetItems(),
            auraEvent.triggerTarget,
            "Event Other"
        ) or ""

        rows[#rows + 1] = {
            rowIndex = index,
            title = eventLabel,
            detail = triggerLabel,
            statusText = tostring(#(auraEvent and auraEvent.effects or {})),
        }
    end

    return rows
end

function DataEditor:RefreshAuraInspectorEventsTable()
    local _, aura = self:GetSelectedAuraAndDataset()
    local rows = self:BuildAuraInspectorEventRows(aura)

    if self.AuraInspectorEventsScroll and self.AuraInspectorEventsScroll.SetItems then
        self.AuraInspectorEventsScroll:SetItems(rows)
    end

    local selectedIndex = tonumber(self.SelectedAuraEventIndex)
    if not selectedIndex or not rows[selectedIndex] then
        self.SelectedAuraEventIndex = rows[1] and 1 or nil
    end
end

function DataEditor:SetSelectedAuraInspectorEventEffectIndex(index)
    local auraEvent = self:GetSelectedAuraInspectorEvent()
    local effects = auraEvent and auraEvent.effects or {}
    index = tonumber(index)

    if not index or not effects[index] then
        self.SelectedAuraEventEffectIndex = nil
    else
        self.SelectedAuraEventEffectIndex = index
    end
end

function DataEditor:GetSelectedAuraInspectorEventEffect()
    local auraEvent = self:GetSelectedAuraInspectorEvent()
    local effects = auraEvent and auraEvent.effects or {}
    local index = tonumber(self.SelectedAuraEventEffectIndex)
    if not index or not effects[index] then
        return nil, nil
    end

    return effects[index], index
end

function DataEditor:CommitSelectedAuraInspectorEventEffect(mutate)
    local effect = self:GetSelectedAuraInspectorEventEffect()
    if type(effect) ~= "table" or type(mutate) ~= "function" then
        return
    end

    self:CommitSelectedAura(function(aura)
        mutate(effect, aura)
    end)
end

function DataEditor:AddAuraEventEffect()
    local auraEvent = self:GetSelectedAuraInspectorEvent()
    if not auraEvent then
        return
    end

    self:CommitSelectedAura(function()
        auraEvent.effects = auraEvent.effects or {}
        auraEvent.effects[#auraEvent.effects + 1] = {
            type = "damage",
            baseDamage = 0,
            damageSchoolRefs = {},
            statScaling = {},
        }
        self.SelectedAuraEventEffectIndex = #auraEvent.effects
        self.SelectedAuraEventScalingIndex = nil
    end)
end

function DataEditor:RemoveSelectedAuraEventEffect()
    local auraEvent = self:GetSelectedAuraInspectorEvent()
    local _, effectIndex = self:GetSelectedAuraInspectorEventEffect()
    if not auraEvent or not effectIndex then
        return
    end

    self:CommitSelectedAura(function()
        table.remove(auraEvent.effects or {}, effectIndex)
        if #(auraEvent.effects or {}) > 0 then
            self.SelectedAuraEventEffectIndex = math.min(effectIndex, #auraEvent.effects)
        else
            self.SelectedAuraEventEffectIndex = nil
        end
        self.SelectedAuraEventScalingIndex = nil
    end)
end

function DataEditor:BuildAuraInspectorEventEffectRows(auraEvent)
    local rows = {}

    for index = 1, #(auraEvent and auraEvent.effects or {}) do
        local effect = auraEvent.effects[index]
        local effectType = tostring(effect and effect.type or "damage")
        local statusText = tostring(tonumber(effect and effect.baseDamage) or 0)
        local detailText = ""
        if effectType == "heal" then
            statusText = tostring(tonumber(effect and effect.baseHealing) or 0)
        elseif effectType == "apply_aura" or effectType == "remove_aura" then
            statusText = tostring(tonumber(effect and effect.stacks) or 1)
        elseif effectType == "resource" then
            statusText = tostring(tonumber(effect and effect.amount) or 0)
        end
        if effectType == "damage" then
            detailText = UI.Utils.JoinCommaSeparatedList(effect and effect.damageSchoolRefs or nil)
        elseif effectType == "apply_aura" or effectType == "remove_aura" then
            detailText = self:ResolveSpellInspectorReferenceLabel("auras", effect and effect.auraRef or "")
        elseif effectType == "resource" then
            detailText = self:ResolveSpellInspectorReferenceLabel("resources", effect and effect.resourceRef or "")
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

function DataEditor:RefreshAuraInspectorEventEffectsTable()
    local auraEvent = self:GetSelectedAuraInspectorEvent()
    local rows = self:BuildAuraInspectorEventEffectRows(auraEvent)

    if self.AuraInspectorEventEffectsScroll and self.AuraInspectorEventEffectsScroll.SetItems then
        self.AuraInspectorEventEffectsScroll:SetItems(rows)
    end

    local selectedIndex = tonumber(self.SelectedAuraEventEffectIndex)
    if not selectedIndex or not rows[selectedIndex] then
        self.SelectedAuraEventEffectIndex = rows[1] and 1 or nil
    end
end

function DataEditor:BuildAuraInspectorEventScalingRows(effect)
    return self:BuildAuraInspectorScalingRows(effect)
end

function DataEditor:RefreshAuraInspectorEventScalingTable()
    local effect = self:GetSelectedAuraInspectorEventEffect()
    local rows = self:BuildAuraInspectorEventScalingRows(effect)

    if self.AuraInspectorEventScalingScroll and self.AuraInspectorEventScalingScroll.SetItems then
        self.AuraInspectorEventScalingScroll:SetItems(rows)
    end

    local selectedIndex = tonumber(self.SelectedAuraEventScalingIndex)
    if not selectedIndex or not rows[selectedIndex] then
        self.SelectedAuraEventScalingIndex = rows[1] and 1 or nil
    end
end
