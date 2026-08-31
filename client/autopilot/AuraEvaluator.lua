local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Database = Addon.Internal.Database or {}

Client.AutopilotAuraEvaluator = Client.AutopilotAuraEvaluator or {}
local Evaluator = Client.AutopilotAuraEvaluator

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

local function getAuraManager()
    return Addon.Client
        and Addon.Client.Spellcasting
        and Addon.Client.Spellcasting.AuraManager
        or nil
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

local function normalizeStackBehavior(value)
    return tostring(value or "") == "independent_duration"
        and "independent_duration"
        or "refresh_duration"
end

local function normalizePositiveInteger(value, fallback)
    local normalized = math.floor(tonumber(value) or tonumber(fallback) or 0)
    return math.max(1, normalized)
end

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

    local effects = definition.effects or {}
    local directDamageEffects = {}
    local directHealingEffects = {}
    local hasDamage = false
    local hasHealing = false
    for index = 1, #effects do
        local effect = effects[index]
        local effectType = tostring(type(effect) == "table" and effect.type or "")
        if effectType == "damage" then
            hasDamage = true
            directDamageEffects[#directDamageEffects + 1] = copyValue(effect)
        elseif effectType == "heal" then
            hasHealing = true
            directHealingEffects[#directHealingEffects + 1] = copyValue(effect)
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
        directDamageEffects = directDamageEffects,
        directHealingEffects = directHealingEffects,
        directHealEffects = directHealingEffects,
        damageEffects = directDamageEffects,
        healingEffects = directHealingEffects,
        controlEffects = controlEffects,
        control = control,
        controlFlags = control,
        triggeredEvents = triggeredEvents,
        triggeredEventDescriptors = triggeredEvents,
        events = copyValue(events),
        hasDamage = hasDamage,
        hasHeal = hasHealing,
        hasHealing = hasHealing,
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
        duration = tonumber(effect.duration) or (profile and profile.duration) or nil,
        powerLevel = tonumber(effect.basePower) or 0,
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
        stackBehavior = normalizeStackBehavior(entry.stackBehavior),
        maxStacks = normalizePositiveInteger(entry.maxStacks, 1),
        lastAdvancedOwnerTurnNumber = tonumber(entry.lastAdvancedOwnerTurnNumber),
        lastAdvancedTurnNumber = tonumber(entry.lastAdvancedTurnNumber),
        -- AuraManager mutates pendingAdvancedOwnerTurnNumber as queue/scheduling
        -- bookkeeping without bumping the Aura revision. It is not tactical Aura
        -- state, so excluding it keeps one frozen planner record tied to one
        -- revision-covered source generation.
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
Evaluator.CopyValue = copyValue

return Evaluator
