local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Loot = Addon.Internal.Loot or {}

local Loot = Addon.Internal.Loot
local Registry = Addon.Internal.Registry or {}
local Profile = Addon.Internal.Profile or {}

if Loot._diagnosticsInstalled == true then
    return
end

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function finiteNumber(value)
    local numeric = tonumber(value)
    if numeric == nil
        or numeric ~= numeric
        or numeric == math.huge
        or numeric == -math.huge
    then
        return nil
    end
    return numeric
end

local function copyTable(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[key] = copyTable(child, seen)
    end
    return copy
end

local function collectOrderedEntries(entries)
    local ordered = {}
    if type(entries) ~= "table" then
        return ordered
    end
    for key, entry in pairs(entries) do
        if type(key) == "number" then
            ordered[#ordered + 1] = {
                index = key,
                entry = entry,
            }
        end
    end
    table.sort(ordered, function(left, right)
        return left.index < right.index
    end)
    return ordered
end

local function findEntryDiagnostic(diagnosis, entryIndex)
    for index = 1, #(diagnosis and diagnosis.entries or {}) do
        local entry = diagnosis.entries[index]
        if tonumber(entry and entry.index) == tonumber(entryIndex) then
            return entry
        end
    end
    return nil
end

local function entryPrefix(entry, detail)
    local index = tonumber(entry and entry.index) or tonumber(detail and detail.entryIndex)
    local id = trim(entry and entry.id or detail and detail.entryId)
    local prefix = index and ("Entry %d"):format(index) or "Loot entry"
    if id ~= "" then
        prefix = prefix .. (" [%s]"):format(id)
    end
    return prefix
end

function Loot.FormatLootDiagnosticIssue(reason, detail, entry)
    local code = tostring(reason or "invalid-loot-table")
    local info = type(detail) == "table" and detail or {}
    local prefix = entryPrefix(entry, info)
    local reference = trim((entry and entry.ref) or info.ref)

    if code == "invalid-loot-table" then
        if info.field == "lootRef" then
            return "Select a Loot Table."
        end
        return "Loot Table data is invalid."
    end
    if code == "unknown-loot-table" then
        local lootRef = trim(info.lootRef)
        return lootRef ~= "" and ("Loot Table %s cannot be resolved."):format(lootRef)
            or "The selected Loot Table cannot be resolved."
    end
    if code == "invalid-draw-count" then
        return "Draw Count must be a positive integer."
    end
    if code == "no-loot-entries" then
        return "Loot Table has no entries."
    end
    if code == "duplicate-entry-id" then
        local id = trim(info.entryId or (entry and entry.id))
        if id ~= "" then
            return ("Duplicate Entry ID: %s%s"):format(
                id,
                tonumber(info.entryIndex) and (" (entry %d)"):format(tonumber(info.entryIndex)) or ""
            )
        end
        return prefix .. ": Entry ID is duplicated."
    end
    if code == "invalid-entry" then
        if info.field == "id" or info.reason == "blank-entry-id" then
            return prefix .. ": Entry ID is blank."
        end
        if info.field == "type" then
            return prefix .. ": Type must be Item or Currency."
        end
        if info.reason == "entry-not-table" then
            return prefix .. ": entry data is invalid."
        end
        return prefix .. ": entry data is invalid."
    end
    if code == "invalid-reward" then
        if info.field == "ref" then
            return prefix .. ": Reference is blank."
        end
        if info.field == "type" then
            return prefix .. ": Type must be Item or Currency."
        end
        return prefix .. ": reward data is invalid."
    end
    if code == "unknown-item" then
        return reference ~= ""
            and ("%s: Item reference %s cannot be resolved."):format(prefix, reference)
            or prefix .. ": Item reference cannot be resolved."
    end
    if code == "unknown-currency" then
        return reference ~= ""
            and ("%s: Currency reference %s cannot be resolved."):format(prefix, reference)
            or prefix .. ": Currency reference cannot be resolved."
    end
    if code == "invalid-weight" then
        return prefix .. ": Weight must be a finite number greater than 0."
    end
    if code == "invalid-quantity-range" then
        local minimum = tonumber(info.minQuantity)
        local maximum = tonumber(info.maxQuantity)
        if minimum and maximum and maximum < minimum then
            return prefix .. ": Maximum Quantity cannot be less than Minimum Quantity."
        end
        if minimum == nil or minimum < 1 or minimum ~= math.floor(minimum) then
            return prefix .. ": Minimum Quantity must be a positive integer."
        end
        if maximum == nil or maximum < 1 or maximum ~= math.floor(maximum) then
            return prefix .. ": Maximum Quantity must be a positive integer."
        end
        return prefix .. ": quantity range is invalid."
    end

    return prefix .. ": " .. code
end

local function resolveRewardName(rewardType, reference)
    if rewardType == "item" and type(Registry.ResolveItemReference) == "function" then
        local ok, _, item = pcall(Registry.ResolveItemReference, Registry, reference)
        if ok and type(item) == "table" and trim(item.name) ~= "" then
            return trim(item.name)
        end
    elseif rewardType == "currency" and type(Profile.ResolveCurrencyDefinition) == "function" then
        local ok, definition = pcall(Profile.ResolveCurrencyDefinition, reference)
        if ok and type(definition) == "table" and trim(definition.name) ~= "" then
            return trim(definition.name)
        end
    end
    return nil
end

local function diagnoseEntry(sourceIndex, entry)
    local row = {
        index = sourceIndex,
        id = type(entry) == "table" and trim(entry.id) or "",
        rewardType = type(entry) == "table" and string.lower(trim(entry.type)) or "",
        ref = type(entry) == "table" and trim(entry.ref) or "",
        resolvedName = nil,
        weight = type(entry) == "table" and entry.weight or nil,
        minQuantity = type(entry) == "table" and entry.minQuantity or nil,
        maxQuantity = type(entry) == "table" and entry.maxQuantity or nil,
        valid = false,
        reason = nil,
        detail = nil,
        message = nil,
    }

    if type(Loot.ValidateLootTable) ~= "function" then
        row.reason = "loot-resolver-unavailable"
        row.detail = { entryIndex = sourceIndex }
        row.message = entryPrefix(row, row.detail) .. ": Loot validator is unavailable."
        return row
    end

    local validated, reason, detail = Loot.ValidateLootTable({
        drawCount = 1,
        entries = { [sourceIndex] = entry },
    })
    if type(validated) == "table" and type(validated.entries) == "table" and type(validated.entries[1]) == "table" then
        local canonical = validated.entries[1]
        row.valid = true
        row.id = canonical.id
        row.rewardType = canonical.type
        row.ref = canonical.ref
        row.weight = canonical.weight
        row.minQuantity = canonical.minQuantity
        row.maxQuantity = canonical.maxQuantity
        row.resolvedName = resolveRewardName(canonical.type, canonical.ref)
        return row
    end

    row.reason = reason or "invalid-entry"
    row.detail = copyTable(type(detail) == "table" and detail or { entryIndex = sourceIndex })
    row.message = Loot.FormatLootDiagnosticIssue(row.reason, row.detail, row)
    return row
end

local function appendIssue(issues, reason, detail, entry)
    issues[#issues + 1] = {
        reason = reason,
        detail = copyTable(detail),
        entryIndex = entry and entry.index or (type(detail) == "table" and detail.entryIndex or nil),
        entryId = entry and entry.id or (type(detail) == "table" and detail.entryId or nil),
        message = Loot.FormatLootDiagnosticIssue(reason, detail, entry),
    }
end

function Loot.DiagnoseLootTable(loot)
    local diagnosis = {
        valid = false,
        reason = nil,
        detail = nil,
        message = nil,
        id = type(loot) == "table" and trim(loot.id) or "",
        name = type(loot) == "table" and trim(loot.name) or "",
        drawCount = type(loot) == "table" and loot.drawCount or nil,
        entryCount = 0,
        totalWeight = nil,
        entries = {},
        issues = {},
        legacyItemsPresent = type(loot) == "table" and type(loot.items) == "table" and next(loot.items) ~= nil,
    }

    if type(Loot.ValidateLootTable) ~= "function" then
        diagnosis.reason = "loot-resolver-unavailable"
        diagnosis.detail = { reason = "validator-unavailable" }
        diagnosis.message = "Loot validator is unavailable."
        appendIssue(diagnosis.issues, diagnosis.reason, diagnosis.detail, nil)
        diagnosis.issues[#diagnosis.issues].message = diagnosis.message
        return diagnosis
    end

    local validated, reason, detail = Loot.ValidateLootTable(loot)
    diagnosis.valid = type(validated) == "table"
    if diagnosis.valid then
        diagnosis.reason = nil
        diagnosis.detail = nil
        diagnosis.drawCount = validated.drawCount
        diagnosis.totalWeight = validated.totalWeight
    else
        diagnosis.reason = reason or "invalid-loot-table"
        diagnosis.detail = copyTable(type(detail) == "table" and detail or {})
    end

    local ordered = collectOrderedEntries(type(loot) == "table" and loot.entries or nil)
    diagnosis.entryCount = #ordered
    local rawTotalWeight = 0
    local hasFiniteWeights = #ordered > 0
    for position = 1, #ordered do
        local source = ordered[position]
        local row = diagnoseEntry(source.index, source.entry)
        diagnosis.entries[#diagnosis.entries + 1] = row
        local weight = type(source.entry) == "table" and finiteNumber(source.entry.weight) or nil
        if weight == nil then
            hasFiniteWeights = false
        else
            rawTotalWeight = rawTotalWeight + weight
        end
    end
    if diagnosis.totalWeight == nil and hasFiniteWeights then
        diagnosis.totalWeight = rawTotalWeight
    end

    -- Per-entry validation above uses the canonical validator on each row. Apply
    -- the canonical cross-row duplicate-ID constraint without changing the full
    -- table result, whose reason/detail came directly from ValidateLootTable.
    local seenIds = {}
    for index = 1, #diagnosis.entries do
        local row = diagnosis.entries[index]
        if row.id ~= "" then
            if seenIds[row.id] then
                row.valid = false
                row.reason = "duplicate-entry-id"
                row.detail = {
                    entryIndex = row.index,
                    entryId = row.id,
                }
                row.message = Loot.FormatLootDiagnosticIssue(row.reason, row.detail, row)
            else
                seenIds[row.id] = true
            end
        end
    end

    local topLevelReason = diagnosis.reason
    if topLevelReason == "invalid-loot-table"
        or topLevelReason == "invalid-draw-count"
        or topLevelReason == "no-loot-entries"
        or topLevelReason == "loot-resolver-unavailable"
    then
        appendIssue(diagnosis.issues, topLevelReason, diagnosis.detail, nil)
    end
    for index = 1, #diagnosis.entries do
        local row = diagnosis.entries[index]
        if row.valid ~= true then
            appendIssue(diagnosis.issues, row.reason or "invalid-entry", row.detail, row)
        end
    end

    if not diagnosis.valid then
        local entry = findEntryDiagnostic(diagnosis, diagnosis.detail and diagnosis.detail.entryIndex)
        diagnosis.message = Loot.FormatLootDiagnosticIssue(diagnosis.reason, diagnosis.detail, entry)
    end
    return diagnosis
end

function Loot.DiagnoseLootReference(lootRef)
    local normalizedRef = trim(lootRef)
    if normalizedRef == "" then
        local diagnosis = Loot.DiagnoseLootTable(nil)
        diagnosis.reason = "invalid-loot-table"
        diagnosis.detail = { field = "lootRef" }
        diagnosis.message = Loot.FormatLootDiagnosticIssue(diagnosis.reason, diagnosis.detail, nil)
        diagnosis.lootRef = normalizedRef
        diagnosis.issues = {
            {
                reason = diagnosis.reason,
                detail = copyTable(diagnosis.detail),
                message = diagnosis.message,
            },
        }
        return diagnosis
    end

    if type(Registry.ResolveLootReference) ~= "function" then
        return {
            valid = false,
            reason = "unknown-loot-table",
            detail = { lootRef = normalizedRef, reason = "loot-api-unavailable" },
            message = ("Loot Table %s cannot be resolved."):format(normalizedRef),
            lootRef = normalizedRef,
            id = "",
            name = "",
            drawCount = nil,
            entryCount = 0,
            totalWeight = nil,
            entries = {},
            issues = {},
            legacyItemsPresent = false,
        }
    end

    local ok, dataset, loot = pcall(Registry.ResolveLootReference, Registry, normalizedRef)
    if not ok or type(dataset) ~= "table" or type(loot) ~= "table" then
        local diagnosis = {
            valid = false,
            reason = "unknown-loot-table",
            detail = { lootRef = normalizedRef },
            lootRef = normalizedRef,
            datasetId = type(dataset) == "table" and trim(dataset.id) or "",
            id = "",
            name = "",
            drawCount = nil,
            entryCount = 0,
            totalWeight = nil,
            entries = {},
            issues = {},
            legacyItemsPresent = false,
        }
        diagnosis.message = Loot.FormatLootDiagnosticIssue(diagnosis.reason, diagnosis.detail, nil)
        appendIssue(diagnosis.issues, diagnosis.reason, diagnosis.detail, nil)
        return diagnosis
    end

    local diagnosis = Loot.DiagnoseLootTable(loot)
    diagnosis.lootRef = normalizedRef
    diagnosis.datasetId = trim(dataset.id)
    return diagnosis
end

Loot._diagnosticsInstalled = true
