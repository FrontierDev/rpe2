local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local AuraEvaluator = Client.AutopilotAuraEvaluator or {}
local normalizeRankMultiplier = AuraEvaluator.NormalizeRankMultiplier

if type(AuraEvaluator) ~= "table" or AuraEvaluator._performanceCowInstalled == true then
    return
end

local function copyMap(values)
    local copied = {}
    for key, value in pairs(type(values) == "table" and values or {}) do
        copied[key] = value
    end
    return copied
end

local function normalizeStackBehavior(value)
    return tostring(value or "") == "independent_duration"
        and "independent_duration"
        or "refresh_duration"
end

local function normalizePositiveInteger(value, fallback)
    local normalized = math.floor(tonumber(value) or tonumber(fallback) or 0)
    return math.max(1, normalized)
end

local function normalizeTurnCount(value, fallback)
    local numericValue = tonumber(value)
    if numericValue == nil then
        numericValue = tonumber(fallback)
    end
    if numericValue == nil or numericValue <= 0 then
        return 1
    end
    return math.max(1, math.ceil(numericValue))
end

local function copyStackTurns(values)
    local copied = nil
    if type(values) == "table" then
        copied = {}
        for index = 1, #values do
            copied[index] = math.max(0, math.floor(tonumber(values[index]) or 0))
        end
    end
    return copied
end

local function cloneProjectedAuraStateShared(state)
    if type(state) ~= "table" then
        return nil
    end
    return {
        auraRef = state.auraRef,
        resolvedAuraRef = state.resolvedAuraRef or state.auraRef,
        datasetId = state.datasetId,
        casterEventId = math.floor(tonumber(state.casterEventId) or 0),
        targetEventId = math.floor(tonumber(state.targetEventId) or 0),
        stacks = math.max(0, math.floor(tonumber(state.stacks) or 0)),
        turnsRemaining = math.max(0, math.floor(tonumber(state.turnsRemaining) or 0)),
        powerLevel = tonumber(state.powerLevel) or 0,
        rankMultiplier = normalizeRankMultiplier(state.rankMultiplier),
        stackBehavior = normalizeStackBehavior(state.stackBehavior),
        maxStacks = normalizePositiveInteger(state.maxStacks, 1),
        stackTurns = copyStackTurns(state.stackTurns),
        -- Profiles/definitions are immutable planning data. Sharing them is the
        -- point of this COW layer; only mutable duration/stack state is copied.
        profile = state.profile,
        definition = state.definition or state.auraDefinition,
    }
end

local function getProjectedAuraStateReference(ledger, identity)
    local byCaster = type(ledger) == "table"
        and type(ledger.byAuraRef) == "table"
        and ledger.byAuraRef[identity and identity.auraRef]
        or nil
    local byTarget = type(byCaster) == "table" and byCaster[identity and identity.casterEventId] or nil
    return type(byTarget) == "table" and byTarget[identity and identity.targetEventId] or nil
end

local function setProjectedAuraState(ledger, identity, state)
    ledger.byAuraRef = type(ledger.byAuraRef) == "table" and ledger.byAuraRef or {}
    local byCaster = ledger.byAuraRef[identity.auraRef]
    if type(byCaster) ~= "table" then
        byCaster = {}
        ledger.byAuraRef[identity.auraRef] = byCaster
    end
    local byTarget = byCaster[identity.casterEventId]
    if type(byTarget) ~= "table" then
        byTarget = {}
        byCaster[identity.casterEventId] = byTarget
    end
    byTarget[identity.targetEventId] = state
end

local function cloneAuraLedgerPath(ledger, identity)
    local nextLedger = {
        byAuraRef = copyMap(type(ledger) == "table" and ledger.byAuraRef or {}),
    }
    local nextByCaster = copyMap(nextLedger.byAuraRef[identity.auraRef])
    nextLedger.byAuraRef[identity.auraRef] = nextByCaster
    local nextByTarget = copyMap(nextByCaster[identity.casterEventId])
    nextByCaster[identity.casterEventId] = nextByTarget
    return nextLedger, nextByTarget
end

local function buildIndependentStackTurns(state)
    local turns = {}
    if type(state) ~= "table" then
        return turns
    end
    if type(state.stackTurns) == "table" and #state.stackTurns > 0 then
        for index = 1, #state.stackTurns do
            local value = math.max(0, math.floor(tonumber(state.stackTurns[index]) or 0))
            if value > 0 then
                turns[#turns + 1] = value
            end
        end
        return turns
    end
    local count = math.max(0, math.floor(tonumber(state.stacks) or 0))
    local remaining = math.max(0, math.floor(tonumber(state.turnsRemaining) or 0))
    for index = 1, count do
        turns[index] = remaining
    end
    return turns
end

function AuraEvaluator.CreateProjectedAuraLedger(activeAuraRecords)
    local ledger = { byAuraRef = {} }
    for index = 1, #(activeAuraRecords or {}) do
        local record = activeAuraRecords[index]
        if type(record) == "table" and (tonumber(record.stacks) or 0) > 0
            and type(AuraEvaluator.ResolveProjectedAuraIdentity) == "function"
        then
            local identity = AuraEvaluator.ResolveProjectedAuraIdentity(
                record,
                record.casterEventId,
                record.targetEventId,
                { datasetId = record.datasetId }
            )
            if identity then
                local state = cloneProjectedAuraStateShared(record)
                state.auraRef = identity.auraRef
                state.resolvedAuraRef = identity.auraRef
                setProjectedAuraState(ledger, identity, state)
            end
        end
    end
    return ledger
end

function AuraEvaluator.CloneProjectedAuraLedger(ledger)
    -- A branch initially shares the immutable nested map/state graph. Every
    -- write goes through ReserveProjectedAura(), which path-copies the affected
    -- aura/caster/target maps and replaces the mutable state object.
    return {
        byAuraRef = copyMap(type(ledger) == "table" and ledger.byAuraRef or {}),
    }
end

function AuraEvaluator.GetProjectedAuraState(ledger, identity)
    return cloneProjectedAuraStateShared(getProjectedAuraStateReference(ledger, identity))
end

local function applyProjectedAuraApplicationShared(previousState, application, identity)
    local profile = type(application) == "table" and application.profile or nil
    if type(profile) ~= "table" and type(AuraEvaluator.BuildAuraProfile) == "function" then
        profile = AuraEvaluator.BuildAuraProfile(application, { datasetId = application and application.datasetId })
    end
    if type(profile) ~= "table" then
        return cloneProjectedAuraStateShared(previousState)
    end

    local stackBehavior = normalizeStackBehavior(profile.stackBehavior)
    local maxStacks = normalizePositiveInteger(profile.maxStacks, 1)
    local stacksToApply = normalizePositiveInteger(application and application.stacks, 1)
    local duration = normalizeTurnCount(application and application.duration, profile.duration)
    local state = cloneProjectedAuraStateShared(previousState) or {
        auraRef = identity.auraRef,
        resolvedAuraRef = identity.auraRef,
        datasetId = application and application.datasetId or profile.datasetId,
        casterEventId = identity.casterEventId,
        targetEventId = identity.targetEventId,
        stacks = 0,
        turnsRemaining = 0,
        powerLevel = 0,
        rankMultiplier = 1,
        stackBehavior = stackBehavior,
        maxStacks = maxStacks,
        stackTurns = nil,
        profile = profile,
        definition = profile.definition,
    }

    state.auraRef = identity.auraRef
    state.resolvedAuraRef = identity.auraRef
    state.datasetId = application and application.datasetId or profile.datasetId or state.datasetId
    state.casterEventId = identity.casterEventId
    state.targetEventId = identity.targetEventId
    state.powerLevel = tonumber(application and application.powerLevel) or 0
    state.rankMultiplier = normalizeRankMultiplier(application and application.rankMultiplier)
    state.stackBehavior = stackBehavior
    state.maxStacks = maxStacks
    state.profile = profile
    state.definition = profile.definition

    if stackBehavior == "independent_duration" then
        local stackTurns = buildIndependentStackTurns(previousState)
        local freeStacks = math.max(0, maxStacks - #stackTurns)
        for index = 1, math.min(stacksToApply, freeStacks) do
            stackTurns[#stackTurns + 1] = duration
        end
        local maxTurns = 0
        for index = 1, #stackTurns do
            maxTurns = math.max(maxTurns, tonumber(stackTurns[index]) or 0)
        end
        state.stackTurns = stackTurns
        state.stacks = #stackTurns
        state.turnsRemaining = maxTurns
    else
        local previousStacks = math.max(0, math.floor(tonumber(previousState and previousState.stacks) or 0))
        if previousState then
            state.stacks = math.min(maxStacks, math.max(1, previousStacks) + stacksToApply)
        else
            state.stacks = math.min(maxStacks, stacksToApply)
        end
        state.turnsRemaining = duration
        state.stackTurns = nil
    end
    return state
end

function AuraEvaluator.ReserveProjectedAura(ledger, application, casterEventId, targetEventId, context, cache)
    if type(application) ~= "table" then
        return ledger, nil, nil, nil
    end
    if type(AuraEvaluator.ResolveProjectedAuraIdentity) ~= "function" then
        return ledger, nil, nil, nil
    end
    local identity = AuraEvaluator.ResolveProjectedAuraIdentity(
        application,
        casterEventId,
        targetEventId,
        context or { datasetId = application.datasetId },
        cache
    )
    if not identity then
        return ledger, nil, nil, nil
    end

    local currentLedger = type(ledger) == "table" and ledger or AuraEvaluator.CreateProjectedAuraLedger()
    local previousState = cloneProjectedAuraStateShared(getProjectedAuraStateReference(currentLedger, identity))
    if type(AuraEvaluator.ShouldSuppressProjectedAuraRefresh) == "function"
        and AuraEvaluator.ShouldSuppressProjectedAuraRefresh(previousState, application)
    then
        return currentLedger, previousState, previousState, identity
    end
    local nextState = applyProjectedAuraApplicationShared(previousState, application, identity)
    local nextLedger, nextByTarget = cloneAuraLedgerPath(currentLedger, identity)
    nextByTarget[identity.targetEventId] = nextState
    return nextLedger, previousState, cloneProjectedAuraStateShared(nextState), identity
end

AuraEvaluator._performanceCowInstalled = true
return AuraEvaluator
