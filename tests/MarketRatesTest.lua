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
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy
    for key, item in pairs(value) do
        copy[clone(key, seen)] = clone(item, seen)
    end
    return copy
end

local now = os.time({ year = 2026, month = 10, day = 30, hour = 10, min = 0, sec = 0 })
function GetServerTime()
    return now
end

date = os.date

C_DateAndTime = {
    GetSecondsUntilDailyReset = function()
        return 3600
    end,
}

local storedSettings = {}
local activeDatasets = {
    exchanges = true,
    trackers = true,
}

local markets = {
    ["trackers:daily"] = {
        dataset = { id = "trackers" },
        market = {
            id = "daily",
            marketType = "tracker",
            baseCoefficientPercent = 20,
            dailyVariationPercent = 0,
            trackerMarketRef = "",
        },
    },
    ["trackers:volatile"] = {
        dataset = { id = "trackers" },
        market = {
            id = "volatile",
            marketType = "tracker",
            baseCoefficientPercent = 0,
            dailyVariationPercent = 10,
            trackerMarketRef = "",
        },
    },
    ["exchanges:stormwind"] = {
        dataset = { id = "exchanges" },
        market = {
            id = "stormwind",
            marketType = "exchange",
            baseCoefficientPercent = 10,
            dailyVariationPercent = 5,
            trackerMarketRef = "trackers:daily",
            trackerInfluencePercent = 25,
        },
    },
    ["exchanges:fixed"] = {
        dataset = { id = "exchanges" },
        market = {
            id = "fixed",
            marketType = "exchange",
            baseCoefficientPercent = 10,
            dailyVariationPercent = 0,
            trackerMarketRef = "trackers:daily",
            trackerInfluencePercent = 25,
        },
    },
    ["exchanges:volatile"] = {
        dataset = { id = "exchanges" },
        market = {
            id = "volatile",
            marketType = "exchange",
            baseCoefficientPercent = 0,
            dailyVariationPercent = 10,
            trackerMarketRef = "",
        },
    },
    ["exchanges:tracker-volatile"] = {
        dataset = { id = "exchanges" },
        market = {
            id = "tracker-volatile",
            marketType = "exchange",
            baseCoefficientPercent = 0,
            dailyVariationPercent = 0,
            trackerMarketRef = "trackers:volatile",
            trackerInfluencePercent = 100,
        },
    },
    ["exchanges:floor"] = {
        dataset = { id = "exchanges" },
        market = {
            id = "floor",
            marketType = "exchange",
            baseCoefficientPercent = -200,
            dailyVariationPercent = 0,
            trackerMarketRef = "",
        },
    },
    ["exchanges:invalid"] = {
        dataset = { id = "exchanges" },
        market = {
            id = "invalid",
            marketType = "exchange",
            baseCoefficientPercent = 10,
            dailyVariationPercent = 0,
            trackerMarketRef = "trackers:missing",
            trackerInfluencePercent = 25,
        },
    },
    ["exchanges:cycle-a"] = {
        dataset = { id = "exchanges" },
        market = {
            id = "cycle-a",
            marketType = "exchange",
            baseCoefficientPercent = 10,
            dailyVariationPercent = 0,
            trackerMarketRef = "exchanges:cycle-b",
            trackerInfluencePercent = 25,
        },
    },
    ["exchanges:cycle-b"] = {
        dataset = { id = "exchanges" },
        market = {
            id = "cycle-b",
            marketType = "exchange",
            baseCoefficientPercent = 10,
            dailyVariationPercent = 0,
            trackerMarketRef = "exchanges:cycle-a",
            trackerInfluencePercent = 25,
        },
    },
}

local function resolveMarketReference(_, marketRef, visited)
    local entry = markets[marketRef]
    if not entry then
        return nil, nil, "missing-market"
    end

    local datasetId = entry.dataset.id
    if not activeDatasets[datasetId] then
        return nil, nil, "inactive-dataset"
    end

    local market = entry.market
    if market.marketType == "exchange" and market.trackerMarketRef ~= "" then
        visited = visited or {}
        if visited[marketRef] then
            return nil, nil, "tracker-cycle"
        end
        visited[marketRef] = true

        local tracker = markets[market.trackerMarketRef]
        if not tracker then
            return nil, nil, "missing-tracker-market"
        end
        if not activeDatasets[tracker.dataset.id] then
            return nil, nil, "inactive-tracker-dataset"
        end
        if tracker.market.marketType ~= "tracker" then
            return resolveMarketReference(_, market.trackerMarketRef, visited)
        end
    end

    if market.marketType == "tracker" and market.trackerMarketRef ~= "" then
        return nil, nil, "tracker-outgoing-reference"
    end

    return entry.dataset, market
end

local function createAddon(settings)
    settings = settings or storedSettings
    local addon = Support.CreateAddon()
    addon.Internal.Database = {
        GetGlobalSetting = function(key, defaultValue)
            if settings[key] == nil then
                return clone(defaultValue)
            end
            return clone(settings[key])
        end,
        SetGlobalSetting = function(key, value)
            settings[key] = clone(value)
        end,
    }
    addon.Internal.Registry = {
        ListActivatedDatasetIds = function()
            local ids = {}
            for datasetId, isActive in pairs(activeDatasets) do
                if isActive then
                    ids[#ids + 1] = datasetId
                end
            end
            return ids
        end,
        ResolveMarketReference = resolveMarketReference,
    }
    Support.LoadAddonFile("utils/Common.lua", addon)
    Support.LoadAddonFile("client/client_MarketRates.lua", addon)
    return addon
end

local function assertHistory(history, message)
    assertTrue(type(history) == "table", message .. " returns history")
    assertEqual(#history, 14, message .. " has fourteen rows")
    for index = 2, #history do
        assertTrue(history[index - 1].dayKey < history[index].dayKey, message .. " is ascending")
    end
    assertEqual(history[#history].dayKey, os.date("%Y-%m-%d", now + 3600), message .. " ends on current cycle")
end

local firstAddon = createAddon()
local firstRates = firstAddon.Client.MarketRates
local firstHistory = assert(firstRates.GetHistory("exchanges:stormwind"))
assertHistory(firstHistory, "empty-cache history")
assertTrue(storedSettings.marketRatesHistory ~= nil, "history is persisted in global settings")
assertEqual(#firstHistory, 14, "empty-cache history is complete")

local volatileHistory = assert(firstRates.GetHistory("exchanges:volatile"))
assertHistory(volatileHistory, "volatile history")
local expectedVolatileValues = {
    -3.79, 9.33, -5.24, -1.19, 4.25, 2.64, 8.08,
    0.36, 5.79, -1.93, 3.50, 8.94, 1.22, -4.12,
}
local volatileMinimum = math.huge
local volatileMaximum = -math.huge
local hasMeaningfulUpwardMove = false
local hasMeaningfulDownwardMove = false
for index = 1, #volatileHistory do
    local value = volatileHistory[index].coefficientPercent
    assertEqual(value, expectedVolatileValues[index], "volatile fixture is byte-for-byte deterministic")
    volatileMinimum = math.min(volatileMinimum, value)
    volatileMaximum = math.max(volatileMaximum, value)
    if index > 1 then
        local previous = volatileHistory[index - 1].coefficientPercent
        hasMeaningfulUpwardMove = hasMeaningfulUpwardMove or value - previous >= 1
        hasMeaningfulDownwardMove = hasMeaningfulDownwardMove or previous - value >= 1
    end
    assertTrue(value >= -10 and value <= 10, "volatile offset stays inside authored variation")
end
assertTrue(volatileMinimum <= -5, "volatile fixture reaches the lower half of its configured range")
assertTrue(volatileMaximum >= 5, "volatile fixture reaches the upper half of its configured range")
assertTrue(volatileMaximum - volatileMinimum >= 10, "volatile fixture spans a substantial configured range")
assertTrue(hasMeaningfulUpwardMove, "volatile fixture contains meaningful upward movement")
assertTrue(hasMeaningfulDownwardMove, "volatile fixture contains meaningful downward movement")

local floorHistory = assert(firstRates.GetHistory("exchanges:floor"))
for index = 1, #floorHistory do
    assertEqual(floorHistory[index].coefficientPercent, -95, "minimum coefficient safety floor remains enforced")
end

local staleStorage = clone(storedSettings)
staleStorage.marketRatesHistory.version = 1
staleStorage.marketRatesHistory.markets["exchanges:volatile"].signature = "version=1;stale"
staleStorage.marketRatesHistory.markets["exchanges:volatile"].values[volatileHistory[#volatileHistory].dayKey] = 999
local invalidatedRates = createAddon(staleStorage).Client.MarketRates
local invalidatedHistory = assert(invalidatedRates.GetHistory("exchanges:volatile"))
for index = 1, #volatileHistory do
    assertEqual(
        invalidatedHistory[index].coefficientPercent,
        volatileHistory[index].coefficientPercent,
        "cache version invalidation replaces stale deterministic values"
    )
end
assertEqual(staleStorage.marketRatesHistory.version, 2, "cache version is rewritten after invalidation")

local trackerHistory = assert(firstRates.GetHistory("trackers:volatile"))
local linkedTrackerHistory = assert(firstRates.GetHistory("exchanges:tracker-volatile"))
for index = 1, #trackerHistory do
    assertEqual(
        linkedTrackerHistory[index].coefficientPercent,
        trackerHistory[index].coefficientPercent,
        "tracker contribution uses the tracker seed independently"
    )
end

local fixedHistory = assert(firstRates.GetHistory("exchanges:fixed"))
for index = 1, #fixedHistory do
    assertEqual(fixedHistory[index].coefficientPercent, 15, "tracker influence is applied")
end
assertEqual(firstRates.GetCurrentCoefficient("exchanges:stormwind"), firstHistory[#firstHistory].coefficientPercent, "current quote uses history source")
assertEqual(markets["trackers:daily"].market.trackerMarketRef, "", "authored tracker is not mutated")
assertEqual(firstRates.RefreshForDailyReset(), false, "same-cycle refresh is idempotent")

math.random()
local secondHistory = assert(firstRates.GetHistory("exchanges:stormwind"))
for index = 1, #firstHistory do
    assertEqual(secondHistory[index].dayKey, firstHistory[index].dayKey, "repeated evaluation keeps dates")
    assertEqual(secondHistory[index].coefficientPercent, firstHistory[index].coefficientPercent, "repeated evaluation is deterministic")
end

local reloadedRates = createAddon().Client.MarketRates
local trackerFirstHistory = assert(reloadedRates.GetHistory("trackers:daily"))
local reloadedHistory = assert(reloadedRates.GetHistory("exchanges:stormwind"))
for index = 1, #firstHistory do
    assertEqual(reloadedHistory[index].coefficientPercent, firstHistory[index].coefficientPercent, "reload and lookup order do not change values")
end
assertHistory(trackerFirstHistory, "tracker history")

local independentFirst = assert(createAddon({}).Client.MarketRates.GetHistory("exchanges:volatile"))
math.random()
local independentSecondRates = createAddon({}).Client.MarketRates
assert(independentSecondRates.GetHistory("trackers:volatile"))
local independentSecond = assert(independentSecondRates.GetHistory("exchanges:volatile"))
for index = 1, #independentFirst do
    assertEqual(independentSecond[index].dayKey, independentFirst[index].dayKey, "identical clients keep the same dates")
    assertEqual(
        independentSecond[index].coefficientPercent,
        independentFirst[index].coefficientPercent,
        "identical clients produce the same deterministic series"
    )
end

activeDatasets.trackers = false
local inactiveHistory, inactiveError = reloadedRates.GetHistory("exchanges:stormwind")
assertEqual(inactiveHistory, nil, "inactive tracker fails explicitly")
assertEqual(inactiveError.code, "inactive-tracker-dataset", "inactive tracker error")
activeDatasets.trackers = true

local invalidHistory, invalidError = reloadedRates.GetHistory("exchanges:invalid")
assertEqual(invalidHistory, nil, "missing tracker fails explicitly")
assertEqual(invalidError.code, "missing-tracker-market", "missing tracker error")
local cycleHistory, cycleError = reloadedRates.GetHistory("exchanges:cycle-a")
assertEqual(cycleHistory, nil, "cyclic tracker fails explicitly")
assertEqual(cycleError.code, "tracker-cycle", "cyclic tracker error")

now = now + (3 * 86400)
local refreshNotifications = 0
local refreshListenerId = reloadedRates.RegisterRefreshListener(function(reason)
    assertEqual(reason, "daily-reset", "reset listener reason")
    refreshNotifications = refreshNotifications + 1
end)
assertTrue(refreshListenerId ~= nil, "market rate reset listener registers")
assertEqual(reloadedRates.RefreshForDailyReset(), true, "daily reset refreshes cached histories")
assertEqual(refreshNotifications, 1, "daily reset notifies listeners once")
local laterHistory = assert(reloadedRates.GetHistory("exchanges:stormwind"))
assertEqual(#laterHistory, 14, "offline gap keeps fourteen rows")
assertEqual(laterHistory[#laterHistory].dayKey, os.date("%Y-%m-%d", now + 3600), "offline gap ends today")
assertTrue(laterHistory[1].dayKey > firstHistory[1].dayKey, "offline gap advances the window")

markets["exchanges:stormwind"].market.baseCoefficientPercent = 11
local changedHistory = assert(reloadedRates.GetHistory("exchanges:stormwind"))
assertEqual(changedHistory[#changedHistory].coefficientPercent, laterHistory[#laterHistory].coefficientPercent + 1, "definition change invalidates cached values")

C_DateAndTime = nil
local unavailableHistory, unavailableError = reloadedRates.GetHistory("exchanges:stormwind")
assertEqual(unavailableHistory, nil, "unavailable calendar does not return partial history")
assertEqual(unavailableError.code, "calendar-unavailable", "unavailable calendar error")

print("MarketRatesTest passed")
