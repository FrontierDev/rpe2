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
addon.Internal.Registry = {
    ResolveItemReference = function(_, itemRef)
        local item = items[itemRef]
        if not item then
            return nil, nil, "missing-item"
        end
        return { id = "items" }, item
    end,
}
addon.Internal.Profile = {
    GetCurrencyAmount = function()
        return 150
    end,
}
addon.Client = {
    Trading = {
        Quote = function(marketRef, itemRef, mode, quantity)
            if marketRef ~= "markets:exchange" then
                return nil, { code = "missing-market" }
            end
            local unit = itemRef == "items:potion" and 100 or itemRef == "items:elixir" and 200 or 50
            if mode == "sell" then
                unit = 40
            end
            return {
                itemRef = itemRef,
                unitCopper = unit,
                totalCopper = unit * quantity,
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
page.market = {
    marketType = "exchange",
    buyItemRefs = { "items:potion", "items:missing", "items:elixir" },
}

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

print("TradingItemsTest passed")
