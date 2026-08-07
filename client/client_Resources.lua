local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Debug = Addon.Debug
local Common = Addon.Utils.Common or {}
local Comms = Addon.Internal.Comms or {}
local Profile = Addon.Internal.Profile or {}
local Operations = Comms.Operations or {}
local ResourceSync = Comms.ResourceSync or {}

local RESOURCE_OPCODE = Operations:GetOpcode("RESOURCE")
local RESOURCE_DELTA_OPCODE = Operations:GetOpcode("RESOURCE_DELTA")
local RESOURCE_DELTA_BATCH_OPCODE = Operations:GetOpcode("RESOURCE_DELTA_BATCH")
local NativeJoinChannel = Comms and Comms.JoinChannel or nil
local NativeResolveChannelId = Comms and Comms.ResolveChannelId or nil
local THREAT_UPDATE_RECORD_SEPARATOR = string.char(30)
local THREAT_UPDATE_FIELD_SEPARATOR = string.char(31)

Client.ResourceSyncQueued = Client.ResourceSyncQueued or false
Client.LastResourceSyncSignature = Client.LastResourceSyncSignature or nil
Client.PendingResourceDeltaFlushQueued = Client.PendingResourceDeltaFlushQueued or false
Client.PendingResourceDeltaFlushQueuedByScope = Client.PendingResourceDeltaFlushQueuedByScope or {}
Client.PendingResourceDeltaBatches = Client.PendingResourceDeltaBatches or {}
Client.LastAppliedTurnRegenKey = Client.LastAppliedTurnRegenKey or nil

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function getCombat()
    return Client.Combat or nil
end

local function isResourceTracingEnabled()
    return Debug and Debug.ResourceTracing == true
end

local function enqueueResourceSync(fn, ...)
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        tasks:Enqueue(fn, ...)
        return true
    end

    if Debug and Debug.Error then
        Debug.Error("Resource sync queue unavailable: Addon.Internal.Tasks is missing.")
    end

    return false
end

local function bumpEventTooltipContextRevision(eventState, casterEventId)
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(builder) == "table" and type(builder.BumpEventTooltipContextRevision) == "function" then
        builder.BumpEventTooltipContextRevision(eventState and eventState.id or nil, casterEventId)
    end
end

local function refreshTargetingForEventState(targetClient, reason)
    if type(targetClient) ~= "table" then
        return
    end

    if type(targetClient.InvalidatePendingSpellTargetingDisplayState) == "function" then
        targetClient:InvalidatePendingSpellTargetingDisplayState()
    end
    if targetClient.PendingSpellTargeting ~= nil
        and type(targetClient.IsTargetingWidgetVisible) == "function"
        and targetClient:IsTargetingWidgetVisible()
        and type(targetClient.QueueTargetingWidgetRefresh) == "function"
    then
        targetClient:QueueTargetingWidgetRefresh(reason)
    end
end

local function queueScopedEventPortraitRefresh(targetClient, reason, targetEventId)
    local numericTargetEventId = tonumber(targetEventId) or 0
    if numericTargetEventId <= 0 or type(targetClient) ~= "table" then
        return false
    end

    if type(targetClient.QueueEventWidgetTargetedRefresh) == "function" then
        return targetClient:QueueEventWidgetTargetedRefresh(reason, { numericTargetEventId }) or false
    end
    if type(targetClient.QueueEventWidgetRefresh) == "function" then
        return targetClient:QueueEventWidgetRefresh(reason) or false
    end

    return false
end

local function shouldRefreshCompanionBarsForTarget(targetClient, eventState, targetUnit, targetEventId)
    if type(targetClient) ~= "table" then
        return false
    end

    local numericTargetEventId = tonumber(targetEventId) or tonumber(targetUnit and targetUnit.eventID) or 0
    if numericTargetEventId <= 0 then
        return true
    end

    local localUnit = type(targetClient.ResolveLocalEventUnit) == "function" and targetClient:ResolveLocalEventUnit(eventState) or nil
    if tonumber(localUnit and localUnit.eventID) == numericTargetEventId then
        return true
    end

    local controlledUnit = type(targetClient.ResolveControlledEventUnit) == "function" and targetClient:ResolveControlledEventUnit(eventState) or nil
    if tonumber(controlledUnit and controlledUnit.eventID) == numericTargetEventId then
        return true
    end

    return false
end

local function bindStateSessionRuntime(state)
    if type(state) ~= "table" then
        return state
    end

    state._sendToChannel = state._sendToChannel or (Comms and Comms.SendToChannel or nil)
    state._resolveChannelId = state._resolveChannelId or (Comms and Comms.ResolveChannelId or nil)
    state._leaveChannel = state._leaveChannel or (Comms and Comms.LeaveChannel or nil)
    state._getPlayerName = state._getPlayerName or Common.GetPlayerName
    return state
end

local function normalizeThreatUpdates(threatUpdates)
    local normalized = {}
    for index = 1, #(threatUpdates or {}) do
        local entry = threatUpdates[index]
        local targetEventId = math.floor(tonumber(entry and entry.targetEventId) or 0)
        local sourceEventId = math.floor(tonumber(entry and entry.sourceEventId) or 0)
        local amount = math.max(0, tonumber(entry and entry.amount) or 0)
        if targetEventId > 0 and sourceEventId > 0 and amount > 0 then
            normalized[#normalized + 1] = {
                targetEventId = targetEventId,
                sourceEventId = sourceEventId,
                amount = amount,
            }
        end
    end

    return normalized
end

local function coalesceThreatUpdates(threatUpdates, additionalThreatUpdates)
    local totals = {}
    local order = {}
    local function merge(list)
        local normalized = normalizeThreatUpdates(list)
        for index = 1, #normalized do
            local entry = normalized[index]
            local key = tostring(entry.targetEventId) .. "\31" .. tostring(entry.sourceEventId)
            if not totals[key] then
                totals[key] = {
                    targetEventId = entry.targetEventId,
                    sourceEventId = entry.sourceEventId,
                    amount = 0,
                }
                order[#order + 1] = key
            end
            totals[key].amount = totals[key].amount + entry.amount
        end
    end

    merge(threatUpdates)
    merge(additionalThreatUpdates)

    local merged = {}
    for index = 1, #order do
        local entry = totals[order[index]]
        if entry and entry.amount > 0 then
            merged[#merged + 1] = entry
        end
    end

    return merged
end

local function serializeThreatUpdates(threatUpdates)
    local records = {}
    local normalized = normalizeThreatUpdates(threatUpdates)
    for index = 1, #normalized do
        local entry = normalized[index]
        records[#records + 1] = table.concat({
            tostring(entry.targetEventId),
            tostring(entry.sourceEventId),
            tostring(entry.amount),
        }, THREAT_UPDATE_FIELD_SEPARATOR)
    end
    return table.concat(records, THREAT_UPDATE_RECORD_SEPARATOR)
end

local function getPlayerNameForState(state)
    bindStateSessionRuntime(state)
    local getter = state and state._getPlayerName or nil
    if type(getter) == "function" then
        return getter()
    end

    return Common.GetPlayerName and Common.GetPlayerName() or nil
end

local function sendToChannelForState(state, channelId, opcode, arguments, metadata)
    bindStateSessionRuntime(state)
    local sender = state and state._sendToChannel or nil
    if type(sender) ~= "function" then
        return false
    end

    return sender(Comms, channelId, opcode, arguments, metadata)
end

local function hasLiveChannelJoinApi()
    return type(JoinChannelByName) == "function"
        and Comms ~= nil
        and Comms.JoinChannel == NativeJoinChannel
end

local function resolveChannelId(state)
    if not state then
        return nil
    end

    bindStateSessionRuntime(state)
    local cachedChannelId = state.channelId
    local hasChannelApis = type(GetChannelName) == "function" or type(GetChannelList) == "function"
    if not hasChannelApis then
        return cachedChannelId
    end

    local resolver = state._resolveChannelId or (Comms and Comms.ResolveChannelId) or nil
    if type(resolver) ~= "function" then
        return cachedChannelId
    end

    local useResolvedLookup = hasLiveChannelJoinApi() or resolver ~= NativeResolveChannelId
    if not useResolvedLookup then
        return cachedChannelId
    end

    local resolvedChannelId = resolver(Comms, state.channelName)
    if resolvedChannelId ~= nil and resolvedChannelId ~= "" then
        state.channelId = resolvedChannelId
        return resolvedChannelId
    end

    if cachedChannelId ~= nil and cachedChannelId ~= "" then
        return cachedChannelId
    end

    if hasLiveChannelJoinApi() then
        state.channelId = nil
    end

    return nil
end

local function addMember(state, memberName, joinedAt)
    state.membersByName = state.membersByName or {}
    state.memberOrder = state.memberOrder or {}

    if state.membersByName[memberName] then
        return false
    end

    state.memberOrder[#state.memberOrder + 1] = memberName
    state.membersByName[memberName] = {
        name = memberName,
        joinedAt = joinedAt or Common.GetNow(),
    }
    return true
end

local function findEventUnitById(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if unit and tonumber(unit.eventID) == numericEventId then
            return unit
        end
    end

    return nil
end

local function normalizeUnitOwnerName(unit)
    return Common.NormalizeName and Common.NormalizeName(unit and (unit.ownerID or unit.controllerID or unit.name) or nil)
        or (unit and (unit.ownerID or unit.controllerID or unit.name) or nil)
end

local function hasResourceEntries(resources)
    return type(resources) == "table" and #resources > 0
end

local function resolveLocalPlayerName()
    local playerName = Common.GetPlayerName and Common.GetPlayerName() or nil
    if Common.NormalizeName then
        return Common.NormalizeName(playerName)
    end

    return type(playerName) == "string" and playerName or ""
end

local function buildResourceDeltaSignature(channelName, playerName, payload, targetEventId)
    return table.concat({
        tostring(channelName or ""),
        tostring(playerName or ""),
        tostring(targetEventId or 0),
        tostring(payload or ""),
    }, "\31")
end

local function buildResourceDeltaBatchSignature(channelName, playerName, payload)
    return table.concat({
        tostring(channelName or ""),
        tostring(playerName or ""),
        tostring(payload or ""),
    }, "\31")
end

local function normalizePendingScope(value)
    return tostring(value or "turn") == "reaction" and "reaction" or "turn"
end

local function buildResourceDeltaBatchKey(channelName, targetEventId, allowLocalEchoApply, scope)
    return table.concat({
        normalizePendingScope(scope),
        tostring(channelName or ""),
        tostring(targetEventId or 0),
        allowLocalEchoApply == true and "1" or "0",
    }, "\31")
end

local function mergeReasons(currentReason, nextReason)
    local currentText = tostring(currentReason or "")
    local nextText = tostring(nextReason or "")
    if currentText == "" then
        return nextText
    end
    if nextText == "" or nextText == currentText then
        return currentText
    end

    return ("%s,%s"):format(currentText, nextText)
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

local function buildTargetedResourceDeltaGroups(targetedResourceDeltas)
    local order = {}
    local deltasByTargetEventId = {}
    local normalized = ResourceSync.CoalesceTargetedResourceDeltas and ResourceSync.CoalesceTargetedResourceDeltas(targetedResourceDeltas) or {}
    for index = 1, #normalized do
        local entry = normalized[index]
        local targetEventId = tonumber(entry and entry.targetEventId) or 0
        if targetEventId > 0 then
            if not deltasByTargetEventId[targetEventId] then
                deltasByTargetEventId[targetEventId] = {}
                order[#order + 1] = targetEventId
            end

            local deltas = deltasByTargetEventId[targetEventId]
            deltas[#deltas + 1] = {
                resourceRef = entry.resourceRef,
                delta = entry.delta,
                maxValue = entry.maxValue,
                currentValue = entry.currentValue,
            }
        end
    end

    return order, deltasByTargetEventId
end

local function syncSuppressedLocalResourceDeltaCache(targetClient, state, playerName, targetEventId)
    if type(targetClient) ~= "table" or type(state) ~= "table" or playerName == "" then
        return false
    end

    local eventState = targetClient.GetEventState and targetClient:GetEventState() or nil
    local targetUnit = tonumber(targetEventId) and tonumber(targetEventId) > 0
        and findEventUnitById(eventState and eventState.units, targetEventId)
        or nil
    local targetOwnerName = Common.NormalizeName(targetUnit and (targetUnit.ownerID or targetUnit.controllerID or targetUnit.name) or nil)
    if not targetUnit or targetUnit.isPlayer ~= true or targetOwnerName == "" or targetOwnerName ~= playerName then
        return false
    end

    state.membersByName = state.membersByName or {}
    state.memberOrder = state.memberOrder or {}
    local member = state.membersByName[playerName]
    if not member then
        addMember(state, playerName)
        member = state.membersByName[playerName]
    end
    if member and ResourceSync.CloneResources then
        member.resources = ResourceSync.CloneResources(targetUnit.resources)
        return true
    end

    return false
end

local function resolveLocalActiveSpellcasterResources(targetClient, eventStateOverride, eventUnitOverride, options)
    if type(targetClient) ~= "table" then
        return nil, nil, nil
    end

    options = type(options) == "table" and options or {}
    local cloneResources = options.clone == true
    local applyFallbackToUnit = options.applyFallbackToUnit == true
    local state = targetClient.GetState and targetClient:GetState() or targetClient.State
    local eventState = eventStateOverride or (targetClient.GetEventState and targetClient:GetEventState() or nil)
    local activeEventUnit = eventUnitOverride
    if type(activeEventUnit) ~= "table" and type(targetClient.ResolveActiveSpellcasterUnit) == "function" then
        activeEventUnit = select(1, targetClient:ResolveActiveSpellcasterUnit(eventState))
    end
    if type(activeEventUnit) ~= "table" and type(targetClient.ResolveLocalEventUnit) == "function" then
        activeEventUnit = targetClient:ResolveLocalEventUnit(eventState)
    end

    if hasResourceEntries(activeEventUnit and activeEventUnit.resources) then
        local resources = activeEventUnit.resources
        if cloneResources and ResourceSync.CloneResources then
            resources = ResourceSync.CloneResources(resources)
        end
        return resources, activeEventUnit, "event"
    end

    local localPlayerName = resolveLocalPlayerName()
    local activeOwnerName = normalizeUnitOwnerName(activeEventUnit)
    if localPlayerName == ""
        or type(activeEventUnit) ~= "table"
        or activeEventUnit.isPlayer ~= true
        or activeOwnerName ~= localPlayerName
    then
        return nil, activeEventUnit, nil
    end

    local fallbackResources = nil
    local source = nil
    local member = type(state) == "table" and type(state.membersByName) == "table" and state.membersByName[localPlayerName] or nil
    if hasResourceEntries(member and member.resources) then
        fallbackResources = member.resources
        source = "member"
    else
        local profileResources = ResourceSync.BuildProfileResourceSnapshot and ResourceSync.BuildProfileResourceSnapshot() or nil
        if hasResourceEntries(profileResources) then
            fallbackResources = profileResources
            source = "profile"
        end
    end

    if not hasResourceEntries(fallbackResources) then
        return nil, activeEventUnit, nil
    end

    local resolvedResources = fallbackResources
    if ResourceSync.CloneResources then
        resolvedResources = ResourceSync.CloneResources(fallbackResources)
    end
    if applyFallbackToUnit == true and type(activeEventUnit) == "table" then
        activeEventUnit.resources = resolvedResources
        if cloneResources == true and ResourceSync.CloneResources then
            resolvedResources = ResourceSync.CloneResources(resolvedResources)
        end
    elseif cloneResources ~= true and ResourceSync.CloneResources then
        resolvedResources = ResourceSync.CloneResources(resolvedResources)
    end

    return resolvedResources, activeEventUnit, source
end

local function resolveAuthoritativeLocalPlayerResourceUnit(targetClient, state, playerName, targetEventId)
    if type(targetClient) ~= "table" or type(state) ~= "table" or playerName == "" then
        return nil, nil
    end

    local eventState = targetClient.GetEventState and targetClient:GetEventState() or nil
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.channelName ~= state.channelName
    then
        return nil, nil
    end

    local numericTargetEventId = tonumber(targetEventId) or 0
    if numericTargetEventId > 0 then
        local targetUnit = findEventUnitById(eventState.units, numericTargetEventId)
        local targetOwnerName = Common.NormalizeName(targetUnit and (targetUnit.ownerID or targetUnit.controllerID or targetUnit.name) or nil)
        if targetUnit and targetUnit.isPlayer == true and targetOwnerName == playerName then
            return targetUnit, eventState
        end
    end

    local localEventUnit = targetClient.ResolveLocalEventUnit and targetClient:ResolveLocalEventUnit(eventState) or nil
    local localOwnerName = Common.NormalizeName(localEventUnit and (localEventUnit.ownerID or localEventUnit.controllerID or localEventUnit.name) or nil)
    if localEventUnit and localEventUnit.isPlayer == true and localOwnerName == playerName then
        return localEventUnit, eventState
    end

    return nil, eventState
end

local function resolveAuthoritativeLocalPlayerResources(targetClient, state, playerName, targetEventId)
    local targetUnit, eventState = resolveAuthoritativeLocalPlayerResourceUnit(targetClient, state, playerName, targetEventId)
    if type(targetUnit) ~= "table" then
        return nil, nil
    end

    local resources = select(1, resolveLocalActiveSpellcasterResources(targetClient, eventState, targetUnit, {
        clone = true,
    }))
    if not hasResourceEntries(resources) then
        return nil, nil
    end
    return resources, tonumber(targetUnit.eventID) or nil
end

local function shouldRefreshActionBarSlotsForTarget(targetClient, eventState, targetUnit, targetEventId, playerName)
    if type(targetClient) ~= "table" then
        return false
    end

    local activeEventUnit = type(targetClient.ResolveActiveSpellcasterUnit) == "function"
        and select(1, targetClient:ResolveActiveSpellcasterUnit(eventState))
        or nil
    if type(activeEventUnit) ~= "table" then
        return false
    end

    local activeEventId = tonumber(activeEventUnit.eventID) or 0
    local numericTargetEventId = tonumber(targetEventId) or tonumber(targetUnit and targetUnit.eventID) or 0
    if activeEventId > 0 and numericTargetEventId > 0 then
        return activeEventId == numericTargetEventId
    end

    if activeEventUnit.isPlayer ~= true then
        return false
    end

    local localPlayerName = resolveLocalPlayerName()
    local normalizedPlayerName = Common.NormalizeName and Common.NormalizeName(playerName)
        or (type(playerName) == "string" and playerName or "")
    if localPlayerName == "" or normalizedPlayerName == "" or normalizedPlayerName ~= localPlayerName then
        return false
    end

    local activeOwnerName = normalizeUnitOwnerName(activeEventUnit)
    if activeOwnerName ~= "" then
        return activeOwnerName == localPlayerName
    end

    if type(targetUnit) == "table" and targetUnit.isPlayer == true then
        return normalizeUnitOwnerName(targetUnit) == localPlayerName
    end

    return true
end

local function applyInboundResourceDeltasForTarget(targetClient, state, eventState, playerName, sender, targetEventId, resourceDeltas)
    local targetUnit = tonumber(targetEventId) and tonumber(targetEventId) > 0
        and findEventUnitById(eventState and eventState.units, targetEventId)
        or nil
    local targetUnitIsPlayer = targetUnit and targetUnit.isPlayer == true or false
    local targetOwnerName = Common.NormalizeName(targetUnit and (targetUnit.ownerID or targetUnit.controllerID or targetUnit.name) or nil)
    local resourceOwnerName = targetUnit and tostring(targetUnit.name or playerName) or playerName
    local cachePlayerName = targetUnitIsPlayer == true and (targetOwnerName ~= "" and targetOwnerName or playerName) or playerName

    local member = nil
    if targetEventId <= 0 or targetUnitIsPlayer == true then
        member = state.membersByName and state.membersByName[cachePlayerName] or nil
        if not member then
            addMember(state, cachePlayerName)
            member = state.membersByName and state.membersByName[cachePlayerName] or nil
        end
    end

    local eventUpdated = false
    local appliedDeltas = {}
    if eventState and targetEventId > 0 and ResourceSync.ApplyResourceDeltasToEventUnitByEventID then
        eventUpdated, targetUnit, appliedDeltas = ResourceSync.ApplyResourceDeltasToEventUnitByEventID(eventState.units, targetEventId, resourceDeltas, {
            healthResourceRef = eventState.healthResourceRef,
        })
        targetUnitIsPlayer = targetUnit and targetUnit.isPlayer == true or false
        targetOwnerName = Common.NormalizeName(targetUnit and (targetUnit.ownerID or targetUnit.controllerID or targetUnit.name) or nil)
        resourceOwnerName = targetUnit and tostring(targetUnit.name or playerName) or resourceOwnerName
        local combat = getCombat()
        if eventUpdated
            and targetUnit
            and combat
            and type(combat.IsUnitDead) == "function"
            and combat:IsUnitDead(targetUnit, { eventState = eventState })
            and type(combat.HandleUnitDeath) == "function"
        then
            combat:HandleUnitDeath({
                client = targetClient,
                eventState = eventState,
                targetUnit = targetUnit,
            })
        end
    end

    local cachedChanged = false
    if member and (targetEventId <= 0 or targetUnitIsPlayer == true) then
        local previousResources = member.resources
        if targetUnit and type(targetUnit.resources) == "table" then
            member.resources = ResourceSync.CloneResources and ResourceSync.CloneResources(targetUnit.resources) or targetUnit.resources
            cachedChanged = previousResources == nil
                or not (ResourceSync.ResourcesEqual and ResourceSync.ResourcesEqual(previousResources, member.resources))
        elseif type(previousResources) == "table" and ResourceSync.ApplyResourceDeltasToResources then
            cachedChanged = select(1, ResourceSync.ApplyResourceDeltasToResources(previousResources, resourceDeltas, {
                healthResourceRef = eventState and eventState.healthResourceRef or nil,
            })) or false
        end
    end

    return {
        changed = cachedChanged or eventUpdated,
        eventUpdated = eventUpdated,
        targetUnit = targetUnit,
        appliedDeltas = appliedDeltas or resourceDeltas,
        resourceOwnerName = resourceOwnerName,
        sender = sender,
    }
end

local function shouldDeferTurnResourceDeltas(targetClient, state, options)
    if type(options) == "table" and options.immediate == true then
        return false
    end
    if type(targetClient) ~= "table" or targetClient.DeferTurnDeltaSync == false then
        return false
    end
    if type(state) ~= "table" or state.active ~= true then
        return false
    end

    local eventState = targetClient.GetEventState and targetClient:GetEventState() or nil
    return type(eventState) == "table"
        and eventState.active == true
        and eventState.channelName == state.channelName
end

local function applyQueuedLocalResourceDeltas(targetClient, state, targetEventId, resourceDeltas)
    local eventState = targetClient.GetEventState and targetClient:GetEventState() or nil
    local playerName = getPlayerNameForState(state) or ""
    if playerName == "" or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local result = applyInboundResourceDeltasForTarget(
        targetClient,
        state,
        eventState,
        playerName,
        playerName,
        targetEventId,
        resourceDeltas
    )
    if result.eventUpdated and type(targetClient.QueueEventWidgetRefresh) == "function" then
        queueScopedEventPortraitRefresh(targetClient, "resource-delta-local", targetEventId)
        bumpEventTooltipContextRevision(eventState, targetEventId)
        refreshTargetingForEventState(targetClient, "resource-delta-local")
    end
    if shouldRefreshActionBarSlotsForTarget(targetClient, eventState, result.targetUnit, targetEventId, playerName) then
        if type(targetClient.QueueActionBarRefresh) == "function" then
            targetClient:QueueActionBarRefresh("resource-delta-local")
        elseif type(targetClient.RefreshActionBarWidget) == "function" then
            targetClient:RefreshActionBarWidget("resource-delta-local")
        end
    end
    if shouldRefreshCompanionBarsForTarget(targetClient, eventState, result.targetUnit, targetEventId)
        and type(targetClient.QueueActionBarCompanionBarsRefresh) == "function"
    then
        targetClient:QueueActionBarCompanionBarsRefresh("resource-delta-local", { immediate = true })
    elseif shouldRefreshCompanionBarsForTarget(targetClient, eventState, result.targetUnit, targetEventId)
        and type(Client.RefreshActionBarCompanionBars) == "function"
    then
        Client:RefreshActionBarCompanionBars("resource-delta-local")
    end
    return result.changed == true
end

local function flushQueuedClientResourceDeltas(targetClient, expectedState, expectedScope)
    if type(targetClient) ~= "table" then
        return false
    end

    local scope = normalizePendingScope(expectedScope)
    targetClient.PendingResourceDeltaFlushQueued = false
    targetClient.PendingResourceDeltaFlushQueuedByScope = targetClient.PendingResourceDeltaFlushQueuedByScope or {}
    targetClient.PendingResourceDeltaFlushQueuedByScope[scope] = false

    local pendingBatches = targetClient.PendingResourceDeltaBatches or {}
    if targetClient.State ~= expectedState or type(expectedState) ~= "table" or expectedState.active ~= true then
        return false
    end

    local batchedPayloads = {}
    local flushed = false
    for batchKey, batch in pairs(pendingBatches) do
        if type(batch) == "table"
            and batch.state == expectedState
            and batch.channelName == expectedState.channelName
            and normalizePendingScope(batch.scope) == scope
            and type(batch.resourceDeltas) == "table"
            and #batch.resourceDeltas > 0
        then
            pendingBatches[batchKey] = nil
            local batchIndex = batch.allowLocalEchoApply == true and 1 or 0
            local aggregate = batchedPayloads[batchIndex]
            if not aggregate then
                aggregate = {
                    reason = "",
                    allowLocalEchoApply = batch.allowLocalEchoApply == true,
                    targetedResourceDeltas = {},
                    threatUpdates = {},
                }
                batchedPayloads[batchIndex] = aggregate
            end

            aggregate.reason = mergeReasons(aggregate.reason, batch.reason)
            for deltaIndex = 1, #batch.resourceDeltas do
                local deltaEntry = batch.resourceDeltas[deltaIndex]
                aggregate.targetedResourceDeltas[#aggregate.targetedResourceDeltas + 1] = {
                    targetEventId = batch.targetEventId,
                    resourceRef = deltaEntry.resourceRef,
                    delta = deltaEntry.delta,
                    maxValue = deltaEntry.maxValue,
                    currentValue = deltaEntry.currentValue,
                }
            end
            aggregate.threatUpdates = coalesceThreatUpdates(aggregate.threatUpdates, batch.threatUpdates)
        end
    end

    for _, aggregate in pairs(batchedPayloads) do
        if type(aggregate) == "table" and type(aggregate.targetedResourceDeltas) == "table" and #aggregate.targetedResourceDeltas > 0 then
            local sent = targetClient:SendClientResourceDeltaBatch(
                expectedState,
                aggregate.reason,
                nil,
                aggregate.targetedResourceDeltas,
                {
                    allowLocalEchoApply = aggregate.allowLocalEchoApply == true,
                    threatUpdates = aggregate.threatUpdates,
                }
            )
            flushed = sent or flushed
        end
    end

    return flushed
end

function Client:FlushDeferredTurnResourceDeltas(stateOverride, eventStateOverride)
    local state = stateOverride or self:GetState()
    local eventState = eventStateOverride or (self.GetEventState and self:GetEventState() or nil)
    if type(state) ~= "table"
        or state.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.channelName ~= state.channelName
    then
        return false
    end

    local pendingBatches = self.PendingResourceDeltaBatches or {}
    self.PendingResourceDeltaFlushQueued = false
    self.PendingResourceDeltaFlushQueuedByScope = self.PendingResourceDeltaFlushQueuedByScope or {}
    self.PendingResourceDeltaFlushQueuedByScope.turn = false
    if type(self.QueueActionBarRefresh) == "function" then
        self:QueueActionBarRefresh("pending-resource-flush")
    elseif type(self.RefreshActionBarWidget) == "function" then
        self:RefreshActionBarWidget("pending-resource-flush")
    end
    if type(self.QueuePendingTurnChangesTooltipRefresh) == "function" then
        self:QueuePendingTurnChangesTooltipRefresh()
    elseif type(self.RefreshPendingTurnChangesTooltip) == "function" then
        self:RefreshPendingTurnChangesTooltip()
    end

    local targetedResourceDeltas = {}
    local reason = ""
    for batchKey, batch in pairs(pendingBatches) do
        if type(batch) == "table"
            and batch.state == state
            and batch.channelName == state.channelName
            and normalizePendingScope(batch.scope) == "turn"
            and type(batch.resourceDeltas) == "table"
            and #batch.resourceDeltas > 0
        then
            pendingBatches[batchKey] = nil
            reason = mergeReasons(reason, batch.reason)
            for deltaIndex = 1, #batch.resourceDeltas do
                local deltaEntry = batch.resourceDeltas[deltaIndex]
                targetedResourceDeltas[#targetedResourceDeltas + 1] = {
                    targetEventId = batch.targetEventId,
                    resourceRef = deltaEntry.resourceRef,
                    delta = deltaEntry.delta,
                    maxValue = deltaEntry.maxValue,
                    currentValue = deltaEntry.currentValue,
                }
            end
        end
    end

    targetedResourceDeltas = ResourceSync.CoalesceTargetedResourceDeltas
        and ResourceSync.CoalesceTargetedResourceDeltas(targetedResourceDeltas)
        or targetedResourceDeltas
    if type(targetedResourceDeltas) ~= "table" or #targetedResourceDeltas == 0 then
        return true
    end

    return self:SendClientResourceDeltaBatch(
        state,
        reason ~= "" and reason or "turn-resource",
        nil,
        targetedResourceDeltas,
        {
            allowLocalEchoApply = false,
        }
    )
end

local function syncServerEventState(eventState)
    if Addon.Server and Addon.Server.EventState and Addon.Server.EventState.id == (eventState and eventState.id or nil) and eventState then
        Addon.Server.EventState.healthResourceRef = eventState.healthResourceRef
        Addon.Server.EventState.rosterReady = eventState.rosterReady
        Addon.Server.EventState.unitsReady = eventState.unitsReady
        Addon.Server.EventState.resourcesReady = eventState.resourcesReady
        Addon.Server.EventState.unitsChunkExpected = eventState.unitsChunkExpected
        Addon.Server.EventState.unitsChunkReceived = eventState.unitsChunkReceived
        Addon.Server.EventState.healthResourcesExpected = eventState.healthResourcesExpected
        Addon.Server.EventState.healthResourcesReceived = eventState.healthResourcesReceived
        Addon.Server.EventState.readyProgressExpected = eventState.readyProgressExpected
        Addon.Server.EventState.readyProgressReceived = eventState.readyProgressReceived
    end
end

function Client:ResetResourceState()
    self.ResourceSyncQueued = false
    self.LastResourceSyncSignature = nil
    self.PendingResourceDeltaFlushQueued = false
    self.PendingResourceDeltaBatches = {}
    self.PendingResourceDeltaFlushQueuedByScope = {}
    self.PendingLocalResourceDeltaEchoSignatures = {}
    self.PendingLocalResourceDeltaBatchEchoSignatures = {}
    self.LastAppliedTurnRegenKey = nil
end

function Client:ApplyLocalTurnStartResourceRegeneration(stateOverride, eventStateOverride)
    local state = stateOverride or self.State
    local eventState = eventStateOverride or (self.GetEventState and self:GetEventState() or nil)
    if type(state) ~= "table"
        or state.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.channelName ~= state.channelName
    then
        return false
    end

    local activeEventUnit, controlContext = nil, nil
    if type(self.ResolveActiveSpellcasterUnit) == "function" then
        activeEventUnit, _, controlContext = self:ResolveActiveSpellcasterUnit(eventState)
    end
    local activeEventId = tonumber(activeEventUnit and activeEventUnit.eventID) or 0
    if activeEventId <= 0 then
        return false
    end
    if activeEventUnit.isPlayer ~= true and not (type(controlContext) == "table" and controlContext.isControlled == true) then
        return false
    end

    local turnNumber = math.floor(tonumber(eventState.turnNumber) or 0)
    if turnNumber <= 0 then
        return false
    end

    local regenKey = table.concat({
        tostring(eventState.id or ""),
        tostring(turnNumber),
        tostring(activeEventId),
    }, "\31")
    if self.LastAppliedTurnRegenKey == regenKey then
        return false
    end

    local activeStats = type(activeEventUnit.stats) == "table" and activeEventUnit.stats or {}
    local resourceDeltas = ResourceSync.BuildPlayerTurnRegenResourceDeltas
        and ResourceSync.BuildPlayerTurnRegenResourceDeltas(activeEventUnit.resources, {
            healthResourceRef = eventState.healthResourceRef,
            resolveStatValue = function(statRef)
                local normalizedStatRef = type(statRef) == "string" and statRef or ""
                if normalizedStatRef == "" then
                    return 0
                end

                for index = 1, #activeStats do
                    local statEntry = activeStats[index]
                    if statEntry and statEntry.statRef == normalizedStatRef then
                        local currentValue = statEntry.currentValue
                        if currentValue == nil then
                            currentValue = statEntry.value
                        end
                        return tonumber(currentValue) or 0
                    end
                end

                return type(Profile.GetResolvedStatValue) == "function"
                    and (tonumber((Profile.GetResolvedStatValue(normalizedStatRef, 0))) or 0)
                    or 0
            end,
        })
        or {}
    if type(resourceDeltas) ~= "table" or #resourceDeltas == 0 then
        self.LastAppliedTurnRegenKey = regenKey
        return false
    end

    local queued = self:QueueClientResourceDeltas(
        state,
        "turn-regen",
        resourceDeltas,
        activeEventId,
        {
            allowLocalEchoApply = true,
            scope = "turn",
        }
    )
    if queued then
        self.LastAppliedTurnRegenKey = regenKey
    end
    return queued
end

function Client:QueueClientResourceSync(reason, options)
    local state = self.State
    if not state or state.active ~= true then
        return false
    end

    bindStateSessionRuntime(state)
    options = type(options) == "table" and options or {}
    local resources = options.resources
    if type(resources) == "table" and #resources == 0 then
        return false
    end

    if self.ResourceSyncQueued then
        return true
    end

    self.ResourceSyncQueued = true
    local playerName = options.playerName or getPlayerNameForState(state) or "unknown"
    local targetEventId = tonumber(options.targetEventId) or nil
    local capturedResources = ResourceSync.CloneResources and ResourceSync.CloneResources(resources) or resources
    local enqueued = enqueueResourceSync(function(targetClient, expectedState, syncReason, queuedPlayerName, queuedResources)
        targetClient.ResourceSyncQueued = false

        if targetClient.State ~= expectedState or not expectedState or expectedState.active ~= true then
            return
        end

        targetClient:SendClientResources(expectedState, syncReason, queuedPlayerName, queuedResources, targetEventId)
    end, self, state, reason, playerName, capturedResources)
    if not enqueued then
        self.ResourceSyncQueued = false
        return false
    end

    return true
end

function Client:ResolveLocalActiveSpellcasterResources(eventStateOverride, eventUnitOverride, options)
    return resolveLocalActiveSpellcasterResources(self, eventStateOverride, eventUnitOverride, options)
end

function Client:QueueClientResourceDeltas(state, reason, resourceDeltasOverride, targetEventIdOverride, options)
    if not state or state.active ~= true then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA queue skipped: client session is inactive.")
        end
        return false
    end

    if not state.channelName or state.channelName == "" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA queue skipped: client session has no channel name.")
        end
        return false
    end

    local targetEventId = tonumber(targetEventIdOverride) or 0
    if targetEventId <= 0 then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA queue skipped: target event id is invalid (%s).", tostring(targetEventIdOverride))
        end
        return false
    end

    local resourceDeltas = ResourceSync.CoalesceResourceDeltas and ResourceSync.CoalesceResourceDeltas(resourceDeltasOverride) or {}
    if type(resourceDeltas) ~= "table" or #resourceDeltas == 0 then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA queue skipped: resolved delta payload is empty for targetEventId=%s.", tostring(targetEventId))
        end
        return false
    end

    bindStateSessionRuntime(state)
    local playerName = getPlayerNameForState(state) or "unknown"
    local allowLocalEchoApply = type(options) == "table" and options.allowLocalEchoApply == true or false
    local scope = normalizePendingScope(type(options) == "table" and options.scope or nil)
    local threatUpdates = coalesceThreatUpdates(type(options) == "table" and options.threatUpdates or nil)
    self.PendingResourceDeltaBatches = self.PendingResourceDeltaBatches or {}
    local batchKey = buildResourceDeltaBatchKey(state.channelName, targetEventId, allowLocalEchoApply, scope)
    local batch = self.PendingResourceDeltaBatches[batchKey]
    if not batch or batch.state ~= state then
        batch = {
            state = state,
            channelName = state.channelName,
            targetEventId = targetEventId,
            allowLocalEchoApply = allowLocalEchoApply,
            scope = scope,
            reason = tostring(reason or "resource-delta-sync"),
            resourceDeltas = resourceDeltas,
            threatUpdates = threatUpdates,
        }
        self.PendingResourceDeltaBatches[batchKey] = batch
    else
        batch.reason = mergeReasons(batch.reason, reason or "resource-delta-sync")
        batch.resourceDeltas = ResourceSync.CoalesceResourceDeltas and ResourceSync.CoalesceResourceDeltas(batch.resourceDeltas, resourceDeltas) or batch.resourceDeltas
        batch.threatUpdates = coalesceThreatUpdates(batch.threatUpdates, threatUpdates)
    end

    syncSuppressedLocalResourceDeltaCache(self, state, playerName, targetEventId)

    if shouldDeferTurnResourceDeltas(self, state, options) then
        if allowLocalEchoApply then
            applyQueuedLocalResourceDeltas(self, state, targetEventId, resourceDeltas)
        end
        if type(self.QueueActionBarRefresh) == "function" then
            self:QueueActionBarRefresh("pending-resource")
        elseif type(self.RefreshActionBarWidget) == "function" then
            self:RefreshActionBarWidget("pending-resource")
        end
        if type(self.QueuePendingTurnChangesTooltipRefresh) == "function" then
            self:QueuePendingTurnChangesTooltipRefresh()
        elseif type(self.RefreshPendingTurnChangesTooltip) == "function" then
            self:RefreshPendingTurnChangesTooltip()
        end
        return true
    end

    self.PendingResourceDeltaFlushQueuedByScope = self.PendingResourceDeltaFlushQueuedByScope or {}
    if self.PendingResourceDeltaFlushQueuedByScope[scope] == true then
        return true
    end

    self.PendingResourceDeltaFlushQueued = true
    self.PendingResourceDeltaFlushQueuedByScope[scope] = true
    local enqueued = enqueueResourceSync(flushQueuedClientResourceDeltas, self, state, scope)
    if not enqueued then
        self.PendingResourceDeltaFlushQueued = false
        self.PendingResourceDeltaFlushQueuedByScope[scope] = false
        return false
    end

    return true
end

-- Sends the current profile resources to the server for the given session state. 
-- Returns true if the send was accepted, false otherwise.
function Client:SendClientResources(state, reason, playerNameOverride, resourcesOverride, targetEventIdOverride)
    if not state or state.active ~= true then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE sync skipped: client session is inactive.")
        end
        return false
    end

    if not state.channelName or state.channelName == "" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE sync skipped: client session has no channel name.")
        end
        return false
    end

    bindStateSessionRuntime(state)
    local channelId = resolveChannelId(state)
    if not channelId then
        if Debug and Debug.Error then
            Debug.Error(
                "RESOURCE sync skipped: session channel %s has no resolved channel id.",
                tostring(state.channelName)
            )
        end
        return false
    end

    local playerName = playerNameOverride or getPlayerNameForState(state) or "unknown"
    local authoritativeResources, authoritativeTargetEventId = resolveAuthoritativeLocalPlayerResources(
        self,
        state,
        playerName,
        targetEventIdOverride
    )
    if authoritativeTargetEventId and authoritativeTargetEventId > 0 then
        syncSuppressedLocalResourceDeltaCache(self, state, playerName, authoritativeTargetEventId)
    end
    local resources = resourcesOverride
        or authoritativeResources
        or (ResourceSync.BuildProfileResourceSnapshot and ResourceSync.BuildProfileResourceSnapshot() or {})
    if #resources == 0 then
        if Debug and Debug.Error then
            Debug.Error(
                "RESOURCE sync skipped: resolved profile resources are empty for %s.",
                tostring(playerName)
            )
        end
        return false
    end

    local payload = ResourceSync.SerializeResources and ResourceSync.SerializeResources(resources) or ""
    if payload == "" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE sync skipped: serialized resource payload is empty.")
        end
        return false
    end

    local arguments = {
        state.channelName,
        playerName,
        payload,
    }
    local targetEventId = tonumber(targetEventIdOverride) or authoritativeTargetEventId or nil
    if targetEventId and targetEventId > 0 then
        arguments[#arguments + 1] = targetEventId
    end
    local sent = sendToChannelForState(state, channelId, RESOURCE_OPCODE, arguments, {
        opcode = RESOURCE_OPCODE,
        scope = "client",
        onFailed = function(_, result)
            if Debug and Debug.Error then
                Debug.Error(
                    "RESOURCE sync send failed on channel %s for %s: %s.",
                    tostring(state.channelName or "unknown"),
                    tostring(playerName),
                    tostring(result or "unknown")
                )
            end
        end,
    })

    if not sent then
        if Debug and Debug.Error then
            Debug.Error(
                "RESOURCE sync failed: send to channel %s was not accepted.",
                tostring(state.channelName or "unknown")
            )
        end
        return false
    end

    return true
end

function Client:SendClientResourceDeltas(state, reason, playerNameOverride, resourceDeltasOverride, targetEventIdOverride, options)
    if not state or state.active ~= true then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA sync skipped: client session is inactive.")
        end
        return false
    end

    if not state.channelName or state.channelName == "" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA sync skipped: client session has no channel name.")
        end
        return false
    end

    bindStateSessionRuntime(state)
    local channelId = resolveChannelId(state)
    if not channelId then
        if Debug and Debug.Error then
            Debug.Error(
                "RESOURCE_DELTA sync skipped: session channel %s has no resolved channel id.",
                tostring(state.channelName)
            )
        end
        return false
    end

    local playerName = playerNameOverride or getPlayerNameForState(state) or "unknown"
    local resourceDeltas = resourceDeltasOverride or {}
    if type(resourceDeltas) ~= "table" or #resourceDeltas == 0 then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA sync skipped: resolved delta payload is empty for %s.", tostring(playerName))
        end
        return false
    end

    local payload = ResourceSync.SerializeResourceDeltas and ResourceSync.SerializeResourceDeltas(resourceDeltas) or ""
    if payload == "" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA sync skipped: serialized delta payload is empty.")
        end
        return false
    end

    local targetEventId = tonumber(targetEventIdOverride) or nil
    local allowLocalEchoApply = type(options) == "table" and options.allowLocalEchoApply == true or false
    local threatUpdates = coalesceThreatUpdates(type(options) == "table" and options.threatUpdates or nil)
    local signature = buildResourceDeltaSignature(state.channelName, playerName, payload, targetEventId)
    if allowLocalEchoApply then
        self.PendingLocalResourceDeltaEchoSignatures = self.PendingLocalResourceDeltaEchoSignatures or {}
        incrementPendingSignature(self.PendingLocalResourceDeltaEchoSignatures, signature)
    else
        syncSuppressedLocalResourceDeltaCache(self, state, playerName, targetEventId)
    end

    local arguments = {
        state.channelName,
        playerName,
        payload,
    }
    if targetEventId and targetEventId > 0 then
        arguments[#arguments + 1] = targetEventId
    end
    if #threatUpdates > 0 then
        arguments[#arguments + 1] = serializeThreatUpdates(threatUpdates)
    end

    local sent = sendToChannelForState(state, channelId, RESOURCE_DELTA_OPCODE, arguments, {
        opcode = RESOURCE_DELTA_OPCODE,
        scope = "client",
        onFailed = function(_, result)
            if Debug and Debug.Error then
                Debug.Error(
                    "RESOURCE_DELTA sync send failed on channel %s for %s: %s.",
                    tostring(state.channelName or "unknown"),
                    tostring(playerName),
                    tostring(result or "unknown")
                )
            end
        end,
    })

    if not sent then
        if allowLocalEchoApply and type(self.PendingLocalResourceDeltaEchoSignatures) == "table" then
            decrementPendingSignature(self.PendingLocalResourceDeltaEchoSignatures, signature)
        end
        if Debug and Debug.Error then
            Debug.Error(
                "RESOURCE_DELTA sync failed: send to channel %s was not accepted.",
                tostring(state.channelName or "unknown")
            )
        end
        return false
    end

    return true
end

function Client:SendClientResourceDeltaBatch(state, reason, playerNameOverride, targetedResourceDeltasOverride, options)
    if not state or state.active ~= true then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA_BATCH sync skipped: client session is inactive.")
        end
        return false
    end

    if not state.channelName or state.channelName == "" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA_BATCH sync skipped: client session has no channel name.")
        end
        return false
    end

    bindStateSessionRuntime(state)
    local channelId = resolveChannelId(state)
    if not channelId then
        if Debug and Debug.Error then
            Debug.Error(
                "RESOURCE_DELTA_BATCH sync skipped: session channel %s has no resolved channel id.",
                tostring(state.channelName)
            )
        end
        return false
    end

    local playerName = playerNameOverride or getPlayerNameForState(state) or "unknown"
    local targetedResourceDeltas = ResourceSync.CoalesceTargetedResourceDeltas
        and ResourceSync.CoalesceTargetedResourceDeltas(targetedResourceDeltasOverride)
        or {}
    if type(targetedResourceDeltas) ~= "table" or #targetedResourceDeltas == 0 then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA_BATCH sync skipped: resolved delta payload is empty for %s.", tostring(playerName))
        end
        return false
    end

    local payload = ResourceSync.SerializeTargetedResourceDeltas and ResourceSync.SerializeTargetedResourceDeltas(targetedResourceDeltas) or ""
    if payload == "" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA_BATCH sync skipped: serialized delta payload is empty.")
        end
        return false
    end

    local allowLocalEchoApply = type(options) == "table" and options.allowLocalEchoApply == true or false
    local threatUpdates = coalesceThreatUpdates(type(options) == "table" and options.threatUpdates or nil)
    local signature = buildResourceDeltaBatchSignature(state.channelName, playerName, payload)
    local targetOrder = nil
    if allowLocalEchoApply then
        self.PendingLocalResourceDeltaBatchEchoSignatures = self.PendingLocalResourceDeltaBatchEchoSignatures or {}
        incrementPendingSignature(self.PendingLocalResourceDeltaBatchEchoSignatures, signature)
    else
        targetOrder = {}
        local targetSeen = {}
        for index = 1, #targetedResourceDeltas do
            local targetEventId = tonumber(targetedResourceDeltas[index] and targetedResourceDeltas[index].targetEventId) or 0
            if targetEventId > 0 and not targetSeen[targetEventId] then
                targetSeen[targetEventId] = true
                targetOrder[#targetOrder + 1] = targetEventId
            end
        end
        for index = 1, #targetOrder do
            syncSuppressedLocalResourceDeltaCache(self, state, playerName, targetOrder[index])
        end
    end
    if not targetOrder then
        targetOrder = buildTargetedResourceDeltaGroups(targetedResourceDeltas)
    end

    local sent = sendToChannelForState(state, channelId, RESOURCE_DELTA_BATCH_OPCODE, {
        state.channelName,
        playerName,
        payload,
        #threatUpdates > 0 and serializeThreatUpdates(threatUpdates) or nil,
    }, {
        opcode = RESOURCE_DELTA_BATCH_OPCODE,
        scope = "client",
        onFailed = function(_, result)
            if Debug and Debug.Error then
                Debug.Error(
                    "RESOURCE_DELTA_BATCH sync send failed on channel %s for %s: %s.",
                    tostring(state.channelName or "unknown"),
                    tostring(playerName),
                    tostring(result or "unknown")
                )
            end
        end,
    })

    if not sent then
        if allowLocalEchoApply and type(self.PendingLocalResourceDeltaBatchEchoSignatures) == "table" then
            decrementPendingSignature(self.PendingLocalResourceDeltaBatchEchoSignatures, signature)
        end
        if Debug and Debug.Error then
            Debug.Error(
                "RESOURCE_DELTA_BATCH sync failed: send to channel %s was not accepted.",
                tostring(state.channelName or "unknown")
            )
        end
        return false
    end

    return true
end

-- When a RESOURCE message is received from the server, this function is called to handle it.
function Client:HandleResource(arguments, sender)
    local state = self.State
    if not state or state.active ~= true then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE receive ignored: client session is inactive.")
        end
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if channelName ~= state.channelName then
        if Debug and Debug.Error then
            Debug.Error(
                "RESOURCE receive ignored: channel mismatch received=%s expected=%s sender=%s.",
                tostring(channelName or "nil"),
                tostring(state.channelName or "nil"),
                tostring(sender or "unknown")
            )
        end
        return false
    end

    local playerName = Common.NormalizeName(arguments and arguments[2] or sender)
    if playerName == "" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE receive ignored: player name is empty for sender=%s.", tostring(sender or "unknown"))
        end
        return false
    end

    local targetEventId = tonumber(arguments and arguments[4]) or 0
    local resourcePayload = arguments and arguments[3] or ""
    local resourceSignature = table.concat({
        tostring(channelName or ""),
        tostring(playerName or ""),
        tostring(sender or ""),
        tostring(targetEventId or 0),
        tostring(resourcePayload or ""),
    }, "\31")
    if state.LastResourceSyncSignature == resourceSignature then
        if Debug and Debug.Internal then
            Debug.Internal(
                "RESOURCE receive ignored: duplicate signature for sender=%s targetEventId=%s player=%s.",
                tostring(sender or "unknown"),
                tostring(targetEventId),
                tostring(playerName)
            )
        end
        return true
    end
    state.LastResourceSyncSignature = resourceSignature

    local resources = ResourceSync.NormalizeResources and ResourceSync.NormalizeResources(resourcePayload) or {}
    local targetUnitIsPlayer = false
    local resourceOwnerName = playerName
    local eventState = self:GetEventState()
    if eventState and targetEventId > 0 then
        for index = 1, #((eventState.units) or {}) do
            local unit = eventState.units[index]
            if unit and tonumber(unit.eventID) == targetEventId then
                targetUnitIsPlayer = unit.isPlayer == true
                if targetUnitIsPlayer ~= true and tostring(unit.name or "") ~= "" then
                    resourceOwnerName = tostring(unit.name)
                end
                break
            end
        end
    end

    local member = nil
    if targetEventId <= 0 or targetUnitIsPlayer == true then
        member = state.membersByName and state.membersByName[playerName] or nil
        if not member then
            addMember(state, playerName)
            member = state.membersByName and state.membersByName[playerName] or nil
        end
    end

    local hadCachedResources = member and member.resources ~= nil
    local cachedChanged = member ~= nil
        and (
            not hadCachedResources
            or not (ResourceSync.ResourcesEqual and ResourceSync.ResourcesEqual(member.resources, resources))
        )

    local eventUpdated = false
    if eventState and targetEventId > 0 and ResourceSync.ApplyResourcesToEventUnitByEventID then
        eventUpdated = ResourceSync.ApplyResourcesToEventUnitByEventID(eventState.units, targetEventId, resources) or false
    elseif eventState and ResourceSync.ApplyResourcesToEventUnits then
        eventUpdated = ResourceSync.ApplyResourcesToEventUnits(eventState.units, playerName, resources) or false
        targetUnitIsPlayer = true
    end

    if member and cachedChanged and (targetEventId <= 0 or targetUnitIsPlayer == true) then
        if targetEventId > 0 and ResourceSync.MergeResourcesByRef then
            member.resources = ResourceSync.MergeResourcesByRef(member.resources, resources)
        else
            member.resources = ResourceSync.CloneResources and ResourceSync.CloneResources(resources) or resources
        end
    end

    if eventState and ResourceSync.UpdateEventReadiness then
        ResourceSync.UpdateEventReadiness(eventState)
    end
    syncServerEventState(eventState)

    if not cachedChanged and not eventUpdated then
        return true
    end

    if isResourceTracingEnabled() and ResourceSync.LogReceivedResources and Debug and Debug.Info then
        ResourceSync.LogReceivedResources(resourceOwnerName, resources, Debug.Info)
    end

    if eventUpdated then
        queueScopedEventPortraitRefresh(self, "resource", targetEventId)
        bumpEventTooltipContextRevision(eventState, targetEventId)
        refreshTargetingForEventState(self, "resource")
    end
    if shouldRefreshActionBarSlotsForTarget(self, eventState, nil, targetEventId, playerName) then
        if type(self.QueueActionBarRefresh) == "function" then
            self:QueueActionBarRefresh("resource")
        elseif type(self.RefreshActionBarWidget) == "function" then
            self:RefreshActionBarWidget("resource")
        end
    end

    if shouldRefreshCompanionBarsForTarget(self, eventState, nil, targetEventId)
        and type(self.QueueActionBarCompanionBarsRefresh) == "function"
    then
        self:QueueActionBarCompanionBarsRefresh("resource", { immediate = true })
    elseif shouldRefreshCompanionBarsForTarget(self, eventState, nil, targetEventId)
        and type(Client.RefreshActionBarCompanionBars) == "function"
    then
        Client:RefreshActionBarCompanionBars("resource")
    end

    local eventManage = Addon.Server and Addon.Server.UI and Addon.Server.UI.EventManage or nil
    if eventManage and eventManage.IsDashboardPageActive and eventManage:IsDashboardPageActive() and eventManage.RefreshDashboard then
        eventManage:RefreshDashboard()
    end

    return true
end

function Client:HandleResourceDelta(arguments, sender)
    local state = self.State
    if not state or state.active ~= true then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA receive ignored: client session is inactive.")
        end
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if channelName ~= state.channelName then
        if Debug and Debug.Error then
            Debug.Error(
                "RESOURCE_DELTA receive ignored: channel mismatch received=%s expected=%s sender=%s.",
                tostring(channelName or "nil"),
                tostring(state.channelName or "nil"),
                tostring(sender or "unknown")
            )
        end
        return false
    end
    local playerName = Common.NormalizeName(arguments and arguments[2] or sender)
    if playerName == "" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA receive ignored: player name is empty for sender=%s.", tostring(sender or "unknown"))
        end
        return false
    end

    local targetEventId = tonumber(arguments and arguments[4]) or 0
    local deltaPayload = arguments and arguments[3] or ""

    local localPlayerName = Common.NormalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil)
    if localPlayerName ~= "" and playerName == localPlayerName then
        local signature = buildResourceDeltaSignature(channelName, playerName, deltaPayload, targetEventId)
        if not consumePendingSignature(self.PendingLocalResourceDeltaEchoSignatures, signature) then
            return true
        end
    end

    local resourceDeltas = ResourceSync.NormalizeResourceDeltas and ResourceSync.NormalizeResourceDeltas(deltaPayload) or {}
    if type(resourceDeltas) ~= "table" or #resourceDeltas == 0 then
        return false
    end

    local eventState = self:GetEventState()
    local result = applyInboundResourceDeltasForTarget(self, state, eventState, playerName, sender, targetEventId, resourceDeltas)

    if eventState and ResourceSync.UpdateEventReadiness then
        ResourceSync.UpdateEventReadiness(eventState)
    end
    syncServerEventState(eventState)

    if not result.changed then
        return true
    end

    if isResourceTracingEnabled() and ResourceSync.LogReceivedResourceDeltas and Debug and Debug.Info then
        ResourceSync.LogReceivedResourceDeltas(result.resourceOwnerName, result.appliedDeltas or resourceDeltas, Debug.Info)
    end

    if result.eventUpdated then
        queueScopedEventPortraitRefresh(self, "resource-delta", targetEventId)
        bumpEventTooltipContextRevision(eventState, targetEventId)
        refreshTargetingForEventState(self, "resource-delta")
    end
    if shouldRefreshActionBarSlotsForTarget(self, eventState, result.targetUnit, targetEventId, playerName) then
        if type(self.QueueActionBarRefresh) == "function" then
            self:QueueActionBarRefresh("resource-delta")
        elseif type(self.RefreshActionBarWidget) == "function" then
            self:RefreshActionBarWidget("resource-delta")
        end
    end

    if shouldRefreshCompanionBarsForTarget(self, eventState, result.targetUnit, targetEventId)
        and type(self.QueueActionBarCompanionBarsRefresh) == "function"
    then
        self:QueueActionBarCompanionBarsRefresh("resource-delta", { immediate = true })
    elseif shouldRefreshCompanionBarsForTarget(self, eventState, result.targetUnit, targetEventId)
        and type(Client.RefreshActionBarCompanionBars) == "function"
    then
        Client:RefreshActionBarCompanionBars("resource-delta")
    end

    local spellcasting = Client.Spellcasting or nil
    if spellcasting
        and type(spellcasting.ShowInboundResourceDeltaCombatText) == "function"
        and Common.NormalizeName(sender) ~= (spellcasting.GetLocalPlayerName and spellcasting.GetLocalPlayerName() or "")
    then
        spellcasting.ShowInboundResourceDeltaCombatText(self, eventState, result.targetUnit, result.appliedDeltas or resourceDeltas)
    end

    local eventManage = Addon.Server and Addon.Server.UI and Addon.Server.UI.EventManage or nil
    if eventManage and eventManage.IsDashboardPageActive and eventManage:IsDashboardPageActive() and eventManage.RefreshDashboard then
        eventManage:RefreshDashboard()
    end

    return true
end

function Client:HandleResourceDeltaBatch(arguments, sender)
    local state = self.State
    if not state or state.active ~= true then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA_BATCH receive ignored: client session is inactive.")
        end
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if channelName ~= state.channelName then
        if Debug and Debug.Error then
            Debug.Error(
                "RESOURCE_DELTA_BATCH receive ignored: channel mismatch received=%s expected=%s sender=%s.",
                tostring(channelName or "nil"),
                tostring(state.channelName or "nil"),
                tostring(sender or "unknown")
            )
        end
        return false
    end
    local playerName = Common.NormalizeName(arguments and arguments[2] or sender)
    if playerName == "" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA_BATCH receive ignored: player name is empty for sender=%s.", tostring(sender or "unknown"))
        end
        return false
    end

    local deltaPayload = arguments and arguments[3] or ""
    local localPlayerName = Common.NormalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil)
    if localPlayerName ~= "" and playerName == localPlayerName then
        local signature = buildResourceDeltaBatchSignature(channelName, playerName, deltaPayload)
        if not consumePendingSignature(self.PendingLocalResourceDeltaBatchEchoSignatures, signature) then
            return true
        end
    end

    local targetedResourceDeltas = ResourceSync.CoalesceTargetedResourceDeltas
        and ResourceSync.CoalesceTargetedResourceDeltas(deltaPayload)
        or {}
    if type(targetedResourceDeltas) ~= "table" or #targetedResourceDeltas == 0 then
        return false
    end

    local targetOrder, deltasByTargetEventId = buildTargetedResourceDeltaGroups(targetedResourceDeltas)
    if #targetOrder == 0 then
        return false
    end

    local eventState = self:GetEventState()
    local changed = false
    local anyEventUpdated = false
    local anyCompanionBarRelevantTarget = false
    local anyActionBarRelevantTarget = false
    local changedEventIds = {}
    local results = {}
    for index = 1, #targetOrder do
        local targetEventId = targetOrder[index]
        local result = applyInboundResourceDeltasForTarget(
            self,
            state,
            eventState,
            playerName,
            sender,
            targetEventId,
            deltasByTargetEventId[targetEventId]
        )
        if result.changed then
            changed = true
        end
        if result.eventUpdated then
            anyEventUpdated = true
            changedEventIds[#changedEventIds + 1] = targetEventId
            bumpEventTooltipContextRevision(eventState, targetEventId)
        end
        if shouldRefreshCompanionBarsForTarget(self, eventState, result.targetUnit, targetEventId) then
            anyCompanionBarRelevantTarget = true
        end
        if shouldRefreshActionBarSlotsForTarget(self, eventState, result.targetUnit, targetEventId, playerName) then
            anyActionBarRelevantTarget = true
        end
        results[#results + 1] = result
    end

    if eventState and ResourceSync.UpdateEventReadiness then
        ResourceSync.UpdateEventReadiness(eventState)
    end
    syncServerEventState(eventState)

    if not changed then
        return true
    end

    if isResourceTracingEnabled() and ResourceSync.LogReceivedResourceDeltas and Debug and Debug.Info then
        for index = 1, #results do
            local result = results[index]
            if result.changed then
                ResourceSync.LogReceivedResourceDeltas(result.resourceOwnerName, result.appliedDeltas or {}, Debug.Info)
            end
        end
    end

    if anyEventUpdated then
        if type(self.QueueEventWidgetTargetedRefresh) == "function" then
            self:QueueEventWidgetTargetedRefresh("resource-delta-batch", changedEventIds)
        else
            queueScopedEventPortraitRefresh(self, "resource-delta-batch", changedEventIds[1])
        end
        refreshTargetingForEventState(self, "resource-delta-batch")
    end
    if anyActionBarRelevantTarget then
        if type(self.QueueActionBarRefresh) == "function" then
            self:QueueActionBarRefresh("resource-delta-batch")
        elseif type(self.RefreshActionBarWidget) == "function" then
            self:RefreshActionBarWidget("resource-delta-batch")
        end
    end

    if anyCompanionBarRelevantTarget
        and type(self.QueueActionBarCompanionBarsRefresh) == "function"
    then
        self:QueueActionBarCompanionBarsRefresh("resource-delta-batch", { immediate = true })
    elseif anyCompanionBarRelevantTarget
        and type(Client.RefreshActionBarCompanionBars) == "function"
    then
        Client:RefreshActionBarCompanionBars("resource-delta-batch")
    end

    local spellcasting = Client.Spellcasting or nil
    if spellcasting
        and type(spellcasting.ShowInboundResourceDeltaCombatText) == "function"
        and Common.NormalizeName(sender) ~= (spellcasting.GetLocalPlayerName and spellcasting.GetLocalPlayerName() or "")
    then
        for index = 1, #results do
            local result = results[index]
            if result.changed then
                spellcasting.ShowInboundResourceDeltaCombatText(self, eventState, result.targetUnit, result.appliedDeltas or {})
            end
        end
    end

    local eventManage = Addon.Server and Addon.Server.UI and Addon.Server.UI.EventManage or nil
    if eventManage and eventManage.IsDashboardPageActive and eventManage:IsDashboardPageActive() and eventManage.RefreshDashboard then
        eventManage:RefreshDashboard()
    end

    return true
end
