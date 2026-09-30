local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Operations = Addon.Internal.Comms.Operations or {}
local operationOpcode = type(Operations.Allocate) == "function" and Operations:Allocate(
    "COMBAT_DAMAGE_RESOLVED",
    function(arguments, sender, distribution, target, message)
        local client = Addon.Client
        if not client or type(client.HandleCombatDamageResolved) ~= "function" then
            return false
        end

        return client:HandleCombatDamageResolved(arguments, sender, distribution, target, message)
    end,
    "combat-damage-resolved"
) or nil

local acknowledgementOpcode = type(Operations.Allocate) == "function" and Operations:Allocate(
    "COMBAT_DAMAGE_RESOLVED_ACK",
    function(arguments, sender, distribution, target, message)
        local client = Addon.Client
        if not client or type(client.HandleCombatDamageResolvedAck) ~= "function" then
            return false
        end

        return client:HandleCombatDamageResolvedAck(arguments, sender, distribution, target, message)
    end,
    "combat-damage-resolved-ack"
) or nil

return (operationOpcode and Operations:Get(operationOpcode))
    or (acknowledgementOpcode and Operations:Get(acknowledgementOpcode))
    or nil
