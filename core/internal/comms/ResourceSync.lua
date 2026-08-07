local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}
Addon.Utils = Addon.Utils or {}

local ResourceSync = Addon.Internal.Comms.ResourceSync or {}
Addon.Internal.Comms.ResourceSync = ResourceSync

local Profile = Addon.Internal.Profile or {}
local Database = Addon.Internal.Database or {}
local Ruleset = Addon.Internal.Ruleset or {}
local Common = Addon.Utils.Common or {}

local RESOURCE_RECORD_SEPARATOR = string.char(27)
local RESOURCE_FIELD_SEPARATOR = string.char(26)

local function getEventUnitClass()
    return Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.EventUnit
        or nil
end

local function normalizePlayerName(name)
    if Common.NormalizeName then
        return Common.NormalizeName(name)
    end

    return type(name) == "string" and name or ""
end

local function normalizeResourceEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local resourceRef = entry.resourceRef or entry.resourceID or entry.id
    if resourceRef == nil or resourceRef == "" then
        return nil
    end

    return {
        resourceRef = tostring(resourceRef),
        currentValue = tonumber(entry.currentValue ~= nil and entry.currentValue or entry.current or entry.value) or 0,
        maxValue = tonumber(entry.maxValue ~= nil and entry.maxValue or entry.max or entry.maximum) or 0,
    }
end

local function normalizeResourceDeltaEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local resourceRef = entry.resourceRef or entry.resourceID or entry.id
    if resourceRef == nil or resourceRef == "" then
        return nil
    end

    local currentValue = entry.currentValue
    if currentValue == nil then
        currentValue = entry.current ~= nil and entry.current or entry.value
    end

    return {
        resourceRef = tostring(resourceRef),
        delta = tonumber(entry.delta) or 0,
        maxValue = tonumber(entry.maxValue ~= nil and entry.maxValue or entry.max or entry.maximum) or 0,
        currentValue = currentValue ~= nil and tonumber(currentValue) or nil,
    }
end

local function normalizeTargetedResourceDeltaEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local targetEventId = tonumber(entry.targetEventId or entry.eventId or entry.targetID) or 0
    if targetEventId <= 0 then
        return nil
    end

    local normalized = normalizeResourceDeltaEntry(entry)
    if not normalized then
        return nil
    end

    normalized.targetEventId = targetEventId
    return normalized
end

local function getHealthResourceRef()
    local activeRuleset = Ruleset and Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset and Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("resources", "health_stat") or nil
    local healthResourceRef = Ruleset and Ruleset.GetRulesetRuleValue and Ruleset.GetRulesetRuleValue(activeRuleset, "resources", ruleDefinition) or nil

    if type(healthResourceRef) ~= "string" or healthResourceRef == "" then
        return ""
    end

    return healthResourceRef
end

local function hasResourceRef(resources, resourceRef)
    if type(resourceRef) ~= "string" or resourceRef == "" then
        return false
    end

    for index = 1, #((resources) or {}) do
        local entry = resources[index]
        if entry and entry.resourceRef == resourceRef then
            return true
        end
    end

    return false
end

local function resolveHealthResourceRef(options)
    local healthResourceRef = type(options) == "table" and options.healthResourceRef or nil
    if type(healthResourceRef) == "string" and healthResourceRef ~= "" then
        return healthResourceRef
    end

    return getHealthResourceRef()
end

local function buildTrackedProfileResourceRefLookup()
    local lookup = {}

    local function append(resourceRef)
        if type(resourceRef) ~= "string" or resourceRef == "" then
            return
        end

        lookup[resourceRef] = true
    end

    local healthResourceRef = type(Profile.GetHealthResourceRef) == "function" and Profile.GetHealthResourceRef() or nil
    append(healthResourceRef)
    if type(healthResourceRef) ~= "string" or healthResourceRef == "" then
        append(getHealthResourceRef())
    end
    append(type(Profile.GetPrimaryResourceRef) == "function" and Profile.GetPrimaryResourceRef() or nil)
    append(type(Profile.GetSpecialResourceRef) == "function" and Profile.GetSpecialResourceRef() or nil)

    return lookup
end

local function getTrackedLocalPlayerResources()
    local client = Addon.Client or nil
    local sessionState = type(client) == "table"
        and type(client.GetState) == "function"
        and client:GetState()
        or (type(client) == "table" and client.State or nil)
    if type(sessionState) ~= "table" or type(sessionState.membersByName) ~= "table" then
        return nil
    end

    local playerName = normalizePlayerName(Common.GetPlayerName and Common.GetPlayerName() or nil)
    if playerName == "" then
        return nil
    end

    local member = sessionState.membersByName[playerName]
    local resources = member and member.resources or nil
    if type(resources) ~= "table" or #resources == 0 then
        return nil
    end

    return ResourceSync.CloneResources(resources)
end

local function resolveResourceDefinition(resourceRef)
    if type(resourceRef) ~= "string" or resourceRef == "" or type(Database.GetDatasetByID) ~= "function" then
        return nil, nil
    end

    local separatorIndex = string.find(resourceRef, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = string.sub(resourceRef, 1, separatorIndex - 1)
    local resourceId = string.sub(resourceRef, separatorIndex + 1)
    if datasetId == "" or resourceId == "" then
        return nil, nil
    end

    local dataset = Database.GetDatasetByID(datasetId)
    for index = 1, #((dataset and dataset.resources) or {}) do
        local resource = dataset.resources[index]
        if resource and resource.id == resourceId then
            return resource, dataset
        end
    end

    return nil, dataset
end

local function mergeResourcesByRef(existingResources, incomingResources)
    local normalizedIncoming = ResourceSync.NormalizeResources(incomingResources)
    if type(existingResources) ~= "table" then
        return ResourceSync.CloneResources(normalizedIncoming)
    end

    local merged = ResourceSync.CloneResources(existingResources)
    local indexByRef = {}
    for index = 1, #merged do
        local entry = merged[index]
        if type(entry) == "table" and type(entry.resourceRef) == "string" and entry.resourceRef ~= "" then
            indexByRef[entry.resourceRef] = index
        end
    end

    for index = 1, #normalizedIncoming do
        local entry = normalizedIncoming[index]
        if type(entry) == "table" and type(entry.resourceRef) == "string" and entry.resourceRef ~= "" then
            local existingIndex = indexByRef[entry.resourceRef]
            if existingIndex then
                merged[existingIndex] = ResourceSync.CloneResources({ entry })[1]
            else
                merged[#merged + 1] = ResourceSync.CloneResources({ entry })[1]
                indexByRef[entry.resourceRef] = #merged
            end
        end
    end

    return merged
end

function ResourceSync.MergeResourcesByRef(existingResources, incomingResources)
    return mergeResourcesByRef(existingResources, incomingResources)
end

function ResourceSync.NormalizeResources(resourcesOrPayload)
    local eventUnitClass = getEventUnitClass()
    if type(resourcesOrPayload) == "string" then
        if eventUnitClass and eventUnitClass.DeserializeResourcesFromNetwork then
            return eventUnitClass.DeserializeResourcesFromNetwork(resourcesOrPayload)
        end

        local normalized = {}
        if resourcesOrPayload == "" then
            return normalized
        end

        local records = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(resourcesOrPayload, RESOURCE_RECORD_SEPARATOR) or {}
        for index = 1, #records do
            local values = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(records[index], RESOURCE_FIELD_SEPARATOR) or {}
            local entry = normalizeResourceEntry({
                resourceRef = values[1],
                currentValue = values[2],
                maxValue = values[3],
            })
            if entry then
                normalized[#normalized + 1] = entry
            end
        end

        return normalized
    end

    if type(resourcesOrPayload) ~= "table" then
        return {}
    end

    if eventUnitClass and eventUnitClass.SerializeResourcesForNetwork and eventUnitClass.DeserializeResourcesFromNetwork then
        return eventUnitClass.DeserializeResourcesFromNetwork(
            eventUnitClass.SerializeResourcesForNetwork(resourcesOrPayload)
        )
    end

    local normalized = {}
    for index = 1, #resourcesOrPayload do
        local entry = normalizeResourceEntry(resourcesOrPayload[index])
        if entry then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

function ResourceSync.CloneResources(resources)
    return ResourceSync.NormalizeResources(resources)
end

function ResourceSync.NormalizeResourceDeltas(resourceDeltasOrPayload)
    if type(resourceDeltasOrPayload) == "string" then
        local normalized = {}
        if resourceDeltasOrPayload == "" then
            return normalized
        end

        local records = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(resourceDeltasOrPayload, RESOURCE_RECORD_SEPARATOR) or {}
        for index = 1, #records do
            local values = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(records[index], RESOURCE_FIELD_SEPARATOR) or {}
            local entry = normalizeResourceDeltaEntry({
                resourceRef = values[1],
                delta = values[2],
                maxValue = values[3],
            })
            if entry then
                normalized[#normalized + 1] = entry
            end
        end

        return normalized
    end

    if type(resourceDeltasOrPayload) ~= "table" then
        return {}
    end

    local normalized = {}
    for index = 1, #resourceDeltasOrPayload do
        local entry = normalizeResourceDeltaEntry(resourceDeltasOrPayload[index])
        if entry then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

function ResourceSync.CloneResourceDeltas(resourceDeltas)
    return ResourceSync.NormalizeResourceDeltas(resourceDeltas)
end

function ResourceSync.CoalesceResourceDeltas(resourceDeltas, additionalResourceDeltas)
    local order = {}
    local byRef = {}

    local function mergeList(values)
        local normalized = ResourceSync.NormalizeResourceDeltas(values)
        for index = 1, #normalized do
            local entry = normalized[index]
            if type(entry) == "table" and type(entry.resourceRef) == "string" and entry.resourceRef ~= "" then
                local existing = byRef[entry.resourceRef]
                if not existing then
                    existing = {
                        resourceRef = entry.resourceRef,
                        delta = 0,
                        maxValue = tonumber(entry.maxValue) or 0,
                        currentValue = entry.currentValue,
                    }
                    byRef[entry.resourceRef] = existing
                    order[#order + 1] = existing
                end

                existing.delta = (tonumber(existing.delta) or 0) + (tonumber(entry.delta) or 0)
                existing.maxValue = tonumber(entry.maxValue) or 0
                if entry.currentValue ~= nil then
                    existing.currentValue = tonumber(entry.currentValue) or 0
                end
            end
        end
    end

    mergeList(resourceDeltas)
    mergeList(additionalResourceDeltas)

    local coalesced = {}
    for index = 1, #order do
        local entry = order[index]
        if (tonumber(entry.delta) or 0) ~= 0 then
            coalesced[#coalesced + 1] = {
                resourceRef = entry.resourceRef,
                delta = tonumber(entry.delta) or 0,
                maxValue = tonumber(entry.maxValue) or 0,
                currentValue = entry.currentValue ~= nil and (tonumber(entry.currentValue) or 0) or nil,
            }
        end
    end

    return coalesced
end

function ResourceSync.NormalizeTargetedResourceDeltas(targetedResourceDeltasOrPayload)
    if type(targetedResourceDeltasOrPayload) == "string" then
        local normalized = {}
        if targetedResourceDeltasOrPayload == "" then
            return normalized
        end

        local records = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(targetedResourceDeltasOrPayload, RESOURCE_RECORD_SEPARATOR) or {}
        for index = 1, #records do
            local values = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(records[index], RESOURCE_FIELD_SEPARATOR) or {}
            local entry = normalizeTargetedResourceDeltaEntry({
                targetEventId = values[1],
                resourceRef = values[2],
                delta = values[3],
                maxValue = values[4],
            })
            if entry then
                normalized[#normalized + 1] = entry
            end
        end

        return normalized
    end

    if type(targetedResourceDeltasOrPayload) ~= "table" then
        return {}
    end

    local normalized = {}
    for index = 1, #targetedResourceDeltasOrPayload do
        local entry = targetedResourceDeltasOrPayload[index]
        if type(entry) == "table" and type(entry.resourceDeltas) == "table" then
            local targetEventId = tonumber(entry.targetEventId) or 0
            if targetEventId > 0 then
                local deltas = ResourceSync.NormalizeResourceDeltas(entry.resourceDeltas)
                for deltaIndex = 1, #deltas do
                    local normalizedEntry = normalizeTargetedResourceDeltaEntry({
                        targetEventId = targetEventId,
                        resourceRef = deltas[deltaIndex].resourceRef,
                        delta = deltas[deltaIndex].delta,
                        maxValue = deltas[deltaIndex].maxValue,
                        currentValue = deltas[deltaIndex].currentValue,
                    })
                    if normalizedEntry then
                        normalized[#normalized + 1] = normalizedEntry
                    end
                end
            end
        else
            local normalizedEntry = normalizeTargetedResourceDeltaEntry(entry)
            if normalizedEntry then
                normalized[#normalized + 1] = normalizedEntry
            end
        end
    end

    return normalized
end

function ResourceSync.CoalesceTargetedResourceDeltas(targetedResourceDeltas, additionalTargetedResourceDeltas)
    local order = {}
    local byKey = {}

    local function mergeList(values)
        local normalized = ResourceSync.NormalizeTargetedResourceDeltas(values)
        for index = 1, #normalized do
            local entry = normalized[index]
            local key = table.concat({
                tostring(tonumber(entry.targetEventId) or 0),
                tostring(entry.resourceRef or ""),
            }, "\31")
            local existing = byKey[key]
            if not existing then
                existing = {
                    targetEventId = tonumber(entry.targetEventId) or 0,
                    resourceRef = entry.resourceRef,
                    delta = 0,
                    maxValue = tonumber(entry.maxValue) or 0,
                    currentValue = entry.currentValue,
                }
                byKey[key] = existing
                order[#order + 1] = existing
            end

            existing.delta = (tonumber(existing.delta) or 0) + (tonumber(entry.delta) or 0)
            existing.maxValue = tonumber(entry.maxValue) or 0
            if entry.currentValue ~= nil then
                existing.currentValue = tonumber(entry.currentValue) or 0
            end
        end
    end

    mergeList(targetedResourceDeltas)
    mergeList(additionalTargetedResourceDeltas)

    local coalesced = {}
    for index = 1, #order do
        local entry = order[index]
        if (tonumber(entry.delta) or 0) ~= 0 then
            coalesced[#coalesced + 1] = {
                targetEventId = tonumber(entry.targetEventId) or 0,
                resourceRef = entry.resourceRef,
                delta = tonumber(entry.delta) or 0,
                maxValue = tonumber(entry.maxValue) or 0,
                currentValue = entry.currentValue ~= nil and (tonumber(entry.currentValue) or 0) or nil,
            }
        end
    end

    return coalesced
end

function ResourceSync.SerializeResources(resources)
    local normalized = ResourceSync.NormalizeResources(resources)
    local eventUnitClass = getEventUnitClass()
    if eventUnitClass and eventUnitClass.SerializeResourcesForNetwork then
        return eventUnitClass.SerializeResourcesForNetwork(normalized)
    end

    local records = {}
    for index = 1, #normalized do
        local entry = normalized[index]
        records[#records + 1] = table.concat({
            tostring(entry.resourceRef or ""),
            tostring(entry.currentValue or 0),
            tostring(entry.maxValue or 0),
        }, RESOURCE_FIELD_SEPARATOR)
    end

    return table.concat(records, RESOURCE_RECORD_SEPARATOR)
end

function ResourceSync.SerializeResourceDeltas(resourceDeltas)
    local normalized = ResourceSync.NormalizeResourceDeltas(resourceDeltas)
    local records = {}

    for index = 1, #normalized do
        local entry = normalized[index]
        records[#records + 1] = table.concat({
            tostring(entry.resourceRef or ""),
            tostring(entry.delta or 0),
            tostring(entry.maxValue or 0),
        }, RESOURCE_FIELD_SEPARATOR)
    end

    return table.concat(records, RESOURCE_RECORD_SEPARATOR)
end

function ResourceSync.SerializeTargetedResourceDeltas(targetedResourceDeltas)
    local normalized = ResourceSync.NormalizeTargetedResourceDeltas(targetedResourceDeltas)
    local records = {}

    for index = 1, #normalized do
        local entry = normalized[index]
        records[#records + 1] = table.concat({
            tostring(entry.targetEventId or 0),
            tostring(entry.resourceRef or ""),
            tostring(entry.delta or 0),
            tostring(entry.maxValue or 0),
        }, RESOURCE_FIELD_SEPARATOR)
    end

    return table.concat(records, RESOURCE_RECORD_SEPARATOR)
end

function ResourceSync.BuildProfileResourceSnapshot()
    local rows = Profile.ListResolvedResources and Profile.ListResolvedResources() or {}
    local trackedResourceRefs = buildTrackedProfileResourceRefLookup()
    local trackedResources = getTrackedLocalPlayerResources() or {}
    local trackedResourcesByRef = {}
    local resources = {}

    for index = 1, #trackedResources do
        local entry = trackedResources[index]
        if type(entry) == "table" and type(entry.resourceRef) == "string" and entry.resourceRef ~= "" then
            trackedResourcesByRef[entry.resourceRef] = entry
        end
    end

    for index = 1, #rows do
        local row = rows[index]
        local resourceRef = type(row and row.ref) == "string" and row.ref or ""
        if trackedResourceRefs[resourceRef] == true then
            local maxValue = tonumber(row.value) or 0
            local startsAtZero = row.resource and row.resource.startsAtZero == true
            local trackedEntry = trackedResourcesByRef[resourceRef]
            local currentValue = tonumber(trackedEntry and trackedEntry.currentValue)
            if currentValue == nil then
                currentValue = tonumber(trackedEntry and trackedEntry.maxValue)
            end
            if currentValue == nil then
                currentValue = startsAtZero and 0 or maxValue
            end
            currentValue = math.max(0, math.min(currentValue, maxValue))

            resources[#resources + 1] = {
                resourceRef = resourceRef,
                currentValue = currentValue,
                maxValue = maxValue,
            }
        end
    end

    return ResourceSync.NormalizeResources(resources)
end

function ResourceSync.BuildPlayerTurnRegenResourceDeltas(resources, options)
    local normalizedResources = ResourceSync.CloneResources(resources)
    if type(normalizedResources) ~= "table" or #normalizedResources == 0 then
        return {}
    end

    local resourceDeltas = {}
    local resolvedRows = Profile.ListResolvedResources and Profile.ListResolvedResources() or {}
    local resolvedRowsByRef = {}
    for index = 1, #resolvedRows do
        local row = resolvedRows[index]
        local rowRef = type(row and row.ref) == "string" and row.ref or ""
        if rowRef ~= "" then
            resolvedRowsByRef[rowRef] = row
        end
    end

    local statResolver = type(options) == "table" and options.resolveStatValue or nil

    for index = 1, #normalizedResources do
        local liveEntry = normalizedResources[index]
        local resourceRef = type(liveEntry and liveEntry.resourceRef) == "string" and liveEntry.resourceRef or ""
        local resolvedRow = resolvedRowsByRef[resourceRef]
        local resourceDefinition = resolvedRow and resolvedRow.resource or select(1, resolveResourceDefinition(resourceRef))
        if type(resourceDefinition) == "table" then
            local regenValue = 0
            if tostring(resourceDefinition.regenMode or "manual") == "derived" then
                local sourceStatRef = type(resourceDefinition.regenSourceStatRef) == "string" and resourceDefinition.regenSourceStatRef or nil
                local statValue = 0
                if sourceStatRef and type(statResolver) == "function" then
                    statValue = statResolver(sourceStatRef, resourceRef)
                elseif sourceStatRef and type(Profile.GetResolvedStatValue) == "function" then
                    statValue = Profile.GetResolvedStatValue(sourceStatRef, 0)
                end
                regenValue = (tonumber(statValue) or 0) * (tonumber(resourceDefinition.regenMultiplier) or 0)
            else
                regenValue = tonumber(resourceDefinition.regenPerSecond) or 0
            end

            if regenValue > 0 then
                resourceDeltas[#resourceDeltas + 1] = {
                    resourceRef = resourceRef,
                    delta = regenValue,
                    maxValue = tonumber(liveEntry.maxValue) or tonumber(resolvedRow and resolvedRow.value) or 0,
                }
            end
        end
    end

    if #resourceDeltas == 0 then
        return {}
    end

    local _, applied = ResourceSync.ApplyResourceDeltasToResources(normalizedResources, resourceDeltas, options)
    local filtered = {}
    for index = 1, #applied do
        local entry = applied[index]
        if type(entry) == "table" and (tonumber(entry.delta) or 0) > 0 then
            filtered[#filtered + 1] = {
                resourceRef = entry.resourceRef,
                delta = tonumber(entry.delta) or 0,
                maxValue = tonumber(entry.maxValue) or 0,
                currentValue = tonumber(entry.currentValue) or 0,
            }
        end
    end

    return filtered
end

function ResourceSync.ResolveResourceName(resourceRef)
    if type(resourceRef) ~= "string" or resourceRef == "" or type(Database.GetDatasetByID) ~= "function" then
        return resourceRef or "unknown"
    end

    local separatorIndex = string.find(resourceRef, ":", 1, true)
    if not separatorIndex then
        return resourceRef
    end

    local datasetId = string.sub(resourceRef, 1, separatorIndex - 1)
    local resourceId = string.sub(resourceRef, separatorIndex + 1)
    if datasetId == "" or resourceId == "" then
        return resourceRef
    end

    local dataset = Database.GetDatasetByID(datasetId)
    for index = 1, #((dataset and dataset.resources) or {}) do
        local resource = dataset.resources[index]
        if resource and resource.id == resourceId then
            return resource.name ~= "" and resource.name or resourceRef
        end
    end

    return resourceRef
end

function ResourceSync.ResourcesEqual(left, right)
    local normalizedLeft = ResourceSync.NormalizeResources(left)
    local normalizedRight = ResourceSync.NormalizeResources(right)
    if #normalizedLeft ~= #normalizedRight then
        return false
    end

    for index = 1, #normalizedLeft do
        local leftEntry = normalizedLeft[index]
        local rightEntry = normalizedRight[index]
        if not rightEntry
            or leftEntry.resourceRef ~= rightEntry.resourceRef
            or leftEntry.currentValue ~= rightEntry.currentValue
            or leftEntry.maxValue ~= rightEntry.maxValue
        then
            return false
        end
    end

    return true
end

function ResourceSync.ResourceDeltasEqual(left, right)
    local normalizedLeft = ResourceSync.NormalizeResourceDeltas(left)
    local normalizedRight = ResourceSync.NormalizeResourceDeltas(right)
    if #normalizedLeft ~= #normalizedRight then
        return false
    end

    for index = 1, #normalizedLeft do
        local leftEntry = normalizedLeft[index]
        local rightEntry = normalizedRight[index]
        if not rightEntry
            or leftEntry.resourceRef ~= rightEntry.resourceRef
            or leftEntry.delta ~= rightEntry.delta
            or leftEntry.maxValue ~= rightEntry.maxValue
        then
            return false
        end
    end

    return true
end

function ResourceSync.ApplyResourceDeltasToResources(resources, resourceDeltas, options)
    if type(resources) ~= "table" then
        return false, {}
    end

    local normalizedDeltas = ResourceSync.NormalizeResourceDeltas(resourceDeltas)
    local healthResourceRef = resolveHealthResourceRef(options)
    local changed = false
    local applied = {}

    for deltaIndex = 1, #normalizedDeltas do
        local deltaEntry = normalizedDeltas[deltaIndex]
        for resourceIndex = 1, #resources do
            local resourceEntry = resources[resourceIndex]
            if resourceEntry and resourceEntry.resourceRef == deltaEntry.resourceRef then
                local currentValue = tonumber(resourceEntry.currentValue)
                if currentValue == nil then
                    currentValue = tonumber(resourceEntry.maxValue) or 0
                end

                local previousMaxValue = tonumber(resourceEntry.maxValue)
                local maxValue = tonumber(deltaEntry.maxValue)
                if maxValue == nil then
                    maxValue = tonumber(resourceEntry.maxValue) or currentValue
                end

                local nextValue = currentValue
                if not (resourceEntry.resourceRef == healthResourceRef and currentValue <= 0) then
                    nextValue = currentValue + (tonumber(deltaEntry.delta) or 0)
                    if nextValue < 0 then
                        nextValue = 0
                    elseif maxValue >= 0 and nextValue > maxValue then
                        nextValue = maxValue
                    end
                end

                local appliedDelta = nextValue - currentValue
                resourceEntry.currentValue = nextValue
                resourceEntry.maxValue = maxValue
                if appliedDelta ~= 0 or previousMaxValue ~= maxValue then
                    changed = true
                end

                applied[#applied + 1] = {
                    resourceRef = resourceEntry.resourceRef,
                    delta = appliedDelta,
                    maxValue = maxValue,
                    currentValue = nextValue,
                }
                break
            end
        end
    end

    return changed, applied
end

function ResourceSync.ApplyResourcesToEventUnits(units, playerName, resources)
    local normalizedPlayerName = normalizePlayerName(playerName)
    if normalizedPlayerName == "" or type(units) ~= "table" then
        return false
    end

    local normalizedResources = ResourceSync.NormalizeResources(resources)
    local updated = false

    for index = 1, #units do
        local unit = units[index]
        if unit and unit.isPlayer == true then
            local ownerName = normalizePlayerName(unit.ownerID or unit.controllerID or unit.name)
            if ownerName == normalizedPlayerName
                and (unit.resources == nil or not ResourceSync.ResourcesEqual(unit.resources, normalizedResources))
            then
                unit.resources = ResourceSync.CloneResources(normalizedResources)
                updated = true
            end
        end
    end

    return updated
end

function ResourceSync.ApplyTrackedPlayerResourcesToEventUnits(playersByName, units)
    if type(playersByName) ~= "table" or type(units) ~= "table" then
        return false
    end

    local updated = false
    for index = 1, #units do
        local unit = units[index]
        if unit and unit.isPlayer == true then
            local ownerName = normalizePlayerName(unit.ownerID or unit.controllerID or unit.name)
            local playerState = ownerName ~= "" and playersByName[ownerName] or nil
            local resources = playerState and playerState.resources or nil
            if type(resources) == "table"
                and (type(unit.resources) ~= "table" or #unit.resources == 0)
            then
                unit.resources = ResourceSync.CloneResources(resources)
                updated = true
            end
        end
    end

    return updated
end

function ResourceSync.ApplyResourcesToEventUnitByEventID(units, eventId, resources)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 or type(units) ~= "table" then
        return false
    end

    local normalizedResources = ResourceSync.NormalizeResources(resources)
    local updated = false

    for index = 1, #units do
        local unit = units[index]
        if unit and tonumber(unit.eventID) == numericEventId then
            local mergedResources = mergeResourcesByRef(unit.resources, normalizedResources)
            if unit.resources == nil or not ResourceSync.ResourcesEqual(unit.resources, mergedResources) then
                unit.resources = mergedResources
                updated = true
            end
            break
        end
    end

    return updated
end

function ResourceSync.ApplyResourceDeltasToEventUnitByEventID(units, eventId, resourceDeltas, options)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 or type(units) ~= "table" then
        return false, nil, {}
    end

    for index = 1, #units do
        local unit = units[index]
        if unit and tonumber(unit.eventID) == numericEventId then
            local changed, applied = ResourceSync.ApplyResourceDeltasToResources(unit.resources, resourceDeltas, options)
            return changed, unit, applied
        end
    end

    return false, nil, {}
end

function ResourceSync.GetEventReadinessState(eventState)
    local units = type(eventState) == "table" and eventState.units or nil
    local healthResourceRef = getHealthResourceRef()
    local unitsChunkExpected = math.max(0, tonumber(eventState and eventState.unitsChunkExpected) or 0)
    local unitsChunkReceived = math.max(0, tonumber(eventState and eventState.unitsChunkReceived) or 0)
    if unitsChunkExpected > 0 and unitsChunkReceived > unitsChunkExpected then
        unitsChunkReceived = unitsChunkExpected
    end

    local playerCount = 0
    local playerWithHealthCount = 0
    for index = 1, #((units) or {}) do
        local unit = units[index]
        if unit and unit.isPlayer == true then
            playerCount = playerCount + 1
            if healthResourceRef == "" or hasResourceRef(unit.resources, healthResourceRef) then
                playerWithHealthCount = playerWithHealthCount + 1
            end
        end
    end

    local healthResourcesExpected = healthResourceRef ~= "" and playerCount or 0
    local healthResourcesReceived = healthResourceRef ~= "" and playerWithHealthCount or healthResourcesExpected
    if healthResourcesReceived > healthResourcesExpected then
        healthResourcesReceived = healthResourcesExpected
    end

    local progressExpected = unitsChunkExpected + healthResourcesExpected
    local progressReceived = unitsChunkReceived + healthResourcesReceived
    local rosterReady = type(eventState) == "table" and eventState.rosterReady == true
    local rosterComplete = rosterReady and (unitsChunkExpected <= 0 or unitsChunkReceived >= unitsChunkExpected)
    local resourcesReady = healthResourcesExpected == 0 or healthResourcesReceived >= healthResourcesExpected

    return {
        healthResourceRef = healthResourceRef,
        unitsChunkExpected = unitsChunkExpected,
        unitsChunkReceived = unitsChunkReceived,
        healthResourcesExpected = healthResourcesExpected,
        healthResourcesReceived = healthResourcesReceived,
        readyProgressExpected = progressExpected,
        readyProgressReceived = progressReceived,
        rosterReady = rosterReady,
        rosterComplete = rosterComplete,
        unitsReady = rosterComplete and resourcesReady,
        resourcesReady = resourcesReady,
    }
end

function ResourceSync.UpdateEventReadiness(eventState)
    local readiness = ResourceSync.GetEventReadinessState(eventState)
    if type(eventState) ~= "table" then
        return readiness
    end

    eventState.healthResourceRef = readiness.healthResourceRef
    eventState.unitsChunkExpected = readiness.unitsChunkExpected
    eventState.unitsChunkReceived = readiness.unitsChunkReceived
    eventState.healthResourcesExpected = readiness.healthResourcesExpected
    eventState.healthResourcesReceived = readiness.healthResourcesReceived
    eventState.readyProgressExpected = readiness.readyProgressExpected
    eventState.readyProgressReceived = readiness.readyProgressReceived
    eventState.rosterReady = readiness.rosterReady
    eventState.resourcesReady = readiness.resourcesReady
    eventState.unitsReady = readiness.unitsReady

    return readiness
end

function ResourceSync.LogReceivedResources(playerName, resources, logger)
    if type(logger) ~= "function" then
        return
    end

    local normalizedResources = ResourceSync.NormalizeResources(resources)
    for index = 1, #normalizedResources do
        local entry = normalizedResources[index]
        logger(
            "RESOURCE from %s: %s = %s / %s",
            tostring(playerName or "unknown"),
            tostring(ResourceSync.ResolveResourceName(entry.resourceRef)),
            tostring(entry.currentValue or 0),
            tostring(entry.maxValue or 0)
        )
    end
end

function ResourceSync.LogReceivedResourceDeltas(playerName, resourceDeltas, logger)
    if type(logger) ~= "function" then
        return
    end

    local normalized = ResourceSync.NormalizeResourceDeltas(resourceDeltas)
    for index = 1, #normalized do
        local entry = normalized[index]
        local deltaText = tostring(tonumber(entry.delta) or 0)
        if tonumber(entry.delta) and tonumber(entry.delta) > 0 then
            deltaText = "+" .. deltaText
        end
        logger(
            "RESOURCE_DELTA from %s: %s %s / %s",
            tostring(playerName or "unknown"),
            tostring(ResourceSync.ResolveResourceName(entry.resourceRef)),
            deltaText,
            tostring(entry.maxValue or 0)
        )
    end
end

return ResourceSync
