local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
if not Combat then
    return
end

local Normalization = Combat.Normalization or nil
if type(Normalization) == "table" and Normalization._hiddenStatusEffectExtended ~= true then
    local originalNormalizeEffectData = Normalization.NormalizeEffectData
    Normalization.NormalizeEffectData = function(effectType, value)
        local normalizedType = Normalization.NormalizeEffectType(effectType)
        if normalizedType == "hide" then
            local data = type(value) == "table" and value or {}
            return {
                type = "hide",
                targetEvents = Normalization.NormalizeEventList(data.targetEvents),
            }
        end

        return originalNormalizeEffectData(effectType, value)
    end
    Normalization._hiddenStatusEffectExtended = true
end

function Combat:ExecuteHideEffect(context, effect, component)
    local target = type(context) == "table" and (context.targetUnit or context.target) or nil
    local client = Addon.Client
    if type(target) ~= "table" or type(client) ~= "table" or type(client.SetEventUnitHiddenStatus) ~= "function" then
        return false, {
            effectType = "hide",
            resultType = "invalid",
        }
    end

    local applied = client:SetEventUnitHiddenStatus(context, target, true) == true
    return applied, {
        effectType = "hide",
        resultType = applied and "applied" or "noop",
        applied = applied,
        component = component,
    }
end

local HideEffect = Combat:CreateEffectContract({
    type = "hide",
    label = "Hide",
    description = "Sets the target unit's hidden status.",
    defaults = {
        type = "hide",
        targetEvents = {},
    },
    fields = {
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteHideEffect(context, effect or self.defaults, component)
    end,
})

return HideEffect
