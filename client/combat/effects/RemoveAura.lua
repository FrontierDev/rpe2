local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
local Spellcasting = Addon.Client and Addon.Client.Spellcasting or nil
if not Combat then
    return
end

function Combat:ExecuteRemoveAuraEffect(context, effect, component)
    local target = type(context) == "table" and (context.targetUnit or context.target) or nil
    local auraManager = Spellcasting and Spellcasting.AuraManager or nil
    if type(target) ~= "table" then
        return false, {
            effectType = "remove_aura",
            resultType = "invalid",
            amount = 0,
        }
    end

    if not auraManager or type(auraManager.RemoveAuraStacksFromContext) ~= "function" then
        return false, {
            effectType = "remove_aura",
            resultType = "invalid",
            amount = 0,
        }
    end

    local removedStacks = math.max(1, math.floor(tonumber(effect and effect.stacks) or 1))
    local applied, auraEntry = auraManager:RemoveAuraStacksFromContext(
        Addon.Client,
        context,
        effect and effect.auraRef or nil,
        removedStacks,
        nil,
        tonumber(target.eventID) or 0
    )
    return applied, {
        effectType = "remove_aura",
        resultType = applied and "applied" or "noop",
        applied = applied,
        auraEntry = auraEntry,
        stacks = removedStacks,
        component = component,
    }
end

local RemoveAuraEffect = Combat:CreateEffectContract({
    type = "remove_aura",
    label = "Remove Aura",
    description = "Removes aura stacks from a target.",
    defaults = {
        type = "remove_aura",
        auraRef = nil,
        stacks = 1,
        targetEvents = {},
    },
    fields = {
        "auraRef",
        "stacks",
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteRemoveAuraEffect(context, effect or self.defaults, component)
    end,
})

return RemoveAuraEffect
