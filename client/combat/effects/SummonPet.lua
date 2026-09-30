local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
if not Combat then
    return
end

function Combat:ExecuteSummonPetEffect(context, effect, component)
    local eventState = type(context) == "table" and context.eventState or nil
    local casterUnit = type(context) == "table" and (context.casterUnit or context.caster) or nil

    if type(eventState) ~= "table" or eventState.active ~= true or type(casterUnit) ~= "table" then
        return false, {
            effectType = "summon_pet",
            resultType = "invalid",
        }
    end

    return true, {
        effectType = "summon_pet",
        resultType = "applied",
        applied = true,
        component = component,
    }
end

local SummonPetEffect = Combat:CreateEffectContract({
    type = "summon_pet",
    label = "Summon Pet",
    description = "Summons the Pet selected in the caster's profile under the caster's control.",
    defaults = {
        type = "summon_pet",
        targetEvents = {},
    },
    fields = {
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteSummonPetEffect(context, effect or self.defaults, component)
    end,
})

return SummonPetEffect
