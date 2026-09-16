local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Debug = Addon.Debug or {}
local Common = Addon.Utils.Common or {}
local Lookup = Addon.Utils.Lookup or {}
local Registry = Addon.Internal.Registry or {}
local Ruleset = Addon.Internal.Ruleset or {}
local Spellcasting = Client.Spellcasting or {}
Client.PendingSpellTargetingRevision = Client.PendingSpellTargetingRevision or 0
Client.PendingSpellTargetingDisplayStateCache = Client.PendingSpellTargetingDisplayStateCache or nil
Client.PendingSpellTargetingMetricsCache = Client.PendingSpellTargetingMetricsCache or nil
Client.PendingSpellTargetingMetricsRequest = Client.PendingSpellTargetingMetricsRequest or nil
Client.TargetingWidgetRefreshQueued = Client.TargetingWidgetRefreshQueued or false

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function enqueueTargetingWork(fn, ...)
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        tasks:Enqueue(fn, ...)
        return true
    end

    return false
end

local function getCombatTargetingRevisionToken(pending, selectedEventId)
    local Combat = Client.Combat or nil
    local eventId = tostring(pending and pending.eventId or "")
    local combatRevision = 0
    if type(Combat) == "table" and type(Combat.CombatRuntimeRevisionsByEventId) == "table" then
        combatRevision = math.max(0, math.floor(tonumber(Combat.CombatRuntimeRevisionsByEventId[eventId]) or 0))
    end

    local auraRevision = 0
    local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.GetEventAuraRevision) == "function" then
        auraRevision = math.max(0, math.floor(tonumber(auraManager:GetEventAuraRevision(Client, eventId)) or 0))
    end

    local descriptionBuilder = Client.Spellcasting and Client.Spellcasting.DescriptionBuilder or nil
    return table.concat({
        tostring(combatRevision),
        tostring(auraRevision),
        tostring(math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))),
        tostring(math.max(1, math.floor(tonumber(descriptionBuilder and descriptionBuilder.ProfileTooltipContextRevision) or 1))),
        tostring(tonumber(selectedEventId) or 0),
    }, ":")
end

local function buildPendingSpellTargetingMetricsKey(pending, revision, selectedEventId)
    return table.concat({
        tostring(pending and pending.spellRef or ""),
        tostring(pending and pending.eventId or ""),
        tostring(tonumber(pending and pending.casterEventId) or 0),
        tostring(math.max(0, math.floor(tonumber(revision) or 0))),
        tostring(tonumber(selectedEventId) or 0),
        getCombatTargetingRevisionToken(pending, selectedEventId),
    }, "\31")
end
local function getEventClass()
    return Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.Event
        or nil
end

Client.PendingSpellTargeting = Client.PendingSpellTargeting or nil
Client.TargetHistoryEventIds = Client.TargetHistoryEventIds or {}

local function normalizeName(name)
    if Common.NormalizeName then
        return Common.NormalizeName(name)
    end

    return type(name) == "string" and name or ""
end

local function getLocalPlayerName()
    return normalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil)
end

local function resolveSpellName(spellRef)
    if Registry.ResolveSpellName then
        return Registry:ResolveSpellName(spellRef)
    end

    return type(spellRef) == "string" and spellRef or "unknown-spell"
end

local function emitTargetingInfo(message, ...)
    if Debug and Debug.Info then
        return Debug.Info(message, ...)
    end

    return false
end

local function getDefaultTargetPolicy()
    return {
        type = "single",
        requiresTarget = true,
        targetDisposition = "enemy",
        minTargets = 1,
        maxTargets = 1,
        allowDeadTargets = false,
        allowHiddenTargets = false,
        disableSelfCast = false,
    }
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

local function findPlayerEventUnit(units, playerName)
    local normalizedPlayerName = normalizeName(playerName)
    if normalizedPlayerName == "" then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if unit and unit.isPlayer == true then
            local candidateName = normalizeName(unit.ownerID or unit.controllerID or unit.name)
            if candidateName == normalizedPlayerName then
                return unit, index
            end
        end
    end

    return nil
end

local function getActiveHealthResourceRef()
    local ruleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("resources", "health_stat") or nil
    local value = Ruleset.GetRulesetRuleValue and Ruleset.GetRulesetRuleValue(ruleset, "resources", ruleDefinition) or nil
    if type(value) ~= "string" or value == "" then
        return nil
    end

    return value
end

local function isUnitAlive(eventUnit)
    local healthResourceRef = getActiveHealthResourceRef()
    if not healthResourceRef then
        return true
    end

    for index = 1, #(eventUnit and eventUnit.resources or {}) do
        local entry = eventUnit.resources[index]
        if entry and entry.resourceRef == healthResourceRef then
            return (tonumber(entry.currentValue) or tonumber(entry.maxValue) or 0) > 0
        end
    end

    return true
end

local function buildUnitHealthText(eventUnit)
    local healthResourceRef = getActiveHealthResourceRef()
    local fallbackEntry = nil

    for index = 1, #(eventUnit and eventUnit.resources or {}) do
        local entry = eventUnit.resources[index]
        if entry and entry.resourceRef == healthResourceRef then
            local currentValue = tonumber(entry.currentValue)
            local maxValue = tonumber(entry.maxValue)
            if currentValue == nil and maxValue ~= nil then
                currentValue = maxValue
            end
            if maxValue == nil and currentValue ~= nil then
                maxValue = currentValue
            end
            if currentValue ~= nil and maxValue ~= nil then
                return ("HP: %d / %d"):format(currentValue, maxValue)
            end
        end

        if fallbackEntry == nil and entry and (entry.currentValue ~= nil or entry.maxValue ~= nil) then
            fallbackEntry = entry
        end
    end

    if fallbackEntry then
        local currentValue = tonumber(fallbackEntry.currentValue) or tonumber(fallbackEntry.maxValue)
        local maxValue = tonumber(fallbackEntry.maxValue) or tonumber(fallbackEntry.currentValue)
        if currentValue ~= nil and maxValue ~= nil then
            return ("%d / %d"):format(currentValue, maxValue)
        end
    end

    return "HP: -"
end

local function formatSignedValue(value)
    local numericValue = Common.Round(tonumber(value) or 0)
    if numericValue > 0 then
        return ("+%d"):format(numericValue)
    end

    return tostring(numericValue)
end

local function formatSignedPercentValue(value)
    local numericValue = tonumber(value) or 0
    local roundedValue = math.floor((numericValue * 10) + (numericValue >= 0 and 0.5 or -0.5)) / 10
    if math.abs(roundedValue - math.floor(roundedValue)) < 0.001 then
        if roundedValue > 0 then
            return ("+%d"):format(math.floor(roundedValue + 0.5))
        end
        return tostring(math.floor(roundedValue + (roundedValue >= 0 and 0.5 or -0.5)))
    end

    if roundedValue > 0 then
        return ("+%.1f"):format(roundedValue)
    end
    return ("%.1f"):format(roundedValue)
end

local function resolveStatLabel(combatModule, statRef)
    if type(combatModule) == "table" and type(combatModule.ResolveStatReferenceLabel) == "function" then
        local label = tostring(combatModule:ResolveStatReferenceLabel(statRef) or "")
        if label ~= "" then
            return label
        end
    end

    if type(Registry.ResolveStatName) == "function" then
        local label = tostring(Registry:ResolveStatName(statRef) or "")
        if label ~= "" then
            return label
        end
    end

    return tostring(statRef or "")
end

local function titleCaseWords(value)
    local text = tostring(value or ""):gsub("_", " "):gsub("%-", " ")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        return ""
    end

    return (text:gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end))
end

local function resolveTeamColor(eventState, eventUnit)
    local eventClass = getEventClass()
    local color = eventClass
        and eventClass.GetTeamColor
        and eventClass.GetTeamColor(eventState, tonumber(eventUnit and eventUnit.team) or 0)
        or nil
    if type(color) ~= "table" then
        return nil
    end

    return {
        r = tonumber(color.r) or 1,
        g = tonumber(color.g) or 1,
        b = tonumber(color.b) or 1,
        a = tonumber(color.a) or 1,
    }
end

local function resolveTeamName(eventUnit)
    local eventClass = getEventClass()
    local eventState = Client.GetEventState and Client:GetEventState() or nil
    local teamName = type(eventUnit) == "table" and tostring(eventUnit.teamName or "") or ""
    if teamName ~= "" then
        return teamName
    end

    local teamId = tonumber(eventUnit and eventUnit.team) or 0
    if teamId > 0 then
        return eventClass and eventClass.GetTeamName and eventClass.GetTeamName(eventState, teamId) or ("Team %d"):format(teamId)
    end

    return "Unassigned Team"
end

local function resolveSelectedUnitDefinition(eventUnit)
    if type(eventUnit) == "table" and type(eventUnit.GetResolvedUnit) == "function" then
        return eventUnit:GetResolvedUnit()
    end

    return nil
end

local function buildSelectedUnitTypeSizeText(eventUnit)
    local resolvedUnit = resolveSelectedUnitDefinition(eventUnit)
    local source = resolvedUnit or eventUnit
    local creatureType = titleCaseWords(type(source) == "table" and source.creatureType or "")
    local creatureSize = titleCaseWords(type(source) == "table" and source.creatureSize or "")
    if creatureSize ~= "" and creatureType ~= "" then
        return ("%s %s"):format(creatureSize, creatureType)
    end
    if creatureSize ~= "" then
        return creatureSize
    end
    if creatureType ~= "" then
        return creatureType
    end

    return ""
end

local function findFirstDamageSpellComponent(spell)
    for index = 1, #(spell and spell.components or {}) do
        local component = spell.components[index]
        local effect = type(component) == "table" and component.effect or nil
        if type(effect) == "table" and tostring(effect.type or "") == "damage" then
            return effect, component
        end
    end

    return nil, nil
end

local function findFirstCriticalSpellComponent(spell)
    for index = 1, #(spell and spell.components or {}) do
        local component = spell.components[index]
        local effect = type(component) == "table" and component.effect or nil
        local effectType = tostring(effect and effect.type or "")
        if effectType == "damage" or effectType == "heal" then
            return effect, component
        end
    end

    return nil, nil
end

local function buildPendingTargetPreviewContext(pending, eventState, casterUnit, targetUnit)
    local Combat = Client.Combat or nil
    if type(pending) ~= "table"
        or type(eventState) ~= "table"
        or type(casterUnit) ~= "table"
        or type(targetUnit) ~= "table"
        or type(Combat) ~= "table"
        or type(Combat.BuildHitPreviewEntry) ~= "function"
    then
        return nil
    end

    local previewContext = {
        damageEffect = nil,
        damageComponent = nil,
        damagePreviewEntry = nil,
        critEffect = nil,
        critComponent = nil,
        critPreviewEntry = nil,
    }

    local damageEffect, damageComponent = findFirstDamageSpellComponent(pending.spell)
    if damageEffect and damageComponent then
        previewContext.damageEffect = damageEffect
        previewContext.damageComponent = damageComponent
        previewContext.damagePreviewEntry = Combat:BuildHitPreviewEntry({
            attackerUnit = casterUnit,
            casterUnit = casterUnit,
            defenderUnit = targetUnit,
            targetUnit = targetUnit,
            eventState = eventState,
            spellRef = pending.spellRef,
            componentKey = damageComponent.key,
            spell = pending.spell,
        }, damageEffect, damageComponent)
    end

    local critEffect, critComponent = findFirstCriticalSpellComponent(pending.spell)
    if critEffect and critComponent then
        previewContext.critEffect = critEffect
        previewContext.critComponent = critComponent
        if damageComponent and critComponent.key == damageComponent.key then
            previewContext.critPreviewEntry = previewContext.damagePreviewEntry
        else
            previewContext.critPreviewEntry = Combat:BuildHitPreviewEntry({
                attackerUnit = casterUnit,
                casterUnit = casterUnit,
                defenderUnit = targetUnit,
                targetUnit = targetUnit,
                eventState = eventState,
                spellRef = pending.spellRef,
                componentKey = critComponent.key,
                spell = pending.spell,
            }, critEffect, critComponent)
        end
    end

    return previewContext
end

local function buildSelectedUnitHitInfo(pending, eventState, casterUnit, targetUnit, previewContext)
    local Combat = Client.Combat or nil
    if type(pending) ~= "table"
        or type(eventState) ~= "table"
        or type(casterUnit) ~= "table"
        or type(targetUnit) ~= "table"
        or type(Combat) ~= "table"
    then
        return nil, nil, nil
    end

    local resolvedPreviewContext = type(previewContext) == "table" and previewContext or buildPendingTargetPreviewContext(pending, eventState, casterUnit, targetUnit)
    local previewEntry = type(resolvedPreviewContext) == "table" and resolvedPreviewContext.damagePreviewEntry or nil
    if type(previewEntry) ~= "table" then
        return nil, nil, nil
    end

    local defenceSystem = type(previewEntry) == "table" and tostring(previewEntry.defenceSystem or "") or nil
    local modifierContext = type(previewEntry) == "table" and previewEntry.attackModifierContext or nil
    if not defenceSystem or type(modifierContext) ~= "table" then
        return nil, nil, nil
    end

    local statValue = tonumber(modifierContext.statValue) or 0
    local weaponSkillPenaltyValue = tonumber(modifierContext.weaponSkillPenaltyValue) or 0
    local totalModifierValue = tonumber(modifierContext.totalModifierValue) or 0
    local hasMeaningfulModifier = totalModifierValue ~= 0 or weaponSkillPenaltyValue ~= 0 or modifierContext.statRef ~= nil
    if hasMeaningfulModifier ~= true then
        return nil, nil, nil
    end

    local statLabel = resolveStatLabel(Combat, modifierContext.statRef)
    local statIcon = nil
    if type(Combat.ResolveStatDefinition) == "function" then
        local _, statDefinition = Combat:ResolveStatDefinition(modifierContext.statRef)
        statIcon = type(statDefinition) == "table" and tostring(statDefinition.icon or "") or nil
    end

    if defenceSystem == "percent" then
        local percentStatValue = statValue
        if modifierContext.statRef and type(Combat.GetCachedCombatStatValue) == "function" then
            percentStatValue = tonumber(Combat:GetCachedCombatStatValue(previewEntry.context, casterUnit, modifierContext.statRef, statValue)) or statValue
        end
        local weaponSkillPenaltyPercent = tonumber(modifierContext.weaponSkillPenaltyPercent) or weaponSkillPenaltyValue or 0
        local totalModifierPercent = percentStatValue - weaponSkillPenaltyPercent
        return statLabel, statIcon, {
            value = totalModifierPercent,
            text = ("Bonus Hit Chance: %s%%"):format(formatSignedPercentValue(totalModifierPercent)),
        }
    end

    return statLabel, statIcon, {
        value = totalModifierValue,
        text = ("Hit Modifier: %s"):format(formatSignedValue(totalModifierValue)),
    }
end

local function buildSelectedUnitCritInfo(pending, eventState, casterUnit, targetUnit, previewContext)
    local Combat = Client.Combat or nil
    if type(pending) ~= "table"
        or type(eventState) ~= "table"
        or type(casterUnit) ~= "table"
        or type(targetUnit) ~= "table"
        or type(Combat) ~= "table"
    then
        return nil
    end

    local resolvedPreviewContext = type(previewContext) == "table" and previewContext or buildPendingTargetPreviewContext(pending, eventState, casterUnit, targetUnit)
    local previewEntry = type(resolvedPreviewContext) == "table" and resolvedPreviewContext.critPreviewEntry or nil
    if type(previewEntry) ~= "table" then
        return nil
    end

    local defenceSystem = type(previewEntry) == "table" and tostring(previewEntry.defenceSystem or "") or nil
    local sharedHitPreview = type(previewEntry) == "table" and previewEntry.sharedHitPreview or nil
    if not defenceSystem or type(sharedHitPreview) ~= "table" then
        return nil
    end

    local critStatRef = sharedHitPreview.critStatRef
    local critRoll = type(sharedHitPreview.critRoll) == "table" and sharedHitPreview.critRoll or nil
    local critStatValue = critRoll and tonumber(critRoll.statValue) or nil
    if critStatValue == nil and critStatRef and type(Combat.GetCachedCombatStatValue) == "function" then
        critStatValue = Combat:GetCachedCombatStatValue(previewEntry.context, casterUnit, critStatRef, 0)
    end
    critStatValue = tonumber(critStatValue) or 0
    local baseCritChance = tonumber(sharedHitPreview.baseCritChance) or 0
    local weaponSkillContext = type(previewEntry) == "table" and previewEntry.weaponSkillContext or nil
    local weaponSkillCritBonusPercent = type(weaponSkillContext) == "table" and (tonumber(weaponSkillContext.critBonusPercent) or 0) or 0

    if defenceSystem == "percent" then
        local chancePercent = baseCritChance + critStatValue + weaponSkillCritBonusPercent
        if type(Common.Clamp) == "function" then
            chancePercent = Common.Clamp(chancePercent, 0, 100)
        else
            chancePercent = math.max(0, math.min(100, chancePercent))
        end
        chancePercent = Common.Round(chancePercent)
        return {
            value = chancePercent,
            text = ("Critical Strike Chance: %d%%"):format(chancePercent),
        }
    end

    if type(Combat.ResolveDiceExpressionMax) ~= "function" or type(Combat.GetCombatRule) ~= "function" then
        return nil
    end

    local rollExpression = Combat:GetCombatRule("critical_roll_dice", "1d20")
    local rollMax = tonumber(Combat:ResolveDiceExpressionMax(rollExpression, 1, 20)) or 20
    rollMax = math.max(1, Common.Round(rollMax))

    local baseWindow = math.floor(((baseCritChance * rollMax) / 100) + 0.5)
    local threshold = math.max(1, rollMax - baseWindow + 1)
    local convertedBonus = math.floor(((weaponSkillCritBonusPercent * rollMax) / 100) + 0.5)
    local totalModifier = Common.Round((tonumber(critStatValue) or 0) + convertedBonus)
    local successRolls = rollMax - (threshold - totalModifier) + 1
    if successRolls < 0 then
        successRolls = 0
    elseif successRolls > rollMax then
        successRolls = rollMax
    end

    local chancePercent = Common.Round((successRolls / rollMax) * 100)
    return {
        value = chancePercent,
        text = ("Critical Strike Chance: %d%%"):format(chancePercent),
    }
end

local function shouldIncludeCaster(policy)
    local targetType = tostring(policy and policy.type or "single")
    local targetDisposition = tostring(policy and policy.targetDisposition or "enemy")
    if targetType == "caster" then
        return true
    end

    if policy and policy.disableSelfCast == true then
        return false
    end

    return targetDisposition == "ally" or targetDisposition == "any"
end

local function isCandidateDispositionMatch(casterUnit, candidateUnit, policy)
    local targetDisposition = tostring(policy and policy.targetDisposition or "enemy")
    if targetDisposition == "any" then
        return true
    end

    local casterTeam = tonumber(casterUnit and casterUnit.team) or 0
    local candidateTeam = tonumber(candidateUnit and candidateUnit.team) or 0
    if targetDisposition == "ally" then
        return casterTeam == candidateTeam
    end

    return casterTeam ~= candidateTeam
end

local function compareCandidateUnits(left, right)
    local leftMarker = tonumber(left and left.raidMarker) or 0
    local rightMarker = tonumber(right and right.raidMarker) or 0
    if leftMarker <= 0 then
        leftMarker = 99
    end
    if rightMarker <= 0 then
        rightMarker = 99
    end

    if leftMarker ~= rightMarker then
        return leftMarker < rightMarker
    end

    local leftName = string.lower(tostring(left and left.name or ""))
    local rightName = string.lower(tostring(right and right.name or ""))
    if leftName ~= rightName then
        return leftName < rightName
    end

    return (tonumber(left and left.eventID) or 0) < (tonumber(right and right.eventID) or 0)
end

local function getUnitRaidMarker(unit)
    local marker = math.floor(tonumber(unit and unit.raidMarker) or 0)
    return marker >= 1 and marker <= 8 and marker or 0
end

local function buildCandidateMap(units, casterUnit, policy)
    local candidates = {}
    local byEventId = {}
    local includeCaster = shouldIncludeCaster(policy)
    local casterEventId = tonumber(casterUnit and casterUnit.eventID) or 0

    for index = 1, #(units or {}) do
        local eventUnit = units[index]
        local eventId = tonumber(eventUnit and eventUnit.eventID) or 0
        if eventId > 0
            and eventUnit
            and (function()
                local eventClass = getEventClass()
                return not eventClass or not eventClass.IsUnitActive or eventClass.IsUnitActive(eventUnit)
            end)()
            and (policy.allowDeadTargets == true or isUnitAlive(eventUnit))
            and (policy.allowHiddenTargets == true or eventUnit.hidden ~= true)
            and isCandidateDispositionMatch(casterUnit, eventUnit, policy)
            and (includeCaster or eventId ~= casterEventId)
        then
            candidates[#candidates + 1] = eventUnit
            byEventId[eventId] = eventUnit
        end
    end

    table.sort(candidates, compareCandidateUnits)

    return candidates, byEventId
end

local function resolveSpellTargetPolicy(spell)
    local component = spell and spell.components and spell.components[1] or nil
    local target = component and component.target or nil
    if type(target) ~= "table" then
        local defaultPolicy = getDefaultTargetPolicy()
        defaultPolicy.allowDeadTargets = spell and spell.allowDeadTargets == true or false
        defaultPolicy.allowHiddenTargets = spell and spell.canTargetHiddenUnits == true or false
        return defaultPolicy
    end

    return {
        type = tostring(target.type or "single"),
        requiresTarget = target.requiresTarget == true,
        targetDisposition = tostring(target.targetDisposition or "enemy"),
        minTargets = math.max(0, tonumber(target.minTargets) or 0),
        maxTargets = math.max(0, tonumber(target.maxTargets) or 0),
        allowDeadTargets = spell and spell.allowDeadTargets == true or target.allowDeadTargets == true,
        allowHiddenTargets = spell and spell.canTargetHiddenUnits == true or target.allowHiddenTargets == true,
        disableSelfCast = target.disableSelfCast == true,
    }
end

local function resolveSpellTargetGroups(spell)
    if Spellcasting.BuildSpellTargetGroups then
        return Spellcasting.BuildSpellTargetGroups(spell)
    end

    return {}, nil
end

local function findTargetGroup(groups, groupKey)
    local normalizedGroupKey = Spellcasting.NormalizeCastingGroup and Spellcasting.NormalizeCastingGroup(groupKey) or tostring(groupKey or "default")
    for index = 1, #(groups or {}) do
        local group = groups[index]
        if group and group.key == normalizedGroupKey then
            return group, index
        end
    end

    return nil
end

local function findRecentCandidateUnit(client, candidates)
    for historyIndex = 1, #(client and client.TargetHistoryEventIds or {}) do
        local recentEventId = tonumber(client.TargetHistoryEventIds[historyIndex]) or 0
        if recentEventId > 0 then
            for candidateIndex = 1, #(candidates or {}) do
                local candidate = candidates[candidateIndex]
                if tonumber(candidate and candidate.eventID) == recentEventId then
                    return candidate
                end
            end
        end
    end

    return candidates and candidates[1] or nil
end

local function resolvePendingTargetUnit(client, activation, targetGroup)
    if type(client) ~= "table" or type(activation) ~= "table" then
        return nil
    end

    local pending = client.PendingSpellTargeting
    if type(pending) ~= "table"
        or tostring(pending.spellRef or "") ~= tostring(activation.spellRef or "")
        or tostring(pending.eventId or "") ~= tostring(activation.eventState and activation.eventState.id or "")
        or tonumber(pending.casterEventId) ~= tonumber(activation.casterUnit and activation.casterUnit.eventID)
    then
        return nil
    end

    local displayState = type(client.GetPendingSpellTargetingDisplayState) == "function" and client:GetPendingSpellTargetingDisplayState() or nil
    if type(displayState) ~= "table" then
        return nil
    end

    local desiredGroupKey = type(targetGroup) == "table" and targetGroup.key or tostring(targetGroup or "")
    if desiredGroupKey ~= "" then
        for index = 1, #(displayState.groups or {}) do
            local groupState = displayState.groups[index]
            if tostring(groupState and groupState.key or "") == desiredGroupKey then
                return groupState and groupState.selectedUnit or nil
            end
        end
    end

    return displayState.selectedUnit or nil
end

local function countSelectedTargets(selectedTargetEventIds)
    local selectedCount = 0
    for _ in pairs(type(selectedTargetEventIds) == "table" and selectedTargetEventIds or {}) do
        selectedCount = selectedCount + 1
    end
    return selectedCount
end

local function normalizeSelectedTargets(selectedTargetEventIds, byEventId)
    local selectedByEventId = {}
    local selectedCount = 0
    for eventId in pairs(type(selectedTargetEventIds) == "table" and selectedTargetEventIds or {}) do
        local numericEventId = tonumber(eventId) or 0
        if numericEventId > 0 and byEventId[numericEventId] then
            selectedByEventId[numericEventId] = true
            selectedCount = selectedCount + 1
        end
    end

    return selectedByEventId, selectedCount
end

local function buildOrderedTargetEventIds(candidates, selectedTargetEventIds, focusedTargetEventId)
    local orderedTargetEventIds = {}
    local numericFocusedTargetEventId = tonumber(focusedTargetEventId) or 0
    if numericFocusedTargetEventId > 0 and selectedTargetEventIds and selectedTargetEventIds[numericFocusedTargetEventId] then
        orderedTargetEventIds[#orderedTargetEventIds + 1] = numericFocusedTargetEventId
    end

    for index = 1, #(candidates or {}) do
        local candidateEventId = tonumber(candidates[index] and candidates[index].eventID) or 0
        if candidateEventId > 0
            and candidateEventId ~= numericFocusedTargetEventId
            and selectedTargetEventIds
            and selectedTargetEventIds[candidateEventId]
        then
            orderedTargetEventIds[#orderedTargetEventIds + 1] = candidateEventId
        end
    end

    return orderedTargetEventIds
end

local function getPendingTargetGroup(pending, groupKey)
    if type(pending) ~= "table" then
        return nil
    end

    local normalizedGroupKey = Spellcasting.NormalizeCastingGroup and Spellcasting.NormalizeCastingGroup(groupKey) or tostring(groupKey or "default")
    for index = 1, #(pending.groups or {}) do
        local group = pending.groups[index]
        if group and group.key == normalizedGroupKey then
            return group, index
        end
    end

    return nil
end

local function getActivePendingTargetGroup(pending)
    if type(pending) ~= "table" then
        return nil
    end

    local activeGroup = getPendingTargetGroup(pending, pending.activeGroupKey)
    if activeGroup then
        return activeGroup
    end

    return pending.groups and pending.groups[1] or nil
end

function Client:GetPendingSpellTargeting()
    return self.PendingSpellTargeting
end

function Client:InvalidatePendingSpellTargetingDisplayState()
    self.PendingSpellTargetingRevision = math.max(0, math.floor(tonumber(self.PendingSpellTargetingRevision) or 0) + 1)
    self.PendingSpellTargetingDisplayStateCache = nil
    self.PendingSpellTargetingMetricsCache = nil
    self.PendingSpellTargetingMetricsRequest = nil
    return self.PendingSpellTargetingRevision
end

function Client:GetPendingSpellTargetingMetrics(metricsKey)
    local cached = self.PendingSpellTargetingMetricsCache
    if type(cached) ~= "table" then
        return nil
    end

    if tostring(cached.key or "") ~= tostring(metricsKey or "") then
        return nil
    end

    return cached
end

function Client:QueuePendingSpellTargetingMetricsRefresh(pending, revision, eventState, casterUnit, selectedUnit)
    if type(pending) ~= "table"
        or type(eventState) ~= "table"
        or type(casterUnit) ~= "table"
        or type(selectedUnit) ~= "table"
    then
        self.PendingSpellTargetingMetricsRequest = nil
        return false
    end

    local selectedEventId = tonumber(selectedUnit.eventID) or 0
    if selectedEventId <= 0 then
        self.PendingSpellTargetingMetricsRequest = nil
        return false
    end

    local metricsKey = buildPendingSpellTargetingMetricsKey(pending, revision, selectedEventId)
    if self:GetPendingSpellTargetingMetrics(metricsKey) then
        self.PendingSpellTargetingMetricsRequest = nil
        return true
    end
    if tostring(self.PendingSpellTargetingMetricsRequest or "") == metricsKey then
        return true
    end

    self.PendingSpellTargetingMetricsRequest = metricsKey
    local enqueued = enqueueTargetingWork(function(targetClient, requestKey, requestPending, requestRevision, requestEventId, requestCasterEventId, requestSelectedEventId)
        if type(targetClient) ~= "table" then
            return
        end

        if tostring(targetClient.PendingSpellTargetingMetricsRequest or "") ~= tostring(requestKey or "") then
            return
        end

        local currentPending = targetClient.PendingSpellTargeting
        if currentPending ~= requestPending then
            targetClient.PendingSpellTargetingMetricsRequest = nil
            return
        end

        local currentRevision = math.max(0, math.floor(tonumber(targetClient.PendingSpellTargetingRevision) or 0))
        if currentRevision ~= math.max(0, math.floor(tonumber(requestRevision) or 0)) then
            targetClient.PendingSpellTargetingMetricsRequest = nil
            return
        end

        local currentEventState = targetClient.GetEventState and targetClient:GetEventState() or nil
        if type(currentEventState) ~= "table"
            or currentEventState ~= eventState
            or tostring(currentEventState.id or "") ~= tostring(requestEventId or "")
        then
            targetClient.PendingSpellTargetingMetricsRequest = nil
            return
        end

        local currentCasterUnit = findEventUnitById(currentEventState.units, requestCasterEventId)
        local currentSelectedUnit = findEventUnitById(currentEventState.units, requestSelectedEventId)
        if type(currentCasterUnit) ~= "table" or type(currentSelectedUnit) ~= "table" then
            targetClient.PendingSpellTargetingMetricsRequest = nil
            return
        end

        local previewContext = buildPendingTargetPreviewContext(requestPending, currentEventState, currentCasterUnit, currentSelectedUnit)

        local selectedUnitHitStatName = nil
        local selectedUnitHitStatIcon = nil
        local selectedUnitHitText = nil
        local selectedUnitHitValue = nil
        local selectedUnitCritText = nil
        local selectedUnitCritValue = nil

        local hitDisplay = nil
        selectedUnitHitStatName, selectedUnitHitStatIcon, hitDisplay = buildSelectedUnitHitInfo(
            requestPending,
            currentEventState,
            currentCasterUnit,
            currentSelectedUnit,
            previewContext
        )
        if type(hitDisplay) == "table" then
            selectedUnitHitText = hitDisplay.text
            selectedUnitHitValue = tonumber(hitDisplay.value) or 0
        end

        local critDisplay = buildSelectedUnitCritInfo(
            requestPending,
            currentEventState,
            currentCasterUnit,
            currentSelectedUnit,
            previewContext
        )
        if type(critDisplay) == "table" then
            selectedUnitCritText = critDisplay.text
            selectedUnitCritValue = tonumber(critDisplay.value) or 0
        end

        if tostring(targetClient.PendingSpellTargetingMetricsRequest or "") ~= tostring(requestKey or "") then
            return
        end

        targetClient.PendingSpellTargetingMetricsCache = {
            key = requestKey,
            selectedUnitHitStatName = selectedUnitHitStatName,
            selectedUnitHitStatIcon = selectedUnitHitStatIcon,
            selectedUnitHitText = selectedUnitHitText,
            selectedUnitHitValue = selectedUnitHitValue,
            selectedUnitCritText = selectedUnitCritText,
            selectedUnitCritValue = selectedUnitCritValue,
        }
        targetClient.PendingSpellTargetingDisplayStateCache = nil
        targetClient.PendingSpellTargetingMetricsRequest = nil
        if type(targetClient.QueueTargetingWidgetRefresh) == "function" then
            targetClient:QueueTargetingWidgetRefresh("target-metrics")
        end
    end, self, metricsKey, pending, revision, eventState.id, casterUnit.eventID, selectedEventId, eventState)
    if enqueued then
        return true
    end

    self.PendingSpellTargetingMetricsRequest = nil
    return false
end

function Client:PushRecentTargetEventId(eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return false
    end

    local history = self.TargetHistoryEventIds or {}
    local nextHistory = { numericEventId }
    for index = 1, #history do
        local existingEventId = tonumber(history[index]) or 0
        if existingEventId > 0 and existingEventId ~= numericEventId then
            nextHistory[#nextHistory + 1] = existingEventId
        end
        if #nextHistory >= 3 then
            break
        end
    end

    self.TargetHistoryEventIds = nextHistory
    return true
end

function Client:ResetPendingSpellTargeting()
    self.PendingSpellTargeting = nil
    self:InvalidatePendingSpellTargetingDisplayState()
    return true
end

function Client:CancelSpellTargeting(reason)
    self.PendingSpellTargeting = nil
    self:InvalidatePendingSpellTargetingDisplayState()
    if self.HideTargetingWidget then
        self:HideTargetingWidget()
    end

    if reason and reason ~= "" then
        emitTargetingInfo("Targeting cancelled: %s.", tostring(reason))
    end
    return true
end

function Client:ResolveSpellActivation(spellRef)
    local sessionState = self.GetState and self:GetState() or nil
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return nil
    end

    local casterUnit = self.ResolveActiveSpellcasterUnit and self:ResolveActiveSpellcasterUnit(eventState) or nil
    if type(casterUnit) == "table" and type(self.ResolveLocalActiveSpellcasterResources) == "function" then
        local resolvedResources = self:ResolveLocalActiveSpellcasterResources(eventState, casterUnit, {
            applyFallbackToUnit = true,
        })
        if type(resolvedResources) == "table" and #resolvedResources > 0 then
            casterUnit.resources = resolvedResources
        end
    end
    local dataset, spell = nil, nil
    if Registry.ResolveSpellReference then
        dataset, spell = Registry:ResolveSpellReference(spellRef)
    end
    if not casterUnit or not dataset or not spell then
        return nil
    end

    local targetGroups, targetingError = resolveSpellTargetGroups(spell)
    local activation = {
        sessionState = sessionState,
        eventState = eventState,
        casterUnit = casterUnit,
        dataset = dataset,
        spell = spell,
        spellRef = spellRef,
        policy = resolveSpellTargetPolicy(spell),
        targetGroups = targetGroups or {},
        targetingError = targetingError,
    }
    activation.targetUnit = self.ResolveSpellActivationTargetUnit and self:ResolveSpellActivationTargetUnit(activation) or nil
    return activation
end

function Client:ResolveSpellActivationTargetUnit(activation, targetGroup)
    local resolvedActivation = type(activation) == "table" and activation or self:ResolveSpellActivation(activation)
    if type(resolvedActivation) ~= "table" then
        return nil
    end

    local pendingTargetUnit = resolvePendingTargetUnit(self, resolvedActivation, targetGroup)
    if type(pendingTargetUnit) == "table" then
        return pendingTargetUnit
    end

    local candidates = self:BuildSpellActivationTargetCandidates(resolvedActivation, targetGroup)
    return findRecentCandidateUnit(self, candidates)
end

function Client:BuildSpellActivationTargetCandidates(activation, targetGroup)
    local resolvedActivation = activation
    if type(resolvedActivation) ~= "table" then
        resolvedActivation = self:ResolveSpellActivation(activation)
    end
    if type(resolvedActivation) ~= "table" then
        return {}
    end

    local policy = nil
    if type(targetGroup) == "table" then
        policy = targetGroup.policy
    elseif type(targetGroup) == "string" then
        local group = findTargetGroup(resolvedActivation.targetGroups, targetGroup)
        policy = group and group.policy or nil
    end
    policy = policy or resolvedActivation.policy or getDefaultTargetPolicy()
    if policy.type == "pet" or policy.type == "last_melee_attacker" then
        local targets = Spellcasting.ResolveComponentTargets and Spellcasting.ResolveComponentTargets(
            resolvedActivation.eventState,
            resolvedActivation.casterUnit,
            {
                target = policy,
            },
            nil
        ) or {}
        return targets
    end
    if policy.type == "caster"
        or ((tonumber(policy.maxTargets) or 0) <= 0 and policy.type ~= "all_allies")
    then
        return {}
    end

    local candidates = buildCandidateMap(resolvedActivation.eventState.units, resolvedActivation.casterUnit, policy)
    return candidates or {}
end

function Client:GetPendingSpellTargetingDisplayState()
    local pending = self.PendingSpellTargeting
    if type(pending) ~= "table" then
        self.PendingSpellTargetingDisplayStateCache = nil
        return nil
    end

    local eventState = self.GetEventState and self:GetEventState() or nil
    if not eventState or eventState.active ~= true or eventState.id ~= pending.eventId then
        self.PendingSpellTargetingDisplayStateCache = nil
        return nil
    end

    local revision = math.max(0, math.floor(tonumber(self.PendingSpellTargetingRevision) or 0))
    local cached = self.PendingSpellTargetingDisplayStateCache
    if type(cached) == "table"
        and cached.pending == pending
        and cached.revision == revision
        and cached.eventId == eventState.id
        and type(cached.displayState) == "table"
    then
        return cached.displayState
    end

    local casterUnit = findEventUnitById(eventState.units, pending.casterEventId)
    if not casterUnit then
        self.PendingSpellTargetingDisplayStateCache = nil
        return nil
    end

    local groupStates = {}
    local activeGroup = getActivePendingTargetGroup(pending)
    if not activeGroup then
        return nil
    end

    local activeGroupState = nil
    for index = 1, #(pending.groups or {}) do
        local group = pending.groups[index]
        local candidates, byEventId = buildCandidateMap(eventState.units, casterUnit, group.policy)
        local selectedByEventId, selectedCount = normalizeSelectedTargets(group.selectedTargetEventIds, byEventId)

        local targetType = tostring(group.policy and group.policy.type or "single")
        local lockedRaidMarker = 0
        if targetType == "raid_marker" then
            local anchorEventId = tonumber(group.focusedTargetEventId) or 0
            local anchorUnit = byEventId[anchorEventId]
            lockedRaidMarker = getUnitRaidMarker(anchorUnit)
            selectedByEventId = {}
            selectedCount = 0
            if anchorUnit and lockedRaidMarker > 0 then
                selectedByEventId[anchorEventId] = true
                selectedCount = 1
                local maxTargets = math.max(1, tonumber(group.policy and group.policy.maxTargets) or 1)
                for candidateIndex = 1, #candidates do
                    local candidate = candidates[candidateIndex]
                    local candidateEventId = tonumber(candidate and candidate.eventID) or 0
                    if candidateEventId ~= anchorEventId
                        and getUnitRaidMarker(candidate) == lockedRaidMarker
                        and selectedCount < maxTargets
                    then
                        selectedByEventId[candidateEventId] = true
                        selectedCount = selectedCount + 1
                    end
                end
            else
                group.focusedTargetEventId = 0
            end
        end
        group.selectedTargetEventIds = selectedByEventId
        if selectedByEventId[tonumber(group.focusedTargetEventId) or 0] ~= true then
            group.focusedTargetEventId = 0
        end

        local rows = {}
        local firstSelectedUnit = nil
        for candidateIndex = 1, #candidates do
            local eventUnit = candidates[candidateIndex]
            local numericEventId = tonumber(eventUnit.eventID) or 0
            if not firstSelectedUnit and selectedByEventId[numericEventId] then
                firstSelectedUnit = eventUnit
            end
            rows[#rows + 1] = {
                eventID = numericEventId,
                unit = eventUnit,
                selected = selectedByEventId[numericEventId] == true,
                enabled = targetType ~= "all_allies"
                    and (targetType ~= "raid_marker"
                        or lockedRaidMarker == 0
                        or selectedByEventId[numericEventId] == true),
            }
        end

        local minTargets = math.max(0, tonumber(group.policy and group.policy.minTargets) or 0)
        local maxTargets = math.max(minTargets, tonumber(group.policy and group.policy.maxTargets) or 0)
        if targetType == "all_allies" then
            maxTargets = #candidates
        end
        local focusedTargetEventId = tonumber(group.focusedTargetEventId) or 0
        local selectedUnit = nil
        if focusedTargetEventId > 0 and selectedByEventId[focusedTargetEventId] then
            selectedUnit = byEventId[focusedTargetEventId]
        end
        if not selectedUnit then
            selectedUnit = firstSelectedUnit
        end

        local state = {
            key = group.key,
            label = group.label,
            policy = group.policy,
            selectedCount = selectedCount,
            minTargets = minTargets,
            maxTargets = maxTargets,
            selectedTargetEventIds = selectedByEventId,
            focusedTargetEventId = focusedTargetEventId,
            candidates = rows,
            byEventId = byEventId,
            selectedUnit = selectedUnit,
            canConfirm = selectedCount >= minTargets and selectedCount <= maxTargets,
        }
        groupStates[#groupStates + 1] = state
        if group.key == activeGroup.key then
            activeGroupState = state
        end
    end

    if not activeGroupState then
        activeGroupState = groupStates[1]
        pending.activeGroupKey = activeGroupState and activeGroupState.key or nil
    end

    local canConfirm = self:CanConfirmPendingSpellTargeting({
        groups = groupStates,
    })
    local activeTargetType = tostring(activeGroupState.policy and activeGroupState.policy.type or "single")
    local recentTargetsEnabled = activeTargetType ~= "all_allies"
        and not (activeTargetType == "raid_marker" and activeGroupState.selectedCount > 0)
    local recentCandidates = {}
    for index = 1, #(self.TargetHistoryEventIds or {}) do
        local recentEventId = tonumber(self.TargetHistoryEventIds[index]) or 0
        local recentUnit = activeGroupState and activeGroupState.byEventId and activeGroupState.byEventId[recentEventId] or nil
        if recentUnit then
            recentCandidates[#recentCandidates + 1] = {
                eventID = recentEventId,
                unit = recentUnit,
                selected = activeGroupState.selectedTargetEventIds[recentEventId] == true,
                enabled = recentTargetsEnabled,
            }
        end
    end
    local helperText
    if #(activeGroupState.candidates or {}) == 0 then
        helperText = ("No valid %s targets."):format(string.lower(tostring(activeGroupState.label or "target")))
    elseif activeGroupState.selectedUnit then
        helperText = ("Selected: %s"):format(tostring(activeGroupState.selectedUnit.name or "Unit"))
    else
        helperText = ("Select %d to %d %s targets."):format(
            activeGroupState.minTargets,
            activeGroupState.maxTargets,
            string.lower(tostring(activeGroupState.label or "target"))
        )
    end

    local selectedEventId = tonumber(activeGroupState.selectedUnit and activeGroupState.selectedUnit.eventID) or 0
    local metricsKey = buildPendingSpellTargetingMetricsKey(pending, revision, selectedEventId)
    local metrics = selectedEventId > 0 and self:GetPendingSpellTargetingMetrics(metricsKey) or nil

    local selectedUnitRoleText = activeGroupState.selectedUnit and tostring(activeGroupState.label or "Selected Target") or ""
    local selectedUnitSummaryText = helperText
    local selectedUnitTeamText = activeGroupState.selectedUnit and resolveTeamName(activeGroupState.selectedUnit) or ""
    local selectedUnitTypeSizeText = activeGroupState.selectedUnit and buildSelectedUnitTypeSizeText(activeGroupState.selectedUnit) or ""
    local selectedUnitNameColor = activeGroupState.selectedUnit and resolveTeamColor(eventState, activeGroupState.selectedUnit) or nil
    if activeGroupState.selectedUnit then
        selectedUnitSummaryText = (type(activeGroupState.selectedUnit.description) == "string" and activeGroupState.selectedUnit.description ~= "")
            and activeGroupState.selectedUnit.description
            or ""
    end

    local displayState = {
        spellRef = pending.spellRef,
        spellName = resolveSpellName(pending.spellRef),
        spellIcon = pending.spell and tostring(pending.spell.icon or "") or "",
        casterEventId = pending.casterEventId,
        selectedCount = activeGroupState.selectedCount,
        minTargets = activeGroupState.minTargets,
        maxTargets = activeGroupState.maxTargets,
        canConfirm = canConfirm,
        groups = groupStates,
        activeGroupKey = activeGroupState.key,
        activeGroupLabel = activeGroupState.label,
        candidates = activeGroupState.candidates,
        recentCandidates = recentCandidates,
        helperText = helperText,
        selectionText = ("%s %d / %d"):format(tostring(activeGroupState.label or "Targets"), activeGroupState.selectedCount, activeGroupState.maxTargets),
        selectedUnit = activeGroupState.selectedUnit,
        selectedUnitRoleText = selectedUnitRoleText,
        selectedUnitName = activeGroupState.selectedUnit and tostring(activeGroupState.selectedUnit.name or "Unnamed Unit") or "No target selected",
        selectedUnitNameColor = selectedUnitNameColor,
        selectedUnitTeamText = selectedUnitTeamText,
        selectedUnitTypeSizeText = selectedUnitTypeSizeText,
        selectedUnitHealthText = activeGroupState.selectedUnit and buildUnitHealthText(activeGroupState.selectedUnit) or "HP: -",
        selectedUnitHitStatName = metrics and metrics.selectedUnitHitStatName or nil,
        selectedUnitHitStatIcon = metrics and metrics.selectedUnitHitStatIcon or nil,
        selectedUnitHitText = metrics and metrics.selectedUnitHitText or nil,
        selectedUnitHitValue = metrics and metrics.selectedUnitHitValue or nil,
        selectedUnitCritText = metrics and metrics.selectedUnitCritText or nil,
        selectedUnitCritValue = metrics and metrics.selectedUnitCritValue or nil,
        selectedUnitSummaryText = selectedUnitSummaryText,
    }
    self.PendingSpellTargetingDisplayStateCache = {
        pending = pending,
        revision = revision,
        eventId = eventState.id,
        displayState = displayState,
    }
    if not metrics and activeGroupState.selectedUnit then
        self:QueuePendingSpellTargetingMetricsRefresh(pending, revision, eventState, casterUnit, activeGroupState.selectedUnit)
    end
    return displayState
end

function Client:QueueTargetingWidgetRefresh(reason)
    if self.PendingSpellTargeting == nil then
        self.PendingTargetingWidgetRefreshReason = nil
        self.TargetingWidgetRefreshQueued = false
        return false
    end

    self.PendingTargetingWidgetRefreshReason = tostring(reason or self.PendingTargetingWidgetRefreshReason or "refresh")
    if self.TargetingWidgetRefreshQueued then
        return true
    end
    self.TargetingWidgetRefreshQueued = true
    if type(self.QueueVisualRefreshFlush) == "function" then
        return self:QueueVisualRefreshFlush()
    end

    local enqueued = enqueueTargetingWork(function(targetClient, refreshReason)
        if type(targetClient) ~= "table" then
            return
        end

        targetClient.TargetingWidgetRefreshQueued = false
        targetClient.PendingTargetingWidgetRefreshReason = nil
        if type(targetClient.RefreshTargetingWidget) == "function" then
            targetClient:RefreshTargetingWidget(refreshReason or "refresh")
        end
    end, self, self.PendingTargetingWidgetRefreshReason or "refresh")
    if enqueued then
        return true
    end

    self.TargetingWidgetRefreshQueued = false
    self.PendingTargetingWidgetRefreshReason = nil
    return self:RefreshTargetingWidget(reason or "refresh")
end

local function attemptSpellActivationCast(targetClient, spellRef, castTime, activationSnapshot, activationOptions)
    if type(targetClient) ~= "table" then
        return false, "cast-rejected"
    end

    local options = type(activationOptions) == "table" and activationOptions or nil
    if options and type(options.onBeforeCastAttempt) == "function" then
        local sourceValid, sourceReason = options.onBeforeCastAttempt(options.sourceContext, spellRef, activationSnapshot)
        if sourceValid ~= true then
            return false, sourceReason or "cast-rejected"
        end
    end

    local accepted = targetClient.OnSpellcastStart
        and targetClient:OnSpellcastStart(spellRef, castTime, activationSnapshot)
        or false
    if accepted ~= true then
        return false, "cast-rejected"
    end

    if options and type(options.onCastAccepted) == "function" then
        local committed, commitReason = options.onCastAccepted(options.sourceContext, spellRef, activationSnapshot)
        if committed == false then
            return false, commitReason or "cast-rejected"
        end
    end

    return true
end

local function executeConfirmedSpellTargeting(targetClient, spellRef, castTime, targetSelections, groupOrder, activationSnapshot, activationOptions)
    if type(targetClient) ~= "table" then
        return false
    end

    if Spellcasting.QueueLocalSpellTargetSelection then
        Spellcasting.QueueLocalSpellTargetSelection(targetClient, spellRef, targetSelections, groupOrder)
    end

    return attemptSpellActivationCast(targetClient, spellRef, castTime, activationSnapshot, activationOptions)
end

function Client:RefreshTargetingWidget(reason)
    local pending = self.PendingSpellTargeting
    if not pending then
        if self.HideTargetingWidget then
            self:HideTargetingWidget()
        end
        return false
    end

    local displayState = self:GetPendingSpellTargetingDisplayState()
    if not displayState then
        return self:CancelSpellTargeting(reason or "targets-invalid")
    end

    if self.BuildTargetingWidget then
        self:BuildTargetingWidget()
    end
    if self.ShowTargetingWidget then
        self:ShowTargetingWidget()
    end
    if self.RefreshTargetingWidgetFrame then
        self:RefreshTargetingWidgetFrame(reason or "refresh", displayState)
    end
    return true
end

function Client:ConfirmPendingSpellTargeting()
    local pending = self.PendingSpellTargeting
    if not pending then
        return false
    end
    if type(self.CanPerformEventAction) == "function"
        and not self:CanPerformEventAction(self:GetEventState(), "targeting-confirm")
    then
        return false
    end

    local displayState = self:GetPendingSpellTargetingDisplayState()
    if not displayState then
        return self:CancelSpellTargeting("targets-invalid")
    end

    if not self:CanConfirmPendingSpellTargeting(displayState) then
        return false
    end

    local spellRef = pending.spellRef
    local castTime = pending.spell and (tonumber(pending.spell.totalTicks) or tonumber(pending.spell.castTime)) or nil
    local activationSnapshot = pending.activationSnapshot
    local activationOptions = pending.activationOptions
    local targetSelections = {}
    local groupOrder = {}
    for index = 1, #(displayState.groups or {}) do
        local groupState = displayState.groups[index]
        local orderedTargetEventIds = buildOrderedTargetEventIds(
            groupState.candidates,
            groupState.selectedTargetEventIds,
            groupState.focusedTargetEventId
        )
        targetSelections[groupState.key] = {
            groupKey = groupState.key,
            targetEventIds = orderedTargetEventIds,
            focusedTargetEventId = groupState.focusedTargetEventId,
            policy = groupState.policy,
        }
        groupOrder[#groupOrder + 1] = groupState.key

        for targetIndex = 1, #orderedTargetEventIds do
            self:PushRecentTargetEventId(orderedTargetEventIds[targetIndex])
        end
    end
    self.PendingSpellTargeting = nil
    self:InvalidatePendingSpellTargetingDisplayState()
    if self.HideTargetingWidget then
        self:HideTargetingWidget()
    end
    local enqueued = enqueueTargetingWork(
        executeConfirmedSpellTargeting,
        self,
        spellRef,
        castTime,
        targetSelections,
        groupOrder,
        activationSnapshot,
        activationOptions
    )
    if enqueued then
        return true
    end

    return executeConfirmedSpellTargeting(
        self,
        spellRef,
        castTime,
        targetSelections,
        groupOrder,
        activationSnapshot,
        activationOptions
    )
end

function Client:CanConfirmPendingSpellTargeting(displayState)
    local state = displayState or self:GetPendingSpellTargetingDisplayState()
    if not state then
        return false
    end

    if #(state.groups or {}) > 0 then
        for index = 1, #state.groups do
            local group = state.groups[index]
            if group.selectedCount < group.minTargets or group.selectedCount > group.maxTargets then
                return false
            end
        end
        return true
    end

    return state.selectedCount >= state.minTargets and state.selectedCount <= state.maxTargets
end

function Client:SetPendingSpellTargetGroup(groupKey)
    local pending = self.PendingSpellTargeting
    if not pending then
        return false
    end
    if type(self.CanPerformEventAction) == "function"
        and not self:CanPerformEventAction(self:GetEventState(), "targeting-group")
    then
        return false
    end

    local group = getPendingTargetGroup(pending, groupKey)
    if not group then
        return false
    end

    pending.activeGroupKey = group.key
    self:InvalidatePendingSpellTargetingDisplayState()
    return self:QueueTargetingWidgetRefresh("target-group")
end

function Client:TogglePendingSpellTarget(eventId)
    local pending = self.PendingSpellTargeting
    if not pending then
        return false
    end
    if type(self.CanPerformEventAction) == "function"
        and not self:CanPerformEventAction(self:GetEventState(), "targeting-mutation")
    then
        return false
    end

    local displayState = self:GetPendingSpellTargetingDisplayState()
    if not displayState then
        return self:CancelSpellTargeting("targets-invalid")
    end

    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return false
    end

    local isCandidate = false
    for index = 1, #displayState.candidates do
        if tonumber(displayState.candidates[index].eventID) == numericEventId
            and displayState.candidates[index].enabled ~= false
        then
            isCandidate = true
            break
        end
    end
    if not isCandidate then
        return false
    end

    local activeGroup = getPendingTargetGroup(pending, displayState.activeGroupKey)
    if not activeGroup then
        return false
    end

    local targetType = tostring(activeGroup.policy and activeGroup.policy.type or "single")
    if targetType == "all_allies" then
        return false
    end

    if targetType == "raid_marker" then
        if countSelectedTargets(activeGroup.selectedTargetEventIds) > 0 then
            return false
        end

        local anchorUnit = nil
        for candidateIndex = 1, #(displayState.candidates or {}) do
            local candidate = displayState.candidates[candidateIndex]
            if tonumber(candidate and candidate.eventID) == numericEventId then
                anchorUnit = candidate.unit
                break
            end
        end
        if getUnitRaidMarker(anchorUnit) <= 0 then
            return false
        end

        activeGroup.selectedTargetEventIds = {
            [numericEventId] = true,
        }
        activeGroup.focusedTargetEventId = numericEventId
        self:InvalidatePendingSpellTargetingDisplayState()
        return self:QueueTargetingWidgetRefresh("raid-marker-target")
    end

    activeGroup.selectedTargetEventIds = activeGroup.selectedTargetEventIds or {}
    if activeGroup.selectedTargetEventIds[numericEventId] then
        activeGroup.selectedTargetEventIds[numericEventId] = nil
        activeGroup.focusedTargetEventId = 0
        self:InvalidatePendingSpellTargetingDisplayState()
        return self:QueueTargetingWidgetRefresh("target-toggle")
    end

    local selectedCount = countSelectedTargets(activeGroup.selectedTargetEventIds)

    local maxTargets = math.max(0, tonumber(activeGroup.policy and activeGroup.policy.maxTargets) or 0)
    if maxTargets > 0 and selectedCount >= maxTargets then
        return false
    end

    activeGroup.selectedTargetEventIds[numericEventId] = true
    activeGroup.focusedTargetEventId = numericEventId

    self:InvalidatePendingSpellTargetingDisplayState()
    return self:QueueTargetingWidgetRefresh("target-toggle")
end

function Client:ActivateSpellReference(spellRef, options)
    if type(self.CanPerformEventAction) == "function"
        and not self:CanPerformEventAction(self:GetEventState(), "spell-cast")
    then
        return false, "cast-rejected"
    end
    local activationSnapshot = self.ResolveSpellActivationSnapshot and self:ResolveSpellActivationSnapshot(spellRef, {
        includeTargetCandidates = true,
    }) or nil
    if not activationSnapshot or activationSnapshot.canCast ~= true then
        return false, "cast-rejected"
    end

    local activationOptions = type(options) == "table" and options or nil
    local castTime = tonumber(activationSnapshot.spell.totalTicks) or activationSnapshot.spell.castTime
    local targetGroups = activationSnapshot.targetGroups or {}
    if #targetGroups == 0 then
        if self.PendingSpellTargeting then
            self:CancelSpellTargeting("")
        end
        return attemptSpellActivationCast(self, spellRef, castTime, activationSnapshot, activationOptions)
    end

    local pendingGroups = {}
    for index = 1, #targetGroups do
        local group = targetGroups[index]
        local candidates = type(activationSnapshot.targetCandidatesByGroup) == "table" and activationSnapshot.targetCandidatesByGroup[group.key] or {}
        local targetType = tostring(group.policy and group.policy.type or "single")
        local minTargets = math.max(0, tonumber(group.policy and group.policy.minTargets) or 0)
        if #candidates == 0
            and group.policy
            and (group.policy.requiresTarget == true or targetType == "all_allies")
        then
            emitTargetingInfo(
                "No valid %s targets for %s.",
                string.lower(tostring(group.label or "target")),
                tostring(resolveSpellName(spellRef))
            )
            return false, "cast-rejected"
        end
        if #candidates > 0 or targetType == "all_allies" then
            local selectedTargetEventIds = {}
            local focusedTargetEventId = 0
            if targetType == "all_allies" then
                for candidateIndex = 1, #candidates do
                    local candidateEventId = tonumber(candidates[candidateIndex] and candidates[candidateIndex].eventID) or 0
                    if candidateEventId > 0 then
                        selectedTargetEventIds[candidateEventId] = true
                    end
                end
                for candidateIndex = 1, #candidates do
                    local candidateEventId = tonumber(candidates[candidateIndex] and candidates[candidateIndex].eventID) or 0
                    if selectedTargetEventIds[candidateEventId] then
                        focusedTargetEventId = candidateEventId
                        break
                    end
                end
            end
            local initialTargetUnit = type(activationSnapshot.initialTargetUnitByGroup) == "table"
                and activationSnapshot.initialTargetUnitByGroup[group.key]
                or nil
            local initialTargetEventId = tonumber(initialTargetUnit and initialTargetUnit.eventID) or 0
            if targetType ~= "all_allies" and targetType ~= "raid_marker" and initialTargetEventId > 0 then
                for candidateIndex = 1, #candidates do
                    if tonumber(candidates[candidateIndex] and candidates[candidateIndex].eventID) == initialTargetEventId then
                        selectedTargetEventIds[initialTargetEventId] = true
                        focusedTargetEventId = initialTargetEventId
                        break
                    end
                end
            end
            pendingGroups[#pendingGroups + 1] = {
                key = group.key,
                label = group.label,
                policy = group.policy,
                selectedTargetEventIds = selectedTargetEventIds,
                focusedTargetEventId = focusedTargetEventId,
            }
        end
    end

    if #pendingGroups == 0 then
        if self.PendingSpellTargeting then
            self:CancelSpellTargeting("")
        end
        return attemptSpellActivationCast(self, spellRef, castTime, activationSnapshot, activationOptions)
    end

    self.PendingSpellTargeting = {
        spellRef = spellRef,
        spell = activationSnapshot.spell,
        dataset = activationSnapshot.dataset,
        eventId = activationSnapshot.eventState.id,
        casterEventId = activationSnapshot.casterUnit.eventID,
        groups = pendingGroups,
        activeGroupKey = pendingGroups[1] and pendingGroups[1].key or nil,
        activationSnapshot = activationSnapshot,
        activationOptions = activationOptions,
    }
    self:InvalidatePendingSpellTargetingDisplayState()

    local targetingReason = activationOptions and activationOptions.targetingReason or "spell-activate"
    return self:RefreshTargetingWidget(targetingReason)
end

function Client:ActivateActionBarSpell(spellRef)
    local activated = self:ActivateSpellReference(spellRef, {
        sourceType = "action_bar",
        targetingReason = "action-bar-activate",
    })
    return activated == true
end

return Client
