local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
if not Combat then
    return
end

local function normalizeQualifiedUnitRef(value)
    local unitRef = tostring(value or "")
    local datasetId, unitId = string.match(unitRef, "^([^:]+):(.+)$")
    if not datasetId or not unitId or datasetId == "" or unitId == "" then
        return nil
    end

    return unitRef
end

function Combat:ExecuteSummonUnitEffect(context, effect, component)
    local eventState = type(context) == "table" and context.eventState or nil
    local casterUnit = type(context) == "table" and (context.casterUnit or context.caster) or nil
    local unitRef = normalizeQualifiedUnitRef(type(effect) == "table" and effect.unitRef or nil)

    if type(eventState) ~= "table" or eventState.active ~= true or type(casterUnit) ~= "table" then
        return false, {
            effectType = "summon_unit",
            resultType = "invalid",
            errorCode = "event-inactive",
        }
    end

    if not unitRef then
        return false, {
            effectType = "summon_unit",
            resultType = "invalid",
            errorCode = "unit-ref-malformed",
        }
    end

    return true, {
        effectType = "summon_unit",
        resultType = "applied",
        applied = true,
        unitRef = unitRef,
        component = component,
    }
end

local SummonUnitEffect = Combat:CreateEffectContract({
    type = "summon_unit",
    label = "Summon Unit",
    description = "Summons the selected Unit definition under the caster's control.",
    defaults = {
        type = "summon_unit",
        unitRef = nil,
        targetEvents = {},
    },
    fields = {
        "unitRef",
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteSummonUnitEffect(context, effect or self.defaults, component)
    end,
})

return SummonUnitEffect
