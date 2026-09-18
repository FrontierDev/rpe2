local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Combat = Addon.Client.Combat or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Internal.Ruleset = Addon.Internal.Ruleset or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Combat = Addon.Client.Combat
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Ruleset = Addon.Internal.Ruleset or {}
local Registry = Addon.Internal.Registry or {}
local Database = Addon.Internal.Database or {}
local Profile = Addon.Internal.Profile or {}
local Common = Addon.Utils.Common or {}
local Dice = Addon.Utils.Dice or {}
local Normalization = Addon.Client.Combat.Normalization or {}
local Debug = Addon.Debug
local UI = Addon.UI or {}

local HIT_CHECK_REQUEST_OPCODE = Operations.GetOpcode and Operations:GetOpcode("COMBAT_HIT_CHECK_REQUEST") or nil
local HIT_CHECK_RESPONSE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("COMBAT_HIT_CHECK_RESPONSE") or nil
local DAMAGE_RESOLVED_OPCODE = Operations.GetOpcode and Operations:GetOpcode("COMBAT_DAMAGE_RESOLVED") or nil
local DAMAGE_RESOLVED_ACK_OPCODE = Operations.GetOpcode and Operations:GetOpcode("COMBAT_DAMAGE_RESOLVED_ACK") or nil

local RESULT_PASS = "pass"
local RESULT_FAIL = "fail"

local ACTION_ICONS = {
    defend = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    pass = "Interface\\Icons\\INV_Misc_QuestionMark",
    melee = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    ranged = "Interface\\Icons\\Ability_Marksmanship",
    spell = "Interface\\Icons\\Spell_Holy_MindVision",
}

local trimText = Normalization.TrimText
local normalizeToken = Normalization.NormalizeToken
local normalizeResultToken = Normalization.NormalizeResultToken
local splitList = Normalization.SplitList
local Dependencies = Database.Dependecies or {}
local REACTION_ATTACK_TYPES = { "melee", "ranged", "spell" }
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local SPELLCAST_SLOW_HELPER_MS = 25
local SPELLCAST_SLOW_TOTAL_MS = 100
local MAX_DAMAGE_OUTCOME_RETRIES = 3

local function getNowMilliseconds()
    if type(GetTimePreciseSec) == "function" then
        return GetTimePreciseSec() * 1000
    end

    return (GetTime and GetTime() or 0) * 1000
end

local function isSpellcastTimingEnabled()
    return type(Addon.Debug) == "table" and Addon.Debug.SpellcastTiming == true
end

local function ensureSpellcastInternalLoggingEnabled()
    if type(Debug) == "table" and type(Debug.EnsureInternalLevelEnabled) == "function" then
        Debug.EnsureInternalLevelEnabled()
    end
end

local function buildTimingSegment(label, elapsed, threshold)
    local numericElapsed = math.max(0, tonumber(elapsed) or 0)
    local isSlow = numericElapsed >= (tonumber(threshold) or SPELLCAST_SLOW_HELPER_MS)
    return ("%s=%.2fms%s"):format(
        tostring(label or "phase"),
        numericElapsed,
        isSlow and " SLOW" or ""
    ), isSlow
end

local function logDamageFinalizeTimingLine(contextLabel, parts, totalElapsed, threshold)
    if not isSpellcastTimingEnabled() or type(Debug) ~= "table" or type(Debug.Internal) ~= "function" then
        return false
    end

    ensureSpellcastInternalLoggingEnabled()

    local slowThreshold = tonumber(threshold) or SPELLCAST_SLOW_TOTAL_MS
    local totalText, totalSlow = buildTimingSegment("total", totalElapsed, slowThreshold)
    local segments = { totalText }
    local hasSlow = totalSlow

    for index = 1, #(parts or {}) do
        local part = parts[index]
        if type(part) == "table" and type(part.label) == "string" then
            local segment, isSlow = buildTimingSegment(part.label, part.elapsed, part.threshold or SPELLCAST_SLOW_HELPER_MS)
            segments[#segments + 1] = segment
            hasSlow = hasSlow or isSlow
        end
    end

    Debug.Internal(
        "%sSpell damage finalize timing [%s]: %s",
        hasSlow and "SLOW " or "",
        tostring(contextLabel or "unknown"),
        table.concat(segments, ", ")
    )
    return true
end

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function enqueueReactionPresentationWork(fn, ...)
    local tasks = getTasks()
    if tasks and type(tasks.Enqueue) == "function" then
        tasks:Enqueue(fn, ...)
        return true
    end

    if C_Timer and C_Timer.After then
        local args = { ... }
        local argCount = select("#", ...)
        C_Timer.After(0, function()
            fn(unpack(args, 1, argCount))
        end)
        return true
    end

    fn(...)
    return true
end

local function refreshReactionWidgetDeferred(targetClient, reason)
    if type(targetClient) ~= "table" then
        return false
    end

    if type(targetClient.RefreshReactionWidget) == "function" then
        targetClient:RefreshReactionWidget(reason)
    end
    if type(targetClient.ShowReactionWidget) == "function" then
        targetClient:ShowReactionWidget()
    end
    return true
end

local function getMountRuleValue(ruleKey, fallback)
    local ruleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("mounts", ruleKey) or nil
    local value = nil
    if Ruleset.GetRulesetRuleValue then
        value = Ruleset.GetRulesetRuleValue(ruleset, "mounts", ruleDefinition)
    end
    if value == nil then
        return fallback
    end

    return value
end

local function getCombatRuleValue(ruleKey, fallback)
    local ruleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("combat", ruleKey) or nil
    local value = nil
    if Ruleset.GetRulesetRuleValue then
        value = Ruleset.GetRulesetRuleValue(ruleset, "combat", ruleDefinition)
    end
    if value == nil then
        return fallback
    end

    return value
end

local function normalizeDefensiveReactionStatRef(value)
    local token = normalizeToken(value)
    return token and string.lower(token) or nil
end

local function isPassReactionAction(action)
    if type(action) == "table" then
        return normalizeResultToken(action.id) == RESULT_PASS
            or normalizeResultToken(action.kind) == RESULT_PASS
            or normalizeResultToken(action.resolutionSystem) == RESULT_PASS
    end

    return normalizeResultToken(action) == RESULT_PASS
end

local function resolveDefensiveReactionAction(entry, action)
    if type(action) == "table" then
        return action
    end
    if isPassReactionAction(action) then
        return { id = RESULT_PASS, resolutionSystem = RESULT_PASS }
    end
    if type(entry) == "table" and type(Combat.FindReactionAction) == "function" then
        return Combat:FindReactionAction(entry, action)
    end
    return nil
end

local function getDefensiveReactionStatRef(action)
    return normalizeDefensiveReactionStatRef(type(action) == "table" and action.statRef or nil)
end

local function isDefensiveReactionStatBypassed(statRef)
    local configured = getCombatRuleValue("defensive_reaction_limit_bypass_stats", {})
    local candidates = {}

    local function addCandidate(value)
        local normalized = normalizeDefensiveReactionStatRef(value)
        if normalized then
            candidates[normalized] = true
        end
    end

    if type(configured) == "table" then
        for key, value in pairs(configured) do
            if type(key) == "number" then
                addCandidate(value)
            elseif value == true then
                addCandidate(key)
            elseif type(value) == "string" then
                addCandidate(value)
            end
        end
    elseif type(splitList) == "function" then
        local values = splitList(configured)
        for index = 1, #values do
            addCandidate(values[index])
        end
    else
        addCandidate(configured)
    end

    return candidates[statRef] == true
end

local function getDefensiveReactionLedgerIdentity(entry, action)
    if type(entry) ~= "table" or type(action) ~= "table" then
        return nil
    end

    local eventState = entry.eventState
    local eventId = normalizeToken(entry.eventId)
    if not eventId then
        eventId = normalizeToken(eventState and eventState.id)
    end
    local turnNumber = tonumber(entry.turnNumber)
    if turnNumber == nil then
        turnNumber = tonumber(eventState and eventState.turnNumber)
    end
    turnNumber = math.floor(turnNumber or 0)
    local defenderEventId = math.floor(tonumber(entry.defenderEventId or (entry.defenderUnit and entry.defenderUnit.eventID)) or 0)
    local resolutionSystem = normalizeToken(action.resolutionSystem or entry.defenceSystem)
    local statRef = getDefensiveReactionStatRef(action)
    if not eventId or turnNumber <= 0 or defenderEventId <= 0 or not resolutionSystem or not statRef then
        return nil
    end

    return table.concat({
        string.lower(eventId),
        tostring(turnNumber),
        tostring(defenderEventId),
        string.lower(resolutionSystem),
        statRef,
    }, "\031"), eventId, turnNumber
end

local function getCurrentEventIdentity(eventState, eventId, turnNumber)
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false, "stale-event"
    end

    local currentEventState = Client.EventState
    if type(currentEventState) ~= "table" then
        return true
    end
    if currentEventState.active ~= true then
        return false, "stale-event"
    end
    if currentEventState ~= eventState then
        return false, "stale-event"
    end

    local currentEventId = normalizeToken(currentEventState.id)
    if currentEventId and currentEventId ~= eventId then
        return false, "stale-event"
    end

    local currentTurnNumber = math.floor(tonumber(currentEventState.turnNumber) or 0)
    if currentTurnNumber > 0 and currentTurnNumber ~= turnNumber then
        return false, currentTurnNumber < turnNumber and "stale-turn" or "stale-event"
    end

    return true
end

local function getDefensiveReactionLedger(eventId, turnNumber)
    -- This is transient client runtime state. Keeping only the active event
    -- turn bounds stale entries without making tick/page changes a reset.
    local ledger = Combat.DefensiveReactionUseLedger
    if type(ledger) == "table" then
        if ledger.eventId == eventId and ledger.turnNumber == turnNumber then
            return ledger
        end
        if ledger.eventId == eventId and (tonumber(ledger.turnNumber) or 0) > turnNumber then
            return nil
        end
    end

    ledger = {
        eventId = eventId,
        turnNumber = turnNumber,
        uses = {},
    }
    Combat.DefensiveReactionUseLedger = ledger
    return ledger
end

function Combat:ClearDefensiveReactionUseLedger(eventId)
    local ledger = self.DefensiveReactionUseLedger
    if type(ledger) ~= "table" then
        return false
    end

    local normalizedEventId = normalizeToken(eventId)
    if not normalizedEventId or ledger.eventId == normalizedEventId then
        self.DefensiveReactionUseLedger = nil
        return true
    end

    return false
end

function Combat:CanUseDefensiveReaction(entry, action)
    if type(entry) ~= "table" then
        if isPassReactionAction(action) then
            return true
        end
        return false, "invalid-entry"
    end
    local resolvedAction = resolveDefensiveReactionAction(entry, action)
    if not resolvedAction then
        return false, "invalid-action"
    end
    if resolvedAction.enabled == false then
        return false, resolvedAction.unavailableReason or "disabled"
    end
    if isPassReactionAction(resolvedAction) then
        return true
    end
    if getCombatRuleValue("limit_defensive_reactions_per_turn", false) ~= true then
        return true
    end

    local statRef = getDefensiveReactionStatRef(resolvedAction)
    if not statRef then
        return true
    end
    if isDefensiveReactionStatBypassed(statRef) then
        return true
    end

    local identity, eventId, turnNumber = getDefensiveReactionLedgerIdentity(entry, resolvedAction)
    if not identity then
        return false, "invalid-defensive-context"
    end

    local currentEventValid, currentEventReason = getCurrentEventIdentity(entry.eventState, eventId, turnNumber)
    if not currentEventValid then
        return false, currentEventReason
    end

    local ledger = getDefensiveReactionLedger(eventId, turnNumber)
    if not ledger then
        return false, "stale-turn"
    end
    if ledger.uses[identity] == true then
        return false, "used-this-turn"
    end

    return true
end

function Combat:ConsumeDefensiveReactionUse(entry, action)
    local resolvedAction = resolveDefensiveReactionAction(entry, action)
    if not resolvedAction or resolvedAction.enabled == false then
        return false, "disabled"
    end
    if isPassReactionAction(resolvedAction) then
        return true
    end

    local statRef = getDefensiveReactionStatRef(resolvedAction)
    if getCombatRuleValue("limit_defensive_reactions_per_turn", false) ~= true or not statRef then
        return true
    end
    if isDefensiveReactionStatBypassed(statRef) then
        return true
    end

    local available, reason = self:CanUseDefensiveReaction(entry, resolvedAction)
    if not available then
        return false, reason
    end

    local identity, eventId, turnNumber = getDefensiveReactionLedgerIdentity(entry, resolvedAction)
    if not identity then
        return false, "invalid-defensive-context"
    end

    local ledger = getDefensiveReactionLedger(eventId, turnNumber)
    if not ledger or ledger.uses[identity] == true then
        return false, "used-this-turn"
    end
    ledger.uses[identity] = true
    return true
end

function Combat:RefreshDefensiveReactionAvailability(entry, actions)
    if type(actions) ~= "table" then
        return actions
    end

    for index = 1, #actions do
        local action = actions[index]
        if type(action) == "table" and not isPassReactionAction(action) then
            if action.enabled == false and action.unavailableReason == "used-this-turn" then
                action.enabled = true
                action.unavailableReason = nil
            end
            if action.enabled ~= false then
                local available, reason = self:CanUseDefensiveReaction(entry, action)
                if not available then
                    action.enabled = false
                    action.unavailableReason = reason
                end
            end
        end
    end

    return actions
end

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function unitHasShield(unit)
    if type(unit) ~= "table" then
        return false
    end

    if normalizeToken(unit.shield) then
        return true
    end

    local resolvedUnit = type(unit.GetResolvedUnit) == "function" and unit:GetResolvedUnit() or nil
    if normalizeToken(resolvedUnit and resolvedUnit.shield or nil) then
        return true
    end

    if unit.isPlayer == true then
        local equipped = Profile.GetEquippedItem and Profile.GetEquippedItem("shield") or nil
        if type(equipped) == "table" and normalizeToken(equipped.itemRef) then
            return true
        end
    end

    return false
end

local function normalizeComparisonToken(value)
    local text = trimText(value or "")
    if text == "" then
        return ""
    end

    return string.lower((text:gsub("[%s%p_]+", "")))
end

local function resolveDismountResistanceThreshold()
    local statRef = normalizeToken(getMountRuleValue("dismount_resistance_stat", ""))
    if not statRef then
        return nil
    end

    local value = Profile.GetResolvedStatValue and Profile.GetResolvedStatValue(statRef, 0) or 0
    return math.max(0, math.min(100, tonumber(value) or 0))
end

local function tryResolveMountedDismount(entry, damageResult)
    if type(entry) ~= "table" or type(damageResult) ~= "table" then
        return false
    end
    if getMountRuleValue("dismount_on_direct_damage", false) ~= true then
        return false
    end
    if not (Profile.IsMounted and Profile.IsMounted()) then
        return false
    end
    if damageResult.applied ~= true or (tonumber(damageResult.amount) or 0) <= 0 then
        return false
    end

    local eventState = entry.eventState or (Client.GetEventState and Client:GetEventState() or nil)
    local localEventUnit = Client.ResolveLocalEventUnit and Client:ResolveLocalEventUnit(eventState) or nil
    if tonumber(localEventUnit and localEventUnit.eventID) ~= tonumber(entry.defenderEventId) then
        return false
    end

    local threshold = resolveDismountResistanceThreshold()
    local roll = Dice.RollRandom and tonumber(Dice.RollRandom(entry.context, 1, 100)) or math.random(1, 100)
    if threshold ~= nil and roll <= threshold then
        return false
    end

    return Profile.SetMounted and Profile.SetMounted(false) == true or false
end

local function findEventUnitById(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit, index
        end
    end

    return nil
end

local function getResolvedName(value)
    if Common.NormalizeName then
        return Common.NormalizeName(value)
    end

    return trimText(value)
end

local function resolveSenderForUnit(eventState, eventUnit)
    if type(eventUnit) ~= "table" then
        return ""
    end

    if eventUnit.isPlayer == true then
        return getResolvedName(eventUnit.ownerID or eventUnit.controllerID or eventUnit.name)
    end

    local controllerId = tonumber(eventUnit.controllerID) or 0
    if controllerId > 0 then
        local controllerUnit = findEventUnitById(eventState and eventState.units, controllerId)
        if controllerUnit then
            return getResolvedName(controllerUnit.ownerID or controllerUnit.controllerID or controllerUnit.name)
        end
    end

    return getResolvedName(eventUnit.controllerID or eventUnit.ownerID or eventUnit.name)
end

local function isLocalAuthorityForUnit(eventState, eventUnit)
    local spellcasting = Client.Spellcasting or nil
    local localPlayerName = spellcasting and type(spellcasting.GetLocalPlayerName) == "function" and spellcasting.GetLocalPlayerName() or ""
    if localPlayerName == "" then
        return false
    end

    return resolveSenderForUnit(eventState, eventUnit) == localPlayerName
end

local function resolveDropdownLabel(options, value)
    for index = 1, #(options or {}) do
        local option = options[index]
        if option and option.value == value then
            return option.label
        end
    end

    return nil
end

function Combat:ResolveStatReferenceLabel(statRef)
    local normalizedRef = normalizeToken(statRef)
    if not normalizedRef then
        return ""
    end

    local options = Ruleset.GetRulesetRuleOptions and Ruleset.GetRulesetRuleOptions({
        type = "dropdown",
        optionsSource = "statReference",
    }) or {}
    local optionLabel = resolveDropdownLabel(options, normalizedRef)
    if optionLabel then
        return optionLabel
    end

    return normalizedRef
end

function Combat:ResolveDefenceTextForStat(statRef)
    local normalizedRef = normalizeToken(statRef)
    if not normalizedRef then
        return ""
    end

    local revision = getConfigurationRevision()
    self.DefenceTextForStatCache = self.DefenceTextForStatCache or {}
    local cacheKey = ("%d:%s"):format(revision, normalizedRef)
    local cached = self.DefenceTextForStatCache[cacheKey]
    if cached ~= nil then
        return tostring(cached)
    end

    if type(Registry.ResolveStatReference) == "function" then
        local _, stat = Registry:ResolveStatReference(normalizedRef)
        local defenceLabel = tostring(stat and stat.defenceLabel or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if defenceLabel ~= "" then
            self.DefenceTextForStatCache[cacheKey] = defenceLabel
            return defenceLabel
        end
    end

    local label = self:ResolveStatReferenceLabel(normalizedRef)
    self.DefenceTextForStatCache[cacheKey] = label
    return label
end

function Combat:ResolveStatDefinition(statRef)
    local normalizedRef = normalizeToken(statRef)
    if not normalizedRef or type(Registry.ResolveStatReference) ~= "function" then
        return nil, nil
    end

    return Registry:ResolveStatReference(normalizedRef)
end

function Combat:ResolveDefenceActionDisplay(statRef)
    local normalizedRef = normalizeToken(statRef)
    if not normalizedRef then
        return {
            label = "",
            icon = DEFAULT_ICON,
        }
    end

    local revision = getConfigurationRevision()
    self.DefenceActionDisplayCache = self.DefenceActionDisplayCache or {}
    local cacheKey = ("%d:%s"):format(revision, normalizedRef)
    local cached = self.DefenceActionDisplayCache[cacheKey]
    if type(cached) == "table" then
        return cached
    end

    local _, stat = self:ResolveStatDefinition(statRef)
    local display = {
        label = self:ResolveDefenceTextForStat(normalizedRef),
        icon = tostring(stat and stat.icon or "") ~= "" and tostring(stat.icon) or DEFAULT_ICON,
    }
    self.DefenceActionDisplayCache[cacheKey] = display
    return display
end

local function enqueueCombatTextEntry(entry)
    local combatText = Client.UI and Client.UI.CombatText and Client.UI.CombatText.Get and Client.UI.CombatText:Get() or nil
    if not combatText or type(combatText.Enqueue) ~= "function" then
        return false
    end

    return combatText:Enqueue(entry)
end

local function showTrackedCombatText(eventState, unit, text, direction, color, size)
    local spellcasting = Client.Spellcasting or nil
    if type(text) ~= "string" or text == "" or type(eventState) ~= "table" or type(unit) ~= "table" then
        return false
    end
    if not spellcasting or type(spellcasting.IsCombatTextTrackedUnit) ~= "function" then
        return false
    end
    if not spellcasting.IsCombatTextTrackedUnit(Client, eventState, unit) then
        return false
    end

    return enqueueCombatTextEntry({
        text = text,
        color = color or UI.ResolveColor(nil, "text.primary"),
        size = size or "normal",
        direction = direction or "UP",
    })
end

local function buildCombatResult(entry, resultToken, resultType)
    return {
        effectType = "damage",
        resultType = resultType or resultToken or "invalid",
        hitCheckResult = resultToken,
        landed = resultToken == RESULT_PASS,
        pending = resultToken == nil,
        amount = 0,
        checkId = entry and entry.checkId or nil,
        eventId = entry and entry.eventId or nil,
        spellRef = entry and entry.spellRef or nil,
        componentKey = entry and entry.componentKey or nil,
    }
end

local function getUnitDisplayName(unit)
    return tostring(unit and unit.name or "Unknown")
end

local function getLocalEventUnitId(eventState)
    local localEventUnit = Client.ResolveLocalEventUnit and Client:ResolveLocalEventUnit(eventState) or nil
    return tonumber(localEventUnit and localEventUnit.eventID) or 0
end

local function resolveReactionTickerSpellIcon(entry)
    local spellIcon = Client.ResolveCombatLogSpellIcon and Client:ResolveCombatLogSpellIcon(nil, entry and entry.spellRef or nil) or nil
    if type(spellIcon) == "string" and spellIcon ~= "" and spellIcon ~= DEFAULT_ICON then
        return spellIcon
    end

    local attackType = tostring(entry and entry.attackType or "")
    return ACTION_ICONS[attackType] or DEFAULT_ICON
end

local function emitReactionCombatLog(entry, detailText, accentColor, role)
    if type(entry) ~= "table" or type(detailText) ~= "string" or detailText == "" or type(Client.EmitCombatLogEntry) ~= "function" then
        return false
    end

    local eventState = type(entry.eventState) == "table" and entry.eventState or nil
    local localEventUnitId = getLocalEventUnitId(eventState)
    local attackerEventId = tonumber(entry.attackerEventId or (entry.attackerUnit and entry.attackerUnit.eventID)) or 0
    local defenderEventId = tonumber(entry.defenderEventId or (entry.defenderUnit and entry.defenderUnit.eventID)) or 0
    if (role == "attacker" and attackerEventId ~= localEventUnitId) or (role == "defender" and defenderEventId ~= localEventUnitId) then
        return false
    end

    return Client:EmitCombatLogEntry({
        eventId = tostring(eventState and eventState.id or ""),
        entryType = "status",
        casterDisplayName = getUnitDisplayName(entry.attackerUnit),
        targetDisplayName = getUnitDisplayName(entry.defenderUnit),
        targetCount = 1,
        spellIconTexture = resolveReactionTickerSpellIcon(entry),
        detailText = detailText,
        accentColor = accentColor,
    })
end

local function sendCombatWhisper(targetName, opcode, arguments, metadataOverrides)
    local normalizedTarget = getResolvedName(targetName)
    if type(Comms.SendMessage) ~= "function" or normalizedTarget == "" or not opcode then
        return false
    end

    local metadata = nil
    local spellcasting = Client.Spellcasting
    if spellcasting and type(spellcasting.BuildSendMetadata) == "function" then
        metadata = spellcasting.BuildSendMetadata(opcode)
    else
        metadata = {
            opcode = opcode,
            scope = "client",
        }
    end

    if type(metadataOverrides) == "table" then
        for key, value in pairs(metadataOverrides) do
            metadata[key] = value
        end
    end

    return Comms:SendMessage("WHISPER", opcode, arguments, normalizedTarget, metadata) and true or false
end

local function getPendingDamageOutcomes(client, create)
    if type(client) ~= "table" then
        return nil
    end
    if type(client.PendingCombatDamageOutcomes) ~= "table" and create == true then
        client.PendingCombatDamageOutcomes = {}
    end
    return client.PendingCombatDamageOutcomes
end

function Client:ClearPendingCombatDamageOutcome(checkId, eventId)
    local outcomes = getPendingDamageOutcomes(self, false)
    local normalizedCheckId = normalizeToken(checkId)
    if type(outcomes) ~= "table" or not normalizedCheckId then
        return false
    end

    local outcome = outcomes[normalizedCheckId]
    if type(outcome) ~= "table"
        or (eventId ~= nil and tostring(outcome.eventId or "") ~= tostring(eventId or ""))
    then
        return false
    end

    outcomes[normalizedCheckId] = nil
    return true
end

function Combat:ClearPendingDamageOutcomes(eventId)
    local outcomes = getPendingDamageOutcomes(Client, false)
    if type(outcomes) ~= "table" then
        return false
    end

    local normalizedEventId = eventId ~= nil and tostring(eventId or "") or nil
    for checkId, outcome in pairs(outcomes) do
        if normalizedEventId == nil
            or tostring(type(outcome) == "table" and outcome.eventId or "") == normalizedEventId
        then
            outcomes[checkId] = nil
        end
    end
    return true
end

local function sendPendingDamageOutcome(client, outcome)
    if type(client) ~= "table"
        or type(outcome) ~= "table"
        or type(outcome.arguments) ~= "table"
        or tostring(outcome.targetName or "") == ""
    then
        return false
    end

    outcome.sendAttempts = (tonumber(outcome.sendAttempts) or 0) + 1
    local function handleFailure(_, reason)
        local outcomes = getPendingDamageOutcomes(client, false)
        local current = outcomes and outcomes[outcome.checkId] or nil
        if current ~= outcome then
            return
        end

        outcome.lastFailure = tostring(reason or "send-failed")
        local retryCount = tonumber(outcome.retryCount) or 0
        if retryCount < MAX_DAMAGE_OUTCOME_RETRIES then
            outcome.retryCount = retryCount + 1
            sendPendingDamageOutcome(client, outcome)
            return
        end

        if type(Debug) == "table" and type(Debug.Internal) == "function" then
            Debug.Internal(
                "Authoritative combat damage hand-off exhausted retries: checkId=%s eventId=%s target=%s reason=%s.",
                tostring(outcome.checkId or ""),
                tostring(outcome.eventId or ""),
                tostring(outcome.targetName or ""),
                tostring(outcome.lastFailure or "send-failed")
            )
        end
    end

    local sent = sendCombatWhisper(
        outcome.targetName,
        DAMAGE_RESOLVED_OPCODE,
        outcome.arguments,
        { onFailed = handleFailure }
    )
    if not sent then
        handleFailure(nil, "enqueue-failed")
    end
    return sent
end

local function sendDamageOutcomeAcknowledgement(targetName, checkId, eventId)
    return sendCombatWhisper(targetName, DAMAGE_RESOLVED_ACK_OPCODE, {
        checkId,
        eventId,
    })
end

local function finalizeDamageCombatEvents(client, entry, landed)
    if type(entry) ~= "table" then
        return false
    end

    if type(Combat.CompleteActionDamageResolution) == "function" then
        Combat:CompleteActionDamageResolution(client, entry, landed == true)
    end

    if landed ~= true
        or not isLocalAuthorityForUnit(entry.eventState, entry.defenderUnit)
        or type(Combat.RunTargetHooks) ~= "function"
    then
        return false
    end

    local hookContext = Combat:CloneValue(entry.context or {})
    hookContext.effectType = "damage"
    hookContext.attackType = entry.attackType
    hookContext.hitType = type(entry.lastDamageResult) == "table" and entry.lastDamageResult.hitType or nil
    hookContext.wasCritical = type(entry.lastDamageResult) == "table" and entry.lastDamageResult.wasCritical == true or false
    return Combat:RunTargetHooks(client, hookContext, entry.targetEvents, { entry.defenderEventId }, entry.attackerEventId)
end

function Combat:ResolveSenderForUnit(eventState, eventUnit)
    return resolveSenderForUnit(eventState, eventUnit)
end

function Combat:SendCombatWhisper(targetName, opcode, arguments)
    return sendCombatWhisper(targetName, opcode, arguments)
end

function Combat:FinalizeLocalDamageResult(entry, damageResult)
    if type(entry) ~= "table" or type(damageResult) ~= "table" then
        return false
    end

    local timingEnabled = isSpellcastTimingEnabled()
    local totalStartTime = timingEnabled and getNowMilliseconds() or nil
    local timingParts = timingEnabled and {} or nil
    local context = type(entry) == "table" and entry.context or nil
    local castEntry = type(context) == "table" and context.castEntry or nil
    local spell = type(context) == "table" and context.spell or nil
    local state = self.GetOrCreateActionCombatEventState and self:GetOrCreateActionCombatEventState(castEntry, spell) or nil
    if type(state) == "table" and type(self.RegisterActionCasterEventOutcome) == "function" then
        local outcomeStartTime = timingEnabled and getNowMilliseconds() or nil
        self:RegisterActionCasterEventOutcome(state, { entry.defenderEventId }, {
            effectType = "damage",
            attackType = entry.attackType,
            hitType = damageResult.hitType,
            wasCritical = damageResult.wasCritical == true,
        })
        if timingEnabled then
            timingParts[#timingParts + 1] = {
                label = "caster-outcome",
                elapsed = getNowMilliseconds() - outcomeStartTime,
            }
        end
    end

    local resourceDeltas = damageResult.resourceDeltas
    if type(Combat.RegisterActionDamageCombatLog) == "function" then
        local combatLogStartTime = timingEnabled and getNowMilliseconds() or nil
        Combat:RegisterActionDamageCombatLog(entry, damageResult)
        if timingEnabled then
            timingParts[#timingParts + 1] = {
                label = "combat-log",
                elapsed = getNowMilliseconds() - combatLogStartTime,
            }
        end
    end
    local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    if type(entry.effect) == "table"
        and entry.effect.applyAura == true
        and type(entry.effect.auraRef) == "string"
        and entry.effect.auraRef ~= ""
        and auraManager
        and type(auraManager.ApplyAuraFromContext) == "function"
    then
        local applyAuraStartTime = timingEnabled and getNowMilliseconds() or nil
        auraManager:ApplyAuraFromContext(Client, entry.context, entry.effect.auraRef, entry.effect.auraStacks or 1, nil, 0)
        if timingEnabled then
            timingParts[#timingParts + 1] = {
                label = "apply-aura",
                elapsed = getNowMilliseconds() - applyAuraStartTime,
            }
        end
    end

    local combatEventsStartTime = timingEnabled and getNowMilliseconds() or nil
    finalizeDamageCombatEvents(Client, entry, true)
    Combat:EmitDamageTypeEvent(Client, entry, damageResult)
    if timingEnabled then
        timingParts[#timingParts + 1] = {
            label = "combat-events",
            elapsed = getNowMilliseconds() - combatEventsStartTime,
        }
    end

    local dismountStartTime = timingEnabled and getNowMilliseconds() or nil
    tryResolveMountedDismount(entry, damageResult)
    if timingEnabled then
        timingParts[#timingParts + 1] = {
            label = "dismount",
            elapsed = getNowMilliseconds() - dismountStartTime,
        }
    end

    local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    -- appliedDelta is the resulting health delta, so fully absorbed hits do
    -- not trigger cancelOnDamage.
    if auraManager
        and type(auraManager.HandleDamageTaken) == "function"
        and (tonumber(damageResult.appliedDelta) or 0) < 0
    then
        local damageTakenStartTime = timingEnabled and getNowMilliseconds() or nil
        auraManager:HandleDamageTaken(Client, entry.eventState, entry.defenderEventId, entry.context)
        if timingEnabled then
            timingParts[#timingParts + 1] = {
                label = "damage-taken",
                elapsed = getNowMilliseconds() - damageTakenStartTime,
            }
        end
    end

    local hasAbsorptionPresentation = (tonumber(damageResult.absorbedAmount) or 0) > 0
    if (type(resourceDeltas) ~= "table" or #resourceDeltas == 0) and not hasAbsorptionPresentation then
        if timingEnabled then
            logDamageFinalizeTimingLine(
                ("%s/%s"):format(tostring(entry.spellRef or "spell"), tostring(entry.componentKey or "component")),
                timingParts,
                getNowMilliseconds() - totalStartTime,
                SPELLCAST_SLOW_TOTAL_MS
            )
        end
        return true
    end

    if type(Client.MarkEventUnitInteraction) == "function" then
        local interactionStartTime = timingEnabled and getNowMilliseconds() or nil
        Client:MarkEventUnitInteraction(entry.eventState, entry.attackerUnit, entry.defenderUnit, damageResult, entry.spellRef)
        if timingEnabled then
            timingParts[#timingParts + 1] = {
                label = "interaction",
                elapsed = getNowMilliseconds() - interactionStartTime,
            }
        end
    end

    local spellcasting = Client.Spellcasting or nil
    if spellcasting and type(spellcasting.ShowLocalResourceDeltaCombatText) == "function" then
        local combatTextStartTime = timingEnabled and getNowMilliseconds() or nil
        spellcasting.ShowLocalResourceDeltaCombatText(
            Client,
            entry.eventState,
            entry.attackerUnit,
            entry.defenderUnit,
            resourceDeltas,
            damageResult.hitType,
            damageResult
        )
        if timingEnabled then
            timingParts[#timingParts + 1] = {
                label = "combat-text",
                elapsed = getNowMilliseconds() - combatTextStartTime,
            }
        end
    end

    local sessionState = entry.sessionState or (Client.GetState and Client:GetState() or nil)
    if type(Client.QueueClientResourceDeltas) ~= "function"
        or type(sessionState) ~= "table"
        or sessionState.active ~= true
    then
        if timingEnabled then
            logDamageFinalizeTimingLine(
                ("%s/%s"):format(tostring(entry.spellRef or "spell"), tostring(entry.componentKey or "component")),
                timingParts,
                getNowMilliseconds() - totalStartTime,
                SPELLCAST_SLOW_TOTAL_MS
            )
        end
        return true
    end

    local immediate = type(entry.context) == "table" and entry.context.immediate == true
    local threatUpdate = nil
    if damageResult.threatCommitted == true
        and damageResult.threatApplied == true
        and damageResult.threatUpdateQueued ~= true
        and type(damageResult.threatUpdate) == "table"
    then
        threatUpdate = damageResult.threatUpdate
    end
    local queueStartTime = timingEnabled and getNowMilliseconds() or nil
    local queued = Client:QueueClientResourceDeltas(
        sessionState,
        "combat-damage",
        resourceDeltas,
        entry.defenderEventId,
        {
            allowLocalEchoApply = true,
            immediate = immediate,
            scope = immediate and (entry.context.pendingScope or "reaction") or "turn",
            threatUpdates = threatUpdate and { threatUpdate } or nil,
        }
    )
    if queued and threatUpdate then
        damageResult.threatUpdateQueued = true
    end
    if timingEnabled then
        timingParts[#timingParts + 1] = {
            label = "resource-queue",
            elapsed = getNowMilliseconds() - queueStartTime,
        }
        logDamageFinalizeTimingLine(
            ("%s/%s"):format(tostring(entry.spellRef or "spell"), tostring(entry.componentKey or "component")),
            timingParts,
            getNowMilliseconds() - totalStartTime,
            SPELLCAST_SLOW_TOTAL_MS
        )
    end
    return queued
end

function Combat:BuildReactionActions(entry)
    if type(entry) ~= "table" then
        return {}
    end
    if type(entry.reactionActionsCache) == "table" then
        -- The turn ledger is a player-defender UI concern. NPC callers may
        -- reuse this action builder for automatic strength evaluation.
        if type(entry.defenderUnit) == "table" and entry.defenderUnit.isPlayer == true then
            return self:RefreshDefensiveReactionAvailability(entry, entry.reactionActionsCache)
        end
        return entry.reactionActionsCache
    end
    local actions = {}

    local function appendAction(action)
        if type(action) ~= "table" or type(action.id) ~= "string" or action.id == "" then
            return
        end

        actions[#actions + 1] = action
    end

    local blockChanceStatRef = normalizeToken(getCombatRuleValue("block_chance_stat", ""))
    local allowBlockWithoutShield = getCombatRuleValue("allow_block_without_shield", true) ~= false
    local defenderHasShield = unitHasShield(entry.defenderUnit)
    local blockActionLabel = blockChanceStatRef and self:ResolveDefenceTextForStat(blockChanceStatRef) or ""
    local normalizedBlockActionLabel = normalizeComparisonToken(blockActionLabel)

    local function applyShieldEligibility(action)
        if type(action) ~= "table" then
            return action
        end

        local matchesBlockStat = blockChanceStatRef ~= nil and action.statRef == blockChanceStatRef
        local normalizedActionLabel = normalizeComparisonToken(action.label)
        local matchesBlockLabel = normalizedBlockActionLabel ~= ""
            and normalizedActionLabel == normalizedBlockActionLabel
        if matchesBlockStat ~= true and matchesBlockLabel ~= true then
            return action
        end

        action.requiresShield = true
        if allowBlockWithoutShield ~= true and defenderHasShield ~= true then
            action.enabled = false
        end

        return action
    end

    local function hasPercentConfiguration(attackType)
        local attackStatRef = self:ResolveAttackStatRef("percent", attackType)
        local resistanceStats = self:ResolvePercentResistanceStatRefs(attackType)
        return attackStatRef ~= nil or #resistanceStats > 0
    end

    local function appendGroupedStatActions(resolutionSystem, statRefResolver)
        local actionsByStatRef = {}

        for attackTypeIndex = 1, #REACTION_ATTACK_TYPES do
            local attackType = REACTION_ATTACK_TYPES[attackTypeIndex]
            local statRefs = statRefResolver(attackType)
            for statIndex = 1, #statRefs do
                local statRef = normalizeToken(statRefs[statIndex])
                if statRef then
                    local display = self:ResolveDefenceActionDisplay(statRef)
                    local existing = actionsByStatRef[statRef]
                    if not existing then
                        existing = {
                            id = ("%s:%s"):format(resolutionSystem, statRef),
                            kind = resolutionSystem,
                            resolutionSystem = resolutionSystem,
                            label = display.label,
                            icon = display.icon,
                            statRef = statRef,
                            enabled = false,
                            allowedAttackTypes = {},
                        }
                        actionsByStatRef[statRef] = existing
                        appendAction(existing)
                    end

                    existing.allowedAttackTypes[attackType] = true
                    if attackType == tostring(entry.attackType or "spell") then
                        existing.enabled = true
                        existing.icon = display.icon or existing.icon
                    end
                    applyShieldEligibility(existing)
                end
            end
        end
    end

    local armorClassStat = self:ResolveDefenceStatRef("ac", entry.attackType)
    if armorClassStat then
        local armorDisplay = self:ResolveDefenceActionDisplay(armorClassStat)
        appendAction({
            id = "ac:resolve",
            kind = "resolve",
            resolutionSystem = "ac",
            label = armorDisplay.label,
            icon = armorDisplay.icon,
            enabled = true,
            statRef = armorClassStat,
        })
    end

    local simpleDefenceStat = self:ResolveDefenceStatRef("simple", entry.attackType)
    if simpleDefenceStat then
        local simpleDisplay = self:ResolveDefenceActionDisplay(simpleDefenceStat)
        appendAction({
            id = "simple:resolve",
            kind = "resolve",
            resolutionSystem = "simple",
            label = simpleDisplay.label ~= "" and simpleDisplay.label or "Defend",
            icon = simpleDisplay.icon,
            enabled = true,
            statRef = simpleDefenceStat,
        })
    end

    for index = 1, #actions do
        applyShieldEligibility(actions[index])
    end

    appendGroupedStatActions("complex", function(attackType)
        return self:ResolveComplexDefenceStats(attackType)
    end)

    local percentConfigured = false
    for attackTypeIndex = 1, #REACTION_ATTACK_TYPES do
        if hasPercentConfiguration(REACTION_ATTACK_TYPES[attackTypeIndex]) then
            percentConfigured = true
            break
        end
    end
    if percentConfigured then
        appendGroupedStatActions("percent", function(attackType)
            return self:ResolvePercentResistanceStatRefs(attackType)
        end)

        local hasExplicitPercentAction = false
        for index = 1, #actions do
            local action = actions[index]
            if action and action.resolutionSystem == "percent" then
                hasExplicitPercentAction = true
                break
            end
        end

        if not hasExplicitPercentAction then
            appendAction({
                id = "percent:resolve",
                kind = "resolve",
                resolutionSystem = "percent",
                label = "Resist",
                icon = ACTION_ICONS.spell,
                enabled = hasPercentConfiguration(tostring(entry.attackType or "spell")),
            })
        end
    end

    actions[#actions + 1] = {
        id = RESULT_PASS,
        kind = RESULT_PASS,
        label = "Pass",
        icon = ACTION_ICONS.pass,
        resolutionSystem = RESULT_PASS,
        enabled = true,
    }

    if type(entry.defenderUnit) == "table" and entry.defenderUnit.isPlayer == true then
        self:RefreshDefensiveReactionAvailability(entry, actions)
    end
    entry.reactionActionsCache = actions
    return actions
end

function Combat:FindReactionAction(entry, actionId)
    local normalizedId = tostring(actionId or "")
    if normalizedId == "" then
        return nil
    end

    local actions = self:BuildReactionActions(entry)
    for index = 1, #actions do
        local action = actions[index]
        if action and action.id == normalizedId then
            return action
        end
    end

    return nil
end

function Combat:ChooseAutomaticReactionAction(entry)
    if type(entry) ~= "table" then
        return RESULT_PASS
    end

    -- Automatic NPC reactions are intentionally outside the player-only
    -- per-turn ledger. Selection is based only on current action eligibility
    -- and the defender's resolved values.
    local defenceSystem = tostring(entry.defenceSystem or "")
    if defenceSystem ~= "ac" and defenceSystem ~= "simple"
        and defenceSystem ~= "complex" and defenceSystem ~= "percent"
    then
        return RESULT_PASS
    end

    local actions = type(entry.sharedHitPreview) == "table"
        and type(entry.sharedHitPreview.reactionActions) == "table"
        and entry.sharedHitPreview.reactionActions
        or self:BuildReactionActions(entry)
    local strongestAction = nil
    local strongestValue = nil

    for index = 1, #actions do
        local action = actions[index]
        if action
            and action.id
            and action.id ~= RESULT_PASS
            and action.enabled ~= false
            and tostring(action.resolutionSystem or "") == defenceSystem
        then
            local value = 0
            local statRef = normalizeToken(action.statRef)
            if statRef and type(self.GetCachedCombatStatValue) == "function" then
                value = tonumber(self:GetCachedCombatStatValue(
                    entry.context,
                    entry.defenderUnit,
                    statRef,
                    0
                )) or 0
            elseif defenceSystem == "percent" then
                value = tonumber(self:SumStatValues(
                    entry.defenderUnit,
                    self:ResolvePercentResistanceStatRefs(entry.attackType),
                    entry.context
                )) or 0
            end

            if strongestAction == nil or value > strongestValue then
                strongestAction = action
                strongestValue = value
            end
        end
    end

    if strongestAction then
        return strongestAction
    end

    -- No valid configured reaction remains for this system/attack type.
    -- Passing is the existing automatic-resolution fallback.
    return RESULT_PASS
end

function Combat:PrintHitCheckResult(resultToken)
    return true
end

function Combat:LogAttackAttempt(entry, resultToken, resolution)
    return true
end

function Combat:LogDefenceAttempt(entry, resultToken, resolution)
    return true
end

function Client:SetPendingCombatHitCheck(entry)
    local checkId = entry and entry.checkId or nil
    if not checkId then
        return nil
    end

    self.PendingCombatHitChecksByCheckId = self.PendingCombatHitChecksByCheckId or {}
    self.PendingCombatHitChecksByCheckId[checkId] = entry
    return entry
end

function Client:GetPendingCombatHitCheck(checkId)
    return self.PendingCombatHitChecksByCheckId and self.PendingCombatHitChecksByCheckId[checkId] or nil
end

function Client:ClearPendingCombatHitCheck(checkId)
    if type(self.PendingCombatHitChecksByCheckId) ~= "table" then
        return nil
    end

    local previous = self.PendingCombatHitChecksByCheckId[checkId]
    self.PendingCombatHitChecksByCheckId[checkId] = nil
    return previous
end

local function ensureCombatReactionQueue(client)
    client.CombatReactionQueue = client.CombatReactionQueue or {}
    return client.CombatReactionQueue
end

local function hasQueuedCombatReaction(client, checkId)
    local normalizedCheckId = tostring(checkId or "")
    if normalizedCheckId == "" then
        return false
    end

    local activeEntry = client.ActiveCombatReactionEntry
    if type(activeEntry) == "table" and tostring(activeEntry.checkId or "") == normalizedCheckId then
        return true
    end

    local queue = ensureCombatReactionQueue(client)
    for index = 1, #queue do
        local entry = queue[index]
        if type(entry) == "table" and tostring(entry.checkId or "") == normalizedCheckId then
            return true
        end
    end

    return false
end

function Client:EnqueueCombatReaction(entry)
    if type(entry) ~= "table" or tostring(entry.checkId or "") == "" then
        return false
    end
    if hasQueuedCombatReaction(self, entry.checkId) then
        return false
    end

    local queue = ensureCombatReactionQueue(self)
    queue[#queue + 1] = entry
    return true
end

function Client:DequeueCombatReaction()
    local queue = ensureCombatReactionQueue(self)
    if #queue == 0 then
        return nil
    end

    local nextEntry = queue[1]
    table.remove(queue, 1)
    return nextEntry
end

function Client:SetActiveCombatReaction(entry)
    self.ActiveCombatReactionEntry = entry
    return entry
end

function Client:ClearActiveCombatReaction()
    local previous = self.ActiveCombatReactionEntry
    self.ActiveCombatReactionEntry = nil
    return previous
end

function Client:ShowNextQueuedCombatReaction()
    local nextEntry = self:DequeueCombatReaction()
    if type(nextEntry) ~= "table" then
        return false
    end

    self:SetActiveCombatReaction(nextEntry)
    enqueueReactionPresentationWork(refreshReactionWidgetDeferred, self, "combat-hit-check-queue")
    return true
end

function Client:GetReactionDisplayState()
    local entry = self.ActiveCombatReactionEntry
    if type(entry) ~= "table" then
        return nil
    end

    local failurePreviewText = ""
    local failurePreviewIcon = nil
    if type(Combat.BuildDamagePreview) == "function" then
        local preview = Combat:BuildDamagePreview(entry)
        if type(preview) == "table" then
            local schoolName = tostring(preview.damageSchoolName or "")
            local amount = tonumber(preview.amount)
            local mitigationPercent = tonumber(preview.mitigationPercent) or 0
            local labelPrefix = ""
            if tostring(preview.resultType or "") == "crushing" then
                labelPrefix = "Crushing "
            elseif tostring(preview.resultType or "") == "critical" then
                labelPrefix = "Critical "
            end
            if amount ~= nil then
                amount = math.max(0, amount)
            end
            local mitigationSuffix = (" (-%.2f%%)"):format(math.max(0, mitigationPercent))
            if schoolName ~= "" and amount ~= nil then
                failurePreviewText = ("On fail: %s%d %s damage%s"):format(labelPrefix, amount, schoolName, mitigationSuffix)
            elseif amount ~= nil then
                failurePreviewText = ("On fail: %s%d damage%s"):format(labelPrefix, amount, mitigationSuffix)
            end
            failurePreviewIcon = tostring(preview.damageSchoolIcon or "") ~= "" and tostring(preview.damageSchoolIcon) or nil
        end
    end

    return {
        checkId = entry.checkId,
        attackerUnit = entry.attackerUnit,
        attackerName = tostring(entry.attackerUnit and entry.attackerUnit.name or "Unknown Attacker"),
        actions = Combat:BuildReactionActions(entry),
        failurePreviewText = failurePreviewText,
        failurePreviewIcon = failurePreviewIcon,
    }
end

function Client:ShowCombatReaction(entry)
    if type(entry) ~= "table" then
        return false
    end

    if type(self.ActiveCombatReactionEntry) == "table" then
        return self:EnqueueCombatReaction(entry)
    end

    self:SetActiveCombatReaction(entry)
    enqueueReactionPresentationWork(refreshReactionWidgetDeferred, self, "combat-hit-check")
    return true
end

function Client:HideCombatReaction()
    self:ClearActiveCombatReaction()
    if type(self.HideReactionWidget) == "function" then
        self:HideReactionWidget()
    end
    return true
end

function Combat:CompleteHitCheck(entry, resultToken, reason)
    local normalizedResult = normalizeResultToken(resultToken)
    if not entry or not normalizedResult then
        return false, buildCombatResult(entry, nil, "invalid")
    end

    Client:ClearPendingCombatHitCheck(entry.checkId)
    self:LogAttackAttempt(entry, normalizedResult, entry.lastResolution)
    self:PrintHitCheckResult(normalizedResult)
    if normalizedResult == RESULT_PASS
        and type(Client.SkillProgression) == "table"
        and type(Client.SkillProgression.TryGainWeaponSkillsForHit) == "function"
    then
        Client.SkillProgression:TryGainWeaponSkillsForHit(entry)
    end
    return true, buildCombatResult(entry, normalizedResult, reason or normalizedResult)
end

local function isSuccessfulDefensiveResolution(entry, action, resultToken, resolution)
    if normalizeResultToken(resultToken) ~= RESULT_FAIL or type(action) ~= "table" or action.enabled == false then
        return false
    end

    if normalizeResultToken(action.id) == RESULT_PASS or type(resolution) ~= "table" then
        return false
    end

    local defenceSystem = tostring(resolution.defenceSystem or entry and entry.defenceSystem or "")
    return defenceSystem == "ac"
        or defenceSystem == "simple"
        or defenceSystem == "complex"
        or defenceSystem == "percent"
end

local function normalizeDefenceStatRef(value)
    local reference = normalizeToken(value)
    return reference and reference ~= "" and reference or nil
end

function Combat:EmitSuccessfulDefenceEvent(client, entry, action, resultToken, resolution)
    if type(client) ~= "table"
        or type(entry) ~= "table"
        or not isSuccessfulDefensiveResolution(entry, action, resultToken, resolution)
        or entry.defenceEventEmitted == true
    then
        return false
    end

    local attackerEventId = math.floor(tonumber(entry.attackerEventId or entry.attackerUnit and entry.attackerUnit.eventID) or 0)
    local defenderEventId = math.floor(tonumber(entry.defenderEventId or entry.defenderUnit and entry.defenderUnit.eventID) or 0)
    local events = self.Events
    if attackerEventId <= 0 or defenderEventId <= 0 or type(events) ~= "table" or type(events.Run) ~= "function" then
        return false
    end

    entry.defenceEventEmitted = true
    return events:Run(client, {
        eventState = entry.eventState,
        sessionState = entry.sessionState or (client.GetState and client:GetState() or nil),
        combatEventId = "on_defence",
        sourceEventId = attackerEventId,
        targetEventIds = { defenderEventId },
        eventSourceUnit = entry.attackerUnit,
        eventOtherUnit = entry.defenderUnit,
        sourceUnit = entry.attackerUnit,
        targetUnit = entry.defenderUnit,
        defenceStatRef = normalizeDefenceStatRef(resolution and resolution.defenceStatRef),
        actionContext = entry.context,
    })
end

function Combat:EmitDamageTypeEvent(client, entry, damageResult)
    if type(client) ~= "table"
        or type(entry) ~= "table"
        or type(damageResult) ~= "table"
        or entry.damageTypeEventEmitted == true
        or damageResult.applied ~= true
        or (tonumber(damageResult.appliedDelta) or 0) >= 0
        or type(entry.attackerUnit) ~= "table"
        or type(entry.defenderUnit) ~= "table"
        or not isLocalAuthorityForUnit(entry.eventState, entry.attackerUnit)
    then
        return false
    end

    local damageSchoolRef = normalizeToken(damageResult.damageSchoolRef)
    local attackerEventId = math.floor(tonumber(entry.attackerEventId or entry.attackerUnit.eventID) or 0)
    local defenderEventId = math.floor(tonumber(entry.defenderEventId or entry.defenderUnit.eventID) or 0)
    local events = self.Events
    if not damageSchoolRef
        or attackerEventId <= 0
        or defenderEventId <= 0
        or type(events) ~= "table"
        or type(events.Run) ~= "function"
    then
        return false
    end

    entry.damageTypeEventEmitted = true
    return events:Run(client, {
        eventState = entry.eventState,
        sessionState = entry.sessionState or (client.GetState and client:GetState() or nil),
        combatEventId = "on_damage_type",
        sourceEventId = attackerEventId,
        targetEventIds = { defenderEventId },
        eventSourceUnit = entry.attackerUnit,
        eventOtherUnit = entry.defenderUnit,
        sourceUnit = entry.attackerUnit,
        targetUnit = entry.defenderUnit,
        damageSchoolRef = damageSchoolRef,
        actionContext = entry.context,
    })
end

function Combat:RecordResolvedCombatAttackHistory(client, entry, resultToken, action, resolution, defendedOverride)
    if type(client) ~= "table" or type(client.RecordCombatAttack) ~= "function" or type(entry) ~= "table" then
        return false
    end

    local normalizedResult = normalizeResultToken(resultToken)
    if not normalizedResult then
        return false
    end

    local landed = normalizedResult == RESULT_PASS
    local successfullyDefended = defendedOverride == true
        or isSuccessfulDefensiveResolution(entry, action, normalizedResult, resolution)
    return client:RecordCombatAttack(
        entry.eventState,
        entry.attackerUnit,
        entry.defenderUnit,
        entry.attackType,
        landed,
        successfullyDefended,
        entry.checkId
    )
end

function Combat:ResolveDefenceCombatText(entry, resolution)
    if type(entry) ~= "table" then
        return nil
    end

    local defenceStatRef = type(resolution) == "table" and resolution.defenceStatRef or nil
    if defenceStatRef then
        local label = self:ResolveDefenceTextForStat(defenceStatRef)
        if label ~= "" then
            return label
        end
    end

    local defenceSystem = tostring(type(resolution) == "table" and resolution.defenceSystem or entry.defenceSystem or "")
    if defenceSystem == "percent" then
        return "Resist"
    end

    return "Defend"
end

function Combat:ShowMissCombatText(entry)
    if type(entry) ~= "table" then
        return false
    end

    return emitReactionCombatLog(entry, "Miss", UI.ResolveColor(nil, "warning"), "attacker")
end

function Combat:ShowDefenceCombatText(entry, resolution)
    if type(entry) ~= "table" then
        return false
    end

    local text = self:ResolveDefenceCombatText(entry, resolution)
    if not text or text == "" then
        return false
    end

    return emitReactionCombatLog(entry, text, UI.ResolveColor(nil, "success"), "defender")
end

function Client:ResolveCombatReactionAction(actionId)
    local entry = self.ActiveCombatReactionEntry
    if type(entry) ~= "table" then
        return false
    end
    if type(self.CanPerformEventAction) == "function"
        and self:CanPerformEventAction(entry.eventState, "combat-reaction") ~= true
    then
        return false
    end

    local action = Combat:FindReactionAction(entry, actionId)
    if type(action) ~= "table" or action.enabled == false then
        return false
    end
    if type(Combat.CanUseDefensiveReaction) == "function"
        and Combat:CanUseDefensiveReaction(entry, action) ~= true
    then
        return false
    end

    local resultToken, resolution = Combat:ResolveHitCheckOutcome(entry, action)
    if not resultToken then
        return false
    end
    if type(Combat.ConsumeDefensiveReactionUse) == "function"
        and Combat:ConsumeDefensiveReactionUse(entry, action) ~= true
    then
        return false
    end

    entry.lastResolution = resolution
    Combat:LogDefenceAttempt(entry, resultToken, resolution)
    entry.context = entry.context or {}
    entry.context.immediate = true
    entry.context.pendingScope = "reaction"

    if entry.localOnly == true then
        self:HideCombatReaction()
        local completed, result = Combat:CompleteHitCheck(entry, resultToken, "player-local")
        if completed then
            Combat:RecordResolvedCombatAttackHistory(self, entry, resultToken, action, resolution)
            if resultToken == RESULT_FAIL then
                Combat:EmitSuccessfulDefenceEvent(self, entry, action, resultToken, resolution)
            end
        end
        if completed and resultToken == RESULT_PASS and type(Combat.ApplyResolvedDamage) == "function" then
            local _, damageResult = Combat:ApplyResolvedDamage(entry)
            entry.lastDamageResult = damageResult
            Combat:FinalizeLocalDamageResult(entry, damageResult)
        elseif completed and resultToken == RESULT_FAIL then
            Combat:ShowDefenceCombatText(entry, resolution)
        end
        self:ShowNextQueuedCombatReaction()
        return completed, result
    end

    local attackerName = resolveSenderForUnit(entry.eventState, entry.attackerUnit)
    local successfullyDefended = isSuccessfulDefensiveResolution(entry, action, resultToken, resolution)
    local defenceStatRef = successfullyDefended and normalizeDefenceStatRef(resolution and resolution.defenceStatRef) or nil
    local responseArguments = {
        entry.checkId,
        entry.eventId,
        resultToken,
        successfullyDefended and "defended" or "",
        defenceStatRef or "",
    }
    if attackerName == "" or not sendCombatWhisper(attackerName, HIT_CHECK_RESPONSE_OPCODE, responseArguments) then
        return false
    end

    Combat:EmitSuccessfulDefenceEvent(self, entry, action, resultToken, resolution)
    self:HideCombatReaction()
    Combat:RecordResolvedCombatAttackHistory(self, entry, resultToken, action, resolution)
    if resultToken == RESULT_PASS and type(Combat.ApplyResolvedDamage) == "function" then
        local _, damageResult = Combat:ApplyResolvedDamage(entry)
        entry.lastDamageResult = damageResult
        Combat:FinalizeLocalDamageResult(entry, damageResult)

        local damageOutcome = {
            checkId = normalizeToken(entry.checkId),
            eventId = entry.eventId,
            targetName = attackerName,
            retryCount = 0,
            sendAttempts = 0,
            arguments = {
                entry.checkId,
                entry.eventId,
                type(damageResult) == "table" and normalizeToken(damageResult.damageSchoolRef) or "",
                type(damageResult) == "table" and tostring(tonumber(damageResult.appliedDelta) or 0) or "0",
                type(damageResult) == "table" and (damageResult.applied == true and "1" or "0") or "0",
            },
        }
        local outcomes = getPendingDamageOutcomes(self, true)
        outcomes[damageOutcome.checkId] = damageOutcome
        local damageOutcomeSent = sendPendingDamageOutcome(self, damageOutcome)
        if not damageOutcomeSent and type(Debug) == "table" and type(Debug.Internal) == "function" then
            Debug.Internal("Authoritative combat damage hand-off queued for retry: checkId=%s.", tostring(entry.checkId or ""))
        end
    elseif resultToken == RESULT_FAIL then
        finalizeDamageCombatEvents(Client, entry, false)
        Combat:ShowDefenceCombatText(entry, resolution)
    end
    self:ShowNextQueuedCombatReaction()
    return true
end

function Combat:HandleDamageHitCheckRequest(client, arguments, sender)
    local checkId = normalizeToken(arguments and arguments[1])
    local eventId = normalizeToken(arguments and arguments[2])
    local attackerEventId = tonumber(arguments and arguments[3]) or 0
    local defenderEventId = tonumber(arguments and arguments[4]) or 0
    local spellRef = normalizeToken(arguments and arguments[5])
    local componentKey = normalizeToken(arguments and arguments[6])
    local attackerTotal = tonumber(arguments and arguments[7]) or nil
    local rawDamage = tonumber(arguments and arguments[8]) or 0
    local resultType = normalizeToken(arguments and arguments[9]) or "hit"

    local sessionState = client.GetState and client:GetState() or nil
    local eventState = client.GetEventState and client:GetEventState() or nil
    if not checkId or not eventId or attackerEventId <= 0 or defenderEventId <= 0 or not spellRef or not componentKey or attackerTotal == nil then
        return false
    end
    if type(sessionState) ~= "table" or sessionState.active ~= true or type(eventState) ~= "table" or eventState.active ~= true or eventState.id ~= eventId then
        return false
    end

    local attackerUnit = findEventUnitById(eventState.units, attackerEventId)
    local defenderUnit = findEventUnitById(eventState.units, defenderEventId)
    if not attackerUnit or not defenderUnit then
        return false
    end

    local expectedSender = resolveSenderForUnit(eventState, attackerUnit)
    if expectedSender == "" or expectedSender ~= getResolvedName(sender) then
        return false
    end

    local localEventUnit = client.ResolveLocalEventUnit and client:ResolveLocalEventUnit(eventState) or nil
    if tonumber(localEventUnit and localEventUnit.eventID) ~= defenderEventId then
        return false
    end

    local _, spell, component = Combat:ResolveSpellComponent(spellRef, componentKey)
    if not spell or not component or Normalization.NormalizeEffectType(component.effect and component.effect.type) ~= "damage" then
        return false
    end

    local entry = {
        checkId = checkId,
        eventId = eventId,
        spellRef = spellRef,
        componentKey = componentKey,
        attackType = Combat:ResolveHitCheckAttackType(component.effect, component),
        defenceSystem = Combat:ResolveDefenceSystem(),
        attackerUnit = attackerUnit,
        defenderUnit = defenderUnit,
        attackerEventId = attackerEventId,
        defenderEventId = defenderEventId,
        turnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1)),
        attackerTotal = attackerTotal,
        rawDamage = rawDamage,
        resultType = resultType,
        effect = component.effect,
        component = component,
        targetEvents = Combat:CloneValue(component.effect and component.effect.targetEvents or {}),
        context = {
            spellRef = spellRef,
            eventState = eventState,
            sessionState = sessionState,
            healthResourceRef = eventState and eventState.healthResourceRef or nil,
            immediate = true,
            pendingScope = "reaction",
        },
        sessionState = sessionState,
        eventState = eventState,
    }
    if not entry.defenceSystem then
        return false
    end

    client:ShowCombatReaction(entry)
    return true
end

function Combat:HandleDamageHitCheckResponse(client, arguments, sender)
    local checkId = normalizeToken(arguments and arguments[1])
    local eventId = normalizeToken(arguments and arguments[2])
    local resultToken = normalizeResultToken(arguments and arguments[3])
    local successfullyDefended = resultToken == RESULT_FAIL
        and tostring(arguments and arguments[4] or "") == "defended"
    local defenceStatRef = successfullyDefended and normalizeDefenceStatRef(arguments and arguments[5]) or nil
    local authoritativeDamageSchoolRef = normalizeToken(arguments and arguments[6])
    local authoritativeAppliedDelta = tonumber(arguments and arguments[7])
    local authoritativeDamageOutcomeToken = tostring(arguments and arguments[8] or "")
    local hasAuthoritativeDamageOutcome = authoritativeDamageOutcomeToken == "0"
        or authoritativeDamageOutcomeToken == "1"
    local authoritativeDamageApplied = tostring(arguments and arguments[8] or "") == "1"
    local entry = checkId and client:GetPendingCombatHitCheck(checkId) or nil
    if not entry or not eventId or eventId ~= entry.eventId or not resultToken then
        return false
    end

    local expectedSender = resolveSenderForUnit(entry.eventState, entry.defenderUnit)
    if expectedSender ~= "" and expectedSender ~= getResolvedName(sender) then
        return false
    end

    if successfullyDefended then
        entry.lastResolution = {
            defenceSystem = entry.defenceSystem,
            defenceStatRef = defenceStatRef,
        }
    end

    if resultToken == RESULT_PASS and not hasAuthoritativeDamageOutcome then
        entry.damageResolutionPending = true
        entry.pendingDamageResultToken = RESULT_PASS
        return true, buildCombatResult(entry, nil, "damage_pending")
    end

    local completed, result = Combat:CompleteHitCheck(entry, resultToken, "player-response")
    if completed then
        Combat:RecordResolvedCombatAttackHistory(client, entry, resultToken, nil, nil, successfullyDefended)
    end
    if completed and resultToken == RESULT_PASS and type(Combat.ApplyResolvedDamage) == "function" then
        local _, damageResult = Combat:ApplyResolvedDamage(entry, true)
        entry.lastDamageResult = damageResult
        if hasAuthoritativeDamageOutcome and type(damageResult) == "table" then
            damageResult.applied = authoritativeDamageApplied
            damageResult.appliedDelta = authoritativeAppliedDelta or 0
            damageResult.damageSchoolRef = authoritativeDamageSchoolRef
        end
        local context = type(entry) == "table" and entry.context or nil
        local castEntry = type(context) == "table" and context.castEntry or nil
        local spell = type(context) == "table" and context.spell or nil
        local state = Combat.GetOrCreateActionCombatEventState and Combat:GetOrCreateActionCombatEventState(castEntry, spell) or nil
        if type(state) == "table" and type(Combat.RegisterActionCasterEventOutcome) == "function" then
            Combat:RegisterActionCasterEventOutcome(state, { entry.defenderEventId }, {
                effectType = "damage",
                attackType = entry.attackType,
                hitType = type(damageResult) == "table" and damageResult.hitType or nil,
                wasCritical = type(damageResult) == "table" and damageResult.wasCritical == true,
            })
        end
        local defenderIsLocalAuthority = isLocalAuthorityForUnit(entry.eventState, entry.defenderUnit)
        -- The defender owns the final post-absorb result for remote hits.
        -- The attacker still completes action bookkeeping, but must not emit a preview log.
        if defenderIsLocalAuthority and type(Combat.RegisterActionDamageCombatLog) == "function" then
            Combat:RegisterActionDamageCombatLog(entry, damageResult)
        end
        finalizeDamageCombatEvents(client, entry, true)
        if hasAuthoritativeDamageOutcome then
            Combat:EmitDamageTypeEvent(client, entry, {
                applied = authoritativeDamageApplied,
                appliedDelta = authoritativeAppliedDelta or 0,
                damageSchoolRef = authoritativeDamageSchoolRef,
            })
        end

        if type(client.MarkEventUnitInteraction) == "function" then
            client:MarkEventUnitInteraction(entry.eventState, entry.attackerUnit, entry.defenderUnit, damageResult, entry.spellRef)
        end

        local spellcasting = Client.Spellcasting or nil
        if spellcasting and type(spellcasting.ShowLocalResourceDeltaCombatText) == "function" then
            spellcasting.ShowLocalResourceDeltaCombatText(
                client,
                entry.eventState,
                entry.attackerUnit,
                entry.defenderUnit,
                damageResult and damageResult.resourceDeltas or nil,
                damageResult and damageResult.hitType or nil,
                damageResult
            )
        end

        local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
        -- The player-response path uses the same post-absorb health contract.
        if auraManager
            and type(auraManager.HandleDamageTaken) == "function"
            and (tonumber(damageResult and damageResult.appliedDelta) or 0) < 0
        then
            auraManager:HandleDamageTaken(client, entry.eventState, entry.defenderEventId, entry.context)
        end
    elseif completed and resultToken == RESULT_FAIL then
        finalizeDamageCombatEvents(client, entry, false)
        Combat:ShowMissCombatText(entry)
    end

    return completed, result
end

function Combat:HandleCombatDamageResolved(client, arguments, sender)
    local checkId = normalizeToken(arguments and arguments[1])
    local eventId = normalizeToken(arguments and arguments[2])
    local damageSchoolRef = normalizeToken(arguments and arguments[3])
    local appliedDelta = tonumber(arguments and arguments[4])
    local appliedToken = tostring(arguments and arguments[5] or "")
    local entry = checkId and client:GetPendingCombatHitCheck(checkId) or nil
    if not checkId
        or not eventId
        or appliedDelta == nil
        or (appliedToken ~= "0" and appliedToken ~= "1")
    then
        return false
    end

    if not entry then
        local eventState = client.GetEventState and client:GetEventState() or nil
        if type(eventState) == "table" and eventState.active == true and tostring(eventState.id or "") == eventId then
            return sendDamageOutcomeAcknowledgement(sender, checkId, eventId)
        end
        return false
    end

    if eventId ~= entry.eventId then
        return false
    end

    local expectedSender = resolveSenderForUnit(entry.eventState, entry.defenderUnit)
    if expectedSender ~= "" and expectedSender ~= getResolvedName(sender) then
        return false
    end

    if entry.damageResolutionPending ~= true then
        return sendDamageOutcomeAcknowledgement(sender, checkId, eventId)
    end

    local completed, result = self:HandleDamageHitCheckResponse(client, {
        checkId,
        eventId,
        RESULT_PASS,
        "",
        "",
        damageSchoolRef or "",
        tostring(appliedDelta),
        appliedToken,
    }, sender)
    if not completed then
        entry.damageResolutionPending = true
        entry.pendingDamageResultToken = RESULT_PASS
    else
        entry.damageResolutionPending = nil
        entry.pendingDamageResultToken = nil
    end
    if completed then
        sendDamageOutcomeAcknowledgement(sender, checkId, eventId)
    end
    return completed, result
end

function Combat:HandleCombatDamageResolvedAck(client, arguments, sender)
    local checkId = normalizeToken(arguments and arguments[1])
    local eventId = normalizeToken(arguments and arguments[2])
    local outcomes = getPendingDamageOutcomes(client, false)
    local outcome = outcomes and checkId and outcomes[checkId] or nil
    if type(outcome) ~= "table"
        or not eventId
        or tostring(outcome.eventId or "") ~= eventId
        or tostring(outcome.targetName or "") ~= getResolvedName(sender)
    then
        return false
    end

    outcomes[checkId] = nil
    return true
end

return true
