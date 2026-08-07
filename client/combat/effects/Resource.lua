local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
if not Combat then
    return
end

function Combat:ExecuteResourceEffect(context, effect, component)
    local target = type(context) == "table" and (context.targetUnit or context.target) or nil
    if type(target) ~= "table" then
        return false, {
            effectType = "resource",
            resultType = "invalid",
            amount = 0,
        }
    end

    local amount = tonumber(effect and effect.amount) or 0
    local applied, entry, appliedDelta = self:ApplyResourceDelta(target, effect and effect.resourceRef or nil, amount, context)
    local result = {
        effectType = "resource",
        resultType = applied and "applied" or "noop",
        amount = amount,
        applied = applied,
        resourceEntry = entry,
        component = component,
        appliedDelta = appliedDelta,
        resourceDeltas = {},
    }
    if applied and entry then
        result.resourceDeltas = {
            {
                resourceRef = tostring(effect and effect.resourceRef or ""),
                delta = appliedDelta,
                maxValue = tonumber(entry.maxValue) or 0,
                currentValue = tonumber(entry.currentValue) or 0,
            },
        }
    end

    return applied, result
end

local ResourceEffect = Combat:CreateEffectContract({
    type = "resource",
    label = "Resource",
    description = "Adjusts a resource value on the target.",
    defaults = {
        type = "resource",
        resourceRef = nil,
        amount = 0,
        targetEvents = {},
    },
    fields = {
        "resourceRef",
        "amount",
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteResourceEffect(context, effect or self.defaults, component)
    end,
})

return ResourceEffect
