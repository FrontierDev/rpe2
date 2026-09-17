local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
if not Combat then
    return
end

local EventUnit = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.EventUnit
    or nil

local function isActive(unit)
    if EventUnit and type(EventUnit.IsActive) == "function" then
        return EventUnit.IsActive(unit)
    end

    return type(unit) == "table" and (unit.isPlayer == true or unit.active ~= false)
end

function Combat:ExecuteTauntEffect(context, effect, component)
    local target = type(context) == "table" and (context.targetUnit or context.target) or nil
    local client = Addon.Client
    local duration = math.floor(tonumber(effect and effect.duration) or 0)
    local result = {
        effectType = "taunt",
        resultType = "invalid",
        applied = false,
        duration = duration,
        component = component,
    }

    if type(target) ~= "table" or target.isPlayer == true or not isActive(target) or duration <= 0 then
        result.resultType = "noop"
        return false, result
    end

    if type(client) ~= "table" or type(client.SetEventUnitTauntState) ~= "function" then
        return false, result
    end

    local applied = client:SetEventUnitTauntState(context, target, duration) == true
    result.applied = applied
    result.resultType = applied and "applied" or "noop"
    return applied, result
end

local TauntEffect = Combat:CreateEffectContract({
    type = "taunt",
    label = "Taunt",
    description = "Causes the target NPC to be taunted by the caster.",
    defaults = {
        type = "taunt",
        duration = 2,
        targetEvents = {},
    },
    fields = {
        "duration",
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteTauntEffect(context, effect or self.defaults, component)
    end,
})

return TauntEffect
