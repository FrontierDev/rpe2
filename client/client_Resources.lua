local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Debug = Addon.Debug
local Common = Addon.Utils.Common or {}
local Comms = Addon.Internal.Comms or {}
local Profile = Addon.Internal.Profile or {}
local Ruleset = Addon.Internal.Ruleset or {}
local Operations = Comms.Operations or {}
local ResourceSync = Comms.ResourceSync or {}
local EventTransactions = Comms.EventTransactions

local RESOURCE_OPCODE = Operations:GetOpcode("RESOURCE")
local NativeJoinChannel = Comms and Comms.JoinChannel or nil
local NativeResolveChannelId = Comms and Comms.ResolveChannelId or nil

Client.ResourceSyncQueued = Client.ResourceSyncQueued or false
Client.LastResourceSyncSignature = Client.LastResourceSyncSignature or nil
Client.PendingResourceDeltaFlushQueued = Client.PendingResourceDeltaFlushQueued or false
Client.PendingResourceDeltaFlushQueuedByScope = Client.PendingResourceDeltaFlushQueuedByScope or {}
Client.PendingResourceDeltaFlushQueuedEventIdByScope = Client.PendingResourceDeltaFlushQueuedEventIdByScope or {}
Client.PendingResourceDeltaBatches = Client.PendingResourceDeltaBatches or {}
Client.LastAppliedTurnRegenKey = Client.LastAppliedTurnRegenKey or nil

local function isTurnResourceRegenerationEnabled()
    local activeRuleset = Ruleset and Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset
        and Ruleset.GetRulesetRuleDefinition
        and Ruleset.GetRulesetRuleDefinition("resources", "enable_resource_regeneration_per_turn")
        or nil
    if not ruleDefinition or type(Ruleset.GetRulesetRuleValue) ~= "function" then
        return true
    end

    return Ruleset.GetRulesetRuleValue(activeRuleset, "resources", ruleDefinition) ~= false
end

local function getResourceRegenerationStatRef()
    local activeRuleset = Ruleset and Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset
        and Ruleset.GetRulesetRuleDefinition
        and Ruleset.GetRulesetRuleDefinition("resources", "resource_regeneration_stat")
        or nil
    local statRef = Ruleset
        and Ruleset.GetRulesetRuleValue
        and Ruleset.GetRulesetRuleValue(activeRuleset, "resources", ruleDefinition)
        or nil

    return type(statRef) == "string" and statRef or ""
end

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
                turnNumber = math.floor(tonumber(entry and entry.turnNumber) or 0) > 0
                    and math.floor(tonumber(entry and entry.turnNumber) or 0)
                    or nil,
            }
        end
    end

    return normalized
end

local function findEventUnitById(units, eventId)
    local numericEventId = math.floor(tonumber(eventId) or 0)
    if type(units) ~= "table" or numericEventId <= 0 then
        return nil
    end

    for index = 1, #units do
        local unit = units[index]
        if type(unit) == "table" and math.floor(tonumber(unit.eventID) or 0) == numericEventId then
            return unit
        end
    end

    return nil
end

local function filterThreatUpdatesForEvent(threatUpdates, eventState)
    local normalized = normalizeThreatUpdates(threatUpdates)
    local units = type(eventState) == "table" and eventState.units or nil
    if type(units) ~= "table" then
        return normalized
    end

    local filtered = {}
    for index = 1, #normalized do
        local entry = normalized[index]
        local sourceUnit = findEventUnitById(units, entry.sourceEventId)
        local targetUnit = findEventUnitById(units, entry.targetEventId)
        -- Keep all valid gameplay threat updates on the transport. EventMeters applies
        -- the player-character source filter independently when it records a row.
        if sourceUnit and targetUnit and targetUnit.isPlayer ~= true then
            entry.turnNumber = entry.turnNumber or math.floor(tonumber(eventState.turnNumber) or 0)
            filtered[#filtered + 1] = entry
        end
    end
    return filtered
end

local function coalesceThreatUpdates(threatUpdates, additionalThreatUpdates)
    local totals = {}
    local order = {}
    local function merge(list)
        local normalized = normalizeThreatUpdates(list)
        for index = 1, #normalized do
            local entry = normalized[index]
            local key = tostring(entry.targetEventId) .. "\31" .. tostring(entry.sourceEventId) .. "\31" .. tostring(entry.turnNumber or 0)
            if not totals[key] then
                totals[key] = {
                    targetEventId = entry.targetEventId,
                    sourceEventId = entry.sourceEventId,
                    amount = 0,
                    turnNumber = entry.turnNumber,
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

local function getEventUnitHealthValue(unit, eventState)
    if type(unit) ~= "table" then
        return nil
    end

    local combat = getCombat()
    if combat and type(combat.GetUnitHealthEntry) == "function" then
        local entry = combat:GetUnitHealthEntry(unit, { eventState = eventState })
        if type(entry) == "table" then
            return tonumber(entry.currentValue) or tonumber(entry.maxValue) or 0
        end
    end

    local healthResourceRef = eventState and eventState.healthResourceRef or nil
    if type(healthResourceRef) ~= "string" or healthResourceRef == "" then
        return nil
    end

    for index = 1, #(unit.resources or {}) do
        local resource = unit.resources[index]
        if resource and resource.resourceRef == healthResourceRef then
            return tonumber(resource.currentValue) or tonumber(resource.maxValue) or 0
        end
    end

    return nil
end

local function getEventUnitHealthMaxValue(unit, eventState)
    if type(unit) ~= "table" then
        return nil
    end

    local combat = getCombat()
    if combat and type(combat.GetUnitHealthEntry) == "function" then
        local entry = combat:GetUnitHealthEntry(unit, { eventState = eventState })
        if type(entry) == "table" then
            return tonumber(entry.maxValue)
        end
    end

    local healthResourceRef = eventState and eventState.healthResourceRef or nil
    if type(healthResourceRef) ~= "string" or healthResourceRef == "" then
        return nil
    end

    for index = 1, #(unit.resources or {}) do
        local resource = unit.resources[index]
        if resource and resource.resourceRef == healthResourceRef then
            return tonumber(resource.maxValue)
        end
    end

    return nil
end

local function resolveKillIsEnemy(targetClient, eventState, targetUnit)
    if type(targetUnit) ~= "table" then
        return false
    end

    local actorUnit = nil
    if type(targetClient.ResolveControlledEventUnit) == "function" then
        actorUnit = targetClient:ResolveControlledEventUnit(eventState)
    end
    if not actorUnit and type(targetClient.ResolveLocalEventUnit) == "function" then
        actorUnit = targetClient:ResolveLocalEventUnit(eventState)
    end

    local targetTeam = tonumber(targetUnit.team)
    local actorTeam = tonumber(actorUnit and actorUnit.team)
    if targetTeam ~= nil and actorTeam ~= nil then
        return targetTeam ~= actorTeam
    end

    return targetUnit.isPlayer ~= true
end

local function isBossEventUnit(unit)
    if type(unit) ~= "table" then
        return false
    end

    local eventUnitClass = Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.EventUnit
        or nil
    if eventUnitClass and type(eventUnitClass.IsBoss) == "function" then
        return eventUnitClass.IsBoss(unit) == true
    end

    return unit.boss == true
end

local function grantBossKillValor(targetClient, eventState, result)
    local kill = result and result.kill
    if type(kill) ~= "table" or kill.isBoss ~= true then
        return false
    end

    if type(targetClient.GrantConfiguredEventCurrency) ~= "function" then
        return false
    end

    local targetEventId = tonumber(kill.targetEventId) or 0
    return targetClient:GrantConfiguredEventCurrency(
        "valor",
        "boss_kill_valor_currency",
        25,
        eventState,
        ("boss-kill-valor:%d"):format(targetEventId)
    )
end

local function notifyRPEKillAchievement(targetClient, eventState, actionOwnerName, result)
    local kill = result and result.kill
    if type(kill) ~= "table" then
        return
    end

    local localPlayerName = resolveLocalPlayerName()
    local normalizedActionOwnerName = Common.NormalizeName
        and Common.NormalizeName(actionOwnerName)
        or tostring(actionOwnerName or "")
    if normalizedActionOwnerName == "" or localPlayerName == "" or normalizedActionOwnerName ~= localPlayerName then
        return
    end

    local achievements = Addon.Client and Addon.Client.Achievements or nil
    if not achievements or type(achievements.HandleRPEKill) ~= "function" then
        return
    end

    local targetUnit = kill.targetUnit
    pcall(
        achievements.HandleRPEKill,
        achievements,
        {
            authoritative = true,
            actionOwnerName = normalizedActionOwnerName,
            actorName = normalizedActionOwnerName,
            eventState = eventState,
            targetEventId = kill.targetEventId,
            targetUnit = targetUnit,
            unitRef = targetUnit and (targetUnit.registryID or targetUnit.unitRef or targetUnit.ref) or nil,
            isEnemy = resolveKillIsEnemy(targetClient, eventState, targetUnit),
            isBoss = kill.isBoss == true
                or (kill.isBoss == nil and isBossEventUnit(targetUnit)),
            wasAlive = true,
            isDead = true,
            source = "resource-delta",
        }
    )
end

local function notifyRPEHealthAchievement(targetClient, eventState, actionOwnerName, result)
    if type(result) ~= "table" or type(result.targetUnit) ~= "table" then
        return
    end

    local localPlayerName = resolveLocalPlayerName()
    local normalizedActionOwnerName = Common.NormalizeName
        and Common.NormalizeName(actionOwnerName)
        or tostring(actionOwnerName or "")
    if normalizedActionOwnerName == ""
        or localPlayerName == ""
        or normalizedActionOwnerName ~= localPlayerName
    then
        return
    end

    local achievements = Addon.Client and Addon.Client.Achievements or nil
    if not achievements then
        return
    end

    local targetUnit = result.targetUnit
    local context = {
        authoritative = true,
        actionOwnerName = normalizedActionOwnerName,
        actorName = normalizedActionOwnerName,
        eventState = eventState,
        targetEventId = result.targetEventId,
        targetUnit = targetUnit,
        unitRef = targetUnit.registryID or targetUnit.unitRef or targetUnit.ref,
        isEnemy = resolveKillIsEnemy(targetClient, eventState, targetUnit),
        source = "resource-delta",
    }

    local actualDamage = math.max(0, tonumber(result.actualDamage) or 0)
    if actualDamage > 0 and type(achievements.HandleRPEDamage) == "function" then
        context.amount = actualDamage
        pcall(achievements.HandleRPEDamage, achievements, context)
    end

    local actualHealing = math.max(0, tonumber(result.actualHealing) or 0)
    if actualHealing > 0 and type(achievements.HandleRPEHealing) == "function" then
        context.amount = actualHealing
        pcall(achievements.HandleRPEHealing, achievements, context)
    end
end

local function normalizePendingScope(value)
    return tostring(value or "turn") == "reaction" and "reaction" or "turn"
end

local function buildResourceDeltaBatchKey(channelName, eventId, sourceTurnNumber, sourceTickNumber, targetEventId, scope)
    return table.concat({
        normalizePendingScope(scope),
        tostring(channelName or ""),
        tostring(eventId or ""),
        tostring(sourceTurnNumber or ""),
        tostring(sourceTickNumber or ""),
        tostring(targetEventId or 0),
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

local function flushQueuedClientResourceDeltas(targetClient, expectedState, expectedScope, expectedEventId)
    if type(targetClient) ~= "table" then
        return false
    end

    local scope = normalizePendingScope(expectedScope)
    local normalizedExpectedEventId = tostring(expectedEventId or "")
    targetClient.PendingResourceDeltaFlushQueuedByScope = targetClient.PendingResourceDeltaFlushQueuedByScope or {}
    targetClient.PendingResourceDeltaFlushQueuedEventIdByScope = targetClient.PendingResourceDeltaFlushQueuedEventIdByScope or {}
    if normalizedExpectedEventId == ""
        or tostring(targetClient.PendingResourceDeltaFlushQueuedEventIdByScope[scope] or "") == normalizedExpectedEventId
    then
        targetClient.PendingResourceDeltaFlushQueued = false
        targetClient.PendingResourceDeltaFlushQueuedByScope[scope] = false
        targetClient.PendingResourceDeltaFlushQueuedEventIdByScope[scope] = nil
    end

    local pendingBatches = targetClient.PendingResourceDeltaBatches or {}
    if targetClient.State ~= expectedState or type(expectedState) ~= "table" or expectedState.active ~= true then
        return false
    end

    local currentEventState = type(targetClient.GetEventState) == "function"
        and targetClient:GetEventState()
        or nil
    local currentEventId = type(currentEventState) == "table" and tostring(currentEventState.id or "") or nil
    if normalizedExpectedEventId ~= "" and currentEventId ~= normalizedExpectedEventId then
        return false
    end
    local currentTurnNumber = type(currentEventState) == "table"
        and tonumber(currentEventState.turnNumber)
        or nil
    local currentTickNumber = type(currentEventState) == "table"
        and tonumber(currentEventState.tickNumber)
        or nil
    local batchedPayloads = {}
    local flushed = false
    for batchKey, batch in pairs(pendingBatches) do
        if type(batch) == "table"
            and batch.state == expectedState
            and batch.channelName == expectedState.channelName
            and normalizePendingScope(batch.scope) == scope
            and (batch.eventId == nil
                or (currentEventState ~= nil
                    and currentEventState.active == true
                    and tostring(batch.eventId or "") == currentEventId
                    and (batch.sourceTurnNumber == nil or tonumber(batch.sourceTurnNumber) == currentTurnNumber)
                    and (batch.sourceTickNumber == nil or tonumber(batch.sourceTickNumber) == currentTickNumber)))
            and type(batch.resourceDeltas) == "table"
        then
            local batchIndex = 1
            local aggregate = batchedPayloads[batchIndex]
            if not aggregate then
                aggregate = {
                    reason = "",
                    targetedResourceDeltas = {},
                    targetEventIds = {},
                    threatUpdates = {},
                    batches = {},
                }
                batchedPayloads[batchIndex] = aggregate
            end

            aggregate.batches[#aggregate.batches + 1] = { key = batchKey, batch = batch }
            aggregate.reason = mergeReasons(aggregate.reason, batch.reason)
            local batchTargetEventId = tonumber(batch.targetEventId) or 0
            if batchTargetEventId > 0 then
                aggregate.targetEventIds[batchTargetEventId] = true
            end
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
        if type(aggregate) == "table" and type(aggregate.targetedResourceDeltas) == "table" then
            local sent = false
            if #aggregate.targetedResourceDeltas > 0 then
                local mutationId
                sent, mutationId = targetClient:SendClientResourceDeltaBatch(
                    expectedState,
                    aggregate.reason,
                    nil,
                    aggregate.targetedResourceDeltas,
                    {
                        threatUpdates = aggregate.threatUpdates,
                        scope = scope,
                        stepSensitive = scope == "turn",
                    }
                )
            end
            if sent then
                for batchIndex = 1, #(aggregate.batches or {}) do
                    local batchEntry = aggregate.batches[batchIndex]
                    if pendingBatches[batchEntry.key] == batchEntry.batch then
                        pendingBatches[batchEntry.key] = nil
                    end
                end
                if type(targetClient.QueueActionBarRefresh) == "function" then
                    targetClient:QueueActionBarRefresh("pending-resource-sent")
                elseif type(targetClient.RefreshActionBarWidget) == "function" then
                    targetClient:RefreshActionBarWidget("pending-resource-sent")
                end
                if type(targetClient.QueuePendingTurnChangesTooltipRefresh) == "function" then
                    targetClient:QueuePendingTurnChangesTooltipRefresh()
                elseif type(targetClient.RefreshPendingTurnChangesTooltip) == "function" then
                    targetClient:RefreshPendingTurnChangesTooltip()
                end
            end
            flushed = sent or flushed
        end
    end

    return flushed
end

function Client:FlushDeferredTurnResourceDeltas(stateOverride, eventStateOverride, sourceTurnNumber, sourceTickNumber)
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
    local targetedResourceDeltas = {}
    local targetEventIds = {}
    local reason = ""
    local matchingBatches = {}
    for batchKey, batch in pairs(pendingBatches) do
        if type(batch) == "table"
            and batch.state == state
            and batch.channelName == state.channelName
            and tostring(batch.eventId or "") == tostring(eventState.id or "")
            and (sourceTurnNumber == nil or tonumber(batch.sourceTurnNumber) == tonumber(sourceTurnNumber))
            and (sourceTickNumber == nil or tonumber(batch.sourceTickNumber) == tonumber(sourceTickNumber))
            and normalizePendingScope(batch.scope) == "turn"
            and type(batch.resourceDeltas) == "table"
        then
            matchingBatches[#matchingBatches + 1] = { key = batchKey, batch = batch }
            reason = mergeReasons(reason, batch.reason)
            local batchTargetEventId = tonumber(batch.targetEventId) or 0
            if batchTargetEventId > 0 then
                targetEventIds[batchTargetEventId] = true
            end
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

    local sent, mutationId = self:SendClientResourceDeltaBatch(
        state,
        reason ~= "" and reason or "turn-resource",
        nil,
        targetedResourceDeltas,
        {
            scope = "turn",
            stepSensitive = true,
        }
    )
    if sent then
        for batchIndex = 1, #matchingBatches do
            local batchEntry = matchingBatches[batchIndex]
            if pendingBatches[batchEntry.key] == batchEntry.batch then
                pendingBatches[batchEntry.key] = nil
            end
        end
        if type(self.QueueActionBarRefresh) == "function" then
            self:QueueActionBarRefresh("pending-resource-sent")
        elseif type(self.RefreshActionBarWidget) == "function" then
            self:RefreshActionBarWidget("pending-resource-sent")
        end
        if type(self.QueuePendingTurnChangesTooltipRefresh) == "function" then
            self:QueuePendingTurnChangesTooltipRefresh()
        elseif type(self.RefreshPendingTurnChangesTooltip) == "function" then
            self:RefreshPendingTurnChangesTooltip()
        end
    end
    return sent
end

function Client:HasPendingTurnResourceDeltas(stateOverride, eventStateOverride, sourceTurnNumber, sourceTickNumber)
    local state = stateOverride or self:GetState()
    local eventState = eventStateOverride or (self.GetEventState and self:GetEventState() or nil)
    if type(state) ~= "table" or type(eventState) ~= "table" then
        return false
    end

    for _, batch in pairs(self.PendingResourceDeltaBatches or {}) do
        if type(batch) == "table"
            and batch.state == state
            and batch.channelName == state.channelName
            and tostring(batch.eventId or "") == tostring(eventState.id or "")
            and (sourceTurnNumber == nil or tonumber(batch.sourceTurnNumber) == tonumber(sourceTurnNumber))
            and (sourceTickNumber == nil or tonumber(batch.sourceTickNumber) == tonumber(sourceTickNumber))
            and normalizePendingScope(batch.scope) == "turn"
            and type(batch.resourceDeltas) == "table"
            and #batch.resourceDeltas > 0
        then
            return true
        end
    end

    return false
end

function Client:DiscardPendingTurnResourceDeltas(eventId, sourceTurnNumber, sourceTickNumber)
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId == "" then
        return 0
    end

    local pendingBatches = self.PendingResourceDeltaBatches or {}
    local removed = 0
    for batchKey, batch in pairs(pendingBatches) do
        if type(batch) == "table"
            and normalizePendingScope(batch.scope) == "turn"
            and tostring(batch.eventId or "") == normalizedEventId
            and (sourceTurnNumber == nil or tonumber(batch.sourceTurnNumber) == tonumber(sourceTurnNumber))
            and (sourceTickNumber == nil or tonumber(batch.sourceTickNumber) == tonumber(sourceTickNumber))
        then
            pendingBatches[batchKey] = nil
            removed = removed + 1
        end
    end

    return removed
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
    self.ResourceSyncQueuedEventId = nil
    self.LastResourceSyncSignature = nil
    self.PendingResourceDeltaFlushQueued = false
    self.PendingResourceDeltaBatches = {}
    self.PendingResourceDeltaFlushQueuedByScope = {}
    self.PendingResourceDeltaFlushQueuedEventIdByScope = {}
    self.LastAppliedTurnRegenKey = nil
end

function Client:ResetEventResourceDeltas(eventId)
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId == "" then
        return false
    end

    local pendingBatches = self.PendingResourceDeltaBatches or {}
    local removed = false
    for batchKey, batch in pairs(pendingBatches) do
        if type(batch) == "table" and tostring(batch.eventId or "") == normalizedEventId then
            pendingBatches[batchKey] = nil
            removed = true
        end
    end

    local currentEventState = self.GetEventState and self:GetEventState() or self.EventState
    if type(currentEventState) ~= "table"
        or tostring(currentEventState.id or "") == normalizedEventId
    then
        self.PendingResourceDeltaFlushQueuedByScope = self.PendingResourceDeltaFlushQueuedByScope or {}
        self.PendingResourceDeltaFlushQueuedByScope.turn = false
        self.PendingResourceDeltaFlushQueuedEventIdByScope = self.PendingResourceDeltaFlushQueuedEventIdByScope or {}
        self.PendingResourceDeltaFlushQueuedEventIdByScope.turn = nil
        self.PendingResourceDeltaFlushQueued = false
        self.ResourceSyncQueued = false
        self.ResourceSyncQueuedEventId = nil
    end

    return removed
end

function Client:ApplyLocalTurnStartResourceRegeneration(stateOverride, eventStateOverride, options)
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

    if not isTurnResourceRegenerationEnabled() then
        self.LastAppliedTurnRegenKey = regenKey
        return false
    end

    local activeStats = type(activeEventUnit.stats) == "table" and activeEventUnit.stats or {}
    local resourceDeltas = ResourceSync.BuildPlayerTurnRegenResourceDeltas
        and ResourceSync.BuildPlayerTurnRegenResourceDeltas(activeEventUnit.resources, {
            healthResourceRef = eventState.healthResourceRef,
            resourceRegenerationStatRef = getResourceRegenerationStatRef(),
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
            scope = "turn",
            suppressLocalVisualRefresh = type(options) == "table" and options.suppressLocalVisualRefresh == true,
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

    local currentEventState = self.GetEventState and self:GetEventState() or self.EventState
    local queuedEventId = type(currentEventState) == "table" and tostring(currentEventState.id or "") or ""
    if type(currentEventState) == "table"
        and math.max(0, math.floor(tonumber(currentEventState.liveUnitRevision) or 0)) > 0
    then
        return false
    end
    if self.ResourceSyncQueued and tostring(self.ResourceSyncQueuedEventId or "") == queuedEventId then
        return true
    end

    self.ResourceSyncQueued = true
    self.ResourceSyncQueuedEventId = queuedEventId
    local playerName = options.playerName or getPlayerNameForState(state) or "unknown"
    local targetEventId = tonumber(options.targetEventId) or nil
    local capturedResources = nil
    if resources ~= nil then
        capturedResources = ResourceSync.CloneResources and ResourceSync.CloneResources(resources) or resources
    end
    local enqueued = enqueueResourceSync(function(targetClient, expectedState, expectedEventId, syncReason, queuedPlayerName, queuedResources)
        if tostring(targetClient.ResourceSyncQueuedEventId or "") == expectedEventId then
            targetClient.ResourceSyncQueued = false
            targetClient.ResourceSyncQueuedEventId = nil
        end

        if targetClient.State ~= expectedState or not expectedState or expectedState.active ~= true then
            return
        end

        local targetEventState = targetClient.GetEventState and targetClient:GetEventState() or targetClient.EventState
        if expectedEventId ~= ""
            and tostring(type(targetEventState) == "table" and targetEventState.id or "") ~= expectedEventId
        then
            return
        end

        targetClient:SendClientResources(expectedState, syncReason, queuedPlayerName, queuedResources, targetEventId)
    end, self, state, queuedEventId, reason, playerName, capturedResources)
    if not enqueued then
        if tostring(self.ResourceSyncQueuedEventId or "") == queuedEventId then
            self.ResourceSyncQueued = false
            self.ResourceSyncQueuedEventId = nil
        end
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

    if type(ResourceSync.CoalesceResourceDeltas) ~= "function" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA queue rejected: resource normalization is unavailable.")
        end
        return false, "resource-sync-unavailable"
    end
    local resourceDeltas = ResourceSync.CoalesceResourceDeltas(resourceDeltasOverride)
    if type(resourceDeltas) ~= "table" or #resourceDeltas == 0 then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA queue skipped: resolved delta payload is empty for targetEventId=%s.", tostring(targetEventId))
        end
        return false
    end

    bindStateSessionRuntime(state)
    local eventState = self.GetEventState and self:GetEventState() or self.EventState
    local eventId = type(eventState) == "table" and eventState.id or nil
    local sourceTurnNumber = type(eventState) == "table" and math.floor(tonumber(eventState.turnNumber) or 0) or nil
    local sourceTickNumber = type(eventState) == "table" and math.floor(tonumber(eventState.tickNumber) or 0) or nil
    local playerName = getPlayerNameForState(state) or "unknown"
    local scope = normalizePendingScope(type(options) == "table" and options.scope or nil)
    local threatUpdates = filterThreatUpdatesForEvent(
        type(options) == "table" and options.threatUpdates or nil,
        eventState
    )
    self.PendingResourceDeltaBatches = self.PendingResourceDeltaBatches or {}
    local batchKey = buildResourceDeltaBatchKey(
        state.channelName,
        eventId,
        sourceTurnNumber,
        sourceTickNumber,
        targetEventId,
        scope
    )
    local batch = self.PendingResourceDeltaBatches[batchKey]
    if not batch or batch.state ~= state then
        batch = {
            state = state,
            channelName = state.channelName,
            eventId = eventId,
            sourceTurnNumber = sourceTurnNumber,
            sourceTickNumber = sourceTickNumber,
            targetEventId = targetEventId,
            scope = scope,
            reason = tostring(reason or "resource-delta-sync"),
            resourceDeltas = resourceDeltas,
            threatUpdates = threatUpdates,
        }
        self.PendingResourceDeltaBatches[batchKey] = batch
    else
        batch.reason = mergeReasons(batch.reason, reason or "resource-delta-sync")
        batch.resourceDeltas = ResourceSync.CoalesceResourceDeltas(batch.resourceDeltas, resourceDeltas)
        batch.threatUpdates = coalesceThreatUpdates(batch.threatUpdates, threatUpdates)
    end

    syncSuppressedLocalResourceDeltaCache(self, state, playerName, targetEventId)

    if shouldDeferTurnResourceDeltas(self, state, options) then
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
    self.PendingResourceDeltaFlushQueuedEventIdByScope = self.PendingResourceDeltaFlushQueuedEventIdByScope or {}
    if self.PendingResourceDeltaFlushQueuedByScope[scope] == true then
        return true
    end

    self.PendingResourceDeltaFlushQueued = true
    self.PendingResourceDeltaFlushQueuedByScope[scope] = true
    self.PendingResourceDeltaFlushQueuedEventIdByScope[scope] = tostring(eventId or "")
    local enqueued = enqueueResourceSync(flushQueuedClientResourceDeltas, self, state, scope, eventId)
    if not enqueued then
        self.PendingResourceDeltaFlushQueued = false
        self.PendingResourceDeltaFlushQueuedByScope[scope] = false
        self.PendingResourceDeltaFlushQueuedEventIdByScope[scope] = nil
        return false
    end

    return true
end

local getLiveResourceTarget
local submitEventResourceTransaction

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

    local targetEventId = tonumber(targetEventIdOverride) or authoritativeTargetEventId or 0
    if targetEventId > 0 then
        if type(ResourceSync.NormalizeResources) ~= "function" then
            if Debug and Debug.Error then
                Debug.Error("RESOURCE replace rejected: resource normalization is unavailable.")
            end
            return false, "resource-sync-unavailable"
        end
        resources = ResourceSync.NormalizeResources(resources)
        if type(resources) ~= "table" or #resources == 0 then
            return false, "empty-resources"
        end
        local targetUnit = getLiveResourceTarget(self, targetEventId)
        if not targetUnit then
            if Debug and Debug.Error then
                Debug.Error("RESOURCE replace rejected: live EventUnit %s is unavailable.", tostring(targetEventId))
            end
            return false, "missing-live-resource-target"
        end
        return submitEventResourceTransaction(
            self,
            state,
            "event-resource-replace",
            reason,
            {
                targetEventId = targetEventId,
                resources = resources,
                reason = tostring(reason or "resource-replace"),
            },
            { targetEventId },
            {
                stepSensitive = false,
            }
        )
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

    local currentEventState = self.GetEventState and self:GetEventState() or self.EventState
    if type(currentEventState) == "table"
        and currentEventState.active == true
        and currentEventState.channelName == state.channelName
    then
        state.lastResourceSyncEventId = currentEventState.id
    end

    return true
end

-- Resource packets are client-to-server commands.  Once an event has entered
-- the revisioned unit stream, peers must not apply those commands directly:
-- the server publishes the committed unit as an Event Unit delta instead.
-- This keeps an old channel packet from overwriting a newer repair snapshot.
getLiveResourceTarget = function(client, targetEventId)
    local eventState = client and client.GetEventState and client:GetEventState() or client and client.EventState
    local numericTargetEventId = tonumber(targetEventId) or 0
    if type(eventState) ~= "table" or eventState.active ~= true or numericTargetEventId <= 0 then
        return nil, eventState
    end
    return findEventUnitById(eventState.units, numericTargetEventId), eventState
end

local function resolveResourceActorEventId(client, eventState, options)
    local explicit = tonumber(type(options) == "table" and options.actorEventId or nil) or 0
    if explicit > 0 then
        return explicit
    end
    local actor = nil
    if type(client.ResolveControlledEventUnit) == "function" then
        actor = client:ResolveControlledEventUnit(eventState)
    end
    if not actor and type(client.ResolveLocalEventUnit) == "function" then
        actor = client:ResolveLocalEventUnit(eventState)
    end
    return tonumber(actor and actor.eventID) or nil
end

local function presentCommittedResourceTransaction(client, envelope)
    if type(client) ~= "table" or type(envelope) ~= "table"
        or envelope.state ~= "committed"
        or tostring(envelope.operation or ""):sub(1, 15) ~= "event-resource-"
    then
        return false
    end

    local eventState = client.GetEventState and client:GetEventState() or client.EventState
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end
    local outcome = type(envelope.outcome) == "table" and envelope.outcome or {}
    local actionOwnerName = Common.NormalizeName(outcome.actionOwnerName or envelope.originName)
    local localPlayerName = resolveLocalPlayerName()
    local isLocalOrigin = actionOwnerName ~= "" and actionOwnerName == localPlayerName
    local results = type(outcome.resourceResults) == "table" and outcome.resourceResults or {}
    for index = 1, #results do
        local result = results[index]
        if type(result) == "table" then
            local targetEventId = tonumber(result.targetEventId) or 0
            local targetUnit = findEventUnitById(eventState.units, targetEventId)
            result.targetUnit = targetUnit
            if type(result.kill) == "table" then
                result.kill.targetUnit = targetUnit
                result.kill.isBoss = result.kill.isBoss == true or isBossEventUnit(targetUnit)
            end
            if isLocalOrigin then
                grantBossKillValor(client, eventState, result)
                notifyRPEKillAchievement(client, eventState, actionOwnerName, result)
                notifyRPEHealthAchievement(client, eventState, actionOwnerName, result)
            else
                local spellcasting = client.Spellcasting
                if spellcasting and type(spellcasting.ShowInboundResourceDeltaCombatText) == "function"
                    and type(result.resourceDeltas) == "table"
                then
                    spellcasting.ShowInboundResourceDeltaCombatText(client, eventState, targetUnit, result.resourceDeltas)
                end
            end
        end
    end

    if type(client.QueueEventWidgetRefresh) == "function" then
        client:QueueEventWidgetRefresh("resource-transaction")
    end
    refreshTargetingForEventState(client, "resource-transaction")
    return true
end

function Client:HandleEventResourceTransactionTerminal(envelope)
    return presentCommittedResourceTransaction(self, envelope)
end

function Client:HandleEventResourceTransactionProjection(envelope)
    return presentCommittedResourceTransaction(self, envelope)
end

submitEventResourceTransaction = function(client, state, operation, reason, input, targetEventIds, options)
    local transactions = EventTransactions and EventTransactions.Client
    local eventState = client.GetEventState and client:GetEventState() or client.EventState
    if type(transactions) ~= "table" or type(transactions.Create) ~= "function"
        or type(transactions.Submit) ~= "function"
    then
        if Debug and Debug.Error then
            Debug.Error("%s rejected: shared Event transaction service is unavailable.", tostring(operation))
        end
        return false, "missing-event-transaction-service"
    end
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false, "missing-live-event"
    end

    options = type(options) == "table" and options or {}
    local transactionOptions = {
        eventId = eventState.id,
        operation = operation,
        actorEventId = resolveResourceActorEventId(client, eventState, options),
        targetEventIds = targetEventIds,
        turnNumber = eventState.turnNumber,
        tickNumber = eventState.tickNumber,
        baseRevision = eventState.liveUnitRevision,
        stepSensitive = options.stepSensitive == true,
        input = input,
    }
    local record, createReason = transactions:Create(transactionOptions)
    if not record then
        return false, createReason or "transaction-create-failed"
    end
    record.options.onTerminal = function(envelope)
        client:HandleEventResourceTransactionTerminal(envelope)
    end
    local submitted, submitReason = transactions:Submit(record, input)
    if not submitted then
        return false, submitReason or "transaction-submit-failed"
    end
    return true, record.id
end

function Client:SendClientResourceDeltas(state, reason, playerNameOverride, resourceDeltasOverride, targetEventIdOverride, options)
    if not state or state.active ~= true then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA sync skipped: client session is inactive.")
        end
        return false
    end

    if type(ResourceSync.CoalesceResourceDeltas) ~= "function" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA rejected: resource normalization is unavailable.")
        end
        return false, "resource-sync-unavailable"
    end
    local resourceDeltas = ResourceSync.CoalesceResourceDeltas(resourceDeltasOverride)
    local targetEventId = tonumber(targetEventIdOverride) or 0
    local targetUnit = getLiveResourceTarget(self, targetEventId)
    if not targetUnit then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA rejected: live EventUnit %s is unavailable.", tostring(targetEventId))
        end
        return false, "missing-live-resource-target"
    end
    if type(resourceDeltas) ~= "table" or #resourceDeltas == 0 then
        return false, "empty-resource-deltas"
    end

    local eventState = self.GetEventState and self:GetEventState() or self.EventState
    local input = {
        targetEventId = targetEventId,
        resourceDeltas = resourceDeltas,
        threatUpdates = filterThreatUpdatesForEvent(
            type(options) == "table" and options.threatUpdates or nil,
            eventState
        ),
        reason = tostring(reason or "resource-delta"),
    }
    return submitEventResourceTransaction(
        self,
        state,
        "event-resource-delta",
        reason,
        input,
        { targetEventId },
        options
    )
end

function Client:SendClientResourceDeltaBatch(state, reason, playerNameOverride, targetedResourceDeltasOverride, options)
    if not state or state.active ~= true then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA_BATCH sync skipped: client session is inactive.")
        end
        return false
    end

    if type(ResourceSync.CoalesceTargetedResourceDeltas) ~= "function" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE_DELTA_BATCH rejected: resource normalization is unavailable.")
        end
        return false, "resource-sync-unavailable"
    end
    local targetedResourceDeltas = ResourceSync.CoalesceTargetedResourceDeltas(targetedResourceDeltasOverride)
    if type(targetedResourceDeltas) ~= "table" or #targetedResourceDeltas == 0 then
        return false, "empty-targeted-resource-deltas"
    end
    local targetEventIds = {}
    local seenTargets = {}
    for index = 1, #targetedResourceDeltas do
        local targetEventId = tonumber(targetedResourceDeltas[index] and targetedResourceDeltas[index].targetEventId) or 0
        if targetEventId > 0 and not seenTargets[targetEventId] then
            seenTargets[targetEventId] = true
            if not getLiveResourceTarget(self, targetEventId) then
                return false, "missing-live-resource-target"
            end
            targetEventIds[#targetEventIds + 1] = targetEventId
        end
    end
    local eventState = self.GetEventState and self:GetEventState() or self.EventState
    return submitEventResourceTransaction(
        self,
        state,
        "event-resource-batch",
        reason,
        {
            targetedResourceDeltas = targetedResourceDeltas,
            threatUpdates = filterThreatUpdatesForEvent(
                type(options) == "table" and options.threatUpdates or nil,
                eventState
            ),
            reason = tostring(reason or "resource-delta-batch"),
        },
        targetEventIds,
        options
    )
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

    local eventState = self:GetEventState()
    local targetEventId = tonumber(arguments and arguments[4]) or 0
    if targetEventId > 0
        or (eventState and math.max(0, math.floor(tonumber(eventState.liveUnitRevision) or 0)) > 0)
    then
        -- A targeted live replace is projected only from EVENT_TX_COMMIT.
        return true
    end
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

    if type(ResourceSync.NormalizeResources) ~= "function" then
        if Debug and Debug.Error then
            Debug.Error("RESOURCE receive rejected: resource normalization is unavailable.")
        end
        return false
    end
    local resources = ResourceSync.NormalizeResources(resourcePayload)
    local targetUnitIsPlayer = false
    local resourceOwnerName = playerName
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
        if shouldRefreshActionBarSlotsForTarget(self, eventState, nil, targetEventId, playerName) then
            if type(self.QueueActionBarRefresh) == "function" then
                self:QueueActionBarRefresh("resource-received")
            end
        end
        if shouldRefreshCompanionBarsForTarget(self, eventState, nil, targetEventId)
            and type(self.QueueActionBarCompanionBarsRefresh) == "function"
        then
            self:QueueActionBarCompanionBarsRefresh("resource-received", { immediate = true })
        end
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
