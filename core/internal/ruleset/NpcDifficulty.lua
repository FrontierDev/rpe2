local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Ruleset = Addon.Internal.Ruleset or {}
Addon.Internal.Ruleset.Rules = Addon.Internal.Ruleset.Rules or {}

local Ruleset = Addon.Internal.Ruleset
local Rules = Ruleset.Rules

local DIFFICULTY_DEFAULTS = {
    normal = {
        healthPercent = 0,
        damagePercent = 0,
        hitBonus = 0,
        defenceBonus = 0,
    },
    heroic = {
        healthPercent = 10,
        damagePercent = 10,
        hitBonus = 0,
        defenceBonus = 0,
    },
    mythic = {
        healthPercent = 25,
        damagePercent = 25,
        hitBonus = 3,
        defenceBonus = 3,
    },
}

local RULE_DEFINITIONS = {
    {
        key = "heroic_npc_health_bonus_percent",
        label = "Heroic NPC Health Bonus (%)",
        default = "10",
        description = "Percentage bonus applied once to NPC Health when the runtime EventUnit is materialized on Heroic difficulty.",
    },
    {
        key = "heroic_npc_damage_bonus_percent",
        label = "Heroic NPC Damage Bonus (%)",
        default = "10",
        description = "Percentage bonus applied to outgoing NPC damage on Heroic difficulty before defender-side damage reduction.",
    },
    {
        key = "heroic_npc_hit_bonus",
        label = "Heroic NPC Hit Bonus",
        default = "0",
        description = "NPC hit bonus on Heroic difficulty. Percent defence uses percentage points; AC, Simple and Complex use a flat attack-total bonus.",
    },
    {
        key = "heroic_npc_defence_bonus",
        label = "Heroic NPC Defence Bonus",
        default = "0",
        description = "NPC defence bonus on Heroic difficulty. Percent defence uses percentage points; AC, Simple and Complex use a flat defence-total bonus.",
    },
    {
        key = "mythic_npc_health_bonus_percent",
        label = "Mythic NPC Health Bonus (%)",
        default = "25",
        description = "Percentage bonus applied once to NPC Health when the runtime EventUnit is materialized on Mythic difficulty.",
    },
    {
        key = "mythic_npc_damage_bonus_percent",
        label = "Mythic NPC Damage Bonus (%)",
        default = "25",
        description = "Percentage bonus applied to outgoing NPC damage on Mythic difficulty before defender-side damage reduction.",
    },
    {
        key = "mythic_npc_hit_bonus",
        label = "Mythic NPC Hit Bonus",
        default = "3",
        description = "NPC hit bonus on Mythic difficulty. Percent defence uses percentage points; AC, Simple and Complex use a flat attack-total bonus.",
    },
    {
        key = "mythic_npc_defence_bonus",
        label = "Mythic NPC Defence Bonus",
        default = "3",
        description = "NPC defence bonus on Mythic difficulty. Percent defence uses percentage points; AC, Simple and Complex use a flat defence-total bonus.",
    },
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

local function normalizeDifficulty(value)
    local difficulty = tostring(value or "normal"):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if difficulty == "heroic" or difficulty == "mythic" then
        return difficulty
    end
    return "normal"
end

local function normalizeFiniteNumber(value, fallback)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return tonumber(fallback) or 0
    end
    return numeric
end

local function ensureDifficultyRuleDefinitions()
    local definitions = type(Rules) == "table" and Rules.Definitions or nil
    if type(definitions) ~= "table" then
        return false
    end

    local eventCategory = nil
    for categoryIndex = 1, #definitions do
        if definitions[categoryIndex] and definitions[categoryIndex].key == "event" then
            eventCategory = definitions[categoryIndex]
            break
        end
    end
    if type(eventCategory) ~= "table" then
        return false
    end

    eventCategory.rules = type(eventCategory.rules) == "table" and eventCategory.rules or {}
    local existing = {}
    for ruleIndex = 1, #eventCategory.rules do
        local rule = eventCategory.rules[ruleIndex]
        if type(rule) == "table" and tostring(rule.key or "") ~= "" then
            existing[rule.key] = true
        end
    end

    for index = 1, #RULE_DEFINITIONS do
        local definition = RULE_DEFINITIONS[index]
        if not existing[definition.key] then
            eventCategory.rules[#eventCategory.rules + 1] = {
                key = definition.key,
                label = definition.label,
                type = "text",
                default = definition.default,
                description = definition.description,
            }
            existing[definition.key] = true
        end
    end

    return true
end

ensureDifficultyRuleDefinitions()

function Ruleset.NormalizeEventDifficulty(value)
    return normalizeDifficulty(value)
end

function Ruleset.GetNpcDifficultyModifiers(difficulty, ruleset)
    local normalizedDifficulty = normalizeDifficulty(difficulty)
    local defaults = DIFFICULTY_DEFAULTS[normalizedDifficulty] or DIFFICULTY_DEFAULTS.normal
    if normalizedDifficulty == "normal" then
        return deepCopy(defaults)
    end

    local resolvedRuleset = ruleset
    if resolvedRuleset == nil and type(Ruleset.GetActiveRuleset) == "function" then
        resolvedRuleset = Ruleset.GetActiveRuleset()
    end

    local function readNumber(suffix, fallback)
        local key = normalizedDifficulty .. "_npc_" .. suffix
        local value = nil
        if type(Ruleset.GetRulesetRuleValueByKey) == "function" then
            value = Ruleset.GetRulesetRuleValueByKey(resolvedRuleset, "event", key, tostring(fallback))
        elseif type(Ruleset.GetRulesetRuleDefinition) == "function"
            and type(Ruleset.GetRulesetRuleValue) == "function"
        then
            local definition = Ruleset.GetRulesetRuleDefinition("event", key)
            value = Ruleset.GetRulesetRuleValue(resolvedRuleset, "event", definition)
        end
        return normalizeFiniteNumber(value, fallback)
    end

    return {
        healthPercent = readNumber("health_bonus_percent", defaults.healthPercent),
        damagePercent = readNumber("damage_bonus_percent", defaults.damagePercent),
        hitBonus = readNumber("hit_bonus", defaults.hitBonus),
        defenceBonus = readNumber("defence_bonus", defaults.defenceBonus),
    }
end
