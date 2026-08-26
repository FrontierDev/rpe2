local _, Addon = ...

Addon = Addon or {}
Addon.Internal = Addon.Internal or {}

-- Runtime revisions and transactions are intentionally recreated on load. They
-- are session state and must never become SavedVariables.
local Runtime = {}
Addon.Internal.Runtime = Runtime

local unpackValues = unpack or table.unpack

local function nowMilliseconds()
    if type(debugprofilestop) == "function" then
        return tonumber(debugprofilestop()) or 0
    end
    if type(GetTimePreciseSec) == "function" then
        return (tonumber(GetTimePreciseSec()) or 0) * 1000
    end
    if type(GetTime) == "function" then
        return (tonumber(GetTime()) or 0) * 1000
    end
    return 0
end

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = type(child) == "table" and copy(child) or child
    end
    return result
end

local function key(value)
    return value == nil and nil or tostring(value)
end

local function put(set, value, storedValue)
    if type(set) == "table" and value ~= nil then
        set[key(value)] = storedValue == nil and true or storedValue
    end
end

local function putMany(set, values)
    if values == nil then
        return
    end
    if type(values) ~= "table" then
        put(set, values)
        return
    end

    for itemKey, itemValue in pairs(values) do
        if type(itemKey) == "number" and itemValue ~= true and itemValue ~= false then
            put(set, itemValue)
        elseif itemValue ~= false and itemValue ~= nil then
            put(set, itemKey, itemValue == true and true or itemValue)
        end
    end
end

local function putGain(gains, gainKey, amount)
    if type(gains) ~= "table" or gainKey == nil then
        return
    end
    local normalizedKey = key(gainKey)
    local numericAmount = tonumber(amount)
    if numericAmount == nil then
        gains[normalizedKey] = true
        return
    end
    gains[normalizedKey] = (tonumber(gains[normalizedKey]) or 0) + numericAmount
end

local function putNested(nested, eventId, unitIds)
    if type(nested) ~= "table" or eventId == nil then
        return
    end
    local eventKey = key(eventId)
    nested[eventKey] = nested[eventKey] or {}
    putMany(nested[eventKey], unitIds)
end

local function putNestedMany(nested, values, defaultEventId)
    if values == nil then
        return
    end
    if defaultEventId ~= nil then
        putNested(nested, defaultEventId, values)
        return
    end
    if type(values) ~= "table" then
        return
    end
    for eventId, unitIds in pairs(values) do
        putNested(nested, eventId, unitIds)
    end
end

local function bucket(changeSet, name)
    local result = changeSet[name]
    if type(result) ~= "table" then
        result = {}
        changeSet[name] = result
    end
    return result
end

local function markBucket(bucketValue)
    bucketValue.changed = true
end

local function normalizeScope(scope)
    if type(scope) ~= "string" then
        return nil
    end
    local value = string.lower(scope)
    value = string.gsub(value, "[%s_/-]+", ".")
    value = string.gsub(value, "%.+", ".")
    value = string.gsub(value, "^%.", "")
    value = string.gsub(value, "%.+$", "")

    local aliases = {
        currency = "currencies",
        currencies = "currencies",
        inventory = "inventory",
        inventories = "inventory",
        achievement = "achievements",
        achievements = "achievements",
        event = "event",
        events = "event",
        ui = "ui",
        equipment = "profile.equipment",
        stats = "profile.stats",
        resources = "profile.resources",
        skills = "profile.skills",
        units = "event.units",
        auras = "event.auras",
        cooldowns = "event.cooldowns",
        spellcasts = "event.spellcasts",
        structural = "event.structural",
        profiletabs = "ui.profileTabs",
        inventorypages = "ui.inventoryPages",
        actionbarslots = "ui.actionBarSlots",
        eventportraits = "ui.eventPortraits",
        targeting = "ui.targeting",
    }
    if aliases[value] then
        return aliases[value]
    end

    local extraAliases = {
        ["event.auraunits"] = "event.auras",
        ["event.cooldownunits"] = "event.cooldowns",
        ["event.spellcastunits"] = "event.spellcasts",
        ["ui.profiletabs"] = "ui.profileTabs",
        ["ui.inventorypages"] = "ui.inventoryPages",
        ["ui.actionbarslots"] = "ui.actionBarSlots",
        ["ui.eventportraits"] = "ui.eventPortraits",
        ["ui.profile.tabs"] = "ui.profileTabs",
        ["ui.inventory.pages"] = "ui.inventoryPages",
        ["ui.action.bar.slots"] = "ui.actionBarSlots",
        ["ui.event.portraits"] = "ui.eventPortraits",
    }
    return extraAliases[value] or value
end

local function markInventory(result, detail)
    markBucket(result)
    result.mutationCount = (tonumber(result.mutationCount) or 0) + 1
    if type(detail) ~= "table" then
        if detail ~= nil then
            result.slots = result.slots or {}
            put(result.slots, detail)
        end
        return
    end

    if detail.mutationCount ~= nil then
        result.mutationCount = (tonumber(result.mutationCount) or 0)
            + math.max(0, tonumber(detail.mutationCount) or 0) - 1
    end
    if detail.slot ~= nil or detail.slotId ~= nil then
        result.slots = result.slots or {}
        put(result.slots, detail.slot or detail.slotId)
    end
    if detail.slots ~= nil then
        result.slots = result.slots or {}
        putMany(result.slots, detail.slots)
    end
    if detail.addedRef ~= nil or detail.addedRefs ~= nil then
        result.addedRefs = result.addedRefs or {}
        put(result.addedRefs, detail.addedRef)
        putMany(result.addedRefs, detail.addedRefs)
    end
    if detail.removedRef ~= nil or detail.removedRefs ~= nil then
        result.removedRefs = result.removedRefs or {}
        put(result.removedRefs, detail.removedRef)
        putMany(result.removedRefs, detail.removedRefs)
    end
end

local function markCurrencies(result, detail)
    markBucket(result)
    if type(detail) ~= "table" then
        if detail ~= nil then
            result.keys = result.keys or {}
            put(result.keys, detail)
        end
        return
    end

    local currencyKey = detail.key or detail.currencyKey or detail.ref
    if currencyKey ~= nil then
        result.keys = result.keys or {}
        put(result.keys, currencyKey)
    end
    if detail.keys ~= nil then
        result.keys = result.keys or {}
        putMany(result.keys, detail.keys)
    end
    if detail.gain ~= nil and currencyKey ~= nil then
        result.gains = result.gains or {}
        putGain(result.gains, currencyKey, detail.gain)
    end
    if detail.gains ~= nil then
        result.gains = result.gains or {}
        for gainKey, amount in pairs(detail.gains) do
            putGain(result.gains, gainKey, amount)
        end
    end
end

local function markAchievements(result, detail)
    markBucket(result)
    if type(detail) ~= "table" then
        if detail ~= nil then
            result.refs = result.refs or {}
            put(result.refs, detail)
        end
        return
    end

    local achievementRef = detail.ref or detail.achievementRef
    if achievementRef ~= nil then
        result.refs = result.refs or {}
        put(result.refs, achievementRef)
    end
    if detail.refs ~= nil then
        result.refs = result.refs or {}
        putMany(result.refs, detail.refs)
    end
    local completedRef = detail.completedRef or detail.completedAchievementRef
    if completedRef ~= nil then
        result.completedRefs = result.completedRefs or {}
        put(result.completedRefs, completedRef)
    end
    if detail.completedRefs ~= nil then
        result.completedRefs = result.completedRefs or {}
        putMany(result.completedRefs, detail.completedRefs)
    end
end

local function markProfile(result, field, detail)
    markBucket(result)
    if field == nil then
        if type(detail) == "table" then
            if detail.equipment ~= nil then result.equipment = true end
            if detail.stats ~= nil then result.stats = true end
            if detail.resources ~= nil then result.resources = true end
            if detail.skills ~= nil then
                result.skills = result.skills or {}
                putMany(result.skills, detail.skills)
            end
        elseif type(detail) == "string" then
            local nestedScope = normalizeScope("profile." .. detail)
            if string.sub(nestedScope or "", 1, 8) == "profile." then
                markProfile(result, string.sub(nestedScope, 9), true)
            end
        end
        return
    end

    if field == "equipment" or field == "stats" or field == "resources" then
        result[field] = true
    elseif field == "skills" then
        result.skills = result.skills or {}
        if detail == nil or type(detail) == "boolean" then
            result.skills.__changed = true
        else
            putMany(result.skills, detail)
        end
    end
end

local function markEvent(result, field, detail)
    markBucket(result)
    result.eventIds = result.eventIds or {}

    if field == "structural" then
        result.structural = true
        if type(detail) == "table" then
            putMany(result.eventIds, detail.eventIds or detail.eventId)
        elseif detail ~= nil and type(detail) ~= "boolean" then
            put(result.eventIds, detail)
        end
        return
    end
    if type(detail) ~= "table" then
        if detail ~= nil then
            put(result.eventIds, detail)
            local fieldMap = {
                units = "units",
                auras = "auraUnits",
                cooldowns = "cooldownUnits",
                spellcasts = "spellcastUnits",
            }
            local nestedField = fieldMap[field]
            if nestedField then
                result[nestedField] = result[nestedField] or {}
                result[nestedField][key(detail)] = result[nestedField][key(detail)] or {}
            end
        end
        return
    end

    putMany(result.eventIds, detail.eventIds or detail.eventId)
    if detail.eventId ~= nil then put(result.eventIds, detail.eventId) end
    if detail.structural then result.structural = true end

    local actualField = field
    if actualField == nil then
        if detail.units ~= nil or detail.unitId ~= nil then
            actualField = "units"
        elseif detail.auras ~= nil or detail.auraUnits ~= nil then
            actualField = "auras"
        elseif detail.cooldowns ~= nil or detail.cooldownUnits ~= nil then
            actualField = "cooldowns"
        elseif detail.spellcasts ~= nil or detail.spellcastUnits ~= nil then
            actualField = "spellcasts"
        end
    end

    local nestedField, values
    if actualField == "units" then
        nestedField, values = "units", detail.units
    elseif actualField == "auras" then
        nestedField, values = "auraUnits", detail.auras or detail.auraUnits
    elseif actualField == "cooldowns" then
        nestedField, values = "cooldownUnits", detail.cooldowns or detail.cooldownUnits
    elseif actualField == "spellcasts" then
        nestedField, values = "spellcastUnits", detail.spellcasts or detail.spellcastUnits
    end
    if nestedField then
        result[nestedField] = result[nestedField] or {}
        if detail.unitId ~= nil then
            putNested(result[nestedField], detail.eventId, detail.unitId)
        end
        putNestedMany(result[nestedField], values, detail.eventId)
    end
end

local function markUI(result, field, detail)
    if field == "targeting" then
        result.targeting = true
        return
    end
    if field == "structural" then
        result.structural = true
        return
    end
    local actualField = field
    if actualField == nil and type(detail) == "table" then
        if detail.targeting ~= nil then result.targeting = true end
        if detail.structural ~= nil then result.structural = true end
        for _, possible in ipairs({ "profileTabs", "inventoryPages", "actionBarSlots", "eventPortraits" }) do
            if detail[possible] ~= nil then
                actualField = possible
                detail = detail[possible]
                break
            end
        end
    elseif actualField == nil and type(detail) == "string" then
        local nestedScope = normalizeScope("ui." .. detail)
        if nestedScope == "ui.targeting" then
            result.targeting = true
            return
        elseif nestedScope == "ui.structural" then
            result.structural = true
            return
        elseif string.sub(nestedScope or "", 1, 3) == "ui." then
            actualField = string.sub(nestedScope, 4)
        end
    end
    if actualField == nil then
        result.changed = true
        return
    end
    result[actualField] = result[actualField] or {}
    putMany(result[actualField], detail)
end

local function markChangedInternal(changeSet, scope, detail)
    local normalized = normalizeScope(scope)
    if normalized == nil or normalized == "" then
        error("Runtime.MarkChanged(scope, detail) requires a non-empty scope.", 3)
    end

    if normalized == "inventory" then
        markInventory(bucket(changeSet, "inventory"), detail)
    elseif normalized == "currencies" then
        markCurrencies(bucket(changeSet, "currencies"), detail)
    elseif normalized == "achievements" then
        markAchievements(bucket(changeSet, "achievements"), detail)
    elseif normalized == "profile" then
        markProfile(bucket(changeSet, "profile"), nil, detail)
    elseif string.sub(normalized, 1, 8) == "profile." then
        markProfile(bucket(changeSet, "profile"), string.sub(normalized, 9), detail)
    elseif normalized == "event" then
        markEvent(bucket(changeSet, "event"), nil, detail)
    elseif string.sub(normalized, 1, 6) == "event." then
        markEvent(bucket(changeSet, "event"), string.sub(normalized, 7), detail)
    elseif normalized == "ui" then
        markUI(bucket(changeSet, "ui"), nil, detail)
    elseif string.sub(normalized, 1, 3) == "ui." then
        markUI(bucket(changeSet, "ui"), string.sub(normalized, 4), detail)
    else
        error(("Runtime.MarkChanged() does not recognize scope '%s'."):format(tostring(scope)), 3)
    end
    return changeSet
end

local keyedRevisionDomains = {
    AuraRevisionByEventId = true,
    CooldownRevisionByEventId = true,
    SpellcastRevisionByEventId = true,
}

local revisionValues = {}
local revisionBumpCounts = {}
for _, domain in ipairs({
    "ProfileStateRevision", "CurrencyRevision", "AchievementRevision",
    "InventoryRevision", "EquipmentRevision", "SkillRevision",
    "ActionBarBindingRevision", "ResolvedProfileRevision", "EventRuntimeRevision",
}) do
    revisionValues[domain] = 0
    revisionBumpCounts[domain] = 0
end
for domain in pairs(keyedRevisionDomains) do
    revisionValues[domain] = {}
    revisionBumpCounts[domain] = {}
end

Runtime.RevisionDomains = {
    "ConfigurationRevision", "ProfileStateRevision", "CurrencyRevision",
    "AchievementRevision", "InventoryRevision", "EquipmentRevision", "SkillRevision",
    "ActionBarBindingRevision", "ResolvedProfileRevision", "EventRuntimeRevision",
    "AuraRevisionByEventId", "CooldownRevisionByEventId", "SpellcastRevisionByEventId",
}
Runtime.KeyedRevisionDomains = copy(keyedRevisionDomains)

local revisionAliases = {
    configuration = "ConfigurationRevision", configurationrevision = "ConfigurationRevision",
    profilestate = "ProfileStateRevision", profilestaterevision = "ProfileStateRevision",
    currency = "CurrencyRevision", currencyrevision = "CurrencyRevision",
    achievement = "AchievementRevision", achievementrevision = "AchievementRevision",
    inventory = "InventoryRevision", inventoryrevision = "InventoryRevision",
    equipment = "EquipmentRevision", equipmentrevision = "EquipmentRevision",
    skill = "SkillRevision", skillrevision = "SkillRevision",
    actionbarbinding = "ActionBarBindingRevision", actionbarbindingrevision = "ActionBarBindingRevision",
    resolvedprofile = "ResolvedProfileRevision", resolvedprofilerevision = "ResolvedProfileRevision",
    eventruntime = "EventRuntimeRevision", eventruntimerevision = "EventRuntimeRevision",
    aurarevisionbyeventid = "AuraRevisionByEventId",
    cooldownrevisionbyeventid = "CooldownRevisionByEventId",
    spellcastrevisionbyeventid = "SpellcastRevisionByEventId",
}

local function normalizeRevisionDomain(domain)
    if type(domain) ~= "string" then return nil end
    if domain == "ConfigurationRevision" or revisionValues[domain] ~= nil then return domain end
    local normalized = string.lower(domain)
    normalized = string.gsub(normalized, "[%s_/-]+", "")
    return revisionAliases[normalized]
end

local function getStoredRevision(domain, revisionKey)
    if domain == "ConfigurationRevision" then
        return math.max(0, math.floor(tonumber(Addon.Internal.ConfigurationRevision) or 0))
    end
    if keyedRevisionDomains[domain] then
        local normalizedKey = key(revisionKey)
        return normalizedKey and math.max(0, math.floor(tonumber(revisionValues[domain][normalizedKey]) or 0)) or 0
    end
    return math.max(0, math.floor(tonumber(revisionValues[domain]) or 0))
end

local function requireRevisionDomain(domain, operation)
    local normalized = normalizeRevisionDomain(domain)
    if normalized == nil then
        error(("Runtime.%s() does not recognize revision domain '%s'."):format(operation, tostring(domain)), 3)
    end
    return normalized
end

local function requestRevision(transaction, domain, revisionKey)
    transaction.hasChanges = true
    if domain == "ConfigurationRevision" then
        error("Runtime transactions cannot bump ConfigurationRevision; the configuration system owns it.", 3)
    end
    if keyedRevisionDomains[domain] then
        local normalizedKey = key(revisionKey)
        if normalizedKey == nil then
            error(("Revision domain '%s' requires an event ID."):format(domain), 3)
        end
        transaction.revisionRequests[domain] = transaction.revisionRequests[domain] or {}
        transaction.revisionRequests[domain][normalizedKey] = true
        return getStoredRevision(domain, normalizedKey) + 1
    end
    transaction.revisionRequests[domain] = true
    return getStoredRevision(domain) + 1
end

local function sortedKeys(values)
    local result = {}
    for value in pairs(values or {}) do result[#result + 1] = value end
    table.sort(result, function(left, right)
        if type(left) == "number" and type(right) == "number" then
            return left < right
        end
        return tostring(left) < tostring(right)
    end)
    return result
end

local function eventIdsFromBucket(eventBucket)
    local ids = {}
    if type(eventBucket) ~= "table" then return ids end
    for eventId in pairs(eventBucket.eventIds or {}) do ids[key(eventId)] = true end
    for _, field in ipairs({ "units", "auraUnits", "cooldownUnits", "spellcastUnits" }) do
        for eventId in pairs(eventBucket[field] or {}) do ids[key(eventId)] = true end
    end
    return ids
end

local function requestChangesRevisions(transaction)
    local changes = transaction.changeSet
    if changes.inventory then
        requestRevision(transaction, "InventoryRevision")
        requestRevision(transaction, "ProfileStateRevision")
    end
    if changes.currencies then
        requestRevision(transaction, "CurrencyRevision")
        requestRevision(transaction, "ProfileStateRevision")
    end
    if changes.achievements then
        requestRevision(transaction, "AchievementRevision")
        requestRevision(transaction, "ProfileStateRevision")
    end

    local profile = changes.profile
    if type(profile) == "table" then
        if profile.equipment then
            requestRevision(transaction, "EquipmentRevision")
            requestRevision(transaction, "ResolvedProfileRevision")
        end
        if profile.stats or profile.resources or profile.changed then
            requestRevision(transaction, "ProfileStateRevision")
        end
        if profile.skills then
            requestRevision(transaction, "SkillRevision")
            requestRevision(transaction, "ProfileStateRevision")
        end
    end

    local event = changes.event
    if type(event) == "table" then
        requestRevision(transaction, "EventRuntimeRevision")
        local ids = eventIdsFromBucket(event)
        for _, eventId in ipairs(sortedKeys(ids)) do
            if event.auraUnits and event.auraUnits[eventId] then
                requestRevision(transaction, "AuraRevisionByEventId", eventId)
            end
            if event.cooldownUnits and event.cooldownUnits[eventId] then
                requestRevision(transaction, "CooldownRevisionByEventId", eventId)
            end
            if event.spellcastUnits and event.spellcastUnits[eventId] then
                requestRevision(transaction, "SpellcastRevisionByEventId", eventId)
            end
        end
    end

    local ui = changes.ui
    if type(ui) == "table" and (ui.actionBarSlots or ui.structural) then
        requestRevision(transaction, "ActionBarBindingRevision")
    end
end

local function bumpStoredRevision(domain, revisionKey)
    if keyedRevisionDomains[domain] then
        local normalizedKey = key(revisionKey)
        local value = math.max(0, math.floor(tonumber(revisionValues[domain][normalizedKey]) or 0)) + 1
        revisionValues[domain][normalizedKey] = value
        revisionBumpCounts[domain][normalizedKey] = (tonumber(revisionBumpCounts[domain][normalizedKey]) or 0) + 1
        return value
    end
    local value = math.max(0, math.floor(tonumber(revisionValues[domain]) or 0)) + 1
    revisionValues[domain] = value
    revisionBumpCounts[domain] = (tonumber(revisionBumpCounts[domain]) or 0) + 1
    return value
end

local function commitRevisions(transaction)
    requestChangesRevisions(transaction)
    local revisions = {}
    for _, domain in ipairs(sortedKeys(transaction.revisionRequests)) do
        local request = transaction.revisionRequests[domain]
        if keyedRevisionDomains[domain] then
            local values = {}
            for _, revisionKey in ipairs(sortedKeys(request)) do
                values[revisionKey] = bumpStoredRevision(domain, revisionKey)
            end
            if next(values) ~= nil then revisions[domain] = values end
        elseif request == true then
            revisions[domain] = bumpStoredRevision(domain)
        end
    end
    return next(revisions) ~= nil and revisions or nil
end

local function mergeValues(target, source)
    if target == source then
        return target
    end
    for field, value in pairs(source or {}) do
        if field == "mutationCount" then
            target[field] = (tonumber(target[field]) or 0) + (tonumber(value) or 0)
        elseif type(value) == "table" then
            target[field] = target[field] or {}
            mergeValues(target[field], value)
        elseif type(value) == "boolean" then
            target[field] = target[field] == true or value
        elseif target[field] == nil then
            target[field] = value
        elseif type(target[field]) == "number" and type(value) == "number" then
            target[field] = target[field] + value
        end
    end
    return target
end

local function scopeCounts(changeSet)
    local counts = {}
    for _, scope in ipairs({ "inventory", "currencies", "achievements", "profile", "event", "ui" }) do
        local value = changeSet[scope]
        if type(value) == "table" then
            local count = 1
            for field, child in pairs(value) do
                if field ~= "changed" then
                    count = count + 1
                    if type(child) == "table" then
                        for _ in pairs(child) do count = count + 1 end
                    end
                end
            end
            counts[scope] = count
        end
    end
    return counts
end

local function captureArguments(...)
    local values, count = {}, select("#", ...)
    for index = 1, count do values[index] = select(index, ...) end
    return values, count
end

local function reportError(message, ...)
    local debugTable = Addon.Debug
    if type(debugTable) == "table" and type(debugTable.Error) == "function" then
        pcall(debugTable.Error, message, ...)
    end
end

local function newTransaction(reason, options)
    Runtime._nextTransactionId = Runtime._nextTransactionId + 1
    local transaction = {
        id = Runtime._nextTransactionId,
        reason = tostring(reason or "runtime-mutation"),
        options = type(options) == "table" and options or {},
        depth = 1,
        status = "active",
        startedAtMs = nowMilliseconds(),
        changeSet = {},
        revisionRequests = {},
        mutationQueue = {},
        mutationHead = 1,
        mutationTail = 0,
        mutationCount = 0,
        afterCommitQueue = {},
    }
    transaction.ChangeSet = transaction.changeSet
    transaction.changes = transaction.changeSet
    return transaction
end

local function beginInternal(reason, options)
    if Runtime._currentTransaction then
        local transaction = Runtime._currentTransaction
        transaction.depth = transaction.depth + 1
        Runtime._transactionDepth = transaction.depth
        transaction.nestedReasons = transaction.nestedReasons or {}
        if reason ~= nil then transaction.nestedReasons[#transaction.nestedReasons + 1] = tostring(reason) end
        return transaction
    end
    local transaction = newTransaction(reason, options)
    Runtime._currentTransaction = transaction
    Runtime._transactionDepth = 1
    return transaction
end

local function failInternal(transaction, err)
    if transaction.status == "failed" then return end
    transaction.status = "failed"
    transaction.error = err
    transaction.depth = 0
    transaction.committing = false
    Runtime._transactionDepth = 0
    if Runtime._currentTransaction == transaction then Runtime._currentTransaction = nil end
    reportError("Runtime transaction '%s' (#%d) failed: %s", transaction.reason, transaction.id, tostring(err))
end

local function processorSnapshot(kind)
    local handlers = Runtime._beforeCommitProcessors[key(kind) or ""]
    if type(handlers) ~= "table" then return nil end
    local result = {}
    for _, token in ipairs(sortedKeys(handlers)) do result[#result + 1] = handlers[token] end
    return result
end

local function drainMutations(transaction)
    while transaction.mutationHead <= transaction.mutationTail do
        local mutation = transaction.mutationQueue[transaction.mutationHead]
        transaction.mutationQueue[transaction.mutationHead] = nil
        transaction.mutationHead = transaction.mutationHead + 1
        mutation.processed = true
        local handlers = processorSnapshot(mutation.kind)
        for index = 1, #(handlers or {}) do
            local ok, err = pcall(handlers[index], mutation.payload, transaction, mutation.kind, mutation)
            if not ok then return false, err end
        end
    end
    return true
end

local function invokeListeners(transaction, summary)
    if not transaction.hasChanges then return end
    local listeners = {}
    for _, token in ipairs(sortedKeys(Runtime._postCommitListeners)) do
        listeners[#listeners + 1] = { token = token, handler = Runtime._postCommitListeners[token] }
    end
    for index = 1, #listeners do
        local listener = listeners[index]
        local ok, err = pcall(listener.handler, transaction.changeSet, summary)
        if not ok then
            reportError("Runtime post-commit listener %s failed for transaction '%s' (#%d): %s", listener.token, transaction.reason, transaction.id, tostring(err))
        end
    end
end

local function invokeAfterCommit(transaction, summary)
    for index = 1, #transaction.afterCommitQueue do
        local callback = transaction.afterCommitQueue[index]
        local ok, err = pcall(function()
            callback.fn(unpackValues(callback.args, 1, callback.argCount))
        end)
        if not ok then
            reportError("Runtime after-commit callback failed for transaction '%s' (#%d): %s", transaction.reason, transaction.id, tostring(err))
        end
    end
end

local function commitInternal(transaction)
    if type(transaction) ~= "table" or transaction.status ~= "active" then
        return false, type(transaction) == "table" and transaction.error or nil
    end
    if Runtime._currentTransaction ~= transaction then
        return false, "Runtime transaction is not current."
    end

    transaction.depth = math.max(0, transaction.depth - 1)
    Runtime._transactionDepth = transaction.depth
    if transaction.depth > 0 then return false, nil end

    transaction.depth = 1
    transaction.committing = true
    Runtime._transactionDepth = 1
    local queueOk, queueError = drainMutations(transaction)
    if not queueOk then
        failInternal(transaction, queueError)
        return false, queueError
    end

    local revisionsOk, revisions = pcall(commitRevisions, transaction)
    if not revisionsOk then
        failInternal(transaction, revisions)
        return false, revisions
    end
    if revisions then transaction.changeSet.revisions = revisions end

    transaction.hasChanges = transaction.hasChanges or next(transaction.changeSet) ~= nil
    transaction.status = "committed"
    transaction.committedAtMs = nowMilliseconds()
    transaction.depth = 0
    transaction.committing = false
    Runtime._transactionDepth = 0
    Runtime._currentTransaction = nil

    local summary = {
        id = transaction.id,
        reason = transaction.reason,
        depth = 1,
        status = transaction.status,
        startedAtMs = transaction.startedAtMs,
        committedAtMs = transaction.committedAtMs,
        elapsedMs = math.max(0, transaction.committedAtMs - transaction.startedAtMs),
        mutationEvents = transaction.mutationCount or 0,
        changeScopes = scopeCounts(transaction.changeSet),
        revisionBumps = copy(revisions or {}),
    }
    summary.scopeCounts = summary.changeScopes
    Runtime._lastCommittedSummary = summary
    invokeListeners(transaction, summary)
    invokeAfterCommit(transaction, summary)
    return true, transaction.changeSet
end

local function implicitMutation(reason, operation)
    local transaction = beginInternal(reason, { implicit = true })
    local ok, result = pcall(operation, transaction)
    if not ok then
        failInternal(transaction, result)
        error(result, 0)
    end
    local committed, commitError = commitInternal(transaction)
    if transaction.status == "failed" then error(commitError or transaction.error, 0) end
    if commitError and not committed then error(commitError, 0) end
    return result
end

Runtime._nextTransactionId = 0
Runtime._transactionDepth = 0
Runtime._currentTransaction = nil
Runtime._lastCommittedSummary = nil
Runtime._beforeCommitProcessors = {}
Runtime._postCommitListeners = {}
Runtime._nextListenerId = 0

function Runtime.GetRevision(selfOrDomain, domainOrKey, maybeKey)
    local domain, revisionKey = selfOrDomain, domainOrKey
    if selfOrDomain == Runtime then domain, revisionKey = domainOrKey, maybeKey end
    return getStoredRevision(requireRevisionDomain(domain, "GetRevision"), revisionKey)
end

function Runtime.BumpRevision(selfOrDomain, domainOrKey, maybeKey)
    local domain, revisionKey = selfOrDomain, domainOrKey
    if selfOrDomain == Runtime then domain, revisionKey = domainOrKey, maybeKey end
    local normalized = requireRevisionDomain(domain, "BumpRevision")
    if normalized == "ConfigurationRevision" then
        error("Runtime.BumpRevision() cannot mutate ConfigurationRevision; the configuration system owns it.", 2)
    end
    if Runtime._currentTransaction then
        Runtime._currentTransaction.hasChanges = true
        return requestRevision(Runtime._currentTransaction, normalized, revisionKey)
    end
    implicitMutation("revision:" .. normalized, function(transaction)
        requestRevision(transaction, normalized, revisionKey)
    end)
    return getStoredRevision(normalized, revisionKey)
end

function Runtime.GetRevisionTuple(selfOrFirst, ...)
    local specifications = {}
    if selfOrFirst == Runtime then
        for index = 1, select("#", ...) do specifications[index] = select(index, ...) end
    else
        specifications[1] = selfOrFirst
        for index = 1, select("#", ...) do specifications[index + 1] = select(index, ...) end
    end
    if #specifications == 1
        and type(specifications[1]) == "table"
        and specifications[1].domain == nil
        and specifications[1].key == nil
    then
        specifications = specifications[1]
    end
    local values = {}
    for index, specification in ipairs(specifications) do
        local domain, revisionKey = specification, nil
        if type(specification) == "table" then
            domain, revisionKey = specification.domain or specification[1], specification.key or specification[2]
        end
        values[index] = Runtime.GetRevision(domain, revisionKey)
    end
    return unpackValues(values, 1, #values)
end

function Runtime.BeginTransaction(selfOrReason, reasonOrOptions, maybeOptions)
    if selfOrReason == Runtime then return beginInternal(reasonOrOptions, maybeOptions) end
    return beginInternal(selfOrReason, reasonOrOptions)
end

function Runtime.GetCurrentTransaction()
    return Runtime._currentTransaction
end

function Runtime.MarkChanged(selfOrScope, scopeOrDetail, maybeDetail)
    local scope, detail = selfOrScope, scopeOrDetail
    if selfOrScope == Runtime then scope, detail = scopeOrDetail, maybeDetail end
    if type(scope) == "string" and detail == nil then
        local shorthandScope, shorthandDetail = string.match(scope, "^([^:]+):(.+)$")
        if shorthandScope then scope, detail = shorthandScope, shorthandDetail end
    end
    if Runtime._currentTransaction then
        Runtime._currentTransaction.hasChanges = true
        return markChangedInternal(Runtime._currentTransaction.changeSet, scope, detail)
    end
    return implicitMutation("change:" .. tostring(scope or "unknown"), function(transaction)
        transaction.hasChanges = true
        return markChangedInternal(transaction.changeSet, scope, detail)
    end)
end

function Runtime.MarkKey(selfOrScope, scopeOrKey, maybeKey, maybeValue)
    local scope, itemKey, value = selfOrScope, scopeOrKey, maybeKey
    if selfOrScope == Runtime then scope, itemKey, value = scopeOrKey, maybeKey, maybeValue end
    local normalized = normalizeScope(scope)
    if normalized == "currencies" then
        return Runtime.MarkChanged(scope, { key = itemKey, gain = value })
    elseif normalized == "achievements" then
        return Runtime.MarkChanged(scope, { ref = itemKey })
    elseif normalized == "inventory" then
        return Runtime.MarkChanged(scope, { slot = itemKey })
    end
    return Runtime.MarkChanged(scope, itemKey)
end
Runtime.MarkChangedKey = Runtime.MarkKey

function Runtime.MarkBoolean(selfOrScope, scopeOrValue, maybeValue)
    local scope, value = selfOrScope, scopeOrValue
    if selfOrScope == Runtime then scope, value = scopeOrValue, maybeValue end
    return Runtime.MarkChanged(scope, value == nil and true or value)
end
Runtime.MarkChangedBoolean = Runtime.MarkBoolean

function Runtime.MarkEventUnit(selfOrKind, kindOrEventId, eventIdOrUnitId, maybeUnitId)
    local kind, eventId, unitId = selfOrKind, kindOrEventId, eventIdOrUnitId
    if selfOrKind == Runtime then kind, eventId, unitId = kindOrEventId, eventIdOrUnitId, maybeUnitId end
    local normalized = normalizeScope("event." .. tostring(kind or "units"))
    return Runtime.MarkChanged(normalized, { eventId = eventId, unitId = unitId })
end

function Runtime.MergeChangeSet(selfOrTarget, targetOrSource, maybeSource)
    local target, source = selfOrTarget, targetOrSource
    if selfOrTarget == Runtime then target, source = targetOrSource, maybeSource end
    if source == nil then
        source = target
        local current = Runtime._currentTransaction
        target = current and current.changeSet or nil
    end
    if type(target) ~= "table" or type(source) ~= "table" then
        error("Runtime.MergeChangeSet(target, source) requires two ChangeSet tables.", 2)
    end
    local current = Runtime._currentTransaction
    if current and target == current.changeSet then current.hasChanges = true end
    return mergeValues(target, source)
end
Runtime.MergeChanges = Runtime.MergeChangeSet

function Runtime.CreateChangeSet()
    return {}
end

function Runtime.EmitMutationEvent(selfOrKind, kindOrPayload, maybePayload)
    local kind, payload = selfOrKind, kindOrPayload
    if selfOrKind == Runtime then kind, payload = kindOrPayload, maybePayload end
    if type(kind) ~= "string" or kind == "" then
        error("Runtime.EmitMutationEvent(kind, payload) requires a non-empty kind.", 2)
    end
    local current = Runtime._currentTransaction
    if not current then
        return implicitMutation("mutation:" .. kind, function(transaction)
            local event = { kind = kind, payload = payload }
            transaction.mutationTail = transaction.mutationTail + 1
            transaction.mutationQueue[transaction.mutationTail] = event
            transaction.mutationCount = transaction.mutationCount + 1
            transaction.hasChanges = true
            return event
        end)
    end
    local event = { kind = kind, payload = payload }
    current.mutationTail = current.mutationTail + 1
    current.mutationQueue[current.mutationTail] = event
    current.mutationCount = current.mutationCount + 1
    current.hasChanges = true
    return event
end

function Runtime.QueueAfterCommit(selfOrFunction, functionOrFirstArg, ...)
    local callback, args, argCount
    if selfOrFunction == Runtime then
        callback = functionOrFirstArg
        args, argCount = captureArguments(...)
    else
        callback = selfOrFunction
        local rest, restCount = captureArguments(...)
        if functionOrFirstArg == nil and restCount == 0 then
            args, argCount = {}, 0
        else
            args, argCount = {}, restCount + 1
            args[1] = functionOrFirstArg
            for index = 1, restCount do args[index + 1] = rest[index] end
        end
    end
    if type(callback) ~= "function" then error("Runtime.QueueAfterCommit(fn, ...) requires a function.", 2) end

    local current = Runtime._currentTransaction
    if not current then
        local ok, err = pcall(function() callback(unpackValues(args, 1, argCount)) end)
        if not ok then
            reportError("Runtime after-commit callback failed outside a transaction: %s", tostring(err))
            return false
        end
        return true
    end
    current.afterCommitQueue[#current.afterCommitQueue + 1] = { fn = callback, args = args, argCount = argCount }
    return true
end

function Runtime.CommitTransaction(selfOrTransaction, maybeTransaction)
    local transaction = selfOrTransaction == Runtime and (maybeTransaction or Runtime._currentTransaction) or selfOrTransaction
    if type(transaction) ~= "table" then return false end
    local committed, commitError = commitInternal(transaction)
    if transaction.status == "failed" then error(commitError or transaction.error, 2) end
    if commitError and not committed then error(commitError, 2) end
    return committed, committed and transaction.changeSet or nil
end

function Runtime.RunTransaction(selfOrReason, reasonOrFunction, functionOrOptions, optionsOrFirstArg, ...)
    local isMethod = selfOrReason == Runtime
    local reason = isMethod and reasonOrFunction or selfOrReason
    local callback = isMethod and functionOrOptions or reasonOrFunction
    local candidateOptions = isMethod and optionsOrFirstArg or functionOrOptions
    local firstCallbackArg = isMethod and nil or optionsOrFirstArg
    local rest, restCount = captureArguments(...)
    if type(callback) ~= "function" then
        error("Runtime.RunTransaction(reason, fn, options, ...) requires a function.", 2)
    end

    local options = type(candidateOptions) == "table" and candidateOptions or {}
    local callbackArgs, callbackArgCount = {}, 0
    local function append(value)
        callbackArgCount = callbackArgCount + 1
        callbackArgs[callbackArgCount] = value
    end
    if isMethod and type(candidateOptions) ~= "table" and candidateOptions ~= nil then append(candidateOptions) end
    if not isMethod and type(candidateOptions) ~= "table" and candidateOptions ~= nil then append(candidateOptions) end
    if not isMethod and firstCallbackArg ~= nil then append(firstCallbackArg) end
    for index = 1, restCount do append(rest[index]) end

    local transaction = beginInternal(reason, options)
    local results, resultCount = captureArguments(pcall(function()
        return callback(unpackValues(callbackArgs, 1, callbackArgCount))
    end))
    local ok = results[1]
    if not ok then
        failInternal(transaction, results[2])
        error(results[2], 0)
    end

    local committed, commitError = commitInternal(transaction)
    if transaction.status == "failed" then error(commitError or transaction.error, 0) end
    if commitError and not committed then error(commitError, 0) end
    return unpackValues(results, 2, resultCount)
end

function Runtime.RegisterBeforeCommitProcessor(selfOrKind, kindOrHandler, maybeHandler)
    local kind, handler = selfOrKind, kindOrHandler
    if selfOrKind == Runtime then kind, handler = kindOrHandler, maybeHandler end
    if type(kind) ~= "string" or kind == "" then error("Runtime.RegisterBeforeCommitProcessor(kind, handler) requires a non-empty kind.", 2) end
    if type(handler) ~= "function" then error("Runtime.RegisterBeforeCommitProcessor(kind, handler) requires a function.", 2) end
    local normalizedKind = key(kind)
    Runtime._beforeCommitProcessors[normalizedKind] = Runtime._beforeCommitProcessors[normalizedKind] or {}
    Runtime._nextListenerId = Runtime._nextListenerId + 1
    local token = Runtime._nextListenerId
    Runtime._beforeCommitProcessors[normalizedKind][token] = handler
    return token
end

function Runtime.UnregisterBeforeCommitProcessor(selfOrKind, kindOrToken, maybeToken)
    local kind, token = selfOrKind, kindOrToken
    if selfOrKind == Runtime then kind, token = kindOrToken, maybeToken end
    local handlers = Runtime._beforeCommitProcessors[key(kind) or ""]
    if type(handlers) ~= "table" then return false end
    if type(token) == "function" then
        for handlerToken, handler in pairs(handlers) do
            if handler == token then handlers[handlerToken] = nil; return true end
        end
        return false
    end
    if handlers[token] ~= nil then handlers[token] = nil; return true end
    return false
end

function Runtime.RegisterPostCommitListener(selfOrHandler, maybeHandler)
    local handler = selfOrHandler == Runtime and maybeHandler or selfOrHandler
    if type(handler) ~= "function" then error("Runtime.RegisterPostCommitListener(handler) requires a function.", 2) end
    Runtime._nextListenerId = Runtime._nextListenerId + 1
    local token = Runtime._nextListenerId
    Runtime._postCommitListeners[token] = handler
    return token
end
Runtime.Subscribe = Runtime.RegisterPostCommitListener

function Runtime.UnregisterPostCommitListener(selfOrToken, maybeToken)
    local token = selfOrToken == Runtime and maybeToken or selfOrToken
    if type(token) == "function" then
        for listenerToken, handler in pairs(Runtime._postCommitListeners) do
            if handler == token then Runtime._postCommitListeners[listenerToken] = nil; return true end
        end
        return false
    end
    if Runtime._postCommitListeners[token] ~= nil then Runtime._postCommitListeners[token] = nil; return true end
    return false
end
Runtime.Unsubscribe = Runtime.UnregisterPostCommitListener

function Runtime.ClearEventRevisions(selfOrEventId, maybeEventId)
    local eventId = selfOrEventId == Runtime and maybeEventId or selfOrEventId
    local normalizedEventId = key(eventId)
    if normalizedEventId == nil then return false end
    local removed = false
    for domain in pairs(keyedRevisionDomains) do
        if revisionValues[domain][normalizedEventId] ~= nil then
            revisionValues[domain][normalizedEventId] = nil
            revisionBumpCounts[domain][normalizedEventId] = nil
            removed = true
        end
    end
    return removed
end
Runtime.ClearEventRuntimeRevisions = Runtime.ClearEventRevisions

function Runtime.GetDiagnostics()
    local current = Runtime._currentTransaction
    local currentSummary
    if current then
        currentSummary = {
            id = current.id,
            reason = current.reason,
            depth = current.depth,
            status = current.status,
            changeScopes = scopeCounts(current.changeSet),
            mutationEvents = math.max(0, (current.mutationTail or 0) - current.mutationHead + 1),
        }
    end
    return {
        currentTransaction = currentSummary,
        currentTransactionId = current and current.id or nil,
        currentTransactionReason = current and current.reason or nil,
        currentTransactionDepth = current and current.depth or 0,
        lastCommittedTransaction = copy(Runtime._lastCommittedSummary),
        lastCommitted = copy(Runtime._lastCommittedSummary),
        revisionBumpCounts = copy(revisionBumpCounts),
    }
end
Runtime.GetDiagnosticSnapshot = Runtime.GetDiagnostics

function Runtime.GetLastCommittedSummary()
    return copy(Runtime._lastCommittedSummary)
end

return Runtime
