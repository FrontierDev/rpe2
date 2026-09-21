local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Comms = Addon.Internal.Comms or {}
local Database = Addon.Internal.Database or {}
local Dependencies = Database.Dependecies or {}
local Profile = Addon.Internal.Profile or {}
local Registry = Addon.Internal.Registry or {}
local Ruleset = Addon.Internal.Ruleset or {}
local EventUnit = (Database.Classes or {}).EventUnit
local Dice = Addon.Utils.Dice or {}
local Common = Addon.Utils.Common or {}

local DEFAULT_SKILL_ROLL_DICE = "1d20"
local DEFAULT_SKILL_ICON = "Interface\\Icons\\Ability_Hunter_FocusedAim"
local Operations = Comms.Operations or {}
local SKILL_ROLL_BROADCAST_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SKILL_ROLL_BROADCAST") or nil
local SKILL_ROLL_RESULT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SKILL_ROLL_RESULT") or nil
local skillRollBroadcastSequence = 0

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

local function isLocalPlayerSkillProgressionSource(eventState, eventUnit)
    if type(eventState) ~= "table" or eventState.active ~= true then
        return type(eventUnit) ~= "table"
    end

    return isLocalPlayerEventUnit(eventState, eventUnit)
end

local function resolveRuntimeStatValue(eventUnit, statRef, eventState)
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
    if value == nil and type(EventUnit) == "table" and type(EventUnit.BuildResolvedStats) == "function" then
        local stats = EventUnit.BuildResolvedStats(eventUnit, nil, {
            level = eventState and eventState.level,
        })
        value = findInRows(stats)
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

    local statValue = resolveRuntimeStatValue(eventUnit, derivedStatRef, eventState)
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

local function buildSkillRollChatMessage(result)
    return ("%s rolls %s: %s."):format(
        tostring(result.unitName or "Unknown"),
        tostring(result.skillName or result.skillRef or "Skill"),
        buildRollDetailText(result.baseRoll, result.modifier, result.total)
    )
end

local function emitSkillRollChatMessage(result)
    if not (DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function") then
        return false
    end

    DEFAULT_CHAT_FRAME:AddMessage(buildSkillRollChatMessage(result), 0.6, 0.6, 0.6)
    return true
end

local function buildSkillRollArguments(result)
    return {
        tostring(result.sourceName or ""),
        tostring(result.rollId or ""),
        tostring(result.unitName or "Unknown"),
        tostring(result.skillName or result.skillRef or "Skill"),
        tostring(result.baseRoll or 0),
        tostring(result.modifier or 0),
        tostring(result.total or 0),
    }
end

local function normalizeSkillRollArguments(arguments)
    if type(arguments) ~= "table" then
        return nil
    end

    local sourceName = tostring(arguments[1] or ""):match("^%s*(.-)%s*$") or ""
    local rollId = tostring(arguments[2] or ""):match("^%s*(.-)%s*$") or ""
    local unitName = tostring(arguments[3] or ""):match("^%s*(.-)%s*$") or ""
    local skillName = tostring(arguments[4] or ""):match("^%s*(.-)%s*$") or ""
    local baseRoll = tonumber(arguments[5])
    local modifier = tonumber(arguments[6])
    local total = tonumber(arguments[7])
    if sourceName == "" or rollId == "" or unitName == "" or skillName == ""
        or #sourceName > 96 or #rollId > 96 or #unitName > 96 or #skillName > 128
        or not rollId:match("^[%w%._:%-]+$")
        or baseRoll == nil or modifier == nil or total == nil
        or baseRoll ~= baseRoll or modifier ~= modifier or total ~= total
        or baseRoll == math.huge or baseRoll == -math.huge
        or modifier == math.huge or modifier == -math.huge
        or total == math.huge or total == -math.huge
    then
        return nil
    end

    return {
        sourceName = sourceName,
        rollId = rollId,
        unitName = unitName,
        skillName = skillName,
        baseRoll = baseRoll,
        modifier = modifier,
        total = total,
    }
end

local function getServerChannelId()
    local state = type(Client.GetState) == "function" and Client:GetState() or Client.State
    if type(state) ~= "table" or state.active ~= true then
        return nil
    end

    local channelId = tonumber(state.channelId)
    return channelId and channelId > 0 and channelId or nil
end

local function markSkillRollSeen(result)
    Client.SkillRollSeenIds = Client.SkillRollSeenIds or {}
    Client.SkillRollSeenOrder = Client.SkillRollSeenOrder or {}
    local key = tostring(result.sourceName or "") .. "\31" .. tostring(result.rollId or "")
    if Client.SkillRollSeenIds[key] then
        return false
    end

    Client.SkillRollSeenIds[key] = true
    Client.SkillRollSeenOrder[#Client.SkillRollSeenOrder + 1] = key
    while #Client.SkillRollSeenOrder > 256 do
        local expiredKey = table.remove(Client.SkillRollSeenOrder, 1)
        Client.SkillRollSeenIds[expiredKey] = nil
    end
    return true
end

local function sendSkillRollToServer(result)
    local channelId = getServerChannelId()
    if not channelId or not SKILL_ROLL_BROADCAST_OPCODE or type(Comms.SendToChannel) ~= "function" then
        return false
    end

    return Comms:SendToChannel(channelId, SKILL_ROLL_BROADCAST_OPCODE, buildSkillRollArguments(result), {
        opcode = SKILL_ROLL_BROADCAST_OPCODE,
        scope = "client",
    }) == true
end

local function sendSkillRollToGroupChat(result)
    local distribution = type(Common.GetGroupType) == "function" and Common.GetGroupType() or nil
    if (distribution ~= "PARTY" and distribution ~= "RAID") or type(SendChatMessage) ~= "function" then
        return false
    end

    return pcall(SendChatMessage, buildSkillRollChatMessage(result), distribution)
end

local function publishSkillRoll(result, eventState)
    if type(eventState) == "table" and eventState.active == true then
        -- Event rolls remain authoritative through the RPE server relay. The
        -- local presentation is marked as seen so the relayed result cannot
        -- surface the same roll a second time.
        if sendSkillRollToServer(result) then
            markSkillRollSeen(result)
            emitSkillRollChatMessage(result)
        elseif not sendSkillRollToGroupChat(result) then
            emitSkillRollChatMessage(result)
        end
        return true
    end

    -- Outside an event, normal group chat is the sole visible source. A
    -- private RPE session may still be active, but it must not change this
    -- transport decision.
    if sendSkillRollToGroupChat(result) then
        return true
    end

    return emitSkillRollChatMessage(result)
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

function Client:HandleSkillRollResult(arguments, sender, distribution, target, message)
    local channelId = getServerChannelId()
    local state = type(self.GetState) == "function" and self:GetState() or self.State
    local normalizedSender = type(Common.NormalizeName) == "function"
        and Common.NormalizeName(sender)
        or tostring(sender or "")
    local expectedHost = type(Common.NormalizeName) == "function"
        and Common.NormalizeName(state and state.hostName)
        or tostring(state and state.hostName or "")
    if distribution ~= "CHANNEL" or tonumber(target) ~= channelId
        or normalizedSender == "" or expectedHost == "" or normalizedSender ~= expectedHost
    then
        return false
    end

    local result = normalizeSkillRollArguments(arguments)
    if not result or markSkillRollSeen(result) ~= true then
        return result ~= nil
    end

    return emitSkillRollChatMessage(result)
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

    skillRollBroadcastSequence = skillRollBroadcastSequence + 1
    result.sourceName = type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or ""
    result.rollId = ("r%d-%d"):format(
        math.max(0, math.floor(tonumber(type(Common.GetNow) == "function" and Common.GetNow() or 0) or 0)),
        skillRollBroadcastSequence
    )
    publishSkillRoll(result, eventState)
    emitSkillRollCombatLog(result, skill, eventState, options)
    local progression = Client.SkillProgression
    if type(progression) == "table"
        and type(progression.TryGain) == "function"
        and type(progression.GetRulesetChance) == "function"
        and isLocalPlayerSkillProgressionSource(eventState, eventUnit)
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
