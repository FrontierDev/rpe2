local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Internal = Addon.Internal or {}
Addon.UI = Addon.UI or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI or {}
local Spellcasting = Client.Spellcasting
local UI = Addon.UI or {}
local Common = Addon.Utils.Common or {}
local Lookup = Addon.Utils.Lookup or {}
local Comms = Addon.Internal.Comms or {}
local Debug = Addon.Debug
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal.Registry or {}
local ResourceSync = Comms.ResourceSync or {}
local Ruleset = Addon.Internal.Ruleset or {}
Client.VisiblePlayerTooltipRefreshQueued = Client.VisiblePlayerTooltipRefreshQueued or false
Client.VisualRefreshFlushQueued = Client.VisualRefreshFlushQueued or false
Client.PendingEventWidgetRefreshTargetEventIds = Client.PendingEventWidgetRefreshTargetEventIds or {}
Client.PendingEventWidgetStructuralRefresh = Client.PendingEventWidgetStructuralRefresh or false
Client.PendingActionBarCompanionBarsRefreshImmediate = Client.PendingActionBarCompanionBarsRefreshImmediate or false
Client.RecentAttackersByEventId = Client.RecentAttackersByEventId or {}
Client.SpellImpactHistoryByEventId = Client.SpellImpactHistoryByEventId or {}

local DEFAULT_MAX_EVENT_UNITS = 5
local DEFAULT_TARGET_SELECTION_GROUP = "default"
local SPELLCAST_SLOW_TOTAL_MS = 100
local SPELLCAST_SLOW_HELPER_MS = 25

local function getTimings()
    return Addon.Debug and Addon.Debug.Timings or nil
end

local function logEventTimingParts(label, parts, totalElapsed, threshold)
    local timings = getTimings()
    if type(timings) == "table" and type(timings.LogParts) == "function" then
        return timings:LogParts(label, "event-visual-phase", parts, totalElapsed, threshold)
    end

    return false
end

local function getNowMilliseconds()
    if type(GetTimePreciseSec) == "function" then
        return GetTimePreciseSec() * 1000
    end

    return (GetTime and GetTime() or 0) * 1000
end

local function isSpellcastTimingEnabled()
    return type(Addon.Debug) == "table" and Addon.Debug.SpellcastTiming == true
end

local function ensureSpellcastInternalLoggingEnabled()
    if type(Debug) == "table" and type(Debug.EnsureInternalLevelEnabled) == "function" then
        Debug.EnsureInternalLevelEnabled()
    end
end

local function buildTimingSegment(label, elapsed, threshold)
    local numericElapsed = math.max(0, tonumber(elapsed) or 0)
    local isSlow = numericElapsed >= (tonumber(threshold) or SPELLCAST_SLOW_HELPER_MS)
    return ("%s=%.2fms%s"):format(
        tostring(label or "phase"),
        numericElapsed,
        isSlow and " SLOW" or ""
    ), isSlow
end

local function logSpellcastTimingLine(prefix, context, parts, totalElapsed, threshold)
    if not isSpellcastTimingEnabled() or type(Debug) ~= "table" or type(Debug.Internal) ~= "function" then
        return false
    end

    ensureSpellcastInternalLoggingEnabled()

    local slowThreshold = tonumber(threshold) or SPELLCAST_SLOW_HELPER_MS
    local totalText, totalSlow = buildTimingSegment("total", totalElapsed, slowThreshold)
    local segments = { totalText }
    local hasSlow = totalSlow

    for index = 1, #(parts or {}) do
        local part = parts[index]
        if type(part) == "table" and type(part.label) == "string" then
            local segment, isSlow = buildTimingSegment(part.label, part.elapsed, part.threshold or slowThreshold)
            segments[#segments + 1] = segment
            hasSlow = hasSlow or isSlow
        end
    end

    Debug.Internal(
        "%s%s [%s]: %s",
        hasSlow and "SLOW " or "",
        tostring(prefix or "Spellcast timing"),
        tostring(context or "unknown"),
        table.concat(segments, ", ")
    )
    return true
end

local function getEventClass()
    return Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.Event
        or nil
end

local function getCombat()
    return Addon.Client and Addon.Client.Combat or nil
end

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function enqueueSpellcastPresentationWork(fn, ...)
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        tasks:Enqueue(fn, ...)
        return true
    end

    if C_Timer and C_Timer.After then
        local args = { ... }
        local argCount = select("#", ...)
        C_Timer.After(0, function()
            fn(unpack(args, 1, argCount))
        end)
        return true
    end

    fn(...)
    return true
end

local function emitResolvedHealCombatLog(client, eventState, casterUnit, targetResults, healthResourceRef, spell, spellRef)
    if type(client) ~= "table"
        or type(client.EmitCombatLogEntry) ~= "function"
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or type(casterUnit) ~= "table"
        or type(targetResults) ~= "table"
    then
        return false
    end

    local targetCount = 0
    local amountMin = nil
    local amountMax = nil
    local singleTargetName = nil
    for index = 1, #targetResults do
        local entry = targetResults[index]
        local result = type(entry) == "table" and entry.result or nil
        local targetUnit = type(entry) == "table" and entry.targetUnit or nil
        local amount = math.max(0, math.floor(tonumber(type(result) == "table" and result.amount or 0) or 0))
        local resultType = tostring(type(result) == "table" and result.resultType or "")
        if type(targetUnit) == "table" and amount > 0 and resultType ~= "invalid" then
            targetCount = targetCount + 1
            if targetCount == 1 then
                singleTargetName = tostring(targetUnit.name or "Unknown")
            end
            if amountMin == nil or amount < amountMin then
                amountMin = amount
            end
            if amountMax == nil or amount > amountMax then
                amountMax = amount
            end
        end
    end

    if targetCount <= 0 or amountMin == nil or amountMax == nil then
        return false
    end

    local iconTexture, labelText, accentColor = client:ResolveCombatLogResourcePresentation(healthResourceRef)
    return client:EmitCombatLogEntry({
        eventId = eventState.id,
        entryType = "heal",
        casterDisplayName = tostring(casterUnit.name or "Unknown"),
        targetDisplayName = targetCount > 1 and ("%d targets"):format(targetCount) or singleTargetName,
        targetCount = targetCount,
        amountMin = amountMin,
        amountMax = amountMax,
        iconTexture = iconTexture,
        spellIconTexture = type(client.ResolveCombatLogSpellIcon) == "function" and client:ResolveCombatLogSpellIcon(spell, spellRef) or nil,
        labelText = labelText,
        accentColor = accentColor,
    })
end

local function emitInterruptCombatLog(client, eventState, casterUnit, targetUnit, result, spellRef)
    if type(client) ~= "table"
        or type(client.EmitCombatLogEntry) ~= "function"
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or type(casterUnit) ~= "table"
        or type(targetUnit) ~= "table"
        or type(result) ~= "table"
        or tostring(result.effectType or "") ~= "interrupt"
        or result.applied ~= true
    then
        return false
    end

    local interruptedSpellRef = tostring(result.interruptedSpellRef or "")
    local interruptedSpellName = tostring(result.interruptedSpellName or "")
    if interruptedSpellName == "" and interruptedSpellRef ~= "" and type(Registry.ResolveSpellName) == "function" then
        interruptedSpellName = tostring(Registry:ResolveSpellName(interruptedSpellRef) or "")
    end
    if interruptedSpellName == "" then
        interruptedSpellName = "spellcasting"
    end

    return client:EmitCombatLogEntry({
        eventId = eventState.id,
        entryType = "status",
        casterDisplayName = tostring(casterUnit.name or "Unknown"),
        targetDisplayName = tostring(targetUnit.name or "Unknown"),
        targetCount = 1,
        amountMin = 1,
        amountMax = 1,
        iconTexture = nil,
        labelText = interruptedSpellName,
        spellIconTexture = type(client.ResolveCombatLogSpellIcon) == "function"
            and client:ResolveCombatLogSpellIcon(nil, interruptedSpellRef ~= "" and interruptedSpellRef or spellRef)
            or nil,
        detailText = ("Interrupted %s."):format(interruptedSpellName),
        accentColor = "ffcf6d2a",
    })
end

local refreshVisiblePlayerTooltipImmediate
local enqueueVisualWork

local function ensureDirtyUiRefreshState(targetClient)
    if type(targetClient) ~= "table" then
        return nil
    end

    local state = targetClient.DirtyUiRefreshState
    if type(state) ~= "table" then
        state = {
            actionBarSlots = {},
            actionBarAllSlotsDirty = false,
            actionBarStructuralDirty = false,
            actionBarRevision = 0,
            companionBarsDirty = false,
            companionBarsImmediate = false,
            eventPortraits = {},
            targetingDirty = false,
            visibleTooltipPayload = nil,
            visibleTooltipsDirty = false,
        }
        targetClient.DirtyUiRefreshState = state
    end

    state.actionBarSlots = type(state.actionBarSlots) == "table" and state.actionBarSlots or {}
    state.eventPortraits = type(state.eventPortraits) == "table" and state.eventPortraits or {}
    return state
end

local function mergeTooltipPayload(targetPayload, payload)
    if type(payload) ~= "table" then
        return targetPayload
    end

    local merged = type(targetPayload) == "table" and targetPayload or {}
    local setKeys = {
        "statRefs",
        "resourceRefs",
        "eventIds",
    }
    for index = 1, #setKeys do
        local key = setKeys[index]
        local values = payload[key]
        if type(values) == "table" then
            merged[key] = type(merged[key]) == "table" and merged[key] or {}
            for valueKey in pairs(values) do
                merged[key][valueKey] = true
            end
            for valueIndex = 1, #values do
                merged[key][tonumber(values[valueIndex]) or values[valueIndex]] = true
            end
        end
    end

    if payload.auraListChanged == true then
        merged.auraListChanged = true
    end
    if payload.spellAvailabilityChanged == true then
        merged.spellAvailabilityChanged = true
    end
    if payload.descriptionContextChanged == true then
        merged.descriptionContextChanged = true
    end

    return merged
end

local function mergeQueuedEventTargetIds(targetClient, eventIds)
    if type(targetClient) ~= "table" or type(eventIds) ~= "table" then
        return false
    end

    local merged = false
    targetClient.PendingEventWidgetRefreshTargetEventIds = targetClient.PendingEventWidgetRefreshTargetEventIds or {}
    for index = 1, #eventIds do
        local eventId = tonumber(eventIds[index]) or 0
        if eventId > 0 and targetClient.PendingEventWidgetRefreshTargetEventIds[eventId] ~= true then
            targetClient.PendingEventWidgetRefreshTargetEventIds[eventId] = true
            merged = true
        end
    end

    return merged
end

local function clearQueuedEventTargetIds(targetClient)
    if type(targetClient) ~= "table" then
        return {}
    end

    local pending = targetClient.PendingEventWidgetRefreshTargetEventIds or {}
    targetClient.PendingEventWidgetRefreshTargetEventIds = {}
    return pending
end

local function hasVisiblePlayerTooltip()
    local tooltip = _G.GameTooltip
    local trp3Tooltip = _G.TRP3_CharacterTooltip
    local tooltipShown = tooltip and tooltip.IsShown and tooltip:IsShown() or false
    local trp3Shown = trp3Tooltip and trp3Tooltip.IsShown and trp3Tooltip:IsShown() or false
    return tooltipShown == true or trp3Shown == true
end

local function consumeVisualPhase(targetClient, phase)
    if type(targetClient) ~= "table" then
        return false
    end

    local timingStartTime = getNowMilliseconds()
    local dirtyState = ensureDirtyUiRefreshState(targetClient)
    local eventRefreshQueued = targetClient.EventWidgetRefreshQueued == true
    local actionBarRefreshQueued = targetClient.ActionBarRefreshQueued == true
    local targetingRefreshQueued = targetClient.TargetingWidgetRefreshQueued == true or (dirtyState and dirtyState.targetingDirty == true)
    local companionBarsRefreshQueued = targetClient.ActionBarCompanionBarsRefreshQueued == true or (dirtyState and dirtyState.companionBarsDirty == true)
    local tooltipRefreshQueued = targetClient.VisiblePlayerTooltipRefreshQueued == true or (dirtyState and dirtyState.visibleTooltipsDirty == true)
    local structuralEventRefresh = targetClient.PendingEventWidgetStructuralRefresh == true
    local eventTargetIds = targetClient.PendingEventWidgetRefreshTargetEventIds or {}
    local hasTargetedEventRefresh = next(eventTargetIds) ~= nil
    local immediateCompanionBars = companionBarsRefreshQueued and (targetClient.PendingActionBarCompanionBarsRefreshImmediate == true or (dirtyState and dirtyState.companionBarsImmediate == true))
    local deferredCompanionBars = companionBarsRefreshQueued and immediateCompanionBars ~= true
    local targetingVisible = type(targetClient.IsTargetingWidgetVisible) == "function" and targetClient:IsTargetingWidgetVisible() or false

    if phase == 1 then
        if actionBarRefreshQueued ~= true then
            return false
        end

        local refreshReason = targetClient.PendingActionBarRefreshReason or "action-bar"
        if type(targetClient.DrainActionBarRefreshWork) == "function" then
            local ran, morePending = targetClient:DrainActionBarRefreshWork(refreshReason)
            if morePending ~= true then
                targetClient.PendingActionBarRefreshReason = nil
                targetClient.ActionBarRefreshQueued = false
            end
            if ran == true then
                logEventTimingParts("phase-1-action-bar", nil, getNowMilliseconds() - timingStartTime, 15)
            end
            return ran == true
        end

        targetClient.PendingActionBarRefreshReason = nil
        targetClient.ActionBarRefreshQueued = false
        if type(targetClient.RefreshActionBarWidget) == "function" then
            targetClient:RefreshActionBarWidget(refreshReason)
            logEventTimingParts("phase-1-action-bar", nil, getNowMilliseconds() - timingStartTime, 15)
            return true
        end
        return false
    end

    if phase == 2 then
        local ran = false
        local timingParts = {}
        if targetingRefreshQueued then
            local targetingStartTime = getNowMilliseconds()
            local refreshReason = targetClient.PendingTargetingWidgetRefreshReason or "targeting"
            targetClient.PendingTargetingWidgetRefreshReason = nil
            targetClient.TargetingWidgetRefreshQueued = false
            if dirtyState then
                dirtyState.targetingDirty = false
            end
            if targetingVisible and type(targetClient.RefreshTargetingWidget) == "function" then
                targetClient:RefreshTargetingWidget(refreshReason)
            end
            timingParts[#timingParts + 1] = {
                label = "targeting",
                elapsedMs = getNowMilliseconds() - targetingStartTime,
                thresholdMs = 15,
            }
            ran = true
        end

        if eventRefreshQueued == true then
            local eventStartTime = getNowMilliseconds()
            local refreshReason = targetClient.PendingEventWidgetRefreshReason or "event"
            targetClient.PendingEventWidgetRefreshReason = nil
            targetClient.EventWidgetRefreshQueued = false
            local targetedEventIds = clearQueuedEventTargetIds(targetClient)
            local shouldRunFullRefresh = structuralEventRefresh or next(targetedEventIds) == nil
            targetClient.PendingEventWidgetStructuralRefresh = false

            local eventState = targetClient.GetEventState and targetClient:GetEventState() or targetClient.EventState
            if eventState and eventState.active == true then
                if type(targetClient.BuildEventWidget) == "function" then
                    targetClient:BuildEventWidget()
                end
                if type(targetClient.ShowEventWidget) == "function" then
                    targetClient:ShowEventWidget()
                end
                if shouldRunFullRefresh and type(targetClient.RefreshEventWidget) == "function" then
                    targetClient:RefreshEventWidget(refreshReason)
                elseif type(targetClient.RefreshEventWidgetPortraits) == "function" then
                    targetClient:RefreshEventWidgetPortraits(targetedEventIds, refreshReason)
                end
            elseif type(targetClient.HideEventWidget) == "function" then
                targetClient:HideEventWidget()
            end

            timingParts[#timingParts + 1] = {
                label = "event-widget",
                elapsedMs = getNowMilliseconds() - eventStartTime,
                thresholdMs = 15,
            }
            if type(targetClient.FlushDeferredConsumablePrompt) == "function" then
                enqueueVisualWork(function(nextClient, currentEventState)
                    if type(nextClient) ~= "table" or type(currentEventState) ~= "table" or currentEventState.active ~= true then
                        return
                    end

                    nextClient:FlushDeferredConsumablePrompt(currentEventState, "event_start")
                end, targetClient, eventState)
            end
            ran = true
        end

        if ran then
            logEventTimingParts("phase-2-targeting-event", timingParts, getNowMilliseconds() - timingStartTime, 20)
        end

        return ran
    end

    if phase == 3 then
        local ran = false
        if immediateCompanionBars or deferredCompanionBars then
            local companionStartTime = getNowMilliseconds()
            local refreshReason = targetClient.PendingActionBarCompanionBarsRefreshReason or "action-bar-companion"
            targetClient.PendingActionBarCompanionBarsRefreshReason = nil
            targetClient.ActionBarCompanionBarsRefreshQueued = false
            targetClient.PendingActionBarCompanionBarsRefreshImmediate = false
            if dirtyState then
                dirtyState.companionBarsDirty = false
                dirtyState.companionBarsImmediate = false
            end
            if type(targetClient.RefreshActionBarCompanionBars) == "function" then
                targetClient:RefreshActionBarCompanionBars(refreshReason)
            end
            logEventTimingParts(
                immediateCompanionBars and "phase-3-companion-bars-immediate" or "phase-3-companion-bars",
                nil,
                getNowMilliseconds() - companionStartTime,
                15
            )
            ran = true
        end

        return ran
    end

    if phase == 4 then
        if tooltipRefreshQueued ~= true then
            return false
        end

        local tooltipStartTime = getNowMilliseconds()
        local refreshReason = targetClient.PendingVisiblePlayerTooltipRefreshReason or "tooltip"
        local payload = dirtyState and dirtyState.visibleTooltipPayload or nil
        targetClient.PendingVisiblePlayerTooltipRefreshReason = nil
        targetClient.VisiblePlayerTooltipRefreshQueued = false
        if dirtyState then
            dirtyState.visibleTooltipsDirty = false
            dirtyState.visibleTooltipPayload = nil
        end
        if hasVisiblePlayerTooltip() then
            refreshVisiblePlayerTooltipImmediate(refreshReason, payload)
        end
        logEventTimingParts("phase-4-tooltip", nil, getNowMilliseconds() - tooltipStartTime, 15)
        return true
    end

    return false
end

local function hasQueuedVisualPhase(targetClient, phase)
    if type(targetClient) ~= "table" then
        return false
    end

    if phase == 1 then
        return targetClient.ActionBarRefreshQueued == true
    end
    if phase == 2 then
        local dirtyState = ensureDirtyUiRefreshState(targetClient)
        return targetClient.TargetingWidgetRefreshQueued == true
            or (dirtyState and dirtyState.targetingDirty == true)
            or targetClient.EventWidgetRefreshQueued == true
    end
    if phase == 3 then
        local dirtyState = ensureDirtyUiRefreshState(targetClient)
        return targetClient.ActionBarCompanionBarsRefreshQueued == true
            or (dirtyState and dirtyState.companionBarsDirty == true)
    end
    if phase == 4 then
        local dirtyState = ensureDirtyUiRefreshState(targetClient)
        return targetClient.VisiblePlayerTooltipRefreshQueued == true
            or (dirtyState and dirtyState.visibleTooltipsDirty == true)
    end

    return false
end

local function queueNextVisualPhase(targetClient)
    if type(targetClient) ~= "table" then
        return false
    end

    for phase = 1, 4 do
        if hasQueuedVisualPhase(targetClient, phase) then
            targetClient.VisualRefreshFlushQueued = true
            targetClient.PendingVisualRefreshPhase = phase
            return enqueueVisualWork(function(nextClient)
                if type(nextClient) ~= "table" then
                    return
                end

                nextClient.VisualRefreshFlushQueued = false
                local currentPhase = tonumber(nextClient.PendingVisualRefreshPhase) or 1
                nextClient.PendingVisualRefreshPhase = nil
                consumeVisualPhase(nextClient, currentPhase)
                queueNextVisualPhase(nextClient)
            end, targetClient)
        end
    end

    targetClient.PendingVisualRefreshPhase = nil
    return false
end

enqueueVisualWork = function(fn, ...)
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        tasks:Enqueue(fn, ...)
        return true
    end

    if C_Timer and C_Timer.After then
        local args = { ... }
        local argCount = select("#", ...)
        C_Timer.After(0, function()
            fn(unpack(args, 1, argCount))
        end)
        return true
    end

    fn(...)
    return true
end

local function flushQueuedVisualRefreshes(targetClient)
    return queueNextVisualPhase(targetClient)
end

function Client:QueueVisualRefreshFlush()
    if self.VisualRefreshFlushQueued == true then
        return true
    end

    self.VisualRefreshFlushQueued = true
    return enqueueVisualWork(function(targetClient)
        if type(targetClient) ~= "table" then
            return
        end

        targetClient.VisualRefreshFlushQueued = false
        flushQueuedVisualRefreshes(targetClient)
    end, self)
end

function Client:QueueEventWidgetTargetedRefresh(reason, eventIds)
    mergeQueuedEventTargetIds(self, eventIds)
    self.PendingEventWidgetRefreshReason = tostring(reason or self.PendingEventWidgetRefreshReason or "event")
    self.EventWidgetRefreshQueued = true
    return self:QueueVisualRefreshFlush()
end

local function trimText(value)
    local text = tostring(value or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function buildImplicitTargetGroupKey(policy)
    local targetDisposition = tostring(policy and policy.targetDisposition or "enemy")
    local targetType = tostring(policy and policy.type or "single")
    local requirement = policy and policy.requiresTarget == true and "required" or "optional"
    local minTargets = math.max(0, tonumber(policy and policy.minTargets) or 0)
    local maxTargets = math.max(minTargets, tonumber(policy and policy.maxTargets) or 0)
    local selfCast = policy and policy.disableSelfCast == true and "no_self" or "self_ok"
    return ("auto_%s_%s_%s_%d_%d_%s"):format(targetDisposition, targetType, requirement, minTargets, maxTargets, selfCast)
end

local function buildTargetGroupLabel(groupKey, groupIndex, groupCount, policy)
    local normalizedGroupKey = trimText(groupKey)
    if normalizedGroupKey == "" then
        normalizedGroupKey = DEFAULT_TARGET_SELECTION_GROUP
    end

    if string.sub(normalizedGroupKey, 1, 5) == "auto_" then
        local targetDisposition = tostring(policy and policy.targetDisposition or "enemy")
        local maxTargets = math.max(0, tonumber(policy and policy.maxTargets) or 0)
        local isOptional = policy and policy.requiresTarget ~= true
        local prefix = "Enemy"
        if targetDisposition == "ally" then
            prefix = "Ally"
        elseif targetDisposition == "any" then
            prefix = "Mixed"
        end

        if isOptional then
            prefix = "Optional " .. prefix
        end

        return prefix .. " " .. (maxTargets == 1 and "Target" or "Targets")
    end

    if groupCount <= 1 and normalizedGroupKey == DEFAULT_TARGET_SELECTION_GROUP then
        return "Targets"
    end

    local label = string.gsub(normalizedGroupKey, "[-_]+", " ")
    label = string.gsub(label, "(%w)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end)
    return label
end

local function cloneTargetPolicy(policy)
    local combat = getCombat()
    if type(policy) ~= "table" then
        return nil
    end

    if combat and combat.NormalizeTarget then
        return combat.NormalizeTarget(policy)
    end

    return {
        type = tostring(policy.type or "single"),
        requiresTarget = policy.requiresTarget == true,
        targetDisposition = tostring(policy.targetDisposition or "enemy"),
        minTargets = math.max(0, tonumber(policy.minTargets) or 0),
        maxTargets = math.max(0, tonumber(policy.maxTargets) or 0),
        allowDeadTargets = policy.allowDeadTargets == true,
        disableSelfCast = policy.disableSelfCast == true,
    }
end

local function mergeTargetPolicies(existingPolicy, nextPolicy)
    local current = cloneTargetPolicy(existingPolicy) or {}
    local incoming = cloneTargetPolicy(nextPolicy) or {}
    local currentDisposition = tostring(current.targetDisposition or "enemy")
    local incomingDisposition = tostring(incoming.targetDisposition or "enemy")
    if currentDisposition ~= incomingDisposition then
        return nil
    end

    if (current.disableSelfCast == true) ~= (incoming.disableSelfCast == true) then
        return nil
    end

    return {
        type = (tostring(current.type or "single") == "multi" or tostring(incoming.type or "single") == "multi") and "multi" or "single",
        requiresTarget = current.requiresTarget == true or incoming.requiresTarget == true,
        targetDisposition = currentDisposition,
        minTargets = math.max(0, math.max(tonumber(current.minTargets) or 0, tonumber(incoming.minTargets) or 0)),
        maxTargets = math.max(0, math.max(tonumber(current.maxTargets) or 0, tonumber(incoming.maxTargets) or 0)),
        allowDeadTargets = current.allowDeadTargets == true or incoming.allowDeadTargets == true,
        disableSelfCast = current.disableSelfCast == true,
    }
end

local function formatTurnCount(turnCount)
    local numericTurns = math.max(0, tonumber(turnCount) or 0)
    local displayTurns = math.max(1, math.ceil(numericTurns))
    if displayTurns == 1 then
        return "1 turn"
    end

    return ("%d turns"):format(displayTurns)
end

local function getEventHistoryBucket(historyByEventId, eventId, createIfMissing)
    local normalizedEventId = type(eventId) == "string" and eventId or ""
    if normalizedEventId == "" then
        return nil
    end

    local bucket = historyByEventId[normalizedEventId]
    if bucket or not createIfMissing then
        return bucket
    end

    bucket = {}
    historyByEventId[normalizedEventId] = bucket
    return bucket
end

local function cloneResourceDeltas(resourceDeltas)
    local cloned = {}
    for index = 1, #(resourceDeltas or {}) do
        local entry = resourceDeltas[index]
        if type(entry) == "table" and type(entry.resourceRef) == "string" and entry.resourceRef ~= "" then
            cloned[#cloned + 1] = {
                resourceRef = entry.resourceRef,
                delta = tonumber(entry.delta) or 0,
                currentValue = tonumber(entry.currentValue) or 0,
                maxValue = tonumber(entry.maxValue) or 0,
            }
        end
    end
    return cloned
end

local function cloneSpellImpactOperation(operation)
    if type(operation) ~= "table" then
        return nil
    end

    return {
        effectType = tostring(operation.effectType or ""),
        resourceDeltas = cloneResourceDeltas(operation.resourceDeltas),
        auraRef = operation.auraRef,
        stacks = tonumber(operation.stacks) or 0,
        turns = tonumber(operation.turns) or 0,
        powerLevel = tonumber(operation.powerLevel) or 0,
        casterEventId = tonumber(operation.casterEventId) or 0,
        targetEventId = tonumber(operation.targetEventId) or 0,
    }
end

function Spellcasting.RecordRecentAttacker(client, eventState, attackerUnit, targetUnit)
    local eventId = type(eventState) == "table" and tostring(eventState.id or "") or ""
    local attackerEventId = tonumber(attackerUnit and attackerUnit.eventID) or 0
    local targetEventId = tonumber(targetUnit and targetUnit.eventID) or 0
    if eventId == "" or attackerEventId <= 0 or targetEventId <= 0 then
        return false
    end

    client.RecentAttackersByEventId = client.RecentAttackersByEventId or {}
    local eventBucket = getEventHistoryBucket(client.RecentAttackersByEventId, eventId, true)
    local history = eventBucket[targetEventId] or {}
    local nextHistory = { attackerEventId }
    for index = 1, #history do
        local candidate = tonumber(history[index]) or 0
        if candidate > 0 and candidate ~= attackerEventId then
            nextHistory[#nextHistory + 1] = candidate
        end
        if #nextHistory >= 8 then
            break
        end
    end
    eventBucket[targetEventId] = nextHistory
    return true
end

function Spellcasting.GetRecentAttackersForTarget(client, eventState, targetEventId)
    local eventId = type(eventState) == "table" and tostring(eventState.id or "") or ""
    local numericTargetEventId = tonumber(targetEventId) or 0
    if eventId == "" or numericTargetEventId <= 0 then
        return {}
    end

    local eventBucket = getEventHistoryBucket(client.RecentAttackersByEventId or {}, eventId, false)
    local history = eventBucket and eventBucket[numericTargetEventId] or nil
    local normalized = {}
    for index = 1, #(history or {}) do
        local attackerEventId = tonumber(history[index]) or 0
        if attackerEventId > 0 then
            normalized[#normalized + 1] = attackerEventId
        end
    end
    return normalized
end

function Spellcasting.RecordSpellImpact(client, eventState, casterUnit, targetUnit, spellRef, result)
    if type(result) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local effectType = tostring(result.effectType or "")
    if effectType ~= "damage"
        and effectType ~= "heal"
        and effectType ~= "resource"
        and effectType ~= "apply_aura"
        and effectType ~= "remove_aura"
    then
        return false
    end

    local eventId = tostring(eventState.id or "")
    local targetEventId = tonumber(targetUnit and targetUnit.eventID) or 0
    local casterEventId = tonumber(casterUnit and casterUnit.eventID) or 0
    if eventId == "" or targetEventId <= 0 or casterEventId <= 0 then
        return false
    end

    client.SpellImpactHistoryByEventId = client.SpellImpactHistoryByEventId or {}
    local eventBucket = getEventHistoryBucket(client.SpellImpactHistoryByEventId, eventId, true)
    local history = eventBucket[targetEventId] or {}

    local operation = {
        effectType = effectType,
        resourceDeltas = cloneResourceDeltas(result.resourceDeltas),
        auraRef = type(result.auraEntry) == "table" and result.auraEntry.auraRef or nil,
        stacks = tonumber(result.stacks or (result.auraEntry and result.auraEntry.stacks)) or 0,
        turns = tonumber(result.duration or (result.auraEntry and result.auraEntry.turnsRemaining)) or 0,
        powerLevel = tonumber(result.powerLevel or (result.auraEntry and result.auraEntry.powerLevel)) or 0,
        casterEventId = tonumber(type(result.auraEntry) == "table" and result.auraEntry.casterEventId or casterEventId) or casterEventId,
        targetEventId = tonumber(type(result.auraEntry) == "table" and result.auraEntry.targetEventId or targetEventId) or targetEventId,
    }

    local latest = history[#history]
    local turnNumber = tonumber(eventState.turnNumber) or 0
    local tickNumber = tonumber(eventState.tickNumber) or 0
    if type(latest) == "table"
        and latest.spellRef == spellRef
        and latest.casterEventId == casterEventId
        and latest.turnNumber == turnNumber
        and latest.tickNumber == tickNumber
    then
        latest.operations[#latest.operations + 1] = operation
    else
        history[#history + 1] = {
            spellRef = spellRef,
            casterEventId = casterEventId,
            targetEventId = targetEventId,
            turnNumber = turnNumber,
            tickNumber = tickNumber,
            operations = { operation },
        }
    end

    while #history > 12 do
        table.remove(history, 1)
    end
    eventBucket[targetEventId] = history
    return true
end

function Spellcasting.RevertLastSpellImpact(client, eventState, targetUnit, context)
    local eventId = type(eventState) == "table" and tostring(eventState.id or "") or ""
    local targetEventId = tonumber(targetUnit and targetUnit.eventID) or 0
    if eventId == "" or targetEventId <= 0 then
        return false, nil
    end

    local eventBucket = getEventHistoryBucket(client.SpellImpactHistoryByEventId or {}, eventId, false)
    local history = eventBucket and eventBucket[targetEventId] or nil
    local bundle = type(history) == "table" and history[#history] or nil
    if type(bundle) ~= "table" or type(bundle.operations) ~= "table" or #bundle.operations == 0 then
        return false, nil
    end

    local reverted = {
        spellRef = bundle.spellRef,
        operationCount = 0,
    }
    local auraManager = client.Spellcasting and client.Spellcasting.AuraManager or nil
    local combat = getCombat()
    for index = #bundle.operations, 1, -1 do
        local operation = cloneSpellImpactOperation(bundle.operations[index])
        local effectType = tostring(operation and operation.effectType or "")
        if effectType == "damage" or effectType == "heal" or effectType == "resource" then
            for deltaIndex = 1, #(operation.resourceDeltas or {}) do
                local deltaEntry = operation.resourceDeltas[deltaIndex]
                if combat and type(combat.ApplyResourceDelta) == "function" then
                    combat:ApplyResourceDelta(targetUnit, deltaEntry.resourceRef, -(tonumber(deltaEntry.delta) or 0), context)
                end
            end
            reverted.operationCount = reverted.operationCount + 1
        elseif effectType == "apply_aura" and auraManager and type(auraManager.RemoveAuraStacksFromContext) == "function" then
            auraManager:RemoveAuraStacksFromContext(client, context, operation.auraRef, math.max(1, operation.stacks), operation.casterEventId, operation.targetEventId)
            reverted.operationCount = reverted.operationCount + 1
        elseif effectType == "remove_aura" and auraManager and type(auraManager.ApplyAuraFromContext) == "function" then
            auraManager:ApplyAuraFromContext(client, context, operation.auraRef, math.max(1, operation.stacks), math.max(1, operation.turns), operation.powerLevel)
            reverted.operationCount = reverted.operationCount + 1
        end
    end

    table.remove(history, #history)
    eventBucket[targetEventId] = history
    return reverted.operationCount > 0, reverted
end

function Client:RecordRecentAttacker(eventState, attackerUnit, targetUnit)
    return Spellcasting.RecordRecentAttacker(self, eventState, attackerUnit, targetUnit)
end

function Client:GetRecentAttackersForTarget(eventState, targetEventId)
    return Spellcasting.GetRecentAttackersForTarget(self, eventState, targetEventId)
end

function Client:RecordSpellImpact(eventState, casterUnit, targetUnit, spellRef, result)
    return Spellcasting.RecordSpellImpact(self, eventState, casterUnit, targetUnit, spellRef, result)
end

function Spellcasting.NormalizeName(name)
    if Common.NormalizeName then
        return Common.NormalizeName(name)
    end

    return type(name) == "string" and name or ""
end

function Spellcasting.GetLocalPlayerName()
    return Spellcasting.NormalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil)
end

function Spellcasting.BuildSendMetadata(opcode)
    return {
        opcode = opcode,
        scope = "client",
    }
end

function Spellcasting.GetActiveSpellcastContext(self)
    local sessionState = self and self.GetState and self:GetState() or nil
    local eventState = self and self.GetEventState and self:GetEventState() or nil
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return nil
    end

    return sessionState, eventState
end

function Spellcasting.ResolveSessionChannelId(sessionState)
    if not sessionState then
        return nil
    end

    local channelId = nil
    if type(Comms.ResolveChannelId) == "function" and type(sessionState.channelName) == "string" and sessionState.channelName ~= "" then
        channelId = Comms:ResolveChannelId(sessionState.channelName)
    end

    if (channelId == nil or channelId == "") then
        channelId = sessionState.channelId
    end

    if channelId ~= nil and channelId ~= "" then
        sessionState.channelId = channelId
    end

    return channelId or nil
end

function Spellcasting.GetEventCastBucket(self, eventId, createIfMissing)
    local normalizedEventId = type(eventId) == "string" and eventId or ""
    if normalizedEventId == "" then
        return nil
    end

    self.ActiveSpellcastsByEventId = self.ActiveSpellcastsByEventId or {}
    local bucket = self.ActiveSpellcastsByEventId[normalizedEventId]
    if bucket or not createIfMissing then
        return bucket
    end

    bucket = {}
    self.ActiveSpellcastsByEventId[normalizedEventId] = bucket
    return bucket
end

function Spellcasting.ClearEventCastBucket(self, eventId)
    local normalizedEventId = type(eventId) == "string" and eventId or ""
    if normalizedEventId == "" or type(self.ActiveSpellcastsByEventId) ~= "table" then
        return
    end

    self.ActiveSpellcastsByEventId[normalizedEventId] = nil
end

function Spellcasting.GetCastEntry(self, eventId, casterEventId)
    local bucket = Spellcasting.GetEventCastBucket(self, eventId, false)
    if not bucket then
        return nil
    end

    return bucket[tonumber(casterEventId) or 0]
end

function Spellcasting.SetCastEntry(self, eventId, casterEventId, value)
    local numericCasterEventId = tonumber(casterEventId) or 0
    if numericCasterEventId <= 0 then
        return nil
    end

    local bucket = Spellcasting.GetEventCastBucket(self, eventId, value ~= nil)
    if not bucket then
        return nil
    end

    bucket[numericCasterEventId] = value
    return value
end

function Spellcasting.RemoveCastEntry(self, eventId, casterEventId)
    local bucket = Spellcasting.GetEventCastBucket(self, eventId, false)
    if not bucket then
        return nil
    end

    local numericCasterEventId = tonumber(casterEventId) or 0
    if numericCasterEventId <= 0 then
        return nil
    end

    local previous = bucket[numericCasterEventId]
    bucket[numericCasterEventId] = nil
    if next(bucket) == nil then
        Spellcasting.ClearEventCastBucket(self, eventId)
    end

    return previous
end

function Spellcasting.FindPlayerEventUnit(units, playerName)
    local normalizedPlayerName = Spellcasting.NormalizeName(playerName)
    if normalizedPlayerName == "" then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if unit and unit.isPlayer == true then
            local candidateName = Spellcasting.NormalizeName(unit.ownerID or unit.controllerID or unit.name)
            if candidateName == normalizedPlayerName then
                return unit, index
            end
        end
    end

    return nil
end

function Spellcasting.ResolveControllerPlayerUnit(eventState, casterUnit)
    local controllerId = tonumber(casterUnit and casterUnit.controllerID) or 0
    if controllerId <= 0 or type(eventState) ~= "table" then
        return nil
    end

    for index = 1, #((eventState.units) or {}) do
        local unit = eventState.units[index]
        if unit and unit.isPlayer == true and tonumber(unit.eventID) == controllerId then
            return unit
        end
    end

    local controllerName = Spellcasting.NormalizeName(casterUnit and casterUnit.controllerID or nil)
    if controllerName == "" then
        return nil
    end

    return Spellcasting.FindPlayerEventUnit(eventState.units, controllerName)
end

function Spellcasting.NormalizeTurnCount(turnCount)
    local numericTurns = tonumber(turnCount)
    if numericTurns == nil or numericTurns <= 0 then
        return nil
    end

    return math.max(1, math.ceil(numericTurns))
end

function Spellcasting.NormalizeRefundFraction(refundOnInterrupt)
    local numericRefund = tonumber(refundOnInterrupt) or 0
    if numericRefund <= 0 then
        return 0
    end

    if numericRefund > 1 then
        numericRefund = numericRefund / 100
    end

    if numericRefund < 0 then
        numericRefund = 0
    elseif numericRefund > 1 then
        numericRefund = 1
    end

    return numericRefund
end

local function findResourceEntry(resources, resourceRef)
    local normalizedRef = type(resourceRef) == "string" and resourceRef or ""
    if normalizedRef == "" then
        return nil
    end

    for index = 1, #(resources or {}) do
        local entry = resources[index]
        if entry and entry.resourceRef == normalizedRef then
            return entry
        end
    end

    return nil
end

local function buildResourceEntriesByRef(resources)
    local entriesByRef = {}

    for index = 1, #(resources or {}) do
        local entry = resources[index]
        local resourceRef = type(entry) == "table" and tostring(entry.resourceRef or "") or ""
        if resourceRef ~= "" and entriesByRef[resourceRef] == nil then
            entriesByRef[resourceRef] = entry
        end
    end

    return entriesByRef
end

local function collectCostResourceRefs(costs)
    local resourceRefs = {}
    local seen = {}

    for index = 1, #(costs or {}) do
        local resourceRef = type(costs[index]) == "table" and tostring(costs[index].resourceRef or "") or ""
        if resourceRef ~= "" and seen[resourceRef] ~= true then
            seen[resourceRef] = true
            resourceRefs[#resourceRefs + 1] = resourceRef
        end
    end

    return resourceRefs
end

local function buildPlayerResolvedResourceRowsByRef(resourceRefs)
    local rowsByRef = {}
    local rows = type(Profile.GetResolvedResourceRowsByRefs) == "function"
        and Profile.GetResolvedResourceRowsByRefs(resourceRefs)
        or nil

    for index = 1, #(rows or {}) do
        local row = rows[index]
        local resourceRef = type(row) == "table" and tostring(row.ref or "") or ""
        if resourceRef ~= "" then
            rowsByRef[resourceRef] = row
        end
    end

    return rowsByRef
end

local resolveSpellcastingResourceTable

local function buildSpellResourceContext(target, costs, options)
    if type(target) ~= "table" then
        return nil
    end

    options = type(options) == "table" and options or {}
    local resources = options.resources
    if type(resources) ~= "table" then
        resources = resolveSpellcastingResourceTable(target, {
            applyFallbackToUnit = options.applyFallbackToUnit == true,
        })
    end
    if type(resources) ~= "table" then
        return nil
    end

    local resourceRefs = options.resourceRefs
    if type(resourceRefs) ~= "table" then
        resourceRefs = collectCostResourceRefs(costs)
    end

    local context = {
        target = target,
        resources = resources,
        entriesByRef = buildResourceEntriesByRef(resources),
        costs = costs,
    }

    if target.isPlayer == true and #resourceRefs > 0 then
        context.resourceRowsByRef = buildPlayerResolvedResourceRowsByRef(resourceRefs)
    else
        context.resourceRowsByRef = {}
    end

    return context
end

local function resolveSpellResourceCostAmounts(target, costs, context)
    local resolvedAmountsByIndex = {}
    local resolvedAmountsByRef = {}

    for index = 1, #(costs or {}) do
        local cost = costs[index]
        local resourceRef = type(cost) == "table" and tostring(cost.resourceRef or "") or ""
        local amount = Spellcasting.ResolveSpellResourceCostAmount(target, cost, context)
        resolvedAmountsByIndex[index] = amount
        if resourceRef ~= "" and amount > 0 then
            resolvedAmountsByRef[resourceRef] = (resolvedAmountsByRef[resourceRef] or 0) + amount
        end
    end

    return resolvedAmountsByIndex, resolvedAmountsByRef
end

resolveSpellcastingResourceTable = function(target, options)
    if type(target) ~= "table" then
        return nil
    end

    options = type(options) == "table" and options or {}
    if type(Client.ResolveLocalActiveSpellcasterResources) == "function" and target.isPlayer == true then
        local resources = Client:ResolveLocalActiveSpellcasterResources(nil, target, options)
        if type(resources) == "table" and #resources > 0 then
            return resources
        end
    end

    if type(target.resources) == "table" then
        return target.resources
    end

    return target
end

function Spellcasting.ResolveSpellResourceCostAmount(target, cost, context)
    if type(cost) ~= "table" then
        return 0
    end

    local amountMode = tostring(cost.amountMode or "flat")
    local amount = math.max(0, tonumber(cost.amount) or 0)
    
    if amountMode == "flat" then
        return amount
    end

    local resourceRef = tostring(cost.resourceRef or "")
    local resourceValue = 0

    local eventUnit = type(target) == "table" and target.resources ~= nil and target or nil
    if type(eventUnit) == "table" and eventUnit.isPlayer == true then
        local row = type(context) == "table" and type(context.resourceRowsByRef) == "table" and context.resourceRowsByRef[resourceRef] or nil
        if type(row) ~= "table" and type(Profile.GetResolvedResourceRow) == "function" then
            row = Profile.GetResolvedResourceRow(resourceRef, {
                includeAuraBonuses = true,
            })
        end
        if amountMode == "base_percent" then
            resourceValue = tonumber(row and row.baseResourceValue) or 0
        else
            resourceValue = tonumber(row and row.value) or tonumber(row and row.baseResourceValue) or 0
        end
    else
        local entry = type(context) == "table" and type(context.entriesByRef) == "table" and context.entriesByRef[resourceRef]
            or findResourceEntry(eventUnit and eventUnit.resources or target, resourceRef)
        resourceValue = tonumber(entry and entry.maxValue) or tonumber(entry and entry.currentValue) or 0
    end

    return math.max(0, math.ceil(resourceValue * amount / 100))
end

function Spellcasting.GetSpellResourceCostsForPhase(spell, phase)
    local targetPhase = tostring(phase or "on_cast_end")
    if type(spell) ~= "table" then
        return {}
    end

    spell._resourceCostsByPhase = spell._resourceCostsByPhase or {}
    if type(spell._resourceCostsByPhase[targetPhase]) == "table" then
        return spell._resourceCostsByPhase[targetPhase]
    end

    local costs = {}

    for index = 1, #(spell and spell.resourceCosts or {}) do
        local cost = spell.resourceCosts[index]
        if type(cost) == "table" and tostring(cost.castPhase or "on_cast_end") == targetPhase then
            costs[#costs + 1] = cost
        end
    end

    spell._resourceCostsByPhase[targetPhase] = costs
    return costs
end

function Spellcasting.CanAffordResourceCosts(target, costs, context)
    if type(target) ~= "table" or type(costs) ~= "table" then
        return false
    end

    local resourceContext = type(context) == "table" and context or buildSpellResourceContext(target, costs)
    if type(resourceContext) ~= "table" or type(resourceContext.resources) ~= "table" then
        return false
    end

    local requiredByRef = type(resourceContext.resolvedAmountsByRef) == "table" and resourceContext.resolvedAmountsByRef or nil
    if type(requiredByRef) ~= "table" then
        _, requiredByRef = resolveSpellResourceCostAmounts(target, costs, resourceContext)
        resourceContext.resolvedAmountsByRef = requiredByRef
    end

    for resourceRef, requiredAmount in pairs(requiredByRef) do
        local entry = resourceContext.entriesByRef and resourceContext.entriesByRef[resourceRef] or nil
        local currentValue = tonumber(entry and entry.currentValue) or 0
        if currentValue < requiredAmount then
            return false
        end
    end

    return true
end

function Spellcasting.ApplyResourceDelta(resources, resourceRef, delta, context)
    if type(resources) ~= "table" or type(resourceRef) ~= "string" or resourceRef == "" then
        return false, 0, nil
    end

    local numericDelta = tonumber(delta) or 0
    if numericDelta == 0 then
        return false, 0, nil
    end

    local entry = type(context) == "table" and type(context.entriesByRef) == "table" and context.entriesByRef[resourceRef] or nil
    if not entry then
        entry = findResourceEntry(resources, resourceRef)
        if entry and type(context) == "table" and type(context.entriesByRef) == "table" then
            context.entriesByRef[resourceRef] = entry
        end
    end

    if not entry then
        return false, 0, nil
    end

    local currentValue = tonumber(entry.currentValue)
    if currentValue == nil then
        currentValue = tonumber(entry.maxValue) or 0
    end

    local maxValue = tonumber(entry.maxValue)
    if maxValue == nil then
        maxValue = currentValue
    end

    local nextValue = currentValue + numericDelta
    if nextValue < 0 then
        nextValue = 0
    elseif maxValue ~= nil and maxValue >= 0 and nextValue > maxValue then
        nextValue = maxValue
    end

    local appliedDelta = nextValue - currentValue
    if appliedDelta ~= 0 then
        entry.currentValue = nextValue
        if entry.maxValue == nil then
            entry.maxValue = math.max(nextValue, maxValue or nextValue)
        end
        return true, appliedDelta, entry
    end

    return false, 0, entry
end

function Spellcasting.ApplySpellResourceCostsToUnit(eventUnit, spell, phase, isInterrupt, context)
    if type(eventUnit) ~= "table" or type(spell) ~= "table" then
        return false, nil
    end

    local timingEnabled = isSpellcastTimingEnabled()
    local totalStartTime = timingEnabled and getNowMilliseconds() or nil
    local relevantCosts = type(context) == "table" and type(context.costs) == "table"
        and context.costs
        or Spellcasting.GetSpellResourceCostsForPhase(spell, phase)
    if #relevantCosts == 0 then
        return false, nil, {}
    end

    local resourceContext = type(context) == "table" and context or buildSpellResourceContext(eventUnit, relevantCosts, {
        applyFallbackToUnit = true,
    })
    local currentResources = resourceContext and resourceContext.resources or nil
    if type(currentResources) ~= "table" then
        return false, nil
    end

    local changed = false
    local resourceDeltas = {}
    local resolvedAmountsByRef = {}
    local timingParts = timingEnabled and {} or nil

    local affordabilityStartTime = timingEnabled and getNowMilliseconds() or nil
    if phase == "on_cast_start" then
        if not Spellcasting.CanAffordResourceCosts(eventUnit, relevantCosts, resourceContext) then
            return false, nil
        end
    end
    if timingEnabled then
        timingParts[#timingParts + 1] = {
            label = ("affordability[%d]"):format(#relevantCosts),
            elapsed = getNowMilliseconds() - affordabilityStartTime,
        }
    end

    for index = 1, #relevantCosts do
        local cost = relevantCosts[index]
        local costStartTime = timingEnabled and getNowMilliseconds() or nil
        local resourceRef = type(cost) == "table" and tostring(cost.resourceRef or "") or ""
        local amount = type(resourceContext.resolvedAmountsByIndex) == "table" and resourceContext.resolvedAmountsByIndex[index]
            or Spellcasting.ResolveSpellResourceCostAmount(eventUnit, cost, resourceContext)
        local applyElapsed = 0
        if resourceRef ~= "" and amount > 0 then
            resolvedAmountsByRef[index] = amount
            local delta = 0
            if isInterrupt == true then
                local refundFraction = Spellcasting.NormalizeRefundFraction(cost and cost.refundOnInterrupt)
                if refundFraction > 0 then
                    delta = math.floor((amount * refundFraction) + 0.5)
                end
            else
                delta = -amount
            end

            if delta ~= 0 then
                local applyStartTime = timingEnabled and getNowMilliseconds() or nil
                local mutated, appliedDelta, entry = Spellcasting.ApplyResourceDelta(currentResources, resourceRef, delta, resourceContext)
                if timingEnabled then
                    applyElapsed = getNowMilliseconds() - applyStartTime
                end
                changed = changed or mutated
                if mutated then
                    resourceDeltas[#resourceDeltas + 1] = {
                        resourceRef = resourceRef,
                        delta = appliedDelta,
                        maxValue = tonumber(entry and entry.maxValue) or 0,
                        currentValue = tonumber(entry and entry.currentValue) or 0,
                    }
                end
            end
        end

        if timingEnabled then
            timingParts[#timingParts + 1] = {
                label = ("cost[%d:%s]=%d/%d"):format(index, resourceRef ~= "" and resourceRef or "none", amount, math.floor(applyElapsed + 0.5)),
                elapsed = getNowMilliseconds() - costStartTime,
            }
        end
    end

    if timingEnabled then
        logSpellcastTimingLine(
            "Spellcast resource timing",
            ("%s/%s/%s"):format(
                tostring(spell.id or spell.name or "spell"),
                tostring(phase or "phase"),
                isInterrupt == true and "interrupt" or "apply"
            ),
            timingParts,
            getNowMilliseconds() - totalStartTime,
            SPELLCAST_SLOW_HELPER_MS
        )
    end

    if not changed then
        return false, nil
    end

    return true, resourceDeltas, resolvedAmountsByRef
end

Spellcasting.BuildSpellResourceContext = buildSpellResourceContext
Spellcasting.ResolveSpellResourceCostAmounts = resolveSpellResourceCostAmounts

function Spellcasting.BuildResourceSyncPayload(resources, updatedRefs)
    local updateFilter = type(updatedRefs) == "table" and updatedRefs or nil
    if type(ResourceSync.CloneResources) == "function" then
        local cloned = ResourceSync.CloneResources(resources)
        if updateFilter == nil then
            return cloned
        end

        local filtered = {}
        for index = 1, #((cloned) or {}) do
            local entry = cloned[index]
            if type(entry) == "table" and updateFilter[entry.resourceRef] == true then
                filtered[#filtered + 1] = entry
            end
        end
        return filtered
    end

    local payload = {}
    for index = 1, #(resources or {}) do
        local entry = resources[index]
        if type(entry) == "table" and (updateFilter == nil or updateFilter[entry.resourceRef] == true) then
            payload[#payload + 1] = {
                resourceRef = entry.resourceRef,
                currentValue = tonumber(entry.currentValue) or 0,
                maxValue = tonumber(entry.maxValue) or 0,
            }
        end
    end

    return payload
end

function Spellcasting.BuildResourceDeltaPayload(resourceDeltas)
    if type(ResourceSync.CloneResourceDeltas) == "function" then
        return ResourceSync.CloneResourceDeltas(resourceDeltas)
    end

    local payload = {}
    for index = 1, #(resourceDeltas or {}) do
        local entry = resourceDeltas[index]
        if type(entry) == "table" and type(entry.resourceRef) == "string" and entry.resourceRef ~= "" then
            payload[#payload + 1] = {
                resourceRef = entry.resourceRef,
                delta = tonumber(entry.delta) or 0,
                maxValue = tonumber(entry.maxValue) or 0,
            }
        end
    end

    return payload
end

function Spellcasting.ResolveSpellName(spellRef)
    if type(Registry.ResolveSpellName) == "function" then
        return Registry:ResolveSpellName(spellRef)
    end

    return type(spellRef) == "string" and spellRef or "unknown-spell"
end

function Spellcasting.GetMaxEventUnits()
    local activeRuleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("event", "max_event_units") or nil
    local maxEventUnits = Ruleset.GetRulesetRuleValue and Ruleset.GetRulesetRuleValue(activeRuleset, "event", ruleDefinition) or nil
    maxEventUnits = math.floor(tonumber(maxEventUnits) or DEFAULT_MAX_EVENT_UNITS)
    if maxEventUnits <= 0 then
        return DEFAULT_MAX_EVENT_UNITS
    end

    return maxEventUnits
end

function Spellcasting.GetUnitPageIndex(eventState, casterEventId)
    local units = eventState and eventState.units or nil
    local numericCasterEventId = tonumber(casterEventId) or 0
    if type(units) ~= "table" or numericCasterEventId <= 0 then
        return nil
    end

    local eventClass = getEventClass()
    local casterUnit = Lookup.FindEventUnitById and Lookup.FindEventUnitById(units, numericCasterEventId) or nil
    if eventClass
        and type(eventClass.IsPlayerSharedTurnPet) == "function"
        and type(casterUnit) == "table"
        and eventClass.IsPlayerSharedTurnPet(units, casterUnit)
    then
        local summonerEventId = tonumber(casterUnit.summonedByEventID) or tonumber(casterUnit.controllerID) or 0
        if summonerEventId > 0 and summonerEventId ~= numericCasterEventId then
            numericCasterEventId = summonerEventId
        end
    end

    local pageSize = Spellcasting.GetMaxEventUnits()
    if eventClass and eventClass.GetUnitPageIndex then
        return eventClass.GetUnitPageIndex(units, numericCasterEventId, pageSize)
    end

    for index = 1, #units do
        if tonumber(units[index] and units[index].eventID) == numericCasterEventId then
            return math.max(1, math.ceil(index / pageSize))
        end
    end

    return nil
end

function Spellcasting.IsCasterTurnOnTick(eventState, casterEventId)
    local currentTick = math.max(1, math.floor(tonumber(eventState and eventState.tickNumber) or 0))
    local casterTick = Spellcasting.GetUnitPageIndex(eventState, casterEventId)
    return casterTick ~= nil and currentTick == casterTick
end

function Spellcasting.BuildCastEntry(spellRef, spellName, authorityType, casterEventId, turnCount, turnNumber)
    local turnsTotal = Spellcasting.NormalizeTurnCount(turnCount)
    if turnsTotal == nil then
        return nil
    end

    local startedOnTurnNumber = math.max(1, math.floor(tonumber(turnNumber) or 1))
    return {
        spellRef = spellRef,
        spellName = spellName,
        turnsTotal = turnsTotal,
        startedOnTurnNumber = startedOnTurnNumber,
        completeOnTurnNumber = startedOnTurnNumber + turnsTotal,
        turnsElapsed = 0,
        lastAdvancedTurnNumber = startedOnTurnNumber,
        authorityType = authorityType,
        casterEventId = casterEventId,
    }
end

function Spellcasting.NormalizeCastingGroup(value)
    local combat = getCombat()
    if combat and type(combat.NormalizeCastingGroup) == "function" then
        return combat.NormalizeCastingGroup(value)
    end

    local group = trimText(value)
    if group == "" then
        return DEFAULT_TARGET_SELECTION_GROUP
    end

    return group
end

function Spellcasting.BuildSpellTargetGroups(spell)
    local combat = getCombat()
    local groupsByKey = {}
    local groupOrder = {}

    for index = 1, #(spell and spell.components or {}) do
        local component = spell.components[index]
        local normalizedComponent = combat and combat.NormalizeComponent and combat.NormalizeComponent(component) or component
        local policy = combat and combat.NormalizeTarget and combat.NormalizeTarget(normalizedComponent and normalizedComponent.target) or normalizedComponent and normalizedComponent.target or nil
        if type(policy) == "table" then
            policy.allowDeadTargets = type(spell) == "table" and spell.allowDeadTargets == true or policy.allowDeadTargets == true
        end
        local targetType = tostring(policy and policy.type or "single")
        local maxTargets = math.max(0, tonumber(policy and policy.maxTargets) or 0)
        if normalizedComponent
            and normalizedComponent.effect
            and targetType ~= "caster"
            and targetType ~= "pet"
            and policy
            and maxTargets > 0
        then
            local normalizedCastingGroup = Spellcasting.NormalizeCastingGroup(normalizedComponent.castingGroup)
            local groupKey = normalizedCastingGroup
            if normalizedCastingGroup == DEFAULT_TARGET_SELECTION_GROUP then
                groupKey = buildImplicitTargetGroupKey(policy)
            end
            local existing = groupsByKey[groupKey]
            if not existing then
                groupsByKey[groupKey] = {
                    key = groupKey,
                    sourceGroupKey = normalizedCastingGroup,
                    policy = cloneTargetPolicy(policy),
                }
                groupOrder[#groupOrder + 1] = groupKey
            else
                local mergedPolicy = mergeTargetPolicies(existing.policy, policy)
                if not mergedPolicy then
                    return nil, ("Spell component casting group '%s' mixes incompatible target policies."):format(groupKey)
                end
                existing.policy = mergedPolicy
            end
        end
    end

    local groups = {}
    for index = 1, #groupOrder do
        local groupKey = groupOrder[index]
        local entry = groupsByKey[groupKey]
        groups[#groups + 1] = {
            key = groupKey,
            label = buildTargetGroupLabel(groupKey, index, #groupOrder, entry and entry.policy),
            policy = cloneTargetPolicy(entry and entry.policy),
        }
    end

    return groups, nil
end

function Spellcasting.CloneTargetEventIds(values)
    local targetEventIds = {}
    local seen = {}

    for index = 1, #(values or {}) do
        local numericEventId = tonumber(values[index]) or 0
        if numericEventId > 0 and not seen[numericEventId] then
            seen[numericEventId] = true
            targetEventIds[#targetEventIds + 1] = numericEventId
        end
    end

    return targetEventIds
end

local function cloneTargetSelectionEntry(groupKey, selection)
    local combat = getCombat()
    local normalizedGroupKey = Spellcasting.NormalizeCastingGroup((type(selection) == "table" and selection.groupKey) or groupKey)
    return {
        groupKey = normalizedGroupKey,
        targetEventIds = Spellcasting.CloneTargetEventIds(type(selection) == "table" and selection.targetEventIds or nil),
        focusedTargetEventId = tonumber(type(selection) == "table" and selection.focusedTargetEventId or nil) or 0,
        policy = type(selection) == "table" and type(selection.policy) == "table" and combat and combat.NormalizeTarget and combat.NormalizeTarget(selection.policy) or (type(selection) == "table" and selection.policy or nil),
    }
end

function Spellcasting.CloneTargetSelections(targetSelections, groupOrder)
    local clonedSelections = {}
    local clonedOrder = {}
    local seen = {}

    local function appendSelection(groupKey, selection)
        local normalizedGroupKey = Spellcasting.NormalizeCastingGroup(groupKey)
        if seen[normalizedGroupKey] then
            return
        end

        seen[normalizedGroupKey] = true
        clonedSelections[normalizedGroupKey] = cloneTargetSelectionEntry(normalizedGroupKey, selection)
        clonedOrder[#clonedOrder + 1] = normalizedGroupKey
    end

    for index = 1, #(groupOrder or {}) do
        local groupKey = groupOrder[index]
        appendSelection(groupKey, type(targetSelections) == "table" and targetSelections[Spellcasting.NormalizeCastingGroup(groupKey)] or nil)
    end

    for groupKey, selection in pairs(type(targetSelections) == "table" and targetSelections or {}) do
        appendSelection(groupKey, selection)
    end

    return clonedSelections, clonedOrder
end

local function getPrimaryTargetSelection(targetSelections, groupOrder)
    local primaryGroupKey = Spellcasting.NormalizeCastingGroup(groupOrder and groupOrder[1] or nil)
    if type(targetSelections) ~= "table" then
        return nil, primaryGroupKey
    end

    if type(groupOrder) == "table" and #groupOrder > 0 then
        return targetSelections[primaryGroupKey], primaryGroupKey
    end

    return targetSelections[DEFAULT_TARGET_SELECTION_GROUP], DEFAULT_TARGET_SELECTION_GROUP
end

function Spellcasting.QueueLocalSpellTargetSelection(self, spellRef, targetSelections, groupOrder)
    local clonedSelections, clonedOrder = Spellcasting.CloneTargetSelections(targetSelections, groupOrder)
    self.QueuedSpellTargetSelection = {
        spellRef = type(spellRef) == "string" and spellRef or nil,
        targetSelections = clonedSelections,
        targetSelectionOrder = clonedOrder,
    }

    return self.QueuedSpellTargetSelection
end

function Spellcasting.ConsumeQueuedSpellTargetSelection(self, spellRef)
    local combat = getCombat()
    local queued = type(self) == "table" and self.QueuedSpellTargetSelection or nil
    if type(queued) ~= "table" then
        return nil
    end

    if type(spellRef) == "string" and spellRef ~= "" and queued.spellRef ~= spellRef then
        return nil
    end

    self.QueuedSpellTargetSelection = nil
    local clonedSelections, clonedOrder = Spellcasting.CloneTargetSelections(queued.targetSelections, queued.targetSelectionOrder)
    local primarySelection = getPrimaryTargetSelection(clonedSelections, clonedOrder)
    return {
        spellRef = queued.spellRef,
        targetSelections = clonedSelections,
        targetSelectionOrder = clonedOrder,
        targetEventIds = Spellcasting.CloneTargetEventIds(primarySelection and primarySelection.targetEventIds or nil),
        focusedTargetEventId = tonumber(primarySelection and primarySelection.focusedTargetEventId or nil) or 0,
        policy = type(primarySelection and primarySelection.policy) == "table" and combat and combat.NormalizeTarget and combat.NormalizeTarget(primarySelection.policy) or (primarySelection and primarySelection.policy or nil),
    }
end

function Spellcasting.PeekQueuedSpellTargetSelection(self, spellRef)
    local combat = getCombat()
    local queued = type(self) == "table" and self.QueuedSpellTargetSelection or nil
    if type(queued) ~= "table" then
        return nil
    end

    if type(spellRef) == "string" and spellRef ~= "" and queued.spellRef ~= spellRef then
        return nil
    end

    local clonedSelections, clonedOrder = Spellcasting.CloneTargetSelections(queued.targetSelections, queued.targetSelectionOrder)
    local primarySelection = getPrimaryTargetSelection(clonedSelections, clonedOrder)
    return {
        spellRef = queued.spellRef,
        targetSelections = clonedSelections,
        targetSelectionOrder = clonedOrder,
        targetEventIds = Spellcasting.CloneTargetEventIds(primarySelection and primarySelection.targetEventIds or nil),
        focusedTargetEventId = tonumber(primarySelection and primarySelection.focusedTargetEventId or nil) or 0,
        policy = type(primarySelection and primarySelection.policy) == "table" and combat and combat.NormalizeTarget and combat.NormalizeTarget(primarySelection.policy) or (primarySelection and primarySelection.policy or nil),
    }
end

local function attachSelectionToCastEntry(entry, selection)
    local combat = getCombat()
    if type(entry) ~= "table" or type(selection) ~= "table" then
        return entry
    end

    local clonedSelections, clonedOrder = Spellcasting.CloneTargetSelections(selection.targetSelections, selection.targetSelectionOrder)
    local primarySelection = getPrimaryTargetSelection(clonedSelections, clonedOrder)
    entry.targetSelections = clonedSelections
    entry.targetSelectionOrder = clonedOrder
    entry.targetEventIds = Spellcasting.CloneTargetEventIds(primarySelection and primarySelection.targetEventIds or nil)
    entry.focusedTargetEventId = tonumber(primarySelection and primarySelection.focusedTargetEventId or nil) or 0
    entry.targetPolicy = type(primarySelection and primarySelection.policy) == "table" and combat and combat.NormalizeTarget and combat.NormalizeTarget(primarySelection.policy) or (primarySelection and primarySelection.policy or nil)
    return entry
end

function Spellcasting.BuildCastEntryWithSelection(self, spellRef, spellName, authorityType, casterEventId, turnCount, turnNumber)
    local entry = Spellcasting.BuildCastEntry(spellRef, spellName, authorityType, casterEventId, turnCount, turnNumber)
    if not entry then
        return nil
    end

    return attachSelectionToCastEntry(entry, Spellcasting.ConsumeQueuedSpellTargetSelection(self, spellRef))
end

function Spellcasting.GetHealthResourceRef()
    local combat = getCombat()
    if combat and type(combat.GetHealthResourceRef) == "function" then
        return combat:GetHealthResourceRef()
    end

    return nil
end

function Spellcasting.RefreshLocalResourceDisplays(reason)
    local refreshed = false
    local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or nil
    local targetEventIds = {}
    local localEventUnit = type(Client.ResolveLocalEventUnit) == "function" and Client:ResolveLocalEventUnit(eventState) or nil
    local controlledEventUnit = type(Client.ResolveControlledEventUnit) == "function" and Client:ResolveControlledEventUnit(eventState) or nil
    local localEventId = tonumber(localEventUnit and localEventUnit.eventID) or 0
    local controlledEventId = tonumber(controlledEventUnit and controlledEventUnit.eventID) or 0
    if localEventId > 0 then
        targetEventIds[#targetEventIds + 1] = localEventId
    end
    if controlledEventId > 0 and controlledEventId ~= localEventId then
        targetEventIds[#targetEventIds + 1] = controlledEventId
    end

    if #targetEventIds > 0 and type(Client.QueueEventWidgetTargetedRefresh) == "function" then
        refreshed = Client:QueueEventWidgetTargetedRefresh(reason, targetEventIds) or refreshed
    elseif type(Client.QueueEventWidgetRefresh) == "function" then
        refreshed = Client:QueueEventWidgetRefresh(reason) or refreshed
    end
    refreshed = Spellcasting.RefreshVisiblePlayerTooltip(reason, {
        skipCompanionBars = true,
    }) or refreshed
    return refreshed
end

function Spellcasting.IsCombatTextTrackedUnit(client, eventState, unit)
    if type(client) ~= "table" or type(eventState) ~= "table" or type(unit) ~= "table" then
        return false
    end

    local unitEventId = tonumber(unit.eventID) or 0
    if unitEventId <= 0 then
        return false
    end

    local localUnit = client.ResolveLocalEventUnit and client:ResolveLocalEventUnit(eventState) or nil
    if tonumber(localUnit and localUnit.eventID) == unitEventId then
        return true
    end

    local controlledUnit = client.ResolveControlledEventUnit and client:ResolveControlledEventUnit(eventState) or nil
    if tonumber(controlledUnit and controlledUnit.eventID) == unitEventId then
        return true
    end

    return false
end

local function getDamageDealtColor(hitType)
    local normalizedHitType = tostring(hitType or "ability")
    if normalizedHitType == "auto" then
        return { r = 1, g = 1, b = 1, a = 1 }
    end
    if normalizedHitType == "pet" then
        return { r = 0.86, g = 0.60, b = 0.34, a = 1 }
    end

    return { r = 1, g = 0.92, b = 0.3, a = 1 }
end

local function enqueueCombatText(entry)
    local combatText = ClientUI and ClientUI.CombatText and ClientUI.CombatText.Get and ClientUI.CombatText:Get() or nil
    if not combatText or type(combatText.Enqueue) ~= "function" then
        return false
    end

    return combatText:Enqueue(entry)
end

local function isCriticalResult(result)
    if type(result) ~= "table" then
        return false
    end

    return result.wasCritical == true
        or result.isCritical == true
        or result.isCrit == true
        or tostring(result.resultType or "") == "critical"
        or tostring(result.resultType or "") == "crushing"
end

local function isCriticalStrikeResult(result)
    return type(result) == "table" and tostring(result.resultType or "") == "critical"
end

local function showTrackedTargetDelta(client, eventState, targetUnit, delta, size, labelPrefix, suffix)
    if not Spellcasting.IsCombatTextTrackedUnit(client, eventState, targetUnit) then
        return false
    end

    local numericDelta = tonumber(delta) or 0
    if numericDelta == 0 then
        return false
    end

    local isHealing = numericDelta > 0
    return enqueueCombatText({
        text = tostring(labelPrefix or "") .. (numericDelta > 0 and "+" or "-") .. tostring(math.abs(numericDelta)) .. tostring(suffix or ""),
        color = isHealing and UI.ResolveColor(nil, "success") or UI.ResolveColor(nil, "danger"),
        size = size,
        direction = "DOWN",
    })
end

local function formatOutgoingDeltaText(delta, labelPrefix)
    local numericDelta = tonumber(delta) or 0
    if numericDelta > 0 then
        return tostring(labelPrefix or "") .. "+" .. tostring(math.abs(numericDelta))
    end

    return tostring(labelPrefix or "") .. tostring(math.abs(numericDelta))
end

function Spellcasting.ShowLocalResourceDeltaCombatText(client, eventState, casterUnit, targetUnit, resourceDeltas, hitType, result)
    local healthResourceRef = type(eventState) == "table" and eventState.healthResourceRef or Spellcasting.GetHealthResourceRef()
    if healthResourceRef == nil or type(resourceDeltas) ~= "table" then
        return false
    end

    local size = isCriticalResult(result) and "critical" or "normal"
    local showed = false
    local handledHealthDelta = false
    local isHealResult = type(result) == "table" and tostring(result.effectType or "") == "heal"
    local healDisplayAmount = isHealResult and math.max(0, tonumber(result.amount) or 0) or 0
    local resultLabelPrefix = type(result) == "table" and tostring(result.resultType or "") == "crushing" and "Crushing " or ""
    local resultSuffix = (not isHealResult and isCriticalStrikeResult(result)) and "!" or ""

    for index = 1, #resourceDeltas do
        local deltaEntry = resourceDeltas[index]
        if type(deltaEntry) == "table" and deltaEntry.resourceRef == healthResourceRef then
            handledHealthDelta = true
            local numericDelta = tonumber(deltaEntry.delta) or 0
            local displayDelta = isHealResult and healDisplayAmount > 0 and healDisplayAmount or numericDelta
            if displayDelta ~= 0 then
                if showTrackedTargetDelta(client, eventState, targetUnit, displayDelta, size, resultLabelPrefix, resultSuffix) then
                    showed = true
                elseif Spellcasting.IsCombatTextTrackedUnit(client, eventState, casterUnit) then
                    local isHealing = displayDelta > 0
                    local text = formatOutgoingDeltaText(displayDelta, resultLabelPrefix)
                    if not isHealing and resultSuffix ~= "" then
                        text = text .. "!"
                    end
                    showed = enqueueCombatText({
                        text = text,
                        color = isHealing and UI.ResolveColor(nil, "success") or getDamageDealtColor(hitType),
                        size = size,
                        direction = "UP",
                    }) or showed
                end
            end
        end
    end

    if not showed
        and handledHealthDelta
        and isHealResult
        and healDisplayAmount > 0
    then
        if showTrackedTargetDelta(client, eventState, targetUnit, healDisplayAmount, size, resultLabelPrefix) then
            showed = true
        elseif Spellcasting.IsCombatTextTrackedUnit(client, eventState, casterUnit) then
            showed = enqueueCombatText({
                text = formatOutgoingDeltaText(healDisplayAmount, resultLabelPrefix),
                color = UI.ResolveColor(nil, "success"),
                size = size,
                direction = "UP",
            }) or showed
        end
    end

    return showed
end

function Spellcasting.ShowInboundResourceDeltaCombatText(client, eventState, targetUnit, resourceDeltas)
    local healthResourceRef = type(eventState) == "table" and eventState.healthResourceRef or Spellcasting.GetHealthResourceRef()
    if healthResourceRef == nil or type(resourceDeltas) ~= "table" then
        return false
    end

    local showed = false
    for index = 1, #resourceDeltas do
        local deltaEntry = resourceDeltas[index]
        if type(deltaEntry) == "table" and deltaEntry.resourceRef == healthResourceRef then
            showed = showTrackedTargetDelta(client, eventState, targetUnit, deltaEntry.delta, "normal") or showed
        end
    end

    return showed
end

local function shouldMarkResolvedEffectInteraction(result)
    if type(result) ~= "table" then
        return false
    end

    local effectType = tostring(result.effectType or "")
    if effectType ~= "damage" and effectType ~= "heal" then
        return false
    end

    local resultType = tostring(result.resultType or "")
    return resultType ~= "invalid"
end

function Spellcasting.ProcessResolvedEffectResult(self, eventState, casterUnit, targetUnit, component, result, spellRef)
    if type(result) ~= "table" then
        return false
    end

    local effectType = tostring(result.effectType or "")
    local deferDamagePresentation = effectType == "damage"

    if type(self) == "table" and type(self.RecordSpellImpact) == "function" and not (type(component) == "table" and component._disableImpactHistory == true) then
        self:RecordSpellImpact(eventState, casterUnit, targetUnit, spellRef, result)
    end

    if effectType == "damage" and type(self) == "table" and type(self.RecordRecentAttacker) == "function" then
        self:RecordRecentAttacker(eventState, casterUnit, targetUnit)
    end

    if type(self.MarkEventUnitInteraction) == "function" and shouldMarkResolvedEffectInteraction(result) then
        self:MarkEventUnitInteraction(eventState, casterUnit, targetUnit, result, spellRef)
    end

    if effectType == "interrupt" then
        emitInterruptCombatLog(self, eventState, casterUnit, targetUnit, result, spellRef)
    end

    local resourceDeltas = Spellcasting.BuildResourceDeltaPayload(result.resourceDeltas)
    local hasResourceDeltas = type(resourceDeltas) == "table" and #resourceDeltas > 0
    local isPureDisplayedHeal = tostring(result.effectType or "") == "heal" and (tonumber(result.amount) or 0) > 0
    if not hasResourceDeltas then
        if not isPureDisplayedHeal then
            return false
        end
        resourceDeltas = {
            {
                resourceRef = type(eventState) == "table" and eventState.healthResourceRef or Spellcasting.GetHealthResourceRef(),
                delta = 0,
                maxValue = 0,
                currentValue = 0,
            },
        }
    end

    local sessionState = self.GetState and self:GetState() or nil
    local targetEventId = tonumber(targetUnit and targetUnit.eventID) or 0
    if type(self.QueueClientResourceDeltas) == "function"
        and type(sessionState) == "table"
        and sessionState.active == true
        and targetEventId > 0
        and hasResourceDeltas
        and deferDamagePresentation ~= true
    then
        self:QueueClientResourceDeltas(
            sessionState,
            "spellcast-component-resource",
            resourceDeltas,
            targetEventId
        )
    end

    if deferDamagePresentation ~= true then
        enqueueSpellcastPresentationWork(function(targetClient, queuedEventState, queuedCasterUnit, queuedTargetUnit, queuedResourceDeltas, queuedHitType, queuedResult)
            Spellcasting.RefreshLocalResourceDisplays("spellcast-component-resource")
            Spellcasting.ShowLocalResourceDeltaCombatText(
                targetClient,
                queuedEventState,
                queuedCasterUnit,
                queuedTargetUnit,
                queuedResourceDeltas,
                queuedHitType,
                queuedResult
            )
        end,
        self,
        eventState,
        casterUnit,
        targetUnit,
        resourceDeltas,
        component and component.effect and component.effect.hitType or nil,
        result)
    end
    return true
end

function Spellcasting.GetComponentTargetSelection(castEntry, component)
    if type(castEntry) ~= "table" or type(component) ~= "table" then
        return nil
    end

    local groupKey = Spellcasting.NormalizeCastingGroup(component.castingGroup)
    if type(castEntry.targetSelections) == "table" and type(castEntry.targetSelections[groupKey]) == "table" then
        return castEntry.targetSelections[groupKey]
    end

    if type(castEntry.targetEventIds) == "table" or castEntry.focusedTargetEventId ~= nil or type(castEntry.targetPolicy) == "table" then
        return {
            groupKey = groupKey,
            targetEventIds = Spellcasting.CloneTargetEventIds(castEntry.targetEventIds),
            focusedTargetEventId = tonumber(castEntry.focusedTargetEventId) or 0,
            policy = castEntry.targetPolicy,
        }
    end

    return nil
end

function Spellcasting.ResolveComponentTargets(eventState, casterUnit, component, castEntry)
    local combat = getCombat()
    if type(eventState) ~= "table" or type(casterUnit) ~= "table" or type(component) ~= "table" then
        return {}
    end

    local targetPolicy = combat and combat.NormalizeTarget and combat.NormalizeTarget(component.target) or component.target or {}
    local targetType = tostring(targetPolicy and targetPolicy.type or "single")
    if targetType == "caster" then
        return { casterUnit }
    end
    if targetType == "pet" then
        local selectedPetRef = type(casterUnit) == "table" and tostring(casterUnit.petRef or "") or ""
        if selectedPetRef == "" then
            return {}
        end

        for index = 1, #(eventState.units or {}) do
            local unit = eventState.units[index]
            if unit
                and unit.isPlayer ~= true
                and tostring(unit.petRef or "") == selectedPetRef
                and tonumber(unit.controllerID) == tonumber(casterUnit.eventID)
            then
                return { unit }
            end
        end
        return {}
    end

    local selection = Spellcasting.GetComponentTargetSelection(castEntry, component)
    targetPolicy.allowDeadTargets = targetPolicy.allowDeadTargets == true
        or (type(selection) == "table" and type(selection.policy) == "table" and selection.policy.allowDeadTargets == true)
        or (type(castEntry) == "table" and type(castEntry.targetPolicy) == "table" and castEntry.targetPolicy.allowDeadTargets == true)
    local focusedTargetEventId = tonumber(selection and selection.focusedTargetEventId) or 0
    local selectedTargetEventIds = Spellcasting.CloneTargetEventIds(selection and selection.targetEventIds)
    local maxTargets = math.max(0, tonumber(targetPolicy and targetPolicy.maxTargets) or 0)
    local disableSelfCast = targetType ~= "caster" and targetPolicy and targetPolicy.disableSelfCast == true
    local casterEventId = tonumber(casterUnit and casterUnit.eventID) or 0
    local targets = {}
    local seen = {}

    local function pushTarget(eventId)
        local numericEventId = tonumber(eventId) or 0
        if numericEventId <= 0 or seen[numericEventId] then
            return false
        end

        if disableSelfCast and numericEventId == casterEventId then
            return false
        end

        local targetUnit = Lookup.FindEventUnitById and Lookup.FindEventUnitById(eventState.units, numericEventId) or nil
        local eventClass = getEventClass()
        if not targetUnit or (eventClass and eventClass.IsUnitActive and not eventClass.IsUnitActive(targetUnit)) then
            return false
        end

        if type(combat) == "table"
            and type(combat.IsUnitDead) == "function"
            and combat:IsUnitDead(targetUnit, {
                eventState = eventState,
                healthResourceRef = eventState and eventState.healthResourceRef or nil,
            })
            and targetPolicy.allowDeadTargets ~= true
        then
            return false
        end

        seen[numericEventId] = true
        targets[#targets + 1] = targetUnit
        return true
    end

    if focusedTargetEventId > 0 then
        pushTarget(focusedTargetEventId)
    end

    if targetType == "last_attackers" then
        local sourceTargetEventId = focusedTargetEventId
        if sourceTargetEventId <= 0 then
            sourceTargetEventId = tonumber(selectedTargetEventIds[1]) or 0
        end
        local recentAttackers = type(Client.GetRecentAttackersForTarget) == "function"
            and Client:GetRecentAttackersForTarget(eventState, sourceTargetEventId)
            or {}
        for index = 1, #recentAttackers do
            if pushTarget(recentAttackers[index]) then
                break
            end
        end
        return targets
    end

    if targetType == "single" then
        for index = 1, #selectedTargetEventIds do
            if pushTarget(selectedTargetEventIds[index]) then
                break
            end
        end
        return targets
    end

    for index = 1, #selectedTargetEventIds do
        pushTarget(selectedTargetEventIds[index])
        if maxTargets > 0 and #targets >= maxTargets then
            break
        end
    end

    return targets
end

function Spellcasting.ExecuteSpellComponentsForPhase(self, eventState, casterUnit, dataset, spell, spellRef, phase, castEntry)
    local combat = getCombat()
    if not combat
        or type(combat.DispatchComponentEffect) ~= "function"
        or type(spell) ~= "table"
        or type(eventState) ~= "table"
        or type(casterUnit) ~= "table"
    then
        return false, {}
    end

    local timingEnabled = isSpellcastTimingEnabled()
    local totalStartTime = timingEnabled and getNowMilliseconds() or nil
    local targetPhase = combat.NormalizeCastPhase and combat.NormalizeCastPhase(phase) or tostring(phase or "on_cast_end")
    local healthResourceRef = type(eventState) == "table" and eventState.healthResourceRef or Spellcasting.GetHealthResourceRef()
    local results = {}
    local executed = false
    local executedComponentCount = 0
    local combatEventState = type(combat.GetOrCreateActionCombatEventState) == "function"
        and combat:GetOrCreateActionCombatEventState(castEntry, spell)
        or nil
    local hasPendingDamage = false

    for index = 1, #(spell.components or {}) do
        local component = spell.components[index]
        local normalizedComponent = combat.NormalizeComponent and combat.NormalizeComponent(component) or component
        local componentPhase = normalizedComponent and normalizedComponent.castPhase or nil
        if normalizedComponent and componentPhase == targetPhase and normalizedComponent.effect then
            local componentStartTime = timingEnabled and getNowMilliseconds() or nil
            local targetResolveStartTime = timingEnabled and getNowMilliseconds() or nil
            local targets = Spellcasting.ResolveComponentTargets(eventState, casterUnit, normalizedComponent, castEntry)
            if #(targets or {}) == 0 and normalizedComponent.target and normalizedComponent.target.type == "caster" then
                targets = { casterUnit }
            end
            local targetResolveElapsed = timingEnabled and (getNowMilliseconds() - targetResolveStartTime) or 0

            local resolvedTargetEventIds = {}
            for targetIndex = 1, #(targets or {}) do
                local targetUnit = targets[targetIndex]
                local targetEventId = math.floor(tonumber(targetUnit and targetUnit.eventID) or 0)
                if targetEventId > 0 then
                    resolvedTargetEventIds[#resolvedTargetEventIds + 1] = targetEventId
                end
            end
            local effectType = tostring(normalizedComponent and normalizedComponent.effect and normalizedComponent.effect.type or "")
            local componentResults = {}
            local beginDamageElapsed = 0
            local dispatchElapsed = 0
            local hookElapsed = 0
            local processElapsed = 0
            local emitElapsed = 0
            if effectType == "damage" then
                local targetCount = #(targets or {})
                hasPendingDamage = targetCount > 0
                if type(combat.BeginActionDamageResolution) == "function" then
                    local beginDamageStartTime = timingEnabled and getNowMilliseconds() or nil
                    for targetIndex = 1, targetCount do
                        combat:BeginActionDamageResolution(castEntry, spell, normalizedComponent.key)
                    end
                    if timingEnabled then
                        beginDamageElapsed = getNowMilliseconds() - beginDamageStartTime
                    end
                end
            end
            for targetIndex = 1, #(targets or {}) do
                local targetUnit = targets[targetIndex]
                local targetSelection = Spellcasting.GetComponentTargetSelection(castEntry, normalizedComponent)
                local targetEventIds = targetSelection and targetSelection.targetEventIds or (castEntry and castEntry.targetEventIds or nil)
                if effectType ~= "damage" and type(combat.RegisterActionCombatEventTargets) == "function" then
                    combat:RegisterActionCombatEventTargets(combatEventState, resolvedTargetEventIds)
                end
                local dispatchStartTime = timingEnabled and getNowMilliseconds() or nil
                local applied, result = combat:DispatchComponentEffect(normalizedComponent, {
                    sessionState = self.GetState and self:GetState() or nil,
                    eventState = eventState,
                    eventId = eventState.id,
                    dataset = dataset,
                    datasetId = dataset and dataset.id or nil,
                    spell = spell,
                    spellRef = spellRef,
                    componentKey = normalizedComponent.key,
                    casterUnit = casterUnit,
                    attackerUnit = casterUnit,
                    targetUnit = targetUnit,
                    defenderUnit = targetUnit,
                    targetUnits = targets,
                    selectedTargetEventIds = targetEventIds,
                    resolvedTargetEventIds = resolvedTargetEventIds,
                    healthResourceRef = healthResourceRef,
                    castEntry = castEntry,
                    combatEventState = combatEventState,
                    spellCasterEvents = type(spell) == "table" and spell.casterEvents or nil,
                })
                if timingEnabled then
                    dispatchElapsed = dispatchElapsed + (getNowMilliseconds() - dispatchStartTime)
                end
                executed = true
                if effectType == "heal"
                    and type(combat.RegisterActionCasterEventOutcome) == "function"
                    and (applied or type(result) == "table" and tostring(result.resultType or "") ~= "invalid")
                then
                    combat:RegisterActionCasterEventOutcome(combatEventState, {
                        tonumber(targetUnit and targetUnit.eventID) or 0,
                    }, {
                        effectType = "heal",
                        wasCritical = type(result) == "table" and result.wasCritical == true,
                    })
                end
                if effectType ~= "damage"
                    and type(combat.RunTargetHooks) == "function"
                    and (applied or type(result) == "table" and tostring(result.resultType or "") ~= "invalid")
                then
                    local hookStartTime = timingEnabled and getNowMilliseconds() or nil
                    combat:RunTargetHooks(
                        self,
                        {
                            sessionState = self.GetState and self:GetState() or nil,
                            eventState = eventState,
                            eventId = eventState.id,
                            dataset = dataset,
                            datasetId = dataset and dataset.id or nil,
                            spell = spell,
                            spellRef = spellRef,
                            componentKey = normalizedComponent.key,
                            casterUnit = casterUnit,
                            attackerUnit = casterUnit,
                            targetUnit = targetUnit,
                            targetUnits = { targetUnit },
                            resolvedTargetEventIds = { tonumber(targetUnit and targetUnit.eventID) or 0 },
                            healthResourceRef = healthResourceRef,
                            castEntry = castEntry,
                            combatEventState = combatEventState,
                            spellCasterEvents = type(spell) == "table" and spell.casterEvents or nil,
                            effectType = effectType,
                            hitType = type(result) == "table" and result.hitType or nil,
                            wasCritical = type(result) == "table" and result.wasCritical == true or false,
                        },
                        normalizedComponent and normalizedComponent.effect and normalizedComponent.effect.targetEvents or nil,
                        { tonumber(targetUnit and targetUnit.eventID) or 0 }
                    )
                    if timingEnabled then
                        hookElapsed = hookElapsed + (getNowMilliseconds() - hookStartTime)
                    end
                end
                results[#results + 1] = {
                    componentKey = normalizedComponent.key,
                    targetEventId = tonumber(targetUnit and targetUnit.eventID) or 0,
                    applied = applied,
                    result = result,
                }
                componentResults[#componentResults + 1] = {
                    targetUnit = targetUnit,
                    applied = applied,
                    result = result,
                }
                local processStartTime = timingEnabled and getNowMilliseconds() or nil
                Spellcasting.ProcessResolvedEffectResult(self, eventState, casterUnit, targetUnit, normalizedComponent, result, spellRef)
                if timingEnabled then
                    processElapsed = processElapsed + (getNowMilliseconds() - processStartTime)
                end
            end

            if effectType == "heal" then
                local emitStartTime = timingEnabled and getNowMilliseconds() or nil
                emitResolvedHealCombatLog(self, eventState, casterUnit, componentResults, healthResourceRef, spell, spellRef)
                if timingEnabled then
                    emitElapsed = getNowMilliseconds() - emitStartTime
                end
            end

            if timingEnabled then
                executedComponentCount = executedComponentCount + 1
                logSpellcastTimingLine(
                    "Spellcast component timing",
                    ("%s/%s/%s targets=%d effect=%s"):format(
                        tostring(spellRef or spell.id or spell.name or "spell"),
                        tostring(targetPhase or "phase"),
                        tostring(normalizedComponent.key or index),
                        #(targets or {}),
                        effectType ~= "" and effectType or "unknown"
                    ),
                    {
                        { label = "targets", elapsed = targetResolveElapsed },
                        { label = "begin-damage", elapsed = beginDamageElapsed },
                        { label = "dispatch", elapsed = dispatchElapsed },
                        { label = "hooks", elapsed = hookElapsed },
                        { label = "process", elapsed = processElapsed },
                        { label = "emit", elapsed = emitElapsed },
                    },
                    getNowMilliseconds() - componentStartTime,
                    SPELLCAST_SLOW_HELPER_MS
                )
            end
        end
    end

    if executed and hasPendingDamage ~= true and type(combat.RunCasterHooks) == "function" then
        combat:RunCasterHooks(self, {
            sessionState = self.GetState and self:GetState() or nil,
            eventState = eventState,
            eventId = eventState.id,
            dataset = dataset,
            datasetId = dataset and dataset.id or nil,
            spell = spell,
            spellRef = spellRef,
            casterUnit = casterUnit,
            attackerUnit = casterUnit,
            castEntry = castEntry,
            combatEventState = combatEventState,
            spellCasterEvents = type(spell) == "table" and spell.casterEvents or nil,
        }, castEntry, spell)
    end

    if timingEnabled then
        logSpellcastTimingLine(
            "Spellcast component phase timing",
            ("%s/%s components=%d targets=%d"):format(
                tostring(spellRef or spell.id or spell.name or "spell"),
                tostring(targetPhase or "phase"),
                executedComponentCount,
                #results
            ),
            nil,
            getNowMilliseconds() - totalStartTime,
            SPELLCAST_SLOW_TOTAL_MS
        )
    end

    return executed, results
end

function Spellcasting.LogLifecycle(phase, authorityType, casterName, spellName, turnCount)
    return false
end

refreshVisiblePlayerTooltipImmediate = function(reason, payload)
    local playerTooltip = Addon.Client and Addon.Client.UI and Addon.Client.UI.Tooltips and Addon.Client.UI.Tooltips.Player or nil
    local refreshed = false
    if playerTooltip and type(playerTooltip.RefreshVisibleTooltips) == "function" then
        refreshed = playerTooltip:RefreshVisibleTooltips(reason, payload) or refreshed
    end
    return refreshed
end

Spellcasting.RefreshVisiblePlayerTooltipImmediate = refreshVisiblePlayerTooltipImmediate

function Client:QueueVisiblePlayerTooltipRefresh(reason)
    return self:MarkVisiblePlayerTooltipDirty(reason)
end

function Client:MarkActionBarSlotsDirty(reason, slotIndexes, options)
    local dirtyState = ensureDirtyUiRefreshState(self)
    dirtyState.actionBarRevision = math.max(0, math.floor(tonumber(dirtyState.actionBarRevision) or 0)) + 1
    self.PendingActionBarRefreshReason = tostring(self.PendingActionBarRefreshReason or reason or "action-bar")
    if type(options) == "table" and options.structural == true then
        dirtyState.actionBarStructuralDirty = true
        dirtyState.actionBarAllSlotsDirty = true
        dirtyState.actionBarSlots = {}
    elseif dirtyState.actionBarAllSlotsDirty ~= true then
        if type(slotIndexes) ~= "table" or #slotIndexes == 0 then
            dirtyState.actionBarAllSlotsDirty = true
            dirtyState.actionBarSlots = {}
        else
            for index = 1, #slotIndexes do
                local slotIndex = math.max(1, math.floor(tonumber(slotIndexes[index]) or 0))
                if slotIndex > 0 then
                    dirtyState.actionBarSlots[slotIndex] = true
                end
            end
        end
    end

    self.ActionBarRefreshQueued = true
    return type(self.QueueVisualRefreshFlush) == "function" and self:QueueVisualRefreshFlush() or true
end

function Client:MarkActionBarCompanionBarsDirty(reason, options)
    local dirtyState = ensureDirtyUiRefreshState(self)
    dirtyState.companionBarsDirty = true
    if type(options) == "table" and options.immediate == true then
        dirtyState.companionBarsImmediate = true
        self.PendingActionBarCompanionBarsRefreshImmediate = true
    elseif dirtyState.companionBarsImmediate ~= true then
        dirtyState.companionBarsImmediate = false
        self.PendingActionBarCompanionBarsRefreshImmediate = false
    end

    self.PendingActionBarCompanionBarsRefreshReason = tostring(
        self.PendingActionBarCompanionBarsRefreshReason or reason or "action-bar-companion"
    )
    self.ActionBarCompanionBarsRefreshQueued = true
    return type(self.QueueVisualRefreshFlush) == "function" and self:QueueVisualRefreshFlush() or true
end

function Client:MarkVisiblePlayerTooltipDirty(reason, payload)
    local dirtyState = ensureDirtyUiRefreshState(self)
    dirtyState.visibleTooltipsDirty = true
    dirtyState.visibleTooltipPayload = mergeTooltipPayload(dirtyState.visibleTooltipPayload, payload)
    self.PendingVisiblePlayerTooltipRefreshReason = tostring(
        self.PendingVisiblePlayerTooltipRefreshReason or reason or "tooltip"
    )
    self.VisiblePlayerTooltipRefreshQueued = true
    return type(self.QueueVisualRefreshFlush) == "function" and self:QueueVisualRefreshFlush() or true
end

function Client:MarkEventWidgetPortraitsDirty(reason, eventIds)
    mergeQueuedEventTargetIds(self, eventIds)
    self.PendingEventWidgetRefreshReason = tostring(self.PendingEventWidgetRefreshReason or reason or "event")
    self.EventWidgetRefreshQueued = true
    return type(self.QueueVisualRefreshFlush) == "function" and self:QueueVisualRefreshFlush() or true
end

function Client:MarkTargetingDirty(reason)
    local dirtyState = ensureDirtyUiRefreshState(self)
    dirtyState.targetingDirty = true
    self.PendingTargetingWidgetRefreshReason = tostring(self.PendingTargetingWidgetRefreshReason or reason or "targeting")
    self.TargetingWidgetRefreshQueued = true
    return type(self.QueueVisualRefreshFlush) == "function" and self:QueueVisualRefreshFlush() or true
end

function Spellcasting.RefreshVisiblePlayerTooltip(reason, options)
    local timingEnabled = isSpellcastTimingEnabled()
    local totalStartTime = timingEnabled and getNowMilliseconds() or nil
    local refreshed = false
    local immediate = type(options) == "table" and options.immediate == true
    local skipCompanionBars = type(options) == "table" and options.skipCompanionBars == true
    local payload = type(options) == "table" and options.payload or nil
    if immediate then
        refreshed = refreshVisiblePlayerTooltipImmediate(reason, payload) or refreshed
        if skipCompanionBars ~= true and type(Client.RefreshActionBarCompanionBars) == "function" then
            refreshed = Client:RefreshActionBarCompanionBars(reason) or refreshed
        end
        if timingEnabled then
            logSpellcastTimingLine(
                "Spellcast visual timing",
                ("%s/immediate"):format(tostring(reason or "visual")),
                {
                    { label = "tooltip", elapsed = getNowMilliseconds() - totalStartTime },
                },
                getNowMilliseconds() - totalStartTime,
                SPELLCAST_SLOW_HELPER_MS
            )
        end
        return refreshed
    end

    local tooltipElapsed = 0
    local companionElapsed = 0
    local tooltipStartTime = timingEnabled and getNowMilliseconds() or nil
    if type(Client.MarkVisiblePlayerTooltipDirty) == "function" then
        refreshed = Client:MarkVisiblePlayerTooltipDirty(reason, payload) or refreshed
    elseif type(Client.QueueVisiblePlayerTooltipRefresh) == "function" then
        refreshed = Client:QueueVisiblePlayerTooltipRefresh(reason) or refreshed
    else
        refreshed = refreshVisiblePlayerTooltipImmediate(reason, payload) or refreshed
    end
    if timingEnabled then
        tooltipElapsed = getNowMilliseconds() - tooltipStartTime
    end

    local companionStartTime = timingEnabled and getNowMilliseconds() or nil
    if skipCompanionBars ~= true and type(Client.MarkActionBarCompanionBarsDirty) == "function" then
        refreshed = Client:MarkActionBarCompanionBarsDirty(reason) or refreshed
    elseif skipCompanionBars ~= true and type(Client.QueueActionBarCompanionBarsRefresh) == "function" then
        refreshed = Client:QueueActionBarCompanionBarsRefresh(reason) or refreshed
    elseif skipCompanionBars ~= true and type(Client.RefreshActionBarCompanionBars) == "function" then
        refreshed = Client:RefreshActionBarCompanionBars(reason) or refreshed
    end
    if timingEnabled then
        companionElapsed = getNowMilliseconds() - companionStartTime
        logSpellcastTimingLine(
            "Spellcast visual timing",
            ("%s/deferred"):format(tostring(reason or "visual")),
            {
                { label = "tooltip", elapsed = tooltipElapsed },
                { label = "companion-bars", elapsed = companionElapsed },
            },
            getNowMilliseconds() - totalStartTime,
            SPELLCAST_SLOW_HELPER_MS
        )
    end

    return refreshed
end

function Spellcasting.ValidateInboundSpellcast(self, arguments, sender)
    local sessionState, eventState = Spellcasting.GetActiveSpellcastContext(self)
    if not sessionState or not eventState then
        return nil
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or channelName ~= sessionState.channelName then
        return nil
    end

    local eventId = arguments and arguments[2] or nil
    if type(eventId) ~= "string" or eventId == "" or eventState.id ~= eventId then
        return nil
    end

    local casterEventId = tonumber(arguments and arguments[3]) or 0
    if casterEventId <= 0 then
        return nil
    end

    local spellRef = arguments and arguments[4] or nil
    local dataset, spell = nil, nil
    if Registry.ResolveSpellReference then
        dataset, spell = Registry:ResolveSpellReference(spellRef)
    end
    if not dataset or not spell then
        return nil
    end

    local authorityType = tostring(arguments and arguments[6] or arguments and arguments[5] or "")
    if authorityType ~= "player" and authorityType ~= "npc" then
        return nil
    end

    local casterUnit = Lookup.FindEventUnitById and Lookup.FindEventUnitById(eventState.units, casterEventId) or nil
    local eventClass = getEventClass()
    if not casterUnit or (eventClass and eventClass.IsUnitActive and not eventClass.IsUnitActive(casterUnit)) then
        return nil
    end

    if authorityType == "player" and casterUnit.isPlayer ~= true then
        return nil
    end

    if authorityType == "npc" and casterUnit.isPlayer == true then
        return nil
    end

    local normalizedSender = Spellcasting.NormalizeName(sender)
    if authorityType == "player" then
        local expectedSender = Spellcasting.NormalizeName(casterUnit.ownerID or casterUnit.controllerID or casterUnit.name)
        if normalizedSender == "" or expectedSender == "" or normalizedSender ~= expectedSender then
            return nil
        end
    else
        local controllerUnit = Spellcasting.ResolveControllerPlayerUnit(eventState, casterUnit)
        local expectedSender = Spellcasting.NormalizeName(controllerUnit and (controllerUnit.ownerID or controllerUnit.controllerID or controllerUnit.name) or nil)
        if normalizedSender == "" or expectedSender == "" or normalizedSender ~= expectedSender then
            return nil
        end
    end

    return {
        sessionState = sessionState,
        eventState = eventState,
        channelName = channelName,
        eventId = eventId,
        casterEventId = casterEventId,
        casterUnit = casterUnit,
        spellRef = spellRef,
        spell = spell,
        authorityType = authorityType,
        sender = normalizedSender,
        castTurns = Spellcasting.NormalizeTurnCount(arguments and arguments[5]),
    }
end

function Spellcasting.ShouldSuppressLoopbackLog(self, eventId, casterEventId, spellRef, authorityType, sender, phase)
    if Spellcasting.NormalizeName(sender) ~= Spellcasting.GetLocalPlayerName() then
        return false
    end

    if authorityType == "player" then
        return true
    end

    local existing = Spellcasting.GetCastEntry(self, eventId, casterEventId)
    if phase == "start" then
        return existing ~= nil
            and existing.spellRef == spellRef
            and existing.authorityType == authorityType
    end

    if phase == "complete" or phase == "interrupt" then
        return existing == nil
    end

    return false
end

function Spellcasting.IsLocalCasterEntry(self, eventId, casterEventId)
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not eventState or eventState.active ~= true or eventState.id ~= eventId then
        return false
    end

    local localUnit = self.ResolveLocalEventUnit and self:ResolveLocalEventUnit(eventState) or nil
    if type(localUnit) ~= "table" then
        return false
    end

    local numericCasterEventId = tonumber(casterEventId) or 0
    if numericCasterEventId <= 0 then
        return false
    end

    if tonumber(localUnit.eventID) == numericCasterEventId then
        return true
    end

    local casterUnit = Lookup.FindEventUnitById and Lookup.FindEventUnitById(eventState.units, numericCasterEventId) or nil
    if type(casterUnit) ~= "table" then
        return false
    end

    if casterUnit.isPlayer == true then
        local localPlayerName = Spellcasting.GetLocalPlayerName()
        local casterPlayerName = Spellcasting.NormalizeName(casterUnit.ownerID or casterUnit.controllerID or casterUnit.name)
        return localPlayerName ~= "" and casterPlayerName ~= "" and casterPlayerName == localPlayerName
    end

    local controllerUnit = Spellcasting.ResolveControllerPlayerUnit(eventState, casterUnit)
    if type(controllerUnit) == "table" and tonumber(controllerUnit.eventID) == tonumber(localUnit.eventID) then
        return true
    end

    local localPlayerName = Spellcasting.GetLocalPlayerName()
    local controllerName = Spellcasting.NormalizeName(
        controllerUnit and (controllerUnit.ownerID or controllerUnit.controllerID or controllerUnit.name)
            or casterUnit.controllerID
            or nil
    )
    return localPlayerName ~= "" and controllerName ~= "" and controllerName == localPlayerName
end
