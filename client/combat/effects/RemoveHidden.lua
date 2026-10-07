local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
if not Combat then
    return
end

local Normalization = Combat.Normalization or nil
if type(Normalization) == "table" and Normalization._removeHiddenEffectExtended ~= true then
    local originalNormalizeEffectData = Normalization.NormalizeEffectData
    Normalization.NormalizeEffectData = function(effectType, value)
        local normalizedType = Normalization.NormalizeEffectType(effectType)
        if normalizedType == "remove_hidden" then
            local data = type(value) == "table" and value or {}
            return {
                type = "remove_hidden",
                targetEvents = Normalization.NormalizeEventList(data.targetEvents),
            }
        end

        return originalNormalizeEffectData(effectType, value)
    end
    Normalization._removeHiddenEffectExtended = true
end

function Combat:ExecuteRemoveHiddenEffect(context, effect, component)
    local target = type(context) == "table" and (context.targetUnit or context.target) or nil
    local client = Addon.Client
    if type(target) ~= "table" or type(client) ~= "table" or type(client.SetEventUnitHiddenStatus) ~= "function" then
        return false, {
            effectType = "remove_hidden",
            resultType = "invalid",
        }
    end

    local applied = client:SetEventUnitHiddenStatus(context, target, false) == true
    return applied, {
        effectType = "remove_hidden",
        resultType = applied and "applied" or "noop",
        applied = applied,
        component = component,
    }
end

local RemoveHiddenEffect = Combat:CreateEffectContract({
    type = "remove_hidden",
    label = "Reveal",
    description = "Removes the target unit's hidden status.",
    defaults = {
        type = "remove_hidden",
        targetEvents = {},
    },
    fields = {
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteRemoveHiddenEffect(context, effect or self.defaults, component)
    end,
})

return RemoveHiddenEffect
