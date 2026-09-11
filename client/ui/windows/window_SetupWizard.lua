local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.SetupWizard = Addon.Client.UI.SetupWizard or {}

local Client = Addon.Client
local SetupWizard = Addon.Client.UI.SetupWizard
local UI = Addon.UI or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local RulesetLogic = Addon.Internal and Addon.Internal.Ruleset or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Equipment = Addon.Internal and Addon.Internal.Profile and Addon.Internal.Profile.Equipment or {}
local Inventory = Addon.Client and Addon.Client.Inventory or {}
local TooltipBuilders = Addon.Client and Addon.Client.UI and Addon.Client.UI.Tooltips or {}
local ItemClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Item or {}
local Timings = Addon.Debug and Addon.Debug.Timings or {}

SetupWizard.__index = SetupWizard

local WINDOW_WIDTH = 520
local WINDOW_HEIGHT = 352
local CONTENT_WIDTH = 468
local PAGE_SPACING = 6
local FOOTER_RESERVED_HEIGHT = 34
local SECTION_HEIGHT = 232
local CHOICE_COLUMNS = 4
local CHOICE_SLOT_SIZE = 40
local CHOICE_LABEL_HEIGHT = 12
local ITEM_SEARCH_HEIGHT = 18
local ITEM_SLOT_COLUMNS = 8
local ITEM_SLOT_ROWS = 5
local ITEM_SLOT_SIZE = 40
local ITEM_SLOT_SPACING = 4
local ITEM_PAGE_SIZE = ITEM_SLOT_COLUMNS * ITEM_SLOT_ROWS
local ACTIONBAR_SLOT_SIZE = 30
local ACTIONBAR_SLOT_SPACING = 4
local ACTIONBAR_DATASET_PANEL_WIDTH = 124
local ACTIONBAR_SPELLBOOK_COLUMNS = 4
local ACTIONBAR_SPELLBOOK_ROWS = 4
local ACTIONBAR_SPELLBOOK_ENTRY_HEIGHT = 34
local ACTIONBAR_SPELLBOOK_COLUMN_SPACING = 10
local ACTIONBAR_SPELLBOOK_ROW_SPACING = 6
local ACTIONBAR_SPELLBOOK_NAV_HEIGHT = 20
local ACTIONBAR_SPELLBOOK_ENTRIES_PER_PAGE = ACTIONBAR_SPELLBOOK_COLUMNS * ACTIONBAR_SPELLBOOK_ROWS
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local COPPER_CURRENCY_KEY = "copper"
local SETUP_WIZARD_TIMING_THRESHOLD_MS = 16

local DEFAULT_SLOT_BORDER = { r = 0.42, g = 0.46, b = 0.52, a = 1 }
local SELECTED_SLOT_BORDER = { r = 0.64, g = 0.82, b = 0.38, a = 1 }
local ACTIONBAR_SELECTED_SLOT_BORDER = { r = 0.94, g = 0.74, b = 0.22, a = 1 }

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimString(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeSearchToken(value)
    return string.lower(trimString(value))
end

local function parseCommaSeparatedList(text)
    local items = {}
    local seen = {}

    for token in string.gmatch(ensureString(text), "([^,]+)") do
        local normalized = normalizeSearchToken(token)
        if normalized ~= "" and not seen[normalized] then
            seen[normalized] = true
            items[#items + 1] = normalized
        end
    end

    return items
end

local function appendUnique(items, seen, entry)
    local value = trimString(entry and entry.value)
    if value == "" or seen[value] then
        return
    end

    seen[value] = true
    items[#items + 1] = entry
end

local function setFrameShown(target, shown)
    local frame = target and target.GetFrame and target:GetFrame() or target
    if frame and frame.SetShown then
        frame:SetShown(shown == true)
    end
end

local function applyTextureColor(texture, color)
    if texture and texture.SetColorTexture then
        texture:SetColorTexture(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end
end

local function startSetupTiming(label, context)
    if type(Timings) == "table" and type(Timings.Start) == "function" then
        return Timings:Start(label, {
            context = context,
            thresholdMs = SETUP_WIZARD_TIMING_THRESHOLD_MS,
        })
    end

    return nil
end

local function stopSetupTiming(timer, cardinality)
    if timer and type(Timings) == "table" and type(Timings.Stop) == "function" then
        Timings:Stop(timer, {
            cardinality = cardinality,
        })
    end
end

local function measureSetupTiming(label, context, fn)
    if type(Timings) == "table" and type(Timings.Measure) == "function" then
        return Timings:Measure(label, fn, {
            context = context,
            thresholdMs = SETUP_WIZARD_TIMING_THRESHOLD_MS,
        })
    end

    return fn()
end

local function selectionLookupFromArray(items)
    local lookup = {}
    for index = 1, #(items or {}) do
        local value = trimString(items[index])
        if value ~= "" then
            lookup[value] = true
        end
    end

    return lookup
end

local function selectionArrayFromLookup(orderedItems, lookup)
    local results = {}
    for index = 1, #(orderedItems or {}) do
        local value = trimString(orderedItems[index] and orderedItems[index].value)
        if value ~= "" and lookup[value] == true then
            results[#results + 1] = value
        end
    end
    return results
end

local function findEntryByValue(items, value)
    local needle = trimString(value)
    if needle == "" then
        return nil
    end

    for index = 1, #(items or {}) do
        local entry = items[index]
        if trimString(entry and entry.value) == needle then
            return entry
        end
    end

    return nil
end

local function buildReferenceLabel(dataset, entry)
    local datasetLabel = Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or tostring(dataset and dataset.name or dataset and dataset.id or "")
    local entryLabel = tostring(entry and entry.name or entry and entry.id or "")
    return ("%s / %s"):format(datasetLabel, entryLabel)
end

local function itemMatchesAnyTag(item, allowedTags)
    if #allowedTags == 0 then
        return false
    end

    for itemTagIndex = 1, #(item and item.tags or {}) do
        local itemTag = normalizeSearchToken(item.tags[itemTagIndex])
        for allowedIndex = 1, #allowedTags do
            if itemTag ~= "" and itemTag == allowedTags[allowedIndex] then
                return true
            end
        end
    end

    return false
end

local function buildItemTooltipSpec(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local datasetName = entry.dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(entry.dataset) or tostring(entry.dataset and (entry.dataset.name or entry.dataset.id) or "")
    local builder = TooltipBuilders and TooltipBuilders.Item or nil
    if builder and builder.Build then
        return builder:Build(entry.item or {
            id = entry.itemId,
            name = entry.label or "Unknown Item",
        }, {
            dataset = entry.dataset,
            datasetId = entry.datasetId,
            datasetName = datasetName,
            itemId = entry.itemId,
            isActive = true,
            isMissing = false,
            soulbound = false,
            modifications = {},
        })
    end

    return {
        title = tostring(entry.item and entry.item.name or entry.label or "Unknown Item"),
        lines = {
            datasetName ~= "" and ("Dataset: " .. datasetName) or nil,
            entry.itemId and ("Item ID: " .. tostring(entry.itemId)) or nil,
        },
    }
end

local function createInstance()
    return setmetatable({
        window = nil,
        cachedState = nil,
        selectedRaceRef = "",
        selectedClassRef = "",
        selectedStartingItemLookup = {},
        startingItemFilterQuery = "",
        startingItemPage = 1,
        availableStartingItems = {},
        filteredStartingItems = {},
        startingItemFeedback = "",
        raceChoices = {},
        classChoices = {},
        startingItemSlots = {},
        actionBarSlotDropdowns = {},
        actionBarSlotRows = {},
        selectedActionBarSlotIndex = 1,
        actionBarDummySlots = {},
        actionBarSpellEntries = {},
        actionBarDatasetRows = {},
        actionBarFilteredSpellRows = {},
        currentActionBarSpellPage = 1,
        selectedActionBarDatasetId = nil,
        selectedActionBarSpellbookCategory = nil,
        finalizeLines = {},
        hasDraftSelectionState = false,
        refreshRequestId = 0,
        needsDatasetPolicyRefresh = false,
        tabRefreshHooksInstalled = false,
    }, SetupWizard)
end

function SetupWizard:Get()
    if not self._singleton then
        self._singleton = createInstance()
    end

    return self._singleton
end

function SetupWizard:GetActiveRuleset()
    if type(RulesetLogic.GetActiveRuleset) ~= "function" then
        return nil
    end

    return RulesetLogic.GetActiveRuleset()
end

function SetupWizard:GetRuleValue(ruleKey, fallback)
    if type(RulesetLogic.GetRulesetRuleValueByKey) ~= "function" then
        return fallback
    end

    return RulesetLogic.GetRulesetRuleValueByKey(self:GetActiveRuleset(), "setup", ruleKey, fallback)
end

function SetupWizard:IsEnabled()
    return self:GetRuleValue("enable_setup_wizard", false) == true
end

function SetupWizard:GetForcedDatasetIds()
    local values = self:GetRuleValue("forced_dataset_ids", {})
    return type(values) == "table" and values or {}
end

function SetupWizard:GetStartingItemBudgetCopper()
    return math.max(0, math.floor(tonumber(self:GetRuleValue("starting_item_budget_copper", 0)) or 0))
end

function SetupWizard:GetRequiredStartingItemSlotRefs()
    local values = self:GetRuleValue("required_starting_item_slot_refs", {})
    return type(values) == "table" and values or {}
end

function SetupWizard:ApplyDatasetPolicy()
    local forcedDatasetIds = self:GetForcedDatasetIds()
    local forceDeactivateOthers = self:GetRuleValue("force_deactivate_other_datasets", false) == true
    local allDatasets = Database.ListDatasets and Database.ListDatasets() or {}
    local forcedLookup = {}

    for index = 1, #forcedDatasetIds do
        local datasetId = trimString(forcedDatasetIds[index])
        if datasetId ~= "" then
            forcedLookup[datasetId] = true
            if Database.SetDatasetActivated then
                Database.SetDatasetActivated(datasetId, true)
            end
        end
    end

    if forceDeactivateOthers and Database.SetDatasetActivated then
        for index = 1, #allDatasets do
            local dataset = allDatasets[index]
            local datasetId = trimString(dataset and dataset.id)
            if datasetId ~= "" and forcedLookup[datasetId] ~= true then
                Database.SetDatasetActivated(datasetId, false)
            end
        end
    end

    return forcedLookup
end

function SetupWizard:BuildAllowedRaceItems()
    local allowedRefs = self:GetRuleValue("allowed_race_refs", {})
    local allowedLookup = {}
    local restrict = type(allowedRefs) == "table" and #allowedRefs > 0

    for index = 1, #(allowedRefs or {}) do
        allowedLookup[tostring(allowedRefs[index] or "")] = true
    end

    local items = {}
    local seen = {}
    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = trimString(dataset and dataset.id)
        for raceIndex = 1, #(dataset and dataset.races or {}) do
            local race = dataset.races[raceIndex]
            local raceId = trimString(race and race.id)
            if datasetId ~= "" and raceId ~= "" then
                local raceRef = ("%s:%s"):format(datasetId, raceId)
                if not restrict or allowedLookup[raceRef] == true then
                    appendUnique(items, seen, {
                        label = buildReferenceLabel(dataset, race),
                        displayName = tostring(race and race.name or raceId),
                        value = raceRef,
                        icon = trimString(race and race.icon),
                    })
                end
            end
        end
    end

    return items
end

function SetupWizard:BuildAllowedClassItems()
    local allowedRefs = self:GetRuleValue("allowed_class_refs", {})
    local allowedLookup = {}
    local restrict = type(allowedRefs) == "table" and #allowedRefs > 0

    for index = 1, #(allowedRefs or {}) do
        allowedLookup[tostring(allowedRefs[index] or "")] = true
    end

    local items = {}
    local seen = {}
    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = trimString(dataset and dataset.id)
        for classIndex = 1, #(dataset and dataset.classes or {}) do
            local classEntry = dataset.classes[classIndex]
            local classId = trimString(classEntry and classEntry.id)
            if datasetId ~= "" and classId ~= "" then
                local classRef = ("%s:%s"):format(datasetId, classId)
                if not restrict or allowedLookup[classRef] == true then
                    appendUnique(items, seen, {
                        label = buildReferenceLabel(dataset, classEntry),
                        displayName = tostring(classEntry and classEntry.name or classId),
                        value = classRef,
                        icon = trimString(classEntry and classEntry.icon),
                    })
                end
            end
        end
    end

    return items
end

function SetupWizard:BuildAllowedStartingItemItems()
    local allowedTags = parseCommaSeparatedList(self:GetRuleValue("starting_item_tags", ""))
    local items = {}
    local seen = {}
    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = trimString(dataset and dataset.id)
        for itemIndex = 1, #(dataset and dataset.items or {}) do
            local item = dataset.items[itemIndex]
            local itemId = trimString(item and item.id)
            if datasetId ~= "" and itemId ~= "" and itemMatchesAnyTag(item, allowedTags) then
                local itemRef = ("%s:%s"):format(datasetId, itemId)
                appendUnique(items, seen, {
                    label = buildReferenceLabel(dataset, item),
                    value = itemRef,
                    dataset = dataset,
                    datasetId = datasetId,
                    item = item,
                    itemId = itemId,
                    icon = trimString(item and item.icon) ~= "" and trimString(item and item.icon) or DEFAULT_ICON,
                    sellPrice = ItemClass and ItemClass.ResolveSellPrice and math.max(0, math.floor(tonumber(ItemClass.ResolveSellPrice(item)) or 0)) or math.max(0, math.floor(tonumber(item and item.sellPrice) or 0)),
                    searchIndex = normalizeSearchToken(buildReferenceLabel(dataset, item) .. " " .. table.concat(item.tags or {}, " ")),
                })
            end
        end
    end

    table.sort(items, function(left, right)
        return ensureString(left and left.label) < ensureString(right and right.label)
    end)

    return items
end

function SetupWizard:GetSelectedStartingItems()
    local selected = {}
    for index = 1, #(self.availableStartingItems or {}) do
        local entry = self.availableStartingItems[index]
        if self.selectedStartingItemLookup[trimString(entry and entry.value)] == true then
            selected[#selected + 1] = entry
        end
    end

    return selected
end

function SetupWizard:GetSelectedStartingItemTotalPrice()
    local total = 0
    local selected = self:GetSelectedStartingItems()
    for index = 1, #selected do
        total = total + math.max(0, math.floor(tonumber(selected[index] and selected[index].sellPrice) or 0))
    end

    return total
end

local function formatCopperAmount(amount)
    local numeric = math.max(0, math.floor(tonumber(amount) or 0))
    if Profile.FormatCurrencyAmount then
        return Profile.FormatCurrencyAmount(COPPER_CURRENCY_KEY, numeric)
    end

    return ("%dc"):format(numeric)
end

local function formatChoiceLabel(entry, fallbackValue)
    if type(entry) ~= "table" then
        return trimString(fallbackValue) ~= "" and trimString(fallbackValue) or "Unselected"
    end

    local displayName = trimString(entry.displayName)
    if displayName ~= "" then
        return displayName
    end

    local label = trimString(entry.label)
    if label ~= "" then
        return label
    end

    local value = trimString(entry.value)
    if value ~= "" then
        return value
    end

    return trimString(fallbackValue) ~= "" and trimString(fallbackValue) or "Unselected"
end

function SetupWizard:FindSelectedEquipmentSlotForItem(item)
    local layout = Profile.GetEquipmentLayoutByScope and Profile.GetEquipmentLayoutByScope("character") or Profile.GetEquipmentLayout and Profile.GetEquipmentLayout() or nil
    if type(item) ~= "table" or type(layout) ~= "table" then
        return nil, nil
    end

    local occupied = {}
    local selected = self:GetSelectedStartingItems()
    for index = 1, #selected do
        local current = selected[index]
        if current and current.item == item then
            break
        end

        local currentItem = current and current.item or nil
        if currentItem and Equipment.DoesItemFitLayoutEntry then
            for layoutIndex = 1, #(layout.entries or {}) do
                local layoutEntry = layout.entries[layoutIndex]
                if not occupied[layoutEntry.slotKey] then
                    local fits, resolvedSlotRef = Equipment.DoesItemFitLayoutEntry(currentItem, layoutEntry)
                    if fits and resolvedSlotRef then
                        occupied[layoutEntry.slotKey] = true
                        break
                    end
                end
            end
        end
    end

    for layoutIndex = 1, #(layout.entries or {}) do
        local layoutEntry = layout.entries[layoutIndex]
        if layoutEntry and not occupied[layoutEntry.slotKey] and Equipment.DoesItemFitLayoutEntry then
            local fits, resolvedSlotRef = Equipment.DoesItemFitLayoutEntry(item, layoutEntry)
            if fits and resolvedSlotRef then
                return layoutEntry.slotKey, resolvedSlotRef
            end
        end
    end

    return nil, nil
end

function SetupWizard:BuildSelectedEquipmentPlan()
    local selected = self:GetSelectedStartingItems()
    local layout = Profile.GetEquipmentLayoutByScope and Profile.GetEquipmentLayoutByScope("character") or Profile.GetEquipmentLayout and Profile.GetEquipmentLayout() or { entries = {} }
    local occupied = {}
    local plan = {
        retained = {},
        equipped = {},
        inventory = {},
        required = {},
    }

    local currentlyEquipped = Profile.ListEquippedSlots and Profile.ListEquippedSlots() or {}
    for index = 1, #currentlyEquipped do
        local equippedSlot = currentlyEquipped[index]
        local slotKey = trimString(equippedSlot and equippedSlot.slotKey)
        if slotKey ~= "" then
            occupied[slotKey] = true
            local detail = Profile.GetEquippedItemByScope and Profile.GetEquippedItemByScope("character", slotKey) or nil
            plan.retained[#plan.retained + 1] = {
                slotKey = slotKey,
                slotRef = trimString(detail and detail.slotRef),
                itemRef = trimString(detail and detail.itemRef),
                item = detail and detail.item or nil,
                detail = detail,
            }
        end
    end

    for index = 1, #selected do
        local entry = selected[index]
        local item = entry and entry.item or nil
        local assigned = false

        if item and Equipment.DoesItemFitLayoutEntry then
            for layoutIndex = 1, #(layout.entries or {}) do
                local layoutEntry = layout.entries[layoutIndex]
                if layoutEntry and not occupied[layoutEntry.slotKey] then
                    local fits, resolvedSlotRef = Equipment.DoesItemFitLayoutEntry(item, layoutEntry)
                    if fits and resolvedSlotRef then
                        occupied[layoutEntry.slotKey] = true
                        plan.equipped[#plan.equipped + 1] = {
                            slotKey = layoutEntry.slotKey,
                            slotRef = resolvedSlotRef,
                            itemRef = entry.value,
                            entry = entry,
                        }
                        assigned = true
                        break
                    end
                end
            end
        end

        if not assigned then
            plan.inventory[#plan.inventory + 1] = entry
        end
    end

    local requiredSlotRefs = self:GetRequiredStartingItemSlotRefs()
    for index = 1, #requiredSlotRefs do
        local slotRef = trimString(requiredSlotRefs[index])
        if slotRef ~= "" then
            local slotKey = Equipment.ResolveSlotKeyFromRef and Equipment.ResolveSlotKeyFromRef(slotRef) or slotRef
            local matched = false
            for retainedIndex = 1, #plan.retained do
                local retainedEntry = plan.retained[retainedIndex]
                if retainedEntry and (
                    trimString(retainedEntry.slotRef) == slotRef
                    or trimString(retainedEntry.slotKey) == trimString(slotKey)
                ) then
                    matched = true
                    break
                end
            end
            for equippedIndex = 1, #plan.equipped do
                local equippedEntry = plan.equipped[equippedIndex]
                if not matched and equippedEntry and (
                    trimString(equippedEntry.slotRef) == slotRef
                    or trimString(equippedEntry.slotKey) == trimString(slotKey)
                ) then
                    matched = true
                    break
                end
            end

            plan.required[#plan.required + 1] = {
                slotRef = slotRef,
                slotKey = slotKey,
                label = Profile.GetSlotLabel and Profile.GetSlotLabel(slotKey) or tostring(slotKey),
                satisfied = matched,
            }
        end
    end

    return plan
end

function SetupWizard:ValidateCurrentItemSelection()
    local budget = self:GetStartingItemBudgetCopper()
    local totalPrice = self:GetSelectedStartingItemTotalPrice()
    local plan = self:BuildSelectedEquipmentPlan()
    local missing = {}

    for index = 1, #(plan.required or {}) do
        local requirement = plan.required[index]
        if requirement and requirement.satisfied ~= true then
            missing[#missing + 1] = requirement.label or tostring(requirement.slotKey or requirement.slotRef or "")
        end
    end

    return {
        budget = budget,
        totalPrice = totalPrice,
        withinBudget = budget <= 0 or totalPrice <= budget,
        remainingBudget = math.max(0, budget - totalPrice),
        plan = plan,
        missingRequiredSlots = missing,
        passesRequiredSlots = #missing == 0,
    }
end

function SetupWizard:BuildAllowedActionBarSpellItems()
    local items = {
        { label = "None", value = "" },
    }
    local seen = {
        [""] = true,
    }

    local rows = Profile.ListKnownSpells and Profile.ListKnownSpells() or {}
    for index = 1, #rows do
        local row = rows[index]
        local spellRef = trimString(row and row.spellRef)
        local detail = type(Profile.GetKnownSpellDetails) == "function" and Profile.GetKnownSpellDetails(spellRef) or nil
        if spellRef ~= ""
            and type(detail) == "table"
            and tostring(detail.learnMode or "") == "always_learned"
        then
            appendUnique(items, seen, {
                label = ("%s%s"):format(
                    tostring(detail.name or spellRef),
                    detail.datasetName and detail.datasetName ~= "" and (" (" .. detail.datasetName .. ")") or ""
                ),
                value = spellRef,
            })
        end
    end

    return items
end

function SetupWizard:CaptureSelectionState()
    local setupState = Profile.GetSetupWizardState and Profile.GetSetupWizardState() or {}
    local actionBarSpellRefs = {}
    local actionBarSize = Profile.GetActionBarSize and Profile.GetActionBarSize() or 0

    for slotIndex = 1, actionBarSize do
        local detail = Profile.GetActionBarSlotDetails and Profile.GetActionBarSlotDetails(slotIndex) or nil
        local currentSpellRef = trimString(detail and detail.spellRef)
        if currentSpellRef ~= "" then
            actionBarSpellRefs[slotIndex] = currentSpellRef
        elseif type(setupState.actionBarSpellRefs) == "table" then
            local storedSpellRef = trimString(setupState.actionBarSpellRefs[slotIndex])
            if storedSpellRef ~= "" then
                actionBarSpellRefs[slotIndex] = storedSpellRef
            end
        end
    end

    return {
        raceRef = trimString(Profile.GetRaceRef and Profile.GetRaceRef() or setupState.raceRef),
        classRef = trimString(Profile.GetClassRef and Profile.GetClassRef() or setupState.classRef),
        startingItemRefs = type(setupState.startingItemRefs) == "table" and setupState.startingItemRefs or {},
        actionBarSpellRefs = actionBarSpellRefs,
    }
end

function SetupWizard:SyncSelectionState(state)
    self.selectedRaceRef = trimString(state and state.raceRef)
    self.selectedClassRef = trimString(state and state.classRef)
    self.selectedStartingItemLookup = selectionLookupFromArray(state and state.startingItemRefs or {})
    self.hasDraftSelectionState = true
end

local function createSectionPanel(parent, name, width)
    return UI.CreatePanel(parent, name, {
        width = width,
        height = SECTION_HEIGHT,
        contentInset = 6,
    })
end

function SetupWizard:EnsureChoiceChoice(collectionKey, index, parent, onClick)
    local collection = self[collectionKey]
    if collection[index] then
        collection[index]._setupWizardOnClick = onClick
        return collection[index]
    end

    local host = CreateFrame("Button", ("RPESetupWizard%sChoice%d"):format(collectionKey, index), parent)
    host:SetSize(84, CHOICE_SLOT_SIZE + CHOICE_LABEL_HEIGHT + 2)
    host:RegisterForClicks("AnyUp")
    host:SetScript("OnClick", function()
        if type(host._setupWizardOnClick) == "function" then
            host._setupWizardOnClick()
        end
    end)
    host._setupWizardOnClick = onClick

    local slot = UI.ObjectSlot:New({
        name = ("RPESetupWizard%sChoiceSlot%d"):format(collectionKey, index),
        width = CHOICE_SLOT_SIZE,
        height = CHOICE_SLOT_SIZE,
        size = CHOICE_SLOT_SIZE,
        iconTexture = DEFAULT_ICON,
        border = false,
    })
    slot:SetParent(host)
    slot:Create()
    slot:GetFrame():SetPoint("TOP", host, "TOP", 0, 0)
    slot:SetScript("OnClick", function()
        if type(host._setupWizardOnClick) == "function" then
            host._setupWizardOnClick()
        end
    end)

    local label = UI.CreateText(host, ("RPESetupWizard%sChoiceLabel%d"):format(collectionKey, index), "", {
        width = 84,
        height = CHOICE_LABEL_HEIGHT,
        justifyH = "CENTER",
        fontSize = 7,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    label:GetFrame():SetPoint("TOP", slot:GetFrame(), "BOTTOM", 0, -2)

    local choice = {
        frame = host,
        slot = slot,
        label = label,
        GetFrame = function(self)
            return self.frame
        end,
    }

    collection[index] = choice
    return choice
end

local function applyChoiceVisual(choice, isSelected, labelText, iconTexture, tooltipText)
    if not choice then
        return
    end

    if choice.slot then
        choice.slot:SetIcon(trimString(iconTexture) ~= "" and iconTexture or DEFAULT_ICON)
        if isSelected then
            choice.slot:SetBorderColor(SELECTED_SLOT_BORDER.r, SELECTED_SLOT_BORDER.g, SELECTED_SLOT_BORDER.b, SELECTED_SLOT_BORDER.a)
        else
            choice.slot:SetBorderColor(DEFAULT_SLOT_BORDER.r, DEFAULT_SLOT_BORDER.g, DEFAULT_SLOT_BORDER.b, DEFAULT_SLOT_BORDER.a)
        end
        choice.slot:SetTooltip({
            title = labelText or "",
            lines = {
                tooltipText,
            },
        })
    end

    if choice.label and choice.label.SetText then
        choice.label:SetText(labelText or "")
    end
    if choice.label and choice.label.SetTextColor then
        if isSelected then
            choice.label:SetTextColor(0.95, 0.98, 0.88, 1)
        else
            local color = UI.ResolveColor(nil, "text.secondary")
            choice.label:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        end
    end
end

function SetupWizard:BuildIdentityPage(page)
    if self.IdentityPageBuilt then
        return
    end

    self.IdentityPageBuilt = true
    self.IdentityPage = page

    self.IdentityHintText = UI.CreateText(page, "RPESetupWizardIdentityHintText", "Choose the race and class allowed by the active ruleset.", {
        width = CONTENT_WIDTH,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.IdentityHintText:GetFrame():SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.IdentityHintText:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)

    local sectionWidth = math.floor((CONTENT_WIDTH - 8) / 2)

    self.RacePanel = createSectionPanel(page, "RPESetupWizardRacePanel", sectionWidth)
    self.RacePanel:GetFrame():SetPoint("TOPLEFT", self.IdentityHintText:GetFrame(), "BOTTOMLEFT", 0, -6)

    self.ClassPanel = createSectionPanel(page, "RPESetupWizardClassPanel", sectionWidth)
    self.ClassPanel:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -20)

    self.RaceTitle = UI.CreateText(self.RacePanel:GetContentFrame(), "RPESetupWizardRaceTitle", "Race", {
        width = sectionWidth - 12,
        height = 12,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.RaceTitle:GetFrame():SetPoint("TOP", self.RacePanel:GetContentFrame(), "TOP", 0, 0)

    self.ClassTitle = UI.CreateText(self.ClassPanel:GetContentFrame(), "RPESetupWizardClassTitle", "Class", {
        width = sectionWidth - 12,
        height = 12,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ClassTitle:GetFrame():SetPoint("TOP", self.ClassPanel:GetContentFrame(), "TOP", 0, 0)

    local gridWidth = sectionWidth - 12
    local cellWidth = math.floor((gridWidth - ((CHOICE_COLUMNS - 1) * 4)) / CHOICE_COLUMNS)

    self.RaceGrid = UI.CreateLayout(UI.GridLayoutGroup, self.RacePanel:GetContentFrame(), "RPESetupWizardRaceGrid", {
        width = gridWidth,
        height = SECTION_HEIGHT - 24,
        columns = CHOICE_COLUMNS,
        cellWidth = cellWidth,
        cellHeight = CHOICE_SLOT_SIZE + CHOICE_LABEL_HEIGHT + 2,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.RaceGrid:GetFrame():SetPoint("TOPLEFT", self.RaceTitle:GetFrame(), "BOTTOMLEFT", 0, -4)

    self.ClassGrid = UI.CreateLayout(UI.GridLayoutGroup, self.ClassPanel:GetContentFrame(), "RPESetupWizardClassGrid", {
        width = gridWidth,
        height = SECTION_HEIGHT - 24,
        columns = CHOICE_COLUMNS,
        cellWidth = cellWidth,
        cellHeight = CHOICE_SLOT_SIZE + CHOICE_LABEL_HEIGHT + 2,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.ClassGrid:GetFrame():SetPoint("TOPLEFT", self.ClassTitle:GetFrame(), "BOTTOMLEFT", 0, -4)
end

function SetupWizard:BuildStartingItemsPage(page)
    if self.StartingItemsPageBuilt then
        return
    end

    self.StartingItemsPageBuilt = true
    self.StartingItemsPage = page

    self.StartingItemsHintText = UI.CreateText(page, "RPESetupWizardItemsHintText", "Choose the starter items allowed by the active ruleset tags.", {
        width = CONTENT_WIDTH,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.StartingItemsHintText:GetFrame():SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.StartingItemsHintText:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)

    self.StartingItemsSearchLabel = UI.CreateText(page, "RPESetupWizardItemsSearchLabel", "Search:", {
        width = 36,
        height = ITEM_SEARCH_HEIGHT,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.StartingItemsSearchLabel:GetFrame():SetPoint("TOPLEFT", self.StartingItemsHintText:GetFrame(), "BOTTOMLEFT", 0, -6)

    self.StartingItemsSearchClearButton = UI.CreateButton(page, "RPESetupWizardItemsSearchClearButton", "Clear", 36, function()
        self.startingItemFilterQuery = ""
        self.startingItemPage = 1
        if self.StartingItemsSearchInput and self.StartingItemsSearchInput.SetText then
            self.StartingItemsSearchInput:SetText("")
        end
        self:RefreshStartingItemsPage(self.cachedState or self:CaptureSelectionState())
    end, {
        height = ITEM_SEARCH_HEIGHT,
        fontSize = 7,
    })
    self.StartingItemsSearchClearButton:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -20)

    self.StartingItemsSearchInput = UI.CreateTextInput(page, "RPESetupWizardItemsSearchInput", {
        width = CONTENT_WIDTH - 80,
        height = ITEM_SEARCH_HEIGHT,
        text = "",
    })
    self.StartingItemsSearchInput:GetFrame():SetPoint("TOPLEFT", self.StartingItemsSearchLabel:GetFrame(), "TOPRIGHT", 4, 0)
    self.StartingItemsSearchInput:GetFrame():SetPoint("TOPRIGHT", self.StartingItemsSearchClearButton:GetFrame(), "TOPLEFT", -4, 0)
    self.StartingItemsSearchInput:SetScript("OnTextChanged", function(_, text)
        self.startingItemFilterQuery = tostring(text or "")
        self.startingItemPage = 1
        self:RefreshStartingItemsPage(self.cachedState or self:CaptureSelectionState())
    end)
    self.StartingItemsSearchInput:SetScript("OnEnterPressed", function(_, text)
        self.startingItemFilterQuery = tostring(text or "")
        self.startingItemPage = 1
        self:RefreshStartingItemsPage(self.cachedState or self:CaptureSelectionState())
    end)

    self.StartingItemsSummaryText = UI.CreateText(page, "RPESetupWizardItemsSummaryText", "", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.StartingItemsSummaryText:GetFrame():SetPoint("TOPLEFT", self.StartingItemsSearchInput:GetFrame(), "BOTTOMLEFT", -40, -6)

    self.StartingItemsRequirementText = UI.CreateText(page, "RPESetupWizardItemsRequirementText", "", {
        width = 148,
        height = 14,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.StartingItemsRequirementText:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -44)

    self.StartingItemsNextButton = UI.TextButton:New({
        name = "RPESetupWizardItemsNextButton",
        width = 22,
        height = 18,
        text = ">",
        fontSize = 11,
        border = false,
    })
    self.StartingItemsNextButton:SetParent(page)
    self.StartingItemsNextButton:Create()
    self.StartingItemsNextButton:SetScript("OnClick", function()
        self.startingItemPage = self.startingItemPage + 1
        self:RefreshStartingItemsPage(self.cachedState or self:CaptureSelectionState())
    end)
    self.StartingItemsNextButton:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -44)

    self.StartingItemsPrevButton = UI.TextButton:New({
        name = "RPESetupWizardItemsPrevButton",
        width = 22,
        height = 18,
        text = "<",
        fontSize = 11,
        border = false,
    })
    self.StartingItemsPrevButton:SetParent(page)
    self.StartingItemsPrevButton:Create()
    self.StartingItemsPrevButton:SetScript("OnClick", function()
        self.startingItemPage = math.max(1, self.startingItemPage - 1)
        self:RefreshStartingItemsPage(self.cachedState or self:CaptureSelectionState())
    end)
    self.StartingItemsPrevButton:GetFrame():SetPoint("RIGHT", self.StartingItemsNextButton:GetFrame(), "LEFT", -4, 0)

    self.StartingItemsPageLabel = UI.CreateText(page, "RPESetupWizardItemsPageLabel", "Page 0 / 0", {
        width = 84,
        height = 18,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.StartingItemsPageLabel:GetFrame():SetPoint("RIGHT", self.StartingItemsPrevButton:GetFrame(), "LEFT", -6, 0)

    self.StartingItemsPanel = UI.CreatePanel(page, "RPESetupWizardItemsPanel", {
        width = CONTENT_WIDTH,
        height = 240,
        contentInset = 6,
    })
    self.StartingItemsPanel:GetFrame():SetPoint("TOPLEFT", self.StartingItemsSummaryText:GetFrame(), "BOTTOMLEFT", 0, -4)
    self.StartingItemsPanel:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -42)

    self.StartingItemsGrid = UI.CreateLayout(UI.GridLayoutGroup, self.StartingItemsPanel:GetContentFrame(), "RPESetupWizardItemsGrid", {
        width = (ITEM_SLOT_COLUMNS * ITEM_SLOT_SIZE) + ((ITEM_SLOT_COLUMNS - 1) * ITEM_SLOT_SPACING),
        height = (ITEM_SLOT_ROWS * ITEM_SLOT_SIZE) + ((ITEM_SLOT_ROWS - 1) * ITEM_SLOT_SPACING),
        columns = ITEM_SLOT_COLUMNS,
        cellWidth = ITEM_SLOT_SIZE,
        cellHeight = ITEM_SLOT_SIZE,
        spacing = ITEM_SLOT_SPACING,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.StartingItemsGrid:GetFrame():SetPoint("TOPLEFT", self.StartingItemsPanel:GetContentFrame(), "TOPLEFT", 2, 0)

    self.StartingItemsEmptyText = UI.CreateText(self.StartingItemsPanel:GetContentFrame(), "RPESetupWizardItemsEmptyText", "", {
        width = CONTENT_WIDTH - 16,
        height = 24,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.StartingItemsEmptyText:GetFrame():SetPoint("CENTER", self.StartingItemsPanel:GetContentFrame(), "CENTER", 0, 0)
end

function SetupWizard:BuildFinalizePage(page)
    if self.FinalizePageBuilt then
        return
    end

    self.FinalizePageBuilt = true
    self.FinalizePage = page

    self.FinalizePageRoot = CreateFrame("Frame", "RPESetupWizardFinalizePageRoot", page)
    UI.Utils.AnchorFill(self.FinalizePageRoot, page, 0, 0, 0, FOOTER_RESERVED_HEIGHT)

    self.FinalizeHintText = UI.CreateText(self.FinalizePageRoot, "RPESetupWizardFinalizeHintText", "Review the final setup below. Apply will overwrite character equipment and action-bar bindings.", {
        width = CONTENT_WIDTH,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.FinalizeHintText:GetFrame():SetPoint("TOPLEFT", self.FinalizePageRoot, "TOPLEFT", 0, 0)
    self.FinalizeHintText:GetFrame():SetPoint("TOPRIGHT", self.FinalizePageRoot, "TOPRIGHT", 0, 0)

    self.FinalizeSummaryPanel = UI.CreatePanel(self.FinalizePageRoot, "RPESetupWizardFinalizeSummaryPanel", {
        width = CONTENT_WIDTH,
        height = 220,
        contentInset = 6,
    })
    self.FinalizeSummaryPanel:GetFrame():SetPoint("TOPLEFT", self.FinalizeHintText:GetFrame(), "BOTTOMLEFT", 0, -6)
    self.FinalizeSummaryPanel:GetFrame():SetPoint("TOPRIGHT", self.FinalizePageRoot, "TOPRIGHT", 0, 0)

    self.FinalizeSummaryScroll = UI.ScrollLayout:New({
        name = "RPESetupWizardFinalizeSummaryScroll",
        width = CONTENT_WIDTH - 12,
        height = 208,
        visibleRows = 11,
        autoFitRows = true,
        minVisibleRows = 4,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        compact = true,
        rowElementClass = UI.ScrollListEntry,
        compactCategoryWidth = 0,
        compactStatusWidth = 0,
        compactCategoryInsetLeft = 0,
        compactNameInsetLeft = 0,
        compactStatusInsetRight = 0,
        rowInsetLeft = 0,
        rowInsetRight = 0,
        contentInsetLeft = 0,
        contentInsetRight = 0,
    })
    self.FinalizeSummaryScroll:SetParent(self.FinalizeSummaryPanel:GetContentFrame())
    self.FinalizeSummaryScroll:SetRowRenderer(function(row, item)
        local line = tostring(item and item.text or "")
        if row.SetCategory then
            row:SetCategory("")
        end
        if row.SetTestName then
            row:SetTestName(line)
        elseif row.SetText then
            row:SetText(line)
        end
        if row.SetStatus then
            row:SetStatus("")
        end
        if row.SetDetail then
            row:SetDetail("")
        end
        if row.SetTooltip then
            row:SetTooltip(nil)
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame and frame.EnableMouse then
            frame:EnableMouse(false)
        end
    end)
    self.FinalizeSummaryScroll:Create()
    self.FinalizeSummaryScroll:SetPoint("TOPLEFT", self.FinalizeSummaryPanel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.FinalizeSummaryScroll:SetPoint("BOTTOMRIGHT", self.FinalizeSummaryPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.FinalizeApplyButton = UI.CreateButton(self.FinalizePageRoot, "RPESetupWizardFinalizeApplyButton", "Apply", 72, function()
        self:ApplyCurrentSelection()
    end, {
        height = 20,
        fontSize = 7,
    })
    local finalizeApplyFrame = self.FinalizeApplyButton.GetFrame and self.FinalizeApplyButton:GetFrame() or nil
    if finalizeApplyFrame then
        finalizeApplyFrame:SetPoint("BOTTOM", self.FinalizePageRoot, "BOTTOM", 0, 0)
    end

    local finalizeSummaryFrame = self.FinalizeSummaryPanel.GetFrame and self.FinalizeSummaryPanel:GetFrame() or nil
    if finalizeSummaryFrame and finalizeApplyFrame then
        finalizeSummaryFrame:ClearAllPoints()
        finalizeSummaryFrame:SetPoint("TOPLEFT", self.FinalizeHintText:GetFrame(), "BOTTOMLEFT", 0, -6)
        finalizeSummaryFrame:SetPoint("TOPRIGHT", self.FinalizePageRoot, "TOPRIGHT", 0, 0)
        finalizeSummaryFrame:SetPoint("BOTTOM", finalizeApplyFrame, "TOP", 0, 8)
    end
end

function SetupWizard:BuildActionBarPage(page)
    if self.ActionBarPageRoot then
        return self.ActionBarPageRoot
    end

    self.ActionBarPageRoot = CreateFrame("Frame", "RPESetupWizardActionBarPageRoot", page)
    UI.Utils.AnchorFill(self.ActionBarPageRoot, page, 0, 0, 0, FOOTER_RESERVED_HEIGHT)

    self.ActionBarHintText = UI.CreateText(self.ActionBarPageRoot, "RPESetupWizardActionBarHintText",
        "Choose a slot above, then click an always-learned spell below to place it on the bar.", {
            width = CONTENT_WIDTH,
            height = 14,
            justifyH = "LEFT",
            textColor = UI.ResolveColor(nil, "text.secondary"),
        }
    )
    self.ActionBarHintText:GetFrame():SetPoint("TOPLEFT", self.ActionBarPageRoot, "TOPLEFT", 0, 0)
    self.ActionBarHintText:GetFrame():SetPoint("TOPRIGHT", self.ActionBarPageRoot, "TOPRIGHT", 0, 0)

    self.ActionBarDummyBarPanel = UI.CreatePanel(self.ActionBarPageRoot, "RPESetupWizardDummyActionBarPanel", {
        width = CONTENT_WIDTH,
        height = 60,
        contentInset = 6,
    })
    self.ActionBarDummyBarPanel:GetFrame():SetPoint("TOPLEFT", self.ActionBarHintText:GetFrame(), "BOTTOMLEFT", 0, -6)
    self.ActionBarDummyBarPanel:GetFrame():SetPoint("TOPRIGHT", self.ActionBarPageRoot, "TOPRIGHT", 0, -20)

    self.ActionBarDummyBarLabel = UI.CreateText(self.ActionBarDummyBarPanel:GetContentFrame(), "RPESetupWizardDummyActionBarLabel", "Action Bar", {
        width = 120,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ActionBarDummyBarLabel:GetFrame():SetPoint("TOPLEFT", self.ActionBarDummyBarPanel:GetContentFrame(), "TOPLEFT", 0, 0)

    self.ActionBarDummyBarHost = CreateFrame("Frame", "RPESetupWizardDummyActionBarHost", self.ActionBarDummyBarPanel:GetContentFrame())
    self.ActionBarDummyBarHost:SetPoint("CENTER", self.ActionBarDummyBarPanel:GetContentFrame(), "CENTER", 0, -4)
    self.ActionBarDummyBarHost:SetSize(1, ACTIONBAR_SLOT_SIZE)

    self.ActionBarBody = UI.CreateLayout(UI.HorizontalLayoutGroup, self.ActionBarPageRoot, "RPESetupWizardActionBarBody", {
        width = CONTENT_WIDTH,
        height = 208,
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    self.ActionBarBody:GetFrame():SetPoint("TOPLEFT", self.ActionBarDummyBarPanel:GetFrame(), "BOTTOMLEFT", 0, -6)
    self.ActionBarBody:GetFrame():SetPoint("TOPRIGHT", self.ActionBarPageRoot, "TOPRIGHT", 0, -86)

    self.ActionBarDatasetPanel = UI.CreatePanel(self.ActionBarBody:GetFrame(), "RPESetupWizardActionBarDatasetPanel", {
        width = ACTIONBAR_DATASET_PANEL_WIDTH,
        height = 208,
        contentInset = 2,
        showBorder = false,
    })
    self.ActionBarBody:AddChild(self.ActionBarDatasetPanel)

    self.ActionBarGridPanel = UI.CreatePanel(self.ActionBarBody:GetFrame(), "RPESetupWizardActionBarGridPanel", {
        width = 1,
        height = 208,
        expandWidth = true,
        weight = 1,
        contentInset = 0,
        showBorder = false,
    })
    self.ActionBarBody:AddChild(self.ActionBarGridPanel)

    self.ActionBarDatasetList = UI.ScrollLayout:New({
        name = "RPESetupWizardActionBarDatasetList",
        width = ACTIONBAR_DATASET_PANEL_WIDTH - 4,
        height = 204,
        visibleRows = 10,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 66,
        statusWidth = 26,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.ActionBarDatasetList:SetParent(self.ActionBarDatasetPanel:GetContentFrame())
    self.ActionBarDatasetList:SetRowRenderer(function(row, item)
        if row.SetCategory then
            row:SetCategory(item and item.name or "")
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(tostring(item and item.count or 0))
        end
        if row.SetDetail then
            row:SetDetail("")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and item and item.datasetId then
                    self:SelectActionBarNavigationItem(item)
                    self:RefreshActionBarPage(self.cachedState or self:CaptureSelectionState())
                end
            end)

            local isSelected = self:IsActionBarNavigationItemSelected(item)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.ActionBarDatasetList:Create()
    UI.Utils.AnchorFill(self.ActionBarDatasetList, self.ActionBarDatasetPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ActionBarDatasetEmptyText = UI.CreateText(self.ActionBarDatasetPanel:GetContentFrame(), "RPESetupWizardActionBarDatasetEmptyText", "", {
        width = 120,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ActionBarDatasetEmptyText:GetFrame():SetPoint("CENTER", self.ActionBarDatasetPanel:GetContentFrame(), "CENTER", 0, 0)

    self.ActionBarGridTitle = UI.CreateText(self.ActionBarGridPanel:GetContentFrame(), "RPESetupWizardActionBarGridTitle", "Spellbook", {
        width = CONTENT_WIDTH - ACTIONBAR_DATASET_PANEL_WIDTH - 20,
        height = 18,
        justifyH = "LEFT",
    })
    self.ActionBarGridTitle:GetFrame():SetPoint("TOPLEFT", self.ActionBarGridPanel:GetContentFrame(), "TOPLEFT", 6, -2)

    self.ActionBarGridHost = CreateFrame("Frame", "RPESetupWizardActionBarGridHost", self.ActionBarGridPanel:GetContentFrame())
    self.ActionBarGridHost:SetPoint("TOPLEFT", self.ActionBarGridPanel:GetContentFrame(), "TOPLEFT", 0, -22)
    self.ActionBarGridHost:SetPoint("BOTTOMRIGHT", self.ActionBarGridPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.ActionBarEntryContentFrame = CreateFrame("Frame", "RPESetupWizardActionBarEntryContent", self.ActionBarGridHost)
    self.ActionBarEntryContentFrame:SetPoint("TOPLEFT", self.ActionBarGridHost, "TOPLEFT", 0, 0)
    self.ActionBarEntryContentFrame:SetPoint("TOPRIGHT", self.ActionBarGridHost, "TOPRIGHT", 0, 0)
    self.ActionBarEntryContentFrame:SetPoint("BOTTOMLEFT", self.ActionBarGridHost, "BOTTOMLEFT", 0, ACTIONBAR_SPELLBOOK_NAV_HEIGHT)
    self.ActionBarEntryContentFrame:SetPoint("BOTTOMRIGHT", self.ActionBarGridHost, "BOTTOMRIGHT", 0, ACTIONBAR_SPELLBOOK_NAV_HEIGHT)

    self.ActionBarEntryListFrame = CreateFrame("Frame", "RPESetupWizardActionBarEntryList", self.ActionBarEntryContentFrame)
    self.ActionBarEntryListFrame:SetPoint("TOP", self.ActionBarEntryContentFrame, "TOP", 0, -4)
    self.ActionBarEntryListFrame:SetSize(1, 1)

    self.ActionBarSpellPageNav = CreateFrame("Frame", "RPESetupWizardActionBarSpellPageNav", self.ActionBarGridHost)
    self.ActionBarSpellPageNav:SetPoint("BOTTOMLEFT", self.ActionBarGridHost, "BOTTOMLEFT", 6, 0)
    self.ActionBarSpellPageNav:SetPoint("BOTTOMRIGHT", self.ActionBarGridHost, "BOTTOMRIGHT", -6, 0)
    self.ActionBarSpellPageNav:SetHeight(ACTIONBAR_SPELLBOOK_NAV_HEIGHT)

    self.ActionBarGridEmptyText = UI.CreateText(self.ActionBarGridHost, "RPESetupWizardActionBarGridEmptyText", "", {
        width = 160,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ActionBarGridEmptyText:GetFrame():SetPoint("CENTER", self.ActionBarGridHost, "CENTER", 0, 0)

    self.ActionBarSpellPageNextButton = UI.TextButton:New({
        name = "RPESetupWizardActionBarSpellPageNextButton",
        width = 22,
        height = 18,
        text = ">",
        fontSize = 11,
        border = false,
    })
    self.ActionBarSpellPageNextButton:SetParent(self.ActionBarSpellPageNav)
    self.ActionBarSpellPageNextButton:Create()
    self.ActionBarSpellPageNextButton:SetScript("OnClick", function()
        self:NextActionBarSpellPage()
    end)
    self.ActionBarSpellPageNextButton:GetFrame():SetPoint("RIGHT", self.ActionBarSpellPageNav, "RIGHT", 0, 0)

    self.ActionBarSpellPagePrevButton = UI.TextButton:New({
        name = "RPESetupWizardActionBarSpellPagePrevButton",
        width = 22,
        height = 18,
        text = "<",
        fontSize = 11,
        border = false,
    })
    self.ActionBarSpellPagePrevButton:SetParent(self.ActionBarSpellPageNav)
    self.ActionBarSpellPagePrevButton:Create()
    self.ActionBarSpellPagePrevButton:SetScript("OnClick", function()
        self:PreviousActionBarSpellPage()
    end)
    self.ActionBarSpellPagePrevButton:GetFrame():SetPoint("RIGHT", self.ActionBarSpellPageNextButton:GetFrame(), "LEFT", -4, 0)

    self.ActionBarSpellPageLabel = UI.CreateText(self.ActionBarSpellPageNav, "RPESetupWizardActionBarSpellPageLabel", "Page 0 / 0", {
        width = 84,
        height = 18,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ActionBarSpellPageLabel:GetFrame():SetPoint("RIGHT", self.ActionBarSpellPagePrevButton:GetFrame(), "LEFT", -8, 0)

    for index = 1, ACTIONBAR_SPELLBOOK_ENTRIES_PER_PAGE do
        self:EnsureActionBarSpellEntry(index)
    end

    return self.ActionBarPageRoot
end

function SetupWizard:EnsureStartingItemSlot(index)
    if self.startingItemSlots[index] then
        return self.startingItemSlots[index]
    end

    local slot = UI.ObjectSlot:New({
        name = ("RPESetupWizardStartingItemSlot%d"):format(index),
        width = ITEM_SLOT_SIZE,
        height = ITEM_SLOT_SIZE,
        size = ITEM_SLOT_SIZE,
        iconTexture = DEFAULT_ICON,
        border = false,
    })
    slot:SetParent(self.StartingItemsGrid:GetFrame())
    slot:Create()
    slot:SetScript("OnClick", function()
        local entry = slot.setupWizardEntry
        local itemRef = trimString(entry and entry.value)
        if itemRef == "" then
            return
        end

        if self.selectedStartingItemLookup[itemRef] == true then
            self.selectedStartingItemLookup[itemRef] = nil
            self.startingItemFeedback = ""
        else
            local budget = self:GetStartingItemBudgetCopper()
            local nextTotal = self:GetSelectedStartingItemTotalPrice() + math.max(0, math.floor(tonumber(entry and entry.sellPrice) or 0))
            if budget > 0 and nextTotal > budget then
                self.startingItemFeedback = ("Budget exceeded: %s / %s"):format(formatCopperAmount(nextTotal), formatCopperAmount(budget))
                self:RefreshStartingItemsPage(self.cachedState or self:CaptureSelectionState())
                if self.FinalizePageBuilt then
                    self:RefreshFinalizePage()
                end
                return
            end
            self.selectedStartingItemLookup[itemRef] = true
            self.startingItemFeedback = ""
        end

        self:RefreshStartingItemsPage(self.cachedState or self:CaptureSelectionState())
        if self.FinalizePageBuilt then
            self:RefreshFinalizePage()
        end
    end)

    self.StartingItemsGrid:AddChild(slot)
    self.startingItemSlots[index] = slot
    return slot
end

function SetupWizard:EnsureActionBarSlotRow(slotIndex)
    if self.actionBarSlotRows[slotIndex] then
        return self.actionBarSlotRows[slotIndex], self.actionBarSlotDropdowns[slotIndex]
    end

    local row = UI.CreateLayout(UI.HorizontalLayoutGroup, self.ActionBarPageRoot:GetFrame(), "RPESetupWizardActionBarRow" .. slotIndex, {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 18,
    })
    local label = UI.CreateText(row:GetFrame(), "RPESetupWizardActionBarLabel" .. slotIndex, ("Slot %d"):format(slotIndex), {
        width = 136,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    row:AddChild(label)

    local dropdown = UI.CreateDropdown(row:GetFrame(), "RPESetupWizardActionBarDropdown" .. slotIndex, {
        width = 228,
        height = 18,
        items = {},
    })
    row:AddChild(dropdown)
    self.ActionBarPageRoot:AddChild(row)

    self.actionBarSlotRows[slotIndex] = row
    self.actionBarSlotDropdowns[slotIndex] = dropdown
    return row, dropdown
end

function SetupWizard:EnsureActionBarDummySlot(slotIndex)
    if self.actionBarDummySlots[slotIndex] then
        return self.actionBarDummySlots[slotIndex]
    end

    local slot = UI.ObjectSlot:New({
        name = ("RPESetupWizardDummyActionBarSlot%d"):format(slotIndex),
        width = ACTIONBAR_SLOT_SIZE,
        height = ACTIONBAR_SLOT_SIZE,
        size = ACTIONBAR_SLOT_SIZE,
        iconTexture = DEFAULT_ICON,
        border = false,
        countText = tostring(slotIndex),
    })
    slot:SetParent(self.ActionBarDummyBarHost)
    slot:Create()
    slot:SetScript("OnClick", function()
        self.selectedActionBarSlotIndex = slotIndex
        self:RefreshActionBarPage(self.cachedState or self:CaptureSelectionState())
    end)
    slot:GetFrame():SetPoint("LEFT", self.ActionBarDummyBarHost, "LEFT", (slotIndex - 1) * (ACTIONBAR_SLOT_SIZE + ACTIONBAR_SLOT_SPACING), 0)
    self.actionBarDummySlots[slotIndex] = slot
    return slot
end

function SetupWizard:EnsureActionBarSpellEntry(index)
    local entry = self.actionBarSpellEntries[index]
    if entry then
        return entry
    end

    entry = UI.SpellbookEntry:New({
        name = ("RPESetupWizardActionBarSpellEntry%d"):format(index),
        width = 104,
        height = ACTIONBAR_SPELLBOOK_ENTRY_HEIGHT,
        iconTexture = DEFAULT_ICON,
        border = false,
    })
    entry:SetParent(self.ActionBarEntryListFrame)
    entry:Create()

    local frame = entry:GetFrame()
    frame:HookScript("OnMouseUp", function(_, button)
        local resolved = entry.resolvedSpell
        if button == "LeftButton" and resolved and resolved.spellRef then
            self:BindWizardSpellToSelectedSlot(resolved.spellRef)
        elseif button == "RightButton" and resolved and resolved.spellRef then
            self:ClearSelectedActionBarSlot()
        end
    end)

    self.actionBarSpellEntries[index] = entry
    return entry
end

function SetupWizard:BuildWindow()
    if self.window then
        return self.window
    end

    local timing = startSetupTiming("SetupWizard.BuildWindow", "create")
    local window = UI.Window:New({
        name = "RPESetupWizardWindow",
        width = WINDOW_WIDTH,
        height = WINDOW_HEIGHT,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 30,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = 12,
        contentInsetRight = 12,
        contentInsetTop = 28,
        contentInsetBottom = 10,
        pagePaddingTop = 4,
        tabs = {
            {
                name = "identity",
                label = "Identity",
                width = 68,
                builder = function(page)
                    measureSetupTiming("SetupWizard.BuildPage", "identity", function()
                        self:BuildIdentityPage(page)
                    end)
                end,
            },
            {
                name = "items",
                label = "Items",
                width = 56,
                builder = function(page)
                    measureSetupTiming("SetupWizard.BuildPage", "items", function()
                        self:BuildStartingItemsPage(page)
                    end)
                end,
            },
            {
                name = "actionbar",
                label = "Action Bar",
                width = 72,
                builder = function(page)
                    measureSetupTiming("SetupWizard.BuildPage", "actionbar", function()
                        self:BuildActionBarPage(page)
                    end)
                end,
            },
            {
                name = "finalize",
                label = "Finalize",
                width = 64,
                builder = function(page)
                    measureSetupTiming("SetupWizard.BuildPage", "finalize", function()
                        self:BuildFinalizePage(page)
                    end)
                end,
            },
        },
    })
    window:SetTitle("Setup Wizard")
    window:Create()
    self.window = window

    local outerContent = window.contentFrame or (window.GetContentFrame and window:GetContentFrame()) or nil
    local footerHost = window.GetFrame and window:GetFrame() or outerContent

    self.ActionsLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, footerHost, "RPESetupWizardActionsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = true,
        height = 20,
    })
    local actionsFrame = self.ActionsLayout:GetFrame()
    actionsFrame:SetPoint("BOTTOMRIGHT", footerHost, "BOTTOMRIGHT", -12, 10)
    actionsFrame:SetFrameStrata("HIGH")
    actionsFrame:SetFrameLevel((footerHost and footerHost.GetFrameLevel and footerHost:GetFrameLevel() or 1) + 20)

    self.ApplyButton = UI.CreateButton(actionsFrame, "RPESetupWizardApplyButton", "Apply", 64, function()
        self:ApplyCurrentSelection()
    end, {
        height = 20,
        fontSize = 7,
    })
    self.ActionsLayout:AddChild(self.ApplyButton)

    self.CloseButton = UI.CreateButton(actionsFrame, "RPESetupWizardCloseButton", "Close", 64, function()
        self:Hide()
    end, {
        height = 20,
        fontSize = 7,
    })
    self.ActionsLayout:AddChild(self.CloseButton)

    self.StatusText = UI.CreateText(footerHost, "RPESetupWizardStatusText", "", {
        width = CONTENT_WIDTH - 140,
        height = 20,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    local statusFrame = self.StatusText.GetFrame and self.StatusText:GetFrame() or nil
    if statusFrame then
        statusFrame:SetPoint("BOTTOMLEFT", footerHost, "BOTTOMLEFT", 12, 10)
        statusFrame:SetPoint("BOTTOMRIGHT", actionsFrame, "BOTTOMLEFT", -8, 2)
        statusFrame:SetFrameStrata("HIGH")
        statusFrame:SetFrameLevel((footerHost and footerHost.GetFrameLevel and footerHost:GetFrameLevel() or 1) + 20)
    end

    self:InstallTabRefreshHooks()
    stopSetupTiming(timing, {
        builtTabs = 1,
    })
    return window
end

function SetupWizard:GetActiveTabIndex()
    local tabContainer = self.window and self.window.tabContainer or nil
    return math.max(1, math.floor(tonumber(tabContainer and tabContainer.activeTabIndex) or 1))
end

function SetupWizard:InstallTabRefreshHooks()
    if self.tabRefreshHooksInstalled == true then
        return
    end

    local tabContainer = self.window and self.window.tabContainer or nil
    if type(tabContainer) ~= "table" then
        return
    end

    for index = 1, #(tabContainer.tabButtons or {}) do
        local button = tabContainer.tabButtons[index]
        local frame = button and button.GetFrame and button:GetFrame() or nil
        if frame and frame.HookScript then
            local tabIndex = index
            frame:HookScript("OnClick", function()
                self:QueuePageRefresh(tabIndex)
            end)
        end
    end

    self.tabRefreshHooksInstalled = true
end

function SetupWizard:RefreshPage(tabIndex, state)
    local index = math.max(1, math.floor(tonumber(tabIndex) or 1))
    local context = ({ "identity", "items", "actionbar", "finalize" })[index] or tostring(index)
    return measureSetupTiming("SetupWizard.RefreshPage", context, function()
        if index == 1 then
            self:RefreshIdentityPage(state)
        elseif index == 2 then
            self:RefreshStartingItemsPage(state)
        elseif index == 3 then
            if not self.ActionBarPageRoot then
                local page = self.window and self.window.tabContainer and self.window.tabContainer.pageFrames and self.window.tabContainer.pageFrames[3] or nil
                if page then
                    self:BuildActionBarPage(page)
                end
            end
            self:RefreshActionBarPage(state)
        elseif index == 4 then
            if not self.FinalizePageBuilt then
                local page = self.window and self.window.tabContainer and self.window.tabContainer.pageFrames and self.window.tabContainer.pageFrames[4] or nil
                if page then
                    self:BuildFinalizePage(page)
                end
            end
            self:RefreshFinalizePage()
        end
    end)
end

function SetupWizard:QueuePageRefresh(tabIndex)
    local requestedTab = math.max(1, math.floor(tonumber(tabIndex) or self:GetActiveTabIndex()))
    self.refreshRequestId = math.max(0, math.floor(tonumber(self.refreshRequestId) or 0)) + 1
    local requestId = self.refreshRequestId

    local function runRefresh()
        if requestId ~= self.refreshRequestId then
            return
        end

        local windowFrame = self.window and self.window.GetFrame and self.window:GetFrame() or nil
        if windowFrame and windowFrame.IsShown and not windowFrame:IsShown() then
            return
        end
        if self:GetActiveTabIndex() ~= requestedTab then
            return
        end

        if self.needsDatasetPolicyRefresh == true then
            local policyTiming = startSetupTiming("SetupWizard.ApplyDatasetPolicy", "show")
            self:ApplyDatasetPolicy()
            stopSetupTiming(policyTiming)
            self.needsDatasetPolicyRefresh = false
        end

        local state = self:CaptureSelectionState()
        self.cachedState = state
        if self.hasDraftSelectionState ~= true then
            self:SyncSelectionState(state)
        end
        self:RefreshPage(requestedTab, state)
        self:RefreshStatus()
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, runRefresh)
    else
        runRefresh()
    end
end

function SetupWizard:RefreshChoiceGrid(collectionKey, layout, items, selectedValue, setter)
    if not layout then
        return
    end

    for index = 1, #items do
        local item = items[index]
        local itemValue = trimString(item and item.value)
        local choice = self:EnsureChoiceChoice(collectionKey, index, layout:GetFrame(), function()
            setter(self, itemValue)
            self:RefreshIdentityPage(self.cachedState or self:CaptureSelectionState())
            if self.FinalizePageBuilt then
                self:RefreshFinalizePage()
            end
        end)

        if not choice:GetFrame():IsShown() then
            choice:GetFrame():Show()
        end

        applyChoiceVisual(
            choice,
            itemValue == trimString(selectedValue),
            tostring(item and (item.displayName or item.name or item.label) or ""),
            item and item.icon or DEFAULT_ICON,
            item and item.label or ""
        )

        if not choice._setupWizardAdded then
            layout:AddChild(choice)
            choice._setupWizardAdded = true
        end
    end

    local collection = self[collectionKey] or {}
    for index = #items + 1, #collection do
        setFrameShown(collection[index], false)
    end

    if layout.RefreshLayout then
        layout:RefreshLayout()
    end
end

function SetupWizard:RefreshIdentityPage(state)
    self:BuildIdentityPage(self.IdentityPage or (self.window and self.window.tabContainer and self.window.tabContainer.GetPageFrame and self.window.tabContainer:GetPageFrame(1)) or nil)

    local raceItems = self:BuildAllowedRaceItems()
    local classItems = self:BuildAllowedClassItems()
    local canChooseRace = type(RulesetLogic.GetRulesetRuleValueByKey) == "function"
        and RulesetLogic.GetRulesetRuleValueByKey(self:GetActiveRuleset(), "character", "use_races", false) == true
    local canChooseClass = type(RulesetLogic.GetRulesetRuleValueByKey) == "function"
        and RulesetLogic.GetRulesetRuleValueByKey(self:GetActiveRuleset(), "character", "use_classes", false) == true

    if trimString(self.selectedRaceRef) == "" then
        self.selectedRaceRef = trimString(state and state.raceRef)
    end
    if trimString(self.selectedClassRef) == "" then
        self.selectedClassRef = trimString(state and state.classRef)
    end

    setFrameShown(self.RacePanel, canChooseRace)
    setFrameShown(self.ClassPanel, canChooseClass)

    self:RefreshChoiceGrid("raceChoices", self.RaceGrid, raceItems, self.selectedRaceRef, function(instance, value)
        instance.selectedRaceRef = value
    end)
    self:RefreshChoiceGrid("classChoices", self.ClassGrid, classItems, self.selectedClassRef, function(instance, value)
        instance.selectedClassRef = value
    end)
end

function SetupWizard:BuildFilteredStartingItems()
    local query = normalizeSearchToken(self.startingItemFilterQuery)
    local filtered = {}

    for index = 1, #(self.availableStartingItems or {}) do
        local entry = self.availableStartingItems[index]
        if query == "" or string.find(tostring(entry.searchIndex or ""), query, 1, true) ~= nil then
            filtered[#filtered + 1] = entry
        end
    end

    self.filteredStartingItems = filtered
    return filtered
end

function SetupWizard:BuildActionBarSpellNavigationRows()
    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
    local knownSpells = Profile.ListKnownSpells and Profile.ListKnownSpells() or {}
    local spellCountsByDataset = {}
    local spellCountsByDatasetAndCategory = {}
    local rows = {}

    for index = 1, #knownSpells do
        local row = knownSpells[index]
        local spellRef = trimString(row and row.spellRef)
        local detail = spellRef ~= "" and Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellRef) or nil
        if type(detail) == "table" and tostring(detail.learnMode or "") == "always_learned" then
            local dataset = row and row.dataset or nil
            if dataset and dataset.id then
                local datasetId = tostring(dataset.id)
                spellCountsByDataset[datasetId] = (spellCountsByDataset[datasetId] or 0) + 1
                local category = trimString(row and row.spellbookCategory)
                if category ~= "" then
                    spellCountsByDatasetAndCategory[datasetId] = spellCountsByDatasetAndCategory[datasetId] or {}
                    spellCountsByDatasetAndCategory[datasetId][category] = (spellCountsByDatasetAndCategory[datasetId][category] or 0) + 1
                end
            end
        end
    end

    for index = 1, #datasets do
        local dataset = datasets[index]
        if dataset and dataset.id then
            local datasetId = tostring(dataset.id)
            local datasetDisplayName = Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or tostring(dataset.name or dataset.id)
            rows[#rows + 1] = {
                rowType = "dataset",
                dataset = dataset,
                datasetId = dataset.id,
                name = datasetDisplayName,
                displayName = datasetDisplayName,
                count = spellCountsByDataset[datasetId] or 0,
            }

            local categories = {}
            local seenCategories = {}
            local categoryCounts = spellCountsByDatasetAndCategory[datasetId] or {}
            for spellIndex = 1, #(dataset.spells or {}) do
                local spell = dataset.spells[spellIndex]
                if tostring(spell and spell.learnMode or "") == "always_learned" then
                    local category = trimString(spell and spell.spellbookCategory)
                    if category ~= "" and not seenCategories[category] then
                        seenCategories[category] = true
                        categories[#categories + 1] = category
                    end
                end
            end

            for category in pairs(categoryCounts) do
                if category and not seenCategories[category] then
                    seenCategories[category] = true
                    categories[#categories + 1] = category
                end
            end

            table.sort(categories, function(left, right)
                return tostring(left) < tostring(right)
            end)

            for categoryIndex = 1, #categories do
                local category = categories[categoryIndex]
                rows[#rows + 1] = {
                    rowType = "category",
                    dataset = dataset,
                    datasetId = dataset.id,
                    category = category,
                    name = ("    %s"):format(category),
                    displayName = category,
                    count = categoryCounts[category] or 0,
                }
            end
        end
    end

    return rows
end

function SetupWizard:EnsureActionBarDatasetSelection(rows)
    local navigationRows = rows or {}
    local datasetSelections = {}
    local firstDatasetWithSpells = nil
    local firstDatasetId = nil

    for index = 1, #navigationRows do
        local row = navigationRows[index]
        if row and row.rowType == "dataset" then
            local datasetId = tostring(row.datasetId or "")
            if datasetId ~= "" then
                if not firstDatasetId then
                    firstDatasetId = row.datasetId
                end
                datasetSelections[datasetId] = datasetSelections[datasetId] or { categories = {} }
                if not firstDatasetWithSpells and (tonumber(row.count) or 0) > 0 then
                    firstDatasetWithSpells = row.datasetId
                end
            end
        elseif row and row.rowType == "category" then
            local datasetId = tostring(row.datasetId or "")
            if datasetId ~= "" then
                datasetSelections[datasetId] = datasetSelections[datasetId] or { categories = {} }
                datasetSelections[datasetId].categories[tostring(row.category or "")] = true
            end
        end
    end

    local selectedDatasetKey = tostring(self.selectedActionBarDatasetId or "")
    if selectedDatasetKey == "" or not datasetSelections[selectedDatasetKey] then
        self.selectedActionBarDatasetId = firstDatasetWithSpells or firstDatasetId
        self.selectedActionBarSpellbookCategory = nil
        return
    end

    local selectedCategory = trimString(self.selectedActionBarSpellbookCategory)
    if selectedCategory == "" then
        self.selectedActionBarSpellbookCategory = nil
        return
    end

    if not datasetSelections[selectedDatasetKey].categories[selectedCategory] then
        self.selectedActionBarSpellbookCategory = nil
    end
end

function SetupWizard:SelectActionBarNavigationItem(item)
    if type(item) ~= "table" or not item.datasetId then
        return
    end

    self.selectedActionBarDatasetId = item.datasetId
    if item.rowType == "category" then
        self.selectedActionBarSpellbookCategory = item.category
    else
        self.selectedActionBarSpellbookCategory = nil
    end
    self.currentActionBarSpellPage = 1
end

function SetupWizard:IsActionBarNavigationItemSelected(item)
    if type(item) ~= "table" then
        return false
    end

    if tostring(item.datasetId or "") ~= tostring(self.selectedActionBarDatasetId or "") then
        return false
    end

    if item.rowType == "category" then
        return tostring(item.category or "") == tostring(self.selectedActionBarSpellbookCategory or "")
    end

    return trimString(self.selectedActionBarSpellbookCategory) == ""
end

function SetupWizard:GetSelectedActionBarNavigationLabel(rows)
    local navigationRows = rows or {}
    for index = 1, #navigationRows do
        local row = navigationRows[index]
        if self:IsActionBarNavigationItemSelected(row) then
            if row.rowType == "category" then
                local datasetName = row.dataset and (Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(row.dataset) or tostring(row.dataset.name or row.dataset.id)) or tostring(row.datasetId or "Spellbook")
                return ("%s / %s"):format(datasetName, row.displayName or tostring(row.category or "Category"))
            end
            return row.displayName or row.name or "Spellbook"
        end
    end

    return "Spellbook"
end

function SetupWizard:GetSelectedActionBarSpellRows()
    local rows = Profile.ListKnownSpells and Profile.ListKnownSpells() or {}
    if not self.selectedActionBarDatasetId or self.selectedActionBarDatasetId == "" then
        return {}
    end

    local filtered = {}
    local selectedCategory = trimString(self.selectedActionBarSpellbookCategory)
    for index = 1, #rows do
        local row = rows[index]
        local dataset = row and row.dataset or nil
        local spellRef = trimString(row and row.spellRef)
        local detail = spellRef ~= "" and Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellRef) or nil
        if dataset
            and tostring(dataset.id or "") == tostring(self.selectedActionBarDatasetId)
            and type(detail) == "table"
            and tostring(detail.learnMode or "") == "always_learned"
        then
            local rowCategory = trimString(row and row.spellbookCategory)
            if selectedCategory == "" or rowCategory == selectedCategory then
                filtered[#filtered + 1] = row
            end
        end
    end

    return filtered
end

function SetupWizard:LayoutActionBarSpellEntries()
    if not self.ActionBarEntryContentFrame or not self.ActionBarEntryListFrame then
        return
    end

    local contentWidth = math.floor(tonumber(self.ActionBarEntryContentFrame:GetWidth()) or 0)
    if contentWidth <= 0 then
        local gridContent = self.ActionBarGridPanel and self.ActionBarGridPanel.GetContentFrame and self.ActionBarGridPanel:GetContentFrame() or nil
        contentWidth = math.floor(tonumber(gridContent and gridContent.GetWidth and gridContent:GetWidth() or 0) or 0)
    end
    if contentWidth <= 0 then
        contentWidth = 320
    end

    local availableWidth = math.max(160, contentWidth - 12)
    local columnWidth = math.floor((availableWidth - ((ACTIONBAR_SPELLBOOK_COLUMNS - 1) * ACTIONBAR_SPELLBOOK_COLUMN_SPACING)) / ACTIONBAR_SPELLBOOK_COLUMNS)
    local layoutWidth = (columnWidth * ACTIONBAR_SPELLBOOK_COLUMNS) + ((ACTIONBAR_SPELLBOOK_COLUMNS - 1) * ACTIONBAR_SPELLBOOK_COLUMN_SPACING)
    local layoutHeight = (ACTIONBAR_SPELLBOOK_ROWS * ACTIONBAR_SPELLBOOK_ENTRY_HEIGHT) + ((ACTIONBAR_SPELLBOOK_ROWS - 1) * ACTIONBAR_SPELLBOOK_ROW_SPACING)

    self.ActionBarEntryListFrame:ClearAllPoints()
    self.ActionBarEntryListFrame:SetPoint("TOP", self.ActionBarEntryContentFrame, "TOP", 0, -8)
    self.ActionBarEntryListFrame:SetSize(math.max(1, layoutWidth), math.max(1, layoutHeight))

    for index = 1, ACTIONBAR_SPELLBOOK_ENTRIES_PER_PAGE do
        local entry = self.actionBarSpellEntries[index]
        local frame = entry and entry.GetFrame and entry:GetFrame() or nil
        if frame then
            entry:SetLayoutMetrics(columnWidth, ACTIONBAR_SPELLBOOK_ENTRY_HEIGHT)
            frame:ClearAllPoints()
            frame:SetPoint(
                "TOPLEFT",
                self.ActionBarEntryListFrame,
                "TOPLEFT",
                ((index - 1) % ACTIONBAR_SPELLBOOK_COLUMNS) * (columnWidth + ACTIONBAR_SPELLBOOK_COLUMN_SPACING),
                -(math.floor((index - 1) / ACTIONBAR_SPELLBOOK_COLUMNS) * (ACTIONBAR_SPELLBOOK_ENTRY_HEIGHT + ACTIONBAR_SPELLBOOK_ROW_SPACING))
            )
        end
    end
end

function SetupWizard:BindWizardSpellToSelectedSlot(spellRef)
    local slotIndex = math.max(1, math.floor(tonumber(self.selectedActionBarSlotIndex) or 1))
    if Profile.BindSpellToActionBarSlot then
        Profile.BindSpellToActionBarSlot(slotIndex, spellRef)
    end

    self.cachedState = self:CaptureSelectionState()
    if Client.RefreshActionBarWidget then
        Client:RefreshActionBarWidget("setup-wizard-bind")
    end
    self:RefreshActionBarPage(self.cachedState)
    if self.FinalizePageBuilt then
        self:RefreshFinalizePage()
    end
end

function SetupWizard:ClearSelectedActionBarSlot()
    local slotIndex = math.max(1, math.floor(tonumber(self.selectedActionBarSlotIndex) or 1))
    if Profile.ClearActionBarSlot then
        Profile.ClearActionBarSlot(slotIndex)
    end

    self.cachedState = self:CaptureSelectionState()
    if Client.RefreshActionBarWidget then
        Client:RefreshActionBarWidget("setup-wizard-clear-slot")
    end
    self:RefreshActionBarPage(self.cachedState)
    if self.FinalizePageBuilt then
        self:RefreshFinalizePage()
    end
end

function SetupWizard:PreviousActionBarSpellPage()
    if (tonumber(self.currentActionBarSpellPage) or 1) <= 1 then
        return false
    end

    self.currentActionBarSpellPage = math.max(1, (tonumber(self.currentActionBarSpellPage) or 1) - 1)
    self:RefreshActionBarPage(self.cachedState or self:CaptureSelectionState())
    return true
end

function SetupWizard:NextActionBarSpellPage()
    local rows = self:GetSelectedActionBarSpellRows()
    local pageCount = math.max(0, math.ceil(#rows / ACTIONBAR_SPELLBOOK_ENTRIES_PER_PAGE))
    if pageCount <= 0 or (tonumber(self.currentActionBarSpellPage) or 1) >= pageCount then
        return false
    end

    self.currentActionBarSpellPage = math.min(pageCount, (tonumber(self.currentActionBarSpellPage) or 1) + 1)
    self:RefreshActionBarPage(self.cachedState or self:CaptureSelectionState())
    return true
end

function SetupWizard:RefreshStartingItemsPage(state)
    self:BuildStartingItemsPage(self.StartingItemsPage or (self.window and self.window.tabContainer and self.window.tabContainer.GetPageFrame and self.window.tabContainer:GetPageFrame(2)) or nil)

    self.availableStartingItems = self:BuildAllowedStartingItemItems()
    self:BuildFilteredStartingItems()
    local validation = self:ValidateCurrentItemSelection()

    if self.StartingItemsSearchInput and self.StartingItemsSearchInput.GetText and self.StartingItemsSearchInput:GetText() ~= self.startingItemFilterQuery then
        self.StartingItemsSearchInput:SetText(self.startingItemFilterQuery)
    end

    local totalItems = #self.filteredStartingItems
    local totalPages = math.max(1, math.ceil(totalItems / ITEM_PAGE_SIZE))
    self.startingItemPage = math.max(1, math.min(self.startingItemPage, totalPages))

    local startIndex = ((self.startingItemPage - 1) * ITEM_PAGE_SIZE) + 1
    local endIndex = math.min(totalItems, startIndex + ITEM_PAGE_SIZE - 1)
    local selectedRefs = selectionArrayFromLookup(self.availableStartingItems, self.selectedStartingItemLookup)

    if self.StartingItemsSummaryText and self.StartingItemsSummaryText.SetText then
        local budget = validation.budget
        local totalPrice = validation.totalPrice
        local budgetText = budget > 0
            and ("%s / %s"):format(formatCopperAmount(totalPrice), formatCopperAmount(budget))
            or formatCopperAmount(totalPrice)
        self.StartingItemsSummaryText:SetText(("%d selected  |  %d shown  |  Cost %s"):format(#selectedRefs, totalItems, budgetText))
    end

    if self.StartingItemsRequirementText and self.StartingItemsRequirementText.SetText then
        if #validation.missingRequiredSlots > 0 then
            self.StartingItemsRequirementText:SetText(("Missing: %s"):format(table.concat(validation.missingRequiredSlots, ", ")))
        else
            self.StartingItemsRequirementText:SetText("")
        end
    end

    if self.startingItemFeedback ~= "" and self.StatusText and self.StatusText.SetText and self:IsEnabled() then
        self.StatusText:SetText(self.startingItemFeedback)
    end

    if self.StartingItemsPageLabel and self.StartingItemsPageLabel.SetText then
        self.StartingItemsPageLabel:SetText(("Page %d / %d"):format(self.startingItemPage, totalPages))
    end

    if self.StartingItemsPrevButton and self.StartingItemsPrevButton.SetEnabled then
        self.StartingItemsPrevButton:SetEnabled(self.startingItemPage > 1)
    end
    if self.StartingItemsNextButton and self.StartingItemsNextButton.SetEnabled then
        self.StartingItemsNextButton:SetEnabled(self.startingItemPage < totalPages)
    end

    local visibleCount = 0
    for listIndex = startIndex, endIndex do
        visibleCount = visibleCount + 1
        local entry = self.filteredStartingItems[listIndex]
        local slot = self:EnsureStartingItemSlot(visibleCount)
        slot.setupWizardEntry = entry
        slot:SetIcon(entry and entry.icon or DEFAULT_ICON)
        slot:SetTooltip(buildItemTooltipSpec(entry))
        slot:SetOverlayText("")

        if self.selectedStartingItemLookup[trimString(entry and entry.value)] == true then
            slot:SetBorderColor(SELECTED_SLOT_BORDER.r, SELECTED_SLOT_BORDER.g, SELECTED_SLOT_BORDER.b, SELECTED_SLOT_BORDER.a)
        else
            slot:SetBorderColor(DEFAULT_SLOT_BORDER.r, DEFAULT_SLOT_BORDER.g, DEFAULT_SLOT_BORDER.b, DEFAULT_SLOT_BORDER.a)
        end

        setFrameShown(slot, true)
    end

    for slotIndex = visibleCount + 1, ITEM_PAGE_SIZE do
        local slot = self:EnsureStartingItemSlot(slotIndex)
        slot.setupWizardEntry = nil
        slot:SetTooltip(nil)
        slot:SetIcon(DEFAULT_ICON)
        slot:SetOverlayText("")
        slot:SetBorderColor(DEFAULT_SLOT_BORDER.r, DEFAULT_SLOT_BORDER.g, DEFAULT_SLOT_BORDER.b, DEFAULT_SLOT_BORDER.a)
        setFrameShown(slot, false)
    end

    setFrameShown(self.StartingItemsEmptyText, totalItems == 0)
    if self.StartingItemsEmptyText and self.StartingItemsEmptyText.SetText then
        if totalItems == 0 and normalizeSearchToken(self.startingItemFilterQuery) ~= "" then
            self.StartingItemsEmptyText:SetText("No starting items match the current search.")
        elseif totalItems == 0 then
            self.StartingItemsEmptyText:SetText("No starting items are available for the active ruleset.")
        else
            self.StartingItemsEmptyText:SetText("")
        end
    end
end

function SetupWizard:RefreshFinalizePage()
    if not self.FinalizePageBuilt then
        return
    end

    local raceItems = self:BuildAllowedRaceItems()
    local classItems = self:BuildAllowedClassItems()
    if not self.availableStartingItems or #self.availableStartingItems == 0 then
        self.availableStartingItems = self:BuildAllowedStartingItemItems()
    end

    local selection = self:CollectCurrentSelection()
    local validation = self:ValidateCurrentItemSelection()
    local plan = validation.plan
    local lines = {}

    local selectedItems = self:GetSelectedStartingItems() or {}
    local raceEntry = findEntryByValue(raceItems, selection.raceRef)
    local classEntry = findEntryByValue(classItems, selection.classRef)
    local actionBarSize = Profile.GetActionBarSize and Profile.GetActionBarSize() or 0
    local boundSpellCount = 0

    lines[#lines + 1] = ("Race: %s"):format(formatChoiceLabel(raceEntry, selection.raceRef))
    lines[#lines + 1] = ("Class: %s"):format(formatChoiceLabel(classEntry, selection.classRef))
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("Starting Items: %d selected  |  Cost %s"):format(#selectedItems, formatCopperAmount(validation.totalPrice))

    if #selectedItems > 0 then
        for index = 1, #selectedItems do
            local entry = selectedItems[index]
            local itemName = tostring(entry and entry.item and entry.item.name or entry and entry.label or "Unknown Item")
            local sellPrice = math.max(0, math.floor(tonumber(entry and entry.sellPrice) or 0))
            lines[#lines + 1] = ("- %s (%s)"):format(itemName, formatCopperAmount(sellPrice))
        end
    else
        lines[#lines + 1] = "- None"
    end

    if validation.passesRequiredSlots ~= true and #(validation.missingRequiredSlots or {}) > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = ("Missing Required Slots: %s"):format(table.concat(validation.missingRequiredSlots, ", "))
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Action Bar:"
    for slotIndex = 1, actionBarSize do
        local spellRef = trimString(selection.actionBarSpellRefs[slotIndex])
        local detail = spellRef ~= "" and Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellRef) or nil
        if spellRef ~= "" then
            boundSpellCount = boundSpellCount + 1
        end
        lines[#lines + 1] = ("- Slot %d: %s"):format(
            slotIndex,
            spellRef ~= "" and tostring(detail and detail.name or spellRef) or "Empty"
        )
    end
    if actionBarSize <= 0 then
        lines[#lines + 1] = "- No action bar slots are available."
    else
        lines[#lines + 1] = ("Bound Spells: %d / %d"):format(boundSpellCount, actionBarSize)
    end

    if self.FinalizeSummaryScroll and self.FinalizeSummaryScroll.SetItems then
        local items = {}
        for index = 1, #lines do
            items[#items + 1] = {
                text = tostring(lines[index] or ""),
            }
        end
        self.FinalizeSummaryScroll:SetItems(items)
    end
    if self.FinalizeApplyButton and self.FinalizeApplyButton.SetEnabled then
        self.FinalizeApplyButton:SetEnabled(
            self:IsEnabled()
            and validation.withinBudget == true
            and validation.passesRequiredSlots == true
        )
    end
end

function SetupWizard:RefreshActionBarPage(state)
    local actionBarSize = Profile.GetActionBarSize and Profile.GetActionBarSize() or 0
    if self.selectedActionBarSlotIndex > actionBarSize then
        self.selectedActionBarSlotIndex = 1
    end

    if self.ActionBarDummyBarHost and self.ActionBarDummyBarHost.SetSize then
        local slotCount = math.max(1, actionBarSize)
        local totalWidth = (slotCount * ACTIONBAR_SLOT_SIZE) + (math.max(0, slotCount - 1) * ACTIONBAR_SLOT_SPACING)
        self.ActionBarDummyBarHost:SetSize(totalWidth, ACTIONBAR_SLOT_SIZE)
    end

    for slotIndex = 1, actionBarSize do
        local slot = self:EnsureActionBarDummySlot(slotIndex)
        local detail = Profile.GetActionBarSlotDetails and Profile.GetActionBarSlotDetails(slotIndex) or nil
        local icon = detail and detail.spell and trimString(detail.spell.icon) or ""
        slot:SetIcon(icon ~= "" and icon or DEFAULT_ICON)
        if detail and detail.spellRef and TooltipBuilders.Spell and type(TooltipBuilders.Spell.Build) == "function" then
            slot:SetTooltip(function(owner)
                local currentDetail = Profile.GetActionBarSlotDetails and Profile.GetActionBarSlotDetails(slotIndex) or nil
                if not currentDetail or not currentDetail.spellRef then
                    return nil
                end

                return TooltipBuilders.Spell:Build(currentDetail, owner)
            end)
        else
            slot:SetTooltip({
                title = ("Slot %d"):format(slotIndex),
                lines = {
                    "Empty slot",
                },
            })
        end
        if slotIndex == self.selectedActionBarSlotIndex then
            slot:SetBorderColor(ACTIONBAR_SELECTED_SLOT_BORDER.r, ACTIONBAR_SELECTED_SLOT_BORDER.g, ACTIONBAR_SELECTED_SLOT_BORDER.b, ACTIONBAR_SELECTED_SLOT_BORDER.a)
        else
            slot:SetBorderColor(DEFAULT_SLOT_BORDER.r, DEFAULT_SLOT_BORDER.g, DEFAULT_SLOT_BORDER.b, DEFAULT_SLOT_BORDER.a)
        end
    end

    local datasetRows = self:BuildActionBarSpellNavigationRows()
    self.actionBarDatasetRows = datasetRows
    self:EnsureActionBarDatasetSelection(datasetRows)
    if self.ActionBarDatasetList and self.ActionBarDatasetList.SetItems then
        self.ActionBarDatasetList:SetItems(datasetRows)
    end
    if self.ActionBarDatasetEmptyText and self.ActionBarDatasetEmptyText.SetText then
        self.ActionBarDatasetEmptyText:SetText(#datasetRows == 0 and "No active datasets." or "")
    end
    if self.ActionBarGridTitle and self.ActionBarGridTitle.SetText then
        self.ActionBarGridTitle:SetText(self:GetSelectedActionBarNavigationLabel(datasetRows))
    end
    local rows = self:GetSelectedActionBarSpellRows()
    local pageCount = math.max(0, math.ceil(#rows / ACTIONBAR_SPELLBOOK_ENTRIES_PER_PAGE))
    if pageCount <= 0 then
        self.currentActionBarSpellPage = 1
    else
        self.currentActionBarSpellPage = math.max(1, math.min(math.floor(tonumber(self.currentActionBarSpellPage) or 1), pageCount))
    end

    local startIndex = ((self.currentActionBarSpellPage - 1) * ACTIONBAR_SPELLBOOK_ENTRIES_PER_PAGE) + 1
    local pageRows = {}
    for index = startIndex, math.min(#rows, startIndex + ACTIONBAR_SPELLBOOK_ENTRIES_PER_PAGE - 1) do
        pageRows[#pageRows + 1] = rows[index]
    end

    self:LayoutActionBarSpellEntries()

    for index = 1, ACTIONBAR_SPELLBOOK_ENTRIES_PER_PAGE do
        local entry = self.actionBarSpellEntries[index]
        local resolved = pageRows[index]
        if entry then
            if resolved then
                local icon = resolved.spell and tostring(resolved.spell.icon or "") or DEFAULT_ICON
                local boundSlot = Profile.FindActionBarSlotBySpell and Profile.FindActionBarSlotBySpell(resolved.spellRef) or nil
                entry:SetIcon(icon ~= "" and icon or DEFAULT_ICON)
                entry:SetSpellName(resolved.name or "Unknown Spell")
                entry:SetEnabled(true)
                entry:SetTooltip(function(owner)
                    local currentResolved = entry.resolvedSpell
                    if not currentResolved or not TooltipBuilders.Spell or type(TooltipBuilders.Spell.Build) ~= "function" then
                        return nil
                    end

                    return TooltipBuilders.Spell:Build(currentResolved, owner)
                end)
                if boundSlot == self.selectedActionBarSlotIndex then
                    entry:SetBorderColor(ACTIONBAR_SELECTED_SLOT_BORDER.r, ACTIONBAR_SELECTED_SLOT_BORDER.g, ACTIONBAR_SELECTED_SLOT_BORDER.b, ACTIONBAR_SELECTED_SLOT_BORDER.a)
                else
                    entry:SetBorderColor(DEFAULT_SLOT_BORDER.r, DEFAULT_SLOT_BORDER.g, DEFAULT_SLOT_BORDER.b, DEFAULT_SLOT_BORDER.a)
                end
                entry.resolvedSpell = resolved
                entry:GetFrame():Show()
            else
                entry:SetIcon(DEFAULT_ICON)
                entry:SetSpellName("")
                entry:SetEnabled(false)
                entry:SetTooltip(nil)
                entry:SetBorderColor(0.24, 0.24, 0.28, 1)
                entry.resolvedSpell = nil
                entry:GetFrame():Hide()
            end
        end
    end

    if self.ActionBarSpellPageLabel and self.ActionBarSpellPageLabel.SetText then
        if #rows <= 0 then
            self.ActionBarSpellPageLabel:SetText("Page 0 / 0")
        else
            self.ActionBarSpellPageLabel:SetText(("Page %d / %d"):format(self.currentActionBarSpellPage, math.max(1, pageCount)))
        end
    end
    if self.ActionBarSpellPagePrevButton and self.ActionBarSpellPagePrevButton.SetEnabled then
        self.ActionBarSpellPagePrevButton:SetEnabled(#rows > 0 and self.currentActionBarSpellPage > 1)
    end
    if self.ActionBarSpellPageNextButton and self.ActionBarSpellPageNextButton.SetEnabled then
        self.ActionBarSpellPageNextButton:SetEnabled(#rows > 0 and self.currentActionBarSpellPage < math.max(1, pageCount))
    end
    if self.ActionBarGridEmptyText and self.ActionBarGridEmptyText.SetText then
        if not self.selectedActionBarDatasetId then
            self.ActionBarGridEmptyText:SetText("Activate a dataset to browse always-learned spells.")
        elseif #rows == 0 then
            self.ActionBarGridEmptyText:SetText(trimString(self.selectedActionBarSpellbookCategory) ~= "" and "No always-learned spells in this category." or "No always-learned spells in this dataset.")
        else
            self.ActionBarGridEmptyText:SetText("")
        end
    end

    for slotIndex = actionBarSize + 1, #(self.actionBarDummySlots or {}) do
        local slot = self.actionBarDummySlots[slotIndex]
        if slot then
            setFrameShown(slot, false)
        end
    end
end

function SetupWizard:RefreshStatus()
    if not self.StatusText or not self.StatusText.SetText then
        return
    end

    if self:IsEnabled() and trimString(self.startingItemFeedback) ~= "" then
        self.StatusText:SetText(self.startingItemFeedback)
    elseif self:IsEnabled() then
        self.StatusText:SetText("")
    else
        self.StatusText:SetText("Setup wizard is disabled for the active ruleset.")
    end
end

function SetupWizard:Refresh()
    local timing = startSetupTiming("SetupWizard.Refresh", "full")
    self:ApplyDatasetPolicy()
    local state = self:CaptureSelectionState()
    self.cachedState = state
    if self.hasDraftSelectionState ~= true then
        self:SyncSelectionState(state)
    end

    if self.IdentityPageBuilt then
        self:RefreshIdentityPage(state)
    end
    if self.StartingItemsPageBuilt then
        self:RefreshStartingItemsPage(state)
    end
    if self.ActionBarPageRoot then
        self:RefreshActionBarPage(state)
    end
    if self.FinalizePageBuilt then
        self:RefreshFinalizePage()
    end

    self:RefreshStatus()
    stopSetupTiming(timing, {
        identity = self.IdentityPageBuilt and 1 or 0,
        items = self.StartingItemsPageBuilt and 1 or 0,
        actionbar = self.ActionBarPageRoot and 1 or 0,
        finalize = self.FinalizePageBuilt and 1 or 0,
    })
    return state
end

local function itemRefFromRecord(record)
    local datasetId = trimString(record and record.dataset)
    local itemId = trimString(record and record.id)
    if datasetId == "" or itemId == "" then
        return ""
    end

    return ("%s:%s"):format(datasetId, itemId)
end

local function countOwnedItemRef(itemRef)
    local count = 0
    local items = Inventory.GetItems and Inventory.GetItems() or {}

    for index = 1, #items do
        if itemRefFromRecord(items[index]) == itemRef then
            count = count + math.max(1, math.floor(tonumber(items[index] and items[index].quantity) or 1))
        end
    end

    local equipped = Profile.ListEquippedSlots and Profile.ListEquippedSlots() or {}
    for index = 1, #equipped do
        local entry = equipped[index]
        if trimString(entry and entry.itemRef) == itemRef then
            count = count + 1
        end
    end

    return count
end

function SetupWizard:CollectCurrentSelection()
    local state = self:CaptureSelectionState()
    local collected = {
        raceRef = trimString(self.selectedRaceRef) ~= "" and trimString(self.selectedRaceRef) or trimString(state.raceRef),
        classRef = trimString(self.selectedClassRef) ~= "" and trimString(self.selectedClassRef) or trimString(state.classRef),
        startingItemRefs = selectionArrayFromLookup(self.availableStartingItems, self.selectedStartingItemLookup),
        actionBarSpellRefs = state.actionBarSpellRefs or {},
    }

    local actionBarSize = Profile.GetActionBarSize and Profile.GetActionBarSize() or 0
    for slotIndex = 1, actionBarSize do
        local dropdown = self.actionBarSlotDropdowns[slotIndex]
        local spellRef = dropdown and dropdown.GetSelectedValue and trimString(dropdown:GetSelectedValue()) or ""
        if spellRef ~= "" then
            collected.actionBarSpellRefs[slotIndex] = spellRef
        elseif dropdown and dropdown.GetSelectedValue then
            collected.actionBarSpellRefs[slotIndex] = nil
        end
    end

    return collected
end

function SetupWizard:ApplyCurrentSelection()
    if not self:IsEnabled() then
        self:RefreshStatus()
        return false
    end

    local state = self:CollectCurrentSelection()
    local validation = self:ValidateCurrentItemSelection()
    local plan = validation.plan
    if validation.withinBudget ~= true then
        self.startingItemFeedback = ("Budget exceeded: %s / %s"):format(formatCopperAmount(validation.totalPrice), formatCopperAmount(validation.budget))
        self:RefreshStatus()
        return false
    end
    if validation.passesRequiredSlots ~= true then
        self.startingItemFeedback = ("Missing required equipment slots: %s"):format(table.concat(validation.missingRequiredSlots, ", "))
        self:RefreshStatus()
        return false
    end

    if trimString(state.raceRef) ~= "" and Profile.SetRaceRef then
        Profile.SetRaceRef(state.raceRef)
    end
    if trimString(state.classRef) ~= "" and Profile.SetClassRef then
        Profile.SetClassRef(state.classRef)
    end

    for index = 1, #(plan.equipped or {}) do
        local assignment = plan.equipped[index]
        if assignment and Profile.EquipItem then
            Profile.EquipItem(assignment.slotKey, assignment.itemRef, {}, assignment.slotRef, false)
        end
    end

    local actionBarSize = Profile.GetActionBarSize and Profile.GetActionBarSize() or 0
    for slotIndex = 1, actionBarSize do
        if Profile.ClearActionBarSlot then
            Profile.ClearActionBarSlot(slotIndex)
        end
    end
    for slotIndex = 1, actionBarSize do
        local spellRef = trimString(state.actionBarSpellRefs[slotIndex])
        if spellRef ~= "" and Profile.BindSpellToActionBarSlot then
            Profile.BindSpellToActionBarSlot(slotIndex, spellRef)
        end
    end

    for index = 1, #(plan.inventory or {}) do
        local itemRef = trimString(plan.inventory[index] and plan.inventory[index].value)
        local datasetId, itemId = string.match(itemRef, "^([^:]+):(.+)$")
        if datasetId and itemId and countOwnedItemRef(itemRef) < 1 and Inventory.AddItem then
            Inventory.AddItem({
                dataset = datasetId,
                id = itemId,
                quantity = 1,
            })
        end
    end

    if Profile.SetSetupWizardState then
        Profile.SetSetupWizardState(state)
    end

    self.startingItemFeedback = ""
    if Client.RefreshActionBarWidget then
        Client:RefreshActionBarWidget("setup-wizard-apply")
    end

    self.cachedState = state
    self:Hide()
    return true
end

function SetupWizard:Show()
    local window = self:BuildWindow()
    local state = self:CaptureSelectionState()
    self.cachedState = state
    self:SyncSelectionState(state)
    self.needsDatasetPolicyRefresh = true

    if window and window.Show then
        window:Show()
    end

    self:RefreshStatus()
    self:QueuePageRefresh(self:GetActiveTabIndex())
    return window
end

function SetupWizard:Hide()
    self.hasDraftSelectionState = false
    self.needsDatasetPolicyRefresh = false
    self.refreshRequestId = math.max(0, math.floor(tonumber(self.refreshRequestId) or 0)) + 1
    if self.window and self.window.Hide then
        self.window:Hide()
    end
    return self.window
end

function Client:BuildSetupWizardWindow()
    return SetupWizard:Get():BuildWindow()
end

function Client:ShowSetupWizardWindow()
    return SetupWizard:Get():Show()
end

function Client:HideSetupWizardWindow()
    return SetupWizard:Get():Hide()
end

return SetupWizard
