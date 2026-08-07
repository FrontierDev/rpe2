local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Spellcasting = Addon.Client.Spellcasting
local AuraManager = Spellcasting.AuraManager or {}

AuraManager:RegisterEffect({
    type = "control",
    Execute = function()
        return false, nil
    end,
    HasFlag = function(self, context, effect, flagName)
        if type(effect) ~= "table" or type(flagName) ~= "string" or flagName == "" then
            return false
        end
        return effect[flagName] == true
    end,
})

return true
