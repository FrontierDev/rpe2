local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local MarketClass = Database.Classes and Database.Classes.Market or nil
local ItemInspectorShared = DataEditor.ItemInspectorShared or {}

local CONTROL_HEIGHT = 20
local FIELD_WIDTH = 236
local SIDE_PADDING = 8
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local MARKET_TYPE_ITEMS = {
    { label = "Exchange", value = "exchange" },
    { label = "Tracker", value = "tracker" },
}

local function buildSelectableItems(items, includeNone)
    local selectable = {}
    for index = 1, #(items or {}) do
        local item = items[index]
        if item and tostring(item.value or "") ~= ""
            and (includeNone == true or tostring(item.value or "") ~= "none")
        then
            selectable[#selectable + 1] = item
        end
    end
    return selectable
end

local function buildAllowedValues(items)
    local values = {}
    for index = 1, #(items or {}) do
        values[string.lower(tostring(items[index].value or ""))] = true
    end
    return values
end

-- These shared item definitions are the authoritative vocabulary for both
-- item authoring and Market eligibility filters.
local ITEM_TYPE_ITEMS = buildSelectableItems(ItemInspectorShared.ITEM_TYPE_ITEMS)
local ARMOR_WEIGHT_ITEMS = buildSelectableItems(ItemInspectorShared.ARMOR_WEIGHT_ITEMS)
local MODIFICATION_ARMOR_WEIGHT_ITEMS = buildSelectableItems(ItemInspectorShared.MODIFICATION_ARMOR_WEIGHT_ITEMS, true)
local MODIFICATION_KIND_ITEMS = buildSelectableItems(ItemInspectorShared.MODIFICATION_KIND_ITEMS)
local CONSUMABLE_TYPE_ITEMS = buildSelectableItems(ItemInspectorShared.CONSUMABLE_TYPE_ITEMS)
local CONSUMABLE_ELIXIR_TYPE_ITEMS = buildSelectableItems(ItemInspectorShared.CONSUMABLE_ELIXIR_TYPE_ITEMS)
local ALLOWED_ITEM_TYPES = buildAllowedValues(ITEM_TYPE_ITEMS)
local ALLOWED_CONSUMABLE_TYPES = buildAllowedValues(CONSUMABLE_TYPE_ITEMS)

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function isFiniteNumber(value)
    return value ~= nil and value == value and value ~= math.huge and value ~= -math.huge
end

local function parseFiniteNumber(value)
    local number = tonumber(value)
    return isFiniteNumber(number) and number or nil
end

local function applyTable(target, source)
    for key in pairs(target or {}) do
        if source[key] == nil then
            target[key] = nil
        end
    end
    for key, value in pairs(source or {}) do
        target[key] = value
    end
end

local function setTextEnabled(element, enabled)
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
    if not dropdown then
        return
    end
    if dropdown.SetEnabled then
        dropdown:SetEnabled(enabled == true)
    end
    local frame = dropdown.GetFrame and dropdown:GetFrame() or nil
    if frame and frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
end

local function setShown(element, shown)
    local frame = element and element.GetFrame and element:GetFrame() or element
    if frame and frame.SetShown then
        frame:SetShown(shown == true)
    elseif frame then
        if shown then frame:Show() else frame:Hide() end
    end
end

local function dropdownContains(items, value)
    for index = 1, #(items or {}) do
        local item = items[index]
        if item and tostring(item.value or "") == tostring(value or "") then
            return true
        end
        if item and dropdownContains(item.children, value) then
            return true
        end
    end
    return false
end

local function appendMissingDropdownValue(items, value, label)
    local reference = trim(value)
    if reference ~= "" and not dropdownContains(items, reference) then
        items[#items + 1] = { label = label or ("Missing: " .. reference), value = reference }
    end
end

local function appendMissingDropdownValues(items, values, labelPrefix)
    for index = 1, #(values or {}) do
        local value = values[index]
        appendMissingDropdownValue(items, value, (labelPrefix or "Missing") .. ": " .. trim(value))
    end
end

local function copyDropdownItems(items, selectedValues, missingLabelPrefix)
    local copy = {}
    for index = 1, #(items or {}) do
        local item = items[index]
        copy[index] = { label = item.label, value = item.value }
    end
    appendMissingDropdownValues(copy, selectedValues, missingLabelPrefix)
    return copy
end

local function buildActivatedCollectionItems(self, collectionKey, values, labelPrefix)
    local items = {}
    local datasets = self:GetDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = trim(dataset and dataset.id)
        if datasetId ~= "" and (type(self.IsDatasetActivated) ~= "function" or self:IsDatasetActivated(datasetId)) then
            local entries = dataset and dataset[collectionKey] or {}
            for entryIndex = 1, #entries do
                local entry = entries[entryIndex]
                if entry and trim(entry.id) ~= "" then
                    items[#items + 1] = {
                        label = ("%s / %s"):format(self:GetDatasetDisplayName(dataset), self:GetEntryDisplayName(collectionKey, entry)),
                        value = ("%s:%s"):format(datasetId, entry.id),
                    }
                end
            end
        end
    end
    appendMissingDropdownValues(items, values, labelPrefix)
    return items
end

local function selectedValuesContain(values, expected)
    for index = 1, #(values or {}) do
        if string.lower(trim(values[index])) == expected then
            return true
        end
    end
    return false
end

local function addLabel(root, name, text)
    local label = UI.CreateText(root:GetFrame(), name, text, {
        width = FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(label)
    return label
end

local function addField(root, self, key, label, options)
    options = options or {}
    local row = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorMarketInspector" .. key .. "Row", {
        spacing = 4,
        height = CONTROL_HEIGHT,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    row:AddChild(UI.CreateText(row:GetFrame(), "RPEDataEditorMarketInspector" .. key .. "Label", label, {
        width = options.labelWidth or 108,
        height = CONTROL_HEIGHT,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    }))

    local control
    if options.dropdown then
        control = UI.CreateDropdown(row:GetFrame(), "RPEDataEditorMarketInspector" .. key, {
            width = FIELD_WIDTH - (options.labelWidth or 108) - 4,
            height = CONTROL_HEIGHT,
            items = options.items or {},
            multiSelect = options.multiSelect == true,
            onValueChanged = options.onValueChanged,
        })
    else
        control = UI.CreateTextInput(row:GetFrame(), "RPEDataEditorMarketInspector" .. key, {
            width = FIELD_WIDTH - (options.labelWidth or 108) - 4,
            height = CONTROL_HEIGHT,
            text = "",
            borderColor = UI.ResolveColor(nil, "panel.border"),
        })
        control:SetScript("OnEnterPressed", options.commit)
        control:SetScript("OnEditFocusLost", options.commit)
    end
    row:AddChild(control)
    root:AddChild(row)
    self["MarketInspector" .. key .. "Row"] = row
    self["MarketInspector" .. key .. "Control"] = control
    return row, control
end

local function buildItemReferenceItems(self, datasetId, reference)
    local items = self:BuildItemInspectorDatasetCollectionItems("items", datasetId, { noneLabel = "None" })
    appendMissingDropdownValue(items, reference, "Missing item: " .. trim(reference))
    return items
end

local function resolveItem(reference)
    if trim(reference) == "" or type(Registry.ResolveItemReference) ~= "function" then
        return nil, nil, "empty-reference"
    end
    return Registry:ResolveItemReference(reference)
end

local function itemRowLabel(reference, item)
    if item then
        local icon = trim(item.icon) ~= "" and item.icon or DEFAULT_ICON
        return ("|T%s:14:14:0:0|t %s"):format(icon, tostring(item.name or reference))
    end
    return "Missing item"
end

local function validateQualifiedReference(reference, fieldName, errors)
    local value = trim(reference)
    if value == "" then
        return
    end
    local datasetId, entryId = value:match("^([^:]+):(.+)$")
    if not datasetId or not entryId or trim(datasetId) == "" or trim(entryId) == "" then
        errors[#errors + 1] = ("%s must use datasetId:itemId."):format(fieldName)
    end
end

local function validateRuleReferenceList(values, fieldName, resolveMethod, errors, warnings)
    for index = 1, #(values or {}) do
        local reference = values[index]
        local label = ("%s %d"):format(fieldName, index)
        validateQualifiedReference(reference, label, errors)
        if trim(reference) ~= "" and type(Registry[resolveMethod]) == "function" then
            local _, entry = Registry[resolveMethod](Registry, reference)
            local datasetId = trim(reference):match("^([^:]+):")
            local active = type(Registry.IsDatasetActivated) ~= "function"
                or Registry:IsDatasetActivated(datasetId)
            if not entry or not active then
                warnings[#warnings + 1] = ("Missing or inactive %s %s."):format(string.lower(fieldName), trim(reference))
            end
        end
    end
end

local function getMarketValidation(self, dataset, market)
    local errors, warnings = {}, {}
    local marketType = string.lower(trim(market and market.marketType))
    local index = string.upper(trim(market and market.index))

    if trim(market and market.name) == "" then
        errors[#errors + 1] = "Market name is required."
    end
    if not index:match("^[A-Z][A-Z0-9_]*$") then
        errors[#errors + 1] = "Index must start with A-Z and contain only A-Z, 0-9 or _."
    end
    if marketType ~= "exchange" and marketType ~= "tracker" then
        errors[#errors + 1] = "Market type must be Exchange or Tracker."
    end

    local numericFields = {
        { key = "baseCoefficientPercent", label = "Base coefficient" },
        { key = "dailyVariationPercent", label = "Daily variation" },
        { key = "trackerInfluencePercent", label = "Tracker influence" },
    }
    for fieldIndex = 1, #numericFields do
        local field = numericFields[fieldIndex]
        local value = tonumber(market and market[field.key])
        if not isFiniteNumber(value) then
            errors[#errors + 1] = field.label .. " must be finite."
        end
    end

    local dailyVariation = tonumber(market and market.dailyVariationPercent)
    if isFiniteNumber(dailyVariation) and dailyVariation < 0 then
        errors[#errors + 1] = "Daily variation cannot be negative."
    end
    local tariff = tonumber(market and market.tariffPercent)
    if not isFiniteNumber(tariff) or tariff < 0 or tariff >= 100 then
        errors[#errors + 1] = "Tariff must be at least 0 and less than 100."
    end

    if marketType == "exchange" then
        for indexValue = 1, #(market and market.buyItemRefs or {}) do
            local reference = market.buyItemRefs[indexValue]
            validateQualifiedReference(reference, ("Buy item %d"):format(indexValue), errors)
            if trim(reference) ~= "" then
                local _, item, reason = resolveItem(reference)
                if not item then
                    warnings[#warnings + 1] = ("Missing buy item %s (%s)."):format(trim(reference), tostring(reason or "unresolved"))
                end
            end
        end

        local sellRules = type(market.sellRules) == "table" and market.sellRules or {}
        for typeIndex = 1, #(sellRules.itemTypes or {}) do
            local itemType = trim(sellRules.itemTypes[typeIndex]):lower()
            if not ALLOWED_ITEM_TYPES[itemType] then
                errors[#errors + 1] = ("Sell item type '%s' is not allowed."):format(itemType)
            end
        end
        for typeIndex = 1, #(sellRules.consumableTypes or {}) do
            local consumableType = trim(sellRules.consumableTypes[typeIndex]):lower()
            if not ALLOWED_CONSUMABLE_TYPES[consumableType] then
                errors[#errors + 1] = ("Consumable subtype '%s' is not allowed."):format(consumableType)
            end
        end
        validateRuleReferenceList(sellRules.weaponTypeRefs, "Weapon type", "ResolveWeaponTypeReference", errors, warnings)
        validateRuleReferenceList(sellRules.slotRefs, "Item slot", "ResolveItemSlotReference", errors, warnings)
        validateRuleReferenceList(sellRules.targetSlotRefs, "Modification target slot", "ResolveItemSlotReference", errors, warnings)
        validateRuleReferenceList(sellRules.targetWeaponTypeRefs, "Modification target weapon type", "ResolveWeaponTypeReference", errors, warnings)
        for indexValue = 1, #(sellRules.itemRefs or {}) do
            local reference = sellRules.itemRefs[indexValue]
            validateQualifiedReference(reference, ("Sell item %d"):format(indexValue), errors)
            if trim(reference) ~= "" then
                local _, item, reason = resolveItem(reference)
                if not item then
                    warnings[#warnings + 1] = ("Missing sell item %s (%s)."):format(trim(reference), tostring(reason or "unresolved"))
                end
            end
        end

        local trackerReference = trim(market and market.trackerMarketRef)
        if trackerReference ~= "" then
            validateQualifiedReference(trackerReference, "Tracker market", errors)
            local trackerDatasetId, trackerMarketId = trackerReference:match("^([^:]+):(.+)$")
            if trackerDatasetId and trackerMarketId
                and tostring(dataset and dataset.id or "") == trackerDatasetId
                and trim(market and market.id) == trackerMarketId
            then
                errors[#errors + 1] = "Tracker market cannot link to itself."
            else
                local resolvedDataset, trackerMarket, reason = Registry:ResolveMarketReference(trackerReference)
                if not resolvedDataset or not trackerMarket then
                    warnings[#warnings + 1] = ("Missing or inactive tracker market %s (%s)."):format(trackerReference, tostring(reason or "unresolved"))
                elseif string.lower(trim(trackerMarket.marketType)) ~= "tracker" then
                    errors[#errors + 1] = "Tracker market link must target a Tracker market."
                end
            end
        end
    end

    return errors, warnings
end

local function setStatus(self, errors, warnings)
    local lines = {}
    for index = 1, #(errors or {}) do
        lines[#lines + 1] = "Error: " .. errors[index]
    end
    for index = 1, #(warnings or {}) do
        lines[#lines + 1] = "Warning: " .. warnings[index]
    end
    if #lines == 0 then
        lines[1] = "Market is ready to use."
    end
    if self.MarketInspectorStatusText then
        self.MarketInspectorStatusText:SetText(table.concat(lines, "\n"))
    end
end

local function commitSelectedMarket(self, mutate)
    local dataset = self:GetSelectedDataset()
    local market = self:GetSelectedMarket()
    if not dataset or not market or type(mutate) ~= "function" then
        return false
    end

    local before = self:DeepCopyValue(market)
    mutate(market, dataset)

    local rawErrors, rawWarnings = getMarketValidation(self, dataset, market)
    if #rawErrors > 0 then
        applyTable(market, before)
        setStatus(self, rawErrors, rawWarnings)
        return false
    end

    if MarketClass and MarketClass.New and MarketClass.ToTable then
        applyTable(market, MarketClass:New(market):ToTable())
    end

    local errors, warnings = getMarketValidation(self, dataset, market)
    if #errors > 0 then
        applyTable(market, before)
        setStatus(self, errors, warnings)
        return false
    end
    if self:DeepEqualValues(before, market) then
        return true
    end

    if type(Database.NotifyDatasetEntryChanged) == "function" then
        Database.NotifyDatasetEntryChanged(dataset.id, "markets", { deferConfigurationChanged = true })
    end
    if self.QueuePendingDatasetEntryChanged then
        self:QueuePendingDatasetEntryChanged(dataset.id, "markets")
    end
    self:RefreshContentPageByKey("markets")
    self:RefreshMarketInspectorPage()
    return true
end

local function swapValues(values, leftIndex, rightIndex)
    values[leftIndex], values[rightIndex] = values[rightIndex], values[leftIndex]
end

function DataEditor:BuildMarketTrackerItems(market)
    local items = { { label = "None", value = "" } }
    local currentReference = trim(market and market.trackerMarketRef)
    local markets = type(Registry.ListMarkets) == "function" and Registry:ListMarkets() or {}
    for index = 1, #markets do
        local row = markets[index]
        local target = row and row.market
        if target and string.lower(trim(target.marketType)) == "tracker" and row.marketRef ~= (self:GetSelectedDataset() and self:GetSelectedDataset().id or "") .. ":" .. trim(market and market.id) then
            items[#items + 1] = {
                label = ("%s / %s"):format(self:GetDatasetDisplayName(row.dataset), self:GetEntryDisplayName("markets", target)),
                value = row.marketRef,
            }
        end
    end
    appendMissingDropdownValue(items, currentReference, "Missing or invalid tracker: " .. currentReference)
    return items
end

function DataEditor:SetMarketInspectorTab(tabKey)
    local market = self:GetSelectedMarket()
    local activeKey = tabKey == "eligibility" and "eligibility" or "general"
    if not market or trim(market.marketType) == "tracker" then
        activeKey = "general"
    end
    self.ActiveMarketInspectorTabKey = activeKey
    setShown(self.MarketInspectorGeneralPage, activeKey == "general")
    setShown(self.MarketInspectorEligibilityPage, activeKey == "eligibility")
    if self.MarketInspectorTabDropdown then
        self._refreshingMarketInspectorTab = true
        self.MarketInspectorTabDropdown:SetSelectedValue(activeKey, true)
        self._refreshingMarketInspectorTab = false
    end
end

local function createItemCollectionEditor(self, root, prefix, title, getValues)
    addLabel(root, "RPEDataEditorMarketInspector" .. prefix .. "Title", title)
    local pickerRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorMarketInspector" .. prefix .. "PickerRow", {
        spacing = 4, height = CONTROL_HEIGHT, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    local datasetDropdown = UI.CreateDropdown(pickerRow:GetFrame(), "RPEDataEditorMarketInspector" .. prefix .. "DatasetDropdown", {
        width = 94, height = CONTROL_HEIGHT, items = self:BuildItemInspectorDatasetItems(),
        onValueChanged = function(value)
            if self._refreshingMarketInspector then return end
            local itemDropdown = self["MarketInspector" .. prefix .. "ItemDropdown"]
            if itemDropdown then
                itemDropdown:SetItems(buildItemReferenceItems(self, value, ""))
                itemDropdown:SetSelectedValue("", true)
            end
        end,
    })
    pickerRow:AddChild(datasetDropdown)
    self["MarketInspector" .. prefix .. "DatasetDropdown"] = datasetDropdown

    local itemDropdown = UI.CreateDropdown(pickerRow:GetFrame(), "RPEDataEditorMarketInspector" .. prefix .. "ItemDropdown", {
        width = 92, height = CONTROL_HEIGHT, items = { { label = "None", value = "" } },
    })
    pickerRow:AddChild(itemDropdown)
    self["MarketInspector" .. prefix .. "ItemDropdown"] = itemDropdown

    local addButton = UI.CreateButton(pickerRow:GetFrame(), "RPEDataEditorMarketInspector" .. prefix .. "AddButton", "Add", 40, function()
        local reference = itemDropdown:GetSelectedValue()
        if trim(reference) == "" then return end
        commitSelectedMarket(self, function(market)
            local values = getValues(market)
            for index = 1, #values do
                if values[index] == reference then return end
            end
            values[#values + 1] = reference
        end)
    end, { height = CONTROL_HEIGHT, fontSize = 7 })
    pickerRow:AddChild(addButton)
    root:AddChild(pickerRow)

    local scroll = UI.ScrollLayout:New({
        name = "RPEDataEditorMarketInspector" .. prefix .. "Scroll", width = FIELD_WIDTH - 12, height = 54,
        visibleRows = 3, autoFitRows = true, rowHeight = 18, rowSpacing = 0, border = false,
        rowElementClass = UI.ScrollListEntry, categoryWidth = 128, statusWidth = 50,
        categoryInsetLeft = 4, statusInsetRight = 4,
    })
    scroll:SetParent(root:GetFrame())
    scroll:SetRowRenderer(function(row, reference, itemIndex)
        local _, item, reason = resolveItem(reference)
        row:SetCategory(itemRowLabel(reference, item))
        row:SetStatus(item and "OK" or "Missing")
        row:SetDetail(tostring(reference or ""))
        local frame = row:GetFrame()
        frame:EnableMouse(true)
        frame:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then
                self["MarketInspector" .. prefix .. "SelectedIndex"] = itemIndex
                self["MarketInspector" .. prefix .. "Status"] = reason
                self:RefreshMarketInspectorPage()
            end
        end)
        if row.entryBackground and row.entryBackground.SetColorTexture then
            local selected = tonumber(self["MarketInspector" .. prefix .. "SelectedIndex"]) == tonumber(itemIndex)
            local color = UI.ResolveColor(nil, selected and "list.rowHover" or "list.rowBackground")
            row.entryBackground:SetColorTexture(color.r, color.g, color.b, color.a)
        end
    end)
    scroll:Create()
    root:AddChild(scroll)
    self["MarketInspector" .. prefix .. "Scroll"] = scroll

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorMarketInspector" .. prefix .. "Actions", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    local function mutateList(mutate)
        local index = tonumber(self["MarketInspector" .. prefix .. "SelectedIndex"])
        if not index then return end
        commitSelectedMarket(self, function(market)
            mutate(getValues(market), index)
        end)
    end
    local removeButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorMarketInspector" .. prefix .. "RemoveButton", "Remove", 50, function()
        mutateList(function(values, index) table.remove(values, index) end)
        self["MarketInspector" .. prefix .. "SelectedIndex"] = nil
        self:RefreshMarketInspectorPage()
    end, { height = 18, fontSize = 7 })
    local upButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorMarketInspector" .. prefix .. "UpButton", "Up", 34, function()
        mutateList(function(values, index) if index > 1 then swapValues(values, index, index - 1); self["MarketInspector" .. prefix .. "SelectedIndex"] = index - 1 end end)
    end, { height = 18, fontSize = 7 })
    local downButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorMarketInspector" .. prefix .. "DownButton", "Down", 42, function()
        mutateList(function(values, index) if index < #values then swapValues(values, index, index + 1); self["MarketInspector" .. prefix .. "SelectedIndex"] = index + 1 end end)
    end, { height = 18, fontSize = 7 })
    actions:AddChild(removeButton)
    actions:AddChild(upButton)
    actions:AddChild(downButton)
    root:AddChild(actions)
    self["MarketInspector" .. prefix .. "Actions"] = actions
end

local function createSellRuleDropdown(self, root, key, label, ruleField, items)
    local group = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorMarketInspector" .. key .. "Group", {
        spacing = 2,
        width = FIELD_WIDTH,
        height = 34,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    group:AddChild(UI.CreateText(group:GetFrame(), "RPEDataEditorMarketInspector" .. key .. "Label", label, {
        width = FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    local dropdown = UI.CreateDropdown(group:GetFrame(), "RPEDataEditorMarketInspector" .. key .. "Dropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = items or {},
        multiSelect = true,
        showSelectionActions = false,
        onValueChanged = function(values)
            if not self._refreshingMarketInspector then
                commitSelectedMarket(self, function(market)
                    market.sellRules = market.sellRules or {}
                    market.sellRules[ruleField] = values or {}
                end)
            end
        end,
    })
    group:AddChild(dropdown)
    root:AddChild(group)
    self["MarketInspector" .. key .. "Group"] = group
    self["MarketInspector" .. key .. "Dropdown"] = dropdown
end

function DataEditor:BuildMarketInspectorPage(parent)
    if self.MarketInspectorPage then
        return self.MarketInspectorPage
    end

    self.MarketInspectorPage = CreateFrame("Frame", "RPEDataEditorMarketInspectorPage", parent)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.MarketInspectorPage, "RPEDataEditorMarketInspectorLayout", {
        spacing = 4, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, self.MarketInspectorPage, SIDE_PADDING, 0, SIDE_PADDING, 0)

    self.MarketInspectorTabDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorMarketInspectorTabDropdown", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT,
        items = { { label = "General", value = "general" }, { label = "Exchange Eligibility", value = "eligibility" } },
        onValueChanged = function(value)
            if not self._refreshingMarketInspectorTab then self:SetMarketInspectorTab(value) end
        end,
    })
    root:AddChild(self.MarketInspectorTabDropdown)

    self.MarketInspectorGeneralPage = CreateFrame("Frame", "RPEDataEditorMarketInspectorGeneralPage", self.MarketInspectorPage)
    self.MarketInspectorEligibilityPage = CreateFrame("Frame", "RPEDataEditorMarketInspectorEligibilityPage", self.MarketInspectorPage)
    self.MarketInspectorGeneralPage:SetPoint("TOPLEFT", self.MarketInspectorPage, "TOPLEFT", SIDE_PADDING, -28)
    self.MarketInspectorGeneralPage:SetPoint("TOPRIGHT", self.MarketInspectorPage, "TOPRIGHT", -SIDE_PADDING, -28)
    self.MarketInspectorGeneralPage:SetPoint("BOTTOMLEFT", self.MarketInspectorPage, "BOTTOMLEFT", SIDE_PADDING, 0)
    self.MarketInspectorGeneralPage:SetPoint("BOTTOMRIGHT", self.MarketInspectorPage, "BOTTOMRIGHT", -SIDE_PADDING, 0)
    self.MarketInspectorEligibilityPage:SetAllPoints(self.MarketInspectorGeneralPage)

    local general = UI.CreateLayout(UI.VerticalLayoutGroup, self.MarketInspectorGeneralPage, "RPEDataEditorMarketInspectorGeneralLayout", {
        spacing = 4, fitChildrenWidth = true, fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(general, self.MarketInspectorGeneralPage, 0, 0, 0, 0)

    self.MarketInspectorIdText = addLabel(general, "RPEDataEditorMarketInspectorIdText", "Generated ID: -")
    self.MarketInspectorReferenceText = addLabel(general, "RPEDataEditorMarketInspectorReferenceText", "Market Ref: -")
    addField(general, self, "Name", "Name", { commit = function() commitSelectedMarket(self, function(market) market.name = self.MarketInspectorNameControl:GetText() end) end })
    addField(general, self, "Index", "Index", { commit = function() commitSelectedMarket(self, function(market) market.index = string.upper(trim(self.MarketInspectorIndexControl:GetText())) end) end })
    addField(general, self, "MarketType", "Type", {
        dropdown = true, items = MARKET_TYPE_ITEMS,
        onValueChanged = function(value)
            if not self._refreshingMarketInspector then
                commitSelectedMarket(self, function(market) market.marketType = value or "exchange" end)
            end
        end,
    })
    addField(general, self, "BaseCoefficient", "Base %", { commit = function() commitSelectedMarket(self, function(market) market.baseCoefficientPercent = parseFiniteNumber(self.MarketInspectorBaseCoefficientControl:GetText()) end) end })
    addField(general, self, "DailyVariation", "Daily variation %", { commit = function() commitSelectedMarket(self, function(market) market.dailyVariationPercent = parseFiniteNumber(self.MarketInspectorDailyVariationControl:GetText()) end) end })
    addField(general, self, "TrackerMarketRef", "Tracker market", {
        dropdown = true, items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if not self._refreshingMarketInspector then
                commitSelectedMarket(self, function(market) market.trackerMarketRef = trim(value) end)
            end
        end,
    })
    addField(general, self, "TrackerInfluence", "Tracker influence %", { commit = function() commitSelectedMarket(self, function(market) market.trackerInfluencePercent = parseFiniteNumber(self.MarketInspectorTrackerInfluenceControl:GetText()) end) end })
    addField(general, self, "Tariff", "Tariff %", { commit = function() commitSelectedMarket(self, function(market) market.tariffPercent = parseFiniteNumber(self.MarketInspectorTariffControl:GetText()) end) end })
    self.MarketInspectorStatusText = UI.CreateText(general:GetFrame(), "RPEDataEditorMarketInspectorStatusText", "", {
        width = FIELD_WIDTH, height = 42, justifyH = "LEFT", wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    general:AddChild(self.MarketInspectorStatusText)

    local eligibility = UI.CreateLayout(UI.VerticalLayoutGroup, self.MarketInspectorEligibilityPage, "RPEDataEditorMarketInspectorEligibilityLayout", {
        spacing = 4, fitChildrenWidth = true, fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(eligibility, self.MarketInspectorEligibilityPage, 0, 0, 0, 0)
    createItemCollectionEditor(self, eligibility, "Buy", "Buy catalogue", function(market)
        market.buyItemRefs = market.buyItemRefs or {}
        return market.buyItemRefs
    end)
    createItemCollectionEditor(self, eligibility, "Sell", "Exact sell item allow-list", function(market)
        market.sellRules = market.sellRules or {}
        market.sellRules.itemRefs = market.sellRules.itemRefs or {}
        return market.sellRules.itemRefs
    end)

    createSellRuleDropdown(self, eligibility, "SellTypes", "Sell item types", "itemTypes", ITEM_TYPE_ITEMS)
    createSellRuleDropdown(self, eligibility, "ArmorWeights", "Armor weights", "armorWeights", ARMOR_WEIGHT_ITEMS)
    createSellRuleDropdown(self, eligibility, "WeaponTypes", "Weapon types", "weaponTypeRefs", {})
    createSellRuleDropdown(self, eligibility, "ItemSlots", "Item slots", "slotRefs", {})
    createSellRuleDropdown(self, eligibility, "ConsumableTypes", "Consumable subtypes", "consumableTypes", CONSUMABLE_TYPE_ITEMS)
    createSellRuleDropdown(self, eligibility, "ConsumableElixirTypes", "Elixir subtypes", "consumableElixirTypes", CONSUMABLE_ELIXIR_TYPE_ITEMS)
    createSellRuleDropdown(self, eligibility, "ModificationKinds", "Modification kinds", "modificationKinds", MODIFICATION_KIND_ITEMS)
    createSellRuleDropdown(self, eligibility, "ModificationTargetSlots", "Modification target slots", "targetSlotRefs", {})
    createSellRuleDropdown(self, eligibility, "ModificationTargetWeaponTypes", "Modification target weapon types", "targetWeaponTypeRefs", {})
    createSellRuleDropdown(self, eligibility, "ModificationTargetArmorWeights", "Modification target armor weights", "targetArmorWeights", MODIFICATION_ARMOR_WEIGHT_ITEMS)

    self.MarketInspectorHelpText = UI.CreateText(eligibility:GetFrame(), "RPEDataEditorMarketInspectorHelpText", "Sell rules match exact item refs or selected item types. Type-specific filters are combined when present; empty filters add no restriction. Exact item refs override filters. No rules means no sale.", {
        width = FIELD_WIDTH, height = 54, justifyH = "LEFT", wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    eligibility:AddChild(self.MarketInspectorHelpText)

    self:SetMarketInspectorTab("general")
    self:RefreshMarketInspectorPage()
    return self.MarketInspectorPage
end

function DataEditor:RefreshMarketInspectorPage()
    local market = self:GetSelectedMarket()
    local dataset = self:GetSelectedDataset()
    local hasMarket = market ~= nil and dataset ~= nil
    local marketType = string.lower(trim(market and market.marketType))
    local isExchange = hasMarket and marketType == "exchange"

    if self.MarketInspectorIdText then
        self.MarketInspectorIdText:SetText("Generated ID: " .. (hasMarket and tostring(market.id or "-") or "-"))
    end
    if self.MarketInspectorReferenceText then
        self.MarketInspectorReferenceText:SetText("Market Ref: " .. (hasMarket and ((tostring(dataset.id) .. ":" .. tostring(market.id or ""))) or "-"))
    end

    self._refreshingMarketInspector = true
    local textFields = {
        { key = "Name", value = market and market.name or "" },
        { key = "Index", value = market and market.index or "" },
        { key = "BaseCoefficient", value = market and market.baseCoefficientPercent or 0 },
        { key = "DailyVariation", value = market and market.dailyVariationPercent or 0 },
        { key = "TrackerInfluence", value = market and market.trackerInfluencePercent or 0 },
        { key = "Tariff", value = market and market.tariffPercent or 0 },
    }
    for index = 1, #textFields do
        local field = textFields[index]
        local control = self["MarketInspector" .. field.key .. "Control"]
        if control then
            control:SetText(tostring(field.value or ""))
            setTextEnabled(control, hasMarket)
        end
    end

    if self.MarketInspectorMarketTypeControl then
        self.MarketInspectorMarketTypeControl:SetSelectedValue(market and market.marketType or "exchange", true)
        setDropdownEnabled(self.MarketInspectorMarketTypeControl, hasMarket)
    end
    if self.MarketInspectorTrackerMarketRefControl then
        self.MarketInspectorTrackerMarketRefControl:SetItems(self:BuildMarketTrackerItems(market))
        self.MarketInspectorTrackerMarketRefControl:SetSelectedValue(market and market.trackerMarketRef or "", true)
        setDropdownEnabled(self.MarketInspectorTrackerMarketRefControl, isExchange)
    end
    if self.MarketInspectorTrackerMarketRefRow then
        setShown(self.MarketInspectorTrackerMarketRefRow, isExchange)
    end
    if self.MarketInspectorTariffRow then
        setShown(self.MarketInspectorTariffRow, isExchange)
    end

    if self.MarketInspectorBuyScroll then self.MarketInspectorBuyScroll:SetItems(isExchange and (market.buyItemRefs or {}) or {}) end
    if self.MarketInspectorSellScroll then self.MarketInspectorSellScroll:SetItems(isExchange and ((market.sellRules or {}).itemRefs or {}) or {}) end
    local sellRules = market and market.sellRules or {}
    local selectedTypes = sellRules.itemTypes or {}
    local showArmor = selectedValuesContain(selectedTypes, "armor")
    local showWeapon = selectedValuesContain(selectedTypes, "weapon")
    local showConsumable = selectedValuesContain(selectedTypes, "consumable")
    local showModification = selectedValuesContain(selectedTypes, "modification")
    local showElixir = showConsumable and selectedValuesContain(sellRules.consumableTypes, "elixir")
    local sellRuleDropdowns = {
        { key = "SellTypes", field = "itemTypes", items = copyDropdownItems(ITEM_TYPE_ITEMS, sellRules.itemTypes, "Unknown item type"), shown = true },
        { key = "ArmorWeights", field = "armorWeights", items = copyDropdownItems(ARMOR_WEIGHT_ITEMS, sellRules.armorWeights, "Unknown armor weight"), shown = showArmor },
        { key = "WeaponTypes", field = "weaponTypeRefs", items = buildActivatedCollectionItems(self, "weaponTypes", sellRules.weaponTypeRefs, "Missing weapon type"), shown = showWeapon },
        { key = "ItemSlots", field = "slotRefs", items = buildActivatedCollectionItems(self, "itemSlots", sellRules.slotRefs, "Missing item slot"), shown = showArmor or showWeapon },
        { key = "ConsumableTypes", field = "consumableTypes", items = copyDropdownItems(CONSUMABLE_TYPE_ITEMS, sellRules.consumableTypes, "Unknown consumable subtype"), shown = showConsumable },
        { key = "ConsumableElixirTypes", field = "consumableElixirTypes", items = copyDropdownItems(CONSUMABLE_ELIXIR_TYPE_ITEMS, sellRules.consumableElixirTypes, "Unknown elixir subtype"), shown = showElixir },
        { key = "ModificationKinds", field = "modificationKinds", items = copyDropdownItems(MODIFICATION_KIND_ITEMS, sellRules.modificationKinds, "Unknown modification kind"), shown = showModification },
        { key = "ModificationTargetSlots", field = "targetSlotRefs", items = buildActivatedCollectionItems(self, "itemSlots", sellRules.targetSlotRefs, "Missing item slot"), shown = showModification },
        { key = "ModificationTargetWeaponTypes", field = "targetWeaponTypeRefs", items = buildActivatedCollectionItems(self, "weaponTypes", sellRules.targetWeaponTypeRefs, "Missing weapon type"), shown = showModification },
        { key = "ModificationTargetArmorWeights", field = "targetArmorWeights", items = copyDropdownItems(MODIFICATION_ARMOR_WEIGHT_ITEMS, sellRules.targetArmorWeights, "Unknown armor weight"), shown = showModification },
    }
    for ruleIndex = 1, #sellRuleDropdowns do
        local definition = sellRuleDropdowns[ruleIndex]
        local dropdown = self["MarketInspector" .. definition.key .. "Dropdown"]
        if dropdown then
            dropdown:SetItems(definition.items)
            dropdown:SetSelectedValues(isExchange and (sellRules[definition.field] or {}) or {}, true)
            setDropdownEnabled(dropdown, isExchange and definition.shown)
        end
        setShown(self["MarketInspector" .. definition.key .. "Group"], isExchange and definition.shown)
    end

    for _, prefix in ipairs({ "Buy", "Sell" }) do
        local datasetDropdown = self["MarketInspector" .. prefix .. "DatasetDropdown"]
        local itemDropdown = self["MarketInspector" .. prefix .. "ItemDropdown"]
        if datasetDropdown then
            datasetDropdown:SetItems(self:BuildItemInspectorDatasetItems())
            setDropdownEnabled(datasetDropdown, isExchange)
        end
        if itemDropdown then
            itemDropdown:SetItems({ { label = "None", value = "" } })
            setDropdownEnabled(itemDropdown, isExchange)
        end
        local scroll = self["MarketInspector" .. prefix .. "Scroll"]
        if scroll then setShown(scroll, isExchange) end
        setShown(self["MarketInspector" .. prefix .. "Actions"], isExchange)
    end
    self._refreshingMarketInspector = false

    self:SetMarketInspectorTab(self.ActiveMarketInspectorTabKey or "general")
    if hasMarket then
        local errors, warnings = getMarketValidation(self, dataset, market)
        setStatus(self, errors, warnings)
    else
        setStatus(self, { "Select a Market to edit it." }, {})
    end
end
