local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Lookup = Addon.Utils and Addon.Utils.Lookup or {}
local ResourceSync = Addon.Internal and Addon.Internal.Comms and Addon.Internal.Comms.ResourceSync or {}

local function enqueuePendingRefresh(fn, ...)
    local tasks = Addon.Internal and Addon.Internal.Tasks or nil
    if tasks and type(tasks.Enqueue) == "function" then
        tasks:Enqueue(fn, ...)
        return true
    end

    fn(...)
    return true
end

local function normalizeRef(value)
    if type(value) ~= "string" or value == "" then
        return nil
    end
    return value
end

local function normalizePendingScope(value)
    return tostring(value or "turn") == "reaction" and "reaction" or "turn"
end

local function getUnitByEventId(eventState, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 or type(eventState) ~= "table" then
        return nil
    end

    local units = eventState.units or {}
    for index = 1, #units do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end
    return nil
end

local function getUnitName(eventState, eventId)
    local unit = getUnitByEventId(eventState, eventId)
    return unit and tostring(unit.name or ("Unit #" .. tostring(eventId))) or ("Unit #" .. tostring(eventId or 0))
end

local function getResourceName(resourceRef)
    if ResourceSync.ResolveResourceName then
        return ResourceSync.ResolveResourceName(resourceRef)
    end
    return tostring(resourceRef or "Resource")
end

local function getAuraName(auraRef)
    local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.ResolveAuraDefinition) == "function" then
        local _, aura = auraManager:ResolveAuraDefinition(auraRef)
        if type(aura) == "table" and tostring(aura.name or "") ~= "" then
            return tostring(aura.name)
        end
    end
    return tostring(auraRef or "Aura")
end

local function findResourceEntry(resources, resourceRef)
    local normalizedRef = normalizeRef(resourceRef)
    if not normalizedRef then
        return nil
    end

    for index = 1, #((resources) or {}) do
        local entry = resources[index]
        if entry and entry.resourceRef == normalizedRef then
            return entry
        end
    end

    return nil
end

local function buildResourceSummary(client, sessionState, eventState)
    local targetedResourceDeltas = {}
    for _, batch in pairs(client.PendingResourceDeltaBatches or {}) do
        if type(batch) == "table"
            and batch.state == sessionState
            and batch.channelName == sessionState.channelName
            and normalizePendingScope(batch.scope) == "turn"
            and type(batch.resourceDeltas) == "table"
            and #batch.resourceDeltas > 0
        then
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

    local rows = {}
    for index = 1, #(targetedResourceDeltas or {}) do
        local entry = targetedResourceDeltas[index]
        local targetEventId = tonumber(entry and entry.targetEventId) or 0
        local resourceRef = normalizeRef(entry and entry.resourceRef)
        if targetEventId > 0 and resourceRef then
            local unit = getUnitByEventId(eventState, targetEventId)
            local resolvedResources = nil
            if type(client.ResolveActiveSpellcasterUnit) == "function" then
                local activeEventUnit = select(1, client:ResolveActiveSpellcasterUnit(eventState))
                if tonumber(activeEventUnit and activeEventUnit.eventID) == targetEventId
                    and type(client.ResolveLocalActiveSpellcasterResources) == "function"
                then
                    resolvedResources = client:ResolveLocalActiveSpellcasterResources(eventState, activeEventUnit, {
                        clone = true,
                    })
                    unit = activeEventUnit or unit
                end
            end
            local resourceEntry = findResourceEntry(resolvedResources, resourceRef)
                or (Lookup.GetResourceEntry and Lookup.GetResourceEntry(unit, resourceRef) or nil)
            local currentValue = tonumber(entry.currentValue)
            if currentValue == nil then
                currentValue = tonumber(resourceEntry and resourceEntry.currentValue)
            end
            local maxValue = tonumber(entry.maxValue)
            if maxValue == nil then
                maxValue = tonumber(resourceEntry and resourceEntry.maxValue)
            end

            rows[#rows + 1] = {
                targetEventId = targetEventId,
                targetName = getUnitName(eventState, targetEventId),
                resourceRef = resourceRef,
                resourceName = getResourceName(resourceRef),
                delta = tonumber(entry.delta) or 0,
                currentValue = currentValue,
                maxValue = maxValue,
            }
        end
    end
    return rows
end

local function buildAuraSummary(client, sessionState, eventState)
    local rows = {}
    local pendingOperations = client.PendingOutboundAuraOperations or {}
    local pendingOrderByScope = client.PendingOutboundAuraOperationOrderByScope or {}
    local pendingOrder = pendingOrderByScope.turn or client.PendingOutboundAuraOperationOrder or {}
    for index = 1, #pendingOrder do
        local operation = pendingOperations[pendingOrder[index]]
        if type(operation) == "table"
            and operation.sessionState == sessionState
            and operation.eventState == eventState
            and tostring(operation.eventId or "") == tostring(eventState.id or "")
            and normalizePendingScope(operation.scope) == "turn"
        then
            local auraRef = normalizeRef(operation.auraRef)
            if auraRef then
                rows[#rows + 1] = {
                    action = operation.kind == "dispel" and "dispel" or "apply",
                    auraRef = auraRef,
                    auraName = getAuraName(auraRef),
                    casterEventId = tonumber(operation.casterEventId) or 0,
                    casterName = getUnitName(eventState, operation.casterEventId),
                    targetEventId = tonumber(operation.targetEventId) or 0,
                    targetName = getUnitName(eventState, operation.targetEventId),
                    stacks = tonumber(operation.stacks) or 0,
                    turns = tonumber(operation.turnsRemaining) or 0,
                    fullState = operation.fullState == true,
                }
            end
        end
    end
    return rows
end

function Client:GetPendingTurnChanges(eventStateOverride)
    local sessionState = self.GetState and self:GetState() or self.State
    local eventState = eventStateOverride or (self.GetEventState and self:GetEventState() or self.EventState)
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.channelName ~= sessionState.channelName
    then
        return {
            resources = {},
            auras = {},
            resourceCount = 0,
            auraCount = 0,
            totalCount = 0,
        }
    end

    local resources = buildResourceSummary(self, sessionState, eventState)
    local auras = buildAuraSummary(self, sessionState, eventState)
    return {
        resources = resources,
        auras = auras,
        resourceCount = #resources,
        auraCount = #auras,
        totalCount = #resources + #auras,
    }
end

local function formatSigned(value)
    local numeric = tonumber(value) or 0
    if numeric > 0 then
        return "+" .. tostring(numeric)
    end
    return tostring(numeric)
end

local function formatValuePair(currentValue, maxValue)
    if currentValue ~= nil and maxValue ~= nil then
        return (" (%s/%s)"):format(tostring(currentValue), tostring(maxValue))
    end
    if currentValue ~= nil then
        return (" (%s)"):format(tostring(currentValue))
    end
    return ""
end

function Client:BuildPendingTurnChangesTooltip(eventStateOverride)
    local summary = self.GetPendingTurnChanges and self:GetPendingTurnChanges(eventStateOverride) or {
        resources = {},
        auras = {},
        resourceCount = 0,
        auraCount = 0,
        totalCount = 0,
    }
    local lines = {
        {
            left = "Pending",
            right = ("%d total"):format(tonumber(summary.totalCount) or 0),
            colorToken = "text.secondary",
        },
    }

    if (tonumber(summary.totalCount) or 0) <= 0 then
        lines[#lines + 1] = {
            text = "No pending changes.",
            colorToken = "text.muted",
        }
    else
        if #(summary.resources or {}) > 0 then
            lines[#lines + 1] = {
                text = "Resources",
                colorToken = "text.primary",
            }
            for index = 1, #summary.resources do
                local entry = summary.resources[index]
                lines[#lines + 1] = {
                    left = ("%s: %s"):format(tostring(entry.targetName or "Unknown"), tostring(entry.resourceName or entry.resourceRef or "Resource")),
                    right = ("%s%s"):format(formatSigned(entry.delta), formatValuePair(entry.currentValue, entry.maxValue)),
                    colorToken = "text.secondary",
                }
            end
        end

        if #(summary.auras or {}) > 0 then
            lines[#lines + 1] = {
                text = "Auras",
                colorToken = "text.primary",
            }
            for index = 1, #summary.auras do
                local entry = summary.auras[index]
                local detail = entry.action == "dispel"
                    and "remove"
                    or ("%s stack(s), %s turn(s)%s"):format(
                        tostring(entry.stacks or 0),
                        tostring(entry.turns or 0),
                        entry.fullState and " full-state" or ""
                    )
                lines[#lines + 1] = {
                    left = ("%s -> %s: %s"):format(
                        tostring(entry.casterName or "Unknown"),
                        tostring(entry.targetName or "Unknown"),
                        tostring(entry.auraName or entry.auraRef or "Aura")
                    ),
                    right = entry.action == "dispel" and detail or ("apply " .. detail),
                    colorToken = "text.secondary",
                }
            end
        end
    end

    lines[#lines + 1] = {
        text = "Click this control to broadcast these changes.",
        colorToken = "text.muted",
    }

    return {
        type = "custom",
        title = "End Turn",
        width = 360,
        lines = lines,
    }
end

function Client:ShowPendingTurnChangesTooltip(owner, eventStateOverride)
    local tooltip = Addon.UI and Addon.UI.Tooltip or nil
    if not tooltip or type(tooltip.ShowForElement) ~= "function" then
        return false
    end

    self.PendingTurnChangesTooltipOwner = owner
    tooltip:ShowForElement(owner, self:BuildPendingTurnChangesTooltip(eventStateOverride))
    return true
end

function Client:HidePendingTurnChangesTooltip()
    local tooltip = Addon.UI and Addon.UI.Tooltip or nil
    self.PendingTurnChangesTooltipOwner = nil
    if tooltip and type(tooltip.Hide) == "function" then
        tooltip:Hide()
    end
    return true
end

function Client:RefreshPendingTurnChangesTooltip()
    local owner = self.PendingTurnChangesTooltipOwner
    local tooltip = Addon.UI and Addon.UI.Tooltip or nil
    if not owner or not tooltip or type(tooltip.RefreshForElement) ~= "function" then
        return false
    end

    return tooltip:RefreshForElement(owner, self:BuildPendingTurnChangesTooltip())
end

function Client:QueuePendingTurnChangesTooltipRefresh()
    if self.PendingTurnChangesTooltipRefreshQueued == true then
        return true
    end

    self.PendingTurnChangesTooltipRefreshQueued = true
    return enqueuePendingRefresh(function(targetClient)
        targetClient.PendingTurnChangesTooltipRefreshQueued = false
        if type(targetClient.RefreshPendingTurnChangesTooltip) == "function" then
            targetClient:RefreshPendingTurnChangesTooltip()
        end
    end, self)
end
