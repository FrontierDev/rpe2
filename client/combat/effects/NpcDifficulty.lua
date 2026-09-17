local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Combat = Addon.Client.Combat or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Ruleset = Addon.Internal.Ruleset or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Combat = Addon.Client.Combat
local Ruleset = Addon.Internal.Ruleset
local Common = Addon.Utils.Common or {}
local Normalization = Addon.Client.Combat.Normalization or {}

if type(Combat) ~= "table" or Combat._npcDifficultyIntegrationInstalled == true then
    return
end

local RESULT_PASS = "pass"
local RESULT_FAIL = "fail"

local function trimText(value)
    if type(Normalization.TrimText) == "function" then
        return Normalization.TrimText(value)
    end
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeToken(value)
    if type(Normalization.NormalizeToken) == "function" then
        return Normalization.NormalizeToken(value)
    end
    local text = trimText(value)
    return text ~= "" and text or nil
end

local function round(value)
    if type(Common.Round) == "function" then
        return Common.Round(value)
    end

    local numeric = tonumber(value) or 0
    if numeric >= 0 then
        return math.floor(numeric + 0.5)
    end
    return math.ceil(numeric - 0.5)
end

local function applyPercentModifier(amount, percentValue, invert)
    local numericAmount = tonumber(amount) or 0
    local numericPercent = tonumber(percentValue) or 0
    local factor = invert and (1 - (numericPercent / 100)) or (1 + (numericPercent / 100))
    return numericAmount * factor
end

local function getEventState(entry)
    if type(entry) == "table" and type(entry.eventState) == "table" then
        return entry.eventState
    end
    if type(entry) == "table" and type(entry.context) == "table" and type(entry.context.eventState) == "table" then
        return entry.context.eventState
    end
    return type(Client.GetEventState) == "function" and Client:GetEventState() or nil
end

local function copyAbsorptionRuntimeSources(auraManager, eventState, targetEventId)
    if not auraManager or type(auraManager.GetAbsorptionSources) ~= "function" then
        return {}
    end

    local copied = {}
    local sources = auraManager:GetAbsorptionSources(Client, eventState, targetEventId) or {}
    for index = 1, #sources do
        local source = sources[index]
        if type(source) == "table" then
            copied[#copied + 1] = {
                auraKey = source.auraKey,
                effectIndex = source.effectIndex,
                maximum = tonumber(source.maximum) or 0,
                remaining = tonumber(source.remaining) or 0,
                revision = tonumber(source.revision) or 0,
            }
        end
    end
    return copied
end

local function getDifficultyModifiers(unit, eventState)
    if type(unit) ~= "table" or unit.isPlayer == true then
        return {
            healthPercent = 0,
            damagePercent = 0,
            hitBonus = 0,
            defenceBonus = 0,
        }
    end

    if type(Ruleset.GetNpcDifficultyModifiers) ~= "function" then
        return {
            healthPercent = 0,
            damagePercent = 0,
            hitBonus = 0,
            defenceBonus = 0,
        }
    end

    local modifiers = Ruleset.GetNpcDifficultyModifiers(type(eventState) == "table" and eventState.difficulty or "normal")
    if type(modifiers) ~= "table" then
        modifiers = {}
    end

    return {
        healthPercent = tonumber(modifiers.healthPercent) or 0,
        damagePercent = tonumber(modifiers.damagePercent) or 0,
        hitBonus = tonumber(modifiers.hitBonus) or 0,
        defenceBonus = tonumber(modifiers.defenceBonus) or 0,
    }
end

local function getStatValue(context, unit, statRef)
    local normalizedStatRef = normalizeToken(statRef)
    if type(unit) ~= "table" or not normalizedStatRef then
        return 0
    end

    if type(Combat.GetCachedCombatStatValue) == "function" then
        return tonumber(Combat:GetCachedCombatStatValue(context, unit, normalizedStatRef, 0)) or 0
    end
    return 0
end

local function applyAttackerHitBonus(entry)
    if type(entry) ~= "table" or type(entry.attackerUnit) ~= "table" then
        return entry
    end

    if entry._npcDifficultyBaseAttackerTotal == nil then
        entry._npcDifficultyBaseAttackerTotal = tonumber(entry.attackerTotal) or 0
    end

    local modifiers = getDifficultyModifiers(entry.attackerUnit, getEventState(entry))
    local hitBonus = tonumber(modifiers.hitBonus) or 0
    entry.attackerTotal = round((tonumber(entry._npcDifficultyBaseAttackerTotal) or 0) + hitBonus)
    entry.difficultyHitBonus = hitBonus

    if type(entry.attackModifierContext) == "table" then
        entry.attackModifierContext.difficultyHitBonus = hitBonus
        entry.attackModifierContext.finalTotal = entry.attackerTotal
    end
    if type(entry.attackerRollContext) == "table" then
        entry.attackerRollContext.difficultyHitBonus = hitBonus
        entry.attackerRollContext.finalTotal = entry.attackerTotal
    end

    return entry
end

local function resolveCreatureTypeDamageStatRef(combatRules, defenderUnit)
    if type(combatRules) ~= "table" or type(defenderUnit) ~= "table" then
        return nil
    end

    local creatureType = normalizeToken(defenderUnit.creatureType)
    if not creatureType then
        return nil
    end
    creatureType = string.lower(creatureType)

    local statRefs = type(combatRules.spellDamageVsCreatureTypeStats) == "table"
        and combatRules.spellDamageVsCreatureTypeStats
        or nil
    return statRefs and normalizeToken(statRefs[creatureType]) or nil
end

local function rebuildThreatPreview(entry, result, combatRules, effect)
    result.threatGenerated = 0
    result.threatSourceEventId = 0
    result.threatTargetEventId = 0
    result.threatTotal = 0
    result.threatUpdate = nil

    if type(entry.defenderUnit) ~= "table"
        or entry.defenderUnit.isPlayer == true
        or (tonumber(result.amount) or 0) <= 0
    then
        return
    end

    local attackerEventId = math.floor(tonumber(entry.attackerEventId or (entry.attackerUnit and entry.attackerUnit.eventID)) or 0)
    local defenderEventId = math.floor(tonumber(entry.defenderEventId or (entry.defenderUnit and entry.defenderUnit.eventID)) or 0)
    if attackerEventId <= 0 or defenderEventId <= 0 then
        return
    end

    local threatCoefficient = tonumber(effect and effect.threatCoefficient) or 1
    local threatAmount = math.max(0, round((tonumber(result.amount) or 0) * threatCoefficient))
    threatAmount = math.max(0, round(applyPercentModifier(
        threatAmount,
        getStatValue(entry.hitResolutionContext or entry.context, entry.attackerUnit, combatRules and combatRules.threatGeneratedStat),
        false
    )))

    local previousThreat = 0
    if type(entry.defenderUnit.threatTable) == "table" then
        previousThreat = tonumber(entry.defenderUnit.threatTable[attackerEventId]) or 0
    end

    result.threatGenerated = threatAmount
    result.threatSourceEventId = attackerEventId
    result.threatTargetEventId = defenderEventId
    result.threatTotal = previousThreat + threatAmount
    if threatAmount > 0 then
        result.threatUpdate = {
            targetEventId = defenderEventId,
            sourceEventId = attackerEventId,
            amount = threatAmount,
        }
    end
end

local function applyDifficultyDamageResult(entry, result)
    if type(entry) ~= "table" or type(result) ~= "table" or type(entry.attackerUnit) ~= "table" then
        return result
    end

    local hitContext = type(entry.hitResolutionContext) == "table" and entry.hitResolutionContext or nil
    if type(hitContext) ~= "table" then
        return result
    end

    local effect = type(hitContext.effect) == "table" and hitContext.effect or entry.effect
    local combatRules = type(hitContext.combatRules) == "table" and hitContext.combatRules or nil
    if type(effect) ~= "table" or type(combatRules) ~= "table" then
        return result
    end

    local rawDamage = math.max(0, tonumber(hitContext.rawDamage) or tonumber(entry.rawDamage) or tonumber(result.rawDamage) or 0)
    result.rawDamage = rawDamage
    local difficultyModifiers = getDifficultyModifiers(entry.attackerUnit, getEventState(entry))
    local damagePercent = tonumber(difficultyModifiers.damagePercent) or 0
    result.difficultyDamagePercent = damagePercent

    if rawDamage <= 0 then
        result.amount = 0
        return result
    end

    local resultType = normalizeToken(entry.resultType or result.resultType) or "hit"
    local wasCritical = resultType == "critical" or resultType == "crushing"
    result.resultType = resultType
    result.wasCritical = wasCritical

    local scaledRawDamage = rawDamage
    if resultType == "crushing" then
        scaledRawDamage = scaledRawDamage * (tonumber(combatRules.crushingDamageMultiplier) or 1.5)
    elseif resultType == "critical" then
        scaledRawDamage = scaledRawDamage * (tonumber(combatRules.criticalDamageMultiplier) or 2.0)
    end

    local finalDamage = scaledRawDamage
    for schoolIndex = 1, #(hitContext.schoolContexts or {}) do
        local schoolContext = hitContext.schoolContexts[schoolIndex]
        local mitigation = schoolContext and schoolContext.mitigation or nil
        if type(mitigation) == "table" then
            if mitigation.mode == "direct" then
                finalDamage = finalDamage - (tonumber(mitigation.flat) or 0)
            else
                finalDamage = finalDamage * (1 - ((tonumber(mitigation.percent) or 0) / 100))
            end
        end
    end

    finalDamage = applyPercentModifier(
        finalDamage,
        getStatValue(hitContext, entry.attackerUnit, combatRules.damageDealtStat),
        false
    )

    if entry.attackType == "spell" then
        local creatureTypeDamageStatRef = resolveCreatureTypeDamageStatRef(combatRules, entry.defenderUnit)
        if creatureTypeDamageStatRef then
            finalDamage = applyPercentModifier(
                finalDamage,
                getStatValue(hitContext, entry.attackerUnit, creatureTypeDamageStatRef),
                false
            )
        end
    end

    -- Event difficulty is an attacker-side multiplier. It is deliberately
    -- applied after existing outgoing damage modifiers and before the
    -- defender's final damage-reduction stage.
    finalDamage = applyPercentModifier(finalDamage, damagePercent, false)

    local reductionStatRef = normalizeToken(combatRules.damageReductionStat)
    if reductionStatRef then
        finalDamage = applyPercentModifier(
            finalDamage,
            getStatValue(hitContext, entry.defenderUnit, reductionStatRef),
            true
        )
    end

    result.critMitigationStatRef = nil
    result.critMitigationStatValue = 0
    result.critMitigation = nil
    result.critMitigated = 0
    if wasCritical then
        local defenderLevel = type(Combat.GetUnitLevel) == "function"
            and Combat:GetUnitLevel(entry.defenderUnit, getEventState(entry))
            or 1
        local critMitigationStatRef = normalizeToken(combatRules.criticalDamageMitigationStat)
        local critMitigationStatValue = critMitigationStatRef and getStatValue(hitContext, entry.defenderUnit, critMitigationStatRef) or 0
        local critMitigation = type(Combat.ResolveCriticalDamageMitigation) == "function"
            and Combat:ResolveCriticalDamageMitigation(combatRules, critMitigationStatValue, defenderLevel)
            or nil
        local damageBeforeCritMitigation = finalDamage

        result.critMitigationStatRef = critMitigationStatRef
        result.critMitigationStatValue = critMitigationStatValue
        result.critMitigation = critMitigation
        if type(critMitigation) == "table" then
            if critMitigation.mode == "direct" then
                finalDamage = finalDamage - (tonumber(critMitigation.flat) or 0)
            else
                finalDamage = finalDamage * (1 - ((tonumber(critMitigation.percent) or 0) / 100))
            end
        end
        result.critMitigated = math.max(0, damageBeforeCritMitigation - finalDamage)
    end

    finalDamage = math.max(0, round(finalDamage))
    scaledRawDamage = math.max(0, round(scaledRawDamage))
    result.preAbsorbAmount = finalDamage
    result.absorbedAmount = 0
    result.absorptionChanges = {}
    result.amount = finalDamage
    result.mitigated = math.max(0, scaledRawDamage - finalDamage)
    result.mitigationPercent = scaledRawDamage > 0 and ((result.mitigated / scaledRawDamage) * 100) or 0

    local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    local targetEventId = entry.defenderEventId or (entry.defenderUnit and entry.defenderUnit.eventID)
    local runtimeSourcesBeforeCommit = copyAbsorptionRuntimeSources(auraManager, getEventState(entry), targetEventId)
    local previewRemainingDamage = nil
    if finalDamage > 0
        and auraManager
        and type(auraManager.PreviewAbsorption) == "function"
    then
        local absorptionPreview = auraManager:PreviewAbsorption(
            Client,
            getEventState(entry),
            entry.defenderEventId or (entry.defenderUnit and entry.defenderUnit.eventID),
            finalDamage,
            effect.damageSchoolRefs or {}
        )
        if type(absorptionPreview) == "table" then
            local previewAbsorbedAmount = tonumber(absorptionPreview.absorbedAmount or absorptionPreview.absorbed)
            previewRemainingDamage = tonumber(absorptionPreview.remainingDamage or absorptionPreview.healthRemainder)
            if previewAbsorbedAmount == nil then
                previewAbsorbedAmount = finalDamage - (previewRemainingDamage or finalDamage)
            end
            result.absorbedAmount = math.min(finalDamage, math.max(0, previewAbsorbedAmount))
            result.absorptionChanges = absorptionPreview.changes or absorptionPreview.plan or {}
            -- Keep the same authoritative arithmetic as the base combat path;
            -- never trust a cached remainder independently of absorbedAmount.
            result.amount = math.max(0, finalDamage - result.absorbedAmount)
        end
    end

    result.absorptionDiagnostics = result.absorptionDiagnostics or {}
    result.absorptionDiagnostics.preAbsorbAmount = finalDamage
    result.absorptionDiagnostics.previewAbsorbedAmount = math.max(0, tonumber(result.absorbedAmount) or 0)
    result.absorptionDiagnostics.previewRemainingDamage = math.max(
        0,
        previewRemainingDamage ~= nil
            and previewRemainingDamage
            or (finalDamage - result.absorbedAmount)
    )
    result.absorptionDiagnostics.runtimeSourcesBeforeCommit = runtimeSourcesBeforeCommit

    rebuildThreatPreview(entry, result, combatRules, effect)
    return result
end

local function updateEntryDamagePreview(entry)
    if type(entry) ~= "table" then
        return entry
    end

    local hitContext = type(entry.hitResolutionContext) == "table" and entry.hitResolutionContext or nil
    local result = hitContext and hitContext.resolvedResult or nil
    if type(result) ~= "table" then
        result = type(entry.damagePreview) == "table" and entry.damagePreview or nil
    end
    if type(result) ~= "table" and type(entry.sharedHitPreview) == "table" then
        result = type(entry.sharedHitPreview.damagePreview) == "table" and entry.sharedHitPreview.damagePreview or nil
    end
    if type(result) ~= "table" then
        return entry
    end

    applyDifficultyDamageResult(entry, result)
    entry.damagePreview = result
    if type(entry.sharedHitPreview) == "table" then
        entry.sharedHitPreview.damagePreview = result
    end
    if hitContext then
        hitContext.resolvedResult = result
    end
    return entry
end

local baseBuildHitCheckEntry = Combat.BuildHitCheckEntry
if type(baseBuildHitCheckEntry) == "function" then
    function Combat:BuildHitCheckEntry(context, effect, component)
        local entry = baseBuildHitCheckEntry(self, context, effect, component)
        applyAttackerHitBonus(entry)
        updateEntryDamagePreview(entry)
        return entry
    end
end

local baseBuildHitPreviewEntry = Combat.BuildHitPreviewEntry
if type(baseBuildHitPreviewEntry) == "function" then
    function Combat:BuildHitPreviewEntry(context, effect, component, timingParts)
        local entry = baseBuildHitPreviewEntry(self, context, effect, component, timingParts)
        applyAttackerHitBonus(entry)
        updateEntryDamagePreview(entry)
        return entry
    end
end

local baseResolveHitCheckOutcome = Combat.ResolveHitCheckOutcome
if type(baseResolveHitCheckOutcome) == "function" then
    function Combat:ResolveHitCheckOutcome(entry, action)
        local resultToken, resolution = baseResolveHitCheckOutcome(self, entry, action)
        if type(resolution) ~= "table" or type(entry) ~= "table" or type(entry.defenderUnit) ~= "table" then
            return resultToken, resolution
        end

        local defenceSystem = tostring(resolution.defenceSystem or "")
        if defenceSystem ~= "ac" and defenceSystem ~= "simple"
            and defenceSystem ~= "complex" and defenceSystem ~= "percent"
        then
            return resultToken, resolution
        end

        local defenceBonus = tonumber(getDifficultyModifiers(entry.defenderUnit, getEventState(entry)).defenceBonus) or 0
        local baseDefenderTotal = tonumber(resolution.defenderTotal) or 0
        local defenderTotal = baseDefenderTotal + defenceBonus
        if defenceSystem == "percent" then
            defenderTotal = round(defenderTotal)
        end

        resolution.baseDefenderTotal = baseDefenderTotal
        resolution.difficultyDefenceBonus = defenceBonus
        resolution.defenderTotal = defenderTotal
        local attackerTotal = tonumber(resolution.attackerTotal) or tonumber(entry.attackerTotal) or 0
        resultToken = attackerTotal > defenderTotal and RESULT_PASS or RESULT_FAIL
        return resultToken, resolution
    end
end

local baseBuildDamagePreview = Combat.BuildDamagePreview
if type(baseBuildDamagePreview) == "function" then
    function Combat:BuildDamagePreview(entry)
        if type(entry) == "table" and type(entry.authoritativeDamageResult) == "table" then
            return entry.authoritativeDamageResult
        end
        local result = baseBuildDamagePreview(self, entry)
        if type(result) == "table" then
            applyDifficultyDamageResult(entry, result)
            if type(entry) == "table" then
                entry.damagePreview = result
                if type(entry.hitResolutionContext) == "table" then
                    entry.hitResolutionContext.resolvedResult = result
                end
            end
        end
        return result
    end
end

local baseApplyResolvedDamage = Combat.ApplyResolvedDamage
if type(baseApplyResolvedDamage) == "function" then
    function Combat:ApplyResolvedDamage(entry, previewOnly)
        if previewOnly ~= true
            and type(entry) == "table"
            and type(entry.authoritativeDamageResult) == "table"
        then
            return true, entry.authoritativeDamageResult
        end
        if type(self.BuildDamagePreview) == "function" then
            self:BuildDamagePreview(entry)
        end
        return baseApplyResolvedDamage(self, entry, previewOnly)
    end
end

Combat._npcDifficultyIntegrationInstalled = true
