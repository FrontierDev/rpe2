local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}
Addon.Internal.Ruleset = Addon.Internal.Ruleset or {}

local Classes = Addon.Internal.Database.Classes
local EventUnit = Classes.EventUnit
local UnitClass = Classes.Unit
local Ruleset = Addon.Internal.Ruleset

if type(EventUnit) ~= "table" or type(UnitClass) ~= "table" then
    return
end

local DEFAULT_SCALING_LEVELS = { "minor", "normal", "elite" }
local DEFAULT_HEALTH_BONUS_PER_PLAYER_PERCENT = 10
local DEFAULT_HEALTH_PERCENT = {
    normal = 0,
    heroic = 10,
    mythic = 25,
}
local VALID_CHALLENGE_LEVELS = {
    swarm = true,
    minor = true,
    normal = true,
    elite = true,
    boss = true,
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end
    return copy
end

local function normalizeRef(value)
    local text = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return text ~= "" and text or nil
end

local function normalizePlayerCount(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function normalizeFiniteNumber(value, fallback)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return tonumber(fallback) or 0
    end
    return numeric
end

local function normalizeLevel(value)
    return math.max(1, math.floor(normalizeFiniteNumber(value, 1)))
end

local function normalizeDifficulty(value)
    local difficulty = tostring(value or "normal"):lower()
    if difficulty == "heroic" or difficulty == "mythic" then
        return difficulty
    end
    return "normal"
end

local function clampRatio(value)
    return math.max(0, math.min(1, tonumber(value) or 0))
end

local function getActiveRuleValue(categoryKey, ruleKey, fallbackValue)
    local activeRuleset = type(Ruleset.GetActiveRuleset) == "function" and Ruleset.GetActiveRuleset() or nil
    if type(Ruleset.GetRulesetRuleValueByKey) == "function" then
        return Ruleset.GetRulesetRuleValueByKey(activeRuleset, categoryKey, ruleKey, fallbackValue)
    end

    local definition = type(Ruleset.GetRulesetRuleDefinition) == "function"
        and Ruleset.GetRulesetRuleDefinition(categoryKey, ruleKey)
        or nil
    if definition and type(Ruleset.GetRulesetRuleValue) == "function" then
        local value = Ruleset.GetRulesetRuleValue(activeRuleset, categoryKey, definition)
        if value ~= nil then
            return value
        end
    end

    return deepCopy(fallbackValue)
end

local function buildScalingChallengeLookup(options)
    local configured = type(options) == "table" and options.playerScalingChallengeLevels or nil
    if configured == nil then
        configured = getActiveRuleValue("event", "player_scaling_challenge_levels", DEFAULT_SCALING_LEVELS)
    end

    local lookup = {}
    for index = 1, #(type(configured) == "table" and configured or {}) do
        local level = tostring(configured[index] or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
        if VALID_CHALLENGE_LEVELS[level] then
            lookup[level] = true
        end
    end
    return lookup
end

local function resolveHealthBonusPerPlayerPercent(options)
    if type(options) == "table" and options.healthBonusPerPlayerPercent ~= nil then
        return normalizeFiniteNumber(options.healthBonusPerPlayerPercent, DEFAULT_HEALTH_BONUS_PER_PLAYER_PERCENT)
    end

    if type(Ruleset.GetNpcHealthBonusPerPlayerPercent) == "function" then
        return normalizeFiniteNumber(
            Ruleset.GetNpcHealthBonusPerPlayerPercent(),
            DEFAULT_HEALTH_BONUS_PER_PLAYER_PERCENT
        )
    end

    return normalizeFiniteNumber(
        getActiveRuleValue(
            "event",
            "npc_health_bonus_per_player_percent",
            tostring(DEFAULT_HEALTH_BONUS_PER_PLAYER_PERCENT)
        ),
        DEFAULT_HEALTH_BONUS_PER_PLAYER_PERCENT
    )
end

local function resolveDifficultyHealthPercent(difficulty, options)
    if type(options) == "table" and options.healthPercent ~= nil then
        return tonumber(options.healthPercent) or 0
    end

    if type(options) == "table" and type(options.difficultyModifiers) == "table" then
        return tonumber(options.difficultyModifiers.healthPercent) or 0
    end

    if type(Ruleset.GetNpcDifficultyModifiers) == "function" then
        local modifiers = Ruleset.GetNpcDifficultyModifiers(difficulty)
        if type(modifiers) == "table" then
            return tonumber(modifiers.healthPercent) or 0
        end
    end

    if difficulty == "normal" then
        return 0
    end

    local key = difficulty .. "_npc_health_bonus_percent"
    return tonumber(getActiveRuleValue("event", key, DEFAULT_HEALTH_PERCENT[difficulty] or 0))
        or (DEFAULT_HEALTH_PERCENT[difficulty] or 0)
end

local function resolveHealthResourceRef(options)
    local explicit = type(options) == "table" and normalizeRef(options.healthResourceRef) or nil
    if explicit then
        return explicit
    end
    return normalizeRef(getActiveRuleValue("resources", "health_stat", ""))
end

local function resolvePreset(baseUnit, presetIndex)
    if type(UnitClass.ResolvePreset) ~= "function" then
        return nil, 0
    end
    return UnitClass.ResolvePreset(baseUnit, presetIndex)
end

local function applyPresetResourceModifiers(values, preset)
    if type(UnitClass.ApplyResourceModifiers) ~= "function" then
        return deepCopy(values)
    end
    return UnitClass.ApplyResourceModifiers(values, preset)
end

local function buildSeedValues(baseUnit, preset, policy)
    local values = {}
    local ratioByRef = {}
    local seen = {}
    local progressionValues = {}
    if type(UnitClass.ResolveResourceValues) == "function" then
        local resolvedValues = UnitClass.ResolveResourceValues(baseUnit, policy.level)
        for index = 1, #resolvedValues do
            local entry = resolvedValues[index]
            local resourceRef = normalizeRef(entry and entry.resourceRef)
            if resourceRef and progressionValues[resourceRef] == nil then
                progressionValues[resourceRef] = normalizeFiniteNumber(entry.value, 0)
            end
        end
    end

    for index = 1, #((baseUnit and baseUnit.resources) or {}) do
        local entry = baseUnit.resources[index]
        local resourceRef = type(entry) == "table" and normalizeRef(entry.resourceRef or entry.resourceID or entry.id) or nil
        if resourceRef and not seen[resourceRef] then
            local explicitCurrent = tonumber(entry.currentValue ~= nil and entry.currentValue or entry.current)
            local explicitMax = tonumber(entry.maxValue ~= nil and entry.maxValue or entry.max or entry.maximum)
            local baseValue
            local ratio = 1

            if explicitCurrent ~= nil or explicitMax ~= nil then
                local baseMax = explicitMax ~= nil and explicitMax or (explicitCurrent or 0)
                local baseCurrent = explicitCurrent ~= nil and explicitCurrent or baseMax
                if baseMax > 0 then
                    ratio = clampRatio(baseCurrent / baseMax)
                end
                baseValue = baseMax
            else
                baseValue = progressionValues[resourceRef]
                if baseValue == nil then
                    baseValue = normalizeFiniteNumber(entry.value, 0)
                end
            end

            local scaledValue = baseValue
            if policy.applyPerPlayerScaling
                and policy.healthResourceRef ~= nil
                and resourceRef == policy.healthResourceRef
                and policy.healthBonusPerPlayerPercent ~= 0
            then
                local multiplier = 1 + (policy.playerCount * policy.healthBonusPerPlayerPercent / 100)
                scaledValue = baseValue * multiplier
            end

            values[#values + 1] = {
                resourceRef = resourceRef,
                value = math.max(0, scaledValue),
            }
            ratioByRef[resourceRef] = ratio
            seen[resourceRef] = true
        end
    end

    for index = 1, #((preset and preset.resourceModifiers) or {}) do
        local modifier = preset.resourceModifiers[index]
        local resourceRef = type(modifier) == "table" and normalizeRef(modifier.resourceRef) or nil
        if resourceRef and not seen[resourceRef] then
            values[#values + 1] = {
                resourceRef = resourceRef,
                value = 0,
            }
            ratioByRef[resourceRef] = 1
            seen[resourceRef] = true
        end
    end

    return values, ratioByRef
end

function EventUnit.ResolveNpcResourcePolicy(baseUnit, playerCount, options)
    local resolvedOptions = type(options) == "table" and options or {}
    local normalizedPlayerCount = normalizePlayerCount(playerCount)
    local challengeLevel = UnitClass.ResolveEffectiveChallengeLevel(baseUnit, resolvedOptions.presetIndex)
    local scalingLookup = buildScalingChallengeLookup(resolvedOptions)
    local applyPerPlayerScaling

    if resolvedOptions.applyPerPlayerScaling ~= nil then
        applyPerPlayerScaling = resolvedOptions.applyPerPlayerScaling == true
    else
        applyPerPlayerScaling = scalingLookup[challengeLevel] == true
    end

    local difficulty = normalizeDifficulty(resolvedOptions.difficulty)
    local healthResourceRef = resolveHealthResourceRef(resolvedOptions)
    local healthBonusPerPlayerPercent = resolveHealthBonusPerPlayerPercent(resolvedOptions)
    local healthPercent = resolveDifficultyHealthPercent(difficulty, resolvedOptions)

    return {
        level = normalizeLevel(resolvedOptions.level),
        playerCount = normalizedPlayerCount,
        challengeLevel = challengeLevel,
        applyPerPlayerScaling = applyPerPlayerScaling,
        healthResourceRef = healthResourceRef,
        healthBonusPerPlayerPercent = healthBonusPerPlayerPercent,
        difficulty = difficulty,
        healthPercent = healthPercent,
    }
end

function EventUnit.BuildUnitDerivedResources(baseUnit, presetIndex, playerCount, options)
    if type(baseUnit) ~= "table" then
        return {}, EventUnit.ResolveNpcResourcePolicy(nil, playerCount, options)
    end

    local preset, normalizedPresetIndex = resolvePreset(baseUnit, presetIndex)
    local policyOptions = deepCopy(type(options) == "table" and options or {})
    policyOptions.presetIndex = normalizedPresetIndex
    local policy = EventUnit.ResolveNpcResourcePolicy(baseUnit, playerCount, policyOptions)
    local seedValues, ratioByRef = buildSeedValues(baseUnit, preset, policy)
    local modifiedValues = applyPresetResourceModifiers(seedValues, preset)
    local resources = {}

    for index = 1, #(modifiedValues or {}) do
        local entry = modifiedValues[index]
        local resourceRef = type(entry) == "table" and normalizeRef(entry.resourceRef) or nil
        if resourceRef then
            local maxValue = math.max(0, tonumber(entry.value) or 0)
            local currentValue = maxValue * (ratioByRef[resourceRef] ~= nil and ratioByRef[resourceRef] or 1)

            if policy.healthResourceRef ~= nil and resourceRef == policy.healthResourceRef and policy.healthPercent ~= 0 then
                local multiplier = 1 + (policy.healthPercent / 100)
                maxValue = math.max(0, maxValue * multiplier)
                currentValue = math.max(0, currentValue * multiplier)
            end

            if currentValue > maxValue then
                currentValue = maxValue
            end

            resources[#resources + 1] = {
                resourceRef = resourceRef,
                currentValue = currentValue,
                maxValue = maxValue,
            }
        end
    end

    policy.presetIndex = normalizedPresetIndex
    return resources, policy
end

function EventUnit.HasExplicitRuntimeResources(eventUnit)
    local resources = type(eventUnit) == "table" and eventUnit.resources or nil
    if type(resources) ~= "table" or #resources == 0 then
        return false
    end

    for index = 1, #resources do
        local entry = resources[index]
        if type(entry) == "table" and (entry.currentValue ~= nil or entry.maxValue ~= nil) then
            return true
        end
    end
    return false
end

if EventUnit._unitDerivedResourceFallbackInstalled ~= true then
    local baseBuildResolvedResources = EventUnit.BuildResolvedResources

    function EventUnit.BuildResolvedResources(eventUnit, playerCount, options)
        if type(eventUnit) ~= "table" or eventUnit.isPlayer == true then
            return type(baseBuildResolvedResources) == "function"
                and baseBuildResolvedResources(eventUnit, playerCount, options)
                or {}
        end

        if EventUnit.HasExplicitRuntimeResources(eventUnit) then
            return type(baseBuildResolvedResources) == "function"
                and baseBuildResolvedResources(eventUnit, playerCount, options)
                or deepCopy(eventUnit.resources or {})
        end

        local baseUnit = type(eventUnit.GetResolvedUnit) == "function" and eventUnit:GetResolvedUnit() or nil
        if type(baseUnit) ~= "table" then
            return type(baseBuildResolvedResources) == "function"
                and baseBuildResolvedResources(eventUnit, playerCount, options)
                or {}
        end

        return EventUnit.BuildUnitDerivedResources(baseUnit, eventUnit.presetIndex, playerCount, options)
    end

    EventUnit._unitDerivedResourceFallbackInstalled = true
end
