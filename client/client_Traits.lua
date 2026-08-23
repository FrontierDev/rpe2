local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Debug = Addon.Debug or {}
local UI = Addon.UI or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Ruleset = Addon.Internal and Addon.Internal.Ruleset or {}
local Inventory = Addon.Client and Addon.Client.Inventory or {}
local Conditions = Addon.Client and Addon.Client.Conditions or {}
local CONSUMABLE_PROMPT_BATCH_SIZE = 8

local function getTimings()
    return Addon.Debug and Addon.Debug.Timings or nil
end

local function getTimingNowMilliseconds()
    local timings = getTimings()
    return type(timings) == "table" and type(timings.GetNowMilliseconds) == "function"
        and timings.GetNowMilliseconds()
        or 0
end

local function logTimingParts(label, parts, totalElapsedMs, thresholdMs)
    local timings = getTimings()
    if type(timings) == "table" and type(timings.LogParts) == "function" then
        return timings:LogParts(label, "event-traits", parts, totalElapsedMs, thresholdMs)
    end

    return false
end

local function getItemClass()
    return Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Item or nil
end

local function getTraitTooltipNamespace()
    local tooltipNamespace = Addon.Client and Addon.Client.UI and Addon.Client.UI.Tooltips or nil
    local traitTooltip = tooltipNamespace and tooltipNamespace.Trait or nil
    if type(traitTooltip) == "table" and type(traitTooltip.Build) == "function" then
        return traitTooltip
    end

    return nil
end

local function getTraitDescriptionBuilder()
    local traitNamespace = Addon.Client and Addon.Client.Traits or nil
    local descriptionBuilder = traitNamespace and traitNamespace.DescriptionBuilder or nil
    if type(descriptionBuilder) == "table" and type(descriptionBuilder.BuildTooltipData) == "function" then
        return descriptionBuilder
    end

    return nil
end

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function enqueueTask(fn, ...)
    local tasks = getTasks()
    if type(tasks) == "table" and type(tasks.Enqueue) == "function" then
        tasks:Enqueue(fn, ...)
        return true
    end

    fn(...)
    return false
end

local function bumpTooltipContextRevisions(eventState)
    local spellDescriptionBuilder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(spellDescriptionBuilder) == "table" and type(spellDescriptionBuilder.BumpEventTooltipContextRevisionForAllUnits) == "function" then
        spellDescriptionBuilder.BumpEventTooltipContextRevisionForAllUnits(eventState)
    end
end

Client.TraitRuntimeByEventId = Client.TraitRuntimeByEventId or {}
Client.TraitRuntimeCompileCache = Client.TraitRuntimeCompileCache or {
    configurationRevision = -1,
    activeTraits = nil,
    equippedTraits = nil,
}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimString(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeChancePercent(value)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return 100
    end

    return math.max(0, math.min(100, numericValue))
end

local function rollSucceedsForChance(chancePercent)
    local normalizedChance = normalizeChancePercent(chancePercent)
    if normalizedChance <= 0 then
        return false
    end
    if normalizedChance >= 100 then
        return true
    end

    return math.random() * 100 <= normalizedChance
end

local function evaluateProcChance(chancePercent)
    local normalizedChance = normalizeChancePercent(chancePercent)
    if normalizedChance <= 0 then
        return false, normalizedChance, nil
    end
    if normalizedChance >= 100 then
        return true, normalizedChance, nil
    end

    local roll = math.random() * 100
    return roll <= normalizedChance, normalizedChance, roll
end

local function buildProcRollText(normalizedChance, roll)
    if normalizedChance <= 0 then
        return "blocked"
    end
    if normalizedChance >= 100 or roll == nil then
        return "auto"
    end

    return ("%.2f"):format(tonumber(roll) or 0)
end

local function logTraitProcDebug(registeredEntry, ownerUnit, targetUnit, combatEventId, effect, chancePercent, chanceRoll, outcome, result)
    if type(Debug) ~= "table" or type(Debug.Internal) ~= "function" then
        return false
    end

    if type(Debug.EnsureInternalLevelEnabled) == "function" then
        Debug.EnsureInternalLevelEnabled()
    end

    local payload = registeredEntry and registeredEntry.payload or nil
    local source = registeredEntry and registeredEntry.source or nil
    local amount = math.max(
        0,
        math.floor(
            tonumber(type(result) == "table" and result.amount or nil)
                or math.abs(tonumber(type(result) == "table" and result.appliedDelta or nil) or 0)
                or 0
        )
    )
    local appliedDelta = math.floor(tonumber(type(result) == "table" and result.appliedDelta or 0) or 0)
    local hitResult = tostring(type(result) == "table" and (result.hitCheckResult or result.resultType) or "n/a")
    local applied = type(result) == "table" and result.applied == true or false
    local effectType = tostring(effect and effect.type or "unknown")
    local traitName = trimString(payload and payload.name)
    if traitName == "" then
        traitName = trimString(source and (source.name or source.itemName) or "")
    end
    if traitName == "" then
        traitName = "unknown"
    end

    return Debug.Internal(
        "Trait proc: trait=%s source=%s owner=%s target=%s event=%s effect=%s chance=%.1f roll=%s outcome=%s applied=%s hit=%s amount=%d delta=%d",
        traitName,
        tostring(source and source.sourceType or "unknown"),
        tostring(ownerUnit and ownerUnit.name or "unknown"),
        tostring(targetUnit and targetUnit.name or "unknown"),
        tostring(combatEventId or "unknown"),
        effectType,
        tonumber(chancePercent) or 0,
        buildProcRollText(tonumber(chancePercent) or 0, chanceRoll),
        tostring(outcome or "unknown"),
        tostring(applied),
        hitResult,
        amount,
        appliedDelta
    )
end

local function logTraitRegistrationDebug(outcome, detail)
    return false
end

local function logTraitDispatchDebug(outcome, detail)
    if type(Debug) ~= "table" or type(Debug.Internal) ~= "function" then
        return false
    end

    if type(Debug.EnsureInternalLevelEnabled) == "function" then
        Debug.EnsureInternalLevelEnabled()
    end

    local values = type(detail) == "table" and detail or {}
    return Debug.Internal(
        "Trait dispatch: outcome=%s event=%s recipient=%s owner=%s source=%s other=%s registrations=%d",
        tostring(outcome or "unknown"),
        tostring(values.combatEventId or ""),
        tostring(values.recipientEventId or ""),
        tostring(values.ownerEventId or ""),
        tostring(values.eventSourceName or ""),
        tostring(values.eventOtherName or ""),
        math.max(0, math.floor(tonumber(values.registrationCount) or 0))
    )
end

local function buildTraitRuntimeRegistrationSummary(activeEntries, registeredCombatEvents)
    local entryParts = {}
    local eventParts = {}

    for index = 1, #(activeEntries or {}) do
        local entry = activeEntries[index]
        local payload = entry and entry.payload or nil
        local sourceType = ensureString(entry and entry.sourceType)
        if sourceType == "equipment" or sourceType == "equipment_modification" or sourceType == "mount_equipment" or sourceType == "mount_equipment_modification" then
            local eventIds = {}
            for eventIndex = 1, #(payload and payload.events or {}) do
                local combatEventId = ensureString(payload.events[eventIndex] and payload.events[eventIndex].combatEventId)
                if combatEventId ~= "" then
                    eventIds[#eventIds + 1] = combatEventId
                end
            end
            entryParts[#entryParts + 1] = ("%s:%s[%s]"):format(
                sourceType,
                trimString(entry and (entry.name or entry.itemName) or "unknown"),
                #eventIds > 0 and table.concat(eventIds, ",") or "-"
            )
        end
    end

    for combatEventId, bucket in pairs(registeredCombatEvents or {}) do
        eventParts[#eventParts + 1] = ("%s=%d"):format(
            tostring(combatEventId),
            #(type(bucket) == "table" and bucket or {})
        )
    end

    table.sort(entryParts)
    table.sort(eventParts)

    return table.concat(entryParts, " | "), table.concat(eventParts, " | ")
end

local function buildRegisteredTraitBucketSummary(registeredCombatEvents, combatEventId)
    local bucketParts = {}
    local bucket = type(registeredCombatEvents) == "table" and registeredCombatEvents[ensureString(combatEventId)] or nil
    for index = 1, #(bucket or {}) do
        local registeredEntry = bucket[index]
        local source = registeredEntry and registeredEntry.source or nil
        bucketParts[#bucketParts + 1] = ("%s:%s"):format(
            ensureString(source and source.sourceType, "unknown"),
            trimString(source and (source.name or source.itemName) or "unknown")
        )
    end
    table.sort(bucketParts)
    return table.concat(bucketParts, " | ")
end

local function logTraitRuntimeRefreshDebug(eventState, state)
    return false
end

local function logTraitEventLookupDebug(combatEventId, recipientEventId, ownerEventId, registeredCombatEvents)
    if type(Debug) ~= "table" or type(Debug.Internal) ~= "function" then
        return false
    end

    if type(Debug.EnsureInternalLevelEnabled) == "function" then
        Debug.EnsureInternalLevelEnabled()
    end

    local bucketSummary = buildRegisteredTraitBucketSummary(registeredCombatEvents, combatEventId)
    local _, registeredEvents = buildTraitRuntimeRegistrationSummary(nil, registeredCombatEvents)
    return Debug.Internal(
        "Equipment trait event lookup: event=%s recipient=%s owner=%s bucket=%s registered=%s",
        tostring(combatEventId or ""),
        tostring(recipientEventId or ""),
        tostring(ownerEventId or ""),
        bucketSummary ~= "" and bucketSummary or "-",
        registeredEvents ~= "" and registeredEvents or "-"
    )
end

local function evaluateRuntimeConditions(ownerType, owner, options)
    if type(Conditions) ~= "table" or type(Conditions.EvaluateList) ~= "function" or type(owner) ~= "table" then
        return {
            passed = true,
            failureText = "",
        }
    end

    local values = type(options) == "table" and options or {}
    local context = Conditions:BuildContext(ownerType, owner, values)
    return Conditions:EvaluateList(owner.conditions, context)
end

local function evaluateRuntimeItemAndPayloadConditions(item, payload, options)
    local values = type(options) == "table" and options or {}
    local itemResult = evaluateRuntimeConditions("item", item, values)
    if itemResult.passed ~= true then
        return itemResult
    end

    return evaluateRuntimeConditions("trait", payload, values)
end

local function copyArray(values)
    local copy = {}
    for index = 1, #(values or {}) do
        copy[index] = values[index]
    end
    return copy
end

local function sortedNumericKeys(values)
    local keys = {}
    for key in pairs(values or {}) do
        local numericKey = tonumber(key)
        if numericKey and numericKey > 0 and math.floor(numericKey) == numericKey then
            keys[#keys + 1] = {
                sortKey = numericKey,
                key = key,
            }
        end
    end

    table.sort(keys, function(left, right)
        return left.sortKey < right.sortKey
    end)
    return keys
end

local function emitTriggeredDamageCombatLog(client, eventState, casterUnit, targetUnit, result, effect)
    if type(client) ~= "table" or type(eventState) ~= "table" or type(result) ~= "table" then
        return false
    end

    local amount = math.max(
        0,
        math.floor(
            tonumber(result.amount)
                or math.abs(tonumber(result.appliedDelta) or 0)
                or 0
        )
    )
    if amount <= 0 then
        return false
    end

    local schoolRef = type(result.damageSchoolRef) == "string" and result.damageSchoolRef or nil
    if schoolRef == nil and type(effect) == "table" and type(effect.damageSchoolRefs) == "table" then
        schoolRef = effect.damageSchoolRefs[1]
    end

    local iconTexture = tostring(result.damageSchoolIcon or "")
    local labelText = tostring(result.damageSchoolName or "")
    local accentColor = nil
    if type(client.ResolveCombatLogDamageSchoolPresentation) == "function" then
        local resolvedIcon, resolvedLabel, resolvedColor = client:ResolveCombatLogDamageSchoolPresentation(
            schoolRef,
            labelText,
            iconTexture
        )
        iconTexture = resolvedIcon or iconTexture
        labelText = resolvedLabel or labelText
        accentColor = resolvedColor
    end

    if iconTexture == "" then
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    if labelText == "" then
        labelText = "True"
    end

    local entry = {
        eventId = eventState.id,
        entryType = "damage",
        casterDisplayName = tostring(casterUnit and casterUnit.name or "Unknown"),
        targetDisplayName = tostring(targetUnit and targetUnit.name or "Unknown"),
        targetCount = 1,
        amountMin = amount,
        amountMax = amount,
        iconTexture = iconTexture,
        spellIconTexture = iconTexture,
        labelText = labelText,
        detailText = ("+%d %s"):format(amount, labelText),
        accentColor = accentColor,
    }

    if type(client.QueueCombatLogEntryEmission) == "function" then
        return client:QueueCombatLogEntryEmission(entry)
    end
    if type(client.EmitCombatLogEntry) == "function" then
        return client:EmitCombatLogEntry(entry)
    end

    return false
end

local function getRulesetRuleValue(categoryKey, ruleKey, fallback)
    local ruleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition(categoryKey, ruleKey) or nil
    local value = nil
    if Ruleset.GetRulesetRuleValue then
        value = Ruleset.GetRulesetRuleValue(ruleset, categoryKey, ruleDefinition)
    end
    if value == nil then
        return fallback
    end

    return value
end

local function parseRequiredTags()
    return UI.Utils and UI.Utils.ParseCommaSeparatedList and UI.Utils.ParseCommaSeparatedList(getRulesetRuleValue("consumables", "required_consumable_item_tags", "")) or {}
end

local function matchesRequiredTags(itemTags)
    local requiredTags = parseRequiredTags()
    if #requiredTags == 0 then
        return true
    end

    local normalizedTags = {}
    for index = 1, #(itemTags or {}) do
        normalizedTags[string.lower(ensureString(itemTags[index]))] = true
    end

    for index = 1, #requiredTags do
        local tag = string.lower(ensureString(requiredTags[index]))
        if tag ~= "" and normalizedTags[tag] then
            return true
        end
    end

    return false
end

local function parseNumericRuleValue(ruleKey, fallback)
    local numericValue = math.floor(tonumber(getRulesetRuleValue("consumables", ruleKey, fallback)) or tonumber(fallback) or 0)
    if numericValue < 0 then
        return 0
    end
    return numericValue
end

local function getConsumableSelectionRules()
    local categorizationEnabled = getRulesetRuleValue("consumables", "elixir_categorisation", false) == true
    local flaskLimit = parseNumericRuleValue("flask_limit", 1)
    local scrollLimit = parseNumericRuleValue("scroll_limit", 1)
    local runeLimit = parseNumericRuleValue("rune_limit", 1)
    local elixirLimit = categorizationEnabled and 2 or parseNumericRuleValue("elixir_limit", 0)

    return {
        flaskLimit = flaskLimit,
        scrollLimit = scrollLimit,
        runeLimit = runeLimit,
        elixirLimit = elixirLimit,
        elixirCategorisation = categorizationEnabled,
    }
end

local function buildEventAuraStateKey(auraRef, targetEventId)
    return ("%s:%d"):format(trimString(auraRef), math.floor(tonumber(targetEventId) or 0))
end

local function normalizeEventAuraTeamIndices(values, teamCount)
    local normalized = {}
    local seen = {}

    for index = 1, #(values or {}) do
        local numericValue = math.floor(tonumber(values[index]) or 0)
        if numericValue > 0 and not seen[numericValue] and (not teamCount or numericValue <= teamCount) then
            seen[numericValue] = true
            normalized[#normalized + 1] = numericValue
        end
    end

    table.sort(normalized)
    return normalized
end

local function eventAuraAppliesToTeam(eventState, entry, teamIndex)
    local numericTeam = math.floor(tonumber(teamIndex) or 0)
    if numericTeam <= 0 then
        return false
    end

    local teams = normalizeEventAuraTeamIndices(type(entry) == "table" and (entry.teamIndices or entry.teams) or nil, #(eventState and eventState.teams or {}))
    if #teams == 0 then
        return true
    end

    for index = 1, #teams do
        if teams[index] == numericTeam then
            return true
        end
    end

    return false
end

local function buildTagLookup(tags)
    local lookup = {}
    for index = 1, #(tags or {}) do
        local tag = string.lower(ensureString(tags[index]))
        if tag ~= "" then
            lookup[tag] = true
        end
    end
    return lookup
end

local CONSUMABLE_TYPE_LOOKUP = {
    potion = true,
    flask = true,
    elixir = true,
    scroll = true,
    rune = true,
    enhancement = true,
}

local function normalizeConsumableType(value)
    local normalized = string.lower(ensureString(value))
    if CONSUMABLE_TYPE_LOOKUP[normalized] == true then
        return normalized
    end

    return ""
end

local CONSUMABLE_ELIXIR_TYPE_LOOKUP = {
    generic = true,
    battle = true,
    guardian = true,
}

local function normalizeConsumableElixirType(value)
    local normalized = string.lower(ensureString(value))
    if CONSUMABLE_ELIXIR_TYPE_LOOKUP[normalized] == true then
        return normalized
    end

    return "generic"
end

local function resolveConsumableElixirType(item, tags)
    local explicitType = normalizeConsumableElixirType(item and item.consumableElixirType)
    if explicitType ~= "generic" then
        return explicitType
    end

    local battle = tags and tags.battle == true
    local guardian = tags and tags.guardian == true
    if battle and guardian then
        return "both"
    end
    if battle then
        return "battle"
    end
    if guardian then
        return "guardian"
    end

    return explicitType
end

local function classifyConsumableRow(row)
    local item = row and row.item or nil
    local tags = buildTagLookup(item and item.tags or nil)
    local consumableType = normalizeConsumableType((item and item.consumableType) or (row and row.consumableType))

    if consumableType == "flask" then
        return {
            kind = "flask",
            consumableType = consumableType,
            tags = tags,
        }
    end

    if consumableType == "scroll" then
        return {
            kind = "scroll",
            consumableType = consumableType,
            tags = tags,
        }
    end

    if consumableType == "rune" then
        return {
            kind = "rune",
            consumableType = consumableType,
            tags = tags,
        }
    end

    if consumableType == "elixir" then
        return {
            kind = "elixir",
            subtype = resolveConsumableElixirType(item or row, tags),
            consumableType = consumableType,
            tags = tags,
        }
    end

    return {
        kind = consumableType == "enhancement" and "enhancement" or "other",
        consumableType = consumableType,
        tags = tags,
    }
end

local function normalizeSelectedValues(selectedValues, rowsByValue)
    local normalized = {}
    local seen = {}

    for index = 1, #(selectedValues or {}) do
        local value = ensureString(selectedValues[index])
        if value ~= "" and not seen[value] and (rowsByValue == nil or rowsByValue[value] ~= nil) then
            normalized[#normalized + 1] = value
            seen[value] = true
        end
    end

    return normalized
end

local function buildConsumableRowLookup(rows)
    local lookup = {}
    for index = 1, #(rows or {}) do
        local row = rows[index]
        local value = ensureString(row and row.itemRef)
        if value ~= "" then
            lookup[value] = row
        end
    end
    return lookup
end

local function buildConsumableSelectionCounts(rowsByValue, selectedValues)
    local counts = {
        total = 0,
        flask = 0,
        scroll = 0,
        rune = 0,
        elixir = 0,
        enhancement = 0,
        battle = 0,
        guardian = 0,
    }

    for index = 1, #(selectedValues or {}) do
        local row = rowsByValue[ensureString(selectedValues[index])]
        if row then
            local classification = classifyConsumableRow(row)
            counts.total = counts.total + 1
            if classification.kind == "flask" then
                counts.flask = counts.flask + 1
            elseif classification.kind == "scroll" then
                counts.scroll = counts.scroll + 1
            elseif classification.kind == "rune" then
                counts.rune = counts.rune + 1
            elseif classification.kind == "elixir" then
                counts.elixir = counts.elixir + 1
                if classification.subtype == "battle" or classification.subtype == "both" then
                    counts.battle = counts.battle + 1
                end
                if classification.subtype == "guardian" or classification.subtype == "both" then
                    counts.guardian = counts.guardian + 1
                end
            elseif classification.kind == "enhancement" then
                counts.enhancement = counts.enhancement + 1
            end
        end
    end

    return counts
end

local function formatConsumableLimit(limit)
    local normalizedLimit = math.max(0, math.floor(tonumber(limit) or 0))
    if normalizedLimit <= 0 then
        return nil
    end

    return tostring(normalizedLimit)
end

local function formatConsumableCountSegment(label, count, limit)
    local limitText = formatConsumableLimit(limit)
    if limitText then
        return ("%s: %d/%s"):format(label, count, limitText)
    end

    return ("%s: %d"):format(label, count)
end

local function buildSlotRefLookup(slotRefs)
    local lookup = {}
    for index = 1, #(slotRefs or {}) do
        local slotRef = ensureString(slotRefs[index])
        if slotRef ~= "" then
            lookup[slotRef] = true
        end
    end
    return lookup
end

local function getConsumableEquippedSlotKeys()
    local orderedSlotKeys = {}
    local seenSlotKeys = {}
    local layout = Profile.GetEquipmentLayout and Profile.GetEquipmentLayout() or nil
    if type(layout) == "table" and type(layout.ordered) == "table" then
        for index = 1, #layout.ordered do
            local slotKey = ensureString(layout.ordered[index])
            if slotKey ~= "" and not seenSlotKeys[slotKey] then
                orderedSlotKeys[#orderedSlotKeys + 1] = slotKey
                seenSlotKeys[slotKey] = true
            end
        end
    end

    local listedSlotKeys = Profile.ListEquippedSlots and Profile.ListEquippedSlots() or nil
    if type(listedSlotKeys) == "table" then
        for index = 1, #listedSlotKeys do
            local slotKey = ensureString(listedSlotKeys[index])
            if slotKey ~= "" and not seenSlotKeys[slotKey] then
                orderedSlotKeys[#orderedSlotKeys + 1] = slotKey
                seenSlotKeys[slotKey] = true
            end
        end
    end

    local equippedSlots = {}
    for index = 1, #orderedSlotKeys do
        local slotKey = orderedSlotKeys[index]
        local equipped = Profile.GetEquippedItem and Profile.GetEquippedItem(slotKey) or nil
        local slotRef = ensureString(equipped and equipped.slotRef)
        if equipped and equipped.isMissing ~= true and equipped.item ~= nil and slotRef ~= "" then
            equippedSlots[#equippedSlots + 1] = {
                slotKey = slotKey,
                slotRef = slotRef,
                equipped = equipped,
            }
        end
    end

    return equippedSlots
end

local function getEnhancementEligibleSlotKeys(row, equippedSlots)
    local item = row and row.item or nil
    local validSlotLookup = buildSlotRefLookup(item and item.validSlotRefs or nil)
    local eligibleSlotKeys = {}
    local seenSlotKeys = {}

    for index = 1, #(equippedSlots or {}) do
        local equippedSlot = equippedSlots[index]
        local slotKey = ensureString(equippedSlot and equippedSlot.slotKey)
        local slotRef = ensureString(equippedSlot and equippedSlot.slotRef)
        if slotKey ~= "" and slotRef ~= "" and validSlotLookup[slotRef] == true and not seenSlotKeys[slotKey] then
            eligibleSlotKeys[#eligibleSlotKeys + 1] = slotKey
            seenSlotKeys[slotKey] = true
        end
    end

    return eligibleSlotKeys
end

local function buildEnhancementSlotAssignments(rowsByValue, selectedValues, candidateValue)
    local equippedSlots = getConsumableEquippedSlotKeys()
    local enhancementSelections = {}
    local candidateRow = candidateValue and rowsByValue[ensureString(candidateValue)] or nil

    local function appendSelection(rowValue, row)
        local validSlotRefs = row and row.item and row.item.validSlotRefs or nil
        local eligibleSlotKeys = getEnhancementEligibleSlotKeys(row, equippedSlots)
        if #(validSlotRefs or {}) == 0 then
            return nil, "Enhancements require at least one valid slot."
        end
        if #eligibleSlotKeys == 0 then
            return nil, "This enhancement requires an equipped item in one of its valid slots."
        end

        enhancementSelections[#enhancementSelections + 1] = {
            value = ensureString(rowValue),
            eligibleSlotKeys = eligibleSlotKeys,
        }
        return true
    end

    for index = 1, #(selectedValues or {}) do
        local selectedValue = ensureString(selectedValues[index])
        local row = rowsByValue[selectedValue]
        if row and classifyConsumableRow(row).kind == "enhancement" then
            local appended, appendError = appendSelection(selectedValue, row)
            if not appended then
                return nil, appendError
            end
        end
    end

    if candidateRow and classifyConsumableRow(candidateRow).kind == "enhancement" then
        local appended, appendError = appendSelection(candidateValue, candidateRow)
        if not appended then
            return nil, appendError
        end
    end

    local assignedBySlotKey = {}
    local visiting = {}

    local function assignSelection(selectionIndex, seenSlotKeys)
        if visiting[selectionIndex] == true then
            return false
        end
        visiting[selectionIndex] = true

        local selection = enhancementSelections[selectionIndex]
        for slotIndex = 1, #(selection and selection.eligibleSlotKeys or {}) do
            local slotKey = ensureString(selection.eligibleSlotKeys[slotIndex])
            if slotKey ~= "" and seenSlotKeys[slotKey] ~= true then
                seenSlotKeys[slotKey] = true
                local currentSelectionIndex = assignedBySlotKey[slotKey]
                if currentSelectionIndex == nil or assignSelection(currentSelectionIndex, seenSlotKeys) then
                    assignedBySlotKey[slotKey] = selectionIndex
                    visiting[selectionIndex] = nil
                    return true
                end
            end
        end

        visiting[selectionIndex] = nil
        return false
    end

    for selectionIndex = 1, #enhancementSelections do
        if not assignSelection(selectionIndex, {}) then
            return nil, "Only one enhancement can be selected per equipped slot."
        end
    end

    return assignedBySlotKey, nil
end

local function getConsumableSelectionDisabledReason(rows, selectedValues, value)
    local rowsByValue = buildConsumableRowLookup(rows)
    local normalizedValue = ensureString(value)
    local normalizedSelectedValues = normalizeSelectedValues(selectedValues, rowsByValue)
    local row = rowsByValue[normalizedValue]
    if normalizedValue == "" or row == nil then
        return "Unavailable."
    end

    for index = 1, #normalizedSelectedValues do
        if normalizedSelectedValues[index] == normalizedValue then
            return nil
        end
    end

    if ensureString(row.unavailableReason) ~= "" then
        return ensureString(row.unavailableReason)
    end

    local nextSelectedValues, statusText = Client:TryToggleConsumableSelection(rows, normalizedSelectedValues, normalizedValue)
    local status = ensureString(statusText)
    if status ~= "" then
        return status
    end

    if type(nextSelectedValues) == "table" then
        for index = 1, #nextSelectedValues do
            if ensureString(nextSelectedValues[index]) == normalizedValue then
                return nil
            end
        end
    end

    return "Unavailable."
end

local function getLocalTraitOwnerUnit(eventState)
    return type(Client.ResolveLocalEventUnit) == "function" and Client:ResolveLocalEventUnit(eventState) or nil
end

local function getTraitCategory(entry)
    if type(entry) ~= "table" then
        return "General"
    end

    if entry.category and entry.category ~= "" then
        return entry.category
    end

    local trait = entry.trait or entry.payload or entry
    if type(trait) ~= "table" then
        return "General"
    end

    if entry.origin == "class" then
        if entry.typeCategory == "talent" then
            return "class_talents"
        end
        return "class_passives"
    end
    if entry.origin == "race" or trait.isRacial == true then
        return "race_passives"
    end
    if trait.isClass == true then
        return "class_passives"
    end
    if entry.sourceType == "consumable" then
        return "consumable"
    end

    local category = trimString(trait.category)
    if category ~= "" then
        return category
    end

    return "General"
end

local function sortTraitRows(rows)
    table.sort(rows, function(left, right)
        local leftCategory = ensureString(left and left.category)
        local rightCategory = ensureString(right and right.category)
        if leftCategory == rightCategory then
            local leftName = string.lower(ensureString(left and left.name))
            local rightName = string.lower(ensureString(right and right.name))
            if leftName == rightName then
                local leftRef = ensureString(left and (left.traitRef or left.itemRef or left.name))
                local rightRef = ensureString(right and (right.traitRef or right.itemRef or right.name))
                return leftRef < rightRef
            end
            return leftName < rightName
        end

        return leftCategory < rightCategory
    end)

    return rows
end

local function buildPayloadDisplayName(payload, fallback)
    local name = trimString(payload and payload.name)
    if name ~= "" then
        return name
    end

    return fallback or "Trait"
end

local function getTraitConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function getTraitSourceCache(client)
    client.TraitRuntimeCompileCache = client.TraitRuntimeCompileCache or {
        configurationRevision = -1,
        activeTraits = nil,
        equippedTraits = nil,
    }

    local cache = client.TraitRuntimeCompileCache
    local configurationRevision = getTraitConfigurationRevision()
    if tonumber(cache.configurationRevision) ~= configurationRevision
        or type(cache.activeTraits) ~= "table"
        or type(cache.equippedTraits) ~= "table"
    then
        cache.configurationRevision = configurationRevision
        cache.activeTraits = Profile.ListActiveTraits and Profile.ListActiveTraits()
            or Profile.ListKnownTraits and Profile.ListKnownTraits()
            or {}
        cache.equippedTraits = Profile.ListEquippedItemTraits and Profile.ListEquippedItemTraits() or {}
    end

    return cache, configurationRevision
end

local function buildAutomaticTraitAuraStateKey(auraRef, casterEventId, targetEventId, sourceKey)
    return table.concat({
        tostring(auraRef or ""),
        tostring(casterEventId or 0),
        tostring(targetEventId or 0),
        tostring(sourceKey or ""),
    }, "\31")
end

local function buildAutomaticTraitAuraSourceKey(sourceEntry, auraIndex)
    return table.concat({
        tostring(sourceEntry and sourceEntry.sourceType or ""),
        tostring(sourceEntry and sourceEntry.traitRef or ""),
        tostring(sourceEntry and sourceEntry.itemRef or ""),
        tostring(sourceEntry and sourceEntry.datasetId or ""),
        tostring(auraIndex or 0),
    }, "\31")
end

local function buildQualifiedAutomaticAuraRef(client, sourceEntry, auraRef)
    local auraManager = client and client.Spellcasting and client.Spellcasting.AuraManager or nil
    if type(auraManager) ~= "table" or type(auraManager.ResolveAuraDefinition) ~= "function" then
        return trimString(auraRef)
    end

    local _, _, qualifiedAuraRef = auraManager:ResolveAuraDefinition(auraRef, {
        dataset = sourceEntry and sourceEntry.dataset or nil,
        datasetId = sourceEntry and sourceEntry.datasetId or nil,
    })
    return trimString(qualifiedAuraRef or auraRef)
end

local function buildActiveTraitEntriesFromSources(client, eventState, activeTraits, equippedTraits, appliedConsumables)
    local rows = {}

    for index = 1, #activeTraits do
        local row = activeTraits[index]
        local trait = row and row.trait or nil
        local category = row and row.category or getTraitCategory(row)
        local conditionState = row and trait and evaluateRuntimeConditions("trait", trait, {
            traitRef = row and row.traitRef or nil,
            eventState = eventState,
        }) or nil
        if row
            and trait
            and row.isMissing ~= true
            and trait.isEnvironmental ~= true
            and client:IsTraitCategoryAllowed(category)
            and conditionState
            and conditionState.passed == true
        then
            rows[#rows + 1] = {
                sourceType = "trait",
                category = category,
                name = row.name,
                payload = trait,
                traitRef = row.traitRef,
                origin = row.origin or "manual",
                isAutoGranted = row.isAutoGranted == true,
            }
        end
    end

    for index = 1, #equippedTraits do
        local row = equippedTraits[index]
        local payload = row and (row.payload or row.equipmentTrait) or nil
        local conditionState = row and type(payload) == "table" and evaluateRuntimeItemAndPayloadConditions(row.item, payload, {
            itemRef = row.itemRef,
            item = row.item,
            eventState = eventState,
            equipmentScope = (row.sourceType == "mount_equipment" or row.sourceType == "mount_equipment_modification") and "mount" or nil,
        }) or nil
        if row
            and type(payload) == "table"
            and row.isMissing ~= true
            and conditionState
            and conditionState.passed == true
        then
            rows[#rows + 1] = {
                sourceType = row.sourceType or "equipment",
                category = "equipment",
                name = row.name,
                itemName = row.itemName,
                itemRef = row.itemRef,
                dataset = row.dataset,
                datasetId = row.datasetId,
                payload = payload,
            }
        end
    end

    if type(eventState) == "table" and eventState.active == true and client:IsTraitCategoryAllowed("consumable") then
        for index = 1, #appliedConsumables do
            local entry = appliedConsumables[index]
            if type(entry) == "table"
                and type(entry.payload) == "table"
                and evaluateRuntimeItemAndPayloadConditions(entry.item, entry.payload, {
                    itemRef = entry.itemRef,
                    item = entry.item,
                    eventState = eventState,
                }).passed == true
            then
                rows[#rows + 1] = entry
            end
        end
    end

    return rows
end

function Client:GetTraitRuntimeState(eventId, createIfMissing)
    local normalizedEventId = ensureString(eventId)
    if normalizedEventId == "" then
        return nil
    end

    self.TraitRuntimeByEventId = self.TraitRuntimeByEventId or {}
    local state = self.TraitRuntimeByEventId[normalizedEventId]
    if state or not createIfMissing then
        return state
    end

    state = {
        ownerEventId = 0,
        activeEntries = {},
        registeredCombatEvents = {},
        appliedConsumableTraits = {},
        compiledConfigurationRevision = -1,
        compiledConsumableRevision = 0,
        automaticAuraStateByKey = {},
        appliedEventAuras = {},
        promptedPhases = {},
    }
    self.TraitRuntimeByEventId[normalizedEventId] = state
    return state
end

function Client:ResetTraitRuntime(eventId)
    local normalizedEventId = ensureString(eventId)
    if normalizedEventId == "" then
        return false
    end

    self.TraitRuntimeByEventId = self.TraitRuntimeByEventId or {}
    local existed = self.TraitRuntimeByEventId[normalizedEventId] ~= nil
    self.TraitRuntimeByEventId[normalizedEventId] = nil
    return existed
end

function Client:IsTraitCategoryAllowed(category)
    local normalizedCategory = ensureString(category)
    if normalizedCategory == "class_passives" or normalizedCategory == "class_talents" then
        return getRulesetRuleValue("traits", "allow_class_traits", true) ~= false
    end
    if normalizedCategory == "race_passives" then
        return getRulesetRuleValue("traits", "allow_race_traits", true) ~= false
    end
    if normalizedCategory == "consumable" then
        return getRulesetRuleValue("consumables", "allow_consumable_traits", true) ~= false
    end

    return true
end

function Client:GetTraitDisplayMode()
    local value = string.lower(ensureString(getRulesetRuleValue("interface", "trait_display_mode", "grouped")))
    if value == "flat" then
        return "flat"
    end

    return "grouped"
end

function Client:GetAppliedConsumableTraitsForEvent(eventState)
    local state = self:GetTraitRuntimeState(eventState and eventState.id or nil, false)
    local rows = {}

    for index = 1, #((state and state.appliedConsumableTraits) or {}) do
        rows[#rows + 1] = state.appliedConsumableTraits[index]
    end

    return rows
end

function Client:QueueDeferredConsumablePrompt(eventState, phase)
    local state = self:GetTraitRuntimeState(eventState and eventState.id or nil, true)
    local normalizedPhase = ensureString(phase)
    if type(state) ~= "table" or normalizedPhase == "" then
        return false
    end

    state.deferredPromptPhases = state.deferredPromptPhases or {}
    state.deferredPromptPhases[normalizedPhase] = true
    return true
end

function Client:FlushDeferredConsumablePrompt(eventState, phase)
    local activeEventState = type(eventState) == "table" and eventState or (self.GetEventState and self:GetEventState() or nil)
    local normalizedPhase = ensureString(phase)
    if type(activeEventState) ~= "table" or activeEventState.active ~= true or normalizedPhase == "" then
        return false
    end

    local state = self:GetTraitRuntimeState(activeEventState.id, false)
    local deferredPromptPhases = type(state) == "table" and state.deferredPromptPhases or nil
    if type(deferredPromptPhases) ~= "table" or deferredPromptPhases[normalizedPhase] ~= true then
        return false
    end

    deferredPromptPhases[normalizedPhase] = nil
    return self.PromptPhaseConsumableTraits and self:PromptPhaseConsumableTraits(activeEventState, normalizedPhase) or false
end

function Client:BuildProfileTraitRows()
    local rows = {}
    local learnedTraits = Profile.ListKnownTraits and Profile.ListKnownTraits() or {}
    local activeTraits = Profile.ListActiveTraits and Profile.ListActiveTraits() or {}
    local equippedTraits = Profile.ListEquippedItemTraits and Profile.ListEquippedItemTraits() or {}
    local availableConsumables = Profile.ListAvailableConsumableTraits and Profile.ListAvailableConsumableTraits() or {}
    local seenTraitRefs = {}
    local seenEquipmentRefs = {}
    local seenConsumableRefs = {}
    local appendedLearnedCount = 0
    local appendedActiveCount = 0
    local appendedEquipmentCount = 0
    local appendedConsumableCount = 0

    local function appendProfileTraitRow(row)
        local category = row and row.category or getTraitCategory(row)
        local traitRef = ensureString(row and row.traitRef)
        if not row then
            return false
        end
        if row.isEnvironmental == true then
            return false
        end
        if not self:IsTraitCategoryAllowed(category) then
            return
        end

        if traitRef ~= "" then
            if seenTraitRefs[traitRef] then
                return false
            end
            seenTraitRefs[traitRef] = true
        end

        rows[#rows + 1] = {
            sourceType = "trait",
            traitRef = row.traitRef,
            category = category,
            name = row.name,
            summaryText = row.summaryText,
            authoredDescriptionText = row.authoredDescriptionText,
            descriptionText = row.descriptionText,
            descriptionSource = row.descriptionSource,
            icon = trimString(row.icon) ~= "" and row.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
            dataset = row.dataset,
            datasetId = row.dataset and row.dataset.id or nil,
            trait = row.trait,
            traitPayload = row.traitPayload,
            datasetName = row.datasetName,
            typeCategory = row.typeCategory,
            origin = row.origin or "manual",
            isAutoGranted = row.isAutoGranted == true,
            isToggleable = row.isToggleable == true,
            isRemovable = row.isRemovable == true,
            isActive = row.isActive == true,
            isMissing = row.isMissing == true,
            conditionFailureText = row.conditionFailureText,
        }
        return true
    end

    local function appendProfileEquipmentRow(row)
        if not row then
            return false
        end
        if row.isMissing == true then
            return false
        end

        local sourceType = ensureString(row.sourceType)
        local itemRef = ensureString(row.itemRef)
        local key = sourceType .. ":" .. itemRef
        if itemRef ~= "" and seenEquipmentRefs[key] then
            return false
        end
        if itemRef ~= "" then
            seenEquipmentRefs[key] = true
        end

        rows[#rows + 1] = {
            sourceType = "equipment",
            category = "equipment",
            name = row.name,
            itemName = row.itemName,
            itemRef = row.itemRef,
            slotKey = row.slotKey,
            summaryText = row.summaryText,
            authoredDescriptionText = row.authoredDescriptionText,
            descriptionText = row.descriptionText,
            descriptionSource = row.descriptionSource,
            icon = trimString(row.icon) ~= "" and row.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
            dataset = row.dataset,
            datasetId = row.datasetId,
            datasetName = row.datasetName,
            item = row.item,
            payload = row.payload or row.equipmentTrait,
            equipmentTrait = row.equipmentTrait,
            isActive = true,
            isMissing = false,
            conditionFailureText = row.conditionFailureText,
        }
        return true
    end

    for index = 1, #learnedTraits do
        if appendProfileTraitRow(learnedTraits[index]) then
            appendedLearnedCount = appendedLearnedCount + 1
        end
    end

    for index = 1, #activeTraits do
        if appendProfileTraitRow(activeTraits[index]) then
            appendedActiveCount = appendedActiveCount + 1
        end
    end

    for index = 1, #equippedTraits do
        if appendProfileEquipmentRow(equippedTraits[index]) then
            appendedEquipmentCount = appendedEquipmentCount + 1
        end
    end

    if self:IsTraitCategoryAllowed("consumable") then
        for index = 1, #availableConsumables do
            local row = availableConsumables[index]
            local item = row and row.item or nil
            if row and item and matchesRequiredTags(item.tags) then
                local itemRef = ensureString(row.itemRef)
                if itemRef == "" or not seenConsumableRefs[itemRef] then
                    if itemRef ~= "" then
                        seenConsumableRefs[itemRef] = true
                    end
                    rows[#rows + 1] = {
                        sourceType = "consumable",
                        itemRef = row.itemRef,
                        sourceIndex = row.sourceIndex,
                        category = "consumable",
                        name = row.name,
                        itemName = row.itemName,
                        traitName = row.traitName,
                        summaryText = row.summaryText,
                        authoredDescriptionText = row.authoredDescriptionText,
                        descriptionText = row.descriptionText,
                        descriptionSource = row.descriptionSource,
                        icon = trimString(row.icon) ~= "" and row.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
                        dataset = row.dataset,
                        datasetId = row.datasetId,
                        datasetName = row.datasetName,
                        item = item,
                        resolvedItem = row.resolvedItem,
                        phase = row.phase,
                        payload = row.payload or row.consumableTrait,
                        sourceIndices = row.sourceIndices,
                        count = tonumber(row.count) or 1,
                        isToggleable = row.isToggleable == true,
                        isActive = row.isActive == true,
                        isMissing = false,
                        conditionFailureText = row.conditionFailureText,
                    }
                    appendedConsumableCount = appendedConsumableCount + 1
                end
            end
        end
    end

    return sortTraitRows(rows)
end

function Client:BuildActiveTraitEntries(eventState)
    local cache = getTraitSourceCache(self)
    local appliedConsumables = self:GetAppliedConsumableTraitsForEvent(eventState)
    return buildActiveTraitEntriesFromSources(self, eventState, cache.activeTraits or {}, cache.equippedTraits or {}, appliedConsumables)
end

local function buildRegisteredTraitCombatEvents(activeEntries)
    local registered = {}

    for index = 1, #(activeEntries or {}) do
        local activeEntry = activeEntries[index]
        local payload = activeEntry and activeEntry.payload or nil
        if type(payload) ~= "table" or #(payload.events or {}) == 0 then
            logTraitRegistrationDebug("registered-events-skipped", {
                sourceType = activeEntry and activeEntry.sourceType or "unknown",
                name = activeEntry and activeEntry.name or nil,
                itemName = activeEntry and activeEntry.itemName or nil,
                itemRef = activeEntry and activeEntry.itemRef or nil,
                traitRef = activeEntry and activeEntry.traitRef or nil,
                payload = payload,
                reason = type(payload) ~= "table" and "missing-payload" or "no-events",
            })
        end
        for eventIndex = 1, #(payload and payload.events or {}) do
            local eventEntry = payload.events[eventIndex]
            local combatEventId = string.lower(ensureString(eventEntry and eventEntry.combatEventId))
            if combatEventId ~= "" then
                local bucket = registered[combatEventId]
                if type(bucket) ~= "table" then
                    bucket = {}
                    registered[combatEventId] = bucket
                end
                bucket[#bucket + 1] = {
                    source = activeEntry,
                    payload = payload,
                    event = eventEntry,
                }
                logTraitRegistrationDebug("registered-event-added", {
                    sourceType = activeEntry and activeEntry.sourceType or "unknown",
                    name = activeEntry and activeEntry.name or nil,
                    itemName = activeEntry and activeEntry.itemName or nil,
                    itemRef = activeEntry and activeEntry.itemRef or nil,
                    traitRef = activeEntry and activeEntry.traitRef or nil,
                    payload = payload,
                    reason = combatEventId,
                })
            else
                logTraitRegistrationDebug("registered-event-skipped", {
                    sourceType = activeEntry and activeEntry.sourceType or "unknown",
                    name = activeEntry and activeEntry.name or nil,
                    itemName = activeEntry and activeEntry.itemName or nil,
                    itemRef = activeEntry and activeEntry.itemRef or nil,
                    traitRef = activeEntry and activeEntry.traitRef or nil,
                    payload = payload,
                    reason = "missing-combatEventId",
                })
            end
        end
    end

    return registered
end

function Client:RefreshTraitRuntimeEntries(eventState)
    if type(eventState) ~= "table" or eventState.active ~= true then
        return nil
    end

    local state = self:GetTraitRuntimeState(eventState.id, true)
    if not state then
        return nil
    end

    local ownerUnit = getLocalTraitOwnerUnit(eventState)
    local ownerEventId = math.floor(tonumber(ownerUnit and ownerUnit.eventID) or 0)
    local _, configurationRevision = getTraitSourceCache(self)
    local consumableRevision = #(state.appliedConsumableTraits or {})
    if state.ownerEventId == ownerEventId
        and tonumber(state.compiledConfigurationRevision) == configurationRevision
        and tonumber(state.compiledConsumableRevision) == consumableRevision
        and type(state.activeEntries) == "table"
        and type(state.registeredCombatEvents) == "table"
    then
        return state
    end

    state.ownerEventId = ownerEventId
    state.compiledConfigurationRevision = configurationRevision
    state.compiledConsumableRevision = consumableRevision
    state.activeEntries = self:BuildActiveTraitEntries(eventState)
    state.registeredCombatEvents = buildRegisteredTraitCombatEvents(state.activeEntries)
    logTraitRuntimeRefreshDebug(eventState, state)
    return state
end

function Client:RefreshTraitResolvedState(eventState, reason)
    local auraManager = self.Spellcasting and self.Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.RefreshLocalPlayerDerivedState) == "function" then
        auraManager:RefreshLocalPlayerDerivedState(eventState)
    end

    if type(self.QueueEventWidgetRefresh) == "function" then
        self:QueueEventWidgetRefresh(reason or "traits")
    end
    bumpTooltipContextRevisions(eventState)
    if type(self.InvalidatePendingSpellTargetingDisplayState) == "function" then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    if type(self.QueueTargetingWidgetRefresh) == "function" then
        self:QueueTargetingWidgetRefresh(reason or "traits")
    end
    if type(self.QueueActionBarRefresh) == "function" then
        self:QueueActionBarRefresh(reason or "traits")
    elseif type(self.RefreshActionBarWidget) == "function" then
        self:RefreshActionBarWidget(reason or "traits")
    end

    local profileWindow = self.UI and self.UI.Profile and self.UI.Profile.Window or nil
    local instance = type(profileWindow) == "table" and profileWindow._singleton or nil
    if type(instance) == "table" then
        if type(instance.RefreshVisible) == "function" then
            instance:RefreshVisible()
        elseif type(instance.Refresh) == "function" then
            instance:Refresh()
        end
    end
end

function Client:ResolveTraitAutoAuraTargets(eventState, ownerUnit, targetScope)
    local targets = {}
    local ownerEventId = tonumber(ownerUnit and ownerUnit.eventID) or 0
    if ownerEventId <= 0 then
        return targets
    end

    if targetScope == "self" then
        targets[1] = ownerUnit
        return targets
    end

    local ownerTeam = tonumber(ownerUnit and ownerUnit.team) or 0
    for index = 1, #(eventState and eventState.units or {}) do
        local unit = eventState.units[index]
        local candidateEventId = tonumber(unit and unit.eventID) or 0
        if candidateEventId > 0 and candidateEventId ~= ownerEventId then
            local candidateTeam = tonumber(unit and unit.team) or 0
            if targetScope == "all_allies" and candidateTeam == ownerTeam then
                targets[#targets + 1] = unit
            elseif targetScope == "all_enemies" and candidateTeam ~= ownerTeam then
                targets[#targets + 1] = unit
            end
        end
    end

    return targets
end

function Client:ApplyTraitAutomaticAuras(eventState, ownerUnit, payload, sourceEntry, targetUnitOverride)
    local auraManager = self.Spellcasting and self.Spellcasting.AuraManager or nil
    if type(auraManager) ~= "table" or type(auraManager.ApplyAuraFromContext) ~= "function" then
        return false
    end

    local changed = false
    for index = 1, #(payload and payload.automaticAuras or {}) do
        local automaticAura = payload.automaticAuras[index]
        local targets = type(targetUnitOverride) == "table" and { targetUnitOverride }
            or self:ResolveTraitAutoAuraTargets(eventState, ownerUnit, automaticAura and automaticAura.targetScope or "self")
        for targetIndex = 1, #targets do
            changed = auraManager:ApplyAuraFromContext(self, {
                eventState = eventState,
                casterUnit = ownerUnit,
                targetUnit = targets[targetIndex],
                dataset = sourceEntry and sourceEntry.dataset or nil,
                datasetId = sourceEntry and sourceEntry.datasetId or nil,
            }, automaticAura.auraRef, automaticAura.stacks, automaticAura.turns, automaticAura.powerLevel) or changed
        end
    end

    return changed
end

function Client:ApplyTraitPayloadToEvent(eventState, payload, options)
    if type(eventState) ~= "table" or eventState.active ~= true or type(payload) ~= "table" then
        return false
    end

    local changed = false
    local state = self:GetTraitRuntimeState(eventState.id, true)
    local localUnit = getLocalTraitOwnerUnit(eventState)
    local persist = type(options) == "table" and options.persist ~= false
    local item = options and options.item or nil
    local itemRef = options and options.itemRef or nil
    local conditionState = evaluateRuntimeItemAndPayloadConditions(item, payload, {
        eventState = eventState,
        item = item,
        itemRef = itemRef,
        casterUnit = localUnit,
    })
    if conditionState.passed ~= true then
        return false
    end
    if persist then
        local itemName = trimString(item and item.name)
        local itemIcon = trimString(item and item.icon)
        state.appliedConsumableTraits[#state.appliedConsumableTraits + 1] = {
            sourceType = "consumable",
            category = "consumable",
            name = itemName ~= "" and itemName or buildPayloadDisplayName(payload, "Consumable Trait"),
            itemName = itemName,
            traitName = "",
            icon = itemIcon,
            payload = payload,
            sourceIndex = options and options.sourceIndex or nil,
            itemRef = itemRef,
            item = item,
        }
        changed = true
    end

    if type(localUnit) == "table" and self:ApplyTraitAutomaticAuras(eventState, localUnit, payload) then
        changed = true
    end

    if #(payload.statBonuses or {}) > 0 or #(payload.skillBonuses or {}) > 0 or #(payload.events or {}) > 0 then
        changed = true
    end

    if changed then
        self:RefreshTraitRuntimeEntries(eventState)
        if self.SyncAutomaticTraitAuras then
            self:SyncAutomaticTraitAuras(eventState, { suppressResolvedRefresh = true })
        end
        self:RefreshTraitResolvedState(eventState, "trait-apply")
    end

    return changed
end

local function resolveTraitTriggeredTarget(ownerUnit, triggerTarget, eventSourceUnit, eventOtherUnit)
    if triggerTarget == "event_source" then
        return eventSourceUnit
    end
    if triggerTarget == "aura_caster" or triggerTarget == "aura_target" then
        return ownerUnit
    end

    return eventOtherUnit
end

function Client:HandleTraitCombatEvent(context)
    local eventState = type(context) == "table" and context.eventState or nil
    local recipientEventId = tonumber(type(context) == "table" and context.recipientEventId or nil) or 0
    if type(eventState) ~= "table" or eventState.active ~= true or recipientEventId <= 0 then
        return false
    end

    local ownerUnit = getLocalTraitOwnerUnit(eventState)
    local ownerEventId = math.floor(tonumber(ownerUnit and ownerUnit.eventID) or 0)
    local state = self:GetTraitRuntimeState(eventState.id, false)
    local cachedOwnerEventId = math.floor(tonumber(state and state.ownerEventId) or 0)
    if type(state) ~= "table"
        or ownerEventId <= 0
        or cachedOwnerEventId <= 0
        or cachedOwnerEventId ~= ownerEventId
    then
        state = self:RefreshTraitRuntimeEntries(eventState)
        cachedOwnerEventId = math.floor(tonumber(state and state.ownerEventId) or 0)
    end
    if type(state) ~= "table" then
        return false
    end

    logTraitEventLookupDebug(
        type(context) == "table" and context.combatEventId or nil,
        recipientEventId,
        cachedOwnerEventId > 0 and cachedOwnerEventId or ownerEventId,
        state.registeredCombatEvents
    )

    if type(ownerUnit) ~= "table" then
        logTraitDispatchDebug("missing-owner-unit", {
            combatEventId = type(context) == "table" and context.combatEventId or nil,
            recipientEventId = recipientEventId,
            ownerEventId = cachedOwnerEventId,
            eventSourceName = type(context) == "table" and type(context.eventSourceUnit) == "table" and context.eventSourceUnit.name or nil,
            eventOtherName = type(context) == "table" and type(context.eventOtherUnit) == "table" and context.eventOtherUnit.name or nil,
            registrationCount = 0,
        })
        return false
    end

    ownerEventId = math.floor(tonumber(ownerUnit.eventID) or 0)
    if ownerEventId <= 0 or ownerEventId ~= recipientEventId then
        logTraitDispatchDebug("owner-recipient-mismatch", {
            combatEventId = type(context) == "table" and context.combatEventId or nil,
            recipientEventId = recipientEventId,
            ownerEventId = ownerEventId,
            eventSourceName = type(context) == "table" and type(context.eventSourceUnit) == "table" and context.eventSourceUnit.name or nil,
            eventOtherName = type(context) == "table" and type(context.eventOtherUnit) == "table" and context.eventOtherUnit.name or nil,
            registrationCount = 0,
        })
        return false
    end

    local auraManager = self.Spellcasting and self.Spellcasting.AuraManager or nil
    local combat = self.Combat or (Addon.Client and Addon.Client.Combat) or nil
    if (type(auraManager) ~= "table" or type(auraManager.GetEffect) ~= "function")
        and (type(combat) ~= "table" or type(combat.GetEffect) ~= "function")
    then
        return false
    end

    local combatEventId = string.lower(ensureString(type(context) == "table" and context.combatEventId or ""))
    if combatEventId == "" then
        return false
    end

    local changed = false
    local registeredEvents = type(state.registeredCombatEvents) == "table" and state.registeredCombatEvents[combatEventId] or nil
    local registrationCount = #(registeredEvents or {})
    if registrationCount == 0 then
        logTraitDispatchDebug("no-registered-events", {
            combatEventId = combatEventId,
            recipientEventId = recipientEventId,
            ownerEventId = ownerEventId,
            eventSourceName = type(context) == "table" and type(context.eventSourceUnit) == "table" and context.eventSourceUnit.name or nil,
            eventOtherName = type(context) == "table" and type(context.eventOtherUnit) == "table" and context.eventOtherUnit.name or nil,
            registrationCount = 0,
        })
    else
        logTraitDispatchDebug("registered-events-found", {
            combatEventId = combatEventId,
            recipientEventId = recipientEventId,
            ownerEventId = ownerEventId,
            eventSourceName = type(context) == "table" and type(context.eventSourceUnit) == "table" and context.eventSourceUnit.name or nil,
            eventOtherName = type(context) == "table" and type(context.eventOtherUnit) == "table" and context.eventOtherUnit.name or nil,
            registrationCount = registrationCount,
        })
    end
    for index = 1, #(registeredEvents or {}) do
        local registeredEntry = registeredEvents[index]
        local eventEntry = registeredEntry and registeredEntry.event or nil
        local targetUnit = resolveTraitTriggeredTarget(
            ownerUnit,
            ensureString(eventEntry and eventEntry.triggerTarget),
            type(context) == "table" and context.eventSourceUnit or nil,
            type(context) == "table" and context.eventOtherUnit or nil
        )
        if type(targetUnit) ~= "table" then
            logTraitProcDebug(
                registeredEntry,
                ownerUnit,
                nil,
                combatEventId,
                nil,
                normalizeChancePercent(eventEntry and eventEntry.chance),
                nil,
                "no-target",
                nil
            )
        else
            local procPassed, normalizedChance, chanceRoll = evaluateProcChance(eventEntry and eventEntry.chance)
            if not procPassed then
                logTraitProcDebug(
                    registeredEntry,
                    ownerUnit,
                    targetUnit,
                    combatEventId,
                    nil,
                    normalizedChance,
                    chanceRoll,
                    "chance-failed",
                    nil
                )
            else
                local effectKeys = sortedNumericKeys(eventEntry and eventEntry.effects or nil)
                for effectKeyIndex = 1, #effectKeys do
                    local effectIndex = effectKeys[effectKeyIndex].key
                    local effect = eventEntry.effects[effectIndex]
                    local effectType = effect and effect.type or nil
                    local contract = nil
                    if effectType == "damage" then
                        contract = type(auraManager) == "table" and type(auraManager.GetEffect) == "function" and auraManager:GetEffect(effectType) or nil
                        if not contract then
                            contract = type(combat) == "table" and type(combat.GetEffect) == "function" and combat:GetEffect(effectType) or nil
                        end
                    else
                        contract = type(combat) == "table" and type(combat.GetEffect) == "function" and combat:GetEffect(effectType) or nil
                        if not contract then
                            contract = type(auraManager) == "table" and type(auraManager.GetEffect) == "function" and auraManager:GetEffect(effectType) or nil
                        end
                    end
                    if contract and type(contract.Execute) == "function" then
                        local applied, result = contract:Execute({
                            client = self,
                            eventState = eventState,
                            sessionState = type(context) == "table" and context.sessionState or (self.GetState and self:GetState() or nil),
                            suppressCombatEvents = true,
                            actionContext = type(context) == "table" and context.actionContext or nil,
                            dataset = type(registeredEntry) == "table" and type(registeredEntry.source) == "table" and registeredEntry.source.dataset or nil,
                            datasetId = type(registeredEntry) == "table" and type(registeredEntry.source) == "table" and registeredEntry.source.datasetId or nil,
                            sourceDatasetId = type(registeredEntry) == "table" and type(registeredEntry.source) == "table" and registeredEntry.source.datasetId or nil,
                            casterUnit = ownerUnit,
                            targetUnit = targetUnit,
                            eventSourceUnit = type(context) == "table" and context.eventSourceUnit or nil,
                            eventOtherUnit = type(context) == "table" and context.eventOtherUnit or nil,
                            healthResourceRef = eventState and eventState.healthResourceRef or nil,
                        }, effect)
                        if applied then
                            changed = true
                        end
                        local spellcasting = self.Spellcasting or nil
                        if type(result) == "table"
                            and type(spellcasting) == "table"
                            and type(spellcasting.ProcessResolvedEffectResult) == "function"
                        then
                            spellcasting.ProcessResolvedEffectResult(
                                self,
                                eventState,
                                ownerUnit,
                                targetUnit,
                                { effect = effect },
                                result
                            )
                        end
                        if type(result) == "table"
                            and tostring(result.effectType or effectType or "") == "damage"
                        then
                            local registeredTriggeredDamage = false
                            if type(combat) == "table"
                                and type(combat.RegisterTriggeredActionBonusDamage) == "function"
                            then
                                registeredTriggeredDamage = combat:RegisterTriggeredActionBonusDamage(
                                    type(context) == "table" and context.actionContext or nil,
                                    targetUnit,
                                    result,
                                    effect,
                                    combatEventId
                                ) == true
                            end
                            if not registeredTriggeredDamage then
                                emitTriggeredDamageCombatLog(self, eventState, ownerUnit, targetUnit, result, effect)
                            end
                        end
                        logTraitProcDebug(
                            registeredEntry,
                            ownerUnit,
                            targetUnit,
                            combatEventId,
                            effect,
                            normalizedChance,
                            chanceRoll,
                            applied and "executed" or "resolved-no-apply",
                            result
                        )
                    else
                        logTraitProcDebug(
                            registeredEntry,
                            ownerUnit,
                            targetUnit,
                            combatEventId,
                            effect,
                            normalizedChance,
                            chanceRoll,
                            "missing-contract",
                            nil
                        )
                    end
                end
            end
        end
    end

    return changed
end

function Client:SyncAutomaticTraitAuras(eventState, options)
    local localUnit = getLocalTraitOwnerUnit(eventState)
    if type(eventState) ~= "table" or eventState.active ~= true or type(localUnit) ~= "table" then
        return false
    end

    local state = self:RefreshTraitRuntimeEntries(eventState)
    state.automaticAuraStateByKey = type(state.automaticAuraStateByKey) == "table" and state.automaticAuraStateByKey or {}
    local auraManager = self.Spellcasting and self.Spellcasting.AuraManager or nil
    local changed = false
    local ownerEventId = math.floor(tonumber(localUnit.eventID) or 0)
    local desired = {}
    local activeTraits = state.activeEntries or {}
    for index = 1, #activeTraits do
        local sourceEntry = activeTraits[index]
        local payload = sourceEntry and sourceEntry.payload or nil
        for auraIndex = 1, #(payload and payload.automaticAuras or {}) do
            local automaticAura = payload.automaticAuras[auraIndex]
            local targets = self:ResolveTraitAutoAuraTargets(eventState, localUnit, automaticAura and automaticAura.targetScope or "self")
            local qualifiedAuraRef = buildQualifiedAutomaticAuraRef(self, sourceEntry, automaticAura and automaticAura.auraRef or nil)
            local sourceKey = buildAutomaticTraitAuraSourceKey(sourceEntry, auraIndex)
            for targetIndex = 1, #targets do
                local targetUnit = targets[targetIndex]
                local targetEventId = math.floor(tonumber(targetUnit and targetUnit.eventID) or 0)
                if qualifiedAuraRef ~= "" and ownerEventId > 0 and targetEventId > 0 then
                    local key = buildAutomaticTraitAuraStateKey(qualifiedAuraRef, ownerEventId, targetEventId, sourceKey)
                    desired[key] = {
                        auraRef = qualifiedAuraRef,
                        sourceAuraRef = automaticAura.auraRef,
                        casterEventId = ownerEventId,
                        targetEventId = targetEventId,
                        stacks = automaticAura.stacks,
                        turns = automaticAura.turns,
                        powerLevel = automaticAura.powerLevel,
                        targetUnit = targetUnit,
                        sourceEntry = sourceEntry,
                    }
                end
            end
        end
    end

    if type(auraManager) == "table" and type(auraManager.RemoveAura) == "function" then
        for key, entry in pairs(state.automaticAuraStateByKey) do
            if not desired[key] then
                changed = auraManager:RemoveAura(self, eventState, entry.auraRef, entry.casterEventId, entry.targetEventId) or changed
                state.automaticAuraStateByKey[key] = nil
            end
        end
    end

    for key, entry in pairs(desired) do
        if not state.automaticAuraStateByKey[key] then
            changed = self:ApplyTraitAutomaticAuras(eventState, localUnit, {
                automaticAuras = {{
                    auraRef = entry.sourceAuraRef,
                    stacks = entry.stacks,
                    turns = entry.turns,
                    powerLevel = entry.powerLevel,
                }},
            }, entry.sourceEntry, entry.targetUnit) or changed
        end
        state.automaticAuraStateByKey[key] = {
            auraRef = entry.auraRef,
            casterEventId = entry.casterEventId,
            targetEventId = entry.targetEventId,
        }
    end

    if changed and not (type(options) == "table" and options.suppressResolvedRefresh == true) then
        self:RefreshTraitResolvedState(eventState, "trait-auto-aura")
    end
    return changed
end

function Client:SyncEventAuras(eventState, options)
    local localUnit = getLocalTraitOwnerUnit(eventState)
    if type(eventState) ~= "table" or eventState.active ~= true or type(localUnit) ~= "table" then
        return false
    end

    local auraManager = self.Spellcasting and self.Spellcasting.AuraManager or nil
    if type(auraManager) ~= "table"
        or type(auraManager.UpsertAura) ~= "function"
        or type(auraManager.RemoveAura) ~= "function"
    then
        return false
    end

    local state = self:GetTraitRuntimeState(eventState.id, true)
    state.appliedEventAuras = type(state.appliedEventAuras) == "table" and state.appliedEventAuras or {}

    local localEventId = math.floor(tonumber(localUnit.eventID) or 0)
    local localTeam = math.floor(tonumber(localUnit.team) or 0)
    if localEventId <= 0 or localTeam <= 0 then
        return false
    end

    local desired = {}
    for index = 1, #(eventState.eventAuras or {}) do
        local entry = eventState.eventAuras[index]
        local auraRef = trimString(entry and entry.auraRef)
        if auraRef ~= "" and eventAuraAppliesToTeam(eventState, entry, localTeam) then
            desired[buildEventAuraStateKey(auraRef, localEventId)] = auraRef
        end
    end

    local changed = false
    for key, auraRef in pairs(state.appliedEventAuras) do
        if not desired[key] then
            changed = auraManager:RemoveAura(self, eventState, auraRef, localEventId, localEventId) or changed
            state.appliedEventAuras[key] = nil
        end
    end

    for key, auraRef in pairs(desired) do
        if not state.appliedEventAuras[key] then
            local applied = auraManager:UpsertAura(self, {
                eventState = eventState,
                auraRef = auraRef,
                stacks = 1,
                turns = 9999,
                powerLevel = 0,
                casterEventId = localEventId,
                targetEventId = localEventId,
                fullState = true,
            })
            if applied then
                state.appliedEventAuras[key] = auraRef
                changed = true
            end
        end
    end

    if changed and not (type(options) == "table" and options.suppressResolvedRefresh == true) then
        self:RefreshTraitResolvedState(eventState, "event-aura")
    end
    return changed
end

function Client:ActivateEventTraits(eventState)
    local totalStartTime = getTimingNowMilliseconds()
    local localUnit = getLocalTraitOwnerUnit(eventState)
    if type(eventState) ~= "table" or eventState.active ~= true or type(localUnit) ~= "table" then
        return false
    end

    local changed = false
    local timingParts = totalStartTime > 0 and {} or nil
    if self.RefreshTraitRuntimeEntries then
        local refreshStartTime = timingParts and getTimingNowMilliseconds() or nil
        self:RefreshTraitRuntimeEntries(eventState)
        if refreshStartTime then
            timingParts[#timingParts + 1] = {
                label = "refresh-runtime-initial",
                elapsedMs = getTimingNowMilliseconds() - refreshStartTime,
                thresholdMs = 15,
            }
        end
    end
    if self.SyncAutomaticTraitAuras then
        local syncAutomaticStartTime = timingParts and getTimingNowMilliseconds() or nil
        changed = self:SyncAutomaticTraitAuras(eventState, { suppressResolvedRefresh = true }) or changed
        if syncAutomaticStartTime then
            timingParts[#timingParts + 1] = {
                label = "sync-automatic-auras",
                elapsedMs = getTimingNowMilliseconds() - syncAutomaticStartTime,
                thresholdMs = 15,
            }
        end
    end
    if self.SyncEventAuras then
        local syncEventStartTime = timingParts and getTimingNowMilliseconds() or nil
        changed = self:SyncEventAuras(eventState, { suppressResolvedRefresh = true }) or changed
        if syncEventStartTime then
            timingParts[#timingParts + 1] = {
                label = "sync-event-auras",
                elapsedMs = getTimingNowMilliseconds() - syncEventStartTime,
                thresholdMs = 15,
            }
        end
    end
    if changed and self.RefreshTraitResolvedState then
        local resolvedRefreshStartTime = timingParts and getTimingNowMilliseconds() or nil
        self:RefreshTraitResolvedState(eventState, "trait-activate")
        if resolvedRefreshStartTime then
            timingParts[#timingParts + 1] = {
                label = "refresh-resolved",
                elapsedMs = getTimingNowMilliseconds() - resolvedRefreshStartTime,
                thresholdMs = 15,
            }
        end
    end
    if timingParts then
        logTimingParts("ActivateEventTraits", timingParts, getTimingNowMilliseconds() - totalStartTime, 25)
    end
    return changed
end

function Client:CollectEligiblePhaseConsumables(eventState, phase)
    local rows = {}
    if self:IsTraitCategoryAllowed("consumable") ~= true or type(eventState) ~= "table" or eventState.active ~= true then
        return rows
    end

    local displayItems = Inventory.GetDisplayItems and Inventory.GetDisplayItems() or {}
    local rowsByItemRef = {}
    local function appendRange(startIndex, endIndex)
        for index = startIndex, math.min(endIndex, #displayItems) do
            local resolved = displayItems[index]
            local item = resolved and resolved.item or nil
            local payload = item and item.consumableTrait or nil
            if resolved
                and resolved.isMissing ~= true
                and type(payload) == "table"
                and ensureString(payload.phase) == ensureString(phase)
                and matchesRequiredTags(item and item.tags or nil)
            then
                local itemRef = resolved.datasetId and resolved.itemId and ("%s:%s"):format(tostring(resolved.datasetId), tostring(resolved.itemId)) or ensureString(item and item.name)
                local itemName = trimString(item and item.name)
                local conditionState = evaluateRuntimeItemAndPayloadConditions(item, payload, {
                    eventState = eventState,
                    item = item,
                    itemRef = itemRef,
                })
                local row = rowsByItemRef[itemRef]
                if not row then
                    row = {
                        itemRef = itemRef,
                        sourceIndex = resolved.sourceIndex,
                        sourceIndices = {},
                        resolvedItem = resolved,
                        item = item,
                        payload = payload,
                        icon = trimString(item and item.icon),
                        label = itemName ~= "" and itemName or buildPayloadDisplayName(payload, "Consumable"),
                        itemName = itemName,
                        traitName = "",
                        description = trimString(payload.description) ~= "" and trimString(payload.description) or trimString(item and item.description),
                        count = 0,
                        conditionFailureText = conditionState and conditionState.failureText or "",
                        unavailableReason = conditionState and conditionState.passed ~= true and conditionState.failureText or nil,
                    }
                    rowsByItemRef[itemRef] = row
                    rows[#rows + 1] = row
                end

                row.count = (tonumber(row.count) or 0) + math.max(1, math.floor(tonumber(resolved.quantity) or 1))
                row.sourceIndices[#row.sourceIndices + 1] = resolved.sourceIndex
            end
        end
    end

    appendRange(1, #displayItems)

    local equippedSlots = getConsumableEquippedSlotKeys()
    for index = 1, #rows do
        local row = rows[index]
        if classifyConsumableRow(row).kind == "enhancement" then
            local validSlotRefs = row and row.item and row.item.validSlotRefs or nil
            local eligibleSlotKeys = getEnhancementEligibleSlotKeys(row, equippedSlots)
            row.enhancementEligibleSlotKeys = eligibleSlotKeys
            if ensureString(row.unavailableReason) ~= "" then
                row.unavailableReason = row.unavailableReason
            elseif #(validSlotRefs or {}) == 0 then
                row.unavailableReason = "Enhancements require at least one valid slot."
            elseif #eligibleSlotKeys == 0 then
                row.unavailableReason = "Requires an equipped item in one of its valid slots."
            else
                row.unavailableReason = nil
            end
        else
            row.unavailableReason = nil
        end
    end

    table.sort(rows, function(left, right)
        return string.lower(ensureString(left and left.label)) < string.lower(ensureString(right and right.label))
    end)

    return rows
end

local function appendEligiblePhaseConsumableRows(rows, rowsByItemRef, displayItems, eventState, phase, startIndex, endIndex)
    for index = math.max(1, tonumber(startIndex) or 1), math.min(math.max(0, tonumber(endIndex) or 0), #(displayItems or {})) do
        local resolved = displayItems[index]
        local item = resolved and resolved.item or nil
        local payload = item and item.consumableTrait or nil
        if resolved
            and resolved.isMissing ~= true
            and type(payload) == "table"
            and ensureString(payload.phase) == ensureString(phase)
            and matchesRequiredTags(item and item.tags or nil)
        then
            local itemRef = resolved.datasetId and resolved.itemId and ("%s:%s"):format(tostring(resolved.datasetId), tostring(resolved.itemId)) or ensureString(item and item.name)
            local itemName = trimString(item and item.name)
            local conditionState = evaluateRuntimeItemAndPayloadConditions(item, payload, {
                eventState = eventState,
                item = item,
                itemRef = itemRef,
            })
            local row = rowsByItemRef[itemRef]
            if not row then
                row = {
                    itemRef = itemRef,
                    sourceIndex = resolved.sourceIndex,
                    sourceIndices = {},
                    resolvedItem = resolved,
                    item = item,
                    payload = payload,
                    icon = trimString(item and item.icon),
                    label = itemName ~= "" and itemName or buildPayloadDisplayName(payload, "Consumable"),
                    itemName = itemName,
                    traitName = "",
                    description = trimString(payload.description) ~= "" and trimString(payload.description) or trimString(item and item.description),
                    count = 0,
                    conditionFailureText = conditionState and conditionState.failureText or "",
                    unavailableReason = conditionState and conditionState.passed ~= true and conditionState.failureText or nil,
                }
                rowsByItemRef[itemRef] = row
                rows[#rows + 1] = row
            end

            row.count = (tonumber(row.count) or 0) + math.max(1, math.floor(tonumber(resolved.quantity) or 1))
            row.sourceIndices[#row.sourceIndices + 1] = resolved.sourceIndex
        end
    end
end

local function finalizeEligiblePhaseConsumableRows(rows)
    local equippedSlots = getConsumableEquippedSlotKeys()
    for index = 1, #rows do
        local row = rows[index]
        if classifyConsumableRow(row).kind == "enhancement" then
            local validSlotRefs = row and row.item and row.item.validSlotRefs or nil
            local eligibleSlotKeys = getEnhancementEligibleSlotKeys(row, equippedSlots)
            row.enhancementEligibleSlotKeys = eligibleSlotKeys
            if ensureString(row.unavailableReason) ~= "" then
                row.unavailableReason = row.unavailableReason
            elseif #(validSlotRefs or {}) == 0 then
                row.unavailableReason = "Enhancements require at least one valid slot."
            elseif #eligibleSlotKeys == 0 then
                row.unavailableReason = "Requires an equipped item in one of its valid slots."
            else
                row.unavailableReason = nil
            end
        else
            row.unavailableReason = nil
        end
    end

    table.sort(rows, function(left, right)
        return string.lower(ensureString(left and left.label)) < string.lower(ensureString(right and right.label))
    end)

    return rows
end

local function buildConsumablePromptTimingTotal(parts)
    local total = 0
    for index = 1, #(parts or {}) do
        total = total + math.max(0, tonumber(parts[index] and parts[index].elapsedMs) or 0)
    end
    return total
end

local function showPhaseConsumablePrompt(targetClient, eventState, phase, state, rows, onFinished, timingParts)
    if #rows == 0 or not (UI.Popup and UI.Popup.ShowConfirmation) then
        if type(state) == "table" and type(state.promptedPhases) == "table" then
            state.promptedPhases[phase] = nil
        end
        if timingParts then
            logTimingParts(
                ("PromptPhaseConsumableTraits:%s"):format(tostring(phase or "unknown")),
                timingParts,
                buildConsumablePromptTimingTotal(timingParts),
                25
            )
        end
        if type(onFinished) == "function" then
            onFinished(false)
        end
        return false
    end

    local lookupByChoice = {}
    local gridItems = {}
    local gridStartTime = timingParts and getTimingNowMilliseconds() or nil
    for index = 1, #rows do
        local row = rows[index]
        local value = ensureString(row.itemRef)
        gridItems[#gridItems + 1] = {
            label = row.label,
            value = value,
            icon = row.icon,
            count = row.count,
            disabled = ensureString(row.unavailableReason) ~= "",
        }
        lookupByChoice[value] = row
    end
    if gridStartTime then
        timingParts[#timingParts + 1] = {
            label = "build-grid",
            elapsedMs = getTimingNowMilliseconds() - gridStartTime,
            thresholdMs = 15,
        }
    end

    local preferredStartTime = timingParts and getTimingNowMilliseconds() or nil
    local selectedChoices = targetClient.GetPreferredConsumableChoiceValues and targetClient:GetPreferredConsumableChoiceValues(rows) or {}
    if preferredStartTime then
        timingParts[#timingParts + 1] = {
            label = "preferred",
            elapsedMs = getTimingNowMilliseconds() - preferredStartTime,
            thresholdMs = 15,
        }
    end

    local popupStartTime = timingParts and getTimingNowMilliseconds() or nil
    UI.Popup:ShowConfirmation({
        title = "Consumables",
        message = phase == "event_end"
            and "Choose one or more consumables to apply before the event ends."
            or "Choose one or more consumables to apply for this event.",
        confirmText = "Apply",
        cancelText = "Skip",
        choiceLabel = "Consumables",
        hideGridLabel = true,
        gridItems = gridItems,
        selectedChoices = selectedChoices,
        gridVisibleColumns = 3,
        gridVisibleRows = 2,
        requireChoice = true,
        getGridStatusText = function(currentSelectedValues)
            return targetClient:GetConsumableSelectionSummaryText(rows, currentSelectedValues)
        end,
        gridDisabledProvider = function(item, currentSelectedValues)
            return getConsumableSelectionDisabledReason(rows, currentSelectedValues, item and item.value) ~= nil
        end,
        gridTooltipProvider = function(item, owner)
            local row = lookupByChoice[ensureString(item and item.value)]
            return buildConsumablePopupTooltip(row, owner)
        end,
        onGridSelectionChanged = function(value, selecting, currentSelectedValues)
            return targetClient:TryToggleConsumableSelection(rows, currentSelectedValues, value)
        end,
        onConfirm = function(spec)
            local selectedValues = normalizeSelectedValues(spec and spec.selectedChoices or {}, lookupByChoice)
            local appliedAny = false

            for index = 1, #selectedValues do
                local selected = lookupByChoice[ensureString(selectedValues[index])]
                if selected then
                    local applied = targetClient:ApplyTraitPayloadToEvent(eventState, selected.payload, {
                        persist = phase ~= "event_end",
                        sourceIndex = selected.sourceIndex,
                        item = selected.item,
                    })
                    if applied and Inventory.RemoveItem then
                        local consumedSourceIndex = selected.sourceIndices and selected.sourceIndices[1] or selected.sourceIndex
                        local itemClass = getItemClass()
                        if consumedSourceIndex and Inventory.BindItem and itemClass and itemClass.IsBindOnUse and itemClass.IsBindOnUse(selected.item) then
                            local _, boundIndex = Inventory.BindItem(consumedSourceIndex, 1)
                            consumedSourceIndex = boundIndex or consumedSourceIndex
                        end
                        Inventory.RemoveItem(consumedSourceIndex)
                    end
                    appliedAny = applied or appliedAny
                end
            end

            if not appliedAny and type(state.promptedPhases) == "table" then
                state.promptedPhases[phase] = nil
            end
            if type(onFinished) == "function" then
                onFinished(appliedAny)
            end
            return appliedAny
        end,
        onCancel = function()
            if type(onFinished) == "function" then
                onFinished(false)
            end
            return false
        end,
    })
    if popupStartTime then
        timingParts[#timingParts + 1] = {
            label = "show-popup",
            elapsedMs = getTimingNowMilliseconds() - popupStartTime,
            thresholdMs = 15,
        }
    end
    if timingParts then
        logTimingParts(
            ("PromptPhaseConsumableTraits:%s"):format(tostring(phase or "unknown")),
            timingParts,
            buildConsumablePromptTimingTotal(timingParts),
            25
        )
    end

    return true
end

local function continueConsumablePromptBuild(targetClient, eventId, phase, sessionId)
    if type(targetClient) ~= "table" then
        return false
    end

    local eventState = targetClient.GetEventState and targetClient:GetEventState() or nil
    local state = targetClient.GetTraitRuntimeState and targetClient:GetTraitRuntimeState(eventId, false) or nil
    local sessions = type(state) == "table" and state.pendingPromptSessions or nil
    local session = type(sessions) == "table" and sessions[phase] or nil
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or tostring(eventState.id or "") ~= tostring(eventId or "")
        or type(session) ~= "table"
        or tonumber(session.id) ~= tonumber(sessionId)
    then
        return false
    end

    local batchStartTime = getTimingNowMilliseconds()
    local startIndex = math.max(1, tonumber(session.nextIndex) or 1)
    local endIndex = math.min(#(session.displayItems or {}), startIndex + CONSUMABLE_PROMPT_BATCH_SIZE - 1)
    appendEligiblePhaseConsumableRows(
        session.rows,
        session.rowsByItemRef,
        session.displayItems,
        eventState,
        phase,
        startIndex,
        endIndex
    )
    session.nextIndex = endIndex + 1
    session.collectElapsedMs = (tonumber(session.collectElapsedMs) or 0) + math.max(0, getTimingNowMilliseconds() - batchStartTime)

    if session.nextIndex <= #(session.displayItems or {}) then
        enqueueTask(continueConsumablePromptBuild, targetClient, eventId, phase, sessionId)
        return true
    end

    sessions[phase] = nil
    finalizeEligiblePhaseConsumableRows(session.rows)
    if type(session.timingParts) == "table" then
        session.timingParts[#session.timingParts + 1] = {
            label = "collect",
            elapsedMs = tonumber(session.collectElapsedMs) or 0,
            thresholdMs = 15,
        }
    end
    return showPhaseConsumablePrompt(
        targetClient,
        eventState,
        phase,
        state,
        session.rows,
        session.onFinished,
        session.timingParts
    )
end

function Client:TryToggleConsumableSelection(rows, selectedValues, value)
    local rowsByValue = buildConsumableRowLookup(rows)
    local normalizedValue = ensureString(value)
    local normalizedSelectedValues = normalizeSelectedValues(selectedValues, rowsByValue)
    if normalizedValue == "" or rowsByValue[normalizedValue] == nil then
        return normalizedSelectedValues, ""
    end

    local row = rowsByValue[normalizedValue]
    if ensureString(row and row.unavailableReason) ~= "" then
        return normalizedSelectedValues, ensureString(row.unavailableReason)
    end

    for index = 1, #normalizedSelectedValues do
        if normalizedSelectedValues[index] == normalizedValue then
            local nextSelectedValues = copyArray(normalizedSelectedValues)
            table.remove(nextSelectedValues, index)
            return nextSelectedValues, ""
        end
    end

    local rules = getConsumableSelectionRules()
    local counts = buildConsumableSelectionCounts(rowsByValue, normalizedSelectedValues)
    local classification = classifyConsumableRow(rowsByValue[normalizedValue])

    if classification.kind == "flask" then
        if rules.flaskLimit > 0 and counts.flask >= rules.flaskLimit then
            return normalizedSelectedValues, ("Flask limit reached (%d)."):format(rules.flaskLimit)
        end
    elseif classification.kind == "scroll" then
        if rules.scrollLimit > 0 and counts.scroll >= rules.scrollLimit then
            return normalizedSelectedValues, ("Scroll limit reached (%d)."):format(rules.scrollLimit)
        end
    elseif classification.kind == "rune" then
        if rules.runeLimit > 0 and counts.rune >= rules.runeLimit then
            return normalizedSelectedValues, ("Rune limit reached (%d)."):format(rules.runeLimit)
        end
    elseif classification.kind == "elixir" then
        if rules.elixirLimit > 0 and counts.elixir >= rules.elixirLimit then
            return normalizedSelectedValues, ("Elixir limit reached (%d)."):format(rules.elixirLimit)
        end

        if rules.elixirCategorisation == true then
            if classification.subtype == "battle" then
                if counts.battle >= 1 then
                    return normalizedSelectedValues, "Only one battle elixir can be selected."
                end
            elseif classification.subtype == "guardian" then
                if counts.guardian >= 1 then
                    return normalizedSelectedValues, "Only one guardian elixir can be selected."
                end
            elseif classification.subtype == "both" then
                if counts.battle >= 1 or counts.guardian >= 1 then
                    return normalizedSelectedValues, "A combined battle/guardian elixir conflicts with an existing elixir selection."
                end
            else
                return normalizedSelectedValues, "Elixir categorisation requires the elixir type to be Battle or Guardian."
            end
        end
    elseif classification.kind == "enhancement" then
        local _, enhancementError = buildEnhancementSlotAssignments(rowsByValue, normalizedSelectedValues, normalizedValue)
        if enhancementError then
            return normalizedSelectedValues, enhancementError
        end
    end

    local nextSelectedValues = copyArray(normalizedSelectedValues)
    nextSelectedValues[#nextSelectedValues + 1] = normalizedValue
    return nextSelectedValues, ""
end

function Client:GetConsumableSelectionSummaryText(rows, selectedValues)
    local rowsByValue = buildConsumableRowLookup(rows)
    local normalizedSelectedValues = normalizeSelectedValues(selectedValues or {}, rowsByValue)
    local counts = buildConsumableSelectionCounts(rowsByValue, normalizedSelectedValues)
    local rules = getConsumableSelectionRules()
    local segments = {
        formatConsumableCountSegment("Flasks", counts.flask, rules.flaskLimit),
        formatConsumableCountSegment("Elixirs", counts.elixir, rules.elixirLimit),
        formatConsumableCountSegment("Scrolls", counts.scroll, rules.scrollLimit),
        formatConsumableCountSegment("Runes", counts.rune, rules.runeLimit),
    }

    return table.concat(segments, "   ")
end

function Client:GetPreferredConsumableChoiceValues(rows)
    local preferredConsumables = Profile.ListPreferredConsumableItemRefs and Profile.ListPreferredConsumableItemRefs() or {}
    local preferredLookup = {}
    local selectedValues = {}

    for index = 1, #preferredConsumables do
        local itemRef = ensureString(preferredConsumables[index])
        if itemRef ~= "" then
            preferredLookup[itemRef] = true
        end
    end

    for index = 1, #(rows or {}) do
        local row = rows[index]
        if preferredLookup[ensureString(row and row.itemRef)] == true then
            selectedValues = self:TryToggleConsumableSelection(rows, selectedValues, row.itemRef)
        end
    end

    return selectedValues
end

local function buildConsumablePopupTooltip(row, owner)
    local traitTooltip = getTraitTooltipNamespace()
    if type(row) ~= "table" or not traitTooltip then
        return nil
    end

    local name = trimString(row.label) ~= "" and trimString(row.label) or "Consumable Trait"
    local payload = type(row.payload) == "table" and row.payload or {}
    local authoredDescriptionText = trimString(payload.description)
    local summaryText = trimString(row.summaryText)
    if summaryText == "" then
        summaryText = trimString(row.item and row.item.description)
    end

    local detail = {
        sourceType = "consumable",
        category = "consumable",
        name = name,
        itemName = trimString(row.itemName) ~= "" and trimString(row.itemName) or name,
        traitName = trimString(row.traitName),
        summaryText = summaryText,
        authoredDescriptionText = authoredDescriptionText,
        descriptionText = authoredDescriptionText ~= "" and authoredDescriptionText or summaryText,
        descriptionSource = authoredDescriptionText ~= "" and "authored" or "summary",
        icon = row.icon,
        item = row.item,
        payload = payload,
        consumableTrait = payload,
        dataset = row.dataset,
        datasetId = row.datasetId,
        isMissing = false,
    }

    local descriptionBuilder = getTraitDescriptionBuilder()
    if descriptionBuilder then
        descriptionBuilder:BuildTooltipData(detail, {
            deferGeneration = false,
            tooltipOwner = owner,
        })
    end

    return traitTooltip:Build(detail, owner)
end

function Client:PromptPhaseConsumableTraits(eventState, phase, onFinished)
    local timingParts = getTimingNowMilliseconds() > 0 and {} or nil
    local state = self:GetTraitRuntimeState(eventState and eventState.id or nil, true)
    state.promptedPhases = state.promptedPhases or {}
    if state.promptedPhases[phase] == true then
        if type(onFinished) == "function" then
            onFinished(false)
        end
        return false
    end
    state.promptedPhases[phase] = true

    local tasks = getTasks()
    if type(tasks) == "table" and type(tasks.Enqueue) == "function" then
        state.pendingPromptSessions = state.pendingPromptSessions or {}
        state.pendingPromptSessionSeed = math.max(0, tonumber(state.pendingPromptSessionSeed) or 0) + 1
        state.pendingPromptSessions[phase] = {
            id = state.pendingPromptSessionSeed,
            rows = {},
            rowsByItemRef = {},
            displayItems = Inventory.GetDisplayItems and Inventory.GetDisplayItems() or {},
            nextIndex = 1,
            collectElapsedMs = 0,
            timingParts = timingParts,
            onFinished = onFinished,
        }
        enqueueTask(continueConsumablePromptBuild, self, eventState.id, phase, state.pendingPromptSessionSeed)
        return true
    end

    local collectStartTime = timingParts and getTimingNowMilliseconds() or nil
    local rows = self:CollectEligiblePhaseConsumables(eventState, phase)
    if collectStartTime then
        timingParts[#timingParts + 1] = {
            label = "collect",
            elapsedMs = getTimingNowMilliseconds() - collectStartTime,
            thresholdMs = 15,
        }
    end
    return showPhaseConsumablePrompt(self, eventState, phase, state, rows, onFinished, timingParts)
end
