local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local SIDE_PADDING = 8
local FIELD_WIDTH = 236
local CONTROL_HEIGHT = 20
local PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "entries", label = "Entries" },
}
local ENTRY_TYPE_ITEMS = {
    { label = "Item", value = "item" },
    { label = "Currency", value = "currency" },
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function parsePositiveInteger(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge
        or numeric < 1 or numeric ~= math.floor(numeric)
    then
        return nil
    end
    return numeric
end

local function parsePositiveNumber(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge or numeric <= 0 then
        return nil
    end
    return numeric
end

local function normalizeEntryType(value)
    local entryType = string.lower(trim(value))
    if entryType == "item" or entryType == "currency" then
        return entryType
    end
    return nil
end

local function parseQualifiedRef(value)
    local datasetId, entryId = trim(value):match("^([^:]+):(.+)$")
    if not datasetId or datasetId == "" or not entryId or entryId == "" then
        return nil, nil
    end
    return datasetId, entryId
end

local function makeLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        width = width or FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
end

local function setTextEnabled(element, enabled)
    if element and element.SetEnabled then element:SetEnabled(enabled == true) end
    if element and element.SetReadOnly then element:SetReadOnly(enabled ~= true) end
end

local function setDropdownEnabled(dropdown, enabled)
    local frame = dropdown and dropdown.GetFrame and dropdown:GetFrame() or nil
    if frame and frame.EnableMouse then frame:EnableMouse(enabled == true) end
    if frame and frame.SetAlpha then frame:SetAlpha(enabled == true and 1 or 0.5) end
end

local function setButtonEnabled(button, enabled)
    if button and button.SetEnabled then button:SetEnabled(enabled == true) end
end

local function setGroupVisible(group, visible)
    if not group then return end
    local height = visible and group._visibleHeight or 0
    if group.SetHeight then group:SetHeight(height or 0) end
    local frame = group.GetFrame and group:GetFrame() or nil
    if frame then
        if frame.SetHeight then frame:SetHeight(height or 0) end
        if visible then frame:Show() else frame:Hide() end
    end
end

local function setRowSelected(row, selected)
    if not row or not row.entryBackground or not row.entryBackground.SetColorTexture then return end
    local color = UI.ResolveColor(nil, selected and "list.rowHover" or "list.rowBackground")
    row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
end

local function containsDropdownValue(items, value)
    local wanted = trim(value)
    for index = 1, #(items or {}) do
        local item = items[index]
        if item and trim(item.value) == wanted then return true end
        if item and containsDropdownValue(item.children, wanted) then return true end
    end
    return false
end

local function appendMissingValue(items, value, label)
    local reference = trim(value)
    if reference ~= "" and not containsDropdownValue(items, reference) then
        items[#items + 1] = { label = label or ("Missing: %s"):format(reference), value = value }
    end
    return items
end

local function normalizeCurrencyReference(value)
    local reference = trim(value)
    if reference == "" then return "" end
    if type(Profile.NormalizeCurrencyKey) == "function" then
        local ok, normalized = pcall(Profile.NormalizeCurrencyKey, reference)
        if ok and trim(normalized) ~= "" then return trim(normalized) end
    end
    return string.lower(reference)
end

local function buildCurrencyItems(self, currentReference)
    local items = { { label = "None", value = "" } }
    local seen = {}
    local builtins = {}

    if type(Profile.GetBuiltinCurrencyDefinitions) == "function" then
        for _, definition in ipairs(Profile.GetBuiltinCurrencyDefinitions() or {}) do
            local value = normalizeCurrencyReference(definition and (definition.key or definition.id))
            if value ~= "" and not seen[value] then
                seen[value] = true
                builtins[#builtins + 1] = {
                    label = trim(definition and definition.name) ~= "" and trim(definition.name) or value,
                    value = value,
                    icon = definition and definition.icon,
                }
            end
        end
    end
    if #builtins > 0 then
        items[#items + 1] = {
            label = "Built-in", value = "loot-currency-group:builtin", enabled = true,
            keepShownOnClick = true, notCheckable = true, children = builtins,
        }
    end

    local datasets = self:GetDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = trim(dataset and dataset.id)
        local children = {}
        for currencyIndex = 1, #(dataset and dataset.currencies or {}) do
            local currency = dataset.currencies[currencyIndex]
            local currencyId = trim(currency and currency.id)
            if datasetId ~= "" and currencyId ~= "" then
                local value = ("%s:%s"):format(datasetId, currencyId)
                if not seen[value] then
                    seen[value] = true
                    children[#children + 1] = {
                        label = self:GetEntryDisplayName("currencies", currency),
                        value = value,
                        icon = currency.icon,
                    }
                end
            end
        end
        if #children > 0 then
            items[#items + 1] = {
                label = self:GetDatasetDisplayName(dataset),
                value = ("loot-currency-group:%s"):format(datasetId),
                enabled = true, keepShownOnClick = true, notCheckable = true, children = children,
            }
        end
    end

    local raw = trim(currentReference)
    local normalized = normalizeCurrencyReference(raw)
    if raw ~= "" and not containsDropdownValue(items, raw) and not containsDropdownValue(items, normalized) then
        appendMissingValue(items, raw, ("Missing currency: %s"):format(raw))
    end
    return items
end

local function getCurrencySelectionValue(items, reference)
    local raw = trim(reference)
    if raw == "" or containsDropdownValue(items, raw) then return raw end
    local normalized = normalizeCurrencyReference(raw)
    if normalized ~= "" and containsDropdownValue(items, normalized) then return normalized end
    return raw
end

local function buildItemDatasetItems(self, datasetId)
    local items = type(self.BuildItemInspectorDatasetItems) == "function"
        and self:BuildItemInspectorDatasetItems()
        or { { label = "None", value = "" } }
    return appendMissingValue(items, datasetId, ("Missing dataset: %s"):format(trim(datasetId)))
end

local function buildItemItems(self, datasetId, reference)
    local items = type(self.BuildItemInspectorDatasetCollectionItems) == "function"
        and self:BuildItemInspectorDatasetCollectionItems("items", datasetId, { noneLabel = "None" })
        or { { label = "None", value = "" } }
    return appendMissingValue(items, reference, ("Missing item: %s"):format(trim(reference)))
end

local function formatTags(tags)
    if type(tags) ~= "table" then return "" end
    local values = {}
    for index = 1, #tags do values[#values + 1] = tostring(tags[index] or "") end
    return table.concat(values, ", ")
end

local function parseTags(text)
    if UI.Utils and type(UI.Utils.ParseCommaSeparatedList) == "function" then
        return UI.Utils.ParseCommaSeparatedList(text)
    end
    local values, seen = {}, {}
    for part in tostring(text or ""):gmatch("[^,]+") do
        local value = trim(part)
        if value ~= "" and not seen[value] then values[#values + 1], seen[value] = value, true end
    end
    return values
end

local function hasLegacyItems(loot)
    return type(loot) == "table" and type(loot.items) == "table" and next(loot.items) ~= nil
end

local function setDraftError(self, key, message)
    self.LootInspectorDraftErrors = self.LootInspectorDraftErrors or {}
    self.LootInspectorDraftErrors[key] = message
end

local function clearDraftError(self, key)
    if type(self.LootInspectorDraftErrors) == "table" then self.LootInspectorDraftErrors[key] = nil end
end

local function clearEntryDraftErrors(self)
    self.LootInspectorDraftErrors = self.LootInspectorDraftErrors or {}
    for key in pairs(self.LootInspectorDraftErrors) do
        if tostring(key):sub(1, 6) == "entry:" then self.LootInspectorDraftErrors[key] = nil end
    end
end

local function getSelectedEntry(self)
    local loot = self:GetSelectedLoot()
    local entries = type(loot) == "table" and loot.entries or nil
    local index = tonumber(self.SelectedLootEntryIndex)
    if type(entries) ~= "table" or not index or entries[index] == nil then
        return loot, entries or {}, nil, nil
    end
    return loot, entries, index, entries[index]
end

function DataEditor:GenerateLootEntryId(entries)
    local used = {}
    for _, entry in pairs(type(entries) == "table" and entries or {}) do
        local id = type(entry) == "table" and trim(entry.id) or ""
        if id ~= "" then used[id] = true end
    end
    local index = 1
    while used["entry_" .. index] do index = index + 1 end
    return "entry_" .. index
end

function DataEditor:ApplyLootEntryType(entry, value)
    if type(entry) ~= "table" then return false end
    local nextType = normalizeEntryType(value)
    if not nextType then return false end
    if normalizeEntryType(entry.type) ~= nextType then entry.ref = "" end
    entry.type = nextType
    return true
end

function DataEditor:CommitSelectedLoot(mutate)
    local dataset = self:GetSelectedDataset()
    local loot = self:GetSelectedLoot()
    if not dataset or not loot or type(mutate) ~= "function" then return loot end

    local before = self:DeepCopyValue(loot)
    mutate(loot, dataset)
    if self:DeepEqualValues(before, loot) then return loot end

    self:QueuePendingDatasetEntryChanged(dataset.id, "loot")
    if self.RefreshLootDataPage then self:RefreshLootDataPage() end
    return loot
end

function DataEditor:ValidateLootTableAuthoring(loot)
    local result = { errors = {}, warnings = {} }
    if type(loot) ~= "table" then
        result.errors[1] = "Select a Loot Table to validate it."
        return result
    end

    if not parsePositiveInteger(loot.drawCount) then
        result.errors[#result.errors + 1] = "Draw Count must be a positive integer."
    end

    local entries = type(loot.entries) == "table" and loot.entries or {}
    local numericEntries = {}
    for key, entry in pairs(entries) do
        if type(key) == "number" then numericEntries[#numericEntries + 1] = { key = key, entry = entry } end
    end
    table.sort(numericEntries, function(left, right) return left.key < right.key end)
    if #numericEntries == 0 then result.errors[#result.errors + 1] = "Loot Table has no entries." end

    local ids = {}
    for position = 1, #numericEntries do
        local rowIndex = numericEntries[position].key
        local entry = numericEntries[position].entry
        local prefix = ("Entry %s: "):format(tostring(rowIndex))
        if type(entry) ~= "table" then
            result.errors[#result.errors + 1] = prefix .. "entry data is invalid."
        else
            local id = trim(entry.id)
            if id == "" then
                result.errors[#result.errors + 1] = prefix .. "Entry ID is blank."
            elseif ids[id] then
                result.errors[#result.errors + 1] = prefix .. ("Entry ID '%s' is duplicated."):format(id)
            else
                ids[id] = true
            end

            local entryType = normalizeEntryType(entry.type)
            if not entryType then
                result.errors[#result.errors + 1] = prefix .. "Type must be Item or Currency."
            end

            local reference = trim(entry.ref)
            if reference == "" then
                result.errors[#result.errors + 1] = prefix .. "Reference is blank."
            elseif entryType == "item" then
                local dataset, item = nil, nil
                if type(Registry.ResolveItemReference) == "function" then
                    local ok, resolvedDataset, resolvedItem = pcall(Registry.ResolveItemReference, Registry, reference)
                    if ok then dataset, item = resolvedDataset, resolvedItem end
                end
                if not dataset or not item then
                    result.errors[#result.errors + 1] = prefix .. ("Item reference '%s' cannot be resolved."):format(reference)
                end
            elseif entryType == "currency" then
                local definition = nil
                if type(Profile.ResolveCurrencyDefinition) == "function" then
                    local ok, resolved = pcall(Profile.ResolveCurrencyDefinition, reference)
                    if ok then definition = resolved end
                end
                if not definition or definition.isMissing == true then
                    result.errors[#result.errors + 1] = prefix .. ("Currency reference '%s' cannot be resolved."):format(reference)
                end
            end

            if not parsePositiveNumber(entry.weight) then
                result.errors[#result.errors + 1] = prefix .. "Weight must be a finite number greater than 0."
            end
            local minimum = parsePositiveInteger(entry.minQuantity)
            local maximum = parsePositiveInteger(entry.maxQuantity)
            if not minimum then result.errors[#result.errors + 1] = prefix .. "Minimum Quantity must be a positive integer." end
            if not maximum then result.errors[#result.errors + 1] = prefix .. "Maximum Quantity must be a positive integer." end
            if minimum and maximum and maximum < minimum then
                result.errors[#result.errors + 1] = prefix .. "Maximum Quantity cannot be less than Minimum Quantity."
            end
        end
    end

    if hasLegacyItems(loot) then
        result.warnings[#result.warnings + 1] = "Legacy items data is preserved read-only and is not converted by this editor."
    end
    return result
end

function DataEditor:GetLootInspectorPageIndexByKey(key)
    for index = 1, #PAGE_DEFINITIONS do if PAGE_DEFINITIONS[index].key == key then return index end end
    return 1
end

function DataEditor:BuildLootInspectorPageSelectorItems()
    local items = {}
    for index = 1, #PAGE_DEFINITIONS do items[index] = { label = PAGE_DEFINITIONS[index].label, value = PAGE_DEFINITIONS[index].key } end
    return items
end

function DataEditor:RefreshLootInspectorPageSelector()
    local index = math.max(1, math.min(self.ActiveLootInspectorPageIndex or 1, #PAGE_DEFINITIONS))
    self.ActiveLootInspectorPageIndex = index
    self.ActiveLootInspectorTabKey = PAGE_DEFINITIONS[index].key
    if self.LootInspectorPageDropdown then
        self._refreshingLootInspectorSelector = true
        self.LootInspectorPageDropdown:SetSelectedValue(self.ActiveLootInspectorTabKey, true)
        self._refreshingLootInspectorSelector = false
    end
    setButtonEnabled(self.LootInspectorPreviousButton, index > 1)
    setButtonEnabled(self.LootInspectorNextButton, index < #PAGE_DEFINITIONS)
end

function DataEditor:SetLootInspectorTab(key)
    local index = self:GetLootInspectorPageIndexByKey(key or "general")
    self.ActiveLootInspectorPageIndex = index
    self.ActiveLootInspectorTabKey = PAGE_DEFINITIONS[index].key
    local pages = { general = self.LootInspectorGeneralPage, entries = self.LootInspectorEntriesPage }
    for pageKey, page in pairs(pages) do
        if page then if pageKey == self.ActiveLootInspectorTabKey then page:Show() else page:Hide() end end
    end
    self:RefreshLootInspectorPageSelector()
end

function DataEditor:BuildLootInspectorPage(parent)
    if self.LootInspectorPage then
        self:RefreshLootInspectorPage()
        return self.LootInspectorPage
    end

    self.LootInspectorPage = CreateFrame("Frame", "RPEDataEditorLootInspectorPage", parent)
    local selector = UI.CreateLayout(UI.HorizontalLayoutGroup, self.LootInspectorPage, "RPEDataEditorLootInspectorSelector", {
        spacing = 4, height = 20, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    selector:GetFrame():SetPoint("TOPLEFT", self.LootInspectorPage, "TOPLEFT", 0, 0)
    selector:GetFrame():SetPoint("TOPRIGHT", self.LootInspectorPage, "TOPRIGHT", 0, 0)
    self.LootInspectorPreviousButton = UI.CreateButton(selector:GetFrame(), "RPEDataEditorLootInspectorPrevious", "Prev", 40, function()
        local definition = PAGE_DEFINITIONS[(self.ActiveLootInspectorPageIndex or 1) - 1]
        self:SetLootInspectorTab(definition and definition.key or "general")
    end, { height = 20, fontSize = 7 })
    selector:AddChild(self.LootInspectorPreviousButton)
    self.LootInspectorPageDropdown = UI.CreateDropdown(selector:GetFrame(), "RPEDataEditorLootInspectorPageDropdown", {
        width = 118, height = 18, expandWidth = true, weight = 1, items = self:BuildLootInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if not self._refreshingLootInspectorSelector then self:SetLootInspectorTab(value) end
        end,
    })
    selector:AddChild(self.LootInspectorPageDropdown)
    self.LootInspectorNextButton = UI.CreateButton(selector:GetFrame(), "RPEDataEditorLootInspectorNext", "Next", 40, function()
        local definition = PAGE_DEFINITIONS[(self.ActiveLootInspectorPageIndex or 1) + 1]
        self:SetLootInspectorTab(definition and definition.key or "entries")
    end, { height = 20, fontSize = 7 })
    selector:AddChild(self.LootInspectorNextButton)

    local function makePage(name)
        local page = CreateFrame("Frame", name, self.LootInspectorPage)
        page:SetPoint("TOPLEFT", self.LootInspectorPage, "TOPLEFT", SIDE_PADDING, -24)
        page:SetPoint("TOPRIGHT", self.LootInspectorPage, "TOPRIGHT", -SIDE_PADDING, -24)
        page:SetPoint("BOTTOMLEFT", self.LootInspectorPage, "BOTTOMLEFT", SIDE_PADDING, 18)
        page:SetPoint("BOTTOMRIGHT", self.LootInspectorPage, "BOTTOMRIGHT", -SIDE_PADDING, 18)
        return page
    end

    self.LootInspectorGeneralPage = makePage("RPEDataEditorLootInspectorGeneralPage")
    self:BuildLootInspectorGeneralPage(self.LootInspectorGeneralPage)
    self.LootInspectorEntriesPage = makePage("RPEDataEditorLootInspectorEntriesPage")
    self:BuildLootInspectorEntriesPage(self.LootInspectorEntriesPage)

    self.LootInspectorValidationText = UI.CreateText(self.LootInspectorPage, "RPEDataEditorLootInspectorValidationText", "", {
        width = FIELD_WIDTH, height = 16, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.LootInspectorValidationText:GetFrame():SetPoint("BOTTOMLEFT", self.LootInspectorPage, "BOTTOMLEFT", SIDE_PADDING, 0)

    self:SetLootInspectorTab("general")
    self:RefreshLootInspectorPage()
    return self.LootInspectorPage
end

function DataEditor:BuildLootInspectorGeneralPage(parent)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPEDataEditorLootInspectorGeneralLayout", {
        spacing = 3, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, parent, 0, 0, 0, 0)

    root:AddChild(makeLabel(root:GetFrame(), "RPEDataEditorLootInspectorNameLabel", "Name"))
    self.LootInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorLootInspectorNameInput", { width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "" })
    local commitName = function()
        self:CommitSelectedLoot(function(loot) loot.name = self.LootInspectorNameInput:GetText() end)
        self:RefreshLootInspectorValidationStatus()
    end
    self.LootInspectorNameInput:SetScript("OnEnterPressed", commitName)
    self.LootInspectorNameInput:SetScript("OnEditFocusLost", commitName)
    root:AddChild(self.LootInspectorNameInput)

    self.LootInspectorIdText = makeLabel(root:GetFrame(), "RPEDataEditorLootInspectorId", "ID: -")
    root:AddChild(self.LootInspectorIdText)

    root:AddChild(makeLabel(root:GetFrame(), "RPEDataEditorLootInspectorDrawCountLabel", "Draw Count"))
    self.LootInspectorDrawCountInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorLootInspectorDrawCountInput", { width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "1" })
    local commitDrawCount = function()
        local value = parsePositiveInteger(self.LootInspectorDrawCountInput:GetText())
        if not value then
            setDraftError(self, "drawCount", "Draw Count input must be a positive integer.")
        else
            clearDraftError(self, "drawCount")
            self:CommitSelectedLoot(function(loot) loot.drawCount = value end)
        end
        self:RefreshLootInspectorValidationStatus()
    end
    self.LootInspectorDrawCountInput:SetScript("OnEnterPressed", commitDrawCount)
    self.LootInspectorDrawCountInput:SetScript("OnEditFocusLost", commitDrawCount)
    root:AddChild(self.LootInspectorDrawCountInput)

    root:AddChild(makeLabel(root:GetFrame(), "RPEDataEditorLootInspectorTagsLabel", "Tags"))
    self.LootInspectorTagsInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorLootInspectorTagsInput", { width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "" })
    local commitTags = function()
        self:CommitSelectedLoot(function(loot) loot.tags = parseTags(self.LootInspectorTagsInput:GetText()) end)
    end
    self.LootInspectorTagsInput:SetScript("OnEnterPressed", commitTags)
    self.LootInspectorTagsInput:SetScript("OnEditFocusLost", commitTags)
    root:AddChild(self.LootInspectorTagsInput)

    root:AddChild(makeLabel(root:GetFrame(), "RPEDataEditorLootInspectorDescriptionLabel", "Description"))
    self.LootInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorLootInspectorDescriptionInput", {
        width = FIELD_WIDTH, height = 72, text = "", readOnly = false,
    })
    self.LootInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedLoot(function(loot) loot.description = self.LootInspectorDescriptionInput:GetText() end)
    end)
    root:AddChild(self.LootInspectorDescriptionInput)

    self.LootInspectorLegacyWarningText = UI.CreateText(root:GetFrame(), "RPEDataEditorLootInspectorLegacyWarning", "", {
        width = FIELD_WIDTH, height = 30, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"), wordWrap = true,
    })
    root:AddChild(self.LootInspectorLegacyWarningText)
end

function DataEditor:BuildLootInspectorEntriesPage(parent)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPEDataEditorLootInspectorEntriesLayout", {
        spacing = 1, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, parent, 0, 0, 0, 0)

    local panel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorLootInspectorEntriesPanel", {
        width = FIELD_WIDTH, height = 48, contentInset = 2, showBorder = false,
    })
    root:AddChild(panel)
    self.LootInspectorEntryScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorLootInspectorEntryScroll", width = FIELD_WIDTH - 4, height = 44,
        visibleRows = 2, autoFitRows = true, rowHeight = 20, rowSpacing = 0, border = false,
        rowElementClass = UI.ScrollListEntry, categoryWidth = 102, statusWidth = 58, categoryInsetLeft = 4, statusInsetRight = 4,
    })
    self.LootInspectorEntryScroll:SetParent(panel:GetContentFrame())
    self.LootInspectorEntryScroll:SetRowRenderer(function(row, entry, index)
        if type(entry) == "table" then
            row:SetCategory(trim(entry.id) ~= "" and trim(entry.id) or "-")
            row:SetStatus(normalizeEntryType(entry.type) or "Invalid")
            row:SetDetail(trim(entry.ref))
        else
            row:SetCategory("Invalid")
            row:SetStatus("")
            row:SetDetail("Malformed entry data")
        end
        row:SetTestName("")
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedLootEntryIndex = index
                    clearEntryDraftErrors(self)
                    self:RefreshLootEntriesInspector()
                end
            end)
            setRowSelected(row, tonumber(self.SelectedLootEntryIndex) == tonumber(index))
        end
    end)
    self.LootInspectorEntryScroll:Create()
    UI.Utils.AnchorFill(self.LootInspectorEntryScroll, panel:GetContentFrame(), 0, 0, 0, 0)

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorLootInspectorEntryActions", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.LootInspectorAddEntryButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorLootInspectorAddEntry", "Add Entry", 74, function()
        local loot = self:CommitSelectedLoot(function(selected)
            selected.entries = type(selected.entries) == "table" and selected.entries or {}
            selected.entries[#selected.entries + 1] = {
                id = self:GenerateLootEntryId(selected.entries), type = "item", ref = "",
                weight = 1, minQuantity = 1, maxQuantity = 1,
            }
        end)
        self.SelectedLootEntryIndex = loot and #(loot.entries or {}) or nil
        self.LootInspectorPendingItemDatasetId = ""
        clearEntryDraftErrors(self)
        self:RefreshLootEntriesInspector()
    end, { height = 18, fontSize = 7 })
    actions:AddChild(self.LootInspectorAddEntryButton)
    self.LootInspectorDeleteEntryButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorLootInspectorDeleteEntry", "Remove Entry", 82, function()
        local _, entries, index = getSelectedEntry(self)
        if not index then return end
        local loot = self:CommitSelectedLoot(function(selected)
            if type(selected.entries) == "table" and selected.entries[index] ~= nil then table.remove(selected.entries, index) end
        end)
        local updated = loot and loot.entries or entries
        self.SelectedLootEntryIndex = #updated > 0 and math.min(index, #updated) or nil
        self.LootInspectorPendingItemDatasetId = ""
        clearEntryDraftErrors(self)
        self:RefreshLootEntriesInspector()
    end, { height = 18, fontSize = 7 })
    actions:AddChild(self.LootInspectorDeleteEntryButton)
    root:AddChild(actions)

    root:AddChild(makeLabel(root:GetFrame(), "RPEDataEditorLootInspectorEntryIdLabel", "Entry ID"))
    self.LootInspectorEntryIdInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorLootInspectorEntryIdInput", { width = FIELD_WIDTH, height = 18, text = "" })
    local commitEntryId = function()
        local _, entries, index, entry = getSelectedEntry(self)
        if type(entry) ~= "table" then return end
        local nextId = trim(self.LootInspectorEntryIdInput:GetText())
        if nextId == "" then
            setDraftError(self, "entry:id", "Entry ID cannot be blank.")
            self:RefreshLootInspectorValidationStatus()
            return
        end
        for otherIndex, other in pairs(entries) do
            if otherIndex ~= index and type(other) == "table" and trim(other.id) == nextId then
                setDraftError(self, "entry:id", ("Entry ID '%s' is already used."):format(nextId))
                self:RefreshLootInspectorValidationStatus()
                return
            end
        end
        clearDraftError(self, "entry:id")
        self:CommitSelectedLoot(function(selected) selected.entries[index].id = nextId end)
        self:RefreshLootEntriesInspector()
    end
    self.LootInspectorEntryIdInput:SetScript("OnEnterPressed", commitEntryId)
    self.LootInspectorEntryIdInput:SetScript("OnEditFocusLost", commitEntryId)
    root:AddChild(self.LootInspectorEntryIdInput)

    root:AddChild(makeLabel(root:GetFrame(), "RPEDataEditorLootInspectorEntryTypeLabel", "Type"))
    self.LootInspectorEntryTypeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorLootInspectorEntryTypeDropdown", {
        width = FIELD_WIDTH, height = 18, items = ENTRY_TYPE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingLootEntries then return end
            local _, _, index, entry = getSelectedEntry(self)
            if type(entry) ~= "table" or not index then return end
            self:CommitSelectedLoot(function(selected) self:ApplyLootEntryType(selected.entries[index], value) end)
            self.LootInspectorPendingItemDatasetId = ""
            clearDraftError(self, "entry:reference")
            self:RefreshLootEntriesInspector()
        end,
    })
    root:AddChild(self.LootInspectorEntryTypeDropdown)

    self.LootInspectorItemDatasetGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorLootInspectorItemDatasetGroup", {
        spacing = 1, height = 30, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.LootInspectorItemDatasetGroup._visibleHeight = 30
    self.LootInspectorItemDatasetGroup:AddChild(makeLabel(self.LootInspectorItemDatasetGroup:GetFrame(), "RPEDataEditorLootInspectorItemDatasetLabel", "Item Dataset"))
    self.LootInspectorItemDatasetDropdown = UI.CreateDropdown(self.LootInspectorItemDatasetGroup:GetFrame(), "RPEDataEditorLootInspectorItemDatasetDropdown", {
        width = FIELD_WIDTH, height = 18, items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingLootEntries then return end
            local datasetId = trim(value)
            self.LootInspectorPendingItemDatasetId = datasetId
            local _, _, index, entry = getSelectedEntry(self)
            if type(entry) == "table" and normalizeEntryType(entry.type) == "item" and trim(entry.ref) ~= "" then
                self:CommitSelectedLoot(function(selected) selected.entries[index].ref = "" end)
            end
            clearDraftError(self, "entry:reference")
            self:RefreshLootEntriesInspector()
        end,
    })
    self.LootInspectorItemDatasetGroup:AddChild(self.LootInspectorItemDatasetDropdown)
    root:AddChild(self.LootInspectorItemDatasetGroup)

    self.LootInspectorItemGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorLootInspectorItemGroup", {
        spacing = 1, height = 30, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.LootInspectorItemGroup._visibleHeight = 30
    self.LootInspectorItemGroup:AddChild(makeLabel(self.LootInspectorItemGroup:GetFrame(), "RPEDataEditorLootInspectorItemLabel", "Item"))
    self.LootInspectorItemDropdown = UI.CreateDropdown(self.LootInspectorItemGroup:GetFrame(), "RPEDataEditorLootInspectorItemDropdown", {
        width = FIELD_WIDTH, height = 18, items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingLootEntries then return end
            local _, _, index, entry = getSelectedEntry(self)
            if type(entry) ~= "table" or normalizeEntryType(entry.type) ~= "item" then return end
            self:CommitSelectedLoot(function(selected) selected.entries[index].ref = trim(value) end)
            clearDraftError(self, "entry:reference")
            self:RefreshLootEntriesInspector()
        end,
    })
    self.LootInspectorItemGroup:AddChild(self.LootInspectorItemDropdown)
    root:AddChild(self.LootInspectorItemGroup)

    self.LootInspectorCurrencyGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorLootInspectorCurrencyGroup", {
        spacing = 1, height = 30, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.LootInspectorCurrencyGroup._visibleHeight = 30
    self.LootInspectorCurrencyGroup:AddChild(makeLabel(self.LootInspectorCurrencyGroup:GetFrame(), "RPEDataEditorLootInspectorCurrencyLabel", "Currency"))
    self.LootInspectorCurrencyDropdown = UI.CreateDropdown(self.LootInspectorCurrencyGroup:GetFrame(), "RPEDataEditorLootInspectorCurrencyDropdown", {
        width = FIELD_WIDTH, height = 18, items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingLootEntries then return end
            local _, _, index, entry = getSelectedEntry(self)
            if type(entry) ~= "table" or normalizeEntryType(entry.type) ~= "currency" then return end
            self:CommitSelectedLoot(function(selected) selected.entries[index].ref = normalizeCurrencyReference(value) end)
            clearDraftError(self, "entry:reference")
            self:RefreshLootEntriesInspector()
        end,
    })
    self.LootInspectorCurrencyGroup:AddChild(self.LootInspectorCurrencyDropdown)
    root:AddChild(self.LootInspectorCurrencyGroup)

    local function addNumberField(fieldName, label, draftKey, parser, writer)
        root:AddChild(makeLabel(root:GetFrame(), "RPEDataEditorLootInspector" .. fieldName .. "Label", label))
        local input = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorLootInspector" .. fieldName .. "Input", { width = FIELD_WIDTH, height = 18, text = "" })
        local commit = function()
            local _, _, index, entry = getSelectedEntry(self)
            if type(entry) ~= "table" then return end
            local value = parser(input:GetText())
            if not value then
                setDraftError(self, draftKey, label .. " input is invalid.")
                self:RefreshLootInspectorValidationStatus()
                return
            end
            if fieldName == "MinQuantity" then
                local maximum = parsePositiveInteger(entry.maxQuantity)
                if maximum and value > maximum then
                    setDraftError(self, draftKey, "Minimum Quantity cannot exceed Maximum Quantity.")
                    self:RefreshLootInspectorValidationStatus()
                    return
                end
            elseif fieldName == "MaxQuantity" then
                local minimum = parsePositiveInteger(entry.minQuantity)
                if minimum and value < minimum then
                    setDraftError(self, draftKey, "Maximum Quantity cannot be less than Minimum Quantity.")
                    self:RefreshLootInspectorValidationStatus()
                    return
                end
            end
            clearDraftError(self, draftKey)
            self:CommitSelectedLoot(function(selected) writer(selected.entries[index], value) end)
            self:RefreshLootInspectorValidationStatus()
        end
        input:SetScript("OnEnterPressed", commit)
        input:SetScript("OnEditFocusLost", commit)
        root:AddChild(input)
        return input
    end

    self.LootInspectorWeightInput = addNumberField("Weight", "Weight", "entry:weight", parsePositiveNumber, function(entry, value) entry.weight = value end)
    self.LootInspectorMinQuantityInput = addNumberField("MinQuantity", "Minimum Quantity", "entry:minQuantity", parsePositiveInteger, function(entry, value) entry.minQuantity = value end)
    self.LootInspectorMaxQuantityInput = addNumberField("MaxQuantity", "Maximum Quantity", "entry:maxQuantity", parsePositiveInteger, function(entry, value) entry.maxQuantity = value end)
end

function DataEditor:RefreshLootInspectorGeneral()
    local loot = self:GetSelectedLoot()
    local enabled = loot ~= nil
    if self.LootInspectorNameInput then self.LootInspectorNameInput:SetText(loot and (loot.name or "") or ""); setTextEnabled(self.LootInspectorNameInput, enabled) end
    if self.LootInspectorIdText then self.LootInspectorIdText:SetText(("ID: %s"):format(loot and tostring(loot.id or "") or "-")) end
    if self.LootInspectorDrawCountInput then self.LootInspectorDrawCountInput:SetText(loot and tostring(loot.drawCount or "") or ""); setTextEnabled(self.LootInspectorDrawCountInput, enabled) end
    if self.LootInspectorTagsInput then self.LootInspectorTagsInput:SetText(loot and formatTags(loot.tags) or ""); setTextEnabled(self.LootInspectorTagsInput, enabled) end
    if self.LootInspectorDescriptionInput then self.LootInspectorDescriptionInput:SetText(loot and (loot.description or "") or ""); setTextEnabled(self.LootInspectorDescriptionInput, enabled) end
    if self.LootInspectorLegacyWarningText then
        self.LootInspectorLegacyWarningText:SetText(hasLegacyItems(loot) and "Legacy items data is preserved read-only. This editor will not reinterpret or discard it." or "")
    end
end

function DataEditor:RefreshLootEntriesInspector()
    local loot, entries, index, entry = getSelectedEntry(self)
    local hasLoot = loot ~= nil
    if hasLoot and type(entries) == "table" and not index and #entries > 0 then
        index, entry, self.SelectedLootEntryIndex = 1, entries[1], 1
    elseif not hasLoot or type(entries) ~= "table" or #entries == 0 then
        index, entry, self.SelectedLootEntryIndex = nil, nil, nil
    elseif index and entries[index] == nil then
        index = math.min(index, #entries)
        self.SelectedLootEntryIndex, entry = index, entries[index]
    end

    if self.LootInspectorEntryScroll then self.LootInspectorEntryScroll:SetItems(type(entries) == "table" and entries or {}) end
    local editable = type(entry) == "table"
    local entryType = editable and normalizeEntryType(entry.type) or nil
    local rawType = editable and trim(entry.type) or ""
    setButtonEnabled(self.LootInspectorAddEntryButton, hasLoot)
    setButtonEnabled(self.LootInspectorDeleteEntryButton, entry ~= nil)

    if self.LootInspectorEntryIdInput then self.LootInspectorEntryIdInput:SetText(editable and tostring(entry.id or "") or ""); setTextEnabled(self.LootInspectorEntryIdInput, editable) end
    self._refreshingLootEntries = true
    if self.LootInspectorEntryTypeDropdown then
        local typeItems = { { label = "Item", value = "item" }, { label = "Currency", value = "currency" } }
        if rawType ~= "" and not entryType then typeItems[#typeItems + 1] = { label = "Unsupported: " .. rawType, value = rawType } end
        self.LootInspectorEntryTypeDropdown:SetItems(typeItems)
        self.LootInspectorEntryTypeDropdown:SetSelectedValue(entryType or rawType, true)
        setDropdownEnabled(self.LootInspectorEntryTypeDropdown, editable)
    end

    local reference = editable and trim(entry.ref) or ""
    local referenceDatasetId = select(1, parseQualifiedRef(reference)) or ""
    if self._lootInspectorItemDatasetEntryIndex ~= index then
        self.LootInspectorPendingItemDatasetId = referenceDatasetId
        self._lootInspectorItemDatasetEntryIndex = index
    elseif referenceDatasetId ~= "" then
        self.LootInspectorPendingItemDatasetId = referenceDatasetId
    end
    local itemDatasetId = self.LootInspectorPendingItemDatasetId or referenceDatasetId

    setGroupVisible(self.LootInspectorItemDatasetGroup, editable and entryType == "item")
    setGroupVisible(self.LootInspectorItemGroup, editable and entryType == "item")
    setGroupVisible(self.LootInspectorCurrencyGroup, editable and entryType == "currency")

    if self.LootInspectorItemDatasetDropdown then
        self.LootInspectorItemDatasetDropdown:SetItems(buildItemDatasetItems(self, itemDatasetId))
        self.LootInspectorItemDatasetDropdown:SetSelectedValue(itemDatasetId, true)
        setDropdownEnabled(self.LootInspectorItemDatasetDropdown, editable and entryType == "item")
    end
    if self.LootInspectorItemDropdown then
        self.LootInspectorItemDropdown:SetItems(buildItemItems(self, itemDatasetId, reference))
        self.LootInspectorItemDropdown:SetSelectedValue(reference, true)
        setDropdownEnabled(self.LootInspectorItemDropdown, editable and entryType == "item" and itemDatasetId ~= "")
    end
    if self.LootInspectorCurrencyDropdown then
        local currencyItems = buildCurrencyItems(self, reference)
        self.LootInspectorCurrencyDropdown:SetItems(currencyItems)
        self.LootInspectorCurrencyDropdown:SetSelectedValue(getCurrencySelectionValue(currencyItems, reference), true)
        setDropdownEnabled(self.LootInspectorCurrencyDropdown, editable and entryType == "currency")
    end
    self._refreshingLootEntries = false

    if self.LootInspectorWeightInput then self.LootInspectorWeightInput:SetText(editable and tostring(entry.weight or "") or ""); setTextEnabled(self.LootInspectorWeightInput, editable) end
    if self.LootInspectorMinQuantityInput then self.LootInspectorMinQuantityInput:SetText(editable and tostring(entry.minQuantity or "") or ""); setTextEnabled(self.LootInspectorMinQuantityInput, editable) end
    if self.LootInspectorMaxQuantityInput then self.LootInspectorMaxQuantityInput:SetText(editable and tostring(entry.maxQuantity or "") or ""); setTextEnabled(self.LootInspectorMaxQuantityInput, editable) end
    self:RefreshLootInspectorValidationStatus()
end

function DataEditor:RefreshLootInspectorValidationStatus()
    if not self.LootInspectorValidationText then return end
    local loot = self:GetSelectedLoot()
    if not loot then self.LootInspectorValidationText:SetText("Select a Loot Table to inspect it."); return end

    local messages, keys = {}, {}
    for key in pairs(self.LootInspectorDraftErrors or {}) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do messages[#messages + 1] = self.LootInspectorDraftErrors[key] end
    local validation = self:ValidateLootTableAuthoring(loot)
    for index = 1, #validation.errors do messages[#messages + 1] = validation.errors[index] end
    for index = 1, #validation.warnings do messages[#messages + 1] = "Warning: " .. validation.warnings[index] end

    if #messages == 0 then self.LootInspectorValidationText:SetText("Loot Table is valid."); return end
    local text = messages[1]
    if #messages > 1 then text = text .. (" (+%d more)"):format(#messages - 1) end
    self.LootInspectorValidationText:SetText(text)
end

function DataEditor:RefreshLootInspectorPage()
    local loot = self:GetSelectedLoot()
    if self._lootInspectorSelectedLoot ~= loot then
        self._lootInspectorSelectedLoot = loot
        self.SelectedLootEntryIndex = nil
        self.LootInspectorDraftErrors = {}
        self.LootInspectorPendingItemDatasetId = ""
        self._lootInspectorItemDatasetEntryIndex = nil
    end
    self:RefreshLootInspectorGeneral()
    self:RefreshLootEntriesInspector()
    self:SetLootInspectorTab(self.ActiveLootInspectorTabKey or "general")
    self:RefreshLootInspectorValidationStatus()
end
