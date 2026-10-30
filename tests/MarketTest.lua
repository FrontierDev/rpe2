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

local Addon = Support.CreateAddon()
Addon.Internal.Database = { Classes = {} }
Support.LoadAddonFile("core/classes/Market.lua", Addon)
Support.LoadAddonFile("core/internal/database/Dependecies.lua", Addon)
Support.LoadAddonFile("core/internal/database/Database.lua", Addon)
Support.LoadAddonFile("core/internal/Registry.lua", Addon)

local Database = Addon.Internal.Database
local Market = Database.Classes.Market
local Registry = Addon.Internal.Registry
local root = Database.EnsureDatasets()
root.datasets = {
    items = {
        id = "items",
        name = "Items",
        items = {
            { id = "potion", name = "Potion" },
        },
        markets = {},
    },
    trackers = {
        id = "trackers",
        name = "Trackers",
        items = {},
        markets = {
            Market:New({
                id = "daily",
                name = "Daily Tracker",
                index = "DLY",
                marketType = "tracker",
                baseCoefficientPercent = 2,
                dailyVariationPercent = 4,
                trackerMarketRef = "ignored:value",
                tariffPercent = 20,
                buyItemRefs = { "items:potion" },
                sellRules = { itemRefs = { "items:potion" } },
            }):ToTable(),
        },
    },
    exchanges = {
        id = "exchanges",
        name = "Exchanges",
        items = {},
        markets = {
            Market:New({
                id = "stormwind",
                name = "  Stormwind Stock Exchange  ",
                index = " swe ",
                trackerMarketRef = "trackers:daily",
                buyItemRefs = { "items:potion", " items:potion " },
                sellRules = {
                    itemRefs = { "items:potion", "items:potion" },
                    itemTypes = { "weapon", " weapon " },
                    consumableTypes = { "potion" },
                },
            }):ToTable(),
        },
    },
}
root.activatedDatasets = { "items", "trackers", "exchanges" }
Database.Datasets = root
Database.Dependecies.RecomputeAllDatasetDependencies()

local tracker = root.datasets.trackers.markets[1]
assertEqual(tracker.trackerMarketRef, "", "tracker markets disable outgoing tracker references")
assertEqual(#tracker.buyItemRefs, 0, "tracker markets disable buy catalogues")
assertEqual(tracker.tariffPercent, 0, "tracker markets disable tariffs")
assertEqual(root.datasets.exchanges.markets[1].index, "SWE", "market index is trimmed and uppercased")
assertEqual(#root.datasets.exchanges.markets[1].buyItemRefs, 1, "market item references are deduplicated")
assertEqual(#root.datasets.exchanges.markets[1].sellRules.itemRefs, 1, "sell item references are deduplicated")
assertEqual(root.datasets.exchanges.markets[1].name, "Stormwind Stock Exchange", "market name is trimmed")

local exchangeDataset, exchange = Registry:ResolveMarketReference("exchanges:stormwind")
assertEqual(exchangeDataset.id, "exchanges", "qualified market references retain their dataset")
assertEqual(exchange.id, "stormwind", "qualified market references resolve by market ID")
local listedMarkets = Registry:ListMarkets()
assertEqual(#listedMarkets, 2, "market listing contains only valid markets from activated datasets")
assertEqual(listedMarkets[1].marketRef, "exchanges:stormwind", "market listing is deterministic")
assertTrue(Database.Dependecies.RecomputeDatasetDependencies("exchanges")[1] == "items", "item market references contribute dependencies")
assertTrue(Database.Dependecies.RecomputeDatasetDependencies("exchanges")[2] == "trackers", "tracker market references contribute dependencies")

local validationOk, validationDiagnostics = Database.ValidateDataset("exchanges")
assertTrue(validationOk, "valid exchange and tracker references pass validation: " .. table.concat(validationDiagnostics, "; "))

local created = Database.CreateDatasetEntry("exchanges", "markets")
assertEqual(#created.id, 8, "new markets receive stable eight-character IDs")
local clone = Database.CloneDatasetEntry("exchanges", "markets", 1)
assertTrue(clone.id ~= "stormwind", "market clones receive a new ID")
assertEqual(#clone.id, 8, "market clone IDs are eight characters")
assert(Database.RenameDatasetEntry("exchanges", "markets", 1, "Renamed Exchange"), "market rename succeeds")
assertEqual(root.datasets.exchanges.markets[1].name, "Renamed Exchange", "market rename changes only the authored name")
root.datasets.exchanges.markets[1].name = "Stormwind Stock Exchange"

local exportedEntry = Database.ExportDatasetEntry("exchanges", "markets", "stormwind")
local importedEntry = assert(Database.ImportDatasetEntry("items", "markets", exportedEntry))
assertEqual(importedEntry.id, "stormwind", "single-entry import preserves IDs when the destination is empty")
assertEqual(importedEntry.index, "SWE", "single-entry import preserves normalized fields")
local duplicateImportedEntry = assert(Database.ImportDatasetEntry("exchanges", "markets", exportedEntry))
assertTrue(duplicateImportedEntry.id ~= "stormwind", "single-entry import avoids duplicate IDs")

local exportedDataset = assert(Database.ExportDataset("exchanges"))
local importedDataset = assert(Database.ImportDataset(exportedDataset))
assertEqual(importedDataset.markets[1].trackerMarketRef, "trackers:daily", "full dataset export/import preserves tracker references")

root.activatedDatasets = { "items", "exchanges" }
local inactiveDataset, inactiveMarket = Registry:ResolveMarketReference("exchanges:stormwind")
assertEqual(inactiveDataset, nil, "inactive tracker dependencies do not resolve")
assertEqual(inactiveMarket, nil, "inactive tracker dependencies do not resolve a market")

root.activatedDatasets = { "items", "trackers", "exchanges" }
assert(Database.DeleteDatasetEntry("trackers", "markets", 1), "tracker deletion succeeds")
assertEqual(root.datasets.exchanges.markets[1].trackerMarketRef, "", "deleted tracker references are pruned")
assertEqual(Registry:ResolveMarketReference("exchanges:stormwind").id, "exchanges", "exchange remains resolvable without an optional tracker")

print("MarketTest passed")
