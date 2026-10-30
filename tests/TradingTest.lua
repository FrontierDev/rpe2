local Support = dofile("tests/support/RuntimeStubs.lua")

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then
        error(message, 2)
    end
end

local function clone(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, nested in pairs(value) do
        copy[clone(key, seen)] = clone(nested, seen)
    end
    return copy
end

local function variantKey(record)
    return table.concat({
        tostring(record.dataset),
        tostring(record.id),
        tostring(record.itemTier or "normal"),
        record.soulbound == true and "true" or "false",
        record.equipped == true and "equipped" or "bag",
    }, "|")
end

local items = {
    ["items:potion"] = {
        id = "potion", itemType = "consumable", consumableType = "potion",
        canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:elixir"] = {
        id = "elixir", itemType = "consumable", consumableType = "elixir",
        canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:food"] = {
        id = "food", itemType = "consumable", consumableType = "food",
        canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:sword"] = {
        id = "sword", itemType = "weapon", canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:quest"] = {
        id = "quest", itemType = "quest", canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:bound"] = {
        id = "bound", itemType = "weapon", canSell = true, canTrade = true,
        bindingFlag = "bind_on_pickup", sellPrice = 100,
    },
    ["items:no-sell"] = {
        id = "no-sell", itemType = "weapon", canSell = false, canTrade = true, sellPrice = 100,
    },
    ["items:no-trade"] = {
        id = "no-trade", itemType = "weapon", canSell = true, canTrade = false, sellPrice = 100,
    },
}

local market = {
    id = "exchange",
    marketType = "exchange",
    baseCoefficientPercent = 10,
    tariffPercent = 5,
    buyItemRefs = { "items:potion" },
    sellRules = {
        itemTypes = { "weapon", "consumable" },
        consumableTypes = { "potion", "elixir", "flask" },
    },
}

local tracker = { id = "tracker", marketType = "tracker" }
local inventoryRecords = {
    { dataset = "items", id = "sword", itemTier = "normal", soulbound = false, quantity = 2, modifications = {} },
    { dataset = "items", id = "sword", itemTier = "heroic", soulbound = false, quantity = 3, modifications = {} },
    { dataset = "items", id = "potion", itemTier = "normal", soulbound = false, quantity = 4, modifications = {} },
    { dataset = "items", id = "elixir", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "food", itemTier = "normal", soulbound = false, quantity = 5, modifications = {} },
    { dataset = "items", id = "quest", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "bound", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "no-sell", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "no-trade", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "sword", itemTier = "normal", soulbound = true, quantity = 1, modifications = {} },
    { dataset = "items", id = "sword", itemTier = "normal", soulbound = false, quantity = 1, modifications = {}, equipped = true },
}

local currency = 1000
local coefficient = 10
local failAddAfterMutation = false
local failCurrencyCredit = false
local addCount = 0

local function findVariant(record)
    local wanted = variantKey(record)
    for index = 1, #inventoryRecords do
        local current = inventoryRecords[index]
        if variantKey(current) == wanted then
            return current
        end
    end
end

local addon = Support.CreateAddon()
addon.Internal.Database = { Classes = {} }
addon.Internal.Database.Classes.Item = {
    ResolveSellPrice = function(item) return item.sellPrice end,
    IsBindOnPickup = function(item) return item.bindingFlag == "bind_on_pickup" end,
}
addon.Internal.Registry = {
    ResolveMarketReference = function(_, ref)
        if ref == "markets:exchange" then return { id = "markets" }, market end
        if ref == "markets:tracker" then return { id = "markets" }, tracker end
        return nil, nil, "missing-market"
    end,
    ResolveItemReference = function(_, ref)
        local item = items[ref]
        if not item then return nil, nil end
        return { id = "items" }, item
    end,
}
addon.Client.MarketRates = {
    GetHistory = function()
        return { { dayKey = "2026-10-30", coefficientPercent = coefficient } }
    end,
}
addon.Internal.Profile = {
    GetCurrencyAmount = function() return currency end,
    ResolveCurrencyDefinition = function() return { max = 2147483647 } end,
    SetCurrencyAmount = function(amount)
        currency = math.min(2147483647, math.max(0, math.floor(amount)))
        return currency
    end,
    SpendCurrencyAmount = function(amount)
        if currency < amount then return false, currency end
        currency = currency - amount
        return true, currency
    end,
    AddCurrencyAmount = function(amount)
        if failCurrencyCredit then return nil end
        local previous = currency
        currency = math.min(2147483647, currency + amount)
        return currency, currency - previous
    end,
}
addon.Internal.Runtime = {
    GetCurrentTransaction = function() return nil end,
    RunTransaction = function(_, _, callback) return callback() end,
}
addon.Client.Inventory = {
    GetItems = function() return inventoryRecords end,
    GetItemVariants = function(datasetId, itemId)
        local result = {}
        for index = 1, #inventoryRecords do
            local record = inventoryRecords[index]
            if record.dataset == datasetId and record.id == itemId then
                local variant = clone(record)
                variant.stackKey = variantKey(record)
                result[#result + 1] = variant
            end
        end
        return result
    end,
    GetVariantQuantity = function(record)
        local variant = findVariant(record)
        return variant and variant.quantity or 0
    end,
    AddItem = function(record)
        addCount = addCount + 1
        local variant = findVariant(record)
        if not variant then
            variant = clone(record)
            inventoryRecords[#inventoryRecords + 1] = variant
        else
            variant.quantity = variant.quantity + record.quantity
        end
        if failAddAfterMutation then return nil end
        return clone(record), #inventoryRecords
    end,
    RemoveVariantQuantity = function(record, quantity)
        local variant = findVariant(record)
        if not variant or variant.quantity < quantity then return false end
        variant.quantity = variant.quantity - quantity
        return true
    end,
}

Support.LoadAddonFile("client/client_Trading.lua", addon)
local Trading = addon.Client.Trading

local offers = assert(Trading.GetMarketOffers("markets:exchange"))
assertEqual(#offers, 1, "buy catalogue only exposes authored items")
assertEqual(offers[1].unitCopper, 116, "buy price uses per-unit half-up tariff rounding")

local sellQuote = assert(Trading.Quote("markets:exchange", "items:potion", "sell", 1, {
    dataset = "items", id = "potion", itemTier = "normal", soulbound = false, quantity = 4,
    stackKey = "items|potion|normal|false|bag",
}))
assertEqual(sellQuote.unitCopper, 105, "sell price uses per-unit half-up tariff rounding")

local eligible = assert(Trading.GetEligibleInventory("markets:exchange"))
local eligibleKeys = {}
for index = 1, #eligible do eligibleKeys[eligible[index].itemRef .. ":" .. eligible[index].itemTier] = true end
assertTrue(eligibleKeys["items:sword:normal"], "weapon type is accepted")
assertTrue(eligibleKeys["items:sword:heroic"], "each item tier remains a separate variant")
assertTrue(eligibleKeys["items:potion:normal"], "allowed potion category is accepted")
assertTrue(eligibleKeys["items:elixir:normal"], "allowed elixir category is accepted")
assertTrue(not eligibleKeys["items:food:normal"], "unlisted consumable category is rejected")
assertTrue(not eligibleKeys["items:quest:normal"], "quest items are rejected")
assertTrue(not eligibleKeys["items:bound:normal"], "bound items are rejected")
assertTrue(not eligibleKeys["items:no-sell:normal"], "non-sellable items are rejected")
assertTrue(not eligibleKeys["items:no-trade:normal"], "non-tradable items are rejected")

local bought, buyReason, buyDetail = Trading.TryBuy("markets:exchange", "items:potion", 2)
assertTrue(bought, "buy succeeds")
assertEqual(buyReason, "ok", "buy success reason")
assertEqual(buyDetail.balanceAfter, 768, "buy deducts total copper once")
assertEqual(findVariant({ dataset = "items", id = "potion", itemTier = "normal", soulbound = false }).quantity, 6, "buy adds requested quantity once")
assertEqual(addCount, 1, "successful buy performs one item grant")

local notListed, notListedReason = Trading.TryBuy("markets:exchange", "items:sword", 1)
assertTrue(not notListed, "unlisted item cannot be bought")
assertEqual(notListedReason, "item-not-for-sale", "unlisted buy reason")

local sold, sellReason, sellDetail = Trading.TrySell("markets:exchange", eligible[1], 1)
assertTrue(sold, "partial variant sale succeeds")
assertEqual(sellReason, "ok", "sell success reason")
assertEqual(sellDetail.balanceAfter, 873, "sell credits total copper once")

local heroicVariant
for index = 1, #eligible do
    if eligible[index].itemTier == "heroic" then heroicVariant = eligible[index] end
end
assertTrue(heroicVariant ~= nil, "heroic variant is available")
local heroicOk, heroicReason, heroicDetail = Trading.TrySell("markets:exchange", heroicVariant, 2)
assertTrue(heroicOk, "heroic sale succeeds")
assertEqual(heroicReason, "ok", "heroic sale success reason")
assertEqual(heroicDetail.quantity, 2, "sale uses the selected tier variant")
assertEqual(findVariant({ dataset = "items", id = "sword", itemTier = "heroic", soulbound = false }).quantity, 1, "sale does not merge tiers")

currency = 100
local insufficient, insufficientReason = Trading.TryBuy("markets:exchange", "items:potion", 1)
assertTrue(not insufficient, "insufficient funds fail")
assertEqual(insufficientReason, "insufficient-currency", "insufficient funds reason")
currency = 1000

local trackerTrade, trackerReason = Trading.GetMarketOffers("markets:tracker")
assertEqual(trackerTrade, nil, "tracker offers are unavailable")
assertEqual(trackerReason.code, "market-not-tradable", "tracker trade reason")

coefficient = 20
local currentQuote = assert(Trading.Quote("markets:exchange", "items:potion", "buy", 1))
assertEqual(currentQuote.unitCopper, 126, "click-time quote uses current coefficient")
currency = 125
local staleBuy, staleBuyReason = Trading.TryBuy("markets:exchange", "items:potion", 1)
assertTrue(not staleBuy, "stale quote cannot authorize a cheaper buy")
assertEqual(staleBuyReason, "insufficient-currency", "stale quote is rechecked at click time")

currency = 2147483640
local capped, cappedReason = Trading.TrySell("markets:exchange", eligible[1], 1)
assertTrue(not capped, "currency cap blocks sale before mutation")
assertEqual(cappedReason, "currency-cap-reached", "currency cap reason")
assertEqual(findVariant({ dataset = "items", id = "sword", itemTier = eligible[1].itemTier, soulbound = false }).quantity, 1, "cap failure preserves inventory")
currency = 1000

failAddAfterMutation = true
local failedBuy, failedBuyReason = Trading.TryBuy("markets:exchange", "items:potion", 1)
assertTrue(not failedBuy, "failed grant returns failure")
assertEqual(failedBuyReason, "item-grant-failed", "failed grant reason")
assertEqual(currency, 1000, "failed grant restores currency")
assertEqual(findVariant({ dataset = "items", id = "potion", itemTier = "normal", soulbound = false }).quantity, 6, "failed grant restores inventory")
failAddAfterMutation = false

failCurrencyCredit = true
local failedSell, failedSellReason = Trading.TrySell("markets:exchange", eligible[1], 1)
assertTrue(not failedSell, "failed credit returns failure")
assertEqual(failedSellReason, "currency-credit-failed", "failed credit reason")
assertEqual(currency, 1000, "failed credit preserves currency")
assertEqual(findVariant({ dataset = "items", id = "sword", itemTier = eligible[1].itemTier, soulbound = false }).quantity, 1, "failed credit restores inventory")

print("TradingTest passed")
