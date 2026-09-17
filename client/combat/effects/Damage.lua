local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Combat = Addon.Client.Combat or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Combat = Addon.Client.Combat
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Registry = Addon.Internal.Registry or {}
local Database = Addon.Internal.Database or {}
local Dependencies = Database.Dependecies or {}
local Common = Addon.Utils.Common or {}
local Dice = Addon.Utils.Dice or {}
local Lookup = Addon.Utils.Lookup or {}
local Normalization = Addon.Client.Combat.Normalization or {}
local Debug = Addon.Debug
local function getAuraManager()
    return Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraManager or nil
end

local function getProfile()
    return Addon.Internal and Addon.Internal.Profile or {}
end

local function getProfileRuntimeRevision()
    local builder = Addon.Client
        and Addon.Client.Spellcasting
        and Addon.Client.Spellcasting.DescriptionBuilder
        or nil
    return math.max(1, math.floor(tonumber(builder and builder.ProfileTooltipContextRevision) or 1))
end

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local DEFAULT_ATTACK_ROLL_DICE = "1d20"
local DEFAULT_DEFENCE_ROLL_DICE = "1d20"
local RESULT_PASS = "pass"
local RESULT_FAIL = "fail"
local HIT_CHECK_REQUEST_OPCODE = Operations.GetOpcode and Operations:GetOpcode("COMBAT_HIT_CHECK_REQUEST") or nil
local SPELLCAST_SLOW_HELPER_MS = 25
local SPELLCAST_SLOW_TOTAL_MS = 100
local trimText = Normalization.TrimText
local normalizeToken = Normalization.NormalizeToken
local normalizeResultToken = Normalization.NormalizeResultToken
local splitList = Normalization.SplitList
local SPELL_DAMAGE_VS_CREATURE_TYPE_RULE_KEYS = {
    aberration = "spell_damage_vs_aberration_stat",
    beast = "spell_damage_vs_beast_stat",
    demon = "spell_damage_vs_demon_stat",
    dragonkin = "spell_damage_vs_dragonkin_stat",
    elemental = "spell_damage_vs_elemental_stat",
    giant = "spell_damage_vs_giant_stat",
    humanoid = "spell_damage_vs_humanoid_stat",
    mechanical = "spell_damage_vs_mechanical_stat",
    undead = "spell_damage_vs_undead_stat",
}

local function getNowMilliseconds()
    if type(GetTimePreciseSec) == "function" then
        return GetTimePreciseSec() * 1000
    end

    return (GetTime and GetTime() or 0) * 1000
end

local function getProfilerMilliseconds()
    if type(debugprofilestop) == "function" then
        return debugprofilestop()
    end

    return nil
end

local function buildUnitStatRevisionToken(unit)
    if type(unit) ~= "table" then
        return "nil"
    end

    local parts = {
        tostring(tonumber(unit.eventID) or 0),
        tostring(math.max(0, math.floor(tonumber(unit.__rpeCombatRevision) or 0))),
        tostring(unit.isPlayer == true and 1 or 0),
        tostring(getConfigurationRevision()),
        tostring(getProfileRuntimeRevision()),
    }

    local stats = type(unit.stats) == "table" and unit.stats or nil
    if stats then
        for index = 1, #stats do
            local entry = stats[index]
            if type(entry) == "table" then
                parts[#parts + 1] = table.concat({
                    tostring(entry.statRef or entry.ref or ""),
                    tostring(entry.currentValue ~= nil and entry.currentValue or ""),
                    tostring(entry.value ~= nil and entry.value or ""),
                    tostring(entry.maxValue ~= nil and entry.maxValue or ""),
                }, "\30")
            end
        end
    end

    return table.concat(parts, "\31")
end

local function getAuraRevisionForEvent(eventId)
    local auraManager = getAuraManager()
    if type(auraManager) == "table" and type(auraManager.GetEventAuraRevision) == "function" then
        return math.max(0, math.floor(tonumber(auraManager:GetEventAuraRevision(Client, eventId)) or 0))
    end

    local bucket = type(Client.ActiveAurasByEventId) == "table" and Client.ActiveAurasByEventId[tostring(eventId or "")] or nil
    return math.max(0, math.floor(tonumber(bucket and bucket.revision) or 0))
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

local function logDamageTimingLine(contextLabel, parts, totalElapsed, threshold)
    if not isSpellcastTimingEnabled() or type(Debug) ~= "table" or type(Debug.Internal) ~= "function" then
        return false
    end

    ensureSpellcastInternalLoggingEnabled()

    local slowThreshold = tonumber(threshold) or SPELLCAST_SLOW_HELPER_MS
    local totalText, totalSlow = buildTimingSegment("total", totalElapsed, slowThreshold)
    local segments = { totalText }
    local hasSlow = totalSlow

    for index = 1, #(parts or {}) do
        local part = parts[index]
        if type(part) == "table" and type(part.label) == "string" then
            local segment, isSlow = buildTimingSegment(part.label, part.elapsed, part.threshold or slowThreshold)
            segments[#segments + 1] = segment
            hasSlow = hasSlow or isSlow
        end
    end

    Debug.Internal(
        "%sSpell damage timing [%s]: %s",
        hasSlow and "SLOW " or "",
        tostring(contextLabel or "unknown"),
        table.concat(segments, ", ")
    )
    return true
end

local function appendTimingPart(parts, label, elapsed, threshold)
    if type(parts) ~= "table" then
        return
    end

    parts[#parts + 1] = {
        label = label,
        elapsed = math.max(0, tonumber(elapsed) or 0),
        threshold = threshold or SPELLCAST_SLOW_HELPER_MS,
    }
end

function Combat:BumpCombatRuntimeRevision(eventId, unitEventId)
    self.CombatRuntimeRevision = math.max(1, math.floor(tonumber(self.CombatRuntimeRevision) or 1) + 1)
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId ~= "" then
        self.CombatRuntimeRevisionsByEventId = self.CombatRuntimeRevisionsByEventId or {}
        self.CombatRuntimeRevisionsByEventId[normalizedEventId] = self.CombatRuntimeRevision
    end

    local numericUnitEventId = tonumber(unitEventId) or 0
    if numericUnitEventId > 0 then
        self.CombatRuntimeRevisionsByUnitEventId = self.CombatRuntimeRevisionsByUnitEventId or {}
        self.CombatRuntimeRevisionsByUnitEventId[numericUnitEventId] = self.CombatRuntimeRevision
    end

    return self.CombatRuntimeRevision
end

function Client:BumpCombatRuntimeRevision(eventState, unitEventId)
    local combat = self.Combat or Addon.Client.Combat
    local eventId = type(eventState) == "table" and eventState.id or eventState
    if type(combat) == "table" and type(combat.BumpCombatRuntimeRevision) == "function" then
        local revision = combat:BumpCombatRuntimeRevision(eventId, unitEventId)
        if type(self.PendingSpellTargeting) == "table"
            and tostring(self.PendingSpellTargeting.eventId or "") == tostring(eventId or "")
        then
            if type(self.InvalidatePendingSpellTargetingDisplayState) == "function" then
                self:InvalidatePendingSpellTargetingDisplayState()
            end
            if type(self.QueueTargetingWidgetRefresh) == "function" then
                self:QueueTargetingWidgetRefresh("combat-revision")
            end
        end
        return revision
    end

    return 0
end

function Combat:BuildCombatLookupSnapshot(context, eventState, attackerUnit, defenderUnit)
    local eventId = normalizeToken(type(eventState) == "table" and eventState.id or type(context) == "table" and context.eventId or nil)
    local eventRevision = 0
    if eventId and type(self.CombatRuntimeRevisionsByEventId) == "table" then
        eventRevision = math.max(0, math.floor(tonumber(self.CombatRuntimeRevisionsByEventId[eventId]) or 0))
    end

    local snapshot = {
        eventId = eventId or "",
        eventRevision = eventRevision,
        auraRevision = getAuraRevisionForEvent(eventId),
        configurationRevision = getConfigurationRevision(),
        profileRevision = getProfileRuntimeRevision(),
        unitRevisionTokens = {},
    }

    if type(attackerUnit) == "table" then
        snapshot.unitRevisionTokens[attackerUnit] = buildUnitStatRevisionToken(attackerUnit)
    end
    if type(defenderUnit) == "table" then
        snapshot.unitRevisionTokens[defenderUnit] = buildUnitStatRevisionToken(defenderUnit)
    end

    return snapshot
end

function Combat:GetCachedCombatStatValue(context, unit, statRef, fallback)
    local normalizedStatRef = normalizeToken(statRef)
    if type(unit) ~= "table" or not normalizedStatRef then
        return tonumber(fallback) or 0
    end

    local snapshot = type(context) == "table" and context.combatLookupSnapshot or nil
    if type(snapshot) ~= "table" then
        snapshot = self:BuildCombatLookupSnapshot(context, type(context) == "table" and context.eventState or nil, unit, nil)
        if type(context) == "table" then
            context.combatLookupSnapshot = snapshot
        end
    end

    local unitRevisionToken = snapshot.unitRevisionTokens and snapshot.unitRevisionTokens[unit]
    if not unitRevisionToken then
        unitRevisionToken = buildUnitStatRevisionToken(unit)
        snapshot.unitRevisionTokens = snapshot.unitRevisionTokens or {}
        snapshot.unitRevisionTokens[unit] = unitRevisionToken
    end

    local key = table.concat({
        tostring(snapshot.eventId or ""),
        tostring(snapshot.eventRevision or 0),
        tostring(snapshot.auraRevision or 0),
        tostring(snapshot.configurationRevision or 0),
        tostring(snapshot.profileRevision or 0),
        tostring(tonumber(unit.eventID) or 0),
        tostring(unitRevisionToken or ""),
        tostring(normalizedStatRef),
    }, "\31")

    self.CombatStatValueCache = self.CombatStatValueCache or {}
    self.CombatStatValueCacheOrder = self.CombatStatValueCacheOrder or {}
    local cached = self.CombatStatValueCache[key]
    if cached ~= nil then
        return tonumber(cached) or 0
    end

    local value = tonumber(Lookup.GetStatValue and Lookup.GetStatValue(unit, normalizedStatRef, fallback or 0) or fallback or 0) or 0
    self.CombatStatValueCache[key] = value
    local order = self.CombatStatValueCacheOrder
    order[#order + 1] = key
    if #order > 256 then
        local oldKey = table.remove(order, 1)
        if oldKey then
            self.CombatStatValueCache[oldKey] = nil
        end
    end

    return value
end

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function enqueueDamagePresentationWork(fn, ...)
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

local function showCombatReactionDeferred(targetClient, entry)
    if type(targetClient) ~= "table" or type(entry) ~= "table" then
        return false
    end
    if type(targetClient.ShowCombatReaction) ~= "function" then
        return false
    end

    return targetClient:ShowCombatReaction(entry)
end

local buildResolvedDamageResult

local function getPercentModifierStatValue(unit, statRef)
    local normalizedStatRef = normalizeToken(statRef)
    if not normalizedStatRef then
        return 0
    end

    return tonumber(Lookup.GetStatValue and Lookup.GetStatValue(unit, normalizedStatRef, 0) or 0) or 0
end

local function applyPercentModifier(amount, percentValue, invert)
    local numericAmount = tonumber(amount) or 0
    local numericPercent = tonumber(percentValue) or 0
    local factor = invert and (1 - (numericPercent / 100)) or (1 + (numericPercent / 100))
    return numericAmount * factor
end

local function buildThreatUpdatePayload(targetUnit, sourceUnit, amount)
    local targetEventId = math.floor(tonumber(targetUnit and targetUnit.eventID) or 0)
    local sourceEventId = math.floor(tonumber(sourceUnit and sourceUnit.eventID) or 0)
    if targetEventId <= 0 or sourceEventId <= 0 then
        return nil
    end

    return {
        targetEventId = targetEventId,
        sourceEventId = sourceEventId,
        amount = math.max(0, Common.Round(amount or 0)),
    }
end

local function applyThreatToUnit(targetUnit, sourceEventId, threatAmount)
    local numericSourceEventId = math.floor(tonumber(sourceEventId) or 0)
    local numericThreatAmount = math.max(0, Common.Round(threatAmount or 0))
    if type(targetUnit) ~= "table" or numericSourceEventId <= 0 or numericThreatAmount <= 0 then
        return false, numericThreatAmount, 0
    end

    targetUnit.threatTable = type(targetUnit.threatTable) == "table" and targetUnit.threatTable or {}
    local previousThreat = tonumber(targetUnit.threatTable[numericSourceEventId]) or 0
    targetUnit.threatTable[numericSourceEventId] = previousThreat + numericThreatAmount
    return true, numericThreatAmount, targetUnit.threatTable[numericSourceEventId]
end

local function getThreatForUnit(targetUnit, sourceEventId)
    local numericSourceEventId = math.floor(tonumber(sourceEventId) or 0)
    if type(targetUnit) ~= "table" or numericSourceEventId <= 0 then
        return 0
    end

    local threatTable = type(targetUnit.threatTable) == "table" and targetUnit.threatTable or nil
    return math.max(0, tonumber(threatTable and threatTable[numericSourceEventId]) or 0)
end

local function commitResolvedDamageThreat(entry, result)
    if type(entry) ~= "table" or type(entry.defenderUnit) ~= "table" or type(result) ~= "table" then
        return false
    end
    if result.threatCommitted == true then
        return result.threatApplied == true
    end

    result.threatCommitted = true
    result.threatApplied = false
    result.threatUpdate = nil
    if entry.defenderUnit.isPlayer == true or (tonumber(result.amount) or 0) <= 0 then
        return false
    end

    local threatApplied, generatedThreat, totalThreat = applyThreatToUnit(
        entry.defenderUnit,
        result.threatSourceEventId,
        result.threatGenerated
    )
    result.threatGenerated = generatedThreat
    result.threatApplied = threatApplied
    result.threatTotal = totalThreat
    if threatApplied then
        result.threatUpdate = buildThreatUpdatePayload(entry.defenderUnit, entry.attackerUnit, generatedThreat)
    end
    return threatApplied
end

local function buildCombatResult(entry, resultToken, resultType)
    return {
        effectType = "damage",
        resultType = resultType or resultToken or "invalid",
        hitCheckResult = resultToken,
        landed = resultToken == RESULT_PASS,
        pending = resultToken == nil,
        preAbsorbAmount = 0,
        absorbedAmount = 0,
        absorptionChanges = {},
        amount = 0,
        checkId = entry and entry.checkId or nil,
        eventId = entry and entry.eventId or nil,
        spellRef = entry and entry.spellRef or nil,
        componentKey = entry and entry.componentKey or nil,
    }
end

local function buildCombatRuleSnapshot(self)
    local spellDamageVsCreatureTypeStats = {}
    for creatureType, ruleKey in pairs(SPELL_DAMAGE_VS_CREATURE_TYPE_RULE_KEYS) do
        spellDamageVsCreatureTypeStats[creatureType] = normalizeToken(self:GetCombatRule(ruleKey, ""))
    end

    return {
        crushingDamageMultiplier = tonumber(self:GetCombatRule("crushing_blow_damage_multiplier", 1.5)) or 1.5,
        criticalDamageMultiplier = tonumber(self:GetCombatRule("critical_damage_multiplier", 2.0)) or 2.0,
        criticalDamageMitigationStat = normalizeToken(self:GetCombatRule("critical_damage_mitigation_stat", "")),
        criticalDamageMitigationMode = normalizeToken(self:GetCombatRule("critical_damage_mitigation_mode", "direct")) or "direct",
        criticalDamageMitigationCoefficient = tonumber(self:GetCombatRule("critical_damage_mitigation_coefficient", 1)) or 1,
        criticalDamageMitigationModel = normalizeToken(self:GetCombatRule("critical_damage_mitigation_model", "legacy")) or "legacy",
        criticalDamageMitigationReferenceAmount = tonumber(self:GetCombatRule("critical_damage_mitigation_reference_amount", 0)) or 0,
        criticalDamageMitigationReferencePercent = tonumber(self:GetCombatRule("critical_damage_mitigation_reference_percent", 0)) or 0,
        criticalDamageMitigationReferenceLevel = tonumber(self:GetCombatRule("critical_damage_mitigation_reference_level", 60)) or 60,
        damageDealtStat = normalizeToken(self:GetCombatRule("damage_dealt_stat", "")),
        spellDamageVsCreatureTypeStats = spellDamageVsCreatureTypeStats,
        damageReductionStat = normalizeToken(self:GetCombatRule("damage_reduction_stat", "")),
        threatGeneratedStat = normalizeToken(self:GetCombatRule("threat_generated_stat", "")),
    }
end

local function resolveSpellDamageCreatureTypeStatRef(combatRules, defenderUnit)
    if type(combatRules) ~= "table" or type(defenderUnit) ~= "table" then
        return nil
    end

    local creatureType = normalizeToken(defenderUnit.creatureType)
    if not creatureType then
        return nil
    end

    local statRefsByCreatureType = type(combatRules.spellDamageVsCreatureTypeStats) == "table"
        and combatRules.spellDamageVsCreatureTypeStats
        or nil
    return statRefsByCreatureType and normalizeToken(statRefsByCreatureType[creatureType]) or nil
end

local function buildWeaponContext(self, context, attackerUnit, effect, attackType)
    local weaponDamageMode = tostring(effect and effect.weaponDamageMode or "none")
    local weaponContext = {
        attackType = attackType,
        damageMode = weaponDamageMode,
        weaponDamageCoefficient = tonumber(effect and effect.weaponDamageCoefficient) or 1,
        refs = {},
        itemsByRef = {},
        totalDamage = 0,
    }
    if weaponDamageMode == "none" then
        return weaponContext
    end

    local function appendSlot(slotKey, fallbackField)
        local itemRef = self.ResolveWeaponItemRef and self:ResolveWeaponItemRef(attackerUnit, slotKey, fallbackField) or nil
        itemRef = normalizeToken(itemRef)
        if not itemRef then
            return
        end

        weaponContext.refs[#weaponContext.refs + 1] = itemRef
        if weaponContext.itemsByRef[itemRef] ~= nil then
            return
        end

        local item = self.ResolveItemDefinition and select(1, self:ResolveItemDefinition(itemRef)) or nil
        weaponContext.itemsByRef[itemRef] = item or false
        if type(item) ~= "table" then
            return
        end

        local damageValue = 0
        local damageMode = tostring(item.damageMode or "fixed")
        if damageMode == "range" then
            local minDamage = math.floor(tonumber(item.minDamagePerTurn) or 0)
            local maxDamage = math.floor(tonumber(item.maxDamagePerTurn) or 0)
            if maxDamage < minDamage then
                maxDamage = minDamage
            end
            damageValue = math.max(0, tonumber(Dice.RollRandom and Dice.RollRandom(context, minDamage, maxDamage) or minDamage) or 0)
        else
            damageValue = math.max(0, tonumber(item.damagePerTurn) or 0)
        end

        weaponContext.totalDamage = weaponContext.totalDamage + damageValue
    end

    local primarySlotKey = attackType == "ranged" and "ranged" or "mainhand"
    local primaryField = attackType == "ranged" and "rangedWeapon" or "mainHandWeapon"
    if weaponDamageMode == "main_hand" or weaponDamageMode == "both" then
        appendSlot(primarySlotKey, primaryField)
    end
    if weaponDamageMode == "off_hand" or weaponDamageMode == "both" then
        appendSlot("offhand", "offHandWeapon")
    end

    return weaponContext
end

local function buildHealthResourceContext(self, entry)
    local healthResourceRef = type(entry.context) == "table" and normalizeToken(entry.context.healthResourceRef) or nil
    if not healthResourceRef then
        healthResourceRef = normalizeToken(entry.eventState and entry.eventState.healthResourceRef)
    end
    if not healthResourceRef and type(self.GetHealthResourceRef) == "function" then
        healthResourceRef = normalizeToken(self:GetHealthResourceRef())
    end

    local context = {
        healthResourceRef = healthResourceRef,
        existingEntry = healthResourceRef and Lookup.GetResourceEntry and Lookup.GetResourceEntry(entry.defenderUnit, healthResourceRef) or nil,
        sourceEntry = nil,
    }
    if context.existingEntry or not healthResourceRef then
        return context
    end

    local resolvedUnit = entry.defenderUnit.GetResolvedUnit and entry.defenderUnit:GetResolvedUnit() or nil
    local resolvedResources = type(resolvedUnit) == "table" and resolvedUnit.resources or nil
    for index = 1, #(resolvedResources or {}) do
        local candidate = resolvedResources[index]
        if normalizeToken(candidate and candidate.resourceRef) == healthResourceRef then
            context.sourceEntry = candidate
            return context
        end
    end

    if type(Dependencies.ParseSourceStatRef) == "function" and type(Database.GetDatasetByID) == "function" then
        local datasetId, resourceId = Dependencies.ParseSourceStatRef(healthResourceRef)
        local dataset = datasetId and Database.GetDatasetByID(datasetId) or nil
        local resources = type(dataset) == "table" and dataset.resources or nil
        for index = 1, #(resources or {}) do
            local candidate = resources[index]
            if tostring(candidate and candidate.id or "") == tostring(resourceId or "") then
                context.sourceEntry = candidate
                break
            end
        end
    end

    return context
end

local function ensureHealthResourceEntry(entry, hitContext)
    local healthContext = type(hitContext) == "table" and hitContext.healthResourceContext or nil
    if type(healthContext) ~= "table" then
        return nil
    end
    if type(healthContext.existingEntry) == "table" then
        return healthContext.existingEntry
    end

    local healthResourceRef = normalizeToken(healthContext.healthResourceRef)
    local sourceEntry = healthContext.sourceEntry
    if not healthResourceRef or type(sourceEntry) ~= "table" then
        return nil
    end

    local playerCount = 0
    for index = 1, #(entry.eventState and entry.eventState.units or {}) do
        if entry.eventState.units[index] and entry.eventState.units[index].isPlayer == true then
            playerCount = playerCount + 1
        end
    end

    local currentValue = sourceEntry.currentValue
    local maxValue = sourceEntry.maxValue
    if currentValue == nil and maxValue == nil then
        if sourceEntry.value ~= nil or sourceEntry.perPlayer ~= nil then
            local scaledValue = (tonumber(sourceEntry.value) or 0) + ((tonumber(sourceEntry.perPlayer) or 0) * playerCount)
            currentValue = scaledValue
            maxValue = scaledValue
        else
            local baseValue = tonumber(sourceEntry.baseValue) or 0
            local derivedValue = 0
            if tostring(sourceEntry.valueMode or "manual") == "derived" and sourceEntry.sourceStatRef then
                derivedValue = (Combat.GetCachedCombatStatValue and Combat:GetCachedCombatStatValue(entry.context, entry.defenderUnit, sourceEntry.sourceStatRef, 0) or 0)
                    * (tonumber(sourceEntry.multiplier) or 0)
            end
            local resolvedValue = baseValue + derivedValue
            currentValue = sourceEntry.startsAtZero == true and 0 or resolvedValue
            maxValue = resolvedValue
        end
    end

    entry.defenderUnit.resources = entry.defenderUnit.resources or {}
    local createdEntry = {
        resourceRef = healthResourceRef,
        currentValue = tonumber(currentValue ~= nil and currentValue or maxValue) or 0,
        maxValue = tonumber(maxValue ~= nil and maxValue or currentValue) or 0,
    }
    entry.defenderUnit.resources[#entry.defenderUnit.resources + 1] = createdEntry
    healthContext.existingEntry = createdEntry
    return createdEntry
end

local function getCachedStatValue(hitContext, unit, statRef)
    local normalizedStatRef = normalizeToken(statRef)
    if type(unit) ~= "table" or not normalizedStatRef then
        return 0
    end

    if type(hitContext) ~= "table" then
        return tonumber(Combat.GetCachedCombatStatValue and Combat:GetCachedCombatStatValue(nil, unit, normalizedStatRef, 0) or 0) or 0
    end

    hitContext.statValueCache = hitContext.statValueCache or {}
    local unitCache = hitContext.statValueCache[unit]
    if type(unitCache) ~= "table" then
        unitCache = {}
        hitContext.statValueCache[unit] = unitCache
    end
    if unitCache[normalizedStatRef] ~= nil then
        return tonumber(unitCache[normalizedStatRef]) or 0
    end

    local value = tonumber(Combat.GetCachedCombatStatValue and Combat:GetCachedCombatStatValue(hitContext, unit, normalizedStatRef, 0) or 0) or 0
    unitCache[normalizedStatRef] = value
    return value
end

local function buildDamageSchoolContexts(self, entry, effect, hitContext)
    local schoolContexts = {}
    local schoolNames = {}
    local damageSchoolIcon = nil
    local damageSchoolRefs = effect and effect.damageSchoolRefs or {}
    local defenderLevel = self.GetUnitLevel and self:GetUnitLevel(entry.defenderUnit, entry.eventState) or 1
    local combatRules = type(hitContext) == "table" and hitContext.combatRules or buildCombatRuleSnapshot(self)

    for schoolIndex = 1, #damageSchoolRefs do
        local schoolRef = normalizeToken(damageSchoolRefs[schoolIndex])
        if schoolRef then
            local _, damageSchool = self:ResolveDamageSchoolReference(schoolRef)
            if damageSchool then
                local mitigationStatRef = normalizeToken(damageSchool.mitigationStatRef)
                local mitigationStatValue = mitigationStatRef and getCachedStatValue(hitContext, entry.defenderUnit, mitigationStatRef) or 0
                local mitigation = self:ResolveDamageSchoolMitigation(damageSchool, mitigationStatValue, defenderLevel)
                local schoolName = tostring(damageSchool.name or "")
                if schoolName ~= "" then
                    schoolNames[#schoolNames + 1] = schoolName
                end
                if damageSchoolIcon == nil and tostring(damageSchool.icon or "") ~= "" then
                    damageSchoolIcon = tostring(damageSchool.icon)
                end
                schoolContexts[#schoolContexts + 1] = {
                    schoolRef = schoolRef,
                    definition = damageSchool,
                    name = schoolName,
                    icon = tostring(damageSchool.icon or ""),
                    mitigationStatRef = mitigationStatRef,
                    mitigationStatValue = mitigationStatValue,
                    mitigation = mitigation,
                }
            end
        end
    end

    return schoolContexts, schoolNames, damageSchoolIcon, combatRules
end

local function ensureHitResolutionContext(self, entry)
    if type(entry) ~= "table" then
        return nil
    end

    local hitContext = type(entry.hitResolutionContext) == "table" and entry.hitResolutionContext or {}
    entry.hitResolutionContext = hitContext
    hitContext.combatLookupSnapshot = hitContext.combatLookupSnapshot
        or entry.combatLookupSnapshot
        or (type(entry.context) == "table" and entry.context.combatLookupSnapshot)
        or self:BuildCombatLookupSnapshot(entry.context, entry.eventState, entry.attackerUnit, entry.defenderUnit)
    if hitContext.initialized == true then
        return hitContext
    end

    local effect = type(entry.effect) == "table" and entry.effect or nil
    local component = type(entry.component) == "table" and entry.component or nil
    if type(effect) ~= "table" or type(component) ~= "table" then
        local _, _, resolvedComponent = self:ResolveSpellComponent(entry.spellRef, entry.componentKey)
        component = resolvedComponent
        effect = type(component) == "table" and component.effect or nil
    end

    hitContext.component = component
    hitContext.effect = effect
    hitContext.combatRules = buildCombatRuleSnapshot(self)
    hitContext.weaponContext = buildWeaponContext(
        self,
        entry.context,
        entry.attackerUnit,
        effect,
        entry.attackType or self:ResolveHitCheckAttackType(effect, component)
    )
    hitContext.healthResourceContext = buildHealthResourceContext(self, entry)
    hitContext.rawDamage = tonumber(entry.rawDamage)
    if hitContext.rawDamage == nil and type(effect) == "table" then
        local resolveContext = type(entry.context) == "table" and entry.context or {}
        resolveContext.hitResolutionContext = hitContext
        hitContext.rawDamage = self:ResolveDamageAmount(resolveContext, effect)
        entry.rawDamage = hitContext.rawDamage
    end
    hitContext.schoolContexts, hitContext.schoolNames, hitContext.damageSchoolIcon =
        buildDamageSchoolContexts(self, entry, effect, hitContext)
    hitContext.initialized = true
    return hitContext
end

local function buildSharedHitPreviewEntry(self, context, effect, component, timingParts)
    local eventState = type(context) == "table" and context.eventState or nil
    if type(eventState) ~= "table" or eventState.active ~= true then
        eventState = Client.GetEventState and Client:GetEventState() or nil
    end

    local sessionState = type(context) == "table" and context.sessionState or nil
    if type(sessionState) ~= "table" or sessionState.active ~= true then
        sessionState = Client.GetState and Client:GetState() or nil
    end

    local attackerUnit = type(context) == "table" and (context.attackerUnit or context.casterUnit or context.caster) or nil
    local defenderUnit = type(context) == "table" and (context.defenderUnit or context.targetUnit or context.target) or nil
    local spellRef = type(context) == "table" and normalizeToken(context.spellRef) or nil
    local componentKey = normalizeToken(component and component.key or type(context) == "table" and context.componentKey or nil)
    local eventId = type(context) == "table" and normalizeToken(context.eventId) or nil
    if not eventId then
        eventId = normalizeToken(eventState and eventState.id)
    end

    local defenceSystem = self:ResolveDefenceSystem()
    local attackType = self:ResolveHitCheckAttackType(effect, component)
    if type(attackerUnit) ~= "table" or type(defenderUnit) ~= "table" or not spellRef or not componentKey or not defenceSystem or not eventId then
        return nil
    end

    local combatLookupSnapshot = self:BuildCombatLookupSnapshot(context, eventState, attackerUnit, defenderUnit)
    local baseContext = {
        attackerUnit = attackerUnit,
        casterUnit = attackerUnit,
        defenderUnit = defenderUnit,
        targetUnit = defenderUnit,
        eventState = eventState,
        sessionState = sessionState,
        spellRef = spellRef,
        componentKey = componentKey,
        spell = type(context) == "table" and context.spell or nil,
        eventId = eventId,
        combatLookupSnapshot = combatLookupSnapshot,
    }
    if type(context) == "table" then
        context.combatLookupSnapshot = combatLookupSnapshot
    end

    local weaponSkillStartTime = timingParts and getNowMilliseconds() or nil
    local weaponSkillContext = self:ResolveWeaponSkillContext(baseContext, effect, component)
    if timingParts then
        appendTimingPart(timingParts, "weapon-skill", getNowMilliseconds() - weaponSkillStartTime)
    end

    local modifierStartTime = timingParts and getNowMilliseconds() or nil
    local attackerTotal, attackerRollContext = self:BuildAttackerTotal(baseContext, attackerUnit, defenceSystem, attackType)
    local prePenaltyAttackerTotal = attackerTotal
    local attackModifierContext = self:ResolveAttackModifierContext(attackerUnit, defenceSystem, attackType, weaponSkillContext, baseContext)
    attackerTotal, attackModifierContext.weaponSkillPenaltyValue = self:ApplyWeaponSkillHitPenalty(attackerTotal, defenceSystem, weaponSkillContext)
    attackModifierContext.baseTotal = prePenaltyAttackerTotal
    attackModifierContext.finalTotal = attackerTotal
    attackModifierContext.roll = type(attackerRollContext) == "table" and attackerRollContext.roll or nil
    if type(attackerRollContext) == "table" then
        attackerRollContext.weaponSkillPenaltyValue = attackModifierContext.weaponSkillPenaltyValue
        attackerRollContext.finalTotal = attackerTotal
        attackerRollContext.totalModifierValue = attackModifierContext.totalModifierValue
    end
    if timingParts then
        appendTimingPart(timingParts, "modifier-resolve", getNowMilliseconds() - modifierStartTime)
    end

    local critResultStartTime = timingParts and getNowMilliseconds() or nil
    local critCategory = self:ResolveCritCategory(effect)
    local critStatRef = self:ResolveCritStatRef(defenceSystem, critCategory)
    local baseCritChance = tonumber(self:ResolveBaseCritChance(critCategory)) or 0
    local critContext = type(context) == "table" and context or {}
    critContext.combatLookupSnapshot = combatLookupSnapshot
    critContext.critResolutionContext = {
        baseCritChance = baseCritChance,
        statRef = critStatRef,
    }
    local resultType, critRoll = self:ResolveEffectResultType(critContext, effect, attackerUnit, defenceSystem, weaponSkillContext)
    if timingParts then
        appendTimingPart(timingParts, "crit-result", getNowMilliseconds() - critResultStartTime)
    end

    local entry = {
        eventId = eventId,
        spellRef = spellRef,
        componentKey = componentKey,
        attackType = attackType,
        defenceSystem = defenceSystem,
        attackerUnit = attackerUnit,
        defenderUnit = defenderUnit,
        attackerEventId = tonumber(attackerUnit.eventID) or 0,
        defenderEventId = tonumber(defenderUnit.eventID) or 0,
        turnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1)),
        attackerTotal = attackerTotal,
        rawDamage = nil,
        resultType = resultType,
        effect = effect,
        component = component,
        weaponSkillContext = weaponSkillContext,
        attackerRollContext = attackerRollContext,
        attackModifierContext = attackModifierContext,
        combatLookupSnapshot = combatLookupSnapshot,
        targetEvents = Combat:CloneValue(effect and effect.targetEvents or {}),
        context = type(context) == "table" and context or baseContext,
        sessionState = sessionState,
        eventState = eventState,
        sharedHitPreview = {
            critCategory = critCategory,
            critStatRef = critStatRef,
            baseCritChance = baseCritChance,
            critRoll = critRoll,
        },
    }

    local reactionActionsStartTime = timingParts and getNowMilliseconds() or nil
    if defenderUnit.isPlayer == true and type(self.BuildReactionActions) == "function" then
        entry.sharedHitPreview.reactionActions = self:BuildReactionActions(entry)
    end
    if timingParts then
        appendTimingPart(timingParts, "reaction-actions", getNowMilliseconds() - reactionActionsStartTime)
    end

    local damagePreviewStartTime = timingParts and getNowMilliseconds() or nil
    entry.hitResolutionContext = ensureHitResolutionContext(self, entry)
    entry.rawDamage = tonumber(type(entry.hitResolutionContext) == "table" and entry.hitResolutionContext.rawDamage) or 0
    local _, preview = buildResolvedDamageResult(self, entry)
    if type(preview) == "table" then
        entry.damagePreview = preview
        entry.sharedHitPreview.damagePreview = preview
    end
    if timingParts then
        appendTimingPart(timingParts, "damage-preview", getNowMilliseconds() - damagePreviewStartTime)
    end

    return entry
end

function Combat:GetCombatRule(ruleKey, fallback)
    return self:GetRuleValue("combat", ruleKey, fallback)
end

function Combat:RollDiceExpression(context, expression)
    return Dice.RollExpression and Dice.RollExpression(context, expression, 1, 20) or 0
end

function Combat:ResolveHitCheckAttackType(effect, component)
    local rawValue = type(effect) == "table" and effect.damageType or nil
    if rawValue == nil and type(component) == "table" and type(component.effect) == "table" then
        rawValue = component.effect.damageType
    end
    if rawValue == nil and type(component) == "table" then
        rawValue = component.damageType
    end

    local attackType = string.lower(trimText(rawValue or "spell"))
    if attackType ~= "melee" and attackType ~= "ranged" then
        attackType = "spell"
    end

    return attackType
end

function Combat:ResolveDefenceSystem()
    local defenceSystem = string.lower(trimText(self:GetCombatRule("defence_system", "ac") or "ac"))
    if defenceSystem == "ac" or defenceSystem == "simple" or defenceSystem == "complex" or defenceSystem == "percent" then
        return defenceSystem
    end

    return nil
end

function Combat:ResolveComplexDefenceStats(attackType)
    return splitList(self:GetCombatRule(("complex_defence_stats_%s"):format(attackType or "spell"), {}))
end

function Combat:ResolveAttackStatRef(defenceSystem, attackType)
    if defenceSystem == "percent" then
        return normalizeToken(self:GetCombatRule(("percent_%s_hit_stat"):format(attackType or "spell"), ""))
    end

    return normalizeToken(self:GetCombatRule("simple_attack_stat", ""))
end

function Combat:ResolveDefenceStatRef(defenceSystem, attackType)
    if defenceSystem == "ac" then
        return normalizeToken(self:GetCombatRule("armor_class_stat", ""))
    end
    if defenceSystem == "simple" then
        return normalizeToken(self:GetCombatRule("simple_defence_stat", ""))
    end
    if defenceSystem == "percent" then
        return normalizeToken(self:GetCombatRule(("percent_%s_resistance_stat"):format(attackType or "spell"), ""))
    end

    return nil
end

function Combat:ResolvePercentResistanceStatRefs(attackType)
    return splitList(self:GetCombatRule(("percent_%s_resistance_stat"):format(attackType or "spell"), {}))
end

function Combat:SumStatValues(unit, statRefs, context)
    local total = 0
    for index = 1, #(statRefs or {}) do
        local statRef = normalizeToken(statRefs[index])
        if statRef then
            total = total + (self.GetCachedCombatStatValue and self:GetCachedCombatStatValue(context, unit, statRef, 0) or 0)
        end
    end

    return total
end

function Combat:ResolveSpellComponent(spellRef, componentKey)
    if type(Registry.ResolveSpellReference) ~= "function" then
        return nil, nil, nil
    end

    local dataset, spell = Registry:ResolveSpellReference(spellRef)
    if not dataset or not spell then
        return nil, nil, nil
    end

    local normalizedComponentKey = normalizeToken(componentKey)
    if not normalizedComponentKey then
        return dataset, spell, nil
    end

    for index = 1, #(spell.components or {}) do
        local component = spell.components[index]
        if normalizeToken(component and component.key) == normalizedComponentKey then
            return dataset, spell, component
        end
    end

    return dataset, spell, nil
end

function Combat:ResolveDamageAmount(context, effect)
    local attackerUnit = type(context) == "table" and (context.attackerUnit or context.casterUnit or context.caster) or nil
    local hitResolutionContext = type(context) == "table" and context.hitResolutionContext or nil
    local baseDamage = tonumber(effect and effect.baseDamage) or 0
    local statScaling = 0
    local weaponDamage = 0
    local weaponContext = type(hitResolutionContext) == "table" and hitResolutionContext.weaponContext or nil
    local weaponDamageCoefficient = tonumber(weaponContext and weaponContext.weaponDamageCoefficient) or tonumber(effect and effect.weaponDamageCoefficient) or 1
    if type(weaponContext) ~= "table" then
        weaponContext = buildWeaponContext(self, context, attackerUnit, effect, self:ResolveHitCheckAttackType(effect))
        if type(hitResolutionContext) == "table" then
            hitResolutionContext.weaponContext = weaponContext
        end
    end
    weaponDamage = tonumber(weaponContext and weaponContext.totalDamage) or 0

    for index = 1, #(effect and effect.statScaling or {}) do
        local entry = effect.statScaling[index]
        if type(entry) == "table" then
            local statRef = normalizeToken(entry.statRef)
            if statRef then
                local statValue = getCachedStatValue(hitResolutionContext, attackerUnit, statRef)
                local coefficient = tonumber(entry.coefficient) or 0
                statScaling = statScaling + (statValue * coefficient)
            end
        end
    end

    local variance = Dice.RollVariance and Dice.RollVariance(context) or 1
    return math.max(0, Common.Round((baseDamage + (weaponDamage * weaponDamageCoefficient) + statScaling) * variance))
end

buildResolvedDamageResult = function(self, entry)
    if type(entry) ~= "table" or type(entry.defenderUnit) ~= "table" then
        return false, nil
    end

    local hitContext = ensureHitResolutionContext(self, entry)
    if type(hitContext) ~= "table" then
        return false, nil
    end
    if type(hitContext.resolvedResult) == "table" then
        return true, hitContext.resolvedResult
    end

    local rawDamage = math.max(0, tonumber(hitContext.rawDamage) or tonumber(entry.rawDamage) or 0)
    local resultType = normalizeToken(entry.resultType) or "hit"
    local result = {
        resultType = resultType,
        wasCritical = resultType == "critical" or resultType == "crushing",
        rawDamage = rawDamage,
        preAbsorbAmount = 0,
        absorbedAmount = 0,
        absorptionChanges = {},
        amount = 0,
        mitigated = 0,
        applied = false,
        resourceEntry = nil,
        healthResourceRef = nil,
        hitType = nil,
        appliedDelta = 0,
        resourceDeltas = {},
        damageSchoolName = "",
        damageSchoolIcon = nil,
        threatGenerated = 0,
        threatApplied = false,
        threatSourceEventId = 0,
        threatTargetEventId = 0,
        threatTotal = 0,
        threatUpdate = nil,
        threatCommitted = false,
        critMitigationStatRef = nil,
        critMitigationStatValue = 0,
        critMitigation = nil,
        critMitigated = 0,
    }
    if rawDamage <= 0 then
        return false, result
    end

    local effect = hitContext.effect
    local component = hitContext.component
    if type(effect) ~= "table" then
        return false, result
    end
    result.hitType = normalizeToken(effect.hitType) or "ability"

    local scaledRawDamage = rawDamage
    local combatRules = type(hitContext.combatRules) == "table" and hitContext.combatRules or buildCombatRuleSnapshot(self)
    local defenderLevel = self.GetUnitLevel and self:GetUnitLevel(entry.defenderUnit, entry.eventState) or 1
    if resultType == "crushing" then
        scaledRawDamage = scaledRawDamage * combatRules.crushingDamageMultiplier
    elseif resultType == "critical" then
        scaledRawDamage = scaledRawDamage * combatRules.criticalDamageMultiplier
    end
    local finalDamage = scaledRawDamage
    for schoolIndex = 1, #(hitContext.schoolContexts or {}) do
        local schoolContext = hitContext.schoolContexts[schoolIndex]
        if result.damageSchoolIcon == nil and tostring(schoolContext and schoolContext.icon or "") ~= "" then
            result.damageSchoolIcon = tostring(schoolContext.icon)
        end
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
        getCachedStatValue(hitContext, entry.attackerUnit, combatRules.damageDealtStat),
        false
    )

    if entry.attackType == "spell" then
        local creatureTypeDamageStatRef = resolveSpellDamageCreatureTypeStatRef(combatRules, entry.defenderUnit)
        if creatureTypeDamageStatRef then
            finalDamage = applyPercentModifier(
                finalDamage,
                getCachedStatValue(hitContext, entry.attackerUnit, creatureTypeDamageStatRef),
                false
            )
        end
    end

    local reductionStatRef = combatRules.damageReductionStat
    if reductionStatRef then
        local reductionValue = getCachedStatValue(hitContext, entry.defenderUnit, reductionStatRef)
        finalDamage = applyPercentModifier(finalDamage, reductionValue, true)
    end

    if result.wasCritical then
        local critMitigationStatRef = combatRules.criticalDamageMitigationStat
        local critMitigationStatValue = critMitigationStatRef and getCachedStatValue(hitContext, entry.defenderUnit, critMitigationStatRef) or 0
        local critMitigation = self:ResolveCriticalDamageMitigation(combatRules, critMitigationStatValue, defenderLevel)
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

    finalDamage = math.max(0, Common.Round(finalDamage))
    scaledRawDamage = math.max(0, Common.Round(scaledRawDamage))
    result.preAbsorbAmount = finalDamage
    result.amount = finalDamage
    result.mitigated = math.max(0, scaledRawDamage - finalDamage)
    result.mitigationPercent = scaledRawDamage > 0 and ((result.mitigated / scaledRawDamage) * 100) or 0
    result.damageSchoolName = table.concat(hitContext.schoolNames or {}, ", ")
    if result.damageSchoolName == "" then
        result.damageSchoolName = "True"
    end

    -- Absorption is previewed after all mitigation and final rounding. The
    -- preview is deliberately pure; authoritative state is committed only by
    -- ApplyResolvedDamage once the hit can be finalized.
    local auraManager = getAuraManager()
    if finalDamage > 0
        and auraManager
        and type(auraManager.PreviewAbsorption) == "function"
    then
        local absorptionPreview = auraManager:PreviewAbsorption(
            Client,
            entry.eventState,
            entry.defenderEventId or (entry.defenderUnit and entry.defenderUnit.eventID),
            finalDamage,
            effect.damageSchoolRefs or {}
        )
        if type(absorptionPreview) == "table" then
            result.absorbedAmount = math.max(0, tonumber(absorptionPreview.absorbedAmount or absorptionPreview.absorbed) or 0)
            result.absorptionChanges = absorptionPreview.changes or absorptionPreview.plan or {}
            result.amount = math.max(0, tonumber(absorptionPreview.remainingDamage or absorptionPreview.healthRemainder) or finalDamage)
        end
    end

    if entry.defenderUnit.isPlayer ~= true and tonumber(result.amount) > 0 then
        local attackerEventId = math.floor(tonumber(entry.attackerEventId or (entry.attackerUnit and entry.attackerUnit.eventID)) or 0)
        local defenderEventId = math.floor(tonumber(entry.defenderEventId or (entry.defenderUnit and entry.defenderUnit.eventID)) or 0)
        local threatCoefficient = tonumber(effect.threatCoefficient) or 1
        local threatAmount = math.max(0, Common.Round(tonumber(result.amount) * threatCoefficient))
        threatAmount = math.max(0, Common.Round(applyPercentModifier(
            threatAmount,
            getCachedStatValue(hitContext, entry.attackerUnit, combatRules.threatGeneratedStat),
            false
        )))
        result.threatGenerated = threatAmount
        result.threatSourceEventId = attackerEventId
        result.threatTargetEventId = defenderEventId
        result.threatTotal = getThreatForUnit(entry.defenderUnit, attackerEventId) + threatAmount
        result.threatUpdate = buildThreatUpdatePayload(entry.defenderUnit, entry.attackerUnit, threatAmount)
    end

    hitContext.resolvedResult = result
    return true, result
end

function Combat:BuildDamagePreview(entry)
    if type(entry) ~= "table" then
        return nil
    end
    local hitContext = ensureHitResolutionContext(self, entry)
    if type(entry.damagePreview) == "table" then
        return entry.damagePreview
    end
    if type(hitContext) == "table" and type(hitContext.resolvedResult) == "table" then
        entry.damagePreview = hitContext.resolvedResult
        return entry.damagePreview
    end

    local _, result = buildResolvedDamageResult(self, entry)
    if type(result) == "table" then
        entry.damagePreview = result
    end
    return result
end

function Combat:ApplyResolvedDamage(entry, previewOnly)
    if previewOnly ~= true and type(entry) == "table" and type(entry.authoritativeDamageResult) == "table" then
        return true, entry.authoritativeDamageResult
    end

    local computed, result = buildResolvedDamageResult(self, entry)
    if not computed or type(result) ~= "table" then
        return false, result
    end
    local finalDamage = math.max(0, tonumber(result.amount) or 0)
    local hitContext = ensureHitResolutionContext(self, entry)
    local healthResourceRef = type(hitContext) == "table"
        and type(hitContext.healthResourceContext) == "table"
        and normalizeToken(hitContext.healthResourceContext.healthResourceRef)
        or nil
    result.healthResourceRef = healthResourceRef
    local absorbedAmount = math.max(0, tonumber(result.absorbedAmount) or 0)
    local preAbsorbAmount = math.max(0, tonumber(result.preAbsorbAmount) or 0)
    if preAbsorbAmount > 0 and absorbedAmount > 0 then
        -- The resource delta must always be the post-absorption remainder. A
        -- damage preview may be cached before application, but shield capacity
        -- consumption cannot turn a partially absorbed hit into a full absorb.
        absorbedAmount = math.min(preAbsorbAmount, absorbedAmount)
        finalDamage = math.max(0, preAbsorbAmount - absorbedAmount)
        result.absorbedAmount = absorbedAmount
        result.amount = finalDamage
    end
    local hasHealthDamage = healthResourceRef ~= nil and finalDamage > 0
    if not hasHealthDamage and absorbedAmount <= 0 then
        return false, result
    end

    if hasHealthDamage then
        local resourceUnit = entry.defenderUnit
        if previewOnly == true then
            resourceUnit = self:CloneValue(entry.defenderUnit)
            local previewHitContext = {
                healthResourceContext = self:CloneValue(hitContext.healthResourceContext),
            }
            ensureHealthResourceEntry({
                context = entry.context,
                defenderUnit = resourceUnit,
                eventState = entry.eventState,
            }, previewHitContext)
        else
            ensureHealthResourceEntry(entry, hitContext)
        end

        -- Damage results are always previewed locally and become authoritative only once
        -- the corresponding RESOURCE_DELTA message is handled back through the client.
        local applied, resourceEntry, appliedDelta = self:PreviewResourceDelta(resourceUnit, healthResourceRef, -finalDamage)
        result.applied = applied
        result.resourceEntry = resourceEntry
        result.appliedDelta = appliedDelta
        if applied and resourceEntry then
            result.resourceDeltas = {
                {
                    resourceRef = healthResourceRef,
                    delta = appliedDelta,
                    maxValue = tonumber(resourceEntry.maxValue) or 0,
                    currentValue = tonumber(resourceEntry.currentValue) or 0,
                },
            }
        end
        if not applied then
            return false, result
        end
    else
        -- A fully absorbed hit is still a landed hit, but it must not invent a
        -- zero-valued health RESOURCE_DELTA.
        result.applied = true
        result.appliedDelta = 0
    end

    if previewOnly ~= true then
        local auraManager = getAuraManager()
        local absorptionChanges = result.absorptionChanges
        if type(absorptionChanges) == "table" and #absorptionChanges > 0 then
            local commitResult = type(entry) == "table" and entry.absorptionCommitResult or nil
            if type(commitResult) ~= "table" then
                local context = type(entry.context) == "table" and entry.context or {}
                local sessionState = context.sessionState
                    or (Client.GetState and Client:GetState() or nil)
                local commitOk, committed = false, nil
                if auraManager and type(auraManager.CommitAbsorptionChanges) == "function" then
                    commitOk, committed = auraManager:CommitAbsorptionChanges(
                        Client,
                        entry.eventState,
                        entry.defenderEventId or (entry.defenderUnit and entry.defenderUnit.eventID),
                        absorptionChanges,
                        {
                            removeDepletedAbsorbAuras = true,
                            context = {
                                sessionState = sessionState,
                                eventState = entry.eventState,
                                pendingScope = context.pendingScope,
                                immediate = context.immediate == true,
                            },
                        }
                    )
                end
                if not commitOk then
                    return false, result
                end
                commitResult = committed
                entry.absorptionCommitResult = commitResult
            end
            result.absorptionChanges = commitResult.changes or absorptionChanges
            result.absorbedAmount = tonumber(commitResult.absorbedAmount or commitResult.absorbed) or absorbedAmount
        end
        commitResolvedDamageThreat(entry, result)
        entry.authoritativeDamageResult = result
    end

    return true, result
end

function Combat:BuildAttackerTotal(context, attackerUnit, defenceSystem, attackType)
    local statRef = self:ResolveAttackStatRef(defenceSystem, attackType)
    local statValue = statRef and (self.GetCachedCombatStatValue and self:GetCachedCombatStatValue(context, attackerUnit, statRef, 0) or 0) or 0
    local statContribution = {
        statRef = statRef,
        statValue = Common.Round(tonumber(statValue) or 0),
    }
    if defenceSystem == "percent" then
        local roll = Dice.RollRandom and tonumber(Dice.RollRandom(context, 1, 100)) or 0
        local total = Common.Round(roll + (tonumber(statContribution.statValue) or 0))
        return total, {
            roll = roll,
            statRef = statContribution.statRef,
            statValue = statContribution.statValue,
            baseTotal = total,
        }
    end

    local roll = self:RollDiceExpression(context, self:GetCombatRule("attack_roll_dice", DEFAULT_ATTACK_ROLL_DICE))
    local total = Common.Round(roll + (tonumber(statContribution.statValue) or 0))
    return total, {
        roll = roll,
        statRef = statContribution.statRef,
        statValue = statContribution.statValue,
        baseTotal = total,
    }
end

function Combat:ResolveHitCheckOutcome(entry, action)
    if type(entry) ~= "table" then
        return nil, nil
    end

    local actionId = type(action) == "table" and action.id or action
    if normalizeResultToken(actionId) == RESULT_PASS then
        return RESULT_PASS, {
            attackerTotal = tonumber(entry.attackerTotal) or 0,
            defenceSystem = RESULT_PASS,
        }
    end

    local resolvedSystem = type(action) == "table" and tostring(action.resolutionSystem or entry.defenceSystem or "") or tostring(entry.defenceSystem or "")
    if resolvedSystem ~= "ac" and resolvedSystem ~= "simple" and resolvedSystem ~= "complex" and resolvedSystem ~= "percent" then
        resolvedSystem = tostring(entry.defenceSystem or "")
    end

    local attackerTotal = tonumber(entry.attackerTotal) or 0
    if resolvedSystem == "ac" then
        local armorClassStat = self:ResolveDefenceStatRef("ac", entry.attackType)
        local armorClass = armorClassStat and (self.GetCachedCombatStatValue and self:GetCachedCombatStatValue(entry.context, entry.defenderUnit, armorClassStat, 0) or 0) or 0
        return attackerTotal > armorClass and RESULT_PASS or RESULT_FAIL, {
            attackerTotal = attackerTotal,
            defenderTotal = armorClass,
            defenceStatRef = armorClassStat,
            defenceSystem = "ac",
        }
    end

    if resolvedSystem == "simple" then
        local defenceStatRef = self:ResolveDefenceStatRef("simple", entry.attackType)
        local roll = self:RollDiceExpression(entry.context, self:GetCombatRule("defence_roll_dice", DEFAULT_DEFENCE_ROLL_DICE))
        local defenceValue = defenceStatRef and (self.GetCachedCombatStatValue and self:GetCachedCombatStatValue(entry.context, entry.defenderUnit, defenceStatRef, 0) or 0) or 0
        local defenderTotal = roll + defenceValue
        return attackerTotal > defenderTotal and RESULT_PASS or RESULT_FAIL, {
            attackerTotal = attackerTotal,
            defenderTotal = defenderTotal,
            defenceStatRef = defenceStatRef,
            defenceSystem = "simple",
        }
    end

    if resolvedSystem == "complex" then
        local defenceStatRef = normalizeToken(type(action) == "table" and action.statRef or actionId)
        local roll = self:RollDiceExpression(entry.context, self:GetCombatRule("defence_roll_dice", DEFAULT_DEFENCE_ROLL_DICE))
        local defenceValue = defenceStatRef and (self.GetCachedCombatStatValue and self:GetCachedCombatStatValue(entry.context, entry.defenderUnit, defenceStatRef, 0) or 0) or 0
        local defenderTotal = roll + defenceValue
        return attackerTotal > defenderTotal and RESULT_PASS or RESULT_FAIL, {
            attackerTotal = attackerTotal,
            defenderTotal = defenderTotal,
            defenceStatRef = defenceStatRef,
            defenceSystem = "complex",
        }
    end

    if resolvedSystem == "percent" then
        local chosenResistanceStats = nil
        local chosenDefenceStatRef = type(action) == "table" and normalizeToken(action.statRef) or nil
        if chosenDefenceStatRef then
            chosenResistanceStats = { chosenDefenceStatRef }
        else
            chosenResistanceStats = self:ResolvePercentResistanceStatRefs(entry.attackType)
        end

        local resistanceValue = self:SumStatValues(entry.defenderUnit, chosenResistanceStats, entry.context)
        local basePenalty = tonumber(self:GetCombatRule("percent_base_penalty", 0)) or 0
        local defenderThreshold = Common.Round(basePenalty + resistanceValue)
        return attackerTotal > defenderThreshold and RESULT_PASS or RESULT_FAIL, {
            attackerTotal = attackerTotal,
            defenderTotal = defenderThreshold,
            resistanceTotal = resistanceValue,
            basePenalty = basePenalty,
            defenceStatRef = chosenDefenceStatRef,
            defenceSystem = "percent",
        }
    end

    return nil, nil
end

function Combat:BuildHitCheckEntry(context, effect, component)
    local entry = buildSharedHitPreviewEntry(self, context, effect, component, nil)
    if type(entry) ~= "table" then
        return nil
    end
    local eventId = entry.eventId
    self.PendingHitCheckCounter = (self.PendingHitCheckCounter or 0) + 1
    entry.checkId = ("%s:%d"):format(eventId, self.PendingHitCheckCounter)
    return entry
end

function Combat:BuildHitPreviewEntry(context, effect, component, timingParts)
    return buildSharedHitPreviewEntry(self, context, effect, component, timingParts)
end

function Combat:BeginHitCheck(context, effect, component)
    local timingEnabled = isSpellcastTimingEnabled()
    local totalStartTime = timingEnabled and getNowMilliseconds() or nil
    local profilerStartTime = timingEnabled and getProfilerMilliseconds() or nil
    local timingParts = timingEnabled and {} or nil
    local entry = nil
    if timingEnabled then
        local buildStartTime = getNowMilliseconds()
        entry = self:BuildHitPreviewEntry(context, effect, component, timingParts)
        appendTimingPart(timingParts, "build-entry", getNowMilliseconds() - buildStartTime)
        if type(entry) == "table" then
            self.PendingHitCheckCounter = (self.PendingHitCheckCounter or 0) + 1
            entry.checkId = ("%s:%d"):format(tostring(entry.eventId or "event"), self.PendingHitCheckCounter)
        end
    else
        entry = self:BuildHitCheckEntry(context, effect, component)
    end
    if not entry or entry.attackerEventId <= 0 or entry.defenderEventId <= 0 then
        if timingEnabled then
            if profilerStartTime ~= nil then
                appendTimingPart(timingParts, "profiler-total", getProfilerMilliseconds() - profilerStartTime, SPELLCAST_SLOW_TOTAL_MS)
            end
            logDamageTimingLine(
                ("%s/%s invalid"):format(
                    tostring(type(context) == "table" and context.spellRef or "spell"),
                    tostring(type(component) == "table" and component.key or "component")
                ),
                timingParts,
                getNowMilliseconds() - totalStartTime,
                SPELLCAST_SLOW_TOTAL_MS
            )
        end
        return false, buildCombatResult(entry, nil, "invalid")
    end

    local auraManager = getAuraManager()
    if auraManager
        and type(auraManager.ShouldForceAutoHitAgainstTarget) == "function"
        and auraManager:ShouldForceAutoHitAgainstTarget(entry.eventState, entry.defenderEventId) == true
    then
        local forcedHitStartTime = timingEnabled and getNowMilliseconds() or nil
        local completed, result = Combat:CompleteHitCheck(entry, RESULT_PASS, "forced-hit")
        if completed and type(Combat.RecordResolvedCombatAttackHistory) == "function" then
            Combat:RecordResolvedCombatAttackHistory(Client, entry, RESULT_PASS, RESULT_PASS, nil)
        end
        if completed and type(Combat.ApplyResolvedDamage) == "function" then
            local _, damageResult = self:ApplyResolvedDamage(entry)
            entry.lastDamageResult = damageResult
            if type(self.FinalizeLocalDamageResult) == "function" then
                self:FinalizeLocalDamageResult(entry, damageResult)
            end
        end
        if timingEnabled then
            appendTimingPart(timingParts, "forced-hit", getNowMilliseconds() - forcedHitStartTime)
            if profilerStartTime ~= nil then
                appendTimingPart(timingParts, "profiler-total", getProfilerMilliseconds() - profilerStartTime, SPELLCAST_SLOW_TOTAL_MS)
            end
            logDamageTimingLine(
                ("%s/%s forced-hit"):format(tostring(entry.spellRef or "spell"), tostring(entry.componentKey or "component")),
                timingParts,
                getNowMilliseconds() - totalStartTime,
                SPELLCAST_SLOW_TOTAL_MS
            )
        end
        return completed, result
    end

    local pendingStartTime = timingEnabled and getNowMilliseconds() or nil
    Client:SetPendingCombatHitCheck(entry)
    if timingEnabled then
        appendTimingPart(timingParts, "set-pending", getNowMilliseconds() - pendingStartTime)
    end

    if entry.defenderUnit.isPlayer ~= true then
        local autoResolveStartTime = timingEnabled and getNowMilliseconds() or nil
        local resolveOutcomeStartTime = timingEnabled and getNowMilliseconds() or nil
        local actionId = Combat.ChooseAutomaticReactionAction and Combat:ChooseAutomaticReactionAction(entry) or RESULT_PASS
        local action = actionId
        if type(action) ~= "table" and normalizeResultToken(action) ~= RESULT_PASS then
            action = Combat.FindReactionAction and Combat:FindReactionAction(entry, action) or nil
        end
        if type(action) ~= "table" then
            action = RESULT_PASS
        elseif action.enabled == false then
            action = RESULT_PASS
        end

        local resultToken, resolution = self:ResolveHitCheckOutcome(entry, action)
        entry.lastResolution = resolution
        if type(Combat.LogDefenceAttempt) == "function" then
            Combat:LogDefenceAttempt(entry, resultToken, resolution)
        end
        if timingEnabled then
            appendTimingPart(timingParts, "resolve-outcome", getNowMilliseconds() - resolveOutcomeStartTime)
        end
        local completed, result = false, nil
        if type(Combat.CompleteHitCheck) == "function" then
            completed, result = Combat:CompleteHitCheck(entry, resultToken, "npc-local")
        end
        if completed and type(Combat.RecordResolvedCombatAttackHistory) == "function" then
            Combat:RecordResolvedCombatAttackHistory(Client, entry, resultToken, action, resolution)
        end
        if completed and resultToken == RESULT_PASS then
            local applyDamageStartTime = timingEnabled and getNowMilliseconds() or nil
            local _, damageResult = self:ApplyResolvedDamage(entry)
            entry.lastDamageResult = damageResult
            if timingEnabled then
                appendTimingPart(timingParts, "apply-damage", getNowMilliseconds() - applyDamageStartTime)
            end
            if type(self.FinalizeLocalDamageResult) == "function" then
                local finalizeDamageStartTime = timingEnabled and getNowMilliseconds() or nil
                self:FinalizeLocalDamageResult(entry, damageResult)
                if timingEnabled then
                    appendTimingPart(timingParts, "finalize-damage", getNowMilliseconds() - finalizeDamageStartTime)
                end
            end
        elseif completed and resultToken == RESULT_FAIL then
            if type(Combat.CompleteActionDamageResolution) == "function" then
                Combat:CompleteActionDamageResolution(Client, entry, false)
            end
            if type(self.ShowMissCombatText) == "function" then
                self:ShowMissCombatText(entry)
            end
        end
        if timingEnabled then
            appendTimingPart(timingParts, "npc-local", getNowMilliseconds() - autoResolveStartTime)
            if profilerStartTime ~= nil then
                appendTimingPart(timingParts, "profiler-total", getProfilerMilliseconds() - profilerStartTime, SPELLCAST_SLOW_TOTAL_MS)
            end
            logDamageTimingLine(
                ("%s/%s npc-local"):format(tostring(entry.spellRef or "spell"), tostring(entry.componentKey or "component")),
                timingParts,
                getNowMilliseconds() - totalStartTime,
                SPELLCAST_SLOW_TOTAL_MS
            )
        end
        return completed, result
    end

    local localEventUnit = Client.ResolveLocalEventUnit and Client:ResolveLocalEventUnit(entry.eventState) or nil
    if tonumber(localEventUnit and localEventUnit.eventID) == entry.defenderEventId then
        entry.localOnly = true
        local scheduleReactionStartTime = timingEnabled and getNowMilliseconds() or nil
        enqueueDamagePresentationWork(showCombatReactionDeferred, Client, entry)
        if timingEnabled then
            appendTimingPart(timingParts, "schedule-reaction", getNowMilliseconds() - scheduleReactionStartTime)
        end
        local pendingResult = buildCombatResult(entry, nil, "pending")
        pendingResult.resultType = entry.resultType or pendingResult.resultType
        if timingEnabled then
            appendTimingPart(timingParts, "return-pending", getNowMilliseconds() - totalStartTime, SPELLCAST_SLOW_HELPER_MS)
            if profilerStartTime ~= nil then
                appendTimingPart(timingParts, "profiler-total", getProfilerMilliseconds() - profilerStartTime, SPELLCAST_SLOW_TOTAL_MS)
            end
            logDamageTimingLine(
                ("%s/%s local-reaction"):format(tostring(entry.spellRef or "spell"), tostring(entry.componentKey or "component")),
                timingParts,
                getNowMilliseconds() - totalStartTime,
                SPELLCAST_SLOW_TOTAL_MS
            )
        end
        return true, pendingResult
    end

    local defenderName = Combat.ResolveSenderForUnit and Combat:ResolveSenderForUnit(entry.eventState, entry.defenderUnit) or ""
    local sendStartTime = timingEnabled and getNowMilliseconds() or nil
    if defenderName == "" or not Combat.SendCombatWhisper or not Combat:SendCombatWhisper(defenderName, HIT_CHECK_REQUEST_OPCODE, {
        entry.checkId,
        entry.eventId,
        entry.attackerEventId,
        entry.defenderEventId,
        entry.spellRef,
        entry.componentKey,
        entry.attackerTotal,
        entry.rawDamage,
        entry.resultType,
    }) then
        if Client.ClearPendingCombatHitCheck then
            Client:ClearPendingCombatHitCheck(entry.checkId)
        end
        if timingEnabled then
            appendTimingPart(timingParts, "send-request", getNowMilliseconds() - sendStartTime)
            if profilerStartTime ~= nil then
                appendTimingPart(timingParts, "profiler-total", getProfilerMilliseconds() - profilerStartTime, SPELLCAST_SLOW_TOTAL_MS)
            end
            logDamageTimingLine(
                ("%s/%s send-failed"):format(tostring(entry.spellRef or "spell"), tostring(entry.componentKey or "component")),
                timingParts,
                getNowMilliseconds() - totalStartTime,
                SPELLCAST_SLOW_TOTAL_MS
            )
        end
        return false, buildCombatResult(entry, nil, "send_failed")
    end
    if timingEnabled then
        appendTimingPart(timingParts, "send-request", getNowMilliseconds() - sendStartTime)
        if profilerStartTime ~= nil then
            appendTimingPart(timingParts, "profiler-total", getProfilerMilliseconds() - profilerStartTime, SPELLCAST_SLOW_TOTAL_MS)
        end
        logDamageTimingLine(
            ("%s/%s remote-request"):format(tostring(entry.spellRef or "spell"), tostring(entry.componentKey or "component")),
            timingParts,
            getNowMilliseconds() - totalStartTime,
            SPELLCAST_SLOW_TOTAL_MS
        )
    end

    local pendingResult = buildCombatResult(entry, nil, "pending")
    pendingResult.resultType = entry.resultType or pendingResult.resultType
    return true, pendingResult
end

function Combat:ExecuteDamageEffect(context, effect, component)
    return self:BeginHitCheck(context, effect, component)
end

local DamageEffect = Combat:CreateEffectContract({
    type = "damage",
    label = "Damage",
    description = "Deals damage to a target.",
    defaults = {
        type = "damage",
        baseDamage = 0,
        threatCoefficient = 1,
        weaponDamageMode = "none",
        weaponDamageCoefficient = 1,
        statScaling = {},
        damageSchoolRefs = {},
        hitType = "ability",
        damageType = "spell",
        alwaysHits = false,
        usesProjectile = false,
        projectilePath = "",
        projectileSpeed = 0,
        applyAura = false,
        auraRef = nil,
        auraStacks = 1,
        targetEvents = {},
    },
    fields = {
        "baseDamage",
        "threatCoefficient",
        "weaponDamageMode",
        "weaponDamageCoefficient",
        "statScaling",
        "damageSchoolRefs",
        "hitType",
        "damageType",
        "alwaysHits",
        "usesProjectile",
        "projectilePath",
        "projectileSpeed",
        "applyAura",
        "auraRef",
        "auraStacks",
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteDamageEffect(context, effect or self.defaults, component)
    end,
})

return DamageEffect
