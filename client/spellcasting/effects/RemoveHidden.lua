local _, Addon = ...

local AuraManager = Addon.Client
    and Addon.Client.Spellcasting
    and Addon.Client.Spellcasting.AuraManager
    or nil
if not AuraManager or type(AuraManager.RegisterEffect) ~= "function" then
    return
end

AuraManager:RegisterEffect("remove_hidden", {
    Apply = function(client, context)
        local targetUnit = type(context) == "table" and context.targetUnit or nil
        if type(targetUnit) ~= "table" or type(client) ~= "table" or type(client.SetEventUnitHiddenStatus) ~= "function" then
            return false, {
                effectType = "remove_hidden",
                resultType = "invalid",
            }
        end

        local applied = client:SetEventUnitHiddenStatus(context, targetUnit, false) == true
        return applied, {
            effectType = "remove_hidden",
            resultType = applied and "applied" or "noop",
            applied = applied,
        }
    end,
})
