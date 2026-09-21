local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Database = Addon.Internal.Database or {}
local Common = Addon.Utils.Common or {}
local Lookup = Addon.Utils.Lookup or {}

Client.AutopilotAuraEvaluator = Client.AutopilotAuraEvaluator or {}
local Evaluator = Client.AutopilotAuraEvaluator

-- Autopilot-only future-value discount. The first future occurrence is 0.8^1.
Evaluator.FUTURE_EFFECT_DISCOUNT = 0.8

local function normalizeRef(value)
    if value == nil then
        return nil
    end

    local reference = tostring(value)
    return reference ~= "" and reference or nil
end

local function parseQualifiedRef(reference)
    local normalized = normalizeRef(reference)
    if not normalized then
        return nil, nil
    end

    local datasetId, auraId = string.match(normalized, "^([^:]+):(.+)$")
    if datasetId == "" or auraId == "" then
        return nil, nil
    end
    return datasetId, auraId
end

local function copyValue(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copied = {}
    seen[value] = copied
    for key, child in pairs(value) do
        copied[copyValue(key, seen)] = copyValue(child, seen)
    end

    local metatable = getmetatable(value)
    if metatable ~= nil then
        setmetatable(copied, metatable)
    end
    return copied
end

local function copyMap(values)
    local copied = {}
    for key, value in pairs(type(values) == "table" and values or {}) do
        copied[key] = value
    end
    return copied
end

local function roundNonNegative(value)
    local numericValue = math.max(0, tonumber(value) or 0)
    if type(Common.Round) == "function" then
        return math.max(0, tonumber(Common.Round(numericValue)) or 0)
    end
    return math.max(0, math.floor(numericValue + 0.5))
end

local function normalizeChancePercent(value)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return 100
    end
    return math.max(0, math.min(100, numericValue))
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

local function normalizeStackBehavior(value)
    return tostring(value or "") == "independent_duration"
        and "independent_duration"
        or "refresh_duration"
end

local function getAuraManager()
    return Addon.Client
        and Addon.Client.Spellcasting
        and Addon.Client.Spellcasting.AuraManager
        or nil
end

local function normalizeRankMultiplier(value)
    local multiplier = tonumber(value)
    if multiplier == nil or multiplier ~= multiplier or math.abs(multiplier) == math.huge or multiplier < 0 then
        return 1
    end
    return multiplier
end
Evaluator.NormalizeRankMultiplier = normalizeRankMultiplier

local function applyRankMultiplier(multiplier, amount)
    local spellcasting = Addon.Client and Addon.Client.Spellcasting or nil
    return spellcasting.ApplySpellRankMultiplier({ spellRankMultiplier = normalizeRankMultiplier(multiplier) }, amount)
end

local function getContextDataset(context)
    if type(context) ~= "table" then
        return nil
    end

    if type(context.dataset) == "table" then
        return context.dataset
    end
    if context.id ~= nil and type(context.auras) == "table" then
        return context
    end
    return nil
end

local function getContextDatasetId(context)
    if type(context) ~= "table" then
        return nil
    end

    local dataset = getContextDataset(context)
    local datasetId = context.datasetId
        or (dataset and dataset.id)
        or context.sourceDatasetId
        or context.spellDatasetId
    return normalizeRef(datasetId)
end

local function buildCacheKey(auraRef, context)
    local explicitDatasetId = select(1, parseQualifiedRef(auraRef))
    local datasetId = explicitDatasetId or getContextDatasetId(context)
    return table.concat({ tostring(datasetId or ""), tostring(auraRef or "") }, "\31")
end

local function ensureCache(cache)
    if type(cache) ~= "table" then
        return nil
    end

    cache.definitionsByKey = type(cache.definitionsByKey) == "table" and cache.definitionsByKey or {}
    cache.resolutionCount = tonumber(cache.resolutionCount) or 0
    cache.hitCount = tonumber(cache.hitCount) or 0
    cache.missCount = tonumber(cache.missCount) or 0
    return cache
end

local function findAuraInDataset(dataset, auraId)
    if type(dataset) ~= "table" or type(auraId) ~= "string" or auraId == "" then
        return nil
    end

    for index = 1, #((dataset and dataset.auras) or {}) do
        local aura = dataset.auras[index]
        if type(aura) == "table" and tostring(aura.id or "") == auraId then
            return aura
        end
    end
    return nil
end

local function fallbackResolveAuraDefinition(auraRef, context)
    local explicitRef = normalizeRef(auraRef)
    if not explicitRef then
        return nil, nil, nil
    end

    local datasetId, auraId = parseQualifiedRef(explicitRef)
    if not datasetId then
        datasetId = getContextDatasetId(context)
        auraId = explicitRef
    end
    if not datasetId or not auraId then
        return nil, nil, nil
    end

    local contextDataset = getContextDataset(context)
    if type(contextDataset) == "table" and tostring(contextDataset.id or "") == datasetId then
        local aura = findAuraInDataset(contextDataset, auraId)
        if aura then
            return contextDataset, aura, ("%s:%s"):format(datasetId, auraId)
        end
    end

    local dataset = type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(datasetId) or nil
    local aura = findAuraInDataset(dataset, auraId)
    if aura then
        return dataset, aura, ("%s:%s"):format(datasetId, auraId)
    end
    return nil, nil, nil
end

function Evaluator.CreatePlanCache()
    return {
        definitionsByKey = {},
        resolutionCount = 0,
        hitCount = 0,
        missCount = 0,
    }
end

function Evaluator.ResolveAuraDefinition(auraRef, context, cache)
    local normalizedRef = normalizeRef(auraRef)
    if not normalizedRef then
        return nil, nil, nil
    end

    if type(context) == "table" and type(context.auraDefinitionCache) == "table" and cache == nil then
        cache = context.auraDefinitionCache
    end
    cache = ensureCache(cache)
    local cacheKey = buildCacheKey(normalizedRef, context)
    if cache and cache.definitionsByKey[cacheKey] ~= nil then
        local cached = cache.definitionsByKey[cacheKey]
        cache.hitCount = cache.hitCount + 1
        if cached == false then
            return nil, nil, nil
        end
        return cached.dataset, cached.definition, cached.qualifiedAuraRef
    end

    if cache then
        cache.resolutionCount = cache.resolutionCount + 1
    end

    local dataset, definition, qualifiedAuraRef
    local auraManager = getAuraManager()
    if type(auraManager) == "table" and type(auraManager.ResolveAuraDefinition) == "function" then
        local contextDataset = getContextDataset(context)
        dataset, definition, qualifiedAuraRef = auraManager:ResolveAuraDefinition(normalizedRef, {
            dataset = contextDataset,
            datasetId = getContextDatasetId(context),
            sourceDatasetId = normalizeRef(type(context) == "table" and context.sourceDatasetId or nil),
            spellDatasetId = normalizeRef(type(context) == "table" and context.spellDatasetId or nil),
        })
    else
        dataset, definition, qualifiedAuraRef = fallbackResolveAuraDefinition(normalizedRef, context)
    end

    if cache then
        if type(dataset) == "table" and type(definition) == "table" then
            local cached = {
                dataset = dataset,
                definition = copyValue(definition),
                qualifiedAuraRef = qualifiedAuraRef,
            }
            cache.definitionsByKey[cacheKey] = cached
            if type(qualifiedAuraRef) == "string" and qualifiedAuraRef ~= "" then
                cache.definitionsByKey[buildCacheKey(qualifiedAuraRef, context)] = cached
                local qualifiedDatasetId, qualifiedAuraId = parseQualifiedRef(qualifiedAuraRef)
                if qualifiedDatasetId and qualifiedAuraId then
                    cache.definitionsByKey[table.concat({ qualifiedDatasetId, qualifiedAuraId }, "\31")] = cached
                end
            end
            return cached.dataset, cached.definition, cached.qualifiedAuraRef
        else
            cache.definitionsByKey[cacheKey] = false
            cache.missCount = cache.missCount + 1
        end
    end

    return dataset, definition, qualifiedAuraRef
end

Evaluator.CreateDefinitionCache = Evaluator.CreatePlanCache

local function buildControlProfile(effects)
    local control = {
        cancelOnDamage = false,
        preventCasting = false,
        movementRangeOverride = nil,
        forceAutoHitAgainstTarget = false,
    }
    local controlEffects = {}
    for index = 1, #(effects or {}) do
        local effect = effects[index]
        if type(effect) == "table" and tostring(effect.type or "") == "control" then
            controlEffects[#controlEffects + 1] = copyValue(effect)
            control.cancelOnDamage = control.cancelOnDamage or effect.cancelOnDamage == true
            control.preventCasting = control.preventCasting or effect.preventCasting == true
            control.forceAutoHitAgainstTarget = control.forceAutoHitAgainstTarget or effect.forceAutoHitAgainstTarget == true
            if effect.movementRangeOverride ~= nil then
                local override = tonumber(effect.movementRangeOverride)
                if override ~= nil then
                    control.movementRangeOverride = control.movementRangeOverride ~= nil
                        and math.min(control.movementRangeOverride, override)
                        or override
                end
            end
        end
    end
    return control, controlEffects
end

local function buildAuraProfileFromDefinition(definition, dataset, qualifiedAuraRef, fallbackRef)
    if type(definition) ~= "table" then
        return nil
    end

    -- Current runtime cadence is explicit: AuraManager:AdvanceAuraEntry invokes
    -- TickAura once for each due owner occurrence, and TickAura executes these
    -- top-level definition.effects. Current runtime emits NO periodic
    -- combatEventId. definition.events are reactive HandleCombatEvent procs and
    -- are deliberately not projected as periodic occurrences.
    local effects = definition.effects or {}
    local periodicDamageEffects = {}
    local periodicHealingEffects = {}
    local hasDamage = false
    local hasHealing = false
    for index = 1, #effects do
        local effect = effects[index]
        local effectType = tostring(type(effect) == "table" and effect.type or "")
        if effectType == "damage" then
            hasDamage = true
            periodicDamageEffects[#periodicDamageEffects + 1] = copyValue(effect)
        elseif effectType == "heal" then
            hasHealing = true
            periodicHealingEffects[#periodicHealingEffects + 1] = copyValue(effect)
        end
    end

    local control, controlEffects = buildControlProfile(effects)
    local events = copyValue(definition.events or {})
    local triggeredEvents = {}
    for index = 1, #(events or {}) do
        triggeredEvents[#triggeredEvents + 1] = copyValue(events[index])
    end

    local resolvedRef = normalizeRef(qualifiedAuraRef) or normalizeRef(fallbackRef) or normalizeRef(definition.id)
    local qualifiedDatasetId = select(1, parseQualifiedRef(resolvedRef))
    local datasetId = normalizeRef(type(dataset) == "table" and dataset.id or nil) or qualifiedDatasetId
    if resolvedRef and datasetId and not qualifiedDatasetId then
        resolvedRef = ("%s:%s"):format(datasetId, resolvedRef)
    end
    return {
        auraRef = resolvedRef,
        resolvedAuraRef = resolvedRef,
        datasetId = datasetId,
        definition = copyValue(definition),
        duration = normalizePositiveInteger(definition.duration, 1),
        stackBehavior = normalizeStackBehavior(definition.stackBehavior),
        maxStacks = normalizePositiveInteger(definition.maxStacks, 1),
        effects = copyValue(effects),
        -- Compatibility names retained from #141. These are top-level Aura
        -- effects and therefore execute periodically at runtime.
        directDamageEffects = copyValue(periodicDamageEffects),
        directHealingEffects = copyValue(periodicHealingEffects),
        directHealEffects = copyValue(periodicHealingEffects),
        damageEffects = copyValue(periodicDamageEffects),
        healingEffects = copyValue(periodicHealingEffects),
        periodicDamageEffects = periodicDamageEffects,
        periodicHealingEffects = periodicHealingEffects,
        periodicHealEffects = periodicHealingEffects,
        controlEffects = controlEffects,
        control = control,
        controlFlags = control,
        triggeredEvents = triggeredEvents,
        triggeredEventDescriptors = triggeredEvents,
        events = copyValue(events),
        hasDamage = hasDamage,
        hasHeal = hasHealing,
        hasHealing = hasHealing,
        hasPeriodicDamage = hasDamage,
        hasPeriodicHealing = hasHealing,
        hasPeriodicHeal = hasHealing,
        hasControl = #controlEffects > 0,
        hasTriggeredEvents = #triggeredEvents > 0,
    }
end

function Evaluator.BuildAuraProfile(auraOrRef, context, cache)
    local definition = nil
    local dataset = nil
    local qualifiedAuraRef = nil
    local fallbackRef = nil

    if type(auraOrRef) == "string" then
        fallbackRef = auraOrRef
        dataset, definition, qualifiedAuraRef = Evaluator.ResolveAuraDefinition(auraOrRef, context, cache)
    elseif type(auraOrRef) == "table" then
        fallbackRef = auraOrRef.auraRef or auraOrRef.resolvedAuraRef or auraOrRef.id
        definition = auraOrRef.definition or auraOrRef.auraDefinition or auraOrRef
        dataset = auraOrRef.dataset or getContextDataset(context)
        qualifiedAuraRef = auraOrRef.qualifiedAuraRef or auraOrRef.resolvedAuraRef
        if not qualifiedAuraRef and normalizeRef(auraOrRef.datasetId) and normalizeRef(fallbackRef)
            and not select(1, parseQualifiedRef(fallbackRef))
        then
            qualifiedAuraRef = ("%s:%s"):format(normalizeRef(auraOrRef.datasetId), normalizeRef(fallbackRef))
        end
    end

    return buildAuraProfileFromDefinition(definition, dataset, qualifiedAuraRef, fallbackRef)
end

Evaluator.BuildProfile = Evaluator.BuildAuraProfile

function Evaluator.ResolveAuraDefinitionCached(cache, auraRef, context)
    return Evaluator.ResolveAuraDefinition(auraRef, context, cache)
end

local function resolveApplication(effect, component, spell, context, cache)
    if type(effect) ~= "table" then
        return nil
    end

    local effectType = tostring(effect.type or "")
    local isPureAura = effectType == "apply_aura"
    local isAuraDamageOrHeal = (effectType == "damage" or effectType == "heal") and effect.applyAura == true
    if not isPureAura and not isAuraDamageOrHeal then
        return nil
    end

    local auraRef = normalizeRef(effect.auraRef)
    if not auraRef then
        return nil
    end

    local auraContext = {
        dataset = getContextDataset(context),
        datasetId = normalizeRef(type(context) == "table" and context.datasetId or nil),
        sourceDatasetId = normalizeRef(type(context) == "table" and context.sourceDatasetId or nil),
        spellDatasetId = normalizeRef(type(context) == "table" and context.spellDatasetId or nil),
    }
    local dataset, definition, qualifiedAuraRef = Evaluator.ResolveAuraDefinition(auraRef, auraContext, cache)
    local profile = buildAuraProfileFromDefinition(definition, dataset, qualifiedAuraRef, auraRef)
    return {
        auraRef = auraRef,
        resolvedAuraRef = qualifiedAuraRef or (profile and profile.resolvedAuraRef) or auraRef,
        datasetId = normalizeRef(dataset and dataset.id or auraContext.datasetId),
        definition = profile and profile.definition or copyValue(definition),
        profile = profile,
        sourceEffectType = effectType,
        componentKey = type(component) == "table" and component.key or nil,
        stacks = normalizePositiveInteger(isPureAura and effect.stacks or effect.auraStacks, 1),
        duration = normalizeTurnCount(effect.duration, profile and profile.duration or 1),
        powerLevel = tonumber(effect.basePower) or 0,
        rankMultiplier = normalizeRankMultiplier(
            type(context) == "table" and (context.spellRankMultiplier
                or (type(context.spellRankContext) == "table" and context.spellRankContext.multiplier))
        ),
        spellRef = type(spell) == "table" and spell.id or nil,
    }
end

function Evaluator.CollectSpellAuraApplications(spell, context, cache)
    local applications = {}
    for index = 1, #(type(spell) == "table" and spell.components or {}) do
        local component = spell.components[index]
        local effect = type(component) == "table" and component.effect or nil
        local application = resolveApplication(effect, component, spell, context, cache)
        if application then
            applications[#applications + 1] = application
        end
    end
    return applications
end

Evaluator.ResolveSpellAuraApplications = Evaluator.CollectSpellAuraApplications

function Evaluator.CopyAuraEntry(entry, context, cache)
    if type(entry) ~= "table" then
        return nil
    end

    local copied = {
        auraKey = entry.auraKey,
        auraRef = entry.auraRef,
        resolvedAuraRef = entry.auraRef,
        datasetId = entry.datasetId,
        casterEventId = tonumber(entry.casterEventId) or 0,
        targetEventId = tonumber(entry.targetEventId) or 0,
        stacks = math.max(0, math.floor(tonumber(entry.stacks) or 0)),
        turnsRemaining = math.max(0, math.floor(tonumber(entry.turnsRemaining) or 0)),
        powerLevel = tonumber(entry.powerLevel) or 0,
        rankMultiplier = normalizeRankMultiplier(entry.rankMultiplier),
        stackBehavior = normalizeStackBehavior(entry.stackBehavior),
        maxStacks = normalizePositiveInteger(entry.maxStacks, 1),
        lastAdvancedOwnerTurnNumber = tonumber(entry.lastAdvancedOwnerTurnNumber),
        lastAdvancedTurnNumber = tonumber(entry.lastAdvancedTurnNumber),
        -- pendingAdvancedOwnerTurnNumber is AuraManager scheduling bookkeeping,
        -- not revision-covered tactical Aura state.
        stackTurns = copyValue(entry.stackTurns),
    }

    local auraContext = {
        dataset = getContextDataset(context),
        datasetId = normalizeRef(copied.datasetId or (type(context) == "table" and context.datasetId or nil)),
        sourceDatasetId = normalizeRef(type(context) == "table" and context.sourceDatasetId or nil),
        spellDatasetId = normalizeRef(type(context) == "table" and context.spellDatasetId or nil),
    }
    local dataset, definition, qualifiedAuraRef = Evaluator.ResolveAuraDefinition(copied.auraRef, auraContext, cache)
    if type(definition) ~= "table" then
        definition = entry.definition or entry.auraDefinition
        dataset = getContextDataset(context)
    end
    copied.auraRef = qualifiedAuraRef or copied.auraRef
    copied.resolvedAuraRef = copied.auraRef
    copied.datasetId = normalizeRef((dataset and dataset.id) or copied.datasetId)
    if type(definition) == "table" then
        copied.stackBehavior = normalizeStackBehavior(entry.stackBehavior or definition.stackBehavior)
        copied.maxStacks = normalizePositiveInteger(entry.maxStacks or definition.maxStacks, 1)
        copied.turnsRemaining = math.max(0, math.floor(tonumber(entry.turnsRemaining) or tonumber(definition.duration) or 0))
    end
    copied.definition = copyValue(definition)
    copied.auraDefinition = copied.definition
    copied.profile = buildAuraProfileFromDefinition(copied.definition, dataset, copied.auraRef, copied.auraRef)
    copied.control = copied.profile and copyValue(copied.profile.control) or nil
    return copied
end

function Evaluator.BuildControlState(auraRecords)
    local state = {
        cancelOnDamage = false,
        preventCasting = false,
        movementRangeOverride = nil,
        forceAutoHitAgainstTarget = false,
    }

    for index = 1, #(auraRecords or {}) do
        local record = auraRecords[index]
        local isActive = type(record) == "table"
            and (tonumber(record.stacks) == nil or tonumber(record.stacks) > 0)
        local control = isActive and record.control or nil
        if type(control) ~= "table" and isActive and type(record.profile) == "table" then
            control = record.profile.control
        end
        if isActive and type(control) == "table" then
            state.cancelOnDamage = state.cancelOnDamage or control.cancelOnDamage == true
            state.preventCasting = state.preventCasting or control.preventCasting == true
            state.forceAutoHitAgainstTarget = state.forceAutoHitAgainstTarget or control.forceAutoHitAgainstTarget == true
            if control.movementRangeOverride ~= nil then
                local override = tonumber(control.movementRangeOverride)
                if override ~= nil then
                    state.movementRangeOverride = state.movementRangeOverride ~= nil
                        and math.min(state.movementRangeOverride, override)
                        or override
                end
            end
        end
    end
    return state
end

Evaluator.BuildFrozenControlState = Evaluator.BuildControlState

-- Pure expected-value helper. It intentionally performs no RNG.
function Evaluator.ResolveExpectedOccurrenceValue(deterministicMagnitude, chancePercent)
    local magnitude = math.max(0, tonumber(deterministicMagnitude) or 0)
    return magnitude * (normalizeChancePercent(chancePercent) / 100)
end

local function getResourceMaximum(targetUnit, resourceRef)
    if type(targetUnit) ~= "table" or type(resourceRef) ~= "string" or resourceRef == "" then
        return 0
    end
    for index = 1, #(targetUnit.resources or {}) do
        local entry = targetUnit.resources[index]
        if type(entry) == "table"
            and tostring(entry.resourceRef or entry.ref or "") == resourceRef
        then
            return math.max(0, tonumber(entry.maxValue) or tonumber(entry.currentValue) or 0)
        end
    end
    return 0
end

local function resolveStatScaling(casterUnit, effect)
    local total = 0
    for index = 1, #(effect and effect.statScaling or {}) do
        local scaling = effect.statScaling[index]
        local statRef = type(scaling) == "table" and normalizeRef(scaling.statRef) or nil
        if statRef then
            local statValue = tonumber(Lookup.GetStatValue and Lookup.GetStatValue(casterUnit, statRef, 0) or 0) or 0
            total = total + (statValue * (tonumber(scaling.coefficient) or 0))
        end
    end
    return total
end

function Evaluator.ResolvePeriodicEffectMagnitude(casterUnit, targetUnit, effect, powerLevel, stacks, rankMultiplier)
    if type(effect) ~= "table" then
        return 0
    end
    local effectType = tostring(effect.type or "")
    local baseField = effectType == "heal" and "baseHealing" or effectType == "damage" and "baseDamage" or nil
    if not baseField then
        return 0
    end

    local baseAmount = (tonumber(effect[baseField]) or 0)
        + (tonumber(powerLevel) or 0)
        + resolveStatScaling(casterUnit, effect)
    baseAmount = tonumber(applyRankMultiplier(rankMultiplier, baseAmount)) or 0
    local amountMode = tostring(effect.amountMode or "flat")
    if amountMode == "base_percent" or amountMode == "max_percent" then
        local resourceValue = getResourceMaximum(targetUnit, tostring(effect.resourceRef or ""))
        baseAmount = math.max(0, math.ceil(resourceValue * baseAmount / 100))
    end

    local stackCount = math.max(0, math.floor(tonumber(stacks) or 0))
    if stackCount <= 0 then
        return 0
    end
    return roundNonNegative(baseAmount * stackCount)
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

local function getActiveStackCountAtOccurrence(state, occurrenceIndex)
    local k = math.max(1, math.floor(tonumber(occurrenceIndex) or 1))
    if type(state) ~= "table" then
        return 0
    end
    if normalizeStackBehavior(state.stackBehavior) == "independent_duration" then
        local count = 0
        local stackTurns = buildIndependentStackTurns(state)
        for index = 1, #stackTurns do
            if stackTurns[index] >= k then
                count = count + 1
            end
        end
        return count
    end

    local turnsRemaining = math.max(0, math.floor(tonumber(state.turnsRemaining) or 0))
    if k > turnsRemaining then
        return 0
    end
    return math.max(0, math.floor(tonumber(state.stacks) or 0))
end

local function getOccurrenceCount(state)
    if type(state) ~= "table" then
        return 0
    end
    if normalizeStackBehavior(state.stackBehavior) == "independent_duration" then
        local maxTurns = 0
        local stackTurns = buildIndependentStackTurns(state)
        for index = 1, #stackTurns do
            maxTurns = math.max(maxTurns, stackTurns[index])
        end
        return maxTurns
    end
    return math.max(0, math.floor(tonumber(state.turnsRemaining) or 0))
end

-- Returns only provably deterministic future owner occurrences from frozen
-- state. The current runtime has no periodic combatEventId whitelist: there
-- are zero such IDs. Each returned occurrence represents the top-level
-- TickAura execution on one future owner occurrence. Reactive definition.events
-- are intentionally absent, regardless of their combatEventId/chance.
function Evaluator.ClassifyDeterministicFutureOccurrences(state)
    if type(state) ~= "table" then
        return {
            cadence = "owner_occurrence",
            deterministicCombatEventIds = {},
            occurrences = {},
        }
    end

    local profile = type(state.profile) == "table" and state.profile
        or Evaluator.BuildAuraProfile(state, { datasetId = state.datasetId })
    local occurrences = {}
    if type(profile) == "table"
        and (profile.hasPeriodicDamage == true or profile.hasPeriodicHealing == true)
    then
        local count = getOccurrenceCount(state)
        for occurrenceIndex = 1, count do
            local activeStacks = getActiveStackCountAtOccurrence(state, occurrenceIndex)
            if activeStacks > 0 then
                occurrences[#occurrences + 1] = {
                    index = occurrenceIndex,
                    chancePercent = 100,
                    activeStacks = activeStacks,
                    periodicDamageEffects = profile.periodicDamageEffects,
                    periodicHealingEffects = profile.periodicHealingEffects,
                }
            end
        end
    end

    return {
        cadence = "owner_occurrence",
        deterministicCombatEventIds = {},
        occurrences = occurrences,
    }
end

-- Projects only TickAura's deterministic top-level damage/heal effects. Aura
-- event procs are reactive to combatEventId and are therefore zero here.
function Evaluator.ProjectPeriodicAuraValue(state, casterUnit, targetUnit)
    if type(state) ~= "table" then
        return {
            periodicDamage = 0,
            periodicHealing = 0,
            occurrenceCount = 0,
        }
    end

    local classification = Evaluator.ClassifyDeterministicFutureOccurrences(state)
    local periodicDamage = 0
    local periodicHealing = 0
    local discount = tonumber(Evaluator.FUTURE_EFFECT_DISCOUNT) or 0.8
    for index = 1, #(classification.occurrences or {}) do
        local occurrence = classification.occurrences[index]
        local occurrenceDamage = 0
        for effectIndex = 1, #(occurrence.periodicDamageEffects or {}) do
            occurrenceDamage = occurrenceDamage + Evaluator.ResolvePeriodicEffectMagnitude(
                casterUnit,
                targetUnit,
                occurrence.periodicDamageEffects[effectIndex],
                state.powerLevel,
                occurrence.activeStacks,
                state.rankMultiplier
            )
        end
        local occurrenceHealing = 0
        for effectIndex = 1, #(occurrence.periodicHealingEffects or {}) do
            occurrenceHealing = occurrenceHealing + Evaluator.ResolvePeriodicEffectMagnitude(
                casterUnit,
                targetUnit,
                occurrence.periodicHealingEffects[effectIndex],
                state.powerLevel,
                occurrence.activeStacks,
                state.rankMultiplier
            )
        end
        local occurrenceIndex = math.max(1, math.floor(tonumber(occurrence.index) or index))
        local weight = discount ^ occurrenceIndex
        periodicDamage = periodicDamage + (Evaluator.ResolveExpectedOccurrenceValue(
            occurrenceDamage,
            occurrence.chancePercent
        ) * weight)
        periodicHealing = periodicHealing + (Evaluator.ResolveExpectedOccurrenceValue(
            occurrenceHealing,
            occurrence.chancePercent
        ) * weight)
    end

    return {
        periodicDamage = periodicDamage,
        periodicHealing = periodicHealing,
        occurrenceCount = #(classification.occurrences or {}),
    }
end

local function normalizeIdentityAuraRef(auraOrApplication, context, cache)
    local reference = type(auraOrApplication) == "table"
        and (auraOrApplication.resolvedAuraRef or auraOrApplication.auraRef)
        or auraOrApplication
    local normalizedRef = normalizeRef(reference)
    if not normalizedRef then
        return nil
    end
    if select(1, parseQualifiedRef(normalizedRef)) then
        return normalizedRef
    end

    local _, _, qualifiedAuraRef = Evaluator.ResolveAuraDefinition(normalizedRef, context, cache)
    return qualifiedAuraRef or normalizedRef
end

function Evaluator.ResolveProjectedAuraIdentity(auraOrApplication, casterEventId, targetEventId, context, cache)
    local auraRef = normalizeIdentityAuraRef(auraOrApplication, context, cache)
    if not auraRef then
        return nil
    end
    local casterId = tonumber(casterEventId)
        or tonumber(type(auraOrApplication) == "table" and auraOrApplication.casterEventId)
        or 0
    local targetId = tonumber(targetEventId)
        or tonumber(type(auraOrApplication) == "table" and auraOrApplication.targetEventId)
        or 0
    casterId = math.floor(casterId)
    targetId = math.floor(targetId)
    if casterId <= 0 or targetId <= 0 then
        return nil
    end
    return {
        auraRef = auraRef,
        casterEventId = casterId,
        targetEventId = targetId,
    }
end

local function cloneProjectedAuraState(state)
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
        stackTurns = copyValue(state.stackTurns),
        profile = copyValue(state.profile),
        definition = copyValue(state.definition or state.auraDefinition),
    }
end

local function setLedgerState(ledger, identity, state)
    if type(ledger) ~= "table" or type(identity) ~= "table" then
        return false
    end
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
    return true
end

local function getLedgerStateReference(ledger, identity)
    local byCaster = type(ledger) == "table"
        and type(ledger.byAuraRef) == "table"
        and ledger.byAuraRef[identity and identity.auraRef]
        or nil
    local byTarget = type(byCaster) == "table" and byCaster[identity and identity.casterEventId] or nil
    return type(byTarget) == "table" and byTarget[identity and identity.targetEventId] or nil
end

function Evaluator.CreateProjectedAuraLedger(activeAuraRecords)
    local ledger = { byAuraRef = {} }
    for index = 1, #(activeAuraRecords or {}) do
        local record = activeAuraRecords[index]
        if type(record) == "table" and (tonumber(record.stacks) or 0) > 0 then
            local identity = Evaluator.ResolveProjectedAuraIdentity(
                record,
                record.casterEventId,
                record.targetEventId,
                { datasetId = record.datasetId }
            )
            if identity then
                local state = cloneProjectedAuraState(record)
                state.auraRef = identity.auraRef
                state.resolvedAuraRef = identity.auraRef
                setLedgerState(ledger, identity, state)
            end
        end
    end
    return ledger
end

function Evaluator.CloneProjectedAuraLedger(ledger)
    local cloned = { byAuraRef = {} }
    for auraRef, byCaster in pairs(type(ledger) == "table" and ledger.byAuraRef or {}) do
        cloned.byAuraRef[auraRef] = {}
        for casterEventId, byTarget in pairs(type(byCaster) == "table" and byCaster or {}) do
            cloned.byAuraRef[auraRef][casterEventId] = {}
            for targetEventId, state in pairs(type(byTarget) == "table" and byTarget or {}) do
                cloned.byAuraRef[auraRef][casterEventId][targetEventId] = cloneProjectedAuraState(state)
            end
        end
    end
    return cloned
end

function Evaluator.GetProjectedAuraState(ledger, identity)
    local state = type(identity) == "table" and getLedgerStateReference(ledger, identity) or nil
    return cloneProjectedAuraState(state)
end

local function cloneLedgerForIdentity(ledger, identity)
    local nextLedger = {
        byAuraRef = copyMap(type(ledger) == "table" and ledger.byAuraRef or {}),
    }
    local previousByCaster = nextLedger.byAuraRef[identity.auraRef]
    local nextByCaster = copyMap(previousByCaster)
    nextLedger.byAuraRef[identity.auraRef] = nextByCaster
    local previousByTarget = nextByCaster[identity.casterEventId]
    local nextByTarget = copyMap(previousByTarget)
    nextByCaster[identity.casterEventId] = nextByTarget
    return nextLedger, nextByTarget
end

local function applyProjectedAuraApplication(previousState, application, identity)
    local profile = type(application) == "table" and application.profile or nil
    if type(profile) ~= "table" and type(application) == "table" then
        profile = Evaluator.BuildAuraProfile(application, { datasetId = application.datasetId })
    end
    if type(profile) ~= "table" then
        return cloneProjectedAuraState(previousState)
    end

    local stackBehavior = normalizeStackBehavior(profile.stackBehavior)
    local maxStacks = normalizePositiveInteger(profile.maxStacks, 1)
    local stacksToApply = normalizePositiveInteger(application and application.stacks, 1)
    local duration = normalizeTurnCount(application and application.duration, profile.duration)
    local state = cloneProjectedAuraState(previousState) or {
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
        profile = copyValue(profile),
        definition = copyValue(profile.definition),
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
    state.profile = copyValue(profile)
    state.definition = copyValue(profile.definition)

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

function Evaluator.ReserveProjectedAura(ledger, application, casterEventId, targetEventId, context, cache)
    if type(application) ~= "table" then
        return ledger, nil, nil, nil
    end
    local identity = Evaluator.ResolveProjectedAuraIdentity(
        application,
        casterEventId,
        targetEventId,
        context or { datasetId = application.datasetId },
        cache
    )
    if not identity then
        return ledger, nil, nil, nil
    end

    local currentLedger = type(ledger) == "table" and ledger or Evaluator.CreateProjectedAuraLedger()
    local previousState = cloneProjectedAuraState(getLedgerStateReference(currentLedger, identity))
    local nextState = applyProjectedAuraApplication(previousState, application, identity)
    local nextLedger, nextByTarget = cloneLedgerForIdentity(currentLedger, identity)
    nextByTarget[identity.targetEventId] = nextState
    return nextLedger, previousState, cloneProjectedAuraState(nextState), identity
end

function Evaluator.EvaluateProjectedAuraApplication(ledger, application, casterUnit, targetUnit, context, cache)
    local casterEventId = math.floor(tonumber(casterUnit and casterUnit.eventID) or 0)
    local targetEventId = math.floor(tonumber(targetUnit and targetUnit.eventID) or 0)
    local nextLedger, previousState, nextState, identity = Evaluator.ReserveProjectedAura(
        ledger,
        application,
        casterEventId,
        targetEventId,
        context or { datasetId = application and application.datasetId },
        cache
    )
    if not identity or type(nextState) ~= "table" then
        return {
            periodicDamage = 0,
            periodicHealing = 0,
            beforePeriodicDamage = 0,
            beforePeriodicHealing = 0,
            afterPeriodicDamage = 0,
            afterPeriodicHealing = 0,
            ledger = nextLedger,
            identity = identity,
        }
    end

    local before = Evaluator.ProjectPeriodicAuraValue(previousState, casterUnit, targetUnit)
    local after = Evaluator.ProjectPeriodicAuraValue(nextState, casterUnit, targetUnit)
    return {
        periodicDamage = (tonumber(after.periodicDamage) or 0) - (tonumber(before.periodicDamage) or 0),
        periodicHealing = (tonumber(after.periodicHealing) or 0) - (tonumber(before.periodicHealing) or 0),
        beforePeriodicDamage = tonumber(before.periodicDamage) or 0,
        beforePeriodicHealing = tonumber(before.periodicHealing) or 0,
        afterPeriodicDamage = tonumber(after.periodicDamage) or 0,
        afterPeriodicHealing = tonumber(after.periodicHealing) or 0,
        beforeOccurrenceCount = tonumber(before.occurrenceCount) or 0,
        afterOccurrenceCount = tonumber(after.occurrenceCount) or 0,
        previousState = previousState,
        nextState = nextState,
        ledger = nextLedger,
        identity = identity,
    }
end

Evaluator.CopyValue = copyValue

return Evaluator
