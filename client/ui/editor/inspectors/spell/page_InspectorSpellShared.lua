local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local Client = Addon.Client or {}
local Combat = Client.Combat or {}
local SpellClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Spell or nil

DataEditor.SpellInspectorSidePadding = DataEditor.SpellInspectorSidePadding or 8
DataEditor.SpellInspectorControlHeight = DataEditor.SpellInspectorControlHeight or 20
DataEditor.SpellInspectorFieldWidth = DataEditor.SpellInspectorFieldWidth or 236

local CAST_PHASE_ITEMS = {
    { label = "On Cast Start", value = "on_cast_start" },
    { label = "On Cast End", value = "on_cast_end" },
    { label = "On Channel Tick", value = "on_channel_tick" },
}

local EFFECT_TYPE_ITEMS = {
    { label = "Damage", value = "damage" },
    { label = "Heal", value = "heal" },
    { label = "Apply Aura", value = "apply_aura" },
    { label = "Remove Aura", value = "remove_aura" },
    { label = "Remove Aura by Tag", value = "remove_aura_by_tag" },
    { label = "Resource", value = "resource" },
    { label = "Interrupt", value = "interrupt" },
    { label = "Taunt", value = "taunt" },
    { label = "Revert", value = "revert" },
    { label = "Summon Pet", value = "summon_pet" },
}

local WEAPON_DAMAGE_MODE_ITEMS = {
    { label = "None", value = "none" },
    { label = "Main Hand", value = "main_hand" },
    { label = "Off Hand", value = "off_hand" },
    { label = "Both", value = "both" },
}

local HIT_TYPE_ITEMS = {
    { label = "Ability", value = "ability" },
    { label = "Auto", value = "auto" },
    { label = "Pet", value = "pet" },
}

local DAMAGE_TYPE_ITEMS = {
    { label = "Spell", value = "spell" },
    { label = "Melee", value = "melee" },
    { label = "Ranged", value = "ranged" },
}

local LEARN_MODE_ITEMS = {
    { label = "Always Learned", value = "always_learned" },
    { label = "Trainer", value = "trainer" },
    { label = "Book", value = "book" },
    { label = "Unavailable", value = "unavailable" },
}

local TARGET_TYPE_ITEMS = {
    { label = "Caster", value = "caster" },
    { label = "Single", value = "single" },
    { label = "Multi", value = "multi" },
    { label = "All Allies", value = "all_allies" },
    { label = "Raid Marker", value = "raid_marker" },
    { label = "Pet", value = "pet" },
    { label = "Last Attackers", value = "last_attackers" },
    { label = "Last Melee Attacker", value = "last_melee_attacker" },
}

local TARGET_DISPOSITION_ITEMS = {
    { label = "Ally", value = "ally" },
    { label = "Enemy", value = "enemy" },
    { label = "Any", value = "any" },
}

local AMOUNT_MODE_ITEMS = {
    { label = "Flat", value = "flat" },
    { label = "% Base", value = "base_percent" },
    { label = "% Max", value = "max_percent" },
}

local SPELL_INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "learning", label = "Learning" },
    { key = "casting", label = "Casting" },
    { key = "cooldown", label = "Cooldown" },
    { key = "cost", label = "Cost" },
    { key = "conditions", label = "Conditions" },
    { key = "components", label = "Components" },
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

function DataEditor:GetSelectedSpellAndDataset()
    return self:GetSelectedDataset(), self:GetSelectedSpell()
end

function DataEditor:SetSpellInspectorDropdownEnabled(dropdown, enabled)
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

function DataEditor:SetSpellInspectorTextElementEnabled(element, enabled)
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

function DataEditor:SetSpellInspectorCheckboxEnabled(checkbox, enabled)
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

function DataEditor:SetSpellInspectorSliderEnabled(slider, enabled)
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

function DataEditor:SetSpellInspectorGroupVisible(group, visible)
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

function DataEditor:BuildSpellInspectorLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or self.SpellInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
    })
end

function DataEditor:CreateSpellInspectorCheckbox(parent, name, text, checked, onValueChanged)
    local checkbox = UI.Checkbox:New({
        name = name,
        width = self.SpellInspectorFieldWidth,
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

function DataEditor:NormalizeSpellDefinition(spell)
    if SpellClass and SpellClass.New and SpellClass.ToTable then
        return SpellClass.ToTable(SpellClass:New(spell))
    end

    return spell or {}
end

function DataEditor:CommitSelectedSpell(mutate)
    local dataset, spell = self:GetSelectedSpellAndDataset()
    if not dataset or not spell or type(mutate) ~= "function" then
        return
    end

    local before = self:DeepCopyValue(spell)
    mutate(spell, dataset)
    applyTable(spell, self:NormalizeSpellDefinition(spell))

    if self:DeepEqualValues(before, spell) then
        return
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "spells")
end

function DataEditor:GetSpellInspectorCastPhaseItems()
    return CAST_PHASE_ITEMS
end

function DataEditor:GetSpellInspectorEffectTypeItems()
    return EFFECT_TYPE_ITEMS
end

function DataEditor:GetSpellInspectorWeaponDamageModeItems()
    return WEAPON_DAMAGE_MODE_ITEMS
end

function DataEditor:GetSpellInspectorHitTypeItems()
    return HIT_TYPE_ITEMS
end

function DataEditor:GetSpellInspectorDamageTypeItems()
    return DAMAGE_TYPE_ITEMS
end

function DataEditor:GetSpellInspectorLearnModeItems()
    return LEARN_MODE_ITEMS
end

function DataEditor:GetSpellInspectorTargetTypeItems()
    return TARGET_TYPE_ITEMS
end

function DataEditor:GetSpellInspectorTargetDispositionItems()
    return TARGET_DISPOSITION_ITEMS
end

function DataEditor:GetSpellInspectorAmountModeItems()
    return AMOUNT_MODE_ITEMS
end

function DataEditor:GetSpellInspectorEventItems()
    local events = Combat.Events or nil
    if type(events) ~= "table" or type(events.GetItems) ~= "function" then
        return {}
    end

    local items = {}
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

function DataEditor:BuildSpellInspectorDatasetItems()
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

function DataEditor:BuildSpellInspectorCollectionItems(collectionKey, datasetId)
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
                value = entry.id,
            }
        end
    end

    return items
end

function DataEditor:BuildSpellInspectorStatsAcrossDatasets()
    return self:BuildReferenceItemsAcrossDatasets("stats", { includeNone = true, noneLabel = "None" })
end

function DataEditor:BuildSpellInspectorResourcesAcrossDatasets()
    return self:BuildReferenceItemsAcrossDatasets("resources", { includeNone = true, noneLabel = "None" })
end

function DataEditor:BuildSpellInspectorSkillsAcrossDatasets()
    return self:BuildReferenceItemsAcrossDatasets("skills", { includeNone = true, noneLabel = "None" })
end

function DataEditor:BuildSpellInspectorDamageSchoolsAcrossDatasets()
    return self:BuildReferenceItemsAcrossDatasets("damageSchools", { includeNone = false })
end

function DataEditor:BuildSpellInspectorUnitsAcrossDatasets()
    return self:BuildReferenceItemsAcrossDatasets("units", { includeNone = true, noneLabel = "None" })
end

function DataEditor:BuildSpellInspectorAurasAcrossDatasets()
    return self:BuildReferenceItemsAcrossDatasets("auras", { includeNone = true, noneLabel = "None" })
end

function DataEditor:ResolveSpellInspectorReferenceLabel(collectionKey, reference)
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

function DataEditor:GetSpellInspectorPageDefinitions()
    return SPELL_INSPECTOR_PAGE_DEFINITIONS
end

function DataEditor:GetSpellInspectorPageIndexByKey(key)
    local pages = self:GetSpellInspectorPageDefinitions()
    for index = 1, #pages do
        if pages[index].key == key then
            return index
        end
    end

    return 1
end

function DataEditor:BuildSpellInspectorPageSelectorItems()
    local items = {}
    local pages = self:GetSpellInspectorPageDefinitions()

    for index = 1, #pages do
        items[#items + 1] = {
            label = pages[index].label,
            value = pages[index].key,
        }
    end

    return items
end

function DataEditor:RefreshSpellInspectorPageSelector()
    local pages = self:GetSpellInspectorPageDefinitions()
    local pageCount = #pages
    local activeIndex = math.max(1, math.min(self.ActiveSpellInspectorPageIndex or 1, pageCount))
    self.ActiveSpellInspectorPageIndex = activeIndex
    self.ActiveSpellInspectorTabKey = pages[activeIndex] and pages[activeIndex].key or "general"

    local activeDefinition = pages[activeIndex]
    if self.SpellInspectorPageDropdown and activeDefinition then
        self._refreshingSpellInspectorPageSelector = true
        self.SpellInspectorPageDropdown:SetSelectedValue(activeDefinition.key, true)
        self._refreshingSpellInspectorPageSelector = false
    end

    if self.SpellInspectorPreviousButton and self.SpellInspectorPreviousButton.SetEnabled then
        self.SpellInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end

    if self.SpellInspectorNextButton and self.SpellInspectorNextButton.SetEnabled then
        self.SpellInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetSpellInspectorTab(tabKey)
    local pages = self:GetSpellInspectorPageDefinitions()
    self.ActiveSpellInspectorPageIndex = self:GetSpellInspectorPageIndexByKey(tabKey or "general")
    self.ActiveSpellInspectorTabKey = pages[self.ActiveSpellInspectorPageIndex] and pages[self.ActiveSpellInspectorPageIndex].key or "general"

    local pages = {
        general = self.SpellInspectorGeneralPage,
        learning = self.SpellInspectorLearningPage,
        casting = self.SpellInspectorCastingPage,
        cooldown = self.SpellInspectorCooldownPage,
        cost = self.SpellInspectorCostPage,
        conditions = self.SpellInspectorConditionsPage,
        components = self.SpellInspectorComponentsPage,
    }

    for key, page in pairs(pages) do
        if page then
            if key == self.ActiveSpellInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    self:RefreshSpellInspectorPageSelector()
end

function DataEditor:SetSelectedSpellInspectorComponentIndex(index)
    local _, spell = self:GetSelectedSpellAndDataset()
    local components = spell and spell.components or {}
    index = tonumber(index)

    if not index or not components[index] then
        self.SelectedSpellInspectorComponentIndex = nil
    else
        self.SelectedSpellInspectorComponentIndex = index
    end
end

function DataEditor:GetSelectedSpellInspectorComponent()
    local _, spell = self:GetSelectedSpellAndDataset()
    local components = spell and spell.components or {}
    local index = tonumber(self.SelectedSpellInspectorComponentIndex)
    if not index or not components[index] then
        return nil, nil
    end

    return components[index], index
end

function DataEditor:GetAutomaticSpellInspectorCastingGroupLabel(component)
    local target = component and component.target or nil
    if not target then
        return "No Target Group"
    end

    local targetType = tostring(target.type or "single")
    if targetType == "caster" then
        return "Caster"
    end
    if targetType == "pet" then
        return "Pet"
    end
    if targetType == "last_attackers" then
        return "Last Attackers"
    end
    if targetType == "last_melee_attacker" then
        return "Last Melee Attacker"
    end
    if targetType == "all_allies" then
        return "All Allies"
    end
    if targetType == "raid_marker" then
        return "Raid Marker"
    end

    local targetDisposition = tostring(target.targetDisposition or "enemy")
    local maxTargets = math.max(0, tonumber(target.maxTargets) or 0)
    local prefix = "Enemy"
    if targetDisposition == "ally" then
        prefix = "Ally"
    elseif targetDisposition == "any" then
        prefix = "Mixed"
    end
    if target.requiresTarget ~= true then
        prefix = "Optional " .. prefix
    end

    return prefix .. " " .. (maxTargets == 1 and "Target" or "Targets")
end

function DataEditor:FormatSpellInspectorTargetSummary(component)
    local target = component and component.target or nil
    local castingGroup = self:GetAutomaticSpellInspectorCastingGroupLabel(component)
    if not target then
        return ("%s / no target"):format(castingGroup)
    end

    local targetType = tostring(target.type or "single")
    local disposition = tostring(target.targetDisposition or "enemy")
    if targetType == "caster" then
        return ("%s / caster only"):format(castingGroup)
    end
    if targetType == "pet" then
        return ("%s / current pet"):format(castingGroup)
    end
    if targetType == "last_attackers" then
        return ("%s / most recent attacker"):format(castingGroup)
    end
    if targetType == "last_melee_attacker" then
        return ("%s / most recent melee attacker"):format(castingGroup)
    end
    if targetType == "all_allies" or targetType == "raid_marker" then
        return ("%s / %s / %s"):format(castingGroup, targetType, disposition)
    end

    local minTargets = math.max(0, tonumber(target.minTargets) or 0)
    local maxTargets = math.max(minTargets, tonumber(target.maxTargets) or minTargets)
    local requirementText = target.requiresTarget == false and "optional" or ("%d-%d"):format(minTargets, maxTargets)
    return ("%s / %s / %s / %s"):format(castingGroup, targetType, disposition, requirementText)
end
