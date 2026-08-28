local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Spellcasting = Client.Spellcasting
local AuraManager = Spellcasting.AuraManager or {}
local Common = Addon.Utils.Common or {}
local Debug = Addon.Debug or {}
local Lookup = Addon.Utils.Lookup or {}
local Registry = Addon.Internal.Registry or {}
local Database = Addon.Internal.Database or {}
local Profile = Addon.Internal.Profile or {}
local Dependencies = Database.Dependecies or {}
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}

local function startTiming(label, thresholdMs, context)
    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Start) == "function" then
        if type(timings.IsEnabled) == "function" and not timings:IsEnabled() then
            return nil
        end
        return timings:Start(label, {
            thresholdMs = thresholdMs,
            context = context,
        })
    end
    return nil
end

local function stopTiming(timer, cardinality)
    if not timer then
        return
    end

    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Stop) == "function" then
        timings:Stop(timer, { cardinality = cardinality })
    end
end

local function countAuraEntries(bucket)
    local count = 0
    if type(bucket) == "table" and type(bucket.byKey) == "table" then
        for _ in pairs(bucket.byKey) do
            count = count + 1
        end
    end
    return count
end

local AURA_APPLY_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_APPLY") or nil
local AURA_DISPEL_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_DISPEL") or nil
local AURA_APPLY_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_APPLY_BATCH") or nil
local AURA_DISPEL_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_DISPEL_BATCH") or nil
local AURA_RECORD_SEPARATOR = string.char(27)
local AURA_FIELD_SEPARATOR = string.char(26)
local buildEmptyDerivedStateImpact
local mergeDerivedStateImpact
local resolveLocalEventUnit
local resolveLocalEventId
local sortedNumericKeys

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function enqueueAuraWork(fn, ...)
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        tasks:Enqueue(fn, ...)
        return true
    end

    if Debug and Debug.Internal then
        Debug.Internal("Aura sync queue unavailable: Addon.Internal.Tasks is missing.")
    end

    return false
end

local function enqueueAuraSliceable(options)
    local tasks = getTasks()
    if type(tasks) == "table" and type(tasks.EnqueueSliceable) == "function" then
        return tasks:EnqueueSliceable(options)
    end

    if Debug and Debug.Error then
        Debug.Error("Aura sliceable queue unavailable: Addon.Internal.Tasks is missing EnqueueSliceable.")
    end
    return nil
end

local function shouldYieldAuraSlice(deadlineMs)
    local tasks = getTasks()
    return type(tasks) == "table"
        and type(tasks.ShouldYield) == "function"
        and tasks:ShouldYield(deadlineMs) == true
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

local function bumpEventTooltipContextRevision(eventId, casterEventId)
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(builder) == "table" and type(builder.BumpEventTooltipContextRevision) == "function" then
        builder.BumpEventTooltipContextRevision(eventId, casterEventId)
    end
end

local function ensureBucket(client, eventId, createIfMissing)
    local normalizedEventId = type(eventId) == "string" and eventId or ""
    if normalizedEventId == "" then
        return nil
    end

    client.ActiveAurasByEventId = client.ActiveAurasByEventId or {}
    local bucket = client.ActiveAurasByEventId[normalizedEventId]
    if bucket or not createIfMissing then
        return bucket
    end

    bucket = {
        eventId = normalizedEventId,
        byKey = {},
        runtimeByKey = {},
        auraKeysByTarget = {},
        controlStateByTarget = {},
        revision = 1,
        statModifierTotalsCache = {},
        statModifierAggregateCache = {},
    }
    client.ActiveAurasByEventId[normalizedEventId] = bucket
    return bucket
end

local function bumpAuraBucketRevision(bucket)
    if type(bucket) ~= "table" then
        return 0
    end

    bucket.revision = math.max(1, math.floor(tonumber(bucket.revision) or 1) + 1)
    bucket.statModifierTotalsCache = {}
    bucket.statModifierAggregateCache = {}

    local combat = Addon.Client and Addon.Client.Combat or nil
    if type(combat) == "table" and type(combat.BumpCombatRuntimeRevision) == "function" then
        combat:BumpCombatRuntimeRevision(bucket.eventId)
    end

    if type(Client) == "table"
        and type(Client.PendingSpellTargeting) == "table"
        and tostring(Client.PendingSpellTargeting.eventId or "") == tostring(bucket.eventId or "")
    then
        if type(Client.InvalidatePendingSpellTargetingDisplayState) == "function" then
            Client:InvalidatePendingSpellTargetingDisplayState()
        end
        if type(Client.QueueTargetingWidgetRefresh) == "function" then
            Client:QueueTargetingWidgetRefresh("aura-revision")
        end
    end

    return bucket.revision
end

local function invalidateAuraRuntime(bucket, auraKey)
    if type(bucket) ~= "table" or type(auraKey) ~= "string" or auraKey == "" then
        return
    end
    if type(bucket.runtimeByKey) == "table" then
        bucket.runtimeByKey[auraKey] = nil
    end
end

local function invalidateControlStateCache(bucket, targetEventId)
    if type(bucket) ~= "table" then
        return
    end

    if type(bucket.controlStateByTarget) ~= "table" then
        bucket.controlStateByTarget = {}
    end

    local numericTargetEventId = tonumber(targetEventId) or 0
    if numericTargetEventId > 0 then
        bucket.controlStateByTarget[numericTargetEventId] = nil
        return
    end

    bucket.controlStateByTarget = {}
end

local function addAuraKeyToTargetIndex(bucket, targetEventId, auraKey)
    if type(bucket) ~= "table" or type(auraKey) ~= "string" or auraKey == "" then
        return
    end
    bucket.auraKeysByTarget = bucket.auraKeysByTarget or {}
    local numericTargetEventId = tonumber(targetEventId) or 0
    if numericTargetEventId <= 0 then
        return
    end

    local keyList = bucket.auraKeysByTarget[numericTargetEventId]
    if type(keyList) ~= "table" then
        keyList = {}
        bucket.auraKeysByTarget[numericTargetEventId] = keyList
    end
    for index = 1, #keyList do
        if keyList[index] == auraKey then
            return
        end
    end
    keyList[#keyList + 1] = auraKey
end

local function removeAuraKeyFromTargetIndex(bucket, targetEventId, auraKey)
    if type(bucket) ~= "table" or type(bucket.auraKeysByTarget) ~= "table" then
        return
    end
    local numericTargetEventId = tonumber(targetEventId) or 0
    local keyList = bucket.auraKeysByTarget[numericTargetEventId]
    if type(keyList) ~= "table" then
        return
    end
    for index = #keyList, 1, -1 do
        if keyList[index] == auraKey then
            table.remove(keyList, index)
        end
    end
    if #keyList == 0 then
        bucket.auraKeysByTarget[numericTargetEventId] = nil
    end
end

local function getBucketAuraEntriesForTarget(bucket, targetEventId)
    local numericTargetEventId = tonumber(targetEventId) or 0
    if type(bucket) ~= "table" or numericTargetEventId <= 0 then
        return {}
    end

    local entries = {}
    local indexedKeys = type(bucket.auraKeysByTarget) == "table" and bucket.auraKeysByTarget[numericTargetEventId] or nil
    if type(indexedKeys) == "table" then
        for index = 1, #indexedKeys do
            local entry = bucket.byKey and bucket.byKey[indexedKeys[index]] or nil
            if type(entry) == "table" and (tonumber(entry.stacks) or 0) > 0 then
                entries[#entries + 1] = entry
            end
        end
        return entries
    end

    for auraKey, entry in pairs(bucket.byKey or {}) do
        if type(entry) == "table"
            and tonumber(entry.targetEventId) == numericTargetEventId
            and (tonumber(entry.stacks) or 0) > 0
        then
            entries[#entries + 1] = entry
            addAuraKeyToTargetIndex(bucket, numericTargetEventId, auraKey)
        end
    end
    return entries
end

local function buildAuraRuntimeEntry(self, bucket, entry)
    if type(bucket) ~= "table" or type(entry) ~= "table" then
        return nil
    end

    bucket.runtimeByKey = bucket.runtimeByKey or {}
    local runtime = bucket.runtimeByKey[entry.auraKey]
    if type(runtime) == "table"
        and runtime.definition == entry.definition
        and runtime.datasetId == entry.datasetId
        and runtime.auraRef == entry.auraRef
    then
        return runtime
    end

    local auraDefinition = entry.definition
    local _, resolvedAuraDefinition = self:ResolveAuraDefinition(entry.auraRef, { datasetId = entry.datasetId })
    if type(resolvedAuraDefinition) == "table" then
        entry.definition = resolvedAuraDefinition
        auraDefinition = resolvedAuraDefinition
    end
    if type(auraDefinition) ~= "table" then
        return nil
    end

    runtime = {
        auraRef = entry.auraRef,
        datasetId = entry.datasetId,
        definition = auraDefinition,
        effectKeys = sortedNumericKeys(auraDefinition.effects),
        eventEntriesByCombatEventId = {},
        control = {
            cancelOnDamage = false,
            preventCasting = false,
            movementRangeOverride = nil,
            forceAutoHitAgainstTarget = false,
        },
    }

    for effectKeyIndex = 1, #runtime.effectKeys do
        local effect = auraDefinition.effects[runtime.effectKeys[effectKeyIndex].key]
        if type(effect) == "table" and tostring(effect.type or "") == "control" then
            runtime.control.cancelOnDamage = runtime.control.cancelOnDamage or effect.cancelOnDamage == true
            runtime.control.preventCasting = runtime.control.preventCasting or effect.preventCasting == true
            runtime.control.forceAutoHitAgainstTarget = runtime.control.forceAutoHitAgainstTarget or effect.forceAutoHitAgainstTarget == true
            if effect.movementRangeOverride ~= nil then
                local overrideValue = tonumber(effect.movementRangeOverride)
                if overrideValue ~= nil then
                    runtime.control.movementRangeOverride = runtime.control.movementRangeOverride ~= nil
                        and math.min(runtime.control.movementRangeOverride, overrideValue)
                        or overrideValue
                end
            end
        end
    end

    local auraEventKeys = sortedNumericKeys(auraDefinition.events)
    for auraEventKeyIndex = 1, #auraEventKeys do
        local auraEventIndex = auraEventKeys[auraEventKeyIndex].key
        local auraEvent = auraDefinition.events[auraEventIndex]
        local combatEventId = self:GetCombatEventId(auraEvent)
        if combatEventId then
            local eventEntries = runtime.eventEntriesByCombatEventId[combatEventId]
            if type(eventEntries) ~= "table" then
                eventEntries = {}
                runtime.eventEntriesByCombatEventId[combatEventId] = eventEntries
            end
            eventEntries[#eventEntries + 1] = {
                auraEventIndex = auraEventIndex,
                auraEvent = auraEvent,
                effectKeys = sortedNumericKeys(auraEvent and auraEvent.effects or nil),
            }
        end
    end

    bucket.runtimeByKey[entry.auraKey] = runtime
    return runtime
end

local function parseDatasetQualifiedRef(reference)
    if type(reference) ~= "string" or reference == "" then
        return nil, nil
    end

    local datasetId, entryId = string.match(reference, "^([^:]+):(.+)$")
    if not datasetId or not entryId or datasetId == "" or entryId == "" then
        return nil, nil
    end

    return datasetId, entryId
end

local function normalizeRef(value)
    if value == nil then
        return nil
    end

    local ref = tostring(value)
    if ref == "" then
        return nil
    end

    return ref
end

local function sameAuraRef(left, right)
    local leftRef = normalizeRef(left)
    local rightRef = normalizeRef(right)
    if not leftRef or not rightRef then
        return false
    end
    if leftRef == rightRef then
        return true
    end

    local leftDatasetId, leftId = parseDatasetQualifiedRef(leftRef)
    local rightDatasetId, rightId = parseDatasetQualifiedRef(rightRef)
    if leftDatasetId and rightDatasetId then
        return false
    end

    return (leftId or leftRef) == (rightId or rightRef)
end

local function normalizeTriggerTarget(value)
    local triggerTarget = string.lower(tostring(value or ""))
    if triggerTarget == "event_source"
        or triggerTarget == "aura_caster"
        or triggerTarget == "aura_target"
    then
        return triggerTarget
    end

    return "event_other"
end

local function normalizeAuraEventId(value)
    local combatEventId = normalizeRef(value)
    return combatEventId and string.lower(combatEventId) or nil
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

local function logAuraProcDebug(auraEntry, auraDefinition, casterUnit, targetUnit, combatEventId, effect, chancePercent, chanceRoll, outcome, result)
    if type(Debug) ~= "table" or type(Debug.Internal) ~= "function" then
        return false
    end

    if type(Debug.EnsureInternalLevelEnabled) == "function" then
        Debug.EnsureInternalLevelEnabled()
    end

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
    local auraName = tostring(
        type(auraDefinition) == "table" and auraDefinition.name
        or type(auraEntry) == "table" and auraEntry.auraRef
        or "unknown"
    )

    return Debug.Internal(
        "Aura proc: aura=%s caster=%s target=%s event=%s effect=%s chance=%.1f roll=%s outcome=%s applied=%s hit=%s amount=%d delta=%d",
        auraName,
        tostring(casterUnit and casterUnit.name or "unknown"),
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

sortedNumericKeys = function(values)
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

local function createSortedNumericKeyContinuation(values)
    return {
        values = type(values) == "table" and values or {},
        scanKey = nil,
        keys = {},
        phase = "scan",
        sortIndex = 2,
        sortCompareIndex = nil,
        sortValue = nil,
    }
end

local function stepSortedNumericKeyContinuation(state)
    if type(state) ~= "table" then
        return true
    end

    if state.phase == "scan" then
        local key = next(state.values, state.scanKey)
        state.scanKey = key
        if key == nil then
            state.phase = "sort"
            state.sortIndex = 2
            state.sortCompareIndex = nil
            state.sortValue = nil
        else
            local numericKey = tonumber(key)
            if numericKey and numericKey > 0 and math.floor(numericKey) == numericKey then
                state.keys[#state.keys + 1] = {
                    sortKey = numericKey,
                    key = key,
                }
            end
        end
        return false
    end

    if state.phase == "sort" then
        if state.sortIndex > #state.keys then
            state.phase = "complete"
            return true
        end

        if state.sortValue == nil then
            state.sortValue = state.keys[state.sortIndex]
            state.sortCompareIndex = state.sortIndex - 1
        end

        if state.sortCompareIndex >= 1
            and state.keys[state.sortCompareIndex].sortKey > state.sortValue.sortKey
        then
            state.keys[state.sortCompareIndex + 1] = state.keys[state.sortCompareIndex]
            state.sortCompareIndex = state.sortCompareIndex - 1
        else
            state.keys[state.sortCompareIndex + 1] = state.sortValue
            state.sortIndex = state.sortIndex + 1
            state.sortCompareIndex = nil
            state.sortValue = nil
        end
        return false
    end

    return true
end

local function normalizeStackBehavior(value)
    if tostring(value or "") == "independent_duration" then
        return "independent_duration"
    end

    return "refresh_duration"
end

local function isAuraDefinitionHarmful(auraDefinition)
    if type(auraDefinition) ~= "table" then
        return false
    end

    local effectKeys = sortedNumericKeys(auraDefinition.effects)
    for index = 1, #effectKeys do
        local effect = auraDefinition.effects[effectKeys[index].key]
        if type(effect) == "table" and tostring(effect.type or "") == "damage" then
            return true
        end
    end

    return false
end

local function normalizeTurnCount(turnCount)
    if Spellcasting.NormalizeTurnCount then
        local normalized = Spellcasting.NormalizeTurnCount(turnCount)
        if normalized ~= nil then
            return normalized
        end
    end

    local numericTurns = tonumber(turnCount)
    if numericTurns == nil or numericTurns <= 0 then
        return nil
    end

    return math.max(1, math.ceil(numericTurns))
end

local function buildAuraKey(auraRef, casterEventId, targetEventId)
    return table.concat({
        tostring(auraRef or ""),
        tostring(tonumber(casterEventId) or 0),
        tostring(tonumber(targetEventId) or 0),
    }, "\31")
end

local function buildAuraApplySignature(channelName, eventId, casterEventId, targetEventId, auraRef, stacks, turns, powerLevel)
    return table.concat({
        tostring(channelName or ""),
        tostring(eventId or ""),
        tostring(tonumber(casterEventId) or 0),
        tostring(tonumber(targetEventId) or 0),
        tostring(auraRef or ""),
        tostring(tonumber(stacks) or 0),
        tostring(tonumber(turns) or 0),
        tostring(tonumber(powerLevel) or 0),
    }, "\31")
end

local function buildAuraDispelSignature(channelName, eventId, casterEventId, targetEventId, auraRef)
    return table.concat({
        tostring(channelName or ""),
        tostring(eventId or ""),
        tostring(tonumber(casterEventId) or 0),
        tostring(tonumber(targetEventId) or 0),
        tostring(auraRef or ""),
    }, "\31")
end

local function buildAuraApplyBatchSignature(channelName, eventId, payload)
    return table.concat({
        tostring(channelName or ""),
        tostring(eventId or ""),
        tostring(payload or ""),
    }, "\31")
end

local function buildAuraDispelBatchSignature(channelName, eventId, payload)
    return table.concat({
        tostring(channelName or ""),
        tostring(eventId or ""),
        tostring(payload or ""),
    }, "\31")
end

local function normalizePendingScope(value)
    return tostring(value or "turn") == "reaction" and "reaction" or "turn"
end

local function buildAuraOperationKey(kind, channelName, eventId, casterEventId, targetEventId, auraRef, scope)
    return table.concat({
        normalizePendingScope(scope),
        tostring(kind or ""),
        tostring(channelName or ""),
        tostring(eventId or ""),
        tostring(tonumber(casterEventId) or 0),
        tostring(tonumber(targetEventId) or 0),
        tostring(auraRef or ""),
    }, "\31")
end

local function incrementPendingSignature(signatureTable, signature)
    if type(signatureTable) ~= "table" or type(signature) ~= "string" or signature == "" then
        return false
    end

    signatureTable[signature] = (tonumber(signatureTable[signature]) or 0) + 1
    return true
end

local function decrementPendingSignature(signatureTable, signature)
    if type(signatureTable) ~= "table" or type(signature) ~= "string" or signature == "" then
        return 0
    end

    local pendingCount = (tonumber(signatureTable[signature]) or 0) - 1
    if pendingCount > 0 then
        signatureTable[signature] = pendingCount
        return pendingCount
    end

    signatureTable[signature] = nil
    return 0
end

local function consumePendingSignature(signatureTable, signature)
    if type(signatureTable) ~= "table" or type(signature) ~= "string" or signature == "" then
        return false
    end

    local pendingCount = tonumber(signatureTable[signature]) or 0
    if pendingCount <= 0 then
        return false
    end

    decrementPendingSignature(signatureTable, signature)
    return true
end

local function normalizeAuraApplyEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local casterEventId = tonumber(entry.casterEventId) or 0
    local targetEventId = tonumber(entry.targetEventId) or 0
    local auraRef = normalizeRef(entry.auraRef)
    if casterEventId <= 0 or targetEventId <= 0 or not auraRef then
        return nil
    end

    return {
        casterEventId = casterEventId,
        targetEventId = targetEventId,
        auraRef = auraRef,
        stacks = math.max(1, math.floor(tonumber(entry.stacks) or 1)),
        turns = math.max(1, math.floor(tonumber(entry.turns or entry.turnsRemaining) or 1)),
        powerLevel = tonumber(entry.powerLevel) or 0,
        fullState = entry.fullState == true or tostring(entry.fullState or "") == "1",
    }
end

local function normalizeAuraDispelEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local casterEventId = tonumber(entry.casterEventId) or 0
    local targetEventId = tonumber(entry.targetEventId) or 0
    local auraRef = normalizeRef(entry.auraRef)
    if casterEventId <= 0 or targetEventId <= 0 or not auraRef then
        return nil
    end

    return {
        casterEventId = casterEventId,
        targetEventId = targetEventId,
        auraRef = auraRef,
    }
end

local function normalizeAuraApplyEntries(entriesOrPayload)
    if type(entriesOrPayload) == "string" then
        if entriesOrPayload == "" then
            return {}
        end

        local normalized = {}
        local records = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(entriesOrPayload, AURA_RECORD_SEPARATOR) or {}
        for index = 1, #records do
            local values = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(records[index], AURA_FIELD_SEPARATOR) or {}
            local entry = normalizeAuraApplyEntry({
                casterEventId = values[1],
                targetEventId = values[2],
                auraRef = values[3],
                stacks = values[4],
                turns = values[5],
                powerLevel = values[6],
                fullState = values[7],
            })
            if entry then
                normalized[#normalized + 1] = entry
            end
        end

        return normalized
    end

    if type(entriesOrPayload) ~= "table" then
        return {}
    end

    local normalized = {}
    for index = 1, #entriesOrPayload do
        local entry = normalizeAuraApplyEntry(entriesOrPayload[index])
        if entry then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

local function normalizeAuraDispelEntries(entriesOrPayload)
    if type(entriesOrPayload) == "string" then
        if entriesOrPayload == "" then
            return {}
        end

        local normalized = {}
        local records = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(entriesOrPayload, AURA_RECORD_SEPARATOR) or {}
        for index = 1, #records do
            local values = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(records[index], AURA_FIELD_SEPARATOR) or {}
            local entry = normalizeAuraDispelEntry({
                casterEventId = values[1],
                targetEventId = values[2],
                auraRef = values[3],
            })
            if entry then
                normalized[#normalized + 1] = entry
            end
        end

        return normalized
    end

    if type(entriesOrPayload) ~= "table" then
        return {}
    end

    local normalized = {}
    for index = 1, #entriesOrPayload do
        local entry = normalizeAuraDispelEntry(entriesOrPayload[index])
        if entry then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

local function serializeAuraApplyEntries(entries)
    local normalized = normalizeAuraApplyEntries(entries)
    local records = {}
    for index = 1, #normalized do
        local entry = normalized[index]
        records[#records + 1] = table.concat({
            tostring(entry.casterEventId or 0),
            tostring(entry.targetEventId or 0),
            tostring(entry.auraRef or ""),
            tostring(entry.stacks or 1),
            tostring(entry.turns or 1),
            tostring(entry.powerLevel or 0),
            entry.fullState == true and "1" or "0",
        }, AURA_FIELD_SEPARATOR)
    end

    return table.concat(records, AURA_RECORD_SEPARATOR)
end

local function serializeAuraDispelEntries(entries)
    local normalized = normalizeAuraDispelEntries(entries)
    local records = {}
    for index = 1, #normalized do
        local entry = normalized[index]
        records[#records + 1] = table.concat({
            tostring(entry.casterEventId or 0),
            tostring(entry.targetEventId or 0),
            tostring(entry.auraRef or ""),
        }, AURA_FIELD_SEPARATOR)
    end

    return table.concat(records, AURA_RECORD_SEPARATOR)
end

local function resolveChannelId(sessionState)
    if type(Spellcasting.ResolveSessionChannelId) == "function" then
        return Spellcasting.ResolveSessionChannelId(sessionState)
    end

    return sessionState and sessionState.channelId or nil
end

local function sendAuraPacket(channelId, opcode, arguments)
    if type(channelId) ~= "number" or channelId <= 0 or type(opcode) ~= "number" or type(Comms.SendToChannel) ~= "function" then
        return false
    end

    return Comms:SendToChannel(channelId, opcode, arguments, Spellcasting.BuildSendMetadata and Spellcasting.BuildSendMetadata(opcode) or {
        opcode = opcode,
        scope = "client",
    })
end

local function buildAuraTooltipPayload(targetEventId, impact, affectsLocal)
    local payload = {
        auraListChanged = true,
        spellAvailabilityChanged = affectsLocal == true,
        eventIds = {},
        statRefs = {},
        resourceRefs = {},
    }
    local numericTargetEventId = tonumber(targetEventId) or 0
    if numericTargetEventId > 0 then
        payload.eventIds[numericTargetEventId] = true
    end
    for statRef in pairs(type(impact) == "table" and impact.statRefs or {}) do
        payload.statRefs[statRef] = true
    end
    for resourceRef in pairs(type(impact) == "table" and impact.resourceRefs or {}) do
        payload.resourceRefs[resourceRef] = true
    end
    return payload
end

local function performAuraDisplayRefresh(reason, eventState, targetEventId, impact)
    local refreshReason = reason or "aura"
    local numericTargetEventId = tonumber(targetEventId) or 0
    local localEventId = resolveLocalEventId(eventState)
    local affectsLocal = localEventId > 0 and localEventId == numericTargetEventId

    if numericTargetEventId > 0 then
        if type(Client.MarkEventWidgetPortraitsDirty) == "function" then
            Client:MarkEventWidgetPortraitsDirty(refreshReason, { numericTargetEventId })
        elseif type(Client.QueueEventWidgetTargetedRefresh) == "function" then
            Client:QueueEventWidgetTargetedRefresh(refreshReason, { numericTargetEventId })
        elseif type(Client.QueueEventWidgetRefresh) == "function" then
            Client:QueueEventWidgetRefresh(refreshReason)
        end
    elseif type(Client.QueueEventWidgetRefresh) == "function" then
        Client:QueueEventWidgetRefresh(refreshReason)
    end

    if affectsLocal then
        if type(Client.QueueActionBarRefresh) == "function" then
            Client:QueueActionBarRefresh(refreshReason)
        elseif type(Client.RefreshActionBarWidget) == "function" then
            Client:RefreshActionBarWidget(refreshReason)
        end
        if type(Client.InvalidatePendingSpellTargetingDisplayState) == "function" then
            Client:InvalidatePendingSpellTargetingDisplayState()
        end
        if type(Client.MarkTargetingDirty) == "function" then
            Client:MarkTargetingDirty(refreshReason)
        elseif type(Client.QueueTargetingWidgetRefresh) == "function" then
            Client:QueueTargetingWidgetRefresh(refreshReason)
        end
        if type(Client.MarkActionBarCompanionBarsDirty) == "function" then
            Client:MarkActionBarCompanionBarsDirty(refreshReason)
        elseif type(Client.QueueActionBarCompanionBarsRefresh) == "function" then
            Client:QueueActionBarCompanionBarsRefresh(refreshReason)
        end
    end

    if type(Spellcasting.RefreshVisiblePlayerTooltip) == "function" then
        Spellcasting.RefreshVisiblePlayerTooltip(refreshReason, {
            skipCompanionBars = true,
            payload = buildAuraTooltipPayload(numericTargetEventId, impact, affectsLocal),
        })
    end
end

local function refreshAuraDisplays(reason, eventState, targetEventId, impact)
    Client.PendingAuraDisplayRefreshReason = tostring(reason or Client.PendingAuraDisplayRefreshReason or "aura")
    Client.PendingAuraDisplayRefreshEventId = tostring(eventState and eventState.id or Client.PendingAuraDisplayRefreshEventId or "")
    Client.PendingAuraDisplayRefreshTargetEventId = tonumber(targetEventId) or Client.PendingAuraDisplayRefreshTargetEventId
    if type(impact) == "table" then
        Client.PendingAuraDisplayRefreshImpact = Client.PendingAuraDisplayRefreshImpact or buildEmptyDerivedStateImpact()
        mergeDerivedStateImpact(Client.PendingAuraDisplayRefreshImpact, impact)
    end
    if Client.PendingAuraDisplayRefreshQueued == true then
        return true
    end

    Client.PendingAuraDisplayRefreshQueued = true
    local enqueued = enqueueAuraWork(function(targetClient)
        targetClient.PendingAuraDisplayRefreshQueued = false
        local refreshReason = targetClient.PendingAuraDisplayRefreshReason or "aura"
        local refreshEventId = tostring(targetClient.PendingAuraDisplayRefreshEventId or "")
        local refreshTargetEventId = tonumber(targetClient.PendingAuraDisplayRefreshTargetEventId) or 0
        local refreshImpact = targetClient.PendingAuraDisplayRefreshImpact
        targetClient.PendingAuraDisplayRefreshReason = nil
        targetClient.PendingAuraDisplayRefreshEventId = nil
        targetClient.PendingAuraDisplayRefreshTargetEventId = nil
        targetClient.PendingAuraDisplayRefreshImpact = nil
        local currentEventState = targetClient.GetEventState and targetClient:GetEventState() or nil
        if type(currentEventState) == "table" and tostring(currentEventState.id or "") == refreshEventId then
            performAuraDisplayRefresh(refreshReason, currentEventState, refreshTargetEventId, refreshImpact)
            return
        end
        performAuraDisplayRefresh(refreshReason, eventState, refreshTargetEventId, refreshImpact)
    end, Client)
    if not enqueued then
        Client.PendingAuraDisplayRefreshQueued = false
        Client.PendingAuraDisplayRefreshReason = nil
        Client.PendingAuraDisplayRefreshEventId = nil
        Client.PendingAuraDisplayRefreshTargetEventId = nil
        Client.PendingAuraDisplayRefreshImpact = nil
        return false
    end

    return true
end

local function refreshProfileWindowIfVisible()
    local profileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    local instance = type(profileWindow) == "table" and profileWindow._singleton or nil
    if type(instance) == "table" and type(instance.Refresh) == "function" then
        instance:Refresh()
    end
end

resolveLocalEventUnit = function(eventState)
    if type(Client.ResolveLocalEventUnit) ~= "function" then
        return nil
    end

    return Client:ResolveLocalEventUnit(eventState)
end

resolveLocalEventId = function(eventState)
    local localUnit = resolveLocalEventUnit(eventState)
    return tonumber(localUnit and localUnit.eventID) or 0, localUnit
end

local function addRefToSet(target, value)
    local ref = normalizeRef(value)
    if not ref then
        return false
    end

    if target[ref] then
        return false
    end

    target[ref] = true
    return true
end

local function hasRefs(target)
    return type(target) == "table" and next(target) ~= nil
end

local function getNowMilliseconds()
    if type(GetTimePreciseSec) == "function" then
        return GetTimePreciseSec() * 1000
    end

    return (GetTime and GetTime() or 0) * 1000
end

local function isSpellcastTimingEnabled()
    return Debug.SpellcastTiming == true
end

local function logAuraTiming(label, spellRef, elapsed)
    if not isSpellcastTimingEnabled() or type(Debug.Internal) ~= "function" then
        return false
    end

    Debug.Internal(
        "Aura timing [%s] aura=%s elapsed=%.2fms",
        tostring(label or "unknown"),
        tostring(spellRef or ""),
        tonumber(elapsed) or 0
    )
    return true
end

buildEmptyDerivedStateImpact = function()
    return {
        statRefs = {},
        resourceRefs = {},
    }
end

local function collectAuraDefinitionStatRefs(auraDefinition, statRefs)
    if type(auraDefinition) ~= "table" or type(statRefs) ~= "table" then
        return false
    end

    local changed = false
    local effectKeys = sortedNumericKeys(auraDefinition.effects)
    for effectKeyIndex = 1, #effectKeys do
        local effect = auraDefinition.effects[effectKeys[effectKeyIndex].key]
        if type(effect) == "table" and tostring(effect.type or "") == "stat" then
            changed = addRefToSet(statRefs, effect.statRef) or changed
        end
    end

    return changed
end

local function buildAuraDerivedDependencyCacheKey()
    local configurationRevision = math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
    local datasetHash = type(Registry.GenerateActivatedDatasetsHash) == "function"
        and tostring(Registry:GenerateActivatedDatasetsHash() or "")
        or ""
    return ("%d\31%s"):format(configurationRevision, datasetHash)
end

local function buildAuraDerivedDependencyIndexes()
    local bySourceStatRef = {}
    local resourceRefsBySourceStatRef = {}
    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = tostring(dataset and dataset.id or "")
        if datasetId ~= "" then
            for statIndex = 1, #(dataset and dataset.stats or {}) do
                local stat = dataset.stats[statIndex]
                local statId = tostring(stat and stat.id or "")
                if statId ~= "" and tostring(stat and stat.valueMode or "manual") == "derived" then
                    local derivedStatRef = ("%s:%s"):format(datasetId, statId)
                    for sourceIndex = 1, #(stat and stat.derivedSources or {}) do
                        local sourceRef = normalizeRef(stat.derivedSources[sourceIndex] and stat.derivedSources[sourceIndex].sourceStatRef)
                        if sourceRef then
                            bySourceStatRef[sourceRef] = bySourceStatRef[sourceRef] or {}
                            bySourceStatRef[sourceRef][derivedStatRef] = true
                        end
                    end
                end
            end

            for resourceIndex = 1, #(dataset and dataset.resources or {}) do
                local resource = dataset.resources[resourceIndex]
                local sourceStatRef = normalizeRef(resource and resource.sourceStatRef)
                local resourceId = tostring(resource and resource.id or "")
                if sourceStatRef and resourceId ~= "" then
                    resourceRefsBySourceStatRef[sourceStatRef] = resourceRefsBySourceStatRef[sourceStatRef] or {}
                    resourceRefsBySourceStatRef[sourceStatRef][("%s:%s"):format(datasetId, resourceId)] = true
                end
            end
        end
    end

    return {
        derivedStatsBySourceStatRef = bySourceStatRef,
        resourceRefsBySourceStatRef = resourceRefsBySourceStatRef,
    }
end

local function getAuraDerivedDependencyIndexes()
    AuraManager._derivedDependencyIndexCache = AuraManager._derivedDependencyIndexCache or {}

    local cacheKey = buildAuraDerivedDependencyCacheKey()
    local cached = AuraManager._derivedDependencyIndexCache
    if cached.key == cacheKey and type(cached.indexes) == "table" then
        return cached.indexes
    end

    local indexes = buildAuraDerivedDependencyIndexes()
    AuraManager._derivedDependencyIndexCache = {
        key = cacheKey,
        indexes = indexes,
    }
    return indexes
end

local function buildExpandedAffectedStatRefs(initialStatRefs, dependencyIndexes)
    local affectedStatRefs = {}
    for statRef in pairs(type(initialStatRefs) == "table" and initialStatRefs or {}) do
        affectedStatRefs[statRef] = true
    end

    if not hasRefs(affectedStatRefs) then
        return affectedStatRefs
    end

    local pending = {}
    for statRef in pairs(affectedStatRefs) do
        pending[#pending + 1] = statRef
    end

    local graph = type(dependencyIndexes) == "table" and dependencyIndexes.derivedStatsBySourceStatRef or nil
    local pendingIndex = 1
    while pendingIndex <= #pending do
        local sourceRef = pending[pendingIndex]
        pendingIndex = pendingIndex + 1
        local derivedRefs = type(graph) == "table" and graph[sourceRef] or nil
        for derivedRef in pairs(derivedRefs or {}) do
            if not affectedStatRefs[derivedRef] then
                affectedStatRefs[derivedRef] = true
                pending[#pending + 1] = derivedRef
            end
        end
    end

    return affectedStatRefs
end

local function buildAffectedResourceRefs(affectedStatRefs, dependencyIndexes)
    local resourceRefs = {}
    if not hasRefs(affectedStatRefs) then
        return resourceRefs
    end

    local bySourceStatRef = type(dependencyIndexes) == "table" and dependencyIndexes.resourceRefsBySourceStatRef or nil
    for statRef in pairs(affectedStatRefs) do
        local mappedResources = type(bySourceStatRef) == "table" and bySourceStatRef[statRef] or nil
        for resourceRef in pairs(mappedResources or {}) do
            resourceRefs[resourceRef] = true
        end
    end

    return resourceRefs
end

local function buildAuraDerivedStateImpact(...)
    local timingStart = isSpellcastTimingEnabled() and getNowMilliseconds() or nil
    local directStatRefs = {}
    for index = 1, select("#", ...) do
        local entry = select(index, ...)
        local auraDefinition = type(entry) == "table" and entry.definition or entry
        collectAuraDefinitionStatRefs(auraDefinition, directStatRefs)
    end

    if not hasRefs(directStatRefs) then
        return nil
    end

    local dependencyIndexes = getAuraDerivedDependencyIndexes()
    local affectedStatRefs = buildExpandedAffectedStatRefs(directStatRefs, dependencyIndexes)
    local impact = {
        statRefs = affectedStatRefs,
        resourceRefs = buildAffectedResourceRefs(affectedStatRefs, dependencyIndexes),
    }
    if timingStart ~= nil then
        local firstEntry = select(1, ...)
        local auraRef = type(firstEntry) == "table" and firstEntry.auraRef or nil
        logAuraTiming("impact", auraRef, getNowMilliseconds() - timingStart)
    end
    return impact
end

mergeDerivedStateImpact = function(targetImpact, impact)
    if type(targetImpact) ~= "table" or type(impact) ~= "table" then
        return false
    end

    local changed = false
    for statRef in pairs(type(impact.statRefs) == "table" and impact.statRefs or {}) do
        if not targetImpact.statRefs[statRef] then
            targetImpact.statRefs[statRef] = true
            changed = true
        end
    end
    for resourceRef in pairs(type(impact.resourceRefs) == "table" and impact.resourceRefs or {}) do
        if not targetImpact.resourceRefs[resourceRef] then
            targetImpact.resourceRefs[resourceRef] = true
            changed = true
        end
    end

    return changed
end

function AuraManager:CreateLocalPlayerDerivedStateContinuation(client, eventState, options)
    local localUnit = resolveLocalEventUnit(eventState)
    local localEventId = math.floor(tonumber(localUnit and localUnit.eventID) or 0)
    if type(client) ~= "table"
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or type(localUnit) ~= "table"
        or localEventId <= 0
        or type(Profile.CreateResolvedStateContinuation) ~= "function"
    then
        return nil
    end

    local profileContinuation = Profile.CreateResolvedStateContinuation({
        includeAuraBonuses = true,
    })
    if type(profileContinuation) ~= "table" then
        return nil
    end

    return {
        client = client,
        eventId = tostring(eventState.id or ""),
        localEventId = localEventId,
        localUnit = localUnit,
        options = options,
        profileContinuation = profileContinuation,
        phase = "resolve",
        statIndex = 1,
        existingResourceIndex = 1,
        resourceIndex = 1,
        existingResourcesByRef = {},
        nextStats = {},
        nextResources = {},
    }
end

function AuraManager:ReleaseLocalPlayerDerivedStateContinuation(continuation)
    if type(continuation) ~= "table" then
        return
    end

    if type(Profile.ReleaseResolvedStateContinuation) == "function" then
        Profile.ReleaseResolvedStateContinuation(continuation.profileContinuation)
    end
    continuation.profileContinuation = nil
    continuation.statRows = nil
    continuation.resourceRows = nil
    continuation.existingResourcesByRef = nil
    continuation.nextStats = nil
    continuation.nextResources = nil
end

function AuraManager:StepLocalPlayerDerivedStateContinuation(continuation, deadlineMs)
    if type(continuation) ~= "table" then
        return true
    end

    local client = continuation.client
    local eventState = type(client) == "table" and type(client.GetEventState) == "function"
        and client:GetEventState()
        or nil
    local localUnit = resolveLocalEventUnit(eventState)
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or tostring(eventState.id or "") ~= tostring(continuation.eventId or "")
        or tonumber(localUnit and localUnit.eventID) ~= tonumber(continuation.localEventId)
        or localUnit ~= continuation.localUnit
    then
        return nil, "event-stale"
    end
    if type(Profile.IsResolvedStateContinuationCurrent) == "function"
        and Profile.IsResolvedStateContinuationCurrent(continuation.profileContinuation) ~= true
    then
        return nil, "profile-stale"
    end

    while true do
        if continuation.phase == "resolve" then
            if type(Profile.StepResolvedStateContinuation) ~= "function" then
                return nil, "missing-profile-resolver"
            end
            local completed, reason = Profile.StepResolvedStateContinuation(continuation.profileContinuation, deadlineMs)
            if completed == nil then
                return nil, reason or "profile-stale"
            end
            if completed ~= true then
                return false
            end
            continuation.statRows = continuation.profileContinuation.statRows or {}
            continuation.resourceRows = continuation.profileContinuation.resourceRows or {}
            continuation.phase = "copy-stats"
        elseif continuation.phase == "copy-stats" then
            local row = continuation.statRows[continuation.statIndex]
            if row == nil then
                continuation.phase = "index-resources"
            else
                local statRef = type(row.ref) == "string" and row.ref or ""
                if statRef ~= "" then
                    local value = tonumber(row.value) or 0
                    continuation.nextStats[#continuation.nextStats + 1] = {
                        statRef = statRef,
                        value = value,
                        currentValue = value,
                    }
                end
                continuation.statIndex = continuation.statIndex + 1
            end
        elseif continuation.phase == "index-resources" then
            local entry = (localUnit.resources or {})[continuation.existingResourceIndex]
            if entry == nil then
                continuation.phase = "copy-resources"
            else
                local resourceRef = type(entry.resourceRef) == "string" and entry.resourceRef or ""
                if resourceRef ~= "" then
                    continuation.existingResourcesByRef[resourceRef] = entry
                end
                continuation.existingResourceIndex = continuation.existingResourceIndex + 1
            end
        elseif continuation.phase == "copy-resources" then
            local row = continuation.resourceRows[continuation.resourceIndex]
            if row == nil then
                continuation.phase = "commit"
            else
                local resourceRef = type(row.ref) == "string" and row.ref or ""
                if resourceRef ~= "" then
                    local maxValue = math.max(0, tonumber(row.value) or 0)
                    local existing = continuation.existingResourcesByRef[resourceRef]
                    local previousMaxValue = tonumber(existing and existing.maxValue)
                    local currentValue = tonumber(existing and existing.currentValue)
                    if currentValue == nil then
                        currentValue = row.resource and row.resource.startsAtZero == true and 0 or maxValue
                    elseif previousMaxValue ~= nil and previousMaxValue > 0 and maxValue ~= previousMaxValue then
                        local preservedRatio = math.max(0, math.min(1, currentValue / previousMaxValue))
                        if type(Common.Round) == "function" then
                            currentValue = Common.Round(maxValue * preservedRatio)
                        else
                            currentValue = math.floor((maxValue * preservedRatio) + 0.5)
                        end
                    end
                    continuation.nextResources[#continuation.nextResources + 1] = {
                        resourceRef = resourceRef,
                        currentValue = math.max(0, math.min(currentValue, maxValue)),
                        maxValue = maxValue,
                    }
                end
                continuation.resourceIndex = continuation.resourceIndex + 1
            end
        else
            localUnit.stats = continuation.nextStats
            localUnit.resources = continuation.nextResources
            if not (type(continuation.options) == "table" and continuation.options.suppressProfileRefresh == true) then
                refreshProfileWindowIfVisible()
            end
            self:ReleaseLocalPlayerDerivedStateContinuation(continuation)
            return true
        end

        if shouldYieldAuraSlice(deadlineMs) then
            return false
        end
    end
end

function AuraManager:QueueLocalPlayerDerivedStateRefresh(eventState, options)
    local client = type(options) == "table" and options.client or Client
    local eventId = tostring(eventState and eventState.id or "")
    local localEventId = resolveLocalEventId(eventState)
    if type(client) ~= "table"
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or eventId == ""
        or localEventId <= 0
    then
        return false
    end

    client.PendingFullAuraDerivedStateRefreshByEventId = client.PendingFullAuraDerivedStateRefreshByEventId or {}
    if client.PendingFullAuraDerivedStateRefreshByEventId[eventId] then
        return true
    end

    local continuation = self:CreateLocalPlayerDerivedStateContinuation(client, eventState, options)
    if type(continuation) ~= "table" then
        return false
    end

    local work = {
        manager = self,
        client = client,
        eventId = eventId,
        localEventId = localEventId,
        options = options,
        continuation = continuation,
    }
    local job = enqueueAuraSliceable({
        label = "aura-derived-state",
        scope = "event:" .. eventId,
        state = work,
        isStale = function(state)
            local targetClient = state and state.client or nil
            local currentEventState = type(targetClient) == "table" and type(targetClient.GetEventState) == "function"
                and targetClient:GetEventState()
                or nil
            local currentLocalEventId = currentEventState and resolveLocalEventId(currentEventState) or 0
            return type(currentEventState) ~= "table"
                or currentEventState.active ~= true
                or tostring(currentEventState.id or "") ~= tostring(state and state.eventId or "")
                or tonumber(currentLocalEventId) ~= tonumber(state and state.localEventId)
                or (type(Profile.IsResolvedStateContinuationCurrent) == "function"
                    and Profile.IsResolvedStateContinuationCurrent(state and state.continuation and state.continuation.profileContinuation) ~= true)
        end,
        step = function(state, deadlineMs)
            local manager = state and state.manager or nil
            if type(manager) ~= "table" then
                return true
            end
            local completed, reason = manager:StepLocalPlayerDerivedStateContinuation(state.continuation, deadlineMs)
            if completed == nil then
                state.staleReason = reason
                return true
            end
            return completed == true
        end,
        onCancel = function(state, cancelReason)
            local targetClient = state and state.client or nil
            local targetEventId = tostring(state and state.eventId or "")
            if type(targetClient) == "table" and type(targetClient.PendingFullAuraDerivedStateRefreshByEventId) == "table" then
                targetClient.PendingFullAuraDerivedStateRefreshByEventId[targetEventId] = nil
            end
            if type(state) == "table" and type(state.manager) == "table" then
                state.manager:ReleaseLocalPlayerDerivedStateContinuation(state.continuation)
                state.continuation = nil
            end
            if cancelReason == "stale" and type(targetClient) == "table" then
                local currentEventState = type(targetClient.GetEventState) == "function" and targetClient:GetEventState() or nil
                if type(currentEventState) == "table"
                    and currentEventState.active == true
                    and tostring(currentEventState.id or "") == targetEventId
                    and type(state) == "table"
                    and type(state.manager) == "table"
                then
                    state.manager:QueueLocalPlayerDerivedStateRefresh(currentEventState, state.options)
                end
            end
        end,
        onComplete = function(state)
            local targetClient = state and state.client or nil
            local targetEventId = tostring(state and state.eventId or "")
            if type(targetClient) == "table" and type(targetClient.PendingFullAuraDerivedStateRefreshByEventId) == "table" then
                targetClient.PendingFullAuraDerivedStateRefreshByEventId[targetEventId] = nil
            end
            if type(state) == "table" then
                state.continuation = nil
            end
        end,
    })
    if not job then
        self:ReleaseLocalPlayerDerivedStateContinuation(continuation)
        return false
    end

    client.PendingFullAuraDerivedStateRefreshByEventId[eventId] = job
    return true
end

local function queueLocalPlayerAuraDerivedStateRefresh(eventState, targetEventId, impact, options)
    local numericTargetEventId = tonumber(targetEventId) or 0
    local localUnit = resolveLocalEventUnit(eventState)
    if numericTargetEventId <= 0
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or tonumber(localUnit and localUnit.eventID) ~= numericTargetEventId
    then
        return false
    end
    if type(impact) == "table"
        and next(type(impact.statRefs) == "table" and impact.statRefs or {}) == nil
        and next(type(impact.resourceRefs) == "table" and impact.resourceRefs or {}) == nil
    then
        return true
    end

    return AuraManager:QueueLocalPlayerDerivedStateRefresh(eventState, options)
end

local function findEventUnit(eventState, eventId)
    if type(Lookup.FindEventUnitById) == "function" then
        return Lookup.FindEventUnitById(eventState and eventState.units, eventId)
    end

    return nil
end

local function cloneAuraTickerState(entry)
    if type(entry) ~= "table" then
        return nil
    end

    return {
        auraRef = entry.auraRef,
        datasetId = entry.datasetId,
        casterEventId = tonumber(entry.casterEventId) or 0,
        targetEventId = tonumber(entry.targetEventId) or 0,
        stacks = math.max(0, math.floor(tonumber(entry.stacks) or 0)),
        definition = entry.definition,
    }
end

local function buildAuraStackDeltaText(prefix, auraName, amount)
    local stackAmount = math.max(1, math.floor(tonumber(amount) or 1))
    return ("%s %d %s stack%s"):format(prefix, stackAmount, auraName, stackAmount == 1 and "" or "s")
end

local function buildAuraPresenceText(prefix, auraName, stacks)
    local stackCount = math.max(1, math.floor(tonumber(stacks) or 1))
    if stackCount > 1 then
        return ("%s %s x%d"):format(prefix, auraName, stackCount)
    end

    return ("%s %s"):format(prefix, auraName)
end

local function publishAuraCombatLog(client, eventState, previousEntry, nextEntry, queueOnly)
    local publish = queueOnly == true
        and client.QueueCombatLogEntry
        or client.QueueCombatLogEntryEmission
        or client.EmitCombatLogEntry
    if type(client) ~= "table" or type(publish) ~= "function" then
        return false
    end

    local currentEntry = type(nextEntry) == "table" and nextEntry or nil
    local previousState = type(previousEntry) == "table" and previousEntry or nil
    local targetEventId = tonumber(
        (currentEntry and currentEntry.targetEventId)
        or (previousState and previousState.targetEventId)
        or 0
    ) or 0
    if targetEventId <= 0 then
        return false
    end

    local previousStacks = math.max(0, math.floor(tonumber(previousState and previousState.stacks) or 0))
    local nextStacks = math.max(0, math.floor(tonumber(currentEntry and currentEntry.stacks) or 0))
    if previousStacks == nextStacks then
        return false
    end

    local auraDefinition = currentEntry and currentEntry.definition or previousState and previousState.definition or nil
    if type(auraDefinition) ~= "table" then
        local datasetId = currentEntry and currentEntry.datasetId or previousState and previousState.datasetId or nil
        local auraRef = currentEntry and currentEntry.auraRef or previousState and previousState.auraRef or nil
        local _, resolvedAuraDefinition = AuraManager:ResolveAuraDefinition(auraRef, { datasetId = datasetId })
        if type(resolvedAuraDefinition) == "table" then
            auraDefinition = resolvedAuraDefinition
        end
    end

    local auraName = tostring(type(auraDefinition) == "table" and auraDefinition.name or currentEntry and currentEntry.auraRef or previousState and previousState.auraRef or "Aura")
    local auraIcon = tostring(type(auraDefinition) == "table" and auraDefinition.icon or "") ~= ""
        and tostring(auraDefinition.icon)
        or (type(client.GetCombatLogFallbackIcon) == "function" and client:GetCombatLogFallbackIcon() or "Interface\\Icons\\INV_Misc_QuestionMark")
    local harmful = isAuraDefinitionHarmful(auraDefinition)
    local gained = nextStacks > previousStacks
    local changeAmount = math.abs(nextStacks - previousStacks)
    local detailText = nil
    if previousStacks <= 0 and nextStacks > 0 then
        detailText = buildAuraPresenceText("Gained", auraName, nextStacks)
    elseif nextStacks <= 0 and previousStacks > 0 then
        detailText = buildAuraPresenceText("Lost", auraName, previousStacks)
    elseif gained then
        detailText = buildAuraStackDeltaText("Gained", auraName, changeAmount)
    else
        detailText = buildAuraStackDeltaText("Lost", auraName, changeAmount)
    end

    local accentColorToken = gained
        and (harmful and "danger" or "success")
        or (harmful and "success" or "danger")
    local sourceEntry = currentEntry or previousState
    local casterUnit = findEventUnit(eventState, sourceEntry and sourceEntry.casterEventId or 0)
    local targetUnit = findEventUnit(eventState, targetEventId)

    return publish(client, {
        eventId = tostring(eventState and eventState.id or ""),
        entryType = "status",
        casterDisplayName = tostring(casterUnit and casterUnit.name or "Unknown"),
        targetDisplayName = tostring(targetUnit and targetUnit.name or "Unknown"),
        targetCount = 1,
        spellIconTexture = auraIcon,
        detailText = detailText,
        accentColor = Addon.UI and type(Addon.UI.ResolveColor) == "function" and Addon.UI.ResolveColor(nil, accentColorToken) or nil,
    })
end

local function resolveExpectedSender(eventState, casterUnit)
    local normalizedCaster = type(Spellcasting.NormalizeName) == "function"
        and Spellcasting.NormalizeName(casterUnit and (casterUnit.ownerID or casterUnit.controllerID or casterUnit.name) or nil)
        or tostring(casterUnit and (casterUnit.ownerID or casterUnit.controllerID or casterUnit.name) or "")

    if casterUnit and casterUnit.isPlayer == true then
        return normalizedCaster
    end

    local controllerUnit = type(Spellcasting.ResolveControllerPlayerUnit) == "function"
        and Spellcasting.ResolveControllerPlayerUnit(eventState, casterUnit)
        or nil

    if type(Spellcasting.NormalizeName) == "function" then
        return Spellcasting.NormalizeName(controllerUnit and (controllerUnit.ownerID or controllerUnit.controllerID or controllerUnit.name) or nil)
    end

    return tostring(controllerUnit and (controllerUnit.ownerID or controllerUnit.controllerID or controllerUnit.name) or "")
end

local function resolveAuraTurnOwnerEventId(eventState, casterUnit, fallbackEventId)
    local numericFallbackEventId = tonumber(fallbackEventId) or 0
    if type(casterUnit) ~= "table" then
        return numericFallbackEventId > 0 and numericFallbackEventId or nil
    end

    if casterUnit.isPlayer == true then
        local numericCasterEventId = tonumber(casterUnit.eventID) or 0
        if numericCasterEventId > 0 then
            return numericCasterEventId
        end
        return numericFallbackEventId > 0 and numericFallbackEventId or nil
    end

    local controllerUnit = type(Spellcasting.ResolveControllerPlayerUnit) == "function"
        and Spellcasting.ResolveControllerPlayerUnit(eventState, casterUnit)
        or nil
    local numericControllerEventId = tonumber(controllerUnit and controllerUnit.eventID) or 0
    if numericControllerEventId > 0 then
        return numericControllerEventId
    end

    return numericFallbackEventId > 0 and numericFallbackEventId or nil
end

local function shouldExecuteLocalAuraTick(client, eventState, casterUnit)
    local localPlayerName = type(Spellcasting.GetLocalPlayerName) == "function" and Spellcasting.GetLocalPlayerName() or ""
    if localPlayerName == "" then
        return false
    end

    return resolveExpectedSender(eventState, casterUnit) == localPlayerName
end

local function resolveAuraOwnerPageIndex(eventState, casterEventId)
    local casterUnit = findEventUnit(eventState, casterEventId)
    local ownerEventId = resolveAuraTurnOwnerEventId(eventState, casterUnit, casterEventId)
    if ownerEventId == nil or type(Spellcasting.GetUnitPageIndex) ~= "function" then
        return nil
    end

    local pageIndex = tonumber(Spellcasting.GetUnitPageIndex(eventState, ownerEventId))
    if pageIndex == nil or pageIndex <= 0 then
        return nil
    end

    return math.max(1, math.floor(pageIndex))
end

-- Aura progression is an owner-turn cursor, not an event-step scalar.
--
-- Expected behavior:
--   * applied before the caster page: this turn's owner occurrence remains due;
--   * applied on/after the caster page: the next turn is the first due one;
--   * intentional refresh: UpsertAura resets this cursor from the new cast
--     position, just like it resets the authored duration/stack state;
--   * a page move from roster topology: the current page is read at each state
--     update, so growth delays the occurrence and shrink makes it due at most
--     once for the current turn.
--
-- The cursor is stable because it records only the logical owner turn. It does
-- not encode a page count or multiply a turn by mutable totalTicks.
local function resolveAuraActivationOwnerTurn(eventState, casterEventId, turnNumber, tickNumber)
    local currentTurn = math.max(1, math.floor(tonumber(turnNumber) or 1))
    local currentTick = math.max(1, math.floor(tonumber(tickNumber) or 1))
    local ownerPage = resolveAuraOwnerPageIndex(eventState, casterEventId)
    if ownerPage ~= nil and currentTick < ownerPage then
        return currentTurn - 1
    end

    return currentTurn
end

local function isAuraOwnerOccurrenceDue(eventState, entry, turnNumber, tickNumber)
    if type(entry) ~= "table" then
        return false
    end

    local ownerPage = resolveAuraOwnerPageIndex(eventState, entry.casterEventId)
    if ownerPage == nil then
        return false
    end

    local currentTurn = math.max(1, math.floor(tonumber(turnNumber) or 1))
    local currentTick = math.max(1, math.floor(tonumber(tickNumber) or 1))
    local lastOwnerTurn = tonumber(entry.lastAdvancedOwnerTurnNumber)
    if lastOwnerTurn == nil then
        lastOwnerTurn = tonumber(entry.lastAdvancedTurnNumber)
    end
    lastOwnerTurn = math.floor(lastOwnerTurn or currentTurn)
    return currentTurn > lastOwnerTurn and currentTick >= ownerPage
end

local function resolveTriggeredAuraTarget(auraEvent, auraCasterUnit, auraTargetUnit, eventSourceUnit, eventOtherUnit)
    local triggerTarget = normalizeTriggerTarget(type(auraEvent) == "table" and auraEvent.triggerTarget or nil)
    if triggerTarget == "event_source" then
        return eventSourceUnit
    end
    if triggerTarget == "aura_caster" then
        return auraCasterUnit
    end
    if triggerTarget == "aura_target" then
        return auraTargetUnit
    end

    return eventOtherUnit
end

function AuraManager:ResolveAuraEffectAmount(targetUnit, effect)
    if type(effect) ~= "table" then
        return 0
    end

    local amountMode = tostring(effect.amountMode or "flat")
    local amount = math.max(0, tonumber(effect.amount) or tonumber(effect.baseAmount) or tonumber(effect.baseDamage) or tonumber(effect.baseHealing) or 0)

    if amountMode == "flat" then
        return amount
    end

    local resourceRef = tostring(effect.resourceRef or "")
    local resourceValue = 0

    if type(targetUnit) == "table" and targetUnit.resources ~= nil then
        local resources = targetUnit.resources or {}
        for index = 1, #resources do
            local entry = resources[index]
            if type(entry) == "table" and tostring(entry.ref or "") == resourceRef then
                if amountMode == "base_percent" then
                    resourceValue = tonumber(entry.maxValue) or tonumber(entry.currentValue) or 0
                else -- max_percent
                    resourceValue = tonumber(entry.maxValue) or tonumber(entry.currentValue) or 0
                end
                break
            end
        end
    end

    return math.max(0, math.ceil(resourceValue * amount / 100))
end

function AuraManager:RegisterEffect(definition)
    if type(definition) ~= "table" or type(definition.type) ~= "string" or definition.type == "" then
        return nil
    end

    self.Effects = self.Effects or {}
    self.Effects[definition.type] = definition
    return definition
end

function AuraManager:GetEffect(effectType)
    return self.Effects and self.Effects[effectType] or nil
end

function AuraManager:ResolveAuraDefinition(auraRef, context)
    local explicitRef = normalizeRef(auraRef)
    if not explicitRef then
        return nil, nil, nil
    end

    local datasetId, auraId = parseDatasetQualifiedRef(explicitRef)
    if not datasetId then
        datasetId = type(context) == "table" and (
            context.datasetId
            or (type(context.dataset) == "table" and context.dataset.id)
            or context.sourceDatasetId
            or context.spellDatasetId
        ) or nil
        auraId = explicitRef
    end

    if type(datasetId) ~= "string" or datasetId == "" or type(auraId) ~= "string" or auraId == "" then
        return nil, nil, nil
    end

    local contextDataset = type(context) == "table" and context.dataset or nil
    if type(contextDataset) == "table" and tostring(contextDataset.id or "") == datasetId then
        local contextAuras = contextDataset.auras or nil
        for index = 1, #(contextAuras or {}) do
            local aura = contextAuras[index]
            if type(aura) == "table" and tostring(aura.id or "") == auraId then
                return contextDataset, aura, ("%s:%s"):format(datasetId, auraId)
            end
        end
    end

    local dataset = type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(datasetId) or nil
    local auras = type(dataset) == "table" and dataset.auras or nil
    for index = 1, #(auras or {}) do
        local aura = auras[index]
        if type(aura) == "table" and tostring(aura.id or "") == auraId then
            return dataset, aura, ("%s:%s"):format(datasetId, auraId)
        end
    end

    return nil, nil, nil
end

function AuraManager:ResolveEffectAmount(context, effect, baseField)
    local auraEntry = type(context) == "table" and context.aura or nil
    local casterUnit = type(context) == "table" and context.casterUnit or nil
    local targetUnit = type(context) == "table" and context.targetUnit or nil
    local amountMode = tostring(effect and effect.amountMode or "flat")

    local baseAmount = tonumber(effect and effect[baseField] or 0) or 0
    baseAmount = baseAmount + (tonumber(auraEntry and auraEntry.powerLevel) or 0)

    for index = 1, #(effect and effect.statScaling or {}) do
        local scaling = effect.statScaling[index]
        local statRef = type(scaling) == "table" and normalizeRef(scaling.statRef) or nil
        if statRef then
            local statValue = type(Lookup.GetStatValue) == "function" and Lookup.GetStatValue(casterUnit, statRef, 0) or 0
            baseAmount = baseAmount + (statValue * (tonumber(scaling.coefficient) or 0))
        end
    end

    local stacks = math.max(1, math.floor(tonumber(auraEntry and auraEntry.stacks) or 1))

    -- Handle percentage modes
    if amountMode == "base_percent" or amountMode == "max_percent" then
        local resourceRef = tostring(effect.resourceRef or "")
        local resourceValue = 0

        if type(targetUnit) == "table" and targetUnit.resources ~= nil then
            local resources = targetUnit.resources or {}
            for index = 1, #resources do
                local entry = resources[index]
                if type(entry) == "table" and tostring(entry.ref or "") == resourceRef then
                    resourceValue = tonumber(entry.maxValue) or tonumber(entry.currentValue) or 0
                    break
                end
            end
        end

        baseAmount = math.max(0, math.ceil(resourceValue * baseAmount / 100))
    end

    return baseAmount * stacks
end

function AuraManager:ResolveApplyAuraPowerLevel(context, effect)
    local powerLevel = tonumber(effect and effect.basePower) or 0

    if type(Common.Round) == "function" then
        return Common.Round(powerLevel)
    end

    return math.floor(powerLevel + 0.5)
end

function AuraManager:GetCombatEventId(auraEvent)
    return normalizeAuraEventId(type(auraEvent) == "table" and auraEvent.combatEventId or nil)
end

function AuraManager:GetEventAuraBucket(client, eventId, createIfMissing)
    return ensureBucket(client, eventId, createIfMissing)
end

function AuraManager:GetEventAuraRevision(client, eventId)
    local bucket = self:GetEventAuraBucket(client or Client, eventId, false)
    return math.max(0, math.floor(tonumber(bucket and bucket.revision) or 0))
end

function AuraManager:GetUnitAuras(client, eventState, unitEventId)
    local bucket = self:GetEventAuraBucket(client, eventState and eventState.id or nil, false)
    if not bucket then
        return {}
    end

    local numericUnitEventId = tonumber(unitEventId) or 0
    if numericUnitEventId <= 0 then
        return {}
    end

    local rows = {}
    for _, entry in pairs(bucket.byKey or {}) do
        if type(entry) == "table"
            and tonumber(entry.targetEventId) == numericUnitEventId
            and (tonumber(entry.stacks) or 0) > 0
        then
            local auraDefinition = entry.definition
            local _, resolvedAuraDefinition = self:ResolveAuraDefinition(entry.auraRef, { datasetId = entry.datasetId })
            if type(resolvedAuraDefinition) == "table" then
                entry.definition = resolvedAuraDefinition
                auraDefinition = resolvedAuraDefinition
            end

            rows[#rows + 1] = {
                auraRef = entry.auraRef,
                datasetId = entry.datasetId,
                name = tostring(type(auraDefinition) == "table" and auraDefinition.name or entry.auraRef or ""),
                icon = tostring(type(auraDefinition) == "table" and auraDefinition.icon or "") ~= ""
                    and tostring(auraDefinition.icon)
                    or "Interface\\Icons\\INV_Misc_QuestionMark",
                isHarmful = isAuraDefinitionHarmful(auraDefinition),
                stacks = math.max(0, math.floor(tonumber(entry.stacks) or 0)),
                turnsRemaining = math.max(0, math.floor(tonumber(entry.turnsRemaining) or 0)),
                powerLevel = tonumber(entry.powerLevel) or 0,
                casterEventId = tonumber(entry.casterEventId) or 0,
                targetEventId = tonumber(entry.targetEventId) or 0,
            }
        end
    end

    table.sort(rows, function(left, right)
        local leftIsHarmful = left and left.isHarmful == true or false
        local rightIsHarmful = right and right.isHarmful == true or false
        if leftIsHarmful ~= rightIsHarmful then
            return leftIsHarmful == false
        end

        local leftName = tostring(left and left.name or "")
        local rightName = tostring(right and right.name or "")
        if leftName ~= rightName then
            return leftName < rightName
        end

        local leftCaster = tonumber(left and left.casterEventId) or 0
        local rightCaster = tonumber(right and right.casterEventId) or 0
        if leftCaster ~= rightCaster then
            return leftCaster < rightCaster
        end

        return tostring(left and left.auraRef or "") < tostring(right and right.auraRef or "")
    end)

    return rows
end

function AuraManager:BuildUnitAuraTooltipLines(client, eventState, unitEventId)
    -- Implement caching to avoid regenerating tooltip lines on every hover
    -- Use event signature to detect when auras have changed
    local cacheKey = self:BuildUnitAuraSignature(client, eventState, unitEventId)

    if type(client) == "table" then
        client.AuraTooltipLinesCached = client.AuraTooltipLinesCached or {}
        client.AuraTooltipLinesCacheSignature = client.AuraTooltipLinesCacheSignature or {}

        if client.AuraTooltipLinesCacheSignature[unitEventId] == cacheKey and type(client.AuraTooltipLinesCached[unitEventId]) == "table" then
            return client.AuraTooltipLinesCached[unitEventId]
        end
    end

    local rows = self:GetUnitAuras(client, eventState, unitEventId)
    if #rows == 0 then
        return {}
    end

    local lines = {
        { text = " " },
        { text = "Active Effects" },
    }
    for index = 1, #rows do
        local row = rows[index]
        local label = tostring(row.name ~= "" and row.name or row.auraRef or "Aura")
        if (tonumber(row.stacks) or 0) > 1 then
            label = ("%s x%d"):format(label, tonumber(row.stacks) or 1)
        end
        local turnsRemaining = math.max(0, math.floor(tonumber(row.turnsRemaining) or 0))
        local colorToken = row.isHarmful == true and "danger" or "success"
        lines[#lines + 1] = {
            icon = row.icon,
            left = label,
            right = ("%d turn%s"):format(turnsRemaining, turnsRemaining == 1 and "" or "s"),
            colorToken = colorToken,
            rightColorToken = colorToken,
        }
    end

    -- Cache the lines for next time
    if type(client) == "table" then
        client.AuraTooltipLinesCached[unitEventId] = lines
        client.AuraTooltipLinesCacheSignature[unitEventId] = cacheKey
    end

    return lines
end

function AuraManager:BuildUnitAuraSignature(client, eventState, unitEventId)
    local rows = self:GetUnitAuras(client, eventState, unitEventId)
    if #rows == 0 then
        return ""
    end

    local parts = {}
    for index = 1, #rows do
        local row = rows[index]
        parts[#parts + 1] = table.concat({
            tostring(row.auraRef or ""),
            tostring(row.icon or ""),
            tostring(row.isHarmful == true and 1 or 0),
            tostring(tonumber(row.stacks) or 0),
            tostring(tonumber(row.turnsRemaining) or 0),
            tostring(tonumber(row.powerLevel) or 0),
            tostring(tonumber(row.casterEventId) or 0),
        }, "\30")
    end

    return table.concat(parts, "\31")
end

function AuraManager:ClearEventAuraBucket(client, eventId)
    local normalizedEventId = type(eventId) == "string" and eventId or ""
    if normalizedEventId == "" or type(client.ActiveAurasByEventId) ~= "table" then
        return
    end

    client.ActiveAurasByEventId[normalizedEventId] = nil

    -- Clear aura tooltip cache for this event
    if type(client) == "table" and type(client.AuraTooltipLinesCached) == "table" then
        client.AuraTooltipLinesCached[normalizedEventId] = nil
        client.AuraTooltipLinesCacheSignature[normalizedEventId] = nil
    end
end

function AuraManager:ResetAuraState(client, eventId)
    local normalizedEventId = eventId ~= nil and tostring(eventId) or nil
    if normalizedEventId ~= nil then
        local tasks = getTasks()
        local derivedJobs = client.PendingFullAuraDerivedStateRefreshByEventId or {}
        if type(tasks) == "table" and type(tasks.Cancel) == "function" then
            tasks:Cancel(derivedJobs[normalizedEventId], "event-aura-reset")
            local outboundJobs = {}
            for _, job in pairs(client.PendingOutboundAuraFlushJobsByScope or {}) do
                local jobState = type(job) == "table" and job.state or nil
                if type(jobState) ~= "table"
                    or tostring(jobState.eventId or "") == normalizedEventId
                then
                    outboundJobs[#outboundJobs + 1] = job
                end
            end
            for index = 1, #outboundJobs do
                tasks:Cancel(outboundJobs[index], "event-aura-reset")
            end
        end
        client.PendingOutboundAuraOperations = client.PendingOutboundAuraOperations or {}
        client.PendingOutboundAuraOperationOrderByScope = client.PendingOutboundAuraOperationOrderByScope or {}

        local filteredOperations = {}
        local filteredOrdersByScope = {}
        local filteredCountsByScope = {}
        for scope, pendingOrder in pairs(client.PendingOutboundAuraOperationOrderByScope) do
            local filteredOrder = {}
            for index = 1, #(pendingOrder or {}) do
                local operationKey = pendingOrder[index]
                local operation = client.PendingOutboundAuraOperations[operationKey]
                if type(operation) == "table" and tostring(operation.eventId or "") ~= normalizedEventId then
                    filteredOperations[operationKey] = operation
                    filteredOrder[#filteredOrder + 1] = operationKey
                    filteredCountsByScope[scope] = (filteredCountsByScope[scope] or 0) + 1
                end
            end
            filteredOrdersByScope[scope] = filteredOrder
        end
        client.PendingOutboundAuraOperations = filteredOperations
        client.PendingOutboundAuraOperationOrderByScope = filteredOrdersByScope
        client.PendingOutboundAuraOperationCountsByScope = filteredCountsByScope
        client.PendingOutboundAuraFlushStatusByScope = client.PendingOutboundAuraFlushStatusByScope or {}
        client.PendingOutboundAuraFlushStatusByScope.turn = "cancelled"
        client.PendingOutboundAuraFlushStatusByScope.reaction = "cancelled"
        client.PendingOutboundAuraOperationOrder = {}
        if type(client.PendingFullAuraDerivedStateRefreshByEventId) == "table" then
            client.PendingFullAuraDerivedStateRefreshByEventId[normalizedEventId] = nil
        end
    end

    if normalizedEventId ~= nil and normalizedEventId ~= "" then
        self:ClearEventAuraBucket(client, normalizedEventId)
        return true
    end

    local tasks = getTasks()
    if type(tasks) == "table" and type(tasks.CancelScope) == "function" then
        tasks:CancelScope("aura-flush:turn", "aura-reset")
        tasks:CancelScope("aura-flush:reaction", "aura-reset")
    end
    if type(tasks) == "table" and type(tasks.Cancel) == "function" then
        local derivedJobs = {}
        for _, job in pairs(client.PendingFullAuraDerivedStateRefreshByEventId or {}) do
            derivedJobs[#derivedJobs + 1] = job
        end
        for index = 1, #derivedJobs do
            tasks:Cancel(derivedJobs[index], "aura-reset")
        end
    end

    client.ActiveAurasByEventId = {}
    client.PendingLocalAuraApplyEchoSignatures = nil
    client.PendingLocalAuraApplyBatchEchoSignatures = nil
    client.PendingLocalAuraDispelEchoSignatures = nil
    client.PendingLocalAuraDispelBatchEchoSignatures = nil
    client.PendingOutboundAuraFlushQueued = false
    client.PendingOutboundAuraFlushQueuedByScope = {}
    client.PendingOutboundAuraFlushJobsByScope = {}
    client.PendingOutboundAuraFlushStatusByScope = {}
    client.PendingOutboundAuraOperations = {}
    client.PendingOutboundAuraOperationOrder = {}
    client.PendingOutboundAuraOperationOrderByScope = {}
    client.PendingOutboundAuraOperationCountsByScope = {}
    client.PendingFullAuraDerivedStateRefreshByEventId = {}
    client.PendingAuraDisplayRefreshQueued = false
    client.PendingAuraDisplayRefreshReason = nil

    -- Clear aura tooltip cache on full reset
    client.AuraTooltipLinesCached = {}
    client.AuraTooltipLinesCacheSignature = {}

    return true
end

function AuraManager:UpsertAura(client, payload)
    local eventState = payload and payload.eventState or nil
    local eventId = type(eventState) == "table" and eventState.id or nil
    local bucket = self:GetEventAuraBucket(client, eventId, true)
    if not bucket then
        if type(Debug.Internal) == "function" then
            Debug.Internal(
                "Aura upsert failed: missing-bucket aura=%s eventId=%s.",
                tostring(type(payload) == "table" and payload.auraRef or "nil"),
                tostring(eventId or "nil")
            )
        end
        return false, nil
    end

    local dataset, auraDefinition, qualifiedAuraRef = self:ResolveAuraDefinition(payload.auraRef, payload)
    if not dataset or not auraDefinition then
        if type(Debug.Internal) == "function" then
            Debug.Internal(
                "Aura upsert failed: unresolved-definition aura=%s datasetId=%s spellDatasetId=%s sourceDatasetId=%s.",
                tostring(type(payload) == "table" and payload.auraRef or "nil"),
                tostring(type(payload) == "table" and payload.datasetId or "nil"),
                tostring(type(payload) == "table" and payload.spellDatasetId or "nil"),
                tostring(type(payload) == "table" and payload.sourceDatasetId or "nil")
            )
        end
        return false, nil
    end

    local auraKey = buildAuraKey(qualifiedAuraRef, payload.casterEventId, payload.targetEventId)
    local turnsRemaining = normalizeTurnCount(payload.turns) or normalizeTurnCount(auraDefinition.duration)
    if turnsRemaining == nil then
        if type(Debug.Internal) == "function" then
            Debug.Internal(
                "Aura upsert failed: invalid-duration aura=%s qualifiedAuraRef=%s authoredTurns=%s defaultDuration=%s.",
                tostring(type(payload) == "table" and payload.auraRef or "nil"),
                tostring(qualifiedAuraRef or "nil"),
                tostring(type(payload) == "table" and payload.turns or "nil"),
                tostring(type(auraDefinition) == "table" and auraDefinition.duration or "nil")
            )
        end
        return false, nil
    end

    local maxStacks = math.max(1, math.floor(tonumber(auraDefinition.maxStacks) or 1))
    local stacksToApply = math.max(1, math.floor(tonumber(payload.stacks) or 1))
    local stackBehavior = normalizeStackBehavior(auraDefinition.stackBehavior)
    local currentTurnNumber = math.max(1, math.floor(tonumber(eventState and eventState.turnNumber) or 1))
    local currentTickNumber = math.max(1, math.floor(tonumber(eventState and eventState.tickNumber) or 1))
    local activationOwnerTurn = resolveAuraActivationOwnerTurn(
        eventState,
        payload.casterEventId,
        currentTurnNumber,
        currentTickNumber
    )
    local powerLevel = tonumber(payload.powerLevel) or 0
    local replaceState = type(payload) == "table" and payload.fullState == true
    local entry = bucket.byKey[auraKey]

    if entry then
        removeAuraKeyFromTargetIndex(bucket, entry.targetEventId, auraKey)
        entry.powerLevel = powerLevel
        entry.definition = auraDefinition
        entry.datasetId = dataset.id
        entry.stackBehavior = stackBehavior
        entry.maxStacks = maxStacks

        if stackBehavior == "independent_duration" then
            entry.stackTurns = replaceState and {} or (type(entry.stackTurns) == "table" and entry.stackTurns or {})
            local freeStacks = math.max(0, maxStacks - #entry.stackTurns)
            for stackIndex = 1, math.min(stacksToApply, freeStacks) do
                entry.stackTurns[#entry.stackTurns + 1] = turnsRemaining
            end

            local maxTurns = 0
            for stackIndex = 1, #entry.stackTurns do
                maxTurns = math.max(maxTurns, tonumber(entry.stackTurns[stackIndex]) or 0)
            end
            entry.stacks = #entry.stackTurns
            entry.turnsRemaining = maxTurns
        else
            if replaceState then
                entry.stacks = math.min(maxStacks, stacksToApply)
            else
                entry.stacks = math.min(maxStacks, math.max(1, tonumber(entry.stacks) or 1) + stacksToApply)
            end
            entry.turnsRemaining = turnsRemaining
            entry.stackTurns = nil
        end

        entry.lastAdvancedOwnerTurnNumber = activationOwnerTurn
        addAuraKeyToTargetIndex(bucket, entry.targetEventId, auraKey)
        invalidateAuraRuntime(bucket, auraKey)
        invalidateControlStateCache(bucket, entry.targetEventId)
        bumpAuraBucketRevision(bucket)
        return true, entry
    end

    entry = {
        auraKey = auraKey,
        auraRef = qualifiedAuraRef,
        datasetId = dataset.id,
        casterEventId = tonumber(payload.casterEventId) or 0,
        targetEventId = tonumber(payload.targetEventId) or 0,
        stacks = math.min(maxStacks, stacksToApply),
        turnsRemaining = turnsRemaining,
        powerLevel = powerLevel,
        stackBehavior = stackBehavior,
        maxStacks = maxStacks,
        lastAdvancedOwnerTurnNumber = activationOwnerTurn,
        definition = auraDefinition,
    }

    if stackBehavior == "independent_duration" then
        entry.stackTurns = {}
        for stackIndex = 1, entry.stacks do
            entry.stackTurns[#entry.stackTurns + 1] = turnsRemaining
        end
    end

    bucket.byKey[auraKey] = entry
    addAuraKeyToTargetIndex(bucket, entry.targetEventId, auraKey)
    invalidateAuraRuntime(bucket, auraKey)
    invalidateControlStateCache(bucket, entry.targetEventId)
    bumpAuraBucketRevision(bucket)
    return true, entry
end

function AuraManager:RemoveAura(client, eventState, auraRef, casterEventId, targetEventId)
    local bucket = self:GetEventAuraBucket(client, eventState and eventState.id or nil, false)
    if not bucket then
        return false, nil
    end

    local auraKey = buildAuraKey(auraRef, casterEventId, targetEventId)
    local existing = bucket.byKey[auraKey]
    if not existing then
        return false, nil
    end

    removeAuraKeyFromTargetIndex(bucket, existing.targetEventId, auraKey)
    invalidateAuraRuntime(bucket, auraKey)
    invalidateControlStateCache(bucket, existing.targetEventId)
    bucket.byKey[auraKey] = nil
    bumpAuraBucketRevision(bucket)
    if next(bucket.byKey) == nil then
        self:ClearEventAuraBucket(client, eventState and eventState.id or nil)
    end

    return true, existing
end

function AuraManager:RemoveAllAurasForUnit(client, eventState, targetEventId, options)
    local bucket = self:GetEventAuraBucket(client, eventState and eventState.id or nil, false)
    local numericTargetEventId = tonumber(targetEventId) or 0
    if not bucket or numericTargetEventId <= 0 then
        return false, {}
    end

    local removedEntries = {}
    for auraKey, entry in pairs(bucket.byKey or {}) do
        if type(entry) == "table" and tonumber(entry.targetEventId) == numericTargetEventId then
            removedEntries[#removedEntries + 1] = entry
            removeAuraKeyFromTargetIndex(bucket, entry.targetEventId, auraKey)
            invalidateAuraRuntime(bucket, auraKey)
            invalidateControlStateCache(bucket, entry.targetEventId)
            bucket.byKey[auraKey] = nil
        end
    end

    if #removedEntries == 0 then
        return false, {}
    end

    bumpAuraBucketRevision(bucket)

    if next(bucket.byKey) == nil then
        self:ClearEventAuraBucket(client, eventState and eventState.id or nil)
    end

    local queueSync = type(options) == "table" and options.queueSync == true
    if queueSync then
        local context = type(options) == "table" and options.context or nil
        if type(context) ~= "table" then
            context = {
                eventState = eventState,
                sessionState = type(options) == "table" and options.sessionState or nil,
            }
        end

        for index = 1, #removedEntries do
            local entry = removedEntries[index]
            self:QueueAuraDispel(client, context, entry.auraRef, entry.casterEventId, entry.targetEventId)
        end
    end

    local cleanupImpact = buildEmptyDerivedStateImpact()
    for index = 1, #removedEntries do
        local impact = buildAuraDerivedStateImpact(removedEntries[index])
        if impact then
            mergeDerivedStateImpact(cleanupImpact, impact)
        end
    end

    queueLocalPlayerAuraDerivedStateRefresh(eventState, numericTargetEventId, cleanupImpact)
    refreshAuraDisplays("aura-death-cleanup", eventState, numericTargetEventId, cleanupImpact)
    return true, removedEntries
end

local OUTBOUND_AURA_BATCH_ENTRY_LIMIT = 16

local function getPendingOutboundAuraScopeCount(client, scope)
    local counts = type(client) == "table" and client.PendingOutboundAuraOperationCountsByScope or nil
    return math.max(0, math.floor(tonumber(type(counts) == "table" and counts[scope] or 0) or 0))
end

local function adjustPendingOutboundAuraScopeCount(client, scope, delta)
    if type(client) ~= "table" then
        return 0
    end

    client.PendingOutboundAuraOperationCountsByScope = client.PendingOutboundAuraOperationCountsByScope or {}
    local nextCount = math.max(0, getPendingOutboundAuraScopeCount(client, scope) + (tonumber(delta) or 0))
    client.PendingOutboundAuraOperationCountsByScope[scope] = nextCount
    return nextCount
end

local function getPendingOutboundAuraOrder(client, scope)
    if type(client) ~= "table" then
        return {}
    end

    client.PendingOutboundAuraOperationOrderByScope = client.PendingOutboundAuraOperationOrderByScope or {}
    client.PendingOutboundAuraOperationOrderByScope[scope] = client.PendingOutboundAuraOperationOrderByScope[scope] or {}
    return client.PendingOutboundAuraOperationOrderByScope[scope]
end

local function hasPendingOutboundAuraOperations(client, scope, expectedEventState, sourceTurnNumber, sourceTickNumber)
    local pendingOperations = type(client) == "table" and client.PendingOutboundAuraOperations or nil
    if type(pendingOperations) ~= "table" then
        return false
    end

    local normalizedScope = normalizePendingScope(scope)
    for _, operation in pairs(pendingOperations) do
        if type(operation) == "table"
            and normalizePendingScope(operation.scope) == normalizedScope
            and (expectedEventState == nil or operation.eventState == expectedEventState)
            and (sourceTurnNumber == nil or tonumber(operation.sourceTurnNumber) == tonumber(sourceTurnNumber))
            and (sourceTickNumber == nil or tonumber(operation.sourceTickNumber) == tonumber(sourceTickNumber))
        then
            return true
        end
    end

    return false
end

local function discardPendingOutboundAuraOperations(client, scope, eventId, sourceTurnNumber, sourceTickNumber)
    if type(client) ~= "table" then
        return 0
    end

    local normalizedEventId = tostring(eventId or "")
    local normalizedScope = normalizePendingScope(scope)
    local pendingOperations = client.PendingOutboundAuraOperations or {}
    local removed = 0
    for operationKey, operation in pairs(pendingOperations) do
        if type(operation) == "table"
            and normalizePendingScope(operation.scope) == normalizedScope
            and tostring(operation.eventId or "") == normalizedEventId
            and (sourceTurnNumber == nil or tonumber(operation.sourceTurnNumber) == tonumber(sourceTurnNumber))
            and (sourceTickNumber == nil or tonumber(operation.sourceTickNumber) == tonumber(sourceTickNumber))
        then
            pendingOperations[operationKey] = nil
            adjustPendingOutboundAuraScopeCount(client, normalizedScope, -1)
            removed = removed + 1
        end
    end

    return removed
end

local function findPendingOutboundAuraSource(client, scope, expectedEventState)
    local pendingOperations = type(client) == "table" and client.PendingOutboundAuraOperations or nil
    if type(pendingOperations) ~= "table" then
        return nil, nil
    end

    local normalizedScope = normalizePendingScope(scope)
    for _, operation in pairs(pendingOperations) do
        if type(operation) == "table"
            and normalizePendingScope(operation.scope) == normalizedScope
            and (expectedEventState == nil or operation.eventState == expectedEventState)
        then
            return operation.sourceTurnNumber, operation.sourceTickNumber
        end
    end

    return nil, nil
end

local function removePendingOutboundAuraOperationsForEvent(client, eventId)
    if type(client) ~= "table" then
        return 0
    end

    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId == "" then
        return 0
    end

    local pendingOperations = client.PendingOutboundAuraOperations or {}
    local removed = 0
    for operationKey, operation in pairs(pendingOperations) do
        if type(operation) == "table" and tostring(operation.eventId or "") == normalizedEventId then
            pendingOperations[operationKey] = nil
            adjustPendingOutboundAuraScopeCount(client, normalizePendingScope(operation.scope), -1)
            removed = removed + 1
        end
    end

    return removed
end

local function areOutboundAuraOperationsBatchCompatible(batch, operation)
    return type(batch) == "table"
        and type(operation) == "table"
        and batch.kind == operation.kind
        and batch.sessionState == operation.sessionState
        and batch.eventState == operation.eventState
        and tostring(batch.eventId or "") == tostring(operation.eventId or "")
        and tostring(batch.channelName or "") == tostring(operation.sessionState and operation.sessionState.channelName or "")
end

local function createOutboundAuraOperationBatch(operation)
    return {
        kind = operation.kind,
        sessionState = operation.sessionState,
        eventState = operation.eventState,
        eventId = operation.eventId,
        channelName = operation.sessionState and operation.sessionState.channelName or nil,
        operationKeys = {},
    }
end

local function flushOutboundAuraOperationBatch(manager, state)
    local batch = state and state.currentBatch or nil
    local client = state and state.client or nil
    local pendingOperations = type(client) == "table" and client.PendingOutboundAuraOperations or nil
    if type(manager) ~= "table" or type(batch) ~= "table" or type(pendingOperations) ~= "table" then
        return true, false
    end

    local entries = {}
    local operationKeys = {}
    for index = 1, #(batch.operationKeys or {}) do
        local operationKey = batch.operationKeys[index]
        local operation = pendingOperations[operationKey]
        if type(operation) == "table"
            and normalizePendingScope(operation.scope) == state.scope
            and (state.expectedEventState == nil or operation.eventState == state.expectedEventState)
            and (state.sourceTurnNumber == nil or tonumber(operation.sourceTurnNumber) == tonumber(state.sourceTurnNumber))
            and (state.sourceTickNumber == nil or tonumber(operation.sourceTickNumber) == tonumber(state.sourceTickNumber))
            and areOutboundAuraOperationsBatchCompatible(batch, operation)
        then
            if operation.kind == "apply" then
                entries[#entries + 1] = {
                    casterEventId = operation.casterEventId,
                    targetEventId = operation.targetEventId,
                    auraRef = operation.auraRef,
                    stacks = operation.stacks,
                    turns = operation.turnsRemaining,
                    powerLevel = operation.powerLevel,
                    fullState = operation.fullState == true,
                }
                operationKeys[#operationKeys + 1] = operationKey
            elseif operation.kind == "dispel" then
                entries[#entries + 1] = {
                    casterEventId = operation.casterEventId,
                    targetEventId = operation.targetEventId,
                    auraRef = operation.auraRef,
                }
                operationKeys[#operationKeys + 1] = operationKey
            end
        end
    end

    if #entries == 0 then
        return true, false
    end

    local context = {
        sessionState = batch.sessionState,
        eventState = batch.eventState,
    }
    local sent = batch.kind == "apply"
        and manager:SendAuraApplyBatch(client, context, entries)
        or batch.kind == "dispel"
            and manager:SendAuraDispelBatch(client, context, entries)
            or false
    if not sent then
        return false, true
    end

    for index = 1, #operationKeys do
        local operationKey = operationKeys[index]
        if pendingOperations[operationKey] ~= nil then
            pendingOperations[operationKey] = nil
            adjustPendingOutboundAuraScopeCount(client, state.scope, -1)
            state.removedCount = (tonumber(state.removedCount) or 0) + 1
        end
    end
    return true, true
end

local queueOutboundAuraFlush

function AuraManager:FlushOutboundAuraOperations(client, scopeOverride, eventStateOverride, sourceTurnNumber, sourceTickNumber)
    return queueOutboundAuraFlush(
        self,
        client,
        normalizePendingScope(scopeOverride),
        eventStateOverride,
        sourceTurnNumber,
        sourceTickNumber
    )
end

function AuraManager:HasPendingOutboundAuraOperations(client, scopeOverride, eventStateOverride, sourceTurnNumber, sourceTickNumber)
    return hasPendingOutboundAuraOperations(
        client,
        normalizePendingScope(scopeOverride),
        eventStateOverride,
        sourceTurnNumber,
        sourceTickNumber
    )
end

function AuraManager:DiscardPendingOutboundAuraOperations(client, scopeOverride, eventId, sourceTurnNumber, sourceTickNumber)
    return discardPendingOutboundAuraOperations(
        client,
        normalizePendingScope(scopeOverride),
        eventId,
        sourceTurnNumber,
        sourceTickNumber
    )
end

function AuraManager:GetOutboundAuraFlushStatus(client, scopeOverride)
    local scope = normalizePendingScope(scopeOverride)
    local statusByScope = type(client) == "table" and client.PendingOutboundAuraFlushStatusByScope or nil
    local jobByScope = type(client) == "table" and client.PendingOutboundAuraFlushJobsByScope or nil
    local job = type(jobByScope) == "table" and jobByScope[scope] or nil
    if type(job) == "table" and job.finalized ~= true then
        return tostring(type(statusByScope) == "table" and statusByScope[scope] or "pending")
    end

    return tostring(type(statusByScope) == "table" and statusByScope[scope] or "idle")
end

local function shouldDeferTurnAuraOperations(client, context)
    if type(context) == "table" and context.immediate == true then
        return false
    end
    if type(client) ~= "table" or client.DeferTurnDeltaSync == false then
        return false
    end

    local sessionState = type(context) == "table" and context.sessionState or nil
    local eventState = type(context) == "table" and context.eventState or nil
    return type(sessionState) == "table"
        and sessionState.active == true
        and type(eventState) == "table"
        and eventState.active == true
        and eventState.channelName == sessionState.channelName
end

local function updatePendingOutboundAuraFlushQueued(client)
    if type(client) ~= "table" then
        return false
    end

    local queuedByScope = client.PendingOutboundAuraFlushQueuedByScope or {}
    client.PendingOutboundAuraFlushQueued = queuedByScope.turn == true or queuedByScope.reaction == true
    return client.PendingOutboundAuraFlushQueued
end

local function clearOutboundAuraFlushState(state)
    if type(state) ~= "table" then
        return
    end

    state.currentBatch = nil
    state.order = nil
    state.compactedOrder = nil
end

local function finishOutboundAuraFlush(state)
    local client = state and state.client or nil
    local scope = state and state.scope or nil
    if type(client) ~= "table" or type(scope) ~= "string" then
        return
    end

    client.PendingOutboundAuraFlushQueuedByScope = client.PendingOutboundAuraFlushQueuedByScope or {}
    client.PendingOutboundAuraFlushQueuedByScope[scope] = false
    client.PendingOutboundAuraFlushStatusByScope = client.PendingOutboundAuraFlushStatusByScope or {}
    client.PendingOutboundAuraFlushStatusByScope[scope] = state.blocked == true and "failed" or "complete"
    if type(client.PendingOutboundAuraFlushJobsByScope) == "table" then
        client.PendingOutboundAuraFlushJobsByScope[scope] = nil
    end
    updatePendingOutboundAuraFlushQueued(client)

    local shouldRetry = state.blocked ~= true
        and hasPendingOutboundAuraOperations(client, scope, state.expectedEventState)
    local retrySourceTurn, retrySourceTick = findPendingOutboundAuraSource(client, scope, state.expectedEventState)
    clearOutboundAuraFlushState(state)
    if shouldRetry then
        queueOutboundAuraFlush(
            state.manager,
            client,
            scope,
            state.expectedEventState,
            retrySourceTurn,
            retrySourceTick
        )
    elseif (tonumber(state.removedCount) or 0) > 0 then
        if type(client.QueueActionBarRefresh) == "function" then
            client:QueueActionBarRefresh(state.blocked == true and "pending-aura-failed" or "pending-aura-sent")
        elseif type(client.RefreshActionBarWidget) == "function" then
            client:RefreshActionBarWidget(state.blocked == true and "pending-aura-failed" or "pending-aura-sent")
        end
        if type(client.QueuePendingTurnChangesTooltipRefresh) == "function" then
            client:QueuePendingTurnChangesTooltipRefresh()
        elseif type(client.RefreshPendingTurnChangesTooltip) == "function" then
            client:RefreshPendingTurnChangesTooltip()
        end
    end
end

local function cancelOutboundAuraFlush(state, reason)
    local client = state and state.client or nil
    local scope = state and state.scope or nil
    if type(client) ~= "table" or type(scope) ~= "string" then
        return
    end

    client.PendingOutboundAuraFlushQueuedByScope = client.PendingOutboundAuraFlushQueuedByScope or {}
    client.PendingOutboundAuraFlushQueuedByScope[scope] = false
    client.PendingOutboundAuraFlushStatusByScope = client.PendingOutboundAuraFlushStatusByScope or {}
    client.PendingOutboundAuraFlushStatusByScope[scope] = "cancelled"
    if type(client.PendingOutboundAuraFlushJobsByScope) == "table" then
        client.PendingOutboundAuraFlushJobsByScope[scope] = nil
    end
    if tostring(reason or "") == "stale"
        or tostring(reason or "") == "event-replaced"
        or tostring(reason or "") == "event-ending"
        or tostring(reason or "") == "event-aura-reset"
        or tostring(reason or "") == "aura-reset"
    then
        if tostring(reason or "") == "stale" and state.sourceTurnNumber ~= nil then
            discardPendingOutboundAuraOperations(
                client,
                scope,
                state.eventId,
                state.sourceTurnNumber,
                state.sourceTickNumber
            )
        else
            removePendingOutboundAuraOperationsForEvent(client, state.eventId)
        end
    end
    updatePendingOutboundAuraFlushQueued(client)
    clearOutboundAuraFlushState(state)
end

local function stepOutboundAuraFlush(state, deadlineMs)
    local manager = state and state.manager or nil
    local client = state and state.client or nil
    if type(manager) ~= "table" or type(client) ~= "table" then
        return true
    end

    while true do
        if state.phase == "scan" then
            if state.orderIndex > state.orderLimit then
                state.phase = state.currentBatch and "flush" or "compact"
            else
                local operationKey = state.order[state.orderIndex]
                local operation = type(client.PendingOutboundAuraOperations) == "table"
                    and client.PendingOutboundAuraOperations[operationKey]
                    or nil
                if type(operation) ~= "table"
                    or normalizePendingScope(operation.scope) ~= state.scope
                    or (state.expectedEventState ~= nil and operation.eventState ~= state.expectedEventState)
                    or (state.sourceTurnNumber ~= nil and tonumber(operation.sourceTurnNumber) ~= tonumber(state.sourceTurnNumber))
                    or (state.sourceTickNumber ~= nil and tonumber(operation.sourceTickNumber) ~= tonumber(state.sourceTickNumber))
                then
                    state.orderIndex = state.orderIndex + 1
                elseif state.currentBatch and not areOutboundAuraOperationsBatchCompatible(state.currentBatch, operation) then
                    state.phase = "flush"
                else
                    state.currentBatch = state.currentBatch or createOutboundAuraOperationBatch(operation)
                    state.currentBatch.operationKeys[#state.currentBatch.operationKeys + 1] = operationKey
                    state.orderIndex = state.orderIndex + 1
                    if #state.currentBatch.operationKeys >= OUTBOUND_AURA_BATCH_ENTRY_LIMIT then
                        state.phase = "flush"
                    end
                end
            end
        elseif state.phase == "flush" then
            local sent, hadEntries = flushOutboundAuraOperationBatch(manager, state)
            if hadEntries and not sent then
                state.blocked = true
                state.phase = "complete"
            else
                state.flushed = state.flushed or sent
                state.currentBatch = nil
                state.phase = "scan"
            end
        elseif state.phase == "compact" then
            local operationKey = state.order[state.compactIndex]
            if operationKey == nil then
                client.PendingOutboundAuraOperationOrderByScope[state.scope] = state.compactedOrder
                state.phase = "complete"
            else
                local operation = type(client.PendingOutboundAuraOperations) == "table"
                    and client.PendingOutboundAuraOperations[operationKey]
                    or nil
                if type(operation) == "table" and normalizePendingScope(operation.scope) == state.scope then
                    state.compactedOrder[#state.compactedOrder + 1] = operationKey
                end
                state.compactIndex = state.compactIndex + 1
            end
        else
            return true
        end

        if shouldYieldAuraSlice(deadlineMs) then
            return false
        end
    end
end

queueOutboundAuraFlush = function(manager, client, scope, eventStateOverride, sourceTurnNumber, sourceTickNumber)
    if type(manager) ~= "table" or type(client) ~= "table" then
        return false
    end

    local normalizedScope = normalizePendingScope(scope)
    client.PendingOutboundAuraFlushQueuedByScope = client.PendingOutboundAuraFlushQueuedByScope or {}
    if client.PendingOutboundAuraFlushQueuedByScope[normalizedScope] == true then
        return true
    end

    local order = getPendingOutboundAuraOrder(client, normalizedScope)
    if getPendingOutboundAuraScopeCount(client, normalizedScope) <= 0 and #order == 0 then
        return false
    end

    if type(client.QueueActionBarRefresh) == "function" then
        client:QueueActionBarRefresh("pending-aura-flush")
    elseif type(client.RefreshActionBarWidget) == "function" then
        client:RefreshActionBarWidget("pending-aura-flush")
    end
    client.PendingOutboundAuraFlushQueuedByScope[normalizedScope] = true
    client.PendingOutboundAuraFlushStatusByScope = client.PendingOutboundAuraFlushStatusByScope or {}
    client.PendingOutboundAuraFlushStatusByScope[normalizedScope] = "pending"
    updatePendingOutboundAuraFlushQueued(client)
    local state = {
        manager = manager,
        client = client,
        scope = normalizedScope,
        expectedEventState = eventStateOverride,
        eventId = eventStateOverride and eventStateOverride.id or nil,
        sourceTurnNumber = sourceTurnNumber,
        sourceTickNumber = sourceTickNumber,
        order = order,
        orderIndex = 1,
        orderLimit = #order,
        compactIndex = 1,
        compactedOrder = {},
        phase = "scan",
        currentBatch = nil,
        blocked = false,
        flushed = false,
        removedCount = 0,
    }
    local job = enqueueAuraSliceable({
        label = "outbound-aura-flush",
        scope = "aura-flush:" .. normalizedScope,
        state = state,
        isStale = function(work)
            if work.expectedEventState == nil then
                return false
            end

            local currentEventState = work.client.GetEventState and work.client:GetEventState() or nil
            return currentEventState ~= work.expectedEventState
                or type(currentEventState) ~= "table"
                or currentEventState.active ~= true
                or currentEventState.ending == true
                or (work.sourceTurnNumber ~= nil
                    and tonumber(currentEventState.turnNumber) ~= tonumber(work.sourceTurnNumber))
                or (work.sourceTickNumber ~= nil
                    and tonumber(currentEventState.tickNumber) ~= tonumber(work.sourceTickNumber))
        end,
        step = stepOutboundAuraFlush,
        onCancel = function(work, reason)
            cancelOutboundAuraFlush(work, reason)
        end,
        onComplete = function(work)
            finishOutboundAuraFlush(work)
        end,
    })
    if not job then
        client.PendingOutboundAuraFlushQueuedByScope[normalizedScope] = false
        client.PendingOutboundAuraFlushStatusByScope[normalizedScope] = "failed"
        updatePendingOutboundAuraFlushQueued(client)
        clearOutboundAuraFlushState(state)
        return false
    end

    client.PendingOutboundAuraFlushJobsByScope = client.PendingOutboundAuraFlushJobsByScope or {}
    client.PendingOutboundAuraFlushJobsByScope[normalizedScope] = job
    return true
end

function AuraManager:QueueAuraApply(client, context, entry, payload)
    local sessionState = type(context) == "table" and context.sessionState or nil
    local eventState = type(context) == "table" and context.eventState or nil
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true or type(entry) ~= "table" then
        return false
    end

    local rawStacks = tonumber(type(payload) == "table" and payload.stacks or nil) or tonumber(entry.stacks) or 1
    local rawTurns = tonumber(type(payload) == "table" and payload.turns or nil) or tonumber(entry.turnsRemaining) or 1
    if rawStacks <= 0 or rawTurns <= 0 then
        return false
    end

    local stacksToApply = math.max(1, math.floor(rawStacks))
    local turnsToApply = math.max(1, math.floor(rawTurns))
    local powerLevel = tonumber(type(payload) == "table" and payload.powerLevel or entry.powerLevel) or 0
    local scope = normalizePendingScope(type(context) == "table" and (context.pendingScope or context.scope) or nil)
    local sourceTurnNumber = math.floor(tonumber(eventState.turnNumber) or 0)
    local sourceTickNumber = math.floor(tonumber(eventState.tickNumber) or 0)

    local operationKey = buildAuraOperationKey(
        "apply",
        sessionState.channelName,
        eventState.id,
        entry.casterEventId,
        entry.targetEventId,
        entry.auraRef,
        scope
    )
    if operationKey == "" then
        return false
    end

    client.PendingOutboundAuraOperations = client.PendingOutboundAuraOperations or {}
    if not client.PendingOutboundAuraOperations[operationKey] then
        local pendingOrder = getPendingOutboundAuraOrder(client, scope)
        pendingOrder[#pendingOrder + 1] = operationKey
        adjustPendingOutboundAuraScopeCount(client, scope, 1)
    end

    local existing = client.PendingOutboundAuraOperations[operationKey]
    local replaceState = type(payload) == "table" and payload.fullState == true
    if type(existing) == "table" and existing.kind == "apply" then
        existing.sessionState = sessionState
        existing.eventState = eventState
        existing.eventId = eventState.id
        if replaceState then
            existing.stacks = stacksToApply
        else
            existing.stacks = math.max(1, math.floor(tonumber(existing.stacks) or 0)) + stacksToApply
        end
        existing.turnsRemaining = turnsToApply
        existing.powerLevel = powerLevel
        existing.fullState = existing.fullState == true or replaceState
        existing.scope = scope
        existing.sourceTurnNumber = sourceTurnNumber
        existing.sourceTickNumber = sourceTickNumber
    else
        client.PendingOutboundAuraOperations[operationKey] = {
            kind = "apply",
            sessionState = sessionState,
            eventState = eventState,
            eventId = eventState.id,
            casterEventId = tonumber(entry.casterEventId) or 0,
            targetEventId = tonumber(entry.targetEventId) or 0,
            auraRef = entry.auraRef,
            stacks = stacksToApply,
            turnsRemaining = turnsToApply,
            powerLevel = powerLevel,
            fullState = replaceState,
            scope = scope,
            sourceTurnNumber = sourceTurnNumber,
            sourceTickNumber = sourceTickNumber,
        }
    end

    if shouldDeferTurnAuraOperations(client, context) then
        bumpEventTooltipContextRevision(eventState.id, entry.casterEventId)
        if type(client.QueueActionBarRefresh) == "function" then
            client:QueueActionBarRefresh("pending-aura")
        elseif type(client.RefreshActionBarWidget) == "function" then
            client:RefreshActionBarWidget("pending-aura")
        end
        if type(client.QueuePendingTurnChangesTooltipRefresh) == "function" then
            client:QueuePendingTurnChangesTooltipRefresh()
        elseif type(client.RefreshPendingTurnChangesTooltip) == "function" then
            client:RefreshPendingTurnChangesTooltip()
        end
        return true
    end

    return queueOutboundAuraFlush(self, client, scope, eventState, sourceTurnNumber, sourceTickNumber)
end

function AuraManager:QueueAuraDispel(client, context, auraRef, casterEventId, targetEventId)
    local sessionState = type(context) == "table" and context.sessionState or nil
    local eventState = type(context) == "table" and context.eventState or nil
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return false
    end
    local scope = normalizePendingScope(type(context) == "table" and (context.pendingScope or context.scope) or nil)
    local sourceTurnNumber = math.floor(tonumber(eventState.turnNumber) or 0)
    local sourceTickNumber = math.floor(tonumber(eventState.tickNumber) or 0)

    local operationKey = buildAuraOperationKey(
        "dispel",
        sessionState.channelName,
        eventState.id,
        casterEventId,
        targetEventId,
        auraRef,
        scope
    )
    if operationKey == "" then
        return false
    end

    client.PendingOutboundAuraOperations = client.PendingOutboundAuraOperations or {}

    local pendingApplyKey = buildAuraOperationKey(
        "apply",
        sessionState.channelName,
        eventState.id,
        casterEventId,
        targetEventId,
        auraRef,
        scope
    )
    if client.PendingOutboundAuraOperations[pendingApplyKey] ~= nil then
        client.PendingOutboundAuraOperations[pendingApplyKey] = nil
        adjustPendingOutboundAuraScopeCount(client, scope, -1)
    end

    if not client.PendingOutboundAuraOperations[operationKey] then
        local pendingOrder = getPendingOutboundAuraOrder(client, scope)
        pendingOrder[#pendingOrder + 1] = operationKey
        adjustPendingOutboundAuraScopeCount(client, scope, 1)
    end

    client.PendingOutboundAuraOperations[operationKey] = {
        kind = "dispel",
        sessionState = sessionState,
        eventState = eventState,
        eventId = eventState.id,
        casterEventId = tonumber(casterEventId) or 0,
        targetEventId = tonumber(targetEventId) or 0,
        auraRef = auraRef,
        scope = scope,
        sourceTurnNumber = sourceTurnNumber,
        sourceTickNumber = sourceTickNumber,
    }

    if shouldDeferTurnAuraOperations(client, context) then
        bumpEventTooltipContextRevision(eventState.id, casterEventId)
        if type(client.QueueActionBarRefresh) == "function" then
            client:QueueActionBarRefresh("pending-aura")
        elseif type(client.RefreshActionBarWidget) == "function" then
            client:RefreshActionBarWidget("pending-aura")
        end
        if type(client.QueuePendingTurnChangesTooltipRefresh) == "function" then
            client:QueuePendingTurnChangesTooltipRefresh()
        elseif type(client.RefreshPendingTurnChangesTooltip) == "function" then
            client:RefreshPendingTurnChangesTooltip()
        end
        return true
    end

    return queueOutboundAuraFlush(self, client, scope, eventState, sourceTurnNumber, sourceTickNumber)
end

function AuraManager:SendAuraApply(client, context, entry)
    local sessionState = type(context) == "table" and context.sessionState or nil
    local eventState = type(context) == "table" and context.eventState or nil
    local channelId = resolveChannelId(sessionState)
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true or not channelId then
        return false
    end

    local signature = buildAuraApplySignature(
        sessionState.channelName,
        eventState.id,
        entry.casterEventId,
        entry.targetEventId,
        entry.auraRef,
        entry.stacks,
        entry.turnsRemaining,
        entry.powerLevel
    )
    client.PendingLocalAuraApplyEchoSignatures = client.PendingLocalAuraApplyEchoSignatures or {}
    incrementPendingSignature(client.PendingLocalAuraApplyEchoSignatures, signature)

    local sent = sendAuraPacket(channelId, AURA_APPLY_OPCODE, {
        sessionState.channelName,
        eventState.id,
        entry.casterEventId,
        entry.targetEventId,
        entry.auraRef,
        entry.stacks,
        entry.turnsRemaining,
        entry.powerLevel,
    })

    if sent then
        return true
    end

    decrementPendingSignature(client.PendingLocalAuraApplyEchoSignatures, signature)

    return false
end

function AuraManager:SendAuraDispel(client, context, auraRef, casterEventId, targetEventId)
    local sessionState = type(context) == "table" and context.sessionState or nil
    local eventState = type(context) == "table" and context.eventState or nil
    local channelId = resolveChannelId(sessionState)
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true or not channelId then
        return false
    end

    local signature = buildAuraDispelSignature(
        sessionState.channelName,
        eventState.id,
        casterEventId,
        targetEventId,
        auraRef
    )
    client.PendingLocalAuraDispelEchoSignatures = client.PendingLocalAuraDispelEchoSignatures or {}
    incrementPendingSignature(client.PendingLocalAuraDispelEchoSignatures, signature)

    local sent = sendAuraPacket(channelId, AURA_DISPEL_OPCODE, {
        sessionState.channelName,
        eventState.id,
        casterEventId,
        targetEventId,
        auraRef,
    })

    if sent then
        return true
    end

    decrementPendingSignature(client.PendingLocalAuraDispelEchoSignatures, signature)

    return false
end

function AuraManager:SendAuraApplyBatch(client, context, entries)
    local sessionState = type(context) == "table" and context.sessionState or nil
    local eventState = type(context) == "table" and context.eventState or nil
    local channelId = resolveChannelId(sessionState)
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true or not channelId then
        return false
    end

    local normalizedEntries = normalizeAuraApplyEntries(entries)
    if #normalizedEntries == 0 then
        return false
    end

    local payload = serializeAuraApplyEntries(normalizedEntries)
    if payload == "" then
        return false
    end

    local signature = buildAuraApplyBatchSignature(sessionState.channelName, eventState.id, payload)
    client.PendingLocalAuraApplyBatchEchoSignatures = client.PendingLocalAuraApplyBatchEchoSignatures or {}
    incrementPendingSignature(client.PendingLocalAuraApplyBatchEchoSignatures, signature)

    local sent = sendAuraPacket(channelId, AURA_APPLY_BATCH_OPCODE, {
        sessionState.channelName,
        eventState.id,
        payload,
    })
    if sent then
        return true
    end

    decrementPendingSignature(client.PendingLocalAuraApplyBatchEchoSignatures, signature)
    return false
end

function AuraManager:SendAuraDispelBatch(client, context, entries)
    local sessionState = type(context) == "table" and context.sessionState or nil
    local eventState = type(context) == "table" and context.eventState or nil
    local channelId = resolveChannelId(sessionState)
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true or not channelId then
        return false
    end

    local normalizedEntries = normalizeAuraDispelEntries(entries)
    if #normalizedEntries == 0 then
        return false
    end

    local payload = serializeAuraDispelEntries(normalizedEntries)
    if payload == "" then
        return false
    end

    local signature = buildAuraDispelBatchSignature(sessionState.channelName, eventState.id, payload)
    client.PendingLocalAuraDispelBatchEchoSignatures = client.PendingLocalAuraDispelBatchEchoSignatures or {}
    incrementPendingSignature(client.PendingLocalAuraDispelBatchEchoSignatures, signature)

    local sent = sendAuraPacket(channelId, AURA_DISPEL_BATCH_OPCODE, {
        sessionState.channelName,
        eventState.id,
        payload,
    })
    if sent then
        return true
    end

    decrementPendingSignature(client.PendingLocalAuraDispelBatchEchoSignatures, signature)
    return false
end

function AuraManager:ApplyAuraFromContext(client, context, auraRef, stacks, turns, powerLevel)
    local eventState = type(context) == "table" and context.eventState or nil
    local casterUnit = type(context) == "table" and context.casterUnit or nil
    local targetUnit = type(context) == "table" and (context.targetUnit or context.target) or nil
    if type(eventState) ~= "table" or eventState.active ~= true or type(casterUnit) ~= "table" or type(targetUnit) ~= "table" then
        if type(Debug.Internal) == "function" then
            Debug.Internal(
                "Aura apply failed: invalid-context aura=%s eventId=%s casterEventId=%s targetEventId=%s hasEvent=%s hasCaster=%s hasTarget=%s.",
                tostring(auraRef or "nil"),
                tostring(type(eventState) == "table" and eventState.id or "nil"),
                tostring(type(casterUnit) == "table" and tonumber(casterUnit.eventID) or 0),
                tostring(type(targetUnit) == "table" and tonumber(targetUnit.eventID) or 0),
                tostring(type(eventState) == "table" and eventState.active == true),
                tostring(type(casterUnit) == "table"),
                tostring(type(targetUnit) == "table")
            )
        end
        return false, nil
    end

    local existingBucket = self:GetEventAuraBucket(client, eventState.id, false)
    local _, _, qualifiedAuraRef = self:ResolveAuraDefinition(auraRef, {
        dataset = type(context) == "table" and context.dataset or nil,
        datasetId = type(context) == "table" and context.datasetId or nil,
        spellDatasetId = type(context) == "table" and context.spellDatasetId or nil,
    })
    local existingAuraKey = buildAuraKey(qualifiedAuraRef or auraRef, casterUnit.eventID, targetUnit.eventID)
    local previousEntry = cloneAuraTickerState(existingBucket and existingBucket.byKey and existingBucket.byKey[existingAuraKey] or nil)
    local applied, entry = self:UpsertAura(client, {
        eventState = eventState,
        dataset = type(context) == "table" and context.dataset or nil,
        datasetId = type(context) == "table" and context.datasetId or nil,
        spellDatasetId = type(context) == "table" and context.spellDatasetId or nil,
        auraRef = auraRef,
        stacks = stacks,
        turns = turns,
        powerLevel = powerLevel,
        casterEventId = tonumber(casterUnit.eventID) or 0,
        targetEventId = tonumber(targetUnit.eventID) or 0,
    })
    if not applied then
        if type(Debug.Internal) == "function" then
            Debug.Internal(
                "Aura apply failed: upsert-rejected aura=%s eventId=%s datasetId=%s spellDatasetId=%s casterEventId=%s targetEventId=%s turns=%s stacks=%s power=%s.",
                tostring(auraRef or "nil"),
                tostring(eventState.id or "nil"),
                tostring(type(context) == "table" and context.datasetId or "nil"),
                tostring(type(context) == "table" and context.spellDatasetId or "nil"),
                tostring(tonumber(casterUnit.eventID) or 0),
                tostring(tonumber(targetUnit.eventID) or 0),
                tostring(turns),
                tostring(stacks),
                tostring(powerLevel)
            )
        end
        return false, nil
    end

    local queued = self:QueueAuraApply(client, context, entry, {
        stacks = stacks,
        turns = turns or entry.turnsRemaining,
        powerLevel = powerLevel,
    })
    if not queued and type(Debug.Internal) == "function" then
        Debug.Internal(
            "Aura apply queue failed: aura=%s casterEventId=%s targetEventId=%s.",
            tostring(entry.auraRef or "unknown"),
            tostring(tonumber(entry.casterEventId) or 0),
            tostring(tonumber(entry.targetEventId) or 0)
        )
    end
    local derivedStateImpact = buildAuraDerivedStateImpact(previousEntry, entry) or buildEmptyDerivedStateImpact()
    publishAuraCombatLog(client, eventState, previousEntry, entry, false)
    queueLocalPlayerAuraDerivedStateRefresh(eventState, entry.targetEventId, derivedStateImpact, {
        suppressProfileRefresh = type(context) == "table" and context.suppressProfileRefresh == true,
    })
    refreshAuraDisplays("aura-apply", eventState, entry.targetEventId, derivedStateImpact)
    return true, entry
end

function AuraManager:DispelAuraFromContext(client, context, auraRef, casterEventId, targetEventId, removedState)
    local eventState = type(context) == "table" and context.eventState or nil
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local removed, removedEntry = self:RemoveAura(client, eventState, auraRef, casterEventId, targetEventId)
    if not removed then
        return false
    end

    local queued = self:QueueAuraDispel(client, context, auraRef, casterEventId, targetEventId)
    if not queued and type(Debug.Internal) == "function" then
        Debug.Internal(
            "Aura dispel queue failed: aura=%s casterEventId=%s targetEventId=%s.",
            tostring(auraRef or "unknown"),
            tostring(tonumber(casterEventId) or 0),
            tostring(tonumber(targetEventId) or 0)
        )
    end
    local previousEntry = cloneAuraTickerState(removedState or removedEntry)
    local derivedStateImpact = buildAuraDerivedStateImpact(previousEntry) or buildEmptyDerivedStateImpact()
    publishAuraCombatLog(client, eventState, previousEntry, nil, false)
    queueLocalPlayerAuraDerivedStateRefresh(eventState, targetEventId, derivedStateImpact, {
        suppressProfileRefresh = type(context) == "table" and context.suppressProfileRefresh == true,
    })
    refreshAuraDisplays("aura-dispel", eventState, targetEventId, derivedStateImpact)
    return true
end

function AuraManager:RemoveAuraStacksFromContext(client, context, auraRef, stacks, casterEventId, targetEventId)
    local eventState = type(context) == "table" and context.eventState or nil
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false, nil
    end

    local contextCasterEventId = tonumber(type(context) == "table" and context.casterUnit and context.casterUnit.eventID or 0) or 0
    local contextTargetEventId = tonumber(type(context) == "table" and ((context.targetUnit and context.targetUnit.eventID) or (context.target and context.target.eventID)) or 0) or 0
    local resolvedCasterEventId = tonumber(casterEventId) or contextCasterEventId
    local resolvedTargetEventId = tonumber(targetEventId) or contextTargetEventId
    local bucket = self:GetEventAuraBucket(client, eventState.id, false)
    if not bucket then
        return false, nil
    end

    local resolveContext = type(context) == "table" and context or {}
    local contextAura = type(resolveContext.aura) == "table" and resolveContext.aura or nil
    local _, _, qualifiedAuraRef = self:ResolveAuraDefinition(auraRef, {
        dataset = resolveContext.dataset,
        datasetId = resolveContext.datasetId or (contextAura and contextAura.datasetId),
        sourceDatasetId = resolveContext.sourceDatasetId,
        spellDatasetId = resolveContext.spellDatasetId,
    })
    local resolvedAuraRef = qualifiedAuraRef or normalizeRef(auraRef)
    if contextAura and sameAuraRef(resolvedAuraRef, contextAura.auraRef) then
        resolvedCasterEventId = tonumber(contextAura.casterEventId) or resolvedCasterEventId
        resolvedTargetEventId = tonumber(contextAura.targetEventId) or resolvedTargetEventId
        resolvedAuraRef = contextAura.auraRef
    end

    local auraKey = buildAuraKey(resolvedAuraRef, resolvedCasterEventId, resolvedTargetEventId)
    local entry = bucket.byKey and bucket.byKey[auraKey] or nil
    if type(entry) ~= "table" then
        if type(Debug.Internal) == "function" then
            Debug.Internal(
                "Aura remove_aura lookup missed: authoredAuraRef=%s resolvedAuraRef=%s casterEventId=%s targetEventId=%s auraKey=%s.",
                tostring(auraRef or "nil"),
                tostring(resolvedAuraRef or "nil"),
                tostring(resolvedCasterEventId or 0),
                tostring(resolvedTargetEventId or 0),
                tostring(auraKey or "")
            )
        end
        return false, nil
    end

    local previousEntry = cloneAuraTickerState(entry)
    local stacksToRemove = math.max(1, math.floor(tonumber(stacks) or 1))
    local nextStacks = math.max(0, math.floor(tonumber(entry.stacks) or 0))
    if nextStacks <= 0 then
        if type(Debug.Internal) == "function" then
            Debug.Internal(
                "Aura remove_aura skipped: aura=%s casterEventId=%s targetEventId=%s stacksBefore=%s remove=%s.",
                tostring(entry.auraRef or "unknown"),
                tostring(tonumber(entry.casterEventId) or 0),
                tostring(tonumber(entry.targetEventId) or 0),
                tostring(nextStacks),
                tostring(stacksToRemove)
            )
        end
        return false, entry
    end

    if entry.stackBehavior == "independent_duration" then
        entry.stackTurns = type(entry.stackTurns) == "table" and entry.stackTurns or {}
        for _ = 1, math.min(stacksToRemove, #entry.stackTurns) do
            table.remove(entry.stackTurns)
        end

        local maxTurns = 0
        for index = 1, #entry.stackTurns do
            maxTurns = math.max(maxTurns, tonumber(entry.stackTurns[index]) or 0)
        end
        entry.stacks = #entry.stackTurns
        entry.turnsRemaining = maxTurns
    else
        entry.stacks = math.max(0, nextStacks - stacksToRemove)
    end

    if type(Debug.Internal) == "function" then
        Debug.Internal(
            "Aura remove_aura applied: aura=%s casterEventId=%s targetEventId=%s stacksBefore=%s remove=%s stacksAfter=%s.",
            tostring(entry.auraRef or "unknown"),
            tostring(tonumber(entry.casterEventId) or 0),
            tostring(tonumber(entry.targetEventId) or 0),
            tostring(nextStacks),
            tostring(stacksToRemove),
            tostring(tonumber(entry.stacks) or 0)
        )
    end

    if (tonumber(entry.stacks) or 0) <= 0 then
        return self:DispelAuraFromContext(client, context, entry.auraRef, entry.casterEventId, entry.targetEventId, previousEntry), nil
    end

    invalidateControlStateCache(bucket, entry.targetEventId)
    bumpAuraBucketRevision(bucket)

    local queuedApply = self:QueueAuraApply(client, context, entry, {
        stacks = entry.stacks,
        turns = entry.turnsRemaining,
        powerLevel = entry.powerLevel,
        fullState = true,
    })
    if not queuedApply and type(Debug.Internal) == "function" then
        Debug.Internal(
            "Aura stack removal queue failed: aura=%s casterEventId=%s targetEventId=%s stacks=%s.",
            tostring(entry.auraRef or "unknown"),
            tostring(tonumber(entry.casterEventId) or 0),
            tostring(tonumber(entry.targetEventId) or 0),
            tostring(tonumber(entry.stacks) or 0)
        )
    end

    local derivedStateImpact = buildAuraDerivedStateImpact(previousEntry, entry) or buildEmptyDerivedStateImpact()
    publishAuraCombatLog(client, eventState, previousEntry, entry, false)
    queueLocalPlayerAuraDerivedStateRefresh(eventState, entry.targetEventId, derivedStateImpact)
    refreshAuraDisplays("aura-remove-stacks", eventState, entry.targetEventId, derivedStateImpact)
    return true, entry
end

function AuraManager:HandleLocalAuraTickResult(client, context, result)
    if type(result) ~= "table" then
        return false
    end

    local auraEntry = type(context) == "table" and context.aura or nil
    local auraDefinition = type(context) == "table" and context.auraDefinition or nil
    local effect = type(context) == "table" and context.effect or nil
    if Debug.AuraTracing == true and type(Debug.Info) == "function" and type(auraEntry) == "table" then
        local casterUnit = type(context) == "table" and context.casterUnit or nil
        local targetUnit = type(context) == "table" and context.targetUnit or nil
        local auraLabel = tostring(
            (type(auraDefinition) == "table" and auraDefinition.name)
            or auraEntry.auraRef
            or "unknown"
        )
        local effectType = tostring(result.effectType or (type(effect) == "table" and effect.type) or "unknown")
        local amount = tonumber(result.amount) or 0
        local appliedDelta = tonumber(result.appliedDelta) or 0
        Debug.Info(
            "Aura tick: %s [%s] %s (%s) -> %s (%s), stacks=%d, turns=%d, power=%d, amount=%d, appliedDelta=%d, applied=%s.",
            auraLabel,
            tostring(auraEntry.auraRef or "unknown"),
            tostring(casterUnit and casterUnit.name or "unknown"),
            tostring(tonumber(auraEntry.casterEventId) or 0),
            tostring(targetUnit and targetUnit.name or "unknown"),
            tostring(tonumber(auraEntry.targetEventId) or 0),
            math.max(0, math.floor(tonumber(auraEntry.stacks) or 0)),
            math.max(0, math.floor(tonumber(auraEntry.turnsRemaining) or 0)),
            math.floor((tonumber(auraEntry.powerLevel) or 0) + 0.5),
            amount,
            appliedDelta,
            tostring(result.applied == true)
        )
    end

    local resourceDeltas = result.resourceDeltas
    if type(resourceDeltas) ~= "table" or #resourceDeltas == 0 then
        return false
    end

    local sessionState = type(context) == "table" and context.sessionState or nil
    local targetUnit = type(context) == "table" and context.targetUnit or nil
    local targetEventId = tonumber(targetUnit and targetUnit.eventID) or 0
    if type(client.QueueClientResourceDeltas) == "function"
        and type(sessionState) == "table"
        and sessionState.active == true
        and targetEventId > 0
    then
        local immediate = type(context) == "table" and context.immediate == true
        client:QueueClientResourceDeltas(
            sessionState,
            "aura-tick-resource",
            resourceDeltas,
            targetEventId,
            {
                immediate = immediate,
                scope = immediate and (context.pendingScope or context.scope or "reaction") or "turn",
            }
        )
    end

    if type(Spellcasting.ShowLocalResourceDeltaCombatText) == "function" then
        Spellcasting.ShowLocalResourceDeltaCombatText(
            client,
            context.eventState,
            context.casterUnit,
            context.targetUnit,
            resourceDeltas,
            result.hitType,
            result
        )
    end

    if type(client.MarkEventUnitInteraction) == "function" then
        client:MarkEventUnitInteraction(context.eventState, context.casterUnit, context.targetUnit, result, auraEntry and auraEntry.auraRef or nil)
    end

    return true
end

function AuraManager:HandleLocalAuraTriggeredResult(client, context, result, combatEventId)
    if type(result) ~= "table" then
        return false
    end

    local auraEntry = type(context) == "table" and context.aura or nil
    local auraDefinition = type(context) == "table" and context.auraDefinition or nil
    local effect = type(context) == "table" and context.effect or nil
    if Debug.AuraTracing == true and type(Debug.Info) == "function" and type(auraEntry) == "table" then
        local casterUnit = type(context) == "table" and context.casterUnit or nil
        local targetUnit = type(context) == "table" and context.targetUnit or nil
        local auraLabel = tostring(
            (type(auraDefinition) == "table" and auraDefinition.name)
            or auraEntry.auraRef
            or "unknown"
        )
        local effectType = tostring(result.effectType or (type(effect) == "table" and effect.type) or "unknown")
        local amount = tonumber(result.amount) or 0
        local appliedDelta = tonumber(result.appliedDelta) or 0
        Debug.Info(
            "Aura trigger: %s [%s] event=%s caster=%s (%s) -> %s (%s), effect=%s, amount=%d, appliedDelta=%d, applied=%s.",
            auraLabel,
            tostring(auraEntry.auraRef or "unknown"),
            tostring(combatEventId or "unknown"),
            tostring(casterUnit and casterUnit.name or "unknown"),
            tostring(tonumber(auraEntry.casterEventId) or 0),
            tostring(targetUnit and targetUnit.name or "unknown"),
            tostring(targetUnit and targetUnit.eventID or "unknown"),
            effectType,
            amount,
            appliedDelta,
            tostring(result.applied == true)
        )
    end

    local combat = Addon.Client and Addon.Client.Combat or nil
    if tostring(result.effectType or "") == "damage"
    then
        local registeredTriggeredDamage = false
        if type(combat) == "table"
            and type(combat.RegisterTriggeredActionBonusDamage) == "function"
        then
            registeredTriggeredDamage = combat:RegisterTriggeredActionBonusDamage(
                type(context) == "table" and context.actionContext or nil,
                type(context) == "table" and context.targetUnit or nil,
                result,
                effect,
                combatEventId
            ) == true
        end
        if not registeredTriggeredDamage then
            emitTriggeredDamageCombatLog(
                client,
                type(context) == "table" and context.eventState or nil,
                type(context) == "table" and context.casterUnit or nil,
                type(context) == "table" and context.targetUnit or nil,
                result,
                effect
            )
        end
    end

    local resourceDeltas = result.resourceDeltas
    if type(resourceDeltas) ~= "table" or #resourceDeltas == 0 then
        return false
    end

    local sessionState = type(context) == "table" and context.sessionState or nil
    local targetUnit = type(context) == "table" and context.targetUnit or nil
    local targetEventId = tonumber(targetUnit and targetUnit.eventID) or 0
    if type(client.QueueClientResourceDeltas) == "function"
        and type(sessionState) == "table"
        and sessionState.active == true
        and targetEventId > 0
    then
        local immediate = type(context) == "table" and context.immediate == true
        client:QueueClientResourceDeltas(
            sessionState,
            "aura-trigger-resource",
            resourceDeltas,
            targetEventId,
            {
                immediate = immediate,
                scope = immediate and (context.pendingScope or context.scope or "reaction") or "turn",
            }
        )
    end

    if type(Spellcasting.ShowLocalResourceDeltaCombatText) == "function" then
        Spellcasting.ShowLocalResourceDeltaCombatText(
            client,
            context.eventState,
            context.casterUnit,
            context.targetUnit,
            resourceDeltas,
            result.hitType,
            result
        )
    end

    if type(client.MarkEventUnitInteraction) == "function" then
        client:MarkEventUnitInteraction(context.eventState, context.casterUnit, context.targetUnit, result, auraEntry and auraEntry.auraRef or nil)
    end

    return true
end

function AuraManager:TickAura(client, eventState, entry, casterUnit, targetUnit)
    local auraDefinition = entry and entry.definition or nil
    local _, resolvedAuraDefinition = self:ResolveAuraDefinition(entry and entry.auraRef or nil, { datasetId = entry and entry.datasetId or nil })
    if type(resolvedAuraDefinition) == "table" then
        auraDefinition = resolvedAuraDefinition
        if type(entry) == "table" then
            entry.definition = resolvedAuraDefinition
        end
    end
    if type(auraDefinition) ~= "table" then
        return false
    end

    local changed = false
    local effectKeys = sortedNumericKeys(auraDefinition.effects)
    for index = 1, #effectKeys do
        local effectIndex = effectKeys[index].key
        local effect = auraDefinition.effects[effectIndex]
        local contract = self:GetEffect(effect and effect.type or nil)
        if contract and type(contract.Execute) == "function" then
            local applied, result = contract:Execute({
                client = client,
                eventState = eventState,
                sessionState = client.GetState and client:GetState() or nil,
                aura = entry,
                auraDefinition = auraDefinition,
                casterUnit = casterUnit,
                targetUnit = targetUnit,
                healthResourceRef = eventState and eventState.healthResourceRef or (Spellcasting.GetHealthResourceRef and Spellcasting.GetHealthResourceRef()),
            }, effect)
            if applied then
                changed = true
            elseif Debug.AuraTracing == true and type(Debug.Info) == "function" then
                Debug.Info(
                    "Aura effect resolved without application: aura=%s effectType=%s caster=%s target=%s.",
                    tostring(entry and entry.auraRef or "unknown"),
                    tostring(effect and effect.type or "unknown"),
                    tostring(casterUnit and casterUnit.name or "unknown"),
                    tostring(targetUnit and targetUnit.name or "unknown")
                )
            end
            self:HandleLocalAuraTickResult(client, {
                eventState = eventState,
                sessionState = client.GetState and client:GetState() or nil,
                aura = entry,
                auraDefinition = auraDefinition,
                effect = effect,
                casterUnit = casterUnit,
                targetUnit = targetUnit,
            }, result)
        end
    end

    return changed
end

function AuraManager:HandleCombatEvent(client, context)
    local eventState = type(context) == "table" and context.eventState or nil
    local recipientEventId = tonumber(type(context) == "table" and context.recipientEventId or nil) or 0
    local combatEventId = normalizeRef(type(context) == "table" and context.combatEventId or nil)
    combatEventId = combatEventId and string.lower(combatEventId) or nil
    local eventSourceUnit = type(context) == "table" and context.eventSourceUnit or nil
    local eventOtherUnit = type(context) == "table" and context.eventOtherUnit or nil
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or recipientEventId <= 0
        or not combatEventId
        or type(eventSourceUnit) ~= "table"
        or type(eventOtherUnit) ~= "table"
    then
        return false
    end

    local bucket = self:GetEventAuraBucket(client, eventState.id, false)
    local changed = false
    local targetEntries = getBucketAuraEntriesForTarget(bucket, recipientEventId)
    for index = 1, #targetEntries do
        local entry = targetEntries[index]
        local runtime = buildAuraRuntimeEntry(self, bucket, entry)
        local auraDefinition = runtime and runtime.definition or nil
        local auraCasterUnit = findEventUnit(eventState, entry.casterEventId)
        local auraTargetUnit = findEventUnit(eventState, entry.targetEventId)
        local auraEventEntries = runtime and runtime.eventEntriesByCombatEventId and runtime.eventEntriesByCombatEventId[combatEventId] or nil
        if type(auraDefinition) == "table"
            and type(auraCasterUnit) == "table"
            and type(auraTargetUnit) == "table"
            and type(auraEventEntries) == "table"
            and #auraEventEntries > 0
            and shouldExecuteLocalAuraTick(client, eventState, auraTargetUnit)
        then
            for auraEventEntryIndex = 1, #auraEventEntries do
                local auraEventEntry = auraEventEntries[auraEventEntryIndex]
                local auraEvent = auraEventEntry.auraEvent
                local auraEventIndex = auraEventEntry.auraEventIndex
                local targetUnit = resolveTriggeredAuraTarget(
                    auraEvent,
                    auraCasterUnit,
                    auraTargetUnit,
                    eventSourceUnit,
                    eventOtherUnit
                )
                if type(targetUnit) ~= "table" then
                    logAuraProcDebug(
                        entry,
                        auraDefinition,
                        auraCasterUnit,
                        nil,
                        combatEventId,
                        nil,
                        normalizeChancePercent(auraEvent and auraEvent.chance),
                        nil,
                        "no-target",
                        nil
                    )
                else
                    local procPassed, normalizedChance, chanceRoll = evaluateProcChance(auraEvent and auraEvent.chance)
                    if not procPassed then
                        logAuraProcDebug(
                            entry,
                            auraDefinition,
                            auraCasterUnit,
                            targetUnit,
                            combatEventId,
                            nil,
                            normalizedChance,
                            chanceRoll,
                            "chance-failed",
                            nil
                        )
                    else
                        local effectKeys = auraEventEntry.effectKeys or {}
                        if Debug.AuraTracing == true and type(Debug.Info) == "function" then
                            Debug.Info(
                                "Aura trigger event registered actions: aura=%s event=%s actions=%d.",
                                tostring(entry and entry.auraRef or "unknown"),
                                tostring(combatEventId or "unknown"),
                                #effectKeys
                            )
                        end
                        for effectKeyIndex = 1, #effectKeys do
                            local effectIndex = effectKeys[effectKeyIndex].key
                            local effect = auraEvent.effects[effectIndex]
                            local contract = self:GetEffect(effect and effect.type or nil)
                            if contract and type(contract.Execute) == "function" then
                                local applied, result = contract:Execute({
                                    client = client,
                                    eventState = eventState,
                                    sessionState = type(context) == "table" and context.sessionState or (client.GetState and client:GetState() or nil),
                                    suppressCombatEvents = true,
                                    actionContext = type(context) == "table" and context.actionContext or nil,
                                    aura = entry,
                                    auraDefinition = auraDefinition,
                                    auraEvent = auraEvent,
                                    auraEventIndex = auraEventIndex,
                                    effectIndex = effectIndex,
                                    casterUnit = auraCasterUnit,
                                    targetUnit = targetUnit,
                                    auraCasterUnit = auraCasterUnit,
                                    auraTargetUnit = auraTargetUnit,
                                    eventSourceUnit = eventSourceUnit,
                                    eventOtherUnit = eventOtherUnit,
                                    healthResourceRef = eventState and eventState.healthResourceRef or (Spellcasting.GetHealthResourceRef and Spellcasting.GetHealthResourceRef()),
                                }, effect)
                                if applied then
                                    changed = true
                                end
                                self:HandleLocalAuraTriggeredResult(client, {
                                    eventState = eventState,
                                    sessionState = type(context) == "table" and context.sessionState or (client.GetState and client:GetState() or nil),
                                    suppressCombatEvents = true,
                                    aura = entry,
                                    auraDefinition = auraDefinition,
                                    auraEvent = auraEvent,
                                    auraEventIndex = auraEventIndex,
                                    effectIndex = effectIndex,
                                    effect = effect,
                                    actionContext = type(context) == "table" and context.actionContext or nil,
                                    casterUnit = auraCasterUnit,
                                    targetUnit = targetUnit,
                                    eventSourceUnit = eventSourceUnit,
                                    eventOtherUnit = eventOtherUnit,
                                }, result, combatEventId)
                                logAuraProcDebug(
                                    entry,
                                    auraDefinition,
                                    auraCasterUnit,
                                    targetUnit,
                                    combatEventId,
                                    effect,
                                    normalizedChance,
                                    chanceRoll,
                                    applied and "executed" or "resolved-no-apply",
                                    result
                                )
                            else
                                if type(Debug.Internal) == "function" then
                                    Debug.Internal(
                                        "Aura trigger effect skipped: aura=%s event=%s effectIndex=%s effectType=%s contract=%s.",
                                        tostring(entry and entry.auraRef or "unknown"),
                                        tostring(combatEventId or "unknown"),
                                        tostring(effectIndex or "unknown"),
                                        tostring(effect and effect.type or "nil"),
                                        tostring(contract ~= nil)
                                    )
                                end
                                logAuraProcDebug(
                                    entry,
                                    auraDefinition,
                                    auraCasterUnit,
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
        end
    end

    if type(client) == "table" and type(client.HandleTraitCombatEvent) == "function" then
        if type(Debug) == "table" and type(Debug.Internal) == "function" then
            if type(Debug.EnsureInternalLevelEnabled) == "function" then
                Debug.EnsureInternalLevelEnabled()
            end
            Debug.Internal(
                "Trait handoff: event=%s recipient=%s source=%s other=%s",
                tostring(combatEventId or ""),
                tostring(recipientEventId or 0),
                tostring(eventSourceUnit and eventSourceUnit.name or ""),
                tostring(eventOtherUnit and eventOtherUnit.name or "")
            )
        end
        local ok, traitChangedOrError = xpcall(function()
            return client:HandleTraitCombatEvent(context)
        end, function(err)
            local stackLine = type(debugstack) == "function" and tostring(debugstack(2, 1, 0) or "") or ""
            if stackLine ~= "" then
                return ("%s @ %s"):format(tostring(err), stackLine)
            end
            return tostring(err)
        end)
        if not ok then
            if type(Debug) == "table" and type(Debug.Error) == "function" then
                Debug.Error(
                    "Trait handoff failed: event=%s recipient=%s error=%s",
                    tostring(combatEventId or ""),
                    tostring(recipientEventId or 0),
                    tostring(traitChangedOrError or "")
                )
            end
        else
            changed = traitChangedOrError or changed
        end
    end

    return changed
end

function AuraManager:AdvanceAuraDurations(entry)
    if type(entry) ~= "table" then
        return false
    end

    if entry.stackBehavior == "independent_duration" then
        local keptTurns = {}
        local maxTurns = 0
        for index = 1, #(entry.stackTurns or {}) do
            local nextTurns = (tonumber(entry.stackTurns[index]) or 0) - 1
            if nextTurns > 0 then
                keptTurns[#keptTurns + 1] = nextTurns
                maxTurns = math.max(maxTurns, nextTurns)
            end
        end
        entry.stackTurns = keptTurns
        entry.stacks = #keptTurns
        entry.turnsRemaining = maxTurns
        return entry.stacks <= 0
    end

    entry.turnsRemaining = math.max(0, (tonumber(entry.turnsRemaining) or 0) - 1)
    if entry.turnsRemaining <= 0 then
        entry.stacks = 0
        return true
    end

    return false
end

function AuraManager:AdvanceAuraEntry(client, eventId, auraKey, targetTurnNumber, targetTickNumber)
    local eventState = client.GetEventState and client:GetEventState() or nil
    if type(eventState) ~= "table" or eventState.active ~= true or tostring(eventState.id or "") ~= tostring(eventId or "") then
        return false
    end

    local bucket = self:GetEventAuraBucket(client, eventId, false)
    local entry = bucket and bucket.byKey and bucket.byKey[auraKey] or nil
    if type(entry) ~= "table" then
        return false
    end

    local timer = startTiming("Aura advancement entry", 8, eventId)

    local currentTurnNumber = math.max(1, math.floor(tonumber(targetTurnNumber) or tonumber(eventState.turnNumber) or 1))
    local currentTickNumber = math.max(1, math.floor(tonumber(targetTickNumber) or tonumber(eventState.tickNumber) or 1))
    local casterUnit = findEventUnit(eventState, entry.casterEventId)
    local targetUnit = findEventUnit(eventState, entry.targetEventId)
    local localPlayerEventId = resolveLocalEventId(eventState)
    local localPlayerDerivedStateImpact = nil
    local changed = false

    if not casterUnit or not targetUnit then
        if localPlayerEventId > 0 and tonumber(entry.targetEventId) == localPlayerEventId then
            localPlayerDerivedStateImpact = buildAuraDerivedStateImpact(entry)
        end
        self:RemoveAura(client, eventState, entry.auraRef, entry.casterEventId, entry.targetEventId)
        changed = true
        local activeBucket = self:GetEventAuraBucket(client, eventId, false)
        if activeBucket then
            invalidateControlStateCache(activeBucket, entry.targetEventId)
            bumpAuraBucketRevision(activeBucket)
        end
        if localPlayerDerivedStateImpact and localPlayerEventId > 0 then
            queueLocalPlayerAuraDerivedStateRefresh(eventState, localPlayerEventId, localPlayerDerivedStateImpact)
        end
        refreshAuraDisplays("aura-advance", eventState, localPlayerEventId, localPlayerDerivedStateImpact)
        if timer then
            stopTiming(timer, { activeAuras = countAuraEntries(bucket), dueAuras = 1, targetCount = 1 })
        end
        return changed
    end

    if not isAuraOwnerOccurrenceDue(eventState, entry, currentTurnNumber, currentTickNumber) then
        local pendingOwnerTurn = math.floor(tonumber(entry.pendingAdvancedOwnerTurnNumber) or 0)
        if pendingOwnerTurn <= currentTurnNumber then
            entry.pendingAdvancedOwnerTurnNumber = nil
        end
        if timer then
            stopTiming(timer, { activeAuras = countAuraEntries(bucket), dueAuras = 0, targetCount = 1 })
        end
        return false
    end

    if shouldExecuteLocalAuraTick(client, eventState, casterUnit) then
        self:TickAura(client, eventState, entry, casterUnit, targetUnit)
    end
    if self:AdvanceAuraDurations(entry) then
        if localPlayerEventId > 0 and tonumber(entry.targetEventId) == localPlayerEventId then
            localPlayerDerivedStateImpact = buildAuraDerivedStateImpact(entry)
        end
        self:RemoveAura(client, eventState, entry.auraRef, entry.casterEventId, entry.targetEventId)
        changed = true
    else
        changed = true
    end

    entry.lastAdvancedOwnerTurnNumber = currentTurnNumber

    if math.floor(tonumber(entry.pendingAdvancedOwnerTurnNumber) or 0) <= currentTurnNumber then
        entry.pendingAdvancedOwnerTurnNumber = nil
    end

    if changed then
        local activeBucket = self:GetEventAuraBucket(client, eventId, false)
        if activeBucket then
            invalidateControlStateCache(activeBucket, entry and entry.targetEventId or nil)
            bumpAuraBucketRevision(activeBucket)
        end
        if localPlayerDerivedStateImpact and localPlayerEventId > 0 then
            queueLocalPlayerAuraDerivedStateRefresh(eventState, localPlayerEventId, localPlayerDerivedStateImpact)
        end
        refreshAuraDisplays("aura-advance", eventState, localPlayerEventId, localPlayerDerivedStateImpact)
    end

    if timer then
        stopTiming(timer, {
            activeAuras = countAuraEntries(bucket),
            dueAuras = 1,
            targetCount = 1,
        })
    end
    return changed
end

function AuraManager:AdvanceAuraState(client, previousTurnNumber, previousTickNumber)
    local eventState = client.GetEventState and client:GetEventState() or nil
    if not eventState or eventState.active ~= true then
        return false
    end

    local eventId = tostring(eventState.id or "")
    if eventId == "" then
        return false
    end

    local timer = startTiming("Aura advancement", 8, eventId)

    local currentTurnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1))
    local currentTickNumber = math.max(1, math.floor(tonumber(eventState.tickNumber) or 1))
    local previousTurn = math.max(0, math.floor(tonumber(previousTurnNumber) or 0))
    local previousTick = math.max(0, math.floor(tonumber(previousTickNumber) or 0))
    if previousTurn == currentTurnNumber and previousTick == currentTickNumber then
        if timer then
            stopTiming(timer, { activeAuras = 0, dueAuras = 0, queuedAuras = 0, eventUnits = type(eventState.units) == "table" and #eventState.units or 0 })
        end
        return false
    end

    local bucket = self:GetEventAuraBucket(client, eventId, false)
    if not bucket then
        if timer then
            stopTiming(timer, { activeAuras = 0, dueAuras = 0, queuedAuras = 0, eventUnits = type(eventState.units) == "table" and #eventState.units or 0 })
        end
        return false
    end

    local queued = false
    local dueAuras = 0

    for auraKey, entry in pairs(bucket.byKey or {}) do
        if type(entry) == "table" then
            if isAuraOwnerOccurrenceDue(eventState, entry, currentTurnNumber, currentTickNumber) then
                dueAuras = dueAuras + 1
                local pendingOwnerTurn = math.floor(tonumber(entry.pendingAdvancedOwnerTurnNumber) or 0)
                if pendingOwnerTurn < currentTurnNumber then
                    entry.pendingAdvancedOwnerTurnNumber = currentTurnNumber
                    local enqueued = enqueueAuraWork(function(manager, targetClient, targetEventId, targetAuraKey, turnNumber, tickNumber)
                        manager:AdvanceAuraEntry(targetClient, targetEventId, targetAuraKey, turnNumber, tickNumber)
                    end, self, client, eventId, auraKey, currentTurnNumber, currentTickNumber)
                    if enqueued then
                        queued = true
                    else
                        entry.pendingAdvancedOwnerTurnNumber = pendingOwnerTurn > 0 and pendingOwnerTurn or nil
                    end
                end
            end
        end
    end

    if timer then
        stopTiming(timer, {
            activeAuras = countAuraEntries(bucket),
            dueAuras = dueAuras,
            queuedAuras = queued and dueAuras or 0,
            eventUnits = type(eventState.units) == "table" and #eventState.units or 0,
        })
    end
    return queued
end

local function getAuraConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function buildStatModifierTotalsCacheKey(unitEventId, statRef, revision, configurationRevision)
    return ("%d:%s:%d:%d"):format(
        tonumber(unitEventId) or 0,
        tostring(statRef or ""),
        tonumber(revision) or 0,
        tonumber(configurationRevision) or 0
    )
end

local function buildStatModifierAggregateCacheKey(eventId, unitEventId, revision, configurationRevision)
    return ("%s:%d:%d:%d"):format(
        tostring(eventId or ""),
        tonumber(unitEventId) or 0,
        tonumber(revision) or 0,
        tonumber(configurationRevision) or 0
    )
end

local function isStatModifierContinuationCurrent(continuation)
    if type(continuation) ~= "table" then
        return false
    end

    local client = type(continuation.client) == "table" and continuation.client or Client
    local currentEventState = type(client.GetEventState) == "function" and client:GetEventState() or client.EventState
    if type(currentEventState) ~= "table"
        or currentEventState.active ~= true
        or tostring(currentEventState.id or "") ~= tostring(continuation.eventId or "")
        or (type(continuation.eventState) == "table" and currentEventState ~= continuation.eventState)
    then
        return false
    end
    local currentLocalUnit = resolveLocalEventUnit(currentEventState)
    if tonumber(currentLocalUnit and currentLocalUnit.eventID) ~= tonumber(continuation.unitEventId) then
        return false
    end

    local currentBucket = ensureBucket(client, continuation.eventId, false)
    if currentBucket ~= continuation.bucket then
        return false
    end
    if currentBucket
        and math.floor(tonumber(currentBucket.revision) or 0) ~= tonumber(continuation.auraRevision)
    then
        return false
    end

    return getAuraConfigurationRevision() == tonumber(continuation.configurationRevision)
end

function AuraManager:CreateStatModifierTotalsContinuation(client, eventState, unitEventId)
    local targetClient = type(client) == "table" and client or Client
    local eventId = tostring(eventState and eventState.id or "")
    local numericUnitEventId = tonumber(unitEventId) or 0
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or eventId == ""
        or numericUnitEventId <= 0
    then
        return nil
    end

    local bucket = self:GetEventAuraBucket(targetClient, eventId, false)
    local revision = math.max(0, math.floor(tonumber(bucket and bucket.revision) or 0))
    local configurationRevision = getAuraConfigurationRevision()
    local aggregateCacheKey = buildStatModifierAggregateCacheKey(
        eventId,
        numericUnitEventId,
        revision,
        configurationRevision
    )
    local cached = type(bucket) == "table"
        and type(bucket.statModifierAggregateCache) == "table"
        and bucket.statModifierAggregateCache[aggregateCacheKey]
        or nil

    return {
        client = targetClient,
        eventState = eventState,
        eventId = eventId,
        unitEventId = numericUnitEventId,
        bucket = bucket,
        auraRevision = revision,
        configurationRevision = configurationRevision,
        aggregateCacheKey = aggregateCacheKey,
        auraKeys = type(bucket) == "table"
            and type(bucket.auraKeysByTarget) == "table"
            and type(bucket.auraKeysByTarget[numericUnitEventId]) == "table"
            and bucket.auraKeysByTarget[numericUnitEventId]
            or {},
        auraIndex = 1,
        currentAura = nil,
        currentDefinition = nil,
        targetUnit = nil,
        targetUnitResolved = false,
        effectKeyContinuation = nil,
        effectKeys = nil,
        effectIndex = 1,
        modifiersByStat = type(cached) == "table" and cached or {},
        failedStatRefs = {},
        phase = type(cached) == "table" and "complete" or "auras",
    }
end

function AuraManager:StepStatModifierTotalsContinuation(continuation, deadlineMs)
    if type(continuation) ~= "table" then
        return true
    end
    if not isStatModifierContinuationCurrent(continuation) then
        return nil, "aura-stale"
    end
    if continuation.phase == "complete" then
        return true
    end

    while true do
        if continuation.phase == "auras" then
            local auraKey = continuation.auraKeys[continuation.auraIndex]
            if auraKey == nil then
                continuation.phase = "publish"
            else
                continuation.auraIndex = continuation.auraIndex + 1
                local entry = continuation.bucket.byKey and continuation.bucket.byKey[auraKey] or nil
                if type(entry) == "table"
                    and (tonumber(entry.stacks) or 0) > 0
                    and type(entry.definition) == "table"
                then
                    if not continuation.targetUnitResolved then
                        continuation.targetUnit = findEventUnit(
                            continuation.eventState or (type(continuation.client.GetEventState) == "function" and continuation.client:GetEventState()),
                            continuation.unitEventId
                        )
                        continuation.targetUnitResolved = true
                    end
                    continuation.currentAura = entry
                    continuation.currentDefinition = entry.definition
                    continuation.effectKeyContinuation = createSortedNumericKeyContinuation(entry.definition.effects)
                    continuation.effectKeys = nil
                    continuation.effectIndex = 1
                    continuation.currentCasterUnit = findEventUnit(
                        continuation.eventState or (type(continuation.client.GetEventState) == "function" and continuation.client:GetEventState()),
                        entry.casterEventId
                    )
                    continuation.phase = "effect-keys"
                end
            end
        elseif continuation.phase == "effect-keys" then
            if stepSortedNumericKeyContinuation(continuation.effectKeyContinuation) then
                continuation.effectKeys = continuation.effectKeyContinuation.keys
                continuation.effectKeyContinuation = nil
                continuation.effectIndex = 1
                continuation.phase = "effects"
            end
        elseif continuation.phase == "effects" then
            local keyEntry = continuation.effectKeys[continuation.effectIndex]
            if keyEntry == nil then
                continuation.currentAura = nil
                continuation.currentDefinition = nil
                continuation.currentCasterUnit = nil
                continuation.effectKeys = nil
                continuation.phase = "auras"
            else
                continuation.effectIndex = continuation.effectIndex + 1
                local effect = continuation.currentDefinition.effects[keyEntry.key]
                local statRef = normalizeRef(effect and effect.statRef)
                local contract = statRef and self:GetEffect(effect and effect.type or nil) or nil
                if statRef
                    and type(continuation.currentCasterUnit) == "table"
                    and contract
                    and type(contract.Accumulate) == "function"
                    and not continuation.failedStatRefs[statRef]
                then
                    local accumulator = continuation.modifiersByStat[statRef]
                    if type(accumulator) ~= "table" then
                        accumulator = { flat = 0, percent = 0 }
                        continuation.modifiersByStat[statRef] = accumulator
                    end
                    local ok = pcall(contract.Accumulate, contract, {
                        aura = continuation.currentAura,
                        auraDefinition = continuation.currentDefinition,
                        eventState = continuation.eventState
                            or (type(continuation.client.GetEventState) == "function" and continuation.client:GetEventState()),
                        casterUnit = continuation.currentCasterUnit,
                        targetUnit = continuation.targetUnit,
                        statRef = statRef,
                    }, effect, accumulator)
                    if not ok then
                        continuation.failedStatRefs[statRef] = true
                        continuation.modifiersByStat[statRef] = nil
                    end
                end
            end
        else
            if not isStatModifierContinuationCurrent(continuation) then
                return nil, "aura-stale"
            end
            local bucket = continuation.bucket
            if type(bucket) ~= "table" then
                continuation.phase = "complete"
                return true
            end
            bucket.statModifierAggregateCache = bucket.statModifierAggregateCache or {}
            bucket.statModifierAggregateCache[continuation.aggregateCacheKey] = continuation.modifiersByStat
            continuation.failedStatRefs = nil
            continuation.phase = "complete"
            return true
        end

        if shouldYieldAuraSlice(deadlineMs) then
            return false
        end
    end
end

function AuraManager:BuildStatModifierTotals(eventState, unitEventId, statRef)
    local bucket = self:GetEventAuraBucket(Client, eventState and eventState.id or nil, false)
    if not bucket then
        return 0, 0
    end

    local normalizedStatRef = normalizeRef(statRef)
    if not normalizedStatRef then
        return 0, 0
    end

    local numericUnitEventId = tonumber(unitEventId) or 0
    if numericUnitEventId <= 0 then
        return 0, 0
    end

    bucket.statModifierTotalsCache = bucket.statModifierTotalsCache or {}
    bucket.statModifierAggregateCache = bucket.statModifierAggregateCache or {}
    local revision = math.max(0, math.floor(tonumber(bucket.revision) or 0))
    local configurationRevision = getAuraConfigurationRevision()
    local cacheKey = buildStatModifierTotalsCacheKey(
        numericUnitEventId,
        normalizedStatRef,
        revision,
        configurationRevision
    )
    local cached = bucket.statModifierTotalsCache[cacheKey]
    if type(cached) == "table" then
        return tonumber(cached.flat) or 0, tonumber(cached.percent) or 0
    end

    local aggregateCacheKey = buildStatModifierAggregateCacheKey(
        eventState and eventState.id or nil,
        numericUnitEventId,
        revision,
        configurationRevision
    )
    local aggregate = bucket.statModifierAggregateCache[aggregateCacheKey]
    if type(aggregate) == "table" then
        local aggregateValue = aggregate[normalizedStatRef]
        local flat = tonumber(aggregateValue and aggregateValue.flat) or 0
        local percent = tonumber(aggregateValue and aggregateValue.percent) or 0
        bucket.statModifierTotalsCache[cacheKey] = {
            flat = flat,
            percent = percent,
        }
        return flat, percent
    end

    local flatTotal = 0
    local percentTotal = 0
    local targetUnit = findEventUnit(eventState, numericUnitEventId)
    local targetEntries = getBucketAuraEntriesForTarget(bucket, numericUnitEventId)
    for index = 1, #targetEntries do
        local entry = targetEntries[index]
        local runtime = buildAuraRuntimeEntry(self, bucket, entry)
        local auraDefinition = runtime and runtime.definition or nil
        local casterUnit = findEventUnit(eventState, entry.casterEventId)
        if type(auraDefinition) == "table" and casterUnit then
            local effectKeys = runtime and runtime.effectKeys or {}
            for effectKeyIndex = 1, #effectKeys do
                local effectIndex = effectKeys[effectKeyIndex].key
                local effect = auraDefinition.effects[effectIndex]
                local contract = self:GetEffect(effect and effect.type or nil)
                if contract and type(contract.Accumulate) == "function" then
                    local accumulator = {
                        flat = flatTotal,
                        percent = percentTotal,
                    }
                    contract:Accumulate({
                        aura = entry,
                        auraDefinition = auraDefinition,
                        eventState = eventState,
                        casterUnit = casterUnit,
                        targetUnit = targetUnit or findEventUnit(eventState, entry.targetEventId),
                        statRef = normalizedStatRef,
                    }, effect, accumulator)
                    flatTotal = accumulator.flat
                    percentTotal = accumulator.percent
                end
            end
        end
    end

    bucket.statModifierTotalsCache[cacheKey] = {
        flat = flatTotal,
        percent = percentTotal,
    }
    return flatTotal, percentTotal
end

function AuraManager:BuildSkillModifierTotal(eventState, unitEventId, skillRef)
    local bucket = self:GetEventAuraBucket(Client, eventState and eventState.id or nil, false)
    if not bucket then
        return 0
    end

    local flatTotal = 0
    local normalizedSkillRef = normalizeRef(skillRef)
    if not normalizedSkillRef then
        return 0
    end

    for _, entry in pairs(bucket.byKey or {}) do
        if type(entry) == "table" and tonumber(entry.targetEventId) == (tonumber(unitEventId) or 0) and (tonumber(entry.stacks) or 0) > 0 then
            local auraDefinition = entry.definition
            local _, resolvedAuraDefinition = self:ResolveAuraDefinition(entry.auraRef, { datasetId = entry.datasetId })
            if type(resolvedAuraDefinition) == "table" then
                entry.definition = resolvedAuraDefinition
                auraDefinition = resolvedAuraDefinition
            end

            local casterUnit = findEventUnit(eventState, entry.casterEventId)
            if type(auraDefinition) == "table" and casterUnit then
                local effectKeys = sortedNumericKeys(auraDefinition.effects)
                for effectKeyIndex = 1, #effectKeys do
                    local effect = auraDefinition.effects[effectKeys[effectKeyIndex].key]
                    if type(effect) == "table"
                        and tostring(effect.type or "") == "skill"
                        and normalizeRef(effect.skillRef) == normalizedSkillRef
                    then
                        flatTotal = flatTotal + (tonumber(self:ResolveEffectAmount({
                            aura = entry,
                            auraDefinition = auraDefinition,
                            eventState = eventState,
                            casterUnit = casterUnit,
                            targetUnit = findEventUnit(eventState, entry.targetEventId),
                        }, effect, "baseAmount")) or 0)
                    end
                end
            end
        end
    end

    return flatTotal
end

function AuraManager:BuildControlState(eventState, unitEventId)
    local bucket = self:GetEventAuraBucket(Client, eventState and eventState.id or nil, false)
    local state = {
        cancelOnDamage = false,
        preventCasting = false,
        movementRangeOverride = nil,
        forceAutoHitAgainstTarget = false,
    }
    if not bucket then
        return state
    end

    local numericUnitEventId = tonumber(unitEventId) or 0
    if numericUnitEventId <= 0 then
        return state
    end

    bucket.controlStateByTarget = type(bucket.controlStateByTarget) == "table" and bucket.controlStateByTarget or {}
    local cachedState = bucket.controlStateByTarget[numericUnitEventId]
    if type(cachedState) == "table" then
        return {
            cancelOnDamage = cachedState.cancelOnDamage == true,
            preventCasting = cachedState.preventCasting == true,
            movementRangeOverride = tonumber(cachedState.movementRangeOverride),
            forceAutoHitAgainstTarget = cachedState.forceAutoHitAgainstTarget == true,
        }
    end

    local targetEntries = getBucketAuraEntriesForTarget(bucket, numericUnitEventId)
    for index = 1, #targetEntries do
        local entry = targetEntries[index]
        local runtime = buildAuraRuntimeEntry(self, bucket, entry)
        local control = runtime and runtime.control or nil
        if type(control) == "table" then
            state.cancelOnDamage = state.cancelOnDamage or control.cancelOnDamage == true
            state.preventCasting = state.preventCasting or control.preventCasting == true
            state.forceAutoHitAgainstTarget = state.forceAutoHitAgainstTarget or control.forceAutoHitAgainstTarget == true
            if control.movementRangeOverride ~= nil then
                local overrideValue = tonumber(control.movementRangeOverride)
                if overrideValue ~= nil then
                    state.movementRangeOverride = state.movementRangeOverride ~= nil
                        and math.min(state.movementRangeOverride, overrideValue)
                        or overrideValue
                end
            end
        end
    end

    bucket.controlStateByTarget[numericUnitEventId] = {
        cancelOnDamage = state.cancelOnDamage == true,
        preventCasting = state.preventCasting == true,
        movementRangeOverride = state.movementRangeOverride,
        forceAutoHitAgainstTarget = state.forceAutoHitAgainstTarget == true,
    }
    return state
end

function AuraManager:CanUnitCast(eventState, unitEventId)
    return self:BuildControlState(eventState, unitEventId).preventCasting ~= true
end

function AuraManager:ShouldForceAutoHitAgainstTarget(eventState, unitEventId)
    return self:BuildControlState(eventState, unitEventId).forceAutoHitAgainstTarget == true
end

function AuraManager:GetLocalPlayerMovementRangeOverride()
    local eventState = Client.GetEventState and Client:GetEventState() or nil
    local localPlayerEventId = resolveLocalEventId(eventState)
    if localPlayerEventId <= 0 then
        return nil
    end

    return self:BuildControlState(eventState, localPlayerEventId).movementRangeOverride
end

function AuraManager:HandleDamageTaken(client, eventState, targetEventId, sourceContext)
    local controlState = self:BuildControlState(eventState, targetEventId)
    if controlState.cancelOnDamage ~= true then
        return false
    end

    local bucket = self:GetEventAuraBucket(client, eventState and eventState.id or nil, false)
    if not bucket then
        return false
    end

    local removedAny = false
    local targetEntries = getBucketAuraEntriesForTarget(bucket, targetEventId)
    for index = 1, #targetEntries do
        local entry = targetEntries[index]
        local runtime = buildAuraRuntimeEntry(self, bucket, entry)
        if type(runtime) == "table" and type(runtime.control) == "table" and runtime.control.cancelOnDamage == true then
            removedAny = self:DispelAuraFromContext(client, sourceContext or { eventState = eventState }, entry.auraRef, entry.casterEventId, entry.targetEventId, entry) or removedAny
        end
    end

    return removedAny
end

function AuraManager:ApplyStatModifiers(unit, statRef, baseValue)
    local eventState = Client.GetEventState and Client:GetEventState() or nil
    local unitEventId = tonumber(unit and unit.eventID) or 0
    if not eventState or eventState.active ~= true or unitEventId <= 0 then
        return baseValue
    end

    local flatTotal, percentTotal = self:BuildStatModifierTotals(eventState, unitEventId, statRef)
    if flatTotal == 0 and percentTotal == 0 then
        return baseValue
    end

    local value = tonumber(baseValue) or 0
    value = value + flatTotal
    if percentTotal ~= 0 then
        value = value * (1 + (percentTotal / 100))
    end

    if type(Common.Round) == "function" then
        return Common.Round(value)
    end

    return math.floor(value + 0.5)
end

function AuraManager:RefreshLocalPlayerDerivedState(eventState, options)
    local localPlayerEventId = resolveLocalEventId(eventState)
    if localPlayerEventId <= 0 then
        return false
    end

    return self:QueueLocalPlayerDerivedStateRefresh(eventState, options)
end

function AuraManager:ValidateInboundAuraPayload(client, sender, channelName, eventId, casterEventId, targetEventId, auraRef, stacks, turns, powerLevel)
    local sessionState, eventState = nil, nil
    if type(Spellcasting.GetActiveSpellcastContext) == "function" then
        sessionState, eventState = Spellcasting.GetActiveSpellcastContext(client)
    end
    if not sessionState or not eventState then
        return nil
    end

    if type(channelName) ~= "string" or channelName == "" or channelName ~= sessionState.channelName then
        return nil
    end

    if type(eventId) ~= "string" or eventId == "" or eventId ~= eventState.id then
        return nil
    end

    local numericCasterEventId = tonumber(casterEventId) or 0
    local numericTargetEventId = tonumber(targetEventId) or 0
    if numericCasterEventId <= 0 or numericTargetEventId <= 0 then
        return nil
    end

    local normalizedAuraRef = normalizeRef(auraRef)
    if not normalizedAuraRef then
        return nil
    end

    local casterUnit = findEventUnit(eventState, numericCasterEventId)
    local targetUnit = findEventUnit(eventState, numericTargetEventId)
    if not casterUnit or not targetUnit then
        return nil
    end

    local normalizedSender = Spellcasting.NormalizeName and Spellcasting.NormalizeName(sender) or tostring(sender or "")
    local expectedSender = resolveExpectedSender(eventState, casterUnit)
    if normalizedSender == "" or expectedSender == "" or normalizedSender ~= expectedSender then
        return nil
    end

    return {
        sessionState = sessionState,
        eventState = eventState,
        channelName = channelName,
        eventId = eventId,
        casterEventId = numericCasterEventId,
        targetEventId = numericTargetEventId,
        casterUnit = casterUnit,
        targetUnit = targetUnit,
        auraRef = normalizedAuraRef,
        sender = normalizedSender,
        stacks = math.max(1, math.floor(tonumber(stacks) or 1)),
        turns = math.max(1, math.floor(tonumber(turns) or 1)),
        powerLevel = tonumber(powerLevel) or 0,
    }
end

function AuraManager:ValidateInboundAura(client, arguments, sender)
    return self:ValidateInboundAuraPayload(
        client,
        sender,
        arguments and arguments[1] or nil,
        arguments and arguments[2] or nil,
        arguments and arguments[3] or nil,
        arguments and arguments[4] or nil,
        arguments and arguments[5] or nil,
        arguments and arguments[6] or nil,
        arguments and arguments[7] or nil,
        arguments and arguments[8] or nil
    )
end

function AuraManager:HandleAuraApply(client, arguments, sender)
    local payload = self:ValidateInboundAura(client, arguments, sender)
    if not payload then
        return false
    end

    local localPlayerName = Spellcasting.GetLocalPlayerName and Spellcasting.GetLocalPlayerName() or ""
    if localPlayerName ~= "" and payload.sender == localPlayerName then
        local signature = buildAuraApplySignature(
            payload.channelName,
            payload.eventId,
            payload.casterEventId,
            payload.targetEventId,
            payload.auraRef,
            payload.stacks,
            payload.turns,
            payload.powerLevel
        )
        if consumePendingSignature(client.PendingLocalAuraApplyEchoSignatures, signature) then
            return true
        end
        return true
    end

    local existingBucket = self:GetEventAuraBucket(client, payload.eventId, false)
    local existingAuraKey = buildAuraKey(payload.auraRef, payload.casterEventId, payload.targetEventId)
    local previousEntry = cloneAuraTickerState(existingBucket and existingBucket.byKey and existingBucket.byKey[existingAuraKey] or nil)
    local applied, entry = self:UpsertAura(client, payload)
    if applied then
        local derivedStateImpact = buildAuraDerivedStateImpact(previousEntry, entry) or buildEmptyDerivedStateImpact()
        publishAuraCombatLog(client, payload.eventState, previousEntry, entry, true)
        queueLocalPlayerAuraDerivedStateRefresh(payload.eventState, payload.targetEventId, derivedStateImpact)
        refreshAuraDisplays("aura-apply-inbound", payload.eventState, payload.targetEventId, derivedStateImpact)
    end
    return applied
end

function AuraManager:HandleAuraDispel(client, arguments, sender)
    local payload = self:ValidateInboundAura(client, arguments, sender)
    if not payload then
        return false
    end

    local localPlayerName = Spellcasting.GetLocalPlayerName and Spellcasting.GetLocalPlayerName() or ""
    if localPlayerName ~= "" and payload.sender == localPlayerName then
        local signature = buildAuraDispelSignature(
            payload.channelName,
            payload.eventId,
            payload.casterEventId,
            payload.targetEventId,
            payload.auraRef
        )
        if consumePendingSignature(client.PendingLocalAuraDispelEchoSignatures, signature) then
            return true
        end
        return true
    end

    local removed, removedEntry = self:RemoveAura(client, payload.eventState, payload.auraRef, payload.casterEventId, payload.targetEventId)
    if removed then
        local previousEntry = cloneAuraTickerState(removedEntry)
        local derivedStateImpact = buildAuraDerivedStateImpact(previousEntry) or buildEmptyDerivedStateImpact()
        publishAuraCombatLog(client, payload.eventState, previousEntry, nil, true)
        queueLocalPlayerAuraDerivedStateRefresh(payload.eventState, payload.targetEventId, derivedStateImpact)
        refreshAuraDisplays("aura-dispel-inbound", payload.eventState, payload.targetEventId, derivedStateImpact)
    end
    return removed
end

function AuraManager:HandleAuraApplyBatch(client, arguments, sender)
    local channelName = arguments and arguments[1] or nil
    local eventId = arguments and arguments[2] or nil
    local payloadText = arguments and arguments[3] or ""
    if type(channelName) ~= "string" or channelName == "" or type(eventId) ~= "string" or eventId == "" then
        return false
    end
    local localPlayerName = Spellcasting.GetLocalPlayerName and Spellcasting.GetLocalPlayerName() or ""
    local normalizedSender = Spellcasting.NormalizeName and Spellcasting.NormalizeName(sender) or tostring(sender or "")
    if localPlayerName ~= "" and normalizedSender == localPlayerName then
        local signature = buildAuraApplyBatchSignature(channelName, eventId, payloadText)
        if consumePendingSignature(client.PendingLocalAuraApplyBatchEchoSignatures, signature) then
            return true
        end
        return true
    end

    local entries = normalizeAuraApplyEntries(payloadText)
    if #entries == 0 then
        return false
    end

    local changed = false
    local localPlayerDerivedStateImpact = nil
    local eventState = type(client.GetEventState) == "function" and client:GetEventState() or nil
    local localPlayerEventId = resolveLocalEventId(eventState)
    for index = 1, #entries do
        local entry = entries[index]
        local payload = self:ValidateInboundAuraPayload(
            client,
            sender,
            channelName,
            eventId,
            entry.casterEventId,
            entry.targetEventId,
            entry.auraRef,
            entry.stacks,
            entry.turns,
            entry.powerLevel
        )
        if payload then
            payload.fullState = entry.fullState == true
            local existingBucket = self:GetEventAuraBucket(client, payload.eventId, false)
            local existingAuraKey = buildAuraKey(payload.auraRef, payload.casterEventId, payload.targetEventId)
            local previousEntry = cloneAuraTickerState(existingBucket and existingBucket.byKey and existingBucket.byKey[existingAuraKey] or nil)
            local applied, nextEntry = self:UpsertAura(client, payload)
            if applied then
                publishAuraCombatLog(client, payload.eventState, previousEntry, nextEntry, true)
                if localPlayerEventId > 0 and tonumber(payload.targetEventId) == localPlayerEventId then
                    localPlayerDerivedStateImpact = localPlayerDerivedStateImpact or {
                        statRefs = {},
                        resourceRefs = {},
                    }
                    mergeDerivedStateImpact(localPlayerDerivedStateImpact, buildAuraDerivedStateImpact(previousEntry, nextEntry) or {})
                end
            end
            changed = applied or changed
        end
    end

    if changed then
        if localPlayerDerivedStateImpact and localPlayerEventId > 0 then
            queueLocalPlayerAuraDerivedStateRefresh(eventState, localPlayerEventId, localPlayerDerivedStateImpact)
        end
        refreshAuraDisplays("aura-apply-batch-inbound", eventState, localPlayerEventId, localPlayerDerivedStateImpact)
    end
    return changed
end

function AuraManager:HandleAuraDispelBatch(client, arguments, sender)
    local channelName = arguments and arguments[1] or nil
    local eventId = arguments and arguments[2] or nil
    local payloadText = arguments and arguments[3] or ""
    if type(channelName) ~= "string" or channelName == "" or type(eventId) ~= "string" or eventId == "" then
        return false
    end
    local localPlayerName = Spellcasting.GetLocalPlayerName and Spellcasting.GetLocalPlayerName() or ""
    local normalizedSender = Spellcasting.NormalizeName and Spellcasting.NormalizeName(sender) or tostring(sender or "")
    if localPlayerName ~= "" and normalizedSender == localPlayerName then
        local signature = buildAuraDispelBatchSignature(channelName, eventId, payloadText)
        if consumePendingSignature(client.PendingLocalAuraDispelBatchEchoSignatures, signature) then
            return true
        end
        return true
    end

    local entries = normalizeAuraDispelEntries(payloadText)
    if #entries == 0 then
        return false
    end

    local changed = false
    local localPlayerDerivedStateImpact = nil
    local eventState = type(client.GetEventState) == "function" and client:GetEventState() or nil
    local localPlayerEventId = resolveLocalEventId(eventState)
    for index = 1, #entries do
        local entry = entries[index]
        local payload = self:ValidateInboundAuraPayload(
            client,
            sender,
            channelName,
            eventId,
            entry.casterEventId,
            entry.targetEventId,
            entry.auraRef
        )
        if payload then
            local removed, removedEntry = self:RemoveAura(client, payload.eventState, payload.auraRef, payload.casterEventId, payload.targetEventId)
            if removed then
                local previousEntry = cloneAuraTickerState(removedEntry)
                publishAuraCombatLog(client, payload.eventState, previousEntry, nil, true)
                if localPlayerEventId > 0 and tonumber(payload.targetEventId) == localPlayerEventId then
                    localPlayerDerivedStateImpact = localPlayerDerivedStateImpact or {
                        statRefs = {},
                        resourceRefs = {},
                    }
                    mergeDerivedStateImpact(localPlayerDerivedStateImpact, buildAuraDerivedStateImpact(previousEntry) or {})
                end
            end
            changed = removed or changed
        end
    end

    if changed then
        if localPlayerDerivedStateImpact and localPlayerEventId > 0 then
            queueLocalPlayerAuraDerivedStateRefresh(eventState, localPlayerEventId, localPlayerDerivedStateImpact)
        end
        refreshAuraDisplays("aura-dispel-batch-inbound", eventState, localPlayerEventId, localPlayerDerivedStateImpact)
    end
    return changed
end

Addon.Internal = Addon.Internal or {}
Addon.Internal.AuraManager = AuraManager
Spellcasting.AuraManager = AuraManager
Spellcasting.ResetAuraState = function(client, eventId)
    return AuraManager:ResetAuraState(client, eventId)
end
Spellcasting.AdvanceAuraState = function(client, previousTurnNumber, previousTickNumber)
    return AuraManager:AdvanceAuraState(client, previousTurnNumber, previousTickNumber)
end

Client.ActiveAurasByEventId = Client.ActiveAurasByEventId or {}
Client.PendingOutboundAuraFlushQueued = Client.PendingOutboundAuraFlushQueued or false
Client.PendingOutboundAuraFlushQueuedByScope = Client.PendingOutboundAuraFlushQueuedByScope or {}
Client.PendingOutboundAuraFlushJobsByScope = Client.PendingOutboundAuraFlushJobsByScope or {}
Client.PendingOutboundAuraFlushStatusByScope = Client.PendingOutboundAuraFlushStatusByScope or {}
Client.PendingOutboundAuraOperations = Client.PendingOutboundAuraOperations or {}
Client.PendingOutboundAuraOperationOrder = Client.PendingOutboundAuraOperationOrder or {}
Client.PendingOutboundAuraOperationOrderByScope = Client.PendingOutboundAuraOperationOrderByScope or {}
Client.PendingOutboundAuraOperationCountsByScope = Client.PendingOutboundAuraOperationCountsByScope or {}
Client.PendingFullAuraDerivedStateRefreshByEventId = Client.PendingFullAuraDerivedStateRefreshByEventId or {}
Client.PendingLocalAuraApplyBatchEchoSignatures = Client.PendingLocalAuraApplyBatchEchoSignatures or {}
Client.PendingLocalAuraDispelBatchEchoSignatures = Client.PendingLocalAuraDispelBatchEchoSignatures or {}
Client.PendingAuraDisplayRefreshQueued = Client.PendingAuraDisplayRefreshQueued or false
Client.PendingAuraDisplayRefreshReason = Client.PendingAuraDisplayRefreshReason or nil
