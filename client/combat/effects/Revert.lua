local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
local Spellcasting = Addon.Client and Addon.Client.Spellcasting or nil
if not Combat then
    return
end

function Combat:ExecuteRevertEffect(context, effect, component)
    local targetUnit = type(context) == "table" and (context.targetUnit or context.target) or nil
    local targetEventId = tonumber(targetUnit and targetUnit.eventID) or 0
    if type(context) ~= "table"
        or type(targetUnit) ~= "table"
        or targetEventId <= 0
        or type(Spellcasting) ~= "table"
        or type(Spellcasting.RevertLastSpellImpact) ~= "function"
    then
        return false, {
            effectType = "revert",
            resultType = "invalid",
            amount = 0,
        }
    end

    local applied, details = Spellcasting.RevertLastSpellImpact(Addon.Client, context.eventState, targetUnit, context)
    return applied, {
        effectType = "revert",
        resultType = applied and "applied" or "noop",
        applied = applied,
        details = details,
        component = component,
    }
end

local RevertEffect = Combat:CreateEffectContract({
    type = "revert",
    label = "Revert",
    description = "Reverses the most recent reversible spell impact on the target.",
    defaults = {
        type = "revert",
        targetEvents = {},
    },
    fields = {
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteRevertEffect(context, effect or self.defaults, component)
    end,
})

return RevertEffect
