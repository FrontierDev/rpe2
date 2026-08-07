local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
local Spellcasting = Addon.Client and Addon.Client.Spellcasting or nil
if not Combat then
    return
end

function Combat:ResolveAuraDefinition(auraRef, context)
    local auraManager = Spellcasting and Spellcasting.AuraManager or nil
    if auraManager and type(auraManager.ResolveAuraDefinition) == "function" then
        local _, aura = auraManager:ResolveAuraDefinition(auraRef, context)
        if aura then
            return aura
        end
    end

    return nil
end

function Combat:ApplyAura(target, auraRef, stacks, duration, context)
    local auraManager = Spellcasting and Spellcasting.AuraManager or nil
    if not auraManager or type(auraManager.ApplyAuraFromContext) ~= "function" then
        return false, nil
    end

    local enrichedContext = Combat:CloneValue(context or {})
    enrichedContext.targetUnit = enrichedContext.targetUnit or target
    enrichedContext.target = enrichedContext.target or target
    return auraManager:ApplyAuraFromContext(Addon.Client, enrichedContext, auraRef, stacks, duration, 0)
end

function Combat:ExecuteAuraEffect(context, effect, component)
    local target = type(context) == "table" and (context.targetUnit or context.target) or nil
    local auraManager = Spellcasting and Spellcasting.AuraManager or nil
    if type(target) ~= "table" then
        return false, {
            effectType = "apply_aura",
            resultType = "invalid",
            amount = 0,
        }
    end

    if not auraManager or type(auraManager.ResolveApplyAuraPowerLevel) ~= "function" then
        return false, {
            effectType = "apply_aura",
            resultType = "invalid",
            amount = 0,
        }
    end

    local powerLevel = auraManager:ResolveApplyAuraPowerLevel(context, effect)
    local applied, auraEntry = auraManager:ApplyAuraFromContext(
        Addon.Client,
        context,
        effect and effect.auraRef or nil,
        effect and effect.stacks or 1,
        effect and effect.duration or nil,
        powerLevel
    )
    local result = {
        effectType = "apply_aura",
        resultType = applied and "applied" or "noop",
        applied = applied,
        auraEntry = auraEntry,
        powerLevel = powerLevel,
        component = component,
    }

    return applied, result
end

local AuraEffect = Combat:CreateEffectContract({
    type = "apply_aura",
    label = "Apply Aura",
    description = "Applies an aura to a target.",
    defaults = {
        type = "apply_aura",
        auraRef = nil,
        stacks = 1,
        duration = 12,
        basePower = 0,
        targetEvents = {},
    },
    fields = {
        "auraRef",
        "stacks",
        "duration",
        "basePower",
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteAuraEffect(context, effect or self.defaults, component)
    end,
})

return AuraEffect
