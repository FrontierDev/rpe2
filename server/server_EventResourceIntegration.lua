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
local DEFAULT_PLAYER_SCALING_CHALLENGE_LEVELS = { "minor", "normal", "elite" }

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

local function ensurePlayerScalingRuleDefinition()
    local definitions = type(Rules) == "table" and Rules.Definitions or nil
    if type(definitions) ~= "table" then
        return nil
    end

    for categoryIndex = 1, #definitions do
        local category = definitions[categoryIndex]
        if category and category.key == "event" then
            category.rules = type(category.rules) == "table" and category.rules or {}
            for ruleIndex = 1, #category.rules do
                if category.rules[ruleIndex] and category.rules[ruleIndex].key == PLAYER_SCALING_RULE_KEY then
                    return category.rules[ruleIndex]
                end
            end

            local rule = {
                key = PLAYER_SCALING_RULE_KEY,
                label = "Player-Count Scaling Challenge Levels",
                type = "dropdown",
                default = deepCopy(DEFAULT_PLAYER_SCALING_CHALLENGE_LEVELS),
                multiSelect = true,
                description = "Choose which NPC challenge levels apply configured per-player resource scaling.",
                options = getChallengeLevelDefinitions(),
            }
            category.rules[#category.rules + 1] = rule
            return rule
        end
    end

    return nil
end

local playerScalingRuleDefinition = ensurePlayerScalingRuleDefinition()

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
    local state = live or server.EventDraftState
    return state, countPlayerUnits(state and state.units or {})
end

local function buildResourceOptions(options, difficulty)
    local source = type(options) == "table" and options or {}
    return {
        difficulty = source.difficulty ~= nil and source.difficulty or difficulty,
        playerScalingChallengeLevels = source.playerScalingChallengeLevels,
        applyPerPlayerScaling = source.applyPerPlayerScaling,
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

        local contextState = type(self.EventState) == "table" and self.EventState.active == true and self.EventState
            or self.EventDraftState
        local difficulty = type(options) == "table" and options.difficulty or nil
        if difficulty == nil then
            difficulty = contextState and contextState.difficulty or "normal"
        end

        local playerCount = type(options) == "table" and options.playerCount or nil
        if playerCount == nil then
            playerCount = variant.playerCount
        end

        local resources, policy = EventUnit.BuildUnitDerivedResources(
            variant.baseUnit,
            variant.presetIndex,
            playerCount,
            buildResourceOptions(options, difficulty)
        )
        variant.resources = deepCopy(resources)
        variant.resourcePolicy = deepCopy(policy)
        variant.playerCount = policy and policy.playerCount or variant.playerCount
        return variant
    end

    Server._unitResourceVariantIntegrationInstalled = true
end

local function materializeMissingRuntimeResources(server, unit, playerCount, difficulty)
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
            for index = 1, #existing.units do
                materializeMissingRuntimeResources(self, existing.units[index], playerCount, difficulty)
            end
        end

        return type(baseGetEventDraftState) == "function" and baseGetEventDraftState(self) or existing
    end

    Server._unitResourceDraftIntegrationInstalled = true
end
