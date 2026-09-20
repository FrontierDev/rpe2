local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}
Addon.Internal.Ruleset = Addon.Internal.Ruleset or {}
Addon.Internal.Ruleset.Rules = Addon.Internal.Ruleset.Rules or {}

local Server = Addon.Server
local Classes = Addon.Internal.Database.Classes
local EventUnit = Classes.EventUnit
local UnitClass = Classes.Unit
local Ruleset = Addon.Internal.Ruleset
local Rules = Ruleset.Rules

if type(Server) ~= "table" or type(EventUnit) ~= "table" then
    return
end

local PLAYER_SCALING_RULE_KEY = "player_scaling_challenge_levels"
local HEALTH_BONUS_PER_PLAYER_RULE_KEY = "npc_health_bonus_per_player_percent"
local DEFAULT_PLAYER_SCALING_CHALLENGE_LEVELS = { "minor", "normal", "elite" }
local DEFAULT_HEALTH_BONUS_PER_PLAYER_PERCENT = 10

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

local function normalizeFiniteNumber(value, fallback)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return tonumber(fallback) or 0
    end
    return numeric
end

local function getChallengeLevelDefinitions()
    if type(UnitClass) == "table" and type(UnitClass.GetChallengeLevelDefinitions) == "function" then
        return UnitClass.GetChallengeLevelDefinitions()
    end

    return {}
end

local function buildChallengeLevelLookup()
    local lookup = {}
    local definitions = getChallengeLevelDefinitions()
    for index = 1, #definitions do
        local value = tostring(definitions[index] and definitions[index].value or "")
        if value ~= "" then
            lookup[value] = true
        end
    end
    return lookup
end

local function normalizeChallengeLevel(value)
    if type(UnitClass) == "table" and type(UnitClass.NormalizeChallengeLevel) == "function" then
        return UnitClass.NormalizeChallengeLevel(value)
    end

    return "normal"
end

local function normalizePlayerScalingChallengeLevels(values, useDefaultsWhenMissing)
    local source = values
    if type(source) ~= "table" then
        if useDefaultsWhenMissing == false then
            source = {}
        else
            source = DEFAULT_PLAYER_SCALING_CHALLENGE_LEVELS
        end
    end

    local valid = buildChallengeLevelLookup()
    local selected = {}
    for index = 1, #source do
        local value = tostring(source[index] or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
        if valid[value] then
            selected[value] = true
        end
    end

    local normalized = {}
    local definitions = getChallengeLevelDefinitions()
    for index = 1, #definitions do
        local value = tostring(definitions[index] and definitions[index].value or "")
        if selected[value] then
            normalized[#normalized + 1] = value
        end
    end
    return normalized
end

local function isDifficultyRuleKey(key)
    local normalized = tostring(key or "")
    return string.match(normalized, "^heroic_npc_") ~= nil
        or string.match(normalized, "^mythic_npc_") ~= nil
end

local function ensurePlayerScalingRuleDefinitions()
    local definitions = type(Rules) == "table" and Rules.Definitions or nil
    if type(definitions) ~= "table" then
        return nil, nil
    end

    local eventCategory = nil
    for categoryIndex = 1, #definitions do
        local category = definitions[categoryIndex]
        if category and category.key == "event" then
            eventCategory = category
            break
        end
    end
    if type(eventCategory) ~= "table" then
        return nil, nil
    end

    eventCategory.rules = type(eventCategory.rules) == "table" and eventCategory.rules or {}

    local challengeRule = nil
    local healthBonusRule = nil
    local retained = {}
    for ruleIndex = 1, #eventCategory.rules do
        local rule = eventCategory.rules[ruleIndex]
        local key = type(rule) == "table" and tostring(rule.key or "") or ""
        if key == PLAYER_SCALING_RULE_KEY then
            challengeRule = rule
        elseif key == HEALTH_BONUS_PER_PLAYER_RULE_KEY then
            healthBonusRule = rule
        else
            retained[#retained + 1] = rule
        end
    end

    challengeRule = challengeRule or {}
    challengeRule.key = PLAYER_SCALING_RULE_KEY
    challengeRule.label = "Player-Count Scaling Challenge Levels"
    challengeRule.type = "dropdown"
    challengeRule.default = deepCopy(DEFAULT_PLAYER_SCALING_CHALLENGE_LEVELS)
    challengeRule.multiSelect = true
    challengeRule.description = "Choose which NPC challenge levels receive Ruleset NPC Health scaling from the current Event player count."
    challengeRule.options = getChallengeLevelDefinitions()

    healthBonusRule = healthBonusRule or {}
    healthBonusRule.key = HEALTH_BONUS_PER_PLAYER_RULE_KEY
    healthBonusRule.label = "NPC Health Bonus Per Player (%)"
    healthBonusRule.type = "text"
    healthBonusRule.default = tostring(DEFAULT_HEALTH_BONUS_PER_PLAYER_PERCENT)
    healthBonusRule.description = "Percentage of Base NPC Health added for each current Event player when the NPC challenge level is selected above. Negative values are supported but final Health cannot fall below zero."

    local insertionIndex = #retained + 1
    for index = 1, #retained do
        if retained[index] and isDifficultyRuleKey(retained[index].key) then
            insertionIndex = index
            break
        end
    end

    table.insert(retained, insertionIndex, challengeRule)
    table.insert(retained, insertionIndex + 1, healthBonusRule)
    eventCategory.rules = retained
    return challengeRule, healthBonusRule
end

local playerScalingRuleDefinition, healthBonusPerPlayerRuleDefinition = ensurePlayerScalingRuleDefinitions()

function Ruleset.GetPlayerScalingChallengeLevels(ruleset)
    local resolvedRuleset = ruleset
    if resolvedRuleset == nil and type(Ruleset.GetActiveRuleset) == "function" then
        resolvedRuleset = Ruleset.GetActiveRuleset()
    end

    local ruleDefinition = type(Ruleset.GetRulesetRuleDefinition) == "function"
        and Ruleset.GetRulesetRuleDefinition("event", PLAYER_SCALING_RULE_KEY)
        or playerScalingRuleDefinition
    local configured = nil
    if ruleDefinition and type(Ruleset.GetRulesetRuleValue) == "function" then
        configured = Ruleset.GetRulesetRuleValue(resolvedRuleset, "event", ruleDefinition)
    end

    if configured == nil then
        configured = DEFAULT_PLAYER_SCALING_CHALLENGE_LEVELS
    end

    return normalizePlayerScalingChallengeLevels(configured, true)
end

function Ruleset.GetNpcHealthBonusPerPlayerPercent(ruleset)
    local resolvedRuleset = ruleset
    if resolvedRuleset == nil and type(Ruleset.GetActiveRuleset) == "function" then
        resolvedRuleset = Ruleset.GetActiveRuleset()
    end

    local ruleDefinition = type(Ruleset.GetRulesetRuleDefinition) == "function"
        and Ruleset.GetRulesetRuleDefinition("event", HEALTH_BONUS_PER_PLAYER_RULE_KEY)
        or healthBonusPerPlayerRuleDefinition
    local configured = nil
    if ruleDefinition and type(Ruleset.GetRulesetRuleValue) == "function" then
        configured = Ruleset.GetRulesetRuleValue(resolvedRuleset, "event", ruleDefinition)
    end

    return normalizeFiniteNumber(configured, DEFAULT_HEALTH_BONUS_PER_PLAYER_PERCENT)
end

function Ruleset.IsPlayerScalingChallengeLevelEnabled(challengeLevel, selectedLevels)
    local normalizedChallengeLevel = normalizeChallengeLevel(challengeLevel)
    local levels = selectedLevels
    if levels == nil then
        levels = Ruleset.GetPlayerScalingChallengeLevels()
    else
        levels = normalizePlayerScalingChallengeLevels(levels, false)
    end

    for index = 1, #levels do
        if levels[index] == normalizedChallengeLevel then
            return true
        end
    end
    return false
end

if EventUnit._challengeLevelPlayerScalingPolicyInstalled ~= true
    and type(EventUnit.ResolveNpcResourcePolicy) == "function"
then
    local baseResolveNpcResourcePolicy = EventUnit.ResolveNpcResourcePolicy

    function EventUnit.ResolveNpcResourcePolicy(baseUnit, playerCount, options)
        local policy = baseResolveNpcResourcePolicy(baseUnit, playerCount, options) or {}
        local resolvedOptions = type(options) == "table" and options or {}

        policy.challengeLevel = normalizeChallengeLevel(baseUnit and baseUnit.challengeLevel)
        if resolvedOptions.applyPerPlayerScaling == nil then
            local selectedLevels = resolvedOptions.playerScalingChallengeLevels
            if selectedLevels == nil then
                selectedLevels = Ruleset.GetPlayerScalingChallengeLevels()
            end
            policy.applyPerPlayerScaling = Ruleset.IsPlayerScalingChallengeLevelEnabled(
                policy.challengeLevel,
                selectedLevels
            )
        end
        if resolvedOptions.healthBonusPerPlayerPercent == nil then
            policy.healthBonusPerPlayerPercent = Ruleset.GetNpcHealthBonusPerPlayerPercent()
        end

        return policy
    end

    EventUnit._challengeLevelPlayerScalingPolicyInstalled = true
end

local function countPlayerUnits(units)
    local count = 0
    for index = 1, #((units) or {}) do
        if units[index] and units[index].isPlayer == true then
            count = count + 1
        end
    end
    return count
end

local function getCurrentEventContext(server)
    local live = type(server.EventState) == "table" and server.EventState.active == true and server.EventState or nil
    local state = live
    if not state and type(server.GetEditableEventState) == "function" then
        state = server:GetEditableEventState()
    end
    state = state or server.EventDraftState
    return state, countPlayerUnits(state and state.units or {})
end

local function buildResourceOptions(options, difficulty)
    local source = type(options) == "table" and options or {}
    return {
        level = source.level,
        difficulty = source.difficulty ~= nil and source.difficulty or difficulty,
        playerScalingChallengeLevels = source.playerScalingChallengeLevels,
        applyPerPlayerScaling = source.applyPerPlayerScaling,
        healthBonusPerPlayerPercent = source.healthBonusPerPlayerPercent,
        healthResourceRef = source.healthResourceRef,
        healthPercent = source.healthPercent,
        difficultyModifiers = source.difficultyModifiers,
    }
end

if Server._unitResourceVariantIntegrationInstalled ~= true then
    local baseBuildResolvedNpcVariant = Server.BuildResolvedNpcVariant

    function Server:BuildResolvedNpcVariant(registryId, options)
        local variant = type(baseBuildResolvedNpcVariant) == "function"
            and baseBuildResolvedNpcVariant(self, registryId, options)
            or nil
        if type(variant) ~= "table" or type(variant.baseUnit) ~= "table"
            or type(EventUnit.BuildUnitDerivedResources) ~= "function"
        then
            return variant
        end

        local contextState = getCurrentEventContext(self)
        local difficulty = type(options) == "table" and options.difficulty or nil
        if difficulty == nil then
            difficulty = contextState and contextState.difficulty or "normal"
        end

        local level = type(options) == "table" and options.level or nil
        if level == nil then
            level = contextState and contextState.level or variant.level
        end

        local playerCount = type(options) == "table" and options.playerCount or nil
        if playerCount == nil then
            playerCount = variant.playerCount
        end

        local resourceOptions = buildResourceOptions(options, difficulty)
        resourceOptions.level = level
        local resources, policy = EventUnit.BuildUnitDerivedResources(
            variant.baseUnit,
            variant.presetIndex,
            playerCount,
            resourceOptions
        )
        variant.resources = deepCopy(resources)
        variant.resourcePolicy = deepCopy(policy)
        variant.playerCount = policy and policy.playerCount or variant.playerCount
        variant.level = policy and policy.level or level
        return variant
    end

    Server._unitResourceVariantIntegrationInstalled = true
end

local function materializeMissingRuntimeResources(server, unit, playerCount, difficulty, level)
    if type(unit) ~= "table" or unit.isPlayer == true or tostring(unit.registryID or "") == "" then
        return false
    end
    if type(EventUnit.HasExplicitRuntimeResources) == "function" and EventUnit.HasExplicitRuntimeResources(unit) then
        return false
    end

    local variant = server:BuildResolvedNpcVariant(unit.registryID, {
        presetIndex = unit.presetIndex,
        playerCount = playerCount,
        difficulty = difficulty,
        level = level,
        selectRandomAppearance = false,
    })
    if type(variant) ~= "table" then
        return false
    end

    unit.resources = deepCopy(variant.resources or {})
    return true
end

if Server._unitResourceDirectAddIntegrationInstalled ~= true then
    local baseAddEventNpcUnit = Server.AddEventNpcUnit

    function Server:AddEventNpcUnit(data)
        local prepared = type(data) == "table" and data or nil
        if prepared and prepared.isPlayer ~= true and tostring(prepared.registryID or "") ~= "" then
            local hasExplicit = type(EventUnit.HasExplicitRuntimeResources) == "function"
                and EventUnit.HasExplicitRuntimeResources(prepared)
                or false
            if not hasExplicit then
                local state, playerCount = getCurrentEventContext(self)
                local variant = self:BuildResolvedNpcVariant(prepared.registryID, {
                    presetIndex = prepared.presetIndex,
                    playerCount = playerCount,
                    difficulty = state and state.difficulty or "normal",
                    level = state and state.level or nil,
                    selectRandomAppearance = false,
                })
                if variant then
                    prepared = deepCopy(prepared)
                    prepared.resources = deepCopy(variant.resources or {})
                end
            end
        end

        return type(baseAddEventNpcUnit) == "function" and baseAddEventNpcUnit(self, prepared) or nil
    end

    Server._unitResourceDirectAddIntegrationInstalled = true
end

if Server._unitResourceDraftIntegrationInstalled ~= true then
    local baseGetEventDraftState = Server.GetEventDraftState

    function Server:GetEventDraftState()
        local existing = self.EventDraftState
        if type(existing) == "table" and type(existing.units) == "table" then
            local playerCount = countPlayerUnits(existing.units)
            local difficulty = existing.difficulty or "normal"
            local level = existing.level
            for index = 1, #existing.units do
                materializeMissingRuntimeResources(self, existing.units[index], playerCount, difficulty, level)
            end
        end

        return type(baseGetEventDraftState) == "function" and baseGetEventDraftState(self) or existing
    end

    Server._unitResourceDraftIntegrationInstalled = true
end
