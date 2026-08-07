local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Combat = Addon.Client.Combat or {}

local Client = Addon.Client
local Combat = Addon.Client.Combat

function Client:HandleCombatHitCheckRequest(arguments, sender)
    if type(Combat.HandleDamageHitCheckRequest) ~= "function" then
        return false
    end

    return Combat:HandleDamageHitCheckRequest(self, arguments, sender)
end

function Client:HandleCombatHitCheckResponse(arguments, sender)
    if type(Combat.HandleDamageHitCheckResponse) ~= "function" then
        return false
    end

    return Combat:HandleDamageHitCheckResponse(self, arguments, sender)
end

return Client
