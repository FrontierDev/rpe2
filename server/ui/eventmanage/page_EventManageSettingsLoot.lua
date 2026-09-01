local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}
Addon.Internal = Addon.Internal or {}

local Server = Addon.Server
local EventManage = Addon.Server.UI.EventManage
local Database = Addon.Internal.Database or {}
local EventClass = Database.Classes and Database.Classes.Event or nil
local Registry = Addon.Internal.Registry or {}
local Profile = Addon.Internal.Profile or {}
local UI = Addon.UI or {}
local C = UI.Constants or {}

if type(EventManage) ~= "table" or type(EventClass) ~= "table" or EventManage._endLootSettingsInstalled == true then
    return
end

local CONTROL_HEIGHT = 20
local DROPDOWN_HEIGHT = 18
local BUTTON_FONT_SIZE = 7
local END_LOOT_EDITOR_HEIGHT = 58

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, child in pairs(value) do
        copy[key] = deepCopy(child)
    end
    return copy
end

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeToken(value)
    return string.lower(trim(value))
end

local function titleCase(value)
    local text = normalizeToken(value)
    if text == "" then
        return "-"
    end
    return text:gsub("(%a)([%w_]*)", function(first, rest)
        return string.upper(first) .. string.lower(rest):gsub("_", " ")
    end)
end

local function positiveInteger(value)
    local numeric = tonumber(value)
    if numeric == nil
        or numeric ~= numeric
        or numeric == math.huge
        or numeric == -math.huge
        or numeric < 1
        or numeric ~= math.floor(numeric)
    then
        return nil
    end
    return math.floor(numeric)
end

local function cloneGrants(values)
    return type(EventClass.CloneEndLootGrants) == "function"
        and EventClass.CloneEndLootGrants(values)
        or deepCopy(values or {})
end

local function cloneGrant(value)
    return type(EventClass.CloneEndLootGrant) == "function"
        and EventClass.CloneEndLootGrant(value)
        or deepCopy(value or {})
end

local function buildLegacyRefs(values)
    return type(EventClass.BuildLegacyLootRefsFromEndLootGrants) == "function"
        and EventClass.BuildLegacyLootRefsFromEndLootGrants(values)
        or {}
end

local function deriveLegacyGrants(values)
    return type(EventClass.BuildEndLootGrantsFromLegacyRefs) == "function"
        and EventClass.BuildEndLootGrantsFromLegacyRefs(values)
        or {}
end

local function getActivatedDatasets()
    return type(Registry.GetActivatedDatasets) == "function" and Registry:GetActivatedDatasets() or {}
end

local function findActivatedDataset(datasetId)
    local wanted = trim(datasetId)
    if wanted == "" then
        return nil
    end
    local datasets = getActivatedDatasets()
    for index = 1, #datasets do
        if type(datasets[index]) == "table" and tostring(datasets[index].id or "") == wanted then
            return datasets[index]
        end
    end
    return nil
end

local function parseDatasetQualifiedRef(value)
    local text = trim(value)
    local separatorIndex = string.find(text, ":", 1, true)
    if not separatorIndex then
        return "", ""
    end
    return string.sub(text, 1, separatorIndex - 1), string.sub(text, separatorIndex + 1)
end

local function resolveActivatedEntry(ref, collectionKey)
    local datasetId, entryId = parseDatasetQualifiedRef(ref)
    if datasetId == "" or entryId == "" then
        return nil, nil
    end
    local dataset = findActivatedDataset(datasetId)
    for index = 1, #(dataset and dataset[collectionKey] or {}) do
        local entry = dataset[collectionKey][index]
        if type(entry) == "table" and tostring(entry.id or "") == entryId then
            return dataset, entry
        end
    end
    return dataset, nil
end

local function appendItemIfMissing(items, value, label)
    local wanted = trim(value)
    if wanted == "" then
        return items
    end
    for index = 1, #items do
        if tostring(items[index] and items[index].value or "") == wanted then
            return items
        end
    end
    items[#items + 1] = {
        label = label or ("Missing: " .. wanted),
        value = wanted,
    }
    return items
end

local function buildDatasetItems(collectionKey, currentDatasetId)
    local items = { { label = "Dataset", value = "" } }
    local datasets = getActivatedDatasets()
    for index = 1, #datasets do
        local dataset = datasets[index]
        if type(dataset) == "table" and type(dataset[collectionKey]) == "table" and #dataset[collectionKey] > 0 then
            items[#items + 1] = {
                label = trim(dataset.name) ~= "" and trim(dataset.name) or tostring(dataset.id or ""),
                value = tostring(dataset.id or ""),
            }
        end
    end
    if trim(currentDatasetId) ~= "" and not findActivatedDataset(currentDatasetId) then
        appendItemIfMissing(items, currentDatasetId, "Missing dataset: " .. trim(currentDatasetId))
    end
    return items
end

local function buildEntryItems(datasetId, collectionKey, emptyLabel, currentRef)
    local items = { { label = emptyLabel or "Select", value = "" } }
    local dataset = findActivatedDataset(datasetId)
    for index = 1, #(dataset and dataset[collectionKey] or {}) do
        local entry = dataset[collectionKey][index]
        if type(entry) == "table" and trim(entry.id) ~= "" then
            local ref = ("%s:%s"):format(tostring(dataset.id), tostring(entry.id))
            items[#items + 1] = {
                label = trim(entry.name) ~= "" and trim(entry.name) or tostring(entry.id),
                value = ref,
            }
        end
    end
    appendItemIfMissing(items, currentRef, "Missing: " .. trim(currentRef))
    return items
end

local function buildCurrencyItems(currentRef)
    local items = { { label = "Currency", value = "" } }
    local definitions = type(Profile.ListCurrencyDefinitions) == "function" and Profile.ListCurrencyDefinitions({
        includeBuiltins = true,
        includeCustom = true,
        includeInactive = false,
        includeMissingBalances = false,
    }) or {}
    for index = 1, #definitions do
        local definition = definitions[index]
        local available = type(definition) == "table"
            and definition.isMissing ~= true
            and (definition.builtin == true or definition.isActive == true)
        local value = available and trim(definition.key or definition.ref or definition.id) or ""
        if value ~= "" then
            local label = trim(definition.name) ~= "" and trim(definition.name) or value
            if definition.builtin ~= true and trim(definition.datasetName) ~= "" then
                label = trim(definition.datasetName) .. " — " .. label
            end
            items[#items + 1] = { label = label, value = value }
        end
    end
    appendItemIfMissing(items, currentRef, "Missing currency: " .. trim(currentRef))
    return items
end

local function resolveCurrency(ref)
    if type(Profile.ResolveCurrencyDefinition) ~= "function" then
        return nil
    end
    local ok, definition = pcall(Profile.ResolveCurrencyDefinition, ref)
    return ok and type(definition) == "table" and definition or nil
end

local function validateGrant(grant)
    if type(grant) ~= "table" then
        return false, "invalid-grant", "Grant is missing."
    end

    local sourceType = normalizeToken(grant.sourceType)
    local distribution = normalizeToken(grant.distribution)
    if sourceType ~= "direct" and sourceType ~= "loot_table" then
        return false, "unsupported-source", "Select Direct Loot or Loot Table."
    end
    if distribution ~= "group" and distribution ~= "personal" then
        return false, "unsupported-distribution", "Select Group or Personal distribution."
    end

    if sourceType == "loot_table" then
        local lootRef = trim(grant.lootRef)
        if lootRef == "" then
            return false, "missing-loot-ref", "Select a Loot Table."
        end
        local _, loot = resolveActivatedEntry(lootRef, "loot")
        if type(loot) ~= "table" then
            return false, "missing-loot-ref", "Selected Loot Table is unavailable."
        end
        return true
    end

    local reward = type(grant.reward) == "table" and grant.reward or nil
    local rewardType = normalizeToken(reward and reward.type)
    if rewardType ~= "item" and rewardType ~= "currency" then
        return false, "unsupported-reward-type", "Select Item or Currency."
    end
    local ref = trim(reward and reward.ref)
    if ref == "" then
        return false, "missing-reward-ref", "Select a reward reference."
    end
    local amount = positiveInteger(reward and reward.amount)
    if not amount then
        return false, "invalid-amount", "Quantity must be a positive integer."
    end

    if rewardType == "item" then
        local _, item = resolveActivatedEntry(ref, "items")
        if type(item) ~= "table" then
            return false, "missing-item", "Selected Item is unavailable."
        end
    else
        local definition = resolveCurrency(ref)
        if type(definition) ~= "table" or definition.isMissing == true
            or (definition.builtin ~= true and definition.isActive ~= true)
        then
            return false, "missing-currency", "Selected Currency is unavailable."
        end
    end

    return true
end

local function canonicalizeDraft(draft)
    local sourceType = normalizeToken(draft and draft.sourceType)
    local distribution = normalizeToken(draft and draft.distribution)
    if sourceType == "loot_table" then
        return {
            sourceType = "loot_table",
            lootRef = trim(draft and draft.lootRef),
            distribution = distribution,
        }
    end

    local reward = type(draft) == "table" and draft.reward or nil
    return {
        sourceType = sourceType,
        distribution = distribution,
        reward = {
            type = normalizeToken(reward and reward.type),
            ref = trim(reward and reward.ref),
            amount = positiveInteger(reward and reward.amount) or (reward and reward.amount),
        },
    }
end

local function defaultDraft()
    return {
        sourceType = "loot_table",
        lootRef = "",
        distribution = "group",
    }
end

local function displayDistribution(value)
    local normalized = normalizeToken(value)
    if normalized == "group" then return "Group" end
    if normalized == "personal" then return "Personal" end
    return trim(value) ~= "" and trim(value) or "Invalid"
end

local function buildLootRows(eventState)
    local rows = {}
    for index = 1, #(eventState and eventState.endLootGrants or {}) do
        local grant = eventState.endLootGrants[index]
        local sourceType = normalizeToken(grant and grant.sourceType)
        local displayName = "Invalid grant"
        local typeLabel = sourceType ~= "" and titleCase(sourceType) or "Invalid"

        if sourceType == "loot_table" then
            local ref = trim(grant and grant.lootRef)
            local _, loot = resolveActivatedEntry(ref, "loot")
            displayName = type(loot) == "table"
                and (trim(loot.name) ~= "" and trim(loot.name) or tostring(loot.id or ref))
                or (ref ~= "" and ("Missing: " .. ref) or "Missing Loot Table")
            typeLabel = "Loot Table"
        elseif sourceType == "direct" then
            local reward = type(grant) == "table" and grant.reward or nil
            local rewardType = normalizeToken(reward and reward.type)
            local ref = trim(reward and reward.ref)
            local amount = positiveInteger(reward and reward.amount)
            if rewardType == "item" then
                local _, item = resolveActivatedEntry(ref, "items")
                displayName = type(item) == "table"
                    and (trim(item.name) ~= "" and trim(item.name) or tostring(item.id or ref))
                    or (ref ~= "" and ("Missing: " .. ref) or "Missing Item")
                typeLabel = "Direct Item"
            elseif rewardType == "currency" then
                local definition = resolveCurrency(ref)
                displayName = type(definition) == "table" and definition.isMissing ~= true
                    and (trim(definition.name) ~= "" and trim(definition.name) or ref)
                    or (ref ~= "" and ("Missing: " .. ref) or "Missing Currency")
                typeLabel = "Direct Currency"
            else
                displayName = ref ~= "" and ref or "Invalid Direct Reward"
                typeLabel = "Direct Invalid"
            end
            if amount then
                displayName = displayName .. " x" .. amount
            end
        end

        rows[#rows + 1] = {
            rowIndex = index,
            reward = displayName,
            type = typeLabel,
            distribution = displayDistribution(grant and grant.distribution),
        }
    end
    return rows
end

function EventManage:ValidateEndLootGrantForSettings(grant)
    return validateGrant(grant)
end

function EventManage:BuildCanonicalEndLootGrantForSettings(draft)
    return canonicalizeDraft(draft)
end

function EventManage:BuildEndLootRowsForSettings(eventState)
    return buildLootRows(eventState)
end

function EventManage:BuildEndLootEntryItemsForSettings(datasetId, collectionKey, emptyLabel, currentRef)
    return buildEntryItems(datasetId, collectionKey, emptyLabel, currentRef)
end

function EventManage:BuildEndLootCurrencyItemsForSettings(currentRef)
    return buildCurrencyItems(currentRef)
end

function EventManage:LoadEndLootGrantDraft(index)
    local state = self:GetEditableSettingsState()
    local grants = state and state.endLootGrants or {}
    local normalizedIndex = math.floor(tonumber(index) or 0)
    local source = normalizedIndex > 0 and grants[normalizedIndex] or nil
    self.EndLootGrantDraftIndex = source and normalizedIndex or nil
    self.EndLootGrantDraft = source and cloneGrant(source) or defaultDraft()
    return self.EndLootGrantDraft
end

local baseSetSelectedSettingsLootIndex = EventManage.SetSelectedSettingsLootIndex
function EventManage:SetSelectedSettingsLootIndex(index)
    local state = self:GetEditableSettingsState()
    local grants = state and state.endLootGrants or {}
    local normalizedIndex = math.floor(tonumber(index) or 0)
    if normalizedIndex <= 0 or normalizedIndex > #grants then
        normalizedIndex = nil
    end
    self.SelectedEventLootIndex = normalizedIndex
    self:LoadEndLootGrantDraft(normalizedIndex)
    self:RefreshSettingsPage()
end

local baseBuildSettingsSharedRows = EventManage.BuildSettingsSharedRows
function EventManage:BuildSettingsSharedRows(sectionKey, eventState)
    if sectionKey == "loot" then
        return buildLootRows(eventState), self.SelectedEventLootIndex, function(index)
            self:SetSelectedSettingsLootIndex(index)
        end
    end
    return baseBuildSettingsSharedRows(self, sectionKey, eventState)
end

local baseGetSettingsSectionPageDefinitions = EventManage.GetSettingsSectionPageDefinitions
function EventManage:GetSettingsSectionPageDefinitions()
    local pages = baseGetSettingsSectionPageDefinitions(self)
    for index = 1, #pages do
        if pages[index] and pages[index].key == "loot" then
            pages[index].label = "End of Event Loot"
            pages[index].columns = self.SettingsLootColumns or pages[index].columns
            pages[index].editor = self.SettingsEndLootEditor or self.SettingsLootEditorRow or pages[index].editor
        end
    end
    return pages
end

local function setFrameShown(element, shown)
    local frame = element and element.GetFrame and element:GetFrame() or nil
    if frame and frame.SetShown then
        frame:SetShown(shown == true)
    elseif frame then
        if shown then frame:Show() else frame:Hide() end
    end
end

local function syncDropdown(dropdown, value)
    if dropdown and dropdown.SetSelectedValue then
        dropdown:SetSelectedValue(value, true)
    end
end

local function syncInput(input, value)
    local editBox = input and input.GetEditBox and input:GetEditBox() or nil
    if editBox and editBox.HasFocus and editBox:HasFocus() then
        return
    end
    if input and input.SetText then
        input:SetText(tostring(value == nil and "" or value))
    end
end

local function refreshDraftControls(self)
    local state = self:GetEditableSettingsState()
    local selectedIndex = tonumber(self.SelectedEventLootIndex)
    if self.EndLootGrantDraft == nil or self.EndLootGrantDraftIndex ~= selectedIndex then
        self:LoadEndLootGrantDraft(selectedIndex)
    end
    local draft = self.EndLootGrantDraft or defaultDraft()
    local sourceType = normalizeToken(draft.sourceType)
    local distribution = normalizeToken(draft.distribution)
    local reward = type(draft.reward) == "table" and draft.reward or nil
    local rewardType = normalizeToken(reward and reward.type)
    if rewardType ~= "currency" then rewardType = "item" end

    syncDropdown(self.EndLootSourceDropdown, sourceType)
    syncDropdown(self.EndLootDistributionDropdown, distribution)

    local tableMode = sourceType == "loot_table"
    local directItemMode = sourceType == "direct" and rewardType == "item"
    local directCurrencyMode = sourceType == "direct" and rewardType == "currency"
    setFrameShown(self.EndLootTableModeRow, tableMode)
    setFrameShown(self.EndLootDirectItemModeRow, directItemMode)
    setFrameShown(self.EndLootDirectCurrencyModeRow, directCurrencyMode)

    if tableMode then
        local lootRef = trim(draft.lootRef)
        local datasetId = select(1, parseDatasetQualifiedRef(lootRef))
        if datasetId == "" then
            datasetId = trim(self.SelectedEndLootDatasetId)
        else
            self.SelectedEndLootDatasetId = datasetId
        end
        if self.EndLootTableDatasetDropdown and self.EndLootTableDatasetDropdown.SetItems then
            self.EndLootTableDatasetDropdown:SetItems(buildDatasetItems("loot", datasetId))
        end
        syncDropdown(self.EndLootTableDatasetDropdown, datasetId)
        if self.EndLootTableRefDropdown and self.EndLootTableRefDropdown.SetItems then
            self.EndLootTableRefDropdown:SetItems(buildEntryItems(datasetId, "loot", "Loot Table", lootRef))
        end
        syncDropdown(self.EndLootTableRefDropdown, lootRef)
    elseif directItemMode then
        local ref = trim(reward and reward.ref)
        local datasetId = select(1, parseDatasetQualifiedRef(ref))
        if datasetId == "" then
            datasetId = trim(self.SelectedEndLootItemDatasetId)
        else
            self.SelectedEndLootItemDatasetId = datasetId
        end
        syncDropdown(self.EndLootDirectItemTypeDropdown, "item")
        if self.EndLootDirectItemDatasetDropdown and self.EndLootDirectItemDatasetDropdown.SetItems then
            self.EndLootDirectItemDatasetDropdown:SetItems(buildDatasetItems("items", datasetId))
        end
        syncDropdown(self.EndLootDirectItemDatasetDropdown, datasetId)
        if self.EndLootDirectItemRefDropdown and self.EndLootDirectItemRefDropdown.SetItems then
            self.EndLootDirectItemRefDropdown:SetItems(buildEntryItems(datasetId, "items", "Item", ref))
        end
        syncDropdown(self.EndLootDirectItemRefDropdown, ref)
        syncInput(self.EndLootDirectItemAmountInput, reward and reward.amount or 1)
    elseif directCurrencyMode then
        local ref = trim(reward and reward.ref)
        syncDropdown(self.EndLootDirectCurrencyTypeDropdown, "currency")
        if self.EndLootDirectCurrencyRefDropdown and self.EndLootDirectCurrencyRefDropdown.SetItems then
            self.EndLootDirectCurrencyRefDropdown:SetItems(buildCurrencyItems(ref))
        end
        syncDropdown(self.EndLootDirectCurrencyRefDropdown, ref)
        syncInput(self.EndLootDirectCurrencyAmountInput, reward and reward.amount or 1)
    end

    local valid, _, message = validateGrant(draft)
    if self.EndLootValidationText and self.EndLootValidationText.SetText then
        self.EndLootValidationText:SetText(valid and "Ready." or message)
    end
    if self.AddEndLootButton and self.AddEndLootButton.SetEnabled then
        self.AddEndLootButton:SetEnabled(valid == true)
    end
    if self.SaveEndLootButton and self.SaveEndLootButton.SetEnabled then
        self.SaveEndLootButton:SetEnabled(valid == true and selectedIndex ~= nil)
    end
    if self.RemoveEndLootButton and self.RemoveEndLootButton.SetEnabled then
        self.RemoveEndLootButton:SetEnabled(selectedIndex ~= nil)
    end
end

function EventManage:RefreshLootEditor()
    refreshDraftControls(self)
end

local function commitLootMutation(self, mutator)
    local result = self:CommitEventSettings(mutator)
    if result == true and Server.EventState and Server.EventState.active == true
        and type(Server.SyncEndLootGrantsToDraft) == "function"
    then
        Server:SyncEndLootGrantsToDraft(Server.EventState)
    end
    return result
end

function EventManage:AddEndLootGrantFromDraft()
    local draft = canonicalizeDraft(self.EndLootGrantDraft or defaultDraft())
    local valid, reason, detail = validateGrant(draft)
    if not valid then
        return false, reason, detail
    end
    commitLootMutation(self, function(state)
        state.endLootGrants = cloneGrants(state.endLootGrants)
        state.endLootGrants[#state.endLootGrants + 1] = cloneGrant(draft)
        state.lootRefs = buildLegacyRefs(state.endLootGrants)
    end)
    local state = self:GetEditableSettingsState()
    self.SelectedEventLootIndex = #(state and state.endLootGrants or {})
    self:LoadEndLootGrantDraft(self.SelectedEventLootIndex)
    self:RefreshSettingsPage()
    return true
end

function EventManage:SaveEndLootGrantDraft()
    local selectedIndex = tonumber(self.SelectedEventLootIndex)
    if not selectedIndex then
        return false, "no-selection"
    end
    local draft = canonicalizeDraft(self.EndLootGrantDraft or defaultDraft())
    local valid, reason, detail = validateGrant(draft)
    if not valid then
        return false, reason, detail
    end
    commitLootMutation(self, function(state)
        state.endLootGrants = cloneGrants(state.endLootGrants)
        if state.endLootGrants[selectedIndex] then
            state.endLootGrants[selectedIndex] = cloneGrant(draft)
        end
        state.lootRefs = buildLegacyRefs(state.endLootGrants)
    end)
    self:LoadEndLootGrantDraft(selectedIndex)
    self:RefreshSettingsPage()
    return true
end

function EventManage:RemoveSelectedEndLootGrant()
    local selectedIndex = tonumber(self.SelectedEventLootIndex)
    if not selectedIndex then
        return false
    end
    commitLootMutation(self, function(state)
        state.endLootGrants = cloneGrants(state.endLootGrants)
        if state.endLootGrants[selectedIndex] then
            table.remove(state.endLootGrants, selectedIndex)
        end
        state.lootRefs = buildLegacyRefs(state.endLootGrants)
    end)
    local state = self:GetEditableSettingsState()
    local count = #(state and state.endLootGrants or {})
    self.SelectedEventLootIndex = count > 0 and math.min(selectedIndex, count) or nil
    self:LoadEndLootGrantDraft(self.SelectedEventLootIndex)
    self:RefreshSettingsPage()
    return true
end

local baseSaveSelectedPreset = EventManage.SaveSelectedPreset
function EventManage:SaveSelectedPreset(...)
    local result = baseSaveSelectedPreset(self, ...)
    if result == true then
        local name = self:GetSelectedPresetName()
        local preset = name ~= "" and self:GetSettingsPresetCollection()[name] or nil
        local state = self:GetEditableSettingsState()
        if type(preset) == "table" and type(state) == "table" then
            preset.endLootGrants = cloneGrants(state.endLootGrants)
            preset.lootRefs = buildLegacyRefs(preset.endLootGrants)
        end
    end
    return result
end

local baseLoadSelectedPreset = EventManage.LoadSelectedPreset
function EventManage:LoadSelectedPreset(...)
    local name = self:GetSelectedPresetName()
    local preset = name ~= "" and self:GetSettingsPresetCollection()[name] or nil
    local grants = type(preset) == "table" and preset.endLootGrants ~= nil
        and cloneGrants(preset.endLootGrants)
        or deriveLegacyGrants(type(preset) == "table" and preset.lootRefs or {})
    local result = baseLoadSelectedPreset(self, ...)
    if result == true then
        commitLootMutation(self, function(state)
            state.endLootGrants = cloneGrants(grants)
            state.lootRefs = buildLegacyRefs(state.endLootGrants)
        end)
        self.SelectedEventLootIndex = nil
        self:LoadEndLootGrantDraft(nil)
    end
    return result
end

local baseRefreshSettingsSectionPager = EventManage.RefreshSettingsSectionPager
function EventManage:RefreshSettingsSectionPager(...)
    local result = baseRefreshSettingsSectionPager(self, ...)
    local active = self:GetActiveSettingsSectionDefinition()
    local height = active and active.editor and tonumber(active.editor._visibleHeight) or CONTROL_HEIGHT
    height = math.max(CONTROL_HEIGHT, height or CONTROL_HEIGHT)
    if self.SettingsEditorHost and self.SettingsEditorHost.SetHeight then
        self.SettingsEditorHost:SetHeight(height)
    end
    local hostFrame = self.SettingsEditorHost and self.SettingsEditorHost.GetFrame and self.SettingsEditorHost:GetFrame() or nil
    if hostFrame and hostFrame.SetHeight then
        hostFrame:SetHeight(height)
    end
    if self.SettingsRootLayout and self.SettingsRootLayout.RefreshLayout then
        self.SettingsRootLayout:RefreshLayout()
    end
    return result
end

local function createText(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        width = width,
        height = 14,
        fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (C.FontSizes and C.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
    })
end

local function createRow(parent, name, width)
    return UI.CreateLayout(UI.HorizontalLayoutGroup, parent, name, {
        width = width,
        height = CONTROL_HEIGHT,
        spacing = 6,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
end

local function buildEditor(self)
    if self.SettingsEndLootEditor or not self.SettingsEditorHost then
        return
    end
    local width = self.Layout and (self.Layout.SettingsWidth or self.Layout.PageContentWidth) or 480
    local parent = self.SettingsEditorHost.GetContentFrame and self.SettingsEditorHost:GetContentFrame() or self.SettingsEditorHost:GetFrame()

    self.SettingsEndLootEditor = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPEServerEventManageSettingsEndLootEditor", {
        width = width,
        height = END_LOOT_EDITOR_HEIGHT,
        spacing = 2,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.SettingsEndLootEditor._visibleHeight = END_LOOT_EDITOR_HEIGHT
    self.SettingsEndLootEditor:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    self.SettingsEndLootEditor:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    local commonRow = createRow(self.SettingsEndLootEditor:GetFrame(), "RPEServerEventManageSettingsEndLootCommonRow", width)
    commonRow:AddChild(createText(commonRow:GetFrame(), "RPEServerEventManageSettingsEndLootSourceLabel", "Source", 38))
    self.EndLootSourceDropdown = UI.CreateDropdown(commonRow:GetFrame(), "RPEServerEventManageSettingsEndLootSourceDropdown", {
        width = 100,
        height = DROPDOWN_HEIGHT,
        items = {
            { label = "Direct Loot", value = "direct" },
            { label = "Loot Table", value = "loot_table" },
        },
        selectedValue = "loot_table",
        onValueChanged = function(value)
            local draft = self.EndLootGrantDraft or defaultDraft()
            local nextType = normalizeToken(value)
            if nextType == "direct" then
                draft.sourceType = "direct"
                draft.lootRef = nil
                draft.reward = type(draft.reward) == "table" and draft.reward or { type = "item", ref = "", amount = 1 }
            else
                draft.sourceType = "loot_table"
                draft.reward = nil
                draft.lootRef = draft.lootRef or ""
            end
            self.EndLootGrantDraft = draft
            self:RefreshLootEditor()
        end,
    })
    commonRow:AddChild(self.EndLootSourceDropdown)
    commonRow:AddChild(createText(commonRow:GetFrame(), "RPEServerEventManageSettingsEndLootDistributionLabel", "Distribution", 62))
    self.EndLootDistributionDropdown = UI.CreateDropdown(commonRow:GetFrame(), "RPEServerEventManageSettingsEndLootDistributionDropdown", {
        width = 82,
        height = DROPDOWN_HEIGHT,
        items = {
            { label = "Group", value = "group" },
            { label = "Personal", value = "personal" },
        },
        selectedValue = "group",
        onValueChanged = function(value)
            local draft = self.EndLootGrantDraft or defaultDraft()
            draft.distribution = normalizeToken(value)
            self.EndLootGrantDraft = draft
            self:RefreshLootEditor()
        end,
    })
    commonRow:AddChild(self.EndLootDistributionDropdown)
    self.AddEndLootButton = UI.CreateButton(commonRow:GetFrame(), "RPEServerEventManageSettingsEndLootAddButton", "Add", 38, function()
        self:AddEndLootGrantFromDraft()
    end, { height = CONTROL_HEIGHT, fontSize = BUTTON_FONT_SIZE })
    commonRow:AddChild(self.AddEndLootButton)
    self.SaveEndLootButton = UI.CreateButton(commonRow:GetFrame(), "RPEServerEventManageSettingsEndLootSaveButton", "Save", 40, function()
        self:SaveEndLootGrantDraft()
    end, { height = CONTROL_HEIGHT, fontSize = BUTTON_FONT_SIZE })
    commonRow:AddChild(self.SaveEndLootButton)
    self.RemoveEndLootButton = UI.CreateButton(commonRow:GetFrame(), "RPEServerEventManageSettingsEndLootRemoveButton", "Remove", 52, function()
        self:RemoveSelectedEndLootGrant()
    end, { height = CONTROL_HEIGHT, fontSize = BUTTON_FONT_SIZE })
    commonRow:AddChild(self.RemoveEndLootButton)
    self.SettingsEndLootEditor:AddChild(commonRow)

    self.EndLootModeHost = UI.CreatePanel(self.SettingsEndLootEditor:GetFrame(), "RPEServerEventManageSettingsEndLootModeHost", {
        width = width,
        height = CONTROL_HEIGHT,
        contentInset = 0,
        showBackground = false,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        backdropColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    self.SettingsEndLootEditor:AddChild(self.EndLootModeHost)
    local modeParent = self.EndLootModeHost.GetContentFrame and self.EndLootModeHost:GetContentFrame() or self.EndLootModeHost:GetFrame()

    self.EndLootTableModeRow = createRow(modeParent, "RPEServerEventManageSettingsEndLootTableModeRow", width)
    self.EndLootTableModeRow:SetPoint("TOPLEFT", modeParent, "TOPLEFT", 0, 0)
    self.EndLootTableModeRow:SetPoint("TOPRIGHT", modeParent, "TOPRIGHT", 0, 0)
    self.EndLootTableModeRow:AddChild(createText(self.EndLootTableModeRow:GetFrame(), "RPEServerEventManageSettingsEndLootTableDatasetLabel", "Dataset", 44))
    self.EndLootTableDatasetDropdown = UI.CreateDropdown(self.EndLootTableModeRow:GetFrame(), "RPEServerEventManageSettingsEndLootTableDatasetDropdown", {
        width = 112, height = DROPDOWN_HEIGHT, items = {}, selectedValue = "",
        onValueChanged = function(value)
            local draft = self.EndLootGrantDraft or defaultDraft()
            draft.lootRef = ""
            self.EndLootGrantDraft = draft
            self.SelectedEndLootDatasetId = trim(value)
            self:RefreshLootEditor()
        end,
    })
    self.EndLootTableModeRow:AddChild(self.EndLootTableDatasetDropdown)
    self.EndLootTableRefDropdown = UI.CreateDropdown(self.EndLootTableModeRow:GetFrame(), "RPEServerEventManageSettingsEndLootTableRefDropdown", {
        width = 250, height = DROPDOWN_HEIGHT, items = {}, selectedValue = "",
        onValueChanged = function(value)
            local draft = self.EndLootGrantDraft or defaultDraft()
            draft.lootRef = trim(value)
            self.EndLootGrantDraft = draft
            self:RefreshLootEditor()
        end,
    })
    self.EndLootTableModeRow:AddChild(self.EndLootTableRefDropdown)

    self.EndLootDirectItemModeRow = createRow(modeParent, "RPEServerEventManageSettingsEndLootDirectItemModeRow", width)
    self.EndLootDirectItemModeRow:SetPoint("TOPLEFT", modeParent, "TOPLEFT", 0, 0)
    self.EndLootDirectItemModeRow:SetPoint("TOPRIGHT", modeParent, "TOPRIGHT", 0, 0)
    self.EndLootDirectItemTypeDropdown = UI.CreateDropdown(self.EndLootDirectItemModeRow:GetFrame(), "RPEServerEventManageSettingsEndLootDirectItemTypeDropdown", {
        width = 82, height = DROPDOWN_HEIGHT,
        items = { { label = "Item", value = "item" }, { label = "Currency", value = "currency" } },
        selectedValue = "item",
        onValueChanged = function(value)
            local draft = self.EndLootGrantDraft or defaultDraft()
            draft.sourceType = "direct"
            local old = type(draft.reward) == "table" and draft.reward or {}
            local nextType = normalizeToken(value)
            if normalizeToken(old.type) ~= nextType then
                draft.reward = { type = nextType, ref = "", amount = positiveInteger(old.amount) or 1 }
            else
                old.type = nextType
                draft.reward = old
            end
            self.EndLootGrantDraft = draft
            self:RefreshLootEditor()
        end,
    })
    self.EndLootDirectItemModeRow:AddChild(self.EndLootDirectItemTypeDropdown)
    self.EndLootDirectItemDatasetDropdown = UI.CreateDropdown(self.EndLootDirectItemModeRow:GetFrame(), "RPEServerEventManageSettingsEndLootDirectItemDatasetDropdown", {
        width = 100, height = DROPDOWN_HEIGHT, items = {}, selectedValue = "",
        onValueChanged = function(value)
            local draft = self.EndLootGrantDraft or defaultDraft()
            draft.reward = type(draft.reward) == "table" and draft.reward or { type = "item", amount = 1 }
            draft.reward.ref = ""
            self.EndLootGrantDraft = draft
            self.SelectedEndLootItemDatasetId = trim(value)
            self:RefreshLootEditor()
        end,
    })
    self.EndLootDirectItemModeRow:AddChild(self.EndLootDirectItemDatasetDropdown)
    self.EndLootDirectItemRefDropdown = UI.CreateDropdown(self.EndLootDirectItemModeRow:GetFrame(), "RPEServerEventManageSettingsEndLootDirectItemRefDropdown", {
        width = 174, height = DROPDOWN_HEIGHT, items = {}, selectedValue = "",
        onValueChanged = function(value)
            local draft = self.EndLootGrantDraft or defaultDraft()
            draft.reward = type(draft.reward) == "table" and draft.reward or { type = "item", amount = 1 }
            draft.reward.type = "item"
            draft.reward.ref = trim(value)
            self.EndLootGrantDraft = draft
            self:RefreshLootEditor()
        end,
    })
    self.EndLootDirectItemModeRow:AddChild(self.EndLootDirectItemRefDropdown)
    self.EndLootDirectItemAmountInput = UI.CreateTextInput(self.EndLootDirectItemModeRow:GetFrame(), "RPEServerEventManageSettingsEndLootDirectItemAmountInput", {
        width = 50, height = CONTROL_HEIGHT, text = "1", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local function commitItemAmount(input)
        local draft = self.EndLootGrantDraft or defaultDraft()
        draft.reward = type(draft.reward) == "table" and draft.reward or { type = "item", ref = "" }
        draft.reward.type = "item"
        draft.reward.amount = input:GetText()
        self.EndLootGrantDraft = draft
        self:RefreshLootEditor()
    end
    self.EndLootDirectItemAmountInput:SetScript("OnEnterPressed", commitItemAmount)
    self.EndLootDirectItemAmountInput:SetScript("OnEditFocusLost", commitItemAmount)
    self.EndLootDirectItemModeRow:AddChild(self.EndLootDirectItemAmountInput)

    self.EndLootDirectCurrencyModeRow = createRow(modeParent, "RPEServerEventManageSettingsEndLootDirectCurrencyModeRow", width)
    self.EndLootDirectCurrencyModeRow:SetPoint("TOPLEFT", modeParent, "TOPLEFT", 0, 0)
    self.EndLootDirectCurrencyModeRow:SetPoint("TOPRIGHT", modeParent, "TOPRIGHT", 0, 0)
    self.EndLootDirectCurrencyTypeDropdown = UI.CreateDropdown(self.EndLootDirectCurrencyModeRow:GetFrame(), "RPEServerEventManageSettingsEndLootDirectCurrencyTypeDropdown", {
        width = 82, height = DROPDOWN_HEIGHT,
        items = { { label = "Item", value = "item" }, { label = "Currency", value = "currency" } },
        selectedValue = "currency",
        onValueChanged = function(value)
            local draft = self.EndLootGrantDraft or defaultDraft()
            draft.sourceType = "direct"
            local old = type(draft.reward) == "table" and draft.reward or {}
            local nextType = normalizeToken(value)
            if normalizeToken(old.type) ~= nextType then
                draft.reward = { type = nextType, ref = "", amount = positiveInteger(old.amount) or 1 }
            else
                old.type = nextType
                draft.reward = old
            end
            self.EndLootGrantDraft = draft
            self:RefreshLootEditor()
        end,
    })
    self.EndLootDirectCurrencyModeRow:AddChild(self.EndLootDirectCurrencyTypeDropdown)
    self.EndLootDirectCurrencyRefDropdown = UI.CreateDropdown(self.EndLootDirectCurrencyModeRow:GetFrame(), "RPEServerEventManageSettingsEndLootDirectCurrencyRefDropdown", {
        width = 280, height = DROPDOWN_HEIGHT, items = {}, selectedValue = "",
        onValueChanged = function(value)
            local draft = self.EndLootGrantDraft or defaultDraft()
            draft.reward = type(draft.reward) == "table" and draft.reward or { type = "currency", amount = 1 }
            draft.reward.type = "currency"
            draft.reward.ref = trim(value)
            self.EndLootGrantDraft = draft
            self:RefreshLootEditor()
        end,
    })
    self.EndLootDirectCurrencyModeRow:AddChild(self.EndLootDirectCurrencyRefDropdown)
    self.EndLootDirectCurrencyAmountInput = UI.CreateTextInput(self.EndLootDirectCurrencyModeRow:GetFrame(), "RPEServerEventManageSettingsEndLootDirectCurrencyAmountInput", {
        width = 50, height = CONTROL_HEIGHT, text = "1", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local function commitCurrencyAmount(input)
        local draft = self.EndLootGrantDraft or defaultDraft()
        draft.reward = type(draft.reward) == "table" and draft.reward or { type = "currency", ref = "" }
        draft.reward.type = "currency"
        draft.reward.amount = input:GetText()
        self.EndLootGrantDraft = draft
        self:RefreshLootEditor()
    end
    self.EndLootDirectCurrencyAmountInput:SetScript("OnEnterPressed", commitCurrencyAmount)
    self.EndLootDirectCurrencyAmountInput:SetScript("OnEditFocusLost", commitCurrencyAmount)
    self.EndLootDirectCurrencyModeRow:AddChild(self.EndLootDirectCurrencyAmountInput)

    self.EndLootValidationText = createText(self.SettingsEndLootEditor:GetFrame(), "RPEServerEventManageSettingsEndLootValidationText", "", width)
    self.SettingsEndLootEditor:AddChild(self.EndLootValidationText)

    if self.SettingsLootEditorRow then
        self.SettingsLootEditorRow._visibleHeight = 0
        setFrameShown(self.SettingsLootEditorRow, false)
    end

    self.SettingsLootColumns = {
        { key = "reward", label = "Source / Reward", width = 210, justifyH = "LEFT" },
        { key = "type", label = "Type", width = 104, justifyH = "LEFT" },
        { key = "distribution", label = "Distribution", width = 64, justifyH = "LEFT" },
    }

    self:LoadEndLootGrantDraft(self.SelectedEventLootIndex)
end

local baseBuildSettingsPage = EventManage.BuildSettingsPage
function EventManage:BuildSettingsPage(page, ...)
    local result = baseBuildSettingsPage(self, page, ...)
    buildEditor(self)
    self:RefreshSettingsPage()
    return result
end

EventManage._endLootSettingsInstalled = true
