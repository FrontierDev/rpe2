local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Trading = Addon.Client.UI.Trading or {}

local Client = Addon.Client
local TradingUI = Addon.Client.UI.Trading
local UI = Addon.UI or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Trading = Client.Trading or {}
local Tooltips = Addon.Client.UI.Tooltips or {}
local ItemTooltip = Tooltips.Item

local ItemsPage = TradingUI.Items or {}
TradingUI.Items = ItemsPage
ItemsPage.__index = ItemsPage

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local MODE_BUY = "buy"
local MODE_SELL = "sell"
local ITEMS_PER_PAGE = 4
local ROW_HEIGHT = 34
local CONTROL_HEIGHT = 20
local DETAIL_HEIGHT = 116
local PAGE_BUTTON_WIDTH = 22
local PAGE_TEXT_WIDTH = 74
local MAX_QUANTITY = 2147483647

local QUALITY_LABELS = {
    poor = "Poor",
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    epic = "Epic",
    legendary = "Legendary",
    artifact = "Artifact",
}

local TYPE_LABELS = {
    armor = "Armor",
    consumable = "Consumables",
    material = "Materials",
    modification = "Modifications",
    weapon = "Weapons",
}

local SUBTYPE_LABELS = {
    elixir = "Elixirs",
    flask = "Flasks",
    potion = "Potions",
}

local REASON_LABELS = {
    ["calendar-unavailable"] = "Daily rate data is unavailable.",
    ["currency-cap-reached"] = "The copper balance is at its limit.",
    ["currency-api-unavailable"] = "RPE copper is unavailable.",
    ["currency-credit-failed"] = "Copper could not be awarded.",
    ["currency-transaction-failed"] = "The copper transaction failed.",
    ["insufficient-currency"] = "Not enough RPE copper.",
    ["insufficient-items"] = "The selected variant does not have enough items.",
    ["invalid-inventory-variant"] = "The selected inventory variant is no longer valid.",
    ["invalid-item-price"] = "This item has no valid price.",
    ["item-cannot-sell"] = "This item cannot be sold.",
    ["item-cannot-trade"] = "This item cannot be traded.",
    ["item-grant-failed"] = "The item could not be granted.",
    ["item-not-for-sale"] = "This item is not listed by the Market.",
    ["item-unavailable"] = "This item is unavailable.",
    ["market-not-tradable"] = "Tracker markets do not support trading.",
    ["market-rates-unavailable"] = "The current Market rate is unavailable.",
    ["missing-item"] = "This item is missing from the active datasets.",
    ["missing-market"] = "The Market is unavailable.",
    ["missing-tracker-market"] = "The linked tracker Market is unavailable.",
    ["no-stock"] = "This Market has no available stock.",
    ["registry-error"] = "Market data could not be read.",
    ["registry-unavailable"] = "Market data is unavailable.",
    ["rollback-failed"] = "The trade failed and could not be rolled back safely.",
    ["trade-api-unavailable"] = "Trading services are unavailable.",
    ["transaction-failed"] = "The trade transaction failed.",
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function lower(value)
    return string.lower(trim(value))
end

local function isFinite(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function titleCase(value)
    local text = trim(value)
    if text == "" then
        return ""
    end
    return text:sub(1, 1):upper() .. text:sub(2):lower()
end

local function qualityLabel(item)
    local quality = lower(item and item.quality)
    return QUALITY_LABELS[quality] or titleCase(quality)
end

local function itemName(item, itemRef)
    local name = trim(item and item.name)
    return name ~= "" and name or trim(itemRef)
end

local function itemType(item)
    return lower(item and item.itemType)
end

local function consumableType(item)
    return lower(item and item.consumableType)
end

local function typeLabel(kind)
    return TYPE_LABELS[kind] or titleCase(kind)
end

local function formatCopper(value)
    if type(Common.FormatCopper) == "function" then
        return Common:FormatCopper(value)
    end
    return tostring(math.max(0, math.floor(tonumber(value) or 0))) .. "c"
end

local function formatReason(reason, detail)
    local code = trim(reason)
    local message = type(detail) == "table" and trim(detail.message) or ""
    local label = REASON_LABELS[code] or message
    if label == "" then
        label = code ~= "" and code or "Trade unavailable."
    end
    if code ~= "" and not REASON_LABELS[code] and message ~= "" then
        return ("Trade failed (%s): %s"):format(code, label)
    end
    return label
end

local function formatActionReason(reason, detail)
    local code = trim(reason)
    local message = formatReason(reason, detail)
    if code == "" then
        return message
    end
    return ("Trade failed (%s): %s"):format(code, message)
end

local function setShown(element, shown, height)
    local frame = element and element.GetFrame and element:GetFrame() or nil
    if frame then
        if frame.SetShown then
            frame:SetShown(shown == true)
        elseif shown then
            frame:Show()
        else
            frame:Hide()
        end
        if height ~= nil and frame.SetHeight then
            frame:SetHeight(height)
        end
    end
    if element and type(element.options) == "table" and height ~= nil then
        element.options.height = height
        element.options.expandHeight = false
        element.options.weight = 0
    end
end

local function makeVariantKey(entry)
    if not entry then
        return nil
    end
    if entry.mode == MODE_SELL then
        return table.concat({
            trim(entry.itemRef),
            trim(entry.stackKey or entry.variant and entry.variant.stackKey),
        }, "|")
    end
    return trim(entry.itemRef)
end

local function getSelectedItem(self)
    for index = 1, #self.filteredItems do
        if self.filteredItems[index].key == self.selectedItemKey then
            return self.filteredItems[index]
        end
    end
    return nil
end

local function findCategoryIndex(categories, value)
    for index = 1, #categories do
        if categories[index].value == value then
            return index
        end
    end
    return nil
end

local function createInstance()
    return setmetatable({
        owner = nil,
        root = nil,
        marketRef = nil,
        market = nil,
        mode = MODE_BUY,
        categoryValue = "all",
        categories = {},
        items = {},
        filteredItems = {},
        page = 1,
        selectedItemKey = nil,
        quantity = 1,
        updatingQuantityInput = false,
        processing = false,
        feedback = "",
        built = false,
        rows = {},
        modeButtons = {},
        marketContext = nil,
        filterDropdown = nil,
        pageText = nil,
        emptyText = nil,
        listLayout = nil,
        detailName = nil,
        balanceText = nil,
        quantityInput = nil,
        quantityPreview = nil,
        actionButton = nil,
        feedbackText = nil,
    }, ItemsPage)
end

function ItemsPage:New()
    return createInstance()
end

function ItemsPage:GetCategoryValue()
    return self.categoryValue or "all"
end

function ItemsPage:GetSelectedItem()
    return getSelectedItem(self)
end

function ItemsPage:GetBalance()
    if type(Profile.GetCurrencyAmount) ~= "function" then
        return nil
    end
    local ok, amount = pcall(Profile.GetCurrencyAmount, "copper")
    amount = ok and tonumber(amount) or nil
    if not ok or not isFinite(amount) or amount < 0 then
        return nil
    end
    return math.floor(amount)
end

function ItemsPage:ResolveItem(itemRef)
    if type(Registry.ResolveItemReference) ~= "function" then
        return nil, nil, "registry-unavailable"
    end
    local ok, dataset, item, reason = pcall(Registry.ResolveItemReference, Registry, itemRef)
    if not ok then
        return nil, nil, "registry-error"
    end
    if type(dataset) ~= "table" or type(item) ~= "table" then
        return nil, nil, tostring(reason or "item-unavailable")
    end
    return dataset, item
end

function ItemsPage:BuildBuyItems()
    local rows = {}
    local seen = {}
    local authored = type(self.market) == "table" and self.market.buyItemRefs or {}
    for index = 1, #authored do
        local itemRef = trim(authored[index])
        if itemRef ~= "" and not seen[itemRef] then
            seen[itemRef] = true
            local dataset, item, resolveReason = self:ResolveItem(itemRef)
            local row = {
                mode = MODE_BUY,
                itemRef = itemRef,
                dataset = dataset,
                item = item,
                enabled = false,
                reason = resolveReason,
            }
            if item then
                local ok, quote, quoteError
                if type(Trading.Quote) == "function" then
                    ok, quote, quoteError = pcall(Trading.Quote, self.marketRef, itemRef, MODE_BUY, 1)
                else
                    quoteError = { code = "trade-api-unavailable" }
                end
                if ok and type(quote) == "table" then
                    row.quote = quote
                    row.unitCopper = tonumber(quote.unitCopper)
                    row.enabled = isFinite(row.unitCopper) and row.unitCopper > 0
                    if not row.enabled then
                        row.reason = "invalid-item-price"
                    else
                        local balance = self:GetBalance()
                        if balance == nil then
                            row.enabled = false
                            row.reason = "currency-api-unavailable"
                        elseif row.unitCopper > balance then
                            row.enabled = false
                            row.reason = "insufficient-currency"
                        end
                    end
                elseif type(quoteError) == "table" then
                    row.reason = type(quoteError) == "table" and quoteError.code or "item-unavailable"
                    row.error = quoteError
                elseif ok then
                    row.reason = "item-unavailable"
                else
                    row.reason = "transaction-failed"
                end
            end
            row.key = makeVariantKey(row)
            rows[#rows + 1] = row
        end
    end
    table.sort(rows, function(left, right)
        local leftName = lower(itemName(left.item, left.itemRef))
        local rightName = lower(itemName(right.item, right.itemRef))
        if leftName ~= rightName then
            return leftName < rightName
        end
        return left.itemRef < right.itemRef
    end)
    return rows
end

function ItemsPage:BuildSellItems()
    if type(Trading.GetEligibleInventory) ~= "function" then
        return {}, "trade-api-unavailable"
    end
    local ok, entries, errorValue = pcall(Trading.GetEligibleInventory, self.marketRef)
    if not ok then
        return {}, "transaction-failed"
    end
    if type(entries) ~= "table" then
        return {}, type(errorValue) == "table" and errorValue.code or "item-unavailable"
    end

    local rows = {}
    for index = 1, #entries do
        local entry = entries[index]
        if type(entry) == "table" and type(entry.item) == "table" then
            local row = {
                mode = MODE_SELL,
                itemRef = trim(entry.itemRef or entry.ref),
                dataset = { id = entry.datasetId },
                item = entry.item,
                variant = entry.variant,
                stackKey = entry.stackKey or entry.stackIdentity,
                quantityAvailable = math.max(0, math.floor(tonumber(entry.quantity) or 0)),
                unitCopper = tonumber(entry.unitCopper),
                enabled = true,
            }
            row.key = makeVariantKey(row)
            if row.itemRef ~= "" and row.quantityAvailable > 0 and isFinite(row.unitCopper) and row.unitCopper > 0 then
                rows[#rows + 1] = row
            end
        end
    end
    table.sort(rows, function(left, right)
        local leftName = lower(itemName(left.item, left.itemRef))
        local rightName = lower(itemName(right.item, right.itemRef))
        if leftName ~= rightName then
            return leftName < rightName
        end
        local leftTier = lower(left.variant and left.variant.itemTier or "normal")
        local rightTier = lower(right.variant and right.variant.itemTier or "normal")
        if leftTier ~= rightTier then
            return leftTier < rightTier
        end
        return trim(left.stackKey) < trim(right.stackKey)
    end)
    return rows
end

function ItemsPage:BuildCategories()
    local byValue = { all = { value = "all", label = "All Items", sort = 0 } }
    for index = 1, #self.items do
        local item = self.items[index].item
        local kind = itemType(item)
        if kind ~= "" then
            local typeKey = "type:" .. kind
            byValue[typeKey] = byValue[typeKey] or {
                value = typeKey,
                label = typeLabel(kind),
                sort = 10,
            }
            if kind == "consumable" then
                local subtype = consumableType(item)
                if subtype ~= "" then
                    local subtypeKey = "consumable:" .. subtype
                    byValue[subtypeKey] = byValue[subtypeKey] or {
                        value = subtypeKey,
                        label = SUBTYPE_LABELS[subtype] or titleCase(subtype),
                        sort = 20,
                    }
                end
            end
        end
    end

    local categories = {}
    for _, category in pairs(byValue) do
        categories[#categories + 1] = category
    end
    table.sort(categories, function(left, right)
        if left.sort ~= right.sort then
            return left.sort < right.sort
        end
        return lower(left.label) < lower(right.label)
    end)
    self.categories = categories
    local selectedIndex = findCategoryIndex(self.categories, self.categoryValue) or 1
    self.categoryValue = self.categories[selectedIndex].value
end

function ItemsPage:ApplyFilter()
    local category = self:GetCategoryValue()
    self.filteredItems = {}
    for index = 1, #self.items do
        local row = self.items[index]
        local matches = category == "all"
        if not matches and row.item then
            local kind = itemType(row.item)
            matches = category == ("type:" .. kind)
            if not matches and kind == "consumable" then
                matches = category == ("consumable:" .. consumableType(row.item))
            end
        end
        if matches then
            self.filteredItems[#self.filteredItems + 1] = row
        end
    end
end

function ItemsPage:EnsureSelection()
    if getSelectedItem(self) then
        return
    end
    self.selectedItemKey = nil
    for index = 1, #self.filteredItems do
        if self.filteredItems[index].enabled ~= false then
            self.selectedItemKey = self.filteredItems[index].key
            break
        end
    end
    if not self.selectedItemKey and self.filteredItems[1] then
        self.selectedItemKey = self.filteredItems[1].key
    end
end

function ItemsPage:RefreshRowMetrics()
    local listFrame = self.listLayout and self.listLayout:GetFrame() or nil
    local width = listFrame and tonumber(listFrame:GetWidth()) or 0
    if width <= 0 then
        return
    end
    for index = 1, #self.rows do
        if self.rows[index].SetLayoutMetrics then
            self.rows[index]:SetLayoutMetrics(width, ROW_HEIGHT)
        end
    end
end

function ItemsPage:UpdateModeButtons()
    local canTrade = self.market and lower(self.market.marketType) == "exchange"
    for mode, button in pairs(self.modeButtons) do
        local selected = mode == self.mode
        local color = UI.ResolveColor(nil, selected and "tab.bar" or "panel.background")
        if button.background and button.background.SetColorTexture then
            button.background:SetColorTexture(color.r, color.g, color.b, color.a)
        end
        button:SetLabelColor(
            UI.ResolveColor(nil, selected and "accent" or "text.primary").r,
            UI.ResolveColor(nil, selected and "accent" or "text.primary").g,
            UI.ResolveColor(nil, selected and "accent" or "text.primary").b,
            UI.ResolveColor(nil, selected and "accent" or "text.primary").a
        )
        button:SetEnabled(canTrade and not self.processing)
    end
end

function ItemsPage:UpdateRows()
    local total = #self.filteredItems
    local pageCount = math.max(1, math.ceil(total / ITEMS_PER_PAGE))
    self.page = math.max(1, math.min(self.page, pageCount))
    local firstIndex = ((self.page - 1) * ITEMS_PER_PAGE) + 1

    for rowIndex = 1, #self.rows do
        local row = self.rows[rowIndex]
        local item = self.filteredItems[firstIndex + rowIndex - 1]
        if item then
            local displayName = itemName(item.item, item.itemRef)
            local quality = qualityLabel(item.item)
            if quality ~= "" then
                displayName = ("%s (%s)"):format(displayName, quality)
            end
            local tier = lower(item.variant and item.variant.itemTier or item.item and item.item.itemTier)
            if tier ~= "" and tier ~= "normal" then
                displayName = ("%s [%s]"):format(displayName, titleCase(tier))
            end
            local costText = item.unitCopper and formatCopper(item.unitCopper) or formatReason(item.reason, item.error)
            if item.mode == MODE_SELL then
                costText = ("%s x%d"):format(costText, item.quantityAvailable)
            elseif not item.enabled then
                costText = ("%s - %s"):format(costText, formatReason(item.reason, item.error))
            end

            row._itemKey = item.key
            row:SetIcon(item.item and item.item.icon or DEFAULT_ICON)
            row:SetItemName(displayName)
            row:SetCostText(costText)
            row:SetCostColor(item.enabled == false and "danger" or "text.secondary")
            row:SetEnabled(item.enabled ~= false and not self.processing)
            row:SetTooltip(function()
                return self:BuildItemTooltip(item)
            end)
            local selected = item.key == self.selectedItemKey
            local nameColor = UI.ResolveColor(nil, selected and "accent" or "text.primary")
            if row.nameRegion and row.nameRegion.SetTextColor then
                row.nameRegion:SetTextColor(nameColor.r, nameColor.g, nameColor.b, nameColor.a)
            end
            local borderColor = UI.ResolveColor(nil, selected and "accent" or "panel.border")
            row:SetBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
            row:Show()
            setShown(row, true, ROW_HEIGHT)
        else
            row._itemKey = nil
            row:SetTooltip(nil)
            row:SetIcon(DEFAULT_ICON)
            row:SetItemName("")
            row:SetCostText("")
            row:SetEnabled(false)
            setShown(row, false, 0)
        end
    end

    if total == 0 then
        local text = self.statusText or "No tradable items match this category."
        self.emptyText:SetText(text)
        setShown(self.emptyText, true, 34)
    else
        setShown(self.emptyText, false, 0)
    end
    self.pageText:SetText(("Page %d / %d"):format(self.page, pageCount))
    self.previousPageButton:SetEnabled(self.page > 1 and not self.processing)
    self.nextPageButton:SetEnabled(self.page < pageCount and not self.processing)
    self.filterDropdown:SetItems(self.categories)
    self.filterDropdown:SetSelectedValue(self:GetCategoryValue(), true)
    self.previousFilterButton:SetEnabled(#self.categories > 1 and self.filterDropdown:GetSelectedIndex() > 1 and not self.processing)
    self.nextFilterButton:SetEnabled(#self.categories > 1 and self.filterDropdown:GetSelectedIndex() < #self.categories and not self.processing)
    self:UpdateModeButtons()
    self.listLayout:RefreshLayout()
    self:RefreshRowMetrics()
end

function ItemsPage:BuildItemTooltip(row)
    if not row.item then
        return {
            type = "custom",
            title = itemName(nil, row.itemRef),
            lines = { { left = formatReason(row.reason, row.error), colorToken = "danger" } },
        }
    end
    local options = {
        itemRef = row.itemRef,
        datasetId = row.dataset and row.dataset.id,
        itemId = row.item.id,
        itemTier = row.variant and row.variant.itemTier or row.item.itemTier,
        quantity = row.quantityAvailable or 1,
        stackIdentity = row.stackKey,
        soulbound = row.variant and row.variant.soulbound == true,
    }
    local tooltip = type(ItemTooltip) == "table" and type(ItemTooltip.Build) == "function"
        and ItemTooltip:Build(row.item, options)
        or nil
    if type(tooltip) ~= "table" then
        tooltip = { type = "custom", title = itemName(row.item, row.itemRef), lines = {} }
    end
    if row.enabled == false then
        local lines = {}
        for index = 1, #(tooltip.lines or {}) do
            lines[index] = tooltip.lines[index]
        end
        lines[#lines + 1] = { left = formatReason(row.reason, row.error), colorToken = "danger" }
        local result = {}
        for key, value in pairs(tooltip) do
            result[key] = value
        end
        result.lines = lines
        return result
    end
    return tooltip
end

function ItemsPage:UpdateQuantityText()
    if self.quantityInput and not self.updatingQuantityInput then
        self.updatingQuantityInput = true
        self.quantityInput:SetText(tostring(self.quantity))
        self.updatingQuantityInput = false
    end
end

function ItemsPage:GetQuantityMaximum(row)
    if not row then
        return 1
    end
    if row.mode == MODE_SELL then
        return math.max(1, row.quantityAvailable or 1)
    end
    local balance = self:GetBalance()
    local unitCopper = tonumber(row.unitCopper) or 0
    if balance and unitCopper > 0 then
        return math.max(1, math.min(MAX_QUANTITY, math.floor(balance / unitCopper)))
    end
    return MAX_QUANTITY
end

function ItemsPage:SetQuantity(value)
    local row = self:GetSelectedItem()
    local numeric = tonumber(value)
    if not isFinite(numeric) then
        numeric = 1
    end
    numeric = math.floor(numeric)
    local maximum = self:GetQuantityMaximum(row)
    self.quantity = math.max(1, math.min(maximum, numeric))
    self:UpdateQuantityText()
    self:RefreshDetails()
end

function ItemsPage:OnQuantityInputChanged(input)
    if self.updatingQuantityInput then
        return
    end
    self:SetQuantity(input:GetText())
end

function ItemsPage:RefreshDetails()
    local row = self:GetSelectedItem()
    local balance = self:GetBalance()
    self.balanceText:SetText(balance and ("RPE Copper: " .. formatCopper(balance)) or "RPE Copper: unavailable")
    self.feedbackText:SetText(self.feedback or "")
    if not row then
        self.detailName:SetText("Select an item to trade.")
        self.quantity = 1
        self:UpdateQuantityText()
        self.quantityPreview:SetText("")
        self.actionButton:SetText(self.mode == MODE_BUY and "Buy" or "Sell")
        self.actionButton:SetEnabled(false)
        self.quantityDown:SetEnabled(false)
        self.quantityInput:SetEnabled(false)
        self.quantityUp:SetEnabled(false)
        return
    end

    local displayName = itemName(row.item, row.itemRef)
    local tier = lower(row.variant and row.variant.itemTier or row.item and row.item.itemTier)
    if tier ~= "" and tier ~= "normal" then
        displayName = ("%s [%s]"):format(displayName, titleCase(tier))
    end
    self.detailName:SetText(displayName)

    local ok, quote, quoteError = false, nil, nil
    if row.enabled ~= false and type(Trading.Quote) == "function" then
        if row.mode == MODE_SELL then
            ok, quote, quoteError = pcall(Trading.Quote, self.marketRef, row.itemRef, MODE_SELL, self.quantity, row.variant)
        else
            ok, quote, quoteError = pcall(Trading.Quote, self.marketRef, row.itemRef, MODE_BUY, self.quantity)
        end
    else
        quoteError = row.error or { code = row.reason }
    end

    local validQuote = ok and type(quote) == "table" and isFinite(tonumber(quote.totalCopper))
    if not validQuote then
        self.quantityPreview:SetText(formatReason(type(quoteError) == "table" and quoteError.code or row.reason, quoteError))
        self.actionButton:SetEnabled(false)
        self.actionButton:SetText(row.mode == MODE_BUY and "Buy" or "Sell")
        self.quantityDown:SetEnabled(false)
        self.quantityInput:SetEnabled(false)
        self.quantityUp:SetEnabled(false)
        return
    end

    local totalCopper = math.max(0, math.floor(tonumber(quote.totalCopper) or 0))
    local affordable = row.mode ~= MODE_BUY or (balance ~= nil and totalCopper <= balance)
    local actionAvailable = row.mode == MODE_BUY
        and type(Trading.TryBuy) == "function"
        or row.mode == MODE_SELL
        and type(Trading.TrySell) == "function"
    self.quantityPreview:SetText(("x%d %s %s"):format(self.quantity, "\194\183", formatCopper(totalCopper)))
    self.actionButton:SetText(row.mode == MODE_BUY and "Buy" or "Sell")
    self.actionButton:SetEnabled(affordable and actionAvailable and not self.processing)
    local quantityEnabled = row.enabled ~= false and not self.processing
    self.quantityDown:SetEnabled(quantityEnabled and self.quantity > 1)
    self.quantityInput:SetEnabled(quantityEnabled)
    self.quantityUp:SetEnabled(quantityEnabled and self.quantity < self:GetQuantityMaximum(row))
    if not affordable then
        self.quantityPreview:SetText(("x%d %s %s (%s)"):format(
            self.quantity,
            "\194\183",
            formatCopper(totalCopper),
            "not enough copper"
        ))
    end
end

function ItemsPage:SelectItem(key)
    for index = 1, #self.filteredItems do
        if self.filteredItems[index].key == key then
            self.selectedItemKey = key
            self.quantity = 1
            self:UpdateRows()
            self:RefreshDetails()
            return true
        end
    end
    return false
end

function ItemsPage:SetMode(mode)
    if mode ~= MODE_BUY and mode ~= MODE_SELL or mode == self.mode then
        return
    end
    self.mode = mode
    self.page = 1
    self.categoryValue = "all"
    self.selectedItemKey = nil
    self.quantity = 1
    self.feedback = ""
    self:Refresh("mode")
end

function ItemsPage:SetCategory(value)
    if not findCategoryIndex(self.categories, value) then
        return false
    end
    self.categoryValue = value
    self.page = 1
    self.selectedItemKey = nil
    self.quantity = 1
    self:Refresh("filter")
    return true
end

function ItemsPage:SelectAdjacentCategory(offset)
    local index = findCategoryIndex(self.categories, self:GetCategoryValue()) or 1
    local nextIndex = math.max(1, math.min(#self.categories, index + (tonumber(offset) or 0)))
    if nextIndex ~= index then
        self:SetCategory(self.categories[nextIndex].value)
    end
end

function ItemsPage:PreviousPage()
    self.page = math.max(1, self.page - 1)
    self:UpdateRows()
end

function ItemsPage:NextPage()
    local pageCount = math.max(1, math.ceil(#self.filteredItems / ITEMS_PER_PAGE))
    self.page = math.min(pageCount, self.page + 1)
    self:UpdateRows()
end

function ItemsPage:Refresh(reason)
    if not self.built then
        return false
    end
    local previousCategory = self:GetCategoryValue()
    local previousPage = self.page
    if self.marketContext then
        if self.marketRef and self.market then
            self.marketContext:SetText(("Market: %s"):format(self.marketRef))
        else
            self.marketContext:SetText("")
        end
    end
    if not self.market or lower(self.market.marketType) ~= "exchange" then
        self.items = {}
        self.filteredItems = {}
        self.categories = { { value = "all", label = "All Items" } }
        self.categoryValue = "all"
        self.statusText = self.market and "Tracker markets do not support trading." or "Select an exchange Market to trade items."
        self.selectedItemKey = nil
        self:UpdateRows()
        self:RefreshDetails()
        return false
    end

    if self.mode == MODE_BUY then
        self.items = self:BuildBuyItems()
        self.statusText = #self.items == 0 and "No items are listed by this Market." or nil
    else
        local sellItems, errorCode = self:BuildSellItems()
        self.items = sellItems
        self.statusText = errorCode and formatReason(errorCode) or (#sellItems == 0 and "No eligible inventory variants match this Market." or nil)
    end
    self:BuildCategories()
    if findCategoryIndex(self.categories, previousCategory) then
        self.categoryValue = previousCategory
    end
    self:ApplyFilter()
    if reason == "market" or reason == "mode" or reason == "filter" then
        self.page = 1
    else
        self.page = previousPage
    end
    self:EnsureSelection()
    self:UpdateRows()
    self:RefreshDetails()
    return true
end

function ItemsPage:ExecuteTrade()
    if self.processing then
        return false
    end
    local row = self:GetSelectedItem()
    if not row or row.enabled == false or not self.marketRef then
        return false
    end
    self.processing = true
    self.feedback = "Processing trade..."
    self:UpdateRows()
    self:RefreshDetails()

    local callOk, success, reason, detail
    if row.mode == MODE_BUY then
        callOk, success, reason, detail = pcall(Trading.TryBuy, self.marketRef, row.itemRef, self.quantity)
    else
        callOk, success, reason, detail = pcall(Trading.TrySell, self.marketRef, row.variant, self.quantity)
    end
    self.processing = false

    if not callOk then
        reason = "transaction-failed"
        detail = { message = tostring(success) }
        success = false
        if Addon.Debug and Addon.Debug.Internal then
            Addon.Debug.Internal("Trading UI action failed: %s", tostring(detail.message))
        end
    end

    if success == true then
        local total = type(detail) == "table" and detail.quote and detail.quote.totalCopper or nil
        self.feedback = ("%s x%d for %s."):format(
            row.mode == MODE_BUY and "Bought" or "Sold",
            self.quantity,
            formatCopper(total)
        )
        self.quantity = 1
    else
        self.feedback = formatActionReason(reason, detail)
    end

    if self.owner and type(self.owner.Refresh) == "function" then
        self.owner:Refresh("trade")
    else
        self:Refresh("trade")
    end
    return success == true, reason, detail
end

function ItemsPage:Build(parent, owner)
    if self.built then
        return self.root
    end
    self.owner = owner
    self.root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPETradingItemsRoot", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.root, parent, 0, 0, 0, 0)

    self.heading = UI.CreateText(self.root:GetFrame(), "RPETradingItemsHeading", "Trading Items", {
        height = 18,
        expandWidth = true,
        justifyH = "LEFT",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Heading2) or 10,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.root:AddChild(self.heading)
    self.marketContext = UI.CreateText(self.root:GetFrame(), "RPETradingItemsMarketContext", "", {
        height = 14,
        expandWidth = true,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.root:AddChild(self.marketContext)

    self.modeNav = UI.CreateLayout(UI.HorizontalLayoutGroup, self.root:GetFrame(), "RPETradingItemsModes", {
        height = CONTROL_HEIGHT,
        expandWidth = true,
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.root:AddChild(self.modeNav)
    for _, mode in ipairs({ MODE_BUY, MODE_SELL }) do
        local label = mode == MODE_BUY and "Buy" or "Sell"
        local button = UI.CreateButton(self.modeNav:GetFrame(), "RPETradingItemsMode" .. label, label, 48, function()
            self:SetMode(mode)
        end, { height = CONTROL_HEIGHT, fontSize = 9 })
        self.modeButtons[mode] = button
        self.modeNav:AddChild(button)
    end

    self.filterNav = UI.CreateLayout(UI.HorizontalLayoutGroup, self.root:GetFrame(), "RPETradingItemsFilter", {
        height = CONTROL_HEIGHT,
        expandWidth = true,
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.root:AddChild(self.filterNav)
    self.previousFilterButton = UI.CreateButton(self.filterNav:GetFrame(), "RPETradingItemsPreviousFilter", "<", 22, function()
        self:SelectAdjacentCategory(-1)
    end, { height = CONTROL_HEIGHT, fontSize = 8 })
    self.filterNav:AddChild(self.previousFilterButton)
    self.filterDropdown = UI.CreateDropdown(self.filterNav:GetFrame(), "RPETradingItemsFilterDropdown", {
        width = 0,
        height = CONTROL_HEIGHT,
        expandWidth = true,
        weight = 1,
        items = { { value = "all", label = "All Items" } },
        selectedValue = "all",
        onValueChanged = function(value)
            if value and value ~= self:GetCategoryValue() then
                self:SetCategory(value)
            end
        end,
    })
    self.filterNav:AddChild(self.filterDropdown)
    self.nextFilterButton = UI.CreateButton(self.filterNav:GetFrame(), "RPETradingItemsNextFilter", ">", 22, function()
        self:SelectAdjacentCategory(1)
    end, { height = CONTROL_HEIGHT, fontSize = 8 })
    self.filterNav:AddChild(self.nextFilterButton)

    self.pageNav = UI.CreateLayout(UI.HorizontalLayoutGroup, self.root:GetFrame(), "RPETradingItemsPagination", {
        height = CONTROL_HEIGHT,
        expandWidth = true,
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.root:AddChild(self.pageNav)
    self.previousPageButton = UI.CreateButton(self.pageNav:GetFrame(), "RPETradingItemsPreviousPage", "<", PAGE_BUTTON_WIDTH, function()
        self:PreviousPage()
    end, { height = CONTROL_HEIGHT, fontSize = 8 })
    self.pageNav:AddChild(self.previousPageButton)
    self.pageText = UI.CreateText(self.pageNav:GetFrame(), "RPETradingItemsPageText", "Page 1 / 1", {
        width = PAGE_TEXT_WIDTH,
        height = CONTROL_HEIGHT,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.pageNav:AddChild(self.pageText)
    self.nextPageButton = UI.CreateButton(self.pageNav:GetFrame(), "RPETradingItemsNextPage", ">", PAGE_BUTTON_WIDTH, function()
        self:NextPage()
    end, { height = CONTROL_HEIGHT, fontSize = 8 })
    self.pageNav:AddChild(self.nextPageButton)

    self.listLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.root:GetFrame(), "RPETradingItemsList", {
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.root:AddChild(self.listLayout)
    for index = 1, ITEMS_PER_PAGE do
        local row
        row = UI.ShopEntry:New({
            name = "RPETradingItemRow" .. index,
            width = 0,
            height = ROW_HEIGHT,
            expandWidth = true,
            iconSize = 26,
            itemName = "",
            costText = "",
            fontSize = 8,
            costFontSize = 7,
            border = false,
        })
        row:SetParent(self.listLayout:GetFrame())
        row:Create()
        row:SetScript("OnClick", function()
            self:SelectItem(row._itemKey)
        end)
        self.rows[index] = row
        self.listLayout:AddChild(row)
    end
    self.emptyText = UI.CreateText(self.listLayout:GetFrame(), "RPETradingItemsEmpty", "", {
        height = 0,
        expandWidth = true,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.muted"),
    })
    self.listLayout:AddChild(self.emptyText)
    local listFrame = self.listLayout:GetFrame()
    if listFrame and listFrame.HookScript then
        listFrame:HookScript("OnSizeChanged", function()
            self:RefreshRowMetrics()
        end)
    end

    self.detailRoot = UI.CreateLayout(UI.VerticalLayoutGroup, self.root:GetFrame(), "RPETradingItemsDetail", {
        height = DETAIL_HEIGHT,
        expandWidth = true,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
        spacing = 2,
    })
    self.root:AddChild(self.detailRoot)
    self.detailName = UI.CreateText(self.detailRoot:GetFrame(), "RPETradingItemsDetailName", "Select an item to trade.", {
        height = 16,
        expandWidth = true,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.detailRoot:AddChild(self.detailName)
    self.balanceText = UI.CreateText(self.detailRoot:GetFrame(), "RPETradingItemsBalance", "RPE Copper: unavailable", {
        height = 14,
        expandWidth = true,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.detailRoot:AddChild(self.balanceText)
    self.quantityRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.detailRoot:GetFrame(), "RPETradingItemsQuantity", {
        height = 22,
        expandWidth = true,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.detailRoot:AddChild(self.quantityRow)
    self.quantityLabel = UI.CreateText(self.quantityRow:GetFrame(), "RPETradingItemsQuantityLabel", "Qty", {
        width = 24,
        height = 22,
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.quantityRow:AddChild(self.quantityLabel)
    self.quantityDown = UI.CreateButton(self.quantityRow:GetFrame(), "RPETradingItemsQuantityDown", "-", 22, function()
        self:SetQuantity(self.quantity - 1)
    end, { height = 22, fontSize = 9 })
    self.quantityRow:AddChild(self.quantityDown)
    self.quantityInput = UI.CreateTextInput(self.quantityRow:GetFrame(), "RPETradingItemsQuantityInput", {
        width = 38,
        height = 22,
        text = "1",
        fontSize = 9,
        justifyH = "CENTER",
    })
    self.quantityInput:SetScript("OnTextChanged", function(input)
        self:OnQuantityInputChanged(input)
    end)
    self.quantityRow:AddChild(self.quantityInput)
    self.quantityUp = UI.CreateButton(self.quantityRow:GetFrame(), "RPETradingItemsQuantityUp", "+", 22, function()
        self:SetQuantity(self.quantity + 1)
    end, { height = 22, fontSize = 9 })
    self.quantityRow:AddChild(self.quantityUp)
    self.quantityPreview = UI.CreateText(self.quantityRow:GetFrame(), "RPETradingItemsQuantityPreview", "", {
        width = 0,
        height = 22,
        expandWidth = true,
        weight = 1,
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.quantityRow:AddChild(self.quantityPreview)
    self.actionButton = UI.CreateButton(self.detailRoot:GetFrame(), "RPETradingItemsAction", "Buy", 0, function()
        self:ExecuteTrade()
    end, {
        height = 22,
        expandWidth = true,
        fontSize = 9,
        backgroundColor = UI.ResolveColor(nil, "tab.bar"),
    })
    self.detailRoot:AddChild(self.actionButton)
    self.feedbackText = UI.CreateText(self.detailRoot:GetFrame(), "RPETradingItemsFeedback", "", {
        height = 30,
        expandWidth = true,
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.muted"),
    })
    self.detailRoot:AddChild(self.feedbackText)

    self.built = true
    self:UpdateRows()
    self:RefreshDetails()
    return self.root
end

function ItemsPage:SetMarket(marketRef, market, reason)
    local changed = self.marketRef ~= marketRef
    self.marketRef = type(marketRef) == "string" and marketRef or nil
    self.market = market
    if changed then
        self.page = 1
        self.selectedItemKey = nil
        self.quantity = 1
        self.categoryValue = "all"
    end
    return self:Refresh(reason or (changed and "market" or "refresh"))
end

return ItemsPage
