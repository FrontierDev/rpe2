local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Spellcasting = Addon.Client.Spellcasting
local AuraManager = Spellcasting.AuraManager or {}

local function getCombat()
    return Addon.Client and Addon.Client.Combat or nil
end

AuraManager:RegisterEffect({
    type = "resource",
    Execute = function(self, context, effect)
        local Combat = getCombat()
        local targetUnit = type(context) == "table" and context.targetUnit or nil
        if not Combat or type(targetUnit) ~= "table" then
            return false, nil
        end

        local amount = Combat:ResolveResourceEffectAmount(context, effect)
        local applied, resourceEntry, appliedDelta = Combat:ApplyResourceDelta(targetUnit, effect and effect.resourceRef or nil, amount, context)
        local result = {
            effectType = "resource",
            amount = amount,
            applied = applied,
            appliedDelta = appliedDelta,
            resourceEntry = resourceEntry,
            resourceDeltas = {},
        }
        if applied and resourceEntry then
            result.resourceDeltas[1] = {
                resourceRef = tostring(effect and effect.resourceRef or ""),
                delta = appliedDelta,
                currentValue = tonumber(resourceEntry.currentValue) or 0,
                maxValue = tonumber(resourceEntry.maxValue) or 0,
            }
        end

        return applied, result
    end,
})

return true
