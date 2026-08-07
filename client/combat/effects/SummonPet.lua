local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
if not Combat then
    return
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

function Combat:ExecuteSummonPetEffect(context, effect, component)
    local eventState = type(context) == "table" and context.eventState or nil
    local casterUnit = type(context) == "table" and (context.casterUnit or context.caster) or nil
    local unitRef = ensureString(type(effect) == "table" and effect.unitRef or "")

    if type(eventState) ~= "table" or eventState.active ~= true or type(casterUnit) ~= "table" then
        return false, {
            effectType = "summon_pet",
            resultType = "invalid",
        }
    end

    if unitRef == "" then
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
        registryID = unitRef,
    }
end

local SummonPetEffect = Combat:CreateEffectContract({
    type = "summon_pet",
    label = "Summon Pet",
    description = "Summons the configured unit into the active event under the caster's control.",
    defaults = {
        type = "summon_pet",
        unitRef = nil,
        targetEvents = {},
    },
    fields = {
        "unitRef",
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteSummonPetEffect(context, effect or self.defaults, component)
    end,
})

return SummonPetEffect
