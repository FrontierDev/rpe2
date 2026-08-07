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
local Dependencies = Database.Dependecies or {}
local REACTION_ATTACK_TYPES = { "melee", "ranged", "spell" }
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

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

    if type(Registry.ResolveStatReference) == "function" then
        local _, stat = Registry:ResolveStatReference(normalizedRef)
        local defenceLabel = tostring(stat and stat.defenceLabel or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if defenceLabel ~= "" then
            return defenceLabel
        end
    end

    return self:ResolveStatReferenceLabel(normalizedRef)
end

function Combat:ResolveStatDefinition(statRef)
    local normalizedRef = normalizeToken(statRef)
    if not normalizedRef or type(Registry.ResolveStatReference) ~= "function" then
        return nil, nil
    end

    return Registry:ResolveStatReference(normalizedRef)
end

function Combat:ResolveDefenceActionDisplay(statRef)
    local _, stat = self:ResolveStatDefinition(statRef)
    return {
        label = self:ResolveDefenceTextForStat(statRef),
        icon = tostring(stat and stat.icon or "") ~= "" and tostring(stat.icon) or DEFAULT_ICON,
    }
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

local function sendCombatWhisper(targetName, opcode, arguments)
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

    return Comms:SendMessage("WHISPER", opcode, arguments, normalizedTarget, metadata) and true or false
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

    local context = type(entry) == "table" and entry.context or nil
    local castEntry = type(context) == "table" and context.castEntry or nil
    local spell = type(context) == "table" and context.spell or nil
    local state = self.GetOrCreateActionCombatEventState and self:GetOrCreateActionCombatEventState(castEntry, spell) or nil
    if type(state) == "table" and type(self.RegisterActionCasterEventOutcome) == "function" then
        self:RegisterActionCasterEventOutcome(state, { entry.defenderEventId }, {
            effectType = "damage",
            attackType = entry.attackType,
            hitType = damageResult.hitType,
            wasCritical = damageResult.wasCritical == true,
        })
    end

    local resourceDeltas = damageResult.resourceDeltas
    if type(Combat.RegisterActionDamageCombatLog) == "function" then
        Combat:RegisterActionDamageCombatLog(entry, damageResult)
    end
    local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    if type(entry.effect) == "table"
        and entry.effect.applyAura == true
        and type(entry.effect.auraRef) == "string"
        and entry.effect.auraRef ~= ""
        and auraManager
        and type(auraManager.ApplyAuraFromContext) == "function"
    then
        auraManager:ApplyAuraFromContext(Client, entry.context, entry.effect.auraRef, entry.effect.auraStacks or 1, nil, 0)
    end

    finalizeDamageCombatEvents(Client, entry, true)
    tryResolveMountedDismount(entry, damageResult)

    local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    if auraManager
        and type(auraManager.HandleDamageTaken) == "function"
        and (tonumber(damageResult.appliedDelta) or 0) < 0
    then
        auraManager:HandleDamageTaken(Client, entry.eventState, entry.defenderEventId, entry.context)
    end

    if type(resourceDeltas) ~= "table" or #resourceDeltas == 0 then
        return true
    end

    if type(Client.MarkEventUnitInteraction) == "function" then
        Client:MarkEventUnitInteraction(entry.eventState, entry.attackerUnit, entry.defenderUnit, damageResult, entry.spellRef)
    end

    local spellcasting = Client.Spellcasting or nil
    if spellcasting and type(spellcasting.ShowLocalResourceDeltaCombatText) == "function" then
        spellcasting.ShowLocalResourceDeltaCombatText(
            Client,
            entry.eventState,
            entry.attackerUnit,
            entry.defenderUnit,
            resourceDeltas,
            damageResult.hitType,
            damageResult
        )
    end

    local sessionState = entry.sessionState or (Client.GetState and Client:GetState() or nil)
    if type(Client.QueueClientResourceDeltas) ~= "function"
        or type(sessionState) ~= "table"
        or sessionState.active ~= true
    then
        return true
    end

    local immediate = type(entry.context) == "table" and entry.context.immediate == true
        return Client:QueueClientResourceDeltas(
        sessionState,
        "combat-damage",
        resourceDeltas,
        entry.defenderEventId,
        {
            allowLocalEchoApply = true,
            immediate = immediate,
            scope = immediate and (entry.context.pendingScope or "reaction") or "turn",
            threatUpdates = damageResult and damageResult.threatUpdate and { damageResult.threatUpdate } or nil,
        }
    )
end

function Combat:BuildReactionActions(entry)
    local actions = {}
    if type(entry) ~= "table" then
        return actions
    end

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
                        applyShieldEligibility(existing)
                        appendAction(existing)
                    end

                    existing.allowedAttackTypes[attackType] = true
                    if attackType == tostring(entry.attackType or "spell") then
                        existing.enabled = true
                        existing.icon = display.icon or existing.icon
                    end
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
    local actions = self:BuildReactionActions(entry)
    for index = 1, #actions do
        local action = actions[index]
        if action
            and action.id
            and action.id ~= RESULT_PASS
            and action.enabled ~= false
            and tostring(action.resolutionSystem or "") == tostring(entry and entry.defenceSystem or "")
        then
            return action.id
        end
    end

    for index = 1, #actions do
        local action = actions[index]
        if action and action.id and action.id ~= RESULT_PASS and action.enabled ~= false then
            return action.id
        end
    end

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
    if type(self.RefreshReactionWidget) == "function" then
        self:RefreshReactionWidget("combat-hit-check-queue")
    end
    if type(self.ShowReactionWidget) == "function" then
        self:ShowReactionWidget()
    end
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
    if type(self.RefreshReactionWidget) == "function" then
        self:RefreshReactionWidget("combat-hit-check")
    end
    if type(self.ShowReactionWidget) == "function" then
        self:ShowReactionWidget()
    end
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
    return true, buildCombatResult(entry, normalizedResult, reason or normalizedResult)
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

    local action = Combat:FindReactionAction(entry, actionId)
    if type(action) ~= "table" or action.enabled == false then
        return false
    end

    local resultToken, resolution = Combat:ResolveHitCheckOutcome(entry, action)
    if not resultToken then
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
    if attackerName == "" or not sendCombatWhisper(attackerName, HIT_CHECK_RESPONSE_OPCODE, {
        entry.checkId,
        entry.eventId,
        resultToken,
    }) then
        return false
    end

    self:HideCombatReaction()
    if resultToken == RESULT_PASS and type(Combat.ApplyResolvedDamage) == "function" then
        local _, damageResult = Combat:ApplyResolvedDamage(entry)
        entry.lastDamageResult = damageResult
        Combat:FinalizeLocalDamageResult(entry, damageResult)
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
    local entry = checkId and client:GetPendingCombatHitCheck(checkId) or nil
    if not entry or not eventId or eventId ~= entry.eventId or not resultToken then
        return false
    end

    local expectedSender = resolveSenderForUnit(entry.eventState, entry.defenderUnit)
    if expectedSender ~= "" and expectedSender ~= getResolvedName(sender) then
        return false
    end

    local completed, result = Combat:CompleteHitCheck(entry, resultToken, "player-response")
    if completed and resultToken == RESULT_PASS and type(Combat.ApplyResolvedDamage) == "function" then
        local _, damageResult = Combat:ApplyResolvedDamage(entry, true)
        entry.lastDamageResult = damageResult
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
        if type(Combat.RegisterActionDamageCombatLog) == "function" then
            Combat:RegisterActionDamageCombatLog(entry, damageResult)
        end
        finalizeDamageCombatEvents(client, entry, true)

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

return true
