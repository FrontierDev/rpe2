local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Spellcasting = Addon.Client.Spellcasting
local AuraManager = Spellcasting.AuraManager or {}

AuraManager:RegisterEffect({
    type = "stat",
    Execute = function()
        return false, nil
    end,
    Accumulate = function(self, context, effect, accumulator)
        local targetStatRef = tostring(type(context) == "table" and context.statRef or "")
        local effectStatRef = tostring(type(effect) == "table" and effect.statRef or "")
        if targetStatRef == "" or targetStatRef ~= effectStatRef then
            return accumulator
        end

        local amount = AuraManager:ResolveEffectAmount(context, effect, "baseAmount")
        if tostring(effect.operation or "flat") == "percent" then
            accumulator.percent = (tonumber(accumulator.percent) or 0) + amount
        else
            accumulator.flat = (tonumber(accumulator.flat) or 0) + amount
        end

        return accumulator
    end,
})

return true
