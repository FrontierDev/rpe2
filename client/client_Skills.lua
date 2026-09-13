local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Database = Addon.Internal.Database or {}
local Dependencies = Database.Dependecies or {}
local Profile = Addon.Internal.Profile or {}
local Registry = Addon.Internal.Registry or {}
local Ruleset = Addon.Internal.Ruleset or {}
local Dice = Addon.Utils.Dice or {}
local Common = Addon.Utils.Common or {}

local DEFAULT_SKILL_ROLL_DICE = "1d20"
local DEFAULT_SKILL_ICON = "Interface\\Icons\\Ability_Hunter_FocusedAim"

local function ensureSkillRollRule()
    local rules = Ruleset.Rules and Ruleset.Rules.Definitions or nil
    if type(rules) ~= "table" then
        return false
    end

    local skillCategory = nil
    for categoryIndex = 1, #rules do
        local category = rules[categoryIndex]
        if type(category) == "table" and tostring(category.key or "") == "skills" then
            skillCategory = category
            break
        end
    end
    if type(skillCategory) ~= "table" then
        return false
    end

    skillCategory.rules = type(skillCategory.rules) == "table" and skillCategory.rules or {}
    for ruleIndex = 1, #skillCategory.rules do
        local rule = skillCategory.rules[ruleIndex]
        if type(rule) == "table" and tostring(rule.key or "") == "skill_roll_dice" then
            return true
        end
    end

    skillCategory.rules[#skillCategory.rules + 1] = {
        key = "skill_roll_dice",
        label = "Skill Roll Dice",
        type = "text",
        default = DEFAULT_SKILL_ROLL_DICE,
        description = "Dice expression used for rollable non-combat skill checks before adding the resolved skill modifier.",
    }
    return true
end

ensureSkillRollRule()

local function normalizeRef(value)
    local text = tostring(value or "")
    if text == "" then
        return nil
    end
    return text
end

local function parseQualifiedRef(reference)
    local normalizedRef = normalizeRef(reference)
    if not normalizedRef then
        return nil, nil
    end

    if type(Dependencies.ParseSourceStatRef) == "function" then
        local datasetId, entryId = Dependencies.ParseSourceStatRef(normalizedRef)
        if datasetId and entryId then
            return tostring(datasetId), tostring(entryId)
        end
    end

    local datasetId, entryId = normalizedRef:match("^([^:]+):(.+)$")
    if not datasetId or not entryId or datasetId == "" or entryId == "" then
        return nil, nil
    end

    return datasetId, entryId
end

local function resolveActivatedSkill(skillRef)
    local datasetId, skillId = parseQualifiedRef(skillRef)
    if not datasetId or not skillId then
        return nil, nil
    end

    local datasets = type(Registry.GetActivatedDatasets) == "function" and Registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        if tostring(dataset and dataset.id or "") == datasetId then
            for skillIndex = 1, #((dataset and dataset.skills) or {}) do
                local skill = dataset.skills[skillIndex]
                if tostring(skill and skill.id or "") == skillId then
                    return dataset, skill
                end
            end
            return dataset, nil
        end
    end

    return nil, nil
end

local function getSkillRollDiceExpression()
    local activeRuleset = type(Ruleset.GetActiveRuleset) == "function" and Ruleset.GetActiveRuleset() or nil
    local definition = type(Ruleset.GetRulesetRuleDefinition) == "function"
        and Ruleset.GetRulesetRuleDefinition("skills", "skill_roll_dice")
        or nil
    local value = nil
    if definition and type(Ruleset.GetRulesetRuleValue) == "function" then
        value = Ruleset.GetRulesetRuleValue(activeRuleset, "skills", definition)
    end

    local expression = tostring(value or DEFAULT_SKILL_ROLL_DICE):gsub("^%s+", ""):gsub("%s+$", "")
    if expression == "" then
        expression = DEFAULT_SKILL_ROLL_DICE
    end
    return expression
end

local function resolveEventState(options)
    if type(options) == "table" and type(options.eventState) == "table" then
        return options.eventState
    end
    if type(Client.GetEventState) == "function" then
        return Client:GetEventState()
    end
    return Client.EventState
end

local function resolveRequestedEventUnit(eventState, options)
    if type(options) == "table" then
        local explicitUnit = options.eventUnit or options.unit
        if type(explicitUnit) == "table" then
            return explicitUnit
        end
    end

    if type(eventState) ~= "table" or eventState.active ~= true then
        return nil
    end

    if type(Client.ResolveControlledEventUnit) == "function" then
        local controlledUnit = Client:ResolveControlledEventUnit(eventState)
        if type(controlledUnit) == "table" then
            return controlledUnit
        end
    end
    if type(Client.ResolveLocalEventUnit) == "function" then
        return Client:ResolveLocalEventUnit(eventState)
    end

    return nil
end

local function isLocalPlayerEventUnit(eventState, eventUnit)
    if type(eventUnit) ~= "table" or eventUnit.isPlayer ~= true then
        return false
    end
    if type(eventState) ~= "table" or eventState.active ~= true then
        return true
    end
    if type(Client.ResolveLocalEventUnit) ~= "function" then
        return false
    end

    local localUnit = Client:ResolveLocalEventUnit(eventState)
    local localEventId = tonumber(localUnit and localUnit.eventID) or 0
    local requestedEventId = tonumber(eventUnit.eventID) or 0
    return localEventId > 0 and localEventId == requestedEventId
end

local function resolveRuntimeStatValue(eventUnit, statRef)
    local normalizedStatRef = normalizeRef(statRef)
    if type(eventUnit) ~= "table" or not normalizedStatRef then
        return nil
    end

    local function findInRows(rows)
        for index = 1, #(rows or {}) do
            local row = rows[index]
            if tostring(row and row.statRef or "") == normalizedStatRef then
                local value = tonumber(row.currentValue)
                if value == nil then
                    value = tonumber(row.value)
                end
                return value
            end
        end
        return nil
    end

    local value = findInRows(eventUnit.stats)
    if value == nil and type(eventUnit.GetResolvedUnit) == "function" then
        local resolvedUnit = eventUnit:GetResolvedUnit()
        value = findInRows(resolvedUnit and resolvedUnit.stats)
    end
    if value == nil then
        return nil
    end

    local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.ApplyStatModifiers) == "function" then
        local ok, modifiedValue = pcall(auraManager.ApplyStatModifiers, auraManager, eventUnit, normalizedStatRef, value)
        if ok and tonumber(modifiedValue) ~= nil then
            value = tonumber(modifiedValue)
        end
    end

    return value
end

local function roundValue(value)
    if type(Common.Round) == "function" then
        return Common.Round(value)
    end

    local numericValue = tonumber(value) or 0
    if numericValue < 0 then
        return math.ceil(numericValue - 0.5)
    end
    return math.floor(numericValue + 0.5)
end

local function resolveSkillModifier(skillRef, skill, eventState, eventUnit)
    if type(eventUnit) ~= "table" or eventUnit.isPlayer == true then
        if type(eventUnit) == "table" and not isLocalPlayerEventUnit(eventState, eventUnit) then
            return nil, "remote-player"
        end

        local row = type(Profile.GetResolvedSkillRow) == "function" and Profile.GetResolvedSkillRow(skillRef) or nil
        if type(row) ~= "table" then
            return nil, "unresolved-skill"
        end
        return tonumber(row.value) or 0, nil, row
    end

    local derivedStatRef = normalizeRef(skill and skill.derivedStatRef)
    if not derivedStatRef then
        return 0
    end

    local statValue = resolveRuntimeStatValue(eventUnit, derivedStatRef)
    if statValue == nil then
        return 0
    end

    local multiplier = tonumber(skill and skill.derivedMultiplier) or 0
    return roundValue(statValue * multiplier)
end

local function resolveUnitName(eventUnit)
    local name = tostring(eventUnit and eventUnit.name or "")
    if name ~= "" then
        return name
    end

    if type(Common.GetPlayerName) == "function" then
        name = tostring(Common.GetPlayerName() or "")
    end
    if name == "" then
        return "Unknown"
    end
    return name
end

local function formatNumber(value)
    local numericValue = tonumber(value) or 0
    if numericValue == math.floor(numericValue) then
        return tostring(math.floor(numericValue))
    end

    local formatted = ("%.2f"):format(numericValue)
    formatted = formatted:gsub("0+$", ""):gsub("%.$", "")
    return formatted
end

local function buildRollDetailText(baseRoll, modifier, total)
    local normalizedModifier = tonumber(modifier) or 0
    if normalizedModifier < 0 then
        return ("%s - %s = %s"):format(
            formatNumber(baseRoll),
            formatNumber(math.abs(normalizedModifier)),
            formatNumber(total)
        )
    end

    return ("%s + %s = %s"):format(
        formatNumber(baseRoll),
        formatNumber(normalizedModifier),
        formatNumber(total)
    )
end

local function emitSkillRollCombatLog(result, skill, eventState, options)
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end
    if type(options) == "table" and options.emitCombatLog == false then
        return false
    end

    local icon = tostring(skill and skill.icon or "")
    if icon == "" then
        icon = DEFAULT_SKILL_ICON
    end

    local entry = {
        eventId = tostring(eventState.id or ""),
        entryType = "status",
        casterDisplayName = tostring(result.unitName or "Unknown"),
        targetDisplayName = ("rolls %s:"):format(tostring(result.skillName or result.skillRef or "Skill")),
        targetCount = 1,
        iconTexture = icon,
        spellIconTexture = icon,
        labelText = tostring(result.skillName or result.skillRef or "Skill"),
        detailText = buildRollDetailText(result.baseRoll, result.modifier, result.total),
    }

    if type(Client.QueueCombatLogEntryEmission) == "function" then
        return Client:QueueCombatLogEntryEmission(entry) == true
    end
    if type(Client.EmitCombatLogEntry) == "function" then
        return Client:EmitCombatLogEntry(entry) == true
    end

    return false
end

function Client:GetSkillRollDiceExpression()
    return getSkillRollDiceExpression()
end

function Client:ResolveSkillRollModifier(skillRef, options)
    local normalizedSkillRef = normalizeRef(skillRef)
    if not normalizedSkillRef then
        return nil, "invalid-skill"
    end

    local _, skill = resolveActivatedSkill(normalizedSkillRef)
    if type(skill) ~= "table" then
        return nil, "missing-skill"
    end
    if skill.rollable ~= true or tostring(skill.skillType or "noncombat") ~= "noncombat" then
        return nil, "not-rollable"
    end

    local eventState = resolveEventState(options)
    local eventUnit = resolveRequestedEventUnit(eventState, options)
    return resolveSkillModifier(normalizedSkillRef, skill, eventState, eventUnit)
end

function Client:RollSkill(skillRef, options)
    local normalizedSkillRef = normalizeRef(skillRef)
    if not normalizedSkillRef then
        return nil, "invalid-skill"
    end

    local dataset, skill = resolveActivatedSkill(normalizedSkillRef)
    if type(dataset) ~= "table" or type(skill) ~= "table" then
        return nil, "missing-skill"
    end
    if skill.rollable ~= true or tostring(skill.skillType or "noncombat") ~= "noncombat" then
        return nil, "not-rollable"
    end
    if type(Dice.RollExpression) ~= "function" then
        return nil, "dice-unavailable"
    end

    local eventState = resolveEventState(options)
    local eventUnit = resolveRequestedEventUnit(eventState, options)
    if type(eventState) == "table" and eventState.active == true and type(eventUnit) ~= "table" then
        return nil, "missing-event-unit"
    end

    local modifier, modifierError = resolveSkillModifier(normalizedSkillRef, skill, eventState, eventUnit)
    if modifier == nil then
        return nil, modifierError or "unresolved-modifier"
    end

    local expression = getSkillRollDiceExpression()
    local rollContext = type(options) == "table" and options or nil
    local baseRoll = tonumber(Dice.RollExpression(rollContext, expression, 1, 20)) or 0
    local total = baseRoll + modifier
    local result = {
        skillRef = normalizedSkillRef,
        skillName = tostring(skill.name or skill.id or normalizedSkillRef),
        skillIcon = tostring(skill.icon or ""),
        datasetId = tostring(dataset.id or ""),
        eventId = type(eventState) == "table" and tostring(eventState.id or "") or "",
        unitEventId = tonumber(eventUnit and eventUnit.eventID) or 0,
        unitName = resolveUnitName(eventUnit),
        rollExpression = expression,
        baseRoll = baseRoll,
        modifier = modifier,
        total = total,
    }

    emitSkillRollCombatLog(result, skill, eventState, options)
    local progression = Client.SkillProgression
    if type(progression) == "table"
        and type(progression.TryGain) == "function"
        and type(progression.GetRulesetChance) == "function"
    then
        progression:TryGain(
            normalizedSkillRef,
            "noncombat-roll",
            progression:GetRulesetChance("noncombat_skill_gain_chance_on_roll", 0),
            options
        )
    end
    return result
end

function Client:ActivateActionBarSkill(skillRef)
    return self:RollSkill(skillRef, {
        source = "action-bar",
    })
end

return true
