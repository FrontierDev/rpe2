local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Combat = Addon.Client.Combat or {}

local Client = Addon.Client
local Combat = Addon.Client.Combat
local Ruleset = Addon.Internal and Addon.Internal.Ruleset or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Normalization = Combat.Normalization or {}
local normalizeToken = Normalization.NormalizeToken or function(value)
    local text = tostring(value or "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text ~= "" and text or nil
end

local baseBuildHitCheckEntry = Combat.BuildHitCheckEntry
local baseBuildHitPreviewEntry = Combat.BuildHitPreviewEntry

if type(baseBuildHitCheckEntry) ~= "function" or type(baseBuildHitPreviewEntry) ~= "function" then
    return true
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

local function resolveEventState(context)
    local state = type(context) == "table" and context.eventState or nil
    if type(state) ~= "table" or state.active ~= true then
        state = type(Client.GetEventState) == "function" and Client:GetEventState() or nil
    end
    return state
end

local function resolveSessionState(context)
    local state = type(context) == "table" and context.sessionState or nil
    if type(state) ~= "table" or state.active ~= true then
        state = type(Client.GetState) == "function" and Client:GetState() or nil
    end
    return state
end

local function resolveCombatUnits(context)
    if type(context) ~= "table" then
        return nil, nil
    end
    return context.attackerUnit or context.casterUnit or context.caster,
        context.defenderUnit or context.targetUnit or context.target
end

local function isPlayerDefenderContext(context)
    local _, defenderUnit = resolveCombatUnits(context)
    return type(defenderUnit) == "table" and defenderUnit.isPlayer == true
end

local function cloneValue(value)
    if type(Combat.CloneValue) == "function" then
        return Combat:CloneValue(value)
    end
    return value
end

local function applyNpcDifficultyHitBonus(entry)
    if type(entry) ~= "table" or type(entry.attackerUnit) ~= "table" or entry.attackerUnit.isPlayer == true then
        return entry
    end

    local eventState = type(entry.eventState) == "table" and entry.eventState
        or type(entry.context) == "table" and entry.context.eventState
        or nil
    local modifiers = type(Ruleset.GetNpcDifficultyModifiers) == "function"
        and Ruleset.GetNpcDifficultyModifiers(type(eventState) == "table" and eventState.difficulty or "normal")
        or nil
    local hitBonus = tonumber(type(modifiers) == "table" and modifiers.hitBonus or 0) or 0

    if entry._npcDifficultyBaseAttackerTotal == nil then
        entry._npcDifficultyBaseAttackerTotal = tonumber(entry.attackerTotal) or 0
    end
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

local function canBuildLazyPlayerEntry()
    return type(Combat.ResolveDefenceSystem) == "function"
        and type(Combat.ResolveHitCheckAttackType) == "function"
        and type(Combat.BuildCombatLookupSnapshot) == "function"
        and type(Combat.ResolveWeaponSkillContext) == "function"
        and type(Combat.BuildAttackerTotal) == "function"
        and type(Combat.ResolveAttackModifierContext) == "function"
        and type(Combat.ApplyWeaponSkillHitPenalty) == "function"
        and type(Combat.ResolveCritCategory) == "function"
        and type(Combat.ResolveCritStatRef) == "function"
        and type(Combat.ResolveBaseCritChance) == "function"
        and type(Combat.ResolveEffectResultType) == "function"
        and type(Combat.ResolveDamageAmount) == "function"
end

local function buildLazyPlayerHitEntry(self, context, effect, component)
    if type(context) ~= "table" or type(effect) ~= "table" or type(component) ~= "table" then
        return nil
    end
    if not canBuildLazyPlayerEntry() then
        return nil
    end

    local eventState = resolveEventState(context)
    local sessionState = resolveSessionState(context)
    local attackerUnit, defenderUnit = resolveCombatUnits(context)
    local spellRef = normalizeToken(context.spellRef)
    local componentKey = normalizeToken(component.key or context.componentKey)
    local eventId = normalizeToken(context.eventId) or normalizeToken(eventState and eventState.id)
    local defenceSystem = self:ResolveDefenceSystem()
    local attackType = self:ResolveHitCheckAttackType(effect, component)

    if type(eventState) ~= "table"
        or eventState.active ~= true
        or type(attackerUnit) ~= "table"
        or type(defenderUnit) ~= "table"
        or defenderUnit.isPlayer ~= true
        or not spellRef
        or not componentKey
        or not defenceSystem
        or not eventId
    then
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
        spell = context.spell,
        eventId = eventId,
        combatLookupSnapshot = combatLookupSnapshot,
    }
    context.combatLookupSnapshot = combatLookupSnapshot

    -- Preserve the canonical hit/crit/random-roll ordering used by
    -- buildSharedHitPreviewEntry(), but stop before player reaction-display
    -- construction and final mitigated damage resolution.
    local weaponSkillContext = self:ResolveWeaponSkillContext(baseContext, effect, component)
    local attackerTotal, attackerRollContext = self:BuildAttackerTotal(
        baseContext,
        attackerUnit,
        defenceSystem,
        attackType
    )
    local prePenaltyAttackerTotal = attackerTotal
    local attackModifierContext = self:ResolveAttackModifierContext(
        attackerUnit,
        defenceSystem,
        attackType,
        weaponSkillContext,
        baseContext
    )
    attackerTotal, attackModifierContext.weaponSkillPenaltyValue = self:ApplyWeaponSkillHitPenalty(
        attackerTotal,
        defenceSystem,
        weaponSkillContext
    )
    attackModifierContext.baseTotal = prePenaltyAttackerTotal
    attackModifierContext.finalTotal = attackerTotal
    attackModifierContext.roll = type(attackerRollContext) == "table" and attackerRollContext.roll or nil
    if type(attackerRollContext) == "table" then
        attackerRollContext.weaponSkillPenaltyValue = attackModifierContext.weaponSkillPenaltyValue
        attackerRollContext.finalTotal = attackerTotal
        attackerRollContext.totalModifierValue = attackModifierContext.totalModifierValue
    end

    local critCategory = self:ResolveCritCategory(effect)
    local critStatRef = self:ResolveCritStatRef(defenceSystem, critCategory)
    local baseCritChance = tonumber(self:ResolveBaseCritChance(critCategory)) or 0
    context.critResolutionContext = {
        baseCritChance = baseCritChance,
        statRef = critStatRef,
    }
    local resultType, critRoll = self:ResolveEffectResultType(
        context,
        effect,
        attackerUnit,
        defenceSystem,
        weaponSkillContext
    )

    -- Raw damage is part of the existing hit-check wire contract. Resolve only
    -- that attacker-side value now; mitigation/schools/health preview remain
    -- lazy until BuildDamagePreview()/ApplyResolvedDamage() actually needs them.
    local hitResolutionContext = type(context.hitResolutionContext) == "table"
        and context.hitResolutionContext
        or {}
    hitResolutionContext.combatLookupSnapshot = combatLookupSnapshot
    context.hitResolutionContext = hitResolutionContext
    local rawDamage = tonumber(self:ResolveDamageAmount(context, effect)) or 0
    hitResolutionContext.rawDamage = rawDamage

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
        rawDamage = rawDamage,
        resultType = resultType,
        effect = effect,
        component = component,
        weaponSkillContext = weaponSkillContext,
        attackerRollContext = attackerRollContext,
        attackModifierContext = attackModifierContext,
        combatLookupSnapshot = combatLookupSnapshot,
        hitResolutionContext = hitResolutionContext,
        targetEvents = cloneValue(effect.targetEvents or {}),
        context = context,
        sessionState = sessionState,
        eventState = eventState,
        sharedHitPreview = {
            critCategory = critCategory,
            critStatRef = critStatRef,
            baseCritChance = baseCritChance,
            critRoll = critRoll,
        },
    }

    -- NpcDifficulty.lua wraps the original hit-entry builders before this
    -- extension loads. The player-target fast path bypasses that wrapper, so
    -- preserve its hit-bonus contract explicitly while leaving its damage
    -- modifier on the existing lazy BuildDamagePreview/ApplyResolvedDamage path.
    return applyNpcDifficultyHitBonus(entry)
end

function Combat:BuildHitCheckEntry(context, effect, component)
    if not isPlayerDefenderContext(context) then
        return baseBuildHitCheckEntry(self, context, effect, component)
    end

    local entry = buildLazyPlayerHitEntry(self, context, effect, component)
    if type(entry) ~= "table" then
        return baseBuildHitCheckEntry(self, context, effect, component)
    end

    self.PendingHitCheckCounter = (self.PendingHitCheckCounter or 0) + 1
    entry.checkId = ("%s:%d"):format(tostring(entry.eventId or "event"), self.PendingHitCheckCounter)
    return entry
end

function Combat:BuildHitPreviewEntry(context, effect, component, timingParts)
    if not isPlayerDefenderContext(context) then
        return baseBuildHitPreviewEntry(self, context, effect, component, timingParts)
    end

    local entry = buildLazyPlayerHitEntry(self, context, effect, component)
    if type(entry) ~= "table" then
        return baseBuildHitPreviewEntry(self, context, effect, component, timingParts)
    end
    return entry
end

Combat._reactionPerformanceLazyPlayerHitEntryInstalled = true
return true
