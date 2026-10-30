local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}
local Trading = Client.Trading or {}
Client.Trading = Trading

local MAX_QUANTITY = 2147483647
local MAX_SAFE_INTEGER = 9007199254740991
local DEFAULT_TARIFF_PERCENT = 5

local function makeError(code, message, detail)
    local result = type(detail) == "table" and detail or {}
    result.code = code
    result.message = message
    return result
end

local function isFinite(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function ensureString(value)
    return value == nil and "" or tostring(value)
end

local function trim(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function lower(value)
    return string.lower(trim(value))
end

local function deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy
    for key, nested in pairs(value) do
        copy[deepCopy(key, seen)] = deepCopy(nested, seen)
    end
    return copy
end

local function normalizeQuantity(value)
    local quantity = tonumber(value)
    if not isFinite(quantity)
        or quantity <= 0
        or math.floor(quantity) ~= quantity
        or quantity > MAX_QUANTITY
    then
        return nil
    end

    return quantity
end

local function roundHalfUp(value)
    if not isFinite(value) then
        return nil
    end
    return math.floor(value + 0.5)
end

local function getInventory()
    return Addon.Client and Addon.Client.Inventory or {}
end

local function getItemClass()
    return Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.Item
        or nil
end

local function getMarketRates()
    return Addon.Client and Addon.Client.MarketRates or {}
end

local function resolveMarket(marketRef)
    if type(marketRef) ~= "string" or marketRef == "" then
        return nil, makeError("invalid-market-reference", "Market reference must be qualified as datasetId:marketId.")
    end
    if type(Registry.ResolveMarketReference) ~= "function" then
        return nil, makeError("registry-unavailable", "Market registry is unavailable.")
    end

    local ok, dataset, market, reason = pcall(Registry.ResolveMarketReference, Registry, marketRef)
    if not ok then
        return nil, makeError("registry-error", "Market registry failed while resolving the Market.")
    end
    if type(dataset) ~= "table" or type(market) ~= "table" then
        return nil, makeError(
            tostring(reason or "market-unavailable"),
            ("Market '%s' is unavailable."):format(marketRef),
            { marketRef = marketRef }
        )
    end

    local datasetId = trim(dataset.id)
    local marketId = trim(market.id)
    local canonicalRef = ("%s:%s"):format(datasetId, marketId)
    if datasetId == "" or marketId == "" or canonicalRef ~= marketRef then
        return nil, makeError("invalid-market-reference", "Market reference is not a qualified active Market.", { marketRef = marketRef })
    end

    local marketType = lower(market.marketType)
    if marketType ~= "exchange" then
        return nil, makeError("market-not-tradable", "Only exchange Markets support trading operations.", {
            marketRef = marketRef,
            marketType = marketType,
        })
    end

    return {
        marketRef = canonicalRef,
        dataset = dataset,
        market = market,
    }
end

local function resolveItem(itemRef)
    if type(itemRef) ~= "string" or itemRef == "" then
        return nil, nil, makeError("invalid-item-reference", "Item reference must be qualified as datasetId:itemId.")
    end
    if type(Registry.ResolveItemReference) ~= "function" then
        return nil, nil, makeError("registry-unavailable", "Item registry is unavailable.", { itemRef = itemRef })
    end

    local ok, dataset, item = pcall(Registry.ResolveItemReference, Registry, itemRef)
    if not ok then
        return nil, nil, makeError("registry-error", "Item registry failed while resolving the item.", { itemRef = itemRef })
    end
    if type(dataset) ~= "table" or type(item) ~= "table" then
        return nil, nil, makeError("item-unavailable", ("Item '%s' is unavailable."):format(itemRef), { itemRef = itemRef })
    end

    local canonicalRef = ("%s:%s"):format(trim(dataset.id), trim(item.id))
    if canonicalRef ~= itemRef then
        return nil, nil, makeError("invalid-item-reference", "Item reference is not qualified.", { itemRef = itemRef })
    end

    return dataset, item
end

local function getCurrentRate(marketRef)
    local rates = getMarketRates()
    if type(rates.GetHistory) ~= "function" then
        return nil, nil, makeError("market-rates-unavailable", "Market rate service is unavailable.", { marketRef = marketRef })
    end

    local ok, history, historyError = pcall(rates.GetHistory, marketRef)
    if not ok or type(history) ~= "table" or #history == 0 then
        if ok and type(historyError) == "table" then
            historyError.marketRef = historyError.marketRef or marketRef
            return nil, nil, historyError
        end
        return nil, nil, makeError("market-rates-unavailable", "The current Market coefficient is unavailable.", { marketRef = marketRef })
    end

    local current = history[#history]
    local coefficient = tonumber(current and current.coefficientPercent)
    local cycleKey = current and current.dayKey
    if not isFinite(coefficient) or type(cycleKey) ~= "string" or cycleKey == "" then
        return nil, nil, makeError("market-rates-unavailable", "The current Market coefficient is invalid.", { marketRef = marketRef })
    end

    return coefficient, cycleKey
end

local function getTariff(market)
    local tariff = market and market.tariffPercent
    if tariff == nil then
        tariff = DEFAULT_TARIFF_PERCENT
    else
        tariff = tonumber(tariff)
    end
    if not isFinite(tariff) or tariff < 0 or tariff >= 100 then
        return nil, makeError("invalid-market-definition", "Market tariff must be finite and between 0 and 100 percent.")
    end
    return tariff
end

local function getSellPrice(item, itemRef)
    local itemClass = getItemClass()
    if not itemClass or type(itemClass.ResolveSellPrice) ~= "function" then
        return nil, makeError("item-api-unavailable", "Item pricing is unavailable.", { itemRef = itemRef })
    end

    local ok, baseUnitCopper = pcall(itemClass.ResolveSellPrice, item)
    baseUnitCopper = ok and tonumber(baseUnitCopper) or nil
    if not ok or not isFinite(baseUnitCopper) or baseUnitCopper <= 0 then
        return nil, makeError("invalid-item-price", "Item has no positive tradable copper price.", { itemRef = itemRef })
    end
    return math.floor(baseUnitCopper)
end

local function listContains(values, expected, caseInsensitive)
    if type(values) ~= "table" then
        return false
    end
    for index = 1, #values do
        local value = caseInsensitive and lower(values[index]) or trim(values[index])
        if value == expected then
            return true
        end
    end
    return false
end

local function itemMatchesSellRules(market, itemRef, item)
    local rules = type(market and market.sellRules) == "table" and market.sellRules or {}
    local itemRefs = type(rules.itemRefs) == "table" and rules.itemRefs or {}
    local itemTypes = type(rules.itemTypes) == "table" and rules.itemTypes or {}
    if #itemRefs == 0 and #itemTypes == 0 then
        return false, "market-sell-policy-empty"
    end

    local matches = listContains(itemRefs, itemRef, false)
    if not matches then
        matches = listContains(itemTypes, lower(item.itemType), true)
    end
    if not matches then
        return false, "item-not-sellable-at-market"
    end

    local consumableTypes = type(rules.consumableTypes) == "table" and rules.consumableTypes or {}
    if lower(item.itemType) == "consumable" and #consumableTypes > 0
        and not listContains(consumableTypes, lower(item.consumableType), true)
    then
        return false, "consumable-type-not-allowed"
    end

    return true
end

local function isNativeInventoryRecord(record)
    return record.native == true
        or record.isNative == true
        or record.bag ~= nil
        or record.bagID ~= nil
        or record.containerID ~= nil
        or record.itemID ~= nil
        or record.itemLink ~= nil
        or record.link ~= nil
end

local function isSellEligible(item, variant, itemRef)
    if type(item) ~= "table" or type(variant) ~= "table" then
        return false, "item-unavailable"
    end
    if isNativeInventoryRecord(variant) then
        return false, "native-inventory-item"
    end
    if variant.equipped == true or variant.isEquipped == true then
        return false, "equipped-item"
    end
    if variant.soulbound == true then
        return false, "soulbound-item"
    end
    if item.canSell == false then
        return false, "item-cannot-sell"
    end
    if item.canTrade == false then
        return false, "item-cannot-trade"
    end
    if lower(item.itemType) == "quest" or item.questItem == true or item.isQuestItem == true then
        return false, "quest-item"
    end

    local itemClass = getItemClass()
    if itemClass and type(itemClass.IsBindOnPickup) == "function" and itemClass.IsBindOnPickup(item) then
        return false, "bound-item"
    end
    local bindingFlag = lower(item.bindingFlag)
    if bindingFlag == "soulbound" or bindingFlag == "bind_on_pickup" then
        return false, "bound-item"
    end

    local quantity = tonumber(variant.quantity)
    if not isFinite(quantity) or quantity <= 0 then
        return false, "insufficient-items"
    end

    return true
end

local function buildQuote(marketContext, itemRef, item, mode, quantity, coefficientPercent, cycleKey)
    local normalizedMode = lower(mode)
    if normalizedMode ~= "buy" and normalizedMode ~= "sell" then
        return nil, makeError("invalid-trade-mode", "Trade mode must be buy or sell.")
    end

    local normalizedQuantity = normalizeQuantity(quantity)
    if not normalizedQuantity then
        return nil, makeError("invalid-quantity", "Quantity must be a positive integer within the supported limit.")
    end

    if normalizedMode == "buy" then
        if not listContains(marketContext.market.buyItemRefs, itemRef, false) then
            return nil, makeError("item-not-for-sale", "The item is not in this Market's buy catalogue.", { itemRef = itemRef })
        end
    else
        local allowed, sellReason = itemMatchesSellRules(marketContext.market, itemRef, item)
        if not allowed then
            return nil, makeError(sellReason, "The item is not accepted by this Market's sell policy.", { itemRef = itemRef })
        end
    end

    local baseUnitCopper, priceError = getSellPrice(item, itemRef)
    if not baseUnitCopper then
        return nil, priceError
    end
    local tariffPercent, tariffError = getTariff(marketContext.market)
    if not tariffPercent then
        return nil, tariffError
    end

    local marketUnit = baseUnitCopper * (1 + coefficientPercent / 100)
    if not isFinite(marketUnit) or marketUnit <= 0 then
        return nil, makeError("invalid-price", "Market price is not positive and finite.", { itemRef = itemRef })
    end

    local multiplier = normalizedMode == "buy"
        and (1 + tariffPercent / 100)
        or (1 - tariffPercent / 100)
    local unitCopper = roundHalfUp(marketUnit * multiplier)
    if not unitCopper or unitCopper <= 0 then
        return nil, makeError("invalid-price", "Market price rounds to no tradable copper.", { itemRef = itemRef })
    end
    unitCopper = math.max(1, unitCopper)
    if normalizedQuantity > math.floor(MAX_SAFE_INTEGER / unitCopper) then
        return nil, makeError("quantity-overflow", "Trade total cannot be represented safely.", { itemRef = itemRef })
    end

    return {
        marketRef = marketContext.marketRef,
        itemRef = itemRef,
        mode = normalizedMode,
        quantity = normalizedQuantity,
        coefficientPercent = coefficientPercent,
        tariffPercent = tariffPercent,
        unitCopper = unitCopper,
        totalCopper = unitCopper * normalizedQuantity,
        cycleKey = cycleKey,
    }
end

local function variantSignature(variant)
    local modifications = type(variant and variant.modifications) == "table" and variant.modifications or {}
    local function serialize(value, seen)
        if type(value) ~= "table" then
            return type(value) .. ":" .. tostring(value)
        end
        seen = seen or {}
        if seen[value] then
            return "ref"
        end
        seen[value] = true
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys, function(left, right) return tostring(left) < tostring(right) end)
        local parts = {}
        for index = 1, #keys do
            local key = keys[index]
            parts[#parts + 1] = serialize(key, seen) .. "=" .. serialize(value[key], seen)
        end
        return "{" .. table.concat(parts, ";") .. "}"
    end
    return table.concat({
        lower(variant and variant.itemTier or "normal"),
        variant and variant.soulbound == true and "true" or "false",
        serialize(modifications),
    }, "|")
end

local function resolveCurrentVariant(itemRef, candidate)
    local inventory = getInventory()
    if type(inventory.GetItemVariants) ~= "function" then
        return nil, makeError("inventory-api-unavailable", "Inventory variants are unavailable.", { itemRef = itemRef })
    end

    local datasetId, itemId = itemRef:match("^([^:]+):(.+)$")
    if not datasetId or not itemId then
        return nil, makeError("invalid-item-reference", "Item reference must be qualified.", { itemRef = itemRef })
    end

    local ok, variants = pcall(inventory.GetItemVariants, datasetId, itemId)
    if not ok or type(variants) ~= "table" then
        return nil, makeError("inventory-api-unavailable", "Inventory variants could not be read.", { itemRef = itemRef })
    end

    local wantedStackKey = candidate and candidate.stackKey
    local wantedSignature = variantSignature(candidate)
    for index = 1, #variants do
        local variant = variants[index]
        if wantedStackKey ~= nil and tostring(variant.stackKey or "") == tostring(wantedStackKey) then
            return variant
        end
        if wantedStackKey == nil and variantSignature(variant) == wantedSignature then
            return variant
        end
    end

    return nil, makeError("inventory-variant-unavailable", "The selected inventory variant is no longer available.", { itemRef = itemRef })
end

local function normalizeVariantInput(inventoryVariant)
    if type(inventoryVariant) ~= "table" then
        return nil, nil, makeError("invalid-inventory-variant", "A concrete inventory variant is required.")
    end

    local source = type(inventoryVariant.variant) == "table" and inventoryVariant.variant or inventoryVariant
    local itemRef = trim(inventoryVariant.itemRef or source.itemRef)
    if itemRef == "" and source.dataset ~= nil and source.id ~= nil then
        itemRef = ("%s:%s"):format(trim(source.dataset), trim(source.id))
    end
    if itemRef == "" then
        return nil, nil, makeError("invalid-inventory-variant", "The inventory variant has no qualified item reference.")
    end
    return itemRef, source
end

local function getVariantQuantity(inventory, variant)
    if type(inventory.GetVariantQuantity) ~= "function" then
        return nil
    end
    local ok, quantity = pcall(inventory.GetVariantQuantity, variant)
    quantity = ok and tonumber(quantity) or nil
    if not ok or not isFinite(quantity) or quantity < 0 or math.floor(quantity) ~= quantity then
        return nil
    end
    return quantity
end

local function readCurrency()
    if type(Profile.GetCurrencyAmount) ~= "function" then
        return nil, makeError("currency-api-unavailable", "Currency storage is unavailable.")
    end
    local ok, amount = pcall(Profile.GetCurrencyAmount, "copper")
    amount = ok and tonumber(amount) or nil
    if not ok or not isFinite(amount) or amount < 0 or math.floor(amount) ~= amount then
        return nil, makeError("currency-api-unavailable", "Current copper balance is invalid.")
    end
    return amount
end

local function getCurrencyCap()
    if type(Profile.ResolveCurrencyDefinition) ~= "function" then
        return nil, makeError("currency-api-unavailable", "Currency definition storage is unavailable.")
    end
    local ok, definition = pcall(Profile.ResolveCurrencyDefinition, "copper")
    local maximum = ok and type(definition) == "table" and tonumber(definition.max) or nil
    if not ok or not isFinite(maximum) or maximum < 0 or math.floor(maximum) ~= maximum then
        return nil, makeError("currency-api-unavailable", "Copper currency cap is unavailable.")
    end
    return maximum
end

local function restoreCurrency(amount)
    if type(Profile.SetCurrencyAmount) ~= "function" then
        return false
    end
    local ok = pcall(Profile.SetCurrencyAmount, "copper", amount)
    if not ok then
        return false
    end
    local current = readCurrency()
    return current == amount
end

local function addInventoryQuantity(variant, quantity, source)
    local inventory = getInventory()
    if type(inventory.AddItem) ~= "function" then
        return false
    end
    local record = {
        dataset = variant.dataset,
        id = variant.id,
        itemTier = variant.itemTier or "normal",
        modifications = deepCopy(variant.modifications or {}),
        soulbound = variant.soulbound == true,
        quantity = quantity,
    }
    local ok, added = pcall(inventory.AddItem, record, {
        source = source,
        suppressLootNotification = true,
    })
    return ok and type(added) == "table"
end

local function removeInventoryQuantity(variant, quantity)
    local inventory = getInventory()
    if type(inventory.RemoveVariantQuantity) ~= "function" then
        return false
    end
    local ok, removed = pcall(inventory.RemoveVariantQuantity, variant, quantity)
    return ok and removed == true
end

local function throwFailure(reason, detail)
    error({ __tradingFailure = true, reason = reason, detail = detail }, 0)
end

local function runOperation(reason, callback)
    local current = type(Runtime.GetCurrentTransaction) == "function" and Runtime:GetCurrentTransaction() or nil
    local ok, first, second, third
    if current then
        ok, first, second, third = pcall(callback)
    elseif type(Runtime.RunTransaction) == "function" then
        ok, first, second, third = pcall(Runtime.RunTransaction, Runtime, reason, callback)
    else
        ok, first, second, third = pcall(callback)
    end

    if not ok then
        if type(first) == "table" and first.__tradingFailure == true then
            return false, first.reason, first.detail
        end
        return false, "transaction-failed", { error = tostring(first) }
    end
    return first, second, third
end

local function buildQuoteForRequest(marketRef, itemRef, mode, quantity, variant)
    local marketContext, marketError = resolveMarket(marketRef)
    if not marketContext then return nil, marketError end

    local dataset, item, itemError = resolveItem(itemRef)
    if not dataset then return nil, itemError end

    local coefficientPercent, cycleKey, rateError = getCurrentRate(marketContext.marketRef)
    if coefficientPercent == nil then return nil, rateError end

    local currentVariant = nil
    if lower(mode) == "sell" then
        local _, candidate, variantError = normalizeVariantInput(variant)
        if not candidate then return nil, variantError end
        if isNativeInventoryRecord(candidate) or candidate.equipped == true or candidate.isEquipped == true then
            return nil, makeError("invalid-inventory-variant", "Only canonical RPE inventory variants can be sold.")
        end
        if candidate.dataset ~= nil and candidate.id ~= nil then
            local candidateRef = ("%s:%s"):format(trim(candidate.dataset), trim(candidate.id))
            if candidateRef ~= itemRef then
                return nil, makeError("invalid-inventory-variant", "The inventory variant does not match the requested item.", { itemRef = itemRef })
            end
        end
        currentVariant, variantError = resolveCurrentVariant(itemRef, candidate)
        if not currentVariant then return nil, variantError end
        local eligible, eligibilityReason = isSellEligible(item, currentVariant, itemRef)
        if not eligible then
            return nil, makeError(eligibilityReason, "The selected inventory variant cannot be sold.", { itemRef = itemRef })
        end
    end

    local quote, quoteError = buildQuote(
        marketContext,
        itemRef,
        item,
        mode,
        quantity,
        coefficientPercent,
        cycleKey
    )
    if not quote then return nil, quoteError end
    quote.datasetId = trim(dataset.id)
    quote.itemId = trim(item.id)
    quote.item = item
    if currentVariant then
        quote.variant = deepCopy(currentVariant)
        quote.stackKey = currentVariant.stackKey
        quote.stackIdentity = currentVariant.stackKey
        if quote.quantity > (tonumber(currentVariant.quantity) or 0) then
            return nil, makeError("insufficient-items", "The selected inventory variant does not contain enough items.", { itemRef = itemRef })
        end
    end
    return quote
end

function Trading.GetMarketOffers(marketRef)
    local marketContext, marketError = resolveMarket(marketRef)
    if not marketContext then return nil, marketError end

    local coefficientPercent, cycleKey, rateError = getCurrentRate(marketContext.marketRef)
    if coefficientPercent == nil then return nil, rateError end

    local offers = {}
    local seen = {}
    for index = 1, #(marketContext.market.buyItemRefs or {}) do
        local itemRef = trim(marketContext.market.buyItemRefs[index])
        if itemRef ~= "" and not seen[itemRef] then
            seen[itemRef] = true
            local dataset, item, itemError = resolveItem(itemRef)
            if not dataset and itemError
                and (itemError.code == "registry-unavailable" or itemError.code == "registry-error")
            then
                return nil, itemError
            end
            if dataset and item then
                local quote, quoteError = buildQuote(
                    marketContext,
                    itemRef,
                    item,
                    "buy",
                    1,
                    coefficientPercent,
                    cycleKey
                )
                if quote then
                    quote.datasetId = trim(dataset.id)
                    quote.itemId = trim(item.id)
                    quote.item = item
                    offers[#offers + 1] = {
                        marketRef = marketContext.marketRef,
                        ref = itemRef,
                        itemRef = itemRef,
                        datasetId = quote.datasetId,
                        itemId = quote.itemId,
                        item = item,
                        quote = quote,
                        unitCopper = quote.unitCopper,
                        coefficientPercent = coefficientPercent,
                        tariffPercent = quote.tariffPercent,
                        cycleKey = cycleKey,
                    }
                elseif quoteError and quoteError.code ~= "invalid-item-price" then
                    return nil, quoteError
                end
            end
        end
    end
    return offers
end

function Trading.GetEligibleInventory(marketRef)
    local marketContext, marketError = resolveMarket(marketRef)
    if not marketContext then return nil, marketError end

    local coefficientPercent, cycleKey, rateError = getCurrentRate(marketContext.marketRef)
    if coefficientPercent == nil then return nil, rateError end

    local inventory = getInventory()
    if type(inventory.GetItems) ~= "function" or type(inventory.GetItemVariants) ~= "function" then
        return nil, makeError("inventory-api-unavailable", "Inventory variants are unavailable.")
    end
    local ok, items = pcall(inventory.GetItems)
    if not ok or type(items) ~= "table" then
        return nil, makeError("inventory-api-unavailable", "Inventory could not be read.")
    end

    local refs, seen = {}, {}
    for index = 1, #items do
        local record = items[index]
        local itemRef = record and record.dataset and record.id
            and ("%s:%s"):format(trim(record.dataset), trim(record.id))
            or ""
        if itemRef ~= "" and not seen[itemRef] then
            seen[itemRef] = true
            refs[#refs + 1] = itemRef
        end
    end

    local result = {}
    for index = 1, #refs do
        local itemRef = refs[index]
        local dataset, item, itemError = resolveItem(itemRef)
        if not dataset then
            if itemError and (itemError.code == "registry-unavailable" or itemError.code == "registry-error") then
                return nil, itemError
            end
        else
            local allowedByRules = itemMatchesSellRules(marketContext.market, itemRef, item)
            if allowedByRules then
                local variantOk, variants = pcall(inventory.GetItemVariants, dataset.id, item.id)
                if not variantOk or type(variants) ~= "table" then
                    return nil, makeError("inventory-api-unavailable", "Inventory variants could not be read.", {
                        itemRef = itemRef,
                    })
                end
                if variantOk and type(variants) == "table" then
                    for variantIndex = 1, #variants do
                        local variant = variants[variantIndex]
                        local eligible = isSellEligible(item, variant, itemRef)
                        if eligible then
                            local quote, quoteError = buildQuote(
                                marketContext,
                                itemRef,
                                item,
                                "sell",
                                variant.quantity,
                                coefficientPercent,
                                cycleKey
                            )
                            if quote then
                                quote.datasetId = trim(dataset.id)
                                quote.itemId = trim(item.id)
                                quote.item = item
                                quote.variant = deepCopy(variant)
                                quote.stackKey = variant.stackKey
                                result[#result + 1] = {
                                    marketRef = marketContext.marketRef,
                                    ref = itemRef,
                                    itemRef = itemRef,
                                    datasetId = quote.datasetId,
                                    itemId = quote.itemId,
                                    item = item,
                                    itemTier = variant.itemTier,
                                    tier = variant.itemTier,
                                    quantity = variant.quantity,
                                    stackKey = variant.stackKey,
                                    stackIdentity = variant.stackKey,
                                    variant = deepCopy(variant),
                                    quote = quote,
                                    unitCopper = quote.unitCopper,
                                    totalCopper = quote.totalCopper,
                                    coefficientPercent = coefficientPercent,
                                    tariffPercent = quote.tariffPercent,
                                    cycleKey = cycleKey,
                                }
                            elseif quoteError and quoteError.code == "invalid-item-price" then
                                -- An unpriced item is not an eligible trading row.
                            elseif quoteError then
                                return nil, quoteError
                            end
                        end
                    end
                end
            end
        end
    end
    return result
end

function Trading.Quote(marketRef, itemRef, mode, quantity, variant)
    return buildQuoteForRequest(marketRef, itemRef, mode, quantity, variant)
end

local function buyRecord(quote)
    return {
        dataset = quote.datasetId,
        id = quote.itemId,
        itemTier = "normal",
        modifications = {},
        soulbound = false,
        quantity = quote.quantity,
    }
end

local function rollbackBuy(balanceBefore, itemRecord, itemQuantityBefore, itemQuantityAfter)
    local restored = true
    if itemQuantityAfter == nil then
        restored = false
    else
        local added = math.max(0, itemQuantityAfter - itemQuantityBefore)
        if added > 0 then
            if not removeInventoryQuantity(itemRecord, added) then
                restored = false
            else
                local current = getVariantQuantity(getInventory(), itemRecord)
                if current ~= itemQuantityBefore then restored = false end
            end
        elseif itemQuantityAfter ~= itemQuantityBefore then
            restored = false
        end
    end
    if not restoreCurrency(balanceBefore) then
        restored = false
    end
    return restored
end

local function rollbackSell(variant, removedQuantity, balanceBefore)
    local restored = true
    if not restoreCurrency(balanceBefore) then
        restored = false
    end
    if removedQuantity > 0 then
        if not addInventoryQuantity(variant, removedQuantity, "market-rollback") then
            restored = false
        else
            local current = getVariantQuantity(getInventory(), variant)
            if current == nil or current ~= (tonumber(variant.quantity) or 0) then
                restored = false
            end
        end
    end
    return restored
end

function Trading.TryBuy(marketRef, itemRef, quantity)
    return runOperation("market-buy", function()
        local quote, quoteError = buildQuoteForRequest(marketRef, itemRef, "buy", quantity)
        if not quote then return false, quoteError.code, quoteError end

        local balanceBefore, balanceError = readCurrency()
        if balanceBefore == nil then return false, balanceError.code, balanceError end
        if balanceBefore < quote.totalCopper then
            return false, "insufficient-currency", {
                quote = quote,
                balance = balanceBefore,
                required = quote.totalCopper,
            }
        end

        local inventory = getInventory()
        if type(inventory.GetVariantQuantity) ~= "function" or type(Profile.SpendCurrencyAmount) ~= "function" then
            return false, "trade-api-unavailable", quote
        end
        local itemRecord = buyRecord(quote)
        local itemQuantityBefore = getVariantQuantity(inventory, itemRecord)
        if itemQuantityBefore == nil then
            return false, "inventory-api-unavailable", quote
        end

        local spendOk, spent, updated = pcall(Profile.SpendCurrencyAmount, "copper", quote.totalCopper)
        local balanceAfterSpend = readCurrency()
        local expectedBalance = balanceBefore - quote.totalCopper
        if not spendOk or spent ~= true or tonumber(updated) ~= expectedBalance or balanceAfterSpend ~= expectedBalance then
            local restored = restoreCurrency(balanceBefore)
            if not restored then throwFailure("rollback-failed", { quote = quote, stage = "currency-spend" }) end
            return false, "currency-transaction-failed", { quote = quote, balance = balanceBefore }
        end

        local addOk, added = pcall(inventory.AddItem, itemRecord, {
            source = "market-buy",
            suppressLootNotification = true,
        })
        local itemQuantityAfter = getVariantQuantity(inventory, itemRecord)
        local actualAdded = itemQuantityAfter and itemQuantityAfter - itemQuantityBefore or nil
        if not addOk or type(added) ~= "table" or actualAdded ~= quote.quantity then
            local restored = rollbackBuy(balanceBefore, itemRecord, itemQuantityBefore, itemQuantityAfter)
            if not restored then throwFailure("rollback-failed", { quote = quote, stage = "item-grant" }) end
            return false, "item-grant-failed", { quote = quote, actualQuantity = actualAdded or 0 }
        end

        return true, "ok", {
            operation = "buy",
            quote = quote,
            quantity = quote.quantity,
            balanceBefore = balanceBefore,
            balanceAfter = expectedBalance,
            itemRef = quote.itemRef,
            itemTier = "normal",
        }
    end)
end

function Trading.TrySell(marketRef, inventoryVariant, quantity)
    local itemRef, candidate, inputError = normalizeVariantInput(inventoryVariant)
    if not itemRef then return false, inputError.code, inputError end

    return runOperation("market-sell", function()
        local quote, quoteError = buildQuoteForRequest(marketRef, itemRef, "sell", quantity, candidate)
        if not quote then return false, quoteError.code, quoteError end

        local inventory = getInventory()
        if type(inventory.RemoveVariantQuantity) ~= "function" or type(Profile.AddCurrencyAmount) ~= "function" then
            return false, "trade-api-unavailable", quote
        end
        local variant = quote.variant
        local quantityBefore = getVariantQuantity(inventory, variant)
        if quantityBefore == nil or quantityBefore < quote.quantity then
            return false, "insufficient-items", { quote = quote }
        end
        local balanceBefore, balanceError = readCurrency()
        if balanceBefore == nil then return false, balanceError.code, balanceError end
        local currencyCap, capError = getCurrencyCap()
        if currencyCap == nil then return false, capError.code, capError end
        if quote.totalCopper > currencyCap - balanceBefore then
            return false, "currency-cap-reached", {
                quote = quote,
                balance = balanceBefore,
                currencyCap = currencyCap,
            }
        end

        local removeOk, removed = pcall(inventory.RemoveVariantQuantity, variant, quote.quantity)
        local quantityAfterRemove = getVariantQuantity(inventory, variant)
        local actualRemoved = quantityAfterRemove and quantityBefore - quantityAfterRemove or nil
        if not removeOk or removed ~= true or actualRemoved ~= quote.quantity then
            local restored = actualRemoved and actualRemoved > 0
                and addInventoryQuantity(variant, actualRemoved, "market-rollback")
                or actualRemoved == 0
            if restored then
                local restoredQuantity = getVariantQuantity(inventory, variant)
                restored = restoredQuantity == quantityBefore
            end
            if not restored then throwFailure("rollback-failed", { quote = quote, stage = "item-removal" }) end
            return false, "item-removal-failed", { quote = quote, actualQuantity = actualRemoved or 0 }
        end

        local addOk, added = pcall(Profile.AddCurrencyAmount, "copper", quote.totalCopper)
        local balanceAfter = readCurrency()
        local expectedBalance = balanceBefore + quote.totalCopper
        if not addOk or added == nil or balanceAfter ~= expectedBalance then
            local restored = rollbackSell(variant, quote.quantity, balanceBefore)
            if not restored then throwFailure("rollback-failed", { quote = quote, stage = "currency-credit" }) end
            return false, "currency-credit-failed", { quote = quote, balance = balanceAfter }
        end

        return true, "ok", {
            operation = "sell",
            quote = quote,
            quantity = quote.quantity,
            balanceBefore = balanceBefore,
            balanceAfter = expectedBalance,
            itemRef = quote.itemRef,
            itemTier = variant.itemTier,
            stackKey = variant.stackKey,
        }
    end)
end

