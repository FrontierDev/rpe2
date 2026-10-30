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

local function findByKey(rows, key)
    for index = 1, #rows do
        if rows[index].key == key then
            return rows[index]
        end
    end
end

local function findByValue(rows, value)
    for index = 1, #rows do
        if rows[index].value == value then
            return rows[index]
        end
    end
end

local items = {
    ["items:potion"] = {
        id = "potion",
        name = "Healing Potion",
        itemType = "consumable",
        consumableType = "potion",
        quality = "common",
        icon = "potion-icon",
    },
    ["items:elixir"] = {
        id = "elixir",
        name = "Battle Elixir",
        itemType = "consumable",
        consumableType = "elixir",
        quality = "uncommon",
        icon = "elixir-icon",
    },
    ["items:sword"] = {
        id = "sword",
        name = "Training Sword",
        itemType = "weapon",
        quality = "rare",
        icon = "sword-icon",
    },
}

local addon = Support.CreateAddon()
addon.UI = {}
addon.Utils = { Common = {} }
local market = {
    marketType = "exchange",
    buyItemRefs = { "items:potion", "items:missing", "items:elixir" },
}
addon.Internal.Registry = {
    ResolveMarketReference = function(_, marketRef)
        if marketRef == "markets:exchange" then
            return { id = "markets" }, market
        end
        return nil, nil, "missing-market"
    end,
}
addon.Internal.Profile = {
    GetCurrencyAmount = function()
        return 150
    end,
}
addon.Client = {
    Trading = {
        GetMarketOffers = function(marketRef)
            if marketRef ~= "markets:exchange" then
                return nil, { code = "missing-market" }
            end
            return {
                {
                    itemRef = "items:potion",
                    datasetId = "items",
                    item = items["items:potion"],
                    unitCopper = 100,
                    enabled = true,
                    quote = { unitCopper = 100, totalCopper = 100 },
                },
                {
                    itemRef = "items:missing",
                    enabled = false,
                    reason = "missing-item",
                },
                {
                    itemRef = "items:elixir",
                    datasetId = "items",
                    item = items["items:elixir"],
                    unitCopper = 200,
                    enabled = true,
                    quote = { unitCopper = 200, totalCopper = 200 },
                },
            }, nil, {
                catalogueEntryCount = 3,
                validEntryCount = 2,
                invalidEntryCount = 1,
                firstInvalidReason = "missing-item",
            }
        end,
        GetEligibleInventory = function()
            return {
                {
                    itemRef = "items:sword",
                    datasetId = "items",
                    item = items["items:sword"],
                    itemTier = "normal",
                    stackKey = "sword-normal",
                    quantity = 2,
                    unitCopper = 40,
                    variant = {
                        dataset = "items",
                        id = "sword",
                        itemTier = "normal",
                        soulbound = false,
                        quantity = 2,
                        stackKey = "sword-normal",
                    },
                },
                {
                    itemRef = "items:sword",
                    datasetId = "items",
                    item = items["items:sword"],
                    itemTier = "heroic",
                    stackKey = "sword-heroic",
                    quantity = 3,
                    unitCopper = 40,
                    variant = {
                        dataset = "items",
                        id = "sword",
                        itemTier = "heroic",
                        soulbound = false,
                        quantity = 3,
                        stackKey = "sword-heroic",
                    },
                },
                {
                    itemRef = "items:elixir",
                    datasetId = "items",
                    item = items["items:elixir"],
                    itemTier = "normal",
                    stackKey = "elixir-normal",
                    quantity = 1,
                    unitCopper = 40,
                    variant = {
                        dataset = "items",
                        id = "elixir",
                        itemTier = "normal",
                        soulbound = false,
                        quantity = 1,
                        stackKey = "elixir-normal",
                    },
                },
            }
        end,
    },
}

Support.LoadAddonFile("client/character/trading/page_TradingItems.lua", addon)
local page = addon.Client.UI.Trading.Items:New()
page.marketRef = "markets:exchange"
page.market = { marketType = "exchange", buyItemRefs = {} }

assertEqual(page:ResolveMarket(), market, "qualified Market reference replaces stale Market data")
market.buyItemRefs = { "items:sword" }
assertEqual(page:ResolveMarket().buyItemRefs[1], "items:sword", "market edits are resolved from the qualified reference")
market.buyItemRefs = { "items:potion", "items:missing", "items:elixir" }
page.marketRef = "markets:missing"
local unresolvedMarket, unresolvedReason = page:ResolveMarket()
assertEqual(unresolvedMarket, nil, "invalid selected Market is rejected explicitly")
assertEqual(unresolvedReason, "missing-market", "invalid selected Market exposes its resolver reason")
page.marketRef = "markets:exchange"

local buyRows = page:BuildBuyItems()
assertEqual(#buyRows, 3, "buy rows retain missing authored entries")
assertTrue(findByKey(buyRows, "items:potion").enabled, "affordable buy row is enabled")
assertTrue(findByKey(buyRows, "items:missing").enabled == false, "missing buy row is disabled")
assertTrue(findByKey(buyRows, "items:missing").reason == "missing-item", "missing buy reason is exposed")
assertTrue(findByKey(buyRows, "items:elixir").enabled == false, "unaffordable buy row is disabled")

page.items = buyRows
page:BuildCategories()
page:ApplyFilter()
page:EnsureSelection()
assertEqual(page.selectedItemKey, "items:potion", "buy selection chooses first affordable row")
assertTrue(findByValue(page.categories, "type:consumable") ~= nil, "consumable category is available")
assertTrue(findByValue(page.categories, "consumable:potion") ~= nil, "potion subtype category is available")
assertTrue(findByValue(page.categories, "consumable:elixir") ~= nil, "elixir subtype category is available")

page.mode = "sell"
local sellRows = page:BuildSellItems()
assertEqual(#sellRows, 3, "sell rows preserve eligible variants")
assertTrue(findByKey(sellRows, "items:sword|sword-normal") ~= nil, "normal variant remains distinct")
assertTrue(findByKey(sellRows, "items:sword|sword-heroic") ~= nil, "heroic variant remains distinct")
assertEqual(findByKey(sellRows, "items:sword|sword-heroic").quantityAvailable, 3, "sell quantity uses current variant quantity")

page.items = sellRows
page:BuildCategories()
page.categoryValue = "consumable:potion"
page:ApplyFilter()
assertEqual(#page.filteredItems, 0, "unavailable subtype produces an empty filtered list")
page.categoryValue = "type:weapon"
page:ApplyFilter()
assertEqual(#page.filteredItems, 2, "weapon filter keeps both tiers")

local quantityChanges = 0
page.quantity = 3
page.SetQuantity = function()
    quantityChanges = quantityChanges + 1
end
page.quantityInput = {
    SetText = function()
        page:OnQuantityInputChanged({ GetText = function() return "3" end })
    end,
}
page:UpdateQuantityText()
assertEqual(quantityChanges, 0, "programmatic quantity text updates do not re-enter the quantity handler")
page:OnQuantityInputChanged({ GetText = function() return "2" end })
assertEqual(quantityChanges, 1, "user quantity edits still update the selection")

local itemBuildCount = 0
local itemHost = {}
addon.Client.UI.Trading.Items = {
    New = function()
        return {
            built = false,
            Build = function(self, parent, owner)
                itemBuildCount = itemBuildCount + 1
                assertEqual(parent, itemHost, "cached window rebuild uses the item panel content frame")
                assertTrue(owner ~= nil, "cached window rebuild supplies the trading window owner")
                self.built = true
            end,
        }
    end,
}
addon.Client.UI.Trading.Markets = { New = function() return {} end }
addon.Client.UI.Trading.Chart = { New = function() return {} end }
Support.LoadAddonFile("client/character/trading/window_Trading.lua", addon)

local tradingWindow = addon.Client.UI.Trading.Window:Get()
tradingWindow.window = {
    GetFrame = function()
        return { SetSize = function() end }
    end,
}
tradingWindow.itemPanel = {
    GetContentFrame = function()
        return itemHost
    end,
}
tradingWindow:BuildWindow()
assertEqual(itemBuildCount, 1, "cached window completes an unbuilt item page")
assertTrue(tradingWindow.itemsPage.built, "cached window marks the rebuilt item page as complete")

print("TradingItemsTest passed")
