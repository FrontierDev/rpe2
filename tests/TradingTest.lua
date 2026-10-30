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
    local parts = {
        tostring(record.dataset),
        tostring(record.id),
        tostring(record.itemTier or "normal"),
        record.soulbound == true and "true" or "false",
        record.equipped == true and "equipped" or "bag",
    }
    if record.variantKey then
        parts[#parts + 1] = tostring(record.variantKey)
    end
    return table.concat(parts, "|")
end

local items = {
    ["items:potion"] = {
        id = "potion", itemType = "consumable", consumableType = "potion",
        canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:elixir"] = {
        id = "elixir", itemType = "consumable", consumableType = "elixir", consumableElixirType = "battle",
        canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:guardian-elixir"] = {
        id = "guardian-elixir", itemType = "consumable", consumableType = "elixir", consumableElixirType = "guardian",
        canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:food"] = {
        id = "food", itemType = "consumable", consumableType = "food",
        canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:sword"] = {
        id = "sword", itemType = "weapon", weaponTypeRef = "definitions:sword", validSlotRefs = { "definitions:main-hand" }, canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:axe"] = {
        id = "axe", itemType = "weapon", weaponTypeRef = "definitions:axe", validSlotRefs = { "definitions:main-hand" }, canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:offhand-sword"] = {
        id = "offhand-sword", itemType = "weapon", weaponTypeRef = "definitions:sword", validSlotRefs = { "definitions:off-hand" }, canSell = true, canTrade = true, sellPrice = 100,
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
    ["items:linen"] = {
        id = "linen", itemType = "material", canSell = true, canTrade = true, sellPrice = 25,
    },
    ["items:wool"] = {
        id = "wool", itemType = "material", canSell = true, canTrade = true, sellPrice = 50,
    },
    ["items:armor"] = {
        id = "armor", itemType = "armor", armorWeight = "cloth", validSlotRefs = { "definitions:head" }, canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:plate-armor"] = {
        id = "plate-armor", itemType = "armor", armorWeight = "plate", validSlotRefs = { "definitions:head" }, canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:leg-armor"] = {
        id = "leg-armor", itemType = "armor", armorWeight = "cloth", validSlotRefs = { "definitions:legs" }, canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:modification-match"] = {
        id = "modification-match", itemType = "modification", modificationKind = "enchant", targetSlotRefs = { "definitions:head" }, targetWeaponTypeRef = "definitions:sword", targetArmorWeight = "cloth", canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:modification-slot-miss"] = {
        id = "modification-slot-miss", itemType = "modification", modificationKind = "enchant", targetSlotRefs = { "definitions:legs" }, targetWeaponTypeRef = "definitions:sword", targetArmorWeight = "cloth", canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:modification-weapon-miss"] = {
        id = "modification-weapon-miss", itemType = "modification", modificationKind = "enchant", targetSlotRefs = { "definitions:head" }, targetWeaponTypeRef = "definitions:axe", targetArmorWeight = "cloth", canSell = true, canTrade = true, sellPrice = 100,
    },
    ["items:modification-armor-miss"] = {
        id = "modification-armor-miss", itemType = "modification", modificationKind = "enchant", targetSlotRefs = { "definitions:head" }, targetWeaponTypeRef = "definitions:sword", targetArmorWeight = "plate", canSell = true, canTrade = true, sellPrice = 100,
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
    { dataset = "items", id = "guardian-elixir", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "food", itemTier = "normal", soulbound = false, quantity = 5, modifications = {} },
    { dataset = "items", id = "quest", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "bound", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "no-sell", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "no-trade", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "sword", itemTier = "normal", soulbound = true, quantity = 1, modifications = {} },
    { dataset = "items", id = "sword", itemTier = "normal", soulbound = false, quantity = 1, modifications = {}, equipped = true },
    { dataset = "items", id = "armor", itemTier = "normal", soulbound = false, quantity = 2, modifications = {}, variantKey = "armor-normal" },
    { dataset = "items", id = "armor", itemTier = "heroic", soulbound = false, quantity = 3, modifications = {}, variantKey = "armor-heroic" },
    { dataset = "items", id = "armor", itemTier = "normal", soulbound = true, quantity = 1, modifications = {}, variantKey = "armor-bound" },
    { dataset = "items", id = "armor", itemTier = "normal", soulbound = false, quantity = 1, modifications = {}, equipped = true, variantKey = "armor-equipped" },
    { dataset = "items", id = "plate-armor", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "leg-armor", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "axe", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "offhand-sword", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "modification-match", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "modification-slot-miss", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "modification-weapon-miss", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
    { dataset = "items", id = "modification-armor-miss", itemTier = "normal", soulbound = false, quantity = 1, modifications = {} },
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

market.buyItemRefs = { "items:linen", "items:wool", "items:missing" }
local catalogue, _, catalogueDiagnostics = assert(Trading.GetMarketOffers("markets:exchange"))
assertEqual(#catalogue, 3, "every authored unique buy reference produces an offer row")
assertEqual(catalogue[1].itemRef, "items:linen", "linen catalogue entry is retained")
assertEqual(catalogue[2].itemRef, "items:wool", "wool catalogue entry is retained")
assertEqual(catalogue[3].itemRef, "items:missing", "missing catalogue entry is retained")
assertTrue(catalogue[1].enabled, "valid linen catalogue entry is enabled")
assertTrue(catalogue[2].enabled, "valid wool catalogue entry is enabled")
assertTrue(catalogue[3].enabled == false, "missing catalogue entry is disabled")
assertEqual(catalogue[3].reason, "item-unavailable", "missing catalogue entry exposes its reason")
assertEqual(catalogueDiagnostics.invalidEntryCount, 1, "catalogue diagnostics count invalid entries")
market.buyItemRefs = { "items:potion" }

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

local function eligibleItemRefs()
    local rows = assert(Trading.GetEligibleInventory("markets:exchange"))
    local refs = {}
    for index = 1, #rows do
        refs[rows[index].itemRef] = true
    end
    return refs
end

market.sellRules = {
    itemTypes = { "armor" },
    armorWeights = { "cloth" },
    slotRefs = { "definitions:head" },
}
local armorRuleRefs = eligibleItemRefs()
assertTrue(armorRuleRefs["items:armor"], "armor weight and slot filters accept a matching item")
assertTrue(not armorRuleRefs["items:plate-armor"], "armor weight filter rejects non-matching armor")
assertTrue(not armorRuleRefs["items:leg-armor"], "armor slot filter rejects non-matching armor")

market.sellRules = {
    itemTypes = { "weapon" },
    weaponTypeRefs = { "definitions:sword" },
    slotRefs = { "definitions:main-hand" },
}
local weaponRuleRefs = eligibleItemRefs()
assertTrue(weaponRuleRefs["items:sword"], "weapon type and slot filters accept a matching item")
assertTrue(not weaponRuleRefs["items:axe"], "weapon type filter rejects non-matching weapons")
assertTrue(not weaponRuleRefs["items:offhand-sword"], "weapon slot filter rejects non-matching weapons")

market.sellRules = {
    itemTypes = { "consumable" },
    consumableTypes = { "elixir" },
    consumableElixirTypes = { "battle" },
}
local elixirRuleRefs = eligibleItemRefs()
assertTrue(elixirRuleRefs["items:elixir"], "elixir subtype filter accepts a matching elixir")
assertTrue(not elixirRuleRefs["items:guardian-elixir"], "elixir subtype filter rejects non-matching elixirs")
assertTrue(not elixirRuleRefs["items:potion"], "consumable subtype filter rejects other consumables")

market.sellRules = {
    itemTypes = { "modification" },
    modificationKinds = { "enchant" },
    targetSlotRefs = { "definitions:head" },
    targetWeaponTypeRefs = { "definitions:sword" },
    targetArmorWeights = { "cloth" },
}
local modificationRuleRefs = eligibleItemRefs()
assertTrue(modificationRuleRefs["items:modification-match"], "modification target filters accept a matching modification")
assertTrue(not modificationRuleRefs["items:modification-slot-miss"], "modification target slot filter rejects non-matching modifications")
assertTrue(not modificationRuleRefs["items:modification-weapon-miss"], "modification target weapon filter rejects non-matching modifications")
assertTrue(not modificationRuleRefs["items:modification-armor-miss"], "modification target armor filter rejects non-matching modifications")

market.sellRules = {
    itemTypes = { "armor", "consumable" },
    armorWeights = { "cloth" },
    slotRefs = { "definitions:head" },
    consumableTypes = { "potion" },
}
local multiTypeRuleRefs = eligibleItemRefs()
assertTrue(multiTypeRuleRefs["items:armor"], "multi-type rules apply armor filters only to armor")
assertTrue(multiTypeRuleRefs["items:potion"], "multi-type rules apply consumable filters only to consumables")

market.sellRules = {
    itemRefs = { "items:plate-armor", "items:no-sell" },
    itemTypes = { "armor" },
    armorWeights = { "cloth" },
    slotRefs = { "definitions:head" },
}
local explicitRuleRefs = eligibleItemRefs()
assertTrue(explicitRuleRefs["items:plate-armor"], "exact sell item references override type-specific filters")
assertTrue(not explicitRuleRefs["items:no-sell"], "exact sell item references still require normal sellability")

market.sellRules = { itemTypes = { "armor" }, armorWeights = {}, slotRefs = {} }
local emptySubtypeRuleRefs = eligibleItemRefs()
assertTrue(emptySubtypeRuleRefs["items:armor"], "empty armor subtype lists impose no additional restriction")
assertTrue(emptySubtypeRuleRefs["items:plate-armor"], "empty armor weight list accepts all armor weights")
assertTrue(emptySubtypeRuleRefs["items:leg-armor"], "empty slot list accepts all armor slots")

market.sellRules = { itemTypes = { "consumable" }, consumableTypes = { "potion" } }
local legacyConsumableRuleRefs = eligibleItemRefs()
assertTrue(legacyConsumableRuleRefs["items:potion"], "legacy consumable subtype rules remain supported")
assertTrue(not legacyConsumableRuleRefs["items:elixir"], "legacy consumable subtype rules still restrict consumables")

market.sellRules = { itemTypes = { "armor" } }
local armorEligible, _, armorDiagnostics = assert(Trading.GetEligibleInventory("markets:exchange"))
local armorKeys = {}
for index = 1, #armorEligible do
    armorKeys[armorEligible[index].stackKey] = true
end
assertTrue(armorKeys["items|armor|normal|false|bag|armor-normal"], "normal armor variant is eligible")
assertTrue(armorKeys["items|armor|heroic|false|bag|armor-heroic"], "heroic armor variant is eligible")
assertTrue(not armorKeys["items|armor|normal|true|bag|armor-bound"], "soulbound armor variant is rejected independently")
assertTrue(not armorKeys["items|armor|normal|false|equipped|armor-equipped"], "equipped armor variant is rejected independently")
assertEqual(armorDiagnostics.eligibleVariantCount, 4, "all eligible armor variants are retained")
assertEqual(armorDiagnostics.rejectedVariantCount, 2, "only ineligible armor variants are rejected")
market.sellRules = {
    itemTypes = { "weapon", "consumable" },
    consumableTypes = { "potion", "elixir", "flask" },
}

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
