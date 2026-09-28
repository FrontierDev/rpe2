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

function Client:HandleCombatHitCheckAck(arguments, sender)
    if type(Combat.HandleDamageHitCheckAck) ~= "function" then
        return false
    end
    return Combat:HandleDamageHitCheckAck(self, arguments, sender)
end

function Client:HandleCombatHitCheckReject(arguments, sender)
    if type(Combat.HandleDamageHitCheckReject) ~= "function" then
        return false
    end
    return Combat:HandleDamageHitCheckReject(self, arguments, sender)
end

function Client:HandleCombatDamageResolved(arguments, sender)
    if type(Combat.HandleCombatDamageResolved) ~= "function" then
        return false
    end

    return Combat:HandleCombatDamageResolved(self, arguments, sender)
end

function Client:HandleCombatDamageResolvedAck(arguments, sender)
    if type(Combat.HandleCombatDamageResolvedAck) ~= "function" then
        return false
    end

    return Combat:HandleCombatDamageResolvedAck(self, arguments, sender)
end

return Client
