local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Client = Addon.Client
local AuraManager = Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraManager or nil

function Client:HandleAuraApply(arguments, sender)
    if not AuraManager or type(AuraManager.HandleAuraApply) ~= "function" then
        return false
    end

    return AuraManager:HandleAuraApply(self, arguments, sender)
end

function Client:HandleAuraDispel(arguments, sender)
    if not AuraManager or type(AuraManager.HandleAuraDispel) ~= "function" then
        return false
    end

    return AuraManager:HandleAuraDispel(self, arguments, sender)
end

function Client:HandleAuraApplyBatch(arguments, sender)
    if not AuraManager or type(AuraManager.HandleAuraApplyBatch) ~= "function" then
        return false
    end

    return AuraManager:HandleAuraApplyBatch(self, arguments, sender)
end

function Client:HandleAuraDispelBatch(arguments, sender)
    if not AuraManager or type(AuraManager.HandleAuraDispelBatch) ~= "function" then
        return false
    end

    return AuraManager:HandleAuraDispelBatch(self, arguments, sender)
end

return Client
