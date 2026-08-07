local _, Addon = ...

Addon.Utils = Addon.Utils or {}

local Lookup = Addon.Utils.Lookup or {}
Addon.Utils.Lookup = Lookup
local Debug = Addon.Debug
local ApplyingAuraStatOverlay = {}

local function getCommon()
    return Addon.Utils and Addon.Utils.Common or {}
end

local function getProfile()
    return Addon.Internal and Addon.Internal.Profile or {}
end

local function getDatabase()
    return Addon.Internal and Addon.Internal.Database or {}
end

local function getDependencies()
    local database = getDatabase()
    return database and database.Dependecies or {}
end

local function getRegistry()
    return Addon.Internal and Addon.Internal.Registry or {}
end

local function normalizeName(value)
    local Common = getCommon()
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end

    return type(value) == "string" and value or ""
end

local function isLocalPlayerUnit(unit)
    if type(unit) ~= "table" or unit.isPlayer ~= true then
        return false
    end

    local Common = getCommon()
    local localPlayerName = type(Common.GetPlayerName) == "function" and normalizeName(Common.GetPlayerName()) or ""
    if localPlayerName == "" then
        return false
    end

    local unitPlayerName = normalizeName(unit.ownerID or unit.controllerID or unit.name)
    return unitPlayerName ~= "" and unitPlayerName == localPlayerName
end

local function resolveStatName(statRef)
    local Registry = getRegistry()
    if type(statRef) ~= "string" or statRef == "" or type(Registry.ResolveStatReference) ~= "function" then
        return statRef
    end

    local _, stat = Registry:ResolveStatReference(statRef)
    local name = tostring(stat and stat.name or "")
    if name ~= "" then
        return name
    end

    return statRef
end

local function ensureUnitEntryCache(unit, cacheKey, sourceKey, refKey)
    if type(unit) ~= "table" or type(cacheKey) ~= "string" or cacheKey == "" then
        return nil
    end

    local entries = unit[sourceKey]
    local cached = type(unit[cacheKey]) == "table" and unit[cacheKey] or nil
    if cached and cached.entries == entries then
        return cached
    end

    local byRef = {}
    local indexByRef = {}
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        local ref = type(entry) == "table" and tostring(entry[refKey] or "") or ""
        if ref ~= "" then
            byRef[ref] = entry
            indexByRef[ref] = index
        end
    end

    cached = {
        entries = entries,
        byRef = byRef,
        indexByRef = indexByRef,
    }
    unit[cacheKey] = cached
    return cached
end

local function debugResolvedStatRows(statRef)
    local Profile = getProfile()
    local Dependencies = getDependencies()
    if type(Debug) ~= "table" or type(Debug.Internal) ~= "function" or type(Profile.ListResolvedStats) ~= "function" then
        return
    end

    local normalizedRef = type(statRef) == "string" and statRef or ""
    local requestedDatasetId, requestedStatId = nil, nil
    if normalizedRef ~= "" and type(Dependencies.ParseSourceStatRef) == "function" then
        requestedDatasetId, requestedStatId = Dependencies.ParseSourceStatRef(normalizedRef)
    end

    local requestedName = tostring(resolveStatName(normalizedRef) or "")
    local rows = Profile.ListResolvedStats() or {}
    local matched = 0

    Debug.Internal(
        "Local player stat lookup debug start: statRef=%s datasetId=%s statId=%s statName=%s resolvedCount=%s.",
        tostring(normalizedRef ~= "" and normalizedRef or "nil"),
        tostring(requestedDatasetId or "nil"),
        tostring(requestedStatId or "nil"),
        tostring(requestedName ~= "" and requestedName or "unknown"),
        tostring(#rows)
    )

    for index = 1, #rows do
        local row = rows[index]
        if type(row) == "table" then
            local rowRef = tostring(row.ref or "")
            local rowDatasetId = tostring(row.datasetId or "")
            local rowStatId = tostring(row.statId or "")
            local rowName = tostring(row.name or "")
            local isRelevant = false

            if normalizedRef ~= "" and rowRef == normalizedRef then
                isRelevant = true
            end
            if requestedDatasetId ~= nil and rowDatasetId == tostring(requestedDatasetId) then
                isRelevant = true
            end
            if requestedStatId ~= nil and rowStatId == tostring(requestedStatId) then
                isRelevant = true
            end
            if requestedName ~= "" and rowName == requestedName then
                isRelevant = true
            end

            if isRelevant then
                matched = matched + 1
                Debug.Internal(
                    "Local player resolved stat row %s: ref=%s datasetId=%s statId=%s name=%s value=%s category=%s visible=%s.",
                    tostring(matched),
                    tostring(rowRef ~= "" and rowRef or "nil"),
                    tostring(rowDatasetId ~= "" and rowDatasetId or "nil"),
                    tostring(rowStatId ~= "" and rowStatId or "nil"),
                    tostring(rowName ~= "" and rowName or "nil"),
                    tostring(row.value ~= nil and row.value or "nil"),
                    tostring(row.stat and row.stat.category or "nil"),
                    tostring(row.stat and row.stat.visibility or "nil")
                )
            end
        end
    end

    if matched <= 0 then
        Debug.Internal(
            "Local player stat lookup debug found no relevant resolved rows for statRef=%s.",
            tostring(normalizedRef ~= "" and normalizedRef or "nil")
        )
    end
end

local function logLocalPlayerStatLookupFailure(statRef)
    if type(Debug) ~= "table" or type(Debug.Internal) ~= "function" then
        return
    end

    Debug.Internal(
        "Local player stat lookup failed: statRef=%s statName=%s is not present in resolved profile stats.",
        tostring(statRef or "nil"),
        tostring(resolveStatName(statRef) or "unknown")
    )
end

function Lookup.FindEventUnitById(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit, index
        end
    end

    return nil
end

function Lookup.GetStatEntry(unit, statRef)
    if type(unit) ~= "table" or type(statRef) ~= "string" or statRef == "" then
        return nil
    end

    local cached = ensureUnitEntryCache(unit, "__rpeStatEntryCache", "stats", "statRef")
    local entry = cached and cached.byRef and cached.byRef[statRef] or nil
    if entry then
        return entry, cached.indexByRef and cached.indexByRef[statRef] or nil
    end

    local resolvedUnit = type(unit.GetResolvedUnit) == "function" and unit:GetResolvedUnit() or nil
    if type(resolvedUnit) == "table" and resolvedUnit ~= unit then
        local resolvedCache = ensureUnitEntryCache(resolvedUnit, "__rpeStatEntryCache", "stats", "statRef")
        local resolvedEntry = resolvedCache and resolvedCache.byRef and resolvedCache.byRef[statRef] or nil
        if resolvedEntry then
            return resolvedEntry, resolvedCache.indexByRef and resolvedCache.indexByRef[statRef] or nil
        end
    end

    return nil
end

function Lookup.GetStatValue(unit, statRef, fallback)
    local overlayKey = tostring(unit) .. "\31" .. tostring(statRef or "")
    local baseValue = fallback or 0

    if isLocalPlayerUnit(unit) then
        local Profile = getProfile()
        local resolvedValue, foundResolved = nil, false
        if type(Profile.GetResolvedStatValue) == "function" then
            resolvedValue, foundResolved = Profile.GetResolvedStatValue(statRef, nil, {
                includeAuraBonuses = false,
            })
        end
        if resolvedValue ~= nil then
            baseValue = resolvedValue
        elseif foundResolved == false then
            debugResolvedStatRows(statRef)
            logLocalPlayerStatLookupFailure(statRef)
            if ApplyingAuraStatOverlay[overlayKey] then
                return baseValue
            end

            local auraManager = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraManager or nil
            if auraManager and type(auraManager.ApplyStatModifiers) == "function" then
                ApplyingAuraStatOverlay[overlayKey] = true
                local ok, value = pcall(auraManager.ApplyStatModifiers, auraManager, unit, statRef, baseValue)
                ApplyingAuraStatOverlay[overlayKey] = nil
                if ok then
                    return value
                end
            end

            return baseValue
        end
    else
        local entry = Lookup.GetStatEntry(unit, statRef)
        if entry then
            baseValue = tonumber(entry.currentValue)
                or tonumber(entry.value)
                or tonumber(entry.current)
                or tonumber(entry.maxValue)
                or fallback
                or 0
        elseif ApplyingAuraStatOverlay[overlayKey] then
            return baseValue
        else
            local auraManager = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraManager or nil
            if auraManager and type(auraManager.ApplyStatModifiers) == "function" then
                ApplyingAuraStatOverlay[overlayKey] = true
                local ok, value = pcall(auraManager.ApplyStatModifiers, auraManager, unit, statRef, baseValue)
                ApplyingAuraStatOverlay[overlayKey] = nil
                if ok then
                    return value
                end
            end

            return baseValue
        end
    end

    if ApplyingAuraStatOverlay[overlayKey] then
        return baseValue
    end

    local auraManager = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraManager or nil
    if auraManager and type(auraManager.ApplyStatModifiers) == "function" then
        ApplyingAuraStatOverlay[overlayKey] = true
        local ok, value = pcall(auraManager.ApplyStatModifiers, auraManager, unit, statRef, baseValue)
        ApplyingAuraStatOverlay[overlayKey] = nil
        if ok then
            return value
        end
    end

    return baseValue
end

function Lookup.GetResourceEntry(unit, resourceRef)
    if type(unit) ~= "table" or type(resourceRef) ~= "string" or resourceRef == "" then
        return nil
    end

    local cached = ensureUnitEntryCache(unit, "__rpeResourceEntryCache", "resources", "resourceRef")
    local entry = cached and cached.byRef and cached.byRef[resourceRef] or nil
    if entry then
        return entry, cached.indexByRef and cached.indexByRef[resourceRef] or nil
    end

    local resolvedUnit = type(unit.GetResolvedUnit) == "function" and unit:GetResolvedUnit() or nil
    if type(resolvedUnit) == "table" and resolvedUnit ~= unit then
        local resolvedCache = ensureUnitEntryCache(resolvedUnit, "__rpeResourceEntryCache", "resources", "resourceRef")
        local resolvedEntry = resolvedCache and resolvedCache.byRef and resolvedCache.byRef[resourceRef] or nil
        if resolvedEntry then
            return resolvedEntry, resolvedCache.indexByRef and resolvedCache.indexByRef[resourceRef] or nil
        end
    end

    return nil
end

return Lookup
