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
        byKey = {},
    }
    client.ActiveAurasByEventId[normalizedEventId] = bucket
    return bucket
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

local function resolveEventProgressStep(turnNumber, tickNumber, totalTicks)
    local normalizedTotalTicks = math.max(1, math.floor(tonumber(totalTicks) or 1))
    local normalizedTurnNumber = math.max(1, math.floor(tonumber(turnNumber) or 1))
    local normalizedTickNumber = math.max(1, math.floor(tonumber(tickNumber) or 1))
    if normalizedTickNumber > normalizedTotalTicks then
        normalizedTickNumber = normalizedTotalTicks
    end

    return ((normalizedTurnNumber - 1) * normalizedTotalTicks) + normalizedTickNumber
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
    if type(debugprofilestop) == "function" then
        return debugprofilestop()
    end

    return (os.clock() or 0) * 1000
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

local function setToOrderedList(values)
    local ordered = {}
    for ref in pairs(type(values) == "table" and values or {}) do
        ordered[#ordered + 1] = ref
    end
    table.sort(ordered)
    return ordered
end

local function updateLocalUnitStatsSubset(localUnit, statRows)
    local stats = type(localUnit.stats) == "table" and localUnit.stats or {}
    local indexByRef = {}
    local changed = false

    for index = 1, #stats do
        local entry = stats[index]
        local statRef = type(entry) == "table" and normalizeRef(entry.statRef) or nil
        if statRef then
            indexByRef[statRef] = index
        end
    end

    for index = 1, #statRows do
        local row = statRows[index]
        local statRef = type(row) == "table" and normalizeRef(row.ref) or nil
        if statRef then
            local value = tonumber(row.value) or 0
            local existingIndex = indexByRef[statRef]
            if existingIndex then
                local existing = stats[existingIndex]
                if tonumber(existing and existing.value) ~= value or tonumber(existing and existing.currentValue) ~= value then
                    stats[existingIndex] = {
                        statRef = statRef,
                        value = value,
                        currentValue = value,
                    }
                    changed = true
                end
            else
                stats[#stats + 1] = {
                    statRef = statRef,
                    value = value,
                    currentValue = value,
                }
                indexByRef[statRef] = #stats
                changed = true
            end
        end
    end

    localUnit.stats = stats
    return changed
end

local function updateLocalUnitResourcesSubset(localUnit, resourceRows)
    local resources = type(localUnit.resources) == "table" and localUnit.resources or {}
    local indexByRef = {}
    local changed = false

    for index = 1, #resources do
        local entry = resources[index]
        local resourceRef = type(entry) == "table" and normalizeRef(entry.resourceRef) or nil
        if resourceRef then
            indexByRef[resourceRef] = index
        end
    end

    for index = 1, #resourceRows do
        local row = resourceRows[index]
        local resourceRef = type(row) == "table" and normalizeRef(row.ref) or nil
        if resourceRef then
            local maxValue = math.max(0, tonumber(row.value) or 0)
            local existingIndex = indexByRef[resourceRef]
            local existing = existingIndex and resources[existingIndex] or nil
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
            currentValue = math.max(0, math.min(currentValue, maxValue))

            if existingIndex then
                if previousMaxValue ~= maxValue or tonumber(existing and existing.currentValue) ~= currentValue then
                    resources[existingIndex] = {
                        resourceRef = resourceRef,
                        currentValue = currentValue,
                        maxValue = maxValue,
                    }
                    changed = true
                end
            else
                resources[#resources + 1] = {
                    resourceRef = resourceRef,
                    currentValue = currentValue,
                    maxValue = maxValue,
                }
                indexByRef[resourceRef] = #resources
                changed = true
            end
        end
    end

    localUnit.resources = resources
    return changed
end

local function rebuildLocalPlayerResolvedState(eventState, localUnit)
    if type(eventState) ~= "table" or eventState.active ~= true or type(localUnit) ~= "table" then
        return false
    end

    local resolvedStats = type(Profile.ListResolvedStats) == "function" and Profile.ListResolvedStats({
        includeAuraBonuses = true,
    }) or {}
    local nextStats = {}
    for index = 1, #resolvedStats do
        local row = resolvedStats[index]
        local statRef = type(row and row.ref) == "string" and row.ref or ""
        if statRef ~= "" then
            local value = tonumber(row.value) or 0
            nextStats[#nextStats + 1] = {
                statRef = statRef,
                value = value,
                currentValue = value,
            }
        end
    end

    local existingResourcesByRef = {}
    for index = 1, #(localUnit.resources or {}) do
        local entry = localUnit.resources[index]
        local resourceRef = type(entry and entry.resourceRef) == "string" and entry.resourceRef or ""
        if resourceRef ~= "" then
            existingResourcesByRef[resourceRef] = entry
        end
    end

    local resolvedResources = type(Profile.ListResolvedResources) == "function" and Profile.ListResolvedResources({
        includeAuraBonuses = true,
    }) or {}
    local nextResources = {}
    for index = 1, #resolvedResources do
        local row = resolvedResources[index]
        local resourceRef = type(row and row.ref) == "string" and row.ref or ""
        if resourceRef ~= "" then
            local maxValue = math.max(0, tonumber(row.value) or 0)
            local existing = existingResourcesByRef[resourceRef]
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
            currentValue = math.max(0, math.min(currentValue, maxValue))
            nextResources[#nextResources + 1] = {
                resourceRef = resourceRef,
                currentValue = currentValue,
                maxValue = maxValue,
            }
        end
    end

    localUnit.stats = nextStats
    localUnit.resources = nextResources
    return true
end

local function rebuildLocalPlayerResolvedStateSubset(eventState, localUnit, impact)
    if type(eventState) ~= "table" or eventState.active ~= true or type(localUnit) ~= "table" or type(impact) ~= "table" then
        return false
    end

    local changed = false
    local statRefs = setToOrderedList(impact.statRefs)
    if #statRefs > 0 and type(Profile.GetResolvedStatRowsByRefs) == "function" then
        local statRows = Profile.GetResolvedStatRowsByRefs(statRefs, {
            includeAuraBonuses = true,
        }) or {}
        changed = updateLocalUnitStatsSubset(localUnit, statRows) or changed
    end

    local resourceRefs = setToOrderedList(impact.resourceRefs)
    if #resourceRefs > 0 and type(Profile.GetResolvedResourceRowsByRefs) == "function" then
        local resourceRows = Profile.GetResolvedResourceRowsByRefs(resourceRefs, {
            includeAuraBonuses = true,
        }) or {}
        changed = updateLocalUnitResourcesSubset(localUnit, resourceRows) or changed
    end

    return changed
end

local function refreshLocalPlayerAuraDerivedState(eventState, targetEventId, impact)
    local numericTargetEventId = tonumber(targetEventId) or 0
    if numericTargetEventId <= 0 then
        return false
    end

    local localUnit = resolveLocalEventUnit(eventState)
    if tonumber(localUnit and localUnit.eventID) ~= numericTargetEventId then
        return false
    end

    local refreshed = type(impact) == "table"
        and rebuildLocalPlayerResolvedStateSubset(eventState, localUnit, impact)
        or rebuildLocalPlayerResolvedState(eventState, localUnit)
    if refreshed then
        refreshProfileWindowIfVisible()
    end
    return refreshed
end

local function queueLocalPlayerAuraDerivedStateRefresh(eventState, targetEventId, impact)
    local numericTargetEventId = tonumber(targetEventId) or 0
    local eventId = tostring(eventState and eventState.id or "")
    if numericTargetEventId <= 0 or eventId == "" then
        return false
    end

    Client.PendingAuraDerivedStateRefreshEventId = eventId
    Client.PendingAuraDerivedStateRefreshTargetEventId = numericTargetEventId
    if type(impact) == "table" then
        Client.PendingAuraDerivedStateRefreshImpact = Client.PendingAuraDerivedStateRefreshImpact or {
            statRefs = {},
            resourceRefs = {},
        }
        mergeDerivedStateImpact(Client.PendingAuraDerivedStateRefreshImpact, impact)
    else
        Client.PendingAuraDerivedStateRefreshImpact = nil
    end
    if Client.PendingAuraDerivedStateRefreshQueued == true then
        return true
    end

    Client.PendingAuraDerivedStateRefreshQueued = true
    local enqueued = enqueueAuraWork(function(targetClient)
        targetClient.PendingAuraDerivedStateRefreshQueued = false
        local refreshEventId = targetClient.PendingAuraDerivedStateRefreshEventId
        local refreshTargetEventId = targetClient.PendingAuraDerivedStateRefreshTargetEventId
        local refreshImpact = targetClient.PendingAuraDerivedStateRefreshImpact
        targetClient.PendingAuraDerivedStateRefreshEventId = nil
        targetClient.PendingAuraDerivedStateRefreshTargetEventId = nil
        targetClient.PendingAuraDerivedStateRefreshImpact = nil

        local currentEventState = targetClient.GetEventState and targetClient:GetEventState() or nil
        if type(currentEventState) == "table" and tostring(currentEventState.id or "") == tostring(refreshEventId or "") then
            refreshLocalPlayerAuraDerivedState(currentEventState, refreshTargetEventId, refreshImpact)
        end
    end, Client)
    if not enqueued then
        Client.PendingAuraDerivedStateRefreshQueued = false
        Client.PendingAuraDerivedStateRefreshEventId = nil
        Client.PendingAuraDerivedStateRefreshTargetEventId = nil
        Client.PendingAuraDerivedStateRefreshImpact = nil
        return false
    end

    return true
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
    local amount = tonumber(effect and effect[baseField] or 0) or 0
    amount = amount + (tonumber(auraEntry and auraEntry.powerLevel) or 0)

    for index = 1, #(effect and effect.statScaling or {}) do
        local scaling = effect.statScaling[index]
        local statRef = type(scaling) == "table" and normalizeRef(scaling.statRef) or nil
        if statRef then
            local statValue = type(Lookup.GetStatValue) == "function" and Lookup.GetStatValue(casterUnit, statRef, 0) or 0
            amount = amount + (statValue * (tonumber(scaling.coefficient) or 0))
        end
    end

    amount = amount * math.max(1, math.floor(tonumber(auraEntry and auraEntry.stacks) or 1))
    return amount
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
end

function AuraManager:ResetAuraState(client, eventId)
    local normalizedEventId = type(eventId) == "string" and eventId or nil
    if normalizedEventId ~= nil then
        client.PendingOutboundAuraOperations = client.PendingOutboundAuraOperations or {}
        client.PendingOutboundAuraOperationOrder = client.PendingOutboundAuraOperationOrder or {}

        local filteredOperations = {}
        local filteredOrder = {}
        for index = 1, #(client.PendingOutboundAuraOperationOrder or {}) do
            local operationKey = client.PendingOutboundAuraOperationOrder[index]
            local operation = client.PendingOutboundAuraOperations[operationKey]
            if type(operation) == "table" and tostring(operation.eventId or "") ~= normalizedEventId then
                filteredOperations[operationKey] = operation
                filteredOrder[#filteredOrder + 1] = operationKey
            end
        end
        client.PendingOutboundAuraOperations = filteredOperations
        client.PendingOutboundAuraOperationOrder = filteredOrder
    end

    if type(eventId) == "string" and eventId ~= "" then
        self:ClearEventAuraBucket(client, eventId)
        return true
    end

    client.ActiveAurasByEventId = {}
    client.PendingLocalAuraApplyEchoSignatures = nil
    client.PendingLocalAuraApplyBatchEchoSignatures = nil
    client.PendingLocalAuraDispelEchoSignatures = nil
    client.PendingLocalAuraDispelBatchEchoSignatures = nil
    client.PendingOutboundAuraFlushQueued = false
    client.PendingOutboundAuraFlushQueuedByScope = {}
    client.PendingOutboundAuraOperations = {}
    client.PendingOutboundAuraOperationOrder = {}
    client.PendingAuraDisplayRefreshQueued = false
    client.PendingAuraDisplayRefreshReason = nil
    client.PendingAuraDerivedStateRefreshQueued = false
    client.PendingAuraDerivedStateRefreshEventId = nil
    client.PendingAuraDerivedStateRefreshTargetEventId = nil
    return true
end

function AuraManager:UpsertAura(client, payload)
    local eventState = payload and payload.eventState or nil
    local eventId = type(eventState) == "table" and eventState.id or nil
    local bucket = self:GetEventAuraBucket(client, eventId, true)
    if not bucket then
        return false, nil
    end

    local dataset, auraDefinition, qualifiedAuraRef = self:ResolveAuraDefinition(payload.auraRef, payload)
    if not dataset or not auraDefinition then
        return false, nil
    end

    local auraKey = buildAuraKey(qualifiedAuraRef, payload.casterEventId, payload.targetEventId)
    local turnsRemaining = normalizeTurnCount(payload.turns) or normalizeTurnCount(auraDefinition.duration)
    if turnsRemaining == nil then
        return false, nil
    end

    local maxStacks = math.max(1, math.floor(tonumber(auraDefinition.maxStacks) or 1))
    local stacksToApply = math.max(1, math.floor(tonumber(payload.stacks) or 1))
    local stackBehavior = normalizeStackBehavior(auraDefinition.stackBehavior)
    local currentTurnNumber = math.max(1, math.floor(tonumber(eventState and eventState.turnNumber) or 1))
    local currentTickNumber = math.max(1, math.floor(tonumber(eventState and eventState.tickNumber) or 1))
    local currentStepNumber = resolveEventProgressStep(currentTurnNumber, currentTickNumber, eventState and eventState.totalTicks)
    local powerLevel = tonumber(payload.powerLevel) or 0
    local replaceState = type(payload) == "table" and payload.fullState == true
    local entry = bucket.byKey[auraKey]

    if entry then
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

        entry.lastAdvancedTurnNumber = currentTurnNumber
        entry.lastAdvancedStep = currentStepNumber
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
        lastAdvancedTurnNumber = currentTurnNumber,
        lastAdvancedStep = currentStepNumber,
        definition = auraDefinition,
    }

    if stackBehavior == "independent_duration" then
        entry.stackTurns = {}
        for stackIndex = 1, entry.stacks do
            entry.stackTurns[#entry.stackTurns + 1] = turnsRemaining
        end
    end

    bucket.byKey[auraKey] = entry
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

    bucket.byKey[auraKey] = nil
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
            bucket.byKey[auraKey] = nil
        end
    end

    if #removedEntries == 0 then
        return false, {}
    end

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

function AuraManager:FlushOutboundAuraOperations(client, scopeOverride)
    if type(client) ~= "table" then
        return false
    end

    local scope = normalizePendingScope(scopeOverride)
    client.PendingOutboundAuraFlushQueued = false
    client.PendingOutboundAuraFlushQueuedByScope = client.PendingOutboundAuraFlushQueuedByScope or {}
    client.PendingOutboundAuraFlushQueuedByScope[scope] = false
    local eventId = nil

    local pendingOperations = client.PendingOutboundAuraOperations or {}
    local pendingOrder = client.PendingOutboundAuraOperationOrder or {}
    if type(client.QueueActionBarRefresh) == "function" then
        client:QueueActionBarRefresh("pending-aura-flush")
    elseif type(client.RefreshActionBarWidget) == "function" then
        client:RefreshActionBarWidget("pending-aura-flush")
    end
    if type(client.QueuePendingTurnChangesTooltipRefresh) == "function" then
        client:QueuePendingTurnChangesTooltipRefresh()
    elseif type(client.RefreshPendingTurnChangesTooltip) == "function" then
        client:RefreshPendingTurnChangesTooltip()
    end

    local function flushOperationBatch(batch)
        if type(batch) ~= "table" or #((batch.entries) or {}) == 0 then
            return false
        end

        eventId = batch.eventId or eventId

        local context = {
            sessionState = batch.sessionState,
            eventState = batch.eventState,
        }
        if batch.kind == "apply" then
            return self:SendAuraApplyBatch(client, context, batch.entries)
        elseif batch.kind == "dispel" then
            return self:SendAuraDispelBatch(client, context, batch.entries)
        end

        return false
    end

    local currentBatch = nil
    local flushed = false
    for index = 1, #pendingOrder do
        local operationKey = pendingOrder[index]
        local operation = pendingOperations[operationKey]
        if type(operation) == "table" and normalizePendingScope(operation.scope) == scope then
            pendingOperations[operationKey] = nil
            local canMerge = currentBatch
                and currentBatch.kind == operation.kind
                and currentBatch.sessionState == operation.sessionState
                and currentBatch.eventState == operation.eventState
                and tostring(currentBatch.eventId or "") == tostring(operation.eventId or "")
                and tostring(currentBatch.channelName or "") == tostring(operation.sessionState and operation.sessionState.channelName or "")
            if not canMerge then
                flushed = flushOperationBatch(currentBatch) or flushed
                currentBatch = {
                    kind = operation.kind,
                    sessionState = operation.sessionState,
                    eventState = operation.eventState,
                    eventId = operation.eventId,
                    channelName = operation.sessionState and operation.sessionState.channelName or nil,
                    entries = {},
                }
            end

            if operation.kind == "apply" then
                currentBatch.entries[#currentBatch.entries + 1] = {
                    casterEventId = operation.casterEventId,
                    targetEventId = operation.targetEventId,
                    auraRef = operation.auraRef,
                    stacks = operation.stacks,
                    turns = operation.turnsRemaining,
                    powerLevel = operation.powerLevel,
                    fullState = operation.fullState == true,
                }
            elseif operation.kind == "dispel" then
                currentBatch.entries[#currentBatch.entries + 1] = {
                    casterEventId = operation.casterEventId,
                    targetEventId = operation.targetEventId,
                    auraRef = operation.auraRef,
                }
            end
        end
    end

    flushed = flushOperationBatch(currentBatch) or flushed

    return flushed
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
    client.PendingOutboundAuraOperationOrder = client.PendingOutboundAuraOperationOrder or {}
    if not client.PendingOutboundAuraOperations[operationKey] then
        client.PendingOutboundAuraOperationOrder[#client.PendingOutboundAuraOperationOrder + 1] = operationKey
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

    client.PendingOutboundAuraFlushQueuedByScope = client.PendingOutboundAuraFlushQueuedByScope or {}
    if client.PendingOutboundAuraFlushQueuedByScope[scope] == true then
        return true
    end

    client.PendingOutboundAuraFlushQueued = true
    client.PendingOutboundAuraFlushQueuedByScope[scope] = true
    local enqueued = enqueueAuraWork(function(targetClient)
        AuraManager:FlushOutboundAuraOperations(targetClient, scope)
    end, client)
    if not enqueued then
        client.PendingOutboundAuraFlushQueued = false
        client.PendingOutboundAuraFlushQueuedByScope[scope] = false
        return false
    end

    return true
end

function AuraManager:QueueAuraDispel(client, context, auraRef, casterEventId, targetEventId)
    local sessionState = type(context) == "table" and context.sessionState or nil
    local eventState = type(context) == "table" and context.eventState or nil
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return false
    end
    local scope = normalizePendingScope(type(context) == "table" and (context.pendingScope or context.scope) or nil)

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
    client.PendingOutboundAuraOperationOrder = client.PendingOutboundAuraOperationOrder or {}

    local pendingApplyKey = buildAuraOperationKey(
        "apply",
        sessionState.channelName,
        eventState.id,
        casterEventId,
        targetEventId,
        auraRef,
        scope
    )
    client.PendingOutboundAuraOperations[pendingApplyKey] = nil

    if not client.PendingOutboundAuraOperations[operationKey] then
        client.PendingOutboundAuraOperationOrder[#client.PendingOutboundAuraOperationOrder + 1] = operationKey
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

    client.PendingOutboundAuraFlushQueuedByScope = client.PendingOutboundAuraFlushQueuedByScope or {}
    if client.PendingOutboundAuraFlushQueuedByScope[scope] == true then
        return true
    end

    client.PendingOutboundAuraFlushQueued = true
    client.PendingOutboundAuraFlushQueuedByScope[scope] = true
    local enqueued = enqueueAuraWork(function(targetClient)
        AuraManager:FlushOutboundAuraOperations(targetClient, scope)
    end, client)
    if not enqueued then
        client.PendingOutboundAuraFlushQueued = false
        client.PendingOutboundAuraFlushQueuedByScope[scope] = false
        return false
    end

    return true
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
    queueLocalPlayerAuraDerivedStateRefresh(eventState, entry.targetEventId, derivedStateImpact)
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
    queueLocalPlayerAuraDerivedStateRefresh(eventState, targetEventId, derivedStateImpact)
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
    for _, entry in pairs(bucket and bucket.byKey or {}) do
        if type(entry) == "table"
            and tonumber(entry.targetEventId) == recipientEventId
            and (tonumber(entry.stacks) or 0) > 0
        then
            local auraDefinition = entry.definition
            local _, resolvedAuraDefinition = self:ResolveAuraDefinition(entry.auraRef, { datasetId = entry.datasetId })
            if type(resolvedAuraDefinition) == "table" then
                entry.definition = resolvedAuraDefinition
                auraDefinition = resolvedAuraDefinition
            end
            local auraCasterUnit = findEventUnit(eventState, entry.casterEventId)
            local auraTargetUnit = findEventUnit(eventState, entry.targetEventId)
            if type(auraDefinition) == "table"
                and type(auraCasterUnit) == "table"
                and type(auraTargetUnit) == "table"
                and shouldExecuteLocalAuraTick(client, eventState, auraTargetUnit)
            then
                local auraEventKeys = sortedNumericKeys(auraDefinition.events)
                for auraEventKeyIndex = 1, #auraEventKeys do
                    local auraEventIndex = auraEventKeys[auraEventKeyIndex].key
                    local auraEvent = auraDefinition.events[auraEventIndex]
                    if self:GetCombatEventId(auraEvent) == combatEventId then
                        local targetUnit = resolveTriggeredAuraTarget(
                            auraEvent,
                            auraCasterUnit,
                            auraTargetUnit,
                            eventSourceUnit,
                            eventOtherUnit
                        )
                        if type(targetUnit) == "table" then
                            local effectKeys = sortedNumericKeys(auraEvent.effects)
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
                                        casterUnit = auraCasterUnit,
                                        targetUnit = targetUnit,
                                        eventSourceUnit = eventSourceUnit,
                                        eventOtherUnit = eventOtherUnit,
                                    }, result, combatEventId)
                                elseif type(Debug.Internal) == "function" then
                                    Debug.Internal(
                                        "Aura trigger effect skipped: aura=%s event=%s effectIndex=%s effectType=%s contract=%s.",
                                        tostring(entry and entry.auraRef or "unknown"),
                                        tostring(combatEventId or "unknown"),
                                        tostring(effectIndex or "unknown"),
                                        tostring(effect and effect.type or "nil"),
                                        tostring(contract ~= nil)
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if type(client) == "table" and type(client.HandleTraitCombatEvent) == "function" then
        changed = client:HandleTraitCombatEvent(context) or changed
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

function AuraManager:AdvanceAuraEntry(client, eventId, auraKey, targetTurnNumber, targetTickNumber, targetStepNumber)
    local eventState = client.GetEventState and client:GetEventState() or nil
    if type(eventState) ~= "table" or eventState.active ~= true or tostring(eventState.id or "") ~= tostring(eventId or "") then
        return false
    end

    local bucket = self:GetEventAuraBucket(client, eventId, false)
    local entry = bucket and bucket.byKey and bucket.byKey[auraKey] or nil
    if type(entry) ~= "table" then
        return false
    end

    local currentTurnNumber = math.max(1, math.floor(tonumber(targetTurnNumber) or tonumber(eventState.turnNumber) or 1))
    local currentTickNumber = math.max(1, math.floor(tonumber(targetTickNumber) or tonumber(eventState.tickNumber) or 1))
    local currentStepNumber = math.max(1, math.floor(tonumber(targetStepNumber) or resolveEventProgressStep(currentTurnNumber, currentTickNumber, eventState.totalTicks)))
    local lastAdvancedStep = math.max(
        1,
        math.floor(
            tonumber(entry.lastAdvancedStep)
            or resolveEventProgressStep(entry.lastAdvancedTurnNumber, currentTickNumber, eventState.totalTicks)
        )
    )
    if currentStepNumber <= lastAdvancedStep then
        if math.floor(tonumber(entry.pendingAdvancedStep) or 0) <= currentStepNumber then
            entry.pendingAdvancedStep = nil
        end
        return false
    end

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
    else
        local turnOwnerEventId = resolveAuraTurnOwnerEventId(eventState, casterUnit, entry.casterEventId)
        local turnOwnerTick = turnOwnerEventId ~= nil
            and Spellcasting.GetUnitPageIndex
            and Spellcasting.GetUnitPageIndex(eventState, turnOwnerEventId)
            or nil
        local shouldExecuteTick = turnOwnerTick ~= nil and shouldExecuteLocalAuraTick(client, eventState, casterUnit)
        local totalTicks = math.max(1, math.floor(tonumber(eventState.totalTicks) or 1))

        if turnOwnerTick ~= nil then
            for step = lastAdvancedStep + 1, currentStepNumber do
                local stepTick = ((step - 1) % totalTicks) + 1
                if stepTick == turnOwnerTick then
                    if shouldExecuteTick then
                        self:TickAura(client, eventState, entry, casterUnit, targetUnit)
                    end
                    if self:AdvanceAuraDurations(entry) then
                        if localPlayerEventId > 0 and tonumber(entry.targetEventId) == localPlayerEventId then
                            localPlayerDerivedStateImpact = buildAuraDerivedStateImpact(entry)
                        end
                        self:RemoveAura(client, eventState, entry.auraRef, entry.casterEventId, entry.targetEventId)
                        changed = true
                        break
                    end
                    changed = true
                end
            end
        end

        entry.lastAdvancedTurnNumber = currentTurnNumber
        entry.lastAdvancedStep = currentStepNumber
    end

    if math.floor(tonumber(entry.pendingAdvancedStep) or 0) <= currentStepNumber then
        entry.pendingAdvancedStep = nil
    end

    if changed then
        if localPlayerDerivedStateImpact and localPlayerEventId > 0 then
            queueLocalPlayerAuraDerivedStateRefresh(eventState, localPlayerEventId, localPlayerDerivedStateImpact)
        end
        refreshAuraDisplays("aura-advance", eventState, localPlayerEventId, localPlayerDerivedStateImpact)
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

    local currentTurnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1))
    local currentTickNumber = math.max(1, math.floor(tonumber(eventState.tickNumber) or 1))
    local currentStepNumber = resolveEventProgressStep(currentTurnNumber, currentTickNumber, eventState.totalTicks)
    local previousTurn = math.max(0, math.floor(tonumber(previousTurnNumber) or 0))
    local previousTick = math.max(0, math.floor(tonumber(previousTickNumber) or 0))
    if previousTurn == currentTurnNumber and previousTick == currentTickNumber then
        return false
    end

    local bucket = self:GetEventAuraBucket(client, eventId, false)
    if not bucket then
        return false
    end

    local queued = false

    for auraKey, entry in pairs(bucket.byKey or {}) do
        if type(entry) == "table" then
            local lastAdvancedStep = math.max(
                1,
                math.floor(
                    tonumber(entry.lastAdvancedStep)
                    or resolveEventProgressStep(entry.lastAdvancedTurnNumber, currentTickNumber, eventState.totalTicks)
                )
            )
            if currentStepNumber > lastAdvancedStep then
                local pendingAdvancedStep = math.floor(tonumber(entry.pendingAdvancedStep) or 0)
                if pendingAdvancedStep < currentStepNumber then
                    entry.pendingAdvancedStep = currentStepNumber
                    local enqueued = enqueueAuraWork(function(manager, targetClient, targetEventId, targetAuraKey, turnNumber, tickNumber, stepNumber)
                        manager:AdvanceAuraEntry(targetClient, targetEventId, targetAuraKey, turnNumber, tickNumber, stepNumber)
                    end, self, client, eventId, auraKey, currentTurnNumber, currentTickNumber, currentStepNumber)
                    if enqueued then
                        queued = true
                    else
                        entry.pendingAdvancedStep = pendingAdvancedStep > 0 and pendingAdvancedStep or nil
                    end
                end
            end
        end
    end

    return queued
end

function AuraManager:BuildStatModifierTotals(eventState, unitEventId, statRef)
    local bucket = self:GetEventAuraBucket(Client, eventState and eventState.id or nil, false)
    if not bucket then
        return 0, 0
    end

    local flatTotal = 0
    local percentTotal = 0
    local normalizedStatRef = normalizeRef(statRef)
    if not normalizedStatRef then
        return 0, 0
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
                            targetUnit = findEventUnit(eventState, entry.targetEventId),
                            statRef = normalizedStatRef,
                        }, effect, accumulator)
                        flatTotal = accumulator.flat
                        percentTotal = accumulator.percent
                    end
                end
            end
        end
    end

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

    for _, entry in pairs(bucket.byKey or {}) do
        if type(entry) == "table" and tonumber(entry.targetEventId) == (tonumber(unitEventId) or 0) and (tonumber(entry.stacks) or 0) > 0 then
            local auraDefinition = entry.definition
            local _, resolvedAuraDefinition = self:ResolveAuraDefinition(entry.auraRef, { datasetId = entry.datasetId })
            if type(resolvedAuraDefinition) == "table" then
                entry.definition = resolvedAuraDefinition
                auraDefinition = resolvedAuraDefinition
            end

            local effectKeys = sortedNumericKeys(auraDefinition and auraDefinition.effects)
            for effectKeyIndex = 1, #effectKeys do
                local effect = auraDefinition.effects[effectKeys[effectKeyIndex].key]
                if type(effect) == "table" and tostring(effect.type or "") == "control" then
                    state.cancelOnDamage = state.cancelOnDamage or effect.cancelOnDamage == true
                    state.preventCasting = state.preventCasting or effect.preventCasting == true
                    state.forceAutoHitAgainstTarget = state.forceAutoHitAgainstTarget or effect.forceAutoHitAgainstTarget == true
                    if effect.movementRangeOverride ~= nil then
                        local overrideValue = tonumber(effect.movementRangeOverride)
                        if overrideValue ~= nil then
                            state.movementRangeOverride = state.movementRangeOverride ~= nil
                                and math.min(state.movementRangeOverride, overrideValue)
                                or overrideValue
                        end
                    end
                end
            end
        end
    end

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
    for _, entry in pairs(bucket.byKey or {}) do
        if type(entry) == "table" and tonumber(entry.targetEventId) == (tonumber(targetEventId) or 0) then
            local auraDefinition = entry.definition
            local _, resolvedAuraDefinition = self:ResolveAuraDefinition(entry.auraRef, { datasetId = entry.datasetId })
            if type(resolvedAuraDefinition) == "table" then
                auraDefinition = resolvedAuraDefinition
            end

            local shouldRemove = false
            local effectKeys = sortedNumericKeys(auraDefinition and auraDefinition.effects)
            for effectKeyIndex = 1, #effectKeys do
                local effect = auraDefinition.effects[effectKeys[effectKeyIndex].key]
                if type(effect) == "table" and tostring(effect.type or "") == "control" and effect.cancelOnDamage == true then
                    shouldRemove = true
                    break
                end
            end

            if shouldRemove then
                removedAny = self:DispelAuraFromContext(client, sourceContext or { eventState = eventState }, entry.auraRef, entry.casterEventId, entry.targetEventId, entry) or removedAny
            end
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

function AuraManager:RefreshLocalPlayerDerivedState(eventState)
    local localPlayerEventId = resolveLocalEventId(eventState)
    if localPlayerEventId <= 0 then
        return false
    end

    return refreshLocalPlayerAuraDerivedState(eventState, localPlayerEventId)
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
Client.PendingOutboundAuraOperations = Client.PendingOutboundAuraOperations or {}
Client.PendingOutboundAuraOperationOrder = Client.PendingOutboundAuraOperationOrder or {}
Client.PendingLocalAuraApplyBatchEchoSignatures = Client.PendingLocalAuraApplyBatchEchoSignatures or {}
Client.PendingLocalAuraDispelBatchEchoSignatures = Client.PendingLocalAuraDispelBatchEchoSignatures or {}
Client.PendingAuraDisplayRefreshQueued = Client.PendingAuraDisplayRefreshQueued or false
Client.PendingAuraDisplayRefreshReason = Client.PendingAuraDisplayRefreshReason or nil
Client.PendingAuraDerivedStateRefreshQueued = Client.PendingAuraDerivedStateRefreshQueued or false
Client.PendingAuraDerivedStateRefreshEventId = Client.PendingAuraDerivedStateRefreshEventId or nil
Client.PendingAuraDerivedStateRefreshTargetEventId = Client.PendingAuraDerivedStateRefreshTargetEventId or nil
Client.PendingAuraDerivedStateRefreshImpact = Client.PendingAuraDerivedStateRefreshImpact or nil
