local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Profile = Addon.Client.UI.Profile or {}

local ProfileUI = Addon.Client.UI.Profile
local UI = Addon.UI or {}
local TooltipBuilders = Addon.Client.UI and Addon.Client.UI.Tooltips or {}
local Combat = Addon.Client and Addon.Client.Combat or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Ruleset = Addon.Internal and Addon.Internal.Ruleset or {}
local ItemClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Item or nil

local EquipmentStatsPage = ProfileUI.EquipmentStatsPage or {}
ProfileUI.EquipmentStatsPage = EquipmentStatsPage

local SLOT_SIZE = 34
local SLOT_SPACING = 5
local MODEL_WIDTH = 170
local MODEL_HEIGHT = 228
local SLOT_COLUMN_TOP_OFFSET = -10
local BOTTOM_ROW_OFFSET_Y = 10
local MODEL_TOP_OFFSET_Y = -8
local STAT_HEADER_COLOR = { r = 1, g = 1, b = 1, a = 1 }
local STAT_TEXT_COLOR = { r = 1, g = 1, b = 1, a = 1 }
local HEALTH_TEXT_COLOR = { r = 1, g = 1, b = 1, a = 1 }
local EQUIPMENT_PANEL_WIDTH = 302
local STATS_PANEL_WIDTH = 150
local STATS_SCROLL_WIDTH = 146
local STAT_VISIBLE_ROWS = 16
local STAT_ROW_HEIGHT = 18
local STAT_ROW_SPACING = 2
local STAT_SCROLL_HEIGHT = (STAT_VISIBLE_ROWS * STAT_ROW_HEIGHT) + (math.max(0, STAT_VISIBLE_ROWS - 1) * STAT_ROW_SPACING)
local STAT_ENTRY_WIDTH = STATS_SCROLL_WIDTH - 14
local STAT_ENTRY_VALUE_WIDTH = 42
local HEALTH_ENTRY_WIDTH = 140
local HEALTH_ENTRY_VALUE_WIDTH = 56
local PROFILE_CONTROLS_ONE_ROW_HEIGHT = 34
local PROFILE_CONTROLS_TWO_ROW_HEIGHT = 70
local HEALTH_PANEL_HEIGHT = 36
local MOVEMENT_SPEED_PANEL_HEIGHT = 14
local STATS_SECTION_GAP_HEIGHT = 6
local ITEM_LEVEL_SUMMARY_HEIGHT = 14
local ITEM_LEVEL_SUMMARY_WIDTH = 196
local EQUIPMENT_SCOPE_BUTTON_SIZE = 20
local EQUIPMENT_SCOPE_BUTTON_GAP = 8
local EQUIPMENT_SCOPE_BUTTON_OFFSET_Y = 8
local EQUIPMENT_SCOPE_PANEL_PADDING_X = 6
local EQUIPMENT_SCOPE_PANEL_PADDING_Y = 4
local EQUIPMENT_SCOPE_ACTIVE_ALPHA = 1
local EQUIPMENT_SCOPE_INACTIVE_ALPHA = 0.5
local RESOURCE_SELECTOR_LABEL_WIDTH = 96
local RESOURCE_SELECTOR_DROPDOWN_WIDTH = 112
local RESOURCE_SELECTOR_DROPDOWN_HEIGHT = 18
local RESOURCE_SELECTOR_LEFT_X = 0
local RESOURCE_SELECTOR_RIGHT_X = 118
local LEVEL_SELECTOR_X = EQUIPMENT_PANEL_WIDTH - 48
local RESOURCE_SELECTOR_LABEL_Y = -2
local RESOURCE_SELECTOR_DROPDOWN_Y = -16
local PROFILE_CONTROL_LABEL_Y = -38
local PROFILE_CONTROL_INPUT_Y = -52
local LEVEL_CONTROL_WIDTH = 48
local PROFILE_SELECTOR_WIDTH = 146
local RACE_SELECTOR_X = 0
local CLASS_SELECTOR_X = EQUIPMENT_PANEL_WIDTH - PROFILE_SELECTOR_WIDTH
local HEALTH_PANEL_FRAME_LEVEL_OFFSET = 6
local HEALTH_ENTRY_FRAME_LEVEL_OFFSET = 8
local TRANSPARENT_PANEL_BACKGROUND = { r = 0, g = 0, b = 0, a = 0 }
local CHARACTER_SCOPE_TEXTURE = "Interface\\Icons\\Achievement_Character_Human_Male"
local MOUNT_SCOPE_TEXTURE = "Interface\\Icons\\Ability_Mount_RidingHorse"
local PET_SCOPE_TEXTURE = "Interface\\Icons\\Ability_Hunter_BeastCall"

local function ensureString(value, fallback)
    if value == nil or value == "" then
        return fallback or ""
    end

    return tostring(value)
end

local function getEquipmentScopeDisplayName(scope)
    local normalizedScope = tostring(scope or "character")
    if normalizedScope == "mount" then
        return "Mount"
    end
    if normalizedScope == "pet" then
        return "Pet"
    end

    return "Character"
end

local function buildMountItems()
    local items = {
        { label = "None", value = "" },
    }

    local mounts = Profile.ListMounts and Profile.ListMounts() or {}
    for index = 1, #mounts do
        local row = mounts[index]
        items[#items + 1] = {
            label = ensureString(row.name, row.ref),
            value = row.ref,
        }
    end

    return items
end

local function buildPetItems()
    local items = {
        { label = "None", value = "" },
    }

    local pets = Profile.ListPets and Profile.ListPets() or {}
    for index = 1, #pets do
        local row = pets[index]
        items[#items + 1] = {
            label = ensureString(row.name, row.ref),
            value = row.ref,
        }
    end

    return items
end

local function getEquipmentScopeTexture(scope)
    local normalizedScope = tostring(scope or "character")
    if normalizedScope == "mount" then
        return MOUNT_SCOPE_TEXTURE
    end
    if normalizedScope == "pet" then
        return PET_SCOPE_TEXTURE
    end

    return CHARACTER_SCOPE_TEXTURE
end

local function getEquipmentScopeTooltip(scope)
    return ("%s Equipment"):format(getEquipmentScopeDisplayName(scope))
end

local function applyEquipmentScopeButtonAlpha(button, isActive)
    local frame = button and button.GetFrame and button:GetFrame() or nil
    if frame and frame.SetAlpha then
        frame:SetAlpha(isActive and EQUIPMENT_SCOPE_ACTIVE_ALPHA or EQUIPMENT_SCOPE_INACTIVE_ALPHA)
    end
end

local function createEquipmentScopeButton(page, parent, scope, name)
    local texture = getEquipmentScopeTexture(scope)
    local button = UI.ImageButton:New({
        name = name,
        width = EQUIPMENT_SCOPE_BUTTON_SIZE,
        height = EQUIPMENT_SCOPE_BUTTON_SIZE,
        border = false,
        normalTexture = texture,
        highlightTexture = texture,
        pushedTexture = texture,
        disabledTexture = texture,
        tooltip = getEquipmentScopeTooltip(scope),
    })
    button:SetParent(parent)
    button:Create()
    local buttonFrame = button:GetFrame()
    if buttonFrame and buttonFrame.SetFrameStrata then
        buttonFrame:SetFrameStrata("HIGH")
    end
    if buttonFrame and buttonFrame.SetFrameLevel and parent and parent.GetFrameLevel then
        buttonFrame:SetFrameLevel((parent:GetFrameLevel() or 0) + 12)
    end
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            page:SetActiveEquipmentScope(scope)
        end
    end)
    button:SetScript("OnEnter", function(frame)
        if frame and frame.SetAlpha then
            frame:SetAlpha(1)
        end
    end)
    button:SetScript("OnLeave", function(frame)
        if frame and frame.SetAlpha then
            frame:SetAlpha(page:GetActiveEquipmentScope() == scope and EQUIPMENT_SCOPE_ACTIVE_ALPHA or EQUIPMENT_SCOPE_INACTIVE_ALPHA)
        end
    end)

    return button
end

local function buildEmptyTooltip(slotKey)
    return {
        type = "custom",
        title = Profile.GetSlotLabel and Profile.GetSlotLabel(slotKey) or "Slot",
        lines = {
            "No item equipped.",
        },
    }
end

local function buildEquippedTooltip(slotInfo)
    if not slotInfo then
        return {
            type = "custom",
            title = "Slot",
            lines = {
                "No item data available.",
            },
        }
    end

    local item = slotInfo.item
    if not item then
        return {
            type = "custom",
            title = Profile.GetSlotLabel and Profile.GetSlotLabel(slotInfo.slotKey) or "Slot",
            lines = {
                ("Missing item: %s"):format(tostring(slotInfo.itemRef or "-")),
            },
        }
    end

    local datasetName = slotInfo.dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(slotInfo.dataset) or "Unknown Dataset"
    local builder = TooltipBuilders and TooltipBuilders.Item
    if builder and builder.Build then
        local tooltip = builder:Build(item, {
            dataset = slotInfo.dataset,
            datasetId = slotInfo.dataset and slotInfo.dataset.id or nil,
            datasetName = datasetName,
            itemId = item.id,
            isActive = slotInfo.isActive,
            isMissing = slotInfo.isMissing,
            soulbound = slotInfo.soulbound == true,
            modifications = slotInfo.modifications,
        })
        if tooltip then
            return tooltip
        end
    end

    return {
        type = "custom",
        title = ensureString(item.name, Profile.GetSlotLabel and Profile.GetSlotLabel(slotInfo.slotKey) or "Item"),
        lines = {
            ("Dataset: %s"):format(datasetName),
        },
    }
end

local function updateSlotVisual(page, slotKey)
    local slot = page.SlotWidgets and page.SlotWidgets[slotKey] or nil
    if not slot then
        return
    end

    local scope = page.GetActiveEquipmentScope and page:GetActiveEquipmentScope() or "character"
    local slotInfo = Profile.GetEquippedItemByScope and Profile.GetEquippedItemByScope(scope, slotKey) or Profile.GetEquippedItem and Profile.GetEquippedItem(slotKey) or nil
    local emptyTexture = Profile.GetSlotTexture and Profile.GetSlotTexture(slotKey) or "Interface\\Icons\\INV_Misc_QuestionMark"
    local icon = emptyTexture
    local enabled = true
    local tooltip = buildEmptyTooltip(slotKey)

    if slotInfo and slotInfo.item then
        icon = ensureString(slotInfo.item.icon, emptyTexture)
        tooltip = buildEquippedTooltip(slotInfo)
    elseif slotInfo and slotInfo.itemRef ~= nil and slotInfo.itemRef ~= "" then
        icon = "Interface\\Icons\\INV_Misc_QuestionMark"
        tooltip = buildEquippedTooltip(slotInfo)
    end

    slot:SetIcon(icon)
    slot:SetEnabled(enabled)
    slot:SetTooltip(tooltip)

    local isSelected = page.owner and page.owner.SelectedSlotKey == slotKey
    if slot.SetBorderColor then
        if isSelected then
            slot:SetBorderColor(0.24, 0.72, 1, 1)
        else
            slot:SetBorderColor(0.42, 0.46, 0.52, 1)
        end
    end
end

local function formatStatValue(row)
    local displayMode = tostring(row and row.displayMode or "signed_value")
    local value = tonumber(row and row.value) or 0

    if displayMode == "value" then
        return ("%g"):format(value)
    end
    if displayMode == "signed_percent" then
        return ("%g%%"):format(value)
    end
    return ("%g"):format(value)
end

local function buildStatMitigationTooltipLines(statRow)
    local statRef = ensureString(statRow and statRow.ref, "")
    if statRef == ""
        or type(Registry.GetActivatedDatasets) ~= "function"
        or type(Combat.ResolveDamageSchoolMitigation) ~= "function" then
        return {}
    end

    local lines = {}
    local profileLevel = Profile.GetLevel and Profile.GetLevel() or 1
    local datasets = Registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        for schoolIndex = 1, #((dataset and dataset.damageSchools) or {}) do
            local damageSchool = dataset.damageSchools[schoolIndex]
            if ensureString(damageSchool and damageSchool.mitigationStatRef, "") == statRef then
                local mitigation = Combat:ResolveDamageSchoolMitigation(
                    damageSchool,
                    tonumber(statRow and statRow.value) or 0,
                    profileLevel
                )
                if mitigation.mode == "percent" then
                    lines[#lines + 1] = ("%s Mitigation: %.2f%%"):format(
                        ensureString(damageSchool and damageSchool.name, damageSchool and damageSchool.id or "Damage School"),
                        tonumber(mitigation.percent) or 0
                    )
                end
            end
        end
    end

    return lines
end

local function buildStatTooltip(statRow)
    if type(statRow) ~= "table" then
        return nil
    end

    local lines = {}
    local description = ensureString(statRow.stat and statRow.stat.description, "")
    if description ~= "" then
        lines[#lines + 1] = description
    end

    local mitigationLines = buildStatMitigationTooltipLines(statRow)
    for index = 1, #mitigationLines do
        lines[#lines + 1] = mitigationLines[index]
    end

    if #lines == 0 then
        return nil
    end

    return {
        title = ensureString(statRow.name, statRow.statId or "Stat"),
        lines = lines,
    }
end

local function refreshStatRows(page, statRows)
    if not page.StatScroll or not page.StatScroll.SetItems then
        return
    end

    page.StatScroll:SetItems(statRows or {})
end

local function getHealthResourceRef()
    local ruleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local value = nil
    if Ruleset.GetRulesetRuleValueByKey then
        value = Ruleset.GetRulesetRuleValueByKey(ruleset, "resources", "health_stat", nil)
    end
    return type(value) == "string" and value or nil
end

local function getResolvedResourceRowByRef(resourceRows, resourceRef)
    local normalizedRef = type(resourceRef) == "string" and resourceRef or ""
    if normalizedRef == "" then
        return nil
    end

    for index = 1, #(resourceRows or {}) do
        local row = resourceRows[index]
        if row and row.ref == normalizedRef then
            return row
        end
    end

    return nil
end

local function refreshHealthEntry(page, resourceRows, healthResourceRef)
    local healthEntry = page.HealthEntry
    local primaryEntry = page.PrimaryHealthResourceEntry
    if not healthEntry then
        return
    end

    local healthRow = getResolvedResourceRowByRef(resourceRows, healthResourceRef)
    local primaryResourceRef = Profile.GetPrimaryResourceRef and Profile.GetPrimaryResourceRef() or nil
    local primaryResourceRow = getResolvedResourceRowByRef(resourceRows, primaryResourceRef)
    local frame = healthEntry.GetFrame and healthEntry:GetFrame() or nil
    local hostFrame = page.HealthPanel and page.HealthPanel.GetFrame and page.HealthPanel:GetFrame() or nil
    local primaryFrame = primaryEntry and primaryEntry.GetFrame and primaryEntry:GetFrame() or nil
    if not frame then
        return
    end

    if healthRow then
        healthEntry:SetIcon(ensureString(healthRow.icon, "Interface\\Icons\\INV_Misc_QuestionMark"))
        healthEntry:SetStatName("Max Health")
        healthEntry:SetStatValue(("%g"):format(tonumber(healthRow.value) or 0))
        if frame.Show then
            frame:Show()
        end
        if hostFrame and hostFrame.Show then
            hostFrame:Show()
        end
        if primaryEntry and primaryResourceRow and primaryResourceRow.ref ~= healthRow.ref then
            primaryEntry:SetIcon(ensureString(primaryResourceRow.icon, "Interface\\Icons\\INV_Misc_QuestionMark"))
            primaryEntry:SetStatName(ensureString(primaryResourceRow.name, "Resource"))
            primaryEntry:SetStatValue(("%g"):format(tonumber(primaryResourceRow.value) or 0))
            if primaryFrame and primaryFrame.Show then
                primaryFrame:Show()
            end
        elseif primaryFrame and primaryFrame.Hide then
            primaryFrame:Hide()
        end
    else
        if frame.Hide then
            frame:Hide()
        end
        if hostFrame and hostFrame.Hide then
            hostFrame:Hide()
        end
        if primaryFrame and primaryFrame.Hide then
            primaryFrame:Hide()
        end
    end
end

local function getCharacterRuleValue(ruleKey, fallback)
    local ruleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local value = nil
    if Ruleset.GetRulesetRuleValueByKey then
        value = Ruleset.GetRulesetRuleValueByKey(ruleset, "character", ruleKey, fallback)
    end
    if value == nil then
        return fallback
    end
    return value
end

local function getEquipmentRuleValue(ruleKey, fallback)
    local ruleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local value = nil
    if Ruleset.GetRulesetRuleValueByKey then
        value = Ruleset.GetRulesetRuleValueByKey(ruleset, "equipment", ruleKey, fallback)
    end
    if value == nil then
        return fallback
    end
    return value
end

local function getInterfaceRuleValue(ruleKey, fallback)
    local ruleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local value = nil
    if Ruleset.GetRulesetRuleValueByKey then
        value = Ruleset.GetRulesetRuleValueByKey(ruleset, "interface", ruleKey, fallback)
    end
    if value == nil then
        return fallback
    end
    return value
end

local function getMountRuleValue(ruleKey, fallback)
    local ruleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local value = nil
    if Ruleset.GetRulesetRuleValueByKey then
        value = Ruleset.GetRulesetRuleValueByKey(ruleset, "mounts", ruleKey, fallback)
    end
    if value == nil then
        return fallback
    end
    return value
end

local function setWidgetVisibility(widget, shown)
    if not widget then
        return
    end

    local frame = widget.GetFrame and widget:GetFrame() or widget
    if not frame then
        return
    end

    if shown then
        if frame.Show then
            frame:Show()
        end
    else
        if frame.Hide then
            frame:Hide()
        end
    end
end

local function getProfileControlsPanelHeight()
    local useLevelSystem = getCharacterRuleValue("use_level_system", false) == true
    local useRaces = getCharacterRuleValue("use_races", false) == true
    local useClasses = getCharacterRuleValue("use_classes", false) == true
    if useLevelSystem or useRaces or useClasses then
        return PROFILE_CONTROLS_TWO_ROW_HEIGHT
    end
    return PROFILE_CONTROLS_ONE_ROW_HEIGHT
end

local function refreshActionBarResourceDisplay()
    if Addon.Client and type(Addon.Client.RefreshActionBarCompanionBars) == "function" then
        Addon.Client:RefreshActionBarCompanionBars("profile-resource-display")
    end
end

local function refreshItemLevelSummary(page, layout)
    local summaryPanel = page and page.ItemLevelSummaryPanel or nil
    local summaryText = page and page.ItemLevelSummaryText or nil
    if not summaryPanel or not summaryText or not summaryText.SetText then
        return
    end

    local isEnabled = getInterfaceRuleValue("use_item_level", true) == true
    setWidgetVisibility(summaryPanel, isEnabled)
    if summaryPanel.options then
        summaryPanel.options.height = isEnabled and ITEM_LEVEL_SUMMARY_HEIGHT or 0
    end

    local summaryFrame = summaryPanel.GetFrame and summaryPanel:GetFrame() or nil
    if summaryFrame and summaryFrame.SetHeight then
        summaryFrame:SetHeight(isEnabled and ITEM_LEVEL_SUMMARY_HEIGHT or 0)
    end

    if not isEnabled then
        return
    end

    local total = 0
    local count = 0
    local minimum = nil
    local maximum = nil
    local scope = page and page.GetActiveEquipmentScope and page:GetActiveEquipmentScope() or "character"
    for index = 1, #(layout and layout.ordered or {}) do
        local slotKey = layout.ordered[index]
        local slotInfo = Profile.GetEquippedItemByScope and Profile.GetEquippedItemByScope(scope, slotKey) or Profile.GetEquippedItem and Profile.GetEquippedItem(slotKey) or nil
        local item = slotInfo and slotInfo.item or nil
        if slotInfo and slotInfo.isMissing ~= true
            and type(item) == "table"
            and type(ItemClass) == "table"
            and type(ItemClass.IsItemLevelEligible) == "function"
            and type(ItemClass.ResolveItemLevel) == "function"
            and ItemClass.IsItemLevelEligible(item)
        then
            local itemLevel = math.max(0, math.floor(tonumber(ItemClass.ResolveItemLevel(item)) or 0))
            if itemLevel > 0 then
                total = total + itemLevel
                count = count + 1
                minimum = minimum and math.min(minimum, itemLevel) or itemLevel
                maximum = maximum and math.max(maximum, itemLevel) or itemLevel
            end
        end
    end

    if count <= 0 then
        summaryText:SetText("Item Level: --")
        return
    end

    summaryText:SetText(("Item Level: %.1f"):format(total / count))
end

local function refreshMovementSpeedEntry(page)
    local movementPanel = page and page.MovementSpeedPanel or nil
    local movementEntry = page and page.MovementSpeedEntry or nil
    if not movementPanel or not movementEntry then
        return
    end

    local statRef = getMountRuleValue("movement_range_stat", "")
    local statRow = statRef ~= "" and Profile.GetResolvedStatRow and Profile.GetResolvedStatRow(statRef) or nil
    local frame = movementEntry.GetFrame and movementEntry:GetFrame() or nil
    if not frame then
        return
    end

    if statRow then
        movementEntry:SetIcon(ensureString(statRow.icon, "Interface\\Icons\\INV_Misc_QuestionMark"))
        movementEntry:SetStatName(ensureString(statRow.name, statRow.statId or "Movement Speed"))
        movementEntry:SetStatValue(formatStatValue(statRow))
        if frame.Show then
            frame:Show()
        end
    elseif frame.Hide then
        frame:Hide()
    end
end

local function resourceItemsContainValue(items, value)
    local normalizedValue = type(value) == "string" and value or ""
    for index = 1, #(items or {}) do
        local item = items[index]
        if type(item) == "table" and tostring(item.value or "") == normalizedValue then
            return true
        end
    end

    return false
end

local function buildPrimaryResourceItems(resources, healthResourceRef, selectedSpecialRef)
    local items = {
        { label = "None", value = "" },
    }

    for index = 1, #resources do
        local resourceRow = resources[index]
        local resourceRef = type(resourceRow and resourceRow.ref) == "string" and resourceRow.ref or ""
        if resourceRef ~= ""
            and resourceRef ~= healthResourceRef
            and resourceRef ~= tostring(selectedSpecialRef or "")
        then
            items[#items + 1] = {
                label = ensureString(resourceRow.name, resourceRef),
                value = resourceRef,
            }
        end
    end

    return items
end

local function buildSpecialResourceItems(resources, healthResourceRef, selectedPrimaryRef)
    local items = {
        { label = "None", value = "" },
    }

    for index = 1, #resources do
        local resourceRow = resources[index]
        local resourceRef = type(resourceRow and resourceRow.ref) == "string" and resourceRow.ref or ""
        if resourceRef ~= ""
            and resourceRef ~= healthResourceRef
            and resourceRef ~= tostring(selectedPrimaryRef or "")
            and resourceRow.isSpecial == true
        then
            items[#items + 1] = {
                label = ensureString(resourceRow.name, resourceRef),
                value = resourceRef,
            }
        end
    end

    return items
end

local function refreshResourceSelectors(page, resources, healthResourceRef)
    local primaryDropdown = page.PrimaryResourceDropdown
    local specialDropdown = page.SpecialResourceDropdown
    if not primaryDropdown or not specialDropdown then
        return
    end

    local activeScope = page and page.GetActiveEquipmentScope and page:GetActiveEquipmentScope() or "character"
    local showScopeControls = activeScope == "mount" or activeScope == "pet"
    setWidgetVisibility(page.PrimaryResourceLabel, not showScopeControls)
    setWidgetVisibility(primaryDropdown, not showScopeControls)
    setWidgetVisibility(page.SpecialResourceLabel, not showScopeControls)
    setWidgetVisibility(specialDropdown, not showScopeControls)

    if showScopeControls then
        return
    end

    local selectedPrimaryRef = Profile.GetPrimaryResourceRef and Profile.GetPrimaryResourceRef() or nil
    local selectedSpecialRef = Profile.GetSpecialResourceRef and Profile.GetSpecialResourceRef() or nil
    local primaryItems = buildPrimaryResourceItems(resources or {}, healthResourceRef, selectedSpecialRef)
    local specialItems = buildSpecialResourceItems(resources or {}, healthResourceRef, selectedPrimaryRef)

    primaryDropdown:SetItems(primaryItems)
    primaryDropdown:SetSelectedValue(resourceItemsContainValue(primaryItems, selectedPrimaryRef) and selectedPrimaryRef or "", true)
    if primaryDropdown.SetEnabled then
        primaryDropdown:SetEnabled(#primaryItems > 1)
    end

    specialDropdown:SetItems(specialItems)
    specialDropdown:SetSelectedValue(resourceItemsContainValue(specialItems, selectedSpecialRef) and selectedSpecialRef or "", true)
    if specialDropdown.SetEnabled then
        specialDropdown:SetEnabled(#specialItems > 1)
    end
end

local function buildProfileDefinitionItems(collectionKey)
    local items = {
        { label = "None", value = "" },
    }
    local registry = Addon.Internal and Addon.Internal.Registry or {}
    local dependencies = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Dependecies or {}
    local datasets = registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        for index = 1, #(dataset and dataset[collectionKey] or {}) do
            local entry = dataset[collectionKey][index]
            if entry and entry.id then
                items[#items + 1] = {
                    label = ("%s / %s"):format(Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or tostring(dataset.id or ""), ensureString(entry.name, tostring(entry.id))),
                    value = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, entry.id) or "",
                }
            end
        end
    end

    return items
end

local function definitionItemsContainValue(items, value)
    local normalizedValue = type(value) == "string" and value or ""
    for index = 1, #(items or {}) do
        local item = items[index]
        if type(item) == "table" and tostring(item.value or "") == normalizedValue then
            return true
        end
    end
    return false
end

local function refreshProfileSelectors(page)
    local useLevelSystem = getCharacterRuleValue("use_level_system", false) == true
    local useRaces = getCharacterRuleValue("use_races", false) == true
    local useClasses = getCharacterRuleValue("use_classes", false) == true
    local activeScope = page and page.GetActiveEquipmentScope and page:GetActiveEquipmentScope() or "character"
    local showScopeControls = activeScope == "mount" or activeScope == "pet"
    local showLevel = useLevelSystem

    if page.LevelInput then
        page.LevelInput:SetText(tostring(Profile.GetLevel and Profile.GetLevel() or 1))
    end

    setWidgetVisibility(page.LevelLabel, showLevel and not showScopeControls)
    setWidgetVisibility(page.LevelInput, showLevel and not showScopeControls)
    setWidgetVisibility(page.RaceLabel, useRaces and not showScopeControls)
    setWidgetVisibility(page.RaceDropdown, useRaces and not showScopeControls)
    setWidgetVisibility(page.ClassLabel, useClasses and not showScopeControls)
    setWidgetVisibility(page.ClassDropdown, useClasses and not showScopeControls)

    if showScopeControls then
        return
    end

    local raceItems = buildProfileDefinitionItems("races")
    local classItems = buildProfileDefinitionItems("classes")
    local selectedRaceRef = Profile.GetRaceRef and Profile.GetRaceRef() or nil
    local selectedClassRef = Profile.GetClassRef and Profile.GetClassRef() or nil

    if page.RaceDropdown and useRaces then
        page.RaceDropdown:SetItems(raceItems)
        page.RaceDropdown:SetSelectedValue(definitionItemsContainValue(raceItems, selectedRaceRef) and selectedRaceRef or "", true)
        if page.RaceDropdown.SetEnabled then
            page.RaceDropdown:SetEnabled(#raceItems > 1)
        end
    end

    if page.ClassDropdown and useClasses then
        page.ClassDropdown:SetItems(classItems)
        page.ClassDropdown:SetSelectedValue(definitionItemsContainValue(classItems, selectedClassRef) and selectedClassRef or "", true)
        if page.ClassDropdown.SetEnabled then
            page.ClassDropdown:SetEnabled(#classItems > 1)
        end
    end
end

local function refreshTraitRuntimeForProfileSelection(reason)
    local client = Addon.Client or nil
    local eventState = type(client) == "table" and type(client.GetEventState) == "function" and client:GetEventState() or nil
    if type(client) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return
    end

    if type(client.RefreshTraitRuntimeEntries) == "function" then
        client:RefreshTraitRuntimeEntries(eventState)
    end
    if type(client.RefreshTraitResolvedState) == "function" then
        client:RefreshTraitResolvedState(eventState, reason or "profile-selection")
    end
end

local function buildLayoutSignature(layout)
    local parts = {}

    local function append(groupName, slotKeys)
        for index = 1, #(slotKeys or {}) do
            parts[#parts + 1] = ("%s:%d:%s"):format(groupName, index, tostring(slotKeys[index]))
        end
    end

    append("left", layout and layout.left or nil)
    append("right", layout and layout.right or nil)
    append("bottom", layout and layout.bottom or nil)

    return table.concat(parts, "|")
end

function EquipmentStatsPage:GetActiveEquipmentScope()
    local scope = tostring(self.ActiveEquipmentScope or "character")
    if scope ~= "mount" and scope ~= "pet" then
        scope = "character"
    end
    self.ActiveEquipmentScope = scope
    return scope
end

function EquipmentStatsPage:SetActiveEquipmentScope(scope, skipRefresh)
    local normalizedScope = tostring(scope or "character")
    if normalizedScope ~= "mount" and normalizedScope ~= "pet" then
        normalizedScope = "character"
    end

    if self.ActiveEquipmentScope == normalizedScope then
        return false
    end

    self.ActiveEquipmentScope = normalizedScope
    if self.owner then
        self.owner.SelectedSlotKey = nil
    end
    self.LastLayoutSignature = nil
    if not skipRefresh then
        self:Refresh()
    end
    return true
end

function EquipmentStatsPage:GetActiveEquipmentLayout()
    local scope = self:GetActiveEquipmentScope()
    return Profile.GetEquipmentLayoutByScope and Profile.GetEquipmentLayoutByScope(scope) or Profile.GetEquipmentLayout()
end

function EquipmentStatsPage:RefreshScopeButtons()
    local activeScope = self:GetActiveEquipmentScope()
    local buttons = {
        character = self.CharacterScopeButton,
        mount = self.MountScopeButton,
        pet = self.PetScopeButton,
    }

    for scope, button in pairs(buttons) do
        if button then
            if button.SetTooltip then
                button:SetTooltip(getEquipmentScopeTooltip(scope))
            end
            if button.SetEnabled then
                button:SetEnabled(true)
            end
            applyEquipmentScopeButtonAlpha(button, scope == activeScope)
        end
    end
end

function EquipmentStatsPage:RefreshEquipmentHeader()
    local scope = self:GetActiveEquipmentScope()
    local showScopeHeader = scope == "mount" or scope == "pet"
    local headerLabel = scope == "pet" and "Active Pet" or "Active Mount"
    local headerItems = scope == "pet" and buildPetItems() or buildMountItems()
    local selectedRef = scope == "pet"
        and (Profile.GetPetRef and (Profile.GetPetRef() or "") or "")
        or (Profile.GetMountRef and (Profile.GetMountRef() or "") or "")

    if self.EquipmentHeaderPanel and self.EquipmentHeaderPanel.GetFrame then
        local headerFrame = self.EquipmentHeaderPanel:GetFrame()
        if headerFrame and headerFrame.Hide then
            headerFrame:Hide()
        end
    end

    if self.MountControlLabel then
        if self.MountControlLabel.SetText then
            self.MountControlLabel:SetText(headerLabel)
        end
        setWidgetVisibility(self.MountControlLabel, showScopeHeader)
    end

    if self.MountControlDropdown then
        self.MountControlDropdown:SetItems(headerItems)
        self.MountControlDropdown:SetSelectedValue(selectedRef, true)
        if self.MountControlDropdown.SetEnabled then
            self.MountControlDropdown:SetEnabled(showScopeHeader)
        end
        setWidgetVisibility(self.MountControlDropdown, showScopeHeader)
    end
end

function EquipmentStatsPage:EnsureSlotWidget(slotKey)
    self.SlotWidgets = self.SlotWidgets or {}

    local slot = self.SlotWidgets[slotKey]
    if slot then
        return slot
    end

    slot = UI.ObjectSlot:New({
        name = "RPEProfileEquipmentSlot" .. slotKey,
        width = SLOT_SIZE,
        height = SLOT_SIZE,
        size = SLOT_SIZE,
        iconTexture = Profile.GetSlotTexture and Profile.GetSlotTexture(slotKey) or "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    slot:SetParent(self.EquipmentBody:GetContentFrame())
    slot:Create()

    local owner = self.owner
    local frame = slot:GetFrame()
    if frame then
        frame:HookScript("OnMouseUp", function(_, button)
            if button == "LeftButton" and owner and owner.SetSelectedSlotKey then
                owner:SetSelectedSlotKey(slotKey)
            elseif button == "RightButton" and Profile.UnequipSlotToInventory then
                local scope = self.GetActiveEquipmentScope and self:GetActiveEquipmentScope() or "character"
                local removed = Profile.UnequipSlotToInventoryByScope and Profile.UnequipSlotToInventoryByScope(scope, slotKey) or Profile.UnequipSlotToInventory(slotKey)
                if removed then
                    if owner and owner.SelectedSlotKey == slotKey then
                        owner.SelectedSlotKey = nil
                    end
                end
            end
        end)
    end

    self.SlotWidgets[slotKey] = slot
    return slot
end

function EquipmentStatsPage:ApplySlotLayout(layout)
    local body = self.EquipmentBody and self.EquipmentBody.GetContentFrame and self.EquipmentBody:GetContentFrame() or nil
    if not body then
        return
    end

    local visible = {}
    local groupConfigs = {
        left = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 0, y = SLOT_COLUMN_TOP_OFFSET, horizontal = false },
        right = { point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = 0, y = SLOT_COLUMN_TOP_OFFSET, horizontal = false },
        bottom = { point = "TOP", relativePoint = "BOTTOM", x = 0, y = -10, horizontal = true, relativeFrame = self.ModelFrame },
    }

    for _, groupName in ipairs({ "left", "right", "bottom" }) do
        local slotKeys = layout and layout[groupName] or {}
        local config = groupConfigs[groupName]

        for index = 1, #slotKeys do
            local slotKey = slotKeys[index]
            local slot = self:EnsureSlotWidget(slotKey)
            local frame = slot and slot.GetFrame and slot:GetFrame() or nil
            if frame then
                frame:ClearAllPoints()
                local relativeFrame = config.relativeFrame or body

                if config.horizontal then
                    local centeredIndex = (index - 1) - ((#slotKeys - 1) / 2)
                    local x = centeredIndex * (SLOT_SIZE + SLOT_SPACING)
                    frame:SetPoint(config.point, relativeFrame, config.relativePoint, x, config.y)
                else
                    local y = config.y - ((index - 1) * (SLOT_SIZE + SLOT_SPACING))
                    frame:SetPoint(config.point, relativeFrame, config.relativePoint, config.x, y)
                end

                if frame.Show then
                    frame:Show()
                end
            end

            visible[slotKey] = true
        end
    end

    for slotKey, slot in pairs(self.SlotWidgets or {}) do
        local frame = slot and slot.GetFrame and slot:GetFrame() or nil
        if frame and not visible[slotKey] and frame.Hide then
            frame:Hide()
        end
    end
end

function EquipmentStatsPage:ApplyMetrics()
    if not self.frame then
        return
    end

    if self.RootLayout and self.RootLayout.options then
        self.RootLayout.options.spacing = 10
        self.RootLayout.options.fitChildrenWidth = true
        self.RootLayout.options.fitChildrenHeight = true
    end

    local equipmentPanelFrame = self.EquipmentPanel and self.EquipmentPanel.GetFrame and self.EquipmentPanel:GetFrame() or nil
    if self.EquipmentPanel and self.EquipmentPanel.options then
        self.EquipmentPanel.options.width = EQUIPMENT_PANEL_WIDTH
        self.EquipmentPanel.options.height = 380
    end
    if equipmentPanelFrame and equipmentPanelFrame.SetWidth then
        equipmentPanelFrame:SetWidth(EQUIPMENT_PANEL_WIDTH)
    end
    if equipmentPanelFrame and equipmentPanelFrame.SetHeight then
        equipmentPanelFrame:SetHeight(380)
    end

    local profileControlsPanelFrame = self.ProfileControlsPanel and self.ProfileControlsPanel.GetFrame and self.ProfileControlsPanel:GetFrame() or nil
    if self.ProfileControlsPanel and self.ProfileControlsPanel.options then
        self.ProfileControlsPanel.options.width = EQUIPMENT_PANEL_WIDTH
        self.ProfileControlsPanel.options.height = getProfileControlsPanelHeight()
    end
    if profileControlsPanelFrame and profileControlsPanelFrame.SetWidth then
        profileControlsPanelFrame:SetWidth(EQUIPMENT_PANEL_WIDTH)
    end
    if profileControlsPanelFrame and profileControlsPanelFrame.SetHeight then
        profileControlsPanelFrame:SetHeight(getProfileControlsPanelHeight())
    end

    local equipmentHeaderPanelFrame = self.EquipmentHeaderPanel and self.EquipmentHeaderPanel.GetFrame and self.EquipmentHeaderPanel:GetFrame() or nil
    if self.EquipmentHeaderPanel and self.EquipmentHeaderPanel.options then
        self.EquipmentHeaderPanel.options.width = EQUIPMENT_PANEL_WIDTH
        self.EquipmentHeaderPanel.options.height = 0
    end
    if equipmentHeaderPanelFrame and equipmentHeaderPanelFrame.SetWidth then
        equipmentHeaderPanelFrame:SetWidth(EQUIPMENT_PANEL_WIDTH)
    end
    if equipmentHeaderPanelFrame and equipmentHeaderPanelFrame.SetHeight then
        equipmentHeaderPanelFrame:SetHeight(0)
    end
    if equipmentHeaderPanelFrame then
        if equipmentHeaderPanelFrame.Hide then
            equipmentHeaderPanelFrame:Hide()
        end
    end

    local equipmentBodyFrame = self.EquipmentBody and self.EquipmentBody.GetFrame and self.EquipmentBody:GetFrame() or nil
    local equipmentBodyHeight = 292 + (PROFILE_CONTROLS_TWO_ROW_HEIGHT - getProfileControlsPanelHeight()) - 26
    if self.EquipmentBody and self.EquipmentBody.options then
        self.EquipmentBody.options.width = EQUIPMENT_PANEL_WIDTH
        self.EquipmentBody.options.height = equipmentBodyHeight
    end
    if equipmentBodyFrame and equipmentBodyFrame.SetWidth then
        equipmentBodyFrame:SetWidth(EQUIPMENT_PANEL_WIDTH)
    end
    if equipmentBodyFrame and equipmentBodyFrame.SetHeight then
        equipmentBodyFrame:SetHeight(equipmentBodyHeight)
    end

    local statsPanelFrame = self.StatsPanel and self.StatsPanel.GetFrame and self.StatsPanel:GetFrame() or nil
    if self.StatsPanel and self.StatsPanel.options then
        self.StatsPanel.options.width = STATS_PANEL_WIDTH
        self.StatsPanel.options.height = 380
        self.StatsPanel.options.expandWidth = true
        self.StatsPanel.options.weight = 1
    end
    if statsPanelFrame and statsPanelFrame.SetHeight then
        statsPanelFrame:SetHeight(380)
    end

    local healthPanelFrame = self.HealthPanel and self.HealthPanel.GetFrame and self.HealthPanel:GetFrame() or nil
    if self.HealthPanel and self.HealthPanel.options then
        self.HealthPanel.options.width = STATS_SCROLL_WIDTH
        self.HealthPanel.options.height = HEALTH_PANEL_HEIGHT
    end
    if healthPanelFrame and healthPanelFrame.SetWidth then
        healthPanelFrame:SetWidth(STATS_SCROLL_WIDTH)
    end
    if healthPanelFrame and healthPanelFrame.SetHeight then
        healthPanelFrame:SetHeight(HEALTH_PANEL_HEIGHT)
    end

    local itemLevelSummaryPanelFrame = self.ItemLevelSummaryPanel and self.ItemLevelSummaryPanel.GetFrame and self.ItemLevelSummaryPanel:GetFrame() or nil
    local movementSpeedPanelFrame = self.MovementSpeedPanel and self.MovementSpeedPanel.GetFrame and self.MovementSpeedPanel:GetFrame() or nil
    local statSectionGapPanelFrame = self.StatSectionGapPanel and self.StatSectionGapPanel.GetFrame and self.StatSectionGapPanel:GetFrame() or nil
    if self.ItemLevelSummaryPanel and self.ItemLevelSummaryPanel.options then
        self.ItemLevelSummaryPanel.options.width = ITEM_LEVEL_SUMMARY_WIDTH
    end
    if itemLevelSummaryPanelFrame and itemLevelSummaryPanelFrame.SetWidth then
        itemLevelSummaryPanelFrame:SetWidth(ITEM_LEVEL_SUMMARY_WIDTH)
    end
    if itemLevelSummaryPanelFrame and itemLevelSummaryPanelFrame.SetHeight then
        itemLevelSummaryPanelFrame:SetHeight(ITEM_LEVEL_SUMMARY_HEIGHT)
    end
    if self.MovementSpeedPanel and self.MovementSpeedPanel.options then
        self.MovementSpeedPanel.options.width = STATS_SCROLL_WIDTH
        self.MovementSpeedPanel.options.height = MOVEMENT_SPEED_PANEL_HEIGHT
    end
    if movementSpeedPanelFrame and movementSpeedPanelFrame.SetWidth then
        movementSpeedPanelFrame:SetWidth(STATS_SCROLL_WIDTH)
    end
    if movementSpeedPanelFrame and movementSpeedPanelFrame.SetHeight then
        movementSpeedPanelFrame:SetHeight(MOVEMENT_SPEED_PANEL_HEIGHT)
    end
    if self.StatSectionGapPanel and self.StatSectionGapPanel.options then
        self.StatSectionGapPanel.options.width = STATS_SCROLL_WIDTH
        self.StatSectionGapPanel.options.height = STATS_SECTION_GAP_HEIGHT
    end
    if statSectionGapPanelFrame and statSectionGapPanelFrame.SetWidth then
        statSectionGapPanelFrame:SetWidth(STATS_SCROLL_WIDTH)
    end
    if statSectionGapPanelFrame and statSectionGapPanelFrame.SetHeight then
        statSectionGapPanelFrame:SetHeight(STATS_SECTION_GAP_HEIGHT)
    end

    local statScrollPanelFrame = self.StatScrollPanel and self.StatScrollPanel.GetFrame and self.StatScrollPanel:GetFrame() or nil
    if self.StatScrollPanel and self.StatScrollPanel.options then
        self.StatScrollPanel.options.width = STATS_SCROLL_WIDTH
        self.StatScrollPanel.options.height = STAT_SCROLL_HEIGHT
        self.StatScrollPanel.options.expandWidth = true
        self.StatScrollPanel.options.expandHeight = false
        self.StatScrollPanel.options.weight = nil
    end
    if statScrollPanelFrame and statScrollPanelFrame.SetHeight then
        statScrollPanelFrame:SetHeight(STAT_SCROLL_HEIGHT)
    end

    local statScrollFrame = self.StatScroll and self.StatScroll.GetFrame and self.StatScroll:GetFrame() or nil
    if statScrollFrame and statScrollFrame.SetWidth then
        statScrollFrame:SetWidth(STATS_SCROLL_WIDTH)
    end
    if statScrollFrame and statScrollFrame.SetHeight then
        statScrollFrame:SetHeight(STAT_SCROLL_HEIGHT)
    end

    if self.HealthEntry and self.HealthEntry.SetLayoutMetrics then
        self.HealthEntry:SetLayoutMetrics(HEALTH_ENTRY_WIDTH, HEALTH_ENTRY_VALUE_WIDTH)
    end
    if self.PrimaryHealthResourceEntry and self.PrimaryHealthResourceEntry.SetLayoutMetrics then
        self.PrimaryHealthResourceEntry:SetLayoutMetrics(HEALTH_ENTRY_WIDTH, HEALTH_ENTRY_VALUE_WIDTH)
    end
    if self.MovementSpeedEntry and self.MovementSpeedEntry.SetLayoutMetrics then
        self.MovementSpeedEntry:SetLayoutMetrics(HEALTH_ENTRY_WIDTH, HEALTH_ENTRY_VALUE_WIDTH)
    end

    if self.StatScroll and self.StatScroll.rows then
        for index = 1, #self.StatScroll.rows do
            local row = self.StatScroll.rows[index]
            if row and row.StatEntry and row.StatEntry.SetLayoutMetrics then
                row.StatEntry:SetLayoutMetrics(STAT_ENTRY_WIDTH, STAT_ENTRY_VALUE_WIDTH)
            end
        end
    end

    if self.RootLayout and self.RootLayout.RefreshLayout then
        self.RootLayout:RefreshLayout()
    end
    if self.EquipmentLayout and self.EquipmentLayout.RefreshLayout then
        self.EquipmentLayout:RefreshLayout()
    end
    if self.StatsLayout and self.StatsLayout.RefreshLayout then
        self.StatsLayout:RefreshLayout()
    end
    if self.StatScroll and self.StatScroll.UpdateGeometry then
        self.StatScroll:UpdateGeometry()
    end
end

function EquipmentStatsPage:Build(parent, owner)
    if self.frame then
        self.owner = owner
        self:ApplyMetrics()
        return self.frame
    end

    self.owner = owner
    self.frame = CreateFrame("Frame", "RPEProfileEquipmentStatsPage", parent)
    self.frame:SetAllPoints(parent)
    self.SlotWidgets = {}
    self.ActiveSlotKeys = {}
    self.ActiveEquipmentScope = self.ActiveEquipmentScope or "character"
    self.LastLayoutSignature = nil

    self.RootLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.frame, "RPEProfileEquipmentStatsRootLayout", {
        spacing = 10,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.EquipmentPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileEquipmentPanel", {
        width = EQUIPMENT_PANEL_WIDTH,
        height = 380,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.RootLayout:AddChild(self.EquipmentPanel)

    self.StatsPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileStatsPanel", {
        width = STATS_PANEL_WIDTH,
        height = 380,
        expandWidth = true,
        weight = 1,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.RootLayout:AddChild(self.StatsPanel)

    local equipmentContent = self.EquipmentPanel:GetContentFrame()
    self.EquipmentLayout = UI.CreateLayout(UI.VerticalLayoutGroup, equipmentContent, "RPEProfileEquipmentPanelLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.EquipmentLayout, equipmentContent, 0, 0, 0, 0)

    self.EquipmentHeaderPanel = UI.CreatePanel(self.EquipmentLayout:GetFrame(), "RPEProfileEquipmentHeaderPanel", {
        width = EQUIPMENT_PANEL_WIDTH,
        height = 0,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.EquipmentLayout:AddChild(self.EquipmentHeaderPanel)

    local equipmentHeaderContent = self.EquipmentHeaderPanel:GetContentFrame()
    self.EquipmentHeaderLabel = UI.CreateText(equipmentHeaderContent, "RPEProfileEquipmentHeaderLabel", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 72,
        height = 12,
        justifyH = "LEFT",
    })
    self.EquipmentHeaderLabel:GetFrame():SetPoint("LEFT", equipmentHeaderContent, "LEFT", 0, 0)

    self.MountHeaderDropdown = UI.CreateDropdown(equipmentHeaderContent, "RPEProfileEquipmentMountDropdown", {
        width = EQUIPMENT_PANEL_WIDTH - 88,
        height = RESOURCE_SELECTOR_DROPDOWN_HEIGHT,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function(value)
            local scope = self.GetActiveEquipmentScope and self:GetActiveEquipmentScope() or "mount"
            if scope == "pet" and Profile.SetPetRef then
                Profile.SetPetRef(value ~= "" and value or nil)
            elseif Profile.SetMountRef then
                Profile.SetMountRef(value ~= "" and value or nil)
            end
            self:Refresh()
        end,
    })
    self.MountHeaderDropdown:GetFrame():SetPoint("RIGHT", equipmentHeaderContent, "RIGHT", 0, 0)

    self.ProfileControlsPanel = UI.CreatePanel(self.EquipmentLayout:GetFrame(), "RPEProfileControlsPanel", {
        width = EQUIPMENT_PANEL_WIDTH,
        height = PROFILE_CONTROLS_TWO_ROW_HEIGHT,
        contentInset = 0,
        showBorder = false,
        frameStrata = "HIGH",
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.EquipmentLayout:AddChild(self.ProfileControlsPanel)

    local controlsContent = self.ProfileControlsPanel:GetContentFrame()

    self.MountControlLabel = UI.CreateText(controlsContent, "RPEProfileMountControlLabel", "Active Mount", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = EQUIPMENT_PANEL_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
    self.MountControlLabel:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", 0, RESOURCE_SELECTOR_LABEL_Y)

    self.MountControlDropdown = UI.CreateDropdown(controlsContent, "RPEProfileMountControlDropdown", {
        width = EQUIPMENT_PANEL_WIDTH - 2,
        height = RESOURCE_SELECTOR_DROPDOWN_HEIGHT,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function(value)
            local scope = self.GetActiveEquipmentScope and self:GetActiveEquipmentScope() or "mount"
            if scope == "pet" and Profile.SetPetRef then
                Profile.SetPetRef(value ~= "" and value or nil)
            elseif Profile.SetMountRef then
                Profile.SetMountRef(value ~= "" and value or nil)
            end
            self:Refresh()
        end,
    })
    self.MountControlDropdown:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", 0, RESOURCE_SELECTOR_DROPDOWN_Y)

    self.PrimaryResourceLabel = UI.CreateText(controlsContent, "RPEProfilePrimaryResourceLabel", "Primary Resource", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = RESOURCE_SELECTOR_DROPDOWN_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
    self.PrimaryResourceLabel:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", RESOURCE_SELECTOR_LEFT_X, RESOURCE_SELECTOR_LABEL_Y)

    self.PrimaryResourceDropdown = UI.CreateDropdown(controlsContent, "RPEProfilePrimaryResourceDropdown", {
        width = RESOURCE_SELECTOR_DROPDOWN_WIDTH,
        height = RESOURCE_SELECTOR_DROPDOWN_HEIGHT,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function(value)
            local normalizedValue = type(value) == "string" and value or ""
            local selectedSpecialRef = Profile.GetSpecialResourceRef and Profile.GetSpecialResourceRef() or nil
            if normalizedValue ~= "" and normalizedValue == tostring(selectedSpecialRef or "") and Profile.SetSpecialResourceRef then
                Profile.SetSpecialResourceRef(nil)
            end
            if Profile.SetPrimaryResourceRef then
                Profile.SetPrimaryResourceRef(normalizedValue ~= "" and normalizedValue or nil)
            end
            refreshActionBarResourceDisplay()
            self:Refresh()
        end,
    })
    self.PrimaryResourceDropdown:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", RESOURCE_SELECTOR_LEFT_X, RESOURCE_SELECTOR_DROPDOWN_Y)

    self.SpecialResourceLabel = UI.CreateText(controlsContent, "RPEProfileSpecialResourceLabel", "Special Resource", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = RESOURCE_SELECTOR_DROPDOWN_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
    self.SpecialResourceLabel:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", RESOURCE_SELECTOR_RIGHT_X, RESOURCE_SELECTOR_LABEL_Y)

    self.SpecialResourceDropdown = UI.CreateDropdown(controlsContent, "RPEProfileSpecialResourceDropdown", {
        width = RESOURCE_SELECTOR_DROPDOWN_WIDTH,
        height = RESOURCE_SELECTOR_DROPDOWN_HEIGHT,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function(value)
            local normalizedValue = type(value) == "string" and value or ""
            local selectedPrimaryRef = Profile.GetPrimaryResourceRef and Profile.GetPrimaryResourceRef() or nil
            if normalizedValue ~= "" and normalizedValue == tostring(selectedPrimaryRef or "") and Profile.SetPrimaryResourceRef then
                Profile.SetPrimaryResourceRef(nil)
            end
            if Profile.SetSpecialResourceRef then
                Profile.SetSpecialResourceRef(normalizedValue ~= "" and normalizedValue or nil)
            end
            refreshActionBarResourceDisplay()
            self:Refresh()
        end,
    })
    self.SpecialResourceDropdown:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", RESOURCE_SELECTOR_RIGHT_X, RESOURCE_SELECTOR_DROPDOWN_Y)

    self.LevelLabel = UI.CreateText(controlsContent, "RPEProfileLevelLabel", "Level", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = LEVEL_CONTROL_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
    self.LevelLabel:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", LEVEL_SELECTOR_X, RESOURCE_SELECTOR_LABEL_Y)

    self.LevelInput = UI.CreateTextInput(controlsContent, "RPEProfileLevelInput", {
        width = LEVEL_CONTROL_WIDTH,
        height = RESOURCE_SELECTOR_DROPDOWN_HEIGHT,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.LevelInput:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", LEVEL_SELECTOR_X, RESOURCE_SELECTOR_DROPDOWN_Y)
    self.LevelInput:SetScript("OnEnterPressed", function()
        if Profile.SetLevel then
            Profile.SetLevel(self.LevelInput:GetText())
        end
        self:Refresh()
    end)
    self.LevelInput:SetScript("OnEditFocusLost", function()
        if Profile.SetLevel then
            Profile.SetLevel(self.LevelInput:GetText())
        end
        self:Refresh()
    end)

    self.RaceLabel = UI.CreateText(controlsContent, "RPEProfileRaceLabel", "Race", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = PROFILE_SELECTOR_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
    self.RaceLabel:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", RACE_SELECTOR_X, PROFILE_CONTROL_LABEL_Y)

    self.RaceDropdown = UI.CreateDropdown(controlsContent, "RPEProfileRaceDropdown", {
        width = PROFILE_SELECTOR_WIDTH,
        height = RESOURCE_SELECTOR_DROPDOWN_HEIGHT,
        items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if Profile.SetRaceRef then
                Profile.SetRaceRef(value ~= "" and value or nil)
            end
            refreshTraitRuntimeForProfileSelection("profile-race")
            self:Refresh()
        end,
    })
    self.RaceDropdown:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", RACE_SELECTOR_X, PROFILE_CONTROL_INPUT_Y)

    self.ClassLabel = UI.CreateText(controlsContent, "RPEProfileClassLabel", "Class", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = PROFILE_SELECTOR_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
    self.ClassLabel:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", CLASS_SELECTOR_X, PROFILE_CONTROL_LABEL_Y)

    self.ClassDropdown = UI.CreateDropdown(controlsContent, "RPEProfileClassDropdown", {
        width = PROFILE_SELECTOR_WIDTH,
        height = RESOURCE_SELECTOR_DROPDOWN_HEIGHT,
        items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if Profile.SetClassRef then
                Profile.SetClassRef(value ~= "" and value or nil)
            end
            refreshTraitRuntimeForProfileSelection("profile-class")
            self:Refresh()
        end,
    })
    self.ClassDropdown:GetFrame():SetPoint("TOPLEFT", controlsContent, "TOPLEFT", CLASS_SELECTOR_X, PROFILE_CONTROL_INPUT_Y)

    self.EquipmentBody = UI.CreatePanel(self.EquipmentLayout:GetFrame(), "RPEProfileEquipmentBody", {
        width = EQUIPMENT_PANEL_WIDTH,
        height = 292,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.EquipmentLayout:AddChild(self.EquipmentBody)

    local statsContent = self.StatsPanel:GetContentFrame()
    self.StatsLayout = UI.CreateLayout(UI.VerticalLayoutGroup, statsContent, "RPEProfileStatsPanelLayout", {
        spacing = 0,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.StatsLayout, statsContent, 0, 0, 0, 0)

    self.HealthPanel = UI.CreatePanel(self.StatsLayout:GetFrame(), "RPEProfileHealthPanel", {
        width = STATS_SCROLL_WIDTH,
        height = HEALTH_PANEL_HEIGHT,
        contentInset = 0,
        showBorder = false,
        frameStrata = "HIGH",
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.StatsLayout:AddChild(self.HealthPanel)

    local healthContent = self.HealthPanel:GetContentFrame()
    self.HealthEntry = UI.StatEntry:New({
        name = "RPEProfileMaximumHealthEntry",
        width = HEALTH_ENTRY_WIDTH,
        height = 14,
        valueWidth = HEALTH_ENTRY_VALUE_WIDTH,
        statNameColor = HEALTH_TEXT_COLOR,
        statValueColor = HEALTH_TEXT_COLOR,
        frameStrata = "HIGH",
    })
    self.HealthEntry:SetParent(healthContent)
    self.HealthEntry:Create()
    self.HealthEntry:GetFrame():SetPoint("TOPLEFT", healthContent, "TOPLEFT", 0, 0)
    self.HealthEntry:GetFrame():SetPoint("TOPRIGHT", healthContent, "TOPRIGHT", 0, 0)
    self.HealthEntry:SetLayoutMetrics(HEALTH_ENTRY_WIDTH, HEALTH_ENTRY_VALUE_WIDTH)

    self.PrimaryHealthResourceEntry = UI.StatEntry:New({
        name = "RPEProfileMaximumPrimaryResourceEntry",
        width = HEALTH_ENTRY_WIDTH,
        height = 14,
        valueWidth = HEALTH_ENTRY_VALUE_WIDTH,
        statNameColor = HEALTH_TEXT_COLOR,
        statValueColor = HEALTH_TEXT_COLOR,
        frameStrata = "HIGH",
    })
    self.PrimaryHealthResourceEntry:SetParent(healthContent)
    self.PrimaryHealthResourceEntry:Create()
    self.PrimaryHealthResourceEntry:GetFrame():SetPoint("TOPLEFT", healthContent, "TOPLEFT", 0, -18)
    self.PrimaryHealthResourceEntry:GetFrame():SetPoint("TOPRIGHT", healthContent, "TOPRIGHT", 0, -18)
    self.PrimaryHealthResourceEntry:SetLayoutMetrics(HEALTH_ENTRY_WIDTH, HEALTH_ENTRY_VALUE_WIDTH)

    self.MovementSpeedPanel = UI.CreatePanel(self.StatsLayout:GetFrame(), "RPEProfileMovementSpeedPanel", {
        width = STATS_SCROLL_WIDTH,
        height = MOVEMENT_SPEED_PANEL_HEIGHT,
        contentInset = 0,
        showBorder = false,
        frameStrata = "HIGH",
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.StatsLayout:AddChild(self.MovementSpeedPanel)

    local movementContent = self.MovementSpeedPanel:GetContentFrame()
    self.MovementSpeedEntry = UI.StatEntry:New({
        name = "RPEProfileMovementSpeedEntry",
        width = HEALTH_ENTRY_WIDTH,
        height = 14,
        valueWidth = HEALTH_ENTRY_VALUE_WIDTH,
        statNameColor = HEALTH_TEXT_COLOR,
        statValueColor = HEALTH_TEXT_COLOR,
        frameStrata = "HIGH",
    })
    self.MovementSpeedEntry:SetParent(movementContent)
    self.MovementSpeedEntry:Create()
    self.MovementSpeedEntry:GetFrame():SetPoint("TOPLEFT", movementContent, "TOPLEFT", 0, 0)
    self.MovementSpeedEntry:GetFrame():SetPoint("TOPRIGHT", movementContent, "TOPRIGHT", 0, 0)
    self.MovementSpeedEntry:SetLayoutMetrics(HEALTH_ENTRY_WIDTH, HEALTH_ENTRY_VALUE_WIDTH)

    self.StatSectionGapPanel = UI.CreatePanel(self.StatsLayout:GetFrame(), "RPEProfileStatSectionGapPanel", {
        width = STATS_SCROLL_WIDTH,
        height = STATS_SECTION_GAP_HEIGHT,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.StatsLayout:AddChild(self.StatSectionGapPanel)
    local statsPanelFrame = self.StatsPanel and self.StatsPanel.GetFrame and self.StatsPanel:GetFrame() or nil
    local healthPanelFrame = self.HealthPanel and self.HealthPanel.GetFrame and self.HealthPanel:GetFrame() or nil
    local healthEntryFrame = self.HealthEntry and self.HealthEntry.GetFrame and self.HealthEntry:GetFrame() or nil
    local primaryHealthEntryFrame = self.PrimaryHealthResourceEntry and self.PrimaryHealthResourceEntry.GetFrame and self.PrimaryHealthResourceEntry:GetFrame() or nil
    local movementSpeedPanelFrame = self.MovementSpeedPanel and self.MovementSpeedPanel.GetFrame and self.MovementSpeedPanel:GetFrame() or nil
    local movementSpeedEntryFrame = self.MovementSpeedEntry and self.MovementSpeedEntry.GetFrame and self.MovementSpeedEntry:GetFrame() or nil
    local baseLevel = statsPanelFrame and statsPanelFrame.GetFrameLevel and statsPanelFrame:GetFrameLevel() or 0

    if healthPanelFrame and healthPanelFrame.SetFrameStrata then
        healthPanelFrame:SetFrameStrata("HIGH")
    end
    if healthPanelFrame and healthPanelFrame.SetFrameLevel then
        healthPanelFrame:SetFrameLevel(baseLevel + HEALTH_PANEL_FRAME_LEVEL_OFFSET)
    end
    if healthContent and healthContent.SetFrameLevel and healthPanelFrame and healthPanelFrame.GetFrameLevel then
        healthContent:SetFrameLevel((healthPanelFrame:GetFrameLevel() or baseLevel) + 1)
    end
    if healthEntryFrame and healthEntryFrame.SetFrameStrata then
        healthEntryFrame:SetFrameStrata("HIGH")
    end
    if healthEntryFrame and healthEntryFrame.SetFrameLevel then
        healthEntryFrame:SetFrameLevel(baseLevel + HEALTH_ENTRY_FRAME_LEVEL_OFFSET)
    end
    if primaryHealthEntryFrame and primaryHealthEntryFrame.SetFrameStrata then
        primaryHealthEntryFrame:SetFrameStrata("HIGH")
    end
    if primaryHealthEntryFrame and primaryHealthEntryFrame.SetFrameLevel then
        primaryHealthEntryFrame:SetFrameLevel(baseLevel + HEALTH_ENTRY_FRAME_LEVEL_OFFSET)
    end
    if movementSpeedPanelFrame and movementSpeedPanelFrame.SetFrameStrata then
        movementSpeedPanelFrame:SetFrameStrata("HIGH")
    end
    if movementSpeedPanelFrame and movementSpeedPanelFrame.SetFrameLevel then
        movementSpeedPanelFrame:SetFrameLevel(baseLevel + HEALTH_PANEL_FRAME_LEVEL_OFFSET)
    end
    if movementContent and movementContent.SetFrameLevel and movementSpeedPanelFrame and movementSpeedPanelFrame.GetFrameLevel then
        movementContent:SetFrameLevel((movementSpeedPanelFrame:GetFrameLevel() or baseLevel) + 1)
    end
    if movementSpeedEntryFrame and movementSpeedEntryFrame.SetFrameStrata then
        movementSpeedEntryFrame:SetFrameStrata("HIGH")
    end
    if movementSpeedEntryFrame and movementSpeedEntryFrame.SetFrameLevel then
        movementSpeedEntryFrame:SetFrameLevel(baseLevel + HEALTH_ENTRY_FRAME_LEVEL_OFFSET)
    end
    local body = self.EquipmentBody:GetContentFrame()

    self.ItemLevelSummaryPanel = UI.CreatePanel(body, "RPEProfileItemLevelSummaryPanel", {
        width = ITEM_LEVEL_SUMMARY_WIDTH,
        height = ITEM_LEVEL_SUMMARY_HEIGHT,
        contentInset = 0,
        showBorder = false,
        frameStrata = "HIGH",
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    local itemLevelSummaryFrame = self.ItemLevelSummaryPanel:GetFrame()
    itemLevelSummaryFrame:SetPoint("TOP", body, "TOP", 0, -2)
    if itemLevelSummaryFrame.SetFrameStrata then
        itemLevelSummaryFrame:SetFrameStrata("HIGH")
    end
    if itemLevelSummaryFrame.SetFrameLevel and body and body.GetFrameLevel then
        itemLevelSummaryFrame:SetFrameLevel((body:GetFrameLevel() or 0) + HEALTH_ENTRY_FRAME_LEVEL_OFFSET)
    end

    self.ItemLevelSummaryText = UI.CreateText(self.ItemLevelSummaryPanel:GetContentFrame(), "RPEProfileItemLevelSummaryText", "Item Level: --", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "text.primary"),
        width = ITEM_LEVEL_SUMMARY_WIDTH,
        height = ITEM_LEVEL_SUMMARY_HEIGHT,
        justifyH = "CENTER",
    })
    self.ItemLevelSummaryText:GetFrame():SetPoint("TOPLEFT", self.ItemLevelSummaryPanel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.ItemLevelSummaryText:GetFrame():SetPoint("TOPRIGHT", self.ItemLevelSummaryPanel:GetContentFrame(), "TOPRIGHT", 0, 0)

    self.LeftColumn = UI.CreateLayout(UI.VerticalLayoutGroup, body, "RPEProfileEquipmentLeftColumn", {
        width = SLOT_SIZE,
        height = MODEL_HEIGHT,
        spacing = SLOT_SPACING,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
        autoSize = true,
    })
    self.LeftColumn:SetPoint("LEFT", body, "LEFT", 0, 8)
    self.LeftColumn:Create()

    self.RightColumn = UI.CreateLayout(UI.VerticalLayoutGroup, body, "RPEProfileEquipmentRightColumn", {
        width = SLOT_SIZE,
        height = MODEL_HEIGHT,
        spacing = SLOT_SPACING,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
        autoSize = true,
    })
    self.RightColumn:SetPoint("RIGHT", body, "RIGHT", 0, 8)
    self.RightColumn:Create()

    self.ModelFrame = CreateFrame("PlayerModel", "RPEProfilePlayerModel", body)
    self.ModelFrame:SetSize(MODEL_WIDTH, MODEL_HEIGHT)
    self.ModelFrame:SetPoint("TOP", body, "TOP", 0, MODEL_TOP_OFFSET_Y)
    if self.ModelFrame.SetUnit then
        self.ModelFrame:SetUnit("player")
    end
    if self.ModelFrame.SetRotation then
        self.ModelFrame:SetRotation(0.25 * math.pi)
    end
    if self.ModelFrame.SetCamDistanceScale then
        self.ModelFrame:SetCamDistanceScale(0.7)
    end
    if self.ModelFrame.SetPosition then
        self.ModelFrame:SetPosition(0, 0, -0.25)
    end

    self.BottomRow = UI.CreateLayout(UI.HorizontalLayoutGroup, body, "RPEProfileEquipmentBottomRow", {
        width = 240,
        height = SLOT_SIZE,
        spacing = SLOT_SPACING,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
        autoSize = true,
    })
    self.BottomRow:SetPoint("TOP", self.ModelFrame, "BOTTOM", 0, -10)
    self.BottomRow:Create()

    local bottomRowFrame = self.BottomRow:GetFrame()
    local scopePanelWidth = (EQUIPMENT_SCOPE_BUTTON_SIZE * 3) + (EQUIPMENT_SCOPE_BUTTON_GAP * 2) + (EQUIPMENT_SCOPE_PANEL_PADDING_X * 2)
    local scopePanelHeight = EQUIPMENT_SCOPE_BUTTON_SIZE + (EQUIPMENT_SCOPE_PANEL_PADDING_Y * 2)
    self.EquipmentScopePanel = UI.CreatePanel(body, "RPEProfileEquipmentScopePanel", {
        width = scopePanelWidth,
        height = scopePanelHeight,
        contentInset = 0,
        showBorder = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = { r = 0.04, g = 0.05, b = 0.07, a = 0.88 },
    })
    local scopePanelFrame = self.EquipmentScopePanel:GetFrame()
    scopePanelFrame:SetPoint("BOTTOM", bottomRowFrame, "TOP", 0, EQUIPMENT_SCOPE_BUTTON_OFFSET_Y)
    if scopePanelFrame.SetFrameStrata then
        scopePanelFrame:SetFrameStrata("HIGH")
    end
    if scopePanelFrame.SetFrameLevel and body and body.GetFrameLevel then
        scopePanelFrame:SetFrameLevel((body:GetFrameLevel() or 0) + 11)
    end
    local scopePanelContent = self.EquipmentScopePanel:GetContentFrame()

    self.MountScopeButton = createEquipmentScopeButton(self, scopePanelContent, "mount", "RPEProfileMountScopeButton")
    self.MountScopeButton:GetFrame():SetPoint("CENTER", scopePanelContent, "CENTER", 0, 0)

    self.CharacterScopeButton = createEquipmentScopeButton(self, scopePanelContent, "character", "RPEProfileCharacterScopeButton")
    self.CharacterScopeButton:GetFrame():SetPoint("RIGHT", self.MountScopeButton:GetFrame(), "LEFT", -EQUIPMENT_SCOPE_BUTTON_GAP, 0)

    self.PetScopeButton = createEquipmentScopeButton(self, scopePanelContent, "pet", "RPEProfilePetScopeButton")
    self.PetScopeButton:GetFrame():SetPoint("LEFT", self.MountScopeButton:GetFrame(), "RIGHT", EQUIPMENT_SCOPE_BUTTON_GAP, 0)

    self.StatScrollPanel = UI.CreatePanel(self.StatsLayout:GetFrame(), "RPEProfileStatsScrollPanel", {
        width = STATS_SCROLL_WIDTH,
        height = STAT_SCROLL_HEIGHT,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.StatsLayout:AddChild(self.StatScrollPanel)

    self.StatScroll = UI.ScrollLayout:New({
        name = "RPEProfileStatsScroll",
        width = STATS_SCROLL_WIDTH,
        height = STAT_SCROLL_HEIGHT,
        visibleRows = STAT_VISIBLE_ROWS,
        rowHeight = STAT_ROW_HEIGHT,
        rowSpacing = STAT_ROW_SPACING,
        border = false,
        rowElementClass = UI.Text,
    })
    self.StatScroll:SetParent(self.StatScrollPanel:GetContentFrame())
    self.StatScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetText then
            row:SetText("")
        end

        local rowFrame = row.GetFrame and row:GetFrame() or nil
        if not rowFrame or not item then
            return
        end
        if rowFrame.EnableMouse then
            rowFrame:EnableMouse(true)
        end
        if not row._statHoverHooksApplied and rowFrame.HookScript then
            rowFrame:HookScript("OnEnter", function()
                local hoveredStatRow = row.StatEntry and row.StatEntry.statRow or nil
                if row.StatHoverTexture and row.StatHoverTexture.Show then
                    row.StatHoverTexture:Show()
                end

                local tooltip = buildStatTooltip(hoveredStatRow)
                if tooltip and UI.Tooltip and UI.Tooltip.ShowForElement then
                    UI.Tooltip:ShowForElement(rowFrame, tooltip)
                end
            end)
            rowFrame:HookScript("OnLeave", function()
                if row.StatHoverTexture and row.StatHoverTexture.Hide then
                    row.StatHoverTexture:Hide()
                end
                if UI.Tooltip and UI.Tooltip.Hide then
                    UI.Tooltip:Hide()
                end
            end)
            rowFrame:HookScript("OnHide", function()
                if row.StatHoverTexture and row.StatHoverTexture.Hide then
                    row.StatHoverTexture:Hide()
                end
                if UI.Tooltip and UI.Tooltip.Hide then
                    UI.Tooltip:Hide()
                end
            end)
            row._statHoverHooksApplied = true
        end

        if not row.StatHeader then
            row.StatHeader = rowFrame:CreateFontString(nil, "OVERLAY")
            row.StatHeader:SetPoint("LEFT", rowFrame, "LEFT", 2, 0)
            row.StatHeader:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
            row.StatHeader:SetJustifyH("LEFT")
            row.StatHeader:SetJustifyV("MIDDLE")
            if UI.Font and UI.Font.Apply then
                UI.Font:Apply(row.StatHeader, {}, {
                    fontSize = 10,
                })
            end
            if row.StatHeader.SetTextColor then
                row.StatHeader:SetTextColor(STAT_HEADER_COLOR.r or 0.8, STAT_HEADER_COLOR.g or 0.8, STAT_HEADER_COLOR.b or 0.8, STAT_HEADER_COLOR.a or 1)
            end
        end

        if not row.StatHoverTexture then
            row.StatHoverTexture = rowFrame:CreateTexture(nil, "BACKGROUND")
            row.StatHoverTexture:SetAllPoints(rowFrame)
            row.StatHoverTexture:SetColorTexture(1, 1, 1, 0.08)
            row.StatHoverTexture:Hide()
        end

        if not row.StatEntry then
            row.StatEntry = UI.StatEntry:New({
                name = ("RPEProfileStatEntry%d"):format(itemIndex),
                width = STAT_ENTRY_WIDTH,
                height = 14,
                valueWidth = STAT_ENTRY_VALUE_WIDTH,
                statNameColor = STAT_TEXT_COLOR,
                statValueColor = STAT_TEXT_COLOR,
            })
            row.StatEntry:SetParent(rowFrame)
            row.StatEntry:Create()
            row.StatEntry:GetFrame():SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
            row.StatEntry:GetFrame():SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
        end
        local statEntryFrame = row.StatEntry and row.StatEntry.GetFrame and row.StatEntry:GetFrame() or nil
        if statEntryFrame and statEntryFrame.EnableMouse then
            statEntryFrame:EnableMouse(false)
        end

        local headerType = type(item) == "table" and item.rowType or nil
        if headerType == "header" then
            if row.StatHeader and row.StatHeader.SetText then
                row.StatHeader:SetText(tostring(item.category or ""))
                row.StatHeader:Show()
            end
            if statEntryFrame and statEntryFrame.Hide then
                statEntryFrame:Hide()
            end
            if row.StatHoverTexture and row.StatHoverTexture.Hide then
                row.StatHoverTexture:Hide()
            end
            if row.StatEntry then
                row.StatEntry.statRow = nil
            end
            return
        end

        local statRow = type(item) == "table" and item.statRow or nil
        if row.StatHeader and row.StatHeader.Hide then
            row.StatHeader:Hide()
        end

        if statEntryFrame and statEntryFrame.Show then
            statEntryFrame:Show()
        end

        if not statRow then
            return
        end

        row.StatEntry:SetIcon(ensureString(statRow.icon, "Interface\\Icons\\INV_Misc_QuestionMark"))
        row.StatEntry:SetStatName(ensureString(statRow.name, statRow.statId or "Stat"))
        row.StatEntry:SetStatValue(formatStatValue(statRow))
        row.StatEntry.statRow = statRow
        if row.StatEntry.nameRegion and row.StatEntry.nameRegion.SetTextColor then
            row.StatEntry.nameRegion:SetTextColor(STAT_TEXT_COLOR.r, STAT_TEXT_COLOR.g, STAT_TEXT_COLOR.b, STAT_TEXT_COLOR.a)
        end
        if row.StatEntry.valueRegion and row.StatEntry.valueRegion.SetTextColor then
            row.StatEntry.valueRegion:SetTextColor(STAT_TEXT_COLOR.r, STAT_TEXT_COLOR.g, STAT_TEXT_COLOR.b, STAT_TEXT_COLOR.a)
        end
    end)
    self.StatScroll:Create()
    UI.Utils.AnchorFill(self.StatScroll, self.StatScrollPanel:GetContentFrame(), 0, 0, 0, 0)

    self:ApplyMetrics()
    self:Refresh()
    return self.frame
end

function EquipmentStatsPage:Refresh()
    if not self.frame or not self.owner then
        return nil
    end

    self:ApplyMetrics()
    local owner = self.owner
    local scope = self:GetActiveEquipmentScope()
    local layout = self:GetActiveEquipmentLayout() or { left = {}, right = {}, bottom = {}, ordered = {} }
    local statRows = Profile.ListProfileStatRows and Profile.ListProfileStatRows() or {}
    local resourceRows = Profile.ListResolvedResources and Profile.ListResolvedResources() or {}
    local healthResourceRef = getHealthResourceRef()
    local layoutSignature = buildLayoutSignature(layout)
    self:RefreshScopeButtons()
    self:RefreshEquipmentHeader()
    if self.LastLayoutSignature ~= layoutSignature then
        self.LastLayoutSignature = layoutSignature
        self:ApplySlotLayout(layout)
    end

    for index = 1, #(layout.ordered or {}) do
        updateSlotVisual(self, layout.ordered[index])
    end

    local selectedSlotKey = owner.SelectedSlotKey
    if selectedSlotKey and selectedSlotKey ~= "" then
        local found = false
        for index = 1, #(layout.ordered or {}) do
            if layout.ordered[index] == selectedSlotKey then
                found = true
                break
            end
        end

        if not found then
            owner.SelectedSlotKey = nil
        end
    end

    refreshStatRows(self, statRows)
    refreshHealthEntry(self, resourceRows, healthResourceRef)
    refreshMovementSpeedEntry(self)
    refreshItemLevelSummary(self, layout)
    refreshResourceSelectors(self, resourceRows, healthResourceRef)
    refreshProfileSelectors(self)
    return self.frame
end

return EquipmentStatsPage
