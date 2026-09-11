local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Client = Addon.Client
local Planner = Client.AutopilotPlanner or {}
local Tasks = Addon.Internal.Tasks or {}
local Database = Addon.Internal.Database or {}
local Registry = Addon.Internal.Registry or {}
local Event = Addon.Internal.Database.Classes.Event
local EventUnit = Addon.Internal.Database.Classes.EventUnit
local AuraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil

if type(Planner) ~= "table" or Planner._performancePreparationInstalled == true then
    return
end

local basePlannerStep = Planner.Step
if type(basePlannerStep) ~= "function" then
    return
end

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

local function shouldYield(deadlineMs)
    return type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true
end

local function configurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function parseQualifiedRef(reference)
    local text = type(reference) == "string" and reference or tostring(reference or "")
    if text == "" then
        return nil, nil
    end
    local separator = string.find(text, ":", 1, true)
    if not separator then
        return nil, nil
    end
    local datasetId = string.sub(text, 1, separator - 1)
    local entryId = string.sub(text, separator + 1)
    if datasetId == "" or entryId == "" then
        return nil, nil
    end
    return datasetId, entryId
end

local function getCollectionCache(dataset, collectionKey)
    if type(dataset) ~= "table" or type(collectionKey) ~= "string" then
        return nil
    end
    local caches = type(dataset.__entryCacheByCollection) == "table" and dataset.__entryCacheByCollection or nil
    local cache = caches and caches[collectionKey] or nil
    local entries = dataset[collectionKey]
    if type(cache) == "table"
        and cache.revision == configurationRevision()
        and cache.entries == entries
        and type(cache.byId) == "table"
    then
        return cache
    end
    return nil
end

local function cacheDatasetEntry(dataset, collectionKey, entryId)
    local cache = getCollectionCache(dataset, collectionKey)
    if not cache then
        return nil, false
    end
    return cache.byId[entryId], true
end

-- EventUnit's historical resolver scans every activated dataset and every unit
-- on each miss. Planner preparation builds the same id maps incrementally; use
-- them when present, while preserving the original resolver as the fallback.
if type(EventUnit) == "table" and EventUnit._autopilotPreparedResolutionInstalled ~= true then
    local baseResolveUnitDefinition = EventUnit.ResolveUnitDefinition
    local baseResolvePetDefinition = EventUnit.ResolvePetDefinition

    function EventUnit:ResolveUnitDefinition()
        local datasetId, unitId = parseQualifiedRef(self and self.registryID)
        if datasetId and unitId
            and type(Registry.IsDatasetActivated) == "function"
            and Registry:IsDatasetActivated(datasetId) == true
        then
            local dataset = type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(datasetId) or nil
            local unit, cached = cacheDatasetEntry(dataset, "units", unitId)
            if cached then
                return unit and dataset or nil, unit
            end
        end
        if type(baseResolveUnitDefinition) == "function" then
            return baseResolveUnitDefinition(self)
        end
        return nil, nil
    end

    function EventUnit:ResolvePetDefinition()
        local datasetId, petId = parseQualifiedRef(self and self.petRef)
        if datasetId and petId
            and type(Registry.IsDatasetActivated) == "function"
            and Registry:IsDatasetActivated(datasetId) == true
        then
            local dataset = type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(datasetId) or nil
            local pet, cached = cacheDatasetEntry(dataset, "pets", petId)
            if cached then
                return pet and dataset or nil, pet
            end
        end
        if type(baseResolvePetDefinition) == "function" then
            return baseResolvePetDefinition(self)
        end
        return nil, nil
    end

    EventUnit._autopilotPreparedResolutionInstalled = true
end

-- AuraManager has the same linear dataset scan for Aura ids. Reuse an already
-- prepared map when available; normal callers and unprepared datasets retain
-- the canonical resolver unchanged.
if type(AuraManager) == "table"
    and type(AuraManager.ResolveAuraDefinition) == "function"
    and AuraManager._autopilotPreparedAuraResolutionInstalled ~= true
then
    local baseResolveAuraDefinition = AuraManager.ResolveAuraDefinition
    function AuraManager:ResolveAuraDefinition(auraRef, context)
        local datasetId, auraId = parseQualifiedRef(auraRef)
        if not datasetId then
            datasetId = type(context) == "table" and (
                context.datasetId
                or (type(context.dataset) == "table" and context.dataset.id)
                or context.sourceDatasetId
                or context.spellDatasetId
            ) or nil
            auraId = type(auraRef) == "string" and auraRef or tostring(auraRef or "")
        end
        if type(datasetId) == "string" and datasetId ~= "" and type(auraId) == "string" and auraId ~= "" then
            local dataset = type(context) == "table"
                and type(context.dataset) == "table"
                and tostring(context.dataset.id or "") == datasetId
                and context.dataset
                or (type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(datasetId) or nil)
            local aura, cached = cacheDatasetEntry(dataset, "auras", auraId)
            if cached then
                if type(aura) == "table" then
                    return dataset, aura, ("%s:%s"):format(datasetId, auraId)
                end
                return nil, nil, nil
            end
        end
        return baseResolveAuraDefinition(self, auraRef, context)
    end
    AuraManager._autopilotPreparedAuraResolutionInstalled = true
end

-- ResolveSpellActivation historically discovers an initial target, then the
-- canonical activation snapshot immediately rebuilds the complete candidate
-- set. A frozen planner proxy needs the latter but not the redundant first
-- discovery. Normal spellcasts retain the original behavior.
if type(Client.ResolveSpellActivationTargetUnit) == "function"
    and Client._autopilotDeferredInitialTargetInstalled ~= true
then
    local baseResolveSpellActivationTargetUnit = Client.ResolveSpellActivationTargetUnit
    function Client:ResolveSpellActivationTargetUnit(activation, targetGroup)
        if rawget(self, "__autopilotPlannerProxy") == true then
            return nil
        end
        return baseResolveSpellActivationTargetUnit(self, activation, targetGroup)
    end
    Client._autopilotDeferredInitialTargetInstalled = true
end

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end

local function sourceUnitMap(state)
    local prep = state.performancePreparation
    if type(prep.sourceUnitByEventId) == "table" then
        return prep.sourceUnitByEventId
    end
    local byId = {}
    for index = 1, #((state.sourceEventState and state.sourceEventState.units) or {}) do
        local unit = state.sourceEventState.units[index]
        local eventId = normalizeEventId(unit and unit.eventID)
        if eventId > 0 then
            byId[eventId] = unit
        end
    end
    prep.sourceUnitByEventId = byId
    return byId
end

local function actorKeyForUnit(unit)
    local eventId = normalizeEventId(unit and unit.eventID)
    local marker = math.max(0, math.floor(tonumber(unit and unit.raidMarker) or 0))
    if marker > 0 then
        return "marker:" .. tostring(marker)
    end
    return "npc:" .. tostring(eventId)
end

local function buildSyntheticCurrentSchedule(state)
    local prep = state.performancePreparation
    if type(prep.syntheticSchedule) == "table" then
        return prep.syntheticSchedule
    end

    local actors = {}
    local byKey = {}
    for index = 1, #(state.actorKeys or {}) do
        local key = tostring(state.actorKeys[index] or "")
        local marker = tonumber(string.match(key, "^marker:(%d+)$")) or 0
        local actor = {
            key = key,
            kind = marker > 0 and "npc_marker" or "npc",
            raidMarker = marker,
            unitEventIds = {},
        }
        actors[#actors + 1] = actor
        byKey[key] = actor
    end

    local unitsById = sourceUnitMap(state)
    for index = 1, #(state.npcEventIds or {}) do
        local eventId = normalizeEventId(state.npcEventIds[index])
        local unit = unitsById[eventId]
        local actor = unit and byKey[actorKeyForUnit(unit)] or nil
        if type(actor) == "table" then
            actor.unitEventIds[#actor.unitEventIds + 1] = eventId
        end
    end

    local schedule = {}
    schedule[math.max(1, math.floor(tonumber(state.tickNumber) or 1))] = {
        actors = actors,
        oversized = false,
    }
    prep.syntheticSchedule = schedule
    return schedule
end

local activeScheduleOverrideState = nil
if type(Event) == "table"
    and type(Event.BuildTurnSchedule) == "function"
    and Event._autopilotPlannerScheduleReuseInstalled ~= true
then
    local baseBuildTurnSchedule = Event.BuildTurnSchedule
    function Event.BuildTurnSchedule(eventState, stepCapacity)
        local state = activeScheduleOverrideState
        if type(state) == "table" and eventState == state.sourceEventState then
            return buildSyntheticCurrentSchedule(state)
        end
        return baseBuildTurnSchedule(eventState, stepCapacity)
    end
    Event._autopilotPlannerScheduleReuseInstalled = true
end

local function ensurePreparationState(state)
    state.performancePreparation = type(state.performancePreparation) == "table" and state.performancePreparation or {}
    return state.performancePreparation
end

local function addDatasetId(order, seen, value)
    local datasetId = type(value) == "string" and value or tostring(value or "")
    if datasetId == "" or seen[datasetId] then
        return
    end
    seen[datasetId] = true
    order[#order + 1] = datasetId
end

local function addDatasetIdFromRef(order, seen, reference)
    local datasetId = select(1, parseQualifiedRef(reference))
    if datasetId then
        addDatasetId(order, seen, datasetId)
    end
end

local function appendJob(jobs, seen, datasetId, collectionKey)
    local key = tostring(datasetId or "") .. "\31" .. tostring(collectionKey or "")
    if datasetId == nil or datasetId == "" or seen[key] then
        return
    end
    local dataset = type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(datasetId) or nil
    if type(dataset) ~= "table" then
        return
    end
    seen[key] = true
    jobs[#jobs + 1] = {
        dataset = dataset,
        collectionKey = collectionKey,
        entries = type(dataset[collectionKey]) == "table" and dataset[collectionKey] or {},
        entryIndex = 1,
        byId = {},
        complete = false,
    }
end

local function buildStageAJobs(state)
    local datasetIds, seenIds = {}, {}
    for index = 1, #((state.sourceEventState and state.sourceEventState.units) or {}) do
        local unit = state.sourceEventState.units[index]
        addDatasetIdFromRef(datasetIds, seenIds, unit and unit.registryID)
        addDatasetIdFromRef(datasetIds, seenIds, unit and unit.petRef)
    end

    local auraBucket = type(Client.ActiveAurasByEventId) == "table"
        and Client.ActiveAurasByEventId[tostring(state.eventId or "")]
        or nil
    for _, entry in pairs(type(auraBucket) == "table" and auraBucket.byKey or {}) do
        addDatasetId(datasetIds, seenIds, entry and entry.datasetId)
        addDatasetIdFromRef(datasetIds, seenIds, entry and entry.auraRef)
    end

    local jobs, seenJobs = {}, {}
    for index = 1, #datasetIds do
        local datasetId = datasetIds[index]
        appendJob(jobs, seenJobs, datasetId, "units")
        appendJob(jobs, seenJobs, datasetId, "pets")
        appendJob(jobs, seenJobs, datasetId, "stats")
        appendJob(jobs, seenJobs, datasetId, "auras")
    end
    return jobs
end

local function buildStageBJobs(state)
    local datasetIds, seenIds = {}, {}
    for _, refs in pairs((state.snapshot and state.snapshot.spellRefsByEventId) or {}) do
        for index = 1, #(refs or {}) do
            addDatasetIdFromRef(datasetIds, seenIds, refs[index])
        end
    end

    local jobs, seenJobs = {}, {}
    for index = 1, #datasetIds do
        local datasetId = datasetIds[index]
        appendJob(jobs, seenJobs, datasetId, "spells")
        appendJob(jobs, seenJobs, datasetId, "stats")
        appendJob(jobs, seenJobs, datasetId, "auras")
    end
    return jobs
end

local function createIndexBuildState(state, stageName)
    local jobs = stageName == "stageA" and buildStageAJobs(state) or buildStageBJobs(state)
    return {
        jobs = jobs,
        jobIndex = 1,
        revision = configurationRevision(),
        complete = #jobs == 0,
    }
end

local function stepIndexBuild(build, deadlineMs)
    if type(build) ~= "table" or build.complete == true then
        return true
    end

    while build.jobIndex <= #(build.jobs or {}) do
        local job = build.jobs[build.jobIndex]
        local existing = getCollectionCache(job.dataset, job.collectionKey)
        if existing then
            job.complete = true
            build.jobIndex = build.jobIndex + 1
        else
            while job.entryIndex <= #(job.entries or {}) do
                local entry = job.entries[job.entryIndex]
                local entryId = tostring(type(entry) == "table" and entry.id or "")
                if entryId ~= "" then
                    job.byId[entryId] = entry
                end
                job.entryIndex = job.entryIndex + 1
                if shouldYield(deadlineMs) then
                    return false
                end
            end

            job.dataset.__entryCacheByCollection = type(job.dataset.__entryCacheByCollection) == "table"
                and job.dataset.__entryCacheByCollection
                or {}
            job.dataset.__entryCacheByCollection[job.collectionKey] = {
                revision = build.revision,
                entries = job.dataset[job.collectionKey],
                byId = job.byId,
            }
            job.complete = true
            build.jobIndex = build.jobIndex + 1
            if shouldYield(deadlineMs) then
                return false
            end
        end
    end

    build.complete = true
    return true
end

local function ensureMetricFields(state)
    state.metrics = type(state.metrics) == "table" and state.metrics or {}
    state.metrics.sliceCount = tonumber(state.metrics.sliceCount) or 0
    state.metrics.yieldCount = tonumber(state.metrics.yieldCount) or 0
    state.metrics.maxSliceMs = tonumber(state.metrics.maxSliceMs) or 0
    state.metrics.snapshotMaxMs = tonumber(state.metrics.snapshotMaxMs) or 0
    return state.metrics
end

local function runPreparationSlice(state, stageName, deadlineMs)
    local prep = ensurePreparationState(state)
    local build = prep[stageName]
    if type(build) ~= "table" then
        build = createIndexBuildState(state, stageName)
        prep[stageName] = build
    end

    local startedAt = nowMilliseconds()
    local complete = stepIndexBuild(build, deadlineMs) == true
    local elapsed = math.max(0, nowMilliseconds() - startedAt)
    local metrics = ensureMetricFields(state)
    metrics.sliceCount = metrics.sliceCount + 1
    metrics.maxSliceMs = math.max(metrics.maxSliceMs, elapsed)
    metrics.snapshotMaxMs = math.max(metrics.snapshotMaxMs, elapsed)
    metrics.yieldCount = metrics.yieldCount + 1
    return complete
end

local function preparationComplete(state, stageName)
    local prep = ensurePreparationState(state)
    return type(prep[stageName]) == "table" and prep[stageName].complete == true
end

local function callBasePlannerStep(state, deadlineMs)
    local phaseAtStart = tostring(state.phase or "")
    local originalShouldYield = Tasks.ShouldYield
    local installedBoundary = type(originalShouldYield) == "function"

    if installedBoundary then
        Tasks.ShouldYield = function(self, deadline)
            if phaseAtStart == "validate" and tostring(state.phase or "") ~= "validate" then
                return true
            end
            if tostring(state.phase or "") == "snapshot-auras" and not preparationComplete(state, "stageA") then
                return true
            end
            if tostring(state.phase or "") == "snapshot-movement" and not preparationComplete(state, "stageB") then
                return true
            end
            return originalShouldYield(self, deadline)
        end
    end

    if phaseAtStart == "validate" then
        activeScheduleOverrideState = state
    end
    local results = { pcall(basePlannerStep, state, deadlineMs) }
    activeScheduleOverrideState = nil
    if installedBoundary then
        Tasks.ShouldYield = originalShouldYield
    end
    if results[1] ~= true then
        error(results[2], 0)
    end
    return results[2]
end

function Planner.Step(state, deadlineMs)
    if type(state) ~= "table" then
        return true
    end

    ensurePreparationState(state)
    if type(state.snapshot) == "table" and type(state.snapshot.clientProxy) == "table" then
        rawset(state.snapshot.clientProxy, "__autopilotPlannerProxy", true)
    end
    if type(state.scratch) == "table" and type(state.scratch.auraDefinitionCache) == "table" then
        state.scratch.auraDefinitionCache.__autopilotShareDefinitions = true
    end

    local phase = tostring(state.phase or "")
    if phase == "snapshot-auras" and not preparationComplete(state, "stageA") then
        runPreparationSlice(state, "stageA", deadlineMs)
        return false
    end
    if phase == "snapshot-movement" and not preparationComplete(state, "stageB") then
        runPreparationSlice(state, "stageB", deadlineMs)
        return false
    end

    return callBasePlannerStep(state, deadlineMs)
end

Planner._performancePreparationInstalled = true
return Planner
