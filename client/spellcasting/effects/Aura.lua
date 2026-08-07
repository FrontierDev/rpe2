local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Spellcasting = Addon.Client.Spellcasting
local AuraManager = Spellcasting.AuraManager or {}

AuraManager:RegisterEffect({
    type = "apply_aura",
    Execute = function(self, context, effect)
        local targetUnit = type(context) == "table" and context.targetUnit or nil
        if type(targetUnit) ~= "table" or type(self.ApplyAuraFromContext) ~= "function" then
            return false, nil
        end

        local powerLevel = type(self.ResolveApplyAuraPowerLevel) == "function"
            and self:ResolveApplyAuraPowerLevel(context, effect)
            or (tonumber(effect and effect.basePower) or 0)
        local applied, auraEntry = self:ApplyAuraFromContext(
            Addon.Client,
            context,
            effect and effect.auraRef or nil,
            effect and effect.stacks or 1,
            effect and effect.duration or nil,
            powerLevel
        )
        return applied, {
            effectType = "apply_aura",
            applied = applied,
            auraEntry = auraEntry,
            powerLevel = powerLevel,
        }
    end,
})

return true
