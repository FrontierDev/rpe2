local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Database = Addon.Internal and Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local MarketRates = Client.MarketRates or {}
Client.MarketRates = MarketRates

local CACHE_KEY = "marketRatesHistory"
local CACHE_VERSION = 2
local HISTORY_LENGTH = 14
local MAX_CACHED_MARKETS = 64
local HASH_MODULUS = 2147483647
local MIX_MULTIPLIER_A = 2246822507
local MIX_MULTIPLIER_B = 3266489909
local MIX_MULTIPLIER_C = 48271
local MINIMUM_COEFFICIENT_PERCENT = -95

MarketRates._cacheLoaded = MarketRates._cacheLoaded == true
MarketRates._cache = MarketRates._cache or nil
MarketRates._cacheDirty = MarketRates._cacheDirty == true
MarketRates._lastCycleKey = MarketRates._lastCycleKey or nil
MarketRates._resetScheduleToken = MarketRates._resetScheduleToken or 0
MarketRates._refreshListeners = MarketRates._refreshListeners or {}
MarketRates._nextRefreshListenerId = MarketRates._nextRefreshListenerId or 0

local function makeError(code, message, marketRef)
    return {
        code = code,
        message = message,
        marketRef = marketRef,
    }
end

local function isFiniteNumber(value)
    return value ~= nil
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function normalizeNumber(value)
    local numeric = tonumber(value)
    return isFiniteNumber(numeric) and numeric or nil
end

local function appendSignatureValue(buffer, key, value)
    buffer[#buffer + 1] = key
    buffer[#buffer + 1] = "="
    buffer[#buffer + 1] = tostring(value == nil and "" or value)
    buffer[#buffer + 1] = ";"
end

local function appendSignatureList(buffer, key, values)
    local list = type(values) == "table" and values or {}
    appendSignatureValue(buffer, key .. ".count", #list)
    for index = 1, #list do
        appendSignatureValue(buffer, key .. "." .. index, list[index])
    end
end

local function appendMarketSignature(buffer, prefix, market)
    local sellRules = type(market and market.sellRules) == "table" and market.sellRules or {}
    appendSignatureValue(buffer, prefix .. ".id", market and market.id)
    appendSignatureValue(buffer, prefix .. ".name", market and market.name)
    appendSignatureValue(buffer, prefix .. ".index", market and market.index)
    appendSignatureValue(buffer, prefix .. ".marketType", market and market.marketType)
    appendSignatureValue(buffer, prefix .. ".baseCoefficientPercent", market and market.baseCoefficientPercent)
    appendSignatureValue(buffer, prefix .. ".dailyVariationPercent", market and market.dailyVariationPercent)
    appendSignatureValue(buffer, prefix .. ".trackerMarketRef", market and market.trackerMarketRef)
    appendSignatureValue(buffer, prefix .. ".trackerInfluencePercent", market and market.trackerInfluencePercent)
    appendSignatureValue(buffer, prefix .. ".tariffPercent", market and market.tariffPercent)
    appendSignatureList(buffer, prefix .. ".buyItemRefs", market and market.buyItemRefs)
    appendSignatureList(buffer, prefix .. ".sellRules.itemRefs", sellRules.itemRefs)
    appendSignatureList(buffer, prefix .. ".sellRules.itemTypes", sellRules.itemTypes)
    appendSignatureList(buffer, prefix .. ".sellRules.consumableTypes", sellRules.consumableTypes)
end

local function hashText(text)
    local hash = 17
    local source = tostring(text or "")
    for index = 1, #source do
        hash = ((hash * 257) + string.byte(source, index)) % HASH_MODULUS
    end
    return hash
end

local function multiplyMod(left, right)
    local result = 0
    local multiplicand = math.floor(left or 0) % HASH_MODULUS
    local multiplier = math.floor(right or 0)

    while multiplier > 0 do
        if multiplier % 2 == 1 then
            result = (result + multiplicand) % HASH_MODULUS
        end
        multiplicand = (multiplicand + multiplicand) % HASH_MODULUS
        multiplier = math.floor(multiplier / 2)
    end

    return result
end

local function deterministicUnit(seed)
    local state = (math.floor(seed or 0) + 2654435769) % HASH_MODULUS
    state = multiplyMod(state, MIX_MULTIPLIER_A)
    state = (state + math.floor(state / 32768)) % HASH_MODULUS
    state = multiplyMod(state, MIX_MULTIPLIER_B)
    state = (state + (math.floor(state / 65536) * 33) + ((state % 65536) * 17)) % HASH_MODULUS
    state = multiplyMod(state, MIX_MULTIPLIER_C)
    return state / (HASH_MODULUS - 1)
end

local function roundPercent(value)
    local scaled = value * 100
    if scaled >= 0 then
        return math.floor(scaled + 0.5) / 100
    end

    return math.ceil(scaled - 0.5) / 100
end

local function sortedActivatedDatasetIds()
    if type(Registry.ListActivatedDatasetIds) ~= "function" then
        return nil, makeError("registry-unavailable", "Activated dataset registry is unavailable.")
    end

    local ok, ids = pcall(Registry.ListActivatedDatasetIds, Registry)
    if not ok then
        return nil, makeError("registry-error", "Activated dataset registry failed while reading its state.")
    end
    if type(ids) ~= "table" then
        return nil, makeError("registry-error", "Activated dataset registry returned invalid state.")
    end
    local sorted = {}
    for index = 1, #ids do
        sorted[#sorted + 1] = tostring(ids[index] or "")
    end
    table.sort(sorted)
    return sorted
end

local function getActivationSignature()
    local ids, errorResult = sortedActivatedDatasetIds()
    if not ids then
        return nil, errorResult
    end

    return table.concat(ids, "|")
end

local function resolveMarketDefinition(marketRef)
    local reference = tostring(marketRef or "")
    if reference == "" then
        return nil, makeError("invalid-reference", "Market reference must be datasetId:marketId.", reference)
    end
    if type(Registry.ResolveMarketReference) ~= "function" then
        return nil, makeError("registry-unavailable", "Market registry is unavailable.", reference)
    end

    local ok, dataset, market, reason = pcall(Registry.ResolveMarketReference, Registry, reference)
    if not ok then
        return nil, makeError("registry-error", "Market registry failed while resolving the Market.", reference)
    end
    if type(dataset) ~= "table" or type(market) ~= "table" then
        return nil, makeError(
            tostring(reason or "market-unavailable"),
            ("Market '%s' is unavailable (%s)."):format(reference, tostring(reason or "unknown")),
            reference
        )
    end

    local marketType = string.lower(tostring(market.marketType or ""))
    if marketType ~= "exchange" and marketType ~= "tracker" then
        return nil, makeError("invalid-market-type", "Market type must be exchange or tracker.", reference)
    end

    local datasetId = tostring(dataset.id or "")
    local marketId = tostring(market.id or "")
    local canonicalRef = ("%s:%s"):format(datasetId, marketId)
    if datasetId == "" or marketId == "" then
        return nil, makeError("invalid-reference", "Resolved Market has no qualified reference.", reference)
    end

    local tracker = nil
    local trackerReference = tostring(market.trackerMarketRef or "")
    trackerReference = trackerReference:gsub("^%s+", ""):gsub("%s+$", "")
    if marketType == "exchange" and trackerReference ~= "" then
        local trackerOk, trackerDataset, trackerMarket, trackerReason = pcall(
            Registry.ResolveMarketReference,
            Registry,
            trackerReference
        )
        if not trackerOk then
            return nil, makeError(
                "registry-error",
                "Market registry failed while resolving the tracker Market.",
                reference
            )
        end
        if type(trackerDataset) ~= "table" or type(trackerMarket) ~= "table" then
            return nil, makeError(
                tostring(trackerReason or "tracker-unavailable"),
                ("Tracker Market '%s' is unavailable (%s)."):format(
                    trackerReference,
                    tostring(trackerReason or "unknown")
                ),
                reference
            )
        end
        if string.lower(tostring(trackerMarket.marketType or "")) ~= "tracker" then
            return nil, makeError(
                "tracker-target-not-tracker",
                ("Market '%s' must link to a tracker Market."):format(trackerReference),
                reference
            )
        end

        tracker = {
            dataset = trackerDataset,
            market = trackerMarket,
            ref = ("%s:%s"):format(tostring(trackerDataset.id or ""), tostring(trackerMarket.id or "")),
        }
    end

    return {
        ref = canonicalRef,
        dataset = dataset,
        market = market,
        marketType = marketType,
        tracker = tracker,
    }
end

local function getDefinitionSignature(definition)
    local activationSignature, activationError = getActivationSignature()
    if not activationSignature then
        return nil, activationError
    end

    local parts = { "version=2;activated=", activationSignature, ";" }
    appendMarketSignature(parts, "market", definition.market)
    appendSignatureValue(parts, "market.ref", definition.ref)
    if definition.tracker then
        appendSignatureValue(parts, "tracker.ref", definition.tracker.ref)
        appendMarketSignature(parts, "tracker", definition.tracker.market)
    end
    return table.concat(parts)
end

local function getHistoryDayKeys(resetState)
    if type(resetState) ~= "table" or not isFiniteNumber(resetState.cycleTimestamp) then
        return nil, makeError("calendar-unavailable", "Daily reset calendar is unavailable.")
    end

    local keys = {}
    local seen = {}
    for age = HISTORY_LENGTH - 1, 0, -1 do
        local timestamp = resetState.cycleTimestamp - (age * 86400)
        local ok, dayKey = pcall(date, "%Y-%m-%d", timestamp)
        if not ok or not tostring(dayKey):match("^%d%d%d%d%-%d%d%-%d%d$") then
            return nil, makeError("calendar-unavailable", "Daily reset calendar is unavailable.")
        end
        if seen[dayKey] then
            return nil, makeError("calendar-unavailable", "Daily reset calendar returned duplicate cycle dates.")
        end
        seen[dayKey] = true
        keys[#keys + 1] = dayKey
    end

    if keys[#keys] ~= resetState.cycleKey then
        return nil, makeError("calendar-unavailable", "Daily reset cycle key is inconsistent.")
    end

    return keys
end

local function calculateOwnPercent(market, marketRef, dayKey)
    local base = normalizeNumber(market and market.baseCoefficientPercent)
    local variation = normalizeNumber(market and market.dailyVariationPercent)
    if not base or not variation or variation < 0 then
        return nil, makeError("invalid-market-definition", "Market coefficient values must be finite and non-negative where required.", marketRef)
    end

    local seed = hashText(marketRef .. "|" .. dayKey)
    local offset = (-variation) + (2 * variation * deterministicUnit(seed))
    local coefficient = base + offset
    if not isFiniteNumber(coefficient) then
        return nil, makeError("invalid-market-definition", "Market coefficient is non-finite.", marketRef)
    end

    return coefficient
end

local function calculateEffectivePercent(definition, dayKey)
    local ownPercent, ownError = calculateOwnPercent(definition.market, definition.ref, dayKey)
    if not ownPercent then
        return nil, ownError
    end

    local coefficient = ownPercent
    if definition.tracker then
        local trackerPercent, trackerError = calculateOwnPercent(
            definition.tracker.market,
            definition.tracker.ref,
            dayKey
        )
        if not trackerPercent then
            return nil, trackerError
        end

        local influence = normalizeNumber(definition.market.trackerInfluencePercent)
        if not influence then
            return nil, makeError("invalid-market-definition", "Tracker influence must be finite.", definition.ref)
        end
        coefficient = coefficient + (trackerPercent * influence / 100)
    end

    if not isFiniteNumber(coefficient) then
        return nil, makeError("invalid-market-definition", "Effective Market coefficient is non-finite.", definition.ref)
    end

    return roundPercent(math.max(MINIMUM_COEFFICIENT_PERCENT, coefficient))
end

local function newCache()
    return {
        version = CACHE_VERSION,
        markets = {},
    }
end

local function loadCache()
    if MarketRates._cacheLoaded then
        return MarketRates._cache
    end
    if type(Database.GetGlobalSetting) ~= "function" then
        return nil, makeError("cache-unavailable", "Global settings storage is unavailable.")
    end

    local ok, value = pcall(Database.GetGlobalSetting, CACHE_KEY, newCache())
    if not ok then
        return nil, makeError("cache-unavailable", "Market rate history cache could not be loaded.")
    end

    if type(value) ~= "table" or tonumber(value.version) ~= CACHE_VERSION or type(value.markets) ~= "table" then
        value = newCache()
        MarketRates._cacheDirty = true
    end

    MarketRates._cache = value
    MarketRates._cacheLoaded = true
    return value
end

local function persistCache()
    if not MarketRates._cacheDirty then
        return true
    end
    if type(Database.SetGlobalSetting) ~= "function" then
        return false, makeError("cache-unavailable", "Global settings storage is unavailable.")
    end

    local ok = pcall(Database.SetGlobalSetting, CACHE_KEY, MarketRates._cache)
    if not ok then
        return false, makeError("cache-unavailable", "Market rate history cache could not be saved.")
    end

    MarketRates._cacheDirty = false
    return true
end

local function setCacheDirty()
    MarketRates._cacheDirty = true
end

local function tablesEqual(left, right)
    left = type(left) == "table" and left or {}
    right = type(right) == "table" and right or {}
    for key, value in pairs(left or {}) do
        if right[key] ~= value then
            return false
        end
    end
    for key in pairs(right or {}) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function buildHistory(definition, resetState)
    local cache, cacheError = loadCache()
    if not cache then
        return nil, cacheError
    end

    local dayKeys, dayError = getHistoryDayKeys(resetState)
    if not dayKeys then
        return nil, dayError
    end

    local signature, signatureError = getDefinitionSignature(definition)
    if not signature then
        return nil, signatureError
    end

    local cachedEntry = cache.markets[definition.ref]
    local cachedValues = cachedEntry
        and cachedEntry.signature == signature
        and type(cachedEntry.values) == "table"
        and cachedEntry.values
        or {}
    local values = {}
    local rows = {}
    for index = 1, #dayKeys do
        local dayKey = dayKeys[index]
        local value = normalizeNumber(cachedValues[dayKey])
        if not value then
            local calculated, calculationError = calculateEffectivePercent(definition, dayKey)
            if not calculated then
                return nil, calculationError
            end
            value = calculated
        end
        values[dayKey] = value
        rows[#rows + 1] = {
            dayKey = dayKey,
            coefficientPercent = value,
        }
    end

    if not cachedEntry
        or cachedEntry.signature ~= signature
        or not tablesEqual(cachedEntry.values, values)
    then
        cache.markets[definition.ref] = {
            signature = signature,
            values = values,
            lastCycleKey = resetState.cycleKey,
        }
        setCacheDirty()
    elseif cachedEntry.lastCycleKey ~= resetState.cycleKey then
        cachedEntry.lastCycleKey = resetState.cycleKey
        setCacheDirty()
    end

    return rows
end

local function removeCacheEntry(marketRef)
    local cache = MarketRates._cache
    if cache and cache.markets and cache.markets[marketRef] then
        cache.markets[marketRef] = nil
        setCacheDirty()
    end
end

local function pruneCacheLimit()
    local cache = MarketRates._cache
    local refs = {}
    for marketRef in pairs(cache and cache.markets or {}) do
        refs[#refs + 1] = tostring(marketRef)
    end
    table.sort(refs)
    for index = MAX_CACHED_MARKETS + 1, #refs do
        removeCacheEntry(refs[index])
    end
end

local function scheduleResetCheck(resetState)
    if not C_Timer or type(C_Timer.After) ~= "function" or type(resetState) ~= "table" then
        return
    end

    MarketRates._resetScheduleToken = MarketRates._resetScheduleToken + 1
    local token = MarketRates._resetScheduleToken
    local delay = math.max(1, math.floor(tonumber(resetState.secondsRemaining) or 1) + 1)
    C_Timer.After(delay, function()
        if token ~= MarketRates._resetScheduleToken then
            return
        end
        MarketRates.RefreshForDailyReset()
    end)
end

local function getResetState()
    if type(Common.GetDailyResetState) ~= "function" then
        return nil, makeError("calendar-unavailable", "Daily reset calendar is unavailable.")
    end

    local state, reason = Common.GetDailyResetState()
    if type(state) ~= "table" then
        return nil, makeError(tostring(reason or "calendar-unavailable"), "Daily reset calendar is unavailable.")
    end
    return state
end

local function observeReset(state)
    local changed = MarketRates._lastCycleKey ~= state.cycleKey
    MarketRates._lastCycleKey = state.cycleKey
    scheduleResetCheck(state)
    return changed
end

local function notifyRefreshListeners(reason)
    for listenerId, listener in pairs(MarketRates._refreshListeners or {}) do
        if type(listener) == "function" then
            local ok, errorMessage = pcall(listener, reason)
            if not ok and Addon.Debug and Addon.Debug.Internal then
                Addon.Debug.Internal("Market rate refresh listener %s failed: %s", tostring(listenerId), tostring(errorMessage))
            end
        end
    end
end

function MarketRates.RegisterRefreshListener(listener)
    if type(listener) ~= "function" then
        return nil
    end
    MarketRates._nextRefreshListenerId = MarketRates._nextRefreshListenerId + 1
    local listenerId = MarketRates._nextRefreshListenerId
    MarketRates._refreshListeners[listenerId] = listener
    return listenerId
end

function MarketRates.UnregisterRefreshListener(listenerId)
    if MarketRates._refreshListeners[listenerId] == nil then
        return false
    end
    MarketRates._refreshListeners[listenerId] = nil
    return true
end

local function getHistoryInternal(marketRef, resetState)
    local definition, definitionError = resolveMarketDefinition(marketRef)
    if not definition then
        return nil, definitionError
    end

    return buildHistory(definition, resetState)
end

function MarketRates.GetHistory(marketRef)
    local resetState, resetError = getResetState()
    if not resetState then
        return nil, resetError
    end

    observeReset(resetState)
    local rows, historyError = getHistoryInternal(marketRef, resetState)
    if not rows then
        return nil, historyError
    end

    pruneCacheLimit()
    local persisted, persistError = persistCache()
    if not persisted then
        return nil, persistError
    end

    return rows
end

function MarketRates.GetCurrentCoefficient(marketRef)
    local history, historyError = MarketRates.GetHistory(marketRef)
    if not history then
        return nil, historyError
    end

    local current = history[#history]
    return current and current.coefficientPercent or nil
end

function MarketRates.RefreshForDailyReset()
    local resetState, resetError = getResetState()
    if not resetState then
        return nil, resetError
    end

    local cache, cacheError = loadCache()
    if not cache then
        return nil, cacheError
    end

    local changedCycle = observeReset(resetState)
    local cachedRefs = {}
    for marketRef in pairs(cache.markets) do
        cachedRefs[#cachedRefs + 1] = tostring(marketRef)
    end
    table.sort(cachedRefs)

    for index = 1, #cachedRefs do
        local marketRef = cachedRefs[index]
        local rows = getHistoryInternal(marketRef, resetState)
        if not rows then
            removeCacheEntry(marketRef)
        end
    end

    pruneCacheLimit()
    local persisted, persistError = persistCache()
    if not persisted then
        return nil, persistError
    end

    if changedCycle then
        notifyRefreshListeners("daily-reset")
    end

    return changedCycle
end

local initializer = CreateFrame and CreateFrame("Frame")
if initializer then
    initializer:RegisterEvent("ADDON_LOADED")
    initializer:RegisterEvent("PLAYER_ENTERING_WORLD")
    initializer:SetScript("OnEvent", function(_, event, loadedAddonName)
        if event == "ADDON_LOADED" and loadedAddonName ~= Addon.Name then
            return
        end
        MarketRates.RefreshForDailyReset()
    end)
end
