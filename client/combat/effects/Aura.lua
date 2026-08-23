local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
if not Combat then
    return
end

local function getAuraManager()
    local spellcasting = Addon.Client and Addon.Client.Spellcasting or nil
    local auraManager = type(spellcasting) == "table" and spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.ApplyAuraFromContext) == "function" then
        return auraManager
    end

    local canonicalAuraManager = Addon.Internal and Addon.Internal.AuraManager or nil
    if type(canonicalAuraManager) == "table" and type(canonicalAuraManager.ApplyAuraFromContext) == "function" then
        if type(spellcasting) == "table" then
            spellcasting.AuraManager = canonicalAuraManager
        end
        return canonicalAuraManager
    end

    return auraManager
end

local function resolveAuraPowerLevel(auraManager, context, effect)
    if type(auraManager) == "table" and type(auraManager.ResolveApplyAuraPowerLevel) == "function" then
        return auraManager:ResolveApplyAuraPowerLevel(context, effect)
    end

    local basePower = tonumber(type(effect) == "table" and effect.basePower or 0) or 0
    local common = Addon.Utils and Addon.Utils.Common or nil
    if type(common) == "table" and type(common.Round) == "function" then
        return common.Round(basePower)
    end

    return math.floor(basePower + 0.5)
end

function Combat:ResolveAuraDefinition(auraRef, context)
    local auraManager = getAuraManager()
    if auraManager and type(auraManager.ResolveAuraDefinition) == "function" then
        local _, aura = auraManager:ResolveAuraDefinition(auraRef, context)
        if aura then
            return aura
        end
    end

    return nil
end

function Combat:ApplyAura(target, auraRef, stacks, duration, context)
    local auraManager = getAuraManager()
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
    local auraManager = getAuraManager()
    if type(target) ~= "table" then
        local Debug = Addon.Debug or {}
        if type(Debug.Internal) == "function" then
            Debug.Internal(
                "Spellcast apply_aura failed: missing-target aura=%s casterEventId=%s component=%s.",
                tostring(type(effect) == "table" and effect.auraRef or "nil"),
                tostring(type(context) == "table" and type(context.casterUnit) == "table" and tonumber(context.casterUnit.eventID) or 0),
                tostring(type(component) == "table" and component.key or "unknown")
            )
        end
        return false, {
            effectType = "apply_aura",
            resultType = "invalid",
            amount = 0,
        }
    end

    if not auraManager or type(auraManager.ApplyAuraFromContext) ~= "function" then
        local Debug = Addon.Debug or {}
        if type(Debug.Internal) == "function" then
            Debug.Internal(
                "Spellcast apply_aura failed: aura-manager-unavailable aura=%s component=%s.",
                tostring(type(effect) == "table" and effect.auraRef or "nil"),
                tostring(type(component) == "table" and component.key or "unknown")
            )
        end
        return false, {
            effectType = "apply_aura",
            resultType = "invalid",
            amount = 0,
        }
    end

    local powerLevel = resolveAuraPowerLevel(auraManager, context, effect)
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

    if applied ~= true then
        local Debug = Addon.Debug or {}
        if type(Debug.Internal) == "function" then
            Debug.Internal(
                "Spellcast apply_aura noop: aura=%s targetEventId=%s casterEventId=%s component=%s.",
                tostring(type(effect) == "table" and effect.auraRef or "nil"),
                tostring(type(target) == "table" and tonumber(target.eventID) or 0),
                tostring(type(context) == "table" and type(context.casterUnit) == "table" and tonumber(context.casterUnit.eventID) or 0),
                tostring(type(component) == "table" and component.key or "unknown")
            )
        end
    end

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
