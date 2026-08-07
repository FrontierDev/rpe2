local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
local Common = Addon.Utils and Addon.Utils.Common or nil
local Dice = Addon.Utils and Addon.Utils.Dice or nil
local Lookup = Addon.Utils and Addon.Utils.Lookup or nil
local Spellcasting = Addon.Client and Addon.Client.Spellcasting or nil
if not Combat then
    return
end

local function applyPercentModifier(amount, percentValue)
    local numericAmount = tonumber(amount) or 0
    local numericPercent = tonumber(percentValue) or 0
    return numericAmount * (1 + (numericPercent / 100))
end

local function getModifierStatValue(unit, statRef)
    local normalizedStatRef = type(statRef) == "string" and statRef or ""
    if normalizedStatRef == "" then
        return 0
    end

    return tonumber(Lookup.GetStatValue and Lookup.GetStatValue(unit, normalizedStatRef, 0) or 0) or 0
end

function Combat:ResolveHealingAmount(context, effect)
    local caster = type(context) == "table" and (context.casterUnit or context.caster) or nil
    local baseHealing = tonumber(effect and effect.baseHealing) or 0
    local statScaling = 0

    for index = 1, #(effect and effect.statScaling or {}) do
        local entry = effect.statScaling[index]
        if type(entry) == "table" and type(entry.statRef) == "string" and entry.statRef ~= "" then
            statScaling = statScaling + ((Lookup and Lookup.GetStatValue and Lookup.GetStatValue(caster, entry.statRef, 0) or 0) * (tonumber(entry.coefficient) or 0))
        end
    end

    local variance = Dice and Dice.RollVariance and Dice.RollVariance(context) or 1
    local amount = (baseHealing + statScaling) * variance
    return math.max(0, Common.Round(amount))
end

function Combat:ExecuteHealEffect(context, effect, component)
    local target = type(context) == "table" and (context.targetUnit or context.target) or nil
    local caster = type(context) == "table" and (context.casterUnit or context.caster) or nil
    if type(target) ~= "table" or type(caster) ~= "table" then
        return false, {
            resultType = "invalid",
            amount = 0,
        }
    end

    local result = {
        effectType = "heal",
        resultType = "hit",
        amount = 0,
        wasCritical = false,
        auraApplied = false,
        component = component,
        appliedDelta = 0,
        resourceDeltas = {},
    }

    local amount = self:ResolveHealingAmount(context, effect)
    local defenceSystem = self:ResolveDefenceSystem() or "ac"
    local resultType = self:ResolveEffectResultType(context, effect, caster, defenceSystem, nil)
    result.resultType = resultType
    result.wasCritical = resultType == "critical"
    if resultType == "critical" then
        amount = Common.Round(amount * (tonumber(self:GetCombatRule("critical_healing_multiplier", 2.0)) or 2.0))
    end
    amount = applyPercentModifier(amount, getModifierStatValue(caster, self:GetCombatRule("healing_done_stat", "")))
    amount = applyPercentModifier(amount, getModifierStatValue(target, self:GetCombatRule("healing_received_stat", "")))
    amount = math.max(0, Common.Round(amount))
    result.amount = amount

    local healthRef = type(context) == "table" and context.healthResourceRef or nil
    if type(healthRef) ~= "string" or healthRef == "" then
        healthRef = self:GetHealthResourceRef()
    end

    local spellAllowsDeadTargets = type(context) == "table"
        and type(context.spell) == "table"
        and context.spell.allowDeadTargets == true
    local targetIsDead = self:IsUnitDead(target, {
        eventState = type(context) == "table" and context.eventState or nil,
        healthResourceRef = healthRef,
    })
    if targetIsDead and spellAllowsDeadTargets ~= true then
        result.resultType = "invalid"
        return false, result
    end

    local applied, entry, appliedDelta = false, nil, 0
    if type(healthRef) == "string" and healthRef ~= "" then
        local applyContext = type(Common) == "table" and type(Common.CopyTable) == "function"
            and Common.CopyTable(type(context) == "table" and context or {})
            or {}
        if type(context) == "table" and next(applyContext) == nil then
            for key, value in pairs(context) do
                applyContext[key] = value
            end
        end
        applyContext.allowDeadHealth = spellAllowsDeadTargets == true
        applied, entry, appliedDelta = self:ApplyResourceDelta(target, healthRef, amount, applyContext)
    end
    result.applied = applied
    result.resourceEntry = entry
    result.appliedDelta = appliedDelta
    if applied and entry then
        result.resourceDeltas = {
            {
                resourceRef = healthRef,
                delta = appliedDelta,
                maxValue = tonumber(entry.maxValue) or 0,
                currentValue = tonumber(entry.currentValue) or 0,
            },
        }
    end

    local auraManager = Spellcasting and Spellcasting.AuraManager or nil
    if effect.applyAura == true
        and type(effect.auraRef) == "string"
        and effect.auraRef ~= ""
        and auraManager
        and type(auraManager.ApplyAuraFromContext) == "function"
    then
        local auraApplied, auraEntry = auraManager:ApplyAuraFromContext(Addon.Client, context, effect.auraRef, effect.auraStacks, nil, 0)
        result.auraApplied = auraApplied
        result.auraEntry = auraEntry
    end

    return applied, result
end

local HealEffect = Combat:CreateEffectContract({
    type = "heal",
    label = "Heal",
    description = "Restores health to a target.",
    defaults = {
        type = "heal",
        baseHealing = 0,
        statScaling = {},
        usesProjectile = false,
        projectilePath = "",
        projectileSpeed = 0,
        applyAura = false,
        auraRef = nil,
        auraStacks = 1,
        targetEvents = {},
    },
    fields = {
        "baseHealing",
        "statScaling",
        "usesProjectile",
        "projectilePath",
        "projectileSpeed",
        "applyAura",
        "auraRef",
        "auraStacks",
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteHealEffect(context, effect or self.defaults, component)
    end,
})

return HealEffect
